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

Captions + per-slot image specs: **`docs/app-store-copy.md` §Screenshot captions**. Two recaptures are planned (slot 2: preview-after-paste; slot 5: Lock Screen rest timer — currently a duplicate of slot 4). Screenshots never block the binary upload: if the recaptures aren't ready at submission, **reuse the 5 approved English screenshots currently live** (strategy (b) — reviewer notes carry the paywall story) and swap shots in a later metadata update. Do not localize screenshots for this submission.

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
