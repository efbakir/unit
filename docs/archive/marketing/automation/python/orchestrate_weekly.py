#!/usr/bin/env python3
"""
orchestrate_weekly.py — Top-level CLI that runs the full weekly content pipeline.

For a given week of the 12-week launch:
  1. Render voice-overs for that week's scripts (elevenlabs_render.py)
  2. Generate quote cards (quote_cards.py)
  3. Stitch raw screen recordings + voice into final videos (video_assemble.py)
  4. Print a manifest of what's queued for Buffer (manual scheduling step)
  5. Print manual-action checklist (Reddit posts, replies, DMs)

Per docs/marketing/automation-map.md:
- ✅ Voice rendering, image generation, video stitching are automated
- ⚠️ Buffer scheduling: orchestrator generates the manifest, prompts before posting
- ❌ Reddit posts/replies, DMs, monthly recording: stay manual

Usage:
    python3 orchestrate_weekly.py --week 3                # full run for week 3
    python3 orchestrate_weekly.py --week 3 --skip-voice   # skip voice (already rendered)
    python3 orchestrate_weekly.py --week 3 --dry-run      # show plan, do nothing
"""

import os
import sys
import argparse
import subprocess
from pathlib import Path


SCRIPT_DIR = Path(__file__).parent


def _load_env(path: Path):
    """Tiny .env loader — populates os.environ."""
    if not path.exists():
        return
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" in line:
            k, _, v = line.partition("=")
            k, v = k.strip(), v.strip().strip('"').strip("'")
            if k and k not in os.environ:
                os.environ[k] = v


_load_env(SCRIPT_DIR / ".env")


def run_step(name: str, cmd: list, dry_run: bool) -> bool:
    """Execute a sub-script, stream output, return True on success."""
    print(f"\n=== {name} ===")
    print(f"  command: {' '.join(cmd)}")
    if dry_run:
        print("  (dry-run, not executing)")
        return True
    result = subprocess.run(cmd)
    if result.returncode != 0:
        print(f"  FAILED (exit {result.returncode})", file=sys.stderr)
        return False
    return True


def main():
    parser = argparse.ArgumentParser(description="Orchestrate Unit's weekly content pipeline.")
    parser.add_argument("--week", type=int, required=True, help="Launch week (1-12)")
    parser.add_argument("--dry-run", action="store_true", help="Show plan without running anything")
    parser.add_argument("--skip-voice", action="store_true", help="Skip ElevenLabs rendering (use existing files)")
    parser.add_argument("--skip-cards", action="store_true", help="Skip quote-card generation")
    parser.add_argument("--skip-video", action="store_true", help="Skip video assembly")
    args = parser.parse_args()

    week = args.week
    dry_run = args.dry_run
    skip_voice = args.skip_voice
    skip_cards = args.skip_cards
    skip_video = args.skip_video

    if week < 1 or week > 12:
        print("Week must be 1-12.", file=sys.stderr)
        sys.exit(1)

    print(f"Orchestrating week {week} content pipeline.")
    print(f"  python: {sys.executable}")
    print(f"  dry-run: {dry_run}")

    output_root = (SCRIPT_DIR / ".." / "sample-output").resolve()
    raw_footage = (SCRIPT_DIR / ".." / "raw-footage" / f"W{week}").resolve()
    audio_dir = output_root / "audio"
    video_dir = output_root / "video"

    # === Step 1: Voice rendering ===
    if not skip_voice:
        cmd = [sys.executable, str(SCRIPT_DIR / "elevenlabs_render.py"), "--week", str(week)]
        if dry_run:
            cmd.append("--dry-run")
        if not run_step("Voice rendering (ElevenLabs)", cmd, dry_run):
            print("Voice render failed. Aborting.")
            sys.exit(1)
    else:
        print("\n=== Voice rendering: SKIPPED ===")

    # === Step 2: Quote cards ===
    if not skip_cards:
        cmd = [sys.executable, str(SCRIPT_DIR / "quote_cards.py")]
        if not run_step("Quote-card generation (Pillow)", cmd, dry_run):
            print("Quote-card gen failed. Continuing anyway.")
    else:
        print("\n=== Quote cards: SKIPPED ===")

    # === Step 3: Video assembly ===
    if not skip_video:
        if not raw_footage.exists():
            print(f"\n=== Video assembly: SKIPPED (no raw-footage at {raw_footage}) ===")
            print("  Drop screen recordings into the W{week}/ folder, named to match audio slugs.")
        else:
            print(f"\n=== Video assembly (FFmpeg) ===")
            video_dir.mkdir(parents=True, exist_ok=True)
            audio_files = sorted(audio_dir.glob("*.mp3")) if audio_dir.exists() else []
            video_files = list(raw_footage.glob("*.mp4")) + list(raw_footage.glob("*.mov"))
            if not audio_files or not video_files:
                print(f"  No matched audio (.mp3) and video (.mp4/.mov) — skipping")
            else:
                for audio in audio_files:
                    # Match by slug prefix
                    matching_video = next(
                        (v for v in video_files if v.stem in audio.stem or audio.stem in v.stem),
                        None,
                    )
                    if not matching_video:
                        print(f"  no video match for {audio.name} — skipping")
                        continue
                    output = video_dir / f"{audio.stem}.mp4"
                    if output.exists():
                        print(f"  exists: {output.name}")
                        continue
                    cmd = [
                        sys.executable,
                        str(SCRIPT_DIR / "video_assemble.py"),
                        "--video",
                        str(matching_video),
                        "--audio",
                        str(audio),
                        "--output",
                        str(output),
                    ]
                    if dry_run:
                        cmd.append("--dry-run")
                    print(f"  → {output.name}")
                    subprocess.run(cmd)
    else:
        print("\n=== Video assembly: SKIPPED ===")

    # === Step 4: Manifest ===
    print(f"\n=== Manifest for week {week} ===")
    print(f"\nReady to schedule (in {video_dir}):")
    if video_dir.exists():
        for f in sorted(video_dir.glob("*.mp4")):
            print(f"  - {f.name}  ({f.stat().st_size // 1024} KB)")
    else:
        print("  (none yet)")

    print(f"\nReady to attach (in {output_root}):")
    if output_root.exists():
        for f in sorted(output_root.glob("*.png")):
            print(f"  - {f.name}")

    # === Step 5: Manual checklist ===
    print(f"\n=== Manual actions for week {week} (per automation-map.md) ===")
    print(f"\n  ☐ Schedule the {len(list((video_dir if video_dir.exists() else Path('.')).glob('*.mp4')))} videos to Buffer:")
    print("      python3 buffer_schedule.py --channel tiktok --text '...' --media <file> --when '...'")
    print(f"  ☐ Reddit post (manual, per reddit.md): see 12-week-calendar.md week {week}")
    print(f"  ☐ Block 6 hours after Reddit post for replies")
    print(f"  ☐ DM follow-ups to early TestFlight testers / subscribers")
    print(f"  ☐ Sunday metrics review: 5 metrics + 1-line summary (per cadence.md)")

    print(f"\nDone.")


if __name__ == "__main__":
    main()
