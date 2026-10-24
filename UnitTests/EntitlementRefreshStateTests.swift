//
//  EntitlementRefreshStateTests.swift
//  UnitTests
//

import XCTest
@testable import Unit

@MainActor
final class EntitlementRefreshStateTests: XCTestCase {
    func testEmptyRefreshThatStartedBeforePurchaseIsIgnored() {
        var state = EntitlementRefreshState()
        let refreshRevision = state.beginRefresh()

        state.recordAuthoritativeChange()

        XCTAssertFalse(state.canApplyEmptyResult(from: refreshRevision))
    }

    func testFreshEmptyRefreshCanRevokeEntitlement() {
        var state = EntitlementRefreshState()
        state.recordAuthoritativeChange()
        let refreshRevision = state.beginRefresh()

        XCTAssertTrue(state.canApplyEmptyResult(from: refreshRevision))
    }

    func testSecondAuthoritativeChangeInvalidatesExistingRefresh() {
        var state = EntitlementRefreshState()
        state.recordAuthoritativeChange()
        let refreshRevision = state.beginRefresh()

        state.recordAuthoritativeChange()

        XCTAssertFalse(state.canApplyEmptyResult(from: refreshRevision))
    }
}

@MainActor
final class TrialReminderSchedulerTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 2_000_000_000)

    func testAuthorizedTrialSchedulesExactlyFortyEightHoursBeforeExpiration() async {
        var replacement: (String, TimeInterval)?
        let scheduler = makeScheduler(status: .authorized) { identifier, interval in
            replacement = (identifier, interval)
        }

        let result = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: true
        )

        XCTAssertEqual(result, .scheduled)
        guard let replacement else {
            XCTFail("authorized trial did not schedule")
            return
        }
        XCTAssertEqual(replacement.0, TrialReminderScheduler.identifier)
        XCTAssertEqual(replacement.1, 5 * 24 * 60 * 60)
    }

    func testNotDeterminedRequestsAuthorizationOnlyForNewPurchase() async {
        var requestCount = 0
        var replacementCount = 0
        let client = TrialReminderNotificationClient(
            authorizationStatus: { .notDetermined },
            requestAuthorization: {
                requestCount += 1
                return true
            },
            replacePendingRequest: { _, _, _, _ in replacementCount += 1 },
            cancelPendingRequest: { _ in }
        )
        let scheduler = TrialReminderScheduler(client: client, now: { self.now })

        let reconciliationResult = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: false
        )
        let purchaseResult = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: true
        )

        XCTAssertEqual(reconciliationResult, .notAuthorized)
        XCTAssertEqual(purchaseResult, .scheduled)
        XCTAssertEqual(requestCount, 1)
        XCTAssertEqual(replacementCount, 1)
    }

    func testDeniedPermissionDoesNotSchedule() async {
        var replacementCount = 0
        var cancellationCount = 0
        let scheduler = makeScheduler(
            status: .denied,
            onReplace: { _, _ in replacementCount += 1 },
            onCancel: { cancellationCount += 1 }
        )

        let result = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: true
        )

        XCTAssertEqual(result, .denied)
        XCTAssertEqual(replacementCount, 0)
        XCTAssertEqual(cancellationCount, 1)
    }

    func testInvalidExpirationCancelsStaleReminder() async {
        var cancellationCount = 0
        let scheduler = makeScheduler(
            status: .authorized,
            onReplace: { _, _ in XCTFail("invalid date must not schedule") },
            onCancel: { cancellationCount += 1 }
        )

        let result = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(TrialReminderScheduler.leadTime),
            requestAuthorizationIfNeeded: true
        )

        XCTAssertEqual(result, .invalidExpiration)
        XCTAssertEqual(cancellationCount, 1)
    }

    func testRepeatedSchedulingReplacesTheStableIdentifier() async {
        var identifiers: [String] = []
        let scheduler = makeScheduler(status: .authorized) { identifier, _ in
            identifiers.append(identifier)
        }

        _ = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(7 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: true
        )
        _ = await scheduler.scheduleReminder(
            expirationDate: now.addingTimeInterval(8 * 24 * 60 * 60),
            requestAuthorizationIfNeeded: true
        )

        XCTAssertEqual(identifiers, [
            TrialReminderScheduler.identifier,
            TrialReminderScheduler.identifier
        ])
    }

    func testPolicySchedulesOnlyActiveIntroductoryTrials() {
        let expiration = now.addingTimeInterval(7 * 24 * 60 * 60)

        XCTAssertEqual(
            TrialReminderPolicy.action(
                isIntroductoryTrial: true,
                expirationDate: expiration,
                isActive: true,
                isReminderEnabled: true
            ),
            .schedule(expiration)
        )
        XCTAssertEqual(
            TrialReminderPolicy.action(
                isIntroductoryTrial: false,
                expirationDate: expiration,
                isActive: true,
                isReminderEnabled: true
            ),
            .cancel
        )
        XCTAssertEqual(
            TrialReminderPolicy.action(
                isIntroductoryTrial: true,
                expirationDate: expiration,
                isActive: false,
                isReminderEnabled: true
            ),
            .cancel
        )
        XCTAssertEqual(
            TrialReminderPolicy.action(
                isIntroductoryTrial: true,
                expirationDate: nil,
                isActive: true,
                isReminderEnabled: true
            ),
            .cancel
        )
        XCTAssertEqual(
            TrialReminderPolicy.action(
                isIntroductoryTrial: true,
                expirationDate: expiration,
                isActive: true,
                isReminderEnabled: false
            ),
            .cancel
        )
    }

    private func makeScheduler(
        status: TrialReminderAuthorizationStatus,
        onReplace: @escaping (String, TimeInterval) -> Void,
        onCancel: @escaping () -> Void = { }
    ) -> TrialReminderScheduler {
        TrialReminderScheduler(
            client: TrialReminderNotificationClient(
                authorizationStatus: { status },
                requestAuthorization: { true },
                replacePendingRequest: { identifier, _, _, interval in
                    onReplace(identifier, interval)
                },
                cancelPendingRequest: { _ in onCancel() }
            ),
            now: { self.now }
        )
    }
}

@MainActor
final class TrialReminderPreferenceStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "TrialReminderPreferenceStoreTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testPreferenceDefaultsOff() {
        let store = TrialReminderPreferenceStore(defaults: defaults)

        XCTAssertFalse(store.isEnabled)
        XCTAssertNil(store.stagedPreference)
    }

    func testStagedPreferenceBecomesActiveOnlyAfterVerification() {
        let store = TrialReminderPreferenceStore(defaults: defaults)

        store.stage(true)
        XCTAssertFalse(store.isEnabled)
        XCTAssertEqual(store.stagedPreference, true)

        store.commitStagedPreference()
        XCTAssertTrue(store.isEnabled)
        XCTAssertNil(store.stagedPreference)
    }

    func testDisableClearsActiveAndPendingPreference() {
        let store = TrialReminderPreferenceStore(defaults: defaults)
        store.stage(true)
        store.commitStagedPreference()
        store.stage(true)

        store.disable()

        XCTAssertFalse(store.isEnabled)
        XCTAssertNil(store.stagedPreference)
    }
}

@MainActor
final class StorePlanPresentationTests: XCTestCase {
    func testEligibleMonthlyShowsConfiguredFreeTrial() {
        let presentation = resolve(
            snapshot: subscriptionSnapshot(renewalUnit: .month),
            eligible: true
        )

        XCTAssertEqual(presentation.trial?.durationText, "7 days")
        XCTAssertEqual(presentation.trial?.adjectiveText, "7-day")
        XCTAssertEqual(presentation.trial?.dayCount, 7)
    }

    func testTrialContextLeadsWithTheBilledAmount() {
        XCTAssertTrue(
            AppCopy.Paywall.trialPurchaseContext(duration: "7 days", billedPrice: "$29.99/year")
                .hasPrefix("$29.99/year after 7 days free")
        )
        XCTAssertEqual(AppCopy.Paywall.annualSavings(percent: 80), "Save 80%")
    }

    func testEligibleYearlyShowsConfiguredFreeTrial() {
        let presentation = resolve(
            snapshot: subscriptionSnapshot(
                displayPrice: "$29.99",
                renewalUnit: .year
            ),
            eligible: true
        )

        XCTAssertEqual(presentation.trial?.durationText, "7 days")
        XCTAssertEqual(presentation.trial?.dayCount, 7)
        XCTAssertEqual(presentation.billingPeriodText, "year")
    }

    func testWeeklyWithoutOfferNeverShowsTrial() {
        let snapshot = StoreProductSnapshot(
            isAutoRenewable: true,
            displayPrice: "$2.99",
            renewalPeriod: .init(unit: .week, value: 1),
            introductoryOffer: nil
        )

        XCTAssertNil(resolve(snapshot: snapshot, eligible: true).trial)
    }

    func testLifetimeNeverShowsTrialEvenWithOfferAndEligibility() {
        let snapshot = StoreProductSnapshot(
            isAutoRenewable: false,
            displayPrice: "$44.99",
            renewalPeriod: nil,
            introductoryOffer: freeWeekOffer
        )

        let presentation = resolve(snapshot: snapshot, eligible: true)
        XCTAssertNil(presentation.trial)
        XCTAssertEqual(presentation.billedPriceText, "$44.99")
    }

    func testIneligibleMonthlyAndYearlyDoNotShowTrial() {
        let monthly = resolve(
            snapshot: subscriptionSnapshot(renewalUnit: .month),
            eligible: false
        )
        let yearly = resolve(
            snapshot: subscriptionSnapshot(renewalUnit: .year),
            eligible: false
        )

        XCTAssertNil(monthly.trial)
        XCTAssertNil(yearly.trial)
    }

    func testEligibilityWithoutConfiguredOfferDoesNotCreateTrial() {
        let snapshot = StoreProductSnapshot(
            isAutoRenewable: true,
            displayPrice: "$4.99",
            renewalPeriod: .init(unit: .month, value: 1),
            introductoryOffer: nil
        )

        XCTAssertNil(resolve(snapshot: snapshot, eligible: true).trial)
    }

    func testNonFreeIntroductoryOfferDoesNotCreateTrial() {
        let snapshot = subscriptionSnapshot(
            renewalUnit: .month,
            offerMode: .payUpFront
        )

        XCTAssertNil(resolve(snapshot: snapshot, eligible: true).trial)
    }

    func testTrialDurationPriceAndRenewalPeriodAreDerivedFromSnapshot() {
        let snapshot = subscriptionSnapshot(
            displayPrice: "₺199,99",
            renewalUnit: .month
        )

        let presentation = resolve(snapshot: snapshot, eligible: true)

        XCTAssertEqual(presentation.trial?.durationText, "7 days")
        XCTAssertEqual(presentation.displayPrice, "₺199,99")
        XCTAssertEqual(presentation.billingPeriodText, "month")
        XCTAssertEqual(presentation.billedPriceText, "₺199,99/month")
    }

    func testInvalidTrialDurationDoesNotCreateTrial() {
        let snapshot = StoreProductSnapshot(
            isAutoRenewable: true,
            displayPrice: "$4.99",
            renewalPeriod: .init(unit: .month, value: 1),
            introductoryOffer: .init(
                paymentMode: .freeTrial,
                period: .init(unit: .week, value: 0),
                periodCount: 1
            )
        )

        XCTAssertNil(resolve(snapshot: snapshot, eligible: true).trial)
    }

    private var freeWeekOffer: StoreIntroductoryOfferSnapshot {
        .init(
            paymentMode: .freeTrial,
            period: .init(unit: .week, value: 1),
            periodCount: 1
        )
    }

    private func subscriptionSnapshot(
        displayPrice: String = "$4.99",
        renewalUnit: StoreSubscriptionPeriodSnapshot.Unit,
        offerMode: StoreIntroductoryOfferSnapshot.PaymentMode = .freeTrial
    ) -> StoreProductSnapshot {
        StoreProductSnapshot(
            isAutoRenewable: true,
            displayPrice: displayPrice,
            renewalPeriod: .init(unit: renewalUnit, value: 1),
            introductoryOffer: .init(
                paymentMode: offerMode,
                period: .init(unit: .week, value: 1),
                periodCount: 1
            )
        )
    }

    private func resolve(
        snapshot: StoreProductSnapshot,
        eligible: Bool
    ) -> StorePlanPresentation {
        StorePlanPresentation.resolve(
            snapshot: snapshot,
            isEligibleForIntroOffer: eligible
        )
    }
}

@MainActor
final class PaywallPlanSelectionStateTests: XCTestCase {
    func testEligibleNewCustomerDefaultsToYearly() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: true,
            annualHasEligibleTrial: true
        )

        XCTAssertEqual(selection.selectedTier, .annual)
    }

    func testIneligibleCustomerDefaultsToWeekly() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: false
        )

        XCTAssertEqual(selection.selectedTier, .weekly)
    }

    func testMonthlyArmPreselectsMonthly() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: true,
            annualHasEligibleTrial: true,
            preferredTrialTier: .monthly
        )

        XCTAssertEqual(selection.selectedTier, .monthly)
    }

    func testWeeklyIsTheFallbackWhenMonthlyIsMissing() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .annual],
            monthlyHasEligibleTrial: false
        )

        XCTAssertEqual(selection.selectedTier, .weekly)
    }

    func testAsyncEligibilityCannotOverrideUserSelection() {
        var selection = PaywallPlanSelectionState()
        selection.selectByUser(.annual)

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: true
        )

        XCTAssertEqual(selection.selectedTier, .annual)
        XCTAssertTrue(selection.hasUserSelectedTier)
    }

    func testYearlyArmPreselectsYearlyWhenItsTrialIsEligible() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: true,
            annualHasEligibleTrial: true,
            preferredTrialTier: .annual
        )

        XCTAssertEqual(selection.selectedTier, .annual)
    }

    func testYearlyArmFallsBackToMonthlyWithoutAYearlyTrial() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.weekly, .monthly, .annual],
            monthlyHasEligibleTrial: true,
            annualHasEligibleTrial: false,
            preferredTrialTier: .annual
        )

        XCTAssertEqual(selection.selectedTier, .monthly)
    }

    func testDefaultPlanArmIsAssignedOnceAndStaysSticky() {
        let suiteName = "PaywallDefaultPlanExperiment.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let first = PaywallDefaultPlanExperiment.assignedArm(defaults: defaults, coinFlip: { true })
        let second = PaywallDefaultPlanExperiment.assignedArm(defaults: defaults, coinFlip: { false })

        XCTAssertEqual(first, .annual)
        XCTAssertEqual(defaults.string(forKey: PaywallDefaultPlanExperiment.key), "annual")
        XCTAssertEqual(first, second)
    }

    func testDefaultPlanTestIsOffAtLaunchAndStoresNothing() {
        let suiteName = "PaywallDefaultPlanExperimentOff.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        XCTAssertFalse(PaywallDefaultPlanExperiment.isRunning)
        XCTAssertEqual(PaywallDefaultPlanExperiment.arm(defaults: defaults, coinFlip: { false }), .annual)
        XCTAssertNil(defaults.string(forKey: PaywallDefaultPlanExperiment.key))
    }

    func testPartialLoadFallsBackToFirstAvailableRequiredTier() {
        var selection = PaywallPlanSelectionState()

        selection.applyInitialDefault(
            availableTiers: [.annual],
            monthlyHasEligibleTrial: false
        )

        XCTAssertEqual(selection.selectedTier, .annual)
    }
}

@MainActor
final class PurchaseAttemptStateTests: XCTestCase {
    func testRepeatedTapCannotStartDuplicatePurchase() {
        var state = PurchaseAttemptState()

        XCTAssertTrue(state.begin())
        XCTAssertFalse(state.begin())
        XCTAssertTrue(state.isPurchasing)
    }

    func testPendingPurchaseBlocksRetriesUntilVerifiedUpdateFinishesIt() {
        var state = PurchaseAttemptState()
        XCTAssertTrue(state.begin())

        state.markPending()

        XCTAssertTrue(state.isPending)
        XCTAssertTrue(state.blocksNewAttempt)
        XCTAssertFalse(state.begin())

        state.finish()

        XCTAssertFalse(state.blocksNewAttempt)
        XCTAssertTrue(state.begin())
    }

    func testCancelledOrUnverifiedPurchaseCanReturnToIdle() {
        var state = PurchaseAttemptState()
        XCTAssertTrue(state.begin())

        state.finish()

        XCTAssertEqual(state.phase, .idle)
        XCTAssertTrue(state.begin())
    }
}
