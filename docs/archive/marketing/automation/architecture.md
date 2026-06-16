# Marketing automation architecture

> What's actually possible. Honest scoping for the "automation beyond MD documents" ask.
> Resolved 2026-04-30.

## Push-back: ElevenLabs is not what you think

ElevenLabs's product line in 2026:

| Product | What it does | Useful for Unit? |
|---|---|---|
| **Text to Speech (Voice cloning)** | Clone your voice once, generate audio from text | ✅ YES — voice-over library narration |
| **Conversational AI / Agent Studio** | Build chatbot/voice-agent flows with branching dialogue | ❌ Not relevant — Unit doesn't have a voice product |
| **Music** | Royalty-free background music generation | ⚠️ Maybe — subtle ambient bed under tradesman demos. Pushed back per anti-patterns: music with lyrics distracts from screen demo |
| **Workflows / Agent Studio** | Chain ElevenLabs's *own* products (TTS → ConvAI → music) into multi-step agent flows | ❌ Wrong tool for marketing automation. Designed for voice-product makers, not content pipelines |

**ElevenLabs does NOT do**: image generation, video generation, social-media posting, scheduling, captions, video editing, content distribution. Anything you've seen called "ElevenLabs Workflows" is voice-agent flows, not multi-modal automation.

The architecture you actually want — and what's built in this folder — is a **proper orchestrator + best-in-class APIs per modality**.

---

## The real architecture

```
                                  ┌──────────────────────────────────┐
                                  │   Orchestrator                   │
                                  │   (Python script OR Make.com)    │
                                  └────────────────┬─────────────────┘
                                                   │
                    ┌──────────────────┬───────────┼───────────┬──────────────────┐
                    │                  │           │           │                  │
                    ▼                  ▼           ▼           ▼                  ▼
            ┌──────────────┐  ┌──────────────┐  ┌──────┐  ┌──────────┐  ┌─────────────┐
            │ ElevenLabs   │  │ Pillow       │  │FFmpeg│  │ Buffer   │  │ Manual: you │
            │ TTS API      │  │ image gen    │  │video │  │ API      │  │ (Reddit,    │
            │ (voice-of-   │  │ (Python,     │  │stitch│  │ (TikTok, │  │ replies,    │
            │ you)         │  │ in-repo)     │  │      │  │ IG, X)   │  │ engagement) │
            └──────────────┘  └──────────────┘  └──────┘  └──────────┘  └─────────────┘
```

**Why this stack**:

1. **Python orchestrator** (`python/orchestrate_weekly.py`) — full control, lives in your repo, runs on your laptop or a cron. Free.
2. **Make.com** (alternative orchestrator) — node-based UI for non-coders. Use if you prefer to drag-and-drop. Free tier is enough at this scale.
3. **ElevenLabs API** — voice rendering. Direct HTTP calls, ~$5/mo Starter tier per `tools.md`.
4. **Pillow (Python)** — programmatic image generation for quote cards, App Store screenshot mockups. Free, in-repo.
5. **FFmpeg** — voiceover + screen recording → final vertical video. Free, already installed on your system.
6. **Buffer API** — schedule TikTok/IG/X posts. $6/mo Essentials per `tools.md`.
7. **Manual** — Reddit, replies, DMs. Per `automation-map.md`: anything where the algorithm rewards "real human" stays manual.

---

## What's NOT in the architecture (and why)

| Tool | Why excluded |
|---|---|
| HeyGen / Synthesia AI talking-head video | Shadowbanned in fitness 2025-2026 (per `anti-patterns.md`) |
| Runway / Veo / Pika AI video generation | Same shadowban risk for fitness; also expensive |
| Auto-DM tools | Spam-flagged by all platforms |
| Reddit posting via API/Buffer | Bans new accounts using 3rd-party tools |
| TikTok unofficial-API posters | ToS violation; account-nuke risk |
| Any tool that crosses the `anti-patterns.md` list | Push back |

---

## What this folder contains

```
automation/
├── architecture.md         (this file)
├── README.md               (setup + run instructions)
├── python/                 (the actual pipeline)
│   ├── requirements.txt
│   ├── .env.example        (credential template — copy to .env, fill in)
│   ├── elevenlabs_render.py    Voice rendering from voiceover-library.md
│   ├── quote_cards.py          Pillow image generation
│   ├── video_assemble.py       FFmpeg: voice + screen recording → final video
│   ├── buffer_schedule.py      Buffer API integration
│   └── orchestrate_weekly.py   Top-level CLI: runs the full week's pipeline
├── make-com/               (alternative orchestrator for non-coders)
│   ├── README.md           (how to import, configure, run)
│   └── weekly-content-pipeline.json    (importable workflow)
└── sample-output/          (real generated artifacts from this folder)
    └── launch-quote-card.png    (1080×1920 vertical card for IG/TikTok)
```

---

## What you can run TODAY (no credentials needed)

```bash
cd docs/marketing/automation/python
pip install -r requirements.txt
python quote_cards.py             # generates sample quote cards in sample-output/
```

Quote-card generation needs zero API keys. It uses Pillow to compose branded cards from text. Output is real PNGs ready to attach to tweets / Reddit posts.

---

## What you need credentials for

| Capability | Credential needed | Where to put it |
|---|---|---|
| Voice rendering | `ELEVENLABS_API_KEY` + `ELEVENLABS_VOICE_ID` | `python/.env` |
| Buffer scheduling | `BUFFER_ACCESS_TOKEN` | `python/.env` |
| Buffer per-channel | `BUFFER_TIKTOK_ID`, `BUFFER_IG_ID`, etc. | `python/.env` |

Never commit `.env`. Use `.env.example` as the template; `.gitignore` already excludes `.env` patterns (or add it).

---

## Manual steps that stay manual

Per `automation-map.md`, these never get automated:

- Reddit posting + replies (ban risk)
- TikTok/IG/X comment replies (algo signal)
- DMs to early users / press
- Monthly content recording (only a human can train and shoot themselves)
- The Sunday weekly review (decision-making, not data collection)

The orchestrator handles the boring mechanical parts: voice rendering, image generation, video stitching, social scheduling. You handle the human parts.

---

## Future: MCP server (optional, post-launch)

A custom MCP server (`mcp-builder` skill) would let future Claude sessions directly call ElevenLabs / Buffer without writing a Python script each time. Scaffolded but NOT built — see `make-com/README.md` for the pattern, build only after the basics are working.

---

## See also

- `python/README.md` (TBD if you want a separate one) or just `README.md` at automation root
- `docs/marketing/cadence.md` — when in the week each step of this pipeline fires
- `docs/marketing/automation-map.md` — the manual/automated dividing line
- `docs/marketing/tools.md` — the $51/mo stack (Buffer, ElevenLabs, Submagic, Opus Clip)
