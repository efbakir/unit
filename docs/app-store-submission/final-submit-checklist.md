# Final submit checklist — Unit v2.1 (build 36)

> The ASC handoff package. Everything below is paste-exact for App Store Connect; nothing requires a code change.
> Updated 2026-07-22 for the recovered v2.1 release. Companions: `docs/pricing.md` (pricing truth), `docs/app-store-localization/asc-paste-checklist.md` (optional localized metadata), `docs/release-qa.md` (device gauntlet).

---

## 0. Warnings — read before touching ASC

- **No trial.** Nothing in metadata, reviewer notes, or product config may mention a free trial. There is none.
- **No fake prices.** Every visible in-app price is StoreKit-derived. ASC product config is the only place prices exist.
- **The app UI is English-only.** Do not claim or imply localization anywhere. Localized *metadata* is a separate, optional step (§8).
- **Product IDs are immutable.** If any ASC screen asks you to create a product, you are on the wrong screen.

## 1. Version / build

| Field | Value | Verified |
|---|---|---|
| Marketing version | **2.1** | `MARKETING_VERSION = 2.1` in all 8 pbxproj configs |
| Build | **36** | `CURRENT_PROJECT_VERSION = 36` in all 8 pbxproj configs |
| Archive source | tagged `main` | clean tree, local `main` equals `origin/main`, tag `v2.1-build36` points at the archived commit |

## 2. App name

Paste from **`docs/app-store-copy.md` §App name** (the single copy source). Separator (em-dash vs colon) is cosmetic and founder-picked at paste time — the note there covers it. Home-screen icon stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`) either way.

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

## 4. Reviewer notes

Paste verbatim from **`docs/app-store-copy.md` §Reviewer notes** into App Review Information → Notes. ($2.99 Weekly price is correct there.)

## 5. English metadata

Paste every field verbatim from **`docs/app-store-copy.md`** — subtitle, promotional text, description, keywords, What's New. That file is the single copy source; this checklist deliberately embeds no strings so they can't drift.

The description's paid-purchase paragraph and the two legal URLs are Guideline 3.1.2(b) compliance — never trim them.

## 6. Screenshot set

Captions (the only text on each frame): **`docs/app-store-copy.md` §Screenshot captions**. Raw captures go through the existing Figma marketing file and export at **1290×2796** to match the three keepers. Screenshots never block the binary upload: if the recaptures aren't ready at submission, reuse the 5 approved live screenshots (strategy (b) — reviewer notes carry the paywall story) and swap in a later metadata update. Do not localize screenshots for this submission.

### Capture runbook — where each shot lives

**Prep (once).** Capture on the **iPhone 17 Pro Max simulator** (raw size differs from 1290×2796; the Figma export normalizes it). Clean the status bar first:
`xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100 --cellularBars 4 --wifiBars 3`
Simulator screenshot = **⌘S** (saves to Desktop).

| Slot | Status | Screen ("where it is") | How to reach the state |
|---|---|---|---|
| 1 | ✅ keep | Active workout — command card | Already live. Only recapture if you want fresher numbers: purchased sim → Today → Start workout → first exercise shows "Last …" pre-fill with one set already ticked. |
| 2 | 🔴 recapture | **Onboarding program preview** ("Summary") — days + exercises + weights parsed from a paste | Needs a **fresh install** (onboarding only shows when no program exists): spare simulator → delete Unit → ⌘R → carousel → kg → "Paste my routine" → paste the demo program below → Read program → schedule → **capture the preview screen**. Free surface — no purchase needed. Don't tap "Save my program". |
| 3 | ✅ keep | Hand-held composition (no-account badges) | Already live. No capture. |
| 4 | ✅ keep | History calendar | Already live. No capture. |
| 5 | 🔴 recapture | **Lock Screen — rest-timer Live Activity** counting down | Purchased sim (or real device) → Today → Start workout → complete one set (timer auto-starts) → **⌘L** to lock → wait for the Live Activity card on the Lock Screen → ⌘S while the countdown shows a mid-range value (1:53-ish reads better than 0:0x). If the sim won't render the Live Activity, use the real iPhone: same flow, Side + Vol-Up on the Lock Screen. Optional bonus: unlock and grab the Dynamic Island variant. |

**Demo program for slot 2's paste** (marketing-quality numbers, kg):

```
Push
Bench Press 4x8 80
Overhead Press 3x10 40
Incline DB Press 3x10 24

Pull
Deadlift 3x5 140
Barbell Row 4x8 70
Lat Pulldown 3x10 55

Legs
Back Squat 3x5 120
Romanian Deadlift 3x10 90
Leg Press 3x10 160

> No line may be exactly **3x8** — the preview flags 3x8 as "Check sets and reps" (parser-default false positive) and the warning ruins the shot.
```

**After capture:** drop both raws into the Figma marketing file, apply the canonical captions (`Paste your program, start lifting` / `Your rest timer, on the lock screen`), export 1290×2796, upload to the 6.9" slot in ASC Media Manager replacing slots 2 and 5.

## 7. IAP / subscription attachment checklist

- [ ] Business → Agreements: **Paid Applications agreement active** (not "Pending"). Blocks everything if not.
- [ ] Features → Subscriptions → `unit-pro` group exists with the 3 auto-renewables (§3 IDs and prices exact).
- [ ] Each product has an English display name + description and a **review screenshot** (one capture of `PaywallView` covers all).
- [ ] App Store tab → version 2.1 → In-App Purchases and Subscriptions → **attach Weekly, Monthly, Yearly** (+ Lifetime if configured).
- [ ] Build 36 attached to the version.

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
- [ ] Xcode Settings shows **Version 2.1 (36)**.
- [ ] `git status --short` is empty and local `main` equals `origin/main`.
- [ ] Tag `v2.1-build36` points at the exact commit being archived.
- [ ] Archive from clean tagged `main` only.
- [ ] Known site inconsistency (not an archive blocker, fix before marketing push): `app/(marketing)/compare/data.ts` still says "Core logging is free forever. Pro is $4.99/mo or $29.99/yr." in 3 rows, and `app/(marketing)/page.tsx` has one "Free. No account. No ads." eyebrow. Both contradict the hard paywall on the live site.
