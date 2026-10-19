# Analytics R5 — calculation checkpoint, UI approval pending

## State

Local source only. Version/build remains 2.1 (84); no phone installation, submission, schema change, or training-data writes. Analytics and exercise-detail UI are unchanged. This is a partial implementation, not the finished Analytics page.

The supplied R5 main, scrolled, detail, bodyweight-detail, and summary-sheet images are the implementation references. Grey text tiles in those references stand for SF Symbols, not literal UI labels.

## Applied

- `Unit/Features/Analytics/AnalyticsEngine.swift`: pure Sendable snapshot input/output with injected clock/calendar. Valid working sets and completed sessions only, local-day windows including today, future-day filtering, per-day bests, epsilon comparisons, earliest record ties, weekly buckets, status thresholds and bounded deterministic persistence. Exact normalized barbell alias selection, candidate selection, separate exercise identities and accepted targets. No writes or recommendations.
- `AnalyticsSnapshot.swift`: main-actor bridge from existing SwiftData models to immutable values. Reads the existing valid-set predicate and accepted routine targets. Explicit unknown equipment becomes nil; explicitly stored Other remains non-barbell.
- `AnalyticsFormatting.swift`: extensions on the existing `WorkoutTargetFormatter`. Analytics-only locale-aware decimal/unit, delta, comparison, date, summary and spoken-set formatting. Existing logging formatting is untouched.
- `UnitTests/AnalyticsEngineTests.swift`: 14 focused tests, including in-memory SwiftData read-only evidence and a five-year performance fixture. Existing telemetry `UnitAnalyticsTests` remains separate and unchanged.
- Xcode project: registers the new files; no version/build change.

Storage finding: `SetEntry.weight`, planned weights and accepted targets use canonical kilograms, not per-set display units. Pounds are presentation conversion only.

No past schedule history exists. Input explicitly takes current planned routine count and uses × 4. Integration with active split/TrainingWeekProgress belongs to the pending page work. §11's single-session baseline exception is honored even after 14 days; §11's positive-load rule takes precedence over an exercise's BW label. Both choices are commented in the calculation owner.

## Evidence

Latest command: selected `UnitTests/AnalyticsEngineTests` and `UnitTests/ProgressionPersistenceTests`, iPhone 16 Simulator, iOS 18.6, Debug. 39 tests passed, zero failures (14 analytics + 25 persistence). Latest log: `/private/tmp/unit-analytics-r5-tests-4.log`; result bundle under `/private/tmp/unit-analytics-r5-build/Logs/Test/`.

Five-year fixture: 1,040 sessions × 8 exercises × 3 sets. Latest XCTest average 58 ms in Debug Simulator. The physical iPhone 12 / <50 ms requirement is NOT established. No new analytics-source warnings were reported; pre-existing test actor-isolation and App Intents metadata warnings appeared in the initial full build.

The first run had a faulty threshold fixture: an older session was still inside a rolling A window. Corrected the fixture; subsequent runs pass. Performance revisions removed repeated calendar arithmetic, copy-on-write accumulation, unnecessary best-set sorting and repeated candidate-window work. No test failures were hidden or disabled.

Source guards and whitespace checks pass. No visual evidence, chart interaction test, Audio Graph test, screenshot matrix, or ProgressionContractUITests run yet. The visible page has not changed, so those deliverables would be premature.

## Questions / blocked

User §0 explicitly requires approval before shared design-system additions. An approval question is pending for:

- `AppStatusSummaryCard`: combined accessible summary + sheet affordance; composes existing AppCard.
- `AppMainLiftCard`: existing AppCard surface plus measured performance, chart and Best/Next composition; the existing session card does not own this contract.
- `AppTrendChart`: one Swift Charts owner for card and detail weekly series, empty/single-point modes and Audio Graphs. There is no existing shared chart owner.
- A 34pt status typography role; 96/120pt chart heights; missing info, functional/traditional strength, climbing and core SF Symbol tokens.

Reuse existing `AppScreen`, `AppSectionHeader`, `AppCard`, `AppCardList`, `AppListRow`, `EmptyStateCard`, native segmented Picker, native NavigationStack and sheets, AppFont numericInput (30pt), semantic colors, spacing and AppRadius.md (14pt). Do not change global card radius or logging typography to match these analytics cards.

No missing storage field currently blocks the specified analytics. No new View, ViewModifier, UI variant, token, design-system file change, or schema field has been created while approval is pending.

## Next

After explicit component approval: move profileTab into AnalyticsView; wire a completed-session FetchDescriptor with setEntries prefetch, immutable snapshot background compute and day/save invalidation; add the approved shared owners and icon tokens. Migrate the detail page to the same engine data while preserving its native metric picker and old SessionPoint API consumers. Add remaining persistence/flip-flop/chart/target regressions and required visual states. Keep logging/progression files untouched. Do not bump or install until Efe explicitly requests delivery.

API references checked: [SwiftData prefetch](https://developer.apple.com/documentation/swiftdata/fetchdescriptor/relationshipkeypathsforprefetching), [ModelContext save notifications](https://developer.apple.com/documentation/swiftdata/modelcontext), [Audio Graph descriptor](https://developer.apple.com/documentation/accessibility/axchartdescriptor).
