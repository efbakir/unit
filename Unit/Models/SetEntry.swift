//
//  SetEntry.swift
//  Unit
//
//  SwiftData model: one set (weight, reps, RPE, warmup, completed).
//

import Foundation
import SwiftData

@Model
final class SetEntry {
    var id: UUID
    var sessionId: UUID
    var exerciseId: UUID
    var weight: Double
    var reps: Int
    /// 1–10; 0 = not set. Kept for legacy data.
    var rpe: Double
    /// Reps In Reserve: 0–5; -1 = not set.
    var rir: Int
    var isWarmup: Bool
    var isCompleted: Bool
    var setIndex: Int
    var note: String

    @Relationship(inverse: \WorkoutSession.setEntries)
    var session: WorkoutSession?

    init(
        id: UUID = UUID(),
        sessionId: UUID,
        exerciseId: UUID,
        weight: Double = 0,
        reps: Int = 0,
        rpe: Double = 0,
        rir: Int = -1,
        isWarmup: Bool = false,
        isCompleted: Bool = false,
        setIndex: Int = 0,
        note: String = ""
    ) {
        self.id = id
        self.sessionId = sessionId
        self.exerciseId = exerciseId
        self.weight = weight
        self.reps = reps
        self.rpe = rpe
        self.rir = rir
        self.isWarmup = isWarmup
        self.isCompleted = isCompleted
        self.setIndex = setIndex
        self.note = note
    }
}

// A history source must represent usable completed work, including explicit BW.
extension SetEntry {
    var isValidCompletedWorkingSet: Bool {
        isCompleted && !isWarmup && weight.isFinite && weight >= 0 && reps > 0
    }

    /// Newest finished workout with valid sets of this exercise. With a
    /// routine, that routine's newest workout wins over newer workouts of
    /// other routines, so a heavy day and a light day keep their own numbers.
    static func latestValidWorkingSets(
        for exerciseID: UUID,
        in sessions: [WorkoutSession],
        excluding sessionID: UUID? = nil,
        preferringTemplate templateID: UUID? = nil
    ) -> [SetEntry] {
        var otherRoutine: [SetEntry] = []
        for session in sessions.sorted(by: { $0.date > $1.date })
        where session.isCompleted && session.id != sessionID {
            let entries = session.setEntries
                .filter { $0.exerciseId == exerciseID && $0.isValidCompletedWorkingSet }
                .sorted { $0.setIndex < $1.setIndex }
            guard !entries.isEmpty else { continue }
            if templateID == nil || session.templateId == templateID { return entries }
            if otherRoutine.isEmpty { otherRoutine = entries }
        }
        return otherRoutine
    }
}

/// Complete value snapshot: Undo recreates the same set, never a new log event.
struct SetEntrySnapshot {
    let id: UUID
    let sessionID: UUID
    let exerciseID: UUID
    let weight: Double
    let reps: Int
    let rpe: Double
    let rir: Int
    let isWarmup: Bool
    let isCompleted: Bool
    let setIndex: Int
    let note: String

    init(_ entry: SetEntry) {
        id = entry.id; sessionID = entry.sessionId; exerciseID = entry.exerciseId
        weight = entry.weight; reps = entry.reps; rpe = entry.rpe; rir = entry.rir
        isWarmup = entry.isWarmup; isCompleted = entry.isCompleted
        setIndex = entry.setIndex; note = entry.note
    }

    func restore(in session: WorkoutSession) -> SetEntry {
        let entry = SetEntry(id: id, sessionId: sessionID, exerciseId: exerciseID,
                             weight: weight, reps: reps, rpe: rpe, rir: rir,
                             isWarmup: isWarmup, isCompleted: isCompleted,
                             setIndex: setIndex, note: note)
        entry.session = session
        return entry
    }
}

// SwiftData on iOS 18 can leave loaded model values stale after rollback.
// Keep the committed values in a separate read context and restore the same
// loaded instances, so a failed save cannot look completed or half-deleted.
extension ModelContext {
    func rollbackRestoringLoadedModels() {
        processPendingChanges()
        let inserted = Set(insertedModelsArray.map(\.persistentModelID))
        let affected = changedModelsArray + deletedModelsArray
        let reader = ModelContext(container)
        reader.autosaveEnabled = false
        var seen = Set<PersistentIdentifier>()
        var restore: [() -> Void] = []
        for model in affected {
            let id = model.persistentModelID
            guard !inserted.contains(id), seen.insert(id).inserted else { continue }
            switch model {
            case let loaded as WorkoutSession:
                guard let saved = reader.model(for: id) as? WorkoutSession else { continue }
                let date = saved.date
                let templateId = saved.templateId
                let isCompleted = saved.isCompleted
                let progressionRecordsByExerciseIdData = saved.progressionRecordsByExerciseIdData
                let entryIDs = saved.setEntries.map(\.persistentModelID)
                restore.append {
                    loaded.date = date
                    loaded.templateId = templateId
                    loaded.isCompleted = isCompleted
                    loaded.progressionRecordsByExerciseIdData = progressionRecordsByExerciseIdData
                    loaded.setEntries = entryIDs.compactMap { self.model(for: $0) as? SetEntry }
                }
            case let loaded as SetEntry:
                guard let saved = reader.model(for: id) as? SetEntry else { continue }
                let sessionId = saved.sessionId
                let exerciseId = saved.exerciseId
                let weight = saved.weight
                let reps = saved.reps
                let rpe = saved.rpe
                let rir = saved.rir
                let isWarmup = saved.isWarmup
                let isCompleted = saved.isCompleted
                let setIndex = saved.setIndex
                let note = saved.note
                restore.append {
                    loaded.sessionId = sessionId
                    loaded.exerciseId = exerciseId
                    loaded.weight = weight
                    loaded.reps = reps
                    loaded.rpe = rpe
                    loaded.rir = rir
                    loaded.isWarmup = isWarmup
                    loaded.isCompleted = isCompleted
                    loaded.setIndex = setIndex
                    loaded.note = note
                }
            case let loaded as DayTemplate:
                guard let saved = reader.model(for: id) as? DayTemplate else { continue }
                let name = saved.name
                let splitId = saved.splitId
                let orderedExerciseIdsData = saved.orderedExerciseIdsData
                let lastPerformedDate = saved.lastPerformedDate
                let scheduledWeekday = saved.scheduledWeekday
                let plannedSetsByExerciseIdData = saved.plannedSetsByExerciseIdData
                let plannedRepsByExerciseIdData = saved.plannedRepsByExerciseIdData
                let plannedWeightByExerciseIdData = saved.plannedWeightByExerciseIdData
                let progressionStateByExerciseIdData = saved.progressionStateByExerciseIdData
                restore.append {
                    loaded.name = name
                    loaded.splitId = splitId
                    loaded.orderedExerciseIdsData = orderedExerciseIdsData
                    loaded.lastPerformedDate = lastPerformedDate
                    loaded.scheduledWeekday = scheduledWeekday
                    loaded.plannedSetsByExerciseIdData = plannedSetsByExerciseIdData
                    loaded.plannedRepsByExerciseIdData = plannedRepsByExerciseIdData
                    loaded.plannedWeightByExerciseIdData = plannedWeightByExerciseIdData
                    loaded.progressionStateByExerciseIdData = progressionStateByExerciseIdData
                }
            case let loaded as Exercise:
                guard let saved = reader.model(for: id) as? Exercise else { continue }
                let displayName = saved.displayName
                let aliasesData = saved.aliasesData
                let notes = saved.notes
                let isBodyweight = saved.isBodyweight
                let isArchived = saved.isArchived
                let muscleGroupRaw = saved.muscleGroupRaw
                let equipmentRaw = saved.equipmentRaw
                restore.append {
                    loaded.displayName = displayName
                    loaded.aliasesData = aliasesData
                    loaded.notes = notes
                    loaded.isBodyweight = isBodyweight
                    loaded.isArchived = isArchived
                    loaded.muscleGroupRaw = muscleGroupRaw
                    loaded.equipmentRaw = equipmentRaw
                }
            case let loaded as Split:
                guard let saved = reader.model(for: id) as? Split else { continue }
                let name = saved.name
                let orderedTemplateIdsData = saved.orderedTemplateIdsData
                let createdAt = saved.createdAt
                restore.append {
                    loaded.name = name
                    loaded.orderedTemplateIdsData = orderedTemplateIdsData
                    loaded.createdAt = createdAt
                }
            default: break
            }
        }
        rollback()
        restore.forEach { $0() }
    }
}
