# Unit — App Store Connect submission (paste-ready)

> Single-source paste sheet for the submission session on Thu May 14.
> Synthesizes [app-store-copy-variants.md](app-store-copy-variants.md) (Variant 1 — Notebook Replacement, locked), [aso-keywords.md](aso-keywords.md) (97-char keywords field, locked), [launch-week-may-11.md](../launch-week-may-11.md) Day 2 + Day 4 specs, and the live legal pages.
> Resolved 2026-05-11.

---

## Field summary (App Information panel)

| Field | Value | Notes |
|---|---|---|
| App Name | `Unit` | 4 chars — leaves room if alt App Name needed later |
| Subtitle | `Log a set in 3 seconds` | 22 chars — Variant 3 ASO subtitle (per `app-store-copy-variants.md` §Subtitle note), paired with Variant 1 description |
| Primary Category | `Health & Fitness` | |
| Secondary Category | `Sports` (optional) | leave blank if undecided |
| Bundle ID | `com.unitlift.app` | already locked in project.pbxproj |
| SKU | `unit-ios-v1` | |
| Content Rights | "Does not contain, show, or access third-party content" | true — Unit ships zero third-party content |
| Age Rating | `4+` | no objectionable content; answers below |
| Copyright | `2026 Efe Bakir` | swap to LLC name if entity changes pre-submission |
| Marketing URL | `https://unitlift.app` | |
| Support URL | `https://unitlift.app/support` | |
| Privacy Policy URL | `https://unitlift.app/privacy` | live, verified 200 |

---

## Promotional Text (170 chars max, updatable without review)

```
You trained without an app for years. The notebook worked. Unit works the same way — your exercises, your weights, your reps — logged faster than you can write.
```

`165 chars` — Variant 1 promotional text.

---

## Description (4000 chars max)

```
Your paper notebook had one thing right: it never slowed you down.

Unit doesn't either. Ghost values pre-fill your last session automatically, so you tap once to confirm a set, not type. Under 3 seconds, one-handed, mid-workout.

The notebook was your system. Unit is the same system — with a rest timer on your Lock Screen.

ONE TAP PER SET
Last session's weight and reps are already there when you open the exercise. You see what you did. You tap Done. That's a logged set. No typing, no dropdowns, no number steppers to hunt. The design is built around the Gym Test: one hand, sweaty, under 3 seconds.

YOUR PROGRAM, IMPORTED OR BUILT FROM SCRATCH
Paste your routine from Notes or a WhatsApp message — Unit reads it. Or build templates manually in under 2 minutes. No rigid 8-week calendars, no mandatory scheduling. Your push day is your push day. Log it when you show up.

REST TIMER ON YOUR LOCK SCREEN
The timer starts automatically when you log a set. It lives on your Lock Screen and in the Dynamic Island. You don't need to reopen the app between sets. The notebook never made you do that either.

YOUR HISTORY, READABLE AT A GLANCE
Calendar view shows every training day at a glance. Tap any date to see exactly what you lifted: exercise, weight, reps, sets. Personal records are tracked automatically and flagged when you hit them. No dashboard. No summary cards. Just your data, organized.

LOCAL. NO ACCOUNT. ALWAYS WORKS.
No sign-up. No cloud dependency. Your training data lives on your iPhone. Unit works in a basement gym, in airplane mode, in a building with no signal. The notebook worked offline. So does this.

WHAT UNIT IS NOT
— Not an AI coach. You already know what to lift.
— Not a social platform. No feed, no followers, no sharing.
— Not a subscription wall on core logging. Set logging, ghost values, rest timer, history, and PRs are free, always.

Unit Pro adds export (CSV, Markdown), Apple Health sync, custom app icons, and custom template colors. $4.99/month or $29.99/year — 7-day free trial included.

Your notebook knew what you needed. So does Unit.
```

Approximate length: ~1900 chars. Under the 4000-char limit with ~2100 chars of headroom for future additions.

**Pricing note:** Pro pricing matches [pricing.md](../pricing.md) — $4.99/mo, $29.99/yr. If Pro IAP products are NOT yet configured in ASC at the moment you paste (you're submitting v1 with paywall inert per [launch-week-may-11.md](../launch-week-may-11.md)), strip the "Unit Pro adds export…" paragraph to avoid mismatch — Apple checks IAP setup against description claims. Re-add when Pro products are live in W5+.

---

## Keywords (100 chars max, comma-separated, NO spaces after commas)

```
gym tracker,workout log,strength log,lifting log,rest timer,gym notebook,set tracker,rep counter
```

`97 chars` — locked in [aso-keywords.md](aso-keywords.md). Excludes literal competitor trademarks (Hevy/Strong/Liftosaur/Jefit/Fitbod), excludes words already in App Name and Subtitle.

---

## What's New in This Version (v1.0.0, 4000 chars max)

```
Unit is here. Log your sets in one tap — last session pre-filled, rest timer on your Lock Screen, your program imported or built from scratch. No account, no AI, no feed. Built solo. Feedback welcome at support@unitlift.app.
```

`221 chars`.

---

## App Privacy declarations (Data Types)

Source of truth: [Unit/PrivacyInfo.xcprivacy](../../Unit/PrivacyInfo.xcprivacy) + the live [privacy policy](https://unitlift.app/privacy).

**Data Collection: No.** Select "We do not collect data from this app."

The privacy manifest declares only `UserDefaults` (reason `CA92.1` — app functionality) with no tracking and no collected data. The app makes no network requests for user data. The only outbound communication is the user-initiated `mailto:` support link, which is governed by the user's mail client, not Unit.

---

## App Review Information

| Field | Value |
|---|---|
| Sign-In Required | **No** |
| Demo Account | N/A |
| Contact First Name | `Efe` |
| Contact Last Name | `Bakir` |
| Contact Phone | (your number) |
| Contact Email | `support@unitlift.app` |

**Notes for the Reviewer:**

```
Unit is a local-first gym logger for iPhone. It requires no account, no sign-in, and no network connection — all workout data is stored on-device via SwiftData. No demo credentials are needed.

To evaluate the core flow:
1. Open the app — onboarding takes ~30 seconds and asks no personal questions.
2. Pick a starter program (or skip and build your own).
3. Tap "Start workout" on the Today tab to begin a session.
4. Log a set: weight and reps are pre-filled from the most recent session ("ghost values"). Tap Done to log. The rest timer starts automatically and is visible on the Lock Screen / Dynamic Island.

In-app purchases for Unit Pro are configured in the listing but are not gated in this build — core logging is free with no paywall. Pro features (export, Apple Health sync, custom icons, custom template colors) will be enabled in a future update, with pricing matching the listing description.

The app does not collect, transmit, or store any personal data. There is no analytics, no tracking, no advertising SDK. The PrivacyInfo manifest declares only UserDefaults (reason CA92.1 — app functionality).

If you have questions during review, please email support@unitlift.app.
```

---

## Compliance / Export

| Field | Value |
|---|---|
| Uses Encryption | No |
| Reason | `Info.plist` sets `ITSAppUsesNonExemptEncryption = false` |
| Content Rights | Does not contain third-party content |
| Advertising Identifier (IDFA) | Does not use |

---

## Age rating questionnaire (likely answers → 4+)

All categories: **None** / **No**.

- Cartoon / Fantasy / Realistic Violence: None
- Profanity / Crude Humor: None
- Mature / Suggestive Themes: None
- Horror / Fear Themes: None
- Medical / Treatment Information: **None** (Unit is fitness tracking, not medical advice — the Terms of Use already disclaim this)
- Gambling and Contests: None
- Unrestricted Web Access: No
- User-Generated Content: No (your workout names are private, on-device only — Apple considers this non-UGC because nothing is shared)

Final rating: **4+**.

---

## In-App Purchases (Pro)

Pulled directly from [pricing.md](../pricing.md) and verified against `Unit/Features/Subscription/StoreManager.swift` `Tier` enum:

| Product | Reference Name | Product ID | Type | Price |
|---|---|---|---|---|
| Monthly | Unit Pro Monthly | `com.unit.monthly` | Auto-renewable subscription (1 month) | $4.99 |
| Annual | Unit Pro Annual | `com.unit.annual` | Auto-renewable subscription (1 year) | $29.99 |
| Lifetime | Unit Pro Lifetime | `com.unit.lifetime` | Non-consumable | $44.99 |

These IDs are load-bearing — `StoreManager.swift:18–24` requests products by these exact strings. Any drift between the StoreManager enum and the ASC product configuration breaks `Product.products(for:)` silently in review.

**Free trial:** 7 days on Monthly and Annual. Configure via Introductory Offer (Free, 7 days) in ASC. Lifetime has no trial — it is one-time.

**Subscription group:** Monthly + Annual belong to one auto-renewable group (suggested name: `unit-pro`). Lifetime is non-consumable and does NOT belong to the subscription group.

**Display name + description** (each ≤30 / ≤45 chars, per Apple):

- `com.unit.monthly` — `Unit Pro Monthly` / `Export, Health sync, custom icons`
- `com.unit.annual` — `Unit Pro Annual` / `Export, Health sync, custom icons`
- `com.unit.lifetime` — `Unit Pro Lifetime` / `Pro features, one-time purchase`

**Win-back offer** (post-launch, not at W3 submission): $19.99/yr Apple promotional offer on the Annual product, triggered after trial expiry without conversion or after cancellation. Configure under the Annual product's "Promotional Offers" in ASC. Wire via StoreKit 2 or RevenueCat per [launch-plan.md](../launch-plan.md) §2.

---

## Localization

Submission ships English (United States) only. Per [launch-plan.md](../launch-plan.md) §1, localization is deferred until $5k MRR or international install spike. Skip every other locale field for now.

---

## Final pre-submit checklist (run Thursday before tapping Submit)

- [ ] All 5 screenshots uploaded at 1290×2796 (per [screenshot-strategy-final.md](research/screenshot-strategy-final.md))
- [ ] App Icon uploaded (1024×1024, no alpha, no rounded corners)
- [ ] Build attached to listing
- [ ] All copy passes the first-person singular check (no `we`, `us`, `our` — grep once before submit)
- [ ] Encryption: No (`ITSAppUsesNonExemptEncryption = false` in Info.plist)
- [ ] Privacy URL returns 200
- [ ] Support URL returns 200
- [ ] Marketing URL returns 200
- [ ] App Privacy section says "Data Not Collected"
- [ ] Age rating set to 4+ (or whatever the questionnaire returned)
- [ ] Pricing tier set (Free at top level; subscriptions configured separately)
- [ ] Subscription Group + Introductory Offer set up for Monthly/Yearly if Pro is going live in v1.0.0 (otherwise IAP records stay in draft)

---

## See also

- [app-store-copy-variants.md](app-store-copy-variants.md) — full Variant 1/2/3 source (Variant 1 ships W3; Variant 3 enters PPO test at W6)
- [aso-keywords.md](aso-keywords.md) — the 100-char keyword field rationale and post-launch monitoring plan
- [research/screenshot-strategy-final.md](research/screenshot-strategy-final.md) — the 5-screenshot Figma spec
- [pricing.md](../pricing.md) — authoritative pricing (matches the description copy above)
- [launch-week-may-11.md](../launch-week-may-11.md) Day 4 — the Thursday submission script this file feeds into
