# Tier 0 — English source (en-US)

> **Canonical English strings live in [`docs/app-store-copy.md`](../app-store-copy.md)** — one source of truth for every ASC field (name, subtitle, promo, description, keywords, What's New, captions, reviewer notes, subscription display fields, URLs). This file no longer duplicates them.
>
> Field limits for translators: name 30 · subtitle 30 · promo 170 · description 4000 · keywords 100 (comma-separated, no spaces) · subscription display name 30 · subscription description 45.

## Derivation notes for the locale files

- The five locale files (`de-DE.md`, `es-MX.md`, `pt-BR.md`, `fr-FR.md`, `tr.md`) were **re-derived 2026-07-11 from the frozen canonical** (founder direction: locale names follow the log-family identity of `Gym Workout Log`, not the old notebook metaphor; subtitles mirror the EN subtitle's add-new-keywords logic). Changed-fields record: `asc-execution-status.md`. Future English changes to any field re-stale the locales — re-derive and re-review before pasting.
- Locale files localize the name suffix, never "Unit".
- Reviewer notes are English-only by design — never localized.
- Every localized description must keep the "app UI is English" line and the paid-purchase disclosure paragraph.
