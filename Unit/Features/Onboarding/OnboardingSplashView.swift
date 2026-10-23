//
//  OnboardingSplashView.swift
//  Unit
//
//  Screen 1 — standalone opener, then progression-led carousel:
//    1. Opener — logo + "Welcome to Unit" + the progression promise.
//       No CTA, no dots, auto-advances after the brand beat.
//    2. Carousel — 3 auto-advancing value slides that teach what Unit does
//       *before* the post-onboarding paywall (decision-log 2026-06-16: "the
//       onboarding has to teach value before the wall"). Founder-approved
//       contract: previous evidence → next target → one-tap logging. Calm,
//       transparent, and outcome-first; value, never price.
//
//  Each slide renders production-token UI rather than competitor artwork or a
//  QA-harness screenshot.
//

import SwiftUI

struct OnboardingSplashView: View {
    var showsDismiss: Bool = false
    var onDismiss: (() -> Void)?
    var onSlideViewed: ((AnalyticsOnboardingSlide) -> Void)?
    var onGetStarted: () -> Void

    private enum Phase { case opener, carousel }

    private static let logoSide: CGFloat = 144
    /// How long the brand opener holds before the carousel reveals. Short on
    /// purpose — the opener is a transient intro, not a screen to dwell on.
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
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.scenePhase) private var scenePhase
    @State private var revealSession = AppRevealSession()
    @State private var phase: Phase = .opener
    @State private var selection: Int = 0
    /// Drives the shared fade/lift departure at handoff; accessibility fades only.
    @State private var openerLeaving = false
    /// Keeps the opener mounted through its exit animation, then unmounts it once
    /// the lift-away has played so it leaves the view hierarchy.
    @State private var openerVisible = true
    @State private var slideViewTracker = OnboardingSlideViewTracker()

    private let slides = MarketingSlide.all

    var body: some View {
        // No opaque background here — `OnboardingFlow` owns the Milk page so a
        // step swap slides only this content layer over a still surface.
        ZStack {
            if phase == .carousel {
                carousel
                    .transition(.opacity)
            }
            // Keep the opener mounted until its departure finishes above the carousel.
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
                    AppIcon.close.image(size: AppIconSize.readiness, weight: .semibold)
                        .foregroundStyle(
                            openerVisible
                                ? AppColor.accentForeground
                                : AppColor.textSecondary
                        )
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
        // Explicit brand-opener exception: keep status-bar chrome legible on
        // the black two-second opener, then return to Unit's light appearance
        // as soon as the opener unmounts.
        .preferredColorScheme(openerVisible ? .dark : .light)
        .environment(\.appRevealSession, revealSession)
        // Changing accessibility or scene state cancels the current sleep immediately.
        .task(id: "\(reduceMotion)-\(voiceOver)-\(scenePhase)") {
            guard scenePhase == .active else { return }
            if phase == .opener {
                // Accessible users reach the manually controlled carousel directly.
                if allowsAutoplay {
                    do { try await Task.sleep(for: .seconds(Self.openerDuration)) }
                    catch { return }
                }
                guard !Task.isCancelled else { return }
                openerLeaving = true
                withAnimation(.appReveal) { phase = .carousel }
                recordVisibleSlide()
            }
            // Also finishes an interrupted handoff after returning from background.
            if openerVisible {
                do { try await Task.sleep(for: .seconds(AppMotion.Duration.transition)) }
                catch { return }
                openerVisible = false
            }
            guard allowsAutoplay, slides.count > 1,
                  !CommandLine.arguments.contains("-ui-testing") else { return }
            var interval = Self.firstSlideInterval
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(interval)) }
                catch { return }
                guard !Task.isCancelled, allowsAutoplay, phase == .carousel else { return }
                withAnimation(.appReveal) { selection = (selection + 1) % slides.count }
                recordVisibleSlide()
                interval = Self.slideInterval
            }
        }
        .onChange(of: selection) { _, _ in
            guard phase == .carousel else { return }
            recordVisibleSlide()
        }
    }

    private var allowsAutoplay: Bool {
        scenePhase == .active && AppMotion.allowsSpatialMotion(
            reduceMotion: reduceMotion, voiceOver: voiceOver
        )
    }

    private func recordVisibleSlide() {
        guard slides.indices.contains(selection) else { return }
        let analyticsID = slides[selection].analyticsID
        guard slideViewTracker.shouldTrack(analyticsID) else { return }
        onSlideViewed?(analyticsID)
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
            // A taller artwork must scroll inside its page instead of growing
            // the TabView and pushing the shared conversion controls below the
            // viewport. The bottom chrome wins vertical compression on every
            // slide, including the smallest supported iPhone.
            .layoutPriority(0)

            VStack(spacing: AppSpacing.lg) {
                PageDots(count: slides.count, selection: selection)

                VStack(spacing: AppSpacing.sm) {
                    AppPrimaryButton(AppCopy.Onboarding.splashCTA, action: onGetStarted)

                    Text(AppCopy.Onboarding.paidAccessDisclosure)
                        .appFont(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
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
            .fixedSize(horizontal: false, vertical: true)
            .layoutPriority(1)
        }
        // This fixed hero composition scales through the largest standard text
        // size; larger accessibility settings keep that legible size while the
        // slide remains vertically scrollable and VoiceOver-readable.
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }
}

/// Keeps carousel analytics idempotent while a slide remains mounted or is
/// revisited. A new slide is a genuine view; repeated lifecycle callbacks are
/// not.
struct OnboardingSlideViewTracker {
    private var viewedSlideIDs: Set<AnalyticsOnboardingSlide> = []

    mutating func shouldTrack(_ slide: AnalyticsOnboardingSlide) -> Bool {
        viewedSlideIDs.insert(slide).inserted
    }
}

// MARK: - Opener

/// The brand opener: logo + "Welcome to Unit" + tagline, vertically centered.
/// No CTA, no dots — it's the app's opening beat, shown once before the carousel
/// reveals. The black surface belongs only to this two-second brand beat; the
/// value carousel and every product screen remain in Unit's light appearance.
/// File-private, splash-only.
private struct SplashOpener: View {
    let logoSide: CGFloat
    /// When true, all brand layers fade/lift together before unmounting.
    var leaving: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
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
                    .modifier(ParallaxEntry(appeared: appeared, leaving: leaving, reduceMotion: reduceMotion || voiceOver))

                VStack(spacing: AppSpacing.xxs) {
                    Text("Welcome to")
                        .font(AppFont.splashWelcome.font)
                        .foregroundStyle(AppColor.textDisabled)

                    Text("Unit")
                        .font(AppFont.splashTitle.font)
                        .tracking(AppFont.splashTitle.tracking)
                        .foregroundStyle(AppColor.accentForeground)
                }
                .padding(.top, AppSpacing.xl)
                .modifier(ParallaxEntry(appeared: appeared, leaving: leaving, reduceMotion: reduceMotion || voiceOver))

                Text(AppCopy.Onboarding.splashTagline)
                    .font(AppFont.splashWelcome.font)
                    .foregroundStyle(AppColor.textDisabled)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
                    .padding(.top, AppSpacing.xl)
                    .modifier(ParallaxEntry(appeared: appeared, leaving: leaving, reduceMotion: reduceMotion || voiceOver))
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer(minLength: AppSpacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColor.textPrimary.ignoresSafeArea())
    }
}

/// Existing splash departure owner. Layers share one restrained departure;
/// Reduce Motion and VoiceOver keep the fade only.
private struct ParallaxEntry: ViewModifier {
    let appeared: Bool
    var leaving: Bool = false
    let reduceMotion: Bool

    /// Shared travel token; the brand departure does not stagger sibling layers.
    private var offset: CGFloat { AppMotion.revealTravel }

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
                .appReveal,
                value: appeared
            )
            .animation(
                .appReveal,
                value: leaving
            )
    }
}

// MARK: - Carousel content

/// One marketing slide. Screen-specific data model (not a design-system
/// primitive) — kept file-private alongside the splash, same as the existing
/// precedent. Copy lives here so the founder can redline one list.
private struct MarketingSlide: Identifiable {
    var analyticsID: AnalyticsOnboardingSlide
    var id: String { analyticsID.rawValue }
    var visual: MarketingSlideVisual
    var headline: String
    var subline: String

    static var all: [MarketingSlide] {
        let metrics = MarketingPreviewMetrics.current
        return [
        MarketingSlide(
            analyticsID: .nextTarget,
            visual: .nextTarget,
            headline: "Know what to lift next",
            subline: "Finish your workout. Unit prepares one clear target for next time."
        ),
        MarketingSlide(
            analyticsID: .doubleProgression,
            visual: .doubleProgression,
            headline: "Build reps, then weight",
            subline: "Reach 10 reps on every set. Then add \(metrics.increment)."
        ),
        MarketingSlide(
            analyticsID: .oneTapLogging,
            visual: .oneTapLogging,
            headline: "Log every set in one tap",
            subline: "Your target and last workout are ready before every set."
        ),
        ]
    }
}

/// The value carousel appears before Unit asks for a weight unit. Match the
/// device's measurement convention until the user makes that explicit choice.
/// This keeps US acquisition examples in pounds without forcing pounds on
/// metric storefronts.
private struct MarketingPreviewMetrics {
    let previousWeight: String
    let nextWeight: String
    let increment: String

    static var current: MarketingPreviewMetrics {
        if Locale.current.measurementSystem == .us {
            return MarketingPreviewMetrics(
                previousWeight: "135 lb",
                nextWeight: "140 lb",
                increment: "5 lb"
            )
        }
        return MarketingPreviewMetrics(
            previousWeight: "60 kg",
            nextWeight: "62.5 kg",
            increment: "2.5 kg"
        )
    }
}

private enum MarketingSlideVisual {
    case nextTarget
    case doubleProgression
    case oneTapLogging
}

/// Renders a single carousel slide: production UI over headline + subline.
/// File-private, splash-only — not a reusable molecule.
private struct MarketingSlideView: View {
    let slide: MarketingSlide
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        GeometryReader { proxy in
            let enlargedTextReserve = dynamicTypeSize >= .xxLarge
                ? AppSpacing.xxl * 2
                : 0
            let imageMaxHeight = max(
                AppSpacing.xxl * 6,
                proxy.size.height
                    - AppSpacing.xxl * 3
                    - AppSpacing.lg
                    - enlargedTextReserve
            )

            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    Spacer(minLength: AppSpacing.lg)

                    MarketingSlideArtwork(
                        visual: slide.visual,
                        maxHeight: imageMaxHeight
                    )
                        .padding(.horizontal, AppSpacing.md)
                        .appReveal(id: "splash.\(slide.id).artwork")

                    VStack(spacing: AppSpacing.smd) {
                        Text(slide.headline)
                            .font(AppFont.title.font)
                            .tracking(AppFont.title.tracking)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(slide.subline)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, AppSpacing.lg)
                    .padding(.horizontal, AppSpacing.xl)
                    .appReveal(id: "splash.\(slide.id).intro")

                    Spacer(minLength: AppSpacing.lg)
                }
                .frame(minHeight: proxy.size.height)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
    }
}

/// Small production-token compositions that teach the real Unit interaction
/// without using a QA harness or competitor artwork.
private struct MarketingSlideArtwork: View {
    let visual: MarketingSlideVisual
    let maxHeight: CGFloat

    private let metrics = MarketingPreviewMetrics.current

    var body: some View {
        AppCard {
            switch visual {
            case .nextTarget:
                VStack(alignment: .leading, spacing: AppSpacing.smd) {
                    Text("SUGGESTED FOR NEXT TIME")
                        .appCapsLabel(.overline)
                        .foregroundStyle(AppColor.textSecondary)

                    Text("Bench Press")
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text("3 × 8 at \(metrics.nextWeight)")
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()

                    Text("Last time · 3 × 10 at \(metrics.previousWeight)")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)

                    AppDivider()

                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        AppIcon.forward.image(size: AppIconSize.readiness, weight: .semibold)
                        Text("All sets reached the top of your range.")
                            .font(AppFont.caption.font)
                    }
                    .foregroundStyle(AppColor.textSecondary)

                    AppPrimaryButton("Use this target") { }
                }
            case .doubleProgression:
                VStack(alignment: .leading, spacing: AppSpacing.smd) {
                    previewEvidence(label: "YOUR RANGE", value: "3 × 8–10")
                    AppDivider()
                    previewStep(label: "LAST", value: "\(metrics.previousWeight) · 10, 10, 10")
                    previewStep(label: "NEXT", value: "\(metrics.nextWeight) · 8, 8, 8", primary: true)

                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        AppIcon.forward.image(size: AppIconSize.readiness, weight: .semibold)
                        Text("Top of the range on every set · +\(metrics.increment)")
                            .font(AppFont.caption.font)
                    }
                    .foregroundStyle(AppColor.textSecondary)
                }
            case .oneTapLogging:
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    HStack(spacing: AppSpacing.xs) {
                        AppTag(text: "SET 1", style: .accent)
                        AppTag(text: "2", style: .muted)
                        AppTag(text: "3", style: .muted)
                    }
                    Text("Bench Press")
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)
                    Text("\(metrics.previousWeight) × 8")
                        .appFont(.numericDisplay)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()
                    Text("Last time · \(metrics.previousWeight) × 7")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                    AppPrimaryButton("Complete set") { }
                }
            }
        }
        .frame(maxWidth: 520)
        .frame(maxHeight: maxHeight)
        .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private func previewEvidence(label: String, value: String, primary: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .appCapsLabel(.overline)
                .foregroundStyle(AppColor.textSecondary)
            Text(value)
                .font(primary ? AppFont.title.font : AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
        }
    }

    private func previewStep(label: String, value: String, primary: Bool = false) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            Text(label)
                .appCapsLabel(.overline)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 92, alignment: .leading)
            Text(value)
                .font(primary ? AppFont.sectionHeader.font : AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
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
