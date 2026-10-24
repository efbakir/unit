# Active workout design scorecard

**Date**: 2026-10-24
**Mode**: contextual (the same session planned and built the 2026-10-24 logging changes)
**Status**: provisional
**Evidence**: code only, at `6458790` before the changes. No render; simulator runs were not part of this review (`CLAUDE.md` §6).
**Anchor**: `docs/references/ios-screens/hevy__active-workout.png`. Borrowed: per-exercise note under the name, rest that belongs to the exercise, actions in the exercise "..." menu. Not borrowed on purpose: the always-visible "Add notes here..." placeholder, the PREVIOUS column, the always-visible "Rest Timer" link.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | AppScreen, AppCard, AppPrimaryButton, tokens; Final B parts live in `DesignSystem.swift` | `ExerciseLoggingCard` hard-coded "Bodyweight", "Skip exercise", menu label "Edit": use `AppCopy` | molecule | dead `WorkoutCommandCard` family may hide more drift |
| Product coherence and restraint | 20% | 7 | One expanded current row, one CTA, quiet cards | In-workout PR moment missing since Final B: restore the History tag on logged sets | molecule | PR rule quirk on first-ever ramp sets |
| Craft | 20% | 6 | Concentric radii hold (card 22, inset 8, row 14); stable Undo slot | Card menu reads "Edit" to VoiceOver: name it "Exercise options" | molecule | no render to check tag fit at large text |
| Gym Test and UX judgment | 25% | 6 | One tap per prefilled set, 400 ms guard, inline Undo | "Skip exercise" on the last unfinished exercise does nothing: close the card, show Finish | screen + pure state | Lock Screen path not exercised |
| Accessibility and verification | 10% | 5 | 44 pt menu, Undo and rows; Reduce Motion gates | Nothing rendered or exercised in this pass | - | VoiceOver order of the new tag |

**Weighted baseline**: 6.4/10

## Hard gates

| Gate | PASS / FAIL / UNVERIFIED | Evidence |
|---|---|---|
| 1 Banned-list hook | UNVERIFIED | runs on edits; checked on the diff before each commit |
| 2 44×44 pt targets | UNVERIFIED | code: menu 44×44, Undo 44, rows 48 |
| 3 WCAG AA contrast | UNVERIFIED | tokens only |
| 4 No colour-only meaning, reduced motion | PASS (code) | PR is a text tag; done is a glyph; AppMotion gates |
| 5 Gym Test | UNVERIFIED | no device run |
| 6 No dead affordance | FAIL | Skip on the last unfinished exercise (fixed in PR A) |
| 7 States not byte-identical | UNVERIFIED | idle rest bar can read as paused (flow doc, Low) |
| 8 Light-only, portrait-only | PASS (code) | no dark or landscape code |

## Priority fixes

1. Skip on the last unfinished exercise (screen + `WorkoutLoggingState`).
2. PR tag on logged sets and done cards (`LoggedSetRow`, `ExerciseSummaryRow`).
3. Menu copy and VoiceOver name (`ExerciseLoggingCard`).

## Opportunity pass

- The idle rest bar can show the current exercise's own rest length (comes with rest per exercise).
- The Lock Screen can carry the next set's numbers, so the phone stays locked between sets.

## Work completed

- PR A: skip fix, PR tag, next-set line on Lock Screen and alert, card menu (Exercise history, note, Remove added set), menu VoiceOver name. Edits applied; visual pass pending.

## Carry forward

- Dead `WorkoutCommandCard`, `SetProgressIndicator`, `RestTimerControl`, `SessionStateBar` still in `DesignSystem.swift` and `docs/atomic-design-system.md` (consistency-audit chat).
- Visual check of the PR tag next to long values at large Dynamic Type (founder, on device).
