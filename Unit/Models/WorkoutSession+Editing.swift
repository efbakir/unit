//
//  WorkoutSession+Editing.swift
//  Unit
//
//  Corrections to a finished workout. PR tags, Analytics, the exercise page
//  and "Last time" read the saved sets, so they follow on their own. What
//  this file keeps right are the two stored copies: the workout's "Next time"
//  evidence and the routine's last-done date. A next target the lifter saved
//  never changes here (PRODUCT.md, principle 2).
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
    /// - a suggestion Finish saved by itself (2026-10-24) on the routine's
    ///   newest workout is calculated and saved again from the corrected sets;
    /// - any other saved decision (kept, edited) keeps its target and shows
    ///   the corrected sets;
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
        let isNewest = isCompleted && !hasNewerCompletedWorkout(for: exerciseID, in: sessions)

        if let template, isNewest,
           record.decisionAction == .usedSuggestion,
           record.acceptedTarget != nil,
           record.acceptedTarget == record.suggestedTarget,
           let state = template.progressionState(for: exerciseID),
           state.sourceWorkoutSessionID == id {
            // Put the routine back where Finish found it, so the new
            // suggestion starts from the same previous target.
            template.setProgressionState(ExerciseProgressionState(
                lowerRepBound: state.lowerRepBound,
                upperRepBound: state.upperRepBound,
                weightIncrementKg: state.weightIncrementKg,
                currentAcceptedTargetWeightKg: record.previousTarget?.weightKg,
                currentAcceptedTargetReps: record.previousTarget?.reps ?? state.lowerRepBound,
                sourceWorkoutSessionID: nil,
                lastAcceptedReason: nil
            ), for: exerciseID)
            setProgressionRecord(nil, for: exerciseID)
            captureProgressionRecords(template: template, exercises: exercises, onlyExerciseIDs: [exerciseID])
            applySuggestedTargets(to: template)
            return true
        }

        if record.acceptedTarget != nil {
            guard corrected != record.completedSets else { return false }
            setProgressionRecord(record.replacingCompletedSets(corrected), for: exerciseID)
            return true
        }

        setProgressionRecord(nil, for: exerciseID)
        if let template, isNewest {
            captureProgressionRecords(
                template: template,
                exercises: exercises,
                onlyExerciseIDs: [exerciseID]
            )
        }
        return true
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
        /// Removes a deleted workout's Apple Health copy; does nothing when
        /// Apple Health is off. Tests swap it.
        var removeFromHealth: (UUID) -> Void = { HealthWorkoutSync.removeWorkout(sessionID: $0) }

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
        let sessionID = session.id
        context.template(for: session)?.restoreLastPerformedDate(
            removing: session,
            sessions: context.sessions
        )
        context.modelContext.delete(session)
        guard save(context) else { return false }
        context.removeFromHealth(sessionID)
        return true
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
