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
}
