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

## Changing prices

Don't change prices without data. If the numbers above need to move:
1. Update this file first.
2. Update the App Store Connect product config (Weekly / Monthly / Annual prices).
3. Update `StoreManager.swift` fallback prices in `PaywallView.priceText(for:)` (the live prices are pulled from StoreKit, not hardcoded — fallbacks only render when product load fails).
4. Note the change in `docs/decision-log.md` with the date and the evidence that justified it.

## History (superseded models)

The original v1 model was "free forever core + soft Pro tier" — paywall gated only export, Apple Health, theming, and a "founding supporter" badge. Core logging was protected by a "sacred promise" in this file. That model is **superseded as of 2026-06-16**. Reasons in `docs/decision-log.md` 2026-06-16 entry. The `InstallProvenance` v1-grandfather mechanic recorded to Keychain has been deleted; v1 users hit the same paywall as new installers on v2 launch.
