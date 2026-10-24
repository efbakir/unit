# Unit — pricing

> Authoritative reference for Unit's subscription tiers. Any change to price or product IDs lives here first, code second.

## Tiers

| Tier     | Price       | Billing       | Product ID         | Notes                                                   |
| -------- | ----------- | ------------- | ------------------ | ------------------------------------------------------- |
| Weekly   | **$2.99**   | auto-renewing | `com.unit.weekly`  | No trial. Preselected for customers without a trial. |
| Monthly  | **$4.99**   | auto-renewing | `com.unit.monthly` | Seven-day introductory trial. |
| Yearly   | **$29.99**  | auto-renewing | `com.unit.annual`  | Seven-day introductory trial; preselected when eligible; "Save 80%" vs 52 weeks of Weekly. |
| Lifetime | **$44.99**  | one-time      | `com.unit.lifetime` | No trial. Optional non-consumable; show only if configured in ASC and returned by StoreKit. |

Version 2.1 supports a seven-day Free introductory offer on Monthly and Yearly. Unit shows trial language only when the selected product is an auto-renewable subscription, StoreKit returns a valid free-trial offer, and Apple reports the customer eligible. Eligibility alone never creates trial copy. Weekly and Lifetime never carry a trial. Lifetime is not a fallback price: it appears only when `Product.products(for:)` returns `com.unit.lifetime`.

The local `Unit.storekit` configuration contains the two seven-day offers for deterministic QA. App Store Connect must still be configured and sandbox-verified by the founder before the trial is release-ready.

## Math

- Weekly × 52 = $155.48/yr — the flexibility premium over Monthly, priced as commitment, not trickery
- Monthly × 12 = $59.88/yr
- Yearly vs monthly-equivalent = $29.99 / $59.88 → roughly 50% lower yearly total
- Lifetime equals about 1.5× the Yearly price and appears only if ASC has the non-consumable configured
- Ladder coherence rule (2026-07-02): every tier must have a role — Weekly = cheapest quick try, Monthly = normal, Yearly = best value, Lifetime = one-time. **No tier may strictly dominate another at the same visible price**; the 2026-06-29 $4.99/$4.99 weekly-monthly tie violated this and was corrected before v2 submission (see decision log).

## Rationale

- **Hard paywall** (resolved 2026-06-16, see `docs/decision-log.md`). All app functionality is gated behind a paid purchase. Onboarding completes free so the user sees their program built; the paywall appears immediately after setup is saved, no dismissal.
- **Seven-day introductory trial, not a free tier.** Eligible new customers may try all of Unit through Monthly or Yearly. After the offer, the selected subscription renews at its displayed StoreKit price unless cancelled. Ineligible customers see no trial claims. The hard paywall remains and there is no permanent free access.
- **Yearly is the default for trial-eligible customers, Weekly for everyone else** (founder decision 2026-10-23). Once the customer chooses a plan, later asynchronous eligibility results must not replace that choice.
- **Default-plan test, built but off.** `PaywallDefaultPlanExperiment.isRunning` switches on a sticky 50/50 Yearly-vs-Monthly default for trial-eligible installs. Off by founder decision; when off, trial-eligible customers get Yearly.
- **Reading the default-plan test.** TelemetryDeck: filter `trial_eligibility = eligible`, split by `default_plan`, compare `trial_started ÷ paywall_viewed` and the plan mix of `purchase_completed`; check App Store Connect for trial-to-paid conversion. After about 300 eligible paywall views per arm, keep the arm with more revenue per paywall view and log the result in `docs/decision-log.md`.
- **Timing stays with the decision.** One scrolling paywall keeps the personalized program payoff, grouped plans, StoreKit-derived Today → Day 5 → Day 7 timeline with the real dates in its text, included features, renewal disclosure, Restore, Terms, Privacy, and sticky purchase action together. The selected plan expands; unselected plans remain compact. Configured Lifetime stays in the same group without a separate heading.
- **The reminder defaults on and stays optional.** `Remind me 2 days before` starts on (2026-10-23) and appears only for a selected, eligible introductory trial. Toggling it never asks for permission; permission is requested only after a verified trial purchase, and denial never blocks access.
- **The CTA mirrors the selected StoreKit offer.** Eligible trials show `Start free trial` with the billed price leading the line above it (no `$0.00`, 2026-10-23); non-trial subscriptions show `Subscribe for [full billed price]`; Lifetime shows `Buy for [price]`.
- **All subscription plans stay visible.** Weekly, Monthly, and Yearly cards render even while StoreKit is loading. Missing products show loading/unavailable copy, never fake prices.
- **Lifetime is optional.** If the existing non-consumable is configured and StoreKit returns it, Unit shows it as a one-time purchase. If ASC does not return it, the card is hidden.

## What is behind the paywall

Everything. Hard paywall = full app gated.

The onboarding flow (opener → path choice → paste or ready-made program → review) runs free so the user sees their program before being asked to pay. A line under the setup button says a paid plan is required after setup. Once onboarding saves the program, the paywall appears before the user can use the main app.

**Free pre-paywall surfaces:**
- All onboarding steps (path choice, program entry or matching, review)
- The post-onboarding "your program is ready" hand-off

**Paid post-paywall surfaces:**
- Today tab (start workout, log sets, rest timer)
- Programs tab (view / edit / reorder templates)
- Analytics tab and History (sessions, PRs, lift progress, edit and delete past workouts)
- Settings (manage subscription, weight unit, analytics opt-out, export workouts, feedback)

**After a subscription ends (founder decision 2026-10-24):**
- The paywall shows "View workout history" when the phone has logged sets. History opens read-only (list, workout detail, exercise pages) with "Export". Nothing starts, saves or changes.
- Everything else stays behind the paywall. New installs never see the link.

## App Review metadata checklist

Apple's subscription review surface is not just the in-app paywall. Before every subscription submission:

1. Paste the Terms of Use (EULA) URL into the visible App Store description text: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`.
2. Keep the Privacy Policy URL in App Store Connect's dedicated Privacy Policy field: `https://unitlift.app/privacy`.
3. Keep the paywall footer and Settings legal section using full labels: `Terms of Service` and `Privacy Policy`.
4. If Apple repeats a boilerplate 3.1.2 rejection after the metadata is fixed, reply in Resolution Center with screenshots and a screen recording proving the current description and in-app legal links are visible.

## StoreKit sandbox verification checklist

Run this on the exact archive/build submitted for review, using products attached to the App Store Connect version and a sandbox Apple ID:

1. Use a fresh sandbox customer who has never redeemed an introductory offer in Unit's subscription group. Fresh install → complete onboarding → confirm the app lands on `PaywallView`, not `TodayView`.
2. Confirm eligible Yearly is selected by default and the same paywall shows all available plans, a timeline of Today, Day 5 and Day 7 with the real dates in its text, the reminder switch defaulted on, full renewal context, and `Start free trial` in the US storefront. Monthly and Yearly each show Apple's seven-day free period; Weekly and Lifetime show no trial or reminder language.
3. Start the Monthly trial, cancel the Apple purchase sheet, and confirm the user remains on `PaywallView`.
4. Turn on the reminder, complete the Monthly trial purchase, and confirm the app immediately enters Today before notification permission is resolved. Accept permission and confirm one `unit.trial-reminder` request is scheduled two days before expiration. Repeat with the reminder off and confirm no permission prompt or pending reminder. Relaunch offline and confirm the last verified entitlement still unlocks the app without another permission prompt.
5. Delete and reinstall the app, tap `Restore Purchases`, and confirm entitlement restores access to the main tab UI.
6. Test an ineligible sandbox customer: Weekly is selected by default, no trial text appears anywhere, and a normal subscription purchase unlocks Today.
7. Cancel the sandbox subscription from App Store subscription management, relaunch after StoreKit reflects the cancellation, and confirm inactive entitlement returns to `PaywallView`.

Apple permits one introductory-offer redemption per customer per subscription group. Do not expect the same sandbox customer to redeem both the Monthly and Yearly trials.

## Win-back

- **Win-back**: $19.99/yr Apple promotional offer (about ⅔ of Yearly), triggered after subscription cancel. Wire via StoreKit 2.
- **Restore purchases**: standard Apple flow; user signed in with same Apple ID auto-restores entitlement (Required by App Store).

## Distribution

> Pricing is one of two levers that close the paid-acquisition math. The other is LTV. This section codifies how to think about both.

**Target**: $11k MRR ≈ $132k ARR (locked 2026-06-17). At current Yearly price $29.99, that is roughly 4,400 yearly subscribers before App Store fees and churn.

**Pricing experiment plan** (post-launch):
1. v2 ships at Weekly $2.99 / Monthly $4.99 / Yearly $29.99, with optional Lifetime $44.99 if ASC returns it.
2. Collect baseline conversion data on the first 100-500 paywall views.
3. Do not change prices without measured paywall-view, purchase, churn, and tier-mix data.
4. Append any price experiment to `docs/decision-log.md` with the date, evidence, and rollback condition.

**Paid acquisition discipline** (locked 2026-06-17):
- **Don't scale Apple Search Ads / paid channels until measured CAC < LTV with payback < 6 months.** Indie SaaS rule.
- A small **burn test** (≤$100) is allowed early to validate ad creative + keyword targeting. Scaling is not.
- Required inputs before scaling: (a) cohort retention data from 100+ paywall views, (b) computed LTV from observed Yearly:Monthly:Weekly tier mix, (c) CAC at the candidate channel comfortably below that LTV.
- Until those inputs exist, organic channels only. Plan: `docs/marketing/README.md` (daily routine — TikTok / IG / Reddit karma).
- Cross-link: `docs/marketing/anti-patterns.md` §Distribution anti-patterns first row codifies this.

## Changing prices

Don't change prices without data. If the numbers above need to move:
1. Update this file first.
2. Update the App Store Connect product config (Weekly / Monthly / Yearly / optional Lifetime prices).
3. Confirm `PaywallView.priceText(for:)` still pulls all visible prices from StoreKit (`Product.displayPrice` + subscription period); no hardcoded visible prices.
4. Update the two places prices are hardcoded outside the app: `Unit/Unit.storekit` (dev QA config) and the marketing site's `app/(marketing)/compare/data.ts` pricing rows.
5. Note the change in `docs/decision-log.md` with the date and the evidence that justified it.

## History (superseded models)

The original v1 model was "free forever core + soft Pro tier" — paywall gated only export, Apple Health, theming, and a "founding supporter" badge. Core logging was protected by a "sacred promise" in this file. That model is **superseded as of 2026-06-16**. Reasons in `docs/decision-log.md` 2026-06-16 entry. The `InstallProvenance` v1-grandfather mechanic recorded to Keychain has been deleted; v1 users hit the same paywall as new installers on v2 launch.
