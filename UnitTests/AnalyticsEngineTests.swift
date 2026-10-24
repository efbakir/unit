import SwiftData
import XCTest
@testable import Unit

@MainActor
final class AnalyticsEngineTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 2
        return value
    }
    private var now: Date { calendar.date(from: DateComponents(year: 2026, month: 10, day: 19, hour: 12))! }
    private let exerciseID = UUID(), templateID = UUID()
    private func date(_ offset: Int) -> Date { calendar.date(byAdding: .day, value: offset, to: now)! }
    private func session(_ offset: Int, weight: Double = 80, reps: Int = 5, id: UUID? = nil, sets: [AnalyticsEngine.SetInput]? = nil) -> AnalyticsEngine.SessionInput {
        .init(id: UUID(), date: date(offset), templateID: templateID, sets: sets ?? [.init(exerciseID: id ?? exerciseID, weight: weight, reps: reps)])
    }
    private func input(_ sessions: [AnalyticsEngine.SessionInput], planned: Int = 3, exercises: [AnalyticsEngine.ExerciseInput]? = nil) -> AnalyticsEngine.Input {
        .init(exercises: exercises ?? [.init(id: exerciseID, name: "Bench Press", isBodyweight: false, equipment: "barbell", muscleGroup: "chest")], sessions: sessions, templates: [], plannedDaysPerWeek: planned)
    }
    private func compute(_ sessions: [AnalyticsEngine.SessionInput], planned: Int = 3, at offset: Int = 0) -> AnalyticsEngine.Output {
        AnalyticsEngine.compute(input(sessions, planned: planned), now: date(offset), calendar: calendar)
    }
    private func performance(_ weight: Double, _ reps: Int, offset: Int = 0) -> AnalyticsEngine.Performance {
        .init(weight: weight, reps: reps, date: date(offset), sessionID: UUID(), templateID: templateID, setIndex: 0)
    }
    func testEmptyAndSingleSessionBaseline() {
        XCTAssertNil(compute([]).summary)
        let result = compute([session(0)])
        XCTAssertEqual(result.summary?.status, .baseline)
        XCTAssertEqual(result.lifts[exerciseID]?.comparison, .new)
        XCTAssertEqual(result.lifts[exerciseID]?.weeks.count, 1)
    }
    func testBaselineDateBoundaryIsImmediate() {
        let values = [session(-14), session(-1)]
        XCTAssertEqual(compute(values, at: -1).summary?.status, .baseline)
        XCTAssertEqual(compute(values).summary?.status, .fewer)
    }
    func testComparisonMatrixAndEpsilon() {
        let b = performance(80, 5)
        for (w, r, expected) in [(82.5, 5, AnalyticsEngine.Comparison.up(weight: 2.5, reps: 0)), (80, 6, .up(weight: 0, reps: 1)), (82.5, 6, .up(weight: 2.5, reps: 1)), (80, 5, .same), (79.999, 5, .same), (77.5, 5, .belowBest), (80, 4, .belowBest), (77.5, 4, .mixed), (82.5, 4, .mixed), (77.5, 6, .mixed)] {
            XCTAssertEqual(AnalyticsEngine.compare(performance(w, r), b, bodyweight: false), expected)
        }
        XCTAssertEqual(AnalyticsEngine.compare(performance(0, 6), performance(0, 5), bodyweight: true), .up(weight: 0, reps: 1))
        XCTAssertEqual(AnalyticsEngine.compare(performance(0, 5), performance(0, 5), bodyweight: true), .same)
        XCTAssertEqual(AnalyticsEngine.compare(performance(0, 4), performance(0, 5), bodyweight: true), .belowBest)
        XCTAssertEqual(AnalyticsEngine.compare(nil, b, bodyweight: false), .notRecent)
        XCTAssertEqual(AnalyticsEngine.compare(b, nil, bodyweight: false), .new)
    }
    func testWindowEndpointsAndFutureSessions() {
        let values = [session(-55, weight: 70), session(-28, weight: 75), session(-27), session(0), session(1, weight: 999)]
        let lift = compute(values).lifts[exerciseID]
        XCTAssertEqual(lift?.comparison, .up(weight: 5, reps: 0))
        XCTAssertEqual(lift?.latest?.weight, 80)
        XCTAssertEqual(lift?.best?.weight, 80)
    }
    func testComparisonEvidenceSeparatesWindowWinnersFromLatestAndAllTimeBest() throws {
        let values = [
            session(-100, weight: 120, reps: 1),
            session(-55, weight: 75, reps: 6),
            session(-28, weight: 80, reps: 6),
            session(-27, weight: 80, reps: 8),
            session(-2, sets: [.init(exerciseID: exerciseID, weight: 200, reps: 8, isWarmup: true)]),
            session(-1, weight: 75, reps: 6),
            session(1, weight: 300, reps: 1)
        ]
        let lift = try XCTUnwrap(compute(values).lifts[exerciseID])
        XCTAssertEqual(lift.best?.weight, 120)
        XCTAssertEqual(lift.latest?.weight, 75)
        XCTAssertEqual(lift.currentWindowBest?.weight, 80)
        XCTAssertEqual(lift.currentWindowBest?.reps, 8)
        XCTAssertEqual(lift.currentWindowBest?.date, date(-27))
        XCTAssertEqual(lift.previousWindowBest?.weight, 80)
        XCTAssertEqual(lift.previousWindowBest?.reps, 6)
        XCTAssertEqual(lift.previousWindowBest?.date, date(-28))
        XCTAssertEqual(lift.comparison, .up(weight: 0, reps: 2))
        XCTAssertEqual(AnalyticsEngine.compare(lift.currentWindowBest, lift.previousWindowBest, bodyweight: lift.bodyweight), lift.comparison)
    }
    func testExtraSetsChangeVolumeWithoutChangingPerformanceComparison() throws {
        let repeatedSets = (0..<3).map { AnalyticsEngine.SetInput(exerciseID: exerciseID, weight: 80, reps: 5, index: $0) }
        let lift = try XCTUnwrap(compute([session(-30), session(-1, sets: repeatedSets)]).lifts[exerciseID])
        XCTAssertEqual(lift.comparison, .same)
        XCTAssertEqual(lift.currentWindowBest?.reps, lift.previousWindowBest?.reps)
        XCTAssertEqual(lift.currentWindowBest?.weight, lift.previousWindowBest?.weight)
        XCTAssertEqual(lift.sessions.first?.volumeKg, 400)
        XCTAssertEqual(lift.sessions.last?.volumeKg, 1200)
    }
    func testComparisonEvidenceHandlesMissingWindowsAndBodyweight() throws {
        let newLift = try XCTUnwrap(compute([session(-1)]).lifts[exerciseID])
        XCTAssertNotNil(newLift.currentWindowBest)
        XCTAssertNil(newLift.previousWindowBest)
        XCTAssertEqual(ExerciseProgressView.comparisonText(for: newLift, unit: "kg"), "No previous comparison")
        let staleLift = try XCTUnwrap(compute([session(-30)]).lifts[exerciseID])
        XCTAssertNil(staleLift.currentWindowBest)
        XCTAssertNotNil(staleLift.previousWindowBest)
        XCTAssertEqual(ExerciseProgressView.comparisonText(for: staleLift, unit: "kg"), "No sets in the last 4 weeks")
        let bodyweightLift = try XCTUnwrap(compute([session(-30, weight: 0, reps: 8), session(-1, weight: 0, reps: 10)]).lifts[exerciseID])
        XCTAssertTrue(bodyweightLift.bodyweight)
        XCTAssertEqual(bodyweightLift.previousWindowBest?.reps, 8)
        XCTAssertEqual(bodyweightLift.currentWindowBest?.reps, 10)
        XCTAssertEqual(bodyweightLift.comparison, .up(weight: 0, reps: 2))
        let current = try XCTUnwrap(bodyweightLift.currentWindowBest)
        XCTAssertEqual(WorkoutTargetFormatter.analyticsPerformance(current, bodyweight: true, unit: "lb"), "BW × 10")
    }
    func testStatusThresholdsAndThreeDayPersistence() {
        let otherID = UUID()
        let exercises = [exerciseID, otherID].map { AnalyticsEngine.ExerciseInput(id: $0, name: $0.uuidString, isBodyweight: false, equipment: nil, muscleGroup: "back") }
        let older = [session(-40, sets: [.init(exerciseID: exerciseID, weight: 75, reps: 5), .init(exerciseID: otherID, weight: 80, reps: 5)])]
        let recent = [-25,-22,-19,-16,-13,-10,-7,-4,-2].map { session($0, sets: [.init(exerciseID: exerciseID, weight: 80, reps: 5), .init(exerciseID: otherID, weight: 80, reps: 5)]) }
        let values = older + recent
        // 9 / 12 sessions, half of two lifts up; only reaches threshold at D-2.
        XCTAssertEqual(AnalyticsEngine.compute(input(values, exercises: exercises), now: date(-2), calendar: calendar).summary?.status, .steady)
        XCTAssertEqual(AnalyticsEngine.compute(input(values, exercises: exercises), now: now, calendar: calendar).summary?.status, .stronger)
        let oneLift = values.map { AnalyticsEngine.SessionInput(id: $0.id, date: $0.date, templateID: $0.templateID, sets: $0.sets.filter { $0.exerciseID == exerciseID }) }
        XCTAssertNotEqual(compute(oneLift).summary?.status, .stronger) // n=1 cannot be stronger
        XCTAssertEqual(compute([session(-55), session(-1)], planned: 0).summary?.planned, 0)
    }
    func testExactSummaryThresholdsAndNoPlanPath() {
        let ids = (0..<100).map { _ in UUID() }
        let exercises = ids.map { AnalyticsEngine.ExerciseInput(id: $0, name: $0.uuidString, isBodyweight: false, equipment: nil, muscleGroup: "back") }
        func fixture(up: Int, completed: Int, plannedDays: Int) -> AnalyticsEngine.Output {
            let before = session(-40, sets: ids.map { .init(exerciseID: $0, weight: 80, reps: 5) })
            let recent = (0..<completed).map { _ in session(-3, sets: ids.enumerated().map { .init(exerciseID: $0.element, weight: $0.offset < up ? 82.5 : 80, reps: 5) }) }
            return AnalyticsEngine.compute(input([before] + recent, planned: plannedDays, exercises: exercises), now: now, calendar: calendar)
        }
        XCTAssertEqual(fixture(up: 50, completed: 9, plannedDays: 3).summary?.status, .stronger)
        XCTAssertEqual(fixture(up: 49, completed: 9, plannedDays: 3).summary?.status, .steady)
        XCTAssertEqual(fixture(up: 50, completed: 49, plannedDays: 25).summary?.status, .fewer)
        XCTAssertEqual(fixture(up: 50, completed: 1, plannedDays: 0).summary?.status, .stronger)
    }
    func testExpiredHistoryAndPlannedDaysRecompute() {
        let history = [session(-200), session(-100)]
        XCTAssertEqual(compute(history).summary?.status, .fewer)
        XCTAssertEqual(compute(history).summary?.sessions, 0)
        XCTAssertEqual(compute(history).lifts[exerciseID]?.comparison, .notRecent)
        XCTAssertEqual(compute(history, planned: 2).summary?.planned, 8)
        XCTAssertEqual(compute(history, planned: 4).summary?.planned, 16)
    }
    func testDecimalAndPoundsFormattingNeverShowsZeroDelta() {
        XCTAssertEqual(WorkoutTargetFormatter.analyticsWeight(1.25, unit: "kg", locale: Locale(identifier: "en_US")), "1.25 kg")
        XCTAssertEqual(WorkoutTargetFormatter.analyticsWeight(1.25, unit: "kg", locale: Locale(identifier: "de_DE")), "1,25 kg")
        XCTAssertEqual(WorkoutTargetFormatter.analyticsWeight(2.5, unit: "kg", locale: Locale(identifier: "en_US")), "2.5 kg")
        XCTAssertEqual(WorkoutTargetFormatter.analyticsWeight(0.01, unit: "lb", locale: Locale(identifier: "en_US"), delta: true), "0.1 lb")
        XCTAssertEqual(WorkoutTargetFormatter.analyticsChange(.up(weight: 0, reps: 1), unit: "kg"), "+1 rep")
    }
    func testAliasesAndExcludedEquipmentAndVariants() {
        for slot in AnalyticsEngine.Slot.allCases {
            for alias in slot.aliases {
                XCTAssertEqual(AnalyticsEngine.slot(for: .init(id: UUID(), name: alias.uppercased().replacingOccurrences(of: " ", with: "_"), isBodyweight: false, equipment: nil, muscleGroup: "")), slot)
            }
        }
        for name in ["Front Squat", "Romanian Deadlift", "Incline Bench Press", "Close-Grip Bench Press", "Trap-Bar Deadlift", "Goblet Squat"] {
            XCTAssertNil(AnalyticsEngine.slot(for: .init(id: UUID(), name: name, isBodyweight: false, equipment: "barbell", muscleGroup: "")))
        }
        XCTAssertNil(AnalyticsEngine.slot(for: .init(id: exerciseID, name: "Bench Press", isBodyweight: false, equipment: "dumbbell", muscleGroup: "chest")))
    }
    func testMainCandidateTieBreakAndRename() {
        let other = UUID()
        let exercises = [AnalyticsEngine.ExerciseInput(id: exerciseID, name: "Sumo Deadlift", isBodyweight: false, equipment: nil, muscleGroup: "back"), .init(id: other, name: "Conventional Deadlift", isBodyweight: false, equipment: "barbell", muscleGroup: "back")]
        let sessions = [session(-5), session(-4), session(-1, id: other)]
        let result = AnalyticsEngine.compute(input(sessions, exercises: exercises), now: now, calendar: calendar)
        XCTAssertEqual(result.main[.deadlift], exerciseID)
        XCTAssertEqual(result.other, [other])
        let renamed = [AnalyticsEngine.ExerciseInput(id: exerciseID, name: "Romanian Deadlift", isBodyweight: false, equipment: nil, muscleGroup: "back"), exercises[1]]
        let next = AnalyticsEngine.compute(input(sessions, exercises: renamed), now: now, calendar: calendar)
        XCTAssertEqual(next.main[.deadlift], other)
        XCTAssertNotNil(next.lifts[exerciseID])
    }
    func testCatalogNamesMatchSlots() {
        for (name, expected) in [("Back Squat (BB)", AnalyticsEngine.Slot.squat), ("Deadlift (Conv)", .deadlift), ("Bench Press (Barbell)", .bench)] {
            XCTAssertEqual(AnalyticsEngine.slot(for: .init(id: UUID(), name: name, isBodyweight: false, equipment: "barbell", muscleGroup: "")), expected)
        }
        for name in ["Deadlift (Dumbbell)", "Smith Machine Squat", "Romanian DL", "Incline DB Press"] {
            XCTAssertNil(AnalyticsEngine.slot(for: .init(id: UUID(), name: name, isBodyweight: false, equipment: "barbell", muscleGroup: "")))
        }
    }
    func testOtherEquipmentTreatedAsUnknown() throws {
        let schema = Schema([Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self, Split.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let exercise = Exercise(displayName: "Squat")
        container.mainContext.insert(exercise)
        let snapshot = AnalyticsSnapshot.make(sessions: [], exercises: [exercise], templates: [], plannedDaysPerWeek: 0)
        XCTAssertNil(snapshot.exercises.first?.equipment)
        XCTAssertEqual(snapshot.exercises.first.flatMap(AnalyticsEngine.slot), .squat)
        XCTAssertEqual(exercise.equipment, .other)
    }
    func testZeroSessionCandidateNeverWins() {
        XCTAssertNil(compute([]).main[.bench])
        XCTAssertNil(compute([session(-140)]).main[.bench])
    }
    func testAliasesFromExerciseMatch() {
        let exercise = AnalyticsEngine.ExerciseInput(id: exerciseID, name: "Low-bar", isBodyweight: false, equipment: "barbell", muscleGroup: "quads", aliases: ["Squat"])
        XCTAssertEqual(AnalyticsEngine.slot(for: exercise), .squat)
        XCTAssertEqual(AnalyticsEngine.slotKey("Back Squat (BB) (BB)"), "back squat (bb)")
        XCTAssertEqual(AnalyticsEngine.normalizedName("Back Squat (BB)"), "back squat (bb)")
    }
    private func selectionFixture(_ rows: [(String, String, [Int])], pins: [UUID] = []) -> AnalyticsEngine.Output {
        let exercises = rows.enumerated().map { index, row in
            AnalyticsEngine.ExerciseInput(id: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, UInt8(index + 1))), name: row.0, isBodyweight: false, equipment: nil, muscleGroup: row.1)
        }
        let sessions = zip(rows, exercises).flatMap { row, exercise in row.2.map { session($0, id: exercise.id) } }
        var value = input(sessions, exercises: exercises)
        value.pinnedMainIDs = pins
        return AnalyticsEngine.compute(value, now: now, calendar: calendar)
    }
    func testAutomaticFillOrder() {
        let rows: [(String, String, [Int])] = [("Bench Press", "chest", [-1]), ("Overhead Press", "shoulders", Array(-8 ... -1)), ("Barbell Row", "back", Array(-6 ... -1)), ("Biceps Curl", "biceps", Array(-10 ... -1))]
        let result = selectionFixture(rows)
        XCTAssertEqual(result.mainIDs.compactMap { result.lifts[$0]?.exercise.name }, ["Bench Press", "Overhead Press", "Barbell Row"])
        XCTAssertEqual(result.mainSource, .automatic)
        XCTAssertEqual(Set(result.other).intersection(result.mainIDs), [])
        let lower = selectionFixture([("Leg Press", "quads", Array(-5 ... 0)), ("Lat Pulldown", "back", Array(-6 ... -1)), ("Pull-Up", "back", Array(-4 ... -1))])
        XCTAssertEqual(lower.mainIDs.compactMap { lower.lifts[$0]?.exercise.name }, ["Leg Press", "Lat Pulldown", "Pull-Up"])
        let isolation = selectionFixture([("Biceps Curl", "biceps", [-1]), ("Hanging Leg Raise", "core", [-2])])
        XCTAssertEqual(isolation.mainIDs.compactMap { isolation.lifts[$0]?.exercise.name }, ["Biceps Curl", "Hanging Leg Raise"])
        let duplicate = selectionFixture([("Squat", "quads", [-3, -2, -1]), ("Back Squat (BB)", "quads", [-5, -4, -3, -2, -1])])
        XCTAssertEqual(duplicate.mainIDs.compactMap { duplicate.lifts[$0]?.exercise.name }, ["Back Squat (BB)"])
        XCTAssertEqual(duplicate.other.compactMap { duplicate.lifts[$0]?.exercise.name }, ["Squat"])
        let old = selectionFixture([("Squat", "quads", [-140])])
        XCTAssertTrue(old.mainIDs.isEmpty)
        XCTAssertEqual(old.other.count, 1)
        let three = selectionFixture([("Squat", "quads", [-2]), ("Bench Press", "chest", [-3]), ("Deadlift", "back", [-1]), ("Row", "back", [-1])])
        XCTAssertEqual(three.mainIDs.compactMap { three.lifts[$0]?.exercise.name }, ["Squat", "Bench Press", "Deadlift"])
    }
    func testCustomPinsRespectedNoFillAndCleanedAndCapped() throws {
        let rows: [(String, String, [Int])] = [("Front Squat", "quads", [-1]), ("Bench Press", "chest", [-2]), ("Row", "back", [-3]), ("Curl", "biceps", [-4])]
        let initial = selectionFixture(rows)
        let byName = Dictionary(uniqueKeysWithValues: initial.lifts.values.map { ($0.exercise.name, $0.id) })
        let front = try XCTUnwrap(byName["Front Squat"]), bench = try XCTUnwrap(byName["Bench Press"])
        let custom = selectionFixture(rows, pins: [front, bench])
        XCTAssertEqual(custom.mainIDs, [front, bench])
        XCTAssertEqual(custom.mainSource, .custom)
        XCTAssertEqual(Set(custom.other).intersection(custom.mainIDs), [])
        let all = rows.compactMap { byName[$0.0] }
        let cleaned = selectionFixture(rows, pins: [UUID(), front, front] + Array(all.dropFirst()))
        XCTAssertEqual(cleaned.mainIDs, Array(all.prefix(3)))
        XCTAssertEqual(selectionFixture(rows, pins: [UUID()]).mainSource, .automatic)
        let raw = "bad,\(front),\(front),\(bench)"
        XCTAssertEqual(AnalyticsEngine.parsedMainIDs(raw), [front, bench])
        XCTAssertEqual(AnalyticsEngine.storedMainIDs([], automatic: initial.mainIDs), "")
        XCTAssertEqual(AnalyticsEngine.storedMainIDs(initial.mainIDs, automatic: initial.mainIDs), "")
    }
    func testPhoneShapeLegacyBenchIsShownWithoutChangingSavedMetadata() throws {
        let schema = Schema([Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self, Split.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let exercise = Exercise(displayName: "Bench Press")
        let workout = WorkoutSession(date: date(-1), templateId: templateID, isCompleted: true)
        context.insert(exercise); context.insert(workout)
        workout.setEntries = (0..<4).map { SetEntry(sessionId: workout.id, exerciseId: exercise.id, weight: 72.5, reps: 7, isCompleted: true, setIndex: $0) }
        try context.save()
        let snapshot = AnalyticsSnapshot.make(sessions: [workout], exercises: [exercise], templates: [], plannedDaysPerWeek: 0)
        let result = AnalyticsEngine.compute(snapshot, now: now, calendar: calendar)
        XCTAssertEqual(result.mainIDs, [exercise.id])
        XCTAssertEqual(result.lifts[exercise.id]?.latest?.weight, 72.5)
        XCTAssertEqual(result.lifts[exercise.id]?.latest?.reps, 7)
        XCTAssertEqual(exercise.equipmentRaw, "other")
        XCTAssertFalse(context.hasChanges)
    }
    func testMuscleSetsCountTheLastFourWeeksByMainMuscle() {
        let bench = UUID(), row = UUID(), curl = UUID(), unknown = UUID(), calf = UUID()
        let exercises: [AnalyticsEngine.ExerciseInput] = [
            .init(id: bench, name: "Bench Press", isBodyweight: false, equipment: "barbell", muscleGroup: "chest"),
            .init(id: row, name: "Barbell Row", isBodyweight: false, equipment: "barbell", muscleGroup: "back"),
            .init(id: curl, name: "Biceps Curl", isBodyweight: false, equipment: nil, muscleGroup: "biceps"),
            .init(id: unknown, name: "Wave 1", isBodyweight: false, equipment: nil, muscleGroup: ""),
            .init(id: calf, name: "Calf Raise", isBodyweight: true, equipment: nil, muscleGroup: "calves")
        ]
        func sets(_ id: UUID, _ count: Int, weight: Double = 60) -> [AnalyticsEngine.SetInput] {
            (0..<count).map { .init(exerciseID: id, weight: weight, reps: 8, index: $0) }
        }
        let skipped: [AnalyticsEngine.SetInput] = [.init(exerciseID: row, weight: 40, reps: 10, isWarmup: true), .init(exerciseID: row, weight: 60, reps: 8, isCompleted: false)]
        let sessions = [
            session(0, sets: sets(bench, 3) + sets(row, 2) + skipped),
            session(-27, sets: sets(bench, 2) + sets(unknown, 2) + sets(calf, 4, weight: 0)),
            // Day 28 is outside the window: curls show 0 sets instead of vanishing.
            session(-28, sets: sets(row, 5) + sets(curl, 3)),
            session(2, sets: sets(bench, 9))
        ]
        let result = AnalyticsEngine.compute(input(sessions, exercises: exercises), now: now, calendar: calendar)
        XCTAssertEqual(result.muscleSets.map(\.muscle), ["chest", "calves", "back", "biceps", ""])
        XCTAssertEqual(result.muscleSets.map(\.sets), [5, 4, 2, 0, 2])
        let stale = AnalyticsEngine.compute(input([session(-35, sets: sets(unknown, 2))], exercises: exercises), now: now, calendar: calendar)
        XCTAssertEqual(stale.muscleSets, [])
        let old = AnalyticsEngine.compute(input([session(-120, sets: sets(bench, 2))], exercises: exercises), now: now, calendar: calendar)
        XCTAssertEqual(old.muscleSets, [])
    }
    func testOnboardingExercisesUseCatalogMuscleWithoutChangingSavedMetadata() throws {
        let schema = Schema([Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self, Split.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        // Onboarding saves names only, so every muscle is the default Full Body.
        let rows: [(String, Int)] = [("Bicep Curls", 10), ("Overhead Press", 8), ("Barbell Row", 6), ("Leg Press", 5), ("Wave 1", 4)]
        let exercises = rows.map { Exercise(displayName: $0.0) }
        var workouts: [WorkoutSession] = []
        for (exercise, row) in zip(exercises, rows) {
            context.insert(exercise)
            for offset in 1...row.1 {
                let workout = WorkoutSession(date: date(-offset), templateId: templateID, isCompleted: true)
                context.insert(workout)
                workout.setEntries = [SetEntry(sessionId: workout.id, exerciseId: exercise.id, weight: 40, reps: 8, isCompleted: true)]
                workouts.append(workout)
            }
        }
        try context.save()
        let snapshot = AnalyticsSnapshot.make(sessions: workouts, exercises: exercises, templates: [], plannedDaysPerWeek: 0)
        XCTAssertEqual(snapshot.exercises.map(\.muscleGroup), ["biceps", "shoulders", "back", "quads", ""])
        let result = AnalyticsEngine.compute(snapshot, now: now, calendar: calendar)
        // Curls are isolation work, so compound lifts fill the main slots first.
        XCTAssertEqual(result.mainIDs.compactMap { result.lifts[$0]?.exercise.name }, ["Overhead Press", "Barbell Row", "Leg Press"])
        XCTAssertEqual(exercises.map(\.muscleGroupRaw), Array(repeating: "fullBody", count: rows.count))
        XCTAssertFalse(context.hasChanges)
    }
    func testValidityWeeklyGapsRecordsAndMixedBodyweight() {
        let sets: [AnalyticsEngine.SetInput] = [.init(exerciseID: exerciseID, weight: 100, reps: 20, isWarmup: true), .init(exerciseID: exerciseID, weight: 200, reps: 5, isCompleted: false), .init(exerciseID: exerciseID, weight: 0, reps: 50), .init(exerciseID: exerciseID, weight: 82.5, reps: 3)]
        let result = compute([session(-100, weight: 82.5, reps: 3), session(-14, weight: 81.25), session(0, sets: sets)])
        let lift = result.lifts[exerciseID]
        XCTAssertEqual(lift?.best?.date, date(-100))
        XCTAssertEqual(lift?.weeks.count, 2)
        XCTAssertEqual(lift?.latest?.weight, 82.5)
        XCTAssertEqual(lift?.bodyweight, false)
        XCTAssertEqual(compute([session(-100)]).lifts[exerciseID]?.weeks.count, 0)
    }
    func testTimeZoneChangesRebucketLocalDays() {
        let value = session(0)
        var zone = calendar; zone.timeZone = TimeZone(secondsFromGMT: 14 * 3600)!
        let result = AnalyticsEngine.compute(input([value]), now: now, calendar: zone)
        XCTAssertEqual(result.today, zone.startOfDay(for: now))
        XCTAssertEqual(result.summary?.sessions, 1)
    }
    func testSwiftDataSnapshotDoesNotWrite() throws {
        let schema = Schema([Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self, Split.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let exercise = Exercise(id: exerciseID, displayName: "Bench Press", equipment: .barbell)
        let workout = WorkoutSession(date: now, templateId: templateID, isCompleted: true)
        context.insert(exercise); context.insert(workout)
        workout.setEntries = [SetEntry(sessionId: workout.id, exerciseId: exerciseID, weight: 81.25, reps: 5, isCompleted: true)]
        try context.save()
        let snapshot = AnalyticsSnapshot.make(sessions: [workout], exercises: [exercise], templates: [], plannedDaysPerWeek: 0)
        XCTAssertEqual(AnalyticsEngine.compute(snapshot, now: now, calendar: calendar).lifts[exerciseID]?.latest?.weight, 81.25)
        XCTAssertFalse(context.hasChanges)
    }
    func testPersistenceLiveCountsAndFlipFlopping() {
        let history = [session(-50)] + (-27 ... -22).map { session($0) }
        XCTAssertEqual(compute(history, at: 1).summary?.status, .steady)
        XCTAssertEqual(compute(history, at: 1).summary?.sessions, 5)
        XCTAssertEqual(compute(history, at: 2).summary?.status, .steady)
        XCTAssertEqual(compute(history, at: 3).summary?.status, .fewer)
        let flips = history + [session(2), session(2), session(4), session(4)]
        for offset in 1...5 { XCTAssertEqual(compute(flips, at: offset).summary?.status, .steady) }
    }
    func testWeightedBodyweightRetainsRecentUnloadedSession() {
        let value = compute([session(-35), session(-1, weight: 0, reps: 12)]).lifts[exerciseID]
        XCTAssertEqual(value?.sessions.count, 2)
        XCTAssertEqual(value?.latest?.weight, 0)
        XCTAssertEqual(value?.best?.weight, 80)
        XCTAssertEqual(value?.bodyweight, false)
        XCTAssertEqual(WorkoutTargetFormatter.analyticsPerformance(value!.latest!, bodyweight: false, unit: "kg"), "BW × 12")
    }
    func testChartDomainGapsAndAcceptedTargetFromLatestContainingRoutine() {
        let otherID = UUID(), secondTemplate = UUID()
        let target = AnalyticsEngine.Target(weight: 82.5, reps: 5, templateName: "Other routine")
        let templates: [AnalyticsEngine.TemplateInput] = [.init(id: templateID, name: "Original", exerciseIDs: [exerciseID], targets: [:]), .init(id: secondTemplate, name: "Other routine", exerciseIDs: [exerciseID, otherID], targets: [exerciseID: target])]
        let sessions = [session(-7), AnalyticsEngine.SessionInput(id: UUID(), date: now, templateID: secondTemplate, sets: [.init(exerciseID: otherID, weight: 40, reps: 5)])]
        let original = input(sessions)
        let result = AnalyticsEngine.compute(.init(exercises: original.exercises, sessions: sessions, templates: templates, plannedDaysPerWeek: 3), now: now, calendar: calendar)
        let lift = result.lifts[exerciseID]
        XCTAssertEqual(lift?.target, target)
        let chart = AnalyticsEngine.chart(lift: lift, weekStarts: result.weekStarts, metric: .weight, unit: "lb")
        XCTAssertEqual(chart.points.count, 1)
        XCTAssertEqual(chart.xLabels.count, 4)
        XCTAssertTrue(chart.yDomain.contains(chart.points[0].value))
        XCTAssertEqual(AnalyticsEngine.chart(lift: nil, weekStarts: result.weekStarts, metric: .weight, unit: "kg").points.count, 0)
    }
    func testEpsilonDoesNotCompoundAcrossSessionsOrDayBuckets() {
        let values = [session(-1, weight: 80, reps: 5), session(-1, weight: 79.995, reps: 6), session(0, weight: 80.007, reps: 1)]
        let result = compute(values).lifts[exerciseID]
        XCTAssertEqual(result?.best?.reps, 5)
        XCTAssertEqual(result?.best?.weight, 80)
        XCTAssertEqual(result?.currentWindowBest, result?.best)
        XCTAssertEqual(compute(Array(values.reversed())).lifts[exerciseID]?.best, result?.best)
    }
    func testFiveYearPerformance() {
        let exercises = (0..<8).map { AnalyticsEngine.ExerciseInput(id: UUID(), name: "Exercise \($0)", isBodyweight: false, equipment: nil, muscleGroup: "back") }
        let sessions = (0..<1040).map { index in session(-index * 7 / 4, sets: exercises.flatMap { exercise in (0..<3).map { .init(exerciseID: exercise.id, weight: Double(40 + index % 20), reps: 8, index: $0) } }) }
        let values = input(sessions, planned: 4, exercises: exercises)
        measure { _ = AnalyticsEngine.compute(values, now: now, calendar: calendar) }
    }
}
