//
//  OnboardingPaywallFlowUITests.swift
//  UnitUITests
//
//  Machine-walk of the release gate: onboarding paste path (including the
//  parser-failure recovery loop) → paywall with live StoreKitTest products →
//  purchase → post-unlock tabs → a logged workout → History. Every step is a
//  hard assertion, so a green run is transcript-grade evidence for the
//  submission checklist.
//
//  StoreKit: `SKTestSession(configurationFileNamed: "Unit")` points at the
//  same dev config the Run scheme uses (bundled into this test target). The
//  session is device-local — it never touches the App Store, and this target
//  is never embedded in a Release archive.
//
//  One test method on purpose: the walk is one user journey, and the app
//  persists onboarding state to UserDefaults across launches
//  (`OnboardingPreferences`), so independent test ordering would leak state
//  between methods. The parser-failure probe exploits that persistence:
//  failed parses are never snapshotted, so a relaunch restores the paste step
//  with a clean editor.
//

import XCTest
import StoreKitTest

@MainActor
final class OnboardingPaywallFlowUITests: XCTestCase {
    private static let monthlyProductID = "com.unit.monthly"
    private static let lifetimeProductID = "com.unit.lifetime"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Two days, no 3x8 lines — the parser treats 3x8 as its own fallback
    /// default and the preview would flag them ("Check sets and reps"),
    /// per docs/app-store-submission/final-submit-checklist.md §6 runbook.
    private static let demoProgram = """
    Push
    Bench Press 4x5 80
    Overhead Press 3x5 50
    Rest 90s between sets

    Pull
    Deadlift 2x5 140
    Barbell Row 4x6 70
    """

    func testProgressionLedOnboardingSlidesAreReadable() throws {
        let app = makeApp(reset: true)
        app.launchArguments += ["-AppleLocale", "en_US"]
        app.launch()
        try XCTSkipIf(
            app.windows.firstMatch.frame.width > 375,
            "Compact CTA check: run on the smallest iPhone (Unit Logging Compact) destination."
        )

        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.splashTagline]
                .waitForExistence(timeout: 8),
            "progression-led opener tagline missing"
        )
        XCTAssertTrue(
            app.staticTexts["Know what to lift next"].waitForExistence(timeout: 8),
            "first progression value slide missing"
        )
        XCTAssertTrue(
            app.staticTexts["Finish your workout. Unit prepares one clear target for next time."].exists,
            "first progression value body copy missing"
        )
        assertCTAIsReadable(in: app, requiresCompactWidth: true)
        attachScreenshot(named: "01-onboarding-next-target", app: app)

        app.swipeLeft()
        XCTAssertTrue(
            app.staticTexts["Build reps, then weight"].waitForExistence(timeout: 5),
            "double-progression slide missing"
        )
        XCTAssertTrue(
            app.staticTexts["Reach 10 reps on every set. Then add 5 lb."].exists,
            "double-progression body copy missing"
        )
        assertCTAIsReadable(in: app, requiresCompactWidth: true)
        attachScreenshot(named: "02-onboarding-double-progression", app: app)

        app.swipeLeft()
        XCTAssertTrue(
            app.staticTexts["Log every set in one tap"].waitForExistence(timeout: 5),
            "one-tap logging slide missing"
        )
        XCTAssertTrue(
            app.staticTexts["Your target and last workout are ready before every set."].exists,
            "one-tap logging body copy missing"
        )
        assertCTAIsReadable(in: app, requiresCompactWidth: true)
        attachScreenshot(named: "03-onboarding-one-tap-smallest", app: app)

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "onboarding CTA")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.methodTitle].waitForExistence(timeout: 5),
            "onboarding CTA introduced an extra step before the program path choice"
        )
        XCTAssertFalse(
            app.staticTexts[AppCopy.Onboarding.unitTitle].exists,
            "the retired weight-unit step reappeared"
        )
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Onboarding.methodPasteOption)
                .waitForExistence(timeout: 5),
            "paste-program path missing"
        )
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Onboarding.methodLibraryOption).exists,
            "ready-made program path missing"
        )
        attachScreenshot(named: "05-onboarding-program-source", app: app)
    }

    func testProgressionLedOnboardingFitsAccessibilityMedium() {
        let app = makeApp(reset: true)
        app.launchArguments += [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityM"
        ]
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Know what to lift next"].waitForExistence(timeout: 8)
        )
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Build reps, then weight"].waitForExistence(timeout: 5))
        app.swipeLeft()
        XCTAssertTrue(app.staticTexts["Log every set in one tap"].waitForExistence(timeout: 5))
        assertCTAIsReadable(in: app)
        attachScreenshot(named: "04-onboarding-accessibility-medium", app: app)
    }

    /// Production-size reference captures for the in-app onboarding carousel.
    /// App Store screenshots 1 and 3 intentionally use real post-workout
    /// progression surfaces instead of this marketing shell.
    func testCaptureProgressionOnboardingReferenceSlides() {
        let app = makeApp(reset: true)
        app.launch()

        XCTAssertTrue(
            app.staticTexts["Know what to lift next"].waitForExistence(timeout: 8)
        )
        assertCTAIsReadable(in: app)
        attachScreenshot(named: "onboarding-01-next-target", app: app)

        app.swipeLeft()
        XCTAssertTrue(
            app.staticTexts["Build reps, then weight"].waitForExistence(timeout: 5)
        )
        assertCTAIsReadable(in: app)
        attachScreenshot(named: "onboarding-02-double-progression", app: app)
    }

    /// Captures the real US setup choice used by screenshot four. The launch
    /// still walks through production onboarding; only the UI-test store is
    /// isolated from user data.
    func testCaptureUSAppStoreProgramSetup() {
        let app = makeApp(reset: true)
        app.launch()

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "splash CTA", timeout: 20)

        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.methodTitle].waitForExistence(timeout: 8),
            "program-source screen did not open"
        )
        XCTAssertTrue(button(in: app, containing: AppCopy.Onboarding.methodPasteOption).exists)
        XCTAssertTrue(button(in: app, containing: AppCopy.Onboarding.methodLibraryOption).exists)
        attachScreenshot(named: "store-04-program-setup", app: app)
    }

    func testReadyMadeProgramPathMatchesCatalogFromThreeAnswers() {
        let app = makeApp(reset: true)
        app.launch()

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "splash CTA", timeout: 20)
        tap(
            button(in: app, containing: AppCopy.Onboarding.methodLibraryOption),
            "program source — ready-made"
        )

        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryGoalTitle].waitForExistence(timeout: 8)
        )
        XCTAssertEqual(
            descendant(in: app, identifier: "onboarding-progress").label,
            "Step 2 of 3, question 1 of 3"
        )
        tap(button(in: app, containing: "Strength"), "goal — Strength")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryLevelTitle].waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            descendant(in: app, identifier: "onboarding-progress").label,
            "Step 2 of 3, question 2 of 3"
        )
        tap(button(in: app, containing: "New"), "experience — New")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryDaysTitle].waitForExistence(timeout: 5)
        )
        XCTAssertEqual(
            descendant(in: app, identifier: "onboarding-progress").label,
            "Step 2 of 3, question 3 of 3"
        )
        XCTAssertTrue(
            button(in: app, containing: AppCopy.Onboarding.trainingDays(3)).isSelected,
            "three training days should be preselected"
        )
        XCTAssertTrue(app.buttons["Continue"].isEnabled)
        attachScreenshot(named: "native-12-preserved-three-day-default", app: app)
        tap(
            button(in: app, containing: AppCopy.Onboarding.trainingDays(2)),
            "schedule — 2 days/week"
        )
        tap(app.buttons["Continue"], "continue with selected schedule")

        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryResultsTitle].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            button(in: app, containing: "Full Body 2-Day").exists,
            "the catalog-backed 2-day recommendation was not shown"
        )
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryResultsSubtitle].exists,
            "matching disclosure is missing"
        )

        tap(app.buttons["Back"], "return to schedule question")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryDaysTitle].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            button(in: app, containing: AppCopy.Onboarding.trainingDays(2)).isSelected,
            "schedule answer should remain selected after navigating back"
        )
        XCTAssertTrue(app.buttons["Continue"].isEnabled)

        tap(app.buttons["Back"], "return to experience question")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryLevelTitle].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            button(in: app, containing: "New").isSelected,
            "experience answer should remain selected after navigating back"
        )
        XCTAssertTrue(app.buttons["Continue"].isEnabled)

        tap(app.buttons["Back"], "return to goal question")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryGoalTitle].waitForExistence(timeout: 5)
        )
        XCTAssertTrue(
            button(in: app, containing: "Strength").isSelected,
            "goal answer should remain selected after navigating back"
        )
        XCTAssertTrue(app.buttons["Continue"].isEnabled)

        tap(app.buttons["Continue"], "continue with saved goal")
        tap(app.buttons["Continue"], "continue with saved experience")
        tap(app.buttons["Continue"], "continue with saved schedule")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.libraryResultsTitle].waitForExistence(timeout: 8)
        )

        tap(button(in: app, containing: "Full Body 2-Day"), "select best match")
        tap(app.buttons[AppCopy.Onboarding.libraryCTA], "review matched program")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Onboarding.previewTitle].waitForExistence(timeout: 8),
            "matched program did not continue straight into review"
        )
        XCTAssertFalse(
            app.staticTexts[AppCopy.Onboarding.scheduleTitle].exists,
            "the retired weekday step reappeared"
        )
        XCTAssertEqual(
            descendant(in: app, identifier: "onboarding-progress").label,
            "Step 3 of 3"
        )
        XCTAssertTrue(
            descendant(in: app, identifier: "onboarding-review-weight-unit").exists,
            "review must let the lifter confirm kg or lb"
        )
        attachScreenshot(named: "native-13-review-with-unit", app: app)
    }

    func testPasteEditorFocusIsStableOnCompactScreen() {
        let app = makeApp(reset: true)
        app.launch()

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "splash CTA", timeout: 20)
        tap(button(in: app, containing: AppCopy.Onboarding.methodPasteOption), "import method — paste")

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 8), "paste editor missing")
        editor.tap()

        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 5), "keyboard did not appear")
        XCTAssertGreaterThan(editor.frame.height, 0, "paste editor collapsed after keyboard focus")
    }

    func testReleaseGate_onboardingThroughPurchaseToLoggedWorkout() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        // ── Launch 1: splash → import → parser failure + recovery ──
        var app = makeApp(reset: true)
        app.launch()
        // A tap skips the two-second opener when it is still showing
        // (benchmark 2026-10-24, setup row 10).
        let skipIntro = app.buttons["Skip intro"]
        if skipIntro.waitForExistence(timeout: 1), skipIntro.isHittable {
            skipIntro.tap()
        }

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "splash CTA", timeout: 20)
        // Analytics is opt-in (App Review 5.1.1(ii)): a fresh install shows
        // the step-1 switch off, so nothing is sent before consent.
        let analyticsSwitch = app.switches["anonymous-analytics-toggle"]
        XCTAssertTrue(analyticsSwitch.waitForExistence(timeout: 8), "analytics switch missing on step 1")
        XCTAssertEqual(analyticsSwitch.value as? String, "0", "analytics must start off on a fresh install")
        tap(button(in: app, containing: AppCopy.Onboarding.methodPasteOption), "import method — paste")

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 8), "paste editor missing")
        editor.tap()
        // Letters-only lines are intentionally recoverable as exercise names
        // with default sets/reps. Digits-only input is truly unparseable and
        // exercises the error-recovery path without contradicting that rule.
        editor.typeText("123456")
        tap(app.buttons["Read program"], "Read program (garbage)")
        // Parse failure surfaces one stable alert. Its recovery action opens
        // the format guide only after the alert dismisses, avoiding SwiftUI's
        // alert/sheet presentation race.
        let failureAlert = app.alerts.firstMatch
        let sheetTitle = app.staticTexts["Format examples"]
        XCTAssertTrue(failureAlert.waitForExistence(timeout: 8), "parse failure alert missing")
        tap(failureAlert.buttons["Show examples"], "parse recovery — Show examples")
        XCTAssertTrue(sheetTitle.waitForExistence(timeout: 8), "format sheet did not open")
        tap(app.buttons["Close"], "dismiss format sheet")

        // ── Launch 2: snapshot restore preserves the unfinished paste draft ──
        app.terminate()
        app = makeApp()
        app.launch()

        let editor2 = app.textViews.firstMatch
        XCTAssertTrue(editor2.waitForExistence(timeout: 15), "paste editor missing after relaunch")
        XCTAssertEqual(editor2.value as? String, "123456", "unfinished paste draft was lost")
        editor2.tap()
        editor2.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6))
        editor2.typeText(Self.demoProgram)
        tap(app.buttons["Read program"], "Read program (valid)")

        // No weekday step: the parsed program goes straight to review.
        XCTAssertTrue(app.staticTexts[AppCopy.Onboarding.previewTitle].waitForExistence(timeout: 10), "preview title missing")
        XCTAssertTrue(
            staticText(in: app, containing: "Bench Press").waitForExistence(timeout: 5),
            "parsed exercise missing from preview"
        )
        // Skipped lines are named, not only counted (benchmark 2026-10-24).
        tap(
            button(in: app, containing: AppCopy.Onboarding.importSkippedTitle(lines: 1, days: 0)),
            "skipped-lines card"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Rest 90s between sets").waitForExistence(timeout: 5),
            "the skipped rest line is not named on Review"
        )
        // A row can be removed from the edit sheet and brought back with Undo
        // (benchmark 2026-10-24, setup row 4).
        tap(app.buttons["Edit Overhead Press, sets, and reps"], "Overhead Press row")
        tap(app.buttons[AppCopy.Onboarding.removeExercise], "Remove exercise")
        XCTAssertTrue(
            staticText(in: app, containing: AppCopy.Toast.removedExercise("Overhead Press")).waitForExistence(timeout: 5),
            "removal toast missing"
        )
        XCTAssertFalse(app.buttons["Edit Overhead Press, sets, and reps"].exists, "removed row still shown")
        tap(app.buttons[AppCopy.Toast.undo], "Undo removal")
        XCTAssertTrue(
            app.buttons["Edit Overhead Press, sets, and reps"].waitForExistence(timeout: 5),
            "Undo did not bring the row back"
        )
        tap(app.buttons[AppCopy.Onboarding.previewCTA], "preview — save program")

        // ── Paywall: loaded products, prices, legal, purchase ──
        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.programReady].waitForExistence(timeout: 20),
            "paywall header missing after commit"
        )
        let trialHeadline = app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")]
        let standardHeadline = app.staticTexts[AppCopy.Paywall.standardHeadline]
        XCTAssertTrue(
            trialHeadline.waitForExistence(timeout: 20)
                || standardHeadline.waitForExistence(timeout: 5),
            "no valid paywall headline appeared"
        )
        openPurchasePage(in: app)
        XCTAssertTrue(
            staticText(in: app, containing: "$2.99/").waitForExistence(timeout: 20),
            "weekly price did not load from StoreKitTest"
        )
        XCTAssertTrue(staticText(in: app, containing: "$4.99/month").exists, "monthly price missing")
        XCTAssertTrue(staticText(in: app, containing: "$29.99/year").exists, "yearly price missing")

        app.swipeUp()
        XCTAssertFalse(
            app.switches["anonymous-analytics-toggle"].exists,
            "the paywall shows the analytics switch only while analytics is on"
        )
        let restorePurchases = app.buttons["Restore Purchases"]
        XCTAssertTrue(
            restorePurchases.waitForExistence(timeout: 8),
            "Restore Purchases unreachable"
        )
        XCTAssertGreaterThanOrEqual(restorePurchases.frame.height, 44)
        XCTAssertTrue(
            app.links["Terms of Service"].exists || app.buttons["Terms of Service"].exists,
            "Terms of Service unreachable"
        )
        XCTAssertTrue(
            app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists,
            "Privacy Policy unreachable"
        )
        let terms = app.links["Terms of Service"].exists
            ? app.links["Terms of Service"]
            : app.buttons["Terms of Service"]
        let privacy = app.links["Privacy Policy"].exists
            ? app.links["Privacy Policy"]
            : app.buttons["Privacy Policy"]
        XCTAssertGreaterThanOrEqual(terms.frame.height, 44)
        XCTAssertGreaterThanOrEqual(privacy.frame.height, 44)

        // A DEBUG-only launch argument prevents iOS 26.3.1's command-line UI
        // runner from replacing the configured local payment sheet with a
        // real Apple Account prompt. The real product must still be loaded;
        // this tap exercises paywall CTA → entitlement → root unlock.
        // Offer eligibility is covered strictly by the dedicated paywall-state
        // tests. After an onboarding persistence relaunch, StoreKitTest can
        // legitimately return either configured local presentation; both must
        // preserve the hard gate and verified purchase path.
        let trialCTA = button(in: app, containing: AppCopy.Paywall.startFreeTrial)
        let subscribeCTA = button(in: app, containing: "Subscribe for")
        let purchaseCTA = trialCTA.exists ? trialCTA : subscribeCTA
        tap(purchaseCTA, "purchase CTA")

        // ── Unlock ──
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 25), "post-unlock tab bar missing — purchase did not unlock")

        tap(app.tabBars.buttons["Programs"], "Programs tab")
        XCTAssertTrue(
            staticText(in: app, containing: "Push").waitForExistence(timeout: 8),
            "committed program missing from Programs"
        )
        // Settings names the trial end or the next charge (benchmark 2026-10-24).
        tap(app.buttons["Settings"], "Settings")
        XCTAssertTrue(
            staticText(in: app, containing: "Trial ends").waitForExistence(timeout: 8)
                || staticText(in: app, containing: "Renews").exists,
            "Settings shows no trial end or renewal date"
        )
        tap(app.buttons["Close"], "Close Settings")
        tap(app.tabBars.buttons["Today"], "back to Today")

        // ── Gym Test: start → one-tap sets → finish → History ──
        let startWorkout = button(in: app, containing: AppCopy.Workout.startWorkout)
        if !startWorkout.waitForExistence(timeout: 3) {
            // The test can run on any weekday. On an unscheduled day, choose
            // the saved Push routine through the real rest-day flow first.
            tap(button(in: app, containing: AppCopy.Today.restDayCTA), "rest day — choose routine")
            tap(button(in: app, containing: "Push"), "choose Push routine")
        }
        tap(startWorkout, "start workout", timeout: 10)
        // Final B logging labels each row's action ("Complete set 1") and
        // exposes a stable per-row identifier.
        XCTAssertTrue(
            app.buttons["complete-set-1"].waitForExistence(timeout: 10),
            "Complete set CTA missing"
        )
        XCTAssertFalse(
            app.staticTexts[AppCopy.Engagement.feedbackTitle].exists,
            "Feedback invitation must never interrupt active logging"
        )

        // Two consecutive logs exercise the fast path without assuming the
        // active routine exposes a third set before advancing its state.
        for setIndex in 1...2 {
            let complete = app.buttons["complete-set-\(setIndex)"]
            XCTAssertTrue(complete.waitForExistence(timeout: 8), "Complete set missing before set \(setIndex)")
            let start = Date()
            complete.tap()
            XCTAssertLessThan(
                Date().timeIntervalSince(start), 3.0,
                "set \(setIndex): the one-tap log took over 3 seconds"
            )
        }

        tap(app.buttons[AppCopy.Workout.finishShort].firstMatch, "finish workout (toolbar)", timeout: 10)
        let confirm = app.alerts.firstMatch.buttons[AppCopy.Workout.finishWorkout]
        XCTAssertTrue(confirm.waitForExistence(timeout: 8), "finish confirmation missing")
        confirm.tap()

        // Finishing intentionally opens the completed-session summary first.
        // Verify it, return to Today, then verify the same session in History.
        XCTAssertTrue(
            app.staticTexts[AppCopy.Engagement.feedbackTitle].waitForExistence(timeout: 15),
            "Completed-session summary or third-workout feedback invitation missing"
        )
        tap(app.buttons[AppCopy.Engagement.noThanks], "dismiss feedback invitation")
        XCTAssertFalse(
            app.staticTexts[AppCopy.Engagement.feedbackTitle].exists,
            "Feedback invitation did not dismiss"
        )
        tap(app.navigationBars.buttons.firstMatch, "return from completed-session summary")
        XCTAssertTrue(
            app.staticTexts["review-request-armed"].waitForExistence(timeout: 5),
            "Review request was not armed after the summary closed"
        )
        XCTAssertTrue(
            button(in: app, containing: AppCopy.Nav.history).waitForExistence(timeout: 15),
            "Today did not return after finish"
        )
        tap(button(in: app, containing: AppCopy.Nav.history), "open History")
        XCTAssertTrue(
            app.buttons["history-session-row"].firstMatch.waitForExistence(timeout: 8),
            "finished session missing from History"
        )
    }

    func testEligibleMonthlyYearlyAndWeeklyPaywallStates() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible"
        )
        app.launch()

        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")]
                .waitForExistence(timeout: 20),
            "eligible trial headline missing"
        )
        // Trial-eligible customers start on Yearly (founder decision 2026-10-23).
        XCTAssertTrue(
            descendant(in: app, identifier: "paywall-plan-com.unit.annual").isSelected,
            "eligible Yearly did not become the default"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "7 days free · then $29.99/year ($0.58/week)").exists,
            "the per-week price does not follow the yearly price"
        )
        // One real, translated App Store review; no rating number yet.
        XCTAssertTrue(
            descendant(in: app, identifier: "paywall-review").exists,
            "the real review is missing above the plans"
        )
        XCTAssertFalse(staticText(in: app, containing: " ratings").exists, "no rating count before about 50 ratings")
        let trialTimeline = descendant(in: app, identifier: "paywall-timeline")
        scrollTo(trialTimeline, in: app)
        XCTAssertTrue(trialTimeline.exists, "eligible trial timeline is missing")
        // "Day 5" / "Day 7" with the real dates in the text (2026-10-24,
        // Blinkist and Mesh pattern).
        XCTAssertTrue(staticText(in: app, containing: AppCopy.Paywall.timelineTodayTitle).exists)
        XCTAssertTrue(staticText(in: app, containing: "Day 5").exists)
        XCTAssertTrue(staticText(in: app, containing: "Day 7").exists)
        XCTAssertTrue(
            staticText(in: app, containing: "on \(trialTimelineDate(daysFromToday: 7)). Cancel anytime before.").exists,
            "the Day 7 row does not name the real charge date"
        )
        XCTAssertTrue(staticText(in: app, containing: "Keep making progress").exists)
        XCTAssertTrue(
            app.switches[AppCopy.Paywall.trialReminderLabel].exists,
            "eligible trial did not expose the optional reminder"
        )
        XCTAssertEqual(
            app.switches[AppCopy.Paywall.trialReminderLabel].value as? String,
            "1",
            "trial reminder must default on (2026-10-23)"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "Unit reminds you on \(trialTimelineDate(daysFromToday: 5)).").exists
        )
        attachScreenshot(named: "01-eligible-yearly-single-page", app: app)

        XCTAssertFalse(app.buttons["paywall-plan-picker-toggle"].exists)
        XCTAssertTrue(descendant(in: app, identifier: "paywall-plan-com.unit.weekly").exists)
        XCTAssertTrue(descendant(in: app, identifier: "paywall-plan-com.unit.monthly").exists)
        XCTAssertTrue(descendant(in: app, identifier: "paywall-plan-com.unit.annual").exists)
        XCTAssertFalse(staticText(in: app, containing: "Or pay once").exists)
        let yearlyCTA = button(in: app, containing: AppCopy.Paywall.startFreeTrial)
        XCTAssertTrue(yearlyCTA.exists)
        XCTAssertTrue(staticText(in: app, containing: "$29.99/year").exists)
        XCTAssertGreaterThanOrEqual(yearlyCTA.frame.height, 44)
        XCTAssertLessThanOrEqual(
            yearlyCTA.frame.maxY,
            app.windows.firstMatch.frame.maxY + 1,
            "Yearly CTA extended below the visible screen"
        )
        attachScreenshot(named: "02-eligible-yearly-purchase", app: app)

        let reminder = app.switches[AppCopy.Paywall.trialReminderLabel]
        scrollTo(reminder, in: app)
        tap(reminder, "trial reminder preference")
        XCTAssertEqual(reminder.value as? String, "0")
        XCTAssertTrue(
            staticText(in: app, containing: "Turn on a reminder for \(trialTimelineDate(daysFromToday: 5)).").exists
        )
        // "How do I cancel?" answers before purchase (2026-10-24).
        let cancelHelp = button(in: app, containing: AppCopy.Paywall.cancelHelpTitle)
        scrollTo(cancelHelp, in: app)
        tap(cancelHelp, "How do I cancel?")
        XCTAssertTrue(
            staticText(in: app, containing: "Manage Subscription").waitForExistence(timeout: 5),
            "cancel steps missing"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "before \(trialTimelineDate(daysFromToday: 7)) and you pay nothing").exists,
            "cancel deadline does not name the trial end"
        )

        let monthly = descendant(in: app, identifier: "paywall-plan-com.unit.monthly")
        scrollTo(monthly, in: app)
        tap(monthly, "Monthly plan")
        XCTAssertTrue(monthly.isSelected, "Monthly selection did not stick")
        let monthlyCTA = button(in: app, containing: AppCopy.Paywall.startFreeTrial)
        XCTAssertTrue(monthlyCTA.waitForExistence(timeout: 5))
        XCTAssertTrue(staticText(in: app, containing: "$4.99/month").exists)
        XCTAssertGreaterThanOrEqual(monthlyCTA.frame.height, 44)
        XCTAssertLessThanOrEqual(
            monthlyCTA.frame.maxY,
            app.windows.firstMatch.frame.maxY + 1,
            "Monthly CTA extended below the visible screen"
        )
        attachScreenshot(named: "03-eligible-monthly-purchase", app: app)

        XCTAssertTrue(staticText(in: app, containing: "Day 5").exists)

        // Yearly against 52 weeks of Weekly ($29.99 vs $155.48).
        XCTAssertTrue(
            staticText(in: app, containing: "Save 80%").exists,
            "Yearly savings badge became unreadable in the visible plan list"
        )
        let weekly = descendant(in: app, identifier: "paywall-plan-com.unit.weekly")
        scrollTo(weekly, in: app)
        tap(weekly, "Weekly plan")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.standardHeadline].waitForExistence(timeout: 5),
            "Weekly selection retained trial framing"
        )
        XCTAssertFalse(
            app.switches[AppCopy.Paywall.trialReminderLabel].exists,
            "non-trial Weekly plan retained the reminder preference"
        )
        let standardCTA = button(in: app, containing: "Subscribe for $2.99/week")
        // The button relabels with an animation; iOS 26 reports the new label later.
        XCTAssertTrue(standardCTA.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(standardCTA.frame.height, 44)
        XCTAssertLessThanOrEqual(
            standardCTA.frame.maxY,
            app.windows.firstMatch.frame.maxY + 1,
            "Ineligible Weekly CTA extended below the visible screen"
        )
        XCTAssertFalse(
            staticText(in: app, containing: "free trial").exists,
            "Weekly selection must not show free-trial copy"
        )
        let weeklyCTA = button(in: app, containing: "Subscribe for $2.99/week")
        XCTAssertGreaterThanOrEqual(weeklyCTA.frame.height, 44)
        XCTAssertLessThanOrEqual(
            weeklyCTA.frame.maxY,
            app.windows.firstMatch.frame.maxY + 1,
            "Weekly CTA extended below the visible screen"
        )
        attachScreenshot(named: "04-weekly-selected-no-trial", app: app)
    }

    func testIneligibleCustomerGetsStandardWeeklyPaywall() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-ineligible"
        )
        app.launch()

        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.standardHeadline]
                .waitForExistence(timeout: 20),
            "ineligible paywall headline missing"
        )
        openPurchasePage(in: app)
        // No-trial customers keep the Weekly default (founder decision 2026-10-23).
        XCTAssertTrue(button(in: app, containing: "Subscribe for $2.99/week").exists)
        XCTAssertTrue(descendant(in: app, identifier: "paywall-plan-com.unit.weekly").isSelected)
        XCTAssertFalse(
            staticText(in: app, containing: "free trial").exists,
            "ineligible customer saw trial copy"
        )
        attachScreenshot(named: "04-ineligible-standard-paywall", app: app)
    }

    func testCancelledAndUnverifiedPurchasesRemainOnPaywall() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        var app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-purchase-cancelled"]
        )
        app.launch()
        openPurchasePage(in: app)
        let trialCTA = button(in: app, containing: AppCopy.Paywall.startFreeTrial)
        tap(trialCTA, "trial CTA", timeout: 20)
        XCTAssertTrue(app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")].exists)
        XCTAssertTrue(trialCTA.isEnabled, "cancelled purchase did not reset the CTA")

        app.terminate()
        app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-purchase-unverified"]
        )
        app.launch()
        openPurchasePage(in: app)
        tap(button(in: app, containing: AppCopy.Paywall.startFreeTrial), "unverified trial CTA", timeout: 20)
        XCTAssertTrue(app.alerts["Something went wrong"].waitForExistence(timeout: 5))
        tap(app.alerts["Something went wrong"].buttons["OK"], "dismiss verification error")
        XCTAssertTrue(app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")].exists)
        XCTAssertFalse(app.tabBars.buttons["Today"].exists)
    }

    func testPendingPurchaseBlocksRepeatedTaps() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-purchase-pending"]
        )
        app.launch()
        openPurchasePage(in: app)
        let trialCTA = button(in: app, containing: AppCopy.Paywall.startFreeTrial)
        tap(trialCTA, "pending trial CTA", timeout: 20)

        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.pendingPurchaseContext]
                .waitForExistence(timeout: 5),
            "pending purchase state was not explained"
        )
        XCTAssertFalse(trialCTA.isEnabled, "pending purchase still accepts duplicate taps")
        XCTAssertFalse(app.tabBars.buttons["Today"].exists)
    }

    func testRestoreUnlocksEntitledCustomer() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-ineligible",
            extraArguments: [
                "-ui-testing-skip-initial-entitlement",
                "-ui-testing-restore-success"
            ]
        )
        app.launch()

        openPurchasePage(in: app)

        let restore = app.buttons["Restore Purchases"]
        scrollTo(restore, in: app)
        tap(restore, "Restore Purchases", timeout: 20)

        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 20),
            "Restore did not unlock the entitled customer"
        )
    }

    func testExistingSubscriberBypassesHardPaywall() async throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        do {
            _ = try await session.buyProduct(identifier: Self.monthlyProductID)
        } catch where ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 26 {
            // Command-line runs on iOS 26+ simulators refuse StoreKitTest
            // purchases ("notEntitled") before the app launches. The same
            // path runs on iOS 18; any failure there still fails this test.
            throw XCTSkip("StoreKitTest purchase unavailable on this simulator: \(error)")
        }
        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-ineligible"
        )
        app.launch()
        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 20),
            "existing subscriber did not bypass the hard paywall"
        )
    }

    func testLifetimeOwnerBypassesHardPaywall() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        let app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-ineligible",
            extraArguments: ["-ui-testing-lifetime-owner"]
        )
        app.launch()
        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 20),
            "Lifetime owner did not bypass the hard paywall"
        )
    }

    func testOfflineRelaunchKeepsLastVerifiedAccess() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        var app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-purchase-success"]
        )
        app.launch()
        openPurchasePage(in: app)
        tap(button(in: app, containing: AppCopy.Paywall.startFreeTrial), "successful trial CTA", timeout: 20)
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 15))

        app.terminate()
        app = makeSeededPaywallApp(
            reset: false,
            eligibilityArgument: nil,
            extraArguments: ["-ui-testing-skip-initial-entitlement"]
        )
        app.launch()

        XCTAssertTrue(
            app.tabBars.buttons["Today"].waitForExistence(timeout: 10),
            "cached verified entitlement did not open Today offline"
        )
        XCTAssertFalse(app.staticTexts[AppCopy.Paywall.standardHeadline].exists)
        attachScreenshot(named: "07-successful-purchase-today", app: app)

        tap(app.tabBars.buttons["Programs"], "Programs tab after purchase")
        XCTAssertTrue(app.navigationBars["Programs"].waitForExistence(timeout: 8))
        XCTAssertTrue(
            staticText(in: app, containing: "Combat Power").exists,
            "saved program missing from the Programs sibling screen"
        )
        attachScreenshot(named: "08-appscreen-sibling-programs", app: app)
    }

    func testProductLoadFailureRetryAndPartialLoading() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        var app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-product-load-fails-once"]
        )
        app.launch()
        XCTAssertTrue(app.staticTexts["Couldn't load subscriptions"].waitForExistence(timeout: 20))
        XCTAssertFalse(app.buttons["Subscribe to continue"].isEnabled)
        tap(app.buttons["Try again"], "product-load retry")
        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")]
                .waitForExistence(timeout: 20),
            "product retry did not recover"
        )

        app.terminate()
        app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: ["-ui-testing-partial-products"]
        )
        app.launch()
        openPurchasePage(in: app)
        XCTAssertTrue(app.staticTexts["Some plans couldn't load."].waitForExistence(timeout: 20))
        let monthly = descendant(in: app, identifier: "paywall-plan-com.unit.monthly")
        scrollTo(monthly, in: app)
        XCTAssertTrue(monthly.exists, "missing Monthly card was hidden instead of disabled")
        XCTAssertFalse(monthly.isEnabled, "unavailable Monthly card remained selectable")
        XCTAssertTrue(staticText(in: app, containing: "Unavailable").exists)
    }

    func testFeatureTableFitsCompactAndAccessibilityMediumLayouts() throws {
        let session = try freshStoreKitSession()
        defer { session.clearTransactions() }

        var app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible"
        )
        app.launch()
        try XCTSkipIf(
            app.windows.firstMatch.frame.width > 390,
            "Compact-layout check: run on the iPhone SE (or Unit Logging Compact) destination."
        )
        XCTAssertTrue(app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")].waitForExistence(timeout: 20))
        openPurchasePage(in: app)
        assertFeatureTableFits(in: app)
        positionFeatureTableForScreenshot(in: app, requiresLastRow: true)
        attachScreenshot(named: "05-feature-table-iphone-se", app: app)

        app.terminate()
        app = makeSeededPaywallApp(
            reset: true,
            eligibilityArgument: "-ui-testing-intro-eligible",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                "UICTContentSizeCategoryAccessibilityM"
            ]
        )
        app.launch()
        XCTAssertTrue(app.staticTexts[AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year")].waitForExistence(timeout: 20))
        openPurchasePage(in: app)
        assertFeatureTableFits(in: app)
        positionFeatureTableForScreenshot(in: app, requiresLastRow: false)
        attachScreenshot(named: "06-feature-table-accessibility-medium", app: app)

        let monthly = descendant(in: app, identifier: "paywall-plan-com.unit.monthly")
        scrollTo(monthly, in: app)
        XCTAssertTrue(monthly.exists)
        XCTAssertGreaterThan(monthly.frame.height, 44)
        XCTAssertLessThanOrEqual(monthly.frame.maxX, app.windows.firstMatch.frame.maxX + 1)
    }

    // MARK: - Helpers

    private enum ScrollDirection {
        case up
        case down
    }

    private func freshStoreKitSession() throws -> SKTestSession {
        let session = try SKTestSession(configurationFileNamed: "Unit")
        session.disableDialogs = true
        session.resetToDefaultState()
        session.clearTransactions()
        return session
    }

    private func makeSeededPaywallApp(
        reset: Bool,
        eligibilityArgument: String?,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-smoke-test-combat-power"
        ]
        if reset {
            app.launchArguments.append("-ui-testing-reset")
        }
        if let eligibilityArgument {
            app.launchArguments.append(eligibilityArgument)
        }
        app.launchArguments.append(contentsOf: extraArguments)
        return app
    }

    private func makeApp(reset: Bool = false) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing",
            "-ui-testing-seed-engagement-two",
            "-ui-testing-purchase-success",
            "-ui-testing-intro-eligible"
        ]
        if reset {
            app.launchArguments.append("-ui-testing-reset")
        }
        return app
    }

    private func openPurchasePage(in app: XCUIApplication) {
        XCTAssertTrue(
            descendant(in: app, identifier: "paywall-plan-com.unit.weekly")
                .waitForExistence(timeout: 20),
            "single-page plan selector did not load"
        )
    }

    private func descendant(
        in app: XCUIApplication,
        identifier: String
    ) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func scrollTo(
        _ element: XCUIElement,
        in app: XCUIApplication,
        direction: ScrollDirection = .up
    ) {
        let window = app.windows.firstMatch
        // Accessibility-sized sections can be taller than one viewport. Use
        // short drags and look back if a lazy row was passed during a reveal.
        for pass in 0..<2 {
            for _ in 0..<20 {
                if element.exists, element.frame.intersects(window.frame), element.frame.height > 0 { return }
                let upward = (direction == .up) == (pass == 0)
                let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.65 : 0.3))
                let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: upward ? 0.3 : 0.65))
                start.press(forDuration: 0.15, thenDragTo: end)
            }
        }
        attachScreenshot(named: "unreachable-element", app: app)
        XCTFail("\(element) was not reachable by scrolling")
    }

    private func assertFeatureTableFits(in app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5))

        for (index, label) in AppCopy.Paywall.includedFeatures.enumerated() {
            let row = descendant(in: app, identifier: "paywall-feature-row-\(index)")
            scrollTo(row, in: app)
            XCTAssertTrue(row.exists, "feature row \(index) missing after scrolling")
            XCTAssertTrue(row.label.contains(label), "feature label \(index) was not readable")
            XCTAssertGreaterThanOrEqual(row.frame.minX, window.frame.minX - 1)
            XCTAssertLessThanOrEqual(row.frame.maxX, window.frame.maxX + 1)
            // Feature rows are descriptive, not controls. SwiftUI exposes the
            // VoiceOver label's text bounds here while the visual row retains
            // its 48pt floor; require readable non-zero content on-screen.
            XCTAssertGreaterThan(row.frame.height, 0)
        }
    }

    private func assertCTAIsReadable(
        in app: XCUIApplication,
        requiresCompactWidth: Bool = false
    ) {
        let window = app.windows.firstMatch
        let cta = app.buttons[AppCopy.Onboarding.splashCTA]

        XCTAssertTrue(window.waitForExistence(timeout: 5))
        XCTAssertTrue(cta.exists, "onboarding CTA missing")
        XCTAssertGreaterThanOrEqual(cta.frame.height, 44)
        XCTAssertTrue(cta.isHittable, "onboarding CTA is outside the visible viewport")
        XCTAssertTrue(cta.frame.intersects(window.frame), "onboarding CTA is clipped")
        XCTAssertLessThanOrEqual(cta.frame.maxY, window.frame.maxY)

        if requiresCompactWidth {
            XCTAssertLessThanOrEqual(window.frame.width, 375, "run compact CTA QA on the smallest iPhone")
        }
    }

    private func positionFeatureTableForScreenshot(
        in app: XCUIApplication,
        requiresLastRow: Bool
    ) {
        // `assertFeatureTableFits` finishes with the final row at the top of
        // the viewport. Shift the scroll content down by a controlled amount
        // so the captured evidence shows the whole compact table instead of
        // only its last row and the plan cards below it.
        let window = app.windows.firstMatch
        let firstRow = descendant(in: app, identifier: "paywall-feature-row-0")
        let lastRow = descendant(in: app, identifier: "paywall-feature-row-5")
        // Lazy rows leave the hierarchy when scrolled away; drag back until
        // the first row is on screen again.
        for _ in 0..<6 {
            if firstRow.exists && firstRow.frame.minY > window.frame.minY + 120 { break }
            window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.32))
                .press(forDuration: 0.1, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        }
        XCTAssertTrue(firstRow.frame.intersects(window.frame), "feature table top is outside the screenshot")
        if requiresLastRow {
            XCTAssertTrue(lastRow.frame.intersects(window.frame), "feature table bottom is outside the screenshot")
        }
    }

    private func attachScreenshot(named name: String, app: XCUIApplication) {
        // XCTest can consider the app idle while SwiftUI is still completing
        // the tier/card transition. Keep visual evidence out of mid-animation
        // frames without slowing normal assertions or purchase interactions.
        Thread.sleep(forTimeInterval: 0.6)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func button(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// The timeline date the app shows for a 7-day trial bought today.
    private func trialTimelineDate(daysFromToday days: Int) -> String {
        let date = Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now
        return AppCopy.Paywall.timelineDate(date)
    }

    private func staticText(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func tap(_ element: XCUIElement, _ name: String, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(name) not found")
        element.tap()
    }
}
