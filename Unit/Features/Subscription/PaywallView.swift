//
//  PaywallView.swift
//  Unit
//
//  Hard paywall presented after onboarding, before first workout log.
//  Weekly, Monthly, Yearly subscriptions plus optional Lifetime purchase.
//  No free trial. No dismissal.
//  Pricing authority: docs/pricing.md.
//

import StoreKit
import SwiftData
import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    // Personalization (founder-approved conversion pass, 2026-07-13): the
    // paywall names the program the user just built, so the screen reads as
    // the payoff of their onboarding effort, not a generic wall.
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @State private var showingManageSubscriptions = false
    @State private var showsRenewalTimeline = false
    var onDismiss: () -> Void

    var body: some View {
        // Hard paywall with no secondary escape. `onDismiss` is invoked only
        // by a verified purchase below.
        AppScreen(
            primaryButton: primaryButtonConfig,
            hidesNavigationBar: true
        ) {
            // No .appScreenEnter() here: the root gate owns the transition.
            // Adding a second opacity-0→1 entrance risks the content staying
            // invisible if onAppear misfires on iOS 26's re-present cycle.
            if store.isPurchased {
                activeSubscriptionContent
            } else {
                purchaseContent
            }
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .sheet(isPresented: $showsRenewalTimeline) {
            renewalTimelineSheet
                .presentationDetents([.medium])
                .appBottomSheetChrome()
        }
        .task {
            await store.loadProducts()
        }
        .onChange(of: store.isPurchased) { _, purchased in
            if purchased { onDismiss() }
        }
        .appHaptic(.purchaseSuccess, trigger: store.isPurchased) { old, new in
            !old && new
        }
        .appHaptic(.tierSelected, trigger: store.selectedTier)
        .alert(
            "Something went wrong",
            isPresented: errorAlertBinding,
            presenting: store.purchaseError
        ) { _ in
            Button("OK", role: .cancel) { store.purchaseError = nil }
        } message: { error in
            Text(error)
        }
        .alert(
            "Restore",
            isPresented: infoAlertBinding,
            presenting: store.infoMessage
        ) { _ in
            Button("OK", role: .cancel) { store.infoMessage = nil }
        } message: { message in
            Text(message)
        }
    }

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )
    }

    private var infoAlertBinding: Binding<Bool> {
        Binding(
            get: { store.infoMessage != nil },
            set: { if !$0 { store.infoMessage = nil } }
        )
    }

    // MARK: - Content

    private var purchaseContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            purchaseHeader
                .appScreenEnter(index: 0)

            programSummaryCard
                .padding(.top, AppSpacing.lg)
                .appScreenEnter(index: 1)

            if hasNoLoadedProducts {
                loadFailureBanner
                    .padding(.top, AppSpacing.lg)
                    .appScreenEnter(index: 2)
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(AppCopy.Paywall.choosePlan)
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)

                    tierSelector
                }
                .padding(.top, AppSpacing.lg)
                .appScreenEnter(index: 2)

                if store.hasAttemptedProductLoad && hasMissingRequiredProducts && !store.isLoading {
                    partialLoadBanner
                        .padding(.top, AppSpacing.md)
                }

                timelineTrigger
                    .padding(.top, AppSpacing.sm)
                    .appScreenEnter(index: 3)

                subscriptionDisclosure
                    .padding(.top, AppSpacing.sm)
                    .appScreenEnter(index: 3)
            }

            footer
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
                .appScreenEnter(index: 3)
        }
    }

    private var activeSubscriptionContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            activeSubscriptionHeader

            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.smd) {
                    Text("Current plan")
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("Current plan: \(activePlanName)")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, AppSpacing.xl)

            if canManageActiveSubscription {
                AppGhostButton("Manage Subscription") {
                    showingManageSubscriptions = true
                }
                .padding(.top, AppSpacing.md)
            }

            footer
                .padding(.top, AppSpacing.xl)
        }
    }

    private var purchaseHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppSpacing.xs) {
                Image("PaywallLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: AppSpacing.xxl, height: AppSpacing.xxl)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppRadius.appIconHomeScreenCornerRadius(sideLength: AppSpacing.xxl),
                            style: .continuous
                        )
                    )

                Text("Unit")
                    .font(AppFont.productHeading.font)
                    .tracking(AppFont.productHeading.tracking)
                    .foregroundStyle(AppColor.textPrimary)
            }

            VStack(spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.xs) {
                    ForEach(0..<5, id: \.self) { _ in
                        AppIcon.starFilled.image(size: AppSpacing.md, weight: .semibold)
                            .foregroundStyle(AppColor.accent)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(AppCopy.Paywall.reviewStars)

                Text(AppCopy.Paywall.reviewQuote)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text(AppCopy.Paywall.reviewAttribution)
                    .font(AppFont.muted.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .padding(.top, AppSpacing.lg)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.sm)
    }

    private var programSummaryCard: some View {
        AppCard(verticalInset: AppSpacing.md) {
            VStack(alignment: .center, spacing: AppSpacing.sm) {
                VStack(spacing: AppSpacing.xs) {
                    AppIcon.checkmarkFilled.image(size: 24)
                        .foregroundStyle(AppColor.accent)

                    Text(AppCopy.Paywall.programReady)
                        .appCapsLabel(.overline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                Text(programTitle)
                    .font(AppFont.title.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if let programDayLine {
                    Text(programDayLine)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var activeSubscriptionHeader: some View {
        VStack(alignment: .leading, spacing: AppSpacing.smd) {
            Text("Unit Pro active")
                .appFont(.largeTitle)
                .foregroundStyle(AppColor.textPrimary)

            Text(activeSubscriptionSubtitle)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppSpacing.xl)
    }

    private var activeSubscriptionSubtitle: String {
        if store.activeTier == .lifetime {
            return "Lifetime access is active. Restore purchases anytime with the same Apple Account."
        }
        return "Your subscription is active. Manage or cancel anytime in App Store settings."
    }

    private var orderedProgramTemplates: [DayTemplate] {
        guard let split = ActiveSplitStore.resolve(from: splits) else { return [] }
        let splitTemplates = templates.filter { $0.splitId == split.id }
        let byID = Dictionary(uniqueKeysWithValues: splitTemplates.map { ($0.id, $0) })
        let ordered = split.orderedTemplateIds.compactMap { byID[$0] }
        return ordered.isEmpty ? splitTemplates.sorted { $0.name < $1.name } : ordered
    }

    private var programTitle: String {
        guard let split = ActiveSplitStore.resolve(from: splits) else {
            return AppCopy.Paywall.programFallbackTitle
        }
        let names = orderedProgramTemplates.map(\.displayName).filter { !$0.isEmpty }
        guard !names.isEmpty else { return AppCopy.Paywall.programFallbackTitle }
        let generatedName = names.joined(separator: " / ")
        let savedName = split.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if savedName.isEmpty || savedName == generatedName {
            return AppCopy.Paywall.programDayCount(names.count)
        }
        return savedName
    }

    private var programDayLine: String? {
        let names = orderedProgramTemplates.map(\.displayName).filter { !$0.isEmpty }
        guard !names.isEmpty else { return nil }

        if names.count > 4 {
            let visibleNames = names.prefix(3).joined(separator: " · ")
            return "\(visibleNames) · \(names.count - 3) more"
        }

        return names.joined(separator: " · ")
    }

    // MARK: - CTA

    private var primaryButtonConfig: PrimaryButtonConfig? {
        guard !store.isPurchased else { return nil }
        return PrimaryButtonConfig(
            label: ctaTitle,
            isEnabled: store.selectedProduct != nil,
            isLoading: store.isLoading,
            disabledReason: ctaDisabledReason,
            contextLabel: selectedPurchaseContext,
            action: { Task { await store.purchase() } }
        )
    }

    private var ctaTitle: String {
        if hasNoLoadedProducts {
            return "Subscribe to continue"
        }

        switch store.selectedTier {
        case .weekly: return AppCopy.Paywall.subscribeWeekly
        case .monthly: return AppCopy.Paywall.subscribeMonthly
        case .annual: return AppCopy.Paywall.subscribeYearly
        case .lifetime: return AppCopy.Paywall.buyLifetime
        }
    }

    private var ctaDisabledReason: String? {
        if hasNoLoadedProducts {
            return "Subscriptions couldn't load. Try again."
        }
        if store.hasAttemptedProductLoad {
            return "Choose an available plan."
        }
        return "Loading subscriptions."
    }

    private var selectedPurchaseContext: String? {
        guard store.selectedProduct != nil else { return nil }
        let price = priceText(for: store.selectedTier)
        if store.selectedTier == .lifetime {
            return AppCopy.Paywall.lifetimePurchaseContext(price)
        }
        return AppCopy.Paywall.subscriptionPurchaseContext(price)
    }

    // MARK: - Tier Selector

    private var tierSelector: some View {
        VStack(spacing: AppSpacing.sm) {
            tierCards
        }
    }

    @ViewBuilder
    private var tierCards: some View {
        ForEach(visibleTiers) { tier in
            AppSelectableTierCard(
                label: label(for: tier),
                price: priceText(for: tier),
                sublabel: sublabel(for: tier),
                badge: badgeText(for: tier),
                isSelected: store.selectedTier == tier,
                action: { store.selectedTier = tier }
            )
        }
    }

    private var visibleTiers: [StoreManager.Tier] {
        if store.hasAttemptedProductLoad {
            var loadedTiers = StoreManager.requiredTiers.filter { store.product(for: $0) != nil }
            if store.product(for: .lifetime) != nil {
                loadedTiers.append(.lifetime)
            }
            return loadedTiers
        }

        var tiers = StoreManager.requiredTiers
        if store.product(for: .lifetime) != nil {
            tiers.append(.lifetime)
        }
        return tiers
    }

    private var hasMissingRequiredProducts: Bool {
        StoreManager.requiredTiers.contains { store.product(for: $0) == nil }
    }

    private var hasNoLoadedProducts: Bool {
        store.hasAttemptedProductLoad && store.products.isEmpty && !store.isLoading
    }

    private var canManageActiveSubscription: Bool {
        guard let activeTier = store.activeTier else { return store.isPurchased }
        return activeTier.isSubscription
    }

    // MARK: - Tier copy

    private func label(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    private func priceText(for tier: StoreManager.Tier) -> String {
        if let billedPrice = billedPriceText(for: tier) { return billedPrice }
        return store.hasAttemptedProductLoad ? "Unavailable" : "Loading…"
    }

    private func sublabel(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "Auto-renews weekly"
        case .monthly:
            if let perWeek = perWeekEquivalentText(for: .monthly) {
                return "Auto-renews monthly · \(perWeek)/week"
            }
            return "Auto-renews monthly"
        case .annual:
            if let perWeek = perWeekEquivalentText(for: .annual) {
                return "Auto-renews yearly · \(perWeek)/week"
            }
            return "Auto-renews yearly"
        case .lifetime: return "One-time purchase"
        }
    }

    /// Every recurring card priced in the unit the pre-selected Weekly tier
    /// anchors on, derived from live StoreKit prices in the product's own
    /// currency ($2.99/week vs $1.15/week vs $0.58/week). Real division only
    /// — never a hardcoded compare-at figure.
    private func perWeekEquivalentText(for tier: StoreManager.Tier) -> String? {
        guard let product = store.product(for: tier) else { return nil }
        let perWeek: Decimal
        switch tier {
        case .monthly: perWeek = product.price * 12 / 52
        case .annual: perWeek = product.price / 52
        case .weekly, .lifetime: return nil
        }
        return perWeek.formatted(product.priceFormatStyle)
    }

    private func badgeText(for tier: StoreManager.Tier) -> String? {
        // docs/pricing.md ladder roles: yearly is the best-value tier and the
        // only badged card — one chip on the upsell target, never on the
        // pre-selected default (a badge on the selected card sells nothing).
        guard tier == .annual else { return nil }
        return annualSavingsBadgeText ?? "Best value"
    }

    /// "Save 80%" — calculated against 52 weeks at the live Weekly price.
    /// The compact badge omits the comparison label; the yearly card already
    /// shows its per-week equivalent directly beneath the price.
    private var annualSavingsBadgeText: String? {
        guard let annual = store.product(for: .annual),
              let weekly = store.product(for: .weekly) else { return nil }
        let annualizedWeekly = weekly.price * 52
        guard annualizedWeekly > annual.price, annualizedWeekly > 0 else { return nil }
        let fraction = (annualizedWeekly - annual.price) / annualizedWeekly
        let percent = Int((NSDecimalNumber(decimal: fraction).doubleValue * 100).rounded(.down))
        guard percent >= 10 else { return nil }
        return "Save \(percent)%"
    }

    private func ctaPlanName(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        case .lifetime: return "Lifetime"
        }
    }

    private var activePlanName: String {
        guard let activeTier = store.activeTier else { return "Active" }
        return ctaPlanName(for: activeTier)
    }

    private func billedPriceText(for tier: StoreManager.Tier) -> String? {
        guard let product = store.product(for: tier) else { return nil }
        guard tier.isSubscription, product.subscription != nil else {
            return product.displayPrice
        }
        return "\(product.displayPrice)/\(billingUnitText(for: product, fallbackTier: tier))"
    }

    private func billingUnitText(for product: Product, fallbackTier: StoreManager.Tier) -> String {
        guard let period = product.subscription?.subscriptionPeriod else {
            return fallbackBillingUnitText(for: fallbackTier)
        }

        let unit: String
        switch period.unit {
        case .day:
            unit = period.value == 1 ? "day" : "days"
        case .week:
            unit = period.value == 1 ? "week" : "weeks"
        case .month:
            unit = period.value == 1 ? "month" : "months"
        case .year:
            unit = period.value == 1 ? "year" : "years"
        @unknown default:
            return fallbackBillingUnitText(for: fallbackTier)
        }

        return period.value == 1 ? unit : "\(period.value) \(unit)"
    }

    private func fallbackBillingUnitText(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "week"
        case .monthly: return "month"
        case .annual: return "year"
        case .lifetime: return "one-time"
        }
    }

    // MARK: - Subscription Disclosure
    //
    // Apple Guideline 3.1.2(b): the purchase surface must disclose
    // subscription title, period, auto-renewal language, and how to cancel.
    // No trial language — hard paywall, no free trial (docs/pricing.md).

    private var subscriptionDisclosure: some View {
        Text(disclosureCopy)
            .font(AppFont.muted.font)
            .foregroundStyle(AppColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclosureCopy: String {
        if store.selectedTier == .lifetime {
            return "Lifetime is a one-time purchase. Subscriptions auto-renew unless cancelled. Payment is charged to your Apple Account. You can manage or cancel your subscription in App Store settings."
        }
        return "Subscriptions auto-renew unless cancelled. Payment is charged to your Apple Account. You can manage or cancel your subscription in App Store settings."
    }

    // MARK: - Load failure banner
    //
    // Shown when StoreKit product loading has finished but products are empty
    // (network failure, App Store outage). Without this, the disabled CTA
    // would leave the user with no recovery path.

    private var loadFailureBanner: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("Couldn't load subscriptions")
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("The App Store couldn't load subscriptions. Try again in a moment.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                AppGhostButton("Try again") {
                    Task { await store.loadProducts(force: true) }
                }
            }
        }
    }

    private var partialLoadBanner: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("Some plans couldn't load.")
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
            AppGhostButton("Try again") {
                Task { await store.loadProducts(force: true) }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    /// One caption-weight line — the only on-page cost of the subscription
    /// timeline. The optional sheet carries the reassurance so the paywall
    /// stays focused on choosing a plan.
    private var timelineTrigger: some View {
        Button(AppCopy.Paywall.timelineTrigger) {
            showsRenewalTimeline = true
        }
        .font(AppFont.caption.font)
        .foregroundStyle(AppColor.textSecondary)
        .frame(maxWidth: .infinity, minHeight: 44)
    }

    private var renewalTimelineSheet: some View {
        AppSheetScreen(
            title: AppCopy.Paywall.timelineTitle,
            dismissLabel: AppCopy.Nav.done,
            dismissActionPlacement: .confirmation,
            onDismissAction: { showsRenewalTimeline = false },
            usesOuterScroll: false
        ) {
            AppCardList(
                data: Array(0..<4),
                id: \.self,
                rowVerticalInset: AppSpacing.sm
            ) { index in
                timelineRow(at: index)
                    .padding(
                        .vertical,
                        index == 0 || index == 3 ? AppSpacing.sm : .zero
                    )
            }
        }
    }

    @ViewBuilder
    private func timelineRow(at index: Int) -> some View {
        switch index {
        case 0:
            AppListRow(
                title: AppCopy.Paywall.timelineSavedTitle,
                subtitle: programDayLine.map { "\($0) is ready." }
                    ?? AppCopy.Paywall.timelineSavedFallback,
                leadingIcon: .checkmarkFilled,
                style: .cardListContent
            )
        case 1:
            AppListRow(
                title: AppCopy.Paywall.timelineTodayTitle,
                subtitle: AppCopy.Paywall.timelineTodayMessage,
                leadingIcon: .bolt,
                style: .cardListContent
            )
        case 2:
            AppListRow(
                title: AppCopy.Paywall.timelineRenewalTitle,
                subtitle: AppCopy.Paywall.timelineRenewalMessage,
                leadingIcon: .calendarClock,
                style: .cardListContent
            )
        default:
            AppListRow(
                title: AppCopy.Paywall.timelineCancelTitle,
                subtitle: AppCopy.Paywall.timelineCancelMessage,
                leadingIcon: .settingsOutline,
                style: .cardListContent
            )
        }
    }

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            // ViewThatFits(in: .horizontal) — same axis rationale as
            // tierSelector above. Decorative "·" separators are dropped in
            // the vertical fallback since they only frame horizontal layout.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.md) {
                    restoreButton
                    middot
                    termsLink
                    middot
                    privacyLink
                }
                VStack(alignment: .center, spacing: AppSpacing.xs) {
                    restoreButton
                    termsLink
                    privacyLink
                }
            }
        }
        .font(AppFont.caption.font)
        .foregroundStyle(AppColor.textSecondary)
        .frame(maxWidth: .infinity)
    }

    private var restoreButton: some View {
        Button("Restore Purchases") {
            Task { await store.restore() }
        }
        .disabled(store.isLoading)
    }

    @ViewBuilder
    private var termsLink: some View {
        if let termsURL = AppCopy.Legal.termsOfServiceURL {
            Link(AppCopy.Legal.termsOfService, destination: termsURL)
        }
    }

    @ViewBuilder
    private var privacyLink: some View {
        if let privacyURL = AppCopy.Legal.privacyPolicyURL {
            Link(AppCopy.Legal.privacyPolicy, destination: privacyURL)
        }
    }

    private var middot: some View {
        Text("·")
            .foregroundStyle(AppColor.textSecondary)
    }
}

// MARK: - Preview

#Preview {
    PaywallView { }
        .environment(StoreManager())
}
