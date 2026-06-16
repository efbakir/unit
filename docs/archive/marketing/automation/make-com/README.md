# Make.com workflow — alternative to Python orchestrator

> If you don't want to run Python locally and prefer a node-based UI to drag/drop, this folder has importable Make.com (formerly Integromat) workflow blueprints that do the same thing as `python/orchestrate_weekly.py`.

## Why Make.com vs the Python script

| | Python (`orchestrate_weekly.py`) | Make.com (this folder) |
|---|---|---|
| Cost | $0 | $9/mo Core (the free tier of 1k ops/mo is too small once you do videos) |
| UI | CLI | Visual node editor |
| Modifications | Edit Python | Drag-and-drop |
| Runs from | Your laptop or any cron host | Make.com cloud (always-on) |
| Source control | In repo | Out of repo (export JSON to commit) |
| Best for | Devs who want full control | Non-devs who want hands-off cloud automation |

**Pick one.** Don't run both — they'll double-render and double-post.

## What's in `weekly-content-pipeline.json`

A Make.com scenario with this node graph:

```
[Trigger: Schedule — every Sunday 6pm]
   ↓
[Google Sheets: read this week's posts from "12-week-calendar"]
   ↓
[Iterator: for each post]
   ↓
[ElevenLabs HTTP POST: render voice from script body]
   ↓
[Cloudinary or Drive: upload audio, get URL]
   ↓
[FFmpeg cloud (or Apify, or local self-hosted): stitch voice + screen recording]
   ↓
[Buffer: create scheduled update with media URL]
   ↓
[Slack/Email: notify "Week N pipeline done — review manifest"]
```

## Setup (10 min)

### 1. Sign up for Make.com

Free tier 1000 ops/mo is enough for **only** the simplest text + image flow. You'll need the **Core plan ($9/mo)** for the video pipeline at 30 ops × 3 channels = ~120 ops/week → ~480 ops/month, plus the per-video bandwidth.

### 2. Import the blueprint

In Make.com:
1. Click "+ Create a new scenario"
2. Click the three-dot menu → "Import Blueprint"
3. Upload `weekly-content-pipeline.json`
4. Connect each integration when prompted (one-time auth):
   - Google Sheets (for the calendar)
   - HTTP module (for ElevenLabs API — paste your `ELEVENLABS_API_KEY`)
   - Buffer (OAuth — log in)
   - Slack or Gmail (for notifications)
   - Cloudinary or Google Drive (for media hosting)

### 3. Set up the Google Sheets calendar

Create a sheet called "Unit content calendar" with columns:
- `week` (1-12)
- `day` (Mon/Wed/Fri)
- `format` (tradesman / founder-vlog / notebook / educational / observational)
- `channel` (tiktok, ig, x, yt)
- `script_id` (slug from voiceover-library.md)
- `caption` (the post text)
- `scheduled_at` (ISO datetime in local timezone)

Pre-populate from `docs/marketing/12-week-calendar.md` once. Update weekly during the Sunday review.

### 4. Test fire

In Make.com, click "Run once" and verify:
- Pulls the right week's rows
- Renders one voice file
- Stitches one video (or skips with a clear error if the FFmpeg step isn't wired)
- Schedules to Buffer in `--dry-run` mode (the blueprint has a `DRY_RUN` env that defaults to `true`)

### 5. Activate

Toggle the scenario to "Active" with a Sunday 6pm trigger.

## Limitations vs the Python script

- Make.com doesn't run FFmpeg natively. You need either:
  - A self-hosted FFmpeg endpoint you call via webhook
  - A 3rd-party service (Cloudinary's video API, Apify FFmpeg actor, Bannerbear)
  - Or skip video assembly in Make.com and run the FFmpeg step locally before triggering the rest
- File uploads in Make.com count as ops (1 op per upload). Volume can spike.
- Debugging is slower than Python — you tail Make.com's history rather than read stdout.

If those limits matter, use the Python pipeline.

## Maintaining the blueprint

When you change the pipeline:
1. Edit in Make.com UI
2. Export the updated blueprint: scenario menu → "Export Blueprint"
3. Save as `weekly-content-pipeline.json` and commit to repo

Keeps source control honest even though the runtime is in the cloud.

## See also

- `../python/orchestrate_weekly.py` — the equivalent local pipeline
- `../architecture.md` — what these orchestrators are wrapped around
- `../../automation-map.md` — what's automated vs manual
