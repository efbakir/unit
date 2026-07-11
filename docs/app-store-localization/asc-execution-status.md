# ASC execution status — RE-DERIVED, AWAITING PER-LOCALE APPROVAL

> Updated 2026-07-11 (second update). **English copy is frozen** (`docs/app-store-copy.md`, canonical since commit `49e4f36`) and the founder confirmed the direction ("the app is *workout log* now — see the bigger picture"). The resume protocol ran: all five locale files are re-derived from the frozen canonical. **Nothing is pasted into ASC yet** — every locale requires explicit founder approval first (tr by the founder directly; de/es-MX/pt-BR/fr each need one native-speaker read).

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

## Second regeneration pending (post-freeze fixes, 2026-07-11)

The English copy is now **FROZEN** (founder-approved, `docs/app-store-copy.md`). Three approved fixes landed after the first re-derivation, so the next localization session must apply, per locale:

1. **Name separator**: `Unit — …` → `Unit: …` (all five — colon resolved in the decision log; matches the live listing's existing rendering).
2. **What's New bullet 2**: "any program" → "your program" equivalents — tr `herhangi bir programı` → `programını`, es `cualquier rutina` → `tu rutina`, pt `qualquer ficha` → `sua ficha`, fr `n'importe quel programme` → `votre programme`; **de already says `dein Programm`** (no change).
3. **What's New bullet 3**: "…to your first logged set in under a minute" → "…to your program built in under a minute" (all five — the old claim crossed the paywall; the new one is the free part).

Everything else from the first re-derivation stands. Descriptions remain untouched (their English source did not change in the freeze).

## Gate before any ASC paste

- [ ] Founder reads + approves **tr** (native).
- [ ] One native read each: **de-DE**, **es-MX**, **pt-BR**, **fr-FR** (register notes are in each file's header; fr has the open tu/vous question).
- [ ] Founder says "paste locale X" per locale — no blanket approval.

## Still true from the aborted preflight

1. No v2.0 version record existed in ASC — it appears when build 15 is uploaded (or create it manually first).
2. The live listing name showed **"Unit: Gym Notebook"** (colon) — precedent for the colon separator choice on the new name; whichever separator the founder picks, apply it in all five locale names too.
3. Localization remains **optional for the v2 submission** — English-only metadata is complete and unblocked today; locales can ride any later metadata update.
