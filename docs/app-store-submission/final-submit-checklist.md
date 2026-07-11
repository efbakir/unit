# Final submit checklist — Unit v2.0 (build 15)

> The ASC handoff package. Everything below is paste-exact for App Store Connect; nothing requires a code change.
> Written 2026-07-11 from `main` after build + tests passed. Companions: `docs/pricing.md` (pricing truth), `docs/app-store-localization/asc-paste-checklist.md` (optional localized metadata), `docs/release-qa.md` (device gauntlet).

---

## 0. Warnings — read before touching ASC

- **No trial.** Nothing in metadata, reviewer notes, or product config may mention a free trial. There is none.
- **No fake prices.** Every visible in-app price is StoreKit-derived. ASC product config is the only place prices exist.
- **The app UI is English-only.** Do not claim or imply localization anywhere. Localized *metadata* is a separate, optional step (§8).
- **Product IDs are immutable.** If any ASC screen asks you to create a product, you are on the wrong screen.

## 1. Version / build

| Field | Value | Verified |
|---|---|---|
| Marketing version | **2.0** | `MARKETING_VERSION = 2.0` in all 6 pbxproj configs |
| Build | **15** | `CURRENT_PROJECT_VERSION = 15` in all 6 pbxproj configs |
| Archive source | `main` @ `cfb0060` (PR #1 + PR #2 merged) | build + test suite pass, clean tree |

## 2. App name

Paste into App Information → Name:

```
Unit: Gym Workout Log
```

Per the 2026-07-11 submission goal. **Separator flag:** the decision log and both copy docs write this name with an em-dash (`Unit — Gym Workout Log`). Same words, same ASO value — keywords index identically; the separator is cosmetic. Pick one at paste time; if you keep the colon, align `docs/app-store-copy.md` + `docs/marketing/app-store-copy.md` after. Home-screen icon stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`) either way.

## 3. Subscription products (must match exactly)

Group: reference name `unit-pro`, display name `Unit Pro`.

| Product | Product ID | Type | Price (USD base) |
|---|---|---|---|
| Weekly — **default selection** | `com.unit.weekly` | Auto-renewable, 1 week | **$2.99** |
| Monthly | `com.unit.monthly` | Auto-renewable, 1 month | **$4.99** |
| Yearly | `com.unit.annual` | Auto-renewable, 1 year | **$29.99** |
| Lifetime (optional) | `com.unit.lifetime` | Non-consumable | **$44.99** |

- [ ] Confirm Weekly reads **$2.99** in ASC (the 2026-07-02 change). If it reads $4.99, fix before anything else.
- [ ] All prices automatically generated from the USD base — no custom storefront prices.
- [ ] No introductory offer on any tier.
- [ ] Lifetime: only if the non-consumable is already configured. Do not create it for this submission.

## 4. Reviewer notes — paste verbatim

App Review Information → Notes:

```
Unit v2 is a local-first gym logger for iPhone. It requires a paid purchase to access the workout-logging features. Onboarding runs free — the reviewer can complete the opener, the three-slide carousel, and the full program setup flow without paying. After setup is saved, the paywall appears full-screen and cannot be dismissed.

To evaluate:
1. Open the app. Onboarding starts with a standalone opener, then a three-slide value carousel with the "Set up your program" CTA, then program setup. No personal information is requested.
2. After onboarding completes, the paywall appears with these StoreKit products: Weekly com.unit.weekly $2.99/week, Monthly com.unit.monthly $4.99/month, Yearly com.unit.annual $29.99/year, and Lifetime com.unit.lifetime $44.99 one-time only if that non-consumable is configured and returned by StoreKit. Weekly is selected by default. There is no "Not now" affordance; the only ways out are to purchase through StoreKit sandbox or close the app.
3. Subscribe to any recurring tier, or buy Lifetime if visible, via the sandbox account. The paywall dismisses and the Today tab unlocks. Log a set; the rest timer starts automatically and appears on the Lock Screen / Dynamic Island.
4. To verify cancellation flow for subscriptions: Settings (visible only when entitled) → Manage Subscription → cancel. Lifetime entitlement has no Manage Subscription row because it is a one-time purchase.

There is no free trial. Apple Guideline 3.1.2(b) disclosure is satisfied: each tier card shows product title, full StoreKit price, and billing period; the selected billed amount remains visible directly above the CTA; auto-renewal and cancel-via-Settings copy is on the paywall itself. No deceptive trial framing.

The app does not collect, transmit, or store any personal data. All workout data lives on-device via SwiftData. The PrivacyInfo manifest declares only UserDefaults (reason CA92.1 — app functionality). Privacy is verifiable offline: post-subscription, put the device in airplane mode and every feature still works.

If you have questions during review, please email support@unitlift.app.
```

(Adapted from the v2 block in `docs/archive/marketing/asc-submission.md` with the corrected $2.99 Weekly price.)

## 5. English metadata — paste verbatim

Source: `docs/marketing/app-store-copy.md` (paste-ready v2).

**Subtitle (30):**

```
Fast workout & strength log
```

**Promotional text (170, editable anytime):**

```
New in v2: paste your program and start with real working numbers from day one. Still no account, no ads — just fast logging that lives on your iPhone.
```

**Description:**

```
Log a set in 3 seconds and get back under the bar.

Your weights from last time are already filled in — confirm, adjust, done. Paste any program and your working numbers are ready from day one.

No account. No ads. No social feed. Your training stays on your iPhone.

A gym notebook, not a platform.

Unit requires a paid purchase after setup. Weekly, monthly, and yearly auto-renewing subscriptions are available. Optional Lifetime appears only if available. Prices are shown in the app before purchase. There is no free trial.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://unitlift.app/privacy
```

**Keywords (100, no spaces):**

```
lifting,tracker,powerlifting,exercise,routine,reps,barbell,fitness,training,planner,5x5,hypertrophy
```

**What's New:**

```
• Log a set in 3 seconds — last time's weights are already filled in
• Paste any program and start with real working numbers from day one
• Rebuilt first run: from install to your first logged set in under a minute
```

The description's paid-purchase paragraph and the two legal URLs are Guideline 3.1.2(b) compliance — never trim them.

## 6. Screenshot set

**Reuse the 5 English screenshots currently live on the listing (1290×2796, approved with v1.1). Upload nothing new.** This is strategy (b) from the v2 override in `docs/archive/marketing/asc-submission.md` §2.3.3: the carousel shows the post-paywall app; the reviewer notes carry the paywall explanation. Spec record: `docs/archive/marketing/research/screenshot-strategy-final.md`. Do not edit, re-crop, or localize screenshots for this submission.

## 7. IAP / subscription attachment checklist

- [ ] Business → Agreements: **Paid Applications agreement active** (not "Pending"). Blocks everything if not.
- [ ] Features → Subscriptions → `unit-pro` group exists with the 3 auto-renewables (§3 IDs and prices exact).
- [ ] Each product has an English display name + description and a **review screenshot** (one capture of `PaywallView` covers all).
- [ ] App Store tab → version 2.0 → In-App Purchases and Subscriptions → **attach Weekly, Monthly, Yearly** (+ Lifetime if configured). First-time IAPs are reviewed with the binary; skipping this is a metadata-mismatch rejection.
- [ ] Build 15 attached to the version.

## 8. Localization (optional for this submission)

PR #2's five-language metadata (de-DE, es-MX, pt-BR, fr-FR, tr) is ready in `docs/app-store-localization/`. **Optional now** — the English-only submission is complete without it. If pasting now: follow `docs/app-store-localization/asc-paste-checklist.md` end to end, including the native-speaker reads (Turkish is founder-reviewed). Do not paste unreviewed translations to hit this submission window; they can ride any later version.

## 9. Privacy / age rating / URLs

- [ ] App Privacy: **"Data Not Collected"** (matches `Unit/PrivacyInfo.xcprivacy` — UserDefaults only, reason CA92.1).
- [ ] Age rating: **4+** (all questionnaire categories None/No).
- [ ] Encryption: **No** (`ITSAppUsesNonExemptEncryption = false` in Info.plist).
- [ ] Privacy Policy URL: `https://unitlift.app/privacy` — returns 200.
- [ ] Support URL: `https://unitlift.app/support` — returns 200.
- [ ] Marketing URL: `https://unitlift.app` — returns 200.
- [ ] Copyright: `2026 Efe Bakir`.
- [ ] First-person check on any copy you edited: no `we / us / our`.

## 10. Pre-archive gate (before Product → Archive)

- [ ] StoreKit sandbox QA — all 5 steps in `docs/pricing.md` §StoreKit sandbox verification checklist, on this exact build, with sandbox Apple ID.
- [ ] `docs/release-qa.md` gauntlet run on device.
- [ ] Archive from `main` @ `cfb0060` (or later docs-only commits — no code drift).
- [ ] Known site inconsistency (not an archive blocker, fix before marketing push): `app/(marketing)/compare/data.ts` still says "Core logging is free forever. Pro is $4.99/mo or $29.99/yr." in 3 rows, and `app/(marketing)/page.tsx` has one "Free. No account. No ads." eyebrow. Both contradict the hard paywall on the live site.
