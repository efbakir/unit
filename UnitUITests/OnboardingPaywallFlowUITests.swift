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

    Pull
    Deadlift 2x5 140
    Barbell Row 4x6 70
    """

    func testReleaseGate_onboardingThroughPurchaseToLoggedWorkout() throws {
        let session = try SKTestSession(configurationFileNamed: "Unit")
        session.disableDialogs = true
        session.clearTransactions()

        // ── Launch 1: splash → unit → import → parser failure + recovery ──
        var app = XCUIApplication()
        app.launch()

        tap(app.buttons[AppCopy.Onboarding.splashCTA], "splash CTA", timeout: 20)
        tap(button(in: app, containing: "Kilograms"), "unit picker — Kilograms")
        tap(button(in: app, containing: AppCopy.Onboarding.methodPasteOption), "import method — paste")

        let editor = app.textViews.firstMatch
        XCTAssertTrue(editor.waitForExistence(timeout: 8), "paste editor missing")
        editor.tap()
        editor.typeText("total garbage that is not a program")
        tap(app.buttons["Read program"], "Read program (garbage)")
        // Parse failure surfaces the explanatory alert; the format sheet may
        // or may not auto-present depending on the alert/sheet presentation
        // race (SwiftUI drops a sheet whose flag is set under an active
        // alert). Assert the error surfaces, then verify recovery is
        // reachable either way — via the auto-sheet or the always-present
        // "Show format examples" button.
        let failureAlert = app.alerts.firstMatch
        let sheetTitle = app.staticTexts["Format examples"]
        XCTAssertTrue(
            failureAlert.waitForExistence(timeout: 8) || sheetTitle.exists,
            "parse failure surfaced neither alert nor recovery sheet"
        )
        if failureAlert.exists, app.alerts.buttons["Got it"].exists {
            app.alerts.buttons["Got it"].tap()
        }
        if !sheetTitle.waitForExistence(timeout: 3) {
            tap(app.buttons["Show format examples"], "manual format-examples recovery")
            XCTAssertTrue(sheetTitle.waitForExistence(timeout: 8), "format sheet did not open")
        }
        tap(app.buttons["Done"], "dismiss format sheet")

        // ── Launch 2: snapshot restore lands on the paste step, clean editor ──
        app.terminate()
        app = XCUIApplication()
        app.launch()

        let editor2 = app.textViews.firstMatch
        XCTAssertTrue(editor2.waitForExistence(timeout: 15), "paste editor missing after relaunch")
        editor2.tap()
        editor2.typeText(Self.demoProgram)
        tap(app.buttons["Read program"], "Read program (valid)")

        tap(app.buttons["Continue"], "schedule — Continue", timeout: 10)

        XCTAssertTrue(app.staticTexts[AppCopy.Onboarding.previewTitle].waitForExistence(timeout: 8), "preview title missing")
        XCTAssertTrue(
            staticText(in: app, containing: "Bench Press").waitForExistence(timeout: 5),
            "parsed exercise missing from preview"
        )
        tap(app.buttons[AppCopy.Onboarding.previewCTA], "preview — save program")

        // ── Paywall: loaded products, prices, legal, purchase ──
        XCTAssertTrue(
            app.staticTexts[AppCopy.Paywall.programReady].waitForExistence(timeout: 20),
            "paywall header missing after commit"
        )
        XCTAssertTrue(
            staticText(in: app, containing: "$2.99").waitForExistence(timeout: 20),
            "weekly $2.99 did not load from StoreKitTest"
        )
        XCTAssertTrue(staticText(in: app, containing: "$4.99").exists, "monthly $4.99 missing")
        XCTAssertTrue(staticText(in: app, containing: "$29.99").exists, "yearly $29.99 missing")
        XCTAssertFalse(staticText(in: app, containing: "trial").exists, "trial copy must not exist")

        app.swipeUp()
        XCTAssertTrue(
            app.buttons["Restore Purchases"].waitForExistence(timeout: 8),
            "Restore Purchases unreachable"
        )
        XCTAssertTrue(
            app.links["Terms of Service"].exists || app.buttons["Terms of Service"].exists,
            "Terms of Service unreachable"
        )
        XCTAssertTrue(
            app.links["Privacy Policy"].exists || app.buttons["Privacy Policy"].exists,
            "Privacy Policy unreachable"
        )

        tap(button(in: app, containing: AppCopy.Paywall.subscribeWeekly), "purchase CTA")

        // ── Unlock ──
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.waitForExistence(timeout: 25), "post-unlock tab bar missing — purchase did not unlock")

        tap(app.tabBars.buttons["Programs"], "Programs tab")
        XCTAssertTrue(
            staticText(in: app, containing: "Push").waitForExistence(timeout: 8),
            "committed program missing from Programs"
        )
        tap(app.tabBars.buttons["Today"], "back to Today")

        // ── Gym Test: start → 3 one-tap sets → finish → History ──
        tap(button(in: app, containing: AppCopy.Workout.startWorkout), "start workout", timeout: 10)
        let complete = app.buttons[AppCopy.Workout.completeSet]
        XCTAssertTrue(complete.waitForExistence(timeout: 10), "Complete set CTA missing")

        for setIndex in 1...3 {
            XCTAssertTrue(complete.waitForExistence(timeout: 8), "Complete set missing before set \(setIndex)")
            let start = Date()
            complete.tap()
            XCTAssertLessThan(
                Date().timeIntervalSince(start), 3.0,
                "set \(setIndex): the one-tap log took over 3 seconds"
            )
        }

        tap(app.buttons[AppCopy.Workout.finishWorkout], "finish workout (toolbar)", timeout: 10)
        let confirm = app.alerts.firstMatch.buttons[AppCopy.Workout.finishWorkout]
        XCTAssertTrue(confirm.waitForExistence(timeout: 8), "finish confirmation missing")
        confirm.tap()

        XCTAssertTrue(
            button(in: app, containing: AppCopy.Nav.history).waitForExistence(timeout: 15),
            "Today did not return after finish"
        )
        tap(button(in: app, containing: AppCopy.Nav.history), "open History")
        XCTAssertTrue(
            staticText(in: app, containing: "Push").waitForExistence(timeout: 8),
            "finished session missing from History"
        )
    }

    // MARK: - Helpers

    private func button(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.buttons.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func staticText(in app: XCUIApplication, containing text: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func tap(_ element: XCUIElement, _ name: String, timeout: TimeInterval = 8) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(name) not found")
        element.tap()
    }
}
