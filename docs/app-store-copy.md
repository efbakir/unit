# Unit — App Store copy (canonical)

> **FROZEN 2026-07-23 FOR VERSION 2.1 — founder-approved.** The single source of truth for every App Store Connect text field; if a string isn't here, it isn't canon. The five locale files are stale for 2.1 and must not be published without a new native review.
> Process (what to click, in what order): `docs/app-store-submission/final-submit-checklist.md`.
> Localized metadata derives from this file — see `docs/app-store-localization/README.md`.
> Consolidated 2026-07-11 from `docs/marketing/app-store-copy.md` (deleted), the old draft here, and `source-en.md`. Conflicting variants live in git history only.

---

## App name (30)

```
Unit: Gym Workout Log
```

21 chars. Locked 2026-07-11 (ASO over brand), superseding `Unit: Gym Notebook`. **Separator resolved to the colon** (2026-07-11, see decision log): identical keyword indexing either way, but the colon is the category norm, scans better at list size, and matches how the live 1.0 listing already renders (`Unit: Gym Notebook`). Home-screen icon stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`).
Locale names take the same separator — flagged for the next locale regeneration pass (do not edit locale files outside that pass).

## Subtitle (30)

```
Simple strength tracker
```

Inclusive positioning for beginner-to-experienced gym users. It describes the product without implying that users must already have a program.

## Promotional text (170, editable anytime without review)

```
Choose a ready-made program or paste your own. Last time’s weights are filled in, every set takes one tap, and the rest timer starts automatically.
```

Evergreen (reads right for cold visitors after launch week too). Update-announcement variants belong in What's New, not here.

## Description (4000)

```
Log a set in 3 seconds and get back to your workout.

Choose a ready-made program or paste your own. Unit keeps your last weights ready, so each set is quick to confirm or adjust.

• One-tap set logging
• Ready-made programs
• Paste any routine
• Automatic rest timer on the Lock Screen
• Workout history and personal records

No account. No ads. No social feed. Your training stays on your iPhone.

Unit requires a paid purchase after setup. Weekly, monthly, and yearly auto-renewing subscriptions are available. Optional Lifetime appears only if available. Prices are shown in the app before purchase. There is no free trial.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://unitlift.app/privacy
```

Short on purpose: iOS descriptions are conversion-only (not search-indexed) and only ~3 lines show before "more". The paid-purchase paragraph + both legal URLs are Guideline 3.1.2(b) compliance — **never trim them**.

## Keywords (100, comma-separated, no spaces)

```
beginner,program,routine,lifting,rest,timer,weights,reps,training,progress,history,sets
```

Beginner-inclusive feature and behavior terms, deduped against the app name and subtitle.

## What's New — v2.1

```
Unit 2.1 makes setup and logging clearer.

• Choose a ready-made program or paste your own
• Improved workout logging and bodyweight history
• Better purchase handling and reliability fixes
```

## Screenshots

Keep the five currently approved screenshots in their current order for 2.1. Do not replace, reorder, or localize them in this submission. The English metadata follows their existing speed, program-import, privacy, notebook, and rest-timer story.

## Reviewer notes (App Review Information → Notes)

```
Unit v2 is a local-first gym logger for iPhone. It requires a paid purchase to access the workout-logging features. Onboarding runs free — the reviewer can complete the opener, the three-slide carousel, and the full program setup flow without paying. After setup is saved, the paywall appears full-screen and cannot be dismissed.

To evaluate:
1. Open the app. Onboarding starts with a standalone opener, then a three-slide value carousel with the "Set up your program" CTA, then program setup. No personal information is requested.
2. After onboarding completes, the paywall appears with these StoreKit products: Weekly com.unit.weekly $2.99/week, Monthly com.unit.monthly $4.99/month, Yearly com.unit.annual $29.99/year, and Lifetime com.unit.lifetime $44.99 one-time only if that non-consumable is configured and returned by StoreKit. Weekly is selected by default. There is no "Not now" affordance; the only ways out are to purchase through StoreKit sandbox or close the app.
3. Subscribe to any recurring tier, or buy Lifetime if visible, via the sandbox account. The paywall dismisses and the Today tab unlocks. Log a set; the rest timer starts automatically and appears on the Lock Screen / Dynamic Island.
4. To verify cancellation flow for subscriptions: Settings (visible only when entitled) → Manage Subscription → cancel. Lifetime entitlement has no Manage Subscription row because it is a one-time purchase.

Engagement prompts in version 2.1 count only workouts completed after installing this version:
- After the first new completed workout, close its workout summary. Two seconds after Today is active, Unit makes one standard StoreKit review-request attempt. iOS may suppress the visible prompt.
- On the third new completed workout’s summary, Unit shows a one-time “Help improve Unit” card. “Book a 15-minute call” opens https://calendar.notion.so/meet/efbakir/unit-feedback and “Email feedback” opens a prefilled email to support@unitlift.app.
- Neither prompt appears during an active workout. Both attempt/shown states persist locally and do not repeat.

There is no free trial. Apple Guideline 3.1.2(b) disclosure is satisfied: each tier card shows product title, full StoreKit price, and billing period; the selected billed amount remains visible directly above the CTA; auto-renewal and cancel-via-Settings copy is on the paywall itself. No deceptive trial framing.

The app does not collect, transmit, or store any personal data. All workout data lives on-device via SwiftData. The PrivacyInfo manifest declares only UserDefaults (reason CA92.1 — app functionality). Privacy is verifiable offline: post-subscription, put the device in airplane mode and every feature still works.

If you have questions during review, please email support@unitlift.app.
```

## Subscription group + products (ASC display fields)

Group: reference name `unit-pro` (immutable) · display name `Unit Pro`.

| Product ID | Display name (≤30) | Description (≤45) | Price (USD base) |
|---|---|---|---|
| `com.unit.weekly` | `Unit Weekly` | `Weekly access to Unit.` | **$2.99** (default selection) |
| `com.unit.monthly` | `Unit Monthly` | `Monthly access to Unit.` | $4.99 |
| `com.unit.annual` | `Unit Yearly` | `Yearly access to Unit.` | $29.99 |
| `com.unit.lifetime` | `Unit Lifetime` | `One-time purchase. Lifetime access.` | $44.99 (optional — only if already configured) |

Pricing authority: `docs/pricing.md`. Product IDs never change. No introductory offers — there is no trial.

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

First-person singular only (`I / me / my`) — never `we / us / our` (PRODUCT.md §Brand Personality). No trial/discount/urgency language anywhere. No coaching or progression claims.
