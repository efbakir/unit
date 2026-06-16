# Account studies — copy what works

> Workflow: founder names an Instagram account → Claude fetches its content → one study file per account that says what to copy and what to skip.
> Rule: **copy mechanics, never content.** Hooks, structure, cadence, format mix — yes. Clips, faces, captions verbatim — no (`anti-patterns.md`, copyright + likeness rows).

## Why this exists

The marketing engine (`tiktok-ig.md`, `content-engine.md`, `cadence.md`) prescribes formats from April research. It has no workflow for studying accounts that are winning *right now*. This folder is that workflow: a swipe file of dissected accounts, one folder each.

## How to fetch an account (four tiers)

| Tier | Method | Setup | Depth |
|---|---|---|---|
| 0 | **Apify script (default)** — `automation/python/ig_account_fetch.py <handle>` pulls profile + last 30 posts headlessly, no Instagram login | One-time: free apify.com signup, token into `automation/python/.env` (`APIFY_TOKEN=`) | Followers, bio, cadence/week, format mix, engagement %, per-post views/likes/captions, top + bottom posts with hook lines. Raw JSON + summary land in the account's folder |
| 1 | **Claude in Chrome** — Claude browses the profile in the founder's logged-in session | Chrome open, Claude extension connected, IG logged in | What a scraper can't see cleanly: stories/highlights, comment threads, visual feel of the grid |
| 2 | **Screenshot drop** — save posts on phone, screenshot, AirDrop PNGs into the account's folder | None | Whatever was captured; Claude reads images directly |
| 3 | **Web metadata** — search-result leak of follower/post counts, bio | None | Shallow; small accounts often not indexed |

Tier 0 is the "fix it forever" path: say "study \<handle\>" and Claude runs the script. Cost ~$0.05 per study against Apify's $5/mo free credit (≈100 studies/month, $0 net). Public data only, no Instagram credentials anywhere. Tier 2 produced the first study (`noah-rolette/`) and stays the fallback for private accounts and Insights screenshots from friendly accounts.

## Folder convention

```
account-studies/
  <handle-kebab>/
    study.md       — the dissection (template below)
    IMG_*.PNG      — source screenshots, dropped by founder
```

## Study template

Every `study.md` answers, in order:

1. **Who / numbers** — followers, posts, niche, what they sell.
2. **Why they win** — the 2-3 mechanics doing the work.
3. **Format mix** — reels vs carousels vs static; cadence.
4. **Hooks** — first 3 seconds / first line, sampled from top posts.
5. **Copy for Unit** — mechanics to adopt, mapped to existing docs.
6. **Skip** — what conflicts with `anti-patterns.md` or PRODUCT.md voice, named explicitly.

## Studies

- [`noah-rolette/`](noah-rolette/study.md) — 634K, the "iPhone-only creator" playbook. Source: his own 8-slide tips carousel, 2026-06-11.
- [`journal-bingen/`](journal-bingen/study.md) — 26K. Turned out to be a **solo founder marketing his own app (Eclipta) via daily reels + comment-to-DM funnel** — the closest template Unit has. One reel hit 11.3M views. Tier 0 fetch, 2026-06-11.
