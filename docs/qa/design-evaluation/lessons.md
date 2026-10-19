# Unit design evaluation lessons

This file is the on-demand memory for recurring design misses. It is not an
always-loaded brief. Per-screen details stay in dated scorecards under
`docs/qa/design-evaluation/scorecards/`.

## Carry-forward backlog

| First seen | Last seen | Screen(s) | Recurring miss or blind spot | Next action | Status |
|---|---|---|---|---|---|

## Promoted lessons

| Date | General rule | Promoted to | Evidence | Replaces |
|---|---|---|---|---|
| 2026-10-19 | Stateful swaps keep stable layers/identity and animate the changed opacity/style locally; ancestor animation is not visual proof | atomic-design-system.md: Logging crossfades | logging-instant-changes scorecard; repeated physical feedback on CTA/metric swaps | Parent-only transition assumptions |

## Maintenance

- Add only confirmed recurrences or evaluator blind spots.
- Merge overlapping entries.
- Remove entries enforced by a token, component, hook, or test.
- Review after five scorecards or before a release audit, whichever comes first.

