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

    func testStartingTargetOnlyPreparesAndFinishOpensSummary() throws {
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
        // No "Update routine with today's weights?" step since 2026-10-24.
        XCTAssertTrue(app.staticTexts["Next time"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Keep routine"].exists)
        capture(app, "final-b-finish-opens-summary")
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

    func testEditedWeightFinishAndEndOfDay() throws {
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
        XCTAssertTrue(app.staticTexts["Next time"].waitForExistence(timeout: 10)
            || app.staticTexts["Workout complete"].exists)
        XCTAssertFalse(app.buttons["Update"].exists)
        capture(app, "final-b-finished-summary")
    }

    func testSkippedExerciseSaysSoAndFinishAsksBeforeLeavingIt() throws {
        let app = launch()
        for sets in [4, 3, 3] {
            for number in 1...sets { tap(app.buttons["complete-set-\(number)"], in: app) }
        }
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["workout-complete-finish"].exists)
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Skip exercise", in: app)
        tap(app.alerts.buttons["Skip exercise"], in: app)
        XCTAssertTrue(app.buttons["workout-complete-finish"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["complete-set-1"].exists)
        let deadlift = app.buttons["Deadlift"].firstMatch
        XCTAssertTrue((deadlift.value as? String)?.contains("Skipped") == true, String(describing: deadlift.value))
        capture(app, "skipped-exercise-finish")
        tap(app.buttons["workout-complete-finish"], in: app)
        XCTAssertTrue(app.alerts["Deadlift is not done."].waitForExistence(timeout: 5))
        capture(app, "finish-asks-not-done")
        tap(app.alerts.buttons["Go to Deadlift"], in: app)
        XCTAssertTrue(app.buttons["complete-set-1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["workout-complete-finish"].exists)
    }

    func testSkippingAnEarlierExerciseMovesOnAndLeavesItSkipped() throws {
        let app = launch()
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Skip exercise", in: app)
        tap(app.alerts.buttons["Skip exercise"], in: app)
        let bench = app.buttons["Bench Press"].firstMatch
        XCTAssertTrue(bench.waitForExistence(timeout: 5))
        XCTAssertTrue((bench.value as? String)?.contains("Skipped") == true, String(describing: bench.value))
        XCTAssertTrue(app.buttons["complete-set-1"].exists, "Barbell Row is current")
    }

    func testCompleteSetStaysEnabledRightAfterASet() throws {
        let app = launch()
        let first = app.buttons["complete-set-1"]
        XCTAssertTrue(first.waitForExistence(timeout: 8))
        first.tap()
        let second = app.buttons["complete-set-2"]
        XCTAssertTrue(second.waitForExistence(timeout: 2))
        // The 400 ms double-tap guard blocks taps but must not grey the button.
        XCTAssertTrue(second.isEnabled)
    }

    func testAddedSetCanBeRemovedAndUndone() throws {
        let app = launch()
        let addSet = app.buttons.matching(NSPredicate(format: "label ENDSWITH[c] 'add set'")).firstMatch
        tap(addSet, in: app)
        XCTAssertTrue(app.buttons["planned-set-5"].waitForExistence(timeout: 5))
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        // The toast's Undo lasts 4 s: tap it without the helper's extra waits.
        tapMenuItem("Remove added set", in: app)
        let undo = app.buttons["Undo"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 3))
        capture(app, "added-set-removed-toast")
        undo.tap()
        XCTAssertTrue(app.buttons["planned-set-5"].waitForExistence(timeout: 5))
        // Removing again takes the added row away; the plan's own rows cannot
        // be removed this way.
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Remove added set", in: app)
        XCTAssertTrue(app.buttons["planned-set-5"].waitForNonExistence(timeout: 5))
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        XCTAssertFalse(app.buttons["Remove added set"].waitForExistence(timeout: 2))
    }

    func testExerciseHistoryOpensAsASheetAndCloses() throws {
        let app = launch(extra: ["-logging-history"])
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Exercise history", in: app)
        let latest = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Latest'")).firstMatch
        XCTAssertTrue(latest.waitForExistence(timeout: 10))
        capture(app, "exercise-history-sheet")
        tap(app.buttons["exercise-history-close"], in: app)
        XCTAssertTrue(latest.waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.buttons["complete-set-1"].isHittable)
    }

    func testNotesOpenFromTheMenuAndSurviveRelaunch() throws {
        let app = launch()
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Notes", in: app)
        let field = app.textViews["exercise-note-field"].exists
            ? app.textViews["exercise-note-field"] : app.textFields["exercise-note-field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        tap(field, in: app)
        field.typeText("Seat 4")
        tap(app.buttons["Save"].firstMatch, in: app)
        XCTAssertTrue(field.waitForNonExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Seat 4"].exists, "the note is not shown on the card")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        XCTAssertTrue(app.buttons["exercise-menu"].firstMatch.waitForExistence(timeout: 15))
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Notes", in: app)
        let reopened = app.textViews["exercise-note-field"].exists
            ? app.textViews["exercise-note-field"] : app.textFields["exercise-note-field"]
        XCTAssertTrue(reopened.waitForExistence(timeout: 5))
        XCTAssertEqual(reopened.value as? String, "Seat 4")
        capture(app, "notes-sheet")
    }

    func testSwapBeforeTheFirstSetKeepsThePlannedSetsAndSurvivesRelaunch() throws {
        let app = launch()
        tap(app.buttons["exercise-menu"].firstMatch, in: app)
        tapMenuItem("Swap exercise", in: app)
        let search = exerciseSearch(in: app)
        search.typeText("Test Press")
        tap(app.buttons["Create \"Test Press\""], in: app)
        XCTAssertTrue(app.staticTexts["Test Press"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Bench Press"].exists)
        // Bench Press had 4 planned sets; the swapped-in exercise keeps them.
        XCTAssertTrue(app.buttons["planned-set-4"].exists)
        capture(app, "swap-exercise")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        XCTAssertTrue(app.staticTexts["Test Press"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["Bench Press"].exists)
    }

    func testAddExerciseInARoutineWorkoutWithItsOwnSetCount() throws {
        let app = launch()
        // The button ends the list; scroll it above the fixed rest bar first.
        let add = app.buttons["Add exercise"]
        XCTAssertTrue(add.waitForExistence(timeout: 8))
        let restBar = app.otherElements["workout-rest-bar"]
        for _ in 0..<6 where add.frame.maxY > restBar.frame.minY { app.swipeUp() }
        add.tap()
        let search = exerciseSearch(in: app)
        search.typeText("Test Curl")
        tap(app.buttons["Create \"Test Curl\""], in: app)
        XCTAssertTrue(app.staticTexts["How many sets?"].waitForExistence(timeout: 5))
        tap(app.buttons["2"], in: app)
        tap(app.buttons["Done"].firstMatch, in: app)
        XCTAssertTrue(app.staticTexts["Test Curl"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["planned-set-2"].exists)
        XCTAssertFalse(app.buttons["planned-set-3"].exists)
        capture(app, "add-exercise-routine-workout")
    }

    func testRestStepIsRememberedForThatExerciseOnly() throws {
        let app = launch()
        tap(app.buttons["complete-set-1"], in: app)
        let rest = app.descendants(matching: .any)["rest-duration"]
        XCTAssertTrue(rest.waitForExistence(timeout: 5))
        tap(app.buttons["+30"], in: app)
        tap(app.buttons["complete-set-2"], in: app)
        // Bench Press now rests 2:30; a few seconds may pass under load.
        let benchRest = (rest.value as? String) ?? ""
        XCTAssertTrue(benchRest.hasPrefix("2:2") || benchRest.hasPrefix("2:3"), benchRest)
        tap(app.buttons["complete-set-3"], in: app)
        tap(app.buttons["complete-set-4"], in: app)
        tap(app.buttons["complete-set-1"], in: app)
        // Barbell Row keeps the 2:00 default.
        let rowRest = (rest.value as? String) ?? ""
        XCTAssertTrue(rowRest.hasPrefix("2:0") || rowRest.hasPrefix("1:5"), rowRest)
    }

    // Build 90 removed the toolbar reorder sheet; exercise cards are reordered
    // by long-pressing a card and dropping it on another (direct drag only).
    func testReorderKeepsLoggedSetRestAndSurvivesRelaunch() throws {
        let app = launch()
        tap(app.buttons["complete-set-1"], in: app)
        let bench = app.staticTexts["Bench Press"].firstMatch
        let row = app.staticTexts["Barbell Row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertLessThan(bench.frame.minY, row.frame.minY)
        row.press(forDuration: 1, thenDragTo: bench)
        XCTAssertTrue(eventually { row.frame.minY < bench.frame.minY }, "Barbell Row did not move above Bench Press")
        XCTAssertTrue(app.buttons["logged-set-1"].exists)
        XCTAssertTrue(app.buttons["complete-set-2"].exists)
        XCTAssertTrue(app.buttons["Skip"].isEnabled)
        XCTAssertTrue(app.buttons["Finish"].isHittable)
        capture(app, "workout-reordered-active-set")
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        XCTAssertTrue(row.waitForExistence(timeout: 15))
        XCTAssertTrue(eventually { row.frame.minY < bench.frame.minY }, "Order did not survive relaunch")
        capture(app, "workout-reordered-relaunch")
    }

    func testLongPressCanReorderExerciseCards() throws {
        let app = launch()
        let bench = app.staticTexts["Bench Press"].firstMatch
        let row = app.staticTexts["Barbell Row"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.isHittable)
        XCTAssertTrue(bench.isHittable)
        XCTAssertLessThan(bench.frame.minY, row.frame.minY)
        row.press(forDuration: 1, thenDragTo: bench)
        XCTAssertTrue(eventually { row.frame.minY < bench.frame.minY }, "Long-press drag did not reorder")
        bench.press(forDuration: 1, thenDragTo: row)
        XCTAssertTrue(eventually { bench.frame.minY < row.frame.minY }, "Dragging back did not restore the order")
        capture(app, "workout-card-long-press-result")
    }

    private func eventually(timeout: TimeInterval = 4, _ condition: () -> Bool) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        return condition()
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

    /// From iOS 26 the picker's search is minimized into a toolbar button.
    private func exerciseSearch(in app: XCUIApplication) -> XCUIElement {
        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: 3) {
            tap(app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Search")).firstMatch, in: app)
        }
        XCTAssertTrue(search.waitForExistence(timeout: 8))
        search.tap()
        return search
    }

    /// Menu items appear with an animation; swiping (as `tap` does) would
    /// close the menu, so wait until the item is tappable instead.
    private func tapMenuItem(_ title: String, in app: XCUIApplication) {
        let item = app.buttons[title]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: item)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 8), .completed, "\(title) never became tappable")
        item.tap()
    }

    private func capture(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
}
