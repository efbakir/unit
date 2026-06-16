# Unit — App Store Connect submission (paste-ready)

> Single-source paste sheet for the submission session.
> Synthesizes [app-store-copy-variants.md](app-store-copy-variants.md) (Variant 1 — Notebook Replacement, locked), [aso-keywords.md](aso-keywords.md) (97-char keywords field, locked), [launch-week-may-11.md](../launch-week-may-11.md) Day 2 + Day 4 specs, and the live legal pages.
> Resolved 2026-05-11. **Updated 2026-05-31**: App Name changed to `Unit — Gym Notebook` (collision on `Unit`), and Pro IAP decoupled — see updated In-App Purchases section. **Updated 2026-06-03**: Build 1.0 (12) rejected under Guideline 2.1(b) — the binary's Settings → Subscription section + Settings → Data → Export PRO row + Screenshot 5 PRO chip all triggered the "paid content with no IAP" pattern. Surgical fix landed (Settings code strips both Pro surfaces; Screenshot 5 Row 3 replaced with "Tracking: None"). Reply drafted at [`app-review-reply-2026-06-03.md`](app-review-reply-2026-06-03.md). See [`../decision-log.md`](../decision-log.md) 2026-06-03 entry for full rationale.

---

## Field summary (App Information panel)

| Field | Value | Notes |
|---|---|---|
| App Name | `Unit — Gym Notebook` | 19 chars. Original `Unit` (4 chars) was already taken on App Store Connect — collision hit 2026-05-31 during submission. Em-dash separator per indie iOS convention (Things, Bear, Reeder, Halide). "Gym Notebook" reinforces Variant 1 positioning and is the App Name alternative pre-blessed in `aso-keywords.md` row 28. Home screen icon still reads `Unit` via `INFOPLIST_KEY_CFBundleDisplayName = Unit` — this rename is App Store listing only. |
| Subtitle | `Log a set in 3 seconds` | 22 chars — Variant 3 ASO subtitle (per `app-store-copy-variants.md` §Subtitle note), paired with Variant 1 description |
| Primary Category | `Health & Fitness` | |
| Secondary Category | `Sports` (optional) | leave blank if undecided |
| Bundle ID | `app.unitlift` | already locked in project.pbxproj (changed from `com.unitlift.app` on 2026-05-12 — original ID unavailable; canonical reverse-DNS of `unitlift.app`) |
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
Calendar view shows every training day at a glance. Tap any date to see exactly what you lifted: exercise, weight, reps, sets. No dashboard. No summary cards. Just your data, organized.

LOCAL. NO ACCOUNT. ALWAYS WORKS.
No sign-up. No cloud dependency. Your training data lives on your iPhone. Unit works in a basement gym, in airplane mode, in a building with no signal. The notebook worked offline. So does this.

WHAT UNIT IS NOT
— Not an AI coach. You already know what to lift.
— Not a social platform. No feed, no followers, no sharing.
— Not a subscription. Everything in the app is here, free.

Your notebook knew what you needed. So does Unit.
```

Approximate length: ~1700 chars. Under the 4000-char limit with ~2300 chars of headroom.

**Submission decision SUPERSEDED (2026-05-31): Decouple chosen — Pro IAP deferred.** The Option B / "configure all 3 IAPs and attach to v1.0.0" plan recorded in this doc on 2026-05-30 was reversed at the moment of submission because no Pro feature is built and the Guideline 3.1.1 "purchase doesn't deliver advertised features" risk is too high to absorb in the launch review. The Pro paragraph is stripped. The third "WHAT UNIT IS NOT" bullet is rewritten from "subscription wall on core logging" to "Not a subscription" — accurate-now and forward-compatible. Product IDs `com.unit.monthly` / `com.unit.annual` / `com.unit.lifetime` remain reserved in `StoreManager.swift` for when Pro ships. When that happens, re-add the Pro paragraph and restore the "subscription wall on core logging" bullet phrasing.

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
1. Open the app. Onboarding walks through about six short screens: pick a weight unit (kg or lb), choose whether to paste an existing program text or build one from scratch, then set up the split (number of training days), schedule, and exercises. No personal information is requested at any point — no name, email, age, weight, or contact details. (Note: the "import past workout history" path only appears for users who already have prior completed sessions on this device; on a fresh reviewer install it is gated off by design.)
2. After onboarding, the Today tab shows the next scheduled workout. Tap "Start workout" to begin a session.
3. Inside a session, weight and reps for each set are pre-filled from your most recent session of that exercise ("ghost values"). Tap Done to log a set. The rest timer starts automatically and is visible on the Lock Screen and in the Dynamic Island so you don't need to reopen the app between sets.
4. The History tab shows every past session by date. Tap any date to see the exercises, weights, reps, and sets you logged.

There are no in-app purchases or subscriptions in this build — the entire app is free. A Pro tier may launch in a future update, but is not configured, gated, or referenced in this submission. StoreKit code paths exist in the binary as scaffolding for that future tier but are not reachable from any UI surface in v1.0.0 — `PaywallView.swift` is never presented from any screen, the Settings Subscription section is not rendered (`subscriptionSection` is defined but uncalled in `settingsContent`), and no IAP products are configured in App Store Connect, so `Product.products(for:)` returns an empty collection at runtime.

The app does not collect, transmit, or store any personal data. There is no analytics, no tracking, no advertising SDK. The PrivacyInfo manifest declares only UserDefaults (reason CA92.1 — app functionality). Privacy is verifiable offline: put the device in airplane mode and every feature still works — onboarding, logging, history, rest timer, Live Activity.

Native iOS depth (verifiable in 30 seconds of use): tap Done on a logged set to see an ActivityKit Live Activity and Dynamic Island countdown (UnitWidget extension, `NSSupportsLiveActivities = YES` in Info.plist). All workout data persists via SwiftData (`@Model` on `WorkoutSession`, `SetEntry`, `Exercise`, `DayTemplate`). UI is 100% native SwiftUI — `TabView`, `NavigationStack`, `presentationDetents`, `@FocusState`, `.sensoryFeedback`. No web view, no cross-platform runtime, no JavaScript bridge.

The subtitle's "3 seconds per set" claim refers to the ghost-value flow: Today → Start workout → tap a set row, observe the elapsed time between the tap and the haptic confirmation. The in-app rest timer auto-starts on set completion and is visible on the Lock Screen and Dynamic Island — that is what makes the loop reproducible without reopening the app between sets.

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

## In-App Purchases (Pro) — DEFERRED for v1.0.0

> **SUPERSEDED 2026-05-31 — Decouple chosen.** Skip this entire section for the v1.0.0 submission. No IAP records are created in ASC. No paragraph in the description references Pro. The product IDs below remain reserved in `StoreManager.swift` for the future Pro launch but are NOT configured in App Store Connect today. Everything below is preserved for the eventual Pro submission — read past it for the v1.0.0 final checklist.
>
> **Original 2026-05-30 Option B plan (DO NOT EXECUTE):** configure all 3 records, attach them to the v1.0.0 build for review, keep the Pro paragraph in the description. The cost is review surface — see **Review risk** below.

**Verified clean 2026-05-30** — product IDs and prices match across all three sources, so there is no silent `Product.products(for:)` failure waiting in review:

| Source | Monthly | Annual | Lifetime |
|---|---|---|---|
| `StoreManager.swift:19-21` | `com.unit.monthly` | `com.unit.annual` | `com.unit.lifetime` |
| `docs/pricing.md` | `com.unit.monthly` · $4.99 | `com.unit.annual` · $29.99 | `com.unit.lifetime` · $44.99 |
| This sheet | ✓ | ✓ | ✓ |

Pulled directly from [pricing.md](../pricing.md) and verified against `Unit/Features/Subscription/StoreManager.swift` `Tier` enum:

| Product | Reference Name | Product ID | Type | Price |
|---|---|---|---|---|
| Monthly | Unit Pro Monthly | `com.unit.monthly` | Auto-renewable subscription (1 month) | $4.99 |
| Annual | Unit Pro Annual | `com.unit.annual` | Auto-renewable subscription (1 year) | $29.99 |
| Lifetime | Unit Pro Lifetime | `com.unit.lifetime` | Non-consumable | $44.99 |

These IDs are load-bearing — `StoreManager.swift:18–24` requests products by these exact strings. Any drift between the StoreManager enum and the ASC product configuration breaks `Product.products(for:)` silently in review.

### ASC configuration sequence (do this in order)

No App Store Connect API key or fastlane config exists in the repo, so this is a manual web task — ~15 min. Order matters: the subscription group must exist before the auto-renewables.

0. **Prerequisite — Paid Applications Agreement must be active.** Business → Agreements, Tax, and Banking → the "Paid Applications" agreement is signed and not "Pending". No IAP can be created or submitted until it is. First-time accounts often have only the free agreement; sign it now or the whole sequence is blocked.
1. **Create the subscription group.** Features → Subscriptions → create group, reference name `unit-pro`, group display name `Unit Pro` (this is user-visible in Manage Subscriptions).
2. **Monthly** (in the `unit-pro` group). Reference Name `Unit Pro Monthly` · Product ID `com.unit.monthly` · Duration 1 month · Price $4.99 · Introductory Offer: **Free, 7 days**.
3. **Annual** (in the `unit-pro` group). Reference Name `Unit Pro Annual` · Product ID `com.unit.annual` · Duration 1 year · Price $29.99 · Introductory Offer: **Free, 7 days**.
4. **Lifetime** (Features → In-App Purchases, **Non-Consumable** — NOT in the subscription group). Reference Name `Unit Pro Lifetime` · Product ID `com.unit.lifetime` · Price $44.99 · no trial.
5. **Per product, fill the localized display name + description** (table below) and **upload one review screenshot** — a capture of `PaywallView` covers all three.
6. **Attach all 3 to the v1.0.0 version for review.** App Store tab → the v1.0.0 version page → "In-App Purchases and Subscriptions" → select all three. First-time IAPs are reviewed *with* the binary; if you skip this they sit unreviewed and the description references purchases nobody can make (metadata-mismatch rejection). This is why Option B attaches rather than leaving them in draft.

**Free trial:** 7 days on Monthly and Annual. Configure via Introductory Offer (Free, 7 days) in ASC. Lifetime has no trial — it is one-time.

**Subscription group:** Monthly + Annual belong to one auto-renewable group (suggested name: `unit-pro`). Lifetime is non-consumable and does NOT belong to the subscription group.

**Display name + description** (each ≤30 / ≤45 chars, per Apple):

- `com.unit.monthly` — `Unit Pro Monthly` / `Support Unit + lock your founding rate`
- `com.unit.annual` — `Unit Pro Annual` / `Support Unit + lock your founding rate`
- `com.unit.lifetime` — `Unit Pro Lifetime` / `Support Unit forever. One-time purchase`

(Each description ≤45 chars, framed around what a purchase delivers *today* — founding-rate support — not the forthcoming features, per the Review-risk resolution below.)

### Review risk (read before you submit)

Every Pro feature named in the description and the in-app paywall is **unbuilt** as of 2026-05-30 (verified against the code):

- Export (CSV/Markdown) and Apple Health sync → Settings shows "Coming soon" *after* purchase (`SettingsView.swift:220,239`).
- Custom app icons + custom template accent colors → no implementation exists at all (no `setAlternateIconName`, no color picker in the codebase).
- A completed purchase delivers exactly one thing today: founding-supporter status (`SettingsView.swift:184` "Active — Thanks for supporting Unit") + the locked founding rate.

Two distinct Apple exposures:

- **Guideline 2.1 "couldn't locate the in-app purchase" — LOW.** The paywall is reachable from three surfaces (Settings → Unit Pro → Subscribe; Settings → Data → Export / Apple Health; History → toolbar PRO chip), and `StoreManager.purchase()` is fully wired. A reviewer can find and complete a sandbox purchase.
- **Guideline 3.1.1 / 2.3.1 "purchase doesn't deliver the advertised features" — MEDIUM-HIGH.** A reviewer who buys Pro sees every advertised feature flip to "Coming soon" or not appear. The description's present-tense "Unit Pro adds export, Health sync, custom icons, custom colors" compounds the mismatch.

**Mitigation — resolved 2026-05-30: timing-honest reframe applied.** The description paragraph, the in-app paywall (`PaywallView.swift` subhead + benefit rows — forthcoming features now tagged "coming soon" to match Settings), and the 3 IAP localized descriptions above all now frame the features as forthcoming free updates, with the founding-rate lock as the present-tense benefit. The reviewer notes still carry the rollout explanation as backup. Residual 3.1.1 risk is reduced but not zero (a strict reviewer may still question charging ahead of features) — if it bounces, the next lever is shipping one cosmetic feature (custom app icons or accent colors) before re-submit.

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
- [ ] **Pro IAP deferred** (Decouple chosen 2026-05-31): zero IAP records created in ASC; description does NOT mention Pro; third "WHAT UNIT IS NOT" bullet says "Not a subscription" (not "subscription wall"); App Review notes say "no in-app purchases in this build". The [In-App Purchases section](#in-app-purchases-pro--deferred-for-v100) is preserved for the future Pro launch — do not execute it today.

---

## See also

- [app-store-copy-variants.md](app-store-copy-variants.md) — full Variant 1/2/3 source (Variant 1 ships W3; Variant 3 enters PPO test at W6)
- [aso-keywords.md](aso-keywords.md) — the 100-char keyword field rationale and post-launch monitoring plan
- [research/screenshot-strategy-final.md](research/screenshot-strategy-final.md) — the 5-screenshot Figma spec
- [pricing.md](../pricing.md) — authoritative pricing (matches the description copy above)
- [launch-week-may-11.md](../launch-week-may-11.md) Day 4 — the Thursday submission script this file feeds into
