//
//  EngagementPromptTrackerTests.swift
//  UnitTests
//

import XCTest
@testable import Unit

@MainActor
final class EngagementPromptTrackerTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suiteName: String!

    override func setUp() {
        super.setUp()
        suiteName = "EngagementPromptTrackerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testCountsOnlyUniqueCompletedSessionsAndCapsAtThree() {
        let tracker = EngagementPromptTracker(defaults: defaults)
        let first = UUID()

        XCTAssertEqual(tracker.recordCompletedWorkout(sessionID: first), 1)
        XCTAssertEqual(tracker.recordCompletedWorkout(sessionID: first), 1)
        XCTAssertEqual(tracker.recordCompletedWorkout(sessionID: UUID()), 2)
        XCTAssertEqual(tracker.recordCompletedWorkout(sessionID: UUID()), 3)
        XCTAssertEqual(tracker.recordCompletedWorkout(sessionID: UUID()), 3)
        XCTAssertEqual(tracker.completedWorkoutCount, 3)
    }

    func testReviewThresholdAndAttemptPersistAcrossTrackerInstances() {
        let tracker = EngagementPromptTracker(defaults: defaults)
        XCTAssertFalse(tracker.shouldRequestReview)

        tracker.recordCompletedWorkout(sessionID: UUID())
        XCTAssertTrue(tracker.shouldRequestReview)

        tracker.markReviewRequestAttempted()
        XCTAssertFalse(EngagementPromptTracker(defaults: defaults).shouldRequestReview)
        XCTAssertTrue(EngagementPromptTracker(defaults: defaults).reviewRequestAttempted)
    }

    func testFeedbackAppearsOnlyForThirdSessionAndOnlyOnce() {
        let tracker = EngagementPromptTracker(defaults: defaults)
        let first = UUID()
        let second = UUID()
        let third = UUID()

        tracker.recordCompletedWorkout(sessionID: first)
        tracker.recordCompletedWorkout(sessionID: second)
        XCTAssertFalse(tracker.shouldShowFeedback(for: second))

        tracker.recordCompletedWorkout(sessionID: third)
        XCTAssertFalse(tracker.shouldShowFeedback(for: first))
        XCTAssertTrue(tracker.shouldShowFeedback(for: third))

        tracker.markFeedbackPromptShown()
        XCTAssertFalse(EngagementPromptTracker(defaults: defaults).shouldShowFeedback(for: third))
        XCTAssertTrue(EngagementPromptTracker(defaults: defaults).feedbackPromptShown)
    }

    func testBookingAndEmailURLsUseApprovedDestinationsAndPrompts() {
        XCTAssertEqual(
            EngagementPromptTracker.bookingURL.absoluteString,
            "https://calendar.notion.so/meet/efbakir/unit-feedback"
        )

        let url = EngagementPromptTracker.feedbackEmailURL(
            appVersion: "2.1",
            buildNumber: "58",
            systemVersion: "iOS test"
        )
        let components = url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }
        let query = Dictionary(
            uniqueKeysWithValues: (components?.queryItems ?? []).compactMap { item in
                item.value.map { (item.name, $0) }
            }
        )

        XCTAssertEqual(components?.scheme, "mailto")
        XCTAssertEqual(components?.path, "support@unitlift.app")
        XCTAssertEqual(query["subject"], "Unit feedback")
        XCTAssertTrue(query["body"]?.contains("What worked:") == true)
        XCTAssertTrue(query["body"]?.contains("What got in the way:") == true)
        XCTAssertTrue(query["body"]?.contains("What should improve:") == true)
        XCTAssertTrue(query["body"]?.contains("Unit 2.1 · build 58 · iOS test") == true)
    }
}
