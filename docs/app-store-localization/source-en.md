# Tier 0 — English source of truth (en-US)

> Canonical strings every translation derives from. Consolidates `docs/marketing/app-store-copy.md` (paste-ready v2) + the v2 override in `docs/archive/marketing/asc-submission.md`. If those change, this file and all locale files are stale.
> Field limits: name 30 · subtitle 30 · promo 170 · description 4000 · keywords 100 (comma-separated, no spaces) · subscription display name 30 · subscription description 45.

## App name (30)

```
Unit — Gym Workout Log
```

Locked 2026-07-11 (ASO over brand; see `docs/decision-log.md`), superseding `Unit — Gym Notebook`. Locale files localize the suffix, never "Unit" — the existing localized names already target log/diary search terms, so they stand unchanged.

## Subtitle (30)

```
Fast workout & strength log
```

Live v1 subtitle is `Log a set in 3 seconds`; the string above is the v2 paste-ready pick.

## Promotional text (170)

```
New in v2: paste your program and start with real working numbers from day one. Still no account, no ads — just fast logging that lives on your iPhone.
```

## Description (4000)

```
Log a set in 3 seconds and get back under the bar.

Your weights from last time are already filled in — confirm, adjust, done. Paste any program and your working numbers are ready from day one.

No account. No ads. No social feed. Your training stays on your iPhone.

A gym notebook, not a platform.

Unit requires a paid purchase after setup. Weekly, monthly, and yearly auto-renewing subscriptions are available. Optional Lifetime appears only if available. Prices are shown in the app before purchase. There is no free trial.

Terms of Use (EULA): https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
Privacy Policy: https://unitlift.app/privacy
```

## Keywords (100)

```
lifting,tracker,powerlifting,exercise,routine,reps,barbell,fitness,training,planner,5x5,hypertrophy
```

## What's New — v2 (4000)

```
• Log a set in 3 seconds — last time's weights are already filled in
• Paste any program and start with real working numbers from day one
• Rebuilt first run: from install to your first logged set in under a minute
```

## URLs (per-locale fields in ASC; same values everywhere)

| Field | Value |
|---|---|
| Support URL | `https://unitlift.app/support` |
| Marketing URL | `https://unitlift.app` |
| Privacy Policy URL | `https://unitlift.app/privacy` |

The site is English-only; URLs stay identical in every locale.

## Subscription group

| Field | Value |
|---|---|
| Reference name (immutable) | `unit-pro` |
| Display name (localizable) | `Unit Pro` |

## Subscription products (display name ≤30 / description ≤45)

| Product ID | Display name | Description |
|---|---|---|
| `com.unit.weekly` | `Unit Weekly` | `Weekly access to Unit.` |
| `com.unit.monthly` | `Unit Monthly` | `Monthly access to Unit.` |
| `com.unit.annual` | `Unit Yearly` | `Yearly access to Unit.` |
| `com.unit.lifetime` | `Unit Lifetime` | `One-time purchase. Lifetime access.` |

Matches `Unit/Unit.storekit` dev config. Product IDs never change.

## Screenshot captions (5 slots, from `docs/marketing/app-store-copy.md`)

1. `3 seconds, back under the bar`
2. `Paste your program, start lifting`
3. `No account. Works offline.`
4. `A notebook, not a feed`
5. `Your rest timer, on the lock screen`

## Reviewer notes

English only — see the v2 reviewer notes block in `docs/archive/marketing/asc-submission.md` §v2 SUBMISSION OVERRIDE. Not localized by design.
