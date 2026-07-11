# App Store localization + regional pricing — strategy

> Decision doc + rollout plan. Written 2026-07-11. Supersedes the "defer localization until $5k MRR" line in `docs/archive/marketing/asc-submission.md` §Localization.
> Three separate tracks. Do not mix them: shipping track 1 does **not** mean the app is translated.

**The plan in one paragraph:** Localize App Store **metadata only**, in 5 languages (German, Spanish-MX, Portuguese-BR, French, Turkish), riding the v2 submission. Screenshots stay English. All prices stay on Apple's automatic conversion from the USD base — no custom storefront prices. The in-app UI stays English; UI localization is a separate future project with its own infra and QA gate. Every localized description states, honestly, that the app UI is in English.

---

## The three tracks

| Track | What it is | Status |
|---|---|---|
| 1. App Store metadata | Per-locale name, subtitle, description, keywords, promo text, What's New, subscription names/descriptions | **Do now** — Tier 1 copy is in this folder, ready for ASC |
| 2. In-app UI | `.xcstrings` String Catalog, translated `AppCopy.swift`, layout QA per language | **Not now** — binary has `knownRegions = (en, Base)`; zero localization infra exists. Tier 3 below. |
| 3. Regional pricing | Per-storefront prices for the 4 products | **No change** — keep Apple automatic conversion. See §Pricing. |

Rule from track separation: localized metadata must never claim or imply a translated app. Each Tier 1 description carries one line: *"the app interface is currently in English"* (localized). This costs some conversion but prevents 1-star "not in my language" reviews on a hard-paywall app, and it matches the brand (`PRODUCT.md` honest-simplicity).

---

## Rollout tiers

### Tier 0 — English (source of truth)

Canonical English strings live in [`docs/app-store-copy.md`](../app-store-copy.md) (single source of truth since 2026-07-11); [`source-en.md`](source-en.md) holds the derivation rules. All translations derive from the canonical file; when English changes, locale files are stale until re-derived (last re-derivation: 2026-07-11 — see [`asc-execution-status.md`](asc-execution-status.md)).

### Tier 1 — ship with v2 (metadata only)

| Locale | ASC language | Why in | Founder review |
|---|---|---|---|
| `de-DE` | German | Largest EU paid-fitness market, high willingness to pay, users search German ("Trainingstagebuch") | Native check needed |
| `es-MX` | Spanish (Mexico) | Covers Mexico + most Latin America storefronts; es-MX metadata is also keyword-indexed on the **US** storefront (bonus reach) | Native check needed |
| `pt-BR` | Portuguese (Brazil) | Brazil is a top-2 country by gym count; "ficha de treino" is an exact-match cultural concept for Unit | Native check needed |
| `fr-FR` | French | Large market, low English search tolerance, strong muscu niche vocabulary | Native check needed |
| `tr` | Turkish | Founder is a native speaker — zero review risk; parser already handles Turkish programs; near-zero cost | **Founder reviews directly** |

Five languages is the ceiling for one review pass. Each file in this folder = one ASC language, paste-ready.

### Tier 2 — later metadata languages (not produced yet)

| Locale | Why deferred |
|---|---|
| `it` | Good intent match ("scheda palestra" ≈ ficha de treino) but smaller market; add after Tier 1 shows installs |
| `es-ES` | es-MX already reaches LatAm; Spain-specific copy is a refinement, not a new market |
| `ja` | High willingness to pay, big market — but highest translation risk. Machine translation reads instantly wrong to natives. Gate: paid native translator, not a review pass. |
| `ko` | Same gate as Japanese (헬스/오운완 vocabulary needs a native) |

### Tier 3 — future in-app UI localization candidates

German, Portuguese-BR, Spanish, Turkish — decided by Tier 1 install data. Hard prerequisites before any UI translation:
1. String Catalog (`.xcstrings`) migration for `AppCopy.swift` + `DesignSystem.swift` strings.
2. Parser impact audit: exercise names, "BW", decimal commas, day-name matching (`ProgramImportParser` already handles Turkish text and `67,5` decimals — do not translate exercise names until the matching layer is audited).
3. Per-language layout QA (German strings run ~30% longer; button and tag truncation).
4. Native-speaker review of every string.

### Rejected (for now)

| Locale | Why out |
|---|---|
| `zh-Hans` | China mainland requires an ICP filing since 2024-03-31; without it the app cannot be listed there. Simplified-Chinese metadata would mostly serve a storefront Unit can't be on. Revisit only with a real China strategy. |
| `ja`, `ko` | Not rejected — deferred to Tier 2 behind a paid-native-translation gate. |

---

## What research established (verified 2026-07-11)

1. **Per-locale ASC fields:** name (30), subtitle (30), description (4000), keywords (100), promotional text (170), What's New, privacy-policy URL, screenshots, app previews. Adding a language pre-fills screenshots and most fields from the primary language; description and keywords must be entered. ([Apple: localize app information](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/))
2. **Screenshots do not need localization.** New languages inherit the English screenshots. Localized screenshots are optional forever. ([same source](https://developer.apple.com/help/app-store-connect/manage-app-information/localize-app-information/))
3. **Subscriptions localize separately.** Each product takes a per-locale display name (≤30) + description (≤45); the subscription group display name localizes too. Every added locale must have both fields filled or ASC flags Missing Metadata. ([ASC subscriptions help](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/))
4. **Pricing: one base price, 175 storefronts.** Apple generates comparable prices from the base (USD) across all storefronts and currencies, following local price conventions and taxes. Auto-generated **app/IAP** prices track FX changes; auto-generated **subscription** prices do NOT auto-adjust after creation — updates are manual. ([Apple: set a price](https://developer.apple.com/help/app-store-connect/manage-app-pricing/set-a-price/), [subscription pricing](https://developer.apple.com/help/app-store-connect/manage-subscriptions/manage-pricing-for-auto-renewable-subscriptions/))
5. **ASC API covers all of this** — `appInfoLocalizations` (name/subtitle), `appStoreVersionLocalizations` (description/keywords/promo), `subscriptionLocalizations`, screenshot sets. No API key exists in this repo, so v1 is manual paste (~30 min for 5 languages). ([API docs](https://developer.apple.com/documentation/appstoreconnectapi/app-store-version-localizations))
6. **Timing:** name, subtitle, description, keywords ship with the next version's review. Promotional text is editable any time without review. So: paste Tier 1 into the v2 version before submitting.
7. **Cross-localization bonus:** the US storefront also indexes es-MX (and some other) keyword fields. v1 keeps es-MX keywords Spanish (honest local intent). Using that field for English keyword overflow is a later ASO experiment, noted in `es-MX.md`. ([MobileAction](https://www.mobileaction.co/blog/app-store-cross-localization/), [AppTweak](https://www.apptweak.com/en/aso-blog/how-to-benefit-from-cross-localization-on-the-app-store))

---

## Keyword strategy

Not translated — researched per market. Each locale file documents intent behind its keyword field. Principles:

- Lead with the term locals use for the *object* Unit replaces: de "Trainingstagebuch", pt-BR "ficha de treino", fr "carnet de muscu", tr "antrenman defteri". These go in the **name/subtitle** (highest ranking weight), not the keyword field.
- Keyword field = 100 chars, comma-separated, no spaces, no words already in that locale's name/subtitle, no competitor trademarks.
- Many EU users also search English ("gym tracker" works in Germany). The English keyword field already covers those searches on storefronts where en is indexed; locale fields chase native-language queries only.

---

## Screenshots — recommendation

**v1: keep all screenshots English.** Reasons: inheritance is automatic (zero work), caption text is 4–6 words per slide, and localizing captions means 5 languages × 5 slots of Figma export + upload — high effort, low return at current volume.

Localized **caption copy is pre-written** in each locale file (5 slots each), so a later screenshot pass is one Figma session, no translation step. Trigger for that pass: any Tier 1 locale exceeding ~15% of installs.

---

## Pricing — recommendation

Locked USD ladder (source of truth `docs/pricing.md`, decision 2026-07-02):

| Tier | USD base | Product ID |
|---|---|---|
| Weekly | $2.99 | `com.unit.weekly` |
| Monthly | $4.99 | `com.unit.monthly` |
| Yearly | $29.99 | `com.unit.annual` |
| Lifetime (optional) | $44.99 | `com.unit.lifetime` |

**Recommendation: Apple automatic conversion from the USD base for all four products. No custom storefront prices in v1.** Rationale:

- Apple's price grid is monotonic per storefront: $2.99 < $4.99 < $29.99 < $44.99 maps to the same order everywhere, so the 2026-07-02 dominance rule ("no tier strictly dominates another at the same visible price") holds by construction.
- Custom storefront prices are the only way to *reintroduce* a dominated tier (the $4.99/$4.99 weekly-monthly tie, per storefront, invisibly). Don't open that door without per-region data.
- One real drift risk: subscription prices are static after generation while the Lifetime non-consumable tracks FX. Large currency moves could bend the Lifetime:Yearly ratio in a storefront. Mitigation: quarterly spot-check (below), not custom prices.

**Spot-check list** (low-price, high-FX-volatility storefronts where rounding compression is most plausible): Turkey, Brazil, India, Mexico, Japan, Nigeria/Egypt. Check in ASC → each product → Pricing → view all prices: Weekly < Monthly < Yearly < Lifetime in local currency, each period priced sensibly against its neighbors.

**Not doing:** custom regional ladders, purchasing-power discounts, or price experiments. Per `docs/pricing.md` §Changing prices, no price moves without paywall-view data, and any move goes ASC-first with a decision-log entry. Paywall display prices remain StoreKit-derived (`Product.displayPrice`) — nothing in code knows a price.

---

## App Store Connect actions (founder, in order)

Execution runbook with merge order, per-click detail, and post-paste verification: [`asc-paste-checklist.md`](asc-paste-checklist.md). Summary below. Everything is manual web work; no code ships. ~45 min total.

1. **Pre-check:** confirm the 2026-07-02 Weekly price change ($4.99 → $2.99) is done in ASC. It gates v2 regardless of localization.
2. **App Store tab → v2 version → add languages:** German, Spanish (Mexico), French, Portuguese (Brazil), Turkish. For each, paste from the locale file in this folder: name, subtitle, description, keywords, promotional text, What's New. Screenshots: leave inherited (English).
3. **Features → Subscriptions → Unit Pro group:** for each of Weekly / Monthly / Yearly, add the 5 localizations (display name + description from the locale files). Also add the 5 group-display-name localizations (keep "Unit Pro" as the name).
4. **Features → In-App Purchases → Unit Lifetime:** same 5 localizations — only if the non-consumable is configured at all.
5. **Pricing check:** each product → Pricing → confirm "automatically generated" from the USD base, then run the §Pricing spot-check list.
6. **Submit v2** with the new languages attached. Reviewer notes stay English (App Review works in English; do not localize the notes).
7. Post-approval: promotional text per locale is editable anytime without review — safe channel for later tweaks.

---

## Native-speaker review risks

- All non-Turkish Tier 1 copy is **Claude-translated, unreviewed by a native**. Quality target is high but subtle register errors are possible. Before submission: one native read per language (de, es-MX, pt-BR, fr) — gym-goers preferred, ~10 min each. Turkish: founder reviews directly.
- Register choices made and flagged per file: German "du", Spanish "tú", Portuguese "você", French "vous" (open question — lifter slang leans "tu"; see `fr-FR.md`), Turkish "sen".
- First-person-singular rule (`PRODUCT.md`): no we-forms in any language (kein "wir", no "nosotros", "nós", "nous", "biz"). Checked in each file.
- Subscription disclosure language (Guideline 3.1.2(b)) is translated inside every description — do not trim those paragraphs when pasting.

---

## Intentionally not localized, and why

| Surface | Why it stays English |
|---|---|
| In-app UI (all of it) | No localization infra in the binary; machine-translating `AppCopy.swift` without layout QA + native review is banned by this plan. Tier 3 prerequisites first. |
| Screenshots | Inherited automatically; captions pre-translated for a later pass. See §Screenshots. |
| Exercise names + parser vocabulary | Parser matching (`ProgramImportParser`) depends on exercise-name strings; translation without a matching-layer audit breaks paste import. Explicitly out of scope. |
| App Review notes | Reviewers work in English. |
| Product IDs, subscription group reference name | Immutable / load-bearing (`StoreManager.swift` requests exact IDs). Never change. |
| Japanese, Korean, Simplified Chinese metadata | Gated: ja/ko behind paid native translation (Tier 2); zh-Hans behind an ICP filing decision (Rejected). |
| unitlift.app marketing site | Separate surface, separate decision. Not in this plan. |
