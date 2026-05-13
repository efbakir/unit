//
//  OnboardingSplashView.swift
//  Unit
//
//  Screen 1 — Value prop splash. No data collected.
//

import SwiftUI

struct OnboardingSplashView: View {
    var showsDismiss: Bool = false
    var onDismiss: (() -> Void)?
    var onGetStarted: () -> Void

    private static let logoSide: CGFloat = 144

    @State private var hasAppeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private func staggered(_ index: Int) -> some ViewModifier {
        StaggeredEntry(
            index: index,
            hasAppeared: hasAppeared,
            reduceMotion: reduceMotion
        )
    }

    var body: some View {
        // No opaque background here — `OnboardingFlow` owns the Milk page so
        // a step swap slides only this content layer over a still surface.
        VStack(spacing: 0) {
            Spacer(minLength: AppSpacing.lg)

            VStack(spacing: 0) {
                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: Self.logoSide, height: Self.logoSide)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppRadius.appIconHomeScreenCornerRadius(sideLength: Self.logoSide),
                            style: .continuous
                        )
                    )
                    .modifier(staggered(0))

                VStack(spacing: AppSpacing.xxs) {
                    Text("Welcome to")
                        .font(AppFont.splashWelcome.font)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("Unit")
                        .font(AppFont.splashTitle.font)
                        .tracking(AppFont.splashTitle.tracking)
                        .foregroundStyle(AppColor.textPrimary)
                }
                .padding(.top, AppSpacing.xl)
                .modifier(staggered(1))

                Text("Your upgraded gym notebook")
                    .font(AppFont.splashWelcome.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.xl)
                    .modifier(staggered(2))
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.lg)

            AppPrimaryButton("Set up program", action: onGetStarted)
                // 16pt horizontal inset matches `AppScreen.primaryButton`'s
                // canonical CTA inset everywhere else in onboarding. Used
                // to be 32pt (`AppSpacing.xl`) which made the button visibly
                // jump inward when advancing Splash → UnitPicker. Fixing
                // here at the Splash level since this is the one screen
                // that doesn't route through `AppScreen`.
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.md)
                .modifier(staggered(3))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
        }
        .overlay(alignment: .topTrailing) {
            if showsDismiss {
                Button {
                    onDismiss?()
                } label: {
                    AppIcon.close.image(size: 16, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .padding(.top, AppSpacing.md)
                .padding(.trailing, AppSpacing.md)
            }
        }
        // The host `NavigationStack` (added in `OnboardingView`) shows its nav
        // bar by default for every step; splash has its own dismiss affordance
        // and no back action, so hide the bar at this level only.
        .toolbar(.hidden, for: .navigationBar)
    }
}

/// Splash-only entry stagger: each block fades + translates in with an 80 ms-per-index delay.
/// Honors Reduce Motion. Kept file-private — promote to DesignSystem.swift if a second screen needs it.
///
/// Uses the canonical `.appEnter` curve (ease-out-quint, 320 ms) for the
/// staggered reveal. Under Reduce Motion the offset collapses to zero and
/// the curve drops to `.appReveal` (250 ms) with no per-index delay, so the
/// splash still resolves on the same timing budget without any translation.
/// This is the only sanctioned hero-entrance moment in the app.
private struct StaggeredEntry: ViewModifier {
    let index: Int
    let hasAppeared: Bool
    let reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: hasAppeared || reduceMotion ? 0 : 8)
            .animation(
                reduceMotion
                    ? .appReveal
                    : .appEnter.delay(Double(index) * 0.08),
                value: hasAppeared
            )
    }
}

#Preview {
    OnboardingSplashView { }
}
