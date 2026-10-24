> **2026-10-23: build 95 is attached to version 2.1, not submitted.** Built from `claude/app-finalization-launch-34a116` (tag `v2.1-build95`), which contains the build-90 phone state plus the finalization changes in `docs/handoffs/2026-10-23-app-finalization.md`. Release type: manual. Build 96 replaces it once the celebration look and the screenshot set are picked: it adds the new celebration, delete buttons in the main-lift editor, a VoiceOver fix on main-lift cards, and a large set-count picker. Sections below that mention builds 66–68 are history.
>
> Builds 94 to 96 differ from the August checklist in four ways that matter for review: (1) the trial button says "Start free trial" and the line above it leads with the billed price; (2) there is no paid-access line under "Set up your program" (founder decision 2026-10-23); (3) Yearly is preselected for trial-eligible customers, Weekly for everyone else, and the trial reminder defaults on; (4) setup is three steps (path, program, review). The reviewer notes in `docs/app-store-copy.md` describe this build.
>
> Still not done by a person: the physical-device sandbox purchase test (§4, §11) and the device gauntlet in `docs/release-qa.md`. Founder action before tapping Release.
>
> History: **October 19 development checkpoint:** The connected phone started on 2.1 (65); this isolated release branch targets **2.1 (68), development-only and unreserved**. Public lookup still reports 2.0. Live App Store Connect build numbers could not be read, so do not upload or attach 68 until the highest uploaded number is checked. The August status and build-67 checklist below are historical, not current release proof. See `docs/handoffs/2026-10-19-unit-motion-release.md` for this pass and its evidence.

# Final submit checklist — Unit v2.1 (build 95)

> The ASC handoff package. Copy fields are paste-exact; the introductory offers require the founder actions in §4 before submission.
> Updated 2026-08-04 for the progression-guided v2.1 release. Companions: `docs/pricing.md` (pricing truth) and `docs/release-qa.md` (device gauntlet).

**ASC status — 2026-10-23:** Version 2.1 has build 95 attached and is not submitted. Release type is manual. Source is `claude/app-finalization-launch-34a116` at tag `v2.1-build95`. `CURRENT_PROJECT_VERSION` is still 95. The next upload is build 96, bumped when that archive is cut, not in the review-fix diff. Yearly is the trial-eligible default. Weekly is the default when StoreKit reports no introductory-offer eligibility. The purchase button is **Start free trial** on an eligible Yearly plan, not "Continue with Weekly".

**History — 2026-08-10:** The draft then had no build attached. Monthly and Yearly each had a one-week Free introductory offer. Build 66 was to stay unattached. That note is not the current archive instruction.

---

## 0. Warnings — read before touching ASC

- **Trial is not release-ready yet.** The app supports a seven-day offer, but App Store Connect must carry the matching Monthly and Yearly offers and an Apple sandbox purchase sheet must confirm the free period before submission.
- **No permanent free tier.** Unit remains a hard paywall after onboarding. Weekly and Lifetime have no introductory offer.
- **Paid access shows at the paywall, not before setup.** The founder removed the onboarding line on 2026-10-23 (supersedes 2026-08-05). The App Store description states the subscription, and the paywall shows every plan and price before purchase.
- **No fake prices.** Every visible in-app price is StoreKit-derived. ASC product config is the only place prices exist.
- **Do not select build 66 or build 67.** Build 95 is the attached build. The next archive is 96 from this release branch, after `CURRENT_PROJECT_VERSION` is bumped.
- **The app UI is English-only.** Do not claim or imply localization anywhere. Localized *metadata* is a separate, optional step (§8).
- **Product IDs are immutable.** If any ASC screen asks you to create a product, you are on the wrong screen.

## 1. Version / build

| Field | Value | Verified |
|---|---|---|
| Marketing version | **2.1** | `MARKETING_VERSION = 2.1` in all 8 pbxproj configs |
| Build | **95** | `CURRENT_PROJECT_VERSION = 95` in all 8 pbxproj configs. Bump to 96 only when cutting the next archive. |
| Archive source | `claude/app-finalization-launch-34a116` | tag `v2.1-build95` is the attached build. Do not archive from `main`. |

## 2. App name

Paste **`Unit: Progressive Overload`** exactly from **`docs/app-store-copy.md` §App name**. Home-screen icon stays `Unit` (`INFOPLIST_KEY_CFBundleDisplayName`).

## 3. Subscription products (must match exactly)

Group: reference name `unit-pro`, display name `Unit Pro`.

| Product | Product ID | Type | Price (USD base) |
|---|---|---|---|
| Weekly — **ineligible default** | `com.unit.weekly` | Auto-renewable, 1 week | **$2.99** |
| Monthly | `com.unit.monthly` | Auto-renewable, 1 month | **$4.99** |
| Yearly — **eligible default** | `com.unit.annual` | Auto-renewable, 1 year | **$29.99** |
| Lifetime (optional) | `com.unit.lifetime` | Non-consumable | **$44.99** |

- [ ] Confirm Weekly reads **$2.99** in ASC (the 2026-07-02 change). If it reads $4.99, fix before anything else.
- [ ] All prices automatically generated from the USD base — no custom storefront prices.
- [x] Monthly and Yearly each have the one-week Free introductory offer described in §4.
- [x] Weekly and Lifetime have no introductory offer.
- [ ] Lifetime: only if the non-consumable is already configured. Do not create it for this submission.

## 4. Introductory-offer setup — founder action

- [x] Open Features → Subscriptions → the Unit subscription group in App Store Connect.
- [x] Open Monthly (`com.unit.monthly`) and add a **one-week Free** introductory offer.
- [x] Open Yearly (`com.unit.annual`) and add a **one-week Free** introductory offer.
- [x] Apply both offers to all 175 storefronts, starting August 10, 2026 with no end date.
- [x] Confirm Weekly (`com.unit.weekly`) has no introductory offer.
- [x] Confirm Lifetime (`com.unit.lifetime`) has no introductory offer.
- [ ] Wait for the StoreKit sandbox configuration to propagate.
- [ ] Test with a fresh sandbox customer who has never redeemed an introductory offer in this subscription group.
- [ ] Confirm Apple's purchase sheet itself displays the seven-day free period and correct post-trial price for Monthly, then repeat the sheet check for Yearly with another fresh eligible sandbox customer if needed.

Apple allows one introductory-offer redemption per customer per subscription group. Do not expect one customer to redeem both the Monthly and Yearly trials. See Apple's [StoreKit implementation guide](https://developer.apple.com/documentation/storekit/implementing-introductory-offers-in-your-app) and [App Store Connect setup guide](https://developer.apple.com/help/app-store-connect/manage-subscriptions/set-up-introductory-offers-for-auto-renewable-subscriptions/).

## 5. Reviewer notes

Paste verbatim from **`docs/app-store-copy.md` §Reviewer notes** into App Review Information → Notes. ($2.99 Weekly price is correct there.)

## 6. English metadata

Paste every field verbatim from **`docs/app-store-copy.md`** — subtitle, promotional text, description, keywords, What's New. That file is the single copy source; this checklist deliberately embeds no strings so they can't drift.

The description's paid-purchase paragraph and the two legal URLs are Guideline 3.1.2(b) compliance — never trim them.

## 7. Screenshot set

- [ ] Upload the new English progression screenshot set defined in `docs/app-store-copy.md`.
- [ ] Keep the canonical order: next target, 3-second log, reps-then-weight, program setup, progress history, Lock Screen timer.
- [ ] Confirm the first screenshot proves the new progressive-overload promise.
- [ ] Do not swap the first two screenshots for submission. Speed-first is the post-launch PPO treatment in `docs/app-store-assets/2.1/ppo-plan.md`.
- [ ] Do not use screenshots from the Progression QA harness.

## 8. IAP / subscription attachment checklist

- [ ] Business → Agreements: **Paid Applications agreement active** (not "Pending"). Blocks everything if not.
- [ ] Features → Subscriptions → `unit-pro` group exists with the 3 auto-renewables (§3 IDs and prices exact) and the §4 offers.
- [ ] Each product has an English display name + description and a **review screenshot** (one capture of `PaywallView` covers all).
- [ ] App Store tab → version 2.1 → In-App Purchases and Subscriptions → **attach Weekly, Monthly, Yearly** (+ Lifetime if configured).
- [x] Build 95 is attached to version 2.1. Builds 66 and 67 stay unattached. The next upload is build 96.

## 9. Localization

- [ ] Ship 2.1 English-only.
- [ ] Do not paste or publish de-DE, es-MX, pt-BR, fr-FR, or tr. All five files are explicitly stale after the beginner-inclusive English rewrite.
- [ ] Do not add Turkish UI localization or regenerate translations for 2.1.

## 10. Privacy / age rating / URLs

- [x] App Privacy: declare **Device ID**, **Product Interaction**, and **Purchase History** for Analytics; all three are not linked to identity and not used for tracking. Do not declare workout content.
- [x] TelemetryDeck app identifier is stored locally in the git-ignored `Config/TelemetryDeck.private.xcconfig`; it is not committed to source.
- [ ] Archive with `-xcconfig Config/TelemetryDeck.private.xcconfig`, then confirm the archived app's `TelemetryDeckAppID` is a non-empty UUID before upload.
- [ ] Settings → Anonymous analytics disables future events immediately.
- [x] Age rating: **4+** (all questionnaire categories None/No).
- [ ] Encryption: **No** (`ITSAppUsesNonExemptEncryption = false` in Info.plist).
- [ ] Privacy Policy URL: `https://unitlift.app/privacy` — returns 200.
- [ ] Support URL: `https://unitlift.app/support` — returns 200.
- [ ] Marketing URL: `https://unitlift.app` — returns 200.
- [ ] Copyright: `2026 Efe Bakir`.
- [ ] First-person check on any copy you edited: no `we / us / our`.

## 11. Pre-archive gate (before Product → Archive)

- [ ] StoreKit sandbox QA — every step in `docs/pricing.md` §StoreKit sandbox verification checklist, on this exact build, with sandbox Apple IDs.
- [ ] Apple's purchase sheet confirms the seven-day free period and correct renewal price for Monthly and Yearly; do not infer this from the in-app paywall alone.
- [ ] `docs/release-qa.md` gauntlet run on device.
- [ ] Xcode Settings shows **Version 2.1 (95)** until the next archive bumps it to 96.
- [ ] `git status --short` is empty on `claude/app-finalization-launch-34a116` (or the review-fix branch cut from it).
- [ ] Tag `v2.1-build95` points at the commit already attached. Tag the next archive `v2.1-build96` only after the build number bump.
- [ ] Archive from that release branch. Do not archive from `main`.
- [ ] Marketing-site pricing and privacy copy matches the hard paywall, conditional seven-day offer, and anonymous-analytics disclosure in this build.

Scope remains frozen for 2.1: no additional ASO keywords, social features, coaching, Apple Watch expansion, or broader discovery work.
