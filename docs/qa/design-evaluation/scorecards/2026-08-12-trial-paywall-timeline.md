# Trial paywall timeline design scorecard

**Date**: 2026-08-12
**Mode**: contextual
**Status**: superseded on 2026-08-13 by the [single-page trial paywall scorecard](2026-08-13-paywall-program-payoff.md)
**Evidence**: existing iPhone SE paywall render at `docs/qa/trial-paywall/final-verified-20260804/AA43DDC5-EC79-4DD5-BE31-88F7B73EC405.png`, current SwiftUI implementation, and five local benchmark paywalls in `/Users/efbakir/Desktop/Projects/unit/benchmark/paywalls`
**Anchor**: Headspace and Vocabulary for an on-page, price-adjacent trial timeline; Opal for keeping plan selection and timeline in one purchase surface. Unit borrows the information hierarchy and connected milestones, not their color, illustration, urgency, or reminder claims.

## Baseline

| Dimension | Weight | Score | Evidence | Top defect + exact fix | Fix layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 8 | The page uses `AppScreen`, `AppCard`, `AppSelectableTierCard`, `AppFeatureAccessTable`, StoreKit-derived prices, and tokenized typography/spacing. | The renewal timeline is hidden in a sheet and has no connected progress treatment; add one canonical timeline organism in `DesignSystem.swift`. | Organism | The inaccessible user screenshot could not be compared with the stored QA render. |
| Product coherence and restraint | 20% | 7 | Program context, honest eligibility handling, and one sticky purchase action fit Unit's trust posture. | Keep tiers on the same page and place selected-plan timing beside the decision instead of adding another navigation step. | Screen | Conversion impact needs post-launch data. |
| Craft | 20% | 6 | The current page is clean and typographically coherent. | Promote the timeline from a text trigger to a visible three-stage rail; keep it monochrome and flat. | Organism/screen | No post-change render exists yet. |
| Gym Test and UX judgment | 25% | 6 | Price repeats at the CTA and selection is reversible. | Show Day 0, the cancellation window, and renewal day before purchase; update the final milestone when the tier changes. | Screen | Scroll depth on the smallest device needs a visual pass. |
| Accessibility and verification | 10% | 7 | Existing controls meet touch-target rules and use Dynamic Type-aware primitives. | Combine each timeline milestone for VoiceOver and verify large-text rail alignment after implementation. | Organism/verification | VoiceOver order and Accessibility sizes are unverified for the new pattern. |

**Weighted baseline**: 6.8/10

## Hard gates

| Gate | PASS / FAIL / UNVERIFIED | Evidence |
|---|---|---|
| UI banned-list | PASS | Changed production Swift files pass `.claude/hooks/ui-banned-list.sh`. |
| Interactive targets ≥ 44 × 44 pt | PASS | Timeline is read-only; existing tier and CTA components retain canonical targets. |
| WCAG AA contrast | PASS | Existing Unit text and surface tokens are unchanged. |
| Non-colour meaning and reduced motion | PASS | Milestones use text and SF Symbols; no new motion is planned. |
| Gym Test | PASS | The active workout flow is untouched. |
| No dead or misleading affordance | PASS | The current sheet trigger works, though the key information is too hidden. |
| Distinct states are not byte-identical | UNVERIFIED | Trial, recurring, and lifetime timeline states require a future visual pass. |
| Light-only and portrait-only | PASS | The existing application constraints remain unchanged. |

## Priority fixes

1. Put the selected plan's timeline directly on the paywall with a connected vertical rail.
2. Never promise a trial-ending reminder until Unit actually provides one.
3. Keep tier selection on the same page and repeat the exact selected StoreKit price at renewal.

## Opportunity pass

- Move the feature matrix below plan choice and renewal clarity if the first viewport remains too proof-heavy on compact devices.

## Work completed

- Reduced the paywall hero from `largeTitle` / `body` to the existing `title` / `muted` pairing and tightened its internal gap from 8pt to 4pt, reclaiming vertical space without changing copy or the global type scale.
- Reworked the page rhythm with 24pt between the hero and program proof, 32pt between distinct purchase sections, and tight 0–12pt grouping inside each section. The 44pt `Change` target now supplies the plan header's internal breathing room instead of receiving another visual gap beneath it.
- Removed the trial-reminder toggle, notification permission request, and local scheduling path. The timeline now says `Before Day 7` and explains cancellation in App Store settings without adding a second decision before purchase.
- Added the shared `AppTimeline` organism using existing `AppCard`, `AppIconCircle`, typography, color, and spacing atoms.
- Replaced the hidden renewal sheet with an on-page timeline that follows the selected Monthly, Yearly, Weekly, or Lifetime tier.
- Eligible offers show `Day 0`, the cancel-before-renewal window, and the actual StoreKit renewal day and price.
- Kept plan selection on the same page and moved the secondary feature matrix below plan choice and timing clarity.
- Added structured day-count coverage and an eligible-paywall UI assertion for `Day 0` / `Day 7`.
- The original timeline implementation passed Swift parsing and a compile-only iOS Simulator build. This spacing/reminder follow-up passes the UI banned-pattern hook, Impeccable layout scan, and diff checks; local recompilation is unavailable because this machine currently exposes Command Line Tools without an Xcode developer directory.

## Carry forward

- Run the user-invoked visual verification pass on compact and Accessibility Medium layouts after the edit.
