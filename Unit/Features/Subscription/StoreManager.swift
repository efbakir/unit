//
//  StoreManager.swift
//  Unit
//
//  Handles StoreKit 2 product loading, purchasing, and restore
//  for Unit's subscription tiers plus optional Lifetime purchase.
//  Pricing authority: docs/pricing.md.
//

import StoreKit
import OSLog
import UserNotifications

enum TrialReminderSchedulingResult: Equatable, Sendable {
    case scheduled
    case denied
    case notAuthorized
    case invalidExpiration
    case failed
}

@MainActor
protocol TrialReminderScheduling: AnyObject {
    func scheduleReminder(
        expirationDate: Date,
        requestAuthorizationIfNeeded: Bool
    ) async -> TrialReminderSchedulingResult
    func cancelReminder() async
}

enum TrialReminderAuthorizationStatus: Equatable, Sendable {
    case notDetermined
    case denied
    case authorized
}

@MainActor
struct TrialReminderNotificationClient {
    var authorizationStatus: () async -> TrialReminderAuthorizationStatus
    var requestAuthorization: () async throws -> Bool
    var replacePendingRequest: (
        _ identifier: String,
        _ title: String,
        _ body: String,
        _ timeInterval: TimeInterval
    ) async throws -> Void
    var cancelPendingRequest: (_ identifier: String) -> Void

    static let live = TrialReminderNotificationClient(
        authorizationStatus: {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .notDetermined: return TrialReminderAuthorizationStatus.notDetermined
            case .denied: return TrialReminderAuthorizationStatus.denied
            case .authorized, .provisional, .ephemeral:
                return TrialReminderAuthorizationStatus.authorized
            @unknown default: return TrialReminderAuthorizationStatus.denied
            }
        },
        requestAuthorization: {
            try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound]
            )
        },
        replacePendingRequest: { identifier, title, body, timeInterval in
            let center = UNUserNotificationCenter.current()
            center.removePendingNotificationRequests(withIdentifiers: [identifier])

            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(
                timeInterval: timeInterval,
                repeats: false
            )
            try await center.add(
                UNNotificationRequest(
                    identifier: identifier,
                    content: content,
                    trigger: trigger
                )
            )
        },
        cancelPendingRequest: { identifier in
            UNUserNotificationCenter.current()
                .removePendingNotificationRequests(withIdentifiers: [identifier])
        }
    )
}

@MainActor
final class TrialReminderScheduler: TrialReminderScheduling {
    nonisolated static let identifier = "unit.trial-reminder"
    nonisolated static let notificationTitle = "Your Unit trial ends in 2 days"
    nonisolated static let notificationBody =
        "Manage your subscription anytime in App Store settings."
    nonisolated static let leadTime: TimeInterval = 48 * 60 * 60

    private let client: TrialReminderNotificationClient
    private let now: () -> Date

    init(
        client: TrialReminderNotificationClient = .live,
        now: @escaping () -> Date = Date.init
    ) {
        self.client = client
        self.now = now
    }

    func scheduleReminder(
        expirationDate: Date,
        requestAuthorizationIfNeeded: Bool
    ) async -> TrialReminderSchedulingResult {
        let fireDate = expirationDate.addingTimeInterval(-Self.leadTime)
        let interval = fireDate.timeIntervalSince(now())
        guard interval > 0, interval.isFinite else {
            await cancelReminder()
            return .invalidExpiration
        }

        let status = await client.authorizationStatus()
        switch status {
        case .denied:
            await cancelReminder()
            return .denied
        case .notDetermined:
            guard requestAuthorizationIfNeeded else { return .notAuthorized }
            do {
                guard try await client.requestAuthorization() else {
                    await cancelReminder()
                    return .denied
                }
            } catch {
                return .failed
            }
        case .authorized:
            break
        }

        do {
            try await client.replacePendingRequest(
                Self.identifier,
                Self.notificationTitle,
                Self.notificationBody,
                interval
            )
            return .scheduled
        } catch {
            return .failed
        }
    }

    func cancelReminder() async {
        client.cancelPendingRequest(Self.identifier)
    }
}

enum TrialReminderTransactionAction: Equatable, Sendable {
    case schedule(Date)
    case cancel
}

enum TrialReminderPolicy {
    nonisolated static func action(
        isIntroductoryTrial: Bool,
        expirationDate: Date?,
        isActive: Bool,
        isReminderEnabled: Bool
    ) -> TrialReminderTransactionAction {
        guard isActive, isIntroductoryTrial, isReminderEnabled, let expirationDate else {
            return .cancel
        }
        return .schedule(expirationDate)
    }
}

/// Persists the user's explicit reminder choice separately from notification
/// authorization. A staged value survives a pending StoreKit transaction; it
/// becomes active only after StoreKit verifies an introductory trial.
@MainActor
struct TrialReminderPreferenceStore {
    nonisolated static let enabledKey = "unit.trial-reminder.enabled"
    nonisolated static let stagedKey = "unit.trial-reminder.staged"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var isEnabled: Bool {
        defaults.bool(forKey: Self.enabledKey)
    }

    var stagedPreference: Bool? {
        defaults.object(forKey: Self.stagedKey) as? Bool
    }

    func stage(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: Self.stagedKey)
    }

    func commitStagedPreference() {
        guard let stagedPreference else { return }
        defaults.set(stagedPreference, forKey: Self.enabledKey)
        defaults.removeObject(forKey: Self.stagedKey)
    }

    func clearStagedPreference() {
        defaults.removeObject(forKey: Self.stagedKey)
    }

    func disable() {
        defaults.set(false, forKey: Self.enabledKey)
        defaults.removeObject(forKey: Self.stagedKey)
    }
}

/// Prevents an entitlement refresh that started before a purchase completed
/// from overwriting that newer, authoritative transaction with a stale
/// "nothing active" result.
struct EntitlementRefreshState {
    private(set) var revision = 0

    func beginRefresh() -> Int {
        revision
    }

    mutating func recordAuthoritativeChange() {
        revision &+= 1
    }

    func canApplyEmptyResult(from refreshRevision: Int) -> Bool {
        refreshRevision == revision
    }
}

/// A StoreKit-independent snapshot of a subscription period. Keeping this
/// small value testable lets the paywall prove that every duration and billing
/// label came from StoreKit metadata instead of a view-level assumption.
struct StoreSubscriptionPeriodSnapshot: Equatable, Sendable {
    enum Unit: Equatable, Sendable {
        case day
        case week
        case month
        case year
        case other
    }

    let unit: Unit
    let value: Int

    init(unit: Unit, value: Int) {
        self.unit = unit
        self.value = value
    }

    init(_ period: Product.SubscriptionPeriod) {
        switch period.unit {
        case .day: unit = .day
        case .week: unit = .week
        case .month: unit = .month
        case .year: unit = .year
        @unknown default: unit = .other
        }
        value = period.value
    }

    var billingText: String? {
        guard value > 0 else { return nil }
        let unitText: String
        switch unit {
        case .day: unitText = value == 1 ? "day" : "days"
        case .week: unitText = value == 1 ? "week" : "weeks"
        case .month: unitText = value == 1 ? "month" : "months"
        case .year: unitText = value == 1 ? "year" : "years"
        case .other: return nil
        }
        return value == 1 ? unitText : "\(value) \(unitText)"
    }
}

struct StoreIntroductoryOfferSnapshot: Equatable, Sendable {
    enum PaymentMode: Equatable, Sendable {
        case freeTrial
        case payAsYouGo
        case payUpFront
        case other
    }

    let paymentMode: PaymentMode
    let period: StoreSubscriptionPeriodSnapshot
    let periodCount: Int
}

struct StoreProductSnapshot: Equatable, Sendable {
    let isAutoRenewable: Bool
    let displayPrice: String
    let renewalPeriod: StoreSubscriptionPeriodSnapshot?
    let introductoryOffer: StoreIntroductoryOfferSnapshot?

    init(
        isAutoRenewable: Bool,
        displayPrice: String,
        renewalPeriod: StoreSubscriptionPeriodSnapshot?,
        introductoryOffer: StoreIntroductoryOfferSnapshot?
    ) {
        self.isAutoRenewable = isAutoRenewable
        self.displayPrice = displayPrice
        self.renewalPeriod = renewalPeriod
        self.introductoryOffer = introductoryOffer
    }

    init(product: Product) {
        let subscription = product.subscription
        let offer = subscription?.introductoryOffer
        isAutoRenewable = product.type == .autoRenewable
        displayPrice = product.displayPrice
        renewalPeriod = subscription.map { StoreSubscriptionPeriodSnapshot($0.subscriptionPeriod) }
        introductoryOffer = offer.map {
            StoreIntroductoryOfferSnapshot(
                paymentMode: Self.paymentMode(for: $0.paymentMode),
                period: StoreSubscriptionPeriodSnapshot($0.period),
                periodCount: $0.periodCount
            )
        }
    }

    private static func paymentMode(
        for mode: Product.SubscriptionOffer.PaymentMode
    ) -> StoreIntroductoryOfferSnapshot.PaymentMode {
        if mode == .freeTrial { return .freeTrial }
        if mode == .payAsYouGo { return .payAsYouGo }
        if mode == .payUpFront { return .payUpFront }
        return .other
    }
}

/// The only trial decision consumed by `PaywallView`. A non-nil `trial`
/// proves all five required conditions: auto-renewable product, configured
/// offer, free-trial payment mode, eligible customer, and valid duration.
struct StorePlanPresentation: Equatable, Sendable {
    struct Trial: Equatable, Sendable {
        let durationText: String
        let adjectiveText: String
        /// Exact day boundary for day- and week-based offers. Month/year
        /// offers stay nil because their calendar boundary is not a fixed
        /// number of days.
        let dayCount: Int?
    }

    let displayPrice: String
    let billingPeriodText: String?
    let trial: Trial?

    var billedPriceText: String {
        guard let billingPeriodText else { return displayPrice }
        return "\(displayPrice)/\(billingPeriodText)"
    }

    static func resolve(
        snapshot: StoreProductSnapshot,
        isEligibleForIntroOffer: Bool
    ) -> StorePlanPresentation {
        let billingPeriod = snapshot.renewalPeriod?.billingText
        let trial: Trial?

        if snapshot.isAutoRenewable,
           isEligibleForIntroOffer,
           let offer = snapshot.introductoryOffer,
           offer.paymentMode == .freeTrial {
            trial = resolvedTrial(for: offer)
        } else {
            trial = nil
        }

        return StorePlanPresentation(
            displayPrice: snapshot.displayPrice,
            billingPeriodText: billingPeriod,
            trial: trial
        )
    }

    private static func resolvedTrial(
        for offer: StoreIntroductoryOfferSnapshot
    ) -> Trial? {
        guard offer.period.value > 0, offer.periodCount > 0 else { return nil }
        let (periods, overflow) = offer.period.value.multipliedReportingOverflow(
            by: offer.periodCount
        )
        guard !overflow, periods > 0 else { return nil }

        let value: Int
        let dayCount: Int?
        let singular: String
        let plural: String
        switch offer.period.unit {
        case .day:
            value = periods
            dayCount = value
            singular = "day"
            plural = "days"
        case .week:
            let result = periods.multipliedReportingOverflow(by: 7)
            guard !result.overflow, result.partialValue > 0 else { return nil }
            value = result.partialValue
            dayCount = value
            singular = "day"
            plural = "days"
        case .month:
            value = periods
            dayCount = nil
            singular = "month"
            plural = "months"
        case .year:
            value = periods
            dayCount = nil
            singular = "year"
            plural = "years"
        case .other:
            return nil
        }

        let unit = value == 1 ? singular : plural
        return Trial(
            durationText: "\(value) \(unit)",
            adjectiveText: "\(value)-\(singular)",
            dayCount: dayCount
        )
    }
}

/// Serializes purchase attempts independently of product loading/restores.
/// A pending Ask-to-Buy/SCA result deliberately keeps the gate closed until a
/// verified transaction arrives through `Transaction.updates`.
struct PurchaseAttemptState: Equatable, Sendable {
    enum Phase: Equatable, Sendable {
        case idle
        case purchasing
        case pending
    }

    private(set) var phase: Phase = .idle

    var blocksNewAttempt: Bool { phase != .idle }
    var isPurchasing: Bool { phase == .purchasing }
    var isPending: Bool { phase == .pending }

    mutating func begin() -> Bool {
        guard phase == .idle else { return false }
        phase = .purchasing
        return true
    }

    mutating func markPending() {
        guard phase == .purchasing else { return }
        phase = .pending
    }

    mutating func finish() {
        phase = .idle
    }
}

@MainActor
@Observable
final class StoreManager {
    // MARK: - Product IDs

    enum Tier: String, CaseIterable, Hashable, Identifiable, Sendable {
        case weekly = "com.unit.weekly"
        case monthly = "com.unit.monthly"
        case annual = "com.unit.annual"
        case lifetime = "com.unit.lifetime"

        var id: String { rawValue }

        var isSubscription: Bool {
            switch self {
            case .weekly, .monthly, .annual: true
            case .lifetime: false
            }
        }

        var analyticsValue: String {
            switch self {
            case .weekly: "weekly"
            case .monthly: "monthly"
            case .annual: "annual"
            case .lifetime: "lifetime"
            }
        }
    }

    nonisolated static let weeklyProductID = Tier.weekly.rawValue
    nonisolated static let monthlyProductID = Tier.monthly.rawValue
    nonisolated static let annualProductID = Tier.annual.rawValue
    nonisolated static let lifetimeProductID = Tier.lifetime.rawValue

    nonisolated static let requiredTiers: [Tier] = [
        .weekly,
        .monthly,
        .annual
    ]

    nonisolated private static let allProductIDs: [String] = [
        Tier.weekly.rawValue,
        Tier.monthly.rawValue,
        Tier.annual.rawValue,
        Tier.lifetime.rawValue
    ]

    /// Last entitlement answer, persisted across launches. Absent = StoreKit
    /// has never answered on this install; "" = answered "no entitlement";
    /// otherwise a `Tier` rawValue. Lets the launch gate open from the cached
    /// answer instead of blocking on `Transaction.currentEntitlements`, which
    /// can hang indefinitely (wedged simulator StoreKit session, broken App
    /// Store connection).
    nonisolated private static let lastKnownEntitlementKey = "storeManager.lastKnownEntitlement"

    /// How long the first-ever entitlement check may block the launch gate
    /// before the app gives up and shows the paywall. The check keeps running
    /// and corrects the state whenever it completes.
    nonisolated private static let entitlementGateTimeout: Duration = .seconds(5)

#if DEBUG
    /// The progression contract UI journey validates app behavior, not App
    /// Store infrastructure. Keep that isolated test deterministic and avoid
    /// presenting a real Apple Account prompt on the simulator.
    nonisolated private static let progressionContractUITestArgument =
        "-ui-testing-progression-contract"
    nonisolated private static let startingTargetUITestArgument =
        "-ui-testing-starting-target"
    nonisolated private static let purchaseSuccessUITestArgument =
        "-ui-testing-purchase-success"
    nonisolated private static let purchaseCancelledUITestArgument =
        "-ui-testing-purchase-cancelled"
    nonisolated private static let purchasePendingUITestArgument =
        "-ui-testing-purchase-pending"
    nonisolated private static let purchaseUnverifiedUITestArgument =
        "-ui-testing-purchase-unverified"
    nonisolated private static let restoreSuccessUITestArgument =
        "-ui-testing-restore-success"
    nonisolated private static let introEligibleUITestArgument =
        "-ui-testing-intro-eligible"
    nonisolated private static let introIneligibleUITestArgument =
        "-ui-testing-intro-ineligible"
    nonisolated private static let skipInitialEntitlementUITestArgument =
        "-ui-testing-skip-initial-entitlement"
    nonisolated private static let partialProductsUITestArgument =
        "-ui-testing-partial-products"
    nonisolated private static let productLoadFailsOnceUITestArgument =
        "-ui-testing-product-load-fails-once"
    /// Xcode's off-device StoreKit test service cannot reliably synthesize a
    /// non-consumable purchase. Model the already-verified Lifetime state at
    /// the entitlement boundary so the hard-gate behavior stays deterministic
    /// without weakening production transaction verification.
    nonisolated private static let lifetimeOwnerUITestArgument =
        "-ui-testing-lifetime-owner"
#endif

    // MARK: - State

    var products: [String: Product] = [:]
    var isLoading = false
    var hasAttemptedProductLoad = false
    var isPurchased = false
    var activeTier: Tier?
    /// Flips true the first time `checkEntitlement()` completes (success or no
    /// entitlement). Read by `ContentView` to avoid flashing the hard paywall
    /// over `mainTabView` on cold launch before the StoreKit check returns.
    var hasCheckedEntitlement = false
    var purchaseError: String?
    /// Non-error notice shown via the same `.alert` channel — e.g.
    /// "No purchases to restore." after a benign restore call.
    var infoMessage: String?
    /// Introductory-offer eligibility is a subscription-group property. Keep
    /// the answer separate from offer metadata so eligibility alone can never
    /// create trial copy.
    private(set) var introOfferEligibilityByGroupID: [String: Bool] = [:]
    private(set) var hasCheckedIntroOfferEligibility = false
    private(set) var planSelection = PaywallPlanSelectionState()
    private(set) var purchaseAttempt = PurchaseAttemptState()

    var selectedTier: Tier { planSelection.selectedTier }
    var isPurchasing: Bool { purchaseAttempt.isPurchasing }
    var isPurchasePending: Bool { purchaseAttempt.isPending }
    var isBusy: Bool { isLoading || purchaseAttempt.blocksNewAttempt }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.unitlift", category: "StoreManager")
    @ObservationIgnored nonisolated(unsafe) private var transactionListener: Task<Void, Never>?
    @ObservationIgnored private var entitlementRefreshState = EntitlementRefreshState()
    @ObservationIgnored private var productLoadAttemptCount = 0
    @ObservationIgnored private let trialReminderScheduler: any TrialReminderScheduling
    @ObservationIgnored private let trialReminderPreferences: TrialReminderPreferenceStore

    // MARK: - Init

    init(
        trialReminderScheduler: any TrialReminderScheduling = TrialReminderScheduler(),
        trialReminderPreferences: TrialReminderPreferenceStore = TrialReminderPreferenceStore()
    ) {
        self.trialReminderScheduler = trialReminderScheduler
        self.trialReminderPreferences = trialReminderPreferences
#if DEBUG
        if CommandLine.arguments.contains(Self.lifetimeOwnerUITestArgument) {
            activeTier = .lifetime
            isPurchased = true
            hasCheckedEntitlement = true
            return
        }
        if CommandLine.arguments.contains(Self.progressionContractUITestArgument) {
            activeTier = .weekly
            isPurchased = true
            hasCheckedEntitlement = true
            return
        }
        if CommandLine.arguments.contains(Self.startingTargetUITestArgument) {
            activeTier = .weekly
            isPurchased = true
            hasCheckedEntitlement = true
            return
        }
#endif
        guard !ProcessInfo.processInfo.isSwiftUIPreview else { return }
        if let cached = UserDefaults.standard.string(forKey: Self.lastKnownEntitlementKey) {
            activeTier = Tier(rawValue: cached)
            isPurchased = activeTier != nil
            hasCheckedEntitlement = true
        }
        transactionListener = listenForTransactions()
#if DEBUG
        if CommandLine.arguments.contains(Self.skipInitialEntitlementUITestArgument) {
            hasCheckedEntitlement = true
        } else {
            Task { await checkEntitlement() }
            Task { await releaseEntitlementGateAfterTimeout() }
        }
#else
        Task { await checkEntitlement() }
        Task { await releaseEntitlementGateAfterTimeout() }
#endif
    }

    /// Nonisolated for the same back-deploy-shim SIGABRT as
    /// `ActiveWorkoutViewModel.deinit` — see the comment there. Safe:
    /// `transactionListener` is `nonisolated(unsafe)` and `Task.cancel()`
    /// is thread-safe.
    nonisolated deinit {
        transactionListener?.cancel()
    }

    // MARK: - Accessors

    func product(for tier: Tier) -> Product? {
        products[tier.rawValue]
    }

    var selectedProduct: Product? { product(for: selectedTier) }

    func presentation(for tier: Tier) -> StorePlanPresentation? {
        guard let product = product(for: tier) else { return nil }
        let eligible: Bool
        if let groupID = product.subscription?.subscriptionGroupID {
            eligible = introOfferEligibilityByGroupID[groupID] == true
        } else {
            eligible = false
        }
        return StorePlanPresentation.resolve(
            snapshot: StoreProductSnapshot(product: product),
            isEligibleForIntroOffer: eligible
        )
    }

    func selectTier(_ tier: Tier) {
        planSelection.selectByUser(tier)
    }

    // MARK: - Load Products

    @MainActor
    func loadProducts(force: Bool = false) async {
        guard products.isEmpty || force else {
            hasAttemptedProductLoad = true
            return
        }
        isLoading = true
        productLoadAttemptCount += 1
        defer {
            isLoading = false
            hasAttemptedProductLoad = true
        }

        do {
#if DEBUG
            if CommandLine.arguments.contains(Self.productLoadFailsOnceUITestArgument),
               productLoadAttemptCount == 1 {
                logger.error("Simulated first product-load failure for UI testing.")
                return
            }
#endif
            var loaded = try await Product.products(for: Self.allProductIDs)
#if DEBUG
            if CommandLine.arguments.contains(Self.partialProductsUITestArgument) {
                loaded.removeAll { $0.id == Tier.monthly.rawValue }
            }
#endif
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
            await loadIntroOfferEligibility(for: loaded)
            applyInitialPlanSelection()
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    private func loadIntroOfferEligibility(for loadedProducts: [Product]) async {
        let groupIDs = Set(loadedProducts.compactMap { $0.subscription?.subscriptionGroupID })
        var resolved: [String: Bool] = [:]
        for groupID in groupIDs {
#if DEBUG
            if CommandLine.arguments.contains(Self.introEligibleUITestArgument) {
                resolved[groupID] = true
                continue
            }
            if CommandLine.arguments.contains(Self.introIneligibleUITestArgument) {
                resolved[groupID] = false
                continue
            }
#endif
            resolved[groupID] = await Product.SubscriptionInfo.isEligibleForIntroOffer(
                for: groupID
            )
        }
        introOfferEligibilityByGroupID = resolved
        hasCheckedIntroOfferEligibility = true
    }

    private func applyInitialPlanSelection() {
        let availableTiers = Set(
            (Self.requiredTiers + [Tier.lifetime]).filter { product(for: $0) != nil }
        )
        let monthlyHasEligibleTrial = presentation(for: .monthly)?.trial != nil
        let annualHasEligibleTrial = presentation(for: .annual)?.trial != nil
        planSelection.applyInitialDefault(
            availableTiers: availableTiers,
            monthlyHasEligibleTrial: monthlyHasEligibleTrial,
            annualHasEligibleTrial: annualHasEligibleTrial,
            preferredTrialTier: monthlyHasEligibleTrial || annualHasEligibleTrial
                ? PaywallDefaultPlanExperiment.arm()
                : .annual
        )
    }

    // MARK: - Purchase

    @MainActor
    func purchase(remindBeforeTrialEnds: Bool = false) async {
        await purchase(
            tier: selectedTier,
            remindBeforeTrialEnds: remindBeforeTrialEnds
        )
    }

    @MainActor
    func purchase(
        tier: Tier,
        remindBeforeTrialEnds: Bool = false
    ) async {
        guard let product = product(for: tier) else { return }
        guard !isLoading, purchaseAttempt.begin() else { return }
        let hasEligibleTrial = presentation(for: tier)?.trial != nil
        let reminderRequested = hasEligibleTrial && remindBeforeTrialEnds
        trialReminderPreferences.stage(reminderRequested)
        UnitAnalytics.shared.track(
            .purchaseStarted(
                tier: tier.analyticsValue,
                hasTrial: hasEligibleTrial,
                reminderRequested: reminderRequested
            )
        )
        defer {
            if purchaseAttempt.isPurchasing {
                purchaseAttempt.finish()
            }
        }
        purchaseError = nil
#if DEBUG
        // Command-line UI tests on iOS 26.3.1 incorrectly route local
        // StoreKit purchases to a real Apple Account prompt. Keep the release
        // gate deterministic while still requiring the live local product and
        // exercising the paywall CTA → entitlement → root-unlock path.
        if CommandLine.arguments.contains(Self.purchaseSuccessUITestArgument) {
            trialReminderPreferences.clearStagedPreference()
            confirmEntitlement(tier)
            return
        }
        if CommandLine.arguments.contains(Self.purchaseCancelledUITestArgument) {
            trialReminderPreferences.clearStagedPreference()
            return
        }
        if CommandLine.arguments.contains(Self.purchasePendingUITestArgument) {
            purchaseAttempt.markPending()
            return
        }
        if CommandLine.arguments.contains(Self.purchaseUnverifiedUITestArgument) {
            trialReminderPreferences.clearStagedPreference()
            purchaseError = "Purchase couldn't be verified. No access was granted."
            return
        }
#endif

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                if let tier = Tier(rawValue: transaction.productID) {
                    confirmEntitlement(tier)
                    let isIntroductoryTrial = transaction.offer?.type == .introductory
                        && transaction.offer?.paymentMode == .freeTrial
                    if isIntroductoryTrial {
                        trialReminderPreferences.commitStagedPreference()
                        UnitAnalytics.shared.track(
                            .trialStarted(
                                tier: tier.analyticsValue,
                                context: ProgramSetupContextStore.load()
                            )
                        )
                    } else {
                        trialReminderPreferences.disable()
                    }
                    UnitAnalytics.shared.track(
                        .purchaseCompleted(
                            tier: tier.analyticsValue,
                            context: ProgramSetupContextStore.load()
                        )
                    )
                    Task {
                        await reconcileTrialReminder(
                            for: transaction,
                            requestAuthorizationIfNeeded: true
                        )
                    }
                }
                await transaction.finish()
            case .userCancelled:
                trialReminderPreferences.clearStagedPreference()
                UnitAnalytics.shared.track(
                    .purchaseOutcome(tier: tier.analyticsValue, outcome: .cancelled)
                )
            case .pending:
                purchaseAttempt.markPending()
                UnitAnalytics.shared.track(
                    .purchaseOutcome(tier: tier.analyticsValue, outcome: .pending)
                )
            @unknown default:
                break
            }
        } catch {
            trialReminderPreferences.clearStagedPreference()
            logger.error("Purchase failed: \(error.localizedDescription)")
            purchaseError = "Purchase failed. Try again in a moment."
            UnitAnalytics.shared.track(
                .purchaseOutcome(tier: tier.analyticsValue, outcome: .failed)
            )
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        guard !isLoading, !isPurchasing else { return }
        purchaseError = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }
#if DEBUG
        // Xcode's local AppStore.sync() can wait forever after SKTestSession
        // creates an off-device transaction. Exercise the visible restore
        // action at the same verified-entitlement boundary; release builds
        // always continue through Apple's sync and verification path below.
        if CommandLine.arguments.contains(Self.restoreSuccessUITestArgument) {
            confirmEntitlement(.monthly)
            return
        }
#endif
        do {
            try await AppStore.sync()
            await checkEntitlement()
            if !isPurchased {
                infoMessage = "No purchases to restore."
                // A declined Ask to Buy never reports back. An explicit
                // restore that finds nothing ends the pending wait so the
                // customer can choose again.
                if purchaseAttempt.isPending { purchaseAttempt.finish() }
            }
            UnitAnalytics.shared.track(
                .restoreOutcome(outcome: isPurchased ? .restored : .nothingFound)
            )
        } catch StoreKitError.userCancelled {
            // User dismissed the Apple ID sign-in prompt. Intentional back-out,
            // not an error — surfacing an alert here punishes the user for
            // declining to authenticate.
            return
        } catch StoreKitError.networkError(_) {
            logger.error("Restore failed: network error")
            purchaseError = "Couldn't reach the App Store. Check your connection and try again."
            UnitAnalytics.shared.track(.restoreOutcome(outcome: .failed))
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            purchaseError = "Couldn't restore purchases. Try again in a moment."
            UnitAnalytics.shared.track(.restoreOutcome(outcome: .failed))
        }
    }

    // MARK: - Entitlement Check

    @MainActor
    func checkEntitlement() async {
        let refreshRevision = entitlementRefreshState.beginRefresh()
        var entitlementTier: Tier?
        var entitlementTransaction: Transaction?
        var sawAny = false
        for await result in Transaction.currentEntitlements {
            sawAny = true
            do {
                let transaction = try checkVerified(result)
                if let tier = Tier(rawValue: transaction.productID) {
                    entitlementTier = tier
                    entitlementTransaction = transaction
                }
            } catch {
                let productID = result.unsafePayloadValue.productID
                logger.error("Entitlement skipped, failed verification: \(productID, privacy: .public) — \(error.localizedDescription, privacy: .public)")
            }
            if entitlementTier != nil { break }
        }
        if entitlementTier == nil {
            logger.info("Entitlement check: none active (any results: \(sawAny, privacy: .public))")
        }
        if let entitlementTier, let entitlementTransaction {
            confirmEntitlement(entitlementTier)
            await reconcileTrialReminder(
                for: entitlementTransaction,
                requestAuthorizationIfNeeded: false
            )
        } else if entitlementRefreshState.canApplyEmptyResult(from: refreshRevision) {
            clearEntitlement()
            await trialReminderScheduler.cancelReminder()
        } else {
            logger.info("Ignoring stale empty entitlement result because a newer transaction changed access.")
        }
        hasCheckedEntitlement = true
    }

    /// First-install fallback: no cached answer exists yet, so the launch gate
    /// is blocking on `checkEntitlement()`. If StoreKit hasn't answered within
    /// the timeout, release the gate unpurchased — the paywall (with Restore)
    /// is recoverable; an infinite spinner is not.
    private func releaseEntitlementGateAfterTimeout() async {
        try? await Task.sleep(for: Self.entitlementGateTimeout)
        if !hasCheckedEntitlement {
            logger.error("Entitlement check did not answer within \(Self.entitlementGateTimeout.components.seconds)s; releasing launch gate unpurchased.")
            hasCheckedEntitlement = true
        }
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { return }
                do {
                    let transaction = try await self.checkVerified(result)
                    if Self.allProductIDs.contains(transaction.productID) {
                        await transaction.finish()
                        if transaction.revocationDate != nil
                            || transaction.isUpgraded
                            || transaction.expirationDate.map({ $0 <= Date() }) == true {
                            // A refund or expiration is an authoritative access
                            // change. Re-derive from current entitlements in
                            // case another subscription tier remains active.
                            await self.recordAuthoritativeEntitlementChange()
                            await self.checkEntitlement()
                        } else if let tier = Tier(rawValue: transaction.productID) {
                            // A verified active transaction is itself the
                            // entitlement. Applying it directly avoids the
                            // StoreKit race where currentEntitlements briefly
                            // returns empty after an Xcode/device purchase.
                            await self.confirmEntitlement(tier)
                            var shouldRequestReminderAuthorization = false
                            if transaction.offer?.type == .introductory,
                               transaction.offer?.paymentMode == .freeTrial {
                                shouldRequestReminderAuthorization =
                                    await self.commitStagedTrialReminderPreference()
                            }
                            await self.reconcileTrialReminder(
                                for: transaction,
                                requestAuthorizationIfNeeded:
                                    shouldRequestReminderAuthorization
                            )
                        }
                    }
                } catch {
                    let productID = result.unsafePayloadValue.productID
                    await self.logUnverifiedTransaction(productID: productID, error: error)
                }
            }
        }
    }

    // MARK: - Verification

    private func confirmEntitlement(_ tier: Tier) {
        purchaseAttempt.finish()
        entitlementRefreshState.recordAuthoritativeChange()
        activeTier = tier
        isPurchased = true
        UserDefaults.standard.set(tier.rawValue, forKey: Self.lastKnownEntitlementKey)
        logger.info("Entitlement active: \(tier.rawValue, privacy: .public)")
    }

    private func clearEntitlement() {
        purchaseAttempt.finish()
        entitlementRefreshState.recordAuthoritativeChange()
        activeTier = nil
        isPurchased = false
        UserDefaults.standard.set("", forKey: Self.lastKnownEntitlementKey)
        logger.info("Entitlement inactive.")
    }

    private func recordAuthoritativeEntitlementChange() {
        entitlementRefreshState.recordAuthoritativeChange()
    }

    private func commitStagedTrialReminderPreference() -> Bool {
        let shouldRequestAuthorization =
            trialReminderPreferences.stagedPreference == true
        trialReminderPreferences.commitStagedPreference()
        return shouldRequestAuthorization
    }

    private func reconcileTrialReminder(
        for transaction: Transaction,
        requestAuthorizationIfNeeded: Bool
    ) async {
        let isActive = transaction.revocationDate == nil
            && !transaction.isUpgraded
            && transaction.expirationDate.map { $0 > Date() } != false
        let isIntroductoryTrial = transaction.offer?.type == .introductory
            && transaction.offer?.paymentMode == .freeTrial
        let isReminderEnabled = trialReminderPreferences.isEnabled
        if !isActive || !isIntroductoryTrial {
            trialReminderPreferences.disable()
        }
        let action = TrialReminderPolicy.action(
            isIntroductoryTrial: isIntroductoryTrial,
            expirationDate: transaction.expirationDate,
            isActive: isActive,
            isReminderEnabled: isReminderEnabled
        )

        // Reconciliation also runs on every launch; only the purchase-time
        // pass (the one that may ask permission) reports an outcome, so the
        // event counts decisions rather than app launches.
        switch action {
        case .schedule(let expirationDate):
            let result = await trialReminderScheduler.scheduleReminder(
                expirationDate: expirationDate,
                requestAuthorizationIfNeeded: requestAuthorizationIfNeeded
            )
            if requestAuthorizationIfNeeded {
                UnitAnalytics.shared.track(
                    .trialReminderAuthorization(outcome: analyticsOutcome(for: result))
                )
            }
        case .cancel:
            await trialReminderScheduler.cancelReminder()
            if requestAuthorizationIfNeeded {
                UnitAnalytics.shared.track(.trialReminderAuthorization(outcome: .cancelled))
            }
        }
    }

    private func analyticsOutcome(
        for result: TrialReminderSchedulingResult
    ) -> AnalyticsTrialReminderOutcome {
        switch result {
        case .scheduled: .scheduled
        case .denied: .denied
        case .notAuthorized: .notAuthorized
        case .invalidExpiration: .invalidExpiration
        case .failed: .failed
        }
    }

    private func checkVerified(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .unverified(_, let error):
            #if DEBUG
            // A local StoreKit configuration signs transactions with Xcode,
            // not the App Store. On physical devices that test certificate can
            // fail StoreKit's verification even though the local purchase
            // completed. Trust only that explicit Xcode test environment, and
            // compile this exception out of TestFlight/App Store builds.
            if result.unsafePayloadValue.environment == .xcode {
                logger.warning("Accepting Xcode StoreKit test transaction for \(result.unsafePayloadValue.productID, privacy: .public) in Debug build.")
                return result.unsafePayloadValue
            }
            #endif
            throw error
        case .verified(let value):
            return value
        }
    }

    private func logUnverifiedTransaction(productID: String, error: Error) {
        logger.error("Transaction update skipped, failed verification: \(productID, privacy: .public) — \(error.localizedDescription, privacy: .public)")
    }
}

/// Install-scoped paywall test (decision log 2026-10-23). Trial-eligible
/// customers start on Monthly or Yearly; both carry the same free trial and
/// every plan stays visible, so only the preselected card differs. The arm is
/// attached to paywall and purchase analytics as `default_plan`.
enum PaywallDefaultPlanExperiment {
    nonisolated static let key = "paywall.defaultPlanArm.v1"

    /// Off: Yearly is the default for every trial-eligible customer (founder
    /// decision 2026-10-23). Turning this on splits new installs 50/50 between
    /// Yearly and Monthly.
    static let isRunning = false

    /// The default plan for a trial-eligible customer.
    static func arm(
        defaults: UserDefaults = .standard,
        coinFlip: () -> Bool = { Bool.random() }
    ) -> StoreManager.Tier {
        guard isRunning else { return .annual }
        return assignedArm(defaults: defaults, coinFlip: coinFlip)
    }

    /// The stored arm, assigned 50/50 on first use and kept for the install.
    static func assignedArm(
        defaults: UserDefaults = .standard,
        coinFlip: () -> Bool = { Bool.random() }
    ) -> StoreManager.Tier {
        if let stored = defaults.string(forKey: key) {
            return stored == StoreManager.Tier.annual.analyticsValue ? .annual : .monthly
        }
        let tier: StoreManager.Tier = coinFlip() ? .annual : .monthly
        defaults.set(tier.analyticsValue, forKey: key)
        return tier
    }
}

/// Keeps the async eligibility result from undoing a choice the user already
/// made. Trial-eligible customers default to Yearly (founder decision
/// 2026-10-23), or to the experiment arm when that test runs. Customers
/// without a trial keep the Weekly default whenever it is available.
struct PaywallPlanSelectionState: Equatable, Sendable {
    private(set) var selectedTier: StoreManager.Tier = .weekly
    private(set) var hasUserSelectedTier = false

    mutating func selectByUser(_ tier: StoreManager.Tier) {
        selectedTier = tier
        hasUserSelectedTier = true
    }

    mutating func applyInitialDefault(
        availableTiers: Set<StoreManager.Tier>,
        monthlyHasEligibleTrial: Bool,
        annualHasEligibleTrial: Bool = false,
        preferredTrialTier: StoreManager.Tier = .annual
    ) {
        guard !hasUserSelectedTier else { return }

        if preferredTrialTier == .annual, annualHasEligibleTrial, availableTiers.contains(.annual) {
            selectedTier = .annual
        } else if monthlyHasEligibleTrial, availableTiers.contains(.monthly) {
            selectedTier = .monthly
        } else if availableTiers.contains(.weekly) {
            selectedTier = .weekly
        } else if let firstAvailable = StoreManager.requiredTiers.first(where: {
            availableTiers.contains($0)
        }) ?? (availableTiers.contains(.lifetime) ? .lifetime : nil) {
            selectedTier = firstAvailable
        }
    }
}

private extension ProcessInfo {
    var isSwiftUIPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
