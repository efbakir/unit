import XCTest
@testable import Unit

/// Apple Health writes go through a fake store: no permission sheet, no
/// Health data. The real `HealthKitWorkoutStore` is checked by hand.
@MainActor
final class HealthWorkoutStoreTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_790_000_000)

    func testOnlyRealWorkoutLengthsAreSaved() {
        XCTAssertNil(HealthWorkoutPolicy.interval(start: start, end: start.addingTimeInterval(59)))
        XCTAssertEqual(HealthWorkoutPolicy.interval(start: start, end: start.addingTimeInterval(60))?.duration, 60)
        XCTAssertEqual(HealthWorkoutPolicy.interval(start: start, end: start.addingTimeInterval(4 * 3600))?.duration, 4 * 3600)
        XCTAssertNil(HealthWorkoutPolicy.interval(start: start, end: start.addingTimeInterval(4 * 3600 + 1)))
        XCTAssertNil(HealthWorkoutPolicy.interval(start: start, end: start.addingTimeInterval(-600)))
    }

    func testSavesOnlyWhenTurnedOnAndAllowed() async throws {
        let suiteName = "HealthWorkoutStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let store = FakeHealthWorkoutStore(allowsAccess: true)
        let sessionID = UUID(), end = start.addingTimeInterval(45 * 60)

        var saved = await HealthWorkoutSync.save(sessionID: sessionID, start: start, end: end, defaults: defaults, store: store)
        XCTAssertFalse(saved, "Off by default")
        defaults.set(true, forKey: HealthWorkoutPolicy.enabledKey)
        saved = await HealthWorkoutSync.save(sessionID: sessionID, start: start, end: end, defaults: defaults, store: store)
        XCTAssertFalse(saved, "On, but iOS has not allowed it yet")

        let allowed = await store.requestAccess()
        XCTAssertTrue(allowed)
        saved = await HealthWorkoutSync.save(sessionID: sessionID, start: start, end: end, defaults: defaults, store: store)
        XCTAssertTrue(saved)
        XCTAssertEqual(store.savedSessionIDs, [sessionID])

        // A workout left open overnight has no real end time.
        saved = await HealthWorkoutSync.save(sessionID: UUID(), start: start, end: start.addingTimeInterval(9 * 3600), defaults: defaults, store: store)
        XCTAssertFalse(saved)
        XCTAssertEqual(store.savedSessionIDs, [sessionID])
    }

    func testDeniedAccessNeverSaves() async throws {
        let suiteName = "HealthWorkoutStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set(true, forKey: HealthWorkoutPolicy.enabledKey)
        let store = FakeHealthWorkoutStore(allowsAccess: false)

        let allowed = await store.requestAccess()
        XCTAssertFalse(allowed)
        let saved = await HealthWorkoutSync.save(sessionID: UUID(), start: start, end: start.addingTimeInterval(1800), defaults: defaults, store: store)
        XCTAssertFalse(saved)
        XCTAssertEqual(store.savedSessionIDs, [])
    }
}
