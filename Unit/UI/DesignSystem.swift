//
//  DesignSystem.swift
//  Unit
//
//  Shared UI atoms, molecules, organisms, and screen wrapper.
//

import SwiftUI
import SwiftData
import UIKit

// MARK: - Atoms

/// Role-based color tokens. Every color used in the app resolves to a case here —
/// no `Color.black/.gray`, no raw hex literals in page files. **Light-mode only**
/// per CLAUDE.md §4 rule 3 — no dark-mode variants are maintained.
enum AppColor {
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

    /// Filled segment in multi-step progress (e.g. onboarding) — softer than `textPrimary` but reads clearly against `border` for inactive steps.
    static let progressSegmentFill = Color(uiColor: uicolor(0x3A3A3A))

    // Interactive
    static let accent = Color(uiColor: uicolor(0x0A0A0A))
    static let accentForeground = Color(uiColor: uicolor(0xF6F6F6))
    static let accentSoft = Color(uiColor: uicolor(0xEBEBEB))

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

/// Bundled custom font helpers. PostScript names match the .ttf filenames in
/// `Unit/Resources/Fonts/`. Use these only via `AppFont`; do not call from
/// feature code.
extension Font {
    /// Weight subset we ship — Geist is bundled as Medium / SemiBold / Bold only.
    enum AppWeight {
        case medium, semibold, bold
        var suffix: String {
            switch self {
            case .medium:   return "Medium"
            case .semibold: return "SemiBold"
            case .bold:     return "Bold"
            }
        }
    }

    /// `relativeTo:` anchors the bundled custom face to a system text style so it
    /// scales with Dynamic Type — without this, `Font.custom(_:size:)` returns a
    /// fixed-size font that ignores the user's text-size preference. Default
    /// `.body` keeps callers that don't care unaffected; the `AppFont` switch
    /// below picks a tighter style per token (largeTitle for splash, title2 for
    /// product heading, caption2 for tiny caps, etc.) so the type scale grows
    /// proportionally at AX sizes instead of all flattening to body.
    static func geist(_ weight: AppWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom("Geist-\(weight.suffix)", size: size, relativeTo: textStyle)
    }

    static func geistMono(_ weight: AppWeight, size: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> Font {
        .custom("GeistMono-\(weight.suffix)", size: size, relativeTo: textStyle)
    }
}

/// UIKit mirrors of `Font.geist` / `Font.geistMono` for surfaces that have to
/// reach for a `UIFont` directly — `UINavigationBarAppearance`, `UITabBarItem`,
/// `UISegmentedControl`. Keeps the chrome on the same atom as the SwiftUI body
/// type so the app never paints SF Pro by accident. Falls back to `systemFont`
/// only if PostScript registration fails (defensive — not expected in shipping).
extension UIFont {
    /// `relativeTo:` wraps the unscaled `UIFont` in `UIFontMetrics` so nav-bar
    /// titles, segmented-control labels, and tab-bar labels respond to Dynamic
    /// Type. Default `.body`; pass a tighter style (`.largeTitle`, `.headline`,
    /// `.caption2`) at the call site so each chrome surface grows at the rate
    /// its text style expects.
    static func geist(_ weight: Font.AppWeight, size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let base = UIFont(name: "Geist-\(weight.suffix)", size: size) ?? systemFont(ofSize: size, weight: weight.uiKitWeight)
        return UIFontMetrics(forTextStyle: textStyle).scaledFont(for: base)
    }

    static func geistMono(_ weight: Font.AppWeight, size: CGFloat, relativeTo textStyle: UIFont.TextStyle = .body) -> UIFont {
        let base = UIFont(name: "GeistMono-\(weight.suffix)", size: size) ?? .monospacedSystemFont(ofSize: size, weight: weight.uiKitWeight)
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
/// **Mono doctrine.** Sans is **Geist**. **Geist Mono is reserved for two roles
/// only**: (1) numerics under fatigue (hero counts, set results, step counters)
/// — weight per role; (2) caps micro-labels (`overline`, `smallLabel`,
/// `overlineStrong`) for footers, footnotes, very-small text, card eyebrows, and
/// chips. Caps tokens render via `Text.appCapsLabel(_:)` which bakes
/// `.textCase(.uppercase)`. **Buttons and CTAs are always sans, never mono.**
///
/// **Weight floor.** Geist is bundled as Medium / SemiBold / Bold only — no
/// Regular .ttf. So `.medium` IS the design-system "regular" baseline for caps
/// tokens; selected/emphasized state escalates to `.bold` (see `overlineStrong`).
/// PostScript names match the bundled .ttf filenames.
enum AppFont {
    // Body hierarchy
    case largeTitle
    case title
    case sectionHeader
    case body
    case caption
    case muted

    // Display / specialized — previously loose `static let`s, now first-class cases
    /// 13pt mono medium UPPERCASE (+0.6 tracking) — card eyebrow, status/filter
    /// chip default state, footer/footnote micro-label. Apply via
    /// `Text.appCapsLabel(.overline)` so uppercase is baked.
    case overline
    /// 11pt mono medium UPPERCASE (+1.0 tracking) — tiny "WAS" / "MOST POPULAR"
    /// style caps. Apply via `Text.appCapsLabel(.smallLabel)`.
    case smallLabel
    /// 13pt mono BOLD UPPERCASE (+0.6 tracking) — selected/active chip state
    /// (filled background) and emphasized eyebrows. Sibling of `overline`.
    /// Apply via `Text.appCapsLabel(.overlineStrong)`.
    case overlineStrong
    /// 56pt bold — splash welcome title only.
    case splashTitle
    /// 16pt medium — splash welcome eyebrow / tagline pair.
    case splashWelcome
    /// 36pt mono bold — workout metric hero, big numerics.
    case numericDisplay
    /// 36pt sans bold + tabular digits — numeric input fields (`AdjustResultSheet`
    /// weight / reps). Same scale and weight as `numericDisplay`, but proportional
    /// glyphs so a decimal like `82.5` doesn't show a wide gap around the period
    /// (mono cells inflate punctuation). `.monospacedDigit()` keeps digits tabular
    /// so values still align if rendered in a column.
    case numericInput
    /// 14pt mono semibold — set step counters in `SetProgressIndicator` (numeric).
    case stepIndicator
    /// 24pt bold — product-screen heading on `ProductTopBar`, hero copy on empty states.
    case productHeading
    /// 17pt sans bold — primary CTA labels, top-bar text actions. **Never mono**
    /// (mono is reserved for numerics and caps micro-labels).
    case productAction
    /// 15pt mono semibold — set-result / PR rows in History (numeric).
    case performance
    /// 15pt system — emoji glyphs concatenated inside `.caption` text. Geist has
    /// no emoji coverage, so an inline emoji needs the system font to fall back
    /// to Apple Color Emoji at the same visual size as `.caption`.
    case emojiCaption

    var font: Font {
        switch self {
        case .largeTitle:     return .geist(.bold,     size: 22, relativeTo: .title2)
        case .title:          return .geist(.bold,     size: 20, relativeTo: .title3)
        case .sectionHeader:  return .geist(.semibold, size: 17, relativeTo: .body)
        case .body:           return .geist(.medium,   size: 17, relativeTo: .body)
        case .caption:        return .geist(.medium,   size: 15, relativeTo: .subheadline)
        case .muted:          return .geist(.medium,   size: 13, relativeTo: .footnote)
        case .overline:       return .geistMono(.medium,   size: 13, relativeTo: .footnote)
        case .smallLabel:     return .geistMono(.medium,   size: 11, relativeTo: .caption2)
        case .overlineStrong: return .geistMono(.bold,     size: 13, relativeTo: .footnote)
        case .splashTitle:    return .geist(.bold,     size: 56, relativeTo: .largeTitle)
        case .splashWelcome:  return .geist(.medium,   size: 16, relativeTo: .callout)
        case .productHeading: return .geist(.bold,     size: 24, relativeTo: .title2)
        case .numericDisplay: return .geistMono(.bold,     size: 36, relativeTo: .title)
        case .numericInput:   return .geist(.bold,         size: 36, relativeTo: .title).monospacedDigit()
        case .stepIndicator:  return .geistMono(.semibold, size: 14, relativeTo: .footnote)
        case .productAction:  return .geist(.bold,         size: 17, relativeTo: .body)
        case .performance:    return .geistMono(.semibold, size: 15, relativeTo: .subheadline)
        case .emojiCaption:
            if let emoji = UIFont(name: "AppleColorEmoji", size: 15) {
                return Font(emoji)
            }
            return .system(size: 15)
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
        case .largeTitle:     return -0.4
        case .splashTitle:    return -1.2
        case .productHeading: return -0.4
        case .numericDisplay: return -0.6
        case .numericInput:   return -0.6   // mirrors numericDisplay so the bumped value reads at the same spacing weight
        case .overline:       return 0.6    // mono caps spacing
        case .overlineStrong: return 0.6    // mono caps spacing (sibling of .overline)
        case .smallLabel:     return 1.0    // tighter, smaller caps need wider tracking
        default:              return 0
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
    /// mono-caps micro-label — card eyebrow, footer/footnote, status chip,
    /// filter chip, dropdown chip. Returns `some View` because `.textCase` is
    /// environment-scoped, not Text-only — so chain non-Text modifiers after it.
    /// Use this instead of `Text.appFont(.overline)` for the caps tokens; using
    /// `appFont` on a caps token produces the right mono weight but skips the
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

/// Motion tokens. The single source of truth for every duration, curve, and spring
/// in the app. Page files call `.appPress` / `.appState` / etc. — never raw
/// `.easeInOut(duration:)` literals.
///
/// Doctrine, restated for the next reader:
/// - **State only.** Motion conveys feedback, reveal, transition between views.
///   Decorative motion is banned in the hot loop (PRODUCT.md, DESIGN.md §4).
/// - **Ease-out only.** No bounce, no elastic, no overshoot. Users are mid-set.
/// - **≤ 320 ms.** The product register cap. Anything longer reads as laggy.
/// - **Exit ≈ 75 % of enter.** Symmetry between dismissal and presentation reads
///   wrong on touch devices — exits should feel decisive.
///
/// Reduce Motion is a call-site contract: `reduceMotion ? nil : .appXxx`, or use
/// `.appAnimation(_:value:reduceMotion:)`. There is no global wrapper because
/// every surface needs to decide its own fallback (sometimes nil, sometimes a
/// shorter cross-fade). See `OnboardingSplashView` for the canonical pattern.
enum AppMotion {
    enum Duration {
        /// 150 ms — instant feedback (button press, toggle confirm). Matches `ScaleButtonStyle`.
        static let press: Double = 0.15
        /// 200 ms — state toggle (toast in/out, tier select, mode swap).
        static let state: Double = 0.20
        /// 250 ms — content reveal (text content swap, progress fill).
        static let reveal: Double = 0.25
        /// 320 ms — entrance (card / sheet appear, hero element).
        static let enter: Double = 0.32
        /// 180 ms — exit (~75 % of enter; dismissal is decisive).
        static let exit: Double = 0.18
    }

    /// Easing curves translated from the design-for-AI motion doctrine
    /// (cubic-bezier values are the same as `--ease-out-quart/quint/expo`).
    enum Curve {
        /// `cubic-bezier(0.25, 1, 0.5, 1)` — smooth, refined. Default for state changes.
        static func quart(_ duration: Double) -> Animation {
            .timingCurve(0.25, 1, 0.5, 1, duration: duration)
        }
        /// `cubic-bezier(0.22, 1, 0.36, 1)` — slightly snappier. Default for entrances.
        static func quint(_ duration: Double) -> Animation {
            .timingCurve(0.22, 1, 0.36, 1, duration: duration)
        }
        /// `cubic-bezier(0.16, 1, 0.3, 1)` — confident, decisive. Reserve for hero moments.
        static func expo(_ duration: Double) -> Animation {
            .timingCurve(0.16, 1, 0.3, 1, duration: duration)
        }
    }

    /// Confirmation spring (segmented pill, set-completed pulse). Damping ≥ 0.85
    /// keeps it brisk — anything looser reads as "bouncy" and is banned by doctrine.
    static let confirmSpring: Animation = .spring(response: 0.32, dampingFraction: 0.85)
}

extension Animation {
    /// 150 ms easeInOut — button press feedback. Ties `ScaleButtonStyle` to
    /// the token system; previously hardcoded.
    static let appPress: Animation = .easeInOut(duration: AppMotion.Duration.press)

    /// 200 ms ease-out-quart — state toggles (visibility, mode swaps, tier select).
    static let appState: Animation = AppMotion.Curve.quart(AppMotion.Duration.state)

    /// 250 ms ease-out-quart — content swap (numeric text, progress fills).
    static let appReveal: Animation = AppMotion.Curve.quart(AppMotion.Duration.reveal)

    /// 320 ms ease-out-quint — entrance (card appear, sheet present, hero land).
    static let appEnter: Animation = AppMotion.Curve.quint(AppMotion.Duration.enter)

    /// 180 ms ease-out-quart — exit (75 % of enter, decisive).
    static let appExit: Animation = AppMotion.Curve.quart(AppMotion.Duration.exit)

    /// Spring for confirmation pulses (segmented pill move, set logged). Same
    /// numbers the segmented pill already used; lifted so all confirm-class
    /// motion stays in lockstep.
    static let appConfirm: Animation = AppMotion.confirmSpring
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
        self.animation(reduceMotion ? nil : animation, value: value)
    }
}

/// Canonical screen-entrance animation. Subtle fade + 6pt upward slide using
/// the existing `.appEnter` curve (320 ms ease-out-quint). Runs once on first
/// `.onAppear`, then becomes a no-op for the lifetime of the view — so
/// scrolling, state changes, and re-renders never re-trigger it.
///
/// Reduce Motion: opacity-only, animation skipped (instant appearance). Per
/// the call-site contract in `AppMotion`, reduceMotion users get no motion.
///
/// Apply at the screen-content layer (typically the root `ScrollView` or
/// the content `VStack` inside `AppScreen`), not per-element. Single
/// canonical implementation — never hand-roll a parallel `.opacity` /
/// `.offset` entrance, never extend with stagger or per-row variants.
private struct AppScreenEnter: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .opacity(hasAppeared ? 1 : 0)
            .offset(y: (hasAppeared || reduceMotion) ? 0 : 6)
            .onAppear {
                guard !hasAppeared else { return }
                withAnimation(reduceMotion ? nil : .appEnter) {
                    hasAppeared = true
                }
            }
    }
}

extension View {
    /// Apply the canonical screen-entrance animation. See `AppScreenEnter` for
    /// doctrine. Apply at the screen-content layer (root `ScrollView` / content
    /// `VStack`), not per-element.
    func appScreenEnter() -> some View {
        modifier(AppScreenEnter())
    }
}

/// Canonical row separator. 1pt hairline at `AppColor.border.opacity(0.55)` —
/// the same value the active-workout lineup hand-rolled before consolidation.
/// Used by `AppDividedList` (and a handful of card-row contexts that compose
/// rows by hand). Spans the full width of its container; constrain via
/// surrounding `.padding(.leading/.trailing, ...)` if a non-full-width inset is
/// needed.
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
/// so icons across the app share the same stroke weight. Disclosure chevrons are
/// intentionally not exposed here.
///
/// `back` + `forward` are a paired set — both chevrons so the visual rhythm
/// reads as one nav control. The earlier `arrow.right` for `.forward` paired
/// awkwardly with `chevron.left` (chevron + straight arrow = inconsistent
/// pair, the only call site is the History calendar month nav). The
/// chevron-right ban in CLAUDE.md §4 is on raw `chevron.right` in view code
/// as a disclosure indicator — using it here via the design-system atom is
/// fine; the hook excludes `DesignSystem.swift`.
enum AppIcon: String {
    case back = "chevron.left"
    case forward = "chevron.right"
    case chevronDown = "chevron.down"
    case chevronUp = "chevron.up"
    case close = "xmark"
    case add = "plus"
    case remove = "minus"
    case edit = "pencil"
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
    case calendarClock = "calendar.badge.clock"
    case bolt = "bolt.fill"
    case chart = "chart.line.uptrend.xyaxis"
    case addCircle = "plus.circle.fill"
    case sliders = "slider.horizontal.3"
    case photo = "photo"
    case dumbbell = "dumbbell"
    case trophy = "trophy"
    case reorder = "line.3.horizontal"
    case camera = "camera"
    case clipboard = "doc.on.clipboard"
    case keyboard = "keyboard"
    case minusCircle = "minus.circle"
    case circle = "circle"
    case scalemass = "scalemass"

    var systemName: String { rawValue }

    func image(size: CGFloat = 17, weight: Font.Weight = .semibold) -> some View {
        // Scale the SF Symbol point size via UIFontMetrics so glyphs grow under
        // Dynamic Type the same way text does. Anchor to `.body` since icons
        // sit alongside body-scale labels in rows, chips, and toolbar buttons.
        let scaled = UIFontMetrics(forTextStyle: .body).scaledValue(for: size)
        return Image(systemName: systemName)
            .font(.system(size: scaled, weight: weight))
    }
}

extension Double {
    var weightString: String {
        self == floor(self) ? "\(Int(self))" : String(format: "%.1f", self)
    }
}

// MARK: - Haptics

/// Single canonical haptic vocabulary for the app. Cases name **moments**
/// (set logged, rest ready, PR, rejected tap…), not mechanisms (light impact,
/// notification success). That keeps tactile intent paired with product intent
/// — if the meaning of "PR" changes, one line moves.
///
/// HIG mapping:
/// - `.success / .warning / .error` → notification class (state-of-task signals).
/// - `.selection` → discrete change with no impact metaphor (tabs, picker reflow).
/// - `.increase / .decrease` → stepper-native pair (iOS 17).
/// - `.impact(weight:intensity:)` → physical metaphor (lift, PR celebration).
///
/// Two ways to fire:
/// 1. **Declarative** — `.appHaptic(.setLogged, trigger: signal)` modifier on the
///    view that owns the moment. Preferred — keeps haptic next to the state.
/// 2. **Imperative** — `AppHaptic.reorderLift.fire()` from gesture/drop
///    delegates that don't have a SwiftUI state to bind to.
///
/// New moments belong here, not as ad-hoc `.sensoryFeedback(...)` calls in
/// feature views — that's how the taxonomy drifts.
enum AppHaptic {
    // Logging hot loop
    case setLogged
    case personalRecord
    case setDeleted

    // Rest timer
    case restFinalCountdown
    case restReady

    // Workout-level
    case workoutFinished

    // CTAs / form
    case rejectedTap
    case validationError

    // Steppers
    case stepperIncrement
    case stepperDecrement

    // Navigation
    case tabChange

    // Reorder gesture
    case reorderLift
    case reorderSwap

    // Purchase
    case purchaseSuccess

    var feedback: SensoryFeedback {
        switch self {
        case .setLogged, .restReady, .workoutFinished, .purchaseSuccess:
            return .success
        case .personalRecord:
            return .impact(weight: .heavy, intensity: 1.0)
        case .setDeleted:
            return .impact(weight: .light, intensity: 0.7)
        case .restFinalCountdown:
            return .warning
        case .rejectedTap, .validationError:
            return .error
        case .stepperIncrement:
            return .increase
        case .stepperDecrement:
            return .decrease
        case .tabChange, .reorderSwap:
            return .selection
        case .reorderLift:
            return .impact(weight: .medium, intensity: 1.0)
        }
    }

    /// Imperative trigger for sites without SwiftUI state to bind to —
    /// `onDrag` closures, `DropDelegate` callbacks. Prefer the modifier.
    func fire() {
        switch self {
        case .setLogged, .restReady, .workoutFinished, .purchaseSuccess:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .restFinalCountdown:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .rejectedTap, .validationError:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        case .personalRecord:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: 1.0)
        case .setDeleted:
            UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.7)
        case .reorderLift:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .stepperIncrement, .stepperDecrement, .tabChange, .reorderSwap:
            UISelectionFeedbackGenerator().selectionChanged()
        }
    }
}

extension View {
    /// Fires `haptic` whenever `trigger` changes. Use on the view that owns the
    /// moment so the haptic lives next to the state, not threaded through a
    /// callback chain. Prefer this over inline `.sensoryFeedback(...)`.
    func appHaptic<T: Equatable>(_ haptic: AppHaptic, trigger: T) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger)
    }

    /// Fires `haptic` only when the `(old, new)` transition matches `condition`.
    /// Use for boolean edges where you want one direction (e.g. `false → true`)
    /// without spamming on every tick: `.appHaptic(.restFinalCountdown, trigger: isFinal) { !$0 && $1 }`.
    func appHaptic<T: Equatable>(
        _ haptic: AppHaptic,
        trigger: T,
        condition: @escaping (T, T) -> Bool
    ) -> some View {
        sensoryFeedback(haptic.feedback, trigger: trigger, condition: condition)
    }
}

// MARK: - Molecules

/// Standard list row — optional leading icon, title, secondary subtitle, and a
/// trailing slot. **Chevron-free by design**: never add `.forward` as a disclosure
/// glyph; let context + tap target convey navigation (HIG).
/// Use `.tappable` (default) for interactive rows — gets 44pt minHeight and a
/// hit-testable content shape. Use `.display` for read-only catalog rows inside
/// a shared card — same 8pt vertical breathing as `.tappable`, but drops the
/// 44pt floor so multi-row catalog blocks pack tighter without going cramped.
enum AppListRowStyle {
    case tappable
    case display
}

struct AppListRow<Trailing: View>: View {
    let title: String
    let subtitle: String?
    let leadingIcon: AppIcon?
    var style: AppListRowStyle = .tappable
    @ViewBuilder let trailing: () -> Trailing

    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        style: AppListRowStyle = .tappable,
        @ViewBuilder trailing: @escaping () -> Trailing
    ) {
        self.title = title
        self.subtitle = subtitle
        self.leadingIcon = leadingIcon
        self.style = style
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let leadingIcon {
                leadingIcon.image(size: 15, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(width: 24, height: 24)
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppFont.body.color)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppFont.muted.color)
                }
            }

            Spacer(minLength: 0)

            trailing()
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.lg)
        .frame(minHeight: style == .display ? nil : 44, alignment: .leading)
        .contentShape(Rectangle())
    }
}

extension AppListRow where Trailing == EmptyView {
    init(
        title: String,
        subtitle: String? = nil,
        leadingIcon: AppIcon? = nil,
        style: AppListRowStyle = .tappable
    ) {
        self.init(title: title, subtitle: subtitle, leadingIcon: leadingIcon, style: style) {
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
        style: AppListRowStyle = .tappable
    ) {
        self.init(title: title, subtitle: subtitle, leadingIcon: leadingIcon, style: style) {
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

/// − / value / + stepper — compact rounded control with 44pt hit targets.
/// Used for set counts, rest-duration seconds, reps, etc. Value is a pre-formatted
/// string (monospaced digits) so callers own unit rendering ("12 reps" vs "12").
struct AppStepper: View {
    let value: String
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
        HStack(spacing: AppSpacing.sm) {
            stepButton(icon: .remove, isEnabled: isDecrementEnabled) {
                decrementPhase &+= 1
                onDecrement()
            }

            Text(value)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppFont.sectionHeader.color)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(minWidth: minimumValueWidth)
                .contentTransition(.numericText())
                .animation(.appReveal, value: value)

            stepButton(icon: .add, isEnabled: isIncrementEnabled) {
                incrementPhase &+= 1
                onIncrement()
            }
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.vertical, AppSpacing.xs)
        .background(AppColor.controlBackground)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .appHaptic(.stepperIncrement, trigger: incrementPhase)
        .appHaptic(.stepperDecrement, trigger: decrementPhase)
    }

    private func stepButton(icon: AppIcon, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            icon.image(size: 14, weight: .semibold)
                .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textDisabled)
                .frame(width: 36, height: 36)
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

    /// Bound to the underlying `TextEditor` so the entire card surface — not
    /// just the inner UITextView's hit area — focuses on tap. Without this,
    /// padding around the TextEditor + the placeholder overlay leave dead
    /// zones where the user's tap visually lands on the input but does
    /// nothing (the OnboardingProgramImportView "input doesn't work" bug).
    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $text)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .scrollContentBackground(.hidden)
                .focused($isFocused)
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
        .simultaneousGesture(TapGesture().onEnded { isFocused = true })
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
    let action: () -> Void

    /// Bumped each time a disabled (not loading) tap is absorbed so
    /// `AppHaptic.rejectedTap` fires. A silently-rejected primary CTA is the
    /// worst-of-both-worlds; a soft buzz tells the user the system saw the
    /// tap but the gate isn't passable. Pair with `disabledReason` on
    /// `PrimaryButtonConfig` to also explain *why*.
    @State private var disabledTapTrigger: Int = 0

    init(_ label: String, isEnabled: Bool = true, isLoading: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.isLoading = isLoading
        self.action = action
    }

    private var isInteractive: Bool { isEnabled && !isLoading }

    var body: some View {
        ZStack {
            Button(action: action) {
                ZStack {
                    Text(label)
                        .font(AppFont.productAction.font)
                        .foregroundStyle(isEnabled ? AppColor.accentForeground : AppColor.textDisabled)
                        .multilineTextAlignment(.center)
                        .truncationMode(.tail)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .opacity(isLoading ? 0 : 1)
                    if isLoading {
                        ProgressView()
                            .tint(AppColor.accentForeground)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 60)
                .background(isEnabled ? AppColor.accent : AppColor.controlBackground)
                .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }
            .buttonStyle(ScaleButtonStyle())
            .disabled(!isInteractive)
            .accessibilityLabel(label)
            .accessibilityValue(isLoading ? Text("loading") : Text(""))

            // Disabled-tap absorber: present only when the button is disabled
            // *and not loading*. Loading is a system-status state, not a user
            // gate, so we don't fire an error haptic for it. AccessibilityHidden
            // so VoiceOver still hears the underlying disabled button.
            if !isEnabled && !isLoading {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { disabledTapTrigger &+= 1 }
                    .accessibilityHidden(true)
            }
        }
        .appHaptic(.rejectedTap, trigger: disabledTapTrigger)
    }
}

/// Filled secondary action used **only** by active-workout organisms — the
/// `metricHero` "Log" pill in `WorkoutCommandCard` and the inline "Next exercise"
/// row in `SessionStateBar`. `fileprivate` so feature code cannot compose it:
/// page files use `AppPrimaryButton` (sticky CTA) or `AppGhostButton` (quiet action).
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
                            }
                            VStack(alignment: .center, spacing: AppSpacing.xxs) {
                                Text(label)
                                    .font(AppFont.productAction.font)
                                    .foregroundStyle(foregroundColor)
                                Text(trimmedDetail)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(isEnabled ? AppColor.textSecondary : AppColor.textDisabled)
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
                            }
                            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                                Text(label)
                                    .font(AppFont.productAction.font)
                                    .foregroundStyle(foregroundColor)
                                Text(trimmedDetail)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(isEnabled ? AppColor.textSecondary : AppColor.textDisabled)
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
                        }
                        Text(label)
                            .font(AppFont.productAction.font)
                            .foregroundStyle(foregroundColor)
                    }
                }
            }
            .padding(.horizontal, secondaryHorizontalPadding)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: fillsAvailableWidth ? .infinity : nil)
            .frame(minHeight: 60)
            .background(backgroundColor)
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
        let detailColor = isEnabled ? AppColor.textSecondary : AppColor.textDisabled
        let row = HStack(alignment: .center, spacing: AppSpacing.smd) {
            if let icon {
                icon.image(size: 16, weight: .semibold)
                    .foregroundStyle(foregroundColor)
            }
            Text(label)
                .font(AppFont.productAction.font)
                .foregroundStyle(foregroundColor)
                .lineLimit(1)
            Text(trimmedDetail)
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
        guard isEnabled else { return AppColor.textDisabled }
        switch tone {
        case .default: return AppColor.textPrimary
        case .accentSoft: return AppColor.accent
        case .destructive: return AppColor.error
        }
    }

    private var backgroundColor: Color {
        guard isEnabled else {
            return tone == .destructive ? Color.clear : AppColor.controlBackground.opacity(0.5)
        }
        switch tone {
        case .default: return AppColor.controlBackground
        case .accentSoft: return AppColor.controlBackground
        case .destructive: return Color.clear
        }
    }
}

/// Text-only action (no fill). Full-width row with **centered** label and ≥44pt hit area.
/// Use inside `NavigationLink` labels or with `AppGhostButton`.
struct AppGhostButtonLabel: View {
    let title: String
    var isEnabled: Bool = true

    var body: some View {
        Text(title)
            .font(AppFont.productAction.font)
            .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textDisabled)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
    }
}

/// Text-only quiet action (no fill, no stroke) — use for "Freestyle session",
/// "Skip", or any optional path that shouldn't compete with the primary CTA.
/// 44pt hit area. For disclosure link labels, use `AppGhostButtonLabel` directly.
struct AppGhostButton: View {
    let label: String
    var isEnabled: Bool = true
    let action: () -> Void

    init(_ label: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.label = label
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            AppGhostButtonLabel(title: label, isEnabled: isEnabled)
                .frame(minHeight: 60)
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
/// - `.accent` (default) — Ink fill, Paper text. Use when this is the page's
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

/// Static status/label pill — "Completed", "Up next", "Missed", "Day 3 of 5".
/// Use `.success` / `.warning` / `.error` for status; `.muted` / `.default` for
/// neutral labels; `.accent` to emphasize. For toggle-able filter pills, use
/// `AppFilterChip` — not this component.
///
/// Pass `onTap` to turn the tag into a tap-to-accept affordance (e.g. the
/// progressive-overload "+ 1 rep" suggestion) without forking a new chip
/// primitive. The visible capsule keeps its compact size; the hit area
/// expands invisibly to the 44pt Gym Test floor.
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
        case .accent, .success, .warning, .error: return true
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .default: return AppColor.textPrimary
        case .accent: return AppColor.accentForeground
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
                    .appCapsLabel(isActive ? .overlineStrong : .overline)
                AppIcon.chevronDown.image(size: 10, weight: .bold)
            }
            .foregroundStyle(isActive ? AppColor.background : AppColor.textPrimary)
            .padding(.horizontal, AppSpacing.smd)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isActive ? AppColor.textPrimary : AppColor.accentSoft)
            )
            // Visible capsule stays compact; hit zone extends to 44pt floor
            // so the chip rhythm reads the same as `AppFilterChip` next to it.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: AppSpacing.xs) {
                Text(label)
                    .appCapsLabel(isSelected ? .overlineStrong : .overline)
                if isSelected && showsClearGlyphWhenSelected {
                    AppIcon.close.image(size: 10, weight: .bold)
                }
                if showsTrailingDot {
                    Circle()
                        .fill(isSelected ? AppColor.background : AppColor.warning)
                        .frame(width: 6, height: 6)
                }
            }
            .foregroundStyle(isSelected ? AppColor.background : AppColor.textPrimary)
            .padding(.leading, AppSpacing.smd)
            .padding(.trailing, isSelected && showsClearGlyphWhenSelected ? AppSpacing.sm : AppSpacing.smd)
            .padding(.vertical, AppSpacing.xs)
            .background(
                Capsule(style: .continuous)
                    .fill(isSelected ? AppColor.textPrimary : AppColor.accentSoft)
            )
            // Visible capsule stays compact; hit zone extends to 44pt floor
            // for one-handed reachability without changing the chip's rhythm.
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint(
            showsClearGlyphWhenSelected && isSelected ? "Tap to clear filter" : "Tap to filter"
        )
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
/// filled capsule ("Set 2"), completed/failed sets as compact `kgxrep` chips, and
/// upcoming sets as numbered circles. Used only in active workout flows.
struct SetProgressIndicator: View {
    struct Step: Identifiable {
        enum State {
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
        /// (computed in `ActiveWorkoutView.completeSet`). The chip flips to accent
        /// chrome so the milestone persists for the rest of the session — pairs with
        /// the heavy-impact haptic that fires once at log time.
        var isPR: Bool = false
        /// True while this chip's set is the subject of an open edit sheet
        /// (`AdjustResultSheet` in `.edit` mode). Renders a slightly darker
        /// chip background so the strip behind the sheet communicates which
        /// set is being modified, even when the current-set accent pill sits
        /// further down the strip. PR chips keep their accent fill — the PR
        /// signal outranks the edit affordance.
        var isEditing: Bool = false
        /// Tap handler for completed/failed chips — opens the edit sheet for that set
        /// in `ActiveWorkoutView`. Honored only when state is `completed` or `failed`;
        /// upcoming/current/disabled chips are never interactive (no values to edit).
        /// Pass `nil` for read-only contexts (previews, history).
        var onTap: (() -> Void)? = nil

        var chipText: String? {
            guard let reps, let weightText, !weightText.isEmpty else { return nil }
            // Uppercase the weight token so the unit (`kg`, `lb`) reads as
            // all-caps inside the chip — matches the all-caps `SET N` pill
            // sitting beside it (`stepIndicator` mono semibold cap-style).
            // Digits are unaffected by `.uppercased()`. The literal `x`
            // separator stays lowercase per the lifter's spec: only the
            // unit converts, not the multiplier glyph. `BW` is already
            // uppercase so it round-trips cleanly. Applying this at the
            // string layer (not via `.textCase(.uppercase)` on the
            // SwiftUI Text) is what lets us case the unit without also
            // casing the `x` between weight and reps.
            return "\(weightText.uppercased())x\(reps)"
        }
    }

    let steps: [Step]
    /// Bumped by the parent each time a set is logged. Drives a one-shot SF Symbols
    /// bounce on every already-mounted ✓ chip so newly-landed sets give the
    /// previously-logged checkmarks a quiet sympathy nod. Newest chip arrives via
    /// the parent's `withAnimation(.appReveal)` and doesn't need its own bounce.
    var setLoggedSignal: Int? = nil

    var body: some View {
        // Most workouts (3-5 sets) fit the card width — render as a plain centered
        // HStack so the strip lines up with the exercise name and metric hero. Long
        // programs (6+ sets) overflow, so fall back to a horizontal scroll that
        // keeps the leading edge anchored.
        ViewThatFits(in: .horizontal) {
            chipRow
            ScrollView(.horizontal, showsIndicators: false) {
                chipRow
            }
            .scrollClipDisabled()
        }
    }

    private var chipRow: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(steps) { step in
                renderStep(step)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(accessibilityLabel(for: step))
            }
        }
    }

    /// Tap-edit on a logged chip is the only interaction in the strip — wrap it in a
    /// `Button` (which auto-applies the `isButton` trait) and inflate the hit area
    /// to 44pt to meet the gym-test touch-target floor. The visible capsule stays
    /// 24pt; the extra 20pt is invisible padding so the HStack grows from 24pt to
    /// 44pt only when chips are interactive.
    @ViewBuilder
    private func renderStep(_ step: Step) -> some View {
        if (step.state == .completed || step.state == .failed), let onTap = step.onTap {
            Button(action: onTap) {
                stepContent(step)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
        } else {
            stepContent(step)
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
                        .symbolEffect(.bounce, options: .nonRepeating, value: setLoggedSignal ?? 0)
                } else {
                    AppIcon.remove.image(size: 10, weight: .bold)
                }
                Text(chipText)
                    .font(AppFont.stepIndicator.font)
                    .lineLimit(1)
            }
            .foregroundStyle(step.isPR ? AppColor.accentForeground : AppColor.textSecondary)
            .padding(.horizontal, AppSpacing.sm)
            .frame(height: 24)
            .background(Capsule(style: .continuous).fill(chipFill(for: step)))
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
        if step.isPR { return AppColor.accent }
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
        switch step.state {
        case .completed:
            return "Set \(step.label), completed\(detail)"
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

/// Rest countdown control — `-15` / central timer pill / `+15`. Sits inside
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
                    accessibilityLabel: "Decrease rest timer by 30 seconds",
                    action: onDecrease
                )

                Button(action: { onToggle?() }) {
                    Group {
                        if showsTimerCapsule {
                            timerCenterTapLabel
                                .clipShape(Capsule(style: .continuous))
                                .contentShape(Capsule(style: .continuous))
                        } else {
                            timerCenterTapLabel
                                .contentShape(Rectangle())
                        }
                    }
                }
                .buttonStyle(ScaleButtonStyle())
                .disabled(onToggle == nil || state == .disabled)
                .accessibilityLabel(timerAccessibilityLabel)

                adjustButton(
                    icon: .add,
                    accessibilityLabel: "Increase rest timer by 30 seconds",
                    action: onIncrease
                )
            }
        }
        .opacity(state == .disabled ? 0.5 : 1)
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
                // ticking instead of flickering. State-only motion → not
                // gated by Reduce Motion (cross-fade survives the system pref).
                .contentTransition(.numericText(countsDown: true))
                .animation(.appReveal, value: timeText)

            if let indicatorIcon {
                indicatorIcon.image(size: 18, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
        .frame(minHeight: 60)
        .padding(.horizontal, AppSpacing.smd)
        .background {
            if showsTimerCapsule {
                Capsule(style: .continuous).fill(AppColor.controlBackground)
            }
        }
        .overlay {
            if showsTimerCapsule {
                Capsule(style: .continuous)
                    .stroke(AppColor.border.opacity(0.55), lineWidth: 1)
            }
        }
    }

    /// Capsule fill + stroke for **idle / paused / disabled** so the affordance reads as
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
                .background(AppColor.controlBackground)
                .overlay {
                    Circle()
                        .stroke(AppColor.border.opacity(0.4), lineWidth: 1)
                }
                .clipShape(Circle())
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(action == nil || state == .disabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityValue(timeText)
    }
}

// MARK: - PreviewListRow + PreviewListContainer

/// Two-line row for preview lists inside cards. The title leads in
/// `sectionHeader`; the subtitle follows in quiet `body`, matching Programs,
/// Templates, day lists, and Today's exercise preview.
///
/// `isEmptyHint = true` softens the data line (caption font + secondary color)
/// for cold-start rows like "No prior sets".
///
/// `trailingLabel` renders on the same baseline as the title in muted text —
/// carries ghost-value memory ("Last 60kg" / "Last BW") so the prior-session
/// weight surfaces on the Today preview alongside the planned set/rep target
/// underneath. Suppressed when nil; takes layout priority so a long title
/// truncates first rather than pushing the weight memory off-screen.
struct PreviewListRow: View {
    let title: String
    let subtitle: String
    var trailingLabel: String? = nil
    var isEmptyHint: Bool = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(trailingLabel == nil ? nil : 1)
                    .truncationMode(.tail)

                Text(subtitle)
                    .font(subtitleFont)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let trailingLabel {
                Text(trailingLabel)
                    .font(AppFont.muted.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(1)
                    .layoutPriority(1)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .frame(minHeight: 52)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var subtitleFont: Font {
        isEmptyHint ? AppFont.caption.font : AppFont.body.font
    }

    private var accessibilityLabel: String {
        var parts = [title, subtitle]
        if let trailingLabel { parts.append(trailingLabel) }
        return parts.joined(separator: ", ")
    }
}

/// Scrollable, capped-height container for `PreviewListRow`s — used on Today hero
/// and in program active-card previews. Top + bottom edges fade via the
/// canonical `appScrollEdgeSoft()` so truncation reads intentionally; the OS
/// only renders the fade where scrolling actually clips, so short content
/// stays flat without measuring height by hand.
struct PreviewListContainer<Content: View>: View {
    /// Capped scroll height — declared as `@ScaledMetric` so the cap grows
    /// proportionally under Dynamic Type. Without this, AX users see rows
    /// clipped at the same 228pt as default text size, halving how many fit.
    @ScaledMetric(relativeTo: .body) private var maxHeight: CGFloat = 228
    /// Vertical gap between rows. Tight by default so the container padding can breathe around the group.
    var rowSpacing: CGFloat = AppSpacing.xs
    /// Inner padding between the container edge and its rows.
    var contentPadding: CGFloat = AppSpacing.md
    @ViewBuilder let content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: rowSpacing) {
                content()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(contentPadding)
        }
        .scrollIndicators(.hidden)
        .frame(maxWidth: .infinity)
        .frame(maxHeight: maxHeight)
        .appScrollEdgeSoft()
        // Canonical row-on-card recipe (Figma source of truth, 2026-04-27):
        // `cardRowFill` + `AppRadius.sm` for any element nested inside `AppCard`.
        .background(AppColor.cardRowFill)
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
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
    /// Outer inset for card chrome. System default is `AppSpacing.lg` (24pt) so every
    /// card has 24pt visual breathing room from card edge to content. Use the default
    /// when the body owns no horizontal padding of its own (text, buttons, custom
    /// layouts). For list content where the inner row already pads itself by
    /// `AppSpacing.md` (16pt) — `AppListRow`, or any row with explicit
    /// `.padding(.horizontal, .md)` — pass `AppSpacing.sm` (8pt) so 8 + 16 composes
    /// to the same 24pt offset. Use `0` only for full-bleed content (dividers
    /// running card-edge to card-edge, media). Anything else is the wrong inset.
    var contentInset: CGFloat = AppSpacing.lg
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

/// Tap-to-advance option tile used by onboarding step screens that ask the
/// lifter to pick one path (unit, import method, etc.). A leading 40pt icon
/// bubble (`AppIconCircle` on `accentSoft` surface), a centered title row,
/// and an optional trailing accent badge. Auto-presses via the canonical
/// `ScaleButtonStyle`, fires a selection haptic at press time, and holds
/// the action by 110ms so the press-state dim is visibly underway when the
/// step-swap slide takes over.
///
/// This was previously `OnboardingOptionCard` in
/// `Unit/Features/Onboarding/OnboardingImportMethodView.swift`. Promoted to
/// the design system because two onboarding screens (`UnitPicker`,
/// `ImportMethod`) and any future step that needs the same affordance
/// should share one canonical molecule — never a feature-file fork.
///
/// Pass either `icon` (SF Symbol via `AppIcon`) or `iconText` (a short
/// glyph like `kg` / `lb`) — exactly one. `badge` is the optional accent
/// chip trailing the title (e.g. "New", "Recommended").
struct AppOptionTileCard: View {
    var icon: AppIcon? = nil
    var iconText: String? = nil
    let title: String
    var badge: String? = nil
    let action: () -> Void

    /// Re-entrancy guard. While the 110ms press-visibility hold is running,
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

                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer(minLength: 0)

                if let badge {
                    AppTag(text: badge, style: .accent, layout: .compactCapsule)
                }
            }
            .appCardStyle()
        }
        // Press feedback (opacity dim + brightness shift + scale) is the
        // canonical system-level treatment on `ScaleButtonStyle`. Every
        // tappable atom in Unit uses the same style so onboarding cards,
        // CTAs, ghost buttons, and floating pills all flash the same way on
        // tap. Don't override here — fix at `ScaleButtonStyle` and the
        // whole product moves.
        .buttonStyle(ScaleButtonStyle())
    }

    private func handleTap() {
        guard !isProcessingTap else { return }
        isProcessingTap = true
        // Selection haptic fires at the same instant the press-state
        // animation begins (via `ScaleButtonStyle`). Visual + tactile
        // together so the tap feels received in two senses.
        UISelectionFeedbackGenerator().selectionChanged()
        // Hold the action by 110ms so the press-state dim from
        // `ScaleButtonStyle` is visibly underway when the slide transition
        // (`appEnter` 0.32s) takes over. Without this, navigation cards
        // (kg / lb / paste / build manually / use past workout) auto-advance
        // before the eye registers the press. CTAs that stay in place
        // (Continue, Read program) don't need this hold — the press is
        // visible during finger-down because the screen doesn't move.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.11) {
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

/// Canonical tier-selection card for the paywall (and any future "pick one of
/// N priced tiers" surface). Replaces the 50-line inline `tierCard` in
/// `PaywallView` that hand-rolled its own `.background`/`.clipShape` chrome
/// outside the design system — CLAUDE.md §4 parallel-implementation ban.
///
/// Layout: optional accent badge top, eyebrow row (small-caps label +
/// trailing checkmark when selected), price (`productHeading` tracking),
/// muted sublabel. Selected state shifts the background to `accentSoft`
/// AND lays down a 1.5pt accent border so the affordance reads correctly
/// for reduced-color-discrimination users (WCAG AA), not just for the
/// 14pt checkmark glyph alone.
///
/// Accessibility: the `.isSelected` trait fires on the underlying button so
/// VoiceOver announces "Selected, Annually" without an extra label hack.
struct AppSelectableTierCard: View {
    let label: String
    let price: String
    let sublabel: String
    var badge: String? = nil
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Button(action: handleTap) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                // Badge slot is always reserved — even on tiers with no
                // badge — so a row of three cards keeps a single visual
                // baseline. Previously, only the badged card (annual)
                // took up the badge-row height, leaving the un-badged
                // cards visibly shorter; in `HStack(alignment: .top)`
                // the annual card then extended past the others and its
                // price + sublabel got clipped by the surrounding
                // scroll-edge fade. `.hidden()` keeps the AppTag's
                // exact footprint without rendering pixels, so any
                // future AppTag size change auto-syncs.
                Group {
                    if let badge {
                        AppTag(text: badge, style: .accent, layout: .compactCapsule)
                    } else {
                        AppTag(text: " ", style: .accent, layout: .compactCapsule)
                            .hidden()
                    }
                }
                .accessibilityHidden(badge == nil)

                HStack(spacing: AppSpacing.xs) {
                    Text(label)
                        .appCapsLabel(.smallLabel)
                        .foregroundStyle(AppColor.textSecondary)

                    Spacer(minLength: 0)

                    if isSelected {
                        AppIcon.checkmarkFilled.image(size: 14, weight: .semibold)
                            .foregroundStyle(AppColor.accent)
                            .accessibilityHidden(true)
                    }
                }

                Text(price)
                    .font(AppFont.productHeading.font)
                    .tracking(AppFont.productHeading.tracking)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .allowsTightening(true)

                Text(sublabel)
                    .font(AppFont.muted.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.65)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, AppSpacing.md)
            .padding(.horizontal, AppSpacing.smd)
            .background(isSelected ? AppColor.accentSoft : AppColor.cardBackground)
            // 1.5pt accent border on selected — a second WCAG-friendly cue
            // beyond the tinted fill, so users with reduced color
            // discrimination (or who have just glanced at the card from
            // across the room) can still tell which tier is selected.
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .strokeBorder(
                        isSelected ? AppColor.accent : Color.clear,
                        lineWidth: 1.5
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func handleTap() {
        // Selection animation matches every other ScaleButtonStyle press in
        // the app — Reduce Motion clamps to a still selection transition.
        withAnimation(reduceMotion ? nil : .appPress) {
            action()
        }
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

/// Optional trailing action on a transient `AppToast` — single reversible step
/// (e.g. "Undo" after a non-destructive deletion). The handler is responsible
/// for the actual reversal; the toast dismisses automatically when tapped.
struct AppToastAction {
    let label: String
    let handler: () -> Void
}

/// Transient pill-shaped notification mounted as a top overlay (not a
/// `safeAreaInset`) so showing or hiding it does **not** reflow layout — sticky
/// CTAs stay pinned, scroll content stays where it is. Sits at the top of the
/// safe area, horizontally centered, on the same line as the host's
/// navigation-bar leading button so the eye lands on it without leaving the
/// "where I just acted" zone. The pill is the canonical Cupertino top toast:
/// drop-shadowed white capsule that floats over content rather than docking to
/// the home-indicator edge.
///
/// Bind `message` to a `String?` `@State`; setting non-nil shows the toast,
/// which auto-dismisses after `duration` seconds. When an `action` is set
/// (e.g. `AppToastAction(label: AppCopy.Toast.undo, handler: ...)`), the pill
/// gains a trailing tap target — same auto-dismiss timing whether or not the
/// user taps it.
struct AppToast: ViewModifier {
    @Binding var message: String?
    var duration: TimeInterval = 3.0
    var action: AppToastAction? = nil

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                ZStack {
                    if let text = message {
                        AppToastPill(
                            text: text,
                            action: action,
                            onActionTap: { withAnimation(.appState) { message = nil } }
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .task(id: text) {
                            try? await Task.sleep(for: .seconds(duration))
                            withAnimation(.appState) { message = nil }
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.top, AppSpacing.xs)
                .animation(.appState, value: message)
                // Transparent overlay area must stay tap-through so the toast
                // doesn't shadow taps on the navigation-bar back button or any
                // top-of-screen affordance behind it.
                .allowsHitTesting(message != nil)
            }
    }
}

/// Floating pill shell for `AppToast`. Light card fill on a soft drop-shadow
/// pair (one large/diffuse for lift, one tight for edge definition) — the only
/// shadowed surface in the system, justified by the pill needing to feel
/// detached from whatever screen content sits beneath it.
private struct AppToastPill: View {
    let text: String
    let action: AppToastAction?
    let onActionTap: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Text(text)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            if let action {
                Button {
                    action.handler()
                    onActionTap()
                } label: {
                    Text(action.label)
                        .font(AppFont.productAction.font)
                        .foregroundStyle(AppColor.accent)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(action.label)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.smd)
        .frame(minHeight: 44)
        .background(AppColor.cardBackground)
        .clipShape(Capsule(style: .continuous))
        .appFloatingShadow()
    }
}

extension View {
    /// Show a transient bottom toast bound to a `String?` state. Pass `action`
    /// to add a single trailing tap target (e.g. "Undo"); the toast dismisses
    /// after the user taps it or after `duration` elapses, whichever first.
    func appToast(
        message: Binding<String?>,
        duration: TimeInterval = 3.0,
        action: AppToastAction? = nil
    ) -> some View {
        modifier(AppToast(message: message, duration: duration, action: action))
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
    let message: String
    let note: String?
    let buttonLabel: String?
    let action: (() -> Void)?
    let content: () -> Content

    var body: some View {
        AppCard {
            VStack(alignment: .center, spacing: AppSpacing.md) {
                if let eyebrow {
                    Text(eyebrow)
                        .appCapsLabel(.overline)
                        .foregroundStyle(AppColor.textSecondary)
                }

                VStack(alignment: .center, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(AppFont.productHeading.font)
                        .tracking(AppFont.productHeading.tracking)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(message)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .multilineTextAlignment(.center)

                    if let note {
                        Text(note)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textTertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                if Content.self != EmptyView.self {
                    content()
                }

                if let buttonLabel, let action {
                    AppPrimaryButton(buttonLabel, action: action)
                }
            }
            .frame(maxWidth: .infinity)
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

    var body: some View {
        Text(message)
            .font(AppFont.caption.font)
            .foregroundStyle(AppColor.textSecondary)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 120)
            .appCardStyle()
    }
}

/// Canonical row-list primitive. Renders rows separated by a 1pt `AppDivider`
/// hairline. Use inside a shared `AppCard` (or `SettingsSection`) when rows
/// share a subject; for a list that owns its own card chrome, use the
/// `AppCardList` molecule instead. Dividers default to full container width
/// (leading/trailing 0); pass `dividerLeading:` / `dividerTrailing:` only when
/// a non-full-width inset is genuinely required.
struct AppDividedList<Data, ID, RowContent>: View
    where Data: RandomAccessCollection, ID: Hashable, RowContent: View
{
    let data: Data
    let id: KeyPath<Data.Element, ID>
    var dividerLeading: CGFloat = 0
    var dividerTrailing: CGFloat = 0
    @ViewBuilder let content: (Data.Element) -> RowContent

    var body: some View {
        let items = Array(data)
        VStack(alignment: .leading, spacing: 0) {
            ForEach(items.indices, id: \.self) { index in
                if index > 0 {
                    AppDivider()
                        .padding(.leading, dividerLeading)
                        .padding(.trailing, dividerTrailing)
                }
                content(items[index])
            }
        }
    }
}

extension AppDividedList where Data.Element: Identifiable, ID == Data.Element.ID {
    init(
        _ data: Data,
        dividerLeading: CGFloat = 0,
        dividerTrailing: CGFloat = 0,
        @ViewBuilder content: @escaping (Data.Element) -> RowContent
    ) {
        self.data = data
        self.id = \.id
        self.dividerLeading = dividerLeading
        self.dividerTrailing = dividerTrailing
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
            .padding(.horizontal, AppSpacing.lg)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .padding(.vertical, verticalInset)
    }
}

extension View {
    /// Apply the canonical card-row recipe (24pt horizontal, 16pt vertical by default,
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

/// Canonical drag-to-reorder row recipe. Apply to a row inside `AppCardList`
/// to make the **entire row** the drag affordance (not just a 44pt icon),
/// dim the source row in place while it floats, fire a medium-impact haptic
/// on lift, and render a custom Bond-fill pill as the floating preview so the
/// row reads as a single card plucked from the list.
///
/// One canonical recipe — never hand-roll `.onDrag` on a sub-element of a
/// reorderable row. The "only the hamburger highlights, hard to grab" failure
/// mode is what this molecule exists to prevent.
///
/// Reduce Motion: opacity dim cross-fades instantly; drag-and-drop is
/// unchanged. Pair the call-site `DropDelegate` with
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
        let isDragged = draggedID == id
        return content
            .opacity(isDragged ? 0.25 : 1.0)
            .appAnimation(.appConfirm, value: isDragged, reduceMotion: reduceMotion)
            .onDrag {
                draggedID = id
                AppHaptic.reorderLift.fire()
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
                withAnimation(reduceMotion ? nil : .appState) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    header()
                    Spacer(minLength: 0)
                    AppIcon.chevronDown.image(size: 13, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .appAnimation(.appState, value: isExpanded, reduceMotion: reduceMotion)
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.sm)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())

            if isExpanded {
                content()
            }
        }
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

    /// One progressive-overload nudge rendered as a flat caps text-button in
    /// `metricSupportingSlot`. The label reads "+ 1 rep" / "+ 2.5 kg" /
    /// "+ 5 lb"; the tap handler opens the AdjustResultSheet pre-filled to
    /// the bumped target. Visual style mirrors the in-hero "Adjust" caps
    /// label so both affordances read as siblings — same component vocabulary,
    /// just different prefills.
    struct SuggestionAction {
        let label: String
        let onTap: () -> Void
    }

    let progressSteps: [SetProgressIndicator.Step]
    let exerciseName: String
    let metricValue: String
    var metricSupportingText: String? = nil
    /// When true, the metric line uses body-sized copy instead of the large numeric display (placeholders).
    var metricIsHint: Bool = false
    /// Pre-fill from a prior session (no working set logged this session yet). Renders the
    /// metric in `textSecondary` so users can tell at a glance whether the number is a
    /// suggestion to beat or a value already committed. Recolors via `appReveal` when
    /// the first set lands and the value transitions to logged.
    var metricIsGhost: Bool = false
    var state: State = .active
    var primaryLabel: String = AppCopy.Workout.completeSet
    var onPrimaryAction: (() -> Void)? = nil
    var onSecondaryAction: (() -> Void)? = nil
    /// Bumped by the parent each time a set is logged. Drives `AppHaptic.setLogged`
    /// on this card so the feedback lives at the atom layer instead of being
    /// threaded through a generator at the call site.
    /// Pass `nil` for non-active surfaces (previews) — feedback is a no-op then.
    var setLoggedSignal: Int? = nil
    /// Bumped by the parent only when the just-logged set beat the prior all-time best
    /// for this exercise. Routes a heavy-impact haptic on top of the regular `.success`
    /// — same atom layer, distinct moment. The `setLoggedSignal` haptic still fires; this
    /// stacks for the milestone feel.
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
    /// Progressive-overload nudges rendered in `metricSupportingSlot` as a row of
    /// flat caps text-buttons matching the in-hero "Adjust" affordance. Each entry
    /// is a label + tap handler; the card iterates and renders one button per
    /// entry. Empty array → slot falls back to `metricSupportingText` (or empty).
    /// Source-of-truth logic for *what* to suggest lives in `SetSuggestion`
    /// (Features/Today/ActiveWorkoutView.swift) — this card is presentation only.
    var suggestionActions: [SuggestionAction] = []
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Toggles for ~800ms each time `setPRSignal` increments — replaces the quiet
    /// `metricSupportingText` line ("Last session …") with a Verde "Personal record"
    /// chip so the peak emotional moment of a session is held visibly long enough
    /// to register before the metric prefill cross-fades to the next set.
    @SwiftUI.State private var prBadgeVisible: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            VStack(alignment: .center, spacing: AppSpacing.lg) {
                HStack {
                    Spacer(minLength: 0)
                    SetProgressIndicator(steps: progressSteps, setLoggedSignal: setLoggedSignal)
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
                    metricHero
                    metricSupportingSlot
                }

                if state != .completed {
                    AppPrimaryButton(
                        primaryLabel,
                        isEnabled: state == .active && onPrimaryAction != nil,
                        action: { onPrimaryAction?() }
                    )
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.lg)

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
        .appHaptic(.setLogged, trigger: setLoggedSignal)
        .appHaptic(.personalRecord, trigger: setPRSignal)
        .onChange(of: setPRSignal) { _, _ in
            showPRBadge()
        }
    }

    /// Dwell on the PR badge — 3.0 s gives the lifter time to read "Personal record"
    /// + the prior-best delta under fatigue, without holding the slot long enough to
    /// stall the next-set prefill cross-fade. The previous 0.8 s flashed before the
    /// glance landed; the heavy haptic was firing alone.
    private static let prBadgeDwellSeconds: UInt64 = 3
    private func showPRBadge() {
        prBadgeVisible = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: Self.prBadgeDwellSeconds * 1_000_000_000)
            prBadgeVisible = false
        }
    }

    @ViewBuilder
    private var metricSupportingSlot: some View {
        Group {
            if prBadgeVisible {
                VStack(spacing: AppSpacing.xs) {
                    HStack(spacing: AppSpacing.xs) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.success)
                        Text(AppCopy.Workout.personalRecord)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .padding(.horizontal, AppSpacing.smd)
                    .padding(.vertical, AppSpacing.xs)
                    .background(AppColor.successSoft, in: Capsule(style: .continuous))

                    if let priorBestText, !priorBestText.isEmpty {
                        Text(priorBestText)
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                            .monospacedDigit()
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(
                    priorBestText.map { "\(AppCopy.Workout.personalRecord). \($0)." }
                        ?? AppCopy.Workout.personalRecord
                )
            } else if !suggestionActions.isEmpty {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Array(suggestionActions.enumerated()), id: \.offset) { _, action in
                        Button(action: action.onTap) {
                            Text(action.label)
                                .appCapsLabel(.smallLabel)
                                .foregroundStyle(AppColor.textPrimary)
                                .padding(.horizontal, AppSpacing.md)
                                .padding(.vertical, AppSpacing.smd)
                                .frame(minHeight: 44)
                                .background(
                                    AppColor.controlBackground,
                                    in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                )
                                .contentShape(
                                    RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                )
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                }
            } else if let metricSupportingText, !metricSupportingText.isEmpty {
                Text(metricSupportingText)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appAnimation(.appReveal, value: prBadgeVisible, reduceMotion: reduceMotion)
    }

    @ViewBuilder
    private var metricHero: some View {
        if onSecondaryAction != nil {
            if metricIsHint {
                AppSecondaryButton(
                    AppCopy.Workout.logMetricHint,
                    isEnabled: state == .active,
                    fillsAvailableWidth: false,
                    action: { onSecondaryAction?() }
                )
                .accessibilityLabel("Log weight and reps")
            } else {
                Button(action: { onSecondaryAction?() }) {
                    VStack(spacing: AppSpacing.xs) {
                        metricValueText

                        Text("Adjust")
                            .appCapsLabel(.smallLabel)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Adjust weight and reps")
            }
        } else {
            metricValueText
        }
    }

    @ViewBuilder
    private var metricValueText: some View {
        Text(metricValue)
            .font(AppFont.numericDisplay.font)
            .tracking(AppFont.numericDisplay.tracking)
            .foregroundStyle(metricIsGhost ? AppColor.textDisabled : AppColor.textPrimary)
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.55)
            .lineLimit(3)
            // Numeric cross-fade between sets — when prefill updates after a
            // logged set, the weight × reps swap reads as a soft handoff
            // instead of a flicker. SwiftUI selects per-glyph fade for the
            // changed digits and leaves the rest static.
            .contentTransition(.numericText())
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
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppFont.sectionHeader.color)
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
    var contentInset: CGFloat = AppSpacing.lg
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        contentInset: CGFloat = AppSpacing.lg,
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
struct PrimaryButtonConfig {
    let label: String
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var disabledReason: String? = nil
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

/// Native bottom-sheet shell: centered `NavigationStack` title, top-right native
/// text action, and `AppScreen` content/CTA layout. Matches sheets like
/// Today's routine; reserve `ProductTopBar` for product/root surfaces.
struct AppSheetScreen<Content: View>: View {
    enum DismissActionPlacement {
        case cancellation
        case confirmation

        var toolbarPlacement: ToolbarItemPlacement {
            switch self {
            case .cancellation: return .cancellationAction
            case .confirmation: return .confirmationAction
            }
        }

        var role: ButtonRole? {
            switch self {
            case .cancellation: return .cancel
            case .confirmation: return nil
            }
        }
    }

    let title: String
    let primaryButton: PrimaryButtonConfig?
    let secondaryButton: SecondaryButtonConfig?
    let dismissLabel: String
    let dismissActionPlacement: DismissActionPlacement
    let onDismissAction: (() -> Void)?
    var usesOuterScroll: Bool
    var showsKeyboardDismissToolbar: Bool
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        primaryButton: PrimaryButtonConfig? = nil,
        secondaryButton: SecondaryButtonConfig? = nil,
        dismissLabel: String = AppCopy.Nav.cancel,
        dismissActionPlacement: DismissActionPlacement = .confirmation,
        onDismissAction: (() -> Void)? = nil,
        usesOuterScroll: Bool = true,
        showsKeyboardDismissToolbar: Bool = false,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.primaryButton = primaryButton
        self.secondaryButton = secondaryButton
        self.dismissLabel = dismissLabel
        self.dismissActionPlacement = dismissActionPlacement
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
            }
            .navigationBarTitleTruncated(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onDismissAction {
                    ToolbarItem(placement: dismissActionPlacement.toolbarPlacement) {
                        Button(role: dismissActionPlacement.role, action: onDismissAction) {
                            Text(dismissLabel)
                        }
                        .appToolbarTextStyle()
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
/// type, spacing, range, and stepper behavior.
struct AppSetRepEditorSheet: View {
    static let defaultSets: Int = 3
    static let defaultReps: Int = 8
    static let defaultSetRange: ClosedRange<Int> = 1...10
    static let defaultRepRange: ClosedRange<Int> = 1...30

    let title: String
    var subtitle: String? = nil
    let setRange: ClosedRange<Int>
    let repRange: ClosedRange<Int>
    let onSave: (_ sets: Int, _ reps: Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var sets: Int
    @State private var reps: Int

    init(
        title: String = AppCopy.Workout.editTarget,
        subtitle: String? = nil,
        initialSets: Int = Self.defaultSets,
        initialReps: Int = Self.defaultReps,
        setRange: ClosedRange<Int> = Self.defaultSetRange,
        repRange: ClosedRange<Int> = Self.defaultRepRange,
        onSave: @escaping (_ sets: Int, _ reps: Int) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.setRange = setRange
        self.repRange = repRange
        self.onSave = onSave
        _sets = State(initialValue: Self.clamped(initialSets, to: setRange))
        _reps = State(initialValue: Self.clamped(initialReps, to: repRange))
    }

    var body: some View {
        AppSheetScreen(
            title: title,
            primaryButton: PrimaryButtonConfig(label: AppCopy.Workout.saveChanges, action: commit),
            dismissLabel: AppCopy.Nav.cancel,
            dismissActionPlacement: .cancellation,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.sm) {
                        targetStepper(label: AppCopy.Workout.targetSetsLabel, value: $sets, range: setRange)
                        targetStepper(label: AppCopy.Workout.targetRepsLabel, value: $reps, range: repRange)
                    }

                    VStack(spacing: AppSpacing.sm) {
                        targetStepper(label: AppCopy.Workout.targetSetsLabel, value: $sets, range: setRange)
                        targetStepper(label: AppCopy.Workout.targetRepsLabel, value: $reps, range: repRange)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
    }

    @ViewBuilder
    private func targetStepper(
        label: String,
        value: Binding<Int>,
        range: ClosedRange<Int>
    ) -> some View {
        let currentValue = value.wrappedValue

        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .appCapsLabel(.smallLabel)
                .foregroundStyle(AppColor.textSecondary)

            AppStepper(
                value: "\(currentValue)",
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
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private func commit() {
        onSave(sets, reps)
        dismiss()
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
        let available = exercises.filter { !existingIds.contains($0.id) }
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

    var body: some View {
        NavigationStack {
            List {
                if canCreateNew {
                    Button {
                        createAndSelect(name: trimmedQuery)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            AppIcon.addCircle.image()
                                .foregroundStyle(AppColor.accent)
                            Text("Create \"\(trimmedQuery)\"")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textPrimary)
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

                if filteredExercises.isEmpty && !canCreateNew {
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
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Nav.done) { dismiss() }
                        .appToolbarTextStyle()
                }
            }
            .appNavigationBarChrome()
            .tint(AppColor.accent)
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

    @State private var floatingAccessoryHidden: Bool = false
    /// True only when scroll content is actually under the chrome — either because
    /// content overflows the viewport or the user has scrolled past the top. Gates
    /// the manual chrome backdrop + soft-edge gradient so non-scrolling screens
    /// (e.g. a 2-card onboarding step) don't show a decorative fade band above
    /// content that never moves. Mirrors iOS-native nav-bar appearance behavior.
    @State private var chromeBackdropVisible: Bool = false

    init(
        primaryButton: PrimaryButtonConfig? = nil,
        secondaryButton: SecondaryButtonConfig? = nil,
        customHeader: AnyView? = nil,
        floatingAccessory: AnyView? = nil,
        hidesNavigationBar: Bool = false,
        showsNativeNavigationBar: Bool = false,
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
        self.usesOuterScroll = usesOuterScroll
        self.showsKeyboardDismissToolbar = showsKeyboardDismissToolbar
        self.surface = surface
        self.content = content
    }

    private var hasBottomBar: Bool { primaryButton != nil || secondaryButton != nil }
    private var hasBottomChrome: Bool { hasBottomBar || floatingAccessory != nil }

    /// Max content width — keeps the mobile layout on iPad / Mac.
    private var maxContentWidth: CGFloat { 430 }

    /// Safe-area chrome always needs a real backdrop because scroll content can
    /// pass underneath it. `surface == nil` only means the page fill is owned by
    /// a parent; the pinned header / CTA bar still resolve to Milk.
    private var chromeSurface: Color { surface ?? AppColor.background }

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
                .appScrollEdgeSoft(
                    top: customHeader != nil || !hidesNavigationBar || showsNativeNavigationBar,
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
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    // Show chrome backdrop the instant the user scrolls past
                    // the natural top edge — iOS-native nav-bar behavior.
                    //
                    // With nested safe-area insets (the host
                    // `NavigationStack`'s nav bar + this AppScreen's
                    // `safeAreaInset` for `customHeader`), `contentOffset.y`
                    // at natural top is `-contentInsets.top` — a *negative*
                    // value matching the total inset height (often 100–150pt).
                    // A naive `contentOffset.y > 0` trigger only fires once
                    // content has scrolled all the way past the visible top,
                    // leaving the customHeader's backdrop off while body
                    // rows are already overlapping its progress + title text
                    // (the bug visible on the training-split screen).
                    // `contentOffset.y + contentInsets.top > 0` is the
                    // iOS-native "scrolled past edge" condition.
                    geometry.contentOffset.y + geometry.contentInsets.top > 1
                } action: { _, shouldShow in
                    guard chromeBackdropVisible != shouldShow else { return }
                    chromeBackdropVisible = shouldShow
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
        .padding(.horizontal, AppSpacing.md)
        .padding(.top, showsNativeNavigationBar ? AppSpacing.md : (customHeader == nil ? AppSpacing.md : AppSpacing.sm))
        .padding(.bottom, AppSpacing.md)
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
                .background(AppScreenChromeBackground(surface: chromeSurface))
                // Opaque always: the chrome is a VStack sibling above the
                // ScrollView, so scroll content can't pass behind it. The
                // soft fade where scroll content meets this chrome's bottom
                // edge is handled by `.scrollEdgeEffectStyle(.soft, for: .top)`
                // on the ScrollView via `appScrollEdgeSoft`.
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
            // Tight sticky-CTA chrome — every pt of vertical padding here is
            // a pt that the input/scroll area above doesn't get. Top `sm`
            // (8pt) keeps the button visually separated from the scroll
            // content fading into it; bottom `xs` (4pt) sits just above the
            // home-indicator safe area, which already handles its own
            // breathing room. Was `md` top + `sm` bottom (24pt total) — the
            // chrome was eating the input area visibly on the onboarding
            // paste step and the split-builder validation state, and there
            // was no design reason for that extra slack. System-level: every
            // screen routing through `AppScreen` with a primary or secondary
            // button picks up the tighter padding (Today, Templates,
            // History, every onboarding step, sheets that wrap `AppScreen`).
            .padding(.top, AppSpacing.sm)
            .padding(.horizontal, AppSpacing.md)
            .padding(.bottom, AppSpacing.xs)
            .frame(maxWidth: maxContentWidth)
            .frame(maxWidth: .infinity)
            .background(AppScreenChromeBackground(surface: chromeSurface))
            // Opaque always: VStack-sibling chrome sits below the
            // ScrollView, scroll content never passes behind it. The
            // soft fade above this CTA bar is handled by
            // `.scrollEdgeEffectStyle(.soft, for: .bottom)` on the
            // ScrollView via `appScrollEdgeSoft`.
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
                    .opacity.combined(with: .offset(y: 12))
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
        // and `appScrollEdgeSoft` still fades content at the ScrollView's
        // top/bottom frame edges (where scroll content meets the chromes).
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
        .background((surface ?? Color.clear).ignoresSafeArea())
        .toolbar(showsNativeNavigationBar ? .automatic : .hidden, for: .navigationBar)
        .toolbarBackground(chromeSurface, for: .navigationBar)
        .toolbarBackground(
            showsNativeNavigationBar && chromeBackdropVisible ? .visible : .hidden,
            for: .navigationBar
        )
        .toolbar {
            if showsKeyboardDismissToolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
                    }
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.accent)
                }
            }
        }
    }
}

/// Backdrop for fixed chrome (sticky header / sticky CTA). It is deliberately
/// opaque: scroll content must never be readable through the header or CTA
/// chrome while moving beneath it.
private struct AppScreenChromeBackground: View {
    let surface: Color

    var body: some View {
        Rectangle()
            .fill(surface)
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
    /// so both entry points are a single source of truth. Pass `AppSpacing.sm`
    /// when the wrapped content already owns 16pt horizontal padding (e.g.
    /// `AppListRow`) so 8 + 16 composes to the canonical 24pt visual offset.
    func appCardStyle(contentInset: CGFloat = AppSpacing.lg) -> some View {
        self
            .padding(contentInset)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .modifier(AppCardElevation())
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
            // Defer bar chrome to the global `UINavigationBar.appearance()` proxy configured in
            // `ContentView.configureNavigationBarAppearance()` — standard appearance has
            // `shadowColor = .clear` (no hairline) and scroll-edge appearance is transparent.
            // SwiftUI's `.toolbarBackground(Material.bar, .visible)` would generate its own
            // appearance with a default separator, overriding the proxy and producing the
            // visible hairline beneath the bar. The soft scroll-edge fade is the only piece
            // that still belongs here.
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

    /// Canonical style for text-label toolbar buttons (e.g. "History", "Browse").
    /// Matches iOS-native bold top-bar actions so every screen reads the same weight.
    func appToolbarTextStyle() -> some View {
        self.font(AppFont.body.font.weight(.semibold))
    }

    /// iOS-native soft gradient fade at the ScrollView edges. Prevents the
    /// sharp-cut appearance of scrolled content meeting an opaque bar (nav bar,
    /// CTA, tab bar) on vertical scrolls, and the same sharp-cut at the
    /// leading/trailing inset on horizontal chip/filter strips. The OS only
    /// renders the fade where scrolling actually clips content, so calling this
    /// on a horizontal ScrollView fades leading/trailing automatically without
    /// extra parameters.
    ///
    /// This is the single canonical modifier for scroll-edge fade. Never add a
    /// parallel LinearGradient/mask-based fade; extend this instead.
    @ViewBuilder
    func appScrollEdgeSoft(top: Bool = true, bottom: Bool = true) -> some View {
        if #available(iOS 26.0, *) {
            switch (top, bottom) {
            case (true, true):   self.scrollEdgeEffectStyle(.soft, for: .all)
            case (true, false):  self.scrollEdgeEffectStyle(.soft, for: .top)
            case (false, true):  self.scrollEdgeEffectStyle(.soft, for: .bottom)
            case (false, false): self
            }
        } else {
            // iOS 18 fallback: `scrollEdgeEffectStyle` is iOS 26-only. Sharp
            // scroll edges; acceptable degradation per CLAUDE.md §7 (don't
            // grow the design system without explicit justification). To
            // restore the soft fade on iOS 18, extend this branch with a
            // centralized LinearGradient mask here — never fork into a
            // parallel modifier in feature code.
            self
        }
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
        case accentSoft                // `AppColor.accentSoft` (adaptive warm neutral / dim white)
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
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        // Scale the bubble diameter with Dynamic Type so the chrome around the
        // glyph grows in lockstep with `AppIcon.image`'s scaled point size —
        // otherwise large-text users see a tiny icon floating in a fixed
        // 36×36 well. Anchored to `.body` to match the icon scaling above.
        let scaledDiameter = UIFontMetrics(forTextStyle: .body).scaledValue(for: diameter)
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

// MARK: - Custom segmented control

/// SwiftUI segmented control with a soft (non-pill) radius, larger label text,
/// and a **single sliding** selected pill (spring-animated) on a track that
/// reads clearly against `AppColor.background`. The pill separates from the
/// track via fill contrast (white on grey), not shadow — matches the
/// flat-by-fill rule from visual-language.md §4.
struct AppSegmentedControl<Item: Hashable & Identifiable>: View {
    enum Size {
        case compact
        case tall

        var verticalPadding: CGFloat {
            switch self {
            case .compact: return AppSpacing.smd
            case .tall:    return AppSpacing.xl
            }
        }

        var minHeight: CGFloat { 44 }
    }

    /// Visual treatment of the selected pill. `.light` (default) keeps the
    /// historical white-on-grey look used by mode toggles. `.dark` flips to a
    /// black pill with white text — used when the picker doubles as a primary
    /// commitment (e.g. onboarding weekday assignment) and needs more weight.
    enum SelectionStyle {
        case light
        case dark
    }

    @Binding var selection: Item
    let items: [Item]
    var size: Size = .compact
    var selectionStyle: SelectionStyle = .light
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
        selectionStyle: SelectionStyle = .light,
        title: @escaping (Item) -> String,
        accessibilityLabel: ((Item) -> String)? = nil,
        isDisabled: ((Item) -> Bool)? = nil
    ) {
        self._selection = selection
        self.items = items
        self.size = size
        self.selectionStyle = selectionStyle
        self.title = title
        self.accessibilityLabel = accessibilityLabel
        self.isDisabled = isDisabled
    }

    /// Vertical breathing room above and below each label. `.compact` keeps
    /// mode toggles such as History List/Calendar tight; `.tall` preserves the
    /// larger set-count picker in workout sheets.
    private var verticalPadding: CGFloat { size.verticalPadding }
    private let trackRadius: CGFloat = AppRadius.md
    private let pillRadius: CGFloat = AppRadius.sm
    /// Uniform inset between the track edge and the pill (applied on all four sides).
    /// Using a single value keeps the pill visually centered inside the track.
    private let trackPadding: CGFloat = AppSpacing.xs

    private var pillFill: Color {
        switch selectionStyle {
        case .light: return AppColor.cardBackground
        case .dark:  return AppColor.textPrimary
        }
    }

    /// Track fill — `controlBackground` is a step darker than `AppColor.background`
    /// so the track reads as a separated surface via contrast alone.
    private var trackFill: Color { AppColor.controlBackground }

    private func foreground(isSelected: Bool, isDisabled: Bool) -> Color {
        if isDisabled { return AppColor.textDisabled }
        switch selectionStyle {
        case .light:
            return isSelected ? AppColor.textPrimary : AppColor.textSecondary
        case .dark:
            return isSelected ? AppColor.accentForeground : AppColor.textSecondary
        }
    }

    var body: some View {
        let trackShape = RoundedRectangle(cornerRadius: trackRadius, style: .continuous)

        ZStack(alignment: .leading) {
            // 1. Track background.
            trackShape.fill(trackFill)

            // 2. Pill — flat fill, no shadow.
            GeometryReader { geo in
                let count = max(items.count, 1)
                let segmentWidth = geo.size.width / CGFloat(count)
                let pillHeight = geo.size.height
                let index = items.firstIndex(where: { $0.id == selection.id }) ?? 0
                let pillX = CGFloat(index) * segmentWidth

                RoundedRectangle(cornerRadius: pillRadius, style: .continuous)
                    .fill(pillFill)
                    .frame(width: segmentWidth, height: pillHeight)
                    .offset(x: pillX)
                    .animation(.appConfirm, value: selection.id)
            }
            .padding(trackPadding)
            .clipShape(trackShape)

            // 3. Labels — drawn above the pill, never clipped so text stays crisp.
            //    Segment buttons span the full track height so the tap target
            //    matches the visual cell; visual centering is unchanged because
            //    the text glyph is centered in the frame. Horizontal trackPadding
            //    still applies so first/last labels don't kiss the track edge.
            HStack(spacing: 0) {
                ForEach(items) { item in
                    let isSelected = item == selection
                    let disabled = isDisabled?(item) ?? false
                    Button {
                        if !isSelected && !disabled {
                            selection = item
                        }
                    } label: {
                        Text(title(item))
                            .font(.geist(.semibold, size: 16, relativeTo: .body))
                            .foregroundStyle(foreground(isSelected: isSelected, isDisabled: disabled))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, verticalPadding)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(disabled)
                    .accessibilityLabel(accessibilityLabel?(item) ?? title(item))
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
    /// non-trivial collateral like nested arrays). Wraps the ID binding into an
    /// `Item` proxy so the canonical implementation stays single.
    init(
        selection: Binding<Item.ID>,
        items: [Item],
        size: Size = .compact,
        selectionStyle: SelectionStyle = .light,
        title: @escaping (Item) -> String,
        accessibilityLabel: ((Item) -> String)? = nil,
        isDisabled: ((Item) -> Bool)? = nil
    ) {
        let proxy = Binding<Item>(
            get: { items.first(where: { $0.id == selection.wrappedValue }) ?? items[0] },
            set: { selection.wrappedValue = $0.id }
        )
        self.init(
            selection: proxy,
            items: items,
            size: size,
            selectionStyle: selectionStyle,
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
                Color.clear.frame(height: AppSpacing.md)
            }
            .presentationDragIndicator(.visible)
            // Passing `nil` lets iOS use the system sheet corner radius, which matches
            // the device's display corner radius on modern iPhones. A custom value would
            // leave the bottom corners mis-aligned with the screen on iPhone 17.
            .presentationCornerRadius(nil)
            .presentationBackground(AppColor.background)
            .presentationContentInteraction(.scrolls)
            // Soft iOS-native gradient fade at both edges — consistent with full-screen pages.
            .appScrollEdgeSoft()
    }
}

/// Canonical press-feedback button style — 0.96x scale + `.appPress` easing.
/// Apply to every tappable card or row so "press" reads consistently. Press is
/// a touch confirmation, not motion, so this is intentionally not gated by
/// Reduce Motion (per Apple HIG: tactile feedback is permitted).
/// Canonical press-state treatment for every tappable atom in Unit —
/// `AppPrimaryButton`, `AppSecondaryButton`, `AppGhostButton`,
/// `AppFloatingPillButton`, `OnboardingOptionCard`, and every internal
/// `Button(...).buttonStyle(ScaleButtonStyle())` call site. **Fix here, not
/// at the screen layer**: any change to how a tap looks is a system-level
/// change and belongs in this struct so every surface flips together.
///
/// Three cues fire on press, all animating together via `.appPress` (0.15s)
/// in both directions:
///
/// 1. **Opacity → 0.88** — subtle dim. Big filled CTAs (accent primary)
///    showed too much state change at the original 0.7; 12 % is still
///    visible on the orange surface without making the button look broken
///    or unavailable mid-tap.
/// 2. **Brightness → -0.06** — the cue that survives on near-white surfaces.
///    Opacity alone on a white card over a Milk background is invisible
///    (you're letting Milk show through Milk). Brightness shifts every
///    color channel down by 6 %, so white reads as a perceptible light
///    grey, accent reads as a slightly deeper accent, and transparent
///    ghosts read as a faded text. Universal — works on every shape we
///    have without per-style branching.
/// 3. **Scale → 0.97** — secondary tactile cue. 3 % is enough to feel
///    without competing with the opacity/brightness shift.
///
/// **Animation is symmetric** (`.appPress` both ways). The earlier asymmetric
/// version (snap-on, ease-off) was meant to register 30ms taps but read as
/// a hard cut — "jumping from one side to the other". 0.15s in both
/// directions is short enough that even a fast tap renders a visible frame
/// or two of dim, and the on-and-off motion stays a single continuous gesture
/// rather than two disjoint moments.
///
/// **Navigation cards must hold the action briefly** (see
/// `OnboardingOptionCard.handleTap`'s 110ms `asyncAfter`). The press state
/// only exists while the finger is down — for surfaces that auto-advance to
/// another screen on release (option cards, but not regular CTAs that stay
/// in place), the slide transition starts the instant the action fires, so
/// without a tiny delay the press is gone before the eye registers it. The
/// hold is the *timing* fix; this style is the *visual* fix. Both layers
/// are needed for tap-to-navigate to feel acknowledged.
///
/// Outline / border highlights were rejected: an accent stroke around a card
/// reads as a selected *state* (persistent), not a momentary press feedback,
/// and looked wrong on filled CTAs where there is no white background to
/// stroke against.
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.88 : 1)
            .brightness(configuration.isPressed ? -0.06 : 0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.appPress, value: configuration.isPressed)
    }
}

extension String {
    func truncatedForNavigationTitle(maxGlyphCount: Int = 34) -> String {
        guard count > maxGlyphCount else { return self }
        let end = index(startIndex, offsetBy: maxGlyphCount)
        return String(self[..<end]).trimmingCharacters(in: .whitespaces) + "…"
    }
}
