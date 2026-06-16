# Unit marketing automation — setup and run

> The Python pipeline that goes beyond MD documents. Voice rendering, image generation, video stitching, social scheduling.
> Read `architecture.md` first if you haven't.

## Setup (5 min, one time)

### 1. Install Python dependencies

```bash
cd /Users/efbakir/unit/docs/marketing/automation/python
pip3 install -r requirements.txt
```

(Pillow, requests, python-dotenv, click — all standard, no native deps.)

### 2. Set up credentials

```bash
cp .env.example .env
# Edit .env in your editor and fill in the values
```

Required for voice rendering:
- `ELEVENLABS_API_KEY` — from https://elevenlabs.io → Profile → API Keys
- `ELEVENLABS_VOICE_ID` — clone your voice in ElevenLabs Voice Lab, copy the voice ID

Required for social scheduling:
- `BUFFER_ACCESS_TOKEN` — from https://publish.buffer.com → Settings → Apps & Extras → Developer → Create Access Token
- `BUFFER_TIKTOK_PROFILE_ID`, `BUFFER_IG_PROFILE_ID`, `BUFFER_X_PROFILE_ID` — get from Buffer's `/profiles` API endpoint

Optional:
- `OUTPUT_DIR` — where rendered files land (defaults to `../sample-output/` relative to script)

### 3. Verify install

```bash
python3 quote_cards.py --help
python3 elevenlabs_render.py --help
python3 buffer_schedule.py --help
python3 orchestrate_weekly.py --help
```

Each script supports `--dry-run` so you can verify config without spending API credits.

---

## Run

### Generate sample quote cards (no credentials needed)

```bash
python3 quote_cards.py
```

Produces:
- `sample-output/launch-quote-card.png` (1080×1920 IG/TikTok)
- `sample-output/launch-quote-card-twitter.png` (1200×675 X)
- `sample-output/notebook-vs-unit-card.png`
- `sample-output/free-tier-promise-card.png`

These are ready to attach to social posts.

### Render voice files for the next week's posts

```bash
python3 elevenlabs_render.py --week 3 --dry-run    # preview
python3 elevenlabs_render.py --week 3              # actually call API
```

Reads `docs/marketing/scripts/voiceover-library.md`, picks scripts for the week, calls ElevenLabs, saves MP3 files.

Cost: ~$0.30/script at ElevenLabs Starter tier. A full week's 3 scripts = ~$1.

### Stitch voiceover + screen recording into final video

```bash
# After you've recorded a screen cap of Unit (e.g., raw-footage/bench-press-2026-04-30.mp4)
# and have an MP3 from elevenlabs_render.py
python3 video_assemble.py \
    --video raw-footage/bench-press-2026-04-30.mp4 \
    --audio sample-output/audio/tradesman-1-bench-press.mp3 \
    --output sample-output/video/tradesman-1-bench-press.mp4 \
    --title "Logging a set in 2.4s"
```

Adds the voiceover, optional title overlay, normalizes audio, exports vertical 1080×1920 H.264.

### Schedule a post to Buffer

```bash
python3 buffer_schedule.py \
    --channel tiktok \
    --text "Logging a set in 2.4s. One-handed. Sweaty." \
    --media sample-output/video/tradesman-1-bench-press.mp4 \
    --when "2026-05-13 10:00:00 ET"
```

Auto mode safety: prompts for confirmation before actually queueing. Use `--yes` to skip the confirmation when running from a parent script.

### Orchestrate the whole week

```bash
python3 orchestrate_weekly.py --week 3
```

Runs the full pipeline for W3:
1. Render voice files for W3 scripts (`elevenlabs_render.py`)
2. Generate quote cards for W3 posts (`quote_cards.py`)
3. Stitch videos from `raw-footage/W3/*.mp4` + voice files (`video_assemble.py`)
4. Schedule W3 posts to Buffer (`buffer_schedule.py`)
5. Print a summary of what was scheduled and what's pending manual action (Reddit, replies)

Reads the schedule from `docs/marketing/12-week-calendar.md`.

---

## Make.com alternative (no Python)

If you prefer node-based UI, see `../make-com/README.md`. The Make.com workflow does the same thing as `orchestrate_weekly.py` but with a visual editor.

Tradeoff:
- Python: full control, free, lives in your repo, runs anywhere
- Make.com: visual, easier to modify, $9/mo Core plan needed at this volume

Pick one. Don't run both — they'll double-post.

---

## Manual steps after the orchestrator runs

The orchestrator handles the boring parts. You still do:

1. **Reddit posting** — manual per `reddit.md` (3rd-party schedulers = ban risk)
2. **6-hour Reddit reply window** — manual
3. **TikTok/IG/X comment replies** — manual
4. **DMs to early users / press** — manual
5. **The Sunday weekly review** — manual

Block 30 min on your Sunday calendar for the review + manual scheduling.

---

## Troubleshooting

### "ELEVENLABS_API_KEY not set"
You haven't created `.env` from `.env.example`. Re-do step 2 of setup.

### "Invalid Buffer access token"
Your token expired or you copied wrong. Regenerate at Buffer → Settings → Apps & Extras.

### "ffmpeg: command not found"
Install via Homebrew: `brew install ffmpeg`. Confirmed 8.0.1+ works.

### "Pillow: cannot open font file"
Pillow needs system fonts. macOS has them by default; if you see this on Linux, install `fonts-dejavu` or pass a TTF path with `--font-path`.

### Voice quality is off
Check ElevenLabs settings in the script: stability=50, clarity=75, style=0, speaker boost=off. These match `elevenlabs-protocol.md`. Adjust the `STABILITY` / `CLARITY` constants in `elevenlabs_render.py` if your cloned voice sounds robotic.

---

## Cost estimate (per month at this scale)

| Cost | Source |
|---|---|
| ElevenLabs Starter | $5/mo (already in tools.md) |
| Buffer Essentials | $6/mo (already in tools.md) |
| Compute | $0 (your laptop) |
| **Total automation cost** | $11/mo (already in `$51/mo tools.md` budget) |

No new spend. The automation runs on the stack you already pay for.

---

## See also

- `architecture.md` — what this folder is and isn't
- `../cadence.md` — when in the week to run the orchestrator
- `../tools.md` — the $51/mo stack
- `../scripts/voiceover-library.md` — input for `elevenlabs_render.py`
