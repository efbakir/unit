# Unit — App Store copy (canonical)

> **FROZEN 2026-07-11 — founder-approved.** The single source of truth for every App Store Connect text field; if a string isn't here, it isn't canon. Any change after the freeze requires a decision-log entry and re-stales the five locale files (regeneration list: `docs/app-store-localization/asc-execution-status.md`).
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
Strength tracker for lifters
```

Why: the new app name already owns *gym, workout, log* — Apple ignores duplicated keywords across name/subtitle, so the subtitle must add fresh terms. This adds *strength, tracker, lifters*. 28 chars.
Superseded alternates (git history): live v1 `Log a set in 3 seconds` (no new keywords), `Fast workout & strength log` (duplicates name terms), `Log every set in one tap.` (near-dupe of live).

## Promotional text (170, editable anytime without review)

```
You already know your program. Unit logs it faster than paper — last time's numbers are already filled in, every set one tap. No AI. No social. Just your numbers.
```

Evergreen (reads right for cold visitors after launch week too). Update-announcement variants belong in What's New, not here.

## Description (4000)

```
Log a set in 3 seconds and get back under the bar.

Your weights from last time are already filled in — confirm, adjust, done. Paste your program and your working numbers are ready from day one.

No account. No ads. No social feed. Your training stays on your iPhone.

A gym notebook, not a platform.

Unit requires a paid purchase after setup. Weekly, monthly, and yearly auto-renewing subscriptions are available. Optional Lifetime appears only if available. Prices are shown in the app before purchase. There is no free trial.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://unitlift.app/privacy
```

Short on purpose: iOS descriptions are conversion-only (not search-indexed) and only ~3 lines show before "more". The paid-purchase paragraph + both legal URLs are Guideline 3.1.2(b) compliance — **never trim them**.

## Keywords (100, comma-separated, no spaces)

```
lifting,rest,timer,set,rep,counter,weights,reps,training,routine,progressive,overload,history,notes
```

99 chars. Founder-corrected 2026-07-11 post-freeze (see decision log): dropped the narrow style terms (*powerlifting, barbell, 5x5, hypertrophy, squat*) for behavior and feature terms lifters actually search. Still deduped against name (*gym, workout, log*) and subtitle (*strength, tracker, lifters*) — duplicates index once, so every slot here adds a new term.

## What's New — v2.0

```
• Log a set in 3 seconds — last time's weights are already filled in
• Paste your program and start with real working numbers from day one
• Rebuilt first run: from install to your program built in under a minute

Unit now requires a paid purchase after setup — plans are shown before you pay. No free trial. Existing training data stays on this iPhone.
```

The paid paragraph is deliberate: v1 users read What's New before updating, and this is the only channel that warns them about the wall. The data-stays line is the reassurance that matters to them.

## Screenshot captions (5 slots — caption is the only text on the shot)

| # | Caption | Image |
|---|---|---|
| 1 | `3 seconds, back under the bar` | ✅ live — logging screen, last time's weights pre-filled, one set ticked |
| 2 | `Paste your program, start lifting` | ⚠️ recapture — program preview right after a paste import (days + exercises + weights filled). Current shot shows the set editor, which doesn't match the caption |
| 3 | `No account. Works offline.` | ✅ live — no-signup proof + "Stored on this iPhone"; airplane glyph as quiet secondary |
| 4 | `A notebook, not a feed` | 🟡 acceptable (History calendar) once #5 stops duplicating it; stronger alternative: the calm Today screen |
| 5 | `Your rest timer, on the lock screen` | ⚠️ recapture — real Lock Screen with the rest-timer Live Activity counting down. Current shot duplicates #4's calendar |

Screenshots don't block the binary upload. If recaptures aren't ready at submission, reuse the current approved set (strategy (b): reviewer notes carry the paywall story) and swap shots in a later metadata update.

## Reviewer notes (App Review Information → Notes)

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
