# Nested onboarding question counter design scorecard

**Date**: 2026-08-13
**Mode**: contextual
**Status**: provisional
**Evidence**: supplied Step 2 and Step 3 screenshots plus changed SwiftUI code; no post-change simulator render
**Anchor**: the supplied Step 2 screen is the canonical Unit reference for counter-only onboarding progress. `docs/references/ios-screens/bevel__onboarding-fitness.png` confirms that secondary progress should stay compact, but its dot indicator is intentionally not borrowed.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | Shared shell, tokenized type, spacing, color, and the canonical progress component are used. | The nested linear bar introduces a visual pattern absent from Steps 1–2; remove it from the shared progress molecule. | Molecule | Post-change alignment is not rendered. |
| Product coherence and restraint | 20% | 6 | Outer and nested progress are both labeled clearly. | Two simultaneous progress systems over-explain one state; retain only the outer step and nested question counters. | Molecule | Results-stage hierarchy is inferred from code. |
| Craft | 20% | 6 | Counter alignment and mono numerics are consistent. | The bar creates an extra horizontal boundary and compresses the title block; remove the bar without adding replacement chrome. | Molecule | Dynamic Type wrapping is unverified. |
| Gym Test and UX judgment | 25% | 7 | Back navigation, current outer step, and question position remain recognizable. | The bar implies progress behavior that other onboarding steps do not teach; use `Q 01 / 03` through `Q 03 / 03` only. | Molecule | Interaction was not exercised after the edit. |
| Accessibility and verification | 10% | 6 | The shared component combines the outer step and question into one accessibility label and honors Reduce Motion. | Current visual evidence predates the fix; run a later user-invoked visual pass if needed. | Verification | Compact and accessibility text sizes are unverified. |

**Weighted baseline**: 6.6/10

## Hard gates

| Gate | Status | Evidence |
|---|---|---|
| UI banned-list hook | PASS | Hook passes after the Swift changes. |
| Targets are at least 44×44 pt | UNVERIFIED | The changed progress header is not interactive; surrounding controls were not re-measured. |
| WCAG AA contrast | UNVERIFIED | Existing semantic color tokens are retained; no rendered measurement was taken. |
| Non-color meaning and reduced motion | PASS | Progress is textual and existing animations use `accessibilityReduceMotion`. |
| Gym Test remains intact | PASS | The change is isolated to onboarding and does not touch active logging. |
| No misleading tappable affordance | PASS | The removed bar was read-only and no new affordance was added. |
| Differing states render differently | UNVERIFIED | No post-change state screenshots were produced. |
| Light-only and portrait-only | PASS | No appearance or orientation code changed. |

## Priority fixes

1. Remove the nested linear bar while preserving the trailing question counter.
2. Hide the nested detail on the results page because it is no longer a question.

## Opportunity pass

- None. The requested counter-only treatment is the most restrained conforming solution.

## Work completed

- Removed the nested `ProgressView` from the shared onboarding progress molecule.
- Kept `Q 01 / 03`, `Q 02 / 03`, and `Q 03 / 03` aligned at the top right.
- Removed `MATCH READY` from the results stage.
- Removed the now-unused `progressSegmentFill` design token and its documentation.

## Carry forward

- Edits applied, not visually verified. Review the three question states and results state in the next scheduled simulator pass.
