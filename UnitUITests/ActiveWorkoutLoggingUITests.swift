import XCTest

/// Exercises production logging against UnitUITests.store, never the normal store.
@MainActor
final class ActiveWorkoutLoggingUITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    func testFourSetsUndoEditAndAutomaticNextExercise() throws {
        let app = launch()
        capture(app, "final-b-before-first-set")
        tap(app.buttons["complete-set-1"], in: app)
        XCTAssertTrue(app.buttons["complete-set-2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logged-set-1"].exists)
        XCTAssertTrue(app.buttons["Skip"].exists)
        tap(app.buttons["complete-set-2"], in: app)
        XCTAssertTrue(app.buttons["complete-set-3"].waitForExistence(timeout: 5))
        capture(app, "final-b-after-set-two")
        let undo = try XCTUnwrap(app.buttons.matching(identifier: "Undo").allElementsBoundByIndex.first(where: \.isHittable))
        undo.tap() // Five-second Undo window: avoid the generic helper’s extra waits.
        XCTAssertTrue(app.buttons["complete-set-2"].waitForExistence(timeout: 5))
        tap(app.buttons["complete-set-2"], in: app)
        tap(app.buttons["logged-set-1"], in: app)
        capture(app, "final-b-completed-row-menu")
        tap(app.buttons.matching(identifier: "Edit").firstMatch, in: app)
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["complete-set-3"].isEnabled)
        capture(app, "final-b-editing-set")
        tap(app.buttons["Done"].firstMatch, in: app)
        tap(app.buttons["complete-set-3"], in: app)
        tap(app.buttons["complete-set-4"], in: app)
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Row"].exists)
        capture(app, "final-b-next-exercise")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.staticTexts["Barbell Row"].exists)
        capture(app, "final-b-relaunch")
    }

    func testStartingTargetOnlyPreparesAndFinishKeepsRoutine() throws {
        let app = launch(extra: ["-logging-empty-target"])
        XCTAssertTrue(app.buttons["save-starting-target"].exists)
        XCTAssertFalse(app.buttons["complete-set-1"].exists)
        capture(app, "final-b-empty-target")
        tap(app.buttons["planned-set-2"], in: app)
        let plannedWeight = app.textFields["logging-weight"].firstMatch
        plannedWeight.typeText("25")
        let plannedReps = app.textFields["logging-reps"].firstMatch
        tap(plannedReps, in: app); plannedReps.typeText("9")
        tap(app.buttons["Done"].firstMatch, in: app)
        XCTAssertTrue(app.staticTexts["25 kg × 9"].exists)
        XCTAssertFalse(app.buttons["logged-set-1"].exists)
        let weight = app.textFields["logging-weight"].firstMatch
        tap(weight, in: app); weight.typeText("24")
        let reps = app.textFields["logging-reps"].firstMatch
        tap(reps, in: app); reps.typeText("8")
        tap(app.buttons["keyboard-current-action"], in: app)
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["logged-set-1"].exists)
        XCTAssertFalse(app.buttons["Skip"].exists && app.buttons["Skip"].isEnabled)
        capture(app, "final-b-target-prepared-not-logged")
        tap(app.buttons["complete-set-1"], in: app)
        tap(app.buttons["Finish"], in: app)
        tap(app.alerts.buttons["Finish workout"], in: app)
        XCTAssertTrue(app.buttons["Keep routine"].waitForExistence(timeout: 5))
        capture(app, "final-b-update-routine-prompt")
        tap(app.buttons["Keep routine"], in: app)
        XCTAssertFalse(app.buttons["complete-set-2"].waitForExistence(timeout: 2))
    }

    func testKeyboardActionPreparesThenExplicitlyLogsCurrentSet() throws {
        let app = launch(extra: ["-logging-empty-target"])
        let weight = app.textFields["logging-weight"].firstMatch
        tap(weight, in: app)
        weight.typeText("24")
        let reps = app.textFields["logging-reps"].firstMatch
        tap(app.buttons["Edit reps"], in: app)
        reps.typeText("8")
        XCTAssertTrue(app.buttons["Edit weight"].exists)
        tap(app.buttons["Edit weight"], in: app)
        tap(app.buttons["Edit reps"], in: app)
        let keyboardAction = app.buttons["keyboard-current-action"]
        XCTAssertTrue(keyboardAction.waitForExistence(timeout: 5))
        XCTAssertTrue(keyboardAction.isHittable)
        XCTAssertEqual(keyboardAction.label, "Save target")
        capture(app, "gym-feedback-keyboard-target")
        tap(keyboardAction, in: app)
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["logged-set-1"].exists)
        XCTAssertFalse(app.buttons["Skip"].exists && app.buttons["Skip"].isEnabled)
        tap(app.textFields["logging-reps"].firstMatch, in: app)
        XCTAssertTrue(keyboardAction.waitForExistence(timeout: 5))
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: keyboardAction)
        let readyResult = XCTWaiter.wait(for: [ready], timeout: 5)
        capture(app, "gym-feedback-keyboard-complete")
        XCTAssertEqual(readyResult, .completed)
        XCTAssertEqual(keyboardAction.label, "Complete set 1")
        tap(keyboardAction, in: app)
        XCTAssertTrue(app.buttons["complete-set-2"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["logged-set-1"].exists)
        capture(app, "gym-feedback-next-set")
    }

    func testFinishUpdateAndEndOfDay() throws {
        let app = launch()
        let weight = app.textFields["logging-weight"].firstMatch
        tap(weight, in: app)
        // Use the visible step controls; tapping a native field does not promise
        // the caret starts at the end of its existing value.
        tap(app.buttons["+2.5"], in: app)
        tap(app.buttons["+2.5"], in: app)
        tap(app.buttons["Done"].firstMatch, in: app)
        XCTAssertEqual(app.textFields["logging-weight"].firstMatch.value as? String, "65")
        capture(app, "final-b-current-target-edited")
        for sets in [4, 3, 3, 3] {
            for number in 1...sets { tap(app.buttons["complete-set-\(number)"], in: app) }
        }
        XCTAssertTrue(app.buttons["Finish"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip"].exists && app.buttons["Skip"].isEnabled)
        capture(app, "final-b-end-of-day")
        tap(app.buttons["Finish"], in: app)
        tap(app.alerts.buttons["Finish workout"], in: app)
        tap(app.buttons["Update"], in: app)
        XCTAssertTrue(app.staticTexts["Next time"].waitForExistence(timeout: 10)
            || app.staticTexts["Workout complete"].exists)
        capture(app, "final-b-finished-update")
    }

    func testReorderKeepsLoggedSetRestAndSurvivesRelaunch() throws {
        let app = launch()
        tap(app.buttons["complete-set-1"], in: app)
        tap(app.buttons["workout-reorder"], in: app)
        let bench = app.cells.containing(.staticText, identifier: "workout-reorder-Bench Press").firstMatch
        let row = app.cells.containing(.staticText, identifier: "workout-reorder-Barbell Row").firstMatch
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        XCTAssertTrue(row.exists)
        bench.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            .press(forDuration: 1, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.9)))
        XCTAssertLessThan(row.frame.minY, bench.frame.minY)
        capture(app, "workout-reordered-sheet")
        tap(app.buttons["Done"], in: app)
        XCTAssertTrue(app.buttons["logged-set-1"].exists)
        XCTAssertTrue(app.buttons["complete-set-2"].exists)
        XCTAssertTrue(app.buttons["Skip"].isEnabled)
        XCTAssertTrue(app.buttons["Finish"].isHittable)
        capture(app, "workout-reordered-active-set")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        tap(app.buttons["workout-reorder"], in: app)
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        XCTAssertLessThan(row.frame.minY, bench.frame.minY)
        capture(app, "workout-reordered-relaunch")
    }

    func testLongPressCanReorderExerciseCards() throws {
        let app = launch()
        tap(app.buttons["workout-reorder"], in: app)
        let bench = app.cells.containing(.staticText, identifier: "workout-reorder-Bench Press").firstMatch
        let row = app.cells.containing(.staticText, identifier: "workout-reorder-Barbell Row").firstMatch
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        bench.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5))
            .press(forDuration: 1, thenDragTo: row.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.9)))
        XCTAssertLessThan(row.frame.minY, bench.frame.minY)
        tap(app.buttons["Done"], in: app)
        let rowTitle = app.staticTexts["Barbell Row"].firstMatch
        let benchTitle = app.staticTexts["Bench Press"].firstMatch
        XCTAssertTrue(rowTitle.isHittable)
        XCTAssertTrue(benchTitle.isHittable)
        rowTitle.press(forDuration: 1, thenDragTo: benchTitle)
        tap(app.buttons["workout-reorder"], in: app)
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        XCTAssertLessThan(bench.frame.minY, row.frame.minY)
        capture(app, "workout-card-long-press-result")
    }

    func testRestFooterKeepsItsFrameAcrossStates() throws {
        let app = launch(extra: ["-restDurationSeconds", "15"])
        let bar = app.otherElements["workout-rest-bar"].firstMatch
        XCTAssertTrue(bar.waitForExistence(timeout: 5))
        let idleFrame = bar.frame
        capture(app, "rest-footer-idle")
        tap(app.buttons["complete-set-1"], in: app)
        XCTAssertTrue(app.buttons["Skip"].isHittable)
        XCTAssertEqual(bar.frame.height, idleFrame.height, accuracy: 1)
        XCTAssertEqual(bar.frame.minY, idleFrame.minY, accuracy: 1)
        capture(app, "rest-footer-running")
        tap(app.buttons[AppCopy.Workout.restPlus], in: app)
        tap(app.buttons[AppCopy.Workout.restMinus], in: app)
        let status = app.descendants(matching: .any).matching(identifier: "rest-duration").firstMatch
        let finished = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@ AND value == %@", "Rest finished.", "0:00"), object: status)
        XCTAssertEqual(XCTWaiter.wait(for: [finished], timeout: 25), .completed)
        XCTAssertFalse(app.buttons["Skip"].exists && app.buttons["Skip"].isEnabled)
        XCTAssertEqual(bar.frame.height, idleFrame.height, accuracy: 1)
        XCTAssertEqual(bar.frame.minY, idleFrame.minY, accuracy: 1)
        capture(app, "rest-footer-finished")
    }

    func testMarkNotDoneStopsSourceRest() throws {
        let app = launch()
        tap(app.buttons["complete-set-1"], in: app)
        tap(app.buttons["logged-set-1"], in: app)
        tap(app.buttons["Mark not done"], in: app)
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Skip"].exists && app.buttons["Skip"].isEnabled)
        capture(app, "final-b-mark-not-done")
    }

    func testPoundsAndBodyweightUseSameLayout() throws {
        for flags in [["-logging-lb"], ["-logging-bodyweight"]] {
            let app = launch(extra: flags)
            XCTAssertTrue(app.buttons["complete-set-1"].exists)
            capture(app, flags[0] == "-logging-lb" ? "final-b-lb" : "final-b-bodyweight")
            app.terminate()
        }
    }

    private func launch(extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset", "-ui-testing-lifetime-owner", "-ui-testing-logging-finalb", "-AppleLocale", "en_US", "-AppleLanguages", "(en)"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["Start workout"].waitForExistence(timeout: 20))
        tap(app.buttons["Start workout"], in: app)
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 10))
        return app
    }

    private func tap(_ element: XCUIElement, in app: XCUIApplication) {
        let exists = element.waitForExistence(timeout: 8)
        if !exists { print("LOGGING FAILURE HIERARCHY: \(app.debugDescription)") }
        XCTAssertTrue(exists)
        for _ in 0..<6 {
            if element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
        element.tap()
        let allow = XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons["Allow"]
        if allow.exists { allow.tap() }
        // The interaction contract rejects a second log inside 400ms.
        // XCTest's idle wait normally exceeds it; waiting for hittability is explicit.
        _ = element.waitForNonExistence(timeout: 0.5)
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
