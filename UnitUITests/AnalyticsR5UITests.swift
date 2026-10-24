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
    private func mainCards(_ app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "analytics-main-"))
    }
    func testRootProgramNavigationRetainsRoutineAccess() {
        let app = app()
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Programs"].waitForExistence(timeout: 20))
        capture(app, "joi-today")
        app.tabBars.buttons["Programs"].tap()
        XCTAssertTrue(app.buttons["Edit program"].waitForExistence(timeout: 8))
        capture(app, "joi-programs")
        app.buttons["Edit program"].tap()
        XCTAssertTrue(app.textFields["Program name"].waitForExistence(timeout: 8))
        capture(app, "joi-program-edit")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["Edit program"].waitForExistence(timeout: 8))
        let routine = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Push A")).firstMatch
        reveal(routine, in: app)
        routine.tap()
        XCTAssertTrue(app.navigationBars["Push A"].waitForExistence(timeout: 8))
        capture(app, "joi-routine")
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
        app.buttons["Close"].tap()
        let bench = app.buttons["analytics-main-Bench Press"]
        for name in ["Squat", "Deadlift"] {
            let card = app.buttons["analytics-main-\(name)"]
            reveal(card, in: app); card.tap()
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
        reveal(bench, in: app); bench.tap()
        XCTAssertTrue(app.buttons["Weight"].waitForExistence(timeout: 8))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Latest ·")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "4-week comparison ·")).firstMatch.exists)
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Previous 4 weeks:")).firstMatch.exists)
        capture(app, "r5-detail")
        XCTAssertTrue(app.staticTexts["82.5 kg × 5"].exists)
        app.buttons["Reps"].tap()
        XCTAssertTrue(app.staticTexts["Reps at weekly top weight · 12 weeks"].exists)
        capture(app, "r5-detail-reps")
        app.buttons["Volume"].tap()
        XCTAssertTrue(app.staticTexts["Session volume at weekly best · 12 weeks"].exists)
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
    func testSingleWeekRetainsChartAndMetricsWithoutRepeatedComparison() {
        let app = app(["-analytics-baseline"]); open(app)
        let bench = app.buttons["analytics-main-Bench Press"]
        reveal(bench, in: app)
        XCTAssertFalse(bench.label.contains("No previous comparison"))
        XCTAssertTrue(bench.label.contains(" Best "))
        capture(app, "analytics-simple-single-week-main")
        bench.tap()
        XCTAssertTrue(app.staticTexts["Bench Press"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Latest ·")).firstMatch.exists)
        XCTAssertTrue(app.descendants(matching: .any)["analytics-trend-chart"].exists)
        XCTAssertFalse(app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "4-week comparison ·")).firstMatch.exists)
        XCTAssertTrue(app.buttons["Weight"].exists)
        XCTAssertTrue(app.staticTexts["Next"].exists)
        capture(app, "analytics-simple-single-week-detail")
    }

    func testMissingMainLiftPoundsAndLargeText() {
        for (flags, name) in [(["-analytics-missing"], "r5-never-logged"), (["-analytics-lb"], "r5-pounds"), (["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityL"], "r5-ax3")] {
            let app = app(flags); open(app)
            XCTAssertTrue(app.buttons["analytics-summary"].waitForExistence(timeout: 10))
            capture(app, name)
            if flags.contains("-analytics-missing") {
                XCTAssertFalse(app.buttons["analytics-main-Deadlift"].exists)
                XCTAssertEqual(mainCards(app).count, 3)
                let fill = app.buttons["analytics-main-Barbell Row"]
                reveal(fill, in: app); fill.tap()
                XCTAssertTrue(app.staticTexts["Barbell Row"].waitForExistence(timeout: 5))
                app.navigationBars.buttons.firstMatch.tap()
                app.swipeUp(); capture(app, "r5-never-logged-scrolled")
            }
            if flags.contains("-analytics-lb") {
                XCTAssertTrue(app.buttons["analytics-main-Squat"].label.contains("pounds"))
            }
            app.terminate()
        }
    }
    func testCatalogNamesOpenTheirOwnDetails() {
        let app = app(["-analytics-catalog-names"]); open(app)
        for name in ["Back Squat (BB)", "Bench Press", "Deadlift (Conv)"] {
            let card = app.buttons["analytics-main-\(name)"]
            reveal(card, in: app); card.tap()
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
            app.navigationBars.buttons.firstMatch.tap()
        }
        capture(app, "main-lifts-catalog-names")
    }
    func testMainLiftEditingPersistsAndCanReturnToAutomatic() {
        let app = app(); open(app)
        app.buttons["analytics-edit-main"].tap()
        XCTAssertTrue(app.navigationBars["Main lifts"].waitForExistence(timeout: 5))
        let squat = app.cells.containing(.staticText, identifier: "Squat").firstMatch
        squat.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Delete")).firstMatch.tap()
        if app.buttons["Delete"].exists { app.buttons["Delete"].tap() }
        let addPullup = app.buttons["analytics-add-Pull-Up"]
        reveal(addPullup, in: app); addPullup.tap()
        let pullup = app.cells.containing(.staticText, identifier: "Pull-Up").firstMatch
        for _ in 0..<4 { if pullup.isHittable { break }; app.swipeDown() }
        let bench = app.cells.containing(.staticText, identifier: "Bench Press").firstMatch
        pullup.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Reorder")).firstMatch.press(forDuration: 0.5, thenDragTo: bench)
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["analytics-main-Pull-Up"].waitForExistence(timeout: 5))
        XCTAssertEqual(mainCards(app).allElementsBoundByIndex.map(\.identifier), ["analytics-main-Pull-Up", "analytics-main-Bench Press", "analytics-main-Deadlift"])
        app.terminate()
        app.launchArguments.removeAll { $0 == "-ui-testing-reset" }
        app.launch()
        app.tabBars.buttons["Analytics"].tap()
        XCTAssertTrue(app.buttons["analytics-main-Pull-Up"].waitForExistence(timeout: 8))
        XCTAssertEqual(mainCards(app).allElementsBoundByIndex.map(\.identifier), ["analytics-main-Pull-Up", "analytics-main-Bench Press", "analytics-main-Deadlift"])
        capture(app, "main-lifts-custom")
        app.buttons["analytics-edit-main"].tap()
        let reset = app.buttons["Use automatic"]
        XCTAssertTrue(reset.waitForExistence(timeout: 5)); reset.tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.buttons["analytics-main-Squat"].waitForExistence(timeout: 5))
    }
    func testSetsPerMuscleListsTheLastFourWeeks() {
        let app = app(); open(app)
        XCTAssertTrue(app.buttons["analytics-summary"].waitForExistence(timeout: 10))
        // Fixture: 11 workouts in 28 days, 3 sets per exercise; Back has 3 exercises.
        let back = app.descendants(matching: .any)["analytics-muscle-back"]
        reveal(back, in: app)
        XCTAssertTrue(app.staticTexts["Sets per muscle · last 4 weeks"].exists)
        XCTAssertTrue(back.label.contains("99 sets"), back.label)
        for muscle in ["biceps", "chest", "core", "quads", "shoulders"] {
            XCTAssertTrue(app.descendants(matching: .any)["analytics-muscle-\(muscle)"].label.contains("33 sets"), muscle)
        }
        XCTAssertFalse(app.descendants(matching: .any)["analytics-muscle-other"].exists)
        capture(app, "analytics-sets-per-muscle")
    }
    func testAppleHealthSwitchKeepsOnlyAllowedAccess() {
        for (flag, allowed) in [("-ui-testing-health-allow", true), ("-ui-testing-health-deny", false)] {
            let app = app([flag])
            app.launch()
            XCTAssertTrue(app.tabBars.buttons["Programs"].waitForExistence(timeout: 20))
            app.tabBars.buttons["Programs"].tap()
            XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 8))
            app.buttons["Settings"].tap()
            let health = app.switches["settings-apple-health"]
            XCTAssertTrue(health.waitForExistence(timeout: 8))
            XCTAssertEqual(health.value as? String, "0", "Off by default")
            health.tap()
            if allowed {
                XCTAssertTrue(NSPredicate(format: "value == '1'").evaluate(with: health))
            } else {
                XCTAssertTrue(app.staticTexts[AppCopy.Preferences.appleHealthDenied].waitForExistence(timeout: 5))
                XCTAssertEqual(health.value as? String, "0")
            }
            capture(app, allowed ? "settings-apple-health-on" : "settings-apple-health-denied")
            app.terminate()
        }
    }
    func testMainLiftEditorCancelDiscardsChanges() {
        let app = app(); open(app)
        app.buttons["analytics-edit-main"].tap()
        let squat = app.cells.containing(.staticText, identifier: "Squat").firstMatch
        squat.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Delete")).firstMatch.tap()
        if app.buttons["Delete"].exists { app.buttons["Delete"].tap() }
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.buttons["analytics-main-Squat"].waitForExistence(timeout: 5))
        XCTAssertEqual(mainCards(app).count, 3)
    }
}
