# Protected behaviors

Run `scripts/check-guards.sh` before every commit that changes Unit or UnitWidget.
Run `scripts/check-guards.sh --self-test` when changing the guard. It creates and
removes a temporary Git repository; it never mutates this checkout.

These contracts describe the October 19 motion/feedback release. Preserve them
when fixing or simplifying UI. Runtime acceptance remains in [release QA](release-qa.md).

| Contract | Owner / static evidence | Runtime acceptance |
|---|---|---|
| One-tap prefilled logging, no keyboard on the happy path, no delay for feedback | `ActiveWorkoutView`, `WorkoutCommandCard` | Gym Test: log a set in ≤3 seconds; rapid taps cannot duplicate a set |
| Save succeeds before success feedback, navigation, progression acceptance, or an Undo result | Active workout and routine persistence methods; failed writes roll back | Force a save failure: draft survives, no success moment, history remains intact |
| Target editor retains edits on failure and owns its failure alert | `AppSetRepEditorSheet`; `TemplateDetailView.saveTarget` suppresses the parent alert | Failed Save shows one alert; dismiss it, correct/retry, then close only after success |
| All color, curve, and tactile definitions have one owner | `AppColor`, `AppMotion`, `AppHaptic` in `Unit/UI/DesignSystem.swift` | Existing palette remains; native SF Pro/SF Mono with restrained tracking; no feature-specific styling forks |
| Reduce Motion OR VoiceOver disables travel, blur, bounce, scale feedback, and confetti; haptics remain enabled | `AppMotion.allowsSpatialMotion`, shared transitions, `ScaleButtonStyle`, `AppNumericValue`, `AppCelebration` | Test each setting separately and together; fade-only feedback, usable controls, no confetti |
| Introductions remember their arrival within their surface; ordinary lists and logging controls never wait for staging | `AppRevealSession`, `AppScreenEnter`; native tab arrival is a cross-fade | Scroll away/back, switch tabs, background/foreground: no replayed stagger or hidden controls |
| Completed/failed set chips with actions remain accessible buttons; read-only chips remain text | `SetProgressIndicator.renderStep` | VoiceOver announces Button and activates the exact set editor; UI test finds the chip as a Button |
| Numeric updates share one accessible treatment | `appNumericValue` on steppers, metrics, set chips, readiness, and progress; native rest-timer treatment | Changed values are legible; VoiceOver/Reduce Motion use opacity, not rolling digits |
| Native tab navigation stays haptically quiet | `ContentView`; guard rejects a selected-tab haptic | Switching tabs has only native navigation feedback |
| One set success cue also covers a personal record | `WorkoutCommandCard`, scene-owned `AppFeedbackState` | One tactile confirmation per completed set; no duplicate PR haptic or replay on appearance |
| Celebration identity and start time are stable; expiry does not restart on redraw | `AppCelebrationMoment`, `AppCelebration` | Returning after expiry does not replay confetti; active logging stays tappable |
| Toasts are occurrences, not strings; stale work cannot dismiss or act on a replacement | `AppToastEvent.consume`, `AppToast`; regression tests in `AppFeedbackPolicyTests` | Replace an actionable toast, tap the old occurrence, and wait for its old timeout: replacement survives |
| Undo is consumed before its handler; its target is the exact removed set | `AppToastAction`, `SetEntrySnapshot`, active-workout Undo | Double tap cannot restore twice; relaunch preserves the exact restored set |
| Errors persist; ordinary toasts last 2s, actionable toasts 4s; VoiceOver holds them for dismissal | `AppToastEvent.duration`, `AppToast` | Long text wraps at accessibility size; action and close remain reachable; one announcement per occurrence |
| Training data stays local and existing history survives | Existing SwiftData models and rollback paths; no schema changes in this quality pass | Upgrade/migration, offline logging, template deletion with history, and relaunch checks in release QA |

## Guard scope and narrow exceptions

The guard scans **Git-tracked `.swift` files in both `Unit/` and `UnitWidget/`**,
using their current working-tree contents. Stage newly created sources before
running the commit gate. Missing tracked paths are treated as pending deletions.
It reports file and line, masks comments/strings, and identifies balanced enum
bodies. Only the exact `AppColor`, `AppMotion`, and `AppHaptic` declarations in
`DesignSystem.swift` may define their raw APIs. Other declarations in that file
are checked too; extensions and same-named enums elsewhere do not gain permission.

- `UIColor(AppColor.token)` bridges an existing token into native UIKit chrome.
  It does not define a new color.
- `RestTimerLiveActivity.swift` alone may use `.foregroundStyle(.primary)`,
  `.foregroundStyle(.secondary)`, and `.keylineTint(.primary)` for native Lock
  Screen/Dynamic Island contrast. This grants no raw RGB, named color, haptic,
  or animation-curve exemption. Widget typography/layout remain system-native.
- `OnboardingSplashView.swift` alone may use the exact
  `.preferredColorScheme(openerVisible ? .dark : .light)` expression for the
  recorded temporary black brand opener. The app returns to light afterward.
- Clear layout surfaces use `AppColor.clear`; transparency has no file exemption.
- Stable 64-bit confetti seed constants are arithmetic, not RGB/ARGB colors.

This targeted lint rejects raw color constructors/literals and common shorthand
colors, raw animation curves/default transactions, and direct haptic APIs outside
their owners. It is not a Swift type checker and cannot prove event ordering,
accessibility, persistence, or arbitrary aliases. Mutation fixtures prove its
covered cases; XCTest and the runtime matrix above cover behavior.

## Typography override — October 19

The user selected native SF Pro with low letter spacing. `Font.geist` and
`UIFont.geist` are compatibility names backed by native system fonts; numeric
roles use native SF Mono. Caps labels use SF Pro with zero extra tracking.
Existing point sizes remain; headings tighten by 0.3pt and the splash by 0.6pt.
Native Dynamic Type scaling remains, without expanding the scope into a large-text
layout redesign. Bundled font assets/project registration are left for separate
cleanup; runtime typography no longer requests Geist.

## Review surface

Debug: Settings → Design system → Components. Large text can be previewed there.
Use actual iOS Accessibility settings for Reduce Motion and VoiceOver; the catalog
does not override read-only environment values. Its failed-save editor is a local
fixture, not a persisted workout. Builds, Simulator, and device acceptance are
owned by the coordinating release chat.

## Native chrome override — October 19

Native navigation material and separators stay intact. Pinned headers/action areas use the shared `.bar` background and full-width boundaries. The existing canonical edge modifier owns hard vertical/soft horizontal clipping; feature-local gradient fades must not return. Sheets defer their background to iOS. This overrides the previous soft-gradient-only bar treatment, without changing content-card fills or any sizes.
