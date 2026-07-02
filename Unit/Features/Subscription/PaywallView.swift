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
import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @State private var showingManageSubscriptions = false
    var onDismiss: () -> Void

    var body: some View {
        // Hard paywall — no `secondaryButton`, no "Not now". The only way out
        // is to subscribe (or kill the app). `onDismiss` is invoked only via
        // the `.onChange(of: store.isPurchased)` post-subscribe handler below.
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
        .task {
            await store.loadProducts()
        }
        .onChange(of: store.isPurchased) { _, purchased in
            if purchased { onDismiss() }
        }
        .appHaptic(.purchaseSuccess, trigger: store.isPurchased) { old, new in
            !old && new
        }
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
            header

            VStack(spacing: 0) {
                benefitRow("Log a set in 3 seconds")
                benefitRow("Last-session numbers ready")
                benefitRow("Rest timer on your Lock Screen")
            }
            .padding(.top, AppSpacing.xl)

            if hasNoLoadedProducts {
                loadFailureBanner
                    .padding(.top, AppSpacing.xl)
            } else {
                tierSelector
                    .padding(.top, AppSpacing.xl)

                if store.hasAttemptedProductLoad && hasMissingRequiredProducts && !store.isLoading {
                    partialLoadBanner
                        .padding(.top, AppSpacing.md)
                }

                subscriptionDisclosure
                    .padding(.top, AppSpacing.md)
            }

            footer
                .padding(.top, AppSpacing.lg)
                .padding(.bottom, AppSpacing.lg)
        }
    }

    private var activeSubscriptionContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.smd) {
                    Text("Unit Pro active")
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

    private var header: some View {
        VStack(alignment: .leading, spacing: AppSpacing.smd) {
            Text(store.isPurchased ? "Unit Pro" : "Unit")
                .appCapsLabel(.smallLabel)
                .foregroundStyle(AppColor.textSecondary)

            Text(store.isPurchased ? "Unit Pro active" : "Your program is ready")
                .appFont(.largeTitle)
                .foregroundStyle(AppColor.textPrimary)

            Text(headerSubtitle)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, AppSpacing.xl)
    }

    private var headerSubtitle: String {
        if store.isPurchased {
            if store.activeTier == .lifetime {
                return "Lifetime access is active. Restore purchases anytime with the same Apple Account."
            }
            return "Your subscription is active. Manage or cancel anytime in App Store settings."
        }
        return "Subscribe to log your first workout."
    }

    // MARK: - CTA

    private var primaryButtonConfig: PrimaryButtonConfig? {
        guard !store.isPurchased else { return nil }
        return PrimaryButtonConfig(
            label: ctaTitle,
            isEnabled: store.selectedProduct != nil,
            isLoading: store.isLoading,
            disabledReason: ctaDisabledReason,
            contextLabel: selectedPlanSummary,
            action: { Task { await store.purchase() } }
        )
    }

    private var ctaTitle: String {
        if hasNoLoadedProducts {
            return "Subscribe to continue"
        }

        switch store.selectedTier {
        case .weekly, .monthly, .annual:
            return "Continue with \(ctaPlanName(for: store.selectedTier))"
        case .lifetime:
            return "Buy Lifetime"
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

    private var selectedPlanSummary: String? {
        guard let billedPrice = selectedSummaryPriceText(for: store.selectedTier) else { return nil }
        return "Selected: \(ctaPlanName(for: store.selectedTier)) · \(billedPrice)"
    }

    // MARK: - Benefit Row

    private func benefitRow(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            AppIcon.checkmark.image(size: 14, weight: .semibold)
                .foregroundStyle(AppColor.accent)
                .frame(width: 16, alignment: .leading)

            Text(text)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(.vertical, AppSpacing.sm)
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
        case .monthly: return "Auto-renews monthly"
        case .annual: return "Auto-renews yearly"
        case .lifetime: return "One-time purchase"
        }
    }

    private func badgeText(for _: StoreManager.Tier) -> String? {
        nil
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

    private func selectedSummaryPriceText(for tier: StoreManager.Tier) -> String? {
        guard let product = store.product(for: tier) else { return nil }
        guard tier.isSubscription, product.subscription != nil else {
            return "\(product.displayPrice) one-time"
        }
        return billedPriceText(for: tier)
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
