//
//  PaywallView.swift
//  Unit
//
//  Hard paywall presented after onboarding, before first workout log.
//  Three tiers: Weekly, Monthly, Annual. No free trial. No dismissal.
//  Pricing authority: docs/pricing.md.
//

import SwiftUI

struct PaywallView: View {
    @Environment(StoreManager.self) private var store
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var onDismiss: () -> Void

    var body: some View {
        // Hard paywall — no `secondaryButton`, no "Not now". The only way out
        // is to subscribe (or kill the app). `onDismiss` is invoked only via
        // the `.onChange(of: store.isPurchased)` post-subscribe handler below.
        AppScreen(
            primaryButton: PrimaryButtonConfig(
                label: ctaTitle,
                isEnabled: !store.products.isEmpty,
                isLoading: store.isLoading,
                action: { Task { await store.purchase() } }
            ),
            hidesNavigationBar: true
        ) {
            VStack(alignment: .leading, spacing: 0) {

                // MARK: - Top Area

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Unit")
                        .appCapsLabel(.smallLabel)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("Your gym notebook")
                        .font(AppFont.numericDisplay.font)
                        .tracking(AppFont.numericDisplay.tracking)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .padding(.top, AppSpacing.xl)

                Text("Log every set, see every PR. Built for lifters who actually train.")
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, AppSpacing.smd)

                // MARK: - Benefits
                //
                // Hard paywall — these are product capabilities, not "Pro extras".
                // Authority: docs/pricing.md §Hard paywall.

                VStack(spacing: 0) {
                    benefitRow("One-tap set logging with last-time pre-fill")
                    benefitRow("Personal records, detected automatically")
                    benefitRow("Lock Screen rest timer")
                    benefitRow("All your training history, forever")
                    benefitRow("Paste your program from Notes or WhatsApp")
                    benefitRow("Local-first — no account, no cloud")
                }
                .padding(.top, AppSpacing.xl)

                // MARK: - Tiers

                tierSelector
                    .padding(.top, AppSpacing.xl)

                // MARK: - Disclosure

                subscriptionDisclosure
                    .padding(.top, AppSpacing.lg)

                // MARK: - Footer

                footer
                    .padding(.top, AppSpacing.xl)

                if store.products.isEmpty && !store.isLoading {
                    loadFailureBanner
                        .padding(.top, AppSpacing.lg)
                }
            }
            .appScreenEnter()
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

    // MARK: - CTA title

    private var ctaTitle: String {
        // Hard paywall — no trial copy. Same verb for every tier; the tier
        // card itself communicates the cadence.
        return "Subscribe"
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
        // ViewThatFits falls back to a vertical stack at narrow widths or
        // larger Dynamic Type sizes — on SE (375pt) with three equal-flex
        // cards (~109pt each) labels like "Annually"/"Lifetime" + scaled
        // price text otherwise overflow.
        ViewThatFits {
            HStack(alignment: .top, spacing: AppSpacing.sm) {
                tierCards
            }
            VStack(spacing: AppSpacing.sm) {
                tierCards
            }
        }
    }

    @ViewBuilder
    private var tierCards: some View {
        ForEach(StoreManager.Tier.allCases) { tier in
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

    // MARK: - Tier copy

    private func label(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Annually"
        }
    }

    private func priceText(for tier: StoreManager.Tier) -> String {
        if let product = store.product(for: tier) {
            return product.displayPrice
        }
        // Fallback prices only shown when StoreKit product load fails —
        // primary authority is the live ASC price returned by `product(for:)`.
        // Authority: docs/pricing.md (2026-06-16 hard-paywall rewrite).
        switch tier {
        case .weekly: return "$4.99"
        case .monthly: return "$9.99"
        case .annual: return "$59.99"
        }
    }

    private func sublabel(for tier: StoreManager.Tier) -> String {
        switch tier {
        case .weekly: return "Per week"
        case .monthly: return "Per month"
        case .annual: return "~$5/mo"
        }
    }

    private func badgeText(for tier: StoreManager.Tier) -> String? {
        switch tier {
        case .annual: return "Save 50%"
        default: return nil
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
        switch store.selectedTier {
        case .weekly:
            return "Weekly subscription. Auto-renews weekly at the price shown above unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store Settings > Apple ID > Subscriptions."
        case .monthly:
            return "Monthly subscription. Auto-renews monthly at the price shown above unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store Settings > Apple ID > Subscriptions."
        case .annual:
            return "Annual subscription. Auto-renews yearly at the price shown above unless cancelled at least 24 hours before the end of the current period. Manage or cancel anytime in App Store Settings > Apple ID > Subscriptions."
        }
    }

    // MARK: - Load failure banner
    //
    // Shown when StoreKit product loading has finished but products are empty
    // (network failure, App Store outage). Without this, the CTA renders with
    // hardcoded fallback prices but `purchase()` silently no-ops because
    // `product(for:)` returns nil — a guaranteed App Store reject. The CTA
    // is also disabled in this state via `PrimaryButtonConfig.isEnabled`.

    private var loadFailureBanner: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Couldn't load subscriptions.")
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
            AppGhostButton("Try again") {
                Task { await store.loadProducts() }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: AppSpacing.sm) {
            // ViewThatFits falls back to vertical stacking on narrow widths
            // / large Dynamic Type. The decorative "·" separators are dropped
            // in the vertical fallback since they only frame the horizontal
            // arrangement.
            ViewThatFits {
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
        Button("Restore purchases") {
            Task { await store.restore() }
        }
    }

    @ViewBuilder
    private var termsLink: some View {
        if let termsURL = URL(string: "https://unitlift.app/terms") {
            Link("Terms", destination: termsURL)
        }
    }

    @ViewBuilder
    private var privacyLink: some View {
        if let privacyURL = URL(string: "https://unitlift.app/privacy") {
            Link("Privacy", destination: privacyURL)
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
