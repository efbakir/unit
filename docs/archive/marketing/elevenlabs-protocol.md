# ElevenLabs voiceover protocol

> Hard rules for using ElevenLabs voice cloning in Unit's content. The only allowed combo is **voice-clone-of-you + real screen recording**. Any other combo is the slop signature that gets shadowbanned in fitness on TikTok/IG in 2025-2026.

## When to use

You have screen recordings of the app working but don't want to record audio. Common cases:
- Sick, tired, voice gone
- In a noisy space (gym during peak hours, café)
- Want a 60s feature-explainer without filming a face
- Need rapid iteration on a script (text edits are easier than re-recording)

Use sparingly — 1-2 times per month max. If you're using ElevenLabs every week, you're either over-producing (slow down) or avoiding being on camera (record real content; the founder face still wins).

## When NOT to use

- ❌ Voice-clone of someone else's voice (likeness law + ToS violation)
- ❌ Voice-clone over stock B-roll (Pexels / Mixkit / Storyblocks footage)
- ❌ Voice-clone over AI-generated visuals (Veo / Runway / Pika output)
- ❌ Voice-clone over UGC creator footage (the creator's voice is already authentic — replacing it is fraud)
- ❌ As a substitute for hard work — the founder vlog format requires a real face on camera some of the time

## One-time setup (10 minutes)

1. Sign up at [elevenlabs.io](https://elevenlabs.io) — Starter tier ($5/mo).
2. Voice Lab → "Add Voice" → "Instant Voice Clone".
3. Upload 3-5 minutes of clean audio of your own voice. Recommendations:
   - Read aloud one of your existing app-positioning paragraphs
   - Or read 4-5 of the rant scripts from `content-engine.md`
   - Quiet room, decent mic (AirPods are fine), no music
4. Save as "Founder voice — Unit".
5. Test: generate 30s of audio from a sample script. Verify it sounds like you.

## Per-clip workflow

1. **Record screen-only clip** of the app (no face, no live voice). Use QuickTime → iPhone screen mirror, or iOS Control Center Screen Recording.
2. **Write a 30-60s script** matching `PRODUCT.md` brand voice (calm, expert, honest). Examples:
   - "Three taps. Ghost value from last session pre-fills weight and reps. Tap to confirm. Haptic. Done. That's the whole loop. No menus, no AI coach, no recommendations. Just the set you actually did."
   - "I built this because every gym app made me tap through 4 fields under fatigue. This is one tap. The previous session pre-fills. You confirm or you adjust. Then you log. That's it."
3. **Generate audio** via ElevenLabs. Use your "Founder voice — Unit" voice. Settings: stability ~50, clarity ~75 (these are the calm-narration defaults — don't push the "expressive" sliders, you sound dry IRL too).
4. **Drop in CapCut**: import screen recording + ElevenLabs audio. Sync audio to actions on screen. Trim silences.
5. **Add Submagic captions** on top of the assembled clip.
6. **Export** as 30-60s vertical (9:16, 1080×1920).

Per-clip time: ~20-30 min.

## Hard rules (the non-negotiables)

| Rule | Why |
|---|---|
| Only voice-clone of YOUR own voice | Likeness law + Terms of Service. Even if cloning a public figure's voice is technically possible, it's illegal in most jurisdictions and gets accounts terminated on ElevenLabs and the social platforms. |
| Only over REAL screen recordings | The combo "AI voice + AI visuals" is the slop signature TikTok/IG actively shadowban in fitness. Real screen footage breaks the pattern. |
| Never over stock B-roll | Same slop signature. |
| Never over AI-generated visuals (Veo / Runway / Pika) | Same. |
| Don't replace UGC creator audio | Their voice is what you paid for. |
| Don't use ElevenLabs for the founder vlog format | The founder vlog needs a real face on camera. ElevenLabs is for screen-only feature explainers. |

## Why this works (research summary)

Per the 2026-04-29 research (`research/viral-patterns-2026-04-29.md`):

> AI-generated voiceover *over real screen recording* — the platform reads it as a normal product demo; voiceover style is no longer a signal.

The classifier looks at the visuals first. If the visuals are real (your app's UI in motion), the voice can be AI-assisted without triggering slop detection. If the visuals are AI/stock + voice is AI, the combo trips the filter.

## Disclosure

If a platform or audience member asks whether the voice is AI: **say yes**. The honest answer is "I cloned my own voice via ElevenLabs to save time when my voice is shot." That's brand-cohesive (calm, expert, honest). Pretending it's a real recording when asked breaks the brand.

You don't need to proactively disclose in every video. But don't lie if asked.

## Tracking

In the weekly metrics review (`cadence.md`), tag clips that used ElevenLabs voice-clone. If they perform 50%+ worse than real-voice clips of comparable format, stop using it. If they perform comparably, keep going.

## See also

- `content-engine.md` Source C
- `anti-patterns.md` — the AI-content shadowban triggers
- `tools.md` — ElevenLabs Starter tier, $5/mo
