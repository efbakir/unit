# Unit 2.1 localized metadata — ASC paste checklist

> One sitting in App Store Connect. Start only after PRO-32 is Done and `asc-execution-status.md` says every locale is ready.
> **The in-app UI stays English.** Nothing you paste below changes that, and every localized description says so. Do not remove that line while pasting.

---

## 0. Release gate (do nothing in ASC before this)

1. All five locale files have a recorded native/founder approval.
2. `npm run test:localizations` passes after the final reviewer edits.
3. PRO-32 is Done.
4. The approved locale commit is on `main`.

## 1. Pre-checks (5 min)

- [ ] ASC → Subscriptions → `com.unit.weekly` → price reads **$2.99** (the 2026-07-02 change). If it still reads $4.99, fix that before anything else — it gates v2 regardless of localization.
- [ ] Native reviews done (see §7). **Do not paste unreviewed copy.** Turkish is the exception: you are the native reviewer.

## 2. What to paste first

Order within the sitting:

1. Subscription localizations (§4) — independent of the version page, can't go stale.
2. Version metadata per locale (§3) — rides the v2 submission.
3. Pricing verification (§5) — read-only, last.

Start with **Turkish** (you can self-verify the flow end to end), then de → es-MX → pt-BR → fr.

## 3. Version metadata — exact actions per locale

ASC → Apps → Unit → App Store tab → the 2.1 version page → language selector (top right) → **Add language**. Add exactly these five, one at a time:

| ASC language menu item | Paste from |
|---|---|
| German | `de-DE.md` |
| Spanish (Mexico) | `es-MX.md` |
| Portuguese (Brazil) | `pt-BR.md` |
| French | `fr-FR.md` |
| Turkish | `tr.md` |

For each language, paste these fields from the locale file, in this order:

- [ ] **Name** (App Information section — localizable per language)
- [ ] **Subtitle** (same place)
- [ ] **Description**
- [ ] **Keywords**
- [ ] **Promotional Text**
- [ ] **What's New in This Version**
- [ ] URLs: leave Support/Marketing/Privacy as the English values (`unitlift.app` is English-only; the locale files say the same)
- [ ] **Screenshots: touch nothing.** ASC pre-fills them from English — that is the plan. Inherited English screenshots, v1.

Paste exactly what is inside the code fences — no added punctuation, no trimmed paragraphs. The subscription-disclosure paragraph and the two legal URLs inside each description are Guideline 3.1.2(b) compliance; never cut them.

## 4. Subscription localizations — exact actions

ASC → Apps → Unit → Features → Subscriptions:

- [ ] **Group `unit-pro`** → App Store Localizations → add the 5 languages. Group display name stays `Unit Pro` in every language (brand, per the locale files).
- [ ] **`com.unit.weekly`** → App Store Localization → add all 5: display name + description from each locale file's Subscriptions table.
- [ ] **`com.unit.monthly`** → same.
- [ ] **`com.unit.annual`** → same.
- [ ] **`com.unit.lifetime`** (Features → In-App Purchases) → same 5 — **only if** the non-consumable is configured at all. If it isn't in ASC, skip; do not create it for this.

Every added locale needs **both** name and description filled, or ASC flags the product "Missing Metadata" and blocks submission.

Product IDs never change. If any screen asks you to create a product, stop — wrong screen.

## 5. Pricing — exact actions (read-only verification)

- [ ] Each of the 4 products → Pricing → confirm prices are **automatically generated** from the USD base (Weekly $2.99 / Monthly $4.99 / Yearly $29.99 / Lifetime $44.99). Do **not** enter custom storefront prices.
- [ ] Spot-check "view all prices" for Turkey, Brazil, India, Mexico, Japan: local-currency order must be Weekly < Monthly < Yearly < Lifetime. Any inversion or tie → stop and open a decision-log entry before touching anything.

## 6. Skip for 2.1 (deliberate, not forgotten)

- Localized screenshots (inherited English is the decision; captions are pre-translated in the locale files for a later Figma pass)
- Localized app previews / videos
- Japanese, Korean (Tier 2 — paid native translation first), Simplified Chinese (ICP gate), Italian, es-ES (Tier 2)
- Localized reviewer notes (App Review works in English)
- In-app UI localization, `.xcstrings`, any code change
- Any price change, custom storefront price, intro offer, or promotional offer

## 7. Native-speaker review checklist (before §3, per language)

One gym-going native reader each for **German, Spanish, Portuguese, French** (~10 min per language). **Turkish: you review it yourself — read the description once out loud.** Per reader:

- [ ] Description reads like a person, not a translation; register matches the file header (de "du", es "tú", pt "você", fr "vous" — fr reader also answers the tu/vous question flagged in `fr-FR.md`)
- [ ] No we-forms (kein "wir" / "nosotros" / "nós" / "nous" / "biz")
- [ ] The "app interface is in English" line is present and natural
- [ ] App name suffix and subscription display names read as product names, not sentences
- [ ] Keywords are words a lifter would type, in that language
- [ ] Any edit stays inside the ASC limits noted in the file (re-count after edits: name/subtitle 30, promo 170, keywords 100, sub name 30, sub desc 45)

Record the reviewer's fixes in the locale file (edit the fenced blocks) before pasting, so repo and ASC never diverge.

## 8. Verify each locale after pasting

Per language, still in ASC:

- [ ] Version page shows no red field warnings; character counters all inside limits
- [ ] Description renders with paragraph breaks intact (ASC sometimes eats double newlines on paste — re-paste if flattened)
- [ ] Keywords field has no spaces after commas
- [ ] Screenshots section shows the English set (inherited), not empty
- [ ] Subscriptions: each product shows the language listed with a green/complete state, no "Missing Metadata"
- [ ] After v2 approval: switch your App Store account region or use the web preview links per storefront (Germany, Mexico, Brazil, France, Turkey) and check the listing shows the localized name + subtitle

Final gate before Submit: version 2.1 has all five approved languages attached, English (U.S.) is still the primary language, and the attached binary is exactly 2.1 (58).
