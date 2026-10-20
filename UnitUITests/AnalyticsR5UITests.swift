import XCTest

@MainActor
final class AnalyticsR5UITests: XCTestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    private func app(_ flags: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-ui-testing-reset", "-ui-testing-lifetime-owner", "-ui-testing-analytics-r5", "-AppleLocale", "en_US", "-AppleLanguages", "(en)"] + flags
        return app
    }
    private func open(_ app: XCUIApplication) {
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Analytics"].waitForExistence(timeout: 20))
        app.tabBars.buttons["Analytics"].tap()
    }
    private func capture(_ app: XCUIApplication, _ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot()); image.name = name; image.lifetime = .keepAlways; add(image)
    }
    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<14 {
            let visibleBottom = app.tabBars.firstMatch.exists ? app.tabBars.firstMatch.frame.minY : app.frame.maxY
            if element.exists && element.isHittable && element.frame.midY < visibleBottom - 24 { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }
    func testNormalCardsSummaryAndDetails() {
        let app = app(); open(app)
        let summary = app.buttons["analytics-summary"]
        XCTAssertTrue(summary.waitForExistence(timeout: 10))
        XCTAssertTrue(summary.label.contains("Getting stronger"))
        capture(app, "r5-main")
        summary.tap()
        XCTAssertTrue(app.navigationBars["How this works"].waitForExistence(timeout: 5))
        capture(app, "r5-summary-info")
        app.buttons["Done"].tap()
        let bench = app.buttons["analytics-main-Bench Press"]
        reveal(bench, in: app); bench.tap()
        XCTAssertTrue(app.buttons["Weight"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Latest session ·")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "4-week comparison ·")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Previous 4 weeks:")).firstMatch.exists)
        capture(app, "r5-detail")
        XCTAssertTrue(app.staticTexts["82.5 kg × 5"].exists)
        app.buttons["Reps"].tap()
        XCTAssertTrue(app.staticTexts["Reps in each week's best set · 12 weeks"].exists)
        capture(app, "r5-detail-reps")
        app.buttons["Volume"].tap()
        XCTAssertTrue(app.staticTexts["Exercise volume in each week's best-set session · 12 weeks"].exists)
        capture(app, "r5-detail-volume")
        app.buttons["Weight"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        let pullup = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Pull-Up")).firstMatch
        reveal(pullup, in: app)
        capture(app, "r5-main-scrolled")
        pullup.tap()
        XCTAssertTrue(app.staticTexts["Recent"].waitForExistence(timeout: 8))
        XCTAssertFalse(app.buttons["Weight"].exists)
        XCTAssertFalse(app.staticTexts["Est. 1RM"].exists)
        capture(app, "r5-detail-other")
    }
    func testEmptyAndBaselineAndFewerStates() {
        for (flag, expected, name) in [("-analytics-empty", "No workouts yet", "r5-empty"), ("-analytics-baseline", "Building a baseline", "r5-baseline"), ("-analytics-fewer", "Fewer sessions lately", "r5-fewer")] {
            let app = app([flag]); open(app)
            if flag == "-analytics-empty" {
                XCTAssertTrue(app.staticTexts[expected].waitForExistence(timeout: 10))
                XCTAssertFalse(app.buttons["analytics-summary"].exists)
            } else {
                XCTAssertTrue(app.buttons["analytics-summary"].waitForExistence(timeout: 10))
                XCTAssertTrue(app.buttons["analytics-summary"].label.contains(expected))
            }
            capture(app, name); app.terminate()
        }
    }
    func testMissingMainLiftPoundsAndLargeText() {
        for (flags, name) in [(["-analytics-missing"], "r5-never-logged"), (["-analytics-lb"], "r5-pounds"), (["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"], "r5-ax3")] {
            let app = app(flags); open(app)
            XCTAssertTrue(app.buttons["analytics-summary"].waitForExistence(timeout: 10))
            capture(app, name)
            if flags.contains("-analytics-missing") {
                XCTAssertFalse(app.buttons["analytics-main-Deadlift"].exists)
                app.swipeUp(); capture(app, "r5-never-logged-scrolled")
            }
            if flags.contains("-analytics-lb") {
                XCTAssertTrue(app.buttons["analytics-main-Squat"].label.contains("pounds"))
            }
            app.terminate()
        }
    }
}
