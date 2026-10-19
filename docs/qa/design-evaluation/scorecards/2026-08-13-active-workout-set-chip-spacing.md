# Active workout set-chip spacing design scorecard

**Date**: 2026-08-13
**Mode**: contextual
**Status**: provisional
**Evidence**: User screenshot `codex-clipboard-c257226a-4d58-4696-8c76-d9ec53fab5b3.png` and code inspection
**Anchor**: `docs/references/ios-screens/hevy__active-workout.png`; borrow compact, scan-friendly set data while retaining Unit's capsule treatment

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 9 | Shared `SetProgressIndicator`, token fonts, fills, spacing, and motion | No system drift found | Molecule | Other workout states were not rendered |
| Product coherence and restraint | 20% | 9 | The strip keeps completed sets compact and the current set dominant | No structural change needed | Molecule | Long programs may create a different density |
| Craft | 20% | 6 | Screenshot shows readable chips, but full-width mono spaces make `32 lb × 10` look fragmented | Use narrow no-break spacing inside weight-unit pairs and thin spacing around `×` | Molecule | Dynamic Type widths were not rendered |
| Gym Test and UX judgment | 25% | 8 | Completed evidence remains glanceable and tappable without adding actions | Tighten the label without reducing the 44pt edit target | Molecule | Tap-edit was not exercised in this pass |
| Accessibility and verification | 10% | 6 | State uses icon plus fill and interactive chips retain a 44pt frame | Keep the readable string and rerun visual/accessibility states when requested | Molecule | VoiceOver and accessibility sizes were not exercised |

**Weighted baseline**: 7.9/10

## Hard gates

| Gate | PASS / FAIL / UNVERIFIED | Evidence |
|---|---|---|
| Banned-list hook | PASS | Changed shared code uses existing typography and layout primitives |
| 44pt interactive targets | PASS | Logged-set buttons retain `minHeight: 44` |
| WCAG AA contrast | PASS | Existing `textSecondary` on `controlBackground` pairing is unchanged |
| Non-colour cues and reduced motion | PASS | Completion retains a checkmark; existing motion reads `accessibilityReduceMotion` |
| Gym Test | UNVERIFIED | No interaction run was requested |
| No dead affordances | PASS | Only completed or failed chips with handlers become buttons |
| Distinct states differ | UNVERIFIED | State renders were not compared |
| Light-only and portrait-only | PASS | The molecule introduces no appearance or orientation branch |

## Priority fixes

1. Tighten the full-width monospaced spaces inside completed-set chip labels.

## Opportunity pass

- None. The requested spacing correction is enough.

## Work completed

- Replaced the normal weight-unit space with a narrow no-break space.
- Replaced normal spaces around the multiplication sign with thin spaces.
- Preserved chip padding, touch target, type token, and accessibility label content.

## Carry forward

- Visual and Dynamic Type checks remain pending until simulator verification is requested.
