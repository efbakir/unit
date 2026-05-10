# Unit — marketing

> Operational marketing infrastructure for the indie iOS gym logger Unit.
> Companion to [`docs/launch-plan.md`](../launch-plan.md) — launch plan covers **WHEN**; this folder covers **HOW**.
> Resolved 2026-04-29.

## What this folder is

The 8-week launch plan in `docs/launch-plan.md` is the strategic timeline. The files here are the operational scaffolding that lets that plan execute without eating your week:

- A tool stack that costs ~$43-60/mo at indie launch (Q1 paid UGC skipped per 2026-05-02 budget decision; cap rises to ~$110-130/mo only if UGC reactivates Q2+)
- Templates so each "post day" is fill-in-the-blank, not write-from-scratch
- A content engine: ~3hrs of recording per month → ~30 short clips
- An automation map that explicitly draws the line between scheduled and manual
- Anti-patterns codified so they don't drift back in

## Layout

```
docs/marketing/
├── README.md                    ← this file
├── tools.md                     ← the ~$60/mo monthly (~$43/mo annual) stack, links, account placeholders
├── reddit.md                    ← Reddit playbook + frequency caps
├── tiktok-ig.md                 ← TikTok/IG playbook + 5 formats
├── content-engine.md            ← monthly recording workflow (3 sources)
├── ugc-brief.md                 ← Billo/Insense casting + format spec
├── elevenlabs-protocol.md       ← voice-clone rules (only over real screen recordings)
├── cadence.md                   ← weekly rhythm + Sunday checklist
├── anti-patterns.md             ← codified won't-do list
├── automation-map.md            ← what's scheduled, what's manual, why
├── research/                    ← dated agent reports (2026-04-29)
└── templates/                   ← drafted starter posts
    ├── reddit/      (3 posts)
    ├── tiktok-ig/   (5 formats)
    └── x/           (3 framings)
```

## Order to read

1. `tools.md` — set this up first (Buffer, Submagic, etc.)
2. `cadence.md` — the weekly rhythm you'll actually live
3. `content-engine.md` — what to record and when
4. `reddit.md` and `tiktok-ig.md` — playbooks for each surface
5. `automation-map.md` — when you wonder "should I automate this?"
6. `anti-patterns.md` — when you're tempted by a shortcut
7. `templates/` — fill-in-the-blank starters for each platform
8. `research/` — the dated source-of-truth research these playbooks rest on

## Source-of-truth chain

| Concern | Lives in |
|---|---|
| Strategy + timing | `docs/launch-plan.md` |
| Brand voice | `PRODUCT.md` and `docs/app-positioning.md` |
| Pricing | `docs/pricing.md` |
| App Store copy | `docs/app-store-copy.md` |
| Competitor teardown | `docs/competitors.md` |
| Product principles | `docs/product-compass.md` |
| Operational marketing infra | this folder |

When playbooks here conflict with `launch-plan.md`, **launch-plan.md wins**. Update launch-plan.md first, cascade here second.

## Confidentiality

This folder will become public-readable after Unit ships to the App Store (the repo's intended state per launch-plan.md). Do not commit:

- Account credentials (use 1Password, not files)
- Real customer data
- Unpublished pricing experiments outside `docs/pricing.md`
- Internal financials beyond what you've already chosen to surface (per launch-plan.md, MRR screenshots are the explicit exception)
