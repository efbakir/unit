# Analytics insights (2.2): contextual baseline

**Date**: 2026-10-24
**Mode**: contextual (the reviewer also built the change)
**Status**: provisional
**Evidence**: code only for the baseline, on `6458790` plus PR #5. UI test captures listed under Work completed.
**Anchor**: `docs/references/ios-screens/hevy__set-count-stats.png` for the muscle list (muscle name leading, set count trailing, most-trained first). Borrowed: the list structure only. Not borrowed: Hevy's chart, checkboxes and half sets for secondary muscles.

## Baseline
| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 8 | Tokens and shared parts throughout (`AppStatusSummaryCard`, `AppMainLiftCard`, `AppCardList`, `AppListRow`) | "Other exercises" rows hand-build their trailing value instead of `AppListRow(value:)` | Molecule (consistency chat owns it) | Font/tracking chains not rendered |
| Product coherence and restraint | 20% | 7 | Verdict first, main lifts, plain list; no score or coaching | Exercise page says "Full Body" under pasted lifts: wrong data shown as fact | Data (read-time muscle lookup) | Real user exercise names not sampled |
| Craft | 20% | 6 | Clear labels, monospaced numbers, latest/comparison split | Same wrong "Full Body" metadata line | Data | Not rendered |
| Gym Test and UX judgment | 25% | 7 | Analytics is off the logging path; every tappable row navigates | None found in scope | - | Interaction not exercised |
| Accessibility and verification | 10% | 6 | Combined labels, chart descriptors, hints | Long lists at AX sizes unverified | Screen | No VoiceOver pass |

**Weighted baseline**: 7.0/10. Unchanged by later work.

## Hard gates
| Gate | Status | Evidence |
|---|---|---|
| Banned-list hook / source guards | PASS | `scripts/check-guards.sh` passed after the change |
| 44×44 pt targets | UNVERIFIED | New muscle rows are read-only; the Health switch is a native `Toggle` |
| WCAG AA contrast | UNVERIFIED | Existing semantic colors only |
| No color-only meaning; reduced motion | PASS | Counts are text; no new motion |
| Gym Test on the logging path | PASS | Finish adds one background call, no new tap |
| No dead or misleading affordance | PASS | Muscle rows have no press effect or chevron |
| Distinct states render differently | PASS | UI test captures: switch on when allowed; switch off plus the message when denied |
| Light-only, portrait-only | PASS | No appearance or orientation code |

## Priority fixes
1. Stop showing "Full Body" for exercises whose muscle is unknown (data layer, read-only).
2. Add sets per muscle with existing list parts.

## Opportunity pass
- Show the previous 4 weeks next to each muscle count once users ask for it. Not in scope.

## Work completed
- Muscle lookup from the exercise library (`ExerciseCatalog.muscleGroup(forName:aliases:saved:)`), read-only. Unknown muscles show nothing instead of "Full Body".
- "Sets per muscle · last 4 weeks" list between Main lifts and Other exercises.
- "Save to Apple Health" switch in Settings > Preferences.
- Captures from the 2026-10-24 UI run (iOS 27 simulator): `analytics-sets-per-muscle`, `settings-apple-health-on`, `settings-apple-health-denied`.
- Seen in the capture: muscle counts use the standard 17pt value; Other exercises rows still use their smaller hand-made value until the consistency branch lands.
- The denied message now stays until dismissed (2 seconds was too short to read).

## Carry forward
- "Other exercises" trailing value moves to `AppListRow(value:)` on the consistency branch; recheck the two lists side by side after that merge.
- Visual pass on a phone: Efe.
