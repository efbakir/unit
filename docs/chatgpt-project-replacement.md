# Efe > Unit — ChatGPT Project replacement package

> **Approval required.** This package describes a destructive live Project replacement. Do not delete, upload, or edit anything in the live **Efe > Unit** ChatGPT Project until the user explicitly approves this exact package.

## Target

- Project: **Efe > Unit**
- Project ID: `g-p-69a18bf6b0ac81919e473e33ca454575`
- Live Project UI last reviewed: 2026-08-31
- Local mirror reviewed: 2026-09-14; all source and instruction hashes remain unchanged
- Mirror source snapshot: 7 uploads; live source cards were dated 2026-08-10 at the last live review and the local mirror last refreshed 2026-08-12
- Live-review limit: both available Chrome profiles were signed out of ChatGPT, so this run did not re-confirm the live source cards or Project Instructions
- Canonical instruction text: `docs/custom-instructions.md`

## Review result

- The live source set has the correct count, but six of seven source hashes differ from the current local canonical files. `docs/AGENTS.md` matches the live `AGENTS.md` upload.
- The live Project Instructions differ from `docs/custom-instructions.md`. The replacement preserves the locked light-only product UI while documenting the confirmed two-second black onboarding opener as a narrow transition exception.
- The local policy is list-only History, but `Unit/Features/History/HistoryView.swift` still exposes List and Calendar modes. This unresolved code-versus-policy conflict does not change the upload manifest.

## Source diff

| Live upload | Local replacement | Live SHA-256 | Replacement SHA-256 | Result |
|---|---|---|---|---|
| `PRODUCT.md` | `PRODUCT.md` | `adfeb296c0b9adca2d97da6fe6c38f0741ab47734183dfe590d73d8df12799e6` | `174343f43f8c9dc039c17962dbccea44b0641213688d265329fbc30e211acc29` | Changed: documents the narrow black-opener exception without weakening light-only product UI |
| `DESIGN.md` | `DESIGN.md` | `018ca00d8cd44063b23a1281f35615be8a99e1279be82f8bacdb963f1fa72ea2` | `68729c23f05afaa359d051ae98dabe74b4397b1fe2ab1523d7bc0b02d39ede37` | Changed: expanded Lab Notebook system and locked light-only product wording |
| `AGENTS.md` | `docs/AGENTS.md` | `71b6bc37d8d25af60d3ed4b25706f59896c730b6ac8e9ef26c1e03018e261586` | `71b6bc37d8d25af60d3ed4b25706f59896c730b6ac8e9ef26c1e03018e261586` | Same content; the local mirror stores this source as `AGENTS (project file).md` only to avoid a filename collision |
| `product-compass.md` | `docs/product-compass.md` | `8a965fe961bb513b36e4fdf0e96c9ddfab811cd7d76b55ee995d2bb6bd1316d2` | `f32d56c09519ee75a88be68e1d98477835a3e807c7a7e996b68b78e75dc38eb8` | Changed: latest paywall chronology, explicit supersession labels, and the confirmed light-only execution constraint |
| `goals.md` | `docs/goals.md` | `418eca10749ccc3a504905232cafabb5949b72114ffee41260ac0af578c6d3fa` | `43c2cb3090cb85483fd75029318f8232645635366c51209918f6e5ddb8a9cf44` | Changed: current scope wording and list-only History |
| `scope.md` | `docs/claude/scope.md` | `a2de50e1d0152fcd16554cef24774eb214446ff4bd750d752d8d1d44b202dae3` | `64907c5b7bb2b33e9911bd7248acfe5180de6516a794fc6cc2b3ade971b52b31` | Changed: current access gate and list-only History |
| `pricing.md` | `docs/pricing.md` | `62ce0541796569bbb223b060b6d1d4a25eb9357d918ba0f9182997944f323f45` | `d5ba87059fa23376dd5544d80dd87379343190574b3b8952a9cb975966196671` | Changed: one-surface paywall, optional reminder, CTA truth, and list-only History |

## Exact live deletion list

Delete every current Project upload:

1. `PRODUCT.md`
2. `DESIGN.md`
3. `AGENTS.md`
4. `product-compass.md`
5. `goals.md`
6. `pricing.md`
7. `scope.md`

## Exact seven-file upload list

After every deletion succeeds, upload only:

1. `PRODUCT.md`
2. `DESIGN.md`
3. `docs/AGENTS.md`
4. `docs/product-compass.md`
5. `docs/goals.md`
6. `docs/claude/scope.md`
7. `docs/pricing.md`

Do not upload `CLAUDE.md`, `docs/custom-instructions.md`, `docs/decision-log.md`, research PDFs, archives, audits, task summaries, or chat exports.

## Instruction replacement

Replace the live Project Instructions with the exact contents of `docs/custom-instructions.md` (SHA-256 `132c9b7596ce84a2966cc275cee8da3d7eea1d6bbf972da6128f0daa23438898`). Do not use the wrapper text from the local mirror's root `AGENTS.md`.

## Approval gate

Explicit user approval must cover all three actions together:

1. delete the seven live uploads listed above;
2. upload the exact seven canonical files listed above;
3. replace the live Project Instructions with `docs/custom-instructions.md`.

If any live source name, source count, local file, or fingerprint changes before approval, stop, re-read the mirror, and regenerate this package. Never partially apply an outdated package.
