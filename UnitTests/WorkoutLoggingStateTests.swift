import SwiftData
import XCTest
@testable import Unit

@MainActor
final class WorkoutLoggingStateTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_000)

    private func entry(_ index: Int, weight: Double = 60, reps: Int = 8) -> WorkoutLoggingState.Entry {
        .init(id: UUID(), weight: weight, reps: reps, setIndex: index)
    }
    private func exercise(_ entries: [WorkoutLoggingState.Entry], count: Int = 4, id: UUID = UUID(), name: String = "Bench") -> WorkoutLoggingState.ExerciseState {
        .init(id: id, name: name, plannedCount: count, entries: entries)
    }

    func testSessionOrderSurvivesEncodingWithoutChangingTemplateOrder() {
        let sessionID = UUID(), first = UUID(), second = UUID()
        let templateIDs = [first, second]
        let saved = WorkoutLoggingState.encodeExerciseOrder([second, first], sessionID: sessionID)
        XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: templateIDs,
            sessionID: sessionID, saved: saved), [second, first])
        XCTAssertEqual(templateIDs, [first, second])
        XCTAssertEqual(WorkoutLoggingState.currentExerciseID(in: [exercise([], id: second),
            exercise([entry(0)], id: first)], selectedID: first), first)
    }

    func testSavedOrderIgnoresOtherSessionsAndCorruptData() {
        let ids = [UUID(), UUID()], sessionID = UUID()
        let saved = WorkoutLoggingState.encodeExerciseOrder(Array(ids.reversed()), sessionID: UUID())
        for data in [saved, Data("invalid".utf8), Data()] {
            XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: ids,
                sessionID: sessionID, saved: data), ids)
        }
    }

    func testUnsavedOrderDropsDuplicateTemplateIDs() {
        let bench = UUID()
        let row = UUID()
        XCTAssertEqual(
            WorkoutLoggingState.orderedExerciseIDs(
                templateIDs: [bench, bench, row],
                sessionID: UUID(),
                saved: Data()
            ),
            [bench, row]
        )
    }

    func testSavedOrderDropsDeletedAndDuplicateIDsAndAppendsNewExercises() {
        let first = UUID(), second = UUID(), added = UUID(), deleted = UUID(), sessionID = UUID()
        let saved = WorkoutLoggingState.encodeExerciseOrder([second, deleted, second, first], sessionID: sessionID)
        XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: [first, second, added],
            sessionID: sessionID, saved: saved), [second, first, added])
    }

    func testSessionPlanDecodesOldOrderOnlyDataAndRoundTrips() throws {
        let sessionID = UUID(), first = UUID(), second = UUID()
        // Data saved by builds before the session plan: order only.
        let legacy = Data(#"{"sessionID":"\#(sessionID.uuidString)","exerciseIDs":["\#(second.uuidString)","\#(first.uuidString)"]}"#.utf8)
        let decoded = WorkoutLoggingState.plan(from: legacy, sessionID: sessionID)
        XCTAssertEqual(decoded.exerciseIDs, [second, first])
        XCTAssertTrue(decoded.swaps.isEmpty && decoded.additions.isEmpty && decoded.skipped.isEmpty)
        XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: [first, second], sessionID: sessionID, saved: legacy),
                       [second, first])
        var plan = decoded
        plan.swaps[first] = UUID(); plan.additions = [UUID()]; plan.setCounts[second] = 5
        plan.addedSets[second] = 1; plan.skipped = [second]
        XCTAssertEqual(WorkoutLoggingState.plan(from: WorkoutLoggingState.encode(plan), sessionID: sessionID), plan)
        XCTAssertEqual(WorkoutLoggingState.plan(from: WorkoutLoggingState.encode(plan), sessionID: UUID()).exerciseIDs, [])
    }

    func testSwapTakesTheRoutineExercisesPlaceAndAdditionsGoLast() {
        let sessionID = UUID(), bench = UUID(), row = UUID(), press = UUID(), curl = UUID()
        var plan = WorkoutLoggingState.SessionPlan(sessionID: sessionID, exerciseIDs: [row, bench])
        plan = WorkoutLoggingState.swapping(bench, with: press, in: plan)
        plan.additions.append(curl)
        XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: [bench, row], plan: plan), [row, press, curl])
        XCTAssertEqual(WorkoutLoggingState.planSourceID(for: press, in: plan), bench)
        XCTAssertEqual(WorkoutLoggingState.planSourceID(for: curl, in: plan), curl)
        // Swapping the swapped-in exercise again still maps to the routine one;
        // swapping back to the routine exercise removes the swap.
        let incline = UUID()
        plan = WorkoutLoggingState.swapping(press, with: incline, in: plan)
        XCTAssertEqual(plan.swaps, [bench: incline])
        plan = WorkoutLoggingState.swapping(incline, with: bench, in: plan)
        XCTAssertTrue(plan.swaps.isEmpty)
        XCTAssertEqual(WorkoutLoggingState.orderedExerciseIDs(templateIDs: [bench, row], plan: plan), [row, bench, curl])
    }

    func testSwappingAnAddedExerciseMovesItsCounts() {
        let sessionID = UUID(), curl = UUID(), hammer = UUID()
        var plan = WorkoutLoggingState.SessionPlan(sessionID: sessionID)
        plan.additions = [curl]; plan.setCounts[curl] = 4; plan.addedSets[curl] = 1; plan.skipped = [curl]
        plan = WorkoutLoggingState.swapping(curl, with: hammer, in: plan)
        XCTAssertEqual(plan.additions, [hammer])
        XCTAssertTrue(plan.swaps.isEmpty)
        XCTAssertEqual(plan.setCounts, [hammer: 4])
        XCTAssertEqual(plan.addedSets, [hammer: 1])
        XCTAssertTrue(plan.skipped.isEmpty)
    }

    func testRowsDeriveCurrentAndPlannedPositionsForZeroTwoAndFourSets() {
        let empty = WorkoutLoggingState.rows(for: exercise([]), isCurrent: true)
        XCTAssertEqual(empty.map(\.number), [1, 2, 3, 4])
        XCTAssertEqual(empty.map(\.kind), [.current, .planned, .planned, .planned])
        let entries = [entry(0), entry(1)]
        let partial = WorkoutLoggingState.rows(for: exercise(entries), isCurrent: true)
        XCTAssertEqual(partial.map(\.kind), [.logged(entries[0].id), .logged(entries[1].id), .current, .planned])
        let full = WorkoutLoggingState.rows(for: exercise((0..<4).map { entry($0) }), isCurrent: true)
        XCTAssertFalse(full.contains { $0.kind == .current })
        let added = WorkoutLoggingState.rows(for: exercise((0..<4).map { entry($0) }, count: 5), isCurrent: true)
        XCTAssertEqual(added.last?.number, 5)
        XCTAssertEqual(added.last?.kind, .current)
    }

    func testMiddleDeletionRenumbersAndMalformedSetsDoNotAdvance() {
        let first = entry(0), last = entry(3)
        var malformed = entry(1)
        malformed.isWarmup = true
        var incomplete = entry(2)
        incomplete.isCompleted = false
        let rows = WorkoutLoggingState.rows(for: exercise([last, incomplete, malformed, first]), isCurrent: true)
        XCTAssertEqual(rows.map(\.number), [1, 2, 3, 4])
        XCTAssertEqual(rows.map(\.kind), [.logged(first.id), .logged(last.id), .current, .planned])
    }

    func testGuardRejects399MillisecondsAndAccepts401() {
        var state = WorkoutLoggingState()
        XCTAssertTrue(state.canLog(at: now))
        state.didLog(entryID: UUID(), exerciseID: UUID(), at: now)
        XCTAssertFalse(state.canLog(at: now.addingTimeInterval(0.399)))
        XCTAssertTrue(state.canLog(at: now.addingTimeInterval(0.401)))
    }

    func testGuardWithDurableInMemoryInsertDoesNotDuplicate() throws {
        let schema = Schema([DayTemplate.self, WorkoutSession.self, SetEntry.self, Exercise.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let session = WorkoutSession(templateId: UUID())
        context.insert(session)
        let exerciseID = UUID()
        var state = WorkoutLoggingState()
        for offset in [0.0, 0.399, 0.401] {
            let time = now.addingTimeInterval(offset)
            guard state.canLog(at: time) else { continue }
            let logged = SetEntry(sessionId: session.id, exerciseId: exerciseID, weight: 60, reps: 8,
                                  isCompleted: true, setIndex: session.setEntries.count)
            logged.session = session
            context.insert(logged)
            try context.save()
            state.didLog(entryID: logged.id, exerciseID: exerciseID, at: time)
        }
        XCTAssertEqual(try context.fetch(FetchDescriptor<SetEntry>()).count, 2)
    }

    func testUndoExpiresAtFiveSecondsAndInvalidatesAfterAnAction() {
        var state = WorkoutLoggingState()
        let entryID = UUID(), exerciseID = UUID()
        state.didLog(entryID: entryID, exerciseID: exerciseID, at: now)
        XCTAssertEqual(state.availableUndo(at: now.addingTimeInterval(4.999))?.entryID, entryID)
        XCTAssertNil(state.availableUndo(at: now.addingTimeInterval(5)))
        state.invalidateUndo()
        XCTAssertNil(state.availableUndo(at: now.addingTimeInterval(1)))
        XCTAssertTrue(WorkoutLoggingState.shouldStopRest(removing: entryID, sourceEntryID: entryID))
        XCTAssertFalse(WorkoutLoggingState.shouldStopRest(removing: UUID(), sourceEntryID: entryID))
    }

    func testUpNextTracksRemainingSetsAddedSetsDeletionAndDayEnd() {
        let benchID = UUID(), inclineID = UUID()
        let incline = exercise([], count: 3, id: inclineID, name: "Incline")
        let two = exercise([entry(0), entry(1)], id: benchID)
        XCTAssertEqual(WorkoutLoggingState.upNext(exercises: [two, incline], currentExerciseID: benchID),
                       .init(exerciseID: benchID, name: "Bench", setNumber: 3))
        let four = (0..<4).map { entry($0) }
        let done = exercise(four, id: benchID)
        XCTAssertEqual(WorkoutLoggingState.upNext(exercises: [done, incline], currentExerciseID: benchID),
                       .init(exerciseID: inclineID, name: "Incline", setNumber: 1))
        XCTAssertNil(WorkoutLoggingState.upNext(exercises: [done], currentExerciseID: benchID))
        let added = exercise(four, count: 5, id: benchID)
        XCTAssertEqual(WorkoutLoggingState.upNext(exercises: [added], currentExerciseID: benchID)?.setNumber, 5)
        let deleted = exercise(Array(four.dropFirst()), id: benchID)
        XCTAssertEqual(WorkoutLoggingState.upNext(exercises: [deleted], currentExerciseID: benchID)?.setNumber, 4)
    }

    func testUpNextDetailShowsTheNextSetsNumbersWhenKnown() {
        XCTAssertEqual(AppCopy.Workout.upNextDetail(setNumber: 2, value: "135 lb × 10"), "Set 2 · 135 lb × 10")
        XCTAssertEqual(AppCopy.Workout.upNextDetail(setNumber: 1, value: "BW × 12"), "Set 1 · BW × 12")
        XCTAssertEqual(AppCopy.Workout.upNextDetail(setNumber: 1, value: nil), "Set 1")
    }

    func testUpcomingExercisesGroupWithoutSwallowingCurrentOrPartialCards() {
        let first = exercise([entry(0)], name: "First")
        let second = exercise([], name: "Second")
        let third = exercise([], name: "Third")
        let fourth = exercise([], name: "Fourth")
        let groups = WorkoutLoggingState.groups(exercises: [first, second, third, fourth], currentID: second.id, expandedID: nil)
        XCTAssertEqual(groups.count, 3)
        XCTAssertFalse(groups[0].isUpcoming)
        XCTAssertFalse(groups[1].isUpcoming)
        XCTAssertEqual(groups[2].exerciseIDs, [third.id, fourth.id])
        XCTAssertTrue(groups[2].isUpcoming)
    }

    func testManualSelectionAndAutomaticWrapFindUnfinishedExercise() {
        let first = exercise([], name: "First")
        let last = exercise([entry(0)], count: 1, name: "Last")
        XCTAssertEqual(WorkoutLoggingState.currentExerciseID(in: [first, last]), first.id)
        XCTAssertEqual(WorkoutLoggingState.currentExerciseID(in: [first, last], selectedID: last.id), last.id)
        XCTAssertEqual(WorkoutLoggingState.nextUnfinishedExerciseID(in: [first, last], after: last.id), first.id)
    }

    func testSkippingTheLastUnfinishedExerciseEndsTheDayUntilReopened() {
        let first = exercise((0..<4).map { entry($0) }, name: "First")
        let last = exercise([entry(0)], count: 3, name: "Last")
        XCTAssertEqual(WorkoutLoggingState.currentExerciseID(in: [first, last]), last.id)
        XCTAssertNil(WorkoutLoggingState.nextUnfinishedExerciseID(in: [first, last], after: last.id))
        XCTAssertFalse(WorkoutLoggingState.isDayDone([first, last]))
        let skipped: Set<UUID> = [last.id]
        XCTAssertNil(WorkoutLoggingState.currentExerciseID(in: [first, last], skipped: skipped))
        XCTAssertNil(WorkoutLoggingState.currentExerciseID(in: [first, last], selectedID: last.id, skipped: skipped))
        XCTAssertTrue(WorkoutLoggingState.isDayDone([first, last], skipped: skipped))
        XCTAssertNil(WorkoutLoggingState.nextUnfinishedExerciseID(in: [first, last], after: first.id, skipped: skipped))
        XCTAssertNil(WorkoutLoggingState.upNext(exercises: [first, last], currentExerciseID: first.id, skipped: skipped))
        // Reopening (an empty skip set) restores the normal order.
        XCTAssertEqual(WorkoutLoggingState.currentExerciseID(in: [first, last], selectedID: last.id), last.id)
        XCTAssertFalse(WorkoutLoggingState.isDayDone([]))
    }

    func testZeroPreparationOnlyChangesTargetDictionary() throws {
        let schema = Schema([DayTemplate.self, WorkoutSession.self, SetEntry.self, Exercise.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let exercise = Exercise(displayName: "Bench", isBodyweight: false)
        let template = DayTemplate(name: "Upper", orderedExerciseIds: [exercise.id])
        let session = WorkoutSession(templateId: template.id)
        context.insert(exercise); context.insert(template); context.insert(session)
        try context.save()
        let targets = try XCTUnwrap(WorkoutLoggingState.savingTarget(
            SetPrefill(weight: 0, reps: 8, source: .prepared), in: [:], sessionID: session.id, exerciseID: exercise.id))
        XCTAssertEqual(targets[session.id.uuidString]?[exercise.id.uuidString]?.weight, 0)
        XCTAssertEqual(try context.fetch(FetchDescriptor<SetEntry>()).count, 0)
        XCTAssertNil(template.plannedWeight(for: exercise.id))
        XCTAssertNil(template.plannedReps(for: exercise.id))
        XCTAssertFalse(exercise.isBodyweight)
    }

    func testRowTargetsOverrideExerciseTargetsAndOldJSONStillDecodes() throws {
        let sessionID = UUID(), exerciseID = UUID()
        let legacy: WorkoutLoggingState.Targets = [sessionID.uuidString: [exerciseID.uuidString: SetPrefill(weight: 60, reps: 8, source: .prepared)]]
        let decoded = WorkoutLoggingState.decodeTargets(try JSONEncoder().encode(legacy))
        let targets = try XCTUnwrap(WorkoutLoggingState.savingTarget(
            SetPrefill(weight: 65, reps: 6, source: .prepared), in: decoded,
            sessionID: sessionID, exerciseID: exerciseID, row: 3))
        let third = WorkoutLoggingState.resolvedTarget(in: targets, sessionID: sessionID, exerciseID: exerciseID, row: 3, fallback: nil)
        let second = WorkoutLoggingState.resolvedTarget(in: targets, sessionID: sessionID, exerciseID: exerciseID, row: 2, fallback: nil)
        XCTAssertEqual(third?.weight, 65)
        XCTAssertEqual(second?.weight, 60)
        XCTAssertNil(WorkoutLoggingState.savingTarget(SetPrefill(weight: 60, reps: 0, source: .prepared), in: targets, sessionID: sessionID, exerciseID: exerciseID))
    }

    func testFinishUpdatesUseFirstLoggedSetAndRequireExerciseTarget() {
        let sessionID = UUID(), exerciseID = UUID()
        let state = exercise([entry(2, weight: 65, reps: 7), entry(0, weight: 60, reps: 8)], id: exerciseID)
        let targets: WorkoutLoggingState.Targets = [sessionID.uuidString: [exerciseID.uuidString: .init(weight: 70, reps: 6, source: .prepared)]]
        let diff = WorkoutLoggingState.routineUpdates(exercises: [state], targets: targets, sessionID: sessionID, isFreestyle: false)
        XCTAssertEqual(diff.first?.weight, 60)
        XCTAssertEqual(diff.first?.reps, 8)
        XCTAssertTrue(WorkoutLoggingState.routineUpdates(exercises: [state], targets: [:], sessionID: sessionID, isFreestyle: false).isEmpty)
        XCTAssertTrue(WorkoutLoggingState.routineUpdates(exercises: [state], targets: targets, sessionID: sessionID, isFreestyle: true).isEmpty)
        XCTAssertTrue(WorkoutLoggingState.routineUpdates(exercises: [exercise([], id: exerciseID)], targets: targets, sessionID: sessionID, isFreestyle: false).isEmpty)
    }

    func testEditingCurrentRowReplacesOnlyItsOldPlannedOverride() throws {
        let sessionID = UUID(), exerciseID = UUID()
        var targets: WorkoutLoggingState.Targets = [:]
        for number in [3, 4] {
            targets = try XCTUnwrap(WorkoutLoggingState.savingTarget(
                .init(weight: 65, reps: 8, source: .prepared), in: targets,
                sessionID: sessionID, exerciseID: exerciseID, row: number))
        }
        targets = try XCTUnwrap(WorkoutLoggingState.savingTarget(
            .init(weight: 70, reps: 9, source: .prepared), in: targets,
            sessionID: sessionID, exerciseID: exerciseID, currentRow: 3))
        XCTAssertEqual(WorkoutLoggingState.resolvedTarget(in: targets, sessionID: sessionID,
            exerciseID: exerciseID, row: 3, fallback: nil)?.weight, 70)
        XCTAssertEqual(WorkoutLoggingState.resolvedTarget(in: targets, sessionID: sessionID,
            exerciseID: exerciseID, row: 4, fallback: nil)?.weight, 65)
    }

    func testRepsOnlyEditPreservesExactCanonicalWeightInPounds() {
        XCTAssertEqual(WorkoutLoggingState.canonicalWeight(originalKg: 60, displayWeight: 132.3,
            weightChanged: false, unitSystem: "lb"), 60)
        XCTAssertEqual(WorkoutLoggingState.canonicalWeight(originalKg: 60, displayWeight: 135,
            weightChanged: true, unitSystem: "lb"), 135 / 2.20462, accuracy: 0.000001)
    }

    func testScopedLoggingFormatsExplicitZeroBodyweightAddedLoadAndPounds() {
        XCTAssertEqual(WorkoutTargetFormatter.loggingSetText(weightKg: 0, reps: 10, isBodyweight: false, unitSystem: "kg"), "0 kg × 10")
        XCTAssertEqual(WorkoutTargetFormatter.loggingSetText(weightKg: 0, reps: 10, isBodyweight: true, unitSystem: "kg"), "BW × 10")
        XCTAssertEqual(WorkoutTargetFormatter.loggingSetText(weightKg: 10, reps: 8, isBodyweight: true, unitSystem: "kg"), "BW + 10 kg × 8")
        XCTAssertEqual(WorkoutTargetFormatter.loggingSetText(weightKg: 10, reps: 8, isBodyweight: false, unitSystem: "lb"), "22 lb × 8")
        XCTAssertEqual(WorkoutLoggingState.steppedWeight(10, direction: 1, unitSystem: "lb"), 15)
        XCTAssertEqual(WorkoutLoggingState.steppedWeight(1, direction: -1, unitSystem: "kg"), 0)
        XCTAssertEqual(WorkoutLoggingState.steppedReps(1, direction: -1), 1)
    }
}
