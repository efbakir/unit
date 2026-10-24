# Workout detail design scorecard

**Date**: 2026-10-24
**Mode**: contextual (the reviewer planned and built the Edit workout change)
**Status**: provisional
**Evidence**: code only (`Unit/Features/History/SessionDetailView.swift`, `SessionExerciseSummary` in `HistoryView.swift`). No render: simulator runs are user-invoked (CLAUDE.md §6).
**Anchor**: Programs > Edit program in this app (pencil in `ProgramDetailView.swift`, trash, checkmark and confirm in `TemplatesView.swift`); `docs/references/ios-screens/neuecast__context-menu.png` for native menu rows. Borrowed: entry point, destructive placement, one menu per row.

## Baseline (before Edit workout)

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | `AppScreen`, `AppCardList`, `AppSectionHeader`, `AppSheetScreen`, shared disclosure | `.bold(emphasized)` in feature code (`SessionDetailView.swift`, evidence line) breaks the "no `.bold()` in feature code" rule. Move emphasis into an `AppFont` role | Atom | Not rendered; token drift inside shared rows unseen |
| Product coherence and restraint | 20% | 7 | Numbers first; "Next time" leads right after Finish | History mixes the workout record and the decision block with no edit path | Screen | Long sessions untested |
| Craft | 20% | 6 | Uniform sets collapse to one line; varied sets list per set | Code-only cap (7); no evidence of long names or large type | Screen | Dynamic Type at XXXL |
| Gym Test and UX judgment | 25% | 6 | Off the hot path; read-only review is fast | No recovery from a wrong set: a typo stays in PRs, charts and "Next" for good | Screen (Edit workout) | Real user error rates unknown |
| Accessibility and verification | 10% | 6 | Hints on rows, 44 pt edit target in the next-target block | Nothing rendered or exercised | n/a | VoiceOver order |

**Weighted baseline**: 6.5/10

## Hard gates

| Gate | PASS / FAIL / UNVERIFIED | Evidence |
|---|---|---|
| Banned-list hook passes | PASS | Hook ran on every Swift edit in this change |
| 44×44 pt targets | UNVERIFIED | Set rows in Edit workout set `minHeight: 44` in code; not measured |
| WCAG AA contrast | UNVERIFIED | Tokens only; not measured |
| No colour-only meaning; reduced motion | PASS (code) | PR tag has a label; no new motion |
| Hot logging path passes the Gym Test | PASS (code) | Nothing changed in active logging |
| No dead or misleading affordance | PASS (code) | Export shows "No workouts yet" instead of a dead row; edit rows carry a pencil glyph |
| States that should differ render differently | UNVERIFIED | Not rendered |
| Light-only, portrait-only | PASS (code) | No appearance or orientation code |

## Priority fixes

1. Recovery from a wrong set: Edit workout (pencil, per-set menu, delete with confirm). Done in this change.
2. `.bold(emphasized)` in the "Next time" evidence line: route through an `AppFont` role. Left to the consistency-audit chat (shared file with the progression-loop chat).

## Opportunity pass

- Show the corrected value briefly in the set row after "Save changes" (existing toast or a transient tag), so the edit reads as done without leaving the screen.

## Work completed

- Edit workout screen, Edit set sheet, delete set with Undo, delete workout with confirm, pencil entry on the detail and the post-Finish summary.
- Read-only mode for lapsed subscribers: no pencil, no "Next time" actions, no writes on open.

## Carry forward

- Visual pass on a phone or simulator: edit rows, sheet height with the keyboard up, toolbar trash and checkmark. Owner: founder.
- Set numbers keep gaps after a deleted set ("Set 1", "Set 3"). Owner: History, low priority.
