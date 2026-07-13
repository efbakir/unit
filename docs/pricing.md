# Unit — pricing

> Authoritative reference for Unit's subscription tiers. Any change to price or product IDs lives here first, code second.

## Tiers

| Tier     | Price       | Billing       | Product ID         | Notes                                                   |
| -------- | ----------- | ------------- | ------------------ | ------------------------------------------------------- |
| Weekly   | **$2.99**   | auto-renewing | `com.unit.weekly`  | Default selection — the smallest number on screen (lowest commitment first). |
| Monthly  | **$4.99**   | auto-renewing | `com.unit.monthly` | The normal plan.                                        |
| Yearly   | **$29.99**  | auto-renewing | `com.unit.annual`  | Best value — about half the monthly-equivalent total.   |
| Lifetime | **$44.99**  | one-time      | `com.unit.lifetime` | Optional non-consumable. Show only if configured in ASC and returned by StoreKit. |

**No free trial** on any tier unless a real App Store Connect introductory offer is configured and detected. Lifetime is not a fallback price: it appears only when `Product.products(for:)` returns `com.unit.lifetime`.

## Math

- Weekly × 52 = $155.48/yr — the flexibility premium over Monthly, priced as commitment, not trickery
- Monthly × 12 = $59.88/yr
- Yearly vs monthly-equivalent = $29.99 / $59.88 → roughly 50% lower yearly total
- Lifetime equals about 1.5× the Yearly price and appears only if ASC has the non-consumable configured
- Ladder coherence rule (2026-07-02): every tier must have a role — Weekly = cheapest quick try, Monthly = normal, Yearly = best value, Lifetime = one-time. **No tier may strictly dominate another at the same visible price**; the 2026-06-29 $4.99/$4.99 weekly-monthly tie violated this and was corrected before v2 submission (see decision log).

## Rationale

- **Hard paywall** (resolved 2026-06-16, see `docs/decision-log.md`). All app functionality is gated behind a paid purchase. Onboarding completes free so the user sees their program built; the paywall appears immediately after setup is saved, no dismissal.
- **No free trial.** Day-1 conversion friction is the explicit goal; Apple Guideline 3.1.2(b) disclosure requirements still apply (auto-renewal language, cancellation method). Acknowledged risks: 1-star reviews citing "pay to even try," App Store reviewer scrutiny around the "no preview of value" pattern (mitigated by placing the wall after onboarding, not before).
- **Weekly is default.** This founder override supersedes the 2026-06-17 annual-default experiment plan. The paywall opens on Weekly and the CTA reads `Subscribe weekly` (minimal-language pass, 2026-07-13). Honest-optics condition (2026-07-02): the default tier must be the smallest visible price on the screen — a pre-selected tier that a cheaper-per-period plan strictly dominates reads as a dark pattern and is banned.
- **All subscription plans stay visible.** Weekly, Monthly, and Yearly cards render even while StoreKit is loading. Missing products show loading/unavailable copy, never fake prices.
- **Lifetime is optional.** If the existing non-consumable is configured and StoreKit returns it, Unit shows it as a one-time purchase. If ASC does not return it, the card is hidden.

## What is behind the paywall

Everything. Hard paywall = full app gated.

The onboarding flow (splash → unit picker → import method → program build → schedule) runs free so the user sees their program in the app before being asked to pay. Once onboarding saves the program, the paywall appears before the user can use the main app.

**Free pre-paywall surfaces:**
- All onboarding steps (program entry, day naming, schedule)
- The post-onboarding "your program is ready" hand-off

**Paid post-paywall surfaces:**
- Today tab (start workout, log sets, rest timer)
- Programs tab (view / edit / reorder templates)
- History (browse past sessions, PR chart, calendar)
- Settings (manage subscription, export, theming, etc.)

## App Review metadata checklist

Apple's subscription review surface is not just the in-app paywall. Before every subscription submission:

1. Paste the Terms of Use (EULA) URL into the visible App Store description text: `https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`.
2. Keep the Privacy Policy URL in App Store Connect's dedicated Privacy Policy field: `https://unitlift.app/privacy`.
3. Keep the paywall footer and Settings legal section using full labels: `Terms of Service` and `Privacy Policy`.
4. If Apple repeats a boilerplate 3.1.2 rejection after the metadata is fixed, reply in Resolution Center with screenshots and a screen recording proving the current description and in-app legal links are visible.

## StoreKit sandbox verification checklist

Run this on the exact archive/build submitted for review, using products attached to the App Store Connect version and a sandbox Apple ID:

1. Fresh install → complete onboarding → confirm the app lands on `PaywallView`, not `TodayView`.
2. Start a purchase from the default Weekly plan, cancel the Apple purchase sheet, and confirm the user remains on `PaywallView`.
3. Complete a sandbox purchase for Weekly and confirm the app enters the main tab UI.
4. Delete and reinstall the app, tap `Restore Purchases`, and confirm entitlement restores access to the main tab UI.
5. Cancel the sandbox subscription from App Store subscription management, relaunch after StoreKit reflects the cancellation, and confirm inactive entitlement returns to `PaywallView`.

## Win-back

- **Win-back**: $19.99/yr Apple promotional offer (about ⅔ of Yearly), triggered after subscription cancel. Wire via StoreKit 2.
- **Restore purchases**: standard Apple flow; user signed in with same Apple ID auto-restores entitlement (Required by App Store).

## Distribution

> Pricing is one of two levers that close the paid-acquisition math. The other is LTV. This section codifies how to think about both.

**Target**: $11k MRR ≈ $132k ARR (locked 2026-06-17). At current Yearly price $29.99, that is roughly 4,400 yearly subscribers before App Store fees and churn.

**Pricing experiment plan** (post-launch):
1. v2 ships at Weekly $4.99 / Monthly $4.99 / Yearly $29.99, with optional Lifetime $44.99 if ASC returns it.
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
