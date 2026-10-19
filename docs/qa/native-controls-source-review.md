# Native segmented controls — source review

Status: edits applied, not yet verified. Build queue held by the main release chat.
Base: `9643cb8567b082cf37ace5529b23a4b188737a06`.
Branch: `codex/unit-native-controls`.

## Scope

Canonical owner: `Unit/UI/DesignSystem.swift`, `AppSegmentedControl`.
No new components, variants, tokens, dependencies, persistence, or navigation.
Native SF Pro/SF Mono and low tracking were already present at the base commit.
Profile, analytics, ContentView, RootTab, release numbers, and phone installs are outside this change.

## Complete consumer matrix

All production references, including their existing preview paths, route through the shared owner.

| Consumer | State / items | Previous size / style | Disposition on iOS 26+ |
|---|---|---|---|
| SettingsView, Preferences | AppStorage string adapted to SettingsWeightUnit; kg/lb | compact / light | Native Picker; same storage binding |
| HistoryView | State SessionHistoryMode; List/Calendar | compact / light | Native Picker; same content switching |
| ExerciseProgressView | State ProgressMetric; Weight/Reps/Volume | compact / light | Native Picker; bodyweight still initializes Reps |
| TodayWeekOverviewSheet | State String ID; WeekOverviewTab with day snapshots | compact / light | Native Picker; ID proxy preserves IDs and does not mutate snapshots |
| SetCountPickerSheet | State SetCountOption; 1...6, initially 3 | tall / light | Native Picker; Done still commits once and dismisses |
| OnboardingLibraryPickerView | Binding DayCountOption?; supported training-day counts | weekday / light | Keep distinct: nil stays unanswered; selecting still calls selectDays; no automatic answer |
| OnboardingScheduleView | Binding Int weekday ID; Monday-first, Apple weekday IDs 2...7,1 | weekday / light | Keep distinct: taken days are disabled buttons with full weekday/row labels; flexible schedule and existing explicit seeding remain owned by screen |

The Item, optional Item, and Item.ID initializer models remain supported.
The Item.ID proxy now returns nil for an unmatched ID or empty items; it no longer indexes items[0] or paints a fabricated first choice.
Optional initializers retain the same button implementation after selection, so answering does not replace the control with a different kind.
Any per-item disabled predicate retains buttons. Container-level disabled propagation remains native SwiftUI behavior.
Missing IDs retain an unselected button track until the user chooses a valid item.

All consumers retain buttons on iOS 18: large native segmented controls were introduced in iOS 26, and wrapping a smaller segment in a 44pt frame alone does not establish a 44pt interactive target.
Native controls use the platform large control size; their final hit bounds still require runtime measurement.

## Removed and retained

- Removed unused SelectionStyle.light/dark chrome API. All seven callers used the default light treatment; no dark caller existed.
- Removed Size.tall and its one caller. Set count uses the system-sized control rather than extra vertical padding.
- Retained Size.compact and Size.weekday for fallback touch/layout bounds.
- Retained one shared button implementation for unanswered, disabled, and compatibility cases.
- Routed retained selection motion through appAnimation, honoring Reduce Motion and VoiceOver policy.
- Reused AppFont.sectionHeader for fallback labels, replacing inline 16pt styling with the existing standard 17pt role.
- Added a group label to every caller; existing per-item labels remain intact.

## Comparison evidence

Unverified: no new runtime capture, screenshot comparison sheet, or interaction evidence yet.
The existing DEBUG Components catalog (Settings → Components) now instantiates production native/retained controls with matching List/Calendar content, an unanswered choice with Clear, per-item-disabled choice, inherited disabled control, ID binding, and empty items.
These are capture fixtures, not rendered evidence and not a before screenshot.

After the main chat releases the queue: capture the catalog and real weekday/day-count screens; package real matching captures with the atomic skill comparison-sheet script. Include context, light appearance, OS, device width, content size, selected/unselected/disabled state, and verification status. The Apple Sports match-detail sheet is the platform-composition reference, not evidence of Unit's changed controls.

## Verification

Passed: scripts/check-guards.sh, git diff --check, Swift frontend syntax parsing of all eight changed Swift files.
Not run: Xcode type checking/build, automated app tests, Simulator, rendered comparison, Dynamic Type, VoiceOver, Reduce Motion, hit-bound measurement, physical-device checks.
No build/install/release changes were performed while the main release owns the queue.

Focused runtime checks remain: change and persist weight unit; switch History and chart metric; switch week IDs; change set count and commit with Done; confirm nil training days keep Continue disabled then choose/switch/back; confirm weekday IDs/full labels and collision disablement; test inherited disabled, empty/missing IDs, Dynamic Type, Reduce Motion, VoiceOver, and 44pt targets. Repeat on iOS 18 fallback and iOS 27 primary.

## API evidence

- [Apple Picker](https://developer.apple.com/documentation/SwiftUI/Picker)
- [Apple optional tags](https://developer.apple.com/documentation/swiftui/view/tag(_:includeoptional:))
- [Apple iOS 26 release notes: large segmented Picker support](https://developer.apple.com/go/?id=ipados-26-rn)
