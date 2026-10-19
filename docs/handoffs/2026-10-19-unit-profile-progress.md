# Unit Profile progress handoff

## Source and status

- Worktree: `/Users/efbakir/.codex/worktrees/bbd7/unit`.
- Branch: `codex/unit-profile-progress`, based exactly on `9643cb8567b082cf37ace5529b23a4b188737a06`.
- Edits applied, not yet runtime verified. Final commit is reported in the chat; no merge/cherry-pick into integration was performed.
- Release queue remains reserved by the main chat. No `xcodebuild`, Simulator boot/install/screenshot, phone operation, version/build-number edit, or store operation was run.
- No persistence schema/model mutation, migration, seed, training-store write or preference reset. No changes to `/Users/efbakir/unit` working files or Plate. Git necessarily writes shared worktree/branch metadata.

## Applied behavior

1. Native third `Tab` named Profile alongside Today and Programs, retaining the existing tab-arrival and active-workout hiding policies. Existing chart icon reused; no new icon token.
2. Last 30 calendar days, including today: finished workouts containing valid working sets, working-set count, total reps. Future-dated sessions are excluded from this summary. No bodyweight tonnage, incomplete-workout totals or imputed missing data.
3. All locally logged exercises, including archived catalog models, newest first: latest heaviest working set (load, then reps), exact date/routine, previous comparable session in that routine. Rep differences require equal recorded load; load differences require equal reps. Otherwise show the previous set without asserting improvement.
4. Current accepted next target for that same routine/exercise is shown separately when a valid target and working-set count exist. Profile never computes/accepts a new target. The Training log section links to existing History and Settings; both use their supported no-close-button configuration inside the native stack.
5. Exercise rows open existing `ExerciseProgressView`; History/session callers retain it. `ExerciseDetailView` now delegates to the same owner instead of maintaining separate Brzycki and raw-volume charts.

## Owners and file changes

| File / owner | Change |
|---|---|
| `Unit/ContentView.swift` | Existing root composition owns native third Tab and Profile content. Adds live exercise/template queries and weight-unit observation; reuses AppScreen, AppSectionHeader, AppCardList, AppListRow, EmptyStateCard, native navigation. No new view type. |
| `Unit/Features/History/ExerciseProgressView.swift` | Existing SessionPoint and chart owner now derive all exercise points through one helper using `SetEntry.isValidCompletedWorkingSet`. Keeps maximum reps separate from the heaviest set. Canonical exact-performance and same-routine comparison text. Explicit chart units, one-session limitation, all-routine history explanation, bodyweight total reps. Pure BW excludes zero-load Weight metric. Epley estimate is labelled and computed from the strongest eligible 1–12-rep set, not merely the heaviest set. |
| `Unit/Features/Templates/ExercisesListView.swift` | Existing ExerciseDetailView keeps live queries and delegates to canonical progress. Deletes unused ExerciseSessionSummary and parallel charts/Brzycki calculation. Removes unused Charts import. |
| `UnitTests/ProgressionPersistenceTests.swift` | Three focused contracts: valid finished-work filtering/actual totals; BW and conservative 1RM eligibility; same-routine comparable-set rules. Prepared, not executed. |
| `UnitUITests/ProgressionContractUITests.swift` | Adds Profile → accepted-target evidence → exercise chart → Today to the existing full progression journey. Prepared, not executed. |
| `docs/product-compass.md`, `docs/decision-log.md`, `docs/goals.md`, `docs/claude/scope.md` | Records the requested private Profile scope while retaining social-profile and hot-loop exclusions. |
| `docs/research/2026-10-19-profile-progress.md` | Bounded official-source/App Store research, dated reviews and caveats, recovered Unit decisions, owner/reuse map. |
| `docs/qa/design-evaluation/scorecards/2026-10-19-profile.md` | Contextual source-only provisional scorecard. Not an official visual grade. |

`DesignSystem.swift` is unchanged. No new components, design tokens, styles, visual variants or dependencies. No extension proposal is necessary for the applied scope. Existing metric choices are preserved: Weight / Reps / Volume, with Weight omitted for pure BW. The old library-specific estimated-1RM curve is replaced by canonical charts plus a clearly labelled estimate; no new chart metric is introduced.

## Source checks completed

- `scripts/check-guards.sh`: PASS for tracked Unit + UnitWidget sources.
- `.claude/hooks/ui-banned-list.sh`: PASS on the added application source in all three changed application files.
- `git diff --check`: PASS.
- `swiftc -frontend -parse` on all five changed Swift files: PASS. Syntax only; no SDK type checking, linking, app build or execution.
- Inspected the repository Hevy exercise-detail anchor image and current shared owner source. This is reference evidence, not a Profile render.

## Coordinator's next checks

1. Integrate sequentially with the separate shared native-control work. Profile intentionally leaves `AppSegmentedControl`, `AppCardList`, token and motion ownership unchanged. Resolve docs additively and retain the newest SF Pro/native-control decisions.
2. Build once after integration. Run `ProgressionPersistenceTests` (includes the three new analytics tests), then the existing full progression-contract journey with its added Profile branch.
3. Inspect Profile standard-size light/portrait on iOS 27, then iOS 18 compatibility. Verify the native three-tab strip, first viewport density, long exercise/routine labels, BW/weighted-BW, kg/lb, empty and one-session states. No enlarged-font layout redesign is part of this change.
4. Exercise Profile → History → session → chart; Profile → Settings → change units → back; exercise library → existing ExerciseDetailView → same canonical chart. Check native stack restoration after switching tabs.
5. Check actual VoiceOver row/metric announcements and Reduce Motion. Shared policies were reused; no runtime accessibility claim is made.
6. Keep all phone preservation/install and final version reservation with the main release coordinator. The physical phone's training data was not opened or modified by this chat.

## Research takeaways

Hevy documents Profile as an analytics/history hub and exercise records as inspectable evidence. An individual review's bodyweight-volume complaint supports clarifying units, not inventing body-mass data. Alpha Progression documents charts with explicit weight/rep guidance; Unit preserves its own post-workout acceptance boundary. Strong's dated official help separates real and estimated records and cautions about estimates above 12 reps. These are useful product patterns and review anecdotes, not a representative demand study. Source links/dates are in the research note.
