# Profile and progress research

Checked 19 October 2026. Bounded desk research: official product/help pages and the reviews Apple surfaced on two US App Store pages. No competitor app was installed in this pass. These reviews illustrate individual needs; they are not a representative sample or proof of demand for Unit.

## Recovered Unit direction

- `docs/archive/geminiresearch-mvp-pivot.md` describes the notebook gap and complexity fatigue. It is an archived synthesis, not fresh interview evidence. Its cycle roadmap and implementation suggestions are superseded.
- `docs/archive/geminiresearch-1.md` proposed cycles, recovery and a composite progress index. Current scope explicitly rejects those ideas; this task does not revive them.
- `docs/decision-log.md`, 3 August: transparent progression guidance, explicit acceptance, no automatic program rewrite, three-second set logging. The 12 August entry leads with “Know what to lift next.”
- `docs/app-positioning.md` and `docs/product-compass.md` keep a quiet path from a chosen routine to completed performance and one understandable next target.
- `docs/qa/competitor-overhaul/coverage.md` records an August benchmark review. Its inspection counts and runtime results are historical reports; this pass did not repeat that review.

The direct request authorizes a private Profile tab. It does not authorize social profiles, accounts, biometrics, leaderboards, coaching, or extra controls while logging.

## Current external evidence

| Source | Concrete pattern | Useful adaptation / limit |
|---|---|---|
| [Hevy official progress guide](https://www.hevyapp.com/features/gym-progress/) — accessed 19 Oct; no publication date shown | Profile links to Statistics, Exercises, Calendar and saved workouts. Exercise records expose heaviest load, projected/actual 1RM, session volume and reps, with underlying history. | Give progress a direct tab and reuse exercise history. Unit omits social identity, body measurements, streaks and strength rankings. Do not copy assets or branding. |
| [Hevy US App Store](https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350) — Organic Mel, 26 Jul 2025 | This reviewer praises weekly/session analytics but objects to bodyweight squats contributing no load volume. The reviewer proposes a body-mass fraction. | Clarify the measured quantity. Unit has no measured body mass or movement-specific fraction; use reps for BW rather than inventing kilograms. This is one review, not validated demand for a bodyweight-load model. |
| Same Apple page — 69burner69, 23 Dec 2024 | Praises graphs, describes importing more than 800 older workouts, and reports cumbersome year selection. | Respect incomplete local history. No percent-growth or consistency claim that assumes an observed full training history. No importer or date-editor expansion in this task. |
| [Alpha Progression official site](https://alphaprogression.com/en) — accessed 19 Oct; no publication date shown | Progress charts and PRs accompany weight/rep recommendations based on previous and current sets. Recommendations also support a user's own plan. | Keep measured performance next to the current accepted target, explicitly labelled. Unit retains post-workout acceptance and its existing deterministic engine; per-set recommendations, periodization and achievements stay out. |
| [Alpha Progression US App Store](https://apps.apple.com/us/app/alpha-progression-gym-tracker/id1462277793) — AmbassadorJoeM, 27 Mar 2024 | This reviewer likes adapting an offered plan but requests 1RM alongside 10RM. | Estimator labels matter. This is a historical review: the current official site now lists estimated 1RM and 10RM, so it does not establish a current competitor omission. |
| Same Apple page — Kaspen82, 4 Feb 2023 | Describes wanting help with intensity while choosing familiar exercises, after another app repeatedly changed recommendations. | Treat autonomy and understandable targets as a hypothesis consistent with Unit's approved direction, not a new market finding. |
| [Strong official records help](https://help.strongapp.io/article/216-exercise-records-screen) — last updated 25 Feb 2021, accessed 19 Oct 2026 | Separates real performances from theoretical records; excludes sets over 12 reps because extrapolated records inflate. | Label estimates and restrict Unit's existing Epley estimate to 1–12 reps. Derive the estimate from the strongest eligible set, not necessarily the heaviest set. Strong's dated help is documentation evidence, not a current installed-app audit. |

## Implementation choices

- Native third tab: Today / Programs / Profile. Existing chart icon represents its progress purpose; no new icon token is needed.
- Last 30 calendar days including today: finished workouts with valid working sets, working-set count, total reps. No whole-body tonnage or strength score.
- Exercise rows: latest heaviest working set (load, then reps), exact date and routine; comparison with the previous recorded session in that routine. Same load permits a rep delta; same reps permits a recorded-load delta. If both change, show the actual previous set without asserting improvement.
- Current accepted next targets are labelled separately and read from the existing routine state. Profile creates no recommendations and writes no targets.
- Existing charts show recorded load, maximum set reps, and recorded load × reps. Bodyweight volume is total reps, without an estimated body-mass load. Pure BW history omits the meaningless zero-load chart.
- One-session histories say that another session is needed for a trend. Missing workouts are never filled or extrapolated. Cross-routine charts remain descriptive history; within-routine comparisons are explicit.

## Reuse map

| Family / owner | Consumers and supported states | Disposition |
|---|---|---|
| `ContentView` / `RootTab`, native `TabView` and `Tab` | Today, Programs, new Profile; active-session tab hiding and shared arrival policy | Reuse current navigation owner; add one tab case, no visual variant |
| `AppScreen`, `AppSectionHeader` | Existing pages and Profile; scroll/safe area/heading rhythm | Reuse |
| `AppCardList`, `AppListRow(style: .cardListContent)`, `AppListRowValueLabel` | Existing Settings/program/history lists and Profile metrics/navigation | Reuse; card list owns row insets and minimum target size |
| `EmptyStateCard` | Existing empty screens and Profile with no completed working sets | Reuse |
| `ExerciseProgressView` / existing `SessionPoint` | History session cards, `SessionDetailView`, Profile and exercise library | Canonical chart/data owner; shared correction for valid sets, comparisons, units and estimated 1RM |
| `ExerciseDetailView` | `ExercisesListView` native destination | Retain live queries; delegate presentation to `ExerciseProgressView`. Remove parallel Brzycki/volume charts and unused summary type/import |
| `SetEntry.isValidCompletedWorkingSet` | Existing prefill plus shared progress and Profile | Reuse; finished-session guard stays at the session boundary |
| `WorkoutTargetFormatter` | Existing logging/progression/history and Profile | Reuse exact BW, load, target and kg/lb formatting |
| `AppFont`, `AppSpacing`, `AppColor`, `AppIcon.chart`, `AppMotion` consumers | Existing owners unchanged | Reuse native SF Pro, restrained tracking, shared Reduce Motion/VoiceOver behavior |

No new SwiftUI view types, design tokens, styles, or variants. No `DesignSystem.swift` edits. Native Picker consolidation belongs to the separate coordinating chat.

## Evidence boundary

Source guard and whitespace checks can run without the release queue. Focused analytics tests and an added Profile leg of the existing progression UI journey are prepared. Build, Simulator, phone, VoiceOver, and rendered Profile evidence remain pending until coordinated verification is available. Historical screenshots establish the visual anchor, not a render of these edits.
