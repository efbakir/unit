//
//  OnboardingPriceDisclosureView.swift
//  Unit
//
//  D0 — Pre-paywall price-disclosure splash. Sits above every other gate.
//  Shown to new and v1 users alike before they invest setup time, so the
//  paid model is a consented commitment, not a surprise tax. Direct response
//  to the documented Fitbod 3★ "Paywall after onboarding" complaint pattern
//  surfaced in docs/onboarding-redesign-research.md §2.
//
//  Copy locked Q3 (Variant A) in the 2026-06-17 grilling: first-person
//  singular ("I built") per PRODUCT.md §Brand Personality, three prices on
//  one line, single CTA. Restore Purchases is intentionally NOT here — it
//  lives on PaywallView's footer per Apple's "discoverable somewhere"
//  requirement (Guideline 3.1.2(b)).
//

import SwiftUI

struct OnboardingPriceDisclosureView: View {
    /// Invoked when the user taps "Continue setup". The caller flips the
    /// `hasSeenPriceDisclosure` flag so this screen does not show again
    /// until uninstall.
    var onContinue: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: AppSpacing.xl)

            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                Text("Before you start")
                    .appCapsLabel(.smallLabel)
                    .foregroundStyle(AppColor.textSecondary)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared || reduceMotion ? 0 : 8)
                    .animation(.appEnter, value: hasAppeared)

                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    Text("I built Unit as a paid app — no free trial.")
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("$4.99/wk, $9.99/mo, or $59.99/yr.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()

                    Text("Setting up your program is free. You'll see your full week ready to log before you're asked to subscribe.")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, AppSpacing.sm)
                }
                .opacity(hasAppeared ? 1 : 0)
                .offset(y: hasAppeared || reduceMotion ? 0 : 8)
                .animation(.appEnter.delay(0.08), value: hasAppeared)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.lg)

            AppPrimaryButton("Continue setup", action: onContinue)
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .opacity(hasAppeared ? 1 : 0)
                .animation(.appEnter.delay(0.16), value: hasAppeared)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
        }
        // Hide the nav bar — D0 is a single screen with one CTA, no back
        // affordance. Per OnboardingSplashView convention.
        .toolbar(.hidden, for: .navigationBar)
    }
}

#Preview {
    OnboardingPriceDisclosureView { }
}
