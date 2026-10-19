# Unit Analytics R5 handoff

## Delivery state

Implemented locally on `main`, starting from calculation checkpoint `5856391`. Version/build remains **2.1 (84)**. This stage has not been installed on the phone, pushed, uploaded or submitted. Efe asked to wait for an explicit delivery request. No production training data was changed, no schema migration was added, and logging/progression source files were not edited.

The supplied R5 main, scrolled, weighted detail, bodyweight detail and summary-sheet images are the reference. Their text icon tiles were interpreted as SF Symbol placeholders. Copy follows the supplied strings, with no coaching or decorative language.

## What changed and why

| File | Change |
|---|---|
| `Unit/ContentView.swift` | Replaced only the old profile-page body with `AnalyticsView` inside its existing NavigationStack. Removed Analytics-only queries/helpers. Native tab composition and tab appearance are byte-identical to checkpoint5856391. |
| `Unit/Features/Analytics/AnalyticsView.swift` | Summary, three main-lift slots, compact other-exercise rows and exact explanation sheet. No History row, totals, score, paragraph or invented recommendation. Recomputes for saves, day/time-zone changes, foregrounding, plan changes and appearance. |
| `Unit/Features/Analytics/AnalyticsStore.swift` | Read-only SwiftData fetch with completed-session predicate and setEntries prefetch, immutable snapshot, detached calculation, input/day/calendar cache and stale-result protection. |
| `Unit/Features/Analytics/AnalyticsEngine.swift` | Pure injected-clock/calendar engine for valid sets, local-day windows, records, comparisons, persistent status, aliases, slot selection and weekly chart data. Retains near-maximum day candidates so the0.01kg epsilon cannot compound across buckets. Unloaded sessions remain in Recent for a weighted exercise. |
| `Unit/Features/Analytics/AnalyticsFormatting.swift` | Reuses WorkoutTargetFormatter for locale-aware kg/lb, BW, deltas, dates, summary and spoken values. Small positive deltas never display as+0. Logging formatting is unchanged. |
| `Unit/Features/History/ExerciseProgressView.swift` | Uses the same engine for hero/comparison,12-week chart, accepted Next, all-time Best/date, estimate info and last two sessions. Retains native metric selection and SessionPoint compatibility API. Bodyweight has no picker or estimated max. |
| `Unit/UI/DesignSystem.swift` | Adds only the three approved Analytics compositions and approved typography/chart/icon tokens. Shared chart owns both card and detail axes, hollow/latest points, empty/single-point modes, scrub readout and Audio Graph descriptor. |
| `Unit/UnitApp.swift` | DEBUG-only isolated Analytics test fixtures, gated by explicit UI-testing flags. Normal launch and the user store do not use them. |
| `UnitTests/AnalyticsEngineTests.swift` |18 calculation/format/storage/performance regressions. |
| `UnitUITests/AnalyticsR5UITests.swift` |3 journey/state cases and screenshots, including summary, weighted/BW detail, native metrics, missing main lift, lb and AX3. |
| `UnitUITests/ProgressionContractUITests.swift` | Updates obsolete Analytics assertions; Settings remains reachable from Programs. Keeps finish, acceptance, relaunch, history and next-workout checks. |
| `Unit.xcodeproj/project.pbxproj` | Registers new source/test files only; all build numbers stay84. |
| `docs/atomic-design-system.md`, `docs/decision-log.md`, `docs/visual-language.md` | Records approved ownership, intentional reuse and SF Pro/SF Mono conventions. |

## Shared system and approvals

Efe explicitly approved `AppStatusSummaryCard`, `AppMainLiftCard`, `AppTrendChart`, `AppFont.analyticsStatus` (34pt/-0.8tracking),96/120pt chart heights and missing info/squat/deadlift/climbing/core symbols. All live in `Unit/UI/DesignSystem.swift`.

Reused AppScreen, AppSectionHeader, AppCard, AppCardList, AppListRow, EmptyStateCard, AppIconCircle, AppDivider, shared disclosure/press feedback, existing numeric and caption roles, native NavigationStack/TabView/sheets and the existing native segmented-control policy. No new palette, font family, shadow, haptic intent, tab style or global size change.

Intentional differences: plain exercise lists keep the existing22pt shared list radius rather than creating another list variant; new Analytics cards use the approved14pt radius. Native navigation retains the existing platform back affordance. iOS18 and27 render native bars differently; the rounded iOS27 bottom navigation was preserved.

## Data decisions

- **Storage is canonical kilograms.** SetEntry, starting values and accepted targets store kg. Unit selection converts presentation only and does not change comparison results.
- Completed sessions and valid completed working sets only; warm-ups, incomplete/invalid sets and future local days are excluded.
- Current active-program planned days ×4: past schedule versions are not stored. This limitation is commented in the calculation owner.
- Exact normalized barbell aliases only; candidate histories are never merged. Explicit Other equipment is not treated as unknown barbell equipment.
- Accepted Next comes from the most recent containing routine. No target is calculated or accepted from Analytics.
- Spec§11 single-session baseline takes precedence over the older-than14days ambiguity in§6. Positive loaded history takes precedence over a BW exercise label, per§11. Both are commented.
- Both load and reps lower is Mixed, as specified. Status is computed with bounded three-day persistence; no status is stored.

## Verification

All runs used isolated test stores on iPhone16 Simulators. No phone install/reset, no production-store writes, and no StoreKit charge.

| Run | Result | Evidence |
|---|---|---|
| iOS27.0 integrated run |46 tests passed:18 engine,25 persistence,3 Analytics UI | `/private/tmp/unit-analytics-r5-ios27-final.log`; result `Test-Unit-2026.10.19_20-35-30-+0800.xcresult` |
| iOS18.6 integrated run |48 tests passed:18 engine,25 persistence,3 Analytics UI,2 progression journeys | `/private/tmp/unit-analytics-r5-ios18-final.log`; result `Test-Unit-2026.10.19_20-38-06-+0800.xcresult` |

Result bundles are under `/private/tmp/unit-analytics-r5-build/Logs/Test/`; temporary logs/bundles are local evidence and may be cleaned by the OS. Durable screenshots are in [the QA folder](../qa/analytics-r5/README.md).

The iOS27 integrated run used system dark appearance and Increase Contrast; Unit remained light. The screenshot review caught an overlapping final pair of date labels specific to the wider iOS27 axis text. The shared date positions were then spread at approximately four-week intervals without changing chart points or values. Post-fix21-test runs (18engine +3Analytics UI) passed on both OS versions. Logs: `/private/tmp/unit-analytics-r5-axis-ios27.log` and `/private/tmp/unit-analytics-r5-axis-ios18.log`. Final screenshot details are recorded in the QA index.

Calculation coverage includes window boundaries, comparison matrix, exact thresholds, baseline boundary, stable/flip-flopping status with live counts, no-plan/current-plan behavior, aliases/equipment/variants/tie breaks/rename, invalid/warm-up/future data, time zones, earliest PR ties, decimal/lb formatting, empty/gapped/single-point charts, accepted-target routine selection, mixed BW/weighted history, epsilon frontier, read-only in-memory storage and five-year history. Existing persistence/migration tests stay green. The iOS18 progression journey finishes a workout, accepts targets, relaunches, checks Analytics and History, switches units and starts the next workout with accepted prefill.

No new Analytics-source warnings were found. Older test actor-isolation warnings and the existing AppIntents metadata warning remain. Source guard and changed-Swift banned-list checks passed; final whitespace/source-checkpoint evidence is recorded with the local commit.

## Performance and remaining proof limits

Five-year fixture:1,040sessions ×8exercises ×3sets. Integrated Debug Simulator averages were60ms(iOS27) and67ms(iOS18). Optimized Mac run over20iterations averaged16.14ms, maximum22.15ms. These are not physical iPhone12 results: the specified under50ms hardware budget remains unconfirmed.

Native Audio Graph descriptors, combined spoken labels, decorative-icon hiding and Reduce Motion handling are implemented. AX3 was captured. Manual VoiceOver audio, AX5, system Reduce Motion toggling, held chart-scrub readout, long-name/localization screenshots and first-frame loading timing were not fully exercised. Do not report those as verified. Charts have no card gestures; detail readouts reset on gesture release/cancellation by GestureState ownership.

No missing model field blocks the requested analytics. Hardware performance and the remaining manual interaction/accessibility checks are the outstanding acceptance evidence. No change to logging, recommendations or schema is needed for them.

## Next

1. Efe reviews the iOS27 main, scrolled and detail screenshots, with the existing rounded bottom bar.
2. Complete remaining manual chart/accessibility and physical-device performance checks when access permits.
3. Only after Efe requests delivery: prepare a new build, upgrade in place and confirm launch/history. Leave public submission to Efe.
