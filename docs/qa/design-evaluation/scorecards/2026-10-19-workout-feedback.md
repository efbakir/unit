# Workout feedback design scorecard

**Date**: 2026-10-19
**Mode**: contextual
**Status**: provisional
**Evidence**: user workout screenshot, source inspection; no new runtime visual pass requested.
**Anchor**: Grok conversation/private-chat captures in `docs/references/ios-screens/grok/`.

## Baseline
| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | Shared tokens/owners | Remove redundant timer outlines using existing fill | Molecule | Other parents not rendered |
| Coherence/restraint | 20% | 7 | Single black CTA | Quiet secondary timer surfaces | Molecule | Whole-app visual coverage |
| Craft | 20% | 6 | Screenshot/source | Last-time value uses disabled colour despite being valid context | Organism | Current device rendering |
| Gym Test | 25% | 7 | Save-before-signal path | Show brief visible saved acknowledgment without delaying next action | Molecule/organism | Physical interaction timing |
| Accessibility/verification | 10% | 6 | Existing touch geometry, motion gate | Keep fades under Reduce Motion/VoiceOver | Molecule | Runtime VoiceOver |

**Weighted baseline**: 6.7/10. No post-change score claimed.

## Hard gates
| Gate | Status | Evidence |
|---|---|---|
| Banned source patterns | PASS | Static source guards |
| 44pt targets | PASS | Existing geometry unchanged |
| Text contrast | UNVERIFIED | Existing secondary token reused; no fresh rendered measurement |
| Non-colour meaning/reduced motion | UNVERIFIED | Checkmark plus accessibility value; source-gated scale, runtime pending |
| Gym Test | UNVERIFIED | No inserted interaction delay; runtime pending |
| Dead affordances | UNVERIFIED | Completed confirmation does not accept another log; runtime pending |
| Distinct state rendering | UNVERIFIED | Runtime visual pass deferred by user |
| Light/portrait | PASS | Existing shell unchanged |

## Work completed
- Extend existing AppPrimaryButton with `isConfirmed`; original text retains layout while checkmark appears. Existing motion tokens, SF Symbol and haptic owner reused.
- WorkoutCommandCard starts a cancellation-safe one-second acknowledgment only on saved-set signal; final planned set also displays it. Reappearance does not start an acknowledgment. Next eligible set remains immediately tappable.
- RestTimerControl uses existing cardRowFill without duplicate outlines in both workout and SessionStateBar parents.
- Existing Last-time text uses textSecondary rather than textDisabled. No sizes, spacing, typography, palette values or radii changed.

## Carry forward
- Visually review the saved checkmark and timer on the phone. No new tests or Simulator runs, per user instruction.
