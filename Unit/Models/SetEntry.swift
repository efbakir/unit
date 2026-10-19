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

    static func latestValidWorkingSets(
        for exerciseID: UUID,
        in sessions: [WorkoutSession],
        excluding sessionID: UUID? = nil
    ) -> [SetEntry] {
        for session in sessions.sorted(by: { $0.date > $1.date })
        where session.isCompleted && session.id != sessionID {
            let entries = session.setEntries
                .filter { $0.exerciseId == exerciseID && $0.isValidCompletedWorkingSet }
                .sorted { $0.setIndex < $1.setIndex }
            if !entries.isEmpty { return entries }
        }
        return []
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
