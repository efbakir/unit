import Foundation

/// Value-only decisions for the active workout. Persistence and timer effects
/// stay with their existing owners; the clock is always supplied by the caller.
struct WorkoutLoggingState {
    /// This workout's own changes to its routine: order, swapped and added
    /// exercises, set counts and the skipped last exercise. Saved per session,
    /// so a relaunch keeps them; the routine itself never changes. Older saved
    /// data (order only) still decodes.
    struct SessionPlan: Codable, Equatable {
        let sessionID: UUID
        var exerciseIDs: [UUID] = []
        /// Routine exercise -> the exercise done instead, this workout only.
        var swaps: [UUID: UUID] = [:]
        /// Exercises added to this workout only, in the order they were added.
        var additions: [UUID] = []
        /// Set count picked for an added or freestyle exercise.
        var setCounts: [UUID: Int] = [:]
        /// Rows added with "+ Add set".
        var addedSets: [UUID: Int] = [:]
        var skipped: Set<UUID> = []

        init(sessionID: UUID, exerciseIDs: [UUID] = []) {
            self.sessionID = sessionID
            self.exerciseIDs = exerciseIDs
        }

        private enum CodingKeys: String, CodingKey {
            case sessionID, exerciseIDs, swaps, additions, setCounts, addedSets, skipped
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            sessionID = try container.decode(UUID.self, forKey: .sessionID)
            exerciseIDs = try container.decodeIfPresent([UUID].self, forKey: .exerciseIDs) ?? []
            swaps = try container.decodeIfPresent([UUID: UUID].self, forKey: .swaps) ?? [:]
            additions = try container.decodeIfPresent([UUID].self, forKey: .additions) ?? []
            setCounts = try container.decodeIfPresent([UUID: Int].self, forKey: .setCounts) ?? [:]
            addedSets = try container.decodeIfPresent([UUID: Int].self, forKey: .addedSets) ?? [:]
            skipped = try container.decodeIfPresent(Set<UUID>.self, forKey: .skipped) ?? []
        }
    }

    static func plan(from saved: Data, sessionID: UUID) -> SessionPlan {
        guard let plan = try? JSONDecoder().decode(SessionPlan.self, from: saved),
              plan.sessionID == sessionID else { return SessionPlan(sessionID: sessionID) }
        return plan
    }

    static func encode(_ plan: SessionPlan) -> Data {
        (try? JSONEncoder().encode(plan)) ?? Data()
    }

    /// Routine order with this workout's swaps applied, then added exercises.
    static func orderedExerciseIDs(templateIDs: [UUID], plan: SessionPlan) -> [UUID] {
        let workoutIDs = templateIDs.map { plan.swaps[$0] ?? $0 } + plan.additions
        let valid = Set(workoutIDs)
        var seen = Set<UUID>()
        return (plan.exerciseIDs.map { plan.swaps[$0] ?? $0 } + workoutIDs)
            .filter { valid.contains($0) && seen.insert($0).inserted }
    }

    static func orderedExerciseIDs(templateIDs: [UUID], sessionID: UUID, saved: Data) -> [UUID] {
        orderedExerciseIDs(templateIDs: templateIDs, plan: plan(from: saved, sessionID: sessionID))
    }

    static func encodeExerciseOrder(_ ids: [UUID], sessionID: UUID) -> Data {
        encode(SessionPlan(sessionID: sessionID, exerciseIDs: ids))
    }

    /// The routine exercise whose planned sets and reps a swapped-in exercise uses.
    static func planSourceID(for exerciseID: UUID, in plan: SessionPlan) -> UUID {
        plan.swaps.first(where: { $0.value == exerciseID })?.key ?? exerciseID
    }

    /// Puts `new` where `old` sits in this workout. A swap back to the
    /// routine's own exercise removes the swap. Counts move with it.
    static func swapping(_ old: UUID, with new: UUID, in plan: SessionPlan) -> SessionPlan {
        guard old != new else { return plan }
        var result = plan
        if let index = result.additions.firstIndex(of: old) {
            result.additions[index] = new
        } else {
            let original = planSourceID(for: old, in: plan)
            result.swaps[original] = new == original ? nil : new
        }
        result.exerciseIDs = result.exerciseIDs.map { $0 == old ? new : $0 }
        result.setCounts[new] = result.setCounts.removeValue(forKey: old)
        result.addedSets[new] = result.addedSets.removeValue(forKey: old)
        result.skipped.remove(old)
        return result
    }

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

    /// `skipped` holds exercises skipped for the rest of this workout. Only the
    /// last unfinished exercise is ever skipped this way; earlier skips just
    /// move on and come back later.
    static func currentExerciseID(in exercises: [ExerciseState], selectedID: UUID? = nil,
                                  skipped: Set<UUID> = []) -> UUID? {
        if let selectedID, !skipped.contains(selectedID),
           exercises.contains(where: { $0.id == selectedID }) { return selectedID }
        return exercises.first(where: { !$0.isComplete && !skipped.contains($0.id) })?.id
    }

    static func nextUnfinishedExerciseID(in exercises: [ExerciseState], after id: UUID,
                                         skipped: Set<UUID> = []) -> UUID? {
        let isOpen = { (exercise: ExerciseState) in !exercise.isComplete && !skipped.contains(exercise.id) }
        guard let index = exercises.firstIndex(where: { $0.id == id }) else {
            return exercises.first(where: isOpen)?.id
        }
        return exercises.dropFirst(index + 1).first(where: isOpen)?.id
            ?? exercises.prefix(index).first(where: isOpen)?.id
    }

    /// Every exercise is logged or skipped: the day is over and Finish replaces rest.
    static func isDayDone(_ exercises: [ExerciseState], skipped: Set<UUID> = []) -> Bool {
        !exercises.isEmpty && exercises.allSatisfy { $0.isComplete || skipped.contains($0.id) }
    }

    /// The set the lifter does next: the current exercise's next row, or the
    /// next unfinished exercise's first open row. Nil when the day is done.
    struct UpNext: Equatable {
        let exerciseID: UUID
        let name: String
        let setNumber: Int
    }

    static func upNext(exercises: [ExerciseState], currentExerciseID: UUID?,
                       skipped: Set<UUID> = []) -> UpNext? {
        guard let id = currentExerciseID,
              let current = exercises.first(where: { $0.id == id }) else { return nil }
        if !current.isComplete {
            return UpNext(exerciseID: current.id, name: current.name, setNumber: current.logged.count + 1)
        }
        guard let nextID = nextUnfinishedExerciseID(in: exercises, after: id, skipped: skipped),
              let next = exercises.first(where: { $0.id == nextID }) else { return nil }
        return UpNext(exerciseID: next.id, name: next.name, setNumber: next.logged.count + 1)
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
        exerciseID: UUID, row: Int? = nil, currentRow: Int? = nil
    ) -> Targets? {
        guard target.weight.isFinite, target.weight >= 0, target.reps > 0 else { return nil }
        var result = targets
        if row == nil, let currentRow {
            result[sessionID.uuidString]?[targetKey(exerciseID: exerciseID, row: currentRow)] = nil
        }
        result[sessionID.uuidString, default: [:]][targetKey(exerciseID: exerciseID, row: row)] = target
        return result
    }

    /// Editing reps must never round-trip an unchanged stored load through pounds.
    static func canonicalWeight(originalKg: Double?, displayWeight: Double, weightChanged: Bool, unitSystem: String) -> Double {
        if !weightChanged, let originalKg { return originalKg }
        return unitSystem == "lb" ? displayWeight / 2.20462 : displayWeight
    }

    static func steppedWeight(_ displayWeight: Double, direction: Int, unitSystem: String) -> Double {
        max(0, displayWeight + Double(direction) * (unitSystem == "lb" ? 5 : 2.5))
    }

    static func steppedReps(_ reps: Int, direction: Int) -> Int { max(1, reps + direction) }
}
