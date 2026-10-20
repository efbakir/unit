import Foundation

/// Value-only decisions for the active workout. Persistence and timer effects
/// stay with their existing owners; the clock is always supplied by the caller.
struct WorkoutLoggingState {
    struct Entry: Equatable {
        let id: UUID
        let weight: Double
        let reps: Int
        let setIndex: Int
        var isCompleted = true
        var isWarmup = false

        var isValid: Bool {
            isCompleted && !isWarmup && weight.isFinite && weight >= 0 && reps > 0
        }
    }

    struct ExerciseState: Identifiable {
        let id: UUID
        let name: String
        let plannedCount: Int
        let entries: [Entry]

        var logged: [Entry] {
            entries.filter(\.isValid).sorted { $0.setIndex < $1.setIndex }
        }
        var isComplete: Bool { logged.count >= max(1, plannedCount) }
    }

    struct Row: Identifiable, Equatable {
        enum Kind: Equatable { case logged(UUID), current, planned }
        let number: Int
        let kind: Kind
        var id: Int { number }
    }

    struct ExerciseGroup: Identifiable {
        let id: UUID
        var exerciseIDs: [UUID]
        let isUpcoming: Bool
    }

    static func groups(exercises: [ExerciseState], currentID: UUID?, expandedID: UUID?) -> [ExerciseGroup] {
        var groups: [ExerciseGroup] = []
        for exercise in exercises {
            let upcoming = exercise.id != currentID && exercise.id != expandedID
                && exercise.logged.isEmpty && !exercise.isComplete
            if upcoming, let last = groups.indices.last, groups[last].isUpcoming {
                groups[last].exerciseIDs.append(exercise.id)
            } else {
                groups.append(ExerciseGroup(id: exercise.id, exerciseIDs: [exercise.id], isUpcoming: upcoming))
            }
        }
        return groups
    }

    struct RoutineUpdate: Equatable {
        let exerciseID: UUID
        let name: String
        let weight: Double
        let reps: Int
    }

    struct Undo: Equatable {
        let entryID: UUID
        let exerciseID: UUID
        let expiresAt: Date
    }

    private(set) var lastLogAt: Date?
    private(set) var undo: Undo?
    static let guardDuration: TimeInterval = 0.4
    static let undoDuration: TimeInterval = 5

    func canLog(at now: Date) -> Bool {
        guard let lastLogAt else { return true }
        return now.timeIntervalSince(lastLogAt) >= Self.guardDuration
    }

    /// Call only after the durable insert succeeds. A failed save consumes neither
    /// the guard nor the previous Undo window.
    mutating func didLog(entryID: UUID, exerciseID: UUID, at now: Date) {
        lastLogAt = now
        undo = Undo(entryID: entryID, exerciseID: exerciseID,
                    expiresAt: now.addingTimeInterval(Self.undoDuration))
    }

    func availableUndo(at now: Date) -> Undo? {
        guard let undo, now < undo.expiresAt else { return nil }
        return undo
    }

    mutating func invalidateUndo() { undo = nil }

    static func rows(for exercise: ExerciseState, isCurrent: Bool) -> [Row] {
        let logged = exercise.logged
        return (0..<max(logged.count, max(1, exercise.plannedCount))).map { index in
            let kind: Row.Kind = index < logged.count ? .logged(logged[index].id)
                : (isCurrent && index == logged.count ? .current : .planned)
            return Row(number: index + 1, kind: kind)
        }
    }

    static func currentExerciseID(in exercises: [ExerciseState], selectedID: UUID? = nil) -> UUID? {
        if let selectedID, exercises.contains(where: { $0.id == selectedID }) { return selectedID }
        return exercises.first(where: { !$0.isComplete })?.id
    }

    static func nextUnfinishedExerciseID(in exercises: [ExerciseState], after id: UUID) -> UUID? {
        guard let index = exercises.firstIndex(where: { $0.id == id }) else {
            return exercises.first(where: { !$0.isComplete })?.id
        }
        return exercises.dropFirst(index + 1).first(where: { !$0.isComplete })?.id
            ?? exercises.prefix(index).first(where: { !$0.isComplete })?.id
    }

    static func upNextText(exercises: [ExerciseState], currentExerciseID: UUID?) -> String? {
        guard let id = currentExerciseID,
              let current = exercises.first(where: { $0.id == id }) else { return nil }
        if !current.isComplete { return "\(current.name) · Set \(current.logged.count + 1)" }
        guard let nextID = nextUnfinishedExerciseID(in: exercises, after: id),
              let next = exercises.first(where: { $0.id == nextID }) else { return nil }
        return "\(next.name) · Set \(next.logged.count + 1)"
    }

    static func shouldStopRest(removing entryID: UUID, sourceEntryID: UUID?) -> Bool {
        entryID == sourceEntryID
    }

    typealias Targets = [String: [String: SetPrefill]]

    static func decodeTargets(_ data: Data) -> Targets {
        (try? JSONDecoder().decode(Targets.self, from: data)) ?? [:]
    }

    static func targetKey(exerciseID: UUID, row: Int? = nil) -> String {
        exerciseID.uuidString + (row.map { "#\($0)" } ?? "")
    }

    static func resolvedTarget(
        in targets: Targets, sessionID: UUID, exerciseID: UUID,
        row: Int, fallback: SetPrefill?
    ) -> SetPrefill? {
        let session = targets[sessionID.uuidString] ?? [:]
        return session[targetKey(exerciseID: exerciseID, row: row)]
            ?? session[targetKey(exerciseID: exerciseID)] ?? fallback
    }

    static func savingTarget(
        _ target: SetPrefill, in targets: Targets, sessionID: UUID,
        exerciseID: UUID, row: Int? = nil
    ) -> Targets? {
        guard target.weight.isFinite, target.weight >= 0, target.reps > 0 else { return nil }
        var result = targets
        result[sessionID.uuidString, default: [:]][targetKey(exerciseID: exerciseID, row: row)] = target
        return result
    }

    static func routineUpdates(
        exercises: [ExerciseState], targets: Targets, sessionID: UUID, isFreestyle: Bool
    ) -> [RoutineUpdate] {
        guard !isFreestyle else { return [] }
        let saved = targets[sessionID.uuidString] ?? [:]
        return exercises.compactMap { exercise in
            guard saved[targetKey(exerciseID: exercise.id)] != nil,
                  let first = exercise.logged.first else { return nil }
            return RoutineUpdate(exerciseID: exercise.id, name: exercise.name,
                                 weight: first.weight, reps: first.reps)
        }
    }

    static func steppedWeight(_ displayWeight: Double, direction: Int, unitSystem: String) -> Double {
        max(0, displayWeight + Double(direction) * (unitSystem == "lb" ? 5 : 2.5))
    }

    static func steppedReps(_ reps: Int, direction: Int) -> Int { max(1, reps + direction) }
}
