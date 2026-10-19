import XCTest
@testable import Unit

@MainActor
final class AppFeedbackPolicyTests: XCTestCase {
    func testInactiveSceneDoesNotAdmitOrRememberFeedback() {
        let state = AppFeedbackState()
        XCTAssertFalse(state.admitHaptic(.error))
        XCTAssertNil(state.lastHaptic)
        state.setActive(true)
        defer { state.setActive(false) }
        XCTAssertTrue(state.admitHaptic(.select))
    }

    func testWindowSuppressesEqualAndWeakerIntentsButAdmitsStrongerOutcomes() {
        let state = AppFeedbackState()
        let now = ContinuousClock.now
        state.clock = { now }
        state.setActive(true)
        defer { state.setActive(false) }
        XCTAssertTrue(state.admitHaptic(.select))
        XCTAssertFalse(state.admitHaptic(.select))
        XCTAssertTrue(state.admitHaptic(.tap))
        XCTAssertFalse(state.admitHaptic(.lift))
        XCTAssertTrue(state.admitHaptic(.firm))
        XCTAssertTrue(state.admitHaptic(.success))
        XCTAssertFalse(state.admitHaptic(.warning))
        XCTAssertFalse(state.admitHaptic(.success)) // Set + PR is one success.
        XCTAssertTrue(state.admitHaptic(.error))
        XCTAssertFalse(state.admitHaptic(.tap))
    }

    func testWindowEndsAtEightyMillisecondsAndSceneReactivationClearsIt() {
        let state = AppFeedbackState()
        var now = ContinuousClock.now
        state.clock = { now }
        state.setActive(true)
        defer { state.setActive(false) }
        XCTAssertTrue(state.admitHaptic(.success))
        now = now.advanced(by: .milliseconds(79))
        XCTAssertFalse(state.admitHaptic(.select))
        now = now.advanced(by: .milliseconds(1))
        XCTAssertTrue(state.admitHaptic(.select))
        state.setActive(false)
        XCTAssertNil(AppFeedbackState.activeScene)
        XCTAssertFalse(state.admitHaptic(.success))
        state.setActive(true)
        XCTAssertTrue(AppFeedbackState.activeScene === state)
        XCTAssertTrue(state.admitHaptic(.select))
    }

    func testAccessibilityPolicyDisallowsSpatialMotionForEitherSetting() {
        XCTAssertTrue(AppMotion.allowsSpatialMotion(reduceMotion: false, voiceOver: false))
        XCTAssertFalse(AppMotion.allowsSpatialMotion(reduceMotion: true, voiceOver: false))
        XCTAssertFalse(AppMotion.allowsSpatialMotion(reduceMotion: false, voiceOver: true))
        XCTAssertFalse(AppMotion.allowsSpatialMotion(reduceMotion: true, voiceOver: true))
    }

    func testConfettiSamplesAreStableBoundedAndVaryByPieceAndChannel() {
        let sample = AppMotion.Confetti.sample(seed: 42, index: 2)
        XCTAssertEqual(sample, AppMotion.Confetti.sample(seed: 42, index: 2))
        XCTAssertNotEqual(sample, AppMotion.Confetti.sample(seed: 42, index: 3))
        XCTAssertNotEqual(sample, AppMotion.Confetti.sample(seed: 42, index: 2, channel: 1))
        for index in 0..<AppMotion.Confetti.count {
            let value = AppMotion.Confetti.sample(seed: 42, index: index)
            XCTAssertGreaterThanOrEqual(value, 0)
            XCTAssertLessThan(value, 1)
        }
    }
    func testIdenticalToastMessagesAreSeparateOccurrences() {
        let first = AppToastEvent("Set removed")
        let second = AppToastEvent("Set removed")
        XCTAssertNotEqual(first.id, second.id)
        XCTAssertEqual(first.text, second.text)
    }

    func testToastReadingWindowsAndPersistentError() {
        XCTAssertEqual(AppToastEvent("Saved").duration, 2)
        let target = UUID()
        let undo = AppToastAction(id: target, label: "Undo", handler: {})
        let removed = AppToastEvent("Set removed", action: undo)
        XCTAssertEqual(removed.duration, 4)
        XCTAssertEqual(removed.action?.id, target)
        XCTAssertNil(AppToastEvent("Couldn't save", kind: .error).duration)
        XCTAssertNil(AppToastEvent("Couldn't undo", kind: .error, action: undo).duration)
    }

    func testCelebrationReconstructionPreservesSeedAndDeadline() {
        let id = UUID()
        let start = Date(timeIntervalSince1970: 100)
        let first = AppCelebrationMoment(style: .shower, id: id, startedAt: start)
        let reconstructed = AppCelebrationMoment(style: .shower, id: id, startedAt: start)
        XCTAssertEqual(first, reconstructed)
        XCTAssertEqual(first.seed, reconstructed.seed)
        XCTAssertEqual(first.endsAt, reconstructed.endsAt)
        XCTAssertLessThan(first.endsAt, Date(timeIntervalSince1970: 103))
        XCTAssertGreaterThan(first.endsAt, start)
    }

    func testAcceptanceBurstHasEightDotsAndExactLifetime() {
        let start = Date(timeIntervalSince1970: 100)
        let burst = AppCelebrationMoment(style: .burst, startedAt: start)
        XCTAssertEqual(AppMotion.burstDots, 8)
        XCTAssertEqual(burst.duration, 0.45)
        XCTAssertEqual(burst.endsAt.timeIntervalSince(start), 0.45, accuracy: 0.0001)
        XCTAssertLessThan(AppMotion.Confetti.popperCount, AppMotion.Confetti.count)
    }

}
