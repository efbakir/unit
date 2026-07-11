# ASC execution status — TR NAME APPROVED; FOUR LOCALES AWAIT NATIVE REVIEW

> Updated 2026-07-11 (second update). **English copy is frozen** (`docs/app-store-copy.md`, canonical since commit `49e4f36`) and the founder confirmed the direction ("the app is *workout log* now — see the bigger picture"). The resume protocol ran: all five locale files are re-derived from the frozen canonical. **Nothing is pasted into ASC yet.** Turkish is founder-reviewed and approved (2026-07-11 naming audit — name final: `Unit: Antrenman Günlüğü`) but still needs the explicit "paste tr" go-ahead. de/es-MX/pt-BR/fr each need one native-speaker read; their names are candidates. Founder naming rule (2026-07-11): competitor differentiation is not a naming criterion — natural local wording, log-vs-plan accuracy, and native comprehension decide.

## Changed fields per locale (re-derivation, 2026-07-11)

| Field | tr | de-DE | es-MX | pt-BR | fr-FR |
|---|---|---|---|---|---|
| App name | **changed** — `Antrenman Defteri` (notebook) → `Antrenman Günlüğü` (log) | unchanged (`Trainingstagebuch` is already log-family) | unchanged (`Diario de Gym` is already log-family) | **changed** — `Ficha de Treino` (sheet) → `Diário de Treino` (log) | **changed** — `Carnet de Muscu` (notebook) → `Journal de Muscu` (log) |
| Subtitle | **changed** — now `Kuvvet ve ağırlık takibi` | **changed** — now `Krafttraining-Tracker` | **changed** — now `Registro de fuerza y series` | **changed** — now `Registro de cargas e séries` | **changed** — now `Suivi de force et de séries` (old one duplicated the new name's *journal*) |
| Promo text | **changed** — evergreen paper-comparison line (all five; the "New in v2" promo is superseded) | changed | changed | changed | changed |
| What's New | **changed** — paid-purchase disclosure paragraph appended (all five) | changed | changed | changed | changed |
| Keywords | **re-deduped** against new name/subtitle (all five; see each file's note for removed/added terms) | re-deduped | re-deduped | re-deduped | re-deduped |
| Description | unchanged (EN source did not change) | unchanged | unchanged | unchanged | unchanged |
| Subscriptions table | unchanged | unchanged | unchanged | unchanged | unchanged |
| Screenshot captions | unchanged (the notebook *metaphor* stays in brand copy; only the name field moved to log-family) | unchanged | unchanged | unchanged | unchanged |

Character limits: **all 20 re-derived fields machine-checked within ASC limits** (name/subtitle 30, promo 170, keywords 100, sub name 30, sub desc 45).

## Second regeneration — APPLIED (post-freeze fixes, 2026-07-11)

The English copy is **FROZEN** (founder-approved, `docs/app-store-copy.md`). The three approved post-freeze fixes are now applied to all five locale files:

1. **Name separator** — all five names read `Unit: …` (colon), matching the frozen `Unit: Gym Workout Log`: tr `Unit: Antrenman Günlüğü` (23), de `Unit: Trainingstagebuch` (23), es `Unit: Diario de Gym` (19), pt `Unit: Diário de Treino` (22), fr `Unit: Journal de Muscu` (22).
2. **What's New bullet 2** — "your program" equivalents: tr `Programını yapıştır…`, es `Pega tu rutina…`, pt `Cole sua ficha…`, fr `Collez votre programme…`. de already read `dein Programm` — untouched.
3. **What's New bullet 3** — now ends at the free surface (program built), not past the paywall (first logged set): tr `…yüklemeden programın hazır olmasına bir dakikadan kısa sürede`, de `…zum fertigen Programm in unter einer Minute`, es `…a tu rutina lista en menos de un minuto`, pt `…à sua ficha montada em menos de um minuto`, fr `…à votre programme prêt en moins d'une minute`.

Everything else from the first re-derivation stands. Descriptions untouched (their English source did not change in the freeze). Character limits re-run after the fixes: **every field in all five files within ASC limits** (name/subtitle 30, promo 170, keywords 100, What's New 4000, sub name 30, sub desc 45).

## Gate before any ASC paste

- [x] Founder reads + approves **tr** (native) — **approved 2026-07-11, name final `Unit: Antrenman Günlüğü`.** Explicit "paste tr" still required before any ASC action.
- [ ] One native read each: **de-DE**, **es-MX**, **pt-BR**, **fr-FR** (register notes are in each file's header; fr has the open tu/vous question).
- [ ] Founder says "paste locale X" per locale — no blanket approval.

## Still true from the aborted preflight

1. No v2.0 version record existed in ASC — it appears when build 16 is uploaded (or create it manually first; build bumped 15 → 16 per the freeze entry).
2. The live listing name showed **"Unit: Gym Notebook"** (colon) — consistent with the adopted colon separator; all five locale names use `Unit: …`.
3. Localization remains **optional for the v2 submission** — English-only metadata is complete and unblocked today; locales can ride any later metadata update.
