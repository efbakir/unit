# Unit — pricing

> Authoritative reference for Unit's subscription tiers. Any change to price or product IDs lives here first, code second.

## Tiers

| Tier     | Price       | Billing       | Product ID         | Notes                                                   |
| -------- | ----------- | ------------- | ------------------ | ------------------------------------------------------- |
| Weekly   | **$4.99**   | auto-renewing | `com.unit.weekly`  | Entry tier. ~$0.71/day.                                 |
| Monthly  | **$9.99**   | auto-renewing | `com.unit.monthly` | Cancelable anytime.                                     |
| Annually | **$59.99**  | auto-renewing | `com.unit.annual`  | Default selection. ~$5/mo effective. 50% off monthly.   |

**No free trial** on any tier. **No lifetime tier** (dropped 2026-06-16 in favor of recurring revenue).

## Math

- Weekly × 52 = $259.48/yr
- Monthly × 12 = $119.88/yr
- Annual vs monthly-equivalent = $59.99 / $119.88 → **50% saved** (display as `SAVE 50%` on the Annual card)
- Weekly is the high-churn tier (LTV from "forgot to cancel" is the lever)

## Rationale

- **Hard paywall** (resolved 2026-06-16, see `docs/decision-log.md`). All app functionality is gated behind a paid subscription. Onboarding completes free so the user sees their program built; the first attempt to start a workout opens the paywall, no dismissal.
- **No free trial.** Day-1 conversion friction is the explicit goal; Apple Guideline 3.1.2(b) disclosure requirements still apply (auto-renewal language, cancellation method). Acknowledged risks: 1-star reviews citing "pay to even try," App Store reviewer scrutiny around the "no preview of value" pattern (mitigated by placing the wall after onboarding, not before).
- **Weekly is the LTV lever.** Industry pattern: weekly subscribers churn fast but forgotten cancellations compound. Strong precedent in habit/utility apps. Position the weekly tier as the "try it for a week" framing without calling it a trial.
- **Annual is default, highlighted.** Best LTV for Unit, biggest perceived savings for the user.
- **Monthly is the middle tier.** Priced 2× weekly's annualized rate so the annual tier is the obvious better deal.
- **No Lifetime.** Lifetime tiers conflict with hard-paywall growth — they cap LTV. Existing v1 users who purchased Lifetime under the soft-paywall model are not retroactively migrated; ASC retires the product.

## What is behind the paywall

Everything. Hard paywall = full app gated.

The onboarding flow (splash → unit picker → import method → program build → schedule) runs free so the user sees their program in the app before being asked to pay. The first attempt to **start a workout** opens the paywall.

**Free pre-paywall surfaces:**
- All onboarding steps (program entry, day naming, schedule)
- The post-onboarding "your program is ready" hand-off

**Paid post-paywall surfaces:**
- Today tab (start workout, log sets, rest timer)
- Programs tab (view / edit / reorder templates)
- History (browse past sessions, PR chart, calendar)
- Settings (manage subscription, export, theming, etc.)

## Win-back

- **Win-back**: $19.99/yr Apple promotional offer (⅔ of Annual), triggered after subscription cancel. Wire via StoreKit 2.
- **Restore purchases**: standard Apple flow; user signed in with same Apple ID auto-restores entitlement (Required by App Store).

## Distribution

> Pricing is one of two levers that close the paid-acquisition math. The other is LTV. This section codifies how to think about both.

**Target**: $11k MRR ≈ $132k ARR (locked 2026-06-17). At current annual price $59.99 = ~2,200 paying annual subs. At $74.99 = ~1,760.

**Pricing experiment plan** (post-launch):
1. v2 ships at Weekly $4.99 / Monthly $9.99 / Annual $59.99 — the current committed prices.
2. Collect baseline conversion data on the first 100-500 paywall views.
3. **Week 3-4**: if Annual conversion is ≥ 8% of paywall views (fitness category benchmark), bump Annual to **$74.99** via ASC for new subscribers. Existing subs grandfather at $59.99 per Apple price-increase policy.
4. **Week 5-6**: measure conversion delta. If down ≥ 30%, revert to $59.99. If down ≤ 20%, hold $74.99.
5. Weekly + Monthly tiers stay unchanged through this experiment. They are short-term / high-churn tiers, not the revenue lever.
6. Append the result to `docs/decision-log.md` as a dated entry. If it justifies further moves (e.g., $89.99 ceiling test), capture the next experiment here.

**Paid acquisition discipline** (locked 2026-06-17):
- **Don't scale Apple Search Ads / paid channels until measured CAC < LTV with payback < 6 months.** Indie SaaS rule.
- A small **burn test** (≤$100) is allowed early to validate ad creative + keyword targeting. Scaling is not.
- Required inputs before scaling: (a) cohort retention data from 100+ paywall views, (b) computed LTV from observed Annual:Monthly:Weekly tier mix, (c) CAC at the candidate channel comfortably below that LTV.
- Until those inputs exist, organic channels only. Plan: `docs/marketing/README.md` (daily routine — TikTok / IG / Reddit karma).
- Cross-link: `docs/marketing/anti-patterns.md` §Distribution anti-patterns first row codifies this.

## Changing prices

Don't change prices without data. If the numbers above need to move:
1. Update this file first.
2. Update the App Store Connect product config (Weekly / Monthly / Annual prices).
3. Update `StoreManager.swift` fallback prices in `PaywallView.priceText(for:)` (the live prices are pulled from StoreKit, not hardcoded — fallbacks only render when product load fails).
4. Note the change in `docs/decision-log.md` with the date and the evidence that justified it.

## History (superseded models)

The original v1 model was "free forever core + soft Pro tier" — paywall gated only export, Apple Health, theming, and a "founding supporter" badge. Core logging was protected by a "sacred promise" in this file. That model is **superseded as of 2026-06-16**. Reasons in `docs/decision-log.md` 2026-06-16 entry. The `InstallProvenance` v1-grandfather mechanic recorded to Keychain has been deleted; v1 users hit the same paywall as new installers on v2 launch.
