# Today up-next preview alignment design scorecard

**Date**: 2026-08-13
**Mode**: contextual
**Status**: provisional
**Evidence**: supplied Today-screen screenshot and current SwiftUI implementation; no post-change simulator render
**Anchor**: `docs/references/ios-screens/hevy__workout-tab.png` for keeping routine content and its action on deliberate, consistent internal edges. Unit retains its own nested recess and centered hero hierarchy.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | The screen uses `EmptyStateCard`, `PreviewListContainer`, `PreviewListRow`, shared typography, and spacing tokens. | The preview molecule uses 16pt horizontal padding but 8pt vertical padding inside a canonical recessed row; use `AppSpacing.sm` on both axes. | Organism | Other preview-list contexts are not rendered in the supplied evidence. |
| Product coherence and restraint | 20% | 8 | One routine, a short exercise preview, and one start action form a restrained Today state. | Preserve the existing composition and correct only the inconsistent inset. | Organism | Schedule-note states are not shown. |
| Craft | 20% | 6 | The card hierarchy and component family are coherent. | The exercise list's top and left internal gutters do not match; make both 8pt so the recess reads deliberately. | Organism | Optical alignment after Dynamic Type scaling is unverified. |
| Gym Test and UX judgment | 25% | 8 | The primary workout action remains obvious and the list is directly tappable. | Avoid changing content density, navigation, or CTA placement while fixing the alignment. | Organism | One-handed interaction was not exercised. |
| Accessibility and verification | 10% | 7 | Existing links, rows, and CTA retain their shared accessibility behavior and minimum targets. | Recheck wrapped exercise names after the inset change on compact and Accessibility layouts. | Verification | VoiceOver order and large-text geometry are unverified. |

**Weighted baseline**: 7.3/10

## Hard gates

| Gate | Status | Evidence |
|---|---|---|
| UI banned-list hook | PASS | The changed shared Swift file passes `.claude/hooks/ui-banned-list.sh`. |
| Targets are at least 44×44 pt | PASS | The shared preview row and primary button dimensions are unchanged. |
| WCAG AA contrast | PASS | Existing semantic text and surface colors are unchanged. |
| Non-color meaning and reduced motion | PASS | No state cue or motion changes. |
| Gym Test remains intact | PASS | Start-workout navigation and the active logging flow are untouched. |
| No misleading tappable affordance | PASS | Preview rows remain navigation links with established pressed feedback. |
| Differing states render differently | UNVERIFIED | No post-change state screenshots were produced. |
| Light-only and portrait-only | PASS | No appearance or orientation behavior changes. |

## Priority fixes

1. Match the preview list's horizontal and vertical internal padding.

## Opportunity pass

- None. This is an alignment correction, not a reason to add visual treatment.

## Work completed

- Changed the shared `PreviewListContainer` recess from 16pt horizontal / 8pt vertical padding to the canonical 8pt inset on both axes.
- Kept the card, row, CTA, scrolling, overflow, and navigation behavior unchanged.

## Carry forward

- Edits applied, not visually verified. Review the Today preview and the active-program preview at standard and Accessibility text sizes.
