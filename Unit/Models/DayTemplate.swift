//
//  DayTemplate.swift
//  Unit
//
//  SwiftData models: split and program day with ordered exercise IDs.
//

import Foundation
import SwiftData

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
    /// Per-exercise planned weight (kg), used as the first-session "Last time"
    /// ghost before any real history exists — seeded from the weights in a
    /// pasted program so day-one sets aren't blank. JSON-encoded
    /// `[exerciseId.uuidString: Double]`. Optional/additive: pre-existing
    /// templates decode to `[:]` and behave exactly as before (blank weight).
    var plannedWeightByExerciseIdData: Data?

    init(
        id: UUID = UUID(),
        name: String,
        splitId: UUID? = nil,
        orderedExerciseIds: [UUID] = [],
        lastPerformedDate: Date? = nil,
        scheduledWeekday: Int = 0,
        plannedSetsByExerciseId: [UUID: Int] = [:],
        plannedRepsByExerciseId: [UUID: Int] = [:],
        plannedWeightByExerciseId: [UUID: Double] = [:]
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

    func plannedSets(for exerciseId: UUID) -> Int? { plannedSetsByExerciseId[exerciseId] }
    func plannedReps(for exerciseId: UUID) -> Int? { plannedRepsByExerciseId[exerciseId] }
    func plannedWeight(for exerciseId: UUID) -> Double? { plannedWeightByExerciseId[exerciseId] }

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
}
