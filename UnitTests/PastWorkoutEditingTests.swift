import SwiftData
import XCTest
@testable import Unit

/// Edit workout corrections: saved sets change, stored copies follow, a next
/// target the lifter chose never moves, and one Finish saved by itself does.
@MainActor
final class PastWorkoutEditingTests: XCTestCase {
    private enum Failure: Error { case disk }

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

    // MARK: - Sets

    func testEditingASetSavesValuesAndPRTagsFollow() throws {
        let fixture = try makeRoutine()
        let older = try finishedWorkout(fixture, daysAgo: 7, sets: [(60, 8), (60, 8), (60, 8)])
        let newer = try finishedWorkout(fixture, daysAgo: 0, sets: [(65, 8), (60, 8), (60, 8)])
        let heavy = try XCTUnwrap(newer.setEntries.first { $0.weight == 65 })
        XCTAssertTrue(PRHistory.prSetEntryIDs(in: [older, newer]).contains(heavy.id))

        XCTAssertTrue(PastWorkoutEditor.update(heavy, weightKg: 55, reps: 8, in: newer, editor(fixture)))

        XCTAssertEqual(heavy.weight, 55)
        XCTAssertFalse(PRHistory.prSetEntryIDs(in: [older, newer]).contains(heavy.id))
    }

    func testDeletingASetLeavesTheWorkoutAndUndoPutsTheSameSetBack() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 8), (60, 8), (60, 7)])
        let last = try XCTUnwrap(workout.setEntries.first { $0.reps == 7 })
        let lastID = last.id

        let snapshot = try XCTUnwrap(PastWorkoutEditor.delete(last, from: workout, editor(fixture)))

        XCTAssertEqual(workout.setEntries.count, 2)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 2)
        XCTAssertTrue(PastWorkoutEditor.restore(snapshot, in: workout, editor(fixture)))
        XCTAssertEqual(workout.setEntries.count, 3)
        XCTAssertEqual(workout.setEntries.first { $0.id == lastID }?.reps, 7)
        XCTAssertFalse(PastWorkoutEditor.restore(snapshot, in: workout, editor(fixture)), "Undo applies once")
    }

    func testInvalidValuesAreRefused() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 8), (60, 8), (60, 8)])
        let set = try XCTUnwrap(workout.setEntries.first)

        XCTAssertFalse(PastWorkoutEditor.update(set, weightKg: -5, reps: 8, in: workout, editor(fixture)))
        XCTAssertFalse(PastWorkoutEditor.update(set, weightKg: 60, reps: 0, in: workout, editor(fixture)))
        XCTAssertFalse(PastWorkoutEditor.update(set, weightKg: .infinity, reps: 8, in: workout, editor(fixture)))
        XCTAssertEqual(set.weight, 60)
        XCTAssertEqual(set.reps, 8)
    }

    // MARK: - "Next time" evidence

    func testUnsavedSuggestionOnNewestWorkoutIsRecalculated() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        XCTAssertEqual(workout.progressionRecord(for: fixture.bench.id)?.recommendationReason, .allSetsReachedTop)
        XCTAssertEqual(workout.progressionRecord(for: fixture.bench.id)?.suggestedTarget, DoubleProgressionTarget(weightKg: 62.5, reps: 8))
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(third, weightKg: 60, reps: 9, in: workout, editor(fixture)))

        let record = try XCTUnwrap(workout.progressionRecord(for: fixture.bench.id))
        XCTAssertEqual(record.recommendationReason, .addARep)
        XCTAssertEqual(record.suggestedTarget, DoubleProgressionTarget(weightKg: 60, reps: 9))
        XCTAssertEqual(record.completedSets.map(\.reps), [10, 10, 9])
        XCTAssertNil(record.acceptedTarget)
    }

    func testLifterDecisionKeepsItsTargetAndShowsTheCorrectedSets() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        let edited = DoubleProgressionTarget(weightKg: 61.25, reps: 9)
        XCTAssertTrue(workout.saveProgressionDecision(edited, action: .edited, reason: .allSetsReachedTop,
                                                      for: fixture.bench.id, template: fixture.template))
        try context.save()
        let savedState = fixture.template.progressionState(for: fixture.bench.id)
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(third, weightKg: 60, reps: 9, in: workout, editor(fixture)))

        let record = try XCTUnwrap(workout.progressionRecord(for: fixture.bench.id))
        XCTAssertEqual(record.acceptedTarget, edited)
        XCTAssertEqual(record.decisionAction, .edited)
        XCTAssertEqual(record.completedSets.map(\.reps), [10, 10, 9])
        XCTAssertEqual(fixture.template.progressionState(for: fixture.bench.id), savedState)
    }

    func testTargetSavedAtFinishFollowsTheCorrectedSets() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        XCTAssertTrue(workout.applySuggestedTargets(to: fixture.template))
        try context.save()
        XCTAssertEqual(fixture.template.progressionState(for: fixture.bench.id)?.acceptedTarget,
                       DoubleProgressionTarget(weightKg: 62.5, reps: 8))
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(third, weightKg: 60, reps: 9, in: workout, editor(fixture)))

        let corrected = DoubleProgressionTarget(weightKg: 60, reps: 9)
        let record = try XCTUnwrap(workout.progressionRecord(for: fixture.bench.id))
        XCTAssertEqual(record.suggestedTarget, corrected)
        XCTAssertEqual(record.acceptedTarget, corrected)
        XCTAssertEqual(record.decisionAction, .usedSuggestion)
        XCTAssertEqual(record.previousTarget, DoubleProgressionTarget(weightKg: 60, reps: 8))
        let state = fixture.template.progressionState(for: fixture.bench.id)
        XCTAssertEqual(state?.acceptedTarget, corrected)
        XCTAssertEqual(state?.sourceWorkoutSessionID, workout.id)
        XCTAssertEqual(fixture.template.plannedWeight(for: fixture.bench.id), 60)
        XCTAssertEqual(fixture.template.plannedReps(for: fixture.bench.id), 9)
    }

    func testTargetSavedAtFinishIsDroppedWhenCorrectedSetsGiveNoSuggestion() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        XCTAssertTrue(workout.applySuggestedTargets(to: fixture.template))
        try context.save()
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(third, weightKg: 65, reps: 10, in: workout, editor(fixture)))

        let record = try XCTUnwrap(workout.progressionRecord(for: fixture.bench.id))
        XCTAssertEqual(record.unavailableReason, .mixedWorkingSetWeights)
        XCTAssertNil(record.acceptedTarget)
        XCTAssertNil(fixture.template.progressionState(for: fixture.bench.id)?.acceptedTarget,
                     "The 62.5 kg target came from the wrong set, so it must not prefill")
        XCTAssertEqual(fixture.template.progressionState(for: fixture.bench.id)?.currentAcceptedTargetReps, 8)
    }

    func testTargetSavedAtFinishOnAnOlderWorkoutStaysPut() throws {
        let fixture = try makeRoutine()
        let older = try finishedWorkout(fixture, daysAgo: 7, sets: [(60, 10), (60, 10), (60, 10)])
        XCTAssertTrue(older.applySuggestedTargets(to: fixture.template))
        let newer = try finishedWorkout(fixture, daysAgo: 0, sets: [(62.5, 8), (62.5, 8), (62.5, 8)])
        XCTAssertTrue(newer.applySuggestedTargets(to: fixture.template))
        try context.save()
        let stateBefore = fixture.template.progressionState(for: fixture.bench.id)
        let set = try XCTUnwrap(older.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(set, weightKg: 60, reps: 9, in: older, editor(fixture)))

        XCTAssertEqual(older.progressionRecord(for: fixture.bench.id)?.acceptedTarget,
                       DoubleProgressionTarget(weightKg: 62.5, reps: 8))
        XCTAssertEqual(fixture.template.progressionState(for: fixture.bench.id), stateBefore)
    }

    func testUnsavedSuggestionOnAnOlderWorkoutIsRemoved() throws {
        let fixture = try makeRoutine()
        let older = try finishedWorkout(fixture, daysAgo: 7, sets: [(60, 10), (60, 10), (60, 10)])
        _ = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 9), (60, 9), (60, 9)])
        XCTAssertNotNil(older.progressionRecord(for: fixture.bench.id))
        let set = try XCTUnwrap(older.setEntries.first)

        XCTAssertTrue(PastWorkoutEditor.update(set, weightKg: 60, reps: 8, in: older, editor(fixture)))

        XCTAssertNil(older.progressionRecord(for: fixture.bench.id))
    }

    func testRecaptureOnlyTouchesTheEditedExercise() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        // A second routine exercise that had no rule at Finish gets one later.
        let row = Exercise(displayName: "Barbell Row")
        context.insert(row)
        fixture.template.orderedExerciseIds.append(row.id)
        fixture.template.setPlannedSets(3, for: row.id)
        fixture.template.setProgressionState(Self.progressionState(), for: row.id)
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })

        XCTAssertTrue(PastWorkoutEditor.update(third, weightKg: 60, reps: 9, in: workout, editor(fixture, extraExercises: [row])))

        XCTAssertNil(workout.progressionRecord(for: row.id))
    }

    // MARK: - Workouts

    func testDeletingTheNewestWorkoutRestoresTheRoutineLastDoneDate() throws {
        let fixture = try makeRoutine()
        let older = try finishedWorkout(fixture, daysAgo: 7, sets: [(60, 8), (60, 8), (60, 8)])
        let newer = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 8), (60, 8), (60, 8)])
        fixture.template.lastPerformedDate = newer.date

        XCTAssertTrue(PastWorkoutEditor.deleteWorkout(newer, editor(fixture)))

        XCTAssertEqual(fixture.template.lastPerformedDate, older.date)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<WorkoutSession>()), 1)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 3, "Its sets go with it")
    }

    func testDeletingAnOlderWorkoutKeepsTheLastDoneDate() throws {
        let fixture = try makeRoutine()
        let older = try finishedWorkout(fixture, daysAgo: 7, sets: [(60, 8), (60, 8), (60, 8)])
        let newer = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 8), (60, 8), (60, 8)])
        fixture.template.lastPerformedDate = newer.date

        XCTAssertTrue(PastWorkoutEditor.deleteWorkout(older, editor(fixture)))

        XCTAssertEqual(fixture.template.lastPerformedDate, newer.date)
    }

    func testDeletingTheWorkoutATargetCameFromKeepsTheSavedTarget() throws {
        let fixture = try makeRoutine()
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)])
        let suggestion = try XCTUnwrap(workout.progressionRecord(for: fixture.bench.id)?.suggestedTarget)
        try save(suggestion, from: workout, fixture)

        XCTAssertTrue(PastWorkoutEditor.deleteWorkout(workout, editor(fixture)))

        XCTAssertEqual(fixture.template.progressionState(for: fixture.bench.id)?.acceptedTarget, suggestion)
    }

    func testFailedSaveLeavesTheSetAndItsEvidenceAsTheyWere() throws {
        let storeContainer = try makeOnDiskContainer()
        let storeContext = storeContainer.mainContext
        let fixture = try makeRoutine(in: storeContext)
        let workout = try finishedWorkout(fixture, daysAgo: 0, sets: [(60, 10), (60, 10), (60, 10)], in: storeContext)
        let recordBefore = workout.progressionRecord(for: fixture.bench.id)
        let third = try XCTUnwrap(workout.setEntries.first { $0.setIndex == 2 })
        var failing = editor(fixture, in: storeContext)
        failing.save = { _ in throw Failure.disk }

        XCTAssertFalse(PastWorkoutEditor.update(third, weightKg: 60, reps: 9, in: workout, failing))
        XCTAssertNil(PastWorkoutEditor.delete(third, from: workout, failing))
        XCTAssertFalse(PastWorkoutEditor.deleteWorkout(workout, failing))

        XCTAssertEqual(third.reps, 10)
        XCTAssertEqual(workout.setEntries.count, 3)
        XCTAssertEqual(workout.progressionRecord(for: fixture.bench.id), recordBefore)
        XCTAssertEqual(try storeContext.fetchCount(FetchDescriptor<WorkoutSession>()), 1)
    }

    // MARK: - Helpers

    private struct Routine {
        let template: DayTemplate
        let bench: Exercise
    }

    private static func progressionState() -> ExerciseProgressionState {
        ExerciseProgressionState(
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: 2.5,
            currentAcceptedTargetWeightKg: 60,
            currentAcceptedTargetReps: 8,
            sourceWorkoutSessionID: nil,
            lastAcceptedReason: nil
        )
    }

    private func makeRoutine(in modelContext: ModelContext? = nil) throws -> Routine {
        let modelContext = modelContext ?? context
        let bench = Exercise(displayName: "Bench Press")
        let template = DayTemplate(name: "Push", orderedExerciseIds: [bench.id])
        template.setPlannedSets(3, for: bench.id)
        template.setProgressionState(Self.progressionState(), for: bench.id)
        modelContext.insert(bench)
        modelContext.insert(template)
        try modelContext.save()
        return Routine(template: template, bench: bench)
    }

    /// A finished workout with its "Next time" records captured, as Finish does.
    private func finishedWorkout(
        _ routine: Routine,
        daysAgo: Int,
        sets: [(weight: Double, reps: Int)],
        in modelContext: ModelContext? = nil
    ) throws -> WorkoutSession {
        let modelContext = modelContext ?? context
        let date = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()) ?? Date()
        let session = WorkoutSession(date: date, templateId: routine.template.id, isCompleted: true)
        modelContext.insert(session)
        for (index, set) in sets.enumerated() {
            let entry = SetEntry(
                sessionId: session.id,
                exerciseId: routine.bench.id,
                weight: set.weight,
                reps: set.reps,
                isCompleted: true,
                setIndex: index
            )
            entry.session = session
            modelContext.insert(entry)
        }
        session.captureProgressionRecords(template: routine.template, exercises: [routine.bench])
        try modelContext.save()
        return session
    }

    /// The summary's "Save for next workout" path.
    private func save(_ target: DoubleProgressionTarget, from session: WorkoutSession, _ routine: Routine) throws {
        let reason = try XCTUnwrap(session.progressionRecord(for: routine.bench.id)?.recommendationReason)
        XCTAssertTrue(routine.template.acceptProgressionRecommendation(
            DoubleProgressionRecommendation(target: target, reason: reason, sourceWorkoutSessionID: session.id),
            for: routine.bench.id
        ))
        XCTAssertTrue(session.recordProgressionDecision(target: target, action: .usedSuggestion, for: routine.bench.id))
        try context.save()
    }

    private func editor(
        _ routine: Routine,
        in modelContext: ModelContext? = nil,
        extraExercises: [Exercise] = []
    ) -> PastWorkoutEditor.Context {
        let modelContext = modelContext ?? context
        return PastWorkoutEditor.Context(
            modelContext: modelContext,
            sessions: (try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? [],
            templates: [routine.template],
            exercises: [routine.bench] + extraExercises
        )
    }

    private func makeOnDiskContainer() throws -> ModelContainer {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("PastWorkoutEditingTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        addTeardownBlock { try? FileManager.default.removeItem(at: directory) }
        let schema = Schema([Split.self, Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self])
        let configuration = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("edit.store"))
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}
