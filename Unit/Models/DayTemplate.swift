//
//  DayTemplate.swift
//  Unit
//
//  SwiftData models: split and program day with ordered exercise IDs.
//

import Foundation
import SwiftData

struct DayTemplateExerciseStateSnapshot: Equatable {
    let exerciseID: UUID
    let index: Int
    let plannedSets: Int?
    let plannedReps: Int?
    let plannedWeightKg: Double?
    let progressionState: ExerciseProgressionState?
}

@Model
final class Split {
    var id: UUID
    var name: String
    var orderedTemplateIdsData: Data?
    /// Earliest date this program can generate schedule-derived "missed" days.
    /// Existing stores receive the migration-time default, which is safer than
    /// inventing missed workouts before Unit knew about the program.
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        name: String,
        orderedTemplateIds: [UUID] = [],
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.orderedTemplateIdsData = (try? JSONEncoder().encode(orderedTemplateIds.map { $0.uuidString })) ?? nil
        self.createdAt = createdAt
    }

    var orderedTemplateIds: [UUID] {
        get {
            guard let data = orderedTemplateIdsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded.compactMap { UUID(uuidString: $0) }
        }
        set {
            orderedTemplateIdsData = try? JSONEncoder().encode(newValue.map { $0.uuidString })
        }
    }
}

/// UserDefaults-backed pointer to the user's currently active `Split`.
/// Fallback: first split by name (legacy behavior) when nothing is set.
/// Views that need reactivity should bind `@AppStorage("activeSplitId")` so
/// SwiftUI re-evaluates when the user switches programs.
enum ActiveSplitStore {
    static let defaultsKey = "activeSplitId"

    static func currentId() -> UUID? {
        guard let raw = UserDefaults.standard.string(forKey: defaultsKey),
              let uuid = UUID(uuidString: raw) else { return nil }
        return uuid
    }

    static func setCurrent(_ id: UUID?) {
        if let id {
            UserDefaults.standard.set(id.uuidString, forKey: defaultsKey)
        } else {
            UserDefaults.standard.removeObject(forKey: defaultsKey)
        }
    }

    static func resolve(from splits: [Split]) -> Split? {
        if let id = currentId(), let match = splits.first(where: { $0.id == id }) {
            return match
        }
        return splits.first
    }
}

@Model
final class DayTemplate {
    var id: UUID
    var name: String
    var splitId: UUID?
    var orderedExerciseIdsData: Data?
    var lastPerformedDate: Date?
    /// Calendar weekday: 1=Sun, 2=Mon … 7=Sat.  0 = unscheduled (rotation mode).
    var scheduledWeekday: Int = 0
    /// Per-exercise planned set count, used as the first-session ghost before any
    /// real history exists. JSON-encoded `[exerciseId.uuidString: Int]`.
    var plannedSetsByExerciseIdData: Data?
    /// Per-exercise planned rep count, used as the first-session ghost before any
    /// real history exists. JSON-encoded `[exerciseId.uuidString: Int]`.
    var plannedRepsByExerciseIdData: Data?
    /// Per-exercise planned weight (kg), used as the first-session starting
    /// target before any real history exists — seeded from weights in a
    /// pasted program so day-one sets aren't blank. JSON-encoded
    /// `[exerciseId.uuidString: Double]`. Optional/additive: pre-existing
    /// templates decode to `[:]` and behave exactly as before (blank weight).
    var plannedWeightByExerciseIdData: Data?
    /// Optional v2.1 double-progression state keyed by exercise ID. Existing or
    /// corrupt stores decode to an empty map and remain unconfigured.
    var progressionStateByExerciseIdData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        splitId: UUID? = nil,
        orderedExerciseIds: [UUID] = [],
        lastPerformedDate: Date? = nil,
        scheduledWeekday: Int = 0,
        plannedSetsByExerciseId: [UUID: Int] = [:],
        plannedRepsByExerciseId: [UUID: Int] = [:],
        plannedWeightByExerciseId: [UUID: Double] = [:],
        progressionStateByExerciseId: [UUID: ExerciseProgressionState] = [:]
    ) {
        self.id = id
        self.name = name
        self.splitId = splitId
        self.orderedExerciseIdsData = (try? JSONEncoder().encode(orderedExerciseIds.map { $0.uuidString })) ?? nil
        self.lastPerformedDate = lastPerformedDate
        self.scheduledWeekday = scheduledWeekday
        self.plannedSetsByExerciseIdData = Self.encodePlanMap(plannedSetsByExerciseId)
        self.plannedRepsByExerciseIdData = Self.encodePlanMap(plannedRepsByExerciseId)
        self.plannedWeightByExerciseIdData = Self.encodeWeightMap(plannedWeightByExerciseId)
        self.progressionStateByExerciseIdData = Self.encodeProgressionMap(progressionStateByExerciseId)
    }

    /// Strips "Day N · " prefix if present, returning just the routine name.
    var displayName: String {
        let pattern = /^Day\s+\d+\s*·\s*/
        let stripped = name.replacing(pattern, with: "")
        return stripped.isEmpty ? name : stripped
    }

    var orderedExerciseIds: [UUID] {
        get {
            guard let data = orderedExerciseIdsData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded.compactMap { UUID(uuidString: $0) }
        }
        set {
            orderedExerciseIdsData = try? JSONEncoder().encode(newValue.map { $0.uuidString })
        }
    }

    var plannedSetsByExerciseId: [UUID: Int] {
        get { Self.decodePlanMap(plannedSetsByExerciseIdData) }
        set { plannedSetsByExerciseIdData = Self.encodePlanMap(newValue) }
    }

    var plannedRepsByExerciseId: [UUID: Int] {
        get { Self.decodePlanMap(plannedRepsByExerciseIdData) }
        set { plannedRepsByExerciseIdData = Self.encodePlanMap(newValue) }
    }

    var plannedWeightByExerciseId: [UUID: Double] {
        get { Self.decodeWeightMap(plannedWeightByExerciseIdData) }
        set { plannedWeightByExerciseIdData = Self.encodeWeightMap(newValue) }
    }

    var progressionStateByExerciseId: [UUID: ExerciseProgressionState] {
        get { Self.decodeProgressionMap(progressionStateByExerciseIdData) }
        set { progressionStateByExerciseIdData = Self.encodeProgressionMap(newValue) }
    }

    func plannedSets(for exerciseId: UUID) -> Int? { plannedSetsByExerciseId[exerciseId] }
    func plannedReps(for exerciseId: UUID) -> Int? { plannedRepsByExerciseId[exerciseId] }
    func plannedWeight(for exerciseId: UUID) -> Double? { plannedWeightByExerciseId[exerciseId] }
    func progressionState(for exerciseId: UUID) -> ExerciseProgressionState? {
        progressionStateByExerciseId[exerciseId]
    }

    func setPlannedSets(_ value: Int?, for exerciseId: UUID) {
        var map = plannedSetsByExerciseId
        if let value { map[exerciseId] = value } else { map.removeValue(forKey: exerciseId) }
        plannedSetsByExerciseId = map
    }

    func setPlannedReps(_ value: Int?, for exerciseId: UUID) {
        var map = plannedRepsByExerciseId
        if let value { map[exerciseId] = value } else { map.removeValue(forKey: exerciseId) }
        plannedRepsByExerciseId = map
    }

    func setPlannedWeight(_ value: Double?, for exerciseId: UUID) {
        var map = plannedWeightByExerciseId
        if let value { map[exerciseId] = value } else { map.removeValue(forKey: exerciseId) }
        plannedWeightByExerciseId = map
    }

    func setProgressionState(_ value: ExerciseProgressionState?, for exerciseId: UUID) {
        var map = progressionStateByExerciseId
        if let value { map[exerciseId] = value } else { map.removeValue(forKey: exerciseId) }
        progressionStateByExerciseId = map
    }

    /// Applies one user-approved absolute target to the routine. This mutates
    /// only the in-memory model; the caller owns the surrounding save/rollback
    /// transaction so a group of recommendations commits atomically.
    @MainActor
    @discardableResult
    func acceptProgressionRecommendation(
        _ recommendation: DoubleProgressionRecommendation,
        for exerciseID: UUID
    ) -> Bool {
        guard let state = progressionState(for: exerciseID),
              state.configuration(workingSetCount: 1).isValid,
              recommendation.target.weightKg.isFinite,
              recommendation.target.weightKg > 0,
              recommendation.target.reps >= state.lowerRepBound,
              recommendation.target.reps <= state.upperRepBound else {
            return false
        }

        let accepted = DoubleProgressionEngine.accepting(recommendation, into: state)
        setProgressionState(accepted, for: exerciseID)
        setPlannedReps(recommendation.target.reps, for: exerciseID)
        setPlannedWeight(recommendation.target.weightKg, for: exerciseID)
        return true
    }

    /// Removes one routine exercise and every per-exercise value as one model
    /// operation. The returned snapshot is sufficient for an exact Undo.
    @discardableResult
    func removeExerciseAndCaptureState(_ exerciseID: UUID) -> DayTemplateExerciseStateSnapshot? {
        var ids = orderedExerciseIds
        guard let index = ids.firstIndex(of: exerciseID) else { return nil }

        let snapshot = DayTemplateExerciseStateSnapshot(
            exerciseID: exerciseID,
            index: index,
            plannedSets: plannedSets(for: exerciseID),
            plannedReps: plannedReps(for: exerciseID),
            plannedWeightKg: plannedWeight(for: exerciseID),
            progressionState: progressionState(for: exerciseID)
        )

        ids.remove(at: index)
        orderedExerciseIds = ids
        setPlannedSets(nil, for: exerciseID)
        setPlannedReps(nil, for: exerciseID)
        setPlannedWeight(nil, for: exerciseID)
        setProgressionState(nil, for: exerciseID)
        return snapshot
    }

    func restoreExerciseState(_ snapshot: DayTemplateExerciseStateSnapshot) {
        var ids = orderedExerciseIds.filter { $0 != snapshot.exerciseID }
        let safeIndex = min(max(snapshot.index, 0), ids.count)
        ids.insert(snapshot.exerciseID, at: safeIndex)
        orderedExerciseIds = ids
        setPlannedSets(snapshot.plannedSets, for: snapshot.exerciseID)
        setPlannedReps(snapshot.plannedReps, for: snapshot.exerciseID)
        setPlannedWeight(snapshot.plannedWeightKg, for: snapshot.exerciseID)
        setProgressionState(snapshot.progressionState, for: snapshot.exerciseID)
    }

    private static func encodePlanMap(_ map: [UUID: Int]) -> Data? {
        let stringKeyed = Dictionary(uniqueKeysWithValues: map.map { ($0.key.uuidString, $0.value) })
        return try? JSONEncoder().encode(stringKeyed)
    }

    private static func decodePlanMap(_ data: Data?) -> [UUID: Int] {
        guard let data,
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data) else {
            return [:]
        }
        var result: [UUID: Int] = [:]
        for (key, value) in decoded {
            if let uuid = UUID(uuidString: key) { result[uuid] = value }
        }
        return result
    }

    private static func encodeWeightMap(_ map: [UUID: Double]) -> Data? {
        let stringKeyed = Dictionary(uniqueKeysWithValues: map.map { ($0.key.uuidString, $0.value) })
        return try? JSONEncoder().encode(stringKeyed)
    }

    private static func decodeWeightMap(_ data: Data?) -> [UUID: Double] {
        guard let data,
              let decoded = try? JSONDecoder().decode([String: Double].self, from: data) else {
            return [:]
        }
        var result: [UUID: Double] = [:]
        for (key, value) in decoded {
            if let uuid = UUID(uuidString: key) { result[uuid] = value }
        }
        return result
    }

    private static func encodeProgressionMap(_ map: [UUID: ExerciseProgressionState]) -> Data? {
        let stringKeyed = Dictionary(uniqueKeysWithValues: map.map { ($0.key.uuidString, $0.value) })
        return try? JSONEncoder().encode(stringKeyed)
    }

    private static func decodeProgressionMap(_ data: Data?) -> [UUID: ExerciseProgressionState] {
        guard let data,
              let decoded = try? JSONDecoder().decode([String: ExerciseProgressionState].self, from: data) else {
            return [:]
        }
        var result: [UUID: ExerciseProgressionState] = [:]
        for (key, value) in decoded {
            if let uuid = UUID(uuidString: key) { result[uuid] = value }
        }
        return result
    }

    /// Inserts a fresh in-progress `WorkoutSession` for this template, stamps
    /// `lastPerformedDate`, and saves. Single source of truth for the
    /// start-of-session sequence — both `TodayView` and `TemplatesView`'s
    /// sticky CTAs go through here so the two paths can never drift.
    @MainActor
    @discardableResult
    func startWorkoutSession(in modelContext: ModelContext) -> WorkoutSession {
        let session = WorkoutSession(
            date: Date(),
            templateId: id,
            isCompleted: false
        )
        modelContext.insert(session)
        lastPerformedDate = session.date
        try? modelContext.save()
        return session
    }

    /// Undo the start stamp when `removed` (a cancelled or auto-discarded
    /// start) is deleted. A flexible rotation picks the routine with the
    /// oldest `lastPerformedDate`, so a cancelled start must not move it on.
    @MainActor
    func restoreLastPerformedDate(removing removed: WorkoutSession, sessions: [WorkoutSession]) {
        guard lastPerformedDate == removed.date else { return }
        lastPerformedDate = sessions
            .filter { $0.templateId == id && $0.isCompleted && $0.id != removed.id }
            .map(\.date)
            .max()
    }
}

/// Shared target-editor input for Today and routine details.
struct RoutineTargetEdit: Identifiable {
    let templateID: UUID
    let exerciseID: UUID
    let exerciseName: String
    let setCount: Int
    let reps: Int
    let progression: DoubleProgressionConfiguration?
    var id: UUID { exerciseID }
}

@MainActor
extension DayTemplate {
    func targetEdit(for exercise: Exercise, sessions: [WorkoutSession],
                    defaultSets: Int, defaultReps: Int) -> RoutineTargetEdit {
        let history = SetEntry.latestValidWorkingSets(for: exercise.id, in: sessions)
        let sets = plannedSets(for: exercise.id).flatMap { $0 > 0 ? $0 : nil }
            ?? (history.isEmpty ? defaultSets : history.count)
        let reps = plannedReps(for: exercise.id).flatMap { $0 > 0 ? $0 : nil }
            ?? history.last?.reps ?? defaultReps
        return RoutineTargetEdit(templateID: id, exerciseID: exercise.id,
                                 exerciseName: exercise.displayName, setCount: sets, reps: reps,
                                 progression: progressionState(for: exercise.id)?.configuration(workingSetCount: sets))
    }

    /// Mutate the same configuration regardless of the screen that opened it.
    /// Callers save and restore their model context on failure.
    func applyTarget(setCount: Int, reps: Int, progression: DoubleProgressionConfiguration?,
                     for exerciseID: UUID, sessions: [WorkoutSession]) {
        setPlannedSets(setCount, for: exerciseID)

        if let progression {
            let previous = progressionState(for: exerciseID)
            let targetReps = min(
                max(
                    previous?.currentAcceptedTargetReps ?? progression.lowerRepBound,
                    progression.lowerRepBound
                ),
                progression.upperRepBound
            )
            // Editing sets, the rep range or the weight step keeps an accepted
            // target: its weight still applies and its reps are clamped into
            // the new range above. Clearing its source here used to drop the
            // accepted weight jump from the next workout without any message.
            let state = ExerciseProgressionState(
                lowerRepBound: progression.lowerRepBound,
                upperRepBound: progression.upperRepBound,
                weightIncrementKg: progression.weightIncrementKg,
                currentAcceptedTargetWeightKg: previous?.currentAcceptedTargetWeightKg
                    ?? progressionSeedWeight(for: exerciseID, sessions: sessions),
                currentAcceptedTargetReps: targetReps,
                sourceWorkoutSessionID: previous?.sourceWorkoutSessionID,
                lastAcceptedReason: previous?.lastAcceptedReason
            )
            setProgressionState(state, for: exerciseID)
            setPlannedReps(targetReps, for: exerciseID)
        } else {
            setProgressionState(nil, for: exerciseID)
            setPlannedReps(reps, for: exerciseID)
        }
    }

    private func progressionSeedWeight(for exerciseID: UUID, sessions: [WorkoutSession]) -> Double? {
        if let planned = plannedWeight(for: exerciseID), planned > 0 {
            return planned
        }

        return sessions.first(where: { candidate in
            candidate.templateId == id
                && candidate.isCompleted
                && candidate.setEntries.contains(where: {
                    $0.exerciseId == exerciseID
                        && $0.isCompleted
                        && !$0.isWarmup
                        && $0.weight > 0
                })
        })?
        .setEntries
        .filter {
            $0.exerciseId == exerciseID
                && $0.isCompleted
                && !$0.isWarmup
                && $0.weight > 0
        }
        .sorted { $0.setIndex < $1.setIndex }
        .last?
        .weight
    }

}
