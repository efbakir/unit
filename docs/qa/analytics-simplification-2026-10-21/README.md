# Analytics and workout simplification

Implemented and integrated into `/Users/efbakir/unit`. No phone installation.
Reference research and the recovered historical brief are in
[`hevy-analytics-2026-10-20`](../../references/hevy-analytics-2026-10-20/README.md).

## Behavior

- Main lift cards show the latest set/date, a comparison only when supported,
  and a chart only with multiple weekly points. Best/Next remain in detail.
- Detail removes the empty one-point graph and repeated missing-baseline text.
  Real comparisons, history and accepted next targets remain.
- Long-press an exercise card and drop it on another to move it. The toolbar
  also opens a native reorder list with drag handles. Order belongs to the
  active session, survives reopening, and does not rewrite the saved routine.
- Rest buttons adjust by −20/+20 seconds. Default rest and the existing
  15-second minimum are unchanged.
- Navigation stacks own neutral tint. Tab selection and explicit primary
  buttons retain their accent. Native toolbar grouping keeps Finish visible
  alongside Reorder.

No new design tokens or SwiftUI components were introduced. Shared drag source,
drag preview, cards and native list controls are reused.

## Verification

All runs used an isolated UI-test store on Unit Logging Compact iOS18
(`C97961F0-3CDB-4360-9931-436DD95A51B7`). Light, portrait, 375pt width.

| Run | Result | Snapshot |
| --- | --- | --- |
| `/tmp/unit-simplify-ios18.xcresult` | 25 unit + 6 UI tests passed | Simplification/reorder/timer with build87 typography |
| `/tmp/unit-simplify-final.xcresult` | 4 UI tests passed | Added main's standard SF Pro, collapsed-card and bottom-spacing changes |
| `/tmp/unit-simplify-final-actions.xcresult` | 4 UI tests passed | Final navigation-stack tint and native Finish/Reorder grouping |

Across these runs, 25 distinct unit tests and 8 distinct UI cases passed.
Coverage includes timer restoration and ±20 adjustments, session-order
sanitization/isolation, direct card dragging, native-list reordering, reopening,
preserving logged sets/rest, finishing without rewriting the routine,
single-week Analytics, multi-week detail/metric navigation, missing lifts,
pounds, large text and Today/Programs navigation.

Static guards, UI banned-pattern checks and whitespace checks passed.
iOS27 attempts failed before tests because of Simulator boot timeout/server
failure; they are not passing evidence. Manual VoiceOver, physical Gym Test,
and iPhone appearance remain unverified.

Visual review caught two issues and they were repaired before handoff:
the inherited tab accent kept native back blue on iOS18; neutral tint needed
to live at the root navigation-stack level. Also, multiple buttons inside one
ToolbarItem hid Finish; ToolbarItemGroup fixes it and a UI assertion protects it.

`source-hashes.json` records the combined main source used for final review.
Main's unrelated edits were preserved. Do not cherry-pick baseline snapshot
commits `b0746a4` or `7614c03`; actual deltas are already applied to main.

## Screens to review

- [Simplified overview](analytics-overview.png)
- [Simplified exercise detail](analytics-detail.png)
- [Reordered workout, Finish and timer](workout-reordered.png)
- [Native reorder sheet](reorder-sheet.png)
- [Programs toolbar](programs.png)
- [Today CTA spacing](today-cta.png) — final app launched with the logging fixture
- [Large text](analytics-large-text.png) — captured before the final navigation
  tint patch; typography/layout are the same.
