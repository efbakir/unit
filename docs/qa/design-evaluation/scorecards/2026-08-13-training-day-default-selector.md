# Training-day default selector design scorecard

**Date**: 2026-08-13
**Mode**: contextual
**Status**: provisional
**Evidence**: supplied training-days screenshot and changed SwiftUI code; no post-change simulator render
**Anchor**: `OnboardingScheduleView` and its canonical `.weekday` `AppSegmentedControl`, used immediately after program selection.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | The page already uses `AppSegmentedControl` and design tokens. | It uses a taller dark-selected variant instead of the schedule selector's established `.weekday` treatment; reuse that configuration. | Screen composition | Post-change geometry is not rendered. |
| Product coherence and restraint | 20% | 7 | Only catalog-supported schedules are shown. | An empty initial state asks for a decision when three days is the common safe default; preselect three without skipping the question. | Screen state | Default preference has not been measured with users. |
| Craft | 20% | 6 | Labels are clear and evenly distributed. | The oversized dark pill carries more visual weight than the equivalent selector later in the flow; use the established light weekday treatment. | Screen composition | Compact-device spacing is unverified. |
| Gym Test and UX judgment | 25% | 7 | Five choices are visible in one control. | Disabled Continue creates an avoidable tap; seed three days and keep the CTA immediately available. | Screen state | Interaction was not exercised after the edit. |
| Accessibility and verification | 10% | 6 | Each segment has a full spoken label and the canonical control maintains 44pt targets. | Current screenshot predates the change; verify selected traits and CTA state in a later user-invoked visual pass. | Verification | Dynamic Type and VoiceOver were not rerun. |

**Weighted baseline**: 6.7/10

## Hard gates

| Gate | Status | Evidence |
|---|---|---|
| UI banned-list hook | PASS | Hook passes after the Swift changes. |
| Targets are at least 44×44 pt | PASS | `AppSegmentedControl.Size.weekday` preserves a 44pt interaction floor. |
| WCAG AA contrast | UNVERIFIED | Existing semantic control colors are retained; no rendered measurement was taken. |
| Non-color meaning and reduced motion | PASS | The selected segment has shape, foreground, and VoiceOver selected state; canonical motion behavior is unchanged. |
| Gym Test remains intact | PASS | The change is isolated to onboarding and reduces one required tap. |
| No misleading tappable affordance | PASS | Every visible segment is a button and Continue reflects the seeded valid value. |
| Differing states render differently | UNVERIFIED | No post-change screenshots were produced. |
| Light-only and portrait-only | PASS | No appearance or orientation code changed. |

## Priority fixes

1. Seed three days when the user reaches the day question, without skipping it.
2. Reuse the schedule page's `.weekday` segmented-control configuration.
3. Keep Continue enabled and require it to advance to results.

## Opportunity pass

- None. Reuse and a sensible default are preferable to more explanation or chrome.

## Work completed

- Added a three-day default only when the day question is entered with no saved answer.
- Preserved any previously selected schedule when navigating back or relaunching.
- Switched to the existing `.weekday` `AppSegmentedControl` treatment from `OnboardingScheduleView`.
- Raised that shared `.weekday` control to the 48pt spacing-grid token, improving both the training-day count selector and the later weekday assignment selector together.
- Updated the onboarding UI test to assert the default selection, enabled Continue state, and explicit continuation.

## Carry forward

- Edits applied, not visually verified. Review question three at standard and accessibility text sizes in the next scheduled simulator pass.
