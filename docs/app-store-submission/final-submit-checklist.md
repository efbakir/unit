# Final submit checklist — Unit v2.1 (build 58)

> The ASC handoff package. Everything below is paste-exact for App Store Connect; nothing requires a code change.
> Updated 2026-07-23 for the recovered v2.1 release. Companions: `docs/pricing.md` (pricing truth) and `docs/release-qa.md` (device gauntlet).

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
| Build | **58** | `CURRENT_PROJECT_VERSION = 58` in all 8 pbxproj configs |
| Archive source | tagged `main` | clean tree, local `main` equals `origin/main`, tag `v2.1-build58` points at the archived commit |

## 2. App name

Paste **`Unit: Gym Workout Log`** exactly from **`docs/app-store-copy.md` §App name**. Home-screen icon stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`).

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

- [ ] Inherit the five currently approved screenshots.
- [ ] Keep their current order.
- [ ] Do not replace, reorder, or localize screenshots for 2.1.

## 7. IAP / subscription attachment checklist

- [ ] Business → Agreements: **Paid Applications agreement active** (not "Pending"). Blocks everything if not.
- [ ] Features → Subscriptions → `unit-pro` group exists with the 3 auto-renewables (§3 IDs and prices exact).
- [ ] Each product has an English display name + description and a **review screenshot** (one capture of `PaywallView` covers all).
- [ ] App Store tab → version 2.1 → In-App Purchases and Subscriptions → **attach Weekly, Monthly, Yearly** (+ Lifetime if configured).
- [ ] Build 58 attached to the version.

## 8. Localization

- [ ] PRO-32 is Done.
- [ ] `npm run test:localizations` passes after all reviewer edits.
- [ ] `docs/app-store-localization/asc-execution-status.md` records approval for de-DE, es-MX, pt-BR, fr-FR, and tr.
- [ ] Add all five approved metadata locales before submission.
- [ ] Keep the in-app UI and inherited screenshots English.
- [ ] Do not paste any locale still marked pending.

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
- [ ] Xcode Settings shows **Version 2.1 (58)**.
- [ ] `git status --short` is empty and local `main` equals `origin/main`.
- [ ] Tag `v2.1-build58` points at the exact commit being archived.
- [ ] Archive from clean tagged `main` only.
- [ ] Known site inconsistency (not an archive blocker, fix before marketing push): `app/(marketing)/compare/data.ts` still says "Core logging is free forever. Pro is $4.99/mo or $29.99/yr." in 3 rows, and `app/(marketing)/page.tsx` has one "Free. No account. No ads." eyebrow. Both contradict the hard paywall on the live site.
