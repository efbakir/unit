# Content engine

> Record once, post 30 times. Three sources feed Buffer; Buffer schedules everything except Reddit.
> Goal: ~3 hours of *your* time per month, ship 3 posts/week to 3 platforms = 36 pieces/month.

## Three sources

| Source | Frequency | What | Who shoots |
|---|---|---|---|
| **A. DIY founder content** | Monthly (3hrs/session) | Gym recordings + talking-head rants | You |
| **B. UGC creators** | **DEFERRED for Q1** (per 2026-05-02 budget decision) | 0 clips during launch ramp; re-evaluate at Q2 | When reactivated: ladder in `tools.md` (TestFlight clips → Fiverr → Collabstr → reduced Billo) |
| **C. ElevenLabs voiceover** | As needed | Voice-of-you narrating screen recordings | You write script + clone voice; no face needed |

All three converge into the same Submagic + CapCut pipeline (Submagic absorbs what Opus Clip used to do — see `tools.md` 2026-05-02 audit). Buffer schedules the output.

---

## Source A — DIY founder content (monthly)

**When**: last Sunday of each month. Block 3 hours.

### Hour 1 — gym recording

Setup:
- Phone on tripod (cheap one is fine, ~$25)
- Real gym, real workout, real plates
- Screen-record the app simultaneously via QuickTime (iPhone connected to MacBook) OR iOS Control Center screen recording

Capture:
- 3 different exercises × 3 sets each = ~9 sets total
- Multiple angles: face-on (talking-head), top-down (over-shoulder while logging), screen-only
- Ambient gym audio is fine — mic up your voice for narration if needed

Output: ~30 min raw footage.

### Hour 2 — talking-head rants

Setup:
- Phone on tripod at home or in the gym
- Quiet space, decent lighting (window light is enough)
- Optional: lavalier mic (~$15)

Record 4 short rants:
1. **"Why I built Unit"** (90s)
2. **"What's broken with Hevy / Strong"** (60s) — be specific, not generic
3. **"Why 'Last time' is the only progression UI you need"** (90s)
4. **"Notebook vs Unit — speed test"** (60s)

Each rant is one take, two takes max. Don't rewrite — first-thought is most authentic.

Output: ~5-7 min raw footage.

### Hour 3 — ingest + edit

Pipeline:
1. **Submagic Pro** — auto-captions on all clips (gym + talking-head). Custom caption style: white text, bold, drop shadow, no fancy animation. Also handles AI Auto Zooms, silence trim, and clip selection on sources up to 5min raw.
2. **Submagic Magic Clips (addon, conditional)** — only if a rant exceeded the 5min Submagic Pro source cap, feed it through Magic Clips for 6-8 short clips per rant. For ≤5min rants, Submagic Pro alone identifies the strongest 30s. (This step replaces the Opus Clip step from the pre-2026-05-02 stack.)
3. **CapCut Free** — assembly. Add transitions only where natural (no flashy effects). Add timer overlays for "set logged in 2.4s" claims. Free tier handles all of this; Premium not needed.
4. Export 30-60s vertical (9:16) at 1080×1920.

Output: ~15-20 vertical clips per session.

---

## Source B — UGC creators (DEFERRED for Q1)

> **Status (2026-05-02): DORMANT.** Q1 paid UGC skipped per the budget decision in `tools.md`. Sources A + C cover ~25 clips/month, sufficient for the W1-W12 launch ramp. Re-evaluate at Q2 (~2026-08-02) only if cornerstone DIY clips are averaging <5k views AND the failure isn't a positioning problem.
>
> When/if reactivated, follow the ladder in `tools.md` UGC section: TestFlight real-user clips ($0) → Fiverr ($50-100/video) → Collabstr → reduced Billo. The original $200/quarter Billo plan was dropped from default.

**When (when reactivated)**: first Sunday of each quarter (Q1, Q2, Q3, Q4).

**Budget (when reactivated)**: tier-dependent — see ladder in `tools.md`. The original $200/quarter for 4-6 videos = $50/video average is preserved as the upper-tier reference, NOT the default.

### Brief once, run quarterly

The brief lives in `ugc-brief.md`. Re-use the same brief each quarter unless you've learned something about which casting/format works best.

**Casting filter**:
- Real intermediate-to-advanced lifter (1+ years training)
- Real gym setting (commercial gym, garage gym, NOT aesthetic-gym chain)
- Comfortable narrating in own voice
- **Not**: models, beauty-app aesthetic, non-lifters in gymwear

Brand criterion = "looks like Unit's customer", not "demographic that gets clicks."

### What to ask UGC creators to film

Brief includes:
- 30-60s vertical
- Show the app working: their phone, their hands, their plates loaded behind them
- Voiceover: their own, in their own words
- Hooks: pick one of 3 pre-written ones from the brief
- CTA: *"I'm using Unit. Free on App Store."* — no affiliate energy, no hype

### Process

1. **Brief** (1hr) — fill out Billo brief once per quarter, paste from `ugc-brief.md`
2. **Cast** — turnaround varies by tier (TestFlight clips: same-day; Fiverr/Collabstr: 24-72h; Billo: 24-72h)
3. **Receive raw footage** (1-2 weeks for paid creators; same-day for TestFlight clips)
4. **Iterate if needed** (most paid platforms offer 1 free revision)
5. **Ingest** — same Submagic + CapCut pipeline as Source A (Magic Clips addon only if any single UGC source exceeds 5min raw, which is unusual for 30–60s briefs)

Output: 4-6 vertical clips per quarter = ~10-15 short pieces after Submagic re-cuts.

---

## Source C — ElevenLabs voiceover over screen recordings (as needed)

**When**: whenever you have screen recordings but don't want to record audio (sick, tired, in a noisy space, or you want a 60s "feature explainer" without filming a face).

**One-time setup**: clone your voice in ElevenLabs (~10 min). Speak 3-5 minutes of clean audio into the recording prompt. Save as a custom voice.

**Per-clip workflow**:
1. Record screen-only clips of the app (no face, no live voice)
2. Write a 30-60s voiceover script that matches `PRODUCT.md` brand voice (calm, expert, honest)
3. Run script through ElevenLabs voice-clone — generate audio
4. In CapCut: drop the audio over the screen recording, sync to actions
5. Add Submagic captions on top

**Hard rule**: ElevenLabs voice-of-you ALWAYS pairs with **real screen recording or your real face footage**. Never with stock B-roll, never with AI-generated visuals. The combo "AI face + AI voice + stock footage" is the slop signature → shadowban.

Per-clip time: ~20-30 min. Use sparingly — once or twice a month max, when you genuinely don't want to record audio.

---

## Output volume

| Source | Clips per cycle | Cycle length | Monthly equivalent |
|---|---|---|---|
| A. DIY | 15-20 | Monthly | 15-20 |
| B. UGC | 10-15 | Quarterly | 3-5 |
| C. ElevenLabs | 1-2 | As needed | 1-2 |
| **Total** | | | **~25-30 clips/month** |

That's ~3 clips per day for a 30-day month. With 3 posts/week to 3 platforms (~36 piece-publishings/month), this leaves a buffer for evergreen reposts of the strongest clips.

---

## Weekly cadence (30 min on Sunday evenings)

1. **Pick** 3 of the ~30 monthly clips for the upcoming week (mix of A/B/C, mix of formats)
2. **Schedule via Buffer** to TikTok + IG Reels + YouTube Shorts (Mon/Wed/Fri)
3. **Cross-post** 1/week to X with different framing
4. **Manually post** 1 build-in-public Reddit post on a random Tue/Wed (cap: max 1 / subreddit / month)
5. **Block 6 hours** after Reddit post for replies

## Total time accounting

| Activity | Time | Frequency |
|---|---|---|
| Monthly recording (Source A) | 3h | Monthly |
| UGC brief + review (Source B) | 1h | Quarterly |
| ElevenLabs ad-hoc (Source C) | 30min/clip | 1-2/month |
| Weekly clip pick + Buffer schedule | 30min | Weekly |
| Reddit post + 6h reply window | 6h | Weekly (only on the Reddit week) |
| Weekly metrics review | 5min | Weekly |

**Total**: ~14h/month, ~3.5h/week. The "I hate marketing" target.

## Recording-day equipment checklist

- [ ] Phone (tripod-mounted)
- [ ] Tripod
- [ ] Optional: lavalier mic ($15)
- [ ] MacBook for QuickTime screen recording
- [ ] Lightning/USB-C cable (iPhone → MacBook)
- [ ] Charged AirPods if you want clean voice capture
- [ ] Notes app open with the 4 rant prompts

## Storage

Raw footage → external SSD or iCloud. Don't commit to repo.

Edited clips → keep in a `clips/` folder synced to iCloud. Buffer pulls from local upload, so you don't need cloud-storage integration.

## When to skip a recording session

If your weekly metrics show:
- Zero engagement on the last 3 weeks of posts → fix the format before recording more
- A single format hitting 10x the others → record more of that format, less variety
- You're at <100 followers across all platforms after 8 weeks → re-run the research, don't double down on volume

Recording without analyzing the previous month's signal is wasted hours.

## See also

- `tiktok-ig.md` — the 5 formats this engine produces
- `cadence.md` — the weekly rhythm
- `automation-map.md` — what gets scheduled vs manual
- `ugc-brief.md` — the brief you paste into Billo
- `elevenlabs-protocol.md` — voice-clone rules
