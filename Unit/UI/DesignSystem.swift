//
//  DesignSystem.swift
//  Unit
//
//  Shared UI atoms, molecules, organisms, and screen wrapper.
//

import SwiftUI
import Charts
import Accessibility
import SwiftData
import UIKit

// MARK: - Atoms

/// Role-based color tokens. Every color used in the app resolves to a case here —
/// no `Color.black/.gray`, no raw hex literals in page files. **Light-mode only**
/// per CLAUDE.md §4 rule 3 — no dark-mode variants are maintained.
enum AppColor {
    static let clear = Color.clear
    // Surfaces
    static let background = Color(uiColor: uicolor(0xF5F5F5))
    static let cardBackground = Color(uiColor: uicolor(0xFFFFFF))
    /// Soft inset fill for elements nested inside `AppCard` (exercise rows, chips, inline cells).
    /// Matches page background so rows read as quiet recesses on white. Use with `AppRadius.sm` (10) +
    /// `AppSpacing.sm` (8) padding per the Figma source of truth. Do not use for top-level controls.
    static let cardRowFill = Color(uiColor: uicolor(0xF5F5F5))
    static let sheetBackground = Color(uiColor: uicolor(0xFFFFFF))
    /// Neutral surface for steppers, segmented track, disabled buttons, muted chip fills.
    /// Single canonical "secondary surface" token.
    static let controlBackground = Color(uiColor: uicolor(0xE8E8E8))
    /// One shade darker than `controlBackground`. Use to mark a control as the
    /// active subject of a sheet that is currently open — e.g. the logged set
    /// chip whose values are being edited in `AdjustResultSheet`. Subtle enough
    /// to read as "this is the one" without competing with the accent pill used
    /// for the live current set.
    static let controlBackgroundActive = Color(uiColor: uicolor(0xD6D6D6))

    // Text
    static let textPrimary = Color(uiColor: uicolor(0x0A0A0A))
    static let textSecondary = Color(uiColor: uicolor(0x595959))
    /// Low-emphasis contextual notes, lighter than `textSecondary` but still readable on Milk/Bond surfaces.
    static let textTertiary = Color(uiColor: uicolor(0x707070))
    /// Disabled primary/secondary buttons — softer than `textSecondary` so inactive reads clearly.
    static let textDisabled = Color(uiColor: uicolor(0x949494))
    /// Placeholder hint for empty text fields and editors. Matches the iOS-native
    /// `TextField` placeholder color (`UIColor.placeholderText`) so SwiftUI's built-in
    /// placeholder rendering and the manual `AppTextEditor` overlay read identically
    /// — single canonical placeholder gray across every input surface.
    static let textPlaceholder = Color(uiColor: .placeholderText)
    static let border = Color(uiColor: uicolor(0xE5E5E5))
    static let chartGrid = border.opacity(0.4)
    static let chartSelection = textSecondary.opacity(0.5)

    /// Filled segment in multi-step progress (e.g. onboarding) — softer than `textPrimary` but reads clearly against `border` for inactive steps.

    // Interactive — October 20 user-approved blue, deepened for light CTA labels.
    static let accent = Color(uiColor: uicolor(0x0068E0))
    static let accentForeground = Color(uiColor: uicolor(0xF6F6F6))
    static let accentSoft = Color(uiColor: uicolor(0xEAF2FF))

    // Celebration pieces only (never UI chrome). Brand: Unit blues plus ink.
    // Color: the Family-style multi-color option kept for comparison.
    static let celebrationBrand: [Color] = [0x0068E0, 0x4D9BFF, 0x0A0A0A, 0xA9CCFF, 0x0068E0]
        .map { Color(uiColor: uicolor($0)) }
    static let celebrationColor: [Color] = [0x0068E0, 0x34C759, 0xFFCC00, 0xFF9500, 0xFF3B30, 0xAF52DE]
        .map { Color(uiColor: uicolor($0)) }

    // Status
    static let success = Color(uiColor: uicolor(0x34C759))
    static let warning = Color(uiColor: uicolor(0xFF9500))
    static let error = Color(uiColor: uicolor(0xFF3B30))

    /// Soft tint fills for status surfaces (calendar day cells, status badges).
    /// Replaces scattered `AppColor.success.opacity(0.18)` and peers.
    static let successSoft = success.opacity(0.18)
    static let warningSoft = warning.opacity(0.22)
    static let errorSoft = error.opacity(0.18)

    /// Accessible text colors paired with the matching `*Soft` backgrounds.
    /// Vivid `success` / `warning` fail WCAG AA contrast when set as text on their own
    /// soft tint; these darker shades are the chip foreground.
    static let successOnSoft = Color(uiColor: uicolor(0x1D7A38))
    static let warningOnSoft = Color(uiColor: uicolor(0x8A4A00))
    static let errorOnSoft = Color(uiColor: uicolor(0xB3261E))

    private nonisolated static func uicolor(_ hex: UInt32) -> UIColor {
        UIColor(
            red: CGFloat((hex & 0xFF0000) >> 16) / 255,
            green: CGFloat((hex & 0x00FF00) >> 8) / 255,
            blue: CGFloat(hex & 0x0000FF) / 255,
            alpha: 1
        )
    }
}

/// Compatibility names retained for callers; faces come from native SF Pro.
/// AppFont remains the single typography owner.
extension Font {
    enum AppWeight {
        case medium, semibold, bold
    }

    /// Bridge native system fonts directly, with UIFontMetrics preserving the
    /// system's Dynamic Type size. Never look up private system font names.
    static func geist(_ weight: AppWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font(UIFont.geist(weight, size: size, relativeTo: textStyle.uiKitStyle))
    }

    /// SF Pro with tabular (fixed-width) digits for numbers that change or
    /// line up in columns. Letters, units and punctuation stay proportional,
    /// so "82.5 kg × 8" reads like text. SF Mono retired 2026-10-24.
    static func geistTabular(_ weight: AppWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        Font(UIFont.geistTabular(weight, size: size, relativeTo: textStyle.uiKitStyle))
    }
}

private extension Font.TextStyle {
    var uiKitStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: return .largeTitle
        case .title: return .title1
        case .title2: return .title2
        case .title3: return .title3
        case .headline: return .headline
        case .subheadline: return .subheadline
        case .callout: return .callout
        case .footnote: return .footnote
        case .caption: return .caption1
        case .caption2: return .caption2
        default: return .body
        }
    }
}

/// Native UIKit chrome uses the same weights and size roles as SwiftUI.
extension UIFont {
    static func geist(_ weight: Font.AppWeight, size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let base = systemFont(ofSize: size, weight: weight.uiKitWeight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }

    static func geistTabular(_ weight: Font.AppWeight, size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let base = monospacedDigitSystemFont(ofSize: size, weight: weight.uiKitWeight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }
}

extension Font.AppWeight {
    var uiKitWeight: UIFont.Weight {
        switch self {
        case .medium:   return .medium
        case .semibold: return .semibold
        case .bold:     return .bold
        }
    }
}

/// Typography tokens. Every font lives as an enum case so its associated
/// tracking is bundled with it — call sites apply both at once via
/// `.appFont(.X)` (Text) or `.font(AppFont.X.font)` + `.tracking(AppFont.X.tracking)`
/// (other views).
///
/// Native SF Pro everywhere. Numbers use SF Pro with tabular digits
/// (`geistTabular`); set data is 17pt wherever it sits (decision 2026-10-24).
/// Tracking is neutral, with restrained tightening on headings.
enum AppFont {
    // Body hierarchy
    case largeTitle
    case title
    case sectionHeader
    case body
    case caption
    case muted
    /// 11pt sans medium — low-emphasis contextual and source notes.
    case metadata

    // Display / specialized — previously loose `static let`s, now first-class cases
    /// 13pt sans medium UPPERCASE (neutral tracking) — card eyebrow, status/filter
    /// chip default state, footer/footnote micro-label. Apply via
    /// `Text.appCapsLabel(.overline)` so uppercase is baked.
    case overline
    /// 11pt sans medium UPPERCASE (neutral tracking) — tiny "WAS" / "MOST POPULAR"
    /// style caps. Apply via `Text.appCapsLabel(.smallLabel)`.
    case smallLabel
    /// 13pt sans BOLD UPPERCASE (neutral tracking) — selected/active chip state
    /// (filled background) and emphasized eyebrows. Sibling of `overline`.
    /// Apply via `Text.appCapsLabel(.overlineStrong)`.
    case overlineStrong
    /// 56pt bold — splash welcome title only.
    case splashTitle
    /// Approved Analytics status heading, 34pt SF Pro bold.
    case analyticsStatus
    /// 16pt medium — splash welcome eyebrow / tagline pair.
    case splashWelcome
    /// 36pt bold, tabular digits — workout metric hero, big numerics.
    case numericDisplay
    /// 30pt sans bold + tabular digits — workout targets and numeric input fields
    /// (`AdjustResultSheet` weight / reps). Proportional
    /// glyphs so a decimal like `82.5` doesn't show a wide gap around the period
    /// (mono cells inflate punctuation). `.monospacedDigit()` keeps digits tabular
    /// so values still align if rendered in a column.
    case numericInput
    /// Approved inline working-set value (30pt bold, tabular digits).
    case setValue
    case setValueCompact
    /// 15pt medium, tabular digits — small counters: set numbers, the
    /// elapsed timer, the onboarding step counter.
    case stepIndicator
    /// 24pt bold — product-screen heading on `ProductTopBar`, hero copy on empty states.
    case productHeading
    /// 17pt sans bold — primary CTA labels and full-width text buttons.
    case productAction
    /// 17pt medium, tabular digits — set data in rows (History, summary,
    /// logged and planned sets, rest time). Same size as the row name.
    case performance
    /// 15pt system — emoji glyphs use native Apple Color Emoji fallback.
    case emojiCaption

    var font: Font {
        switch self {
        case .setValue: return .geistTabular(.bold, size: 30, relativeTo: .title)
        case .setValueCompact: return .geistTabular(.bold, size: 28, relativeTo: .title)
        case .analyticsStatus: return .geist(.bold, size: 34, relativeTo: .largeTitle)
        case .largeTitle:     return .geist(.bold,     size: 22, relativeTo: .title2)
        case .title:          return .geist(.bold,     size: 20, relativeTo: .title3)
        case .sectionHeader:  return .geist(.semibold, size: 17, relativeTo: .body)
        case .body:           return .geist(.medium,   size: 17, relativeTo: .body)
        case .caption:        return .geist(.medium,   size: 15, relativeTo: .subheadline)
        case .muted:          return .geist(.medium,   size: 13, relativeTo: .footnote)
        case .metadata:       return .geist(.medium,   size: 11, relativeTo: .caption2)
        case .overline:       return .geist(.medium,   size: 13, relativeTo: .footnote)
        case .smallLabel:     return .geist(.medium,   size: 11, relativeTo: .caption2)
        case .overlineStrong: return .geist(.bold,     size: 13, relativeTo: .footnote)
        case .splashTitle:    return .geist(.bold,     size: 56, relativeTo: .largeTitle)
        case .splashWelcome:  return .geist(.medium,   size: 16, relativeTo: .callout)
        case .productHeading: return .geist(.bold,     size: 24, relativeTo: .title2)
        case .numericDisplay: return .geistTabular(.bold,  size: 36, relativeTo: .title)
        case .numericInput:   return .geist(.bold,         size: 30, relativeTo: .title).monospacedDigit()
        case .stepIndicator:  return .geistTabular(.medium, size: 15, relativeTo: .subheadline)
        case .productAction:  return .geist(.bold,         size: 17, relativeTo: .body)
        case .performance:    return .geistTabular(.medium, size: 17, relativeTo: .body)
        case .emojiCaption:
            // Use SwiftUI's public system-font path so supported runtimes and
            // physical devices resolve composed sequences through Apple Color
            // Emoji without depending on a private font-name lookup.
            return .system(size: 15, weight: .medium)
        }
    }

    var color: Color {
        switch self {
        case .muted: return AppColor.textSecondary
        default:     return AppColor.textPrimary
        }
    }

    /// Tracking baked into the case — apply via `.appFont(.X)` on Text and it lands automatically.
    /// Call sites should never pull a loose tracking constant from elsewhere.
    var tracking: CGFloat {
        switch self {
        case .largeTitle, .title, .productHeading: return -0.3
        case .setValue, .setValueCompact: return -0.5
        case .analyticsStatus: return -0.8
        case .splashTitle: return -0.6
        default: return 0
        }
    }
}

extension Text {
    /// Applies an AppFont style with its associated tracking.
    func appFont(_ style: AppFont) -> Text {
        self.font(style.font).tracking(style.tracking)
    }

    /// Applies a caps `AppFont` style (overline, smallLabel, overlineStrong) with
    /// its tracking AND `.textCase(.uppercase)`. Single canonical recipe for any
    /// caps micro-label — card eyebrow, footer/footnote, status chip,
    /// filter chip, dropdown chip. Returns `some View` because `.textCase` is
    /// environment-scoped, not Text-only — so chain non-Text modifiers after it.
    /// Use this instead of `Text.appFont(.overline)` for the caps tokens; using
    /// `appFont` on a caps token produces the right weight but skips the
    /// uppercase rendering, which would silently violate the doctrine.
    func appCapsLabel(_ style: AppFont) -> some View {
        self.font(style.font)
            .tracking(style.tracking)
            .textCase(.uppercase)
    }
}


/// 4pt-grid spacing tokens. Use instead of `.padding(16)` / literal gaps so section
/// rhythm stays consistent. `smd` (12) fills the gap between `sm` and `md` for
/// compact controls; `xxl` (48) for rare top-of-screen gutters.
enum AppSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32

    static let smd: CGFloat = 12
    static let xxl: CGFloat = 48
}

/// Shared chart viewports; unrelated touch-target floors stay explicit at 44pt.
enum AppChartMetrics {
    static let compactHeight: CGFloat = 160
    static let standardHeight: CGFloat = 180
    static let trendHeight: CGFloat = 96
    static let accessibleTrendHeight: CGFloat = 120
}

/// Corner radius tokens. Always paired with `RoundedRectangle(style: .continuous)`
/// — iOS's native squircle (≈60% Figma corner smoothing). `sm` compact chips/cells,
/// `md` buttons + inputs, `lg` (`card`) cards. Hook-enforced via
/// `.claude/hooks/ui-banned-list.sh`: bare `RoundedRectangle(cornerRadius:)` and
/// `.cornerRadius(...)` are blocked in feature code. No other radii should appear
/// in page code.
enum AppRadius {
    static let sm: CGFloat = 10
    static let md: CGFloat = 14
    /// Card outer radius. Concentric-radius math holds for `AppCardList` rows
    /// (card 22 − row inset 12 = row pill 10 = `sm`) and for any inline button
    /// (card 22 − button inset 8 = button radius 14 = `md`). Default `AppCard`
    /// content inset is `lg` (24), where concentric math doesn't apply because
    /// content is plain text/buttons rather than nested radii.
    static let lg: CGFloat = 22
    /// Semantic alias — prefer `card` at call sites where the radius is a card's
    /// outer corner (the docs and visual-language.md both reference `AppRadius.card`).
    static let card: CGFloat = lg

    /// Corner radius for a square tile so `RoundedRectangle(..., style: .continuous)` matches the iPhone Home Screen app icon mask (Apple icon grid: `10/57 × side length`).
    static func appIconHomeScreenCornerRadius(sideLength: CGFloat) -> CGFloat {
        sideLength * 10 / 57
    }
}

/// Shared sizing for day/week steppers and compact day badges (Paper e.g. node 2P1-0).
enum AppProgressChipMetrics {
    static let rowHeight: CGFloat = 20
    static var compactHorizontalPadding: CGFloat { AppSpacing.sm }
}

/// One motion vocabulary. Active logging stays quiet; staged moments may settle.
/// Reduce Motion OR VoiceOver permits fades only. Shared animated owners apply
/// `allowsSpatialMotion`; callers must not animate travel, blur, or scale otherwise.
enum AppMotion {
    enum Duration {
        static let feedback: Double = 0.15
        static let transition: Double = 0.28
        static let press = feedback
        static let state = transition
        static let reveal = transition
        static let enter = transition
        static let exit = transition
        /// Staged introductions only. Never stagger scrolling lists or logging taps.
        static let staggerStep: Double = 0.1
        static let burst: Double = 0.45
        static let toast: Double = 2
        static let toastAction: Double = 4
    }

    static let feedback = Animation.timingCurve(0.2, 0, 0, 1, duration: Duration.feedback)
    static let transition = Animation.timingCurve(0.2, 0, 0, 1, duration: Duration.transition)
    static let reveal = Animation.easeOut(duration: Duration.transition)
    static let collectionChange = Animation.smooth(duration: Duration.transition)
    static let settle = Animation.spring(duration: 0.5, bounce: 0.22)
    static let confirmSpring = settle
    static let immediate = Animation.linear(duration: 0)
    static let pressedScale: CGFloat = 0.96
    static let liftScale: CGFloat = 1.06
    static let leaveScale: CGFloat = 0.92
    static let markPopScale: CGFloat = 0.25
    static let pressedOpacity: Double = 0.82
    static let disabledOpacity: Double = 0.45
    static let revealTravel: CGFloat = 12
    static let revealBlur: CGFloat = 4
    static let burstDots = 8
    static let burstDot: CGFloat = 4
    static let burstStart: CGFloat = 10
    static let burstEnd: CGFloat = 32
    static let burstShrink: CGFloat = 0.5
    static let edgeGive: CGFloat = 0.55
    static let edgeGiveLimit: CGFloat = 64

    static func allowsSpatialMotion(reduceMotion: Bool, voiceOver: Bool) -> Bool {
        !reduceMotion && !voiceOver
    }

    static func give(_ overshoot: CGFloat) -> CGFloat {
        guard overshoot != 0 else { return 0 }
        let travel = (1 - 1 / (abs(overshoot) * edgeGive / edgeGiveLimit + 1)) * edgeGiveLimit
        return overshoot < 0 ? -travel : travel
    }

    static func give(from limit: CGSize, toward proposed: CGSize) -> CGSize {
        CGSize(width: limit.width + give(proposed.width - limit.width),
               height: limit.height + give(proposed.height - limit.height))
    }

    /// Celebration tokens. Chunky lifting-themed pieces fired from the bottom
    /// corners with launch, air drag, gravity, flutter and a 3D flip; the target
    /// burst pops from its card. Deterministic per moment, so a remount
    /// continues the same moment instead of replaying it.
    enum Confetti {
        static let showerCount = 56
        static let popperCount = 36
        static let burstCount = 14
        static let lifetime: Double = 2.8
        static let stagger: Double = 0.18
        static let burstLifetime: Double = 0.9
        /// Points per second squared and per second: a fast launch that
        /// settles into a slow, fluttering fall (about 250 pt/s).
        static let gravity: Double = 700
        static let drag: Double = 2.8
        static let launchSpeed: ClosedRange<Double> = 1650...2500
        static let launchSpreadDegrees: ClosedRange<Double> = 8...38
        static let burstSpeed: ClosedRange<Double> = 300...560
        static let pieceSize: ClosedRange<Double> = 16...28
        static let burstPieceSize: ClosedRange<Double> = 10...16
        static let popIn: Double = 0.16
        static let fadeOut: Double = 0.5
        static let ringStart: Double = 10
        static let ringEnd: Double = 64

        // Previous renderer, kept only as the comparison baseline.
        static let count = 32
        static let classicPopperCount = 12
        static let classicLifetime: Double = 1.8
        static let classicStagger: Double = 0.2
        static let colors: [Color] = [AppColor.accent, AppColor.textSecondary, AppColor.textDisabled]
        static let classicPieceSize = CGSize(width: 6, height: 10)
        static let spread: CGFloat = 160
        static let rise: CGFloat = 120
        static let fall: CGFloat = 320

        /// Stable across redraws and processes; never use randomized `hashValue`.
        static func sample(seed: UInt64, index: Int, channel: Int = 0) -> Double {
            var value = seed &+ UInt64(truncatingIfNeeded: index) &* 0x9E3779B97F4A7C15
            value &+= UInt64(truncatingIfNeeded: channel) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 30)) &* 0xBF58476D1CE4E5B9
            value = (value ^ (value >> 27)) &* 0x94D049BB133111EB
            value ^= value >> 31
            return Double(value >> 11) / Double(UInt64(1) << 53)
        }
    }
}

extension Animation {
    static let appPress = AppMotion.feedback
    static let appState = AppMotion.transition
    static let appReveal = AppMotion.reveal
    static let appEnter = AppMotion.transition
    static let appExit = AppMotion.transition
    static var appConfirm: Animation {
        AppMotion.allowsSpatialMotion(
            reduceMotion: UIAccessibility.isReduceMotionEnabled,
            voiceOver: UIAccessibility.isVoiceOverRunning
        ) ? AppMotion.settle : AppMotion.immediate
    }
}

extension View {
    /// `.animation(_:value:)` with a Reduce Motion gate baked in. Pass the
    /// environment's `accessibilityReduceMotion` value; the modifier resolves
    /// to `nil` when true, so the change still happens but instantly.
    func appAnimation<V: Equatable>(
        _ animation: Animation,
        value: V,
        reduceMotion: Bool
    ) -> some View {
        self.animation(reduceMotion || UIAccessibility.isVoiceOverRunning ? nil : animation, value: value)
    }
}

/// Owned by the scroll surface, so recycled intro/media views remember their arrival.
@MainActor
final class AppRevealSession {
    // Avoid the isolated-deinit back-deployment crash on iOS 18.
    // This state owns no resources requiring main-actor teardown.
    nonisolated deinit {}

    private var revealed: Set<String> = []
    func contains(_ id: String) -> Bool { revealed.contains(id) }
    func record(_ id: String) { revealed.insert(id) }
}

extension EnvironmentValues {
    @Entry var appRevealSession: AppRevealSession? = nil
}

/// One entrance owner for introductions, staged moments and native tab arrivals.
/// Legacy whole-screen calls are immediate: lists, controls and errors never hide.
private struct AppScreenEnter: ViewModifier {
    var index: Int = 0
    var enabled = false
    var id: String? = nil
    var onScroll = false
    var isSelected: Bool? = nil
    @Environment(\.appRevealSession) private var session
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var hasAppeared = false
    @State private var tabVisible = true
    @State private var tabMounted = false

    private var spatial: Bool {
        AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
    }
    private var visible: Bool {
        guard enabled else { return true }
        if isSelected != nil { return tabVisible }
        return hasAppeared || id.map { session?.contains($0) == true } == true
    }

    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .blur(radius: visible || !spatial ? 0 : AppMotion.revealBlur)
            .offset(y: visible || !spatial || isSelected != nil ? 0 : AppMotion.revealTravel)
            .onGeometryChange(for: Bool.self) { geometry in
                guard enabled, onScroll,
                      let viewport = geometry.bounds(of: .scrollView(axis: .vertical)) else { return true }
                let intersection = viewport.intersection(CGRect(origin: .zero, size: geometry.size))
                return !intersection.isNull && intersection.width > 0 && intersection.height > 0
            } action: { inViewport in
                if inViewport { reveal() }
            }
            .onAppear {
                if !onScroll || !spatial { reveal() }
            }
            .onChange(of: reduceMotion) { _, _ in if !spatial { reveal() } }
            .onChange(of: voiceOver) { _, _ in if !spatial { reveal() } }
            .task(id: isSelected) {
                guard let selected = isSelected else { return }
                guard tabMounted else { tabMounted = true; return }
                guard selected else { tabVisible = true; return }
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { tabVisible = false }
                await Task.yield()
                guard !Task.isCancelled else { return }
                withAnimation(.appReveal) { tabVisible = true }
            }
            .onDisappear { tabVisible = true }
    }

    private func reveal() {
        guard enabled, isSelected == nil, !hasAppeared else { return }
        let remembered = id.map { session?.contains($0) == true } == true
        let delay = spatial ? Double(max(0, index)) * AppMotion.Duration.staggerStep : 0
        withAnimation(remembered ? nil : .appReveal.delay(delay)) {
            hasAppeared = true
            if let id { session?.record(id) }
        }
    }
}

/// Transition-only visibility: it never animates a destination's layout or drafts.
private struct AppBlurVisibility: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    let visible: Bool
    var scales: Bool = false
    func body(content: Content) -> some View {
        content
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible || !scales || !AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? 1 : AppMotion.leaveScale)
            .blur(radius: visible || !AppMotion.allowsSpatialMotion(
                reduceMotion: reduceMotion, voiceOver: voiceOver
            ) ? 0 : AppMotion.revealBlur)
    }
}

struct AppBlurTransition: Transition {
    var scales = false
    func body(content: Content, phase: TransitionPhase) -> some View {
        content.modifier(AppBlurVisibility(visible: phase.isIdentity, scales: scales))
    }
}

extension View {
    /// Existing whole-content calls stay immediate. Opt in only for paywall/success chunks.
    func appScreenEnter(index: Int = 0, staged: Bool = false) -> some View {
        modifier(AppScreenEnter(index: index, enabled: staged))
    }

    /// Introductory copy and media only. Supply a scroll-owned session for stable memory.
    func appReveal(id: String, onScroll: Bool = true) -> some View {
        modifier(AppScreenEnter(enabled: true, id: id, onScroll: onScroll))
    }

    /// Arrival only; native TabView still owns navigation and selection.
    func appTabEntrance(isSelected: Bool) -> some View {
        modifier(AppScreenEnter(enabled: true, isSelected: isSelected))
    }
}

/// A number animates at its owner regardless of which caller changed it.
private struct AppNumericValue<Value: Equatable>: ViewModifier {
    let value: Value
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    func body(content: Content) -> some View {
        content
            .contentTransition(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? .numericText() : .opacity)
            .animation(AppMotion.feedback, value: value)
    }
}

extension View {
    func appNumericValue<Value: Equatable>(value: Value) -> some View {
        modifier(AppNumericValue(value: value))
    }
}

/// Immutable event time and seed: remounting continues the same moment, never replays it.
struct AppCelebrationMoment: Identifiable, Equatable {
    /// `shower`: first workout ever. `popper`: every later finished workout.
    /// `burst`: a saved next target, popping from its card.
    enum Style: Equatable { case shower, popper, burst }
    let id: UUID
    let startedAt: Date
    let seed: UInt64
    let style: Style
    let look: AppCelebrationLook

    init(style: Style, id: UUID = UUID(), startedAt: Date = .now, look: AppCelebrationLook = .current) {
        self.id = id
        self.startedAt = startedAt
        self.style = style
        self.look = look
        self.seed = id.uuidString.utf8.reduce(UInt64(0)) { $0 &* 31 &+ UInt64($1) }
    }

    var duration: Double {
        if look == .classic {
            return style == .burst ? AppMotion.Duration.burst : AppMotion.Confetti.classicLifetime + AppMotion.Confetti.classicStagger
        }
        return style == .burst ? AppMotion.Confetti.burstLifetime : AppMotion.Confetti.lifetime + AppMotion.Confetti.stagger
    }
    var endsAt: Date { startedAt.addingTimeInterval(duration) }
}

/// How a celebration looks. One renderer draws every look; production uses
/// `current`. The others stay for side-by-side review in the debug component
/// catalog (2026-10-23 confetti redesign).
enum AppCelebrationLook: String, CaseIterable, Identifiable, Hashable {
    /// Chunky lifting pieces (plates, dumbbells, checks, plus signs) in Unit blues and ink.
    case plates
    /// The same pieces and physics in a multi-color palette.
    case color
    /// Curled streamers mixed with plates.
    case ribbons
    /// The previous small capsules and checkmarks (baseline).
    case classic

    var id: String { rawValue }

    var title: String {
        switch self {
        case .plates: "Plates"
        case .color: "Color"
        case .ribbons: "Ribbons"
        case .classic: "Old"
        }
    }

    static let production: AppCelebrationLook = .plates

#if DEBUG
    /// Debug-only comparison override (component catalog chips, or the
    /// `-celebration-look <name>` launch argument used for recordings).
    static var debugOverride: AppCelebrationLook? = {
        let arguments = CommandLine.arguments
        guard let index = arguments.firstIndex(of: "-celebration-look"),
              arguments.indices.contains(index + 1) else { return nil }
        return AppCelebrationLook(rawValue: arguments[index + 1])
    }()
    static var current: AppCelebrationLook { debugOverride ?? production }
#else
    static var current: AppCelebrationLook { production }
#endif

    var palette: [Color] {
        switch self {
        case .color: AppColor.celebrationColor
        case .classic: AppMotion.Confetti.colors
        case .plates, .ribbons: AppColor.celebrationBrand
        }
    }
}

/// The single celebration renderer. All particles share one Canvas and clock.
/// Motion-disabled and VoiceOver users retain the saved result and its haptic.
struct AppCelebration: View {
    let moment: AppCelebrationMoment?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var landedID: UUID?

    private enum Piece: CaseIterable { case plate, dumbbell, check, plus, capsule, dot, ribbon }

    var body: some View {
        ZStack {
            if let moment, landedID != moment.id, moment.endsAt > .now,
               AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) {
                TimelineView(.animation) { timeline in
                    Canvas { context, size in
                        let elapsed = timeline.date.timeIntervalSince(moment.startedAt)
                        if moment.look == .classic {
                            drawClassic(moment, elapsed: elapsed, in: context, size: size)
                        } else {
                            draw(moment, elapsed: elapsed, in: context, size: size)
                        }
                    } symbols: {
                        AppIcon.checkmark.image(size: AppMotion.Confetti.classicPieceSize.height, weight: .bold)
                            .foregroundStyle(AppColor.accent)
                            .tag(0)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .task(id: moment?.id) {
            guard let moment else { return }
            let remaining = moment.endsAt.timeIntervalSinceNow
            if remaining > 0 {
                do { try await Task.sleep(for: .seconds(remaining)) }
                catch { return }
            }
            guard !Task.isCancelled else { return }
            landedID = moment.id
        }
    }

    // MARK: Physics renderer

    private func draw(_ moment: AppCelebrationMoment, elapsed: Double, in context: GraphicsContext, size: CGSize) {
        typealias C = AppMotion.Confetti
        let isBurst = moment.style == .burst
        let count = isBurst ? C.burstCount : (moment.style == .shower ? C.showerCount : C.popperCount)
        let palette = moment.look.palette

        if isBurst {
            // A soft ring marks the save before the pieces pop out of it.
            let ringProgress = min(1, max(0, elapsed / (C.burstLifetime * 0.55)))
            if ringProgress < 1 {
                let radius = C.ringStart + (C.ringEnd - C.ringStart) * (1 - pow(1 - ringProgress, 3))
                var ring = context
                ring.opacity = 0.55 * (1 - ringProgress)
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                ring.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(AppColor.accent), lineWidth: 3)
            }
        }

        for index in 0..<count {
            let sample = { (channel: Int) in C.sample(seed: moment.seed, index: index, channel: channel) }
            let lifetime = isBurst ? C.burstLifetime : C.lifetime
            let t = elapsed - (isBurst ? 0 : sample(0) * C.stagger)
            guard t >= 0, t < lifetime else { continue }

            // Launch point and velocity (screen y grows downward).
            var origin: CGPoint
            var velocity: CGVector
            if isBurst {
                origin = CGPoint(x: size.width / 2, y: size.height / 2)
                let angle = (Double(index) + sample(1) * 0.6) / Double(count) * .pi * 2
                let speed = C.burstSpeed.lowerBound + (C.burstSpeed.upperBound - C.burstSpeed.lowerBound) * sample(2)
                velocity = CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed)
            } else {
                let fromLeft = index.isMultiple(of: 2)
                origin = CGPoint(x: fromLeft ? -8 : size.width + 8, y: size.height + 12)
                let spread = (C.launchSpreadDegrees.lowerBound + (C.launchSpreadDegrees.upperBound - C.launchSpreadDegrees.lowerBound) * sample(1)) * .pi / 180
                let speed = (C.launchSpeed.lowerBound + (C.launchSpeed.upperBound - C.launchSpeed.lowerBound) * sample(2))
                    * min(1.15, max(0.75, size.height / 874))
                velocity = CGVector(dx: (fromLeft ? 1 : -1) * sin(spread) * speed, dy: -cos(spread) * speed)
            }
            if moment.look == .ribbons, moment.style == .shower, index.isMultiple(of: 3) {
                // Ribbons also rain from the top on a first workout.
                origin = CGPoint(x: sample(1) * size.width, y: -20)
                velocity = CGVector(dx: (sample(2) - 0.5) * 80, dy: 60)
            }

            // Linear drag with gravity: fast launch, slow fluttering fall.
            let drag = C.drag * (0.8 + 0.4 * sample(5)) * (isBurst ? 1.6 : 1)
            let gravity = C.gravity * (isBurst ? 0.6 : 1)
            let decay = 1 - exp(-drag * t)
            var x = origin.x + velocity.dx / drag * decay
            let y = origin.y + gravity / drag * t + (velocity.dy - gravity / drag) / drag * decay
            if !isBurst {
                let swayAmplitude = 8 + 14 * sample(6)
                x += sin(t * (3 + 3 * sample(7)) + sample(8) * .pi * 2) * swayAmplitude * min(1, t / 0.9)
            }

            // 3D flip: squash one axis and shade the back face.
            let flip = cos(t * (5 + 7 * sample(9)) + sample(10) * .pi * 2)
            let spin = (sample(11) - 0.5) * 12
            let pieceRange = isBurst ? C.burstPieceSize : C.pieceSize
            let side = pieceRange.lowerBound + (pieceRange.upperBound - pieceRange.lowerBound) * sample(12)
            let fade = isBurst ? 1 - pow(t / lifetime, 2) : min(1, (lifetime - t) / C.fadeOut)

            // Pieces pop to full size as they leave the cannon.
            let pop = 0.55 + 0.45 * min(1, t / C.popIn)
            var particle = context
            particle.opacity = max(0, fade) * (flip < 0 ? 0.78 : 1)
            particle.addFilter(.shadow(color: AppColor.textPrimary.opacity(0.12), radius: 1.5, x: 0, y: 1))
            particle.translateBy(x: x, y: y)
            particle.rotate(by: .radians(sample(13) * .pi * 2 + spin * t))
            particle.scaleBy(x: pop, y: pop * max(0.14, abs(flip)))
            let color = palette[Int(sample(14) * Double(palette.count)) % palette.count]
            fill(piece(for: moment.look, burst: isBurst, roll: sample(15)), side: side, color: color, in: &particle)
        }
    }

    private func piece(for look: AppCelebrationLook, burst: Bool, roll: Double) -> Piece {
        if burst { return roll < 0.45 ? .plus : (roll < 0.8 ? .plate : .dot) }
        if look == .ribbons {
            return roll < 0.5 ? .ribbon : (roll < 0.75 ? .plate : .capsule)
        }
        switch roll {
        case ..<0.30: return .plate
        case ..<0.48: return .check
        case ..<0.62: return .plus
        case ..<0.74: return .dumbbell
        case ..<0.90: return .capsule
        default: return .dot
        }
    }

    private func fill(_ piece: Piece, side: Double, color: Color, in context: inout GraphicsContext) {
        let s = side
        switch piece {
        case .plate:
            var path = Path(ellipseIn: CGRect(x: -s / 2, y: -s / 2, width: s, height: s))
            path.addEllipse(in: CGRect(x: -s * 0.17, y: -s * 0.17, width: s * 0.34, height: s * 0.34))
            context.fill(path, with: .color(color), style: FillStyle(eoFill: true))
        case .dumbbell:
            var path = Path(roundedRect: CGRect(x: -s * 0.5, y: -s * 0.08, width: s, height: s * 0.16), cornerRadius: s * 0.08)
            path.addRoundedRect(in: CGRect(x: -s * 0.62, y: -s * 0.3, width: s * 0.24, height: s * 0.6), cornerSize: CGSize(width: s * 0.08, height: s * 0.08))
            path.addRoundedRect(in: CGRect(x: s * 0.38, y: -s * 0.3, width: s * 0.24, height: s * 0.6), cornerSize: CGSize(width: s * 0.08, height: s * 0.08))
            context.fill(path, with: .color(color))
        case .check:
            var path = Path()
            path.move(to: CGPoint(x: -s * 0.38, y: s * 0.02))
            path.addLine(to: CGPoint(x: -s * 0.1, y: s * 0.3))
            path.addLine(to: CGPoint(x: s * 0.4, y: -s * 0.28))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: s * 0.22, lineCap: .round, lineJoin: .round))
        case .plus:
            var path = Path(roundedRect: CGRect(x: -s * 0.14, y: -s * 0.45, width: s * 0.28, height: s * 0.9), cornerRadius: s * 0.14)
            path.addRoundedRect(in: CGRect(x: -s * 0.45, y: -s * 0.14, width: s * 0.9, height: s * 0.28), cornerSize: CGSize(width: s * 0.14, height: s * 0.14))
            context.fill(path, with: .color(color))
        case .capsule:
            context.fill(Path(roundedRect: CGRect(x: -s * 0.22, y: -s * 0.55, width: s * 0.44, height: s * 1.1), cornerRadius: s * 0.22), with: .color(color))
        case .dot:
            context.fill(Path(ellipseIn: CGRect(x: -s * 0.32, y: -s * 0.32, width: s * 0.64, height: s * 0.64)), with: .color(color))
        case .ribbon:
            var path = Path()
            path.move(to: CGPoint(x: -s * 0.2, y: -s * 0.9))
            path.addQuadCurve(to: CGPoint(x: 0, y: 0), control: CGPoint(x: s * 0.5, y: -s * 0.5))
            path.addQuadCurve(to: CGPoint(x: s * 0.2, y: s * 0.9), control: CGPoint(x: -s * 0.5, y: s * 0.5))
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: s * 0.24, lineCap: .round))
        }
    }

    // MARK: Previous renderer (comparison baseline)

    private func drawClassic(_ moment: AppCelebrationMoment, elapsed: Double, in context: GraphicsContext, size: CGSize) {
        typealias C = AppMotion.Confetti
        let count = moment.style == .burst ? AppMotion.burstDots : (moment.style == .shower ? C.count : C.classicPopperCount)
        for index in 0..<count {
            if moment.style == .burst {
                let progress = min(1, max(0, elapsed / AppMotion.Duration.burst))
                guard progress < 1 else { continue }
                let angle = Double(index) / Double(count) * .pi * 2
                let distance = AppMotion.burstStart + (AppMotion.burstEnd - AppMotion.burstStart) * progress
                let side = AppMotion.burstDot * (1 - (1 - AppMotion.burstShrink) * progress)
                let point = CGPoint(x: size.width / 2 + cos(angle) * distance, y: size.height / 2 + sin(angle) * distance)
                var particle = context
                particle.opacity = 1 - progress
                particle.fill(Path(ellipseIn: CGRect(x: point.x - side / 2, y: point.y - side / 2, width: side, height: side)), with: .color(AppColor.accent))
                continue
            }
            let sample = { (channel: Int) in C.sample(seed: moment.seed, index: index, channel: channel) }
            let local = elapsed - sample(0) * C.classicStagger
            guard local >= 0, local < C.classicLifetime else { continue }
            let progress = local / C.classicLifetime
            let x: Double
            let y: Double
            if moment.style == .shower {
                x = sample(1) * size.width + (sample(2) - 0.5) * C.spread * progress
                y = -C.classicPieceSize.height + (size.height + C.classicPieceSize.height * 2) * progress
            } else {
                x = size.width / 2 + (sample(1) - 0.5) * C.spread * 2 * (1 - pow(1 - progress, 3))
                y = size.height / 3 - sin(progress * .pi) * C.rise + progress * progress * C.fall
            }
            var particle = context
            particle.opacity = min(1, (1 - progress) * 4)
            particle.translateBy(x: x, y: y)
            particle.rotate(by: .radians((sample(3) - 0.5) * .pi * 4 * progress))
            if index.isMultiple(of: 3), let check = particle.resolveSymbol(id: 0) {
                particle.draw(check, at: .zero)
            } else {
                let piece = C.classicPieceSize
                particle.fill(Path(roundedRect: CGRect(x: -piece.width / 2, y: -piece.height / 2, width: piece.width, height: piece.height), cornerRadius: piece.width / 2), with: .color(C.colors[index % C.colors.count]))
            }
        }
    }
}

/// Canonical row separator. 1pt hairline at `AppColor.border.opacity(0.55)` —
/// the same value the active-workout lineup hand-rolled before consolidation.
/// Used by `AppDividedList` (and a handful of card-row contexts that compose
/// rows by hand). Spans the full width of its container. Row content owns
/// its padding; separator owners must remain outside those content insets.
struct AppDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppColor.border.opacity(0.55))
            .frame(maxWidth: .infinity)
            .frame(height: 1)
    }
}

/// Shared card elevation — no-op now that elevation is fill-contrast-only.
/// Per DESIGN.md §4 (Flat-By-Default Rule), Bond cards separate from the Milk
/// page through the 6.25% lightness step alone. No stroke, no shadow — both
/// fight the flat doctrine. Retained as a stable extension point so callers
/// (`AppCard`, `appCardStyle`, `appCardElevation()`) keep a single chrome
/// pivot if a future variant ever needs lift (e.g. card over photographic
/// onboarding background). Today it intentionally renders flat.
private struct AppCardElevation: ViewModifier {
    var cornerRadius: CGFloat = AppRadius.lg

    func body(content: Content) -> some View {
        content
    }
}

/// Sheet-hosted input field chrome — no-op now that elevation is contrast-only.
/// Retained as a stable extension point if a future variant ever needs to lift
/// inputs (e.g. sheet stacking). Today it intentionally renders flat.
private struct AppInputElevation: ViewModifier {
    let enabled: Bool

    func body(content: Content) -> some View {
        content
    }
}

/// Workout logging surface — same chrome as `AppCard`: Bond fill + continuous
/// corner clip, no stroke (Flat-By-Default Rule, DESIGN.md §4). `AppCard` is
/// the canonical card; this exists only because the workout panel composes
/// its own internal layout (hairline divider between metric and timer) and
/// can't pass through `AppCard`'s VStack-of-content pattern.
private struct AppWorkoutPanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
    }
}

/// SF Symbol catalog as role-named cases. Always invoke via `.image(size:weight:)`
/// so icons across the app share the same stroke weight. Navigation disclosure
/// uses `forward` through the shared row owner (user direction, 2026-10-19).
///
/// `back` + `forward` are a paired set — both chevrons so the visual rhythm
/// reads as one nav control. The earlier `arrow.right` for `.forward` paired
/// awkwardly with `chevron.left` (chevron + straight arrow = inconsistent
/// pair, the only call site is the History calendar month nav). The
/// raw-glyph ban keeps feature code on the canonical icon/row API.
/// Navigation disclosures are explicitly approved as of 2026-10-19.
nonisolated enum AppIcon: String, Sendable {
    case back = "chevron.left"
    case forward = "chevron.right"
    case chevronDown = "chevron.down"
    case chevronUp = "chevron.up"
    case close = "xmark"
    case add = "plus"
    case remove = "minus"
    case edit = "pencil"
    case more = "ellipsis"
    case undo = "arrow.uturn.backward"
    case trash = "trash"
    case swap = "arrow.triangle.2.circlepath"
    case search = "magnifyingglass"
    case program = "square.and.pencil"
    case todayTab = "dumbbell.fill"
    case settings = "gearshape.fill"
    case settingsOutline = "gearshape"
    case checkmarkFilled = "checkmark.circle.fill"
    case checkmark = "checkmark"
    case xmarkFilled = "xmark.circle.fill"
    case play = "play.fill"
    case pause = "pause.fill"
    case list = "list.bullet"
    case bell = "bell.fill"
    case calendarClock = "calendar.badge.clock"
    case bolt = "bolt.fill"
    case chart = "chart.line.uptrend.xyaxis"
    case addCircle = "plus.circle.fill"
    case sliders = "slider.horizontal.3"
    case photo = "photo"
    case dumbbell = "dumbbell"
    case trophy = "trophy"
    case starFilled = "star.fill"
    case reorder = "line.3.horizontal"
    case camera = "camera"
    case clipboard = "doc.on.clipboard"
    case keyboard = "keyboard"
    case minusCircle = "minus.circle"
    case circle = "circle"
    case scalemass = "scalemass"
    case info = "info.circle"
    case squat = "figure.strengthtraining.functional"
    case deadlift = "figure.strengthtraining.traditional"
    case climbing = "figure.climbing"
    case core = "figure.core.training"

    // Original movement artwork: approved custom fallback after the library benchmark.
    case liftSquat = "unit.lift.squat"
    case liftBench = "unit.lift.bench"
    case liftDeadlift = "unit.lift.deadlift"
    case liftOverhead = "unit.lift.overhead"
    case liftRow = "unit.lift.row"
    case liftPullup = "unit.lift.pullup"

    var isMovementAsset: Bool { rawValue.hasPrefix("unit.lift.") }
    var systemName: String { isMovementAsset ? AppIcon.deadlift.rawValue : rawValue }

    @MainActor func image(size: CGFloat = 17, weight: Font.Weight = .semibold, maximumScale: CGFloat? = nil) -> some View {
        Glyph(icon: self, size: size, weight: weight, maximumScale: maximumScale)
    }

    /// One renderer for movement vectors and native control symbols.
    @MainActor private struct Glyph: View {
        let icon: AppIcon
        let size: CGFloat
        let weight: Font.Weight
        let maximumScale: CGFloat?
        @ScaledMetric(relativeTo: .body) private var scale = 1.0

        var body: some View {
            let pointSize = size * min(scale, maximumScale ?? .greatestFiniteMagnitude)
            Group {
                if icon.isMovementAsset, let asset = movementAsset {
                    Image(uiImage: asset).renderingMode(.template).resizable().scaledToFit()
                        .frame(width: pointSize, height: pointSize)
                } else if maximumScale != nil {
                    // Wide exercise figures stay inside the shared tile's glyph box.
                    Image(systemName: icon.systemName).resizable().scaledToFit()
                        .font(.system(size: pointSize, weight: weight))
                        .frame(width: pointSize, height: pointSize)
                } else {
                    Image(systemName: icon.systemName)
                        .font(.system(size: pointSize, weight: weight))
                }
            }.symbolRenderingMode(.monochrome)
        }
        private var movementAsset: UIImage? {
            let asset = UIImage(named: icon.rawValue)
            assert(asset != nil, "Missing movement artwork: \(icon.rawValue)")
            return asset
        }
    }
}

/// Semantic icon sizes for standalone symbols that carry hierarchy rather
/// than sitting inside a control or icon circle.
enum AppIconSize {
    static let compact: CGFloat = 14
    static let indicator: CGFloat = 12
    static let readiness: CGFloat = 16
    static let reward: CGFloat = 20
    static let exercise: CGFloat = 20
    static let exerciseDetail: CGFloat = 28
    static let exerciseDetailTile: CGFloat = 44
}

extension Double {
    /// Editable weight text: up to 2 decimals (so a 61.25 kg target is not
    /// shown as 61.3), trailing zeros dropped, "." as the mark; input fields
    /// swap in the phone's mark. Rounds first: pounds are stored as converted
    /// kilograms, so 155 lb comes back as 154.99999. Display text uses
    /// `WorkoutTargetFormatter.weightNumber`.
    var weightString: String {
        let rounded = (self * 100).rounded() / 100
        if rounded == rounded.rounded() { return "\(Int(rounded))" }
        let text = String(format: "%.2f", rounded)
        return text.hasSuffix("0") ? String(text.dropLast()) : text
    }
}

// MARK: - Haptics

/// Seven tactile intents. Secondary links, ordinary rows, typing and scrolling
/// stay quiet. Both trigger modifiers and imperative gestures use scene admission.
enum AppHaptic: CaseIterable, Equatable, Sendable {
    case select, tap, lift, firm, success, warning, error

    var strength: Int {
        switch self {
        case .select: 0
        case .tap, .lift: 1
        case .firm: 2
        case .success, .warning: 3
        case .error: 4
        }
    }

    var feedback: SensoryFeedback {
        switch self {
        case .select: .selection
        case .tap: .impact(weight: .light)
        case .lift: .impact(flexibility: .soft)
        case .firm: .impact(weight: .medium)
        case .success: .success
        case .warning: .warning
        case .error: .error
        }
    }

    /// Gestures use the active scene; declarative controls supply their own scene.
    /// No scene means silence, including previews. Haptics remain on with accessibility.
    @MainActor
    func fire(in scene: AppFeedbackState? = nil) {
        guard (scene ?? AppFeedbackState.activeScene)?.admitHaptic(self) == true else { return }
        switch self {
        case .select: UISelectionFeedbackGenerator().selectionChanged()
        case .tap: UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .lift: UIImpactFeedbackGenerator(style: .soft).impactOccurred()
        case .firm: UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .success: UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning: UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error: UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

/// Scene-local admission, shared by all control and outcome delivery paths.
@MainActor
final class AppFeedbackState {
    // Avoid the isolated-deinit back-deployment crash on iOS 18.
    // This state owns no resources requiring main-actor teardown.
    nonisolated deinit {}

    static weak var activeScene: AppFeedbackState?
    static let repeatWindow: Duration = .milliseconds(80)
    private(set) var isActive = false
    private(set) var lastHaptic: AppHaptic?
    private var lastHapticTime: ContinuousClock.Instant?
    var clock: () -> ContinuousClock.Instant = { .now }

    func setActive(_ active: Bool) {
        isActive = active
        lastHaptic = nil
        lastHapticTime = nil
        if active { Self.activeScene = self }
        else if Self.activeScene === self { Self.activeScene = nil }
    }

    func admitHaptic(_ intent: AppHaptic) -> Bool {
        guard isActive else { return false }
        let now = clock()
        if let lastHaptic, let lastHapticTime,
           now - lastHapticTime < Self.repeatWindow,
           intent.strength <= lastHaptic.strength { return false }
        lastHaptic = intent
        lastHapticTime = now
        return true
    }
}

extension EnvironmentValues {
    @Entry var appFeedback: AppFeedbackState? = nil
}

/// Owns admission for one WindowGroup root, including presented sheets.
private struct AppFeedbackScene: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @State private var feedback = AppFeedbackState()

    func body(content: Content) -> some View {
        content
            .environment(\.appFeedback, feedback)
            .onAppear { feedback.setActive(scenePhase == .active) }
            .onChange(of: scenePhase) { _, phase in feedback.setActive(phase == .active) }
            .onDisappear { feedback.setActive(false) }
    }
}

/// The trigger path intentionally calls the same player as imperative gestures.
private struct AppHapticModifier<Trigger: Equatable>: ViewModifier {
    @Environment(\.appFeedback) private var feedback
    @Environment(\.isEnabled) private var isEnabled
    let intent: AppHaptic
    let trigger: Trigger
    let condition: (Trigger, Trigger) -> Bool

    func body(content: Content) -> some View {
        content.onChange(of: trigger) { old, new in
            guard isEnabled, condition(old, new), let feedback else { return }
            intent.fire(in: feedback)
        }
    }
}

extension View {
    func appFeedbackScene() -> some View { modifier(AppFeedbackScene()) }

    func appHaptic<T: Equatable>(
        _ haptic: AppHaptic,
        trigger: T,
        condition: @escaping (T, T) -> Bool = { _, _ in true }
    ) -> some View {
        modifier(AppHapticModifier(intent: haptic, trigger: trigger, condition: condition))
    }
}

// MARK: - Molecules

/// Standard list row — optional leading icon, title, secondary subtitle, and a
/// trailing slot. **Chevron-free by design**: never add `.forward` as a disclosure
/// glyph; let context + tap target convey navigation (HIG).
/// Use `.tappable` (default) for interactive rows — gets 44pt minHeight and a
/// hit-testable content shape. Use `.display` for read-only catalog rows inside
/// a shared card — balanced 12pt vertical breathing and no 44pt floor so
/// multi-row catalog blocks stay comfortably scannable. Use `.cardListContent`
/// only inside `AppCardList`; the list owns the row insets and minimum height,
/// while `AppListRow` supplies the icon + text hierarchy.
enum AppListRowStyle {
    case tappable
    case display
    case cardListContent
}

struct AppListRow<Trailing: View>: View {
    /// `.action` is a row that runs something in place (no chevron), so its
    /// title is blue like every text button. Rows that open a screen keep a
    /// black title and the disclosure chevron.
    enum Tone {
        case `default`
        case action
    }

    let title: String
    let subtitle: String?
    let leadingIcon: AppIcon?
    var style: AppListRowStyle = .tappable
    var showsDisclosure: Bool = false
    var tone: Tone = .default
    @ViewBuilder let trailing: () -> Trailing
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        style: AppListRowStyle = .tappable,
        showsDisclosure: Bool = false,
        tone: Tone = .default,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.style = style
        self.showsDisclosure = showsDisclosure
        self.tone = tone
        self.trailing = trailing
    }

    private var titleColor: Color {
        guard tone == .action else { return AppFont.body.color }
        return isEnabled ? AppColor.accent : AppColor.textDisabled
    }

    var body: some View {
        // At accessibility sizes the trailing value moves under the title
        // instead of squeezing beside it (Apple: fewer columns as text grows).
        let stacks = dynamicTypeSize.isAccessibilitySize
        let layout = stacks
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: AppSpacing.xs))
            : AnyLayout(HStackLayout(spacing: AppSpacing.sm))
        layout {
            if let leadingIcon {
                leadingIcon.image(size: 15, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.body.font)
                    .foregroundStyle(titleColor)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppFont.muted.color)
                } else if style == .display {
                    // Read-only program rows reserve the real subtitle line so
                    // titles and targets keep one consistent scanning rhythm.
                    // Hidden text still follows Dynamic Type without adding an
                    // accessibility announcement or imposing a clipping height.
                    Text("Reserved detail")
                        .font(AppFont.muted.font)
                        .hidden()
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !stacks {
                Spacer(minLength: 0)
            }

            trailing()
        }
        .appNavigationDisclosure(showsDisclosure)
        .padding(.horizontal, horizontalInset)
        .padding(.vertical, verticalInset)
        .frame(minHeight: minimumHeight, alignment: .leading)
        .contentShape(Rectangle())
    }

    /// Only free-standing tappable rows own the 16pt gutter. Display and
    /// card-list rows sit in containers that already provide it.
    private var horizontalInset: CGFloat {
        style == .tappable ? AppSpacing.md : 0
    }

    private var verticalInset: CGFloat {
        switch style {
        case .tappable:
            return AppSpacing.md
        case .display:
            return AppSpacing.smd
        case .cardListContent:
            return 0
        }
    }

    private var minimumHeight: CGFloat? {
        style == .tappable ? 44 : nil
    }
}

extension AppListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        style: AppListRowStyle = .tappable,
        showsDisclosure: Bool = false
    ) {
        self.init(title: title, subtitle: subtitle, leadingIcon: leadingIcon, style: style, showsDisclosure: showsDisclosure) {
            EmptyView()
        }
    }
}

/// Plain status/value accessory ("On this iPhone", "None", "kg") — renders
/// the trailing label at the same scale as the title in secondary color,
/// matching a native iOS Settings row. Use this in place of a hand-rolled
/// `Text(...).font(AppFont.muted.font)` trailing closure, which lands at
/// 13pt against the 17pt title and reads as undersized.
extension AppListRow where Trailing == AppListRowValueLabel {
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        style: AppListRowStyle = .tappable,
        showsDisclosure: Bool = false
    ) {
        self.init(title: title, subtitle: subtitle, leadingIcon: leadingIcon, style: style, showsDisclosure: showsDisclosure) {
            AppListRowValueLabel(value)
        }
    }
}

struct AppListRowValueLabel: View {
    private let value: String

    init(_ value: String) {
        self.value = value
    }

    var body: some View {
        Text(value)
            .font(AppFont.body.font)
            .foregroundStyle(AppColor.textSecondary)
            .monospacedDigit()
    }
}

/// Inline single-line decimal-pad weight field with its unit suffix ("kg" / "lb")
/// shown *inside* the field. The canonical weight input for onboarding, used by
/// the program-preview weight edit (`OnboardingProgramPreviewView`). Value and
/// unit sit together on a light inset fill (`cardRowFill`, the Milk recess used
/// for anything nested inside an `AppCard`, not the darker `controlBackground`
/// stepper gray that read as too dark on the white preview card). The fill alone
/// is deliberately reinforced by a pencil cue because the same field also sits
/// directly on sheet backgrounds where the recess can be visually subtle.
/// Keeping the suffix and edit cue inside the box makes "82 kg" read as one
/// editable value instead of static text floating detached to the right.
///
/// Empty state shows no placeholder digit: no em dash (a banned placeholder,
/// §4) and no bare "0" (reads as a real entered value, the sibling of the
/// banned "0 kg"). The filled surface plus the inline unit is the affordance.
/// The caller binds a plain string and owns any unit conversion (kg / lb) at
/// its boundary. Whole-number values (reps in Edit set) pass `.numberPad`.
struct AppInlineWeightField: View {
    @Binding var text: String
    let unitSuffix: String
    var accessibilityLabel: String = "Weight"
    var keyboardType: UIKeyboardType = .decimalPad
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            TextField("", text: $text)
                .keyboardType(keyboardType)
                .focused($isFocused)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityValue(text.isEmpty ? "Empty, \(unitSuffix)" : "\(text) \(unitSuffix)")

            Text(unitSuffix)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .accessibilityHidden(true)

            AppIcon.edit.image(size: 14, weight: .semibold)
                .foregroundStyle(isFocused ? AppColor.accent : AppColor.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.sm)
        .frame(width: 104)
        .frame(minHeight: 48)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .fill(AppColor.cardRowFill)
        )
        .contentShape(Rectangle())
        .onTapGesture { isFocused = true }
        .accessibilityHint("Double tap to edit")
        .toolbar {
            if isFocused {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(AppCopy.Nav.done) {
                        isFocused = false
                    }
                }
            }
        }
    }
}

/// − / value / + stepper — compact rounded control with 44pt hit targets.
/// Used for set counts, rest-duration seconds, reps, etc. Compact values use
/// the medium body baseline so editable numbers do not compete with labels;
/// prominent values retain the bold workout-numeric hierarchy. Value is a
/// pre-formatted string (monospaced digits) so callers own unit rendering
/// ("12 reps" vs "12").
struct AppStepper: View {
    enum Size {
        case compact
        case prominent
    }

    let value: String
    var size: Size = .compact
    var minimumValueWidth: CGFloat = 28
    var isDecrementEnabled: Bool = true
    var isIncrementEnabled: Bool = true
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    /// Phase counters drive `AppHaptic` so every ± tap fires the canonical
    /// stepper haptic without requiring callers to thread one through.
    /// `stepperIncrement` / `stepperDecrement` map to iOS 17's native
    /// `.increase` / `.decrease` semantic pair.
    @State private var incrementPhase: Int = 0
    @State private var decrementPhase: Int = 0

    var body: some View {
        HStack(spacing: controlSpacing) {
            stepButton(icon: .remove, isEnabled: isDecrementEnabled) {
                decrementPhase &+= 1
                onDecrement()
            }

            Text(value)
                .font(valueFont.font)
                .tracking(valueFont.tracking)
                .foregroundStyle(valueFont.color)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: minimumValueWidth)
                .appNumericValue(value: value)

            stepButton(icon: .add, isEnabled: isIncrementEnabled) {
                incrementPhase &+= 1
                onIncrement()
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, verticalPadding)
        .background(AppColor.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .appHaptic(.select, trigger: incrementPhase)
        .appHaptic(.select, trigger: decrementPhase)
    }

    private var valueFont: AppFont {
        switch size {
        case .compact: return .body
        case .prominent: return .numericDisplay
        }
    }

    private var controlSpacing: CGFloat {
        switch size {
        case .compact: return AppSpacing.sm
        case .prominent: return AppSpacing.xs
        }
    }

    private var verticalPadding: CGFloat {
        switch size {
        case .compact: return AppSpacing.xs
        case .prominent: return AppSpacing.sm
        }
    }

    private var buttonVisualSize: CGFloat {
        switch size {
        case .compact: return 36
        case .prominent: return 44
        }
    }

    private var iconSize: CGFloat {
        switch size {
        case .compact: return 14
        case .prominent: return 16
        }
    }

    private func stepButton(icon: AppIcon, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon.image(size: iconSize, weight: .semibold)
                .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textDisabled)
                .frame(width: buttonVisualSize, height: buttonVisualSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(icon == .remove ? "Decrease" : "Increase")
        .frame(minWidth: 44, minHeight: 44)
    }
}

/// Multi-line text input with a greyed-out placeholder shown when empty.
/// Canonical chrome for any free-form paragraph editor — never style a raw
/// `TextEditor` in a feature view. `TextField` already has native placeholder
/// support, so this atom exists specifically to give `TextEditor` parity.
///
/// Caller-applied modifiers (`.textInputAutocapitalization`, `.autocorrectionDisabled`,
/// `.focused`, etc.) propagate through the wrapper to the underlying `TextEditor`.
struct AppTextEditor: View {
    @Binding var text: String
    let placeholder: String
    var minHeight: CGFloat = 220
    /// Optional ceiling on the card's vertical size. Default `nil` keeps the
    /// historical behavior — the card sits at exactly `minHeight` and the
    /// inner UITextView scrolls internally for long pastes. Pass `.infinity`
    /// for screens whose body should be dominated by the editor (e.g. the
    /// onboarding paste step) so the card flexes to fill all available
    /// vertical space between its top sibling and whatever sits below it.
    /// Combine with a parent `VStack(... maxHeight: .infinity)` so the flex
    /// has somewhere to go.
    var maxHeight: CGFloat? = nil
    /// Optional parent-owned focus binding for screens that need to coordinate
    /// keyboard chrome or layout with this editor. The editor keeps its local
    /// focus state by default so existing callers remain unchanged.
    var focus: FocusState<Bool>.Binding? = nil

    /// Bound to the underlying `TextEditor` so the entire card surface — not
    /// just the inner UITextView's hit area — focuses on tap. Without this,
    /// padding around the TextEditor + the placeholder overlay leave dead
    /// zones where the user's tap visually lands on the input but does
    /// nothing (the OnboardingProgramImportView "input doesn't work" bug).
    @FocusState private var localFocus: Bool

    private var resolvedFocus: FocusState<Bool>.Binding {
        focus ?? $localFocus
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .scrollDismissesKeyboard(.interactively)
                .focused(resolvedFocus)
                .padding(AppSpacing.md)

            if text.isEmpty {
                Text(placeholder)
                    .font(AppFont.body.font)
                    // `textPlaceholder` mirrors UIKit's `UIColor.placeholderText` so this
                    // manual overlay matches every native `TextField` placeholder in the
                    // app (single canonical placeholder gray).
                    .foregroundStyle(AppColor.textPlaceholder)
                    // TextEditor's internal NSTextContainer inset is ~5pt horizontal,
                    // ~8pt vertical — offset the placeholder so it sits on the cursor.
                    .padding(.horizontal, AppSpacing.md + 5)
                    .padding(.top, AppSpacing.md + 8)
                    .allowsHitTesting(false)
            }
        }
        .frame(minHeight: minHeight, maxHeight: maxHeight, alignment: .topLeading)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        // Make the full card a hit target and route every tap to focus.
        // `contentShape` matches the visible clipped surface so taps in the
        // 16pt padding margin still register. Use `simultaneousGesture` (not
        // `onTapGesture`) so the inner `TextEditor`'s own focus-on-tap is
        // never pre-empted — when this card is nested inside a parent
        // `ScrollView`, a parent `onTapGesture` can swallow taps before the
        // underlying `UITextView` gets to claim them, leaving the field
        // visually hit but never focused. Setting `isFocused = true` on top
        // of `TextEditor`'s own focusing is idempotent.
        .contentShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .simultaneousGesture(TapGesture().onEnded { resolvedFocus.wrappedValue = true })
        .appCardElevation()
    }
}

/// Full-width filled CTA — the **single** dominant action on any Gym-Test screen.
/// Use inside `AppScreen(primaryButton:)` for sticky bottom CTAs, or inline for
/// in-card primaries. Never more than one on screen in core logging flows.
struct AppPrimaryButton: View {
    let label: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    /// A saved outcome replaces the label without changing the button’s layout.
    var isConfirmed: Bool = false
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.isEnabled) private var parentIsEnabled

    /// Bumped each time a disabled (not loading) tap is absorbed so
    /// `AppHaptic.error` fires. A silently-rejected primary CTA is the
    /// worst-of-both-worlds; a soft buzz tells the user the system saw the
    /// tap but the gate isn't passable. Pair with `disabledReason` on
    /// `PrimaryButtonConfig` to also explain *why*.
    @State private var disabledTapTrigger: Int = 0

    init(_ label: String, isEnabled: Bool = true, isLoading: Bool = false, isConfirmed: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.isConfirmed = isConfirmed
        self.action = action
    }

    private var effectiveEnabled: Bool { isEnabled && parentIsEnabled }
    private var isInteractive: Bool { effectiveEnabled && !isLoading && !isConfirmed }

    var body: some View {
        ZStack {
            Button(action: action) {
                ZStack {
                    Text(label)
                        .contentTransition(.opacity)
                        .animation(AppMotion.transition, value: label)
                        .font(AppFont.productAction.font)
                        .foregroundStyle(effectiveEnabled ? AppColor.accentForeground : AppColor.textDisabled)
                        .multilineTextAlignment(.center)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .opacity(isLoading || isConfirmed ? 0 : 1)
                        // Bind the fade at the layer itself. Conditional
                        // insertion/ancestor transactions cannot cut it short.
                        .animation(AppMotion.transition, value: isConfirmed)
                        .animation(AppMotion.transition, value: isLoading)
                        .animation(AppMotion.transition, value: effectiveEnabled)
                    AppIcon.checkmarkFilled.image(size: 24, weight: .semibold)
                        .symbolRenderingMode(.monochrome)
                        .foregroundStyle(effectiveEnabled ? AppColor.accentForeground : AppColor.textDisabled)
                        // Native monochrome circle fill leaves the tick cut out,
                        // revealing the button fill through its negative space.
                        .opacity(isConfirmed && !isLoading ? 1 : 0)
                        .scaleEffect(isConfirmed || !AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? 1 : AppMotion.leaveScale)
                        .animation(AppMotion.transition, value: isConfirmed)
                        .animation(AppMotion.transition, value: isLoading)
                        .accessibilityHidden(true)
                    if isLoading {
                        ProgressView()
                            .tint(effectiveEnabled ? AppColor.accentForeground : AppColor.textDisabled)
                            .transition(.opacity.animation(AppMotion.transition))
                    }
                }
                .animation(AppMotion.transition, value: isLoading)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background {
                    (effectiveEnabled ? AppColor.accent : AppColor.controlBackground)
                        .animation(AppMotion.transition, value: effectiveEnabled)
                }
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isInteractive)
            .accessibilityLabel(label)
            .accessibilityValue(isLoading ? Text("loading") : Text(isConfirmed ? "Saved" : ""))

            // Disabled-tap absorber: present only when the button is disabled
            // *and not loading*. Loading is a system-status state, not a user
            // gate, so we don't fire an error haptic for it. AccessibilityHidden
            // so VoiceOver still hears the underlying disabled button.
            if !effectiveEnabled && !isLoading {
                AppColor.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .contentShape(Rectangle())
                    .onTapGesture { disabledTapTrigger &+= 1 }
                    .accessibilityHidden(true)
            }
        }
        .appHaptic(.error, trigger: disabledTapTrigger)
    }
}

/// Filled secondary action with optional icon/detail. Shared by workout organisms
/// and supporting feature actions; primary commits use `AppPrimaryButton`.
struct AppSecondaryButton: View {
    enum Tone {
        case `default`
        case accentSoft
        case destructive
    }

    enum DetailAlignment {
        case leading
        case center
    }

    enum DetailLayout {
        case stacked
        case inline
    }

    let label: String
    var isEnabled: Bool = true
    @Environment(\.isEnabled) private var parentIsEnabled
    private var effectiveEnabled: Bool { isEnabled && parentIsEnabled }
    var icon: AppIcon? = nil
    var detail: String? = nil
    var detailAlignment: DetailAlignment = .leading
    var detailLayout: DetailLayout = .stacked
    var tone: Tone = .default
    var fillsAvailableWidth: Bool = true
    let action: () -> Void

    init(
        _ label: String,
        isEnabled: Bool = true,
        icon: AppIcon? = nil,
        detail: String? = nil,
        detailAlignment: DetailAlignment = .leading,
        detailLayout: DetailLayout = .stacked,
        tone: Tone = .default,
        fillsAvailableWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.isEnabled = isEnabled
        self.icon = icon
        self.detail = detail
        self.detailAlignment = detailAlignment
        self.detailLayout = detailLayout
        self.tone = tone
        self.fillsAvailableWidth = fillsAvailableWidth
        self.action = action
    }

    private var trimmedDetail: String? {
        guard let detail else { return nil }
        let t = detail.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }

    var body: some View {
        Button(action: action) {
            Group {
                if let trimmedDetail {
                    if detailLayout == .inline {
                        inlineDetailRow(trimmedDetail: trimmedDetail)
                    } else if detailAlignment == .center {
                        HStack(alignment: .center, spacing: AppSpacing.sm) {
                            Spacer(minLength: 0)
                            if let icon {
                                icon.image(size: 16, weight: .semibold)
                                    .foregroundStyle(foregroundColor)
                                    .animation(AppMotion.feedback, value: effectiveEnabled)
                            }
                            VStack(alignment: .center, spacing: AppSpacing.xxs) {
                                Text(label)
                                    .appNumericValue(value: label)
                                    .font(AppFont.productAction.font)
                                    .foregroundStyle(foregroundColor)
                                    .animation(AppMotion.feedback, value: effectiveEnabled)
                                Text(trimmedDetail)
                                    .appNumericValue(value: trimmedDetail)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(effectiveEnabled ? AppColor.textSecondary : AppColor.textDisabled)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                    .multilineTextAlignment(.center)
                            }
                            Spacer(minLength: 0)
                        }
                    } else {
                        HStack(alignment: .center, spacing: AppSpacing.sm) {
                            if let icon {
                                icon.image(size: 16, weight: .semibold)
                                    .foregroundStyle(foregroundColor)
                                    .animation(AppMotion.feedback, value: effectiveEnabled)
                            }
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(label)
                                    .appNumericValue(value: label)
                                    .font(AppFont.productAction.font)
                                    .foregroundStyle(foregroundColor)
                                    .animation(AppMotion.feedback, value: effectiveEnabled)
                                Text(trimmedDetail)
                                    .appNumericValue(value: trimmedDetail)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(effectiveEnabled ? AppColor.textSecondary : AppColor.textDisabled)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                } else {
                    HStack(alignment: .center, spacing: AppSpacing.sm) {
                        if let icon {
                            icon.image(size: 16, weight: .semibold)
                                .foregroundStyle(foregroundColor)
                                .animation(AppMotion.feedback, value: effectiveEnabled)
                        }
                        Text(label)
                            .appNumericValue(value: label)
                            .font(AppFont.productAction.font)
                            .foregroundStyle(foregroundColor)
                            .animation(AppMotion.feedback, value: effectiveEnabled)
                    }
                }
            }
            .padding(.horizontal, secondaryHorizontalPadding)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
            .frame(minHeight: 60)
            .background(backgroundColor.animation(AppMotion.feedback, value: effectiveEnabled))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
    }

    private var secondaryHorizontalPadding: CGFloat {
        if !fillsAvailableWidth {
            return AppSpacing.md
        }
        return trimmedDetail == nil ? 0 : AppSpacing.md
    }

    @ViewBuilder
    private func inlineDetailRow(trimmedDetail: String) -> some View {
        let detailColor = effectiveEnabled ? AppColor.textSecondary : AppColor.textDisabled
        let row = HStack(alignment: .center, spacing: AppSpacing.smd) {
            if let icon {
                icon.image(size: 16, weight: .semibold)
                    .foregroundStyle(foregroundColor)
                    .animation(AppMotion.feedback, value: effectiveEnabled)
            }
            Text(label)
                .appNumericValue(value: label)
                .font(AppFont.productAction.font)
                .foregroundStyle(foregroundColor)
                .animation(AppMotion.feedback, value: effectiveEnabled)
                .lineLimit(1)
            Text(trimmedDetail)
                .appNumericValue(value: trimmedDetail)
                .font(AppFont.productAction.font)
                .foregroundStyle(detailColor)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        if detailAlignment == .center {
            HStack {
                Spacer(minLength: 0)
                row
                Spacer(minLength: 0)
            }
        } else {
            row
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var foregroundColor: Color {
        guard effectiveEnabled else { return AppColor.textDisabled }
        switch tone {
        case .default: return AppColor.textPrimary
        case .accentSoft: return AppColor.accent
        case .destructive: return AppColor.error
        }
    }

    private var backgroundColor: Color {
        guard effectiveEnabled else {
            return tone == .destructive ? AppColor.clear : AppColor.controlBackground
        }
        switch tone {
        case .default: return AppColor.controlBackground
        case .accentSoft: return AppColor.controlBackground
        case .destructive: return AppColor.clear
        }
    }
}

/// Text-only action (no fill), blue like every text button so it reads as
/// tappable next to black body text (decision 2026-10-24). `.fullWidth` is a
/// centered row; `.inline` hugs its text for rows and section headers. Both
/// keep a ≥44pt hit area. Use inside `NavigationLink` labels or `Link`s too.
struct AppGhostButtonLabel: View {
    let title: String
    var isEnabled: Bool = true
    var layout: AppGhostButton.Layout = .fullWidth
    @Environment(\.isEnabled) private var parentIsEnabled
    private var effectiveEnabled: Bool { isEnabled && parentIsEnabled }

    var body: some View {
        Text(title)
            .font(layout == .inline ? AppFont.caption.font : AppFont.productAction.font)
            .foregroundStyle(effectiveEnabled ? AppColor.accent : AppColor.textDisabled)
            .multilineTextAlignment(.center)
            .frame(maxWidth: layout == .inline ? nil : .infinity)
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// Text-only quiet action (no fill, no stroke) — use for "Freestyle session",
/// "Skip", or any optional path that shouldn't compete with the primary CTA.
/// `.inline` is the same action at row size: "Edit", "Undo", "No thanks".
/// For disclosure link labels, use `AppGhostButtonLabel` directly.
struct AppGhostButton: View {
    enum Layout {
        case fullWidth
        case inline
    }

    let label: String
    var isEnabled: Bool = true
    var layout: Layout = .fullWidth
    let action: () -> Void

    init(_ label: String, isEnabled: Bool = true, layout: Layout = .fullWidth, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.layout = layout
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            AppGhostButtonLabel(title: label, isEnabled: isEnabled, layout: layout)
                .frame(minHeight: layout == .inline ? 44 : 60)
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
    }
}

/// Capsule-shaped floating action — scroll-aware affordance that hovers above
/// the page surface. Pair with `AppScreen(floatingAccessory:)` so the screen
/// owns scroll-direction show/hide; the atom itself stays stateless.
///
/// Two styles:
/// - `.accent` (default) — Accent fill, Paper text. Use when this is the page's
///   primary action (e.g. "Continue" floating over scroll content). The black
///   fill on a light surface carries its own contrast; no shadow needed.
/// - `.elevated` — Paper fill (`AppColor.cardBackground`) with Ink text. Use
///   when this is a secondary affordance that already sits above a primary
///   `AppPrimaryButton` in the same chrome (e.g. "Add exercise" above "Start
///   training" in onboarding) — keeps the black-fill weight unique to the
///   primary CTA so the two pills don't compete. Paper-on-Mist alone is too
///   close in value to read as detached, so this style picks up the canonical
///   `appFloatingShadow()` — the same two-layer recipe the `AppToast` pill
///   uses. The flat-card doctrine still applies to every non-floating surface;
///   only views that genuinely hover over scroll content get the shadow.
struct AppFloatingPillButton: View {
    enum Style {
        case accent
        case elevated
    }

    let label: String
    var icon: AppIcon? = nil
    var style: Style = .accent
    var isEnabled: Bool = true
    let action: () -> Void

    init(
        _ label: String,
        icon: AppIcon? = nil,
        style: Style = .accent,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) {
        self.label = label
        self.icon = icon
        self.style = style
        self.isEnabled = isEnabled
        self.action = action
    }

    private var foregroundColor: Color {
        switch style {
        case .accent:   AppColor.accentForeground
        case .elevated: AppColor.textPrimary
        }
    }

    private var fillColor: Color {
        switch style {
        case .accent:   AppColor.accent
        case .elevated: AppColor.cardBackground
        }
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                if let icon {
                    icon.image(size: 14, weight: .semibold)
                        .foregroundStyle(foregroundColor)
                }
                Text(label)
                    .font(AppFont.productAction.font)
                    .foregroundStyle(foregroundColor)
            }
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, AppSpacing.smd)
            .frame(minHeight: 48)
            .background(fillColor)
            .clipShape(Capsule(style: .continuous))
            .modifier(AppFloatingPillShadow(style: style))
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(label)
    }
}

/// Per-style shadow gate for `AppFloatingPillButton`. `.elevated` picks up the
/// canonical `appFloatingShadow()`; `.accent` stays flat (the Ink fill carries
/// its own contrast). Lifted out so the body stays declarative and the per-
/// style shadow rule lives next to the doc comment that explains it.
private struct AppFloatingPillShadow: ViewModifier {
    let style: AppFloatingPillButton.Style

    func body(content: Content) -> some View {
        switch style {
        case .accent:   content
        case .elevated: content.appFloatingShadow()
        }
    }
}

/// Ink "PR" chip: History rows, the workout summary, and logged sets during a
/// workout. One owner so every personal record reads the same.
@ViewBuilder
func historyPRTag() -> some View {
    AppTag(text: AppCopy.Workout.prTag, style: .ink, layout: .compactCapsule)
        .accessibilityLabel(AppCopy.Workout.personalRecord)
}

/// Static status/label pill — "Completed", "Up next", "Missed", "Day 3 of 5".
/// Use `.success` / `.warning` / `.error` for status; `.muted` / `.default` for
/// neutral labels; `.accent` to emphasize. For toggle-able filter pills, use
/// `AppFilterChip` — not this component.
///
/// Pass `onTap` to turn the tag into a compact tappable status affordance
/// without forking a new chip primitive. The visible capsule keeps its compact
/// size; the hit area expands invisibly to the 44pt Gym Test floor.
struct AppTag: View {
    let text: String
    var style: Style = .default
    /// `.compactCapsule` matches Paper today “Day n of m” (node 2P1-0) — short status pills inside cards.
    var layout: Layout = .regular
    /// Optional leading glyph rendered inline with the text (same foreground color).
    var icon: AppIcon? = nil
    /// When non-nil, the tag wraps in a Button with ScaleButtonStyle and a 44pt
    /// invisible hit floor. Visible chrome is unchanged.
    var onTap: (() -> Void)? = nil

    enum Layout {
        case regular
        case compactCapsule
    }

    enum Style {
        case `default`
        case accent
        case ink
        case success
        case warning
        case error
        case muted
        case custom(fg: Color, bg: Color)
    }

    var body: some View {
        if let onTap {
            Button(action: onTap) {
                tagShape
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            tagShape
        }
    }

    @ViewBuilder
    private var tagShape: some View {
        switch layout {
        case .regular:
            content
                .padding(.horizontal, AppSpacing.smd)
                .padding(.vertical, AppSpacing.sm)
                .background(backgroundColor)
                .clipShape(Capsule(style: .continuous))
        case .compactCapsule:
            content
                .padding(.horizontal, AppProgressChipMetrics.compactHorizontalPadding)
                .frame(minHeight: AppProgressChipMetrics.rowHeight)
                .background(backgroundColor)
                .clipShape(Capsule(style: .continuous))
        }
    }

    private var content: some View {
        HStack(spacing: AppSpacing.xs) {
            if let icon {
                icon.image(size: 12, weight: .semibold)
            }
            Text(text)
                .appCapsLabel(isEmphasized ? .overlineStrong : .overline)
        }
        .foregroundStyle(foregroundColor)
    }

    /// Filled / colored-background styles render the label in mono BOLD caps;
    /// neutral styles use mono medium caps. This mirrors the chip-state rule —
    /// a colored background IS the "selected" affordance for status pills.
    private var isEmphasized: Bool {
        switch style {
        case .default, .muted, .custom: return false
        case .accent, .ink, .success, .warning, .error: return true
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .default: return AppColor.textPrimary
        case .accent: return AppColor.accentForeground
        case .ink: return AppColor.cardBackground
        case .success: return AppColor.successOnSoft
        case .warning: return AppColor.warningOnSoft
        case .error: return AppColor.errorOnSoft
        case .muted: return AppColor.textSecondary
        case .custom(let fg, _): return fg
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .default: return AppColor.controlBackground
        case .accent: return AppColor.accent
        case .ink: return AppColor.textPrimary
        case .success: return AppColor.successSoft
        case .warning: return AppColor.warningSoft
        case .error: return AppColor.errorSoft
        case .muted: return AppColor.controlBackground
        case .custom(_, let bg): return bg
        }
    }
}

/// Capsule dropdown chip — pairs a label with a trailing `chevron.down` and wraps
/// the provided menu `content` in an iOS-native `Menu`. Use when a filter has
/// more than ~3 mutually-exclusive values, where a row of `AppFilterChip` toggles
/// would overflow; the native menu gives automatic checkmarks and dismissal.
///
/// Justification vs. extending `AppFilterChip`: filter chips are binary toggles
/// (one action, one selected state). A dropdown chip renders N-option menus and
/// owns no action itself — conflating the two would muddy both APIs. Selection
/// styling (inverted fill when `isActive`) mirrors `AppFilterChip` so the two
/// atoms compose in the same row without visual drift.
struct AppDropdownChip<Content: View>: View {
    let label: String
    var isActive: Bool = false
    @ViewBuilder let content: () -> Content

    var body: some View {
        Menu {
            content()
        } label: {
            HStack(spacing: AppSpacing.xs) {
                Text(label)
                    .font(AppFont.caption.font)
                    .appNumericValue(value: label)
                AppIcon.chevronDown.image(size: 10, weight: .bold)
            }
            .modifier(AppFilterChipSurface(isSelected: isActive))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? .isSelected : [])
    }
}

/// Toggleable capsule chip for filter bars (Exercises list, Program library, History)
/// and segmented pickers (onboarding day strip). Selected state inverts to
/// `textPrimary` fill with `background` foreground — the canonical "active pill"
/// recipe for Unit. Not for status labels — use `AppTag` there.
///
/// Two optional trailing affordances:
/// - `showsClearGlyphWhenSelected`: trailing `×` when selected, signals "tap to clear".
/// - `showsTrailingDot`: small status dot regardless of selection — used by the
///   onboarding day picker to flag days that still need exercises. Dot inverts
///   color in the selected state so it stays visible against the dark fill.
struct AppFilterChip: View {
    let label: String
    let isSelected: Bool
    /// Show an `×` to the right of the label when selected — used on History where
    /// tapping a selected chip clears the filter. Filter bars that reset via a
    /// dedicated "All" pill should leave this false.
    var showsClearGlyphWhenSelected: Bool = false
    /// Show a small status dot at the trailing edge regardless of selection state.
    /// Used by the onboarding day picker to flag days with no exercises yet.
    var showsTrailingDot: Bool = false
    let action: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Text(label)
                    .font(AppFont.caption.font)
                if isSelected && showsClearGlyphWhenSelected {
                    AppIcon.close.image(size: 10, weight: .bold)
                        .transition(.opacity.animation(AppMotion.feedback))
                }
                if showsTrailingDot {
                    Circle()
                        .fill(isSelected ? AppColor.background : AppColor.warning)
                        .frame(width: 6, height: 6)
                }
            }
            .appAnimation(.appPress, value: isSelected, reduceMotion: reduceMotion)
            .modifier(AppFilterChipSurface(
                isSelected: isSelected,
                hasClearGlyph: isSelected && showsClearGlyphWhenSelected
            ))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(
            showsClearGlyphWhenSelected && isSelected ? "Tap to clear filter" : "Tap to filter"
        )
    }
}

/// Private chrome shared by menu and toggle chips; interaction stays with each owner.
private struct AppFilterChipSurface: ViewModifier {
    let isSelected: Bool
    var hasClearGlyph = false
    @Environment(\.isEnabled) private var isEnabled

    func body(content: Content) -> some View {
        content
            .animation(AppMotion.feedback) { label in
                label.foregroundStyle(isEnabled
                    ? (isSelected ? AppColor.background : AppColor.textPrimary)
                    : AppColor.textDisabled)
            }
            .padding(.leading, AppSpacing.smd)
            .padding(.trailing, hasClearGlyph ? AppSpacing.sm : AppSpacing.smd)
            .padding(.vertical, AppSpacing.sm)
            .frame(minHeight: 44)
            .background {
                Capsule(style: .continuous)
                    .fill(isEnabled && isSelected ? AppColor.textPrimary : AppColor.controlBackground)
                    .animation(AppMotion.feedback, value: isSelected)
                    .animation(AppMotion.feedback, value: isEnabled)
            }
            .contentShape(Rectangle())
    }
}

/// Canonical horizontal filter-chip strip — one `ScrollView(.horizontal)` with
/// `AppSpacing.xs` between chips and `appScrollEdgeSoft()` at the leading/trailing
/// edges so chips fade rather than sharp-cut. Use anywhere a row of
/// `AppFilterChip` toggles or `AppDropdownChip` menus needs to scroll
/// horizontally (Program library, Exercises list, History). Single source of
/// truth for chip-bar chrome — never re-roll a `ScrollView { HStack { chips } }`
/// inline in a feature view.
///
/// `contentInset` only adds horizontal padding to the chip strip itself.
/// Default `0` for bars hosted inside `AppScreen` (which already provides 16pt
/// outer padding via `paddedMainContent`). Pass `AppSpacing.md` (16pt) for bars
/// hosted in containers without outer padding (e.g. a `List` row with
/// `listRowInsets(EdgeInsets())`).
struct AppFilterChipBar<Content: View>: View {
    var contentInset: CGFloat = 0
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.xs) {
                content()
            }
            .padding(.horizontal, contentInset)
            .padding(.vertical, AppSpacing.xxs)
        }
        .appScrollEdgeSoft()
        // iOS 18+ horizontal `ScrollView` (made worse by `.scrollEdgeEffectStyle`)
        // reports an *unbounded* ideal width. When this molecule is hosted inside
        // `.safeAreaInset(.top)` (e.g. `OnboardingShell`'s sticky day picker), the
        // unbounded measurement leaks through the parent VStack and silently
        // cancels `AppScreen`'s canonical 16pt horizontal padding for the entire
        // screen — header, body, and bottom CTA all snap to x=0 / x=screen-width.
        //
        // `.frame(maxWidth: .infinity)` alone does NOT fix it: it only constrains
        // the actual proposed size, never the ideal that propagates upward.
        // `.fixedSize(horizontal: false, vertical: true)` alone does NOT fix it
        // either: it selects which axis uses the ideal, but the unbounded ideal
        // is still what gets reported when a parent consults it.
        // `idealWidth: 0` is the load-bearing piece — it pins this view's
        // reported ideal width to 0pt, so any ancestor measuring the bar sees a
        // finite value and the leak stops at this molecule. `maxWidth: .infinity`
        // keeps the bar free to fill its parent's actual proposal.
        .frame(idealWidth: 0, maxWidth: .infinity)
    }
}

/// Pill-shaped header action (48pt icon square or 60pt-min text label) used
/// inside `ProductTopBar`. The visible tap area replaces floating text headers
/// so every header action has a clear hit target.
private struct ProductTopBarAction: View {
    enum Content {
        case text(String)
        case icon(AppIcon)
    }

    let content: Content
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                switch content {
                case .text(let label):
                    Text(label)
                        .font(AppFont.productAction.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minWidth: 60, minHeight: 48)

                case .icon(let icon):
                    icon.image(size: 16, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(width: 48, height: 48)
                        .background(AppColor.controlBackground)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                }
            }
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

/// Root/product-screen top bar — title + optional leading/trailing actions on a
/// 64pt surface. Compose via `AppScreen(customHeader:)`. Detail flows use system
/// `NavigationStack` chrome. Use `AppSheetScreen` when a modal should match iOS
/// native sheet title/action behavior.
struct ProductTopBar: View {
    enum Size {
        case md
        case large
    }

    struct ActionItem: Identifiable {
        enum Kind {
            case text(String)
            case icon(AppIcon)
        }

        let id = UUID()
        let kind: Kind
        let action: () -> Void

        static func text(_ label: String, action: @escaping () -> Void) -> ActionItem {
            ActionItem(kind: .text(label), action: action)
        }

        static func icon(_ icon: AppIcon, action: @escaping () -> Void) -> ActionItem {
            ActionItem(kind: .icon(icon), action: action)
        }
    }

    let title: String
    var size: Size = .large
    var leadingAction: ActionItem? = nil
    var trailingActions: [ActionItem] = []

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            if let leadingAction {
                ProductTopBarAction(content: content(for: leadingAction.kind), action: leadingAction.action)
            }

            Text(title)
                .font(titleFont)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .tracking(AppFont.productHeading.tracking)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: AppSpacing.sm) {
                ForEach(trailingActions) { item in
                    ProductTopBarAction(content: content(for: item.kind), action: item.action)
                }
            }
        }
        .frame(minHeight: 64)
    }

    private var titleFont: Font {
        switch size {
        case .md: return AppFont.productHeading.font
        case .large: return AppFont.productHeading.font
        }
    }

    private func content(for kind: ActionItem.Kind) -> ProductTopBarAction.Content {
        switch kind {
        case .text(let label):
            return .text(label)
        case .icon(let icon):
            return .icon(icon)
        }
    }
}

/// Set-step tracker inside `WorkoutCommandCard`. Renders the current set as a
/// filled capsule ("Set 2"), completed/failed sets as readable `kg × rep` chips, and
/// upcoming sets as numbered circles. Used only in active workout flows.
struct SetProgressIndicator: View {
    struct Step: Identifiable {
        enum State: Hashable {
            case upcoming
            case current
            case completed
            case failed
            case disabled
        }

        let id: Int
        let label: String
        let state: State
        var reps: Int? = nil
        var weightText: String? = nil
        /// Marks a completed step that beat the prior all-time best for this exercise
        /// (computed in `ActiveWorkoutView.completeSet`). The chip flips to success
        /// chrome so the milestone persists for the rest of the session, sharing
        /// the set's single success haptic at log time.
        var isPR: Bool = false
        /// True while this chip's set is the subject of an open edit sheet
        /// (`AdjustResultSheet` in `.edit` mode). Renders a slightly darker
        /// chip background so the strip behind the sheet communicates which
        /// set is being modified, even when the current-set accent pill sits
        /// further down the strip. PR chips keep their success fill — the PR
        /// signal outranks the edit affordance.
        var isEditing: Bool = false
        /// Tap handler for completed/failed chips — opens the edit sheet for that set
        /// in `ActiveWorkoutView`. Honored only when state is `completed` or `failed`;
        /// upcoming/current/disabled chips are never interactive (no values to edit).
        /// Pass `nil` for read-only contexts (previews, history).
        var onTap: (() -> Void)? = nil

        var chipText: String? {
            guard let reps, let weightText, !weightText.isEmpty else { return nil }
            return WorkoutTargetFormatter.compactMetricSpacing("\(weightText) × \(reps)")
        }
    }

    let steps: [Step]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // One hierarchy at every width: adding a logged-value chip must not
        // replace a fitted row with a different ScrollView mid-animation.
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                chipRow
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            .frame(height: 44)
            .onChange(of: steps.map(\.state)) { _, _ in
                guard let nextID = steps.first(where: { $0.state == .current })?.id
                    ?? steps.last(where: { $0.state == .completed || $0.state == .failed })?.id else { return }
                withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: UIAccessibility.isVoiceOverRunning) ? AppMotion.collectionChange : nil) {
                    proxy.scrollTo(nextID, anchor: .center)
                }
            }
        }
    }

    private var chipRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(steps) { step in
                renderStep(step)
                    .id(step.state)
                    .transition(AsymmetricTransition(
                        insertion: AppBlurTransition(),
                        removal: AppBlurTransition(scales: true)
                    ).animation(AppMotion.collectionChange))
                    .id(step.id)
            }
        }
        .appAnimation(AppMotion.collectionChange, value: steps.map(\.state), reduceMotion: reduceMotion)
        .appAnimation(AppMotion.collectionChange, value: steps.map(\.chipText), reduceMotion: reduceMotion)
    }

    /// Tap-edit on a logged chip is the only interaction in the strip — wrap it in a
    /// `Button` (which auto-applies the `isButton` trait) and inflate the hit area
    /// to 44pt to meet the gym-test touch-target floor. Every state reserves
    /// that same invisible hit-area height; the first log must not grow the row
    /// from 24pt to 44pt and push the entire timer downward.
    @ViewBuilder
    private func renderStep(_ step: Step) -> some View {
        if (step.state == .completed || step.state == .failed), let onTap = step.onTap {
            Button(action: onTap) {
                stepContent(step)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(accessibilityLabel(for: step))
            .accessibilityHint("Edits this set.")
            .accessibilityAddTraits(.isButton)
        } else {
            stepContent(step)
                .frame(minHeight: 44)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(accessibilityLabel(for: step))
        }
    }

    @ViewBuilder
    private func stepContent(_ step: Step) -> some View {
        if step.state == .current {
            Text("Set \(step.label)")
                .font(AppFont.stepIndicator.font)
                .textCase(.uppercase)
                .foregroundStyle(AppColor.accentForeground)
                .padding(.horizontal, AppSpacing.smd)
                .frame(height: 24)
                .background(Capsule(style: .continuous).fill(AppColor.accent))
        } else if (step.state == .completed || step.state == .failed),
                  let chipText = step.chipText {
            HStack(spacing: AppSpacing.xxs) {
                if step.state == .completed {
                    AppIcon.checkmark.image(size: 10, weight: .bold)
                } else {
                    AppIcon.remove.image(size: 10, weight: .bold)
                }
                Text(chipText)
                    .appNumericValue(value: chipText)
                    .font(AppFont.stepIndicator.font)
                    .lineLimit(1)
            }
            .foregroundStyle(step.isPR ? AppColor.successOnSoft : AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .frame(height: 24)
            .background(Capsule(style: .continuous).fill(chipFill(for: step)))
            .animation(AppMotion.feedback, value: step.isPR)
            .animation(AppMotion.feedback, value: step.isEditing)
        } else {
            ZStack {
                Circle()
                    .fill(backgroundColor(for: step.state, isEditing: step.isEditing))
                    .frame(width: 24, height: 24)

                switch step.state {
                case .completed:
                    AppIcon.checkmark.image(size: 10, weight: .bold)
                        .foregroundStyle(AppColor.textPrimary)
                case .failed:
                    AppIcon.remove.image(size: 10, weight: .bold)
                        .foregroundStyle(AppColor.textPrimary)
                default:
                    Text(step.label)
                        .font(AppFont.stepIndicator.font)
                        .foregroundStyle(foregroundColor(for: step.state))
                }
            }
        }
    }

    private func chipFill(for step: Step) -> Color {
        if step.isPR { return AppColor.successSoft }
        return step.isEditing ? AppColor.controlBackgroundActive : AppColor.controlBackground
    }

    private func backgroundColor(for state: Step.State, isEditing: Bool = false) -> Color {
        switch state {
        case .current:
            return AppColor.accent
        case .disabled:
            return AppColor.background
        case .completed, .failed, .upcoming:
            return isEditing ? AppColor.controlBackgroundActive : AppColor.controlBackground
        }
    }

    private func foregroundColor(for state: Step.State) -> Color {
        switch state {
        case .current:
            return AppColor.accentForeground
        case .disabled:
            return AppColor.textSecondary
        case .completed, .failed, .upcoming:
            return AppColor.textSecondary
        }
    }

    private func accessibilityLabel(for step: Step) -> String {
        let detail = step.chipText.map { ", \($0)" } ?? ""
        let milestone = step.isPR ? ", personal record" : ""
        switch step.state {
        case .completed:
            return "Set \(step.label), completed\(detail)\(milestone)"
        case .failed:
            return "Set \(step.label), below target\(detail)"
        case .current:
            return "Set \(step.label), current"
        case .upcoming:
            return "Set \(step.label), upcoming"
        case .disabled:
            return "Set \(step.label), unavailable"
        }
    }
}

/// Rest countdown control — `-20` / central timer pill / `+20`. Sits inside
/// `SessionStateBar` (detached bottom sheet) or `WorkoutCommandCard` (inline).
/// `.ready` state drops the capsule so the transition to "done resting" reads
/// as a deliberate visual beat, not just a color change.
struct RestTimerControl: View {
    enum State: Equatable {
        case idle
        case running
        case paused
        case ready
        case disabled
    }

    let timeText: String
    var state: State = .running
    var onDecrease: (() -> Void)? = nil
    var onToggle: (() -> Void)? = nil
    var onIncrease: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            HStack(spacing: AppSpacing.lg) {
                adjustButton(
                    icon: .remove,
                    accessibilityLabel: "Decrease rest timer by 20 seconds",
                    action: onDecrease
                )

                Button(action: { onToggle?() }) {
                    // Keep one label hierarchy and one centre column when
                    // idle/paused becomes running; only its chrome crossfades.
                    timerCenterTapLabel
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(onToggle == nil || state == .disabled)
                .accessibilityLabel(timerAccessibilityLabel)

                adjustButton(
                    icon: .add,
                    accessibilityLabel: "Increase rest timer by 20 seconds",
                    action: onIncrease
                )
            }
        }
        .opacity(state == .disabled ? AppMotion.disabledOpacity : 1)
        .animation(AppMotion.transition, value: state)
    }

    private var timerCenterTapLabel: some View {
        HStack(spacing: AppSpacing.sm) {
            Text(timeText)
                .font(AppFont.numericDisplay.font)
                .tracking(AppFont.numericDisplay.tracking)
                .foregroundStyle(timerCenterForeground)
                .monospacedDigit()
                // Per-second countdown roll. iOS picks the changed digits and
                // fades them downward so the timer reads as deliberately
                // ticking instead of flickering. "Ready" is nonnumeric, so it
                // cross-fades instead of entering the numeric transition at
                // the exact moment the countdown completes.
                .contentTransition(timerContentTransition)
                .animation(.appReveal, value: timeText)

            if let indicatorIcon {
                indicatorIcon.image(size: 18, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .contentTransition(AppMotion.allowsSpatialMotion(reduceMotion: UIAccessibility.isReduceMotionEnabled, voiceOver: UIAccessibility.isVoiceOverRunning) ? .symbolEffect(.replace) : .opacity)
                    .transition(.opacity.animation(AppMotion.transition))
            }
        }
        .frame(minHeight: 60)
        .padding(.horizontal, AppSpacing.smd)
        .background {
            if showsTimerCapsule {
                Capsule(style: .continuous).fill(AppColor.cardRowFill)
                    .transition(.opacity.animation(AppMotion.transition))
            }
        }
    }

    private var timerContentTransition: ContentTransition {
        state == .ready || UIAccessibility.isReduceMotionEnabled || UIAccessibility.isVoiceOverRunning ? .opacity : .numericText(countsDown: true)
    }

    /// Quiet capsule fill for **idle / paused / disabled** so the affordance reads as
    /// tappable when not actively counting. Drops to plain text for **running** and **ready**:
    /// while running, the numeral is the hero of the screen (Beside-style isolation); when
    /// ready, the absence of chrome reads as a deliberate "done resting" beat.
    private var showsTimerCapsule: Bool {
        switch state {
        case .running, .ready:
            return false
        case .idle, .paused, .disabled:
            return true
        }
    }

    private var timerCenterForeground: Color {
        switch state {
        case .ready:
            return AppColor.textSecondary
        default:
            return AppColor.textPrimary
        }
    }

    private var timerAccessibilityLabel: String {
        switch state {
        case .idle:
            return timeText
        case .paused:
            return "\(timeText), paused"
        case .running:
            return "\(timeText), running"
        case .ready:
            return "\(timeText), ready"
        case .disabled:
            return "Timer unavailable"
        }
    }

    private var indicatorIcon: AppIcon? {
        switch state {
        case .idle, .paused:
            return .play
        case .running:
            return .pause
        case .ready, .disabled:
            return nil
        }
    }

    private func adjustButton(
        icon: AppIcon,
        accessibilityLabel: String,
        action: (() -> Void)?
    ) -> some View {
        Button(action: { action?() }) {
            icon.image(size: 26, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 60, height: 60)
                .background(AppColor.cardRowFill)
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(action == nil || state == .disabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(timeText)
    }
}

extension View {
    /// Shared trailing disclosure for a row/card label that opens a destination.
    /// Apply inside the button/link, before outer card chrome. Native List links
    /// already supply their own disclosure and must not receive this modifier.
    @ViewBuilder
    func appNavigationDisclosure(_ isPresented: Bool = true) -> some View {
        if isPresented {
            HStack(spacing: AppSpacing.md) {
                self.frame(maxWidth: .infinity, alignment: .leading)
                AppIcon.forward.image(size: AppIconSize.indicator, weight: .medium)
                    .foregroundStyle(AppColor.textTertiary)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        } else {
            self
        }
    }
}

// MARK: - PreviewListRow + PreviewListContainer

/// Shared row for preview lists inside cards. The default stacked layout keeps
/// the established title/subtitle hierarchy used by library and detail lists.
/// `compactInline` is reserved for recessed, capped previews: body-size title on
/// the left, body-size metadata on the right, and a comfortable 64pt row.
/// `identityFirst` gives the title the full row width, then places the complete
/// target and optional evidence beneath it. Use it when truncating the subject
/// would make a compact metric meaningless (Today exercise previews).
///
/// `isEmptyHint = true` softens the data line (caption font + secondary color)
/// for cold-start rows like "No prior sets".
struct PreviewListRow: View {
    enum Layout {
        case stacked
        case compactInline
        case identityFirst
    }

    let title: String
    let subtitle: String
    var supportingText: String? = nil
    var isEmptyHint: Bool = false
    var layout: Layout = .stacked

    /// Opt in only when the row opens another screen; read-only previews stay plain.
    var showsDisclosure: Bool = false
    var showsSeparator: Bool = false

    @ScaledMetric(relativeTo: .body) private var compactTwoLineRowHeight: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var identityFirstRowHeight: CGFloat = 80

    var body: some View {
        rowContent
            .appNavigationDisclosure(showsDisclosure)
            .padding(.horizontal, layout == .stacked ? 0 : AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) {
                if showsSeparator { AppDivider() }
            }
    }

    @ViewBuilder
    private var rowContent: some View {

        switch layout {
        case .stacked:
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)

                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(AppColor.textSecondary)
                if let supportingText, !supportingText.isEmpty {
                    Text(supportingText)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.sm)
            .frame(minHeight: 52)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)

        case .compactInline:
            HStack(alignment: supportingText == nil ? .firstTextBaseline : .top, spacing: AppSpacing.sm) {
                Text(title)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                    Text(subtitle)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)

                    if let supportingText, !supportingText.isEmpty {
                        Text(supportingText)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .monospacedDigit()
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .layoutPriority(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.md)
            .frame(minHeight: compactTwoLineRowHeight)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)

        case .identityFirst:
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(
                        isEmptyHint ? AppColor.textSecondary : AppColor.textPrimary
                    )
                    .monospacedDigit()
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                if let supportingText, !supportingText.isEmpty {
                    Text(supportingText)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.smd)
            .frame(minHeight: identityFirstRowHeight, alignment: .leading)
            .contentShape(Rectangle())
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    private var subtitleFont: Font {
        isEmptyHint ? AppFont.caption.font : AppFont.body.font
    }

    private var accessibilityLabel: String {
        [title, subtitle, supportingText]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

/// Scrollable, capped-height container for `PreviewListRow`s — used on Today hero
/// and in program active-card previews. Content up to `visibleItemLimit` is shown
/// in full. Overflow reveals the next row, flashes the native indicator,
/// and uses the canonical soft scroll edge so the affordance does not depend on
/// the transient indicator alone.
struct PreviewListContainer<Content: View>: View {
    let itemCount: Int
    let visibleItemLimit: Int
    var usesTwoLineRows: Bool = false
    @ViewBuilder let content: () -> Content

    @ScaledMetric(relativeTo: .body) private var rowHeight: CGFloat = 64
    @ScaledMetric(relativeTo: .body) private var twoLineRowHeight: CGFloat = 80

    private var overflows: Bool {
        itemCount > visibleItemLimit
    }

    /// Expanded rows can grow beyond their scaled estimate when a long name
    /// wraps. Keep their inner scroll available so Dynamic Type never turns
    /// the viewport cap into clipping.
    private var canScroll: Bool {
        overflows || usesTwoLineRows
    }

    private var viewportHeight: CGFloat {
        let visibleRows = min(max(itemCount, 0), max(visibleItemLimit, 0))
        let resolvedRowHeight = usesTwoLineRows ? twoLineRowHeight : rowHeight
        let fullRowsHeight = CGFloat(visibleRows) * resolvedRowHeight
        let overflowPeekHeight: CGFloat
        if overflows {
            // Keep the next row's title visible after centering its content;
            // a smaller peek would expose only blank inset or clipped glyphs.
            overflowPeekHeight = usesTwoLineRows
                ? resolvedRowHeight / 2
                : resolvedRowHeight / 2 + AppSpacing.smd
        } else {
            overflowPeekHeight = 0
        }
        return fullRowsHeight + overflowPeekHeight
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .scrollDisabled(!canScroll)
        .scrollIndicators(canScroll ? .visible : .hidden)
        .scrollIndicatorsFlash(onAppear: canScroll)
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: viewportHeight)
        .appScrollEdgeSoft()
    }
}

// MARK: - Organisms

/// Canonical card surface — Bond (`#FFFFFF`) fill on a Milk (`#F5F5F5`) page,
/// continuous corners at `AppRadius.lg` (22pt), no stroke, no shadow. Cards
/// lift through fill-value contrast alone (DESIGN.md §4 Flat-By-Default Rule).
/// The default chrome for any grouped surface. Use `.appCardStyle()` instead
/// when a wrapper type is awkward (e.g. applied to an existing VStack without
/// re-nesting). Never invent inline `.background(...).clipShape(...)` chrome.
struct AppCard<Content: View>: View {
    /// Shared 16pt content gutter. Rows use the same gutter through AppCardList;
    /// do not add a second horizontal inset around already padded rows.
    /// Zero is reserved for shared full-bleed compositions and dividers.
    var contentInset: CGFloat = AppSpacing.md
    /// Optional vertical override. When the card's content is a list whose rows
    /// already own vertical padding (e.g. `AppDividedList` of `AppListRow` /
    /// `PreviewListRow`), pass a smaller value here so the card chrome doesn't
    /// compound with the row padding and create asymmetric edge-vs-between
    /// spacing. `nil` (default) uses `contentInset` on all four sides — current
    /// behavior for non-list cards.
    var verticalInset: CGFloat? = nil
    /// Corner radius for clip + stroke; default matches `AppRadius.lg` cards app-wide.
    var cornerRadius: CGFloat = AppRadius.lg
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content()
        }
        .padding(.horizontal, contentInset)
        .padding(.vertical, verticalInset ?? contentInset)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .modifier(AppCardElevation(cornerRadius: cornerRadius))
    }
}

/// Selectable option tile used by onboarding steps that ask the lifter to pick
/// one path (unit, import method, program, etc.). A leading 40pt icon bubble is
/// optional; title, subtitle, selected state, and optional badge all share the
/// same card treatment. The caller decides whether selection auto-advances or
/// waits for a CTA.
///
/// This was previously `OnboardingOptionCard` in
/// `Unit/Features/Onboarding/OnboardingImportMethodView.swift`. Promoted to
/// the design system because two onboarding screens (`UnitPicker`,
/// `ImportMethod`) and any future step that needs the same affordance
/// should share one canonical molecule — never a feature-file fork.
///
/// Pass either `icon` (SF Symbol via `AppIcon`) or `iconText` (a short
/// glyph like `kg` / `lb`) — exactly one. `badge` is the optional accent
/// chip above the title (e.g. "New", "Recommended") so supporting copy
/// always keeps the card's full content width.
struct AppOptionTileCard: View {
    var icon: AppIcon? = nil
    var iconText: String? = nil
    let title: String
    var subtitle: String? = nil
    var badge: String? = nil
    var isSelected: Bool = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Re-entrancy guard. While the 50ms press-visibility hold is running,
    /// a second tap should no-op rather than queueing another navigation.
    /// Reset isn't strictly required because the step swap destroys the
    /// view, but resetting after `action()` keeps the card safe in the
    /// unlikely case the parent ignores the tap and the view stays mounted.
    @State private var isProcessingTap = false

    var body: some View {
        Button(action: handleTap) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                if icon != nil || iconText != nil {
                    iconBubble
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    if let badge {
                        AppTag(text: badge, style: .accent, layout: .compactCapsule)
                            .fixedSize(horizontal: true, vertical: false)
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(title)
                            .font(AppFont.sectionHeader.font)
                            .foregroundStyle(AppColor.textPrimary)

                        if let subtitle {
                            Text(subtitle)
                                .font(AppFont.muted.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .appCardStyle(isSelected: isSelected)
        }
        // Press feedback (opacity dim + accessible scale) is the
        // canonical system-level treatment on `ScaleButtonStyle`. Every
        // tappable atom in Unit uses the same style so onboarding cards,
        // CTAs, ghost buttons, and floating pills all flash the same way on
        // tap. Don't override here — fix at `ScaleButtonStyle` and the
        // whole product moves.
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .appAnimation(.appPress, value: isSelected, reduceMotion: reduceMotion)
    }

    private func handleTap() {
        guard !isProcessingTap else { return }
        isProcessingTap = true
        // Selection haptic fires at the same instant the press-state
        // animation begins (via `ScaleButtonStyle`). Visual + tactile
        // together so the tap feels received in two senses.
        AppHaptic.select.fire()
        // Hold the action by 50ms so a couple of frames of press-state dim
        // from `ScaleButtonStyle` register before the forward transition
        // slides the card fully off-screen and fades it
        // (`.move(.leading) + .opacity`, OnboardingView). 50ms sits below the
        // ~100ms threshold where a delay starts to read as latency (Nielsen),
        // so the step feels instant while the press still gets a moment. The
        // tap is already acknowledged on finger-down — this only keeps the dim
        // from being swallowed by the aggressive exit, it is not the feedback
        // itself. CTAs that stay in place (Continue, Read program) don't need
        // it — the press is visible during finger-down because nothing moves.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            action()
            isProcessingTap = false
        }
    }

    @ViewBuilder
    private var iconBubble: some View {
        AppIconCircle(
            diameter: 40,
            shape: .roundedRect(radius: AppRadius.md),
            surface: .accentSoft
        ) {
            Group {
                if let icon {
                    icon.image(size: 18, weight: .semibold)
                } else if let iconText {
                    Text(iconText)
                        .font(AppFont.stepIndicator.font)
                }
            }
            .foregroundStyle(AppColor.accent)
        }
    }
}

/// One read-only milestone in `AppTimeline`. Titles carry the time marker
/// (for example, `Day 0` or `Day 7`) while subtitles explain the outcome.
/// `isCurrent` is reinforced by both the filled icon well and VoiceOver's
/// current-value announcement, so the state never depends on colour alone.
struct AppTimelineItem: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let icon: AppIcon
    var isCurrent: Bool = false
    var isReward: Bool = false
}

/// Canonical connected milestone rail for short, read-only sequences such as
/// subscription timing. `AppCardList` remains the default for divided rows;
/// this separate organism exists because a timeline needs one continuous
/// vertical connector that survives multiline text and Dynamic Type.
struct AppTimeline: View {
    let items: [AppTimelineItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                let isHighlighted = item.isCurrent || item.isReward

                HStack(alignment: .top, spacing: AppSpacing.smd) {
                    AppIconCircle(
                        diameter: item.isReward ? AppSpacing.xxl : AppSpacing.xl,
                        surface: isHighlighted
                            ? .tinted(AppColor.accent, opacity: 1)
                            : .control
                    ) {
                        item.icon
                            .image(
                                size: item.isReward ? AppIconSize.reward : 14,
                                weight: .semibold
                            )
                            .foregroundStyle(
                                isHighlighted
                                    ? AppColor.accentForeground
                                    : AppColor.textSecondary
                            )
                    }
                    .frame(width: AppSpacing.xxl)
                    .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                        Text(item.title)
                            .contentTransition(.opacity)
                            .animation(AppMotion.feedback, value: item.title)
                            .font(item.isReward ? AppFont.title.font : AppFont.sectionHeader.font)
                            .foregroundStyle(AppColor.textPrimary)

                        Text(item.subtitle)
                            .contentTransition(.opacity)
                            .animation(AppMotion.feedback, value: item.subtitle)
                            .font(item.isReward ? AppFont.caption.font : AppFont.muted.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.bottom, index < items.count - 1 ? AppSpacing.xl : 0)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(item.title). \(item.subtitle)")
                .accessibilityValue(
                    item.isCurrent ? "Current" : (item.isReward ? "Ongoing benefit" : "")
                )
            }
        }
        .background(alignment: .leading) {
            if items.count > 1 {
                Rectangle()
                    .fill(AppColor.controlBackground)
                    .frame(width: AppSpacing.xxs)
                    .padding(.vertical, AppSpacing.md)
                    .offset(x: (AppSpacing.xxl - AppSpacing.xxs) / 2)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Canonical tier-selection card for the paywall (and any future "pick one of
/// N priced tiers" surface). Its regular-width layout is a compact comparison
/// row: plan identity and renewal detail stay together on the leading edge,
/// while the StoreKit price forms one stable trailing column. This preserves
/// the fast scan of a grouped pricing table without introducing a second page
/// or a separate pricing component. At large Dynamic Type sizes the row falls
/// back to a vertical layout instead of compressing or clipping price copy.
///
/// The selected state uses the shared `appCardStyle` fill, border, checkmark,
/// and accessibility trait, so selection never depends on colour alone.
///
/// Accessibility: the `.isSelected` trait fires on the underlying button so
/// VoiceOver announces the selected tier without an extra label hack.
struct AppSelectableTierCard: View {
    let label: String
    let price: String
    let sublabel: String
    var badge: String? = nil
    let isSelected: Bool
    var showsDetails: Bool = true
    var isEnabled: Bool = true
    var accessibilityHint: String = "Select this plan"
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Button(action: handleTap) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        planIdentity
                        priceLabel
                    }
                } else {
                HStack(alignment: .center, spacing: AppSpacing.md) {
                    planIdentity

                    Spacer(minLength: AppSpacing.sm)

                    priceLabel
                }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: AppSpacing.xxl)
            .padding(.vertical, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.smd)
            // Reserve the checkmark column for every state so selection never
            // changes text width or forces the price below the plan name.
            .padding(.trailing, AppSpacing.lg)
            .appCardStyle(
                contentInset: 0,
                cornerRadius: AppRadius.md,
                isSelected: isSelected
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityHint(isEnabled ? accessibilityHint : "This plan is unavailable")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        // Apply disabled state to the final combined accessibility element,
        // not only the button's child tree. VoiceOver and XCTest must both
        // announce unavailable products as non-interactive.
        .disabled(!isEnabled)
        // Animate only this card's selected chrome. Wrapping `action()` in
        // `withAnimation` leaked the transaction into the entire paywall,
        // momentarily reflowing the sticky CTA and clipping it on iPhone SE
        // when trial context changed.
        .appAnimation(.appPress, value: isSelected, reduceMotion: reduceMotion)
    }

    private func handleTap() {
        action()
    }

    private var planIdentity: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            // A badge too long for the row moves under the plan name
            // instead of pushing the card wider than the screen.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: AppSpacing.sm) {
                    planName
                    planBadge
                }
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    planName
                    planBadge
                }
            }

            if showsDetails {
                Text(sublabel)
                    .font(AppFont.muted.font)
                    .foregroundStyle(isEnabled ? AppColor.textSecondary : AppColor.textDisabled)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var planName: some View {
        Text(label)
            .font(AppFont.sectionHeader.font)
            .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textDisabled)
            .fixedSize(horizontal: true, vertical: true)
    }

    @ViewBuilder
    private var planBadge: some View {
        if let badge {
            AppTag(text: badge, style: .accent, layout: .compactCapsule)
                .fixedSize(horizontal: true, vertical: true)
        }
    }

    private var priceLabel: some View {
        Text(price)
            .font(AppFont.sectionHeader.font)
            .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textDisabled)
            .multilineTextAlignment(.trailing)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: true, vertical: true)
    }

    private var accessibilitySummary: String {
        [label, price, sublabel, badge]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

/// Session header row: eyebrow (date), title (template name), optional caption,
/// trailing status. No card chrome — use directly as a row inside `AppCardList`
/// (history list of sessions) or compose into `AppSessionHighlightCard` when a
/// single session needs its own elevated surface (missed-day card, earlier-week
/// catch-up). The row owns text hierarchy only; card/list chrome owns vertical
/// insets so captioned and non-captioned sessions share the same edge rhythm.
/// Single source of truth for the session header layout.
struct AppSessionHighlightRow<Trailing: View>: View {
    let eyebrow: String
    let title: String
    let caption: String?
    @ViewBuilder let trailing: () -> Trailing

    private var hasCaption: Bool {
        guard let caption else { return false }
        return !caption.isEmpty
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: hasCaption ? AppSpacing.sm : AppSpacing.xs) {
                Text(eyebrow)
                    .appCapsLabel(.overline)
                    .foregroundStyle(AppColor.textSecondary)

                Text(title)
                    .font(AppFont.title.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                if let caption, !caption.isEmpty {
                    Text(caption)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 0)

            trailing()
        }
    }
}

/// Session highlight as a single elevated card. Wraps `AppSessionHighlightRow`
/// in `AppCard` chrome and optionally appends extra detail beneath the header
/// (separated by an `AppDivider`) — used by the calendar summary sheet where
/// the session header is followed by a context note + per-exercise breakdown.
/// For lists of multiple sessions on a single surface, use
/// `AppSessionHighlightRow` inside `AppCardList` instead — never stack
/// per-row `AppSessionHighlightCard`s in a list (CLAUDE.md §5: no per-row
/// shadowed cards in lists).
///
/// Card chrome owns no padding (`contentInset: 0`, `verticalInset: 0`) so
/// every `AppDivider` — the header→body hairline AND any list dividers inside
/// `belowContent` — runs card-edge to card-edge, matching the full-bleed rule
/// shared with `AppCardList`.
///
/// **Caller contract for `belowContent`** (the slot is rendered full-bleed,
/// no horizontal or vertical wrapper padding):
/// - Floating chrome (notes, empty-state text) → wrap in
///   `.padding(.horizontal, .lg).padding(.vertical, .md)`.
/// - List rows inside an `AppDividedList` → apply `.appCardRowChrome()` to
///   each row. Dividers will then run full-width with uniform 16pt breathing
///   above and below every row.
///
/// Header rhythm: the highlight row uses the canonical `.appCardRowChrome()`
/// recipe (24pt horizontal, 16pt vertical, 52pt floor) so a lone session card
/// (e.g. the earlier-week catch-up row in History) and a session row inside
/// `AppCardList` (the History month list) share an identical vertical rhythm.
/// Forking padding here (e.g. 24pt vertical for the lone-card variant only)
/// produces the kind of parallel-implementation drift CLAUDE.md §4 bans.
struct AppSessionHighlightCard<Trailing: View, BelowContent: View>: View {
    let eyebrow: String
    let title: String
    let caption: String?
    @ViewBuilder let trailing: () -> Trailing
    @ViewBuilder let belowContent: () -> BelowContent

    private var hasBelowContent: Bool {
        BelowContent.self != EmptyView.self
    }

    var body: some View {
        AppCard(contentInset: 0, verticalInset: 0) {
            VStack(alignment: .leading, spacing: 0) {
                AppSessionHighlightRow(
                    eyebrow: eyebrow,
                    title: title,
                    caption: caption,
                    trailing: trailing
                )
                .appCardRowChrome()

                if hasBelowContent {
                    AppDivider()
                    belowContent()
                }
            }
        }
    }
}

/// Comfortable two-column feature matrix used by purchase surfaces that unlock
/// one complete product rather than a permanent free tier. The label column is
/// allowed to wrap at Dynamic Type sizes; Accessibility sizes collapse to one
/// column so feature identity never competes with density.
struct AppFeatureAccessTable: View {
    let rows: [String]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        AppCard(contentInset: AppSpacing.md, verticalInset: AppSpacing.md) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: AppSpacing.smd) {
                ForEach(Array(rows.enumerated()), id: \.offset) { index, label in
                    featureRow(label)
                        .accessibilityIdentifier("paywall-feature-row-\(index)")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("paywall-feature-table")
    }

    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(
            repeating: GridItem(.flexible(), spacing: AppSpacing.sm, alignment: .topLeading),
            count: count
        )
    }

    private func featureRow(_ label: String) -> some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            AppIcon.checkmarkFilled.image(size: AppIconSize.readiness, weight: .semibold)
                .foregroundStyle(AppColor.textPrimary)
                .accessibilityHidden(true)

            Text(label)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(label), included in Unit")
    }
}

extension AppSessionHighlightCard where BelowContent == EmptyView {
    init(
        eyebrow: String,
        title: String,
        caption: String?,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.caption = caption
        self.trailing = trailing
        self.belowContent = { EmptyView() }
    }
}

/// Each occurrence has its own identity, even when the words repeat.
struct AppToastEvent: Identifiable {
    enum Kind: Equatable { case information, success, error }
    let id: UUID
    let text: String
    let kind: Kind
    let action: AppToastAction?

    init(_ text: String, kind: Kind = .information, action: AppToastAction? = nil, id: UUID = UUID()) {
        self.id = id
        self.text = text
        self.kind = kind
        self.action = action
    }

    /// Consume only this occurrence. A stale timeout/action cannot consume its replacement.
    static func consume(_ id: UUID, from current: inout AppToastEvent?) -> AppToastEvent? {
        guard let occurrence = current, occurrence.id == id else { return nil }
        current = nil
        return occurrence
    }

    var duration: Double? {
        kind == .error ? nil : (action == nil ? AppMotion.Duration.toast : AppMotion.Duration.toastAction)
    }
}

/// The target identifies the exact reversible operation, never the message text.
struct AppToastAction {
    var id = UUID()
    let label: String
    let handler: () -> Void
}

/// Event-owned overlay: cancellation cannot clear a replacement message.
struct AppToast: ViewModifier {
    @Binding var event: AppToastEvent?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var announcedID: UUID?

    func body(content: Content) -> some View {
        content.overlay(alignment: .top) {
            ZStack {
                if let current = event {
                    AppToastPill(event: current, dismiss: { dismiss(current.id) }) {
                        // Consume before invoking: a second tap cannot replay the action,
                        // and a handler may safely publish a replacement event.
                        let action = AppToastEvent.consume(current.id, from: &event)?.action
                        action?.handler()
                    }
                    .id(current.id)
                    .transition(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
                        ? .move(edge: .top).combined(with: .opacity) : .opacity)
                    .task(id: current.id.uuidString + String(voiceOver)) {
                        if announcedID != current.id {
                            announcedID = current.id
                            AccessibilityNotification.Announcement(current.text).post()
                        }
                        guard !voiceOver, let duration = current.duration else { return }
                        do { try await Task.sleep(for: .seconds(duration)) }
                        catch { return }
                        guard !Task.isCancelled, !voiceOver else { return }
                        dismiss(current.id)
                    }
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.top, AppSpacing.xs)
            .animation(AppMotion.transition, value: event?.id)
            .allowsHitTesting(event != nil)
        }
    }

    private func dismiss(_ id: UUID) {
        _ = AppToastEvent.consume(id, from: &event)
    }
}

/// Wrapping text and full-sized actions remain readable at accessibility sizes.
private struct AppToastPill: View {
    let event: AppToastEvent
    let dismiss: () -> Void
    let performAction: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var markVisible = false
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: AppSpacing.sm) {
                message.fixedSize(horizontal: true, vertical: false)
                actionButton
                dismissButton
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .top, spacing: AppSpacing.sm) {
                    message
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    dismissButton
                }
                actionButton
            }
        }
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
        .background(AppColor.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .appFloatingShadow()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("toast")
        .task(id: event.id) {
            withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
                ? AppMotion.confirmSpring : AppMotion.feedback) {
                markVisible = true
            }
        }
    }

    private var message: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            if event.kind == .success {
                AppIcon.checkmark.image(size: AppIconSize.readiness, weight: .bold)
                    .foregroundStyle(AppColor.textPrimary)
                    .opacity(markVisible ? 1 : 0)
                    .scaleEffect(markVisible || !AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
                        ? 1 : AppMotion.markPopScale)
                    .accessibilityHidden(true)
            }
            Text(event.text)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
        }
    }

    @ViewBuilder private var actionButton: some View {
        if let action = event.action {
            Button(action: performAction) {
                Text(action.label)
                    .font(AppFont.productAction.font)
                    .foregroundStyle(AppColor.accent)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityIdentifier("toast-action")
        }
    }

    private var dismissButton: some View {
        Button(action: dismiss) {
            AppIcon.close.image(size: AppIconSize.readiness, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Dismiss message")
        .buttonStyle(ScaleButtonStyle())
    }
}

extension View {
    func appToast(event: Binding<AppToastEvent?>) -> some View {
        modifier(AppToast(event: event))
    }

    /// Two-layer drop shadow applied to surfaces that genuinely float over
    /// scroll content (the transient `AppToast` pill, the elevated
    /// `AppFloatingPillButton`). One large/diffuse shadow for lift, one tight
    /// shadow for edge definition. The flat-card doctrine still applies to
    /// every other surface — only views that need to read as detached from the
    /// page get this treatment.
    ///
    /// **Directional, not haloed.** `y == radius` on both layers so the
    /// shadow extends purely downward from the pill — no upward bleed. The
    /// earlier halo recipe (`radius: 20, y: 10`) reached ~10pt above the
    /// pill's top edge, which got hard-clipped by the iOS 26 navigation-bar
    /// Liquid Glass material whenever a top-mounted `AppToast` sat near the
    /// safe-area inset (visible on the onboarding "Add exercises" undo
    /// toast as a sharp horizontal cut along the toast's top edge). Matches
    /// the Apple-native floating-pill convention (Clipboard / "Copied")
    /// where the shadow lives beneath the object, not around it.
    func appFloatingShadow() -> some View {
        self
            .shadow(color: AppColor.textPrimary.opacity(0.14), radius: 14, x: 0, y: 14)
            .shadow(color: AppColor.textPrimary.opacity(0.06), radius: 2, x: 0, y: 2)
    }
}

/// Empty-state card. Two shapes share one molecule:
/// 1. **CTA-bearing** (`eyebrow` + `title` + `message` + `buttonLabel` + `action`) — for
///    features the user *can* fix from this screen (no program → "Create program").
/// 2. **Quiet** (`title` + `message`) — for screens where the missing data is created
///    elsewhere (History → "No sessions yet").
///
/// Compose inside `AppScreen`; don't rebuild a title+message card in-place when this
/// covers the shape. Per CLAUDE.md §5 (extend > create), variants live behind one
/// struct so list screens converge instead of forking.
struct EmptyStateCard<Content: View>: View {
    let eyebrow: String?
    let title: String
    /// Optional: one status line per state — omit when the title already
    /// says everything (minimal-language rule, 2026-07-13).
    let message: String?
    let note: String?
    let buttonLabel: String?
    let action: (() -> Void)?
    let content: () -> Content

    var body: some View {
        Group {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let eyebrow {
                    // Sentence case, like Today's "Up next": eyebrows can be
                    // a program name the lifter typed (decision 2026-10-24).
                    Text(eyebrow)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppColor.textSecondary)
                }

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppFont.productHeading.font)
                        .tracking(AppFont.productHeading.tracking)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if let message {
                        Text(message)
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.leading)
                    }

                    if let note {
                        Text(note)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textTertiary)
                            .multilineTextAlignment(.leading)
                    }
                }

                if Content.self != EmptyView.self {
                    content()
                }

                if let buttonLabel, let action {
                    AppPrimaryButton(buttonLabel, action: action)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.md)
        }
    }
}

extension EmptyStateCard where Content == EmptyView {
    /// CTA-bearing empty state (primary use — feature can be initiated here).
    init(eyebrow: String, title: String, message: String, buttonLabel: String, action: @escaping () -> Void) {
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.note = nil
        self.buttonLabel = buttonLabel
        self.action = action
        self.content = { EmptyView() }
    }

    /// Quiet empty state — title + message only, for screens where missing data is
    /// created elsewhere. Replaces hand-rolled `AppCard { VStack { Text + Text } }`.
    init(title: String, message: String) {
        self.eyebrow = nil
        self.title = title
        self.message = message
        self.note = nil
        self.buttonLabel = nil
        self.action = nil
        self.content = { EmptyView() }
    }

    /// CTA-bearing empty state without an eyebrow. `message` omitted = the
    /// title is the whole status line.
    init(title: String, message: String? = nil, buttonLabel: String, action: @escaping () -> Void) {
        self.eyebrow = nil
        self.title = title
        self.message = message
        self.note = nil
        self.buttonLabel = buttonLabel
        self.action = action
        self.content = { EmptyView() }
    }

    /// Hero variant without inline content or CTA — used by Today's rest-day card
    /// (eyebrow + title + subtitle, nothing else).
    init(eyebrow: String, title: String, message: String) {
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.note = nil
        self.buttonLabel = nil
        self.action = nil
        self.content = { EmptyView() }
    }
}

extension EmptyStateCard {
    /// Content-bearing empty state where the caller owns the full action block
    /// (for example, primary + secondary actions). Keeps the canonical empty-state
    /// card chrome without forcing the built-in single-primary CTA slot.
    init(
        title: String,
        message: String,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.eyebrow = nil
        self.title = title
        self.message = message
        self.note = nil
        self.buttonLabel = nil
        self.action = nil
        self.content = content
    }

    /// Hero variant with an inline content slot above the CTA — used by Today's
    /// "Up next" card to embed a tappable preview list. Optional `note:` renders
    /// a caption beneath the subtitle (e.g. "Different routine for today").
    init(
        eyebrow: String,
        title: String,
        message: String,
        note: String? = nil,
        buttonLabel: String,
        action: @escaping () -> Void,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.eyebrow = eyebrow
        self.title = title
        self.message = message
        self.note = note
        self.buttonLabel = buttonLabel
        self.action = action
        self.content = content
    }
}

/// Lightweight transient empty state — caption-sized message centered in a
/// card-chromed surface. Use when a filter or search has returned no results
/// (Program library "No programs match these filters", Exercises list search
/// empty, History filter empty). Distinct from `EmptyStateCard`, which is the
/// heavy cold-start treatment for "no data yet" with eyebrow + title + message
/// + CTA. `AppEmptyHint` carries no eyebrow, no title, no action — just a
/// quiet hint that the current filter/search produced nothing.
struct AppEmptyHint: View {
    private let message: String

    init(_ message: String) {
        self.message = message
    }

    /// Left-aligned on the page like `EmptyStateCard` (JOI rule: no
    /// centered boxed empty states).
    var body: some View {
        Text(message)
            .font(AppFont.caption.font)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.md)
    }
}

/// Canonical row-list primitive. Renders rows separated by a 1pt `AppDivider`
/// hairline. Use inside a shared `AppCard` (or `SettingsSection`) when rows
/// share a subject; for a list that owns its own card chrome, use the
/// `AppCardList` molecule instead. Dividers always span the full container
/// width; padding belongs to each row, never the separator.
struct AppDividedList<Data, ID, RowContent>: View
    where Data: RandomAccessCollection, ID: Hashable, RowContent: View
{
    let data: Data
    let id: KeyPath<Data.Element, ID>
    @ViewBuilder let content: (Data.Element) -> RowContent
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let items = Array(data)
        let firstID = items.first.map { $0[keyPath: id] }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items, id: id) { item in
                VStack(alignment: .leading, spacing: 0) {
                    if item[keyPath: id] != firstID {
                        AppDivider()
                    }
                    content(item)
                }
                .transition(AppBlurTransition(scales: true).animation(.appReveal))
            }
        }
        // Existing rows keep their state and slide to their new position. The
        // explicit row transition still fades when layout motion is disabled.
        .appAnimation(AppMotion.collectionChange, value: items.map { $0[keyPath: id] }, reduceMotion: reduceMotion)
    }
}

extension AppDividedList where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ data: Data,
        @ViewBuilder content: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.id = \.id
        self.content = content
    }
}

/// Canonical "list inside its own card" molecule. The card runs full-bleed
/// (`contentInset: 0`, `verticalInset: 0`) so the rows fully own their own
/// inset and the 1pt `AppDivider` hairlines extend card-edge to card-edge —
/// the documented full-width-of-container rule. Rows use the canonical 16/24
/// recipe by default: `AppSpacing.md` (16pt) vertically and `AppSpacing.lg`
/// (24pt) horizontally. Pass `rowVerticalInset: AppSpacing.lg` for setup rows
/// that contain stacked controls and need the same relaxed rhythm as Settings
/// rows. The molecule also enforces a 52pt minimum row height (matching
/// `PreviewListRow` / `AppCardListAddRow`) so single-line text rows never
/// collapse to a 44pt tap-target floor. Use this anywhere you'd otherwise
/// compose `AppCard` +
/// `AppDividedList` by hand — that combination is banned in feature code
/// (see CLAUDE.md §5 + `.claude/hooks/ui-banned-list.sh`).
///
/// Optional `trailing:` slot renders one extra divided row after the data
/// rows — typically an `AppCardListAddRow("Add X")` affordance, matching the
/// in-card add convention used elsewhere. The trailing row is preceded by an
/// `AppDivider` only when there is at least one data row, so the empty state
/// (just the add affordance) reads as one clean row.
///
/// For list content nested inside a `SettingsSection` or another `AppCard`
/// (which already provides card chrome), use `AppDividedList` directly — the
/// hairline divider is shared.
struct AppCardList<Data, ID, RowContent, Trailing>: View
    where Data: RandomAccessCollection, ID: Hashable, RowContent: View, Trailing: View
{
    private let data: Data
    private let id: KeyPath<Data.Element, ID>
    private let rowVerticalInset: CGFloat
    private let row: (Data.Element) -> RowContent
    private let trailing: () -> Trailing

    var body: some View {
        // Card chrome owns no padding (`contentInset: 0`, `verticalInset: 0`)
        // so `AppDivider` hairlines run card-edge to card-edge. Each row's
        // padding/frame recipe is applied via the canonical
        // `.appCardRowChrome()` modifier so any other card-hosted list (e.g.
        // `AppSessionHighlightCard.belowContent`) gets the same rhythm without
        // forking the recipe.
        AppCard(contentInset: 0, verticalInset: 0) {
            VStack(alignment: .leading, spacing: 0) {
                AppDividedList(data: data, id: id) { item in
                    row(item).appCardRowChrome(verticalInset: rowVerticalInset)
                }
                if Trailing.self != EmptyView.self {
                    if !data.isEmpty {
                        AppDivider()
                    }
                    trailing().appCardRowChrome(verticalInset: rowVerticalInset)
                }
            }
        }
        .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity, alignment: .leading)
    }
}

/// Canonical row chrome for content that sits as a row inside a card's
/// full-bleed `AppDividedList`. Layered as **frame-first, padding-second** so
/// caller content is reliably centered before outer breathing is added:
///
///   1. `fixedSize(vertical: true)` lets the inner take its natural vertical
///      size (not stretch).
///   2. Horizontal pad (24pt each side) for column inset.
///   3. `frame(minHeight: 52, alignment: .leading)` enforces the canonical
///      tap-target floor and *vertically centers* row content within it —
///      single-line `Text` / `TextField` get a guaranteed center.
///   4. Outer vertical padding adds the documented list-in-card breathing.
///      Tuned in two passes: 8 → 12 first, to recover breathing for multi-line
///      rows (the 52pt floor only centers single-line content; multi-line content
///      flows past the floor and only sees the outer pad), then 12 → 16 once
///      *taller* multi-line rows landed (header HStack + stepper HStack inside
///      one card row, e.g. the onboarding exercise card). At 12pt the bottom
///      edge of stacked controls visibly kissed the divider / card edge; at
///      16pt the row reads as breathing room rather than packed cargo. Control-heavy
///      setup rows can opt into 24pt via `AppCardList(rowVerticalInset:)`, matching
///      the more generous Settings row cadence.
///
/// Net visible spacing for any single-line row is identical above and below
/// the content — first / last rows match mid rows whether the boundary is a
/// card edge or an `AppDivider` hairline. Rows with taller content flow past
/// the 52pt floor; the wrapper never clamps them.
///
/// Use directly on row content inside an `AppDividedList` that runs full-bleed
/// inside a card (e.g. `AppCardList`, `AppSessionHighlightCard.belowContent`).
/// Never compose hand-rolled `.padding(.horizontal, .lg).padding(.vertical, .smd)`
/// stacks instead — this is the single source of truth.
private struct AppCardRowChrome: ViewModifier {
    var verticalInset: CGFloat = AppSpacing.md

    func body(content: Content) -> some View {
        content
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, AppSpacing.md)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.vertical, verticalInset)
            // The row chrome sits outside caller-owned Button/NavigationLink
            // labels. Declare the final padded rectangle as the hit-test
            // shape so blank space between leading and trailing content is
            // tappable, not just the rendered glyphs.
            .contentShape(Rectangle())
    }
}

extension View {
    /// Apply the canonical card-row recipe (16pt horizontal, 16pt vertical by default,
    /// 52pt min-height). Use `AppSpacing.lg` for relaxed setup rows with stacked controls.
    /// See `AppCardRowChrome` for layering rationale.
    func appCardRowChrome(verticalInset: CGFloat = AppSpacing.md) -> some View {
        modifier(AppCardRowChrome(verticalInset: verticalInset))
    }
}

extension AppCardList where Trailing == EmptyView {
    init(
        data: Data,
        id: KeyPath<Data.Element, ID>,
        rowVerticalInset: CGFloat = AppSpacing.md,
        @ViewBuilder row: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.id = id
        self.rowVerticalInset = rowVerticalInset
        self.row = row
        self.trailing = { EmptyView() }
    }
}

extension AppCardList where Data.Element: Identifiable, ID == Data.Element.ID, Trailing == EmptyView {
    init(
        _ data: Data,
        rowVerticalInset: CGFloat = AppSpacing.md,
        @ViewBuilder row: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.id = \.id
        self.rowVerticalInset = rowVerticalInset
        self.row = row
        self.trailing = { EmptyView() }
    }
}

extension AppCardList where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ data: Data,
        rowVerticalInset: CGFloat = AppSpacing.md,
        @ViewBuilder row: @escaping (Data.Element) -> RowContent,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.data = data
        self.id = \.id
        self.rowVerticalInset = rowVerticalInset
        self.row = row
        self.trailing = trailing
    }
}

/// Trailing affordance for an `AppCardList` — a "+ Add X" row that sits as
/// the final divided row of the list. Renders an accent-colored title beside
/// `addCircle`, matching the in-card add convention used in
/// `TemplateDetailView`. 52pt min-height aligns with `PreviewListRow` so the
/// rhythm reads uniform whether the list is empty or full. Place inside
/// `AppCardList(_:row:trailing:)`'s `trailing:` closure — never as a free
/// floating button below the card.
struct AppCardListAddRow: View {
    private let title: String
    private let icon: AppIcon
    private let action: () -> Void

    init(_ title: String, icon: AppIcon = .addCircle, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.sm) {
                icon.image()
                Text(title)
                    .font(AppFont.body.font)
                Spacer(minLength: 0)
            }
            .foregroundStyle(AppColor.accent)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Reorderable rows

/// Floating drag-preview chrome for rows that already use `appReorderable`.
/// This owns only the preview shell: reorder glyph, card fill, fixed preview
/// width, and minimum height. The row content stays at the call site so routine
/// rows and exercise rows can keep their own typography/trailing values.
struct AppReorderDragPreview<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            AppIcon.reorder.image(size: AppIconSize.readiness, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 44, alignment: .leading)

            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: 320, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColor.cardBackground)
        )
    }
}

/// Canonical drag-to-reorder row recipe. Apply to a row inside `AppCardList`
/// to make the **entire row** the drag affordance (not just a 44pt icon),
/// keep the source row legible while it floats, fire a medium-impact haptic on
/// lift, and render a custom Bond-fill pill as the floating preview. The source
/// deliberately stays at full opacity: SwiftUI can retain a stale drag identity
/// when a live-reordered destination moves beneath the pointer, and dimming the
/// full row in that state makes successfully moved content look disabled.
///
/// One canonical recipe — never hand-roll `.onDrag` on a sub-element of a
/// reorderable row. The "only the hamburger highlights, hard to grab" failure
/// mode is what this molecule exists to prevent.
///
/// Reduce Motion: drag-and-drop remains system-owned. Pair the call-site
/// `DropDelegate` with
/// `withAnimation(reduceMotion ? nil : .appConfirm) { ... }` for the swap.
///
/// Usage:
/// ```swift
/// rowContent
///     .appReorderable(
///         id: exercise.id,
///         draggedID: $draggedExerciseID,
///         reduceMotion: reduceMotion
///     ) {
///         ExerciseRowDragPreview(exercise: exercise)
///     }
/// ```
extension View {
    func appReorderable<Preview: View>(
        id: UUID,
        draggedID: Binding<UUID?>,
        reduceMotion: Bool,
        @ViewBuilder preview: @escaping () -> Preview
    ) -> some View {
        modifier(
            AppReorderableRow(
                id: id,
                draggedID: draggedID,
                reduceMotion: reduceMotion,
                preview: preview
            )
        )
    }
}

private struct AppReorderableRow<Preview: View>: ViewModifier {
    let id: UUID
    @Binding var draggedID: UUID?
    let reduceMotion: Bool
    let preview: () -> Preview

    func body(content: Content) -> some View {
        return content
            .onDrag {
                draggedID = id
                AppHaptic.lift.fire()
                return NSItemProvider(object: id.uuidString as NSString)
            } preview: {
                preview()
            }
    }
}

/// Expand/collapse card — chevron-toggled header above an optional body.
/// Default chrome is `AppCard`-style fill with a smaller `AppRadius.md` corner
/// so it nests cleanly inside other cards (`WorkoutCommandCard` neighbour, etc.).
/// Pass `cornerRadius: AppRadius.lg` for a top-level disclosure card; default
/// `md` is right for nested usage. Header content lays out to the leading edge;
/// the chevron is appended automatically and rotates 180° on expand.
///
/// Animation is owned here — call sites do not need to wrap `isExpanded.toggle()`
/// in `withAnimation`. Reduce Motion is honored via `appAnimation`.
struct AppDisclosureCard<Header: View, Content: View>: View {
    @Binding var isExpanded: Bool
    var cornerRadius: CGFloat = AppRadius.md
    @ViewBuilder let header: () -> Header
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    header()
                    Spacer(minLength: 0)
                    AppIcon.chevronDown.image(size: 13, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .appAnimation(.appState, value: isExpanded, reduceMotion: reduceMotion)
                }
                // Header padding matches the canonical disclosure spec in Figma
                // (node 344-23): lg (24pt) sides, md (16pt) top/bottom. The 24pt
                // sides line the collapsed title up with the expanded exercise
                // rows below (`appCardRowChrome` is also lg); the 16pt vertical
                // (was sm/8pt) un-cramps the container height into a taller tap
                // target — the airy row rhythm the rest of the cards already use.
                .padding(.horizontal, AppSpacing.lg)
                .padding(.vertical, AppSpacing.md)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())

            if isExpanded {
                content()
                    .transition(AppBlurTransition().animation(.appReveal))
            }
        }
        .appAnimation(.appState, value: isExpanded, reduceMotion: reduceMotion)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(AppColor.cardBackground)
        )
    }
}

/// Active-workout hero — set progress strip + exercise name + metric hero +
/// primary "Log set" CTA, with an optional rest-timer strip at the bottom.
/// This is the central surface of `ActiveWorkoutView`; never build a page-local
/// command panel to replace it. Timer strip is hidden when `timerValue == nil`.
struct WorkoutCommandCard: View {
    enum State: Equatable {
        case active
        case completed
        case disabled
    }

    let progressSteps: [SetProgressIndicator.Step]
    let exerciseName: String
    let metricValue: String
    var exerciseID: UUID? = nil
    var metricSupportingText: String? = nil
    /// When true, the metric line uses body-sized copy instead of the large numeric display (placeholders).
    var metricIsHint: Bool = false
    /// Pre-fill from a prior session (no working set logged this session yet). Renders the
    /// metric in `textSecondary` so users can tell at a glance whether the number is a
    /// prior value or a value already committed. Recolors via `appReveal` when
    /// the first set lands and the value transitions to logged.
    var metricIsGhost: Bool = false
    var state: State = .active
    var primaryLabel: String = AppCopy.Workout.completeSet
    var onPrimaryAction: (() -> Void)? = nil
    /// Called after this saved set’s existing confirmation dwell; the caller
    /// rechecks completion/selection and returns true if it advanced, letting
    /// the card handoff own the exit. No second timer owner.
    var onSetConfirmationFinished: (() -> Bool)? = nil
    var onSecondaryAction: (() -> Void)? = nil
    /// Bumped by the parent each time a set is logged. Drives `AppHaptic.success`
    /// on this card so the feedback lives at the atom layer instead of being
    /// threaded through a generator at the call site.
    /// Pass `nil` for non-active surfaces (previews) — feedback is a no-op then.
    var setLoggedSignal: Int? = nil
    /// Bumped by the parent only when the just-logged set beat the prior all-time best
    /// for this exercise. The badge shares the set's single success haptic;
    /// a personal record never adds a second tactile event.
    var setPRSignal: Int? = nil
    /// Sentence-case description of the prior best the just-logged set beat — e.g.
    /// "Beat 145 kg × 8". Rendered as a quiet caption beneath the "Personal record"
    /// badge so the lifter knows *what* they beat, not just *that* they beat something.
    /// Visible only while `prBadgeVisible` is true (~3s dwell). Optional: legacy callers
    /// can omit it and the badge stays single-line.
    var priorBestText: String? = nil
    var timerValue: String? = nil
    var timerState: RestTimerControl.State = .idle
    var onTimerDecrease: (() -> Void)? = nil
    var onTimerToggle: (() -> Void)? = nil
    var onTimerIncrease: (() -> Void)? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Toggles for ~800ms each time `setPRSignal` increments — replaces the quiet
    /// `metricSupportingText` line ("Last session …") with a Verde "Personal record"
    /// chip so the peak emotional moment of a session is held visibly long enough
    /// to register before the metric prefill cross-fades to the next set.
    @SwiftUI.State private var prBadgeVisible: Bool = false
    @SwiftUI.State private var setConfirmationVisible = false
    @SwiftUI.State private var setConfirmationSequence = 0
    private static let setConfirmationDwellSeconds: Double = 2.5
    /// Invalidates an older auto-dismiss task when another PR lands before the
    /// current badge finishes its dwell. The newest milestone always receives
    /// the full visible duration instead of being hidden by the first task.
    @SwiftUI.State private var prBadgeSequence: Int = 0

    private var exerciseTransitionID: String { exerciseID?.uuidString ?? exerciseName }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // PlateSteps pattern: replace only exercise content. The timer is
            // outside the identity boundary and never gets rebuilt with a step.
            ZStack(alignment: .top) {
                VStack(alignment: .center, spacing: AppSpacing.lg) {
                    HStack {
                        Spacer(minLength: 0)
                        SetProgressIndicator(steps: progressSteps)
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)

                    Text(exerciseName)
                        .font(AppFont.productHeading.font)
                        .tracking(AppFont.productHeading.tracking)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    VStack(alignment: .center, spacing: AppSpacing.sm) {
                        metricHero.frame(minHeight: 60)
                        metricSupportingSlot
                    }

                    // Keep the existing 60pt slot after completion, so the
                    // confirmation timing cannot collapse the timer's layout.
                    AppPrimaryButton(
                        primaryLabel,
                        isEnabled: setConfirmationVisible || (state == .active && onPrimaryAction != nil),
                        isConfirmed: setConfirmationVisible,
                        action: {
                            guard state == .active else { return }
                            onPrimaryAction?()
                        }
                    )
                    .opacity(state == .completed && !setConfirmationVisible ? 0 : 1)
                    .allowsHitTesting(state == .active)
                    .accessibilityHidden(state == .completed && !setConfirmationVisible)
                    .animation(AppMotion.transition, value: setConfirmationVisible)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
                .id(exerciseTransitionID)
                .transition(AppBlurTransition().animation(AppMotion.transition))
            }

            if let timerValue {
                Rectangle()
                    .fill(AppColor.border.opacity(0.32))
                    .frame(maxWidth: .infinity)
                    .frame(height: 1)

                RestTimerControl(
                    timeText: timerValue,
                    state: timerState,
                    onDecrease: onTimerDecrease,
                    onToggle: onTimerToggle,
                    onIncrease: onTimerIncrease
                )
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.lg)
            }
        }
        .frame(maxWidth: .infinity)
        .appWorkoutPanelChrome()
        .appAnimation(AppMotion.collectionChange, value: exerciseTransitionID, reduceMotion: reduceMotion)
        .appAnimation(AppMotion.collectionChange, value: prBadgeVisible, reduceMotion: reduceMotion)
        .appAnimation(AppMotion.collectionChange, value: metricSupportingText, reduceMotion: reduceMotion)
        .appHaptic(.success, trigger: setLoggedSignal)
        .onChange(of: setLoggedSignal) { _, _ in
            // Parent increments only after persistence succeeds. The next set
            // remains immediately tappable; this is feedback, never a log delay.
            setConfirmationVisible = true
            setConfirmationSequence &+= 1
        }
        .task(id: setConfirmationSequence) {
            guard setConfirmationSequence > 0, setConfirmationVisible else { return }
            do {
                try await Task.sleep(for: .seconds(Self.setConfirmationDwellSeconds))
            } catch { return }
            guard setConfirmationVisible else { return }
            // An exercise handoff owns the whole outgoing card. Keep its saved
            // mark intact instead of flashing its old label before the blur.
            if onSetConfirmationFinished?() != true {
                withAnimation(AppMotion.transition) { setConfirmationVisible = false }
            }
        }
        .onChange(of: exerciseTransitionID) { _, _ in
            setConfirmationVisible = false
            prBadgeSequence &+= 1
            prBadgeVisible = false
        }
        .onChange(of: setPRSignal) { _, _ in
            showPRBadge()
        }
        .onDisappear {
            prBadgeSequence &+= 1
            prBadgeVisible = false
            setConfirmationVisible = false
        }
    }

    /// Dwell on the PR badge — 3.0 s gives the lifter time to read "Personal record"
    /// + the prior-best delta under fatigue, without holding the slot long enough to
    /// stall the next-set prefill cross-fade. The previous 0.8 s flashed before the
    /// glance landed; the heavy haptic was firing alone.
    private static let prBadgeDwellSeconds: UInt64 = 3
    private func showPRBadge() {
        prBadgeSequence &+= 1
        let sequence = prBadgeSequence
        withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: UIAccessibility.isVoiceOverRunning) ? .appReveal : nil) {
            prBadgeVisible = true
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.prBadgeDwellSeconds * 1_000_000_000)
            guard sequence == prBadgeSequence else { return }
            withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: UIAccessibility.isVoiceOverRunning) ? .appExit : nil) {
                prBadgeVisible = false
            }
        }
    }

    private var personalRecordBadge: some View {
        HStack(spacing: AppSpacing.xs) {
            AppIcon.checkmarkFilled.image(size: 17)
                .foregroundStyle(AppColor.success)
            Text(AppCopy.Workout.personalRecord)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textPrimary)
        }
        .padding(.horizontal, AppSpacing.smd)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColor.successSoft, in: Capsule(style: .continuous))
        .fixedSize()
    }

    private var metricSupportingSlot: some View {
        ZStack {
            // Reserve a caption/badge line even when the evidence clears.
            Text(AppCopy.Workout.startingTargetLabel)
                .font(AppFont.caption.font)
                .padding(.vertical, AppSpacing.xs)
                .hidden()
                .accessibilityHidden(true)

            if prBadgeVisible {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.sm) {
                        personalRecordBadge
                        if let priorBestText, !priorBestText.isEmpty {
                            Text(priorBestText)
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .monospacedDigit()
                                .fixedSize()
                        }
                    }
                    VStack(spacing: AppSpacing.xs) {
                        personalRecordBadge
                        if let priorBestText, !priorBestText.isEmpty {
                            Text(priorBestText)
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                                .monospacedDigit()
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                .transition(AppBlurTransition().animation(AppMotion.transition))
            } else {
                Text(metricSupportingText ?? " ")
                    .contentTransition(.opacity)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(metricSupportingText == nil ? 0 : 1)
                    .animation(AppMotion.transition, value: metricSupportingText)
                    .accessibilityHidden(metricSupportingText == nil)
                    .transition(.opacity)
            }
        }
    }

    private var metricHero: some View {
        ZStack {
            Group {
                if metricIsHint {
                    AppSecondaryButton(
                        AppCopy.Workout.logMetricHint,
                        isEnabled: state == .active,
                        fillsAvailableWidth: false,
                        action: { onSecondaryAction?() }
                    )
                } else {
                    Button(action: { onSecondaryAction?() }) {
                        metricValueLabel
                            .frame(maxWidth: .infinity)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(onSecondaryAction == nil || state != .active)
                    .accessibilityLabel(onSecondaryAction == nil
                        ? Self.voiceOverLabel(forMetric: metricValue)
                        : "Adjust weight and reps, \(Self.voiceOverLabel(forMetric: metricValue))")
                    .accessibilityRemoveTraits(onSecondaryAction == nil ? .isButton : [])
                }
            }
            .id(metricIsHint)
            .transition(AppBlurTransition().animation(AppMotion.transition))
        }
    }

    private var metricValueLabel: some View {
        VStack(spacing: AppSpacing.xs) {
            metricValueText
            Text("Adjust")
                .appCapsLabel(.smallLabel)
                .foregroundStyle(AppColor.textSecondary)
                .opacity(onSecondaryAction == nil ? 0 : 1)
                .animation(AppMotion.transition, value: onSecondaryAction != nil)
                .accessibilityHidden(onSecondaryAction == nil)
        }
    }

    @ViewBuilder
    private var metricValueText: some View {
        Text(WorkoutTargetFormatter.compactMetricSpacing(metricValue))
            // Restore the original prominent workout readout through the
            // existing 36pt numeric-display role; editors keep their own size.
            .font(AppFont.numericDisplay.font)
            .tracking(AppFont.numericDisplay.tracking)
            .monospacedDigit()
            .foregroundStyle(metricIsGhost ? AppColor.textSecondary : AppColor.textPrimary)
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.55)
            .lineLimit(3)
            // "Last …" becoming an actual target/performance is a whole
            // content swap. A fast numeric roll made that mixed text look abrupt.
            .contentTransition(.opacity)
            .animation(AppMotion.transition, value: metricValue)
            .animation(AppMotion.transition, value: metricIsGhost)
            .accessibilityLabel(Self.voiceOverLabel(forMetric: metricValue))
    }

    /// Translate the compact metric token (`3x8x80kg`, `BWx12`) into a
    /// VoiceOver-friendly phrase. `x` becomes " by ", `BW` expands to
    /// "bodyweight". Keeps the visible glyphs untouched — the numeric column
    /// stays tight on screen while screen-reader users get a sentence.
    static func voiceOverLabel(forMetric metric: String) -> String {
        metric
            .replacingOccurrences(of: "BW", with: "bodyweight")
            .replacingOccurrences(of: "x", with: " by ")
    }
}

/// Bottom-anchored state bar for active sessions. Renders rest timer (running /
/// paused / complete) or "Next exercise" subtitle + advance action. Compose via
/// `.safeAreaInset(edge: .bottom)` on `ActiveWorkoutView` so it floats above the
/// tab bar, never scrolls with content.
struct SessionStateBar: View {
    enum State {
        case restRunning(countdown: String, helperText: String?)
        case restPaused(countdown: String, helperText: String?)
        case restComplete(helperText: String?)
        case nextExercise(subtitle: String)
    }

    let state: State
    var onDecreaseRest: (() -> Void)? = nil
    var onToggleRest: (() -> Void)? = nil
    var onIncreaseRest: (() -> Void)? = nil
    var onAdvance: (() -> Void)? = nil

    var body: some View {
        switch state {
        case .nextExercise:
            nextExerciseButton
        default:
            VStack(spacing: 0) {
                content
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.md)
                    .padding(.bottom, AppSpacing.lg)
            }
            .frame(maxWidth: .infinity)
            .background(AppColor.background)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch state {
        case .restRunning(let countdown, let helperText):
            restContent(
                title: "Rest",
                helperText: helperText,
                controlState: .running,
                countdown: countdown
            )

        case .restPaused(let countdown, let helperText):
            restContent(
                title: "Rest",
                helperText: helperText,
                controlState: .paused,
                countdown: countdown
            )

        case .restComplete(let helperText):
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Ready")
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)

                if let helperText, !helperText.isEmpty {
                    Text(helperText)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        case .nextExercise:
            EmptyView()
        }
    }

    private var nextExerciseButton: some View {
        Group {
            if case .nextExercise(let subtitle) = state {
                Button(action: { onAdvance?() }) {
                    HStack(spacing: AppSpacing.xs) {
                        Text(AppCopy.Workout.nextExercise)
                            .foregroundStyle(AppColor.textSecondary)
                        Text(subtitle)
                            .foregroundStyle(AppColor.textPrimary)
                            .contentTransition(.opacity)
                            .animation(AppMotion.transition, value: subtitle)
                    }
                    // `productAction` (17pt bold) matches `AppPrimaryButton`'s
                    // label font so the secondary "Next exercise" CTA reads at
                    // the same visual weight as the primary "Complete set"
                    // CTA stacked above it. Visual hierarchy still works:
                    // the primary uses `AppColor.accent` fill + accent
                    // foreground, the secondary uses `controlBackground` +
                    // textPrimary/textSecondary halves — chrome carries the
                    // hierarchy, type carries the read. Was `caption`
                    // (15pt medium) which read as a footnote and felt tiny
                    // on iPhone Pro screens.
                    .font(AppFont.productAction.font)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(
                        AppColor.controlBackground,
                        in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    )
                    .contentShape(
                        RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    )
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(onAdvance == nil)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                .padding(.bottom, AppSpacing.lg)
                .frame(maxWidth: .infinity)
                .background(AppColor.background)
            }
        }
    }

    private func restContent(
        title: String,
        helperText: String?,
        controlState: RestTimerControl.State,
        countdown: String
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)

            RestTimerControl(
                timeText: countdown,
                state: controlState,
                onDecrease: onDecreaseRest,
                onToggle: onToggleRest,
                onIncrease: onIncreaseRest
            )

            if let helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Section header line — title text plus an optional trailing accessory
/// (e.g. "Reorder", "Edit", "See all"). Use as the heading of any titled
/// group whose body is a standalone surface (`AppCardList`, an
/// `appInputFieldStyle()` field, custom card content). For groups whose
/// body needs its own card chrome around free-form content, use
/// `SettingsSection` — which composes this header internally.
struct AppSectionHeader<Trailing: View>: View {
    private let title: String
    private let trailing: () -> Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
            Spacer(minLength: 0)
            trailing()
        }
    }
}

extension AppSectionHeader {
    init(_ title: String, @ViewBuilder trailing: @escaping () -> Trailing) {
        self.title = title
        self.trailing = trailing
    }
}

extension AppSectionHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}

/// Titled group: section-header text above an `AppCard` body. Default
/// `contentInset: AppSpacing.lg` (24pt) matches `AppCard`'s default chrome and is
/// right for plain content (single buttons, free-form copy, custom layouts) where
/// the body owns no horizontal padding of its own. Pass `contentInset: AppSpacing.sm`
/// (8pt) for **list mode**: list content where the inner row already pads itself
/// (`AppListRow`, `AppDividedList`). In list mode the card collapses to 0/0
/// so the 1pt `AppDivider` hairlines run card-edge to card-edge — same
/// full-bleed rule as `AppCardList`. Passing `contentInset: 0` is reserved for
/// surfaces where rows must run card-edge to card-edge (e.g. full-bleed media)
/// without any list semantics.
struct SettingsSection<Content: View>: View {
    let title: String
    var contentInset: CGFloat = AppSpacing.md
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        contentInset: CGFloat = AppSpacing.md,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.contentInset = contentInset
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader(title)

            AppCard(contentInset: cardHorizontalInset, verticalInset: cardVerticalInset) {
                VStack(alignment: .leading, spacing: isListMode ? 0 : AppSpacing.sm) {
                    content()
                }
            }
        }
    }

    /// List mode: rows own their own padding (24pt via `AppListRow`), so the
    /// card runs full-bleed (0/0) and `AppDivider` hairlines extend card-edge
    /// to card-edge — matching `AppCardList`'s documented rule.
    private var isListMode: Bool { contentInset == AppSpacing.sm }
    private var cardHorizontalInset: CGFloat { isListMode ? 0 : contentInset }
    private var cardVerticalInset: CGFloat? { isListMode ? 0 : nil }
}

// MARK: - Template

/// Configures the sticky primary CTA baked into `AppScreen(primaryButton:)`.
/// Pass via `AppScreen(primaryButton: .init(label:action:))` — the screen renders
/// it inside a `.safeAreaInset(edge: .bottom)` so it floats above scroll content.
///
/// `disabledReason` is rendered as a single-line caption (`AppFont.muted`,
/// `AppColor.textSecondary`) directly above the button when the button is
/// disabled and not loading. Use it to turn a silent grey CTA into a
/// diagnostic — pair with strings under `AppCopy.FormHint`.
///
/// `contextLabel` is rendered in the same quiet slot when present and the
/// button is enabled — for example, a selected-plan summary above a purchase
/// CTA. Keep it short; the button label remains the action.
struct PrimaryButtonConfig {
    let label: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var disabledReason: String? = nil
    var contextLabel: String? = nil
    let action: () -> Void
}

/// Quiet ghost CTA (e.g. onboarding "Back") rendered directly under the primary.
/// Renders as `AppGhostButton` — text-only, no fill — so it doesn't compete with
/// the primary. When set together with `primaryButton`, the pair reads as one unit:
/// they share one `.safeAreaInset(edge: .bottom)` with `AppSpacing.xs` (4pt)
/// between them. Use `AppScreen(secondaryButton:)` — never stack two separate
/// `.safeAreaInset`s.
struct SecondaryButtonConfig {
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void
}

/// Native bottom-sheet shell: centered title, leading close X, and
/// `AppScreen` content/commit CTA layout. Matches sheets like
/// Today's routine; reserve `ProductTopBar` for product/root surfaces.
struct AppSheetScreen<Content: View>: View {
    let title: String
    let primaryButton: PrimaryButtonConfig?
    let secondaryButton: SecondaryButtonConfig?
    let dismissLabel: String
    let onDismissAction: (() -> Void)?
    var usesOuterScroll: Bool
    var showsKeyboardDismissToolbar: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        primaryButton: PrimaryButtonConfig? = nil,
        secondaryButton: SecondaryButtonConfig? = nil,
        dismissLabel: String = AppCopy.Nav.cancel,
        onDismissAction: (() -> Void)? = nil,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.dismissLabel = dismissLabel
        self.onDismissAction = onDismissAction
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.content = content
    }

    var body: some View {
        NavigationStack {
            AppScreen(
                primaryButton: primaryButton,
                secondaryButton: secondaryButton,
                showsNativeNavigationBar: true,
                usesOuterScroll: usesOuterScroll,
                showsKeyboardDismissToolbar: showsKeyboardDismissToolbar
            ) {
                content()
                    .padding(.vertical, usesOuterScroll ? 0 : AppSpacing.md)
            }
            .navigationBarTitleTruncated(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onDismissAction {
                    ToolbarItem(placement: .cancellationAction) {
                        Group {
                            Button(action: onDismissAction) {
                                Label(dismissLabel == AppCopy.Nav.done ? AppCopy.Nav.close : dismissLabel, systemImage: AppIcon.close.systemName)
                                    .labelStyle(.iconOnly)
                            }
                        }
                        .tint(AppColor.textPrimary)
                    }
                }
            }
            .appNavigationBarChrome()
        }
        .tint(AppColor.accent)
    }
}

/// Reusable bottom sheet for editing a routine's working set target. Keeps
/// template-edit and onboarding-style set/reps controls on the same sheet,
/// type, spacing, range, and stepper behavior. The edited exercise leads the
/// content, while compact rows group sets and reps into one scannable target.
/// A rep range reads as one progression concept instead of three equally loud
/// columns of controls.
struct AppSetRepEditorSheet: View {
    static let defaultSets: Int = 3
    static let defaultReps: Int = 8
    static let defaultSetRange: ClosedRange<Int> = 1...10
    static let defaultRepRange: ClosedRange<Int> = 1...30

    let title: String
    var subject: String? = nil
    let setRange: ClosedRange<Int>
    let repRange: ClosedRange<Int>
    let onSave: (_ sets: Int, _ reps: Int, _ progression: DoubleProgressionConfiguration?) -> Bool

    @Environment(\.dismiss) private var dismiss
    @AppStorage("unitSystem") private var unitSystem = "kg"
    @State private var saveFailed = false
    @State private var sets: Int
    @State private var reps: Int
    @State private var progressionEnabled: Bool
    @State private var lowerReps: Int
    @State private var upperReps: Int
    @State private var incrementText: String

    init(
        title: String = AppCopy.Workout.editTarget,
        subject: String? = nil,
        initialSets: Int = Self.defaultSets,
        initialReps: Int = Self.defaultReps,
        initialProgression: DoubleProgressionConfiguration? = nil,
        setRange: ClosedRange<Int> = Self.defaultSetRange,
        repRange: ClosedRange<Int> = Self.defaultRepRange,
        onSave: @escaping (
            _ sets: Int,
            _ reps: Int,
            _ progression: DoubleProgressionConfiguration?
        ) -> Bool
    ) {
        self.title = title
        self.subject = subject
        self.setRange = setRange
        self.repRange = repRange
        self.onSave = onSave
        _sets = State(initialValue: Self.clamped(initialSets, to: setRange))
        _reps = State(initialValue: Self.clamped(initialReps, to: repRange))
        _progressionEnabled = State(initialValue: initialProgression != nil)
        _lowerReps = State(initialValue: Self.clamped(
            initialProgression?.lowerRepBound ?? initialReps,
            to: repRange
        ))
        _upperReps = State(initialValue: Self.clamped(
            initialProgression?.upperRepBound ?? min(initialReps + 2, repRange.upperBound),
            to: repRange
        ))

        let storedUnit = UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
        let defaultIncrementKg = storedUnit == "lb" ? 5 / 2.20462 : 2.5
        let incrementKg = initialProgression?.weightIncrementKg ?? defaultIncrementKg
        let displayIncrement = storedUnit == "lb" ? incrementKg * 2.20462 : incrementKg
        _incrementText = State(initialValue: displayIncrement.weightString)
    }

    var body: some View {
        AppSheetScreen(
            title: title,
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.Workout.saveChanges,
                isEnabled: canSave,
                action: commit
            ),
            dismissLabel: AppCopy.Nav.cancel,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let subject, !subject.isEmpty {
                    Text(subject)
                        .appFont(.productHeading)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SettingsSection(title: AppCopy.Workout.targetLabel, contentInset: AppSpacing.sm) {
                    targetRow(
                        label: AppCopy.Workout.targetSetsLabel,
                        value: $sets,
                        range: setRange
                    )

                    AppDivider()

                    if progressionEnabled {
                        targetRow(
                            label: AppCopy.Workout.lowerRepsLabel,
                            value: $lowerReps,
                            range: repRange.lowerBound...upperReps
                        )

                        AppDivider()

                        targetRow(
                            label: AppCopy.Workout.upperRepsLabel,
                            value: $upperReps,
                            range: lowerReps...repRange.upperBound
                        )
                    } else {
                        targetRow(
                            label: AppCopy.Workout.targetRepsLabel,
                            value: $reps,
                            range: repRange
                        )
                    }
                }

                SettingsSection(title: AppCopy.Workout.progressionLabel, contentInset: AppSpacing.sm) {
                    AppListRow(
                        title: AppCopy.Workout.progressionToggleLabel,
                        subtitle: AppCopy.Workout.progressionExplanation
                    ) {
                        Toggle("", isOn: $progressionEnabled)
                            .labelsHidden()
                            .tint(AppColor.accent)
                            .frame(minWidth: 44, minHeight: 44)
                            .accessibilityLabel(AppCopy.Workout.progressionToggleLabel)
                    }

                    if progressionEnabled {
                        AppDivider()

                        AppListRow(
                            title: AppCopy.Workout.weightIncrementLabel,
                            subtitle: AppCopy.Workout.weightIncrementExplanation
                        ) {
                            AppInlineWeightField(
                                text: $incrementText,
                                unitSuffix: unitSystem,
                                accessibilityLabel: AppCopy.Workout.weightIncrementLabel
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .alert("Couldn’t save target", isPresented: $saveFailed) {
            Button(AppCopy.Nav.ok, role: .cancel) { }
        } message: {
            Text("Your changes are still here. Try saving again.")
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
    }

    @ViewBuilder
    private func targetRow(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        let currentValue = value.wrappedValue

        HStack(spacing: AppSpacing.md) {
            Text(label)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)

            Spacer(minLength: 0)

            AppStepper(
                value: "\(currentValue)",
                size: .compact,
                minimumValueWidth: AppSpacing.xl,
                isDecrementEnabled: currentValue > range.lowerBound,
                isIncrementEnabled: currentValue < range.upperBound,
                onDecrement: {
                    value.wrappedValue = Self.clamped(currentValue - 1, to: range)
                },
                onIncrement: {
                    value.wrappedValue = Self.clamped(currentValue + 1, to: range)
                }
            )
        }
        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
        .padding(.horizontal, AppSpacing.md)
        .padding(.vertical, AppSpacing.sm)
    }

    private func commit() {
        let savedReps = progressionEnabled
            ? min(max(reps, lowerReps), upperReps)
            : reps
        if onSave(sets, savedReps, progressionConfiguration) {
            dismiss()
        } else {
            saveFailed = true
        }
    }

    private var canSave: Bool {
        !progressionEnabled || progressionConfiguration != nil
    }

    private var progressionConfiguration: DoubleProgressionConfiguration? {
        guard progressionEnabled,
              lowerReps >= repRange.lowerBound,
              upperReps >= lowerReps,
              upperReps <= repRange.upperBound,
              let displayIncrement = Double(
                incrementText.replacingOccurrences(of: ",", with: ".")
              ),
              displayIncrement.isFinite,
              displayIncrement > 0 else {
            return nil
        }

        let incrementKg = unitSystem == "lb"
            ? displayIncrement / 2.20462
            : displayIncrement
        return DoubleProgressionConfiguration(
            workingSetCount: sets,
            lowerRepBound: lowerReps,
            upperRepBound: upperReps,
            weightIncrementKg: incrementKg
        )
    }

    private static func clamped(_ value: Int, to range: ClosedRange<Int>) -> Int {
        min(range.upperBound, max(range.lowerBound, value))
    }
}

/// Canonical exercise picker sheet — search-driven catalog list with optional
/// "Create …" affordance for a brand-new exercise. Replaces the parallel
/// `AddExerciseToTemplateView` / `AddExerciseSheet` / `ExerciseSearchSheet`
/// implementations that drifted on detents, toolbar slot, separators, and row
/// layout. One canonical chrome — large detent, trailing **Done**, visible
/// hairlines, alias subtitle row, prepended create-new affordance.
///
/// Drop into a `.sheet { ... }`; the primitive owns its own
/// `appBottomSheetChrome` and `presentationDetents`. Caller wires the
/// `onSelect` callback to append the chosen `Exercise` to its target
/// (template, session, …). Create-new persists the new `Exercise` into the
/// shared `modelContext` then forwards it through `onSelect`.
struct AppExercisePickerSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    let title: String
    let existingIds: Set<UUID>
    var allowsCreatingNew: Bool
    let onSelect: (Exercise) -> Void

    @State private var query = ""

    init(
        title: String = AppCopy.Workout.addExercise,
        existingIds: Set<UUID>,
        allowsCreatingNew: Bool = true,
        onSelect: @escaping (Exercise) -> Void
    ) {
        self.title = title
        self.existingIds = existingIds
        self.allowsCreatingNew = allowsCreatingNew
        self.onSelect = onSelect
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredExercises: [Exercise] {
        let available = exercises.filter { !$0.isArchived && !existingIds.contains($0.id) }
        guard !trimmedQuery.isEmpty else { return available }
        let needle = trimmedQuery.lowercased()
        return available.filter { exercise in
            exercise.displayName.lowercased().contains(needle) ||
            exercise.aliases.contains { $0.lowercased().contains(needle) }
        }
    }

    private var canCreateNew: Bool {
        guard allowsCreatingNew, !trimmedQuery.isEmpty else { return false }
        return !exercises.contains {
            $0.displayName.compare(
                trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }
    }

    private var archivedExactMatch: Exercise? {
        guard !trimmedQuery.isEmpty else { return nil }
        return exercises.first {
            $0.isArchived &&
            $0.displayName.compare(
                trimmedQuery,
                options: [.caseInsensitive, .diacriticInsensitive]
            ) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            List {
                if let archivedExactMatch {
                    Button {
                        archivedExactMatch.isArchived = false
                        try? modelContext.save()
                        onSelect(archivedExactMatch)
                        dismiss()
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            AppIcon.addCircle.image()
                                .foregroundStyle(AppColor.accent)
                            Text("Restore \"\(archivedExactMatch.displayName)\"")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.accent)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .appPlainListRowChrome()
                }

                if canCreateNew {
                    Button {
                        createAndSelect(name: trimmedQuery)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            AppIcon.addCircle.image()
                                .foregroundStyle(AppColor.accent)
                            Text("Create \"\(trimmedQuery)\"")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.accent)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .appPlainListRowChrome()
                }

                ForEach(filteredExercises, id: \.id) { exercise in
                    Button {
                        onSelect(exercise)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            HStack(spacing: AppSpacing.sm) {
                                Text(exercise.displayName)
                                    .font(AppFont.body.font)
                                    .foregroundStyle(AppColor.textPrimary)
                                if exercise.isBodyweight {
                                    Text(AppCopy.Workout.bodyweightAbbrev)
                                        .font(AppFont.caption.font)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                            }
                            if !exercise.aliases.isEmpty {
                                Text(exercise.aliases.joined(separator: " · "))
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .appPlainListRowChrome()
                }

                if filteredExercises.isEmpty && !canCreateNew && archivedExactMatch == nil {
                    Text(trimmedQuery.isEmpty
                         ? AppCopy.Search.noExercisesYet
                         : AppCopy.Search.noMatchingExercises)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minHeight: 44, alignment: .leading)
                        .appPlainListRowChrome(separator: .hidden)
                }
            }
            .listSectionSpacing(0)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.sheetBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .appExerciseSearchable(text: $query)
            .onSubmit(of: .search) {
                guard canCreateNew else { return }
                createAndSelect(name: trimmedQuery)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button { dismiss() } label: {
                            Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName)
                                .labelStyle(.iconOnly)
                        }
                    }
                    .tint(AppColor.textPrimary)
                }
            }
            .appNavigationBarChrome()
            .tint(AppColor.accent)
            .task {
                ExerciseCatalog.ensurePersisted(
                    in: modelContext,
                    existingExercises: exercises
                )
            }
        }
        .presentationDetents([.large])
        .appBottomSheetChrome()
    }

    private func createAndSelect(name: String) {
        let exercise = Exercise(displayName: name)
        modelContext.insert(exercise)
        try? modelContext.save()
        onSelect(exercise)
        dismiss()
    }
}

/// Page-level template: horizontal padding, optional `customHeader` (typically
/// `ProductTopBar` for root tabs) or system `NavigationStack` chrome, scrollable
/// body, optional sticky primary CTA. **Every full screen in the app composes
/// through `AppScreen`** — don't rebuild a ScrollView/VStack/nav-bar shell in a
/// feature view. Set `usesOuterScroll: false` for fixed dashboards where inner
/// controls own scrolling.
struct AppScreen<Content: View>: View {
    let primaryButton: PrimaryButtonConfig?
    let secondaryButton: SecondaryButtonConfig?
    let customHeader: AnyView?
    /// Optional capsule accessory that hovers above the primary CTA — typically
    /// `AppFloatingPillButton`. Auto-hides on scroll-down, reveals on scroll-up,
    /// always visible at the top of the scroll. Renders without chrome
    /// background so scroll content fades behind it via `appScrollEdgeSoft`.
    let floatingAccessory: AnyView?
    var hidesNavigationBar: Bool = false
    var showsNativeNavigationBar: Bool = false
    /// Set false for a chrome-free purchase surface that needs no top bar effect.
    var showsTopScrollFade: Bool = true
    /// When `false`, the screen does not wrap content in `ScrollView` — use for fixed dashboards where an inner control (e.g. `PreviewListContainer`) owns vertical scrolling.
    var usesOuterScroll: Bool = true
    /// When `true`, adds a trailing **Done** to the keyboard accessory bar
    /// to dismiss first responder. **Default is `false` and no caller in
    /// the app currently opts in.** iOS 26 renders
    /// `ToolbarItemGroup(placement: .keyboard)` content as a persistent
    /// floating Liquid Glass pill at the bottom safe area — even when the
    /// keyboard is dismissed, and even when the focused field is a
    /// numeric pad on a hardware-keyboard simulator (visible as a stray
    /// bottom-right Done with no keyboard in sight). For dismissal, rely
    /// instead on: `.scrollDismissesKeyboard(.interactively)` (already on
    /// `AppScreen`), tap-outside on the milk background, or the sheet's
    /// primary CTA. Re-introduce this opt-in only behind `@FocusState`
    /// gating that attaches the toolbar exclusively while a multi-line
    /// `axis: .vertical` TextField is first responder.
    var showsKeyboardDismissToolbar: Bool = false
    /// Page surface fill. Default `AppColor.background` (Milk) keeps every screen
    /// rendering as an opaque page. Pass a `nil` to suppress the fill so a
    /// parent container can own a single shared page surface (used by
    /// `OnboardingFlow`, where the page must stay still while step content
    /// slides in from the trailing edge).
    var surface: Color? = AppColor.background
    @ViewBuilder let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @State private var floatingAccessoryHidden: Bool = false

    init(
        primaryButton: PrimaryButtonConfig? = nil,
        secondaryButton: SecondaryButtonConfig? = nil,
        customHeader: AnyView? = nil,
        floatingAccessory: AnyView? = nil,
        hidesNavigationBar: Bool = false,
        showsNativeNavigationBar: Bool = false,
        showsTopScrollFade: Bool = true,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        surface: Color? = AppColor.background,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.customHeader = customHeader
        self.floatingAccessory = floatingAccessory
        self.hidesNavigationBar = hidesNavigationBar
        self.showsNativeNavigationBar = showsNativeNavigationBar
        self.showsTopScrollFade = showsTopScrollFade
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.surface = surface
        self.content = content
    }

    private var hasBottomBar: Bool { primaryButton != nil || secondaryButton != nil }
    private var hasBottomChrome: Bool { hasBottomBar || floatingAccessory != nil }

    /// Max content width — keeps the mobile layout on iPad / Mac.
    private var maxContentWidth: CGFloat { 430 }

    @ViewBuilder
    private var scrollContent: some View {
        Group {
            if usesOuterScroll {
                ScrollView {
                    paddedMainContent
                }
                .scrollDismissesKeyboard(.interactively)
                // Bounce only when content actually overflows. Without this,
                // a short screen (e.g. the unit picker — 2 cards) over-scrolls
                // on rubber-band drag and exposes content sliding behind the
                // header chrome. iOS-native bars do this automatically;
                // `safeAreaInset` doesn't, so we opt in explicitly.
                .scrollBounceBehavior(.basedOnSize)
                // Native edge effects belong to the scroll view; no gradient overlay.
                .appScrollEdgeSoft(
                    top: showsTopScrollFade,
                    bottom: hasBottomChrome
                )
                .onScrollGeometryChange(for: CGFloat.self) { geometry in
                    geometry.contentOffset.y
                } action: { oldOffset, newOffset in
                    guard floatingAccessory != nil else { return }
                    let delta = newOffset - oldOffset
                    let threshold: CGFloat = 6
                    if newOffset <= 4 {
                        if floatingAccessoryHidden {
                            withAnimation(.appState) { floatingAccessoryHidden = false }
                        }
                    } else if delta > threshold {
                        if !floatingAccessoryHidden {
                            withAnimation(.appState) { floatingAccessoryHidden = true }
                        }
                    } else if delta < -threshold {
                        if floatingAccessoryHidden {
                            withAnimation(.appState) { floatingAccessoryHidden = false }
                        }
                    }
                }

            } else {
                paddedMainContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
    }

    private var paddedMainContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            content()
        }
        // The one owner of page tint: content is blue, while bars and
        // toolbars stay black from ContentView (decision 2026-10-24).
        .tint(AppColor.accent)
        .padding(.horizontal, AppSpacing.md)
        // Child-owned scrolling must reach the safe-area boundary. Fixed
        // sheet/onboarding content restores its own internal padding.
        .padding(.top, usesOuterScroll ? (showsNativeNavigationBar ? AppSpacing.md : (customHeader == nil ? AppSpacing.md : AppSpacing.sm)) : 0)
        .padding(.bottom, usesOuterScroll ? AppSpacing.md : 0)
        .frame(maxWidth: maxContentWidth)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var topChrome: some View {
        // `customHeader` renders even when `showsNativeNavigationBar: true`
        // (used by `OnboardingShell` to layer a progress + title + subtitle
        // chrome below the iOS-native nav bar that hosts the real back-button
        // `ToolbarItem`). When the caller doesn't provide one, this branch
        // simply produces nothing.
        if let customHeader {
            customHeader
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.sm)
                // `sm` (8pt) bottom — was `md` (16pt). Combined with the
                // content area's `.padding(.top, md)` below, the old pair
                // produced a 32pt gap between the chrome and the first
                // scroll-content line. That reads as airy "header → body"
                // when the chrome ends with a primary element (large title
                // + subtitle), but as a disconnect when the chrome ends
                // with a secondary affordance like `OnboardingShell`'s
                // sticky day-chip strip — two small things bracketing a
                // big gap. Tightening to `sm` brings the gap to 24pt,
                // which mirrors `bottomChrome`'s `top: sm` for symmetry
                // across the page chrome (top: sm-bottom, bottom: sm-top).
                .padding(.bottom, AppSpacing.sm)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
                .background(AppScreenChromeBackground(surface: surface ?? AppColor.background))
        }
    }

    @ViewBuilder
    private var bottomChrome: some View {
        if hasBottomBar {
            VStack(spacing: AppSpacing.xs) {
                if let primaryButton {
                    // Diagnostic caption above the disabled CTA. Hidden
                    // while loading (the spinner is the status) and while
                    // enabled (no gate to explain). Caption is single-line
                    // muted text so it never competes with the button.
                    if !primaryButton.isEnabled,
                       !primaryButton.isLoading,
                       let reason = primaryButton.disabledReason,
                       !reason.isEmpty {
                        Text(reason)
                            .font(AppFont.muted.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(reason)
                    }
                    if primaryButton.isEnabled,
                       let contextLabel = primaryButton.contextLabel,
                       !contextLabel.isEmpty {
                        Text(contextLabel)
                            .font(AppFont.muted.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .accessibilityLabel(contextLabel)
                    }
                    AppPrimaryButton(
                        primaryButton.label,
                        isEnabled: primaryButton.isEnabled,
                        isLoading: primaryButton.isLoading,
                        action: primaryButton.action
                    )
                }
                if let secondaryButton {
                    AppGhostButton(
                        secondaryButton.label,
                        isEnabled: secondaryButton.isEnabled,
                        action: secondaryButton.action
                    )
                }
            }
            // Shared breathing room above native tab bars and the home safe area.
            .padding(.top, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.md)
            // Bottom chrome must never donate its CTA height to the scroll
            // view on short devices or when context copy changes line count.
            // Keep the full button and its rounded lower edge on-screen.
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
            .background(AppScreenChromeBackground(surface: surface ?? AppColor.background))
        }
    }

    /// Floating accessory rendered as an overlay on the scroll content (not as
    /// a sibling row in `bottomChrome`). The pill genuinely floats above scroll
    /// content — the chrome backdrop stays unique to the primary CTA below, so
    /// the two pills don't read as one shared chrome panel. Scroll content
    /// fades behind the pill via the ScrollView's `appScrollEdgeSoft` bottom
    /// fade.
    @ViewBuilder
    private var floatingAccessoryOverlay: some View {
        if let floatingAccessory, !floatingAccessoryHidden {
            floatingAccessory
                .padding(.bottom, AppSpacing.sm)
                .frame(maxWidth: maxContentWidth)
                .frame(maxWidth: .infinity)
                .transition(
                    AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
                        ? .opacity.combined(with: .offset(y: AppMotion.revealTravel)) : .opacity
                )
        }
    }

    @ViewBuilder
    private var contentWithChrome: some View {
        // VStack-based chrome layout instead of `safeAreaInset`/`safeAreaBar`.
        // Both inset modifiers ship a layout bug on iOS 26 where short
        // ScrollView content (content height < viewport) shifts the bottom
        // inset chrome to the natural content bottom rather than the frame
        // bottom — visible on the onboarding split-builder screen, which
        // floated the disabled-reason caption + Continue button mid-screen
        // with day rows continuing below them. Forcing `scrollContent` to
        // claim full height *before* the inset is applied did not propagate
        // through the inner `ScrollView`'s own content sizing on iOS 26.
        //
        // VStack siblings remove the ambiguity: each chrome is a real layout
        // child pinned to its edge, the ScrollView fills the remaining space,
        // Shared materials and separators retain the existing pinned geometry.
        VStack(spacing: 0) {
            if customHeader != nil {
                topChrome
            }
            scrollContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .overlay(alignment: .bottom) {
                    floatingAccessoryOverlay
                }
            if hasBottomBar {
                bottomChrome
            }
        }
    }

    var body: some View {
        contentWithChrome
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background((surface ?? AppColor.clear).ignoresSafeArea())
        .toolbar(showsNativeNavigationBar ? .automatic : .hidden, for: .navigationBar)
        .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
        .toolbar {
            if showsKeyboardDismissToolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(AppCopy.Nav.done) {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                }
            }
        }
    }
}

/// Pinned sections occupy their own layout space; no content passes behind
/// them. Match the page surface. Actual navigation bars own native scroll-driven
/// material and separators rather than imitating a bar on a nonoverlapping view.
private struct AppScreenChromeBackground: View {
    let surface: Color

    var body: some View {
        Rectangle().fill(surface)
    }
}

// MARK: - Shared modifiers

extension View {
    /// `elevated` adds the canonical card shadow so sheet inputs read as lifted controls
    /// (matches Apple native form sheets). Default stays flat for in-flow row inputs.
    func appInputFieldStyle(
        height: CGFloat = 48,
        horizontalPadding: CGFloat = AppSpacing.md,
        lineWidth: CGFloat = 0.5,
        elevated: Bool = false
    ) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            // `height` is a hint for the minimum (≥44pt hit-area floor); the
            // field grows when Dynamic Type or wrapped content needs it.
            .frame(minHeight: max(44, height))
            .background(AppColor.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColor.border, lineWidth: lineWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .modifier(AppInputElevation(enabled: elevated))
    }

    /// Multi-line variant: vertical-axis TextFields expand with content, so the container
    /// uses `minHeight` + vertical padding instead of a fixed `height`.
    func appInputFieldStyleMultiline(
        minHeight: CGFloat,
        horizontalPadding: CGFloat = AppSpacing.md,
        verticalPadding: CGFloat = AppSpacing.sm,
        lineWidth: CGFloat = 0.5,
        elevated: Bool = false
    ) -> some View {
        self
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .frame(minHeight: minHeight, alignment: .topLeading)
            .background(AppColor.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColor.border, lineWidth: lineWidth)
            }
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .modifier(AppInputElevation(enabled: elevated))
    }

    /// Canonical card chrome applied as a modifier — matches `AppCard`'s defaults
    /// so both entry points are a single source of truth. `isSelected` adds the
    /// shared accent-soft fill, accent border, and checkmark used by every
    /// selectable card, including onboarding choices and paywall tiers.
    func appCardStyle(
        contentInset: CGFloat = AppSpacing.md,
        cornerRadius: CGFloat = AppRadius.lg,
        isSelected: Bool = false
    ) -> some View {
        self
            .padding(contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                (isSelected ? AppColor.accentSoft : AppColor.cardBackground)
                    .animation(AppMotion.feedback, value: isSelected)
            }
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    AppIcon.checkmarkFilled.image(size: 14, weight: .semibold)
                        .foregroundStyle(AppColor.accent)
                        .padding(AppSpacing.smd)
                        .accessibilityHidden(true)
                        .transition(.opacity.animation(AppMotion.feedback))
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColor.accent : AppColor.clear,
                        lineWidth: 1.5
                    )
                    .animation(AppMotion.feedback, value: isSelected)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .modifier(AppCardElevation(cornerRadius: cornerRadius))
    }

    /// Native `List` row chrome for plain searchable lists that still need
    /// platform behavior (navigation, swipe actions, search). Keeps the same
    /// 24pt horizontal content inset as `AppCardList` rows and suppresses the
    /// stray top separator above the first visible row while preserving bottom
    /// separators between rows by default.
    func appPlainListRowChrome(
        separator: Visibility = .visible,
        background: Color = AppColor.cardBackground
    ) -> some View {
        self
            .listRowInsets(
                EdgeInsets(
                    top: AppSpacing.sm,
                    leading: AppSpacing.lg,
                    bottom: AppSpacing.sm,
                    trailing: AppSpacing.lg
                )
            )
            .listRowSeparator(.hidden, edges: .top)
            .listRowSeparator(separator, edges: .bottom)
            .listRowBackground(background)
    }

    /// Apply the canonical card chrome to a view that already provides its own
    /// background and clip shape (e.g. ad-hoc cards that can't use `AppCard` or
    /// `appCardStyle`). Renders flat — fill contrast carries separation.
    func appCardElevation() -> some View {
        modifier(AppCardElevation())
    }

    /// Bond fill + continuous-corner clip for the active workout command/timer
    /// panel. Flat by doctrine; the panel's internal hairline divider between
    /// metric and timer is the only line in the surface.
    func appWorkoutPanelChrome() -> some View {
        modifier(AppWorkoutPanelChrome())
    }

    func appBottomSheetChrome() -> some View {
        modifier(AppBottomSheetChromeModifier())
    }

    func navigationBarTitleTruncated(_ title: String, maxGlyphCount: Int = 34) -> some View {
        navigationTitle(title.truncatedForNavigationTitle(maxGlyphCount: maxGlyphCount))
    }

    func appNavigationBarChrome() -> some View {
        self
            // Native scroll-edge visibility: transparent at rest, material only
            // when scrolling content passes underneath. Do not force a style.
            .toolbarBackgroundVisibility(.automatic, for: .navigationBar)
            .appScrollEdgeSoft()
            // Keep nav title + toolbar buttons (e.g. "Add Exercise" / "Done") visible when
            // a `.searchable` field becomes focused. Default behavior collapses them to make
            // room for search, which made auto-focused exercise pickers look like the title
            // and Done were fading out a second after the sheet opened. No-op on screens
            // without `.searchable`.
            .searchPresentationToolbarBehavior(.avoidHidingContent)
    }

    /// Canonical exercise-picker `.searchable` wiring. Uses iOS 26's native
    /// bottom-toolbar search placement so picker sheets keep search reachable
    /// near the thumb while the exercise list stays directly under the header.
    /// On iOS 18 the `.searchToolbarBehavior(.minimize)` minimize-on-scroll
    /// affordance is unavailable; the field still appears in the toolbar.
    @ViewBuilder
    func appExerciseSearchable(text: Binding<String>) -> some View {
        if #available(iOS 26.0, *) {
            self
                .searchable(text: text, placement: .toolbar, prompt: AppCopy.Search.exercises)
                .searchToolbarBehavior(.minimize)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        } else {
            self
                .searchable(text: text, placement: .toolbar, prompt: AppCopy.Search.exercises)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        }
    }

    /// Compatibility entry point for existing screens. SwiftUI owns scroll edges:
    /// do not force hard/soft effects or draw a backdrop behind native bars.
    /// The legacy parameters remain so callers need no layout changes.
    func appScrollEdgeSoft(top: Bool = true, bottom: Bool = true) -> some View {
        self
    }

    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}

// MARK: - Icon circle (shared styling for chevron buttons + status badges)

/// Canonical 36×36 icon-on-soft-fill bubble. Defaults to a circle (used by
/// nav chevrons + status badges); pass `shape: .roundedRect(radius:)` for
/// the rounded-square variant used by paywall benefit rows + onboarding
/// option cards. Single primitive across both shapes so the size/weight
/// of the icon glyph stays consistent everywhere.
struct AppIconCircle<Icon: View>: View {
    enum Shape {
        case circle
        /// Rounded-square variant — pass the canonical radius (`AppRadius.sm` for 36pt tiles, `AppRadius.md` for 40pt).
        case roundedRect(radius: CGFloat)
    }

    enum Surface {
        case control                   // grey neutral
        case accentSoft                // `AppColor.accentSoft` (pale accent container / dim white)
        case background                // `AppColor.background` (on-card badge)
        case cardBackground            // `AppColor.cardBackground` (on-control-bg badge)
        case tinted(Color, opacity: Double)

        var backgroundColor: Color {
            switch self {
            case .control: return AppColor.controlBackground
            case .accentSoft: return AppColor.accentSoft
            case .background: return AppColor.background
            case .cardBackground: return AppColor.cardBackground
            case .tinted(let color, let opacity): return color.opacity(opacity)
            }
        }
    }

    var diameter: CGFloat = 36
    var shape: Shape = .circle
    var surface: Surface = .control
    var maximumScale: CGFloat? = nil
    @ScaledMetric(relativeTo: .body) private var iconScale = 1.0
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        // Scale the bubble diameter with Dynamic Type so the chrome around the
        // glyph grows in lockstep with `AppIcon.image`'s scaled point size —
        // otherwise large-text users see a tiny icon floating in a fixed
        // 36×36 well. Anchored to `.body` to match the icon scaling above.
        let scaledDiameter = diameter * min(iconScale, maximumScale ?? .greatestFiniteMagnitude)
        let glyph = icon()
            .frame(width: scaledDiameter, height: scaledDiameter)
            .background(surface.backgroundColor)

        switch shape {
        case .circle:
            glyph.clipShape(Circle())
        case .roundedRect(let radius):
            glyph.clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
        }
    }
}

/// Standard icon size + weight so all `AppIconCircle` icons match.
enum AppIconCircleSize {
    static let icon: CGFloat = 16
    static let weight: Font.Weight = .semibold
}

// MARK: - Onboarding progress

/// Numeric onboarding counter with an optional nested question label aligned
/// to the trailing edge. The outer onboarding flow intentionally has no bar.
struct OnboardingProgressBar: View {
    struct Detail: Equatable {
        let label: String
        let accessibilityLabel: String
    }

    let step: Int
    let total: Int
    var detail: Detail? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clampedStep: Int { max(1, min(step, max(total, 1))) }
    private var stepText: String { String(format: "%02d", clampedStep) }
    private var totalText: String { String(format: "%02d", max(total, 1)) }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            HStack(spacing: 0) {
                Text("STEP ")
                    .foregroundStyle(AppColor.textSecondary)
                Text(stepText)
                    .foregroundStyle(AppColor.textPrimary)
                    .appNumericValue(value: clampedStep)
                Text(" / \(totalText)")
                    .foregroundStyle(AppColor.textDisabled)
            }

            Spacer(minLength: AppSpacing.sm)

            if let detail {
                Text(detail.label)
                    .foregroundStyle(AppColor.textSecondary)
                    .appNumericValue(value: detail.label)
            }
        }
        .font(AppFont.stepIndicator.font)
        .accessibilityElement(children: .ignore)
        .accessibilityIdentifier("onboarding-progress")
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let stepLabel = "Step \(clampedStep) of \(max(total, 1))"
        guard let detail else { return stepLabel }
        return "\(stepLabel), \(detail.accessibilityLabel)"
    }
}

// MARK: - Segmented selection

/// Native segmented Picker for exclusive or unanswered selection. Only
/// per-item disabling uses the existing buttons; no production caller needs
/// that fallback. System control sizing is intentional, not a custom reskin.
struct AppSegmentedControl<Item: Hashable & Identifiable>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    enum Size {
        case compact
        /// Shared large picker (training days, weekdays, set count). Uses the
        /// 48pt spacing-grid token and the native large size, so taps reach
        /// 44pt on iOS 26 without a screen-specific measurement.
        case weekday

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return AppSpacing.xs
            case .weekday: return AppSpacing.sm
            }
        }

        var minHeight: CGFloat {
            switch self {
            case .weekday: return AppSpacing.xxl
            case .compact: return 44
            }
        }

        var trackHeight: CGFloat? {
            switch self {
            case .weekday: return AppSpacing.xxl
            case .compact: return AppSpacing.xl
            }
        }
    }

    private let selection: Binding<Item?>
    let items: [Item]
    var size: Size = .compact
    let label: String
    let title: (Item) -> String
    /// Optional VoiceOver label override per segment. Use when `title` is a
    /// glyph or single-letter abbreviation that wouldn't read clearly out loud
    /// (e.g. "M / T / W" weekday picker should announce "Monday / Tuesday /
    /// Wednesday"). When nil, `title` is used for both visual and accessibility.
    let accessibilityLabel: ((Item) -> String)?
    /// Optional per-item disabled predicate. Disabled items render with
    /// `textDisabled` and ignore taps — the selection cannot land on them.
    let isDisabled: ((Item) -> Bool)?

    init(
        selection: Binding<Item>,
        items: [Item],
        size: Size = .compact,
        label: String = "Options",
        title: @escaping (Item) -> String,
        accessibilityLabel: ((Item) -> String)? = nil,
        isDisabled: ((Item) -> Bool)? = nil
    ) {
        self.selection = Binding(
            get: { selection.wrappedValue },
            set: { newValue in
                if let newValue {
                    selection.wrappedValue = newValue
                }
            }
        )
        self.items = items
        self.size = size
        self.label = label
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.isDisabled = isDisabled
    }

    /// Optional-selection overload for controls whose initial state is
    /// intentionally unanswered. No segment is highlighted until selection.
    init(
        selection: Binding<Item?>,
        items: [Item],
        size: Size = .compact,
        label: String = "Options",
        title: @escaping (Item) -> String,
        accessibilityLabel: ((Item) -> String)? = nil,
        isDisabled: ((Item) -> Bool)? = nil
    ) {
        self.selection = selection
        self.items = items
        self.size = size
        self.label = label
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.isDisabled = isDisabled
    }

    /// Vertical breathing room above and below each label. `.compact` keeps
    /// mode toggles tight; `.weekday` keeps the existing weekday touch bounds.
    private var verticalPadding: CGFloat { size.verticalPadding }
    private let trackRadius: CGFloat = AppRadius.md
    private let pillRadius: CGFloat = AppRadius.sm
    /// Uniform inset between the track edge and the pill (applied on all four sides).
    /// Using a single value keeps the pill visually centered inside the track.
    private let trackPadding: CGFloat = AppSpacing.xs

    private var trackFill: Color { AppColor.controlBackground }

    private func foreground(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled { return AppColor.textDisabled }
        return isSelected ? AppColor.textPrimary : AppColor.textSecondary
    }

    @ViewBuilder
    var body: some View {
        // Use the platform control on both supported iOS generations, including
        // an unanswered optional selection. Only per-item disabling keeps the
        // existing fallback because native segments do not reliably honor it.
        if isDisabled == nil {
            Picker(label, selection: selection) {
                ForEach(items) { item in
                    Text(title(item))
                        .tag(Optional(item))
                        .accessibilityLabel(accessibilityLabel?(item) ?? title(item))
                }
            }
            .pickerStyle(.segmented)
            .controlSize(size == .compact ? .regular : .large)
            .labelsHidden()
            .accessibilityLabel(label)
            .frame(minHeight: size.minHeight)
        } else {
            buttonSegments
        }
    }

    @ViewBuilder
    private var buttonSegments: some View {
        let trackShape = RoundedRectangle(cornerRadius: trackRadius, style: .continuous)
        let selectedItem = selection.wrappedValue

        ZStack(alignment: .leading) {
            // 1. Track background.
            trackShape
                .fill(trackFill)
                .frame(height: size.trackHeight)

            // 2. Pill — flat fill, no shadow.
            GeometryReader { geo in
                let count = max(items.count, 1)
                let segmentWidth = geo.size.width / CGFloat(count)
                let pillHeight = geo.size.height
                if let selectedItem,
                   let index = items.firstIndex(where: { $0.id == selectedItem.id }) {
                    let pillX = CGFloat(index) * segmentWidth

                    RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                        .fill(AppColor.cardBackground)
                        .frame(width: segmentWidth, height: pillHeight)
                        .offset(x: pillX)
                        .appAnimation(.appConfirm, value: selectedItem.id, reduceMotion: reduceMotion)
                }
            }
            .padding(trackPadding)
            .frame(height: size.trackHeight)
            .clipShape(trackShape)

            // 3. Labels — drawn above the pill, never clipped so text stays crisp.
            //    Segment buttons keep the 44pt interaction floor even when a
            //    size uses a denser visible track. Horizontal trackPadding still
            //    applies so first/last labels don't kiss the track edge.
            HStack(spacing: 0) {
                ForEach(items) { item in
                    let isSelected = item == selectedItem
                    let disabled = isDisabled?(item) ?? false
                    Button {
                        if !isSelected && !disabled {
                            selection.wrappedValue = item
                        }
                    } label: {
                        Text(title(item))
                            .font(AppFont.sectionHeader.font)
                            .foregroundStyle(foreground(isSelected: isSelected, isDisabled: disabled))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, verticalPadding)
                            .frame(minHeight: size.minHeight)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                    .accessibilityLabel(accessibilityLabel?(item) ?? title(item))
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, trackPadding)
        }
        // Lock to the intrinsic height so a greedy parent (e.g. a sheet's
        // `.frame(maxHeight: .infinity)`) cannot stretch the GeometryReader
        // and elongate the pill. The intrinsic height is glyph + verticalPadding.
        .frame(minHeight: size.minHeight)
        .fixedSize(horizontal: false, vertical: true)
    }
}

extension AppSegmentedControl {
    /// ID-binding overload for callers whose state tracks the selection by
    /// `Item.ID` rather than the full `Item` (e.g. when the items carry
    /// non-trivial collateral like nested arrays). Missing IDs remain unselected;
    /// an empty collection never indexes a fabricated first choice.
    init(
        selection: Binding<Item.ID>,
        items: [Item],
        size: Size = .compact,
        label: String = "Options",
        title: @escaping (Item) -> String,
        accessibilityLabel: ((Item) -> String)? = nil,
        isDisabled: ((Item) -> Bool)? = nil
    ) {
        let proxy = Binding<Item?>(
            get: { items.first(where: { $0.id == selection.wrappedValue }) },
            set: { item in
                if let item {
                    selection.wrappedValue = item.id
                }
            }
        )
        self.init(
            selection: proxy,
            items: items,
            size: size,
            label: label,
            title: title,
            accessibilityLabel: accessibilityLabel,
            isDisabled: isDisabled
        )
    }
}

private struct AppBottomSheetChromeModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .top, spacing: 0) {
                AppColor.clear.frame(height: AppSpacing.md)
            }
            .presentationDragIndicator(.visible)
            // Passing `nil` lets iOS use the system sheet corner radius, which matches
            // the device's display corner radius on modern iPhones. A custom value would
            // leave the bottom corners mis-aligned with the screen on iPhone 17.
            .presentationCornerRadius(nil)
            // Keep the platform sheet material instead of forcing an opaque fill.
            .presentationContentInteraction(.scrolls)
            // Shared native edge treatment, consistent with full-screen pages.
            .appScrollEdgeSoft()
    }
}

/// Shared custom-control press feedback. Disabled fill/foreground pairs remain
/// owned by the button; no second disabled dim is applied. Native controls retain
/// their platform style. Reduce Motion and VoiceOver use only the opacity fade.
struct ScaleButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    func makeBody(configuration: Configuration) -> some View {
        let pressed = isEnabled && configuration.isPressed
        let spatial = AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
        configuration.label
            .opacity(pressed ? AppMotion.pressedOpacity : 1)
            .scaleEffect(pressed && spatial ? AppMotion.pressedScale : 1)
            .animation(.appPress, value: pressed)
    }
}

extension String {
    func truncatedForNavigationTitle(maxGlyphCount: Int = 34) -> String {
        guard count > maxGlyphCount else { return self }
        let end = index(startIndex, offsetBy: maxGlyphCount)
        return String(self[..<end]).trimmingCharacters(in: .whitespaces) + "…"
    }
}

#if DEBUG
/// Read-only production-component fixtures. All actions change this page's local state;
/// no workout/template data is written and no purchase actions are invoked.
struct AppComponentCatalog: View {
    @Environment(\.dynamicTypeSize) private var systemTypeSize
    @State private var largeText = false
    @State private var selected = false
    @State private var stepCount = 3
    @State private var field = ""
    @State private var toast: AppToastEvent?
    @State private var celebration: AppCelebrationMoment?
    @State private var celebrationLook = AppCelebrationLook.current
    @State private var showsEditor = false
    @State private var failSave = true
    @State private var segmentMode = SessionHistoryMode.list
    @State private var unansweredMode: SessionHistoryMode?
    @State private var retainedMode: SessionHistoryMode? = .list
    @State private var segmentID = SessionHistoryMode.list.id
    @State private var disabledMode = SessionHistoryMode.list

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SettingsSection(title: "Preview policy", contentInset: AppSpacing.md) {
                    Toggle("Large text preview", isOn: $largeText)
                        .font(AppFont.body.font)
                    Text("Use iOS Accessibility settings to review Reduce Motion and VoiceOver. Press and hold an enabled control to inspect its pressed state. Samples never save workout data.")
                        .appFont(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                }
                samples
                    .environment(\.dynamicTypeSize, largeText ? .accessibility3 : systemTypeSize)
            }
        }
        .navigationTitle("Components")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
        .tint(AppColor.accent)
        .appToast(event: $toast)
        .overlay { AppCelebration(moment: celebration) }
        .environment(\.dynamicTypeSize, largeText ? .accessibility3 : systemTypeSize)
        .sheet(isPresented: $showsEditor) {
            VStack(spacing: 0) {
                AppSetRepEditorSheet(subject: "Sample exercise") { _, _, _ in
                    if failSave {
                        failSave = false
                        return false
                    }
                    return true
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private var samples: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            buttonSamples
            chipSamples
            selectionSamples
            fieldSamples
            surfaceSamples
            feedbackSamples
        }
    }

    private var buttonSamples: some View {
        SettingsSection(title: "Buttons", contentInset: AppSpacing.md) {
            AppPrimaryButton("Default · press and hold") { }
            AppPrimaryButton("Disabled", isEnabled: false) { }
            AppPrimaryButton("Loading", isLoading: true) { }
            AppPrimaryButton("Disabled and loading", isEnabled: false, isLoading: true) { }
            AppPrimaryButton("Inherited disabled") { }.disabled(true)
            AppSecondaryButton("Secondary") { }
            AppSecondaryButton("Secondary disabled", isEnabled: false) { }
            AppSecondaryButton("Destructive", tone: .destructive) { }
            AppGhostButton("Add exercise") { }
            AppGhostButton("Add exercise disabled", isEnabled: false) { }
        }
    }

    private var chipSamples: some View {
        SettingsSection(title: "Chips", contentInset: AppSpacing.md) {
            AppFilterChipBar {
                AppFilterChip(label: "Toggle", isSelected: selected) { selected.toggle() }
                AppFilterChip(label: "Clear", isSelected: true, showsClearGlyphWhenSelected: true) { }
                AppFilterChip(label: "Disabled", isSelected: true) { }.disabled(true)
                AppDropdownChip(label: selected ? "Selected" : "Menu", isActive: selected) {
                    Button("All") { selected = false }
                    Button("Selected") { selected = true }
                }
                AppDropdownChip(label: "Disabled", isActive: true) { Button("Option") { } }
                    .disabled(true)
            }
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                AppTag(text: "Saved", style: .success)
                AppTag(text: "Needs review", style: .warning)
            }
        }
    }

    /// Real shared controls with matching labels for the comparison capture.
    /// Optional state stays native before and after the first answer.
    private var selectionSamples: some View {
        SettingsSection(title: "Segmented selection", contentInset: AppSpacing.md) {
            Text("Native · existing selection")
                .appFont(.caption)
            AppSegmentedControl(selection: $segmentMode, items: SessionHistoryMode.allCases,
                                size: .weekday, label: "Native history view", title: { $0.rawValue })
            Text("Compact native · same content")
                .appFont(.caption)
            AppSegmentedControl(selection: $retainedMode, items: SessionHistoryMode.allCases,
                                label: "Retained history view", title: { $0.rawValue },
                                accessibilityLabel: { "Retained \($0.rawValue)" })
            Text("Unanswered · select, switch, then clear")
                .appFont(.caption)
            AppSegmentedControl(selection: $unansweredMode, items: SessionHistoryMode.allCases,
                                size: .weekday, label: "Unanswered choice", title: { $0.rawValue },
                                accessibilityLabel: { "Unanswered \($0.rawValue)" })
            Button("Clear answer") { unansweredMode = nil }
            Text("Calendar unavailable · List remains selected")
                .appFont(.caption)
            AppSegmentedControl(selection: $disabledMode,
                                items: SessionHistoryMode.allCases, size: .weekday,
                                label: "Per-item disabled choice", title: { $0.rawValue },
                                accessibilityLabel: { "Restricted \($0.rawValue)" },
                                isDisabled: { $0 == .calendar })
            Text("Inherited disabled · native control")
                .appFont(.caption)
            AppSegmentedControl(selection: $segmentMode, items: SessionHistoryMode.allCases,
                                size: .weekday, label: "Disabled history view", title: { $0.rawValue })
                .disabled(true)
            Text("ID binding · same selection model as training week")
                .appFont(.caption)
            AppSegmentedControl(selection: $segmentID, items: SessionHistoryMode.allCases,
                                size: .weekday, label: "ID history view", title: { $0.rawValue })
            AppSegmentedControl(selection: .constant("missing"), items: [SessionHistoryMode](),
                                label: "Empty items", title: { $0.rawValue })
        }
    }

    private var fieldSamples: some View {
        SettingsSection(title: "Inputs", contentInset: AppSpacing.md) {
            TextField("Sample name", text: $field)
                .appInputFieldStyle()
                .accessibilityLabel("Sample name")
            AppStepper(value: "\(stepCount)", isDecrementEnabled: stepCount > 1,
                       isIncrementEnabled: stepCount < 10,
                       onDecrement: { stepCount -= 1 }, onIncrement: { stepCount += 1 })
            AppStepper(value: "3", isDecrementEnabled: false, isIncrementEnabled: false,
                       onDecrement: { }, onIncrement: { })
        }
    }

    private var surfaceSamples: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("Surfaces")
            AppCardList(data: ["First row", "A longer row title that wraps at larger text sizes"], id: \.self) { title in
                AppListRow(title: title, subtitle: "Supporting text", style: .cardListContent)
            }
            EmptyStateCard(title: "No sessions yet", message: "Completed workouts appear here.")
        }
    }

    private var feedbackSamples: some View {
        SettingsSection(title: "Feedback and sheets", contentInset: AppSpacing.md) {
            AppSecondaryButton("Success message") { toast = AppToastEvent("Sample saved", kind: .success) }
            AppSecondaryButton("Error message") { toast = AppToastEvent("Sample failed. Try again.", kind: .error) }
            AppSecondaryButton("Undo message") {
                toast = AppToastEvent("Sample removed", action: AppToastAction(label: "Undo") {
                    toast = AppToastEvent("Sample restored", kind: .success)
                })
            }
            AppSegmentedControl(
                selection: $celebrationLook,
                items: AppCelebrationLook.allCases,
                label: "Celebration look",
                title: { $0.title }
            )
            .onChange(of: celebrationLook) { _, look in AppCelebrationLook.debugOverride = look }
            AppSecondaryButton("First workout") { celebration = AppCelebrationMoment(style: .shower) }
            AppSecondaryButton("Workout finished") { celebration = AppCelebrationMoment(style: .popper) }
            AppSecondaryButton("Target saved") { celebration = AppCelebrationMoment(style: .burst) }
            Toggle("Fail the next sample save", isOn: $failSave).font(AppFont.body.font)
            AppSecondaryButton("Target editor") { showsEditor = true }
        }
    }
}
#endif

// MARK: - Analytics (approved R5 owners)

/// A single combined accessible summary. Its caller owns native sheet presentation.
struct AppStatusSummaryCard: View {
    let word: String
    let sentence: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                Text("Last 4 weeks").appFont(.muted)
                Spacer(minLength: AppSpacing.sm)
                AppIcon.info.image(size: AppIconSize.readiness)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(AppColor.textSecondary)
            Text(word).appFont(.analyticsStatus)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(AppColor.textPrimary)
            Text(sentence).appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, AppSpacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(word). \(sentence)")
        .accessibilityHint("Shows how this works.")
    }
}

/// One chart implementation for display-only cards and interactive exercise detail.
/// All bucketing, metric selection and domains are supplied by AnalyticsEngine.
struct AppTrendChart: View {
    let data: AnalyticsEngine.ChartData
    let caption: String
    var interactive = false
    var height: CGFloat = AppChartMetrics.trendHeight
    var unit = "kg"
    var bodyweight = false
    var metric: AnalyticsEngine.Metric = .weight
    @State private var selectedDate: Date?
    @State private var revealedMetric: AnalyticsEngine.Metric?
    @GestureState private var selectionIsActive = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityDifferentiateWithoutColor) private var differentiate
    @Environment(\.colorSchemeContrast) private var contrast

    private var selected: AnalyticsEngine.ChartPoint? {
        guard metricIsRevealed, selectionIsActive, let selectedDate else { return nil }
        return data.points.min { abs($0.week.timeIntervalSince(selectedDate)) < abs($1.week.timeIntervalSince(selectedDate)) }
    }
    private var selectedMetric: AnalyticsEngine.Metric { bodyweight ? .reps : metric }
    private var metricIsRevealed: Bool { revealedMetric == nil || revealedMetric == selectedMetric }
    private var chartTitle: String { caption.replacingOccurrences(of: " · ", with: ", ") }
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            if interactive {
                Text(selected.map { point in
                    let value = selectedMetric == .weight
                        ? WorkoutTargetFormatter.analyticsPerformance(point.best, bodyweight: bodyweight, unit: unit)
                        : WorkoutTargetFormatter.analyticsChartValue(point.value, metric: selectedMetric, unit: unit)
                    return "\(value) · \(WorkoutTargetFormatter.analyticsDate(point.best.date, now: data.xDomain.upperBound))"
                } ?? " ")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
                    .opacity(selected == nil ? 0 : 1)
                    .accessibilityHidden(selected == nil)
            }
            Chart {
                if data.points.isEmpty {
                    RuleMark(y: .value("", 0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundStyle(AppColor.border)
                }
                ForEach(data.points) { point in
                    if data.points.count > 1 {
                        LineMark(x: .value("", point.week), y: .value("", point.value))
                            .interpolationMethod(.linear)
                            .lineStyle(StrokeStyle(lineWidth: differentiate ? 2.5 : 2))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    if selected?.id == point.id {
                        RuleMark(x: .value("", point.week))
                            .lineStyle(StrokeStyle(lineWidth: 1))
                            .foregroundStyle(AppColor.accent)
                    }
                    PointMark(x: .value("", point.week), y: .value("", point.value))
                        .symbol {
                            Circle()
                                .fill(selected?.id == point.id ? AppColor.accent : (point.id == data.points.last?.id ? AppColor.textPrimary : AppColor.cardBackground))
                                .frame(width: selected?.id == point.id ? 9 : (point.id == data.points.last?.id ? 7 : 5), height: selected?.id == point.id ? 9 : (point.id == data.points.last?.id ? 7 : 5))
                                .overlay { Circle().stroke(selected?.id == point.id ? AppColor.cardBackground : AppColor.textPrimary, lineWidth: selected?.id == point.id ? 2 : 1.5) }
                        }
                }
            }
            .chartXScale(domain: data.xDomain, range: .plotDimension(startPadding: AppSpacing.sm, endPadding: AppSpacing.sm))
            .chartYScale(domain: data.points.isEmpty ? 0...1 : data.yDomain)
            .chartXAxis {
                AxisMarks(values: typeSize.isAccessibilitySize ? [data.xDomain.lowerBound, data.xDomain.upperBound] : data.xLabels) { value in
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day(), centered: false, anchor: value.index == 0 ? .topLeading : value.index == (typeSize.isAccessibilitySize ? 1 : data.xLabels.count - 1) ? .topTrailing : .top, collisionResolution: .disabled)
                        .font(AppFont.metadata.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .chartYAxis {
                if !data.points.isEmpty {
                    AxisMarks(position: .trailing, values: data.yTicks) { value in
                        AxisGridLine().foregroundStyle(contrast == .increased ? AppColor.textSecondary : AppColor.chartGrid)
                        AxisValueLabel {
                            if let number = value.as(Double.self) {
                                Text(number.formatted(.number.precision(.fractionLength(0...2))))
                                    .font(AppFont.metadata.font).foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                }
            }
            // Plot units/domains change immediately. Fade only its drawing;
            // the overlay below stays mounted and accepts scrub input at once.
            .transaction { $0.animation = nil }
            .opacity(metricIsRevealed ? 1 : 0)
            .chartOverlay { proxy in
                if interactive {
                    GeometryReader { geometry in
                        Rectangle().fill(AppColor.clear).contentShape(Rectangle())
                            .gesture(DragGesture(minimumDistance: 0)
                                .updating($selectionIsActive) { _, active, _ in active = true }
                                .onChanged { gesture in
                                    guard let frame = proxy.plotFrame else { return }
                                    let x = gesture.location.x - geometry[frame].origin.x
                                    selectedDate = proxy.value(atX: x, as: Date.self)
                                }
                                .onEnded { _ in selectedDate = nil })
                    }
                }
            }
            .frame(height: typeSize.isAccessibilitySize ? max(height, AppChartMetrics.accessibleTrendHeight) : height)
            .accessibilityChartDescriptor(TrendDescriptor(data: data, title: chartTitle, metric: selectedMetric, unit: unit))
            .accessibilityHidden(!interactive)
            .accessibilityIdentifier("analytics-trend-chart")
            .onChange(of: selectedMetric) { _, _ in selectedDate = nil }
            Text(data.points.isEmpty ? "No sets in 12 weeks" : caption)
                .font(AppFont.muted.font)
                .foregroundStyle(AppColor.textSecondary)
                .opacity(metricIsRevealed ? 1 : 0)
        }
        .transaction { transaction in
            // Hide the replacement immediately, even inside a native Picker
            // transaction. Its reveal never interpolates kg into reps/volume.
            if let revealedMetric, revealedMetric != selectedMetric {
                transaction.animation = nil
            }
        }
        .task(id: selectedMetric) {
            guard revealedMetric != nil else {
                // Already-loaded content has no entrance/re-entry animation.
                var instant = Transaction()
                instant.disablesAnimations = true
                withTransaction(instant) { revealedMetric = selectedMetric }
                return
            }
            guard revealedMetric != selectedMetric else { return }
            // Give the hidden replacement its own render transaction. There is
            // no timed delay, recreated Chart, disabled gesture or cached data.
            await Task.yield()
            guard !Task.isCancelled else { return }
            withAnimation(AppMotion.transition) { revealedMetric = selectedMetric }
        }
    }
    private struct TrendDescriptor: AXChartDescriptorRepresentable {
        let data: AnalyticsEngine.ChartData
        let title: String
        let metric: AnalyticsEngine.Metric
        let unit: String
        func makeChartDescriptor() -> AXChartDescriptor {
            let x = AXNumericDataAxisDescriptor(title: "", range: data.xDomain.lowerBound.timeIntervalSince1970...data.xDomain.upperBound.timeIntervalSince1970, gridlinePositions: []) { value in
                Date(timeIntervalSince1970: value).formatted(.dateTime.month(.wide).day())
            }
            let y = AXNumericDataAxisDescriptor(title: metric.rawValue, range: data.yDomain, gridlinePositions: data.yTicks) { WorkoutTargetFormatter.analyticsChartValue($0, metric: metric, unit: unit, spoken: true) }
            let series = AXDataSeriesDescriptor(name: title, isContinuous: data.points.count > 1, dataPoints: data.points.map { AXDataPoint(x: $0.week.timeIntervalSince1970, y: $0.value) })
            return AXChartDescriptor(title: title, summary: nil, xAxis: x, yAxis: y, additionalAxes: [], series: [series])
        }
        func updateChartDescriptor(_ descriptor: AXChartDescriptor) {
            let updated = makeChartDescriptor()
            descriptor.title = updated.title
            descriptor.xAxis = updated.xAxis
            descriptor.yAxis = updated.yAxis
            descriptor.series = updated.series
        }
    }
}

/// R5 lift anatomy. Native NavigationLink ownership stays with the page.
struct AppMainLiftCard: View {
    let title: String
    let icon: AppIcon?
    let lift: AnalyticsEngine.Lift?
    let chart: AnalyticsEngine.ChartData
    let unit: String
    let now: Date
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        AppCard(contentInset: 0) {
            VStack(alignment: .leading, spacing: AppSpacing.smd) {
                HStack(spacing: AppSpacing.sm) {
                    Text(title).font(AppFont.sectionHeader.font).lineLimit(2)
                }
                .appNavigationDisclosure(lift?.latest != nil)
                if let lift, let latest = lift.latest {
                    Self.metric(latest, bodyweight: lift.bodyweight, unit: unit)
                    Text("Latest · \(WorkoutTargetFormatter.analyticsDate(latest.date, now: now))")
                        .font(AppFont.muted.font).foregroundStyle(AppColor.textSecondary)
                    if lift.comparison.isComparable { change(lift) }
                    AppTrendChart(data: chart, caption: lift.bodyweight ? "Most reps per week · 12 weeks" : "Best set per week · 12 weeks", unit: unit, bodyweight: lift.bodyweight)
                } else {
                    Text("No sessions yet").font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                    AppTrendChart(data: chart, caption: "No sets in 12 weeks")
                }
            }
            .padding(AppSpacing.md)
            if let lift, let best = lift.best {
                AppDivider()
                Group {
                    if typeSize.isAccessibilitySize {
                        VStack(alignment: .leading, spacing: AppSpacing.smd) { footer(lift, best: best) }
                    } else {
                        HStack(alignment: .top, spacing: AppSpacing.md) { footer(lift, best: best) }
                    }
                }
                .padding(AppSpacing.md)
            }
        }
        .foregroundStyle(AppColor.textPrimary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }
    private func change(_ lift: AnalyticsEngine.Lift) -> some View {
        Text("4-week comparison · \(WorkoutTargetFormatter.analyticsComparison(lift.comparison, unit: unit))")
            .font(AppFont.caption.font).monospacedDigit()
            .foregroundStyle(lift.comparison.isUp ? AppColor.textPrimary : AppColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
    @ViewBuilder private func footer(_ lift: AnalyticsEngine.Lift, best: AnalyticsEngine.Performance) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Best").appFont(.muted).foregroundStyle(AppColor.textSecondary)
            Text("\(WorkoutTargetFormatter.analyticsPerformance(best, bodyweight: lift.bodyweight, unit: unit, onBodyweight: lift.exercise.isBodyweight)) · \(WorkoutTargetFormatter.analyticsDate(best.date, now: now))")
                .font(AppFont.caption.font).monospacedDigit()
        }.frame(maxWidth: .infinity, alignment: .leading)
        if let target = lift.target {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Next").appFont(.muted).foregroundStyle(AppColor.textSecondary)
                Text(WorkoutTargetFormatter.analyticsTarget(target, unit: unit, onBodyweight: lift.exercise.isBodyweight)).font(AppFont.caption.font).monospacedDigit()
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    static func iconTile(_ icon: AppIcon, side: CGFloat, detail: Bool = false) -> some View {
        AppIconCircle(diameter: side, shape: .roundedRect(radius: AppRadius.sm), surface: .background, maximumScale: 2) {
            icon.image(size: detail ? AppIconSize.exerciseDetail : AppIconSize.exercise, weight: .regular, maximumScale: 2)
                .foregroundStyle(AppColor.textPrimary)
        }.accessibilityHidden(true)
    }
    static func metric(_ value: AnalyticsEngine.Performance, bodyweight: Bool, unit: String, numberStyle: AppFont = .numericInput) -> some View {
        let weight = WorkoutTargetFormatter.analyticsWeight(value.weight, unit: unit)
        let number = bodyweight || value.weight == 0 ? "BW" : weight.components(separatedBy: " ").dropLast().joined(separator: " ")
        let suffix = bodyweight || value.weight == 0 ? " × \(value.reps.formatted())" : " \(unit) × \(value.reps.formatted())"
        return (Text(number).appFont(numberStyle) + Text(suffix).appFont(.caption))
            .monospacedDigit().minimumScaleFactor(0.7).lineLimit(1)
            .foregroundStyle(AppColor.textPrimary)
    }
    private var spokenLabel: String {
        guard let lift, let latest = lift.latest else { return "\(title). No sessions yet" }
        var text = "\(title). Latest session: \(WorkoutTargetFormatter.analyticsSpokenSet(latest, bodyweight: lift.bodyweight, unit: unit)), \(latest.date.formatted(.dateTime.month(.wide).day()))."
        // Spoken like the card reads: the comparison only when there is one.
        if lift.comparison.isComparable {
            text += " Four-week comparison: \(WorkoutTargetFormatter.analyticsComparison(lift.comparison, unit: unit))."
        }
        if let best = lift.best { text += " Best \(WorkoutTargetFormatter.analyticsSpokenSet(best, bodyweight: lift.bodyweight, unit: unit))." }
        if let target = lift.target { text += " Next \(WorkoutTargetFormatter.analyticsSpokenTarget(target, unit: unit))." }
        return text
    }
}


// MARK: - Final B active workout (approved 20 October 2026)

/// Geometry belongs to the logging family, not individual screens.
enum AppWorkoutMetrics {
    static let compactWidth: CGFloat = 343
    static let focusLineWidth: CGFloat = 2
    static let rowHeight: CGFloat = 48
    static let editingRowHeight: CGFloat = 56
    static let indexWidth: CGFloat = 30
    static let chipHeight: CGFloat = 54
    static let compactChipHeight: CGFloat = 50
    static let weightChipWidth: CGFloat = 140
    static let repsChipWidth: CGFloat = 64
}

/// The screen owns its ScrollView/position; this owner supplies only list rhythm.
struct WorkoutDayList<Content: View>: View {
    @ViewBuilder let content: () -> Content
    var body: some View {
        LazyVStack(alignment: .leading, spacing: AppSpacing.sm, content: content)
            .scrollTargetLayout()
    }
}

/// An exercise's editable rows share one existing card surface.
struct ExerciseLoggingCard<Content: View>: View {
    let name: String
    /// The lifter's own pinned note ("Seat 4, pin 6"); hidden when empty.
    var note = ""
    @Binding var isBodyweight: Bool
    let onSkip: () -> Void
    let onAddSet: () -> Void
    var onSelect: (() -> Void)? = nil
    /// Optional menu actions; nil hides the item.
    var onShowHistory: (() -> Void)? = nil
    var onSwap: (() -> Void)? = nil
    var onEditNote: (() -> Void)? = nil
    var onRemoveAddedSet: (() -> Void)? = nil
    @ViewBuilder let content: () -> Content
    var body: some View {
        AppCard(contentInset: AppSpacing.sm) {
            HStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                    Group {
                        if let onSelect {
                            Button(name, action: onSelect).buttonStyle(ScaleButtonStyle())
                        } else { Text(name) }
                    }
                    .font(AppFont.sectionHeader.font).foregroundStyle(AppColor.textPrimary).lineLimit(2)
                    if !note.isEmpty {
                        Text(note).appFont(.muted).foregroundStyle(AppColor.textSecondary).lineLimit(2)
                            .accessibilityIdentifier("exercise-note")
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Menu {
                    Section {
                        if let onShowHistory {
                            Button(AppCopy.Workout.exerciseHistory, action: onShowHistory)
                        }
                        if let onSwap {
                            Button(AppCopy.Workout.swapExercise, action: onSwap)
                        }
                        if let onEditNote {
                            Button(note.isEmpty ? AppCopy.Workout.addNote : AppCopy.Workout.editNote, action: onEditNote)
                        }
                        Toggle(AppCopy.Workout.bodyweightToggle, isOn: $isBodyweight)
                    }
                    Section {
                        if let onRemoveAddedSet {
                            Button(AppCopy.Workout.removeAddedSet, role: .destructive, action: onRemoveAddedSet)
                        }
                        Button(AppCopy.Workout.skipExerciseAction, role: .destructive, action: onSkip)
                    }
                } label: {
                    Label(AppCopy.Workout.exerciseOptions, systemImage: AppIcon.more.systemName)
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .tint(AppColor.textPrimary)
                .accessibilityIdentifier("exercise-menu")
            }
            .padding(.horizontal, AppSpacing.xs)
            content()
            // Same "add to this list" row as a routine's "Add exercise".
            AppCardListAddRow(AppCopy.Workout.addSet, action: onAddSet)
                .padding(.horizontal, AppSpacing.smd)
        }
    }
}

/// Only the current row owns a completion action; values/focus stay with the caller.
struct CurrentSetRow<Value: View>: View {
    let number: Int
    let supportingText: String?
    let isSetup: Bool
    let isCTAEnabled: Bool
    var showsCTA: Bool = true
    var showsAction: Bool = true
    var showsCompletion: Bool = true
    let onComplete: () -> Void
    let onSaveTarget: () -> Void
    @ViewBuilder let value: () -> Value
    var body: some View {
        Group {
        if showsCTA {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                Text("Set \(number)").appFont(.muted)
                Spacer(minLength: AppSpacing.sm)
                if let supportingText {
                    Text(supportingText).appFont(.muted)
                        .multilineTextAlignment(.trailing)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .foregroundStyle(AppColor.textSecondary)
            value()
            if showsCTA {
                Group {
                    AppPrimaryButton(
                        isSetup ? AppCopy.Workout.saveTarget : AppCopy.Workout.completeSetNumbered(number),
                        isEnabled: isCTAEnabled && showsAction,
                        action: isSetup ? onSaveTarget : onComplete
                    )
                }
                .opacity(showsAction ? 1 : 0)
                .allowsHitTesting(showsAction)
                .accessibilityHidden(!showsAction)
                .transition(.opacity)
                .accessibilityIdentifier(isSetup ? "save-starting-target" : "complete-set-\(number)")
            }
        }
        .padding(AppSpacing.smd)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.cardRowFill, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .padding(.vertical, AppSpacing.xxs)
        } else {
            HStack(spacing: AppSpacing.xs) {
                Text("\(number)").appFont(.stepIndicator)
                    .foregroundStyle(AppColor.textTertiary)
                    .frame(width: AppWorkoutMetrics.indexWidth, alignment: .leading)
                value()
                if showsCompletion { AppIcon.checkmarkFilled.image(size: 20).accessibilityHidden(true) }
            }
            .padding(.horizontal, AppSpacing.smd)
            .frame(minHeight: AppWorkoutMetrics.editingRowHeight)
        }
        }
        .transition(.opacity.animation(AppMotion.transition))
    }
}

/// Menu and Undo are sibling controls; the reserved Undo slot never moves the check.
struct LoggedSetRow: View {
    let number: Int
    let value: String
    /// A personal record at the moment it was logged (same rule as History).
    var isPR = false
    let showsUndo: Bool
    let onUndo: () -> Void
    let onEdit: () -> Void
    let onMarkNotDone: () -> Void
    var body: some View {
        HStack(spacing: AppSpacing.xs) {
            Menu {
                Button("Edit", systemImage: AppIcon.edit.systemName, action: onEdit)
                Button("Mark not done", systemImage: AppIcon.undo.systemName, role: .destructive, action: onMarkNotDone)
            } label: {
                HStack(spacing: AppSpacing.xs) {
                    Text("\(number)").appFont(.stepIndicator)
                        .foregroundStyle(AppColor.textTertiary)
                        .frame(width: AppWorkoutMetrics.indexWidth, alignment: .leading)
                    // The tag sits beside the value; the Undo slot and check
                    // after the menu keep their positions.
                    HStack(spacing: AppSpacing.sm) {
                        Text(value).appFont(.performance).monospacedDigit()
                        if isPR { historyPRTag() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: AppWorkoutMetrics.rowHeight)
                .contentShape(Rectangle())
            }
            .tint(AppColor.textPrimary)
            .accessibilityIdentifier("logged-set-\(number)")
            .accessibilityLabel(isPR ? "Set \(number), \(value), \(AppCopy.Workout.personalRecord), done"
                                     : "Set \(number), \(value), done")
            .accessibilityAction(named: "Edit", onEdit)
            .accessibilityAction(named: "Mark not done", onMarkNotDone)
            Group {
                if showsUndo {
                    AppGhostButton(AppCopy.Toast.undo, layout: .inline, action: onUndo)
                } else {
                    AppColor.clear.frame(width: 44, height: 44)
                        .accessibilityHidden(true)
                }
            }
            .animation(AppMotion.transition, value: showsUndo)
            AppIcon.checkmarkFilled.image(size: 20)
                .foregroundStyle(AppColor.textPrimary).accessibilityHidden(true)
        }
        .padding(.horizontal, AppSpacing.smd)
        .foregroundStyle(AppColor.textPrimary)
        .transition(.opacity.animation(AppMotion.transition))
    }
}

struct PlannedSetRow: View {
    let number: Int
    let value: String
    let onEdit: () -> Void
    var body: some View {
        Button(action: onEdit) {
            HStack(spacing: AppSpacing.xs) {
                Text("\(number)").appFont(.stepIndicator)
                    .frame(width: AppWorkoutMetrics.indexWidth, alignment: .leading)
                Text(value).appFont(.performance).monospacedDigit()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.smd)
            .frame(minHeight: AppWorkoutMetrics.rowHeight)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityIdentifier("planned-set-\(number)")
        .accessibilityLabel("Set \(number), planned, \(value)")
        .accessibilityHint("Double-tap to edit.")
    }
}

struct ExerciseSummaryRow: View {
    let name: String
    let summary: String
    let isCompleted: Bool
    let showsUndo: Bool
    let onUndo: () -> Void
    let onSelect: () -> Void
    /// One of this exercise's sets was a personal record. The done card closes
    /// right after the last set, so a final-set PR would otherwise never show.
    var showsPR = false
    var body: some View {
        // Match the expanded exercise header's 8pt card + 4pt title inset.
        // Each summary is its own flat card, including upcoming exercises.
        AppCard(contentInset: AppSpacing.md, verticalInset: 0, cornerRadius: AppRadius.md) {
            HStack(spacing: AppSpacing.sm) {
                Button(action: onSelect) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        Text(name).font(AppFont.sectionHeader.font).lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if !summary.isEmpty || showsPR {
                            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                                if !summary.isEmpty {
                                    Text(summary).appFont(.body).monospacedDigit()
                                        .foregroundStyle(AppColor.textSecondary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                if showsPR { historyPRTag() }
                            }
                        }
                    }
                    .padding(.vertical, AppSpacing.md)
                    .frame(minHeight: 52).contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(name)
                .accessibilityValue([isCompleted ? "Completed" : "Upcoming", summary,
                                     showsPR ? AppCopy.Workout.personalRecord : ""]
                    .filter { !$0.isEmpty }.joined(separator: ", "))
                .accessibilityHint("Opens exercise sets")
                if isCompleted {
                    if showsUndo {
                        AppGhostButton(AppCopy.Toast.undo, layout: .inline, action: onUndo)
                    }
                    AppIcon.checkmarkFilled.image(size: 20)
                        .accessibilityHidden(true)
                }
            }
            .foregroundStyle(isCompleted ? AppColor.textSecondary : AppColor.textPrimary)
        }
    }
}

/// Fixed bottom rest chrome. No duplicated next-set label or pause action.
struct RestBar: View {
    enum State: Equatable { case idle, running, finished }
    let timeText: String
    let state: State
    let progress: Double
    /// The manager's actual deadline and duration; never inferred from rounded text.
    var endDate: Date? = nil
    var totalDuration: TimeInterval = 0
    let canDecrease: Bool
    let onDecrease: () -> Void
    let onIncrease: () -> Void
    let onSkip: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    private var spatial: Bool {
        AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
    }

    var body: some View {
        VStack(spacing: 0) {
            Self.progressLine(progress: progress, endDate: endDate, totalDuration: totalDuration,
                              isRunning: state == .running, spatial: spatial)
            VStack(spacing: AppSpacing.sm) {
                Self.status(timeText: timeText, state: state, spatial: spatial)
                controls
            }
            .padding(AppSpacing.md)
        }
        .background(AppColor.background.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { AppDivider() }
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("workout-rest-bar")
    }

    /// Both bottom modes use this header, so the timer never changes its type
    /// or leading/trailing anchors when the keyboard or timer state changes.
    static func status(timeText: String, state: State, spatial: Bool) -> some View {
        let displayTime = state == .finished ? "0:00" : timeText
        return HStack(spacing: AppSpacing.sm) {
            ZStack(alignment: .leading) {
                Text(AppCopy.Workout.restLabel)
                    .opacity(state == .finished ? 0 : 1)
                Text(AppCopy.Workout.restFinishedInline)
                    .opacity(state == .finished ? 1 : 0)
            }
            .font(AppFont.caption.font)
            .foregroundStyle(AppColor.textSecondary)
            .animation(AppMotion.transition, value: state)
            Spacer(minLength: AppSpacing.sm)
            Text(displayTime).appFont(.performance).monospacedDigit()
                .foregroundStyle(AppColor.textPrimary)
                .contentTransition(spatial ? .numericText(countsDown: true) : .opacity)
                .animation(AppMotion.transition, value: displayTime)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(state == .finished ? AppCopy.Workout.restFinishedInline : AppCopy.Workout.restLabel)
        .accessibilityValue(displayTime)
        .accessibilityIdentifier("rest-duration")
    }

    /// One deadline-driven progress owner for resting and keyboard editing.
    static func progressLine(progress: Double, endDate: Date?, totalDuration: TimeInterval,
                             isRunning: Bool, spatial: Bool) -> some View {
        TimelineView(.animation(paused: !isRunning || endDate == nil || !spatial)) { timeline in
            GeometryReader { geometry in
                let sampled = spatial ? timeline.date : Date.now
                let value = isRunning && totalDuration > 0
                    ? endDate.map { $0.timeIntervalSince(sampled) / totalDuration } ?? progress : progress
                let fraction = value.isFinite ? min(1, max(0, value)) : 0
                ZStack(alignment: .leading) {
                    AppColor.controlBackground
                    AppColor.accent.frame(width: geometry.size.width * fraction)
                }
                .transaction { $0.animation = nil }
            }
        }
        .frame(height: 3)
        .opacity(isRunning ? 1 : 0)
        .animation(AppMotion.transition, value: isRunning)
        .accessibilityHidden(true)
    }

    private var controls: some View {
        HStack(spacing: AppSpacing.sm) {
            control(AppCopy.Workout.restMinus, label: AppCopy.Workout.restMinusLabel, action: onDecrease)
                .disabled(!canDecrease)
            control(AppCopy.Workout.restPlus, label: AppCopy.Workout.restPlusLabel, action: onIncrease)
            control(AppCopy.Workout.restSkip, label: "Skip rest", action: onSkip)
        }
        .frame(maxWidth: .infinity)
        .disabled(state != .running)
        .allowsHitTesting(state == .running)
        .accessibilityHidden(state != .running)
    }

    private func control(_ text: String, label: String, action: @escaping () -> Void) -> some View {
        AppSecondaryButton(text, detailAlignment: .center, action: action)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .accessibilityLabel(label)
            .accessibilityIdentifier(text)
    }
}
