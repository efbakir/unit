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

    func testProfileDoesNotTreatStartingTargetsAsCompletedProgress() throws {
        let app = makeStartingTargetApp(reset: true)
        app.launch()
        XCTAssertTrue(app.staticTexts["Today"].waitForExistence(timeout: 20))
        tap(app.tabBars.buttons["Analytics"], "empty Profile tab")
        XCTAssertTrue(app.staticTexts["No workouts yet"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["analytics-summary"].exists)
        XCTAssertFalse(staticText(in: app, containing: "Accepted next target").exists)
        XCTAssertFalse(button(in: app, containing: "Bench Press").exists)
        attachScreenshot(of: app, named: "profile-empty-starting-target")
    }

    func testProgressionContract_outcomesActionsPersistenceAndNextWorkout() throws {
        var app = makeApp(reset: true)
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Upper A"].waitForExistence(timeout: 20),
            "Seeded active workout did not open"
        )
        let finishWorkout = app.buttons[AppCopy.Workout.finishShort].firstMatch
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
            staticText(in: app, containing: AppCopy.Workout.allSetsReachedTopReason).exists,
            "Increase-weight explanation is missing"
        )
        attachScreenshot(of: app, named: "01b-completed-workout-summary")
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
        let weightField = app.textFields[AppCopy.Workout.nextTargetLabel]
        let repsField = app.textFields[AppCopy.Workout.repsLabel]
        XCTAssertEqual(weightField.frame.width, repsField.frame.width, accuracy: 1)
        XCTAssertEqual(weightField.frame.height, repsField.frame.height, accuracy: 1)
        attachScreenshot(of: app, named: "05-matched-target-inputs")
        tap(repsField, "Edit target reps")
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5))
        repsField.doubleTap()
        if app.menuItems["Select All"].waitForExistence(timeout: 1) {
            app.menuItems["Select All"].tap()
        }
        let previousReps = repsField.value as? String ?? ""
        repsField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: previousReps.count))
        attachScreenshot(of: app, named: "05-empty-target-reps")
        XCTAssertEqual(repsField.value as? String, "")
        let disabledSave = NSPredicate(format: "isEnabled == false")
        expectation(for: disabledSave, evaluatedWith: app.buttons[AppCopy.Workout.saveChanges])
        waitForExpectations(timeout: 3)
        repsField.typeText("10")
        tap(app.buttons[AppCopy.Nav.done], "Dismiss target keyboard")
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
        tap(app.tabBars.buttons["Analytics"], "Analytics tab")
        XCTAssertTrue(app.buttons["analytics-summary"].waitForExistence(timeout: 8))
        attachScreenshot(of: app, named: "09-analytics-summary-kg")
        var profileExercise = button(in: app, containing: "Bench Press")
        scrollTo(profileExercise, in: app, maximumSwipes: 6)
        tap(profileExercise, "Analytics exercise progress")
        XCTAssertTrue(staticText(in: app, containing: "60 kg × 10").waitForExistence(timeout: 10))
        XCTAssertTrue(staticText(in: app, containing: "62.5 kg × 8").exists)
        attachScreenshot(of: app, named: "09-analytics-exercise-kg")
        tap(app.navigationBars.buttons.firstMatch, "back to Analytics")

        tap(app.tabBars.buttons["Programs"], "Programs settings entry")
        tap(app.buttons["Settings"], "Settings")
        tap(app.buttons["lb"].firstMatch, "pounds weight unit")
        tap(app.buttons["Close"], "Close Settings")
        tap(app.tabBars.buttons["Analytics"], "Analytics in pounds")
        profileExercise = button(in: app, containing: "Bench Press")
        scrollTo(profileExercise, in: app)
        tap(profileExercise, "Analytics exercise in pounds")
        XCTAssertTrue(staticText(in: app, containing: "132.3 lb × 10").waitForExistence(timeout: 10))
        XCTAssertTrue(staticText(in: app, containing: "137.8 lb × 8").exists)
        tap(app.buttons["Volume"].firstMatch, "working-set volume metric")
        attachScreenshot(of: app, named: "09-analytics-volume-lb")
        tap(app.navigationBars.buttons.firstMatch, "back to Analytics")
        tap(app.tabBars.buttons["Programs"], "Programs")
        tap(app.buttons["Settings"], "Settings to restore kilograms")
        tap(app.buttons["kg"].firstMatch, "kilograms weight unit")
        tap(app.buttons["Close"], "Close Settings")
        tap(app.tabBars.buttons["Today"], "Today tab")
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
            staticText(in: app, containing: "60 kg × 10")
                .waitForExistence(timeout: 10),
            "History did not explain the best set with readable units"
        )
        XCTAssertTrue(
            app.staticTexts["Best set"].exists,
            "History did not label its all-time best set"
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
            app.buttons["complete-set-1"].waitForExistence(timeout: 10)
                && (app.textFields["logging-weight"].firstMatch.value as? String) == "62.5"
                && (app.textFields["logging-reps"].firstMatch.value as? String) == "8",
            "Accepted complete target is not prefilled in the next workout"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Last time 60 × 10").exists,
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
        // Exercise-done preview (2026-10-23): a finished progression exercise
        // shows the same suggestion the summary will offer, before Finish.
        let exerciseDoneSuggestion = app.descendants(matching: .any).matching(
            NSPredicate(format: "label CONTAINS %@ OR value CONTAINS %@",
                        "Suggested next: 140 lb × 8", "Suggested next: 140 lb × 8")
        ).firstMatch
        XCTAssertTrue(
            exerciseDoneSuggestion.waitForExistence(timeout: 10),
            "Finished Bench Press card did not show its suggested next target"
        )
        attachScreenshot(of: app, named: "exercise-done-suggestion")
        let finishWorkout = app.buttons[AppCopy.Workout.finishShort].firstMatch
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
            staticText(in: app, containing: "Previous").exists
                && staticText(in: app, containing: "3 × 10 at 135 lb").exists,
            "US screenshot recommendation lost the 135 lb evidence"
        )
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Workout.allSetsReachedTopReason).exists,
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
        // October Analytics layout: "Best set" is a row title with the value
        // beside it (thin spaces between number, unit and ×).
        XCTAssertTrue(
            staticText(in: app, containing: "Best set").waitForExistence(timeout: 10)
                && staticText(in: app, containing: "135").exists
                && staticText(in: app, containing: "lb").exists,
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
            app.buttons["complete-set-1"].waitForExistence(timeout: 10)
                && (app.textFields["logging-weight"].firstMatch.value as? String) == "140",
            "Accepted US target was not prefilled"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Last time 135 × 10").exists,
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

        tap(app.buttons["complete-set-1"], "Complete the prefilled first set")

        XCTAssertTrue(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier == %@", "logged-set-1")
            ).firstMatch.waitForExistence(timeout: 8),
            "The one-tap action did not record the first set"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "60 kg × 8").exists,
            "The next set did not retain the within-session 60 kg × 8 prefill"
        )
        XCTAssertTrue(
            app.buttons["Skip"].waitForExistence(timeout: 8),
            "The normal rest timer did not begin after one-tap completion"
        )
        attachScreenshot(of: app, named: "10-first-session-set-completed")
    }

    func testSetUndoAndInterruptedWorkoutSurviveRelaunch() throws {
        var app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.buttons[AppCopy.Workout.startWorkout], "Start isolated workout", timeout: 20)
        tap(app.buttons["complete-set-1"], "Log seeded 60 kg × 8 set")
        let loggedSet = app.buttons.matching(
            NSPredicate(format: "identifier == %@", "logged-set-1")
        ).firstMatch
        XCTAssertTrue(loggedSet.waitForExistence(timeout: 8))
        let originalLabel = loggedSet.label
        tap(loggedSet, "Edit completed set")
        tap(app.buttons["Mark not done"], "Mark completed set not done")
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
            NSPredicate(format: "identifier == %@", "logged-set-1")
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

    func testNativeSegmentedSelectionContracts() throws {
        var app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.tabBars.buttons["Programs"], "Programs", timeout: 20)
        tap(app.buttons["Settings"], "Settings")
        let pounds = app.buttons["lb"].firstMatch
        tap(pounds, "Weight unit pounds")
        XCTAssertTrue(pounds.isSelected)
        XCTAssertTrue(app.segmentedControls["Weight unit"].exists, "Weight units must use a native segmented picker")
        XCTAssertGreaterThanOrEqual(pounds.frame.width, 44)
        attachScreenshot(of: app, named: "native-01-settings-pounds")
        app.terminate()
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-lifetime-owner"]
        app.launch()
        tap(app.tabBars.buttons["Programs"], "Programs after relaunch", timeout: 20)
        tap(app.buttons["Settings"], "Settings after relaunch")
        XCTAssertTrue(app.buttons["lb"].firstMatch.isSelected, "Weight unit did not persist")
        tap(app.buttons["kg"].firstMatch, "Restore kilograms")

        let components = button(in: app, containing: "Components")
        scrollTo(components, in: app)
        tap(components, "Components")
        scrollTo(app.staticTexts["Native · existing selection"], in: app, maximumSwipes: 16)
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            let native = app.segmentedControls["Native history view"]
            XCTAssertTrue(native.waitForExistence(timeout: 5), "Expected native segmented Picker")
            tap(native.buttons["Calendar"], "Native calendar")
            XCTAssertTrue(native.buttons["Calendar"].isSelected)
            XCTAssertGreaterThanOrEqual(native.buttons["Calendar"].frame.height, 44)
            tap(native.buttons["List"], "Native list")
            XCTAssertTrue(native.buttons["List"].isSelected)
        } else {
            XCTAssertTrue(app.segmentedControls["Native history view"].exists, "iOS 18 must also use the native picker")
        }
        attachScreenshot(of: app, named: "native-02-native-and-retained")
        let unansweredList = app.buttons["Unanswered List"]
        let unansweredCalendar = app.buttons["Unanswered Calendar"]
        scrollTo(unansweredCalendar, in: app)
        XCTAssertFalse(unansweredList.isSelected)
        XCTAssertFalse(unansweredCalendar.isSelected)
        attachScreenshot(of: app, named: "native-03-unanswered")
        tap(unansweredCalendar, "Answer calendar")
        XCTAssertTrue(unansweredCalendar.isSelected)
        tap(unansweredList, "Switch answer to list")
        XCTAssertTrue(unansweredList.isSelected)
        XCTAssertFalse(unansweredCalendar.isSelected)
        attachScreenshot(of: app, named: "native-04-answered")
        scrollTo(app.buttons["Clear answer"], in: app)
        tap(app.buttons["Clear answer"], "Clear answer")
        XCTAssertFalse(unansweredList.isSelected)
        XCTAssertFalse(unansweredCalendar.isSelected)
        scrollTo(app.buttons["Restricted Calendar"], in: app)
        XCTAssertFalse(app.buttons["Restricted Calendar"].isEnabled)
        XCTAssertTrue(app.buttons["Restricted List"].isEnabled)
        XCTAssertTrue(app.buttons["Restricted List"].isSelected)
        XCTAssertGreaterThanOrEqual(app.buttons["Restricted Calendar"].frame.height, 44)
        attachScreenshot(of: app, named: "native-05-disabled")
        if ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            let inherited = app.segmentedControls["Disabled history view"]
            scrollTo(inherited, in: app)
            XCTAssertFalse(inherited.buttons["Calendar"].isEnabled)
            let idPicker = app.segmentedControls["ID history view"]
            scrollTo(idPicker, in: app)
            tap(idPicker.buttons["Calendar"], "ID selection calendar")
            XCTAssertTrue(idPicker.buttons["Calendar"].isSelected)
        }
        attachScreenshot(of: app, named: "native-06-id-selection")
    }

    func testNativeHistoryAndProgressConsumers() throws {
        var app = makeApp(reset: true)
        app.launch()
        tap(app.buttons[AppCopy.Workout.finishShort].firstMatch, "Finish seeded workout", timeout: 20)
        tap(app.alerts.firstMatch.buttons[AppCopy.Workout.finishWorkout], "Confirm finish")
        XCTAssertTrue(app.staticTexts[AppCopy.Workout.nextTimeTitle].waitForExistence(timeout: 15))
        app.terminate()
        app = makeApp()
        app.launch()
        tap(app.buttons[AppCopy.Nav.history], "History", timeout: 20)
        XCTAssertTrue(app.segmentedControls["History view"].exists, "History must use the native picker")
        tap(app.buttons["Calendar"], "History calendar")
        XCTAssertTrue(app.buttons["Calendar"].isSelected)
        attachScreenshot(of: app, named: "native-07-history-calendar")
        tap(app.buttons["List"], "History list")
        XCTAssertTrue(app.buttons["List"].isSelected)
        attachScreenshot(of: app, named: "native-08-history-list")
        tap(app.buttons["history-session-row"].firstMatch, "Completed session")
        let exercise = button(in: app, containing: "Bench Press")
        scrollTo(exercise, in: app)
        tap(exercise, "Exercise progress")
        XCTAssertTrue(app.segmentedControls["Progress metric"].exists, "Progress must use the native picker")
        tap(app.buttons["Reps"], "Progress reps")
        XCTAssertTrue(app.buttons["Reps"].isSelected)
        attachScreenshot(of: app, named: "native-09-progress-reps")
        tap(app.buttons["Volume"], "Progress volume")
        XCTAssertTrue(app.buttons["Volume"].isSelected)
        attachScreenshot(of: app, named: "native-10-progress-volume")
        tap(app.buttons["Weight"], "Progress weight")
        XCTAssertTrue(app.buttons["Weight"].isSelected)
    }

    func testNativeSetCountConsumer() throws {
        let app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.tabBars.buttons["Programs"], "Programs", timeout: 20)
        tap(button(in: app, containing: "Freestyle session"), "Start freestyle")
        let add = app.buttons[AppCopy.Workout.addExercise]
        scrollTo(add, in: app)
        tap(add, "Add exercise")
        let search = app.searchFields.firstMatch
        if !search.waitForExistence(timeout: 2) {
            tap(button(in: app, containing: "Search"), "Open exercise search")
        }
        tap(search, "Find exercise")
        search.typeText("Barbell Curl")
        tap(button(in: app, containing: "Barbell Curl"), "Barbell Curl")
        XCTAssertTrue(app.staticTexts[AppCopy.Workout.setCountQuestion].waitForExistence(timeout: 8))
        tap(app.buttons["5"], "Five sets")
        XCTAssertTrue(app.buttons["5"].isSelected)
        XCTAssertGreaterThanOrEqual(app.buttons["5"].frame.height, 44)
        attachScreenshot(of: app, named: "native-11-set-count")
        tap(app.buttons[AppCopy.Nav.done].firstMatch, "Commit set count")
        XCTAssertTrue(app.staticTexts[AppCopy.Workout.setCountQuestion].waitForNonExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Barbell Curl"].exists)
    }

    func testNativeSelectionsAtLargeText() throws {
        let app = makeStartingTargetApp(reset: true)
        app.launch()
        tap(app.tabBars.buttons["Programs"], "Programs", timeout: 20)
        tap(app.buttons["Settings"], "Settings")
        let components = button(in: app, containing: "Components")
        scrollTo(components, in: app)
        tap(components, "Components")
        tap(app.switches["Large text preview"], "Accessibility text size")
        scrollTo(app.staticTexts["Native · existing selection"], in: app, maximumSwipes: 24)
        attachScreenshot(of: app, named: "native-15-large-text-native")
        let retained = app.buttons["Retained Calendar"]
        scrollTo(retained, in: app, maximumSwipes: 8)
        tap(retained, "Retained calendar at large text")
        XCTAssertTrue(retained.isSelected)
        XCTAssertTrue(app.segmentedControls["Retained history view"].exists)
        XCTAssertLessThanOrEqual(retained.frame.maxX, app.frame.maxX)
        attachScreenshot(of: app, named: "native-16-large-text-retained")
    }

    // MARK: - Helpers

    private func makeApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-progression-contract", "-AppleLocale", "en_US", "-AppleLanguages", "(en)"
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
            "-ui-testing-starting-target", "-AppleLocale", "en_US", "-AppleLanguages", "(en)"
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
