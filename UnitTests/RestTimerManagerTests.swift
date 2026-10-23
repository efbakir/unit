import XCTest
import UserNotifications
@testable import Unit

@MainActor
final class RestTimerManagerTests: XCTestCase {
    @MainActor private final class Notifications {
        var requests: [UNNotificationRequest] = []
        var cancelled: [String] = []
        var permissionRequests = 0
        var onAdd: (() -> Void)?
        var client: RestTimerManager.NotificationClient {
            .init(
                authorizationStatus: { .authorized },
                requestAuthorization: { self.permissionRequests += 1; return true },
                add: {
                    self.requests.append($0)
                    let callback = self.onAdd
                    self.onAdd = nil
                    callback?()
                },
                cancel: { self.cancelled.append(contentsOf: $0) }
            )
        }
        func waitForRequest(_ action: () -> Void) async {
            let added = XCTestExpectation(description: "Rest completion notification added")
            onAdd = { added.fulfill() }
            action()
            let result = await XCTWaiter.fulfillment(of: [added], timeout: 2)
            XCTAssertEqual(result, .completed)
            onAdd = nil
        }
    }

    private func defaults() -> UserDefaults {
        let name = "RestTimerManagerTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        addTeardownBlock { defaults.removePersistentDomain(forName: name) }
        return defaults
    }

    private func timer(
        _ defaults: UserDefaults,
        _ notifications: Notifications,
        now: @escaping () -> Date
    ) -> RestTimerManager {
        RestTimerManager(defaults: defaults, now: now, notifications: notifications.client,
                         usesLiveActivities: false, automaticallyTicks: false)
    }

    func testUpNextReplacementKeepsDeadlineAndCancelsOnlyPreviousGeneration() async throws {
        let defaults = defaults()
        let notifications = Notifications()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let timer = timer(defaults, notifications, now: { now })
        defer { timer.stop() }
        await notifications.waitForRequest { timer.start(totalSeconds: 120, upNext: "Bench · Set 2") }
        let deadline = timer.endDate
        let first = try XCTUnwrap(notifications.requests.first)
        await notifications.waitForRequest { timer.updateUpNext("Incline · Set 1") }
        let second = try XCTUnwrap(notifications.requests.last)
        XCTAssertEqual(timer.endDate, deadline)
        XCTAssertEqual(timer.secondsRemaining, 120)
        XCTAssertNotEqual(first.identifier, second.identifier)
        XCTAssertTrue(notifications.cancelled.contains(first.identifier))
        XCTAssertFalse(notifications.cancelled.contains(second.identifier))
        XCTAssertEqual(second.content.body, "Next: Incline · Set 1")
        XCTAssertEqual(second.content.interruptionLevel, .timeSensitive)
        XCTAssertEqual((second.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval, 120)
        XCTAssertEqual(defaults.object(forKey: "unit.restTimer.endDate") as? Date, deadline)
    }

    func testRestStepAdjustmentsKeepElapsedTimeAndMinimum() async throws {
        let defaults = defaults()
        let notifications = Notifications()
        var now = Date(timeIntervalSince1970: 2_000_000_000)
        let timer = timer(defaults, notifications, now: { now })
        defer { timer.stop() }
        await notifications.waitForRequest { timer.start(totalSeconds: 120) }
        now = now.addingTimeInterval(20)
        let step = AppCopy.Workout.restStepSeconds
        await notifications.waitForRequest { timer.adjust(by: step) }
        XCTAssertEqual(timer.secondsRemaining, 100 + step)
        XCTAssertEqual(timer.totalDuration, 120 + step)
        XCTAssertEqual(timer.endDate, now.addingTimeInterval(TimeInterval(100 + step)))
        XCTAssertEqual(
            (notifications.requests.last?.trigger as? UNTimeIntervalNotificationTrigger)?.timeInterval,
            TimeInterval(100 + step)
        )
        await notifications.waitForRequest { timer.adjust(by: -step) }
        XCTAssertEqual(timer.secondsRemaining, 100)
        XCTAssertEqual(timer.totalDuration, 120)
        XCTAssertEqual(timer.endDate, now.addingTimeInterval(100))
        await notifications.waitForRequest { timer.adjust(by: -500) }
        XCTAssertEqual(timer.secondsRemaining, 15)
        XCTAssertEqual(timer.totalDuration, 15)
        XCTAssertEqual(timer.endDate, now.addingTimeInterval(15))
    }

    func testStopClearsSourceDeadlineFinishedStateAndNotificationWithoutCompletion() async throws {
        let defaults = defaults()
        let notifications = Notifications()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let timer = timer(defaults, notifications, now: { now })
        let source = UUID()
        await notifications.waitForRequest { timer.start(totalSeconds: 120, sourceEntryID: source) }
        XCTAssertEqual(timer.sourceEntryID, source)
        let identifier = try XCTUnwrap(notifications.requests.last?.identifier)
        timer.stop()
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isFinished)
        XCTAssertEqual(timer.completionCount, 0)
        XCTAssertNil(timer.sourceEntryID)
        XCTAssertNil(timer.endDate)
        XCTAssertTrue(notifications.cancelled.contains(identifier))
        for key in ["endDate", "totalDuration", "upNext", "sourceEntryID", "finishedAt", "notificationID"] {
            XCTAssertNil(defaults.object(forKey: "unit.restTimer.\(key)"))
        }
    }

    func testRunningRestoreRetainsSourceAndDoesNotScheduleOrRequestPermission() {
        let defaults = defaults()
        let notifications = Notifications()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        let source = UUID()
        defaults.set(now.addingTimeInterval(90), forKey: "unit.restTimer.endDate")
        defaults.set(120, forKey: "unit.restTimer.totalDuration")
        defaults.set(source.uuidString, forKey: "unit.restTimer.sourceEntryID")
        let timer = timer(defaults, notifications, now: { now })
        defer { timer.stop() }
        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.secondsRemaining, 90)
        XCTAssertEqual(timer.sourceEntryID, source)
        XCTAssertEqual(notifications.requests.count, 0)
        XCTAssertEqual(notifications.permissionRequests, 0)
    }

    func testExpiredRestoreFinishesOnceAndClearsExactlyThirtySecondsAfterDeadline() {
        let defaults = defaults()
        let notifications = Notifications()
        var now = Date(timeIntervalSince1970: 2_000_000_000)
        let deadline = now.addingTimeInterval(-10)
        let source = UUID()
        defaults.set(deadline, forKey: "unit.restTimer.endDate")
        defaults.set(120, forKey: "unit.restTimer.totalDuration")
        defaults.set(source.uuidString, forKey: "unit.restTimer.sourceEntryID")
        let timer = timer(defaults, notifications, now: { now })
        XCTAssertFalse(timer.isRunning)
        XCTAssertTrue(timer.isFinished)
        XCTAssertEqual(timer.finishedAt, deadline)
        XCTAssertEqual(timer.completionCount, 1)
        XCTAssertEqual(timer.sourceEntryID, source)
        timer.resumeFromBackground()
        XCTAssertEqual(timer.completionCount, 1)
        XCTAssertEqual(notifications.requests.count, 0)
        XCTAssertEqual(notifications.permissionRequests, 0)
        now = deadline.addingTimeInterval(29.999)
        timer.resumeFromBackground()
        XCTAssertTrue(timer.isFinished)
        now = deadline.addingTimeInterval(30)
        timer.resumeFromBackground()
        XCTAssertFalse(timer.isFinished)
        XCTAssertNil(timer.sourceEntryID)
        XCTAssertEqual(timer.completionCount, 1)
    }

    func testFinishedStateSurvivesSecondRelaunchAndStartResetsIt() async {
        let defaults = defaults()
        let notifications = Notifications()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        defaults.set(now.addingTimeInterval(-2), forKey: "unit.restTimer.endDate")
        _ = timer(defaults, notifications, now: { now })
        let restored = timer(defaults, notifications, now: { now })
        defer { restored.stop() }
        XCTAssertTrue(restored.isFinished)
        XCTAssertEqual(restored.completionCount, 0, "Relaunching a finished state must not replay completion")
        await notifications.waitForRequest { restored.start(totalSeconds: 120) }
        XCTAssertFalse(restored.isFinished)
        XCTAssertTrue(restored.isRunning)
        XCTAssertNil(defaults.object(forKey: "unit.restTimer.finishedAt"))
    }

    func testNaturalCompletionKeepsSourceAndStopClearsFinishedWithoutAnotherEvent() async {
        let defaults = defaults()
        let notifications = Notifications()
        var now = Date(timeIntervalSince1970: 2_000_000_000)
        let timer = timer(defaults, notifications, now: { now })
        let source = UUID()
        await notifications.waitForRequest { timer.start(totalSeconds: 120, sourceEntryID: source) }
        now = now.addingTimeInterval(120)
        timer.resumeFromBackground()
        XCTAssertTrue(timer.isFinished)
        XCTAssertEqual(timer.completionCount, 1)
        XCTAssertEqual(timer.sourceEntryID, source)
        XCTAssertEqual(notifications.requests.count, 1)
        timer.updateUpNext("Bench · Set 3")
        XCTAssertEqual(notifications.requests.count, 1)
        timer.stop()
        XCTAssertFalse(timer.isFinished)
        XCTAssertNil(timer.sourceEntryID)
        XCTAssertEqual(timer.completionCount, 1)
    }

    func testOldExpiredTimerReturnsToIdleWithoutRescheduling() {
        let defaults = defaults()
        let notifications = Notifications()
        let now = Date(timeIntervalSince1970: 2_000_000_000)
        defaults.set(now.addingTimeInterval(-31), forKey: "unit.restTimer.endDate")
        let timer = timer(defaults, notifications, now: { now })
        XCTAssertFalse(timer.isRunning)
        XCTAssertFalse(timer.isFinished)
        XCTAssertEqual(notifications.requests.count, 0)
        XCTAssertEqual(notifications.permissionRequests, 0)
        XCTAssertNil(defaults.object(forKey: "unit.restTimer.endDate"))
    }
}
