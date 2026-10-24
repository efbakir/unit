# Unit — App Store copy (canonical)

> **FROZEN 2026-08-04 FOR VERSION 2.1 — founder-approved direction.** The single source of truth for every App Store Connect text field; if a string isn't here, it isn't canon. The five locale files predate the progressive-overload rename and must not be published without regeneration and review.
> Process (what to click, in what order): `docs/app-store-submission/final-submit-checklist.md`.
> Localized metadata derives from this file — see `docs/app-store-localization/README.md`.
> The progressive-overload positioning ships with the verified transparent double-progression feature in 2.1. Retired copy lives in git history, not beside the active fields.

## App name (30)

```
Unit: Progressive Overload
```

26 characters. The App Store listing names the outcome Unit now supports. The in-app and Home Screen name stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`). Unit provides transparent, user-controlled double-progression suggestions; it does not claim to calculate an optimal program.

## Subtitle (30)

```
Gym Workout Log & Tracker
```

25 characters. The subtitle explains the product category while the name carries the progression outcome.

## Promotional text (170, editable anytime without review)

```
Log each set in one tap. Unit remembers last time and shows one clear next target as soon as an exercise is done. Accept it, repeat it, or change it.
```

Evergreen and explicit about the mechanism. It promises a suggestion, not coaching or automatic program control.

## Description (4000)

```
Log a set in 3 seconds and know what to aim for next time.

Choose a ready-made program or paste your own. Unit keeps your previous weights and reps ready, so each set is quick to confirm or adjust.

For exercises with a rep range, Unit suggests one clear next target as soon as the exercise is done. Reach the top of the range on every set to add weight. Otherwise, keep the weight and build reps. Every suggestion can be accepted, repeated, or edited after your workout.

• One-tap set logging
• Transparent progressive overload targets
• Ready-made programs
• Paste your routine
• Automatic rest timer on the Lock Screen
• Workout history, personal records, and main-lift analytics

No account. No ads. No social feed. Raw workout details stay on your iPhone. Unit sends limited anonymous product-usage events to help improve the app. Analytics are not linked to your identity, are not used for tracking, and can be disabled in Settings.

Unit requires a paid purchase after setup. Weekly, monthly, and yearly auto-renewing subscriptions are available. Eligible new customers may receive a 7-day free introductory trial on Monthly or Yearly when Apple confirms the offer. Weekly and optional Lifetime have no trial. Prices and offer details are shown in the app before purchase.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://unitlift.app/privacy
```

Short on purpose: iOS descriptions are conversion-only (not search-indexed) and only ~3 lines show before "more". The paid-purchase paragraph + both legal URLs are Guideline 3.1.2(b) compliance — **never trim them**.

## Keywords (100, comma-separated, no spaces)

```
reps,barbell,sets,strength,lifting,weights,routine,history,rest,timer,personal,record,pr,load,1rm
```

97 bytes. Behavior and category terms are deduplicated against `Progressive Overload`, `Gym`, `Workout`, `Log`, and `Tracker` in the name and subtitle. The field supports combinations including reps tracker, barbell tracker, set tracker, rest timer, personal record, PR tracker, load tracker, and 1RM tracker.

## What's New — v2.1

```
Unit 2.1 adds transparent progressive overload without slowing down your workout.

• See your suggested next target as soon as an exercise is done
• Increase reps, then weight, using your own rep range and increment
• Accept, repeat, or edit every suggestion after your workout
• New workout screen: every exercise on one page, one tap per set, 5-second undo
• New Analytics tab for your main lifts
• Faster setup: three steps from install to your program
• Rest timer adjusts by 30 seconds; drag to reorder exercises
```

## Screenshots

The old screenshot set does not support the new App Store name. Capture and upload a new English set before submission, in this order:

1. `Know what to lift next` — real post-workout recommendation with previous target, next target, reason, and action.
2. `Log a set in 3 seconds` — active workout with accepted target and Last time.
3. `Hit 10 reps. Add 5 lb.` — real accepted double-progression result with previous and next targets.
4. `Paste your plan or choose one` — beginner-inclusive setup paths.
5. `See your strength go up` — exercise progress and history.
6. `Rest timer on your Lock Screen` — verified Live Activity.

Screenshots must use production data and names, not the Progression QA harness.

## Reviewer notes (App Review Information → Notes)

```
Unit 2.1 is a local-first gym logger with optional transparent double progression. Workout logging requires a paid purchase. Onboarding is free: the reviewer can complete the opener, value carousel and full program setup without paying. After setup is saved, a full-screen paywall appears and cannot be dismissed.

To evaluate:
1. Open the app: a short opener, a three-slide carousel with "Set up your program", then three setup steps: choose a path (paste a program, or answer three questions to match a ready-made one), set up the program, review it. The weight unit comes from the device region and can be changed on review or in Settings. No personal information is requested.
2. The paywall offers Weekly com.unit.weekly $2.99/week, Monthly com.unit.monthly $4.99/month, Yearly com.unit.annual $29.99/year, and Lifetime com.unit.lifetime $44.99 when StoreKit returns it. Yearly is preselected when the customer is eligible for its introductory offer; otherwise Weekly is preselected. All plans stay visible. There is no "Not now"; the only ways out are a purchase or closing the app.
3. Use a fresh sandbox Apple Account that has not redeemed an introductory offer in this subscription group. Yearly has a 1-week free trial. The headline shows the price and free period together ("$29.99/year after 7 days free"), and the billed amount stays above the button with trial length, renewal price, auto-renewal and cancel-via-App-Store copy. Tap Start free trial and confirm Apple's sheet; a verified purchase unlocks Today. Free-trial wording appears only for a product with a free introductory offer and only when StoreKit reports eligibility; otherwise plain prices are shown. Weekly never shows a trial. Log a set: the rest timer starts and appears on the Lock Screen and Dynamic Island.
4. Cancel: Settings (visible when entitled) > Manage Subscription. Lifetime has no Manage Subscription row.

Progressive overload is optional and set per routine and exercise. It evaluates completed straight working sets at one load. When every planned set is logged, the exercise card shows the suggested next target (read-only). After Finish, the summary shows the next target and its reason; the user explicitly uses, repeats or edits it. Unit never rewrites the routine automatically and never interrupts set logging. Mixed loads, incomplete sets, invalid increments and unsupported bodyweight sessions get an explanation instead of a target.

Engagement prompts count only workouts completed in this version:
- After the first workout summary closes, one standard StoreKit review request (iOS may suppress it).
- The third workout summary shows a one-time "Help improve Unit" card: "Book a 15-minute call" opens https://calendar.notion.so/meet/efbakir/unit-feedback and "Email feedback" opens an email to support@unitlift.app.
- Neither appears during a workout or repeats.

Workout data stays on-device (SwiftData). With the person's consent, Unit sends a small allowlist of anonymous product-interaction and purchase-state events through TelemetryDeck with a hashed device identifier, not linked to identity and not used for tracking. Anonymous analytics is off by default and nothing is sent until the person turns it on (Guideline 5.1.1(ii)). The switch is on the first setup step and in Settings > Preferences > Anonymous analytics; the paywall footer shows it only while it is on, so it can be turned off before purchase. Unit works fully offline.

Questions during review: support@unitlift.app.
```

## Subscription group + products (ASC display fields)

Group: reference name `unit-pro` (immutable) · display name `Unit Pro`.

| Product ID | Display name (≤30) | Description (≤45) | Price (USD base) | Introductory offer |
|---|---|---|---|---|
| `com.unit.weekly` | `Unit Weekly` | `Weekly access to Unit.` | **$2.99** (ineligible default) | None |
| `com.unit.monthly` | `Unit Monthly` | `Monthly access to Unit.` | $4.99 | One-week Free offer; founder must configure in ASC |
| `com.unit.annual` | `Unit Yearly` | `Yearly access to Unit.` | $29.99 (eligible default) | One-week Free offer; founder must configure in ASC |
| `com.unit.lifetime` | `Unit Lifetime` | `One-time purchase. Lifetime access.` | $44.99 (optional — only if already configured) | None |

Pricing authority: `docs/pricing.md`. Product IDs never change. The app supports the Monthly and Yearly offers above, but this document does not claim they are configured in App Store Connect. Confirm both there and in an Apple sandbox purchase before release.

## URLs / fixed fields

| Field | Value |
|---|---|
| Support URL | `https://unitlift.app/support` |
| Marketing URL | `https://unitlift.app` |
| Privacy Policy URL | `https://unitlift.app/privacy` |
| Category | Health & Fitness |
| Age rating | 4+ |
| Copyright | 2026 Efe Bakir |

## What's New history

**v1.1 — prepared, never shipped** (ASC shows 1.0 as the only released version; verified live 2026-07-11): PR badges in History; paste import reads table-style + Turkish programs; onboarding day-count 1–7, keyboard fix, force-quit crash fix; stray Done button removed; Start workout only on Today. Fold anything still relevant into the v2.0 notes if wanted.
**v1.0 (live):** "Unit is here. Log your sets in one tap, import your program from Notes, and track your progress — all without leaving the gym floor."

## Voice rules (apply to every field above)

First-person singular only (`I / me / my`) — never `we / us / our` (PRODUCT.md §Brand Personality). Trial language is allowed only when it accurately reflects verified StoreKit offer metadata and customer eligibility; no countdown, fake discount, or urgency language. Progression claims may describe only the shipped, transparent double-progression behavior and must not imply AI coaching, program generation, recovery adaptation, or automatic control.
