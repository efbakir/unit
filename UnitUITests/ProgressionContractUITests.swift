//
//  ProgressionContractUITests.swift
//  UnitUITests
//
//  Deterministic release-gate journey for the v2.2 progression information
//  contract: post-workout outcomes → explicit decisions → cold relaunch →
//  configuration → accepted target in the next workout.
//


import XCTest

@MainActor
final class ProgressionContractUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testProgressionContract_outcomesActionsPersistenceAndNextWorkout() throws {
        var app = makeApp(reset: true)
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Upper A"].waitForExistence(timeout: 20),
            "Seeded active workout did not open"
        )
        let finishWorkout = app.buttons[AppCopy.Workout.finishWorkout].firstMatch
        XCTAssertTrue(
            finishWorkout.waitForExistence(timeout: 12),
            "Seeded workout is not ready to finish"
        )
        assertNoProgressionDecisionUI(in: app)
        attachScreenshot(of: app, named: "01-progression-ready-to-finish")
        tap(finishWorkout, "ready-to-finish workout")

        let finishConfirmation = app.alerts.firstMatch.buttons[AppCopy.Workout.finishWorkout]
        tap(finishConfirmation, "finish confirmation")

        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.nextTimeTitle].waitForExistence(timeout: 15),
            "Post-workout progression section did not appear"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 62.5 kg").exists,
            "Increase-weight target is incomplete or incorrect"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Every set reached the top of your 8–10 range").exists,
            "Increase-weight explanation is missing"
        )
        let useFirstSuggestion = button(
            in: app,
            containing: AppCopy.Workout.useThisTarget
        )
        scrollTo(useFirstSuggestion, in: app)
        attachScreenshot(of: app, named: "02-increase-weight")
        tap(useFirstSuggestion, "Use this target — increase weight")
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.acceptedForNextTime)
                .waitForExistence(timeout: 8),
            "Accepted state did not replace the pending action"
        )

        let repeatPrevious = button(
            in: app,
            containing: AppCopy.Workout.repeatPreviousTarget
        )
        scrollTo(repeatPrevious, in: app)
        attachScreenshot(of: app, named: "03-increase-reps")
        tap(repeatPrevious, "Repeat previous target — add-rep recommendation")
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.repeatingForNextTime)
                .waitForExistence(timeout: 8),
            "Repeat-previous decision was not shown"
        )

        let editRepeatTarget = app.buttons["Edit next target for Back Squat"]
        scrollTo(editRepeatTarget, in: app)
        attachScreenshot(of: app, named: "04-repeat-target")
        tap(editRepeatTarget, "Edit repeat-target recommendation")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.editNextTarget].waitForExistence(timeout: 8),
            "Recommendation edit sheet did not open"
        )
        tap(app.buttons["Increase"].firstMatch, "Increase edited target reps")
        tap(app.buttons[AppCopy.Workout.saveChanges], "Save edited recommendation")
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.editedForNextTime)
                .waitForExistence(timeout: 8),
            "Edited decision was not shown"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 10 at 50 kg").exists,
            "Edited complete target was not shown"
        )

        let mixedWeightExplanation = staticText(
            in: app,
            containing: AppCopy.Workout.mixedWeightsUnavailable
        )
        scrollTo(mixedWeightExplanation, in: app)
        XCTAssertTrue(
            mixedWeightExplanation.exists,
            "Mixed working-set weights did not explain why automation is unavailable"
        )
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.noAutomaticTarget).exists,
            "Unavailable state heading is missing"
        )
        XCTAssertFalse(
            button(in: app, containing: AppCopy.Workout.repeatPreviousTarget).exists,
            "Accepted and unavailable rows must not keep stale repeat actions"
        )
        attachScreenshot(of: app, named: "05-mixed-weight-unavailable")

        // Cold relaunch against the same dedicated store. The launch seeder is
        // idempotent and must not recreate the workout or replace decisions.
        app.terminate()
        app = makeApp()
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Today"].waitForExistence(timeout: 20),
            "Relaunch did not return to Today"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 62.5 kg")
                .waitForExistence(timeout: 12),
            "Accepted increase-weight target did not survive relaunch"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 40 kg").exists,
            "Repeated previous target did not survive relaunch"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 10 at 50 kg").exists,
            "Edited target did not survive relaunch"
        )
        for exerciseName in [
            "Bench Press",
            "Barbell Row",
            "Back Squat",
            "Deadlift"
        ] {
            XCTAssertTrue(
                button(in: app, containing: exerciseName).exists,
                "Today lost the complete exercise identity for \(exerciseName)"
            )
        }
        attachScreenshot(of: app, named: "06-accepted-targets-today")

        tap(app.tabBars.buttons["Programs"], "Programs tab")
        let routine = button(in: app, containing: "Upper A")
        tap(routine, "Upper A routine", timeout: 10)
        tap(
            app.buttons["Edit target for Bench Press"],
            "Bench Press target editor"
        )
        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.progressionLabel].waitForExistence(timeout: 8),
            "Progressive overload configuration is missing"
        )
        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.weightIncrementLabel].exists,
            "Smallest-available-increase label is missing"
        )
        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.weightIncrementExplanation].exists,
            "Smallest-available-increase helper is missing"
        )
        XCTAssertTrue(
            app.textFields[AppCopy.Workout.weightIncrementLabel].exists,
            "Smallest available increase is not an editable field"
        )
        scrollTo(
            app.staticTexts[AppCopy.Workout.weightIncrementExplanation],
            in: app,
            maximumSwipes: 4
        )
        attachScreenshot(of: app, named: "07-progression-configuration")

        // Template detail intentionally hides the tab bar. Relaunching is the
        // real cold-start path and avoids coupling this contract test to the
        // navigation stack's synthesized back-button label.
        app.terminate()
        app = makeApp()
        app.launch()
        XCTAssertTrue(
            app.staticTexts["Today"].waitForExistence(timeout: 20),
            "Today did not return after the configuration relaunch"
        )

        // The same completed-session evidence must stay readable in History:
        // sentence-friendly set formatting, explicit volume units, and an
        // exact day on the chart rather than repeated month-only labels.
        tap(app.buttons[AppCopy.Nav.history], "History")
        let completedSessionRow = app.buttons["history-session-row"].firstMatch
        tap(completedSessionRow, "completed progression session")
        XCTAssertTrue(
            staticText(in: app, containing: "Bench Press")
                .waitForExistence(timeout: 8),
            "Completed-session details did not open"
        )
        let exerciseProgress = button(
            in: app,
            containing: "Bench Press"
        )
        scrollTo(exerciseProgress, in: app, maximumSwipes: 4)
        tap(exerciseProgress, "Bench Press progress")
        XCTAssertTrue(
            staticText(in: app, containing: "Best set · 60 kg × 10")
                .waitForExistence(timeout: 10),
            "History did not explain the best set with readable units"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Total volume · 1,800 kg·reps").exists,
            "History did not label total volume clearly"
        )
        let expectedChartDate = Date().formatted(
            .dateTime.month(.abbreviated).day()
        )
        XCTAssertTrue(
            staticText(in: app, containing: expectedChartDate).exists,
            "History chart did not expose an exact date"
        )
        attachScreenshot(of: app, named: "09-history-evidence")
        tap(app.navigationBars.buttons.firstMatch, "back to session details")
        tap(app.navigationBars.buttons.firstMatch, "back to History")
        tap(app.navigationBars.buttons.firstMatch, "back to Today")

        let startNextWorkout = app.buttons[AppCopy.Workout.startWorkout]
        scrollTo(startNextWorkout, in: app)
        tap(startNextWorkout, "Start next workout", timeout: 10)
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 62.5 kg")
                .waitForExistence(timeout: 10),
            "Accepted complete target is not prefilled in the next workout"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Last time · 3 × 10 at 60 kg").exists,
            "The next workout lost the prior-session evidence"
        )
        assertNoProgressionDecisionUI(in: app)
        attachScreenshot(of: app, named: "08-accepted-target-next-workout")
    }

    /// Captures the real, production progression surfaces used by the US App
    /// Store screenshot set. The dedicated seed uses pounds and ordinary
    /// exercise/routine names; it never introduces screenshot-only views.
    func testCaptureUSAppStoreProgressionScreens() throws {
        var app = makeAppStoreScreenshotApp(reset: true)
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Upper A"].waitForExistence(timeout: 20),
            "US App Store seed did not open the completed workout"
        )
        let finishWorkout = app.buttons[AppCopy.Workout.finishWorkout].firstMatch
        tap(finishWorkout, "finish US screenshot workout", timeout: 12)
        tap(
            app.alerts.firstMatch.buttons[AppCopy.Workout.finishWorkout],
            "finish US screenshot confirmation"
        )

        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 140 lb")
                .waitForExistence(timeout: 15),
            "US screenshot recommendation did not show the complete 140 lb target"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Previous target · 3 × 10 at 135 lb").exists,
            "US screenshot recommendation lost the 135 lb evidence"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Every set reached the top of your 8–10 range").exists,
            "US screenshot recommendation lost its transparent reason"
        )

        let useSuggestion = button(in: app, containing: AppCopy.Workout.useThisTarget)
        scrollTo(useSuggestion, in: app)
        attachScreenshot(of: app, named: "store-01-real-next-target")

        // Additional real recommendation variants for founder-composed App
        // Store artwork. These stay outside the canonical six-image export so
        // Figma can layer or crop them without changing the product UI.
        let addRepSuggestion = app.buttons[
            "\(AppCopy.Workout.useThisTarget) for Barbell Row"
        ]
        scrollTo(addRepSuggestion, in: app, maximumSwipes: 6)
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 9 at 95 lb").exists,
            "US add-rep recommendation was not visible"
        )
        attachScreenshot(of: app, named: "figma-card-add-one-rep")

        let repeatSuggestion = app.buttons[
            "\(AppCopy.Workout.useThisTarget) for Back Squat"
        ]
        scrollTo(repeatSuggestion, in: app, maximumSwipes: 6)
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 9 at 115 lb").exists,
            "US repeat-target recommendation was not visible"
        )
        attachScreenshot(of: app, named: "figma-card-repeat-target")

        scrollTo(useSuggestion, in: app, maximumSwipes: 8)

        tap(useSuggestion, "Use this target — US screenshot")
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.acceptedForNextTime)
                .waitForExistence(timeout: 8),
            "Accepted recommendation state was not visible"
        )
        attachScreenshot(of: app, named: "store-03-real-double-progression-result")

        // Capture the real History surface before starting the next workout.
        app.terminate()
        app = makeAppStoreScreenshotApp()
        app.launch()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 20))
        tap(app.buttons[AppCopy.Nav.history], "History — US screenshot")
        tap(
            app.buttons["history-session-row"].firstMatch,
            "completed session — US screenshot",
            timeout: 10
        )
        let exerciseProgress = button(in: app, containing: "Bench Press")
        scrollTo(exerciseProgress, in: app, maximumSwipes: 4)
        tap(exerciseProgress, "Bench Press progress — US screenshot")
        XCTAssertTrue(
            staticText(in: app, containing: "Best set · 135 lb × 10")
                .waitForExistence(timeout: 10),
            "US History evidence did not use pounds"
        )
        attachScreenshot(of: app, named: "store-05-strength-progress")

        tap(app.navigationBars.buttons.firstMatch, "back to session details")
        tap(app.navigationBars.buttons.firstMatch, "back to History")
        tap(app.navigationBars.buttons.firstMatch, "back to Today")

        let startWorkout = app.buttons[AppCopy.Workout.startWorkout]
        scrollTo(startWorkout, in: app)
        tap(startWorkout, "start accepted-target workout — US screenshot")
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 140 lb")
                .waitForExistence(timeout: 10),
            "Accepted US target was not prefilled"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Last time · 3 × 10 at 135 lb").exists,
            "US active workout lost previous-session evidence"
        )
        attachScreenshot(of: app, named: "store-02-one-tap-workout")
    }

    func testPastedStartingTargetSurvivesRelaunchAndLogsInOneTap() throws {
        var app = makeStartingTargetApp(reset: true)
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Today"].waitForExistence(timeout: 20),
            "Starting-target seed did not reach Today"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 60 kg")
                .waitForExistence(timeout: 12),
            "Today did not show the pasted Bench Press starting target"
        )

        // Reopen before the first workout: the target must come from SwiftData,
        // not transient onboarding state or an idempotent test reseed.
        app.terminate()
        app = makeStartingTargetApp()
        app.launch()
        XCTAssertTrue(
            staticText(in: app, containing: "3 × 8 at 60 kg")
                .waitForExistence(timeout: 20),
            "The pasted starting target did not survive a cold relaunch"
        )

        let startWorkout = app.buttons[AppCopy.Workout.startWorkout]
        scrollTo(startWorkout, in: app)
        tap(startWorkout, "Start first Upper A workout")

        XCTAssertTrue(
            app.staticTexts["Bench Press"].waitForExistence(timeout: 12),
            "Bench Press did not open first"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "60 kg × 8").exists,
            "The first active set did not show the usable 60 kg × 8 target"
        )
        XCTAssertTrue(
            app.staticTexts[AppCopy.Workout.startingTargetLabel].exists,
            "The planned value was not identified as a starting target"
        )
        XCTAssertFalse(
            staticText(in: app, containing: "Last time").exists,
            "A first-session target must not be mislabeled as workout history"
        )
        XCTAssertFalse(
            app.buttons[AppCopy.Workout.logMetricHint].exists,
            "Log first set must only appear when no usable target exists"
        )
        attachScreenshot(of: app, named: "09-first-session-starting-target")

        tap(app.buttons[AppCopy.Workout.completeSet], "Complete the prefilled first set")

        XCTAssertTrue(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "label CONTAINS %@", "Set 1, completed")
            ).firstMatch.waitForExistence(timeout: 8),
            "The one-tap action did not record the first set"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "60 kg × 8").exists,
            "The next set did not retain the within-session 60 kg × 8 prefill"
        )
        XCTAssertTrue(
            app.buttons.containing(
                NSPredicate(format: "label CONTAINS %@", "running")
            ).firstMatch.waitForExistence(timeout: 8),
            "The normal rest timer did not begin after one-tap completion"
        )
        attachScreenshot(of: app, named: "10-first-session-set-completed")
    }

    func testSetUndoAndInterruptedWorkoutSurviveRelaunch() throws {
        var app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.buttons[AppCopy.Workout.startWorkout], "Start isolated workout", timeout: 20)
        tap(app.buttons[AppCopy.Workout.completeSet], "Log seeded 60 kg × 8 set")
        let loggedSet = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Set 1, completed")
        ).firstMatch
        XCTAssertTrue(loggedSet.waitForExistence(timeout: 8))
        let originalLabel = loggedSet.label
        tap(loggedSet, "Edit completed set")
        tap(app.buttons[AppCopy.Workout.deleteSet], "Delete completed set")
        let undo = app.buttons["toast-action"]
        XCTAssertTrue(undo.waitForExistence(timeout: 2), "Set removal did not offer Undo")
        undo.tap()
        XCTAssertTrue(loggedSet.waitForExistence(timeout: 5), "Undo did not restore the set")
        XCTAssertEqual(loggedSet.label, originalLabel, "Undo changed the original set values")
        attachScreenshot(of: app, named: "11-set-undo-restored")

        app.terminate()
        app = makeStartingTargetApp()
        app.launch()
        let restoredSet = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@", "Set 1, completed")
        ).firstMatch
        XCTAssertTrue(restoredSet.waitForExistence(timeout: 20), "Interrupted workout lost its completed set")
        XCTAssertEqual(restoredSet.label, originalLabel)
        assertNoProgressionDecisionUI(in: app)
        attachScreenshot(of: app, named: "12-interrupted-workout-restored")
    }

    func testSharedFeedbackCatalogAndFailedSaveRetry() throws {
        let app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.tabBars.buttons["Programs"], "Programs", timeout: 20)
        tap(app.buttons["Settings"], "Settings")
        let components = button(in: app, containing: "Components")
        scrollTo(components, in: app)
        tap(components, "Component catalog")
        XCTAssertTrue(app.buttons["Default · press and hold"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Inherited disabled"].isEnabled)
        attachScreenshot(of: app, named: "13-catalog-default-states")

        let success = app.buttons["Success message"]
        scrollTo(app.buttons["Error message"], in: app)
        tap(success, "Success toast")
        tap(app.buttons["Error message"], "Replacement error toast")
        let error = app.staticTexts["Sample failed. Try again."]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        Thread.sleep(forTimeInterval: 2.5)
        XCTAssertTrue(error.exists, "Old toast timeout cleared the replacement error")
        attachScreenshot(of: app, named: "14-persistent-error-toast")
        tap(app.buttons["Dismiss message"], "Dismiss error")
        XCTAssertTrue(error.waitForNonExistence(timeout: 3), "Dismiss did not remove the error toast")
        scrollTo(app.buttons["Undo message"], in: app)
        tap(app.buttons["Undo message"], "Actionable toast")
        tap(app.buttons["toast-action"], "Undo sample")
        XCTAssertTrue(app.staticTexts["Sample restored"].waitForExistence(timeout: 3))

        let targetEditor = app.buttons["Target editor"]
        scrollTo(targetEditor, in: app)
        tap(targetEditor, "Target editor sample")
        tap(app.buttons[AppCopy.Workout.saveChanges], "Simulate failed target save")
        let alert = app.alerts["Couldn't save target"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        tap(alert.buttons["Close"], "Close failure alert")
        XCTAssertTrue(app.staticTexts["Sample exercise"].exists, "Failure dismissed the edit draft")
        attachScreenshot(of: app, named: "15-target-draft-after-failure")
        tap(app.buttons[AppCopy.Workout.saveChanges], "Retry target save")
        XCTAssertTrue(targetEditor.waitForExistence(timeout: 5), "Successful retry did not dismiss")

        // Standard-size interaction is this release's review scope. The catalog
        // keeps its optional large-text preview for a separate accessibility pass.
        attachScreenshot(of: app, named: "16-catalog-after-successful-retry")
    }

    // MARK: - Helpers

    private func makeApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-progression-contract"
        ]
        if reset {
            app.launchArguments.append("-ui-testing-reset")
        }
        return app
    }

    private func makeStartingTargetApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-starting-target"
        ]
        if reset {
            app.launchArguments.append("-ui-testing-reset")
        }
        return app
    }

    private func makeAppStoreScreenshotApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-progression-contract",
            "-ui-testing-app-store-screenshot"
        ]
        if reset {
            app.launchArguments.append("-ui-testing-reset")
        }
        return app
    }

    private func button(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func staticText(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func tap(
        _ element: XCUIElement,
        _ name: String,
        timeout: TimeInterval = 8
    ) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(name) not found")
        XCTAssertTrue(element.isHittable, "\(name) exists but is not hittable")
        element.tap()
    }

    private func scrollTo(
        _ element: XCUIElement,
        in app: XCUIApplication,
        maximumSwipes: Int = 8
    ) {
        var remaining = maximumSwipes
        while remaining > 0 && (!element.exists || !element.isHittable) {
            let shouldScrollDown = element.exists
                && element.frame.maxY < app.frame.midY
            let startY = shouldScrollDown ? 0.34 : 0.66
            let endY = shouldScrollDown ? 0.58 : 0.42
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: startY))
                .press(
                    forDuration: 0.01,
                    thenDragTo: app.coordinate(
                        withNormalizedOffset: CGVector(dx: 0.5, dy: endY)
                    )
                )
            remaining -= 1
        }
        XCTAssertTrue(element.exists, "Element did not appear after scrolling")
        XCTAssertTrue(element.isHittable, "Element is still not hittable after scrolling")
    }

    private func attachScreenshot(of app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func assertNoProgressionDecisionUI(in app: XCUIApplication) {
        XCTAssertFalse(
            button(in: app, containing: AppCopy.Workout.useThisTarget).exists,
            "Use-this-target must not interrupt active logging"
        )
        XCTAssertFalse(
            button(in: app, containing: AppCopy.Workout.repeatPreviousTarget).exists,
            "Repeat-previous must not interrupt active logging"
        )
        XCTAssertEqual(
            app.buttons.matching(
                NSPredicate(format: "label BEGINSWITH %@", "Edit next target")
            ).count,
            0,
            "Edit-target controls must not interrupt active logging"
        )
        XCTAssertFalse(app.staticTexts[AppCopy.Workout.nextTimeTitle].exists)
        XCTAssertFalse(app.staticTexts[AppCopy.Workout.suggestedForNextTime].exists)
        XCTAssertFalse(app.staticTexts[AppCopy.Workout.noAutomaticTarget].exists)
        XCTAssertFalse(
            staticText(in: app, containing: "Every set reached the top").exists
        )
        XCTAssertFalse(
            staticText(in: app, containing: AppCopy.Workout.addARepReason).exists
        )
        XCTAssertFalse(
            staticText(in: app, containing: AppCopy.Workout.repeatTargetReason).exists
        )
    }
}
