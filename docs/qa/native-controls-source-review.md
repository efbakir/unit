# Native segmented controls — source review

Status: source built; focused iOS 27 cases passed as listed below. Main owns remaining combined verification.
Base: `9643cb8567b082cf37ace5529b23a4b188737a06`.
Branch: `codex/unit-native-controls`.

## Scope

Canonical owner: `Unit/UI/DesignSystem.swift`, `AppSegmentedControl`.
No new production components, variants, tokens, dependencies, persistence, or navigation.
Native SF Pro/SF Mono and low tracking were already present at the base commit.
Profile, analytics, ContentView, RootTab, release numbers, and phone installs are outside this change.

## Complete consumer matrix

All seven source consumers, including their existing preview paths, route through the shared owner. TodayWeekOverviewSheet currently has no production call site; its ID-binding contract is exercised in the catalog.

| Consumer | State / items | Previous size / style | Disposition on iOS 26+ |
|---|---|---|---|
| SettingsView, Preferences | AppStorage string adapted to SettingsWeightUnit; kg/lb | compact / light | Native Picker; same storage binding |
| HistoryView | State SessionHistoryMode; List/Calendar | compact / light | Native Picker; same content switching |
| ExerciseProgressView | State ProgressMetric; Weight/Reps/Volume | compact / light | Native Picker; bodyweight still initializes Reps |
| TodayWeekOverviewSheet | State String ID; WeekOverviewTab with day snapshots | compact / light | Native Picker; currently unused sheet definition; ID proxy preserves IDs and does not mutate snapshots |
| SetCountPickerSheet | State SetCountOption; 1...6, initially 3 | tall / light | Native Picker; Done still commits once and dismisses |
| OnboardingLibraryPickerView | Binding DayCountOption?; supported training-day counts | weekday / light | Keep distinct: the control leaves nil unanswered; the screen retains its existing explicit three-day default and selectDays behavior |
| OnboardingScheduleView | Binding Int weekday ID; Monday-first, Apple weekday IDs 2...7,1 | weekday / light | Keep distinct: taken days are disabled buttons with full weekday/row labels; flexible schedule and existing explicit seeding remain owned by screen |

The Item, optional Item, and Item.ID initializer models remain supported.
The Item.ID proxy now returns nil for an unmatched ID or empty items; it no longer indexes items[0] or paints a fabricated first choice.
Optional initializers retain the same button implementation after selection, so answering does not replace the control with a different kind.
The screen already calls preselectDefaultDaysIfNeeded on entering its days question. Main explicitly confirmed preservation of that product decision; the catalog independently tests true nil, selection, switching, and clearing.
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

## Runtime verification handoff

Actual iOS 27 / iPhone 17 Simulator log passes:

- 11 AppFeedbackPolicyTests, including Reduce Motion/VoiceOver spatial-motion policy.
- testReadyMadeProgramPathMatchesCatalogFromThreeAnswers: existing default, navigation persistence, selecting Wednesday, and other routine disabled for that occupied day.
- testNativeHistoryAndProgressConsumers: Calendar/List and Reps/Volume/Weight switching.
- testPastedStartingTargetSurvivesRelaunchAndLogsInOneTap: one-tap set logging still records the prefill.
- testNativeSegmentedSelectionContracts: native Picker identity, weight-unit persistence across a non-seeding relaunch, 44pt Settings targets, selection/switch/clear, disabled predicate, inherited disabled, ID binding, and empty items.
- testNativeSelectionsAtLargeText: accessibility3 catalog capture, retained selection, target height and horizontal bounds.

Logs: /private/tmp/unit-native-controls-ios27-pass2.log and /private/tmp/unit-native-controls-ios27-pass3.log. The first bundle stalled during finalization; main requested stopping isolated verification for combined testing. Both xcodebuild processes were stopped; their aggregate run status is interrupted, not passed. Individual completed cases above are recorded by XCTest. Raw screenshot PNG payloads remain recoverable from the bundles' Data directories, with source provenance.

Initial failures were corrected: the extracted fallback needed @ViewBuilder; persistence testing needed a non-seeding relaunch because StartingTargetUITestSeeder explicitly rewrites kg; set-count testing needed the Freestyle route. The corrected set-count test was interrupted while opening exercise search and has NOT passed.

Pending for main: set-count selection/Done, iOS 18 fallback, final combined-source suite, native/fallback full target bounds, VoiceOver narration, runtime Reduce Motion, and physical-device Gym Test. The unused WeekOverviewSheet has no reachable production route; its binding model is tested in the catalog.

Static checks: source guard, UI banned-list hook, whitespace check. No version/build-number changes, integration, or phone operation. Shared lock released after the leased Simulator was shut down; unrelated devices were untouched.

## Comparison evidence

[Inspected compact comparison](native-controls/comparison.png) · [Portable HTML](native-controls/comparison.html) · [Screenshot provenance](native-controls/provenance.json) · [State hashes](native-controls/state-comparisons.json) · [Test log extract](native-controls/test-log-extract.txt).

Real PNG screenshots were recovered without modification from XCTest payloads. The compact PNG sheet was opened and visually inspected. Full-screen originals accompany the isolated crops. Native List and retained List share matching content; unanswered and answered crops visibly differ, as do History, progress-metric and weekday states. These are current production native and retained fallback controls, not fabricated before screenshots.

The HTML was generated by the atomic-design skill and structurally checked. Browser policy rejected local file URLs, so HTML browser layout is unverified; the inspected PNG sheet is the primary deliverable. No browser-policy workaround was used.
The existing DEBUG Components catalog (Settings → Components) uses matching List/Calendar content, an unanswered choice with Clear, per-item-disabled choice, inherited disabled control, ID binding, and empty items.

## Hard gates and limitations

This is a contextual, provisional review, not an official passing scorecard.

| Gate | Result | Evidence |
|---|---|---|
| Source guards / UI hook | PASS | Static checks on changed source |
| 44pt targets | UNVERIFIED | Native Settings width+height and catalog segment heights asserted; all siblings/weekday widths require main's check |
| Text contrast | UNVERIFIED | Retained enabled text tokens calculate 19.80:1 selected, 5.72:1 unselected; native sampled contrast not measured |
| Non-colour meaning / motion | UNVERIFIED | Selected traits and disabled actions asserted; 11 policy tests pass; live VoiceOver/Reduce Motion still pending |
| Gym Test | UNVERIFIED | One-tap logging UI test passes; physical fatigue/time measurement not run here |
| Affordances | UNVERIFIED | Verified selection contracts; set-count completion interrupted |
| Distinct states | PASS for captured pairs | Hashes and visible selected-state differences recorded |
| Light / portrait | PASS for captures | All supplied screenshots are light, portrait; no appearance or orientation code changed |

The local large-text toggle sets SwiftUI dynamicTypeSize. Because shared font helpers bridge through UIFontMetrics, that toggle alone does not prove full system accessibility text scaling. Main should use system/launch content-size settings for that claim.

## API evidence

- [Apple Picker](https://developer.apple.com/documentation/SwiftUI/Picker)
- [Apple optional tags](https://developer.apple.com/documentation/swiftui/view/tag(_:includeoptional:))
- [Apple iOS 26 release notes: large segmented Picker support](https://developer.apple.com/go/?id=ipados-26-rn)
