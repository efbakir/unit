//
//  WorkoutSession+Editing.swift
//  Unit
//
//  Corrections to a finished workout. PR tags, Analytics, the exercise page
//  and "Last time" read the saved sets, so they follow on their own. What
//  this file keeps right are the two stored copies: the workout's "Next time"
//  evidence and the routine's last-done date. A next target the lifter chose
//  (Keep previous target, Edit) never changes here; one Finish saved by
//  itself follows the corrected sets (decision 2026-10-24).
//

import Foundation
import SwiftData

extension WorkoutSession {
    /// True when the same routine has a later finished workout with logged
    /// work for this exercise. Its suggestion can then no longer be saved.
    @MainActor
    func hasNewerCompletedWorkout(for exerciseID: UUID, in sessions: [WorkoutSession]) -> Bool {
        sessions.contains { candidate in
            candidate.id != id
                && candidate.templateId == templateId
                && candidate.isCompleted
                && candidate.date > date
                && candidate.setEntries.contains(where: {
                    $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup
                })
        }
    }

    /// The logged working sets the "Next time" evidence shows, with the same
    /// rule Finish uses to capture them.
    @MainActor
    func completedProgressionSets(for exerciseID: UUID) -> [CompletedProgressionSet] {
        setEntries
            .filter { $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup }
            .sorted { $0.setIndex < $1.setIndex }
            .compactMap { set in
                guard set.weight.isFinite, set.weight >= 0, set.reps > 0 else { return nil }
                return CompletedProgressionSet(weightKg: set.weight, reps: set.reps)
            }
    }

    /// Rewrites one exercise's "Next time" record after its logged sets changed:
    /// - a target Finish saved and nobody changed, on the routine's newest
    ///   workout, is calculated again and saved again;
    /// - a saved decision keeps its target and shows the corrected sets;
    /// - an unsaved suggestion on the routine's newest workout is calculated
    ///   again from the corrected sets;
    /// - an unsaved suggestion on an older workout is removed, because it can
    ///   no longer be saved.
    @MainActor
    @discardableResult
    func refreshProgressionRecord(
        for exerciseID: UUID,
        template: DayTemplate?,
        exercises: [Exercise],
        sessions: [WorkoutSession]
    ) -> Bool {
        guard let record = progressionRecord(for: exerciseID) else { return false }
        let corrected = completedProgressionSets(for: exerciseID)

        if let template, isCompleted,
           let rolledBack = autoSavedTargetRolledBack(record, template: template, sessions: sessions) {
            guard corrected != record.completedSets else { return false }
            template.setProgressionState(rolledBack, for: exerciseID)
            template.setPlannedReps(rolledBack.currentAcceptedTargetReps, for: exerciseID)
            template.setPlannedWeight(rolledBack.currentAcceptedTargetWeightKg, for: exerciseID)
            setProgressionRecord(nil, for: exerciseID)
            captureProgressionRecords(template: template, exercises: exercises, onlyExerciseIDs: [exerciseID])
            if let recaptured = progressionRecord(for: exerciseID),
               let target = recaptured.suggestedTarget,
               let reason = recaptured.recommendationReason {
                saveProgressionDecision(target, action: .usedSuggestion, reason: reason,
                                        for: exerciseID, template: template)
            }
            return true
        }

        if record.acceptedTarget != nil {
            guard corrected != record.completedSets else { return false }
            setProgressionRecord(record.replacingCompletedSets(corrected), for: exerciseID)
            return true
        }

        setProgressionRecord(nil, for: exerciseID)
        if let template, isCompleted, !hasNewerCompletedWorkout(for: exerciseID, in: sessions) {
            captureProgressionRecords(
                template: template,
                exercises: exercises,
                onlyExerciseIDs: [exerciseID]
            )
        }
        return true
    }

    /// A target Finish saved and nobody changed (2026-10-24) follows an edit
    /// of the routine's newest workout. Returns the routine state as it was
    /// before Finish, so capture can run again; nil when the lifter decided
    /// (Keep previous target, Edit) or a later workout moved the target on.
    @MainActor
    private func autoSavedTargetRolledBack(
        _ record: SessionProgressionRecord,
        template: DayTemplate,
        sessions: [WorkoutSession]
    ) -> ExerciseProgressionState? {
        guard record.decisionAction == .usedSuggestion,
              let saved = record.acceptedTarget, saved == record.suggestedTarget,
              let previous = record.previousTarget,
              let state = template.progressionState(for: record.exerciseID),
              state.sourceWorkoutSessionID == id, state.acceptedTarget == saved,
              !hasNewerCompletedWorkout(for: record.exerciseID, in: sessions) else { return nil }
        // The source before Finish is not stored; without one the previous
        // weight still seeds "Previous target" but no longer prefills.
        return ExerciseProgressionState(
            lowerRepBound: state.lowerRepBound,
            upperRepBound: state.upperRepBound,
            weightIncrementKg: state.weightIncrementKg,
            currentAcceptedTargetWeightKg: previous.weightKg,
            currentAcceptedTargetReps: previous.reps,
            sourceWorkoutSessionID: nil,
            lastAcceptedReason: nil
        )
    }
}

extension SessionProgressionRecord {
    func replacingCompletedSets(_ sets: [CompletedProgressionSet]) -> SessionProgressionRecord {
        SessionProgressionRecord(
            exerciseID: exerciseID,
            exerciseName: exerciseName,
            isBodyweight: isBodyweight,
            configuredSetCount: configuredSetCount,
            lowerRepBound: lowerRepBound,
            upperRepBound: upperRepBound,
            weightIncrementKg: weightIncrementKg,
            previousTarget: previousTarget,
            completedSets: sets,
            suggestedTarget: suggestedTarget,
            recommendationReason: recommendationReason,
            unavailableReason: unavailableReason,
            acceptedTarget: acceptedTarget,
            decisionAction: decisionAction
        )
    }
}

/// Saves corrections to a finished workout in one place. Every change is
/// saved at once; a failed save puts every loaded value back.
enum PastWorkoutEditor {
    struct Context {
        let modelContext: ModelContext
        let sessions: [WorkoutSession]
        let templates: [DayTemplate]
        let exercises: [Exercise]
        /// Tests swap this to prove a failed save leaves everything as it was.
        var save: (ModelContext) throws -> Void = { try $0.save() }

        func template(for session: WorkoutSession) -> DayTemplate? {
            templates.first { $0.id == session.templateId }
        }
    }

    /// New weight (kg) and reps for one logged set.
    static func update(
        _ entry: SetEntry,
        weightKg: Double,
        reps: Int,
        in session: WorkoutSession,
        _ context: Context
    ) -> Bool {
        guard weightKg.isFinite, weightKg >= 0, reps > 0 else { return false }
        entry.weight = weightKg
        entry.reps = reps
        session.refreshProgressionRecord(
            for: entry.exerciseId,
            template: context.template(for: session),
            exercises: context.exercises,
            sessions: context.sessions
        )
        return save(context)
    }

    /// Removes one logged set. Returns the snapshot Undo needs, or nil when
    /// the save failed and nothing changed.
    static func delete(
        _ entry: SetEntry,
        from session: WorkoutSession,
        _ context: Context
    ) -> SetEntrySnapshot? {
        let snapshot = SetEntrySnapshot(entry)
        // Leave the relationship first, so the refreshed evidence below never
        // counts the set being deleted.
        session.setEntries.removeAll { $0.id == entry.id }
        context.modelContext.delete(entry)
        session.refreshProgressionRecord(
            for: snapshot.exerciseID,
            template: context.template(for: session),
            exercises: context.exercises,
            sessions: context.sessions
        )
        return save(context) ? snapshot : nil
    }

    /// Puts a deleted set back with its original id and values.
    static func restore(
        _ snapshot: SetEntrySnapshot,
        in session: WorkoutSession,
        _ context: Context
    ) -> Bool {
        guard !session.setEntries.contains(where: { $0.id == snapshot.id }) else { return false }
        context.modelContext.insert(snapshot.restore(in: session))
        session.refreshProgressionRecord(
            for: snapshot.exerciseID,
            template: context.template(for: session),
            exercises: context.exercises,
            sessions: context.sessions
        )
        return save(context)
    }

    /// Deletes the workout and its sets. When it was the routine's newest
    /// workout, the routine's last-done date goes back to the one before, so
    /// a flexible rotation offers the right routine next. A next target saved
    /// from this workout stays on the routine.
    static func deleteWorkout(_ session: WorkoutSession, _ context: Context) -> Bool {
        context.template(for: session)?.restoreLastPerformedDate(
            removing: session,
            sessions: context.sessions
        )
        context.modelContext.delete(session)
        return save(context)
    }

    private static func save(_ context: Context) -> Bool {
        do {
            try context.save(context.modelContext)
            return true
        } catch {
            context.modelContext.rollbackRestoringLoadedModels()
            return false
        }
    }
}
