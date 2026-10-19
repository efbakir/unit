# Program recommendation disclosure design scorecard

**Date**: 2026-08-13
**Mode**: contextual
**Status**: provisional
**Evidence**: supplied results screenshot and changed SwiftUI code; no post-change simulator render
**Anchor**: `docs/references/ios-screens/hevy__explore-programs.png` — three visible programs followed by one explicit show-all action.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | The results use canonical option cards, filter chips, tokens, and sticky CTA behavior. | The screen silently truncates the ranked catalog at three; expose remaining schedule matches with the existing quiet action primitive. | Screen composition | Post-change geometry is not rendered. |
| Product coherence and restraint | 20% | 7 | Three recommendations form a clear shortlist and the first is identified as the best match. | The included catalog feels smaller than it is; keep three visible and disclose the rest rather than showing every card immediately. | Screen composition | Catalog breadth is still intentionally limited. |
| Craft | 20% | 7 | Cards have consistent hierarchy, wrapping, and selected state. | There is no end-of-shortlist affordance explaining whether more choices exist; add a centered show-all action beneath card three. | Screen composition | Expanded-state rhythm is unverified. |
| Gym Test and UX judgment | 25% | 7 | Users can select and continue without entering another page. | People who dislike the top three have no recovery path; add one-tap expansion while keeping training days as a hard constraint. | Screen state | Interaction was not exercised after the edit. |
| Accessibility and verification | 10% | 6 | Existing cards and quiet buttons preserve 44pt targets and spoken labels. | The expanded and collapsed states have not been rendered or exercised with VoiceOver; verify in a later user-invoked pass. | Verification | Dynamic Type and VoiceOver remain unverified. |

**Weighted baseline**: 6.9/10

## Hard gates

| Gate | Status | Evidence |
|---|---|---|
| UI banned-list hook | PASS | Hook passes after the Swift changes. |
| Targets are at least 44×44 pt | PASS | `AppGhostButton` and `AppOptionTileCard` retain canonical touch targets. |
| WCAG AA contrast | UNVERIFIED | Existing semantic colors are retained; no rendered measurement was taken. |
| Non-color meaning and reduced motion | PASS | Disclosure uses text and no new animation; selection retains shape, checkmark, and accessibility state. |
| Gym Test remains intact | PASS | The change is isolated to onboarding. |
| No misleading tappable affordance | PASS | The show-all label accurately reports the total matching-program count. |
| Differing states render differently | UNVERIFIED | No post-change screenshots were produced. |
| Light-only and portrait-only | PASS | No appearance or orientation code changed. |

## Priority fixes

1. Preserve the three-program shortlist.
2. Expose additional schedule-compatible matches with one quiet disclosure action.
3. Keep rank, selection analytics, and filter-reset behavior correct in the expanded state.

## Opportunity pass

- None. A single disclosure is preferable to a new catalog page inside onboarding.

## Work completed

- Requested the full ranked set from the existing local catalog while preserving the three-program default shortlist.
- Added `Show all N matching programs` and `Show top 3` using `AppGhostButton`.
- Kept training days as a hard filter and preserved the real rank for analytics.
- Reset expansion when answers change and clear a hidden selection when collapsing.
- Added a unit test proving the default three and full four-day result sets share the same order.

## Carry forward

- Edits applied, not visually verified. Review collapsed, expanded, selected-extra, and filter-changed states in the next user-invoked simulator pass.
