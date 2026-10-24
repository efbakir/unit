import StoreKitTest
import XCTest

/// Edit workout and the lapsed-subscriber History, end to end.
final class TrustLayerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testEditASetDeleteASetWithUndoAndDeleteTheWorkout() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing", "-ui-testing-reset", "-ui-testing-lifetime-owner",
            "-ui-testing-analytics-r5", "-analytics-baseline",
            "-AppleLocale", "en_US", "-AppleLanguages", "(en)"
        ]
        app.launch()

        let history = app.buttons["History"]
        XCTAssertTrue(history.waitForExistence(timeout: 20))
        history.tap()
        let row = app.buttons["history-session-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        row.tap()

        let pencil = app.buttons["edit-workout"]
        XCTAssertTrue(pencil.waitForExistence(timeout: 10))
        pencil.tap()

        // Edit set: reps 5 -> 6.
        let firstSet = app.buttons["edit-workout-set-Squat-1"]
        XCTAssertTrue(firstSet.waitForExistence(timeout: 10))
        XCTAssertTrue(firstSet.label.contains("× 5"), firstSet.label)
        firstSet.tap()
        let editSet = app.buttons["Edit set"]
        XCTAssertTrue(editSet.waitForExistence(timeout: 5))
        editSet.tap()
        let reps = app.textFields["Reps"]
        XCTAssertTrue(reps.waitForExistence(timeout: 5))
        reps.tap()
        reps.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "6")
        XCTAssertEqual(reps.value as? String, "6 reps")
        app.buttons["Save changes"].tap()
        XCTAssertTrue(waitForLabel(of: firstSet, containing: "× 6"), firstSet.label)

        // Delete set, then Undo puts it back.
        let secondSet = app.buttons["edit-workout-set-Squat-2"]
        XCTAssertTrue(secondSet.waitForExistence(timeout: 5))
        secondSet.tap()
        let deleteSet = app.buttons["Delete set"]
        XCTAssertTrue(deleteSet.waitForExistence(timeout: 5))
        deleteSet.tap()
        // The toast only appears after a saved delete; tap Undo before it times out.
        let undo = app.buttons["Undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        undo.tap()
        XCTAssertTrue(secondSet.waitForExistence(timeout: 5))

        // Delete the workout: back on History, nothing left, no crash.
        app.buttons["delete-workout"].tap()
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == %@ AND identifier != %@", "Delete workout", "delete-workout")
        ).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()
        XCTAssertTrue(app.staticTexts["No sessions yet"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.state, .runningForeground)
    }

    /// The summary right after Finish is the likeliest place to catch a typo.
    @MainActor
    func testDeleteFromTheSummaryAfterFinishReturnsToToday() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing", "-ui-testing-reset", "-ui-testing-progression-contract",
            "-AppleLocale", "en_US", "-AppleLanguages", "(en)"
        ]
        app.launch()

        let finish = app.buttons["Finish"].firstMatch
        XCTAssertTrue(finish.waitForExistence(timeout: 20))
        finish.tap()
        let confirmFinish = app.alerts.firstMatch.buttons["Finish workout"]
        XCTAssertTrue(confirmFinish.waitForExistence(timeout: 5))
        confirmFinish.tap()

        let pencil = app.buttons["edit-workout"]
        XCTAssertTrue(pencil.waitForExistence(timeout: 15))
        pencil.tap()
        let trash = app.buttons["delete-workout"]
        XCTAssertTrue(trash.waitForExistence(timeout: 5))
        trash.tap()
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == %@ AND identifier != %@", "Delete workout", "delete-workout")
        ).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        confirm.tap()

        XCTAssertTrue(app.buttons["History"].waitForExistence(timeout: 10), "Back on Today")
        XCTAssertFalse(app.buttons["edit-workout"].exists)
        XCTAssertEqual(app.state, .runningForeground)
    }

    @MainActor
    func testLapsedSubscriberReadsHistoryFromThePaywall() throws {
        let session = try SKTestSession(configurationFileNamed: "Unit")
        session.disableDialogs = true
        session.resetToDefaultState()
        session.clearTransactions()
        defer { session.clearTransactions() }

        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing", "-smoke-test-combat-power", "-ui-testing-reset", "-ui-testing-intro-ineligible",
            "-AppleLocale", "en_US", "-AppleLanguages", "(en)"
        ]
        app.launch()

        let link = app.buttons["paywall-view-history"]
        XCTAssertTrue(scrollUntilHittable(link, in: app), "View workout history missing on the paywall")
        link.tap()

        let row = app.buttons["history-session-row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["read-only-history-export"].exists)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Tap to start")).firstMatch.exists)

        row.tap()
        XCTAssertTrue(app.staticTexts.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["edit-workout"].exists, "No editing for a lapsed subscriber")
        XCTAssertFalse(app.buttons["Save for next workout"].exists)
        XCTAssertFalse(app.buttons["Repeat previous target"].exists)
    }

    private func waitForLabel(of element: XCUIElement, containing text: String) -> Bool {
        let predicate = NSPredicate(format: "label CONTAINS %@", text)
        return XCTWaiter().wait(for: [XCTNSPredicateExpectation(predicate: predicate, object: element)], timeout: 5) == .completed
    }

    @MainActor
    private func scrollUntilHittable(_ element: XCUIElement, in app: XCUIApplication) -> Bool {
        guard app.otherElements.firstMatch.waitForExistence(timeout: 20) else { return false }
        for _ in 0..<12 {
            if element.exists && element.isHittable { return true }
            app.swipeUp()
        }
        return element.exists && element.isHittable
    }
}
