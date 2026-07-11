# ASC execution status — PAUSED

> Updated 2026-07-11. **Localization execution is paused by the founder: the English source copy is being rewritten and frozen first.** Nothing below may be pasted into App Store Connect until the founder says "English copy frozen" AND explicitly approves the re-derived translations.

## Current state

| Item | Status |
|---|---|
| Locales pasted into ASC | **None. Zero ASC fields were edited.** |
| de-DE, es-MX, pt-BR, fr-FR | Blocked twice over: no native-review record in the locale files, and now stale against the changing English source |
| tr | Was cleared to paste (founder-approved), **paused before any paste** — now stale like the others; requires re-review after re-derivation |
| Subscription localizations (`unit-pro`, 4 products) | Not touched |
| Pricing spot-check | Not run (read-only step; paused before reaching it) |
| Screenshots | Not touched (would inherit English by default) |
| ASC errors | None — session ended at the Apps list, before any edit surface |

## Why paused

The English App Store copy and product messaging are being rewritten (see the consolidated `docs/app-store-copy.md`, now the single canonical copy source). The five locale files were derived 2026-07-11 from the **pre-consolidation** English strings, so they are no longer a reliable source of truth. Do not treat them as approved or final; do not patch them incrementally; do not generate new translations while the source is moving.

## Observation from the aborted preflight (report only, nothing changed)

The ASC Apps list showed **"Unit: Gym Notebook" — iOS 1.0, Ready for Distribution**. Two things for the founder to check when work resumes:
1. No v2.0 version record was visible from the list page — it may need to be created in ASC before any version-tied metadata (localized or English) can be entered.
2. The live listing name appears to be "Unit: Gym Notebook" — relevant to the pending name change to "Gym Workout Log" and the separator choice.

## Resume protocol (runs only when the founder says "English copy frozen")

1. Diff the frozen `docs/app-store-copy.md` against the pre-consolidation English source (git history) — list every affected localization field.
2. Re-derive all five locale files from the frozen source; preserve fields whose English source did not change.
3. Output an explicit changed-fields list per locale.
4. Re-run the ASC character-limit check on every field.
5. Mark **every** language as requiring review again — **including Turkish**.
6. Paste nothing into App Store Connect until the founder explicitly approves the re-derived copy.

## Founder actions remaining

- Finish and freeze the English copy in `docs/app-store-copy.md`; say "English copy frozen".
- After re-derivation: native reads for de/es-MX/pt-BR/fr; founder re-reads tr.
- Explicit approval per locale before any ASC paste.
