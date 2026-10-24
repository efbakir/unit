import SwiftData
import XCTest
@testable import Unit

@MainActor
final class ProgressionPersistenceTests: XCTestCase {
    func testProgressAnalyticsExcludeUnfinishedWarmupAndInvalidEntries() throws {
        let exerciseID = UUID()
        let finished = WorkoutSession(date: Date(timeIntervalSince1970: 100), templateId: UUID(), isCompleted: true)
        let unfinished = WorkoutSession(templateId: finished.templateId)
        finished.setEntries = [
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: 60, reps: 8, isCompleted: true),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: 60, reps: 10, isCompleted: true),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: 100, reps: 20, isWarmup: true, isCompleted: true),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: 200, reps: 8),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: .infinity, reps: 8, isCompleted: true),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: -20, reps: 8, isCompleted: true),
            SetEntry(sessionId: finished.id, exerciseId: exerciseID, weight: 100, reps: 0, isCompleted: true)
        ]
        unfinished.setEntries = [SetEntry(sessionId: unfinished.id, exerciseId: exerciseID, weight: 500, reps: 10, isCompleted: true)]
        let points = ExerciseProgressView.sessionPointsByExercise(in: [unfinished, finished])[exerciseID] ?? []
        XCTAssertEqual(points.count, 1)
        let point = try XCTUnwrap(points.first)
        XCTAssertEqual(point.weight, 60)
        XCTAssertEqual(point.reps, 10)
        XCTAssertEqual(point.totalReps, 18)
        XCTAssertEqual(point.volumeKg, 1_080)
        XCTAssertEqual(try XCTUnwrap(point.estimatedOneRM), 80, accuracy: 0.001)
        XCTAssertTrue(ExerciseProgressView.sessionPointsByExercise(in: [unfinished]).isEmpty)
    }

    func testProgressAnalyticsKeepBodyweightAndLimitOneRMEstimate() throws {
        let bodyweightID = UUID()
        let loadedID = UUID()
        let session = WorkoutSession(templateId: UUID(), isCompleted: true)
        session.setEntries = [
            SetEntry(sessionId: session.id, exerciseId: bodyweightID, weight: 0, reps: 12, isCompleted: true),
            SetEntry(sessionId: session.id, exerciseId: loadedID, weight: 100, reps: 1, isCompleted: true),
            SetEntry(sessionId: session.id, exerciseId: loadedID, weight: 90, reps: 10, isCompleted: true),
            SetEntry(sessionId: session.id, exerciseId: loadedID, weight: 150, reps: 30, isCompleted: true)
        ]
        let points = ExerciseProgressView.sessionPointsByExercise(in: [session])
        let bw = try XCTUnwrap(points[bodyweightID]?.first)
        XCTAssertEqual(ExerciseProgressView.performanceText(for: bw, isBodyweight: true), "BW × 12")
        XCTAssertNil(bw.estimatedOneRM)
        let loaded = try XCTUnwrap(points[loadedID]?.first)
        // Estimate comes from the strongest eligible set, not the heaviest
        // high-rep set, nor only the one-rep set.
        XCTAssertEqual(try XCTUnwrap(loaded.estimatedOneRM), 120, accuracy: 0.001)
    }

    func testProgressComparisonRequiresSameRoutineAndComparableLoadOrReps() throws {
        let exerciseID = UUID()
        let routineID = UUID()
        func point(weight: Double, reps: Int, routine: UUID? = nil) throws -> ExerciseProgressView.SessionPoint {
            let session = WorkoutSession(templateId: routine ?? routineID, isCompleted: true)
            session.setEntries = [SetEntry(sessionId: session.id, exerciseId: exerciseID, weight: weight, reps: reps, isCompleted: true)]
            return try XCTUnwrap(ExerciseProgressView.sessionPointsByExercise(in: [session])[exerciseID]?.first)
        }
        let previous = try point(weight: 60, reps: 8)
        let extraReps = try point(weight: 60, reps: 10)
        XCTAssertEqual(ExerciseProgressView.comparisonText(for: extraReps, previous: previous, isBodyweight: false), "+2 reps at the same load")
        let changedBoth = try point(weight: 65, reps: 6)
        XCTAssertTrue(ExerciseProgressView.comparisonText(for: changedBoth, previous: previous, isBodyweight: false).hasPrefix("Previous · "))
        let differentRoutine = try point(weight: 60, reps: 10, routine: UUID())
        XCTAssertEqual(ExerciseProgressView.comparisonText(for: differentRoutine, previous: previous, isBodyweight: false), "First recorded session for this routine")
    }

    private struct PersistedTargetSnapshot {
        let state: ExerciseProgressionState?
        let plannedReps: Int?
        let plannedWeightKg: Double?
    }

    func testPrefillSkipsMalformedNewestHistoryAndIncompleteCurrentWork() {
        let exerciseID = UUID()
        let current = WorkoutSession(date: Date(), templateId: UUID(), isCompleted: false)
        let latest = WorkoutSession(date: Date().addingTimeInterval(-60), templateId: UUID(), isCompleted: true)
        let older = WorkoutSession(date: Date().addingTimeInterval(-120), templateId: UUID(), isCompleted: true)
        current.setEntries = [SetEntry(sessionId: current.id, exerciseId: exerciseID, weight: 999, reps: 99)]
        latest.setEntries = [SetEntry(sessionId: latest.id, exerciseId: exerciseID, weight: -.infinity, reps: 8, isCompleted: true)]
        older.setEntries = [SetEntry(sessionId: older.id, exerciseId: exerciseID, weight: 60, reps: 8, isCompleted: true)]
        let value = ActiveWorkoutViewModel().prefillSet(
            for: exerciseID, currentSession: current, sessions: [older, current, latest]
        )
        XCTAssertEqual(value?.source, .priorSession)
        XCTAssertEqual(value?.weight, 60)
        XCTAssertEqual(value?.reps, 8)
    }

    func testCompletedBodyweightHistoryIsValidAndWarmupsAreExcluded() {
        let exerciseID = UUID()
        let current = WorkoutSession(date: Date(), templateId: UUID(), isCompleted: false)
        let previous = WorkoutSession(date: Date().addingTimeInterval(-60), templateId: UUID(), isCompleted: true)
        previous.setEntries = [
            SetEntry(sessionId: previous.id, exerciseId: exerciseID, weight: 0, reps: 8, isCompleted: true),
            SetEntry(sessionId: previous.id, exerciseId: exerciseID, weight: 20, reps: 20, isWarmup: true, isCompleted: true, setIndex: 1)
        ]
        let value = ActiveWorkoutViewModel().prefillSet(for: exerciseID, currentSession: current, sessions: [previous])
        XCTAssertEqual(value?.weight, 0)
        XCTAssertEqual(value?.reps, 8)
    }

    func testFailedWorkoutSaveRollsBackCompletionAndNewSets() throws {
        enum Failure: Error { case disk }
        let container = try makeContainer(at: temporaryStoreURL(named: "failed-save"))
        let context = container.mainContext
        let session = WorkoutSession(date: Date(), templateId: UUID(), isCompleted: false)
        context.insert(session)
        try context.save()
        // ActiveWorkout reads the relationship before any user mutation.
        XCTAssertTrue(session.setEntries.isEmpty)
        session.isCompleted = true
        let entry = SetEntry(sessionId: session.id, exerciseId: UUID(), weight: 60, reps: 8, isCompleted: true)
        entry.session = session
        context.insert(entry)
        XCTAssertFalse(ActiveWorkoutViewModel().saveChanges(in: context, save: { throw Failure.disk }))
        XCTAssertFalse(session.isCompleted)
        XCTAssertTrue(session.setEntries.isEmpty)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 0)
    }

    func testFailedRoutineSaveRestoresLoadedStartingAndProgressionTargets() throws {
        enum Failure: Error { case disk }
        let container = try makeContainer(at: temporaryStoreURL(named: "failed-routine"))
        let context = container.mainContext
        let exerciseID = UUID()
        let template = DayTemplate(name: "Upper", orderedExerciseIds: [exerciseID])
        template.setPlannedReps(8, for: exerciseID)
        template.setPlannedWeight(60, for: exerciseID)
        template.setProgressionState(progressionState(), for: exerciseID)
        context.insert(template)
        try context.save()
        let savedState = template.progressionStateByExerciseIdData
        template.setPlannedReps(12, for: exerciseID)
        template.setPlannedWeight(90, for: exerciseID)
        template.setProgressionState(nil, for: exerciseID)
        XCTAssertFalse(ActiveWorkoutViewModel().saveChanges(in: context, save: { throw Failure.disk }))
        XCTAssertEqual(template.plannedReps(for: exerciseID), 8)
        XCTAssertEqual(template.plannedWeight(for: exerciseID), 60)
        XCTAssertEqual(template.progressionStateByExerciseIdData, savedState)
    }

    func testFailedSetDeletionRestoresLoadedSessionRelationship() throws {
        enum Failure: Error { case disk }
        let container = try makeContainer(at: temporaryStoreURL(named: "failed-delete"))
        let context = container.mainContext
        let session = WorkoutSession(templateId: UUID())
        context.insert(session)
        let entry = SetEntry(sessionId: session.id, exerciseId: UUID(), weight: 60, reps: 8, isCompleted: true)
        entry.session = session
        context.insert(entry)
        try context.save()
        XCTAssertEqual(session.setEntries.count, 1)
        let originalID = entry.id
        context.delete(entry)
        XCTAssertFalse(ActiveWorkoutViewModel().saveChanges(in: context, save: { throw Failure.disk }))
        XCTAssertEqual(session.setEntries.map(\.id), [originalID])
        XCTAssertEqual(session.setEntries.first?.weight, 60)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 1)
    }

    func testSetUndoRestoresIdentityOrderAndEveryRecordedValue() throws {
        let container = try makeContainer(at: temporaryStoreURL(named: "set-undo"))
        let context = container.mainContext
        let session = WorkoutSession(date: Date(), templateId: UUID(), isCompleted: false)
        context.insert(session)
        let entry = SetEntry(sessionId: session.id, exerciseId: UUID(), weight: 61.25, reps: 9,
                             rpe: 8, rir: 2, isWarmup: false, isCompleted: true,
                             setIndex: 3, note: "Controlled tempo")
        entry.session = session
        context.insert(entry)
        try context.save()
        let snapshot = SetEntrySnapshot(entry)
        context.delete(entry)
        try context.save()
        let restored = snapshot.restore(in: session)
        context.insert(restored)
        try context.save()
        XCTAssertEqual(restored.id, snapshot.id)
        XCTAssertEqual(restored.sessionId, session.id)
        XCTAssertEqual(restored.exerciseId, snapshot.exerciseID)
        XCTAssertEqual(restored.weight, 61.25)
        XCTAssertEqual(restored.reps, 9)
        XCTAssertEqual(restored.rpe, 8)
        XCTAssertEqual(restored.rir, 2)
        XCTAssertEqual(restored.setIndex, 3)
        XCTAssertEqual(restored.note, "Controlled tempo")
        XCTAssertTrue(restored.isCompleted)
        XCTAssertFalse(restored.isWarmup)
        XCTAssertEqual(try context.fetchCount(FetchDescriptor<SetEntry>()), 1)
    }

    func testMissingAndCorruptProgressionDataDecodeAsEmpty() {
        let template = DayTemplate(name: "Push")
        XCTAssertTrue(template.progressionStateByExerciseId.isEmpty)
        XCTAssertNil(template.progressionState(for: UUID()))

        template.progressionStateByExerciseIdData = Data([0xFF, 0x00, 0x01])
        XCTAssertTrue(template.progressionStateByExerciseId.isEmpty)
    }

    func testProgressionStateRoundTripsByExerciseID() {
        let exerciseID = UUID()
        let template = DayTemplate(
            name: "Push",
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )

        XCTAssertEqual(template.progressionState(for: exerciseID), progressionState())
        XCTAssertNil(template.progressionState(for: UUID()))
    }

    func testEditingTheRuleKeepsTheAcceptedTargetWeight() {
        let exerciseID = UUID()
        let sourceID = UUID()
        let template = DayTemplate(
            name: "Push",
            plannedSetsByExerciseId: [exerciseID: 3],
            progressionStateByExerciseId: [
                exerciseID: progressionState(weightKg: 62.5, sourceSessionID: sourceID)
            ]
        )
        XCTAssertEqual(template.progressionState(for: exerciseID)?.acceptedTarget?.weightKg, 62.5)

        // Wider rep range, one more set, smaller weight step.
        template.applyTarget(
            setCount: 4,
            reps: 8,
            progression: DoubleProgressionConfiguration(
                workingSetCount: 4,
                lowerRepBound: 10,
                upperRepBound: 12,
                weightIncrementKg: 1.25
            ),
            for: exerciseID,
            sessions: []
        )

        let edited = template.progressionState(for: exerciseID)
        XCTAssertEqual(edited?.acceptedTarget?.weightKg ?? 0, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(edited?.acceptedTarget?.reps, 10, "reps clamp into the new range")
        XCTAssertEqual(edited?.sourceWorkoutSessionID, sourceID)
        XCTAssertEqual(template.plannedSets(for: exerciseID), 4)
    }

    func testDismissedRecommendationDoesNotMutateRoutine() throws {
        let storeURL = temporaryStoreURL(named: "dismissed-target")
        let templateID = UUID()
        let exerciseID = UUID()
        try writePersistentTemplate(
            at: storeURL,
            templateID: templateID,
            exerciseID: exerciseID,
            state: progressionState()
        )
        let recommendation = try XCTUnwrap(
            DoubleProgressionEngine.recommendation(
                for: input(sessionID: UUID(), reps: [10, 10, 10])
            )
        )

        XCTAssertEqual(recommendation.target.weightKg, 62.5, accuracy: 0.000_001)
        let reopened = try readTargetSnapshot(
            at: storeURL,
            templateID: templateID,
            exerciseID: exerciseID
        )
        XCTAssertEqual(reopened.state, progressionState())
        XCTAssertNil(reopened.state?.sourceWorkoutSessionID)
        XCTAssertEqual(reopened.plannedReps, 8)
        XCTAssertEqual(reopened.plannedWeightKg ?? -1, 60, accuracy: 0.000_001)
    }

    func testAcceptedEditedTargetSurvivesPersistentRelaunch() throws {
        let storeURL = temporaryStoreURL(named: "accepted-target")
        let templateID = UUID()
        let exerciseID = UUID()
        let sessionID = UUID()
        let editedTarget = DoubleProgressionRecommendation(
            target: DoubleProgressionTarget(weightKg: 61.25, reps: 9),
            reason: .addARep,
            sourceWorkoutSessionID: sessionID
        )

        try writePersistentTemplate(
            at: storeURL,
            templateID: templateID,
            exerciseID: exerciseID,
            state: progressionState()
        )

        do {
            let container = try makeContainer(at: storeURL)
            let descriptor = FetchDescriptor<DayTemplate>(
                predicate: #Predicate { $0.id == templateID }
            )
            let template = try XCTUnwrap(container.mainContext.fetch(descriptor).first)
            XCTAssertTrue(template.acceptProgressionRecommendation(editedTarget, for: exerciseID))
            try container.mainContext.save()
        }

        let reopened = try readTargetSnapshot(
            at: storeURL,
            templateID: templateID,
            exerciseID: exerciseID
        )
        XCTAssertEqual(reopened.state?.currentAcceptedTargetWeightKg ?? -1, 61.25, accuracy: 0.000_001)
        XCTAssertEqual(reopened.state?.currentAcceptedTargetReps, 9)
        XCTAssertEqual(reopened.state?.sourceWorkoutSessionID, sessionID)
        XCTAssertEqual(reopened.plannedWeightKg ?? -1, 61.25, accuracy: 0.000_001)
        XCTAssertEqual(reopened.plannedReps, 9)
    }

    func testTargetsRemainScopedToRoutineAndExercise() {
        let sharedExerciseID = UUID()
        let otherExerciseID = UUID()
        let firstTemplate = DayTemplate(name: "Push")
        let secondTemplate = DayTemplate(name: "Upper")
        firstTemplate.setProgressionState(progressionState(weightKg: 62.5), for: sharedExerciseID)
        firstTemplate.setProgressionState(progressionState(weightKg: 30), for: otherExerciseID)
        secondTemplate.setProgressionState(progressionState(weightKg: 70), for: sharedExerciseID)

        XCTAssertEqual(
            firstTemplate.progressionState(for: sharedExerciseID)?.currentAcceptedTargetWeightKg ?? -1,
            62.5,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            firstTemplate.progressionState(for: otherExerciseID)?.currentAcceptedTargetWeightKg ?? -1,
            30,
            accuracy: 0.000_001
        )
        XCTAssertEqual(
            secondTemplate.progressionState(for: sharedExerciseID)?.currentAcceptedTargetWeightKg ?? -1,
            70,
            accuracy: 0.000_001
        )
    }

    func testRemovingAndUndoingExerciseRestoresProgressionAndPlannedValues() throws {
        let exerciseID = UUID()
        let otherExerciseID = UUID()
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [otherExerciseID, exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            plannedWeightByExerciseId: [exerciseID: 60],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )

        let snapshot = try XCTUnwrap(template.removeExerciseAndCaptureState(exerciseID))
        XCTAssertFalse(template.orderedExerciseIds.contains(exerciseID))
        XCTAssertNil(template.plannedSets(for: exerciseID))
        XCTAssertNil(template.plannedReps(for: exerciseID))
        XCTAssertNil(template.plannedWeight(for: exerciseID))
        XCTAssertNil(template.progressionState(for: exerciseID))

        template.restoreExerciseState(snapshot)
        XCTAssertEqual(template.orderedExerciseIds, [otherExerciseID, exerciseID])
        XCTAssertEqual(template.plannedSets(for: exerciseID), 3)
        XCTAssertEqual(template.plannedReps(for: exerciseID), 8)
        XCTAssertEqual(template.plannedWeight(for: exerciseID) ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(template.progressionState(for: exerciseID), progressionState())
    }

    func testPrefillPrecedenceCurrentThenAcceptedThenPriorThenPlanned() {
        let exerciseID = UUID()
        let currentSession = WorkoutSession(templateId: UUID())
        let priorSession = WorkoutSession(
            date: Date().addingTimeInterval(-3600),
            templateId: UUID(),
            isCompleted: true
        )
        let priorEntry = SetEntry(
            sessionId: priorSession.id,
            exerciseId: exerciseID,
            weight: 60,
            reps: 8,
            isCompleted: true,
            setIndex: 0
        )
        priorEntry.session = priorSession
        priorSession.setEntries = [priorEntry]
        let accepted = DoubleProgressionTarget(weightKg: 62.5, reps: 8)
        let viewModel = ActiveWorkoutViewModel()

        let acceptedPrefill = viewModel.prefillSet(
            for: exerciseID,
            currentSession: currentSession,
            sessions: [currentSession, priorSession],
            acceptedProgressionTarget: accepted,
            plannedReps: 5,
            plannedWeightKg: 40
        )
        XCTAssertEqual(acceptedPrefill?.source, .acceptedProgression)
        XCTAssertEqual(acceptedPrefill?.weight ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(acceptedPrefill?.reps, 8)

        let currentEntry = SetEntry(
            sessionId: currentSession.id,
            exerciseId: exerciseID,
            weight: 61.25,
            reps: 9,
            isCompleted: true,
            setIndex: 0
        )
        currentEntry.session = currentSession
        currentSession.setEntries = [currentEntry]
        let currentPrefill = viewModel.prefillSet(
            for: exerciseID,
            currentSession: currentSession,
            sessions: [currentSession, priorSession],
            acceptedProgressionTarget: accepted,
            plannedReps: 5,
            plannedWeightKg: 40
        )
        XCTAssertEqual(currentPrefill?.source, .currentSession)
        XCTAssertEqual(currentPrefill?.weight ?? -1, 61.25, accuracy: 0.000_001)
        XCTAssertEqual(currentPrefill?.reps, 9)

        currentSession.setEntries = []
        let priorPrefill = viewModel.prefillSet(
            for: exerciseID,
            currentSession: currentSession,
            sessions: [currentSession, priorSession],
            plannedReps: 5,
            plannedWeightKg: 40
        )
        XCTAssertEqual(priorPrefill?.source, .priorSession)
        XCTAssertEqual(priorPrefill?.weight ?? -1, 60, accuracy: 0.000_001)

        let plannedPrefill = viewModel.prefillSet(
            for: UUID(),
            currentSession: currentSession,
            sessions: [currentSession, priorSession],
            plannedReps: 5,
            plannedWeightKg: 40
        )
        XCTAssertEqual(plannedPrefill?.source, .planned)
        XCTAssertEqual(plannedPrefill?.weight ?? -1, 40, accuracy: 0.000_001)
        XCTAssertEqual(plannedPrefill?.reps, 5)
    }

    func testProgressionTestPastePersistsStartingTargetThroughFirstLoggedSet() throws {
        let previousUnit = UserDefaults.standard.string(forKey: "unitSystem")
        UserDefaults.standard.set("kg", forKey: "unitSystem")
        defer {
            if let previousUnit {
                UserDefaults.standard.set(previousUnit, forKey: "unitSystem")
            } else {
                UserDefaults.standard.removeObject(forKey: "unitSystem")
            }
        }

        let parsed = ProgramImportParser.parseWithWarnings(
            """
            Progression Test

            Bench Press 3x8-10 60
            Barbell Row 3x8-10 40
            Back Squat 3x8-10 50
            Deadlift 3x8-10 30
            """,
            defaultUnit: "kg"
        )
        XCTAssertEqual(parsed.days.count, 1)
        XCTAssertEqual(parsed.days.first?.name, "Progression Test")
        XCTAssertEqual(parsed.days.first?.exercises.count, 4)

        let storeURL = temporaryStoreURL(named: "first-session-starting-target")
        let container = try makeContainer(at: storeURL)
        let onboarding = OnboardingViewModel()
        onboarding.importMethod = .paste
        onboarding.unitSystem = "kg"
        onboarding.applyImportedProgram(parsed.days)
        onboarding.dayWeekdays = [Calendar.current.component(.weekday, from: Date())]
        try onboarding.commit(modelContext: container.mainContext)

        let split = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<Split>())
                .first(where: { $0.name == "Progression Test" })
        )
        let template = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<DayTemplate>())
                .first(where: { $0.splitId == split.id })
        )
        let exercises = try container.mainContext.fetch(FetchDescriptor<Exercise>())
        let exerciseByName = Dictionary(
            uniqueKeysWithValues: exercises.map { ($0.displayName, $0) }
        )
        let expectedWeights: [String: Double] = [
            "Bench Press": 60,
            "Barbell Row": 40,
            "Back Squat": 50,
            "Deadlift": 30
        ]
        for (name, expectedWeight) in expectedWeights {
            let exercise = try XCTUnwrap(exerciseByName[name])
            XCTAssertEqual(template.plannedSets(for: exercise.id), 3)
            XCTAssertEqual(template.plannedReps(for: exercise.id), 8)
            XCTAssertEqual(
                template.plannedWeight(for: exercise.id) ?? -1,
                expectedWeight,
                accuracy: 0.000_001
            )
            XCTAssertEqual(template.progressionState(for: exercise.id)?.lowerRepBound, 8)
            XCTAssertEqual(template.progressionState(for: exercise.id)?.upperRepBound, 10)
        }

        let bench = try XCTUnwrap(exerciseByName["Bench Press"])
        let session = template.startWorkoutSession(in: container.mainContext)
        let firstPrefill = ActiveWorkoutViewModel().prefillSet(
            for: bench.id,
            currentSession: session,
            sessions: [session],
            acceptedProgressionTarget: template.progressionState(for: bench.id)?.acceptedTarget,
            plannedReps: template.plannedReps(for: bench.id),
            plannedWeightKg: template.plannedWeight(for: bench.id)
        )
        XCTAssertEqual(firstPrefill?.source, .planned)
        XCTAssertEqual(firstPrefill?.weight ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(firstPrefill?.reps, 8)

        let firstEntry = SetEntry(
            sessionId: session.id,
            exerciseId: bench.id,
            weight: try XCTUnwrap(firstPrefill).weight,
            reps: try XCTUnwrap(firstPrefill).reps,
            isCompleted: true,
            setIndex: 0
        )
        firstEntry.session = session
        container.mainContext.insert(firstEntry)
        try container.mainContext.save()

        let nextPrefill = ActiveWorkoutViewModel().prefillSet(
            for: bench.id,
            currentSession: session,
            sessions: [session],
            acceptedProgressionTarget: template.progressionState(for: bench.id)?.acceptedTarget,
            plannedReps: template.plannedReps(for: bench.id),
            plannedWeightKg: template.plannedWeight(for: bench.id)
        )
        XCTAssertEqual(nextPrefill?.source, .currentSession)
        XCTAssertEqual(nextPrefill?.weight ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(nextPrefill?.reps, 8)
        XCTAssertEqual(session.setEntries.count, 1)
    }

    func testUnconfiguredRoutineKeepsPriorSessionPrefillBehavior() {
        let exerciseID = UUID()
        let currentSession = WorkoutSession(templateId: UUID())
        let priorSession = WorkoutSession(
            templateId: UUID(),
            isCompleted: true
        )
        let priorEntry = SetEntry(
            sessionId: priorSession.id,
            exerciseId: exerciseID,
            weight: 80,
            reps: 6,
            isCompleted: true
        )
        priorEntry.session = priorSession
        priorSession.setEntries = [priorEntry]

        let prefill = ActiveWorkoutViewModel().prefillSet(
            for: exerciseID,
            currentSession: currentSession,
            sessions: [priorSession]
        )

        XCTAssertEqual(prefill?.source, .priorSession)
        XCTAssertEqual(prefill?.weight ?? -1, 80, accuracy: 0.000_001)
        XCTAssertEqual(prefill?.reps, 6)
    }

    func testSetOneStartsFromThisRoutinesFirstSetBeforeNewerOtherRoutines() {
        let exerciseID = UUID(), heavyDay = UUID(), lightDay = UUID()
        let current = WorkoutSession(templateId: heavyDay)
        let lastHeavy = WorkoutSession(date: Date().addingTimeInterval(-7 * 86_400), templateId: heavyDay, isCompleted: true)
        lastHeavy.setEntries = [
            completedEntry(session: lastHeavy, exerciseID: exerciseID, weight: 100, reps: 5, index: 0),
            completedEntry(session: lastHeavy, exerciseID: exerciseID, weight: 100, reps: 5, index: 1),
            completedEntry(session: lastHeavy, exerciseID: exerciseID, weight: 100, reps: 3, index: 2)
        ]
        let newerLight = WorkoutSession(date: Date().addingTimeInterval(-86_400), templateId: lightDay, isCompleted: true)
        newerLight.setEntries = [completedEntry(session: newerLight, exerciseID: exerciseID, weight: 70, reps: 10, index: 0)]

        let prefill = ActiveWorkoutViewModel().prefillSet(
            for: exerciseID, currentSession: current, sessions: [current, newerLight, lastHeavy]
        )

        XCTAssertEqual(prefill?.source, .priorSession)
        XCTAssertEqual(prefill?.weight ?? -1, 100, accuracy: 0.000_001)
        XCTAssertEqual(prefill?.reps, 5, "Set 1 anchors on set 1, not on the weaker last set")
    }

    func testSetOneFallsBackToFirstSetOfAnotherRoutine() {
        let exerciseID = UUID()
        let current = WorkoutSession(templateId: UUID())
        let other = WorkoutSession(date: Date().addingTimeInterval(-86_400), templateId: UUID(), isCompleted: true)
        other.setEntries = [
            completedEntry(session: other, exerciseID: exerciseID, weight: 60, reps: 8, index: 0),
            completedEntry(session: other, exerciseID: exerciseID, weight: 60, reps: 6, index: 1)
        ]

        let prefill = ActiveWorkoutViewModel().prefillSet(
            for: exerciseID, currentSession: current, sessions: [other], plannedReps: 10, plannedWeightKg: 40
        )

        XCTAssertEqual(prefill?.source, .priorSession)
        XCTAssertEqual(prefill?.weight ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(prefill?.reps, 8)
    }

    func testRepeatedLiftBlocksAnchorOnTheirOwnHistory() {
        // PR #5 saves a second listing (5/3/1 BBB) as its own exercise.
        let main = UUID(), volume = UUID(), routine = UUID()
        let current = WorkoutSession(templateId: routine)
        let last = WorkoutSession(date: Date().addingTimeInterval(-86_400), templateId: routine, isCompleted: true)
        last.setEntries = [
            completedEntry(session: last, exerciseID: main, weight: 100, reps: 5, index: 0),
            completedEntry(session: last, exerciseID: volume, weight: 50, reps: 10, index: 0)
        ]
        let viewModel = ActiveWorkoutViewModel()

        XCTAssertEqual(viewModel.prefillSet(for: main, currentSession: current, sessions: [last])?.weight, 100)
        XCTAssertEqual(viewModel.prefillSet(for: volume, currentSession: current, sessions: [last])?.weight, 50)
    }

    func testLastTimeSetsPreferTheRoutineWithoutChangingTheDefault() {
        let exerciseID = UUID(), routine = UUID()
        let older = WorkoutSession(date: Date().addingTimeInterval(-7 * 86_400), templateId: routine, isCompleted: true)
        older.setEntries = [completedEntry(session: older, exerciseID: exerciseID, weight: 80, reps: 5, index: 0)]
        let newer = WorkoutSession(date: Date().addingTimeInterval(-86_400), templateId: UUID(), isCompleted: true)
        newer.setEntries = [completedEntry(session: newer, exerciseID: exerciseID, weight: 60, reps: 10, index: 0)]

        XCTAssertEqual(SetEntry.latestValidWorkingSets(for: exerciseID, in: [older, newer]).first?.weight, 60)
        XCTAssertEqual(SetEntry.latestValidWorkingSets(for: exerciseID, in: [older, newer],
                                                       preferringTemplate: routine).first?.weight, 80)
        XCTAssertEqual(SetEntry.latestValidWorkingSets(for: exerciseID, in: [newer],
                                                       preferringTemplate: routine).first?.weight, 60)
    }

    func testCompleteTargetFormattingIncludesSetsWeightAndUnit() {
        let defaults = UserDefaults.standard
        let previousUnit = defaults.string(forKey: "unitSystem")
        defer {
            if let previousUnit {
                defaults.set(previousUnit, forKey: "unitSystem")
            } else {
                defaults.removeObject(forKey: "unitSystem")
            }
        }

        defaults.set("kg", forKey: "unitSystem")
        XCTAssertEqual(
            WorkoutTargetFormatter.milestoneText(
                weightKg: 60,
                reps: 8,
                isBodyweight: false
            ),
            "60 kg × 8"
        )
        XCTAssertEqual(
            WorkoutTargetFormatter.completeTargetText(
                weightKg: 62.5,
                setCount: 3,
                reps: 8
            ),
            "3 × 8 at 62.5 kg"
        )

        defaults.set("lb", forKey: "unitSystem")
        XCTAssertEqual(
            WorkoutTargetFormatter.completeTargetText(
                weightKg: 20,
                setCount: 3,
                reps: 8
            ),
            "3 × 8 at 44.1 lb"
        )

        XCTAssertNil(
            WorkoutTargetFormatter.completeTargetText(
                weightKg: 0,
                setCount: 3,
                reps: 8
            )
        )

        defaults.set("kg", forKey: "unitSystem")
        XCTAssertEqual(
            WorkoutTargetFormatter.completedPerformanceText(
                weightsKg: [60, 60, 60],
                reps: [8, 8, 8],
                isBodyweight: false
            ),
            "3 × 8 at 60 kg"
        )
        XCTAssertEqual(
            WorkoutTargetFormatter.completedPerformanceText(
                weightsKg: [60, 60, 60],
                reps: [10, 9, 8],
                isBodyweight: false
            ),
            "60 kg · 10/9/8 reps"
        )
    }

    func testFinishingSessionCapturesRecommendationEvidenceOnce() throws {
        let exerciseID = UUID()
        let exercise = Exercise(
            id: exerciseID,
            displayName: "Bench Press",
            isBodyweight: false
        )
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            plannedWeightByExerciseId: [exerciseID: 60],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = [
            completedEntry(session: session, exerciseID: exerciseID, weight: 40, reps: 5, index: -1, isWarmup: true),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 10, index: 0),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 10, index: 1),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 10, index: 2)
        ]

        XCTAssertTrue(session.captureProgressionRecords(template: template, exercises: [exercise]))
        let record = try XCTUnwrap(session.progressionRecord(for: exerciseID))
        XCTAssertEqual(record.previousTarget, DoubleProgressionTarget(weightKg: 60, reps: 8))
        XCTAssertEqual(record.completedSets.count, 3)
        XCTAssertEqual(record.completedSets.map(\.reps), [10, 10, 10])
        XCTAssertEqual(record.suggestedTarget, DoubleProgressionTarget(weightKg: 62.5, reps: 8))
        XCTAssertEqual(record.recommendationReason, .allSetsReachedTop)
        XCTAssertNil(record.unavailableReason)
        XCTAssertNil(record.acceptedTarget)

        let originalData = session.progressionRecordsByExerciseIdData
        XCTAssertFalse(session.captureProgressionRecords(template: template, exercises: [exercise]))
        XCTAssertEqual(session.progressionRecordsByExerciseIdData, originalData)

        _ = template.removeExerciseAndCaptureState(exerciseID)
        XCTAssertEqual(
            session.progressionRecord(for: exerciseID)?.exerciseName,
            "Bench Press"
        )
    }

    func testFinishAppliesSuggestedTargetsOnce() throws {
        let bench = UUID(), deadlift = UUID()
        let exercises = [
            Exercise(id: bench, displayName: "Bench Press", isBodyweight: false),
            Exercise(id: deadlift, displayName: "Deadlift", isBodyweight: false)
        ]
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [bench, deadlift],
            plannedSetsByExerciseId: [bench: 3, deadlift: 3],
            plannedRepsByExerciseId: [bench: 8, deadlift: 8],
            progressionStateByExerciseId: [bench: progressionState(), deadlift: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = (0..<3).map {
            completedEntry(session: session, exerciseID: bench, weight: 60, reps: 10, index: $0)
        } + [60.0, 65, 60].enumerated().map {
            completedEntry(session: session, exerciseID: deadlift, weight: $0.element, reps: 8, index: $0.offset)
        }
        session.captureProgressionRecords(template: template, exercises: exercises)

        XCTAssertTrue(session.applySuggestedTargets(to: template))
        let applied = DoubleProgressionTarget(weightKg: 62.5, reps: 8)
        XCTAssertEqual(template.progressionState(for: bench)?.acceptedTarget, applied)
        XCTAssertEqual(template.progressionState(for: bench)?.sourceWorkoutSessionID, session.id)
        XCTAssertEqual(template.plannedWeight(for: bench), 62.5)
        XCTAssertEqual(session.progressionRecord(for: bench)?.acceptedTarget, applied)
        XCTAssertEqual(session.progressionRecord(for: bench)?.decisionAction, .usedSuggestion)
        // Weights varied: no suggestion, so the routine keeps its target.
        XCTAssertNil(template.progressionState(for: deadlift)?.acceptedTarget)
        XCTAssertNil(session.progressionRecord(for: deadlift)?.decisionAction)

        let recordsAfterFinish = session.progressionRecordsByExerciseIdData
        XCTAssertFalse(session.applySuggestedTargets(to: template))
        XCTAssertEqual(session.progressionRecordsByExerciseIdData, recordsAfterFinish)
    }

    func testFailedFinishSaveRollsBackAppliedTargets() throws {
        enum Failure: Error { case disk }
        let container = try makeContainer(at: temporaryStoreURL(named: "failed-apply"))
        let context = container.mainContext
        let exerciseID = UUID()
        let exercise = Exercise(id: exerciseID, displayName: "Bench Press", isBodyweight: false)
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            plannedWeightByExerciseId: [exerciseID: 60],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id)
        context.insert(exercise)
        context.insert(template)
        context.insert(session)
        for index in 0..<3 {
            let entry = SetEntry(sessionId: session.id, exerciseId: exerciseID, weight: 60, reps: 10,
                                 isCompleted: true, setIndex: index)
            entry.session = session
            context.insert(entry)
        }
        try context.save()
        let savedState = template.progressionStateByExerciseIdData

        session.isCompleted = true
        session.captureProgressionRecords(template: template, exercises: [exercise])
        XCTAssertTrue(session.applySuggestedTargets(to: template))
        XCTAssertFalse(ActiveWorkoutViewModel().saveChanges(in: context, save: { throw Failure.disk }))

        XCTAssertFalse(session.isCompleted)
        XCTAssertEqual(template.progressionStateByExerciseIdData, savedState)
        XCTAssertEqual(template.plannedWeight(for: exerciseID), 60)
        XCTAssertTrue(session.progressionRecordsByExerciseId.isEmpty)
    }

    func testKeepPreviousThenUseSuggestedThenEditMoveTheSavedTarget() throws {
        let exerciseID = UUID()
        let exercise = Exercise(id: exerciseID, displayName: "Bench Press", isBodyweight: false)
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = (0..<3).map {
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 10, index: $0)
        }
        session.captureProgressionRecords(template: template, exercises: [exercise])
        session.applySuggestedTargets(to: template)
        let previous = try XCTUnwrap(session.progressionRecord(for: exerciseID)?.previousTarget)
        let suggested = DoubleProgressionTarget(weightKg: 62.5, reps: 8)

        XCTAssertTrue(session.saveProgressionDecision(previous, action: .repeatedPreviousTarget,
                                                      reason: .repeatTarget, for: exerciseID, template: template))
        XCTAssertEqual(template.progressionState(for: exerciseID)?.acceptedTarget, previous)
        XCTAssertEqual(session.progressionRecord(for: exerciseID)?.decisionAction, .repeatedPreviousTarget)

        XCTAssertTrue(session.saveProgressionDecision(suggested, action: .usedSuggestion,
                                                      reason: .allSetsReachedTop, for: exerciseID, template: template))
        XCTAssertEqual(template.progressionState(for: exerciseID)?.acceptedTarget, suggested)

        let edited = DoubleProgressionTarget(weightKg: 61.25, reps: 9)
        XCTAssertTrue(session.saveProgressionDecision(edited, action: .edited,
                                                      reason: .allSetsReachedTop, for: exerciseID, template: template))
        XCTAssertEqual(template.progressionState(for: exerciseID)?.acceptedTarget, edited)
        XCTAssertEqual(session.progressionRecord(for: exerciseID)?.decisionAction, .edited)
    }

    func testEditSetsATargetWhenWeightsVaried() throws {
        let exerciseID = UUID()
        let exercise = Exercise(id: exerciseID, displayName: "Deadlift", isBodyweight: false)
        let template = DayTemplate(
            name: "Pull",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            progressionStateByExerciseId: [exerciseID: progressionState(weightKg: 100)]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = [100.0, 110, 100].enumerated().map {
            completedEntry(session: session, exerciseID: exerciseID, weight: $0.element, reps: 8, index: $0.offset)
        }
        session.captureProgressionRecords(template: template, exercises: [exercise])
        XCTAssertFalse(session.applySuggestedTargets(to: template))
        let record = try XCTUnwrap(session.progressionRecord(for: exerciseID))
        XCTAssertEqual(record.unavailableReason, .mixedWorkingSetWeights)
        XCTAssertEqual(record.previousTarget, DoubleProgressionTarget(weightKg: 100, reps: 8))

        let target = DoubleProgressionTarget(weightKg: 105, reps: 8)
        XCTAssertTrue(session.saveProgressionDecision(target, action: .edited, reason: .repeatTarget,
                                                      for: exerciseID, template: template))
        XCTAssertEqual(template.progressionState(for: exerciseID)?.acceptedTarget, target)
        XCTAssertEqual(session.progressionRecord(for: exerciseID)?.decisionAction, .edited)
    }

    func testStallReasonNamesThePlannedSetsThatFellShort() {
        func reason(_ reps: [Int]) -> String {
            let record = SessionProgressionRecord(
                exerciseID: UUID(), exerciseName: "Back Squat", isBodyweight: false,
                configuredSetCount: 3, lowerRepBound: 8, upperRepBound: 10, weightIncrementKg: 2.5,
                previousTarget: DoubleProgressionTarget(weightKg: 100, reps: 8),
                completedSets: reps.map { CompletedProgressionSet(weightKg: 100, reps: $0) },
                suggestedTarget: DoubleProgressionTarget(weightKg: 100, reps: 8),
                recommendationReason: .repeatTarget, unavailableReason: nil
            )
            return AppCopy.Workout.stallReason(shortSets: record.shortSets, targetReps: 8)
        }
        XCTAssertEqual(reason([8, 8, 8, 5]), "Keep this target.", "An extra set never counts")
        XCTAssertEqual(reason([8, 8, 6]), "Set 3: 6 of 8 reps. Keep this target.")
        XCTAssertEqual(reason([8, 7, 6]), "Sets 2 and 3: under 8 reps. Keep this target.")
        XCTAssertEqual(reason([7, 7, 6]), "Sets 1, 2 and 3: under 8 reps. Keep this target.")
    }

    func testSheetSaveReadsAsSuggestionPreviousOrEdit() {
        let record = SessionProgressionRecord(
            exerciseID: UUID(), exerciseName: "Bench Press", isBodyweight: false,
            configuredSetCount: 3, lowerRepBound: 8, upperRepBound: 10, weightIncrementKg: 2.5,
            previousTarget: DoubleProgressionTarget(weightKg: 60, reps: 10),
            completedSets: (0..<3).map { _ in CompletedProgressionSet(weightKg: 60, reps: 10) },
            suggestedTarget: DoubleProgressionTarget(weightKg: 62.5, reps: 8),
            recommendationReason: .allSetsReachedTop, unavailableReason: nil
        )
        XCTAssertEqual(record.decisionAction(saving: .init(weightKg: 62.5, reps: 8)), .usedSuggestion)
        // 137.8 lb typed back from pounds still means the suggestion.
        XCTAssertEqual(record.decisionAction(saving: .init(weightKg: 137.8 / 2.20462, reps: 8)), .usedSuggestion)
        XCTAssertEqual(record.decisionAction(saving: .init(weightKg: 60, reps: 10)), .repeatedPreviousTarget)
        XCTAssertEqual(record.decisionAction(saving: .init(weightKg: 61.25, reps: 9)), .edited)
    }

    func testSessionCapturesTypedUnavailableOutcome() throws {
        let exerciseID = UUID()
        let exercise = Exercise(
            id: exerciseID,
            displayName: "Bench Press",
            isBodyweight: false
        )
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = [
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 8, index: 0),
            completedEntry(session: session, exerciseID: exerciseID, weight: 62.5, reps: 8, index: 1),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 8, index: 2)
        ]

        XCTAssertTrue(session.captureProgressionRecords(template: template, exercises: [exercise]))
        let record = try XCTUnwrap(session.progressionRecord(for: exerciseID))
        XCTAssertNil(record.suggestedTarget)
        XCTAssertNil(record.recommendationReason)
        XCTAssertEqual(record.unavailableReason, .mixedWorkingSetWeights)
    }

    func testNonfiniteSetStillPersistsUnavailableEvidence() throws {
        let exerciseID = UUID()
        let exercise = Exercise(
            id: exerciseID,
            displayName: "Bench Press",
            isBodyweight: false
        )
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            progressionStateByExerciseId: [exerciseID: progressionState()]
        )
        let session = WorkoutSession(templateId: template.id, isCompleted: true)
        session.setEntries = [
            completedEntry(session: session, exerciseID: exerciseID, weight: .infinity, reps: 8, index: 0),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 8, index: 1),
            completedEntry(session: session, exerciseID: exerciseID, weight: 60, reps: 8, index: 2)
        ]

        XCTAssertTrue(session.captureProgressionRecords(template: template, exercises: [exercise]))
        let record = try XCTUnwrap(session.progressionRecord(for: exerciseID))
        XCTAssertEqual(record.unavailableReason, .invalidWorkingSetData)
        XCTAssertEqual(record.completedSets.count, 2)
        XCTAssertNotNil(session.progressionRecordsByExerciseIdData)
    }

    func testUseRepeatAndEditDecisionsPersistIdempotently() throws {
        try assertDecisionPersists(
            action: .usedSuggestion,
            target: DoubleProgressionTarget(weightKg: 62.5, reps: 8),
            reason: .allSetsReachedTop,
            storeName: "use-suggested"
        )
        try assertDecisionPersists(
            action: .repeatedPreviousTarget,
            target: DoubleProgressionTarget(weightKg: 60, reps: 8),
            reason: .repeatTarget,
            storeName: "repeat-previous"
        )
        try assertDecisionPersists(
            action: .edited,
            target: DoubleProgressionTarget(weightKg: 61.25, reps: 9),
            reason: .addARep,
            storeName: "edited-target"
        )
    }

    func testAcceptedVersion22StateBackfillsOnlyKnownDecisionFactsOnce() throws {
        let exerciseID = UUID()
        let sessionID = UUID()
        let exercise = Exercise(
            id: exerciseID,
            displayName: "Bench Press",
            isBodyweight: false
        )
        let template = DayTemplate(
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: 8],
            plannedWeightByExerciseId: [exerciseID: 62.5],
            progressionStateByExerciseId: [
                exerciseID: progressionState(
                    weightKg: 62.5,
                    sourceSessionID: sessionID
                )
            ]
        )
        let session = WorkoutSession(
            id: sessionID,
            templateId: template.id,
            isCompleted: true
        )
        session.setEntries = [
            completedEntry(
                session: session,
                exerciseID: exerciseID,
                weight: 60,
                reps: 10,
                index: 0
            ),
            completedEntry(
                session: session,
                exerciseID: exerciseID,
                weight: 60,
                reps: 10,
                index: 1
            ),
            completedEntry(
                session: session,
                exerciseID: exerciseID,
                weight: 60,
                reps: 10,
                index: 2
            )
        ]

        XCTAssertTrue(
            session.captureProgressionRecords(
                template: template,
                exercises: [exercise],
                evaluatePendingRecommendations: false
            )
        )
        let record = try XCTUnwrap(session.progressionRecord(for: exerciseID))
        XCTAssertEqual(
            record.acceptedTarget,
            DoubleProgressionTarget(weightKg: 62.5, reps: 8)
        )
        XCTAssertEqual(record.recommendationReason, .allSetsReachedTop)
        XCTAssertNil(record.previousTarget)
        XCTAssertNil(record.suggestedTarget)
        XCTAssertNil(record.unavailableReason)
        XCTAssertNil(record.decisionAction)

        let originalData = session.progressionRecordsByExerciseIdData
        XCTAssertFalse(
            session.captureProgressionRecords(
                template: template,
                exercises: [exercise],
                evaluatePendingRecommendations: false
            )
        )
        XCTAssertEqual(session.progressionRecordsByExerciseIdData, originalData)
    }

    func testCopiedVersion21StoreMigratesWithoutRecoveryFallback() throws {
        let fixtureURL = try XCTUnwrap(
            Bundle(for: Self.self).url(
                forResource: "Unit-v2.1",
                withExtension: "store"
            )
        )
        let storeURL = temporaryStoreURL(named: "v2.1-migration")
        try FileManager.default.copyItem(at: fixtureURL, to: storeURL)

        let identifiers = try migrateFixtureAndPersistProgression(at: storeURL)
        XCTAssertEqual(identifiers.templateID.uuidString, "20000000-0000-0000-0000-000000000001")
        XCTAssertEqual(identifiers.sessionCount, 1)
        XCTAssertEqual(identifiers.setCount, 3)

        let reopened = try readProgressionState(
            at: storeURL,
            templateID: identifiers.templateID,
            exerciseID: identifiers.exerciseID
        )
        XCTAssertEqual(reopened?.currentAcceptedTargetWeightKg ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(reopened?.sourceWorkoutSessionID?.uuidString, "40000000-0000-0000-0000-000000000001")
    }

    private func migrateFixtureAndPersistProgression(
        at storeURL: URL
    ) throws -> (templateID: UUID, exerciseID: UUID, sessionCount: Int, setCount: Int) {
        let container = try makeContainer(at: storeURL)
        let templates = try container.mainContext.fetch(FetchDescriptor<DayTemplate>())
        let exercises = try container.mainContext.fetch(FetchDescriptor<Exercise>())
        let sessions = try container.mainContext.fetch(FetchDescriptor<WorkoutSession>())
        let entries = try container.mainContext.fetch(FetchDescriptor<SetEntry>())
        let template = try XCTUnwrap(templates.first)
        let exerciseID = try XCTUnwrap(template.orderedExerciseIds.first)
        let exercise = try XCTUnwrap(exercises.first)
        let sourceSession = try XCTUnwrap(sessions.first)
        let sortedEntries = entries.sorted { $0.setIndex < $1.setIndex }

        XCTAssertTrue(template.progressionStateByExerciseId.isEmpty)
        XCTAssertEqual(template.name, "Push")
        XCTAssertEqual(exerciseID.uuidString, "30000000-0000-0000-0000-000000000001")
        XCTAssertEqual(exercise.id, exerciseID)
        XCTAssertEqual(exercise.displayName, "Bench Press")
        XCTAssertEqual(template.plannedSets(for: exerciseID), 3)
        XCTAssertEqual(template.plannedReps(for: exerciseID), 8)
        XCTAssertEqual(template.plannedWeight(for: exerciseID) ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(sourceSession.id.uuidString, "40000000-0000-0000-0000-000000000001")
        XCTAssertEqual(sourceSession.templateId, template.id)
        XCTAssertTrue(sourceSession.isCompleted)
        XCTAssertEqual(sourceSession.setEntries.count, 3)
        XCTAssertEqual(sortedEntries.map(\.id.uuidString), [
            "50000000-0000-0000-0000-000000000001",
            "50000000-0000-0000-0000-000000000002",
            "50000000-0000-0000-0000-000000000003"
        ])
        XCTAssertEqual(sortedEntries.map(\.weight), [60, 60, 60])
        XCTAssertEqual(sortedEntries.map(\.reps), [8, 9, 10])
        XCTAssertTrue(sortedEntries.allSatisfy(\.isCompleted))
        XCTAssertTrue(sortedEntries.allSatisfy { !$0.isWarmup })
        XCTAssertTrue(sortedEntries.allSatisfy { $0.sessionId == sourceSession.id })
        XCTAssertTrue(sortedEntries.allSatisfy { $0.exerciseId == exerciseID })
        XCTAssertTrue(sortedEntries.allSatisfy { $0.session?.id == sourceSession.id })

        template.setProgressionState(
            progressionState(weightKg: 62.5, sourceSessionID: sourceSession.id),
            for: exerciseID
        )
        try container.mainContext.save()
        return (template.id, exerciseID, sessions.count, entries.count)
    }

    private func writePersistentTemplate(
        at storeURL: URL,
        templateID: UUID,
        exerciseID: UUID,
        state: ExerciseProgressionState
    ) throws {
        let container = try makeContainer(at: storeURL)
        let template = DayTemplate(
            id: templateID,
            name: "Push",
            orderedExerciseIds: [exerciseID],
            plannedSetsByExerciseId: [exerciseID: 3],
            plannedRepsByExerciseId: [exerciseID: state.currentAcceptedTargetReps],
            plannedWeightByExerciseId: [exerciseID: state.currentAcceptedTargetWeightKg ?? 0],
            progressionStateByExerciseId: [exerciseID: state]
        )
        container.mainContext.insert(template)
        try container.mainContext.save()
    }

    private func assertDecisionPersists(
        action: ProgressionDecisionAction,
        target: DoubleProgressionTarget,
        reason: DoubleProgressionReason,
        storeName: String
    ) throws {
        let storeURL = temporaryStoreURL(named: storeName)
        let exerciseID = UUID()
        let templateID = UUID()
        let sessionID = UUID()
        let record = SessionProgressionRecord(
            exerciseID: exerciseID,
            exerciseName: "Bench Press",
            isBodyweight: false,
            configuredSetCount: 3,
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: 2.5,
            previousTarget: DoubleProgressionTarget(weightKg: 60, reps: 8),
            completedSets: [
                CompletedProgressionSet(weightKg: 60, reps: 10),
                CompletedProgressionSet(weightKg: 60, reps: 10),
                CompletedProgressionSet(weightKg: 60, reps: 10)
            ],
            suggestedTarget: DoubleProgressionTarget(weightKg: 62.5, reps: 8),
            recommendationReason: .allSetsReachedTop,
            unavailableReason: nil,
            acceptedTarget: nil,
            decisionAction: nil
        )

        do {
            let container = try makeContainer(at: storeURL)
            let template = DayTemplate(
                id: templateID,
                name: "Push",
                orderedExerciseIds: [exerciseID],
                plannedSetsByExerciseId: [exerciseID: 3],
                plannedRepsByExerciseId: [exerciseID: 8],
                plannedWeightByExerciseId: [exerciseID: 60],
                progressionStateByExerciseId: [exerciseID: progressionState()]
            )
            let session = WorkoutSession(
                id: sessionID,
                templateId: templateID,
                isCompleted: true,
                progressionRecordsByExerciseId: [exerciseID: record]
            )
            container.mainContext.insert(template)
            container.mainContext.insert(session)
            try container.mainContext.save()
        }

        do {
            let container = try makeContainer(at: storeURL)
            let template = try XCTUnwrap(
                container.mainContext.fetch(
                    FetchDescriptor<DayTemplate>(
                        predicate: #Predicate { $0.id == templateID }
                    )
                ).first
            )
            let session = try XCTUnwrap(
                container.mainContext.fetch(
                    FetchDescriptor<WorkoutSession>(
                        predicate: #Predicate { $0.id == sessionID }
                    )
                ).first
            )
            let recommendation = DoubleProgressionRecommendation(
                target: target,
                reason: reason,
                sourceWorkoutSessionID: sessionID
            )
            XCTAssertTrue(template.acceptProgressionRecommendation(recommendation, for: exerciseID))
            XCTAssertTrue(session.recordProgressionDecision(target: target, action: action, for: exerciseID))
            XCTAssertTrue(template.acceptProgressionRecommendation(recommendation, for: exerciseID))
            XCTAssertTrue(session.recordProgressionDecision(target: target, action: action, for: exerciseID))
            try container.mainContext.save()
        }

        let container = try makeContainer(at: storeURL)
        let reopenedTemplate = try XCTUnwrap(
            container.mainContext.fetch(
                FetchDescriptor<DayTemplate>(
                    predicate: #Predicate { $0.id == templateID }
                )
            ).first
        )
        let reopenedSession = try XCTUnwrap(
            container.mainContext.fetch(
                FetchDescriptor<WorkoutSession>(
                    predicate: #Predicate { $0.id == sessionID }
                )
            ).first
        )
        XCTAssertEqual(reopenedTemplate.progressionState(for: exerciseID)?.acceptedTarget, target)
        XCTAssertEqual(reopenedTemplate.progressionState(for: exerciseID)?.lastAcceptedReason, reason)
        XCTAssertEqual(reopenedSession.progressionRecordsByExerciseId.count, 1)
        XCTAssertEqual(reopenedSession.progressionRecord(for: exerciseID)?.acceptedTarget, target)
        XCTAssertEqual(reopenedSession.progressionRecord(for: exerciseID)?.decisionAction, action)
    }

    private func completedEntry(
        session: WorkoutSession,
        exerciseID: UUID,
        weight: Double,
        reps: Int,
        index: Int,
        isWarmup: Bool = false
    ) -> SetEntry {
        let entry = SetEntry(
            sessionId: session.id,
            exerciseId: exerciseID,
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            isCompleted: true,
            setIndex: index
        )
        entry.session = session
        return entry
    }

    private func readProgressionState(
        at storeURL: URL,
        templateID: UUID,
        exerciseID: UUID
    ) throws -> ExerciseProgressionState? {
        let container = try makeContainer(at: storeURL)
        let descriptor = FetchDescriptor<DayTemplate>(
            predicate: #Predicate { $0.id == templateID }
        )
        return try container.mainContext.fetch(descriptor).first?.progressionState(for: exerciseID)
    }

    private func readTargetSnapshot(
        at storeURL: URL,
        templateID: UUID,
        exerciseID: UUID
    ) throws -> PersistedTargetSnapshot {
        let container = try makeContainer(at: storeURL)
        let descriptor = FetchDescriptor<DayTemplate>(
            predicate: #Predicate { $0.id == templateID }
        )
        let template = try XCTUnwrap(container.mainContext.fetch(descriptor).first)
        return PersistedTargetSnapshot(
            state: template.progressionState(for: exerciseID),
            plannedReps: template.plannedReps(for: exerciseID),
            plannedWeightKg: template.plannedWeight(for: exerciseID)
        )
    }

    private func makeContainer(at storeURL: URL) throws -> ModelContainer {
        let schema = Schema([
            Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self
        ])
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func temporaryStoreURL(named name: String) -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("ProgressionPersistenceTests-\(UUID().uuidString)", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: directory)
        }
        return directory.appendingPathComponent("\(name).store")
    }

    private func input(sessionID: UUID, reps: [Int]) -> DoubleProgressionInput {
        DoubleProgressionInput(
            configuration: DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: 2.5
            ),
            currentTargetReps: 8,
            sourceWorkoutSessionID: sessionID,
            isBodyweightOnly: false,
            sets: reps.enumerated().map { index, reps in
                DoubleProgressionSet(
                    weightKg: 60,
                    reps: reps,
                    isWarmup: false,
                    isCompleted: true,
                    setIndex: index
                )
            }
        )
    }

    private func progressionState(
        weightKg: Double = 60,
        sourceSessionID: UUID? = nil
    ) -> ExerciseProgressionState {
        ExerciseProgressionState(
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: 2.5,
            currentAcceptedTargetWeightKg: weightKg,
            currentAcceptedTargetReps: 8,
            sourceWorkoutSessionID: sourceSessionID,
            lastAcceptedReason: sourceSessionID == nil ? nil : .allSetsReachedTop
        )
    }
}
