import Foundation
import TelemetryDeck

protocol AnalyticsTransport: AnyObject {
    func initialize(appID: String)
    func terminate()
    func send(name: String, parameters: [String: String])
}

final class TelemetryDeckAnalyticsTransport: AnalyticsTransport {
    func initialize(appID: String) {
        let configuration = TelemetryDeck.Config(appID: appID)
        configuration.sessionStatsEnabled = false
        // One anonymous session-start signal per app session. Without it,
        // daily/weekly active users and retention can't be measured for
        // people who open Unit but don't finish a workout that day.
        configuration.sendNewSessionBeganSignal = true
        configuration.logHandler = nil
        TelemetryDeck.initialize(config: configuration)
    }

    func terminate() {
        TelemetryDeck.terminate()
    }

    func send(name: String, parameters: [String: String]) {
        TelemetryDeck.signal(name, parameters: parameters)
    }
}

enum AnalyticsDurationBucket: String, CaseIterable, Hashable {
    case under15 = "under_15m"
    case from15To30 = "15_30m"
    case from30To60 = "30_60m"
    case over60 = "over_60m"

    static func value(for seconds: TimeInterval) -> Self {
        switch max(0, seconds) {
        case ..<900: .under15
        case ..<1_800: .from15To30
        case ..<3_600: .from30To60
        default: .over60
        }
    }
}

enum AnalyticsSetCountBucket: String, CaseIterable, Hashable {
    case from1To5 = "1_5"
    case from6To10 = "6_10"
    case from11To20 = "11_20"
    case over20 = "over_20"

    static func value(for count: Int) -> Self {
        switch max(0, count) {
        case ...5: .from1To5
        case ...10: .from6To10
        case ...20: .from11To20
        default: .over20
        }
    }
}

/// Workouts in one history import, never the exact number.
enum AnalyticsImportSizeBucket: String, CaseIterable, Hashable {
    case from1To10 = "1_10"
    case from11To50 = "11_50"
    case from51To200 = "51_200"
    case over200 = "over_200"

    init(workoutCount: Int) {
        switch workoutCount {
        case ...10: self = .from1To10
        case ...50: self = .from11To50
        case ...200: self = .from51To200
        default: self = .over200
        }
    }
}

enum AnalyticsNoKeyboardRatioBucket: String, CaseIterable, Hashable {
    case none
    case under50 = "under_50"
    case from50To89 = "50_89"
    case from90To99 = "90_99"
    case all

    static func value(prefilledSets: Int, completedSets: Int) -> Self {
        guard completedSets > 0 else { return .none }
        let ratio = Double(max(0, min(prefilledSets, completedSets))) / Double(completedSets)
        switch ratio {
        case 0: return .none
        case ..<0.5: return .under50
        case ..<0.9: return .from50To89
        case ..<1: return .from90To99
        default: return .all
        }
    }
}

enum AnalyticsProgressionOutcome: String, CaseIterable, Hashable {
    case addWeight = "add_weight"
    case addRep = "add_rep"
    case repeatTarget = "repeat"
    case unsupported
}

enum AnalyticsProgressionDecision: String, CaseIterable, Hashable {
    case accept
    case repeatTarget = "repeat"
    case edit
    case dismiss
}

enum AnalyticsFeedbackAction: String, CaseIterable, Hashable {
    case book
    case email
    case dismiss
    case portal
}

enum AnalyticsOnboardingSlide: String, CaseIterable, Hashable {
    case nextTarget = "next_target"
    case doubleProgression = "double_progression"
    case oneTapLogging = "one_tap_logging"
}

enum AnalyticsOnboardingStep: String, CaseIterable, Hashable {
    case unit
    case method
    case paste
    case library
    case schedule
    case review
}

enum AnalyticsPurchaseOutcome: String, CaseIterable, Hashable {
    case cancelled
    case pending
    case failed
}

enum AnalyticsRestoreOutcome: String, CaseIterable, Hashable {
    case restored
    case nothingFound = "nothing_found"
    case failed
}

enum AnalyticsTrialReminderOutcome: String, CaseIterable, Hashable {
    case scheduled
    case denied
    case notAuthorized = "not_authorized"
    case invalidExpiration = "invalid_expiration"
    case failed
    case cancelled
}

enum UnitAnalyticsEvent {
    case onboardingStarted
    case onboardingSlideViewed(id: AnalyticsOnboardingSlide)
    case onboardingStepViewed(step: AnalyticsOnboardingStep)
    case weightUnitSelected(unit: String)
    case programSourceSelected(source: String)
    case programMatchSelected(profile: ProgramMatchProfile, rank: Int)
    case programSetupCompleted(source: String)
    case paywallViewed(trialEligibility: String)
    case trialReminderPreferenceChanged(isEnabled: Bool)
    case trialReminderAuthorization(outcome: AnalyticsTrialReminderOutcome)
    case purchaseStarted(tier: String, hasTrial: Bool, reminderRequested: Bool)
    case trialStarted(tier: String, context: ProgramSetupContext?)
    case purchaseCompleted(tier: String, context: ProgramSetupContext?)
    case purchaseOutcome(tier: String, outcome: AnalyticsPurchaseOutcome)
    case restoreOutcome(outcome: AnalyticsRestoreOutcome)
    case workoutStarted
    case workoutCompleted(duration: AnalyticsDurationBucket, setCount: AnalyticsSetCountBucket, noKeyboardRatio: AnalyticsNoKeyboardRatioBucket)
    case progressionRecommendationShown(outcome: AnalyticsProgressionOutcome)
    case progressionPreviewShown(outcome: AnalyticsProgressionOutcome)
    case progressionDecision(action: AnalyticsProgressionDecision, outcome: AnalyticsProgressionOutcome)
    case feedbackAction(action: AnalyticsFeedbackAction)
    case dataExported
    case historyImported(source: WorkoutHistorySource, size: AnalyticsImportSizeBucket)

    static let allowedNames: Set<String> = [
        "onboarding_started",
        "onboarding_slide_viewed",
        "onboarding_step_viewed",
        "weight_unit_selected",
        "program_source_selected",
        "program_match_selected",
        "program_setup_completed",
        "paywall_viewed",
        "trial_reminder_preference_changed",
        "trial_reminder_authorization",
        "purchase_started",
        "trial_started",
        "purchase_completed",
        "purchase_outcome",
        "restore_outcome",
        "workout_started",
        "workout_completed",
        "progression_recommendation_shown",
        "progression_preview_shown",
        "progression_decision",
        "feedback_action",
        "data_exported",
        "history_imported"
    ]

    var payload: (name: String, parameters: [String: String]) {
        switch self {
        case .onboardingStarted:
            ("onboarding_started", [:])
        case .onboardingSlideViewed(let id):
            ("onboarding_slide_viewed", ["slide": id.rawValue])
        case .onboardingStepViewed(let step):
            ("onboarding_step_viewed", ["step": step.rawValue])
        case .weightUnitSelected(let unit):
            ("weight_unit_selected", ["unit": unit == "lb" ? "lb" : "kg"])
        case .programSourceSelected(let source):
            ("program_source_selected", ["source": source == "paste" ? "paste" : "library"])
        case .programMatchSelected(let profile, let rank):
            (
                "program_match_selected",
                [
                    "goal": profile.goal.rawValue,
                    "experience": profile.level.rawValue,
                    "days": Self.validDays(profile.daysPerWeek),
                    "rank": Self.validRank(rank)
                ]
            )
        case .programSetupCompleted(let source):
            ("program_setup_completed", ["source": source == "paste" ? "paste" : "library"])
        case .paywallViewed(let trialEligibility):
            ("paywall_viewed", ["trial_eligibility": Self.validTrialEligibility(trialEligibility)])
        case .trialReminderPreferenceChanged(let isEnabled):
            (
                "trial_reminder_preference_changed",
                ["is_enabled": isEnabled ? "true" : "false"]
            )
        case .trialReminderAuthorization(let outcome):
            ("trial_reminder_authorization", ["outcome": outcome.rawValue])
        case .purchaseStarted(let tier, let hasTrial, let reminderRequested):
            (
                "purchase_started",
                [
                    "tier": Self.validTier(tier),
                    "has_trial": hasTrial ? "true" : "false",
                    "reminder_requested": reminderRequested ? "true" : "false"
                ]
            )
        case .trialStarted(let tier, let context):
            ("trial_started", Self.purchaseParameters(tier: tier, context: context))
        case .purchaseCompleted(let tier, let context):
            ("purchase_completed", Self.purchaseParameters(tier: tier, context: context))
        case .purchaseOutcome(let tier, let outcome):
            ("purchase_outcome", ["tier": Self.validTier(tier), "outcome": outcome.rawValue])
        case .restoreOutcome(let outcome):
            ("restore_outcome", ["outcome": outcome.rawValue])
        case .workoutStarted:
            ("workout_started", [:])
        case .workoutCompleted(let duration, let setCount, let noKeyboardRatio):
            (
                "workout_completed",
                [
                    "duration": duration.rawValue,
                    "set_count": setCount.rawValue,
                    "no_keyboard_ratio": noKeyboardRatio.rawValue
                ]
            )
        case .progressionRecommendationShown(let outcome):
            ("progression_recommendation_shown", ["outcome": outcome.rawValue])
        case .progressionPreviewShown(let outcome):
            ("progression_preview_shown", ["outcome": outcome.rawValue])
        case .progressionDecision(let action, let outcome):
            ("progression_decision", ["action": action.rawValue, "outcome": outcome.rawValue])
        case .feedbackAction(let action):
            ("feedback_action", ["action": action.rawValue])
        case .dataExported:
            ("data_exported", [:])
        case .historyImported(let source, let size):
            ("history_imported", ["source": source.rawValue, "workouts": size.rawValue])
        }
    }

    private static func validTier(_ tier: String) -> String {
        ["weekly", "monthly", "annual", "lifetime"].contains(tier) ? tier : "unknown"
    }

    private static func purchaseParameters(
        tier: String,
        context: ProgramSetupContext?
    ) -> [String: String] {
        var parameters = ["tier": validTier(tier)]
        guard let context else {
            parameters["program_source"] = "unknown"
            return parameters
        }

        parameters["program_source"] = context.source.rawValue
        if let profile = context.matchProfile {
            parameters["goal"] = profile.goal.rawValue
            parameters["experience"] = profile.level.rawValue
            parameters["days"] = validDays(profile.daysPerWeek)
        }
        return parameters
    }

    private static func validDays(_ days: Int) -> String {
        (1...7).contains(days) ? String(days) : "unknown"
    }

    private static func validRank(_ rank: Int) -> String {
        (1...3).contains(rank) ? String(rank) : "unknown"
    }

    private static func validTrialEligibility(_ value: String) -> String {
        ["eligible", "ineligible"].contains(value) ? value : "unknown"
    }
}

final class UnitAnalytics {
    @MainActor
    static let shared = UnitAnalytics()
    static let enabledKey = "analytics.enabled"

    private let defaults: UserDefaults
    private let transport: AnalyticsTransport
    private let appIDProvider: () -> String?
    @MainActor private(set) var isConfigured = false

    /// Opt-in (App Review 5.1.1(ii)): a missing key means the person never
    /// turned analytics on, so nothing is sent.
    @MainActor
    var isEnabled: Bool {
        defaults.bool(forKey: Self.enabledKey)
    }

    @MainActor
    init(
        defaults: UserDefaults = .standard,
        transport: AnalyticsTransport = TelemetryDeckAnalyticsTransport(),
        appIDProvider: @escaping () -> String? = {
            Bundle.main.object(forInfoDictionaryKey: "TelemetryDeckAppID") as? String
        }
    ) {
        self.defaults = defaults
        self.transport = transport
        self.appIDProvider = appIDProvider
    }

    nonisolated deinit {}

    @MainActor
    func configure() {
        guard isEnabled, let appID = validAppID else {
            transport.terminate()
            isConfigured = false
            return
        }
        transport.initialize(appID: appID)
        isConfigured = true
    }

    @MainActor
    func setEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Self.enabledKey)
        if enabled {
            configure()
        } else {
            transport.terminate()
            isConfigured = false
        }
    }

    /// Events that carry the install's paywall default-plan arm, so trial and
    /// purchase rates can be compared between the Monthly and Yearly defaults.
    static let experimentEventNames: Set<String> = [
        "paywall_viewed", "purchase_started", "purchase_outcome", "trial_started", "purchase_completed"
    ]

    @MainActor
    func track(_ event: UnitAnalyticsEvent) {
        guard isEnabled, isConfigured else { return }
        let payload = event.payload
        guard UnitAnalyticsEvent.allowedNames.contains(payload.name) else { return }
        var parameters = payload.parameters
        if Self.experimentEventNames.contains(payload.name),
           let arm = defaults.string(forKey: PaywallDefaultPlanExperiment.key),
           ["monthly", "annual"].contains(arm) {
            parameters["default_plan"] = arm
        }
        transport.send(name: payload.name, parameters: parameters)
    }

    @MainActor
    private var validAppID: String? {
        guard let rawValue = appIDProvider()?.trimmingCharacters(in: .whitespacesAndNewlines),
              !rawValue.isEmpty,
              !rawValue.contains("$("),
              UUID(uuidString: rawValue) != nil else {
            return nil
        }
        return rawValue
    }
}
