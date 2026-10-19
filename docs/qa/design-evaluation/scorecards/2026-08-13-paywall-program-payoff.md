# Single-page trial paywall design scorecard

**Date**: 2026-08-13  
**Mode**: contextual  
**Status**: provisional  
**Evidence**: current SwiftUI implementation and pre-revision screenshots supplied by the user; no fresh render of the single-page revision  
**Anchor**: `docs/references/ios-screens/opal__trial-paywall.png` for keeping selected offer, connected timeline, zero-due context, and purchase action together. The user-supplied Headspace/Napper-style examples inform the optional reminder placement. Unit keeps its own light, flat visual language.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | Uses `AppScreen`, `AppCard`, `AppSelectableTierCard`, `AppTimeline`, `AppFeatureAccessTable`, native `Toggle`, and existing tokens. | Confirm the compact tier state has the same rhythm as the selected state in a fresh render. | Molecule | Code inspection cannot prove the expanded-to-compact transition looks balanced. |
| Product coherence and restraint | 20% | 7 | One StoreKit-backed decision surface, one sticky action, no separate Lifetime heading, and no duplicate checkout stage. | Measure whether four visible offers add decision friction; keep the selected plan visually dominant. | Screen | Conversion effects require production data. |
| Craft | 20% | 6 | Major sections use the established 32/48pt rhythm and the timeline remains left-scannable. | Inspect the full scroll length and sticky CTA overlap on compact devices. | Screen | No current single-page screenshot exists. |
| Gym Test and UX judgment | 25% | 7 | The purchase action is direct, reminder consent is optional, and StoreKit failure remains recoverable. | Confirm plan changes update headline, timeline, reminder, price context, and CTA without stale state. | Screen/state | Native StoreKit confirmation cannot be proven by static code alone. |
| Accessibility and verification | 10% | 6 | Native switch, non-colour tier selection, semantic labels, and 44pt-or-larger targets remain in code. | Exercise VoiceOver, compact iPhone, and Accessibility Medium before promotion. | Verification | Dynamic Type and announcement order are unverified visually. |

**Weighted baseline**: 6.7/10

## Hard gates

| Gate | Status | Evidence |
|---|---|---|
| UI banned-list hook | PASS | Changed production Swift files pass `.claude/hooks/ui-banned-list.sh`. |
| Targets are at least 44×44 pt | PASS | Tier cards, native switch, legal actions, Retry, and sticky CTA retain canonical minimums. |
| WCAG AA contrast | PASS | No new colour pairing; established Ink/Chalk, Ink/Bond, and Ash/Milk tokens remain. |
| Non-colour meaning and reduced motion | PASS | Tier selection uses checkmark, border, and accessibility value; switch exposes text state; existing reduced-motion tier animation remains. |
| Gym Test remains intact | PASS | Active logging code is untouched. |
| No misleading tappable affordance | PASS | Program and timeline remain read-only; tiers, switch, legal actions, Retry, and CTA are explicit controls. |
| Differing states render differently | UNVERIFIED | Compact/expanded tiers and reminder-off/on states need fresh visual evidence. |
| Light-only and portrait-only | PASS | The implementation stays inside Unit's existing light, portrait shell. |

## Priority fixes

1. Render eligible Monthly, Yearly, Weekly, reminder-on, product-failure, compact iPhone, and Accessibility Medium states before release.
2. Confirm the sticky purchase context keeps the full billed price readable while the long page scrolls.

## Opportunity pass

- Use the existing selected-card transition as the only plan-selection motion; add no paywall-specific celebration animation.
- Preserve the goal-aware final timeline reward as the quiet payoff after the billing milestone.

## Work completed

- Collapsed the two-page route into one StoreKit-backed `AppScreen`.
- Extended the canonical tier card so selected plans show full billing detail while unselected plans stay compact.
- Grouped Weekly, Monthly, Yearly, and configured Lifetime without `Or pay once`.
- Added a default-off native reminder switch and reactive Day 5 copy.
- Changed eligible trial CTAs to StoreKit-localized `Try for 0.00`; non-trial and Lifetime CTAs remain truthful.
- Connected reminder persistence and permission scheduling to verified introductory-trial purchases only.
- Retired split page-view analytics and added controlled reminder-preference and purchase-start events.

## Carry forward

- Visual verification is intentionally pending; simulator work was not requested in this turn.
- The generic iOS Simulator app build and test-target build both compile successfully.
- Run a blind review with current screenshots before treating this as an official score.
