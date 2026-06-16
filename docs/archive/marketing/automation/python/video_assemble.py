#!/usr/bin/env python3
"""
video_assemble.py — Stitch screen recording + ElevenLabs voiceover into a final
vertical TikTok/IG/Reels video using FFmpeg.

Per docs/marketing/elevenlabs-protocol.md hard rule:
"ElevenLabs voice ALWAYS pairs with REAL screen recording or your real face
footage. Never with stock B-roll, never with AI-generated visuals."

This script enforces that by REQUIRING a --video input. There is no codepath
that generates AI video.

Usage:
    python3 video_assemble.py \\
        --video raw-footage/bench-press-2026-04-30.mp4 \\
        --audio sample-output/audio/tradesman-1-bench-press.mp3 \\
        --output sample-output/video/tradesman-1-bench-press.mp4 \\
        --title "Logging a set in 2.4s"

Options:
    --video       Path to source screen recording or face footage (REQUIRED)
    --audio       Path to ElevenLabs MP3 voiceover (REQUIRED)
    --output      Path for final MP4 output (REQUIRED)
    --title       Optional title overlay (top of frame, 2s in)
    --target-w    Output width (default 1080)
    --target-h    Output height (default 1920 for vertical)
    --duration    Cap output to this many seconds (default: full audio length)
    --dry-run     Print FFmpeg command, don't execute
"""

import os
import sys
import shutil
import argparse
import subprocess
from pathlib import Path


def ensure_ffmpeg():
    if not shutil.which("ffmpeg"):
        print("ERROR: ffmpeg not found. Install with: brew install ffmpeg", file=sys.stderr)
        sys.exit(1)


def get_audio_duration(audio_path: Path) -> float:
    """Return audio duration in seconds via ffprobe."""
    result = subprocess.run(
        [
            "ffprobe",
            "-v",
            "error",
            "-show_entries",
            "format=duration",
            "-of",
            "default=noprint_wrappers=1:nokey=1",
            str(audio_path),
        ],
        capture_output=True,
        text=True,
        check=True,
    )
    return float(result.stdout.strip())


def build_ffmpeg_command(
    video_in: Path,
    audio_in: Path,
    output: Path,
    target_w: int,
    target_h: int,
    duration: float,
    title: str | None,
) -> list:
    """Build the FFmpeg command for vertical video assembly.

    Pipeline:
    1. Scale + pad source video to target dimensions (1080x1920) with letterbox
    2. Mute the source video's audio (voiceover replaces it)
    3. Mix in ElevenLabs MP3
    4. Optional: overlay title text in the top portion (drawtext)
    5. Trim to audio duration
    6. Output H.264 + AAC, broadly compatible
    """
    # Video filter: scale to fit within target, pad with off-white background
    # Light-mode brand: pad color #FAFAFA = 250,250,250
    # FFmpeg uses 0xRRGGBB
    pad_color = "0xFAFAFA"

    vf_chain = (
        f"scale={target_w}:{target_h}:force_original_aspect_ratio=decrease,"
        f"pad={target_w}:{target_h}:(ow-iw)/2:(oh-ih)/2:color={pad_color}"
    )

    if title:
        # Find a system font for drawtext
        font_candidates = [
            "/System/Library/Fonts/Helvetica.ttc",
            "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
        ]
        font_path = next((p for p in font_candidates if os.path.exists(p)), None)
        if font_path:
            # Escape single quotes and colons in title for FFmpeg
            safe_title = title.replace("'", r"\'").replace(":", r"\:")
            vf_chain += (
                f",drawtext=fontfile='{font_path}':"
                f"text='{safe_title}':"
                f"fontsize=64:"
                f"fontcolor=0x0A0A0A:"
                f"x=(w-text_w)/2:"
                f"y=h*0.08:"
                f"enable='between(t,0.5,3.5)'"
            )

    cmd = [
        "ffmpeg",
        "-y",  # overwrite output
        "-i",
        str(video_in),
        "-i",
        str(audio_in),
        "-filter_complex",
        f"[0:v]{vf_chain}[v]",
        "-map",
        "[v]",
        "-map",
        "1:a",  # use audio from second input (ElevenLabs MP3)
        "-c:v",
        "libx264",
        "-pix_fmt",
        "yuv420p",
        "-preset",
        "medium",
        "-crf",
        "20",  # high quality, reasonable size
        "-c:a",
        "aac",
        "-b:a",
        "192k",
        "-shortest",
        "-t",
        f"{duration:.2f}",
        str(output),
    ]
    return cmd


def main():
    parser = argparse.ArgumentParser(description="Stitch screen recording + ElevenLabs voiceover into vertical video via FFmpeg.")
    parser.add_argument("--video", dest="video_in", required=True, help="Source video (screen recording or face footage)")
    parser.add_argument("--audio", dest="audio_in", required=True, help="ElevenLabs MP3 voiceover")
    parser.add_argument("--output", required=True, help="Output MP4 path")
    parser.add_argument("--title", default=None, help="Optional title overlay (shown 0.5s-3.5s)")
    parser.add_argument("--target-w", type=int, default=1080, help="Output width (default 1080)")
    parser.add_argument("--target-h", type=int, default=1920, help="Output height (default 1920, vertical)")
    parser.add_argument("--duration", type=float, default=None, help="Override output duration (default: audio length)")
    parser.add_argument("--dry-run", action="store_true", help="Print FFmpeg command, don't execute")
    args = parser.parse_args()

    if not Path(args.video_in).exists():
        print(f"Video not found: {args.video_in}", file=sys.stderr)
        sys.exit(1)
    if not Path(args.audio_in).exists():
        print(f"Audio not found: {args.audio_in}", file=sys.stderr)
        sys.exit(1)

    ensure_ffmpeg()

    video_in = Path(args.video_in).resolve()
    audio_in = Path(args.audio_in).resolve()
    output = Path(args.output).resolve()
    title = args.title
    target_w = args.target_w
    target_h = args.target_h
    duration = args.duration
    dry_run = args.dry_run
    output.parent.mkdir(parents=True, exist_ok=True)

    if duration is None:
        duration = get_audio_duration(audio_in)

    cmd = build_ffmpeg_command(video_in, audio_in, output, target_w, target_h, duration, title)

    if dry_run:
        print("DRY RUN — would execute:")
        print(" ".join(f'"{c}"' if " " in c else c for c in cmd))
        return

    print(f"Stitching → {output}")
    print(f"  duration: {duration:.2f}s, dimensions: {target_w}x{target_h}")
    print(f"  title overlay: {'yes' if title else 'no'}")

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"FFmpeg failed (exit {result.returncode}):", file=sys.stderr)
        print(result.stderr, file=sys.stderr)
        sys.exit(result.returncode)

    print(f"\nOK. Output: {output}")
    print(f"Size: {output.stat().st_size // 1024} KB")


if __name__ == "__main__":
    main()
