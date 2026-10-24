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

    func testTrialHeadlineLeadsWithTheBilledAmount() {
        XCTAssertEqual(
            AppCopy.Paywall.trialHeadline(duration: "7 days", billedPrice: "$29.99/year"),
            "$29.99/year after 7 days free"
        )
        XCTAssertEqual(AppCopy.Paywall.annualSavings(percent: 80), "Save 80%")
        XCTAssertFalse(AppCopy.Paywall.standardHeadline.localizedCaseInsensitiveContains("free"))
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

    /// Benchmark 2026-10-24, paywall row 3: the timeline shows real dates.
    func testTrialTimelineShowsRealDatesFromToday() throws {
        let calendar = Calendar.current
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12)))
        let trial = try XCTUnwrap(resolve(
            snapshot: subscriptionSnapshot(displayPrice: "$29.99", renewalUnit: .year),
            eligible: true
        ).trial)
        let english = Locale(identifier: "en_US")

        let end = try XCTUnwrap(trial.endDate(from: start, calendar: calendar))
        let reminder = try XCTUnwrap(trial.reminderDate(from: start, calendar: calendar))

        XCTAssertEqual(AppCopy.Paywall.timelineDate(end, now: start, calendar: calendar, locale: english), "Oct 31")
        XCTAssertEqual(AppCopy.Paywall.timelineDate(reminder, now: start, calendar: calendar, locale: english), "Oct 29")
    }

    func testRenewalDateAddsOneBillingPeriodAndShowsTheYearWhenItChanges() throws {
        let calendar = Calendar.current
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12)))
        let english = Locale(identifier: "en_US")
        let yearly = resolve(snapshot: subscriptionSnapshot(renewalUnit: .year), eligible: false)
        let weekly = resolve(
            snapshot: StoreProductSnapshot(
                isAutoRenewable: true,
                displayPrice: "$2.99",
                renewalPeriod: .init(unit: .week, value: 1),
                introductoryOffer: nil
            ),
            eligible: false
        )

        let yearlyRenewal = try XCTUnwrap(yearly.renewalDate(from: start, calendar: calendar))
        let weeklyRenewal = try XCTUnwrap(weekly.renewalDate(from: start, calendar: calendar))

        XCTAssertEqual(
            AppCopy.Paywall.timelineDate(yearlyRenewal, now: start, calendar: calendar, locale: english),
            "Oct 24, 2027"
        )
        XCTAssertEqual(
            AppCopy.Paywall.timelineDate(weeklyRenewal, now: start, calendar: calendar, locale: english),
            "Oct 31"
        )
        XCTAssertEqual(AppCopy.Paywall.timelineRenewalTitle("year"), "Every year")
        XCTAssertEqual(AppCopy.Paywall.trialTimelineEndTitle(dayCount: 7), "Day 7")
        XCTAssertEqual(AppCopy.Paywall.trialTimelineEndTitle(dayCount: nil), "After the trial")
        XCTAssertEqual(AppCopy.Paywall.trialTimelineReminderTitle(dayCount: 7), "Day 5")
    }

    /// Blinkist / Mesh pattern: the real date sits in the row text.
    func testTimelineTextNamesTheRealDates() throws {
        let calendar = Calendar.current
        let start = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 10, day: 24, hour: 12)))
        let end = try XCTUnwrap(calendar.date(byAdding: .day, value: 7, to: start))
        let reminder = try XCTUnwrap(calendar.date(byAdding: .day, value: 5, to: start))
        let endText = AppCopy.Paywall.timelineDate(end)
        let reminderText = AppCopy.Paywall.timelineDate(reminder)

        XCTAssertEqual(
            AppCopy.Paywall.trialTimelineEndMessage("$29.99/year", date: end),
            "You will be charged $29.99/year on \(endText). Cancel anytime before."
        )
        XCTAssertEqual(AppCopy.Paywall.trialTimelineReminderMessage(isOn: true, date: reminder),
                       "Unit reminds you on \(reminderText).")
        XCTAssertEqual(AppCopy.Paywall.trialTimelineReminderMessage(isOn: false, date: reminder),
                       "Turn on a reminder for \(reminderText).")
        XCTAssertEqual(AppCopy.Paywall.trialTimelineEndMessage("$29.99/year", date: nil),
                       "Renews at $29.99/year unless cancelled.")
        XCTAssertTrue(AppCopy.Paywall.timelineRenewalMessage("$2.99/week", date: end).hasPrefix("Next charge "))
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

/// Benchmark 2026-10-24, paywall row 4: Settings shows the trial end or the
/// next charge date.
@MainActor
final class SubscriptionRenewalSummaryTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_793_000_000)
    private var nextWeek: Date { now.addingTimeInterval(7 * 86_400) }

    func testFreeTrialShowsWhenItEndsWhetherOrNotItRenews() {
        for willAutoRenew in [true, false, nil] as [Bool?] {
            XCTAssertEqual(
                SubscriptionRenewalSummary.resolve(
                    expirationDate: nextWeek, isFreeTrial: true, willAutoRenew: willAutoRenew, now: now
                ),
                SubscriptionRenewalSummary(kind: .trialEnds, date: nextWeek)
            )
        }
    }

    func testPaidPlanRenewsOrEnds() {
        XCTAssertEqual(
            SubscriptionRenewalSummary.resolve(expirationDate: nextWeek, isFreeTrial: false, willAutoRenew: true, now: now)?.kind,
            .renews
        )
        XCTAssertEqual(
            SubscriptionRenewalSummary.resolve(expirationDate: nextWeek, isFreeTrial: false, willAutoRenew: false, now: now)?.kind,
            .ends
        )
    }

    func testNoRowForLifetimePastDatesOrUnknownRenewal() {
        XCTAssertNil(SubscriptionRenewalSummary.resolve(expirationDate: nil, isFreeTrial: false, willAutoRenew: true, now: now),
                     "Lifetime has no expiration")
        XCTAssertNil(SubscriptionRenewalSummary.resolve(expirationDate: now.addingTimeInterval(-60), isFreeTrial: true, willAutoRenew: true, now: now))
        XCTAssertNil(SubscriptionRenewalSummary.resolve(expirationDate: nextWeek, isFreeTrial: false, willAutoRenew: nil, now: now),
                     "an unknown renewal state shows nothing rather than a guess")
    }
}
