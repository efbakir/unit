//
//  HealthWorkoutStore.swift
//  Unit
//
//  Saves finished workouts to Apple Health when the lifter turns it on in
//  Settings. Write-only: Unit never reads Health data. Each saved workout
//  carries the Unit session id, so removing a workout can find its copy.
//

import Foundation
import HealthKit
import os

protocol HealthWorkoutWriting {
    var isAvailable: Bool { get }
    var canSave: Bool { get }
    func requestAccess() async -> Bool
    func save(sessionID: UUID, interval: DateInterval) async throws
    func remove(sessionID: UUID) async throws
}

/// When a finished workout may be written. Unit stores only a start time, so
/// only a workout finished live has a real end. App Review 5.1.3(ii) bans
/// writing inaccurate data to Health, so anything outside these limits is skipped.
enum HealthWorkoutPolicy {
    static let enabledKey = "unit.health.saveWorkouts"
    static let shortestWorkout: TimeInterval = 60
    static let longestWorkout: TimeInterval = 4 * 60 * 60

    static func interval(start: Date, end: Date) -> DateInterval? {
        let duration = end.timeIntervalSince(start)
        guard duration >= shortestWorkout, duration <= longestWorkout else { return nil }
        return DateInterval(start: start, end: end)
    }
}

/// The one place the app talks to Apple Health.
enum HealthWorkoutSync {
    /// DEBUG UI tests swap in a fake (`UnitApp`).
    static var store: any HealthWorkoutWriting = HealthKitWorkoutStore()
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.unitlift", category: "AppleHealth")

    static var isAvailable: Bool { store.isAvailable }
    static var canSave: Bool { store.canSave }

    static func requestAccess() async -> Bool {
        await store.requestAccess()
    }

    /// Called after "Finish workout" saved the session. Never blocks or fails
    /// the finish; a failed save is logged and dropped.
    static func saveFinishedWorkout(sessionID: UUID, start: Date, end: Date) {
        Task { await save(sessionID: sessionID, start: start, end: end) }
    }

    @discardableResult
    static func save(
        sessionID: UUID,
        start: Date,
        end: Date,
        defaults: UserDefaults = .standard,
        store: any HealthWorkoutWriting = HealthWorkoutSync.store
    ) async -> Bool {
        guard defaults.bool(forKey: HealthWorkoutPolicy.enabledKey),
              let interval = HealthWorkoutPolicy.interval(start: start, end: end),
              store.canSave else { return false }
        do {
            try await store.save(sessionID: sessionID, interval: interval)
            return true
        } catch {
            logger.error("Apple Health save failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// For deleting a workout from History: removes its Apple Health copy, if any.
    static func removeWorkout(sessionID: UUID) {
        guard store.canSave else { return }
        let store = store
        Task {
            do {
                try await store.remove(sessionID: sessionID)
            } catch {
                logger.error("Apple Health remove failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

final class HealthKitWorkoutStore: HealthWorkoutWriting {
    private let healthStore = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    var canSave: Bool {
        isAvailable && healthStore.authorizationStatus(for: HKObjectType.workoutType()) == .sharingAuthorized
    }

    func requestAccess() async -> Bool {
        guard isAvailable else { return false }
        do {
            try await healthStore.requestAuthorization(toShare: [HKObjectType.workoutType()], read: [])
        } catch {
            return false
        }
        return canSave
    }

    func save(sessionID: UUID, interval: DateInterval) async throws {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .traditionalStrengthTraining
        configuration.locationType = .indoor
        let builder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
        try await builder.beginCollection(at: interval.start)
        try await builder.addMetadata([HKMetadataKeyExternalUUID: sessionID.uuidString])
        try await builder.endCollection(at: interval.end)
        _ = try await builder.finishWorkout()
    }

    func remove(sessionID: UUID) async throws {
        let predicate = HKQuery.predicateForObjects(
            withMetadataKey: HKMetadataKeyExternalUUID,
            allowedValues: [sessionID.uuidString]
        )
        _ = try await healthStore.deleteObjects(of: HKObjectType.workoutType(), predicate: predicate)
    }
}

#if DEBUG
/// UI-test stand-in so tests never hit the system permission sheet.
final class FakeHealthWorkoutStore: HealthWorkoutWriting {
    private let allowsAccess: Bool
    private(set) var isAuthorized = false
    private(set) var savedSessionIDs: [UUID] = []

    init(allowsAccess: Bool) {
        self.allowsAccess = allowsAccess
    }

    var isAvailable: Bool { true }
    var canSave: Bool { isAuthorized }

    func requestAccess() async -> Bool {
        isAuthorized = allowsAccess
        return isAuthorized
    }

    func save(sessionID: UUID, interval: DateInterval) async throws {
        savedSessionIDs.append(sessionID)
    }

    func remove(sessionID: UUID) async throws {
        savedSessionIDs.removeAll { $0 == sessionID }
    }
}
#endif
