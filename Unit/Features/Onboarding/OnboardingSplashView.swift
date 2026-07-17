//
//  OnboardingSplashView.swift
//  Unit
//
//  Screen 1 — standalone opener, then carousel; no data collected:
//    1. Opener — logo + "Welcome to Unit" + "Your gym log."
//       No CTA, no dots, auto-advances after the brand beat.
//    2. Carousel — 3 auto-advancing value slides that teach what Unit does
//       *before* the post-onboarding paywall (decision-log 2026-06-16: "the
//       onboarding has to teach value before the wall"). Founder-approved
//       wedges (decision-log 2026-06-09 "Last time" + day-one paste import;
//       PRODUCT.md "No account. Works offline."). Calm/expert/honest, first-
//       person / Unit-as-subject — never the "transform your training" three-
//       feature-grid trap PRODUCT.md §Anti-references bans. Value, never price
//       (the price-disclosure splash was removed 2026-06-18).
//
//  Each slide renders its named screenshot when available and falls back to a
//  finished, tokenized icon tile. Empty asset catalogs never surface as
//  development placeholders in a release build.
//

import SwiftUI

struct OnboardingSplashView: View {
    var showsDismiss: Bool = false
    var onDismiss: (() -> Void)?
    var onGetStarted: () -> Void

    private enum Phase { case opener, carousel }

    private static let logoSide: CGFloat = 144
    /// How long the brand opener holds before the carousel reveals. Short on
    /// purpose — the opener is a transient intro, not a screen to dwell on. Must
    /// outlast the staggered parallax reveal (~0.5s) so it lands before passing.
    private static let openerDuration: TimeInterval = 2.0
    /// First carousel beat — shorter than the steady cadence so the deck starts
    /// moving soon after the opener (opener + this ≈ one steady beat), instead of
    /// the first slide sitting noticeably longer than the rest.
    private static let firstSlideInterval: TimeInterval = 3.0
    /// Steady cadence for every slide after the first. Marketing carousel only —
    /// NOT the hot loop, so a gentle timed advance is sanctioned (PRODUCT.md's
    /// decorative-motion ban governs the logging loop).
    private static let slideInterval: TimeInterval = 4.5

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Phase = .opener
    @State private var selection: Int = 0
    /// Drives the opener's staggered parallax *exit*. Set true at handoff so each
    /// brand layer lifts + fades out on its per-index delay (mirroring the
    /// entrance), instead of the opener flat-fading as one block.
    @State private var openerLeaving = false
    /// Keeps the opener mounted through its exit animation, then unmounts it once
    /// the lift-away has played so it leaves the view hierarchy.
    @State private var openerVisible = true

    private let slides = MarketingSlide.all

    var body: some View {
        // No opaque background here — `OnboardingFlow` owns the Milk page so a
        // step swap slides only this content layer over a still surface.
        ZStack {
            if phase == .carousel {
                carousel
                    .transition(.opacity)
            }
            // Opener sits above the carousel and lifts away on its own staggered
            // parallax exit (see `ParallaxEntry.leaving`) while the carousel fades
            // in beneath it. Kept mounted through the exit, then unmounted.
            if openerVisible {
                SplashOpener(logoSide: Self.logoSide, leaving: openerLeaving)
                    // Once the hand-off starts the opener is fading away on top of
                    // the live carousel — stop it absorbing taps meant for the CTA.
                    .allowsHitTesting(!openerLeaving)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // No `.appScreenEnter()` here: first render must be visible without
        // waiting for lifecycle callbacks.
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
        .task {
            // The opener is mounted on first render, with the carousel kept as
            // a separate surface underneath after hand-off. If this task is
            // cancelled, the opener remains visible rather than leaving a blank
            // page.
            if phase == .opener {
                try? await Task.sleep(for: .seconds(Self.openerDuration))
                if Task.isCancelled { return }
                // Hand off with a parallax *disappearance*: the opener's layers
                // lift + fade out staggered (driven by `ParallaxEntry`'s `leaving`
                // branch) while the carousel cross-fades in beneath. Then unmount
                // the now-invisible opener once the lift-away has played.
                openerLeaving = true
                withAnimation(reduceMotion ? nil : .appEnter) { phase = .carousel }
                try? await Task.sleep(for: .seconds(reduceMotion ? 0.2 : 0.65))
                if Task.isCancelled { return }
                openerVisible = false
            }

            // Reduce Motion → no unprompted motion; a single slide → nothing to
            // advance. The first beat is shorter (see `firstSlideInterval`) so
            // the deck starts moving soon after the opener; every beat after
            // settles into the steady `slideInterval`.
            guard !reduceMotion, slides.count > 1 else { return }
            var interval = Self.firstSlideInterval
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(interval))
                if Task.isCancelled || phase != .carousel { return }
                withAnimation(.appEnter) { selection = (selection + 1) % slides.count }
                interval = Self.slideInterval
            }
        }
    }

    private var carousel: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                ForEach(slides.indices, id: \.self) { index in
                    MarketingSlideView(slide: slides[index])
                        .tag(index)
                }
            }
            // Native dots sit at the very bottom and would collide with the
            // pinned CTA, so hide them and draw a tokenized `PageDots` row above
            // the button instead.
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: AppSpacing.lg) {
                PageDots(count: slides.count, selection: selection)

                AppPrimaryButton(AppCopy.Onboarding.splashCTA, action: onGetStarted)
                    // Horizontal + bottom insets mirror `AppScreen`'s canonical
                    // sticky-CTA chrome (md sides, xs above the home-indicator
                    // safe area) so the button doesn't jump — inward OR downward —
                    // when advancing Splash → UnitPicker. The splash can't route
                    // through `AppScreen.primaryButton` (its body is a full-bleed
                    // TabView), so it mirrors the inset by hand: keep these two in
                    // lockstep with `AppScreen.bottomChrome`.
                    .padding(.horizontal, AppSpacing.md)
            }
            .padding(.bottom, AppSpacing.xs)
        }
    }
}

// MARK: - Opener

/// The brand opener: logo + "Welcome to Unit" + tagline, vertically centered.
/// No CTA, no dots — it's the app's opening beat, shown once before the carousel
/// reveals. File-private, splash-only.
private struct SplashOpener: View {
    let logoSide: CGFloat
    /// When true, the opener plays its staggered parallax *exit* — each layer
    /// lifts + fades out on a per-index delay, mirroring the entrance.
    var leaving: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = true

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: AppSpacing.lg)

            VStack(spacing: 0) {
                Image("BrandLogo")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: logoSide, height: logoSide)
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: AppRadius.appIconHomeScreenCornerRadius(sideLength: logoSide),
                            style: .continuous
                        )
                    )
                    .modifier(ParallaxEntry(index: 0, appeared: appeared, leaving: leaving, reduceMotion: reduceMotion))

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
                .modifier(ParallaxEntry(index: 1, appeared: appeared, leaving: leaving, reduceMotion: reduceMotion))

                Text(AppCopy.Onboarding.splashTagline)
                    .font(AppFont.splashWelcome.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.xl)
                    .modifier(ParallaxEntry(index: 2, appeared: appeared, leaving: leaving, reduceMotion: reduceMotion))
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Staggered "parallax" entrance for the opener — each layer fades + rises into
/// place on a per-index delay, deeper layers travelling further so the reveal
/// reads as depth rather than one block appearing at once. Honors Reduce Motion
/// (fade only, no stagger or offset). File-private, splash-only: the opener is
/// the app's one sanctioned hero-entrance moment.
private struct ParallaxEntry: ViewModifier {
    let index: Int
    let appeared: Bool
    var leaving: Bool = false
    let reduceMotion: Bool

    /// Deeper layers travel further so both entrance and exit read as depth.
    private var offset: CGFloat { CGFloat(8 + index * 6) }

    private var isVisible: Bool { appeared && !leaving }

    /// Pre-entrance: start below (+offset). Leaving: lift away (−offset). In
    /// place: 0. Reduce Motion: no travel — fade only, both directions.
    private var offsetY: CGFloat {
        guard !reduceMotion else { return 0 }
        if leaving { return -offset }
        return appeared ? 0 : offset
    }

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: offsetY)
            .animation(
                reduceMotion ? .appReveal : .appEnter.delay(Double(index) * 0.10),
                value: appeared
            )
            .animation(
                reduceMotion ? .appReveal : .appEnter.delay(Double(index) * 0.10),
                value: leaving
            )
    }
}

// MARK: - Carousel content

/// One marketing slide. Screen-specific data model (not a design-system
/// primitive) — kept file-private alongside the splash, same as the existing
/// precedent. Copy lives here so the founder can redline one list.
private struct MarketingSlide: Identifiable {
    let id = UUID()
    /// Asset name in `Assets.xcassets`; the slide uses its semantic icon when
    /// the screenshot is not bundled.
    var imageName: String? = nil
    var fallbackIcon: AppIcon
    var headline: String
    var subline: String

    static let all: [MarketingSlide] = [
        MarketingSlide(
            imageName: "MarketingShotLogging",
            fallbackIcon: .dumbbell,
            headline: "Last time is already there",
            subline: "Your weight and reps from last session, ready to confirm with one tap."
        ),
        MarketingSlide(
            imageName: "MarketingShotProgram",
            fallbackIcon: .clipboard,
            headline: "Your numbers, from day one",
            subline: "Paste your program and Unit fills in your working weights. No blank first week."
        ),
        MarketingSlide(
            imageName: "MarketingShotPrivacy",
            fallbackIcon: .checkmarkFilled,
            headline: "No account. Works offline.",
            subline: "Your training lives on your iPhone. Always."
        ),
    ]
}

/// Renders a single carousel slide: screenshot over headline + subline.
/// File-private, splash-only — not a reusable molecule.
private struct MarketingSlideView: View {
    let slide: MarketingSlide

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: AppSpacing.lg)

            MarketingSlideImage(
                imageName: slide.imageName,
                fallbackIcon: slide.fallbackIcon
            )
                .padding(.horizontal, AppSpacing.md)

            VStack(spacing: AppSpacing.smd) {
                Text(slide.headline)
                    .font(AppFont.title.font)
                    .tracking(AppFont.title.tracking)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.center)

                Text(slide.subline)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, AppSpacing.lg)
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.lg)
        }
    }
}

/// Screenshot frame for a feature slide. Renders the named asset clipped to the
/// card squircle if it exists, else a finished semantic icon tile.
/// File-private — there is no existing image-frame primitive to extend, and this
/// is one-screen marketing chrome, not a general molecule.
private struct MarketingSlideImage: View {
    let imageName: String?
    let fallbackIcon: AppIcon

    private static let maxHeight: CGFloat = 420
    private static var expandedMaxHeight: CGFloat {
        maxHeight + AppSpacing.xxl + AppSpacing.lg + AppSpacing.smd
    }

    private var resolvedImage: UIImage? {
        guard let imageName else { return nil }
        return UIImage(named: imageName)
    }

    var body: some View {
        Group {
            if let resolvedImage {
                Image(uiImage: resolvedImage)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(maxHeight: Self.expandedMaxHeight)
                    .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            } else {
                AppIconCircle(
                    diameter: AppSpacing.xxl * 2,
                    shape: .roundedRect(radius: AppRadius.lg),
                    surface: .cardBackground
                ) {
                    fallbackIcon.image(size: AppSpacing.xl, weight: .semibold)
                        .foregroundStyle(AppColor.textPrimary)
                }
            }
        }
    }
}

/// Tokenized page indicator. Native `TabView` dots can't be repositioned above
/// the pinned CTA, so this draws the row from `AppColor` tokens. File-private —
/// no existing dots primitive to reuse; if a second screen ever needs paging
/// dots, promote this to `DesignSystem.swift`.
private struct PageDots: View {
    let count: Int
    let selection: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let dotSize: CGFloat = 7

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == selection ? AppColor.textPrimary : AppColor.controlBackgroundActive)
                    .frame(width: Self.dotSize, height: Self.dotSize)
            }
        }
        .animation(reduceMotion ? nil : .appState, value: selection)
        .accessibilityHidden(true)
    }
}

#Preview {
    OnboardingSplashView { }
}
