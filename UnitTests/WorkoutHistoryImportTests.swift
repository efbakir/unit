import SwiftData
import XCTest
@testable import Unit

/// Fixtures copy the headers and row shapes of real exports (checked
/// 2026-10-24): Strong 6.2.3+ (semicolons, quoted, "Weight (kg)"), Strong's
/// older comma layout, Strong's per-row unit layout, and Hevy in kg and lbs.
@MainActor
final class WorkoutHistoryImportTests: XCTestCase {
    private enum Failure: Error { case disk }

    private let utc = TimeZone(identifier: "UTC")!

    private lazy var container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Split.self, Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("In-memory store failed: \(error)")
        }
    }()
    private var context: ModelContext { container.mainContext }
    private lazy var defaults: UserDefaults = {
        let name = "WorkoutHistoryImportTests-\(UUID().uuidString)"
        addTeardownBlock { UserDefaults.standard.removePersistentDomain(forName: name) }
        return UserDefaults(suiteName: name)!
    }()

    private let strongCurrent = """
    "Workout #";"Date";"Workout Name";"Duration (sec)";"Exercise Name";"Set Order";"Weight (kg)";"Reps";"RPE";"Distance (meters)";"Seconds";"Notes";"Workout Notes"
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Bench Press (Barbell)";"W";"40.0";"8";"";"";"";"";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Bench Press (Barbell)";"1";"61.23492";"5";"8";"";"";"felt fast";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Bench Press (Barbell)";"2";"61.23492";"5";"";"";"";"";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Bench Press (Barbell)";"Rest Timer";"";"";"";"";"120.0";"";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Deadlift (Barbell)";"Note";"";"";"";"";"";"1rm test";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Plank";"1";"";"";"";"";"60.0";"";""
    "1";"2026-03-02 07:05:00";"Upper A";"3900";"Butterfly Reverse (Maschine, Kabel)";"1";"5,5";"9";"";"";"";"";""
    "2";"2026-03-04 18:00:00";"Lower";"3600";"Squat (Barbell)";"D";"80.0";"7";"";"";"";"";""
    """

    private let strongComma = """
    Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
    2020-12-30 18:51:52,"Evening Workout",2h 38m,"Snatch (Barbell)",1,40.0,3,0,0,"","",
    2020-12-30 18:51:52,"Evening Workout",2h 38m,"Snatch (Barbell)",2,40.0,3,0,0,,,
    2021-01-04 18:33:57,"Evening Workout",2h 35m,"Pull Up",1,0,8,0,0,"","",
    """

    private let strongPerRowUnit = """
    Date;Workout Name;Exercise Name;Set Order;Weight;Weight Unit;Reps;RPE;Distance;Distance Unit;Seconds;Notes;Workout Notes;Workout Duration
    2019-05-01 08:00:00;Push;Bench Press (Barbell);1;135;lbs;5;;;;;;;58m
    2019-05-01 08:00:00;Push;Bench Press (Barbell);2;60;kg;5;;;;;;;58m
    """

    private let hevyPounds = """
    "title","start_time","end_time","description","exercise_title","superset_id","exercise_notes","set_index","set_type","weight_lbs","reps","distance_miles","duration_seconds","rpe"
    "Thursday- Upper Reps","28 Mar 2025, 17:29","28 Mar 2025, 18:52","","Band Pullaparts",,"",0,"normal",,20,,0,
    "Thursday- Upper Reps","28 Mar 2025, 17:29","28 Mar 2025, 18:52","","Bench Press (Barbell)",,"Pause 1s",0,"warmup",95,10,,,
    "Thursday- Upper Reps","28 Mar 2025, 17:29","28 Mar 2025, 18:52","","Bench Press (Barbell)",,"Pause 1s",1,"normal",185,8,,,8
    "Thursday- Upper Reps","28 Mar 2025, 17:29","28 Mar 2025, 18:52","","Plank",,"",0,"normal",,,,60,
    "Thursday- Upper Reps","28 Mar 2025, 17:29","28 Mar 2025, 18:52","","Bench Press (Barbell)",,"Pause 1s",2,"failure",185,6,,,
    """

    private let hevyKilograms = """
    title,start_time,end_time,description,exercise_title,superset_id,exercise_notes,set_index,set_type,weight_kg,reps,distance_km,duration_seconds,rpe
    Push A,"1 Jan 2025, 08:00","1 Jan 2025, 09:00",,Bench Press (Barbell),,,0,normal,60,8,,,
    Push A,"1 Jan 2025, 08:00","1 Jan 2025, 09:00",,Bench Press (Barbell),,,1,dropset,50,10,,,
    """

    // MARK: - Parsing

    func testStrongCurrentLayoutReadsKilogramsAndSkipsNonSetRows() throws {
        let file = try WorkoutHistoryParser.parse(strongCurrent, timeZone: utc)

        XCTAssertEqual(file.source, .strong)
        XCTAssertFalse(file.needsWeightUnit)
        XCTAssertEqual(file.workouts.map(\.title), ["Upper A", "Lower"])
        XCTAssertEqual(file.skippedRowCount, 1, "The timed plank row; rest timer and note rows are not sets")
        let upper = file.workouts[0]
        XCTAssertEqual(upper.date, date(2026, 3, 2, 7, 5))
        XCTAssertEqual(upper.exercises.map(\.name), ["Bench Press (Barbell)", "Butterfly Reverse (Maschine, Kabel)"])
        let bench = upper.exercises[0].sets
        XCTAssertEqual(bench.map(\.isWarmup), [true, false, false])
        XCTAssertEqual(bench.map(\.reps), [8, 5, 5])
        XCTAssertEqual(bench[1].weightKg(assuming: .lb), 61.23492, accuracy: 0.000_1)
        XCTAssertEqual(bench[1].rpe, 8)
        XCTAssertEqual(bench[1].note, "felt fast")
        XCTAssertEqual(upper.exercises[1].sets.first?.weight, 5.5, "Decimal comma in a semicolon file")
        XCTAssertEqual(file.workouts[1].exercises.first?.sets.first?.isWarmup, false, "A drop set counts as a normal set")
    }

    func testStrongCommaLayoutHasNoUnitSoTheLifterPicksOne() throws {
        let file = try WorkoutHistoryParser.parse(strongComma, timeZone: utc)

        XCTAssertTrue(file.needsWeightUnit)
        XCTAssertEqual(file.workouts.count, 2)
        let snatch = try XCTUnwrap(file.workouts.first?.exercises.first?.sets.first)
        XCTAssertNil(snatch.unit)
        XCTAssertEqual(snatch.weightKg(assuming: .kg), 40)
        XCTAssertEqual(snatch.weightKg(assuming: .lb), 40 / 2.20462, accuracy: 0.000_1)
        XCTAssertEqual(file.workouts.last?.exercises.first?.sets.first?.weight, 0, "Bodyweight")
    }

    func testStrongPerRowUnitsConvertEachRow() throws {
        let file = try WorkoutHistoryParser.parse(strongPerRowUnit, timeZone: utc)

        XCTAssertFalse(file.needsWeightUnit)
        let sets = try XCTUnwrap(file.workouts.first?.exercises.first?.sets)
        XCTAssertEqual(sets[0].weightKg(assuming: .kg), 135 / 2.20462, accuracy: 0.000_1)
        XCTAssertEqual(sets[1].weightKg(assuming: .lb), 60)
    }

    func testHevyPoundsMergesRepeatedBlocksKeepsWarmupsAndNotesOnce() throws {
        let file = try WorkoutHistoryParser.parse(hevyPounds, timeZone: utc)

        XCTAssertEqual(file.source, .hevy)
        XCTAssertFalse(file.needsWeightUnit)
        XCTAssertEqual(file.skippedRowCount, 1, "The timed plank")
        let workout = try XCTUnwrap(file.workouts.first)
        XCTAssertEqual(workout.title, "Thursday- Upper Reps")
        XCTAssertEqual(workout.date, date(2025, 3, 28, 17, 29))
        XCTAssertEqual(workout.exercises.map(\.name), ["Band Pullaparts", "Bench Press (Barbell)"])
        let bench = workout.exercises[1].sets
        XCTAssertEqual(bench.map(\.isWarmup), [true, false, false])
        XCTAssertEqual(bench.map(\.reps), [10, 8, 6])
        XCTAssertEqual(bench[1].weightKg(assuming: .kg), 185 / 2.20462, accuracy: 0.000_1)
        XCTAssertEqual(bench[1].rpe, 8)
        XCTAssertEqual(bench.map(\.note), ["Pause 1s", "", ""])
        XCTAssertEqual(workout.exercises[0].sets.first?.weight, 0)
    }

    func testHevyKilograms() throws {
        let file = try WorkoutHistoryParser.parse(hevyKilograms, timeZone: utc)
        let sets = try XCTUnwrap(file.workouts.first?.exercises.first?.sets)
        XCTAssertEqual(sets.map { $0.weightKg(assuming: .lb) }, [60, 50])
    }

    func testUnknownAndEmptyFilesAreRefused() {
        XCTAssertThrowsError(try WorkoutHistoryParser.parse("Name,Value\nBench,60")) { error in
            XCTAssertEqual(error as? WorkoutHistoryImportError, .unknownFormat)
        }
        XCTAssertThrowsError(try WorkoutHistoryParser.parse("")) { error in
            XCTAssertEqual(error as? WorkoutHistoryImportError, .unknownFormat)
        }
        let restOnly = """
        Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE
        2020-12-30 18:51:52,"Evening",1h,"Plank",Rest Timer,,,0,90,,,
        """
        XCTAssertThrowsError(try WorkoutHistoryParser.parse(restOnly)) { error in
            XCTAssertEqual(error as? WorkoutHistoryImportError, .noWorkouts)
        }
    }

    func testUnitsOwnExportReadsBack() throws {
        let rows = [
            WorkoutCSVRow(date: date(2026, 10, 1, 9, 0), workoutName: "Push, heavy", exerciseName: "Bench Press",
                          setOrder: "W", weightKg: 40, reps: 8, note: "", rpe: 0),
            WorkoutCSVRow(date: date(2026, 10, 1, 9, 0), workoutName: "Push, heavy", exerciseName: "Bench Press",
                          setOrder: "1", weightKg: 62.5, reps: 5, note: "grip \"wide\"", rpe: 8)
        ]
        let text = WorkoutCSVExport.csv(rows, unitSystem: "kg", timeZone: utc)

        let file = try WorkoutHistoryParser.parse(text, timeZone: utc)

        XCTAssertTrue(file.needsWeightUnit)
        let workout = try XCTUnwrap(file.workouts.first)
        XCTAssertEqual(workout.title, "Push, heavy")
        XCTAssertEqual(workout.date, rows[0].date)
        let sets = try XCTUnwrap(workout.exercises.first?.sets)
        XCTAssertEqual(sets.map(\.isWarmup), [true, false])
        XCTAssertEqual(sets.map { $0.weightKg(assuming: .kg) }, [40, 62.5])
        XCTAssertEqual(sets[1].note, "grip \"wide\"")
        XCTAssertEqual(sets[1].rpe, 8)
    }

    // MARK: - Plan and import

    func testPlanMatchesYourExercisesThroughTheCatalogAndListsNewOnes() throws {
        context.insert(Exercise(displayName: "Bench Press"))
        let file = try WorkoutHistoryParser.parse(strongCurrent, timeZone: utc)

        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: try context.fetch(FetchDescriptor<Exercise>()))

        XCTAssertEqual(plan.matchedExerciseNames, ["Bench Press (Barbell)"])
        XCTAssertEqual(plan.newExerciseNames, ["Butterfly Reverse (Maschine, Kabel)", "Squat (Barbell)"])
        XCTAssertEqual(plan.workouts.count, 2)
        XCTAssertEqual(plan.setCount, 5)
        XCTAssertEqual(plan.duplicateCount, 0)
    }

    func testImportWritesFinishedWorkoutsOnHiddenRoutines() throws {
        let bench = Exercise(displayName: "Bench Press")
        context.insert(bench)
        try context.save()
        let file = try WorkoutHistoryParser.parse(strongCurrent, timeZone: utc)
        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [bench])

        let batch = try WorkoutHistoryImporter.importHistory(plan, weightUnit: .kg, into: context, defaults: defaults)

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>(sortBy: [SortDescriptor(\.date)]))
        XCTAssertEqual(sessions.count, 2)
        XCTAssertTrue(sessions.allSatisfy(\.isCompleted))
        XCTAssertTrue(sessions.allSatisfy { $0.progressionRecordsByExerciseId.isEmpty })
        let templates = try context.fetch(FetchDescriptor<DayTemplate>())
        XCTAssertEqual(Set(templates.map(\.name)), ["Upper A", "Lower"])
        XCTAssertTrue(templates.allSatisfy { $0.splitId == nil }, "Hidden from Programs and Today")
        let benchSets = try XCTUnwrap(sessions.first?.setEntries.filter { $0.exerciseId == bench.id }.sorted { $0.setIndex < $1.setIndex })
        XCTAssertEqual(benchSets.map(\.setIndex), [0, 1, 2])
        XCTAssertEqual(benchSets.map(\.isWarmup), [true, false, false])
        XCTAssertEqual(benchSets[1].rpe, 8)
        XCTAssertEqual(benchSets[1].note, "felt fast")
        let squat = try XCTUnwrap(try context.fetch(FetchDescriptor<Exercise>()).first { $0.displayName == "Back Squat (BB)" })
        XCTAssertEqual(squat.equipmentRaw, Equipment.barbell.rawValue, "Created from Unit's catalog")
        XCTAssertEqual(batch.sessionIDs.count, 2)
        XCTAssertEqual(WorkoutHistoryImporter.lastBatch(defaults: defaults), batch)
        // Imported work feeds "Last time" like any finished workout.
        let lastTime = SetEntry.latestValidWorkingSets(for: bench.id, in: sessions)
        XCTAssertEqual(lastTime.map(\.reps), [5, 5])
    }

    func testPoundsChoiceConvertsAFileWithoutUnits() throws {
        let file = try WorkoutHistoryParser.parse(strongComma, timeZone: utc)
        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [])

        try WorkoutHistoryImporter.importHistory(plan, weightUnit: .lb, into: context, defaults: defaults)

        let weights = try context.fetch(FetchDescriptor<SetEntry>()).map(\.weight).sorted()
        XCTAssertEqual(weights[0], 0)
        XCTAssertEqual(weights[1], 40 / 2.20462, accuracy: 0.000_1)
        let pullUp = try XCTUnwrap(try context.fetch(FetchDescriptor<Exercise>()).first { $0.displayName == "Pull-Up" })
        XCTAssertTrue(pullUp.isBodyweight)
    }

    func testImportingTheSameFileTwiceAddsNothing() throws {
        let file = try WorkoutHistoryParser.parse(hevyPounds, timeZone: utc)
        let first = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [])
        try WorkoutHistoryImporter.importHistory(first, weightUnit: .kg, into: context, defaults: defaults)

        let second = WorkoutHistoryImporter.plan(
            for: file,
            existingSessions: try context.fetch(FetchDescriptor<WorkoutSession>()),
            exercises: try context.fetch(FetchDescriptor<Exercise>())
        )

        XCTAssertTrue(second.workouts.isEmpty)
        XCTAssertEqual(second.duplicateCount, 1)
        XCTAssertEqual(second.newExerciseNames, [])
    }

    func testUndoRemovesOnlyWhatTheImportAdded() throws {
        let file = try WorkoutHistoryParser.parse(strongCurrent, timeZone: utc)
        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [])
        let batch = try WorkoutHistoryImporter.importHistory(plan, weightUnit: .kg, into: context, defaults: defaults)
        // A workout logged in Unit afterwards uses an exercise the import created.
        let squat = try XCTUnwrap(try context.fetch(FetchDescriptor<Exercise>()).first { $0.displayName == "Back Squat (BB)" })
        let routine = DayTemplate(name: "Legs", splitId: UUID(), orderedExerciseIds: [squat.id])
        let logged = WorkoutSession(date: Date(), templateId: routine.id, isCompleted: true)
        context.insert(routine)
        context.insert(logged)
        let entry = SetEntry(sessionId: logged.id, exerciseId: squat.id, weight: 100, reps: 5, isCompleted: true)
        entry.session = logged
        context.insert(entry)
        try context.save()

        try WorkoutHistoryImporter.undo(batch, in: context, defaults: defaults)

        let sessions = try context.fetch(FetchDescriptor<WorkoutSession>())
        XCTAssertEqual(sessions.map(\.id), [logged.id])
        XCTAssertEqual(try context.fetch(FetchDescriptor<DayTemplate>()).map(\.name), ["Legs"])
        let names = Set(try context.fetch(FetchDescriptor<Exercise>()).map(\.displayName))
        XCTAssertEqual(names, ["Back Squat (BB)"], "Kept because a Unit workout uses it; the others go")
        XCTAssertNil(WorkoutHistoryImporter.lastBatch(defaults: defaults))
    }

    func testFailedSaveImportsNothing() throws {
        let file = try WorkoutHistoryParser.parse(hevyKilograms, timeZone: utc)
        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [])

        XCTAssertThrowsError(try WorkoutHistoryImporter.importHistory(
            plan,
            weightUnit: .kg,
            into: context,
            defaults: defaults,
            save: { _ in throw Failure.disk }
        ))

        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSession>()), 0)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 0)
        XCTAssertNil(WorkoutHistoryImporter.lastBatch(defaults: defaults))
    }

    // MARK: - Size

    /// About three years of Strong history: 1,000 workouts, 50,000 sets.
    func testFiftyThousandSetsParseAndImport() throws {
        var lines = [WorkoutCSVExport.header]
        lines.reserveCapacity(50_001)
        let exercises = ["Bench Press (Barbell)", "Squat (Barbell)", "Deadlift (Barbell)", "Pull Up", "Lateral Raise (Dumbbell)"]
        for workout in 0..<1_000 {
            let day = String(format: "2023-%02d-%02d %02d:00:00", workout / 100 % 12 + 1, workout % 28 + 1, workout % 24)
            for exercise in exercises {
                for set in 1...10 {
                    lines.append("\(day),\"Day \(workout)\",1h,\"\(exercise)\",\(set),60,8,0,0,\"\",\"\",")
                }
            }
        }
        let text = lines.joined(separator: "\n")

        let parseStart = Date()
        let file = try WorkoutHistoryParser.parse(text, timeZone: utc)
        let parseSeconds = Date().timeIntervalSince(parseStart)
        let plan = WorkoutHistoryImporter.plan(for: file, existingSessions: [], exercises: [])
        let importStart = Date()
        try WorkoutHistoryImporter.importHistory(plan, weightUnit: .kg, into: context, defaults: defaults)
        let importSeconds = Date().timeIntervalSince(importStart)

        XCTAssertEqual(file.workouts.count, 1_000)
        XCTAssertEqual(plan.setCount, 50_000)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 50_000)
        print("Import timing: parse \(parseSeconds) s, import \(importSeconds) s")
        XCTAssertLessThan(parseSeconds, 10)
        XCTAssertLessThan(importSeconds, 60)
    }

    // MARK: - Helpers

    private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = utc
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
