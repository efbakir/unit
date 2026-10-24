import XCTest
@testable import Unit

@MainActor
final class UnitAnalyticsTests: XCTestCase {
    private final class RecordingTransport: AnalyticsTransport {
        var initializedAppIDs: [String] = []
        var terminateCount = 0
        var signals: [(String, [String: String])] = []

        func initialize(appID: String) { initializedAppIDs.append(appID) }
        func terminate() { terminateCount += 1 }
        func send(name: String, parameters: [String: String]) {
            signals.append((name, parameters))
        }
    }

    private let appID = "11111111-1111-1111-1111-111111111111"

    func testDefaultsOnAndOptOutStopsFutureEventsImmediately() {
        let fixture = makeFixture(appIDProvider: { [appID] in appID })
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let analytics = fixture.analytics
        let transport = fixture.transport
        XCTAssertTrue(analytics.isEnabled)
        analytics.configure()
        analytics.track(.workoutStarted)
        XCTAssertEqual(transport.signals.count, 1)

        analytics.setEnabled(false)
        analytics.track(.workoutCompleted(duration: .under15, setCount: .from1To5, noKeyboardRatio: .all))

        XCTAssertEqual(transport.signals.count, 1)
        XCTAssertEqual(transport.terminateCount, 1)
        XCTAssertFalse(analytics.isConfigured)
    }

    func testMissingConfigurationFailsClosed() {
        let fixture = makeFixture(appIDProvider: { nil })
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        let analytics = fixture.analytics
        let transport = fixture.transport
        analytics.configure()
        analytics.track(.paywallViewed(trialEligibility: "eligible"))

        XCTAssertTrue(transport.initializedAppIDs.isEmpty)
        XCTAssertTrue(transport.signals.isEmpty)
        XCTAssertFalse(analytics.isConfigured)
    }

    func testCustomEventAllowlistIsExact() {
        XCTAssertEqual(UnitAnalyticsEvent.allowedNames, [
            "onboarding_started", "onboarding_slide_viewed", "onboarding_step_viewed", "weight_unit_selected",
            "program_source_selected", "program_match_selected", "program_setup_completed", "paywall_viewed",
            "trial_reminder_preference_changed", "trial_reminder_authorization",
            "purchase_started", "trial_started", "purchase_completed", "purchase_outcome", "restore_outcome",
            "workout_started", "workout_completed",
            "progression_recommendation_shown", "progression_preview_shown", "progression_decision",
            "feedback_action", "data_exported"
        ])
    }

    func testOnboardingSlideAnalyticsFireOncePerGenuineView() {
        var tracker = OnboardingSlideViewTracker()

        XCTAssertTrue(tracker.shouldTrack(.nextTarget))
        XCTAssertFalse(tracker.shouldTrack(.nextTarget))
        XCTAssertTrue(tracker.shouldTrack(.doubleProgression))
        XCTAssertFalse(tracker.shouldTrack(.doubleProgression))
        XCTAssertTrue(tracker.shouldTrack(.oneTapLogging))
        XCTAssertFalse(tracker.shouldTrack(.oneTapLogging))
    }

    func testPayloadsContainOnlyControlledValuesAndNoWorkoutContent() {
        let events: [UnitAnalyticsEvent] = [
            .onboardingSlideViewed(id: .nextTarget),
            .weightUnitSelected(unit: "kg"),
            .programSourceSelected(source: "paste"),
            .programMatchSelected(
                profile: ProgramMatchProfile(goal: .strength, level: .intermediate, daysPerWeek: 4),
                rank: 1
            ),
            .paywallViewed(trialEligibility: "eligible"),
            .trialReminderPreferenceChanged(isEnabled: true),
            .trialReminderAuthorization(outcome: .scheduled),
            .purchaseStarted(tier: "annual", hasTrial: true, reminderRequested: true),
            .purchaseCompleted(
                tier: "annual",
                context: ProgramSetupContext(
                    source: .matchedLibrary,
                    matchProfile: ProgramMatchProfile(
                        goal: .strength,
                        level: .intermediate,
                        daysPerWeek: 4
                    )
                )
            ),
            .onboardingStepViewed(step: .review),
            .purchaseOutcome(tier: "monthly", outcome: .cancelled),
            .restoreOutcome(outcome: .nothingFound),
            .workoutCompleted(duration: .from30To60, setCount: .from11To20, noKeyboardRatio: .from90To99),
            .progressionPreviewShown(outcome: .addWeight),
            .progressionDecision(action: .edit, outcome: .addWeight),
            .feedbackAction(action: .book),
            .dataExported
        ]
        let forbiddenKeys = Set([
            "exercise", "program", "weight", "reps", "note", "bodyweight", "email",
            "timestamp", "session_id", "exercise_id", "receipt"
        ])

        for event in events {
            let payload = event.payload
            XCTAssertTrue(UnitAnalyticsEvent.allowedNames.contains(payload.name))
            XCTAssertTrue(forbiddenKeys.isDisjoint(with: payload.parameters.keys))
            XCTAssertFalse(payload.parameters.values.contains("Bench Press"))
            XCTAssertFalse(payload.parameters.values.contains("60"))
        }
    }

    func testWorkoutBucketsNeverExposeExactValues() {
        XCTAssertEqual(AnalyticsDurationBucket.value(for: 1_234), .from15To30)
        XCTAssertEqual(AnalyticsSetCountBucket.value(for: 12), .from11To20)
        XCTAssertEqual(
            AnalyticsNoKeyboardRatioBucket.value(prefilledSets: 9, completedSets: 10),
            .from90To99
        )
    }

    func testPurchasePayloadIncludesOnlyControlledProgramSegment() {
        let payload = UnitAnalyticsEvent.purchaseCompleted(
            tier: "annual",
            context: ProgramSetupContext(
                source: .matchedLibrary,
                matchProfile: ProgramMatchProfile(
                    goal: .strength,
                    level: .intermediate,
                    daysPerWeek: 4
                )
            )
        ).payload

        XCTAssertEqual(payload.name, "purchase_completed")
        XCTAssertEqual(payload.parameters, [
            "tier": "annual",
            "program_source": "matched_library",
            "goal": "strength",
            "experience": "intermediate",
            "days": "4"
        ])
    }

    func testPurchaseAndReminderPayloadsStayControlled() {
        XCTAssertEqual(
            UnitAnalyticsEvent.purchaseStarted(
                tier: "unexpected",
                hasTrial: true,
                reminderRequested: false
            ).payload.parameters,
            ["tier": "unknown", "has_trial": "true", "reminder_requested": "false"]
        )
        XCTAssertEqual(
            UnitAnalyticsEvent.trialReminderPreferenceChanged(isEnabled: true).payload.parameters,
            ["is_enabled": "true"]
        )
        XCTAssertEqual(
            UnitAnalyticsEvent.trialReminderAuthorization(outcome: .denied).payload.parameters,
            ["outcome": "denied"]
        )
    }

    func testPaywallAndPurchaseEventsCarryTheDefaultPlanArm() {
        let fixture = makeFixture(appIDProvider: { [appID] in appID })
        defer { fixture.defaults.removePersistentDomain(forName: fixture.suiteName) }
        fixture.defaults.set("annual", forKey: PaywallDefaultPlanExperiment.key)
        fixture.analytics.configure()

        fixture.analytics.track(.paywallViewed(trialEligibility: "eligible"))
        fixture.analytics.track(.workoutStarted)

        XCTAssertEqual(fixture.transport.signals.first?.1["default_plan"], "annual")
        XCTAssertNil(fixture.transport.signals.last?.1["default_plan"])
    }

    func testFunnelOutcomePayloadsStayControlled() {
        XCTAssertEqual(
            UnitAnalyticsEvent.purchaseOutcome(tier: "unexpected", outcome: .pending).payload.parameters,
            ["tier": "unknown", "outcome": "pending"]
        )
        XCTAssertEqual(
            UnitAnalyticsEvent.restoreOutcome(outcome: .nothingFound).payload.parameters,
            ["outcome": "nothing_found"]
        )
        XCTAssertEqual(
            UnitAnalyticsEvent.onboardingStepViewed(step: .paste).payload.parameters,
            ["step": "paste"]
        )
    }

    private func makeFixture(
        appIDProvider: @escaping () -> String?
    ) -> (
        analytics: UnitAnalytics,
        transport: RecordingTransport,
        defaults: UserDefaults,
        suiteName: String
    ) {
        let suiteName = "UnitAnalyticsTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let transport = RecordingTransport()
        let analytics = UnitAnalytics(
            defaults: defaults,
            transport: transport,
            appIDProvider: appIDProvider
        )
        return (analytics, transport, defaults, suiteName)
    }
}
