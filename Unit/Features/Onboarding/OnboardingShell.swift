//
//  OnboardingShell.swift
//  Unit
//
//  Shared onboarding wrapper built on top of AppScreen.
//  Keeps onboarding on the same atom layer: one screen shell, one nav treatment,
//  one sticky primary CTA, one progress component. The back action is a real
//  iOS-native `ToolbarItem(.topBarLeading)` rendered by the host
//  `NavigationStack`'s `UINavigationBar` (auto-styled exactly like the Today
//  screen's leading button). The `customHeader` chrome below the nav bar
//  stacks progress → title → optional sticky accessory (e.g. day chips); body
//  scrolls beneath via the canonical `appScrollEdgeSoft` fade.
//
//  Surface: transparent. The Milk page lives once on `OnboardingFlow` so a
//  step swap slides only the content (header + body + sticky CTA) over a
//  still page surface — never the page itself. The shell drops the canonical
//  `appScreenEnter()` because that 6pt fade-up composes with the flow's
//  horizontal slide and reads as double motion.
//

import SwiftUI

struct OnboardingShell<Content: View, StickyAccessory: View, FloatingAccessory: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Keyboard-aware header compression. When any input on the step focuses
    /// and the keyboard slides up, `titleBlock` (large title + subtitle)
    /// fades out and the input region gets that vertical space back —
    /// roughly 80pt on a typical step, which is the difference between
    /// seeing 3 day-name rows cramped vs. 4 rows comfortably on the split
    /// builder. The progress bar stays so the lifter still knows which
    /// step they are on; the back-button toolbar item stays for the same
    /// reason. When the keyboard hides, the title fades back in.
    ///
    /// This is the explicit relax of the earlier "no overlap with the back
    /// button" rule — under keyboard, we prefer maximizing input
    /// visibility over keeping the title visible. The title returns the
    /// instant focus leaves the input.
    @State private var isKeyboardVisible = false

    let title: String
    var subtitle: String? = nil
    var ctaLabel: String = "Continue"
    var ctaEnabled: Bool = true
    /// One-line diagnostic shown above a disabled primary CTA. Pass a string
    /// from `AppCopy.FormHint` so a greyed `Continue` button explains its own
    /// gate ("Add at least one named exercise to every day."). Hidden when the
    /// CTA is enabled. Pair with `ctaEnabled` — both flip together.
    var ctaDisabledReason: String? = nil
    var progressStep: Int? = nil
    var progressTotal: Int? = nil
    var onContinue: (() -> Void)? = nil
    /// Back action is owned by `OnboardingFlow` (state-driven coordinator);
    /// every step gets one wired explicitly so there is no environment-dismiss
    /// fallback to drift to.
    let onBack: () -> Void
    /// Mirrors `AppScreen.usesOuterScroll`. Default `true` matches every
    /// onboarding screen with simple stacked cards. Pass `false` for a screen
    /// whose body is dominated by a flexible control (e.g. a `TextEditor` that
    /// fills available height) — putting one of those inside a SwiftUI
    /// `ScrollView` breaks hit-testing on the editor and lets inline content
    /// push the bottom CTA past the screen edge.
    var usesOuterScroll: Bool = true
    /// Mirrors `AppScreen.showsKeyboardDismissToolbar`. Default `false` so the
    /// standard TextField flows (Return / Next / Done) don't show a redundant
    /// accessory bar. Flip to `true` on screens that focus a multi-line
    /// `TextEditor`, where Return inserts a newline and the user needs an
    /// explicit Done button to dismiss the keyboard.
    var showsKeyboardDismissToolbar: Bool = false
    @ViewBuilder var content: () -> Content
    /// Optional sticky accessory rendered below the title in the top safe-area
    /// inset (e.g. a horizontal day-chip strip). Stays pinned while the body
    /// scrolls beneath via `appScrollEdgeSoft`.
    @ViewBuilder var stickyAccessory: () -> StickyAccessory
    /// Optional capsule pill that hovers above the primary CTA. Auto-hides on
    /// scroll-down, reveals on scroll-up. Built from `AppFloatingPillButton`.
    @ViewBuilder var floatingAccessory: () -> FloatingAccessory

    private var hasProgressBar: Bool { progressStep != nil && progressTotal != nil }
    private var hasStickyAccessory: Bool { StickyAccessory.self != EmptyView.self }
    private var hasFloatingAccessory: Bool { FloatingAccessory.self != EmptyView.self }

    private var headerStack: AnyView {
        AnyView(
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // No back-button row: the back action is now a real
                // `ToolbarItem(.topBarLeading)` declared in `body`, rendered by
                // the host `NavigationStack`'s `UINavigationBar` — same code
                // path as `TodayView`'s leading list-icon button, so the
                // capsule chrome, sizing, and Liquid Glass treatment match
                // automatically.
                if hasProgressBar {
                    OnboardingProgressBar(
                        step: progressStep ?? 0,
                        total: progressTotal ?? 0
                    )
                }
                // Title + subtitle collapse out of the layout while the
                // keyboard is up so the input region gets that ~80pt back.
                // `appReveal` animates both the opacity fade and the layout
                // reflow so the input rows expand into the recovered space
                // rather than popping. Reduce-motion users get a quieter
                // fade via `appAnimation`'s own clamp.
                if !isKeyboardVisible {
                    titleBlock
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                if hasStickyAccessory {
                    // Width clamping for horizontal-scrolling accessories
                    // (e.g. `AppFilterChipBar`) lives at the atom layer so the
                    // unbounded ideal width never leaks through this VStack
                    // and cancels `AppScreen`'s canonical 16pt screen padding.
                    // No screen-side workaround required.
                    stickyAccessory()
                }
            }
            .appAnimation(.appReveal, value: isKeyboardVisible, reduceMotion: reduceMotion)
        )
    }

    @ViewBuilder
    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .appFont(.largeTitle)
                .foregroundStyle(AppColor.textPrimary)
                .contentTransition(.opacity)
                .appAnimation(.appReveal, value: title, reduceMotion: reduceMotion)

            if let subtitle {
                Text(subtitle)
                    .appFont(.caption)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.opacity)
                    .appAnimation(.appReveal, value: subtitle, reduceMotion: reduceMotion)
            }
        }
    }

    var body: some View {
        AppScreen(
            primaryButton: onContinue.map { action in
                PrimaryButtonConfig(
                    label: ctaLabel,
                    isEnabled: ctaEnabled,
                    disabledReason: ctaDisabledReason,
                    action: action
                )
            },
            customHeader: headerStack,
            floatingAccessory: hasFloatingAccessory ? AnyView(floatingAccessory()) : nil,
            // `showsNativeNavigationBar: true` instead of `hidesNavigationBar`
            // so the host `NavigationStack`'s nav bar is visible and can host
            // the back-button `ToolbarItem` below. The `customHeader`
            // (progress + title + subtitle + sticky accessory) still renders
            // below it — `AppScreen.topChrome` no longer gates customHeader on
            // `!showsNativeNavigationBar` for exactly this case.
            showsNativeNavigationBar: true,
            usesOuterScroll: usesOuterScroll,
            showsKeyboardDismissToolbar: showsKeyboardDismissToolbar,
            surface: nil
        ) {
            content()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: onBack) {
                    Label("Back", systemImage: AppIcon.back.systemName)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Back")
            }
        }
        // Nav bar appearance is owned by the global proxy in
        // `ContentView.configureNavigationBarAppearance()`: transparent at
        // scroll edge, default Material once scrolled — same scroll-aware
        // pattern as `TodayView`. No `.toolbarBackground(.hidden)` here, or
        // the bar would stay transparent on scroll and content would show
        // through behind the back button.
        .navigationBarTitleDisplayMode(.inline)
        // UIKit keyboard notifications are the only reliable cross-view
        // way to know when the system keyboard is on screen — SwiftUI's
        // `@FocusState` is scoped to the view that owns it, and the
        // `keyboardLayoutGuide` is read-only geometry. `keyboardWillShow`
        // / `willHide` fire just before the keyboard animates in/out, so
        // pairing them with `appAnimation` on `headerStack` makes the
        // title fade in lockstep with the keyboard slide.
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
        ) { _ in
            isKeyboardVisible = true
        }
        .onReceive(
            NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
        ) { _ in
            isKeyboardVisible = false
        }
    }
}

extension OnboardingShell where StickyAccessory == EmptyView, FloatingAccessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        ctaLabel: String = "Continue",
        ctaEnabled: Bool = true,
        ctaDisabledReason: String? = nil,
        progressStep: Int? = nil,
        progressTotal: Int? = nil,
        onContinue: (() -> Void)? = nil,
        onBack: @escaping () -> Void,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.ctaLabel = ctaLabel
        self.ctaEnabled = ctaEnabled
        self.ctaDisabledReason = ctaDisabledReason
        self.progressStep = progressStep
        self.progressTotal = progressTotal
        self.onContinue = onContinue
        self.onBack = onBack
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.content = content
        self.stickyAccessory = { EmptyView() }
        self.floatingAccessory = { EmptyView() }
    }
}

extension OnboardingShell where FloatingAccessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        ctaLabel: String = "Continue",
        ctaEnabled: Bool = true,
        ctaDisabledReason: String? = nil,
        progressStep: Int? = nil,
        progressTotal: Int? = nil,
        onContinue: (() -> Void)? = nil,
        onBack: @escaping () -> Void,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder stickyAccessory: @escaping () -> StickyAccessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.ctaLabel = ctaLabel
        self.ctaEnabled = ctaEnabled
        self.ctaDisabledReason = ctaDisabledReason
        self.progressStep = progressStep
        self.progressTotal = progressTotal
        self.onContinue = onContinue
        self.onBack = onBack
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.content = content
        self.stickyAccessory = stickyAccessory
        self.floatingAccessory = { EmptyView() }
    }
}

extension OnboardingShell where StickyAccessory == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        ctaLabel: String = "Continue",
        ctaEnabled: Bool = true,
        ctaDisabledReason: String? = nil,
        progressStep: Int? = nil,
        progressTotal: Int? = nil,
        onContinue: (() -> Void)? = nil,
        onBack: @escaping () -> Void,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder floatingAccessory: @escaping () -> FloatingAccessory
    ) {
        self.title = title
        self.subtitle = subtitle
        self.ctaLabel = ctaLabel
        self.ctaEnabled = ctaEnabled
        self.ctaDisabledReason = ctaDisabledReason
        self.progressStep = progressStep
        self.progressTotal = progressTotal
        self.onContinue = onContinue
        self.onBack = onBack
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.content = content
        self.stickyAccessory = { EmptyView() }
        self.floatingAccessory = floatingAccessory
    }
}

/// Page-corner numeric counter — `STEP 02 / 04`.
/// Replaces the old segmented capsule bar. Mono digits (Geist Mono SemiBold 14
/// via `AppFont.stepIndicator`) make the count the loudest element instead of
/// chrome. Current digit reads in Ink, total in Mist, label in Ash — three
/// weights of meaning on one line. Leading-aligned with the title underneath.
struct OnboardingProgressBar: View {
    let step: Int
    let total: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedStep: Int { max(1, min(step, max(total, 1))) }
    private var stepText: String { String(format: "%02d", clampedStep) }
    private var totalText: String { String(format: "%02d", max(total, 1)) }

    var body: some View {
        HStack(spacing: 0) {
            Text("STEP ")
                .foregroundStyle(AppColor.textSecondary)
            Text(stepText)
                .foregroundStyle(AppColor.textPrimary)
                .contentTransition(.numericText())
                .appAnimation(.appReveal, value: clampedStep, reduceMotion: reduceMotion)
            Text(" / \(totalText)")
                .foregroundStyle(AppColor.textDisabled)
        }
        .font(AppFont.stepIndicator.font)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(clampedStep) of \(max(total, 1))")
    }
}
