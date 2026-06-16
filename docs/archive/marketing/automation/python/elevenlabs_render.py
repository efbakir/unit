#!/usr/bin/env python3
"""
elevenlabs_render.py — Generate voice-over audio from voiceover-library.md.

Reads docs/marketing/scripts/voiceover-library.md, parses individual scripts
(each H3 section), and calls the ElevenLabs Text-to-Speech API to render each
to MP3.

Per docs/marketing/elevenlabs-protocol.md:
- Voice MUST be the cloned voice of the founder (set ELEVENLABS_VOICE_ID)
- Audio is paired with REAL screen recordings only (never AI visuals or stock B-roll)
- Settings: stability=0.50, clarity=0.75, style=0.0, speaker_boost=off
  (calm narration; tweak only if cloned voice sounds robotic)

Usage:
    python3 elevenlabs_render.py --list              # show all available scripts
    python3 elevenlabs_render.py --week 3 --dry-run  # preview what would render
    python3 elevenlabs_render.py --week 3            # actually call API
    python3 elevenlabs_render.py --script tradesman-1-bench-press
    python3 elevenlabs_render.py --all               # render every script (caution: cost)

Cost estimate at ElevenLabs Starter ($5/mo, 30k chars):
- Average script: ~300 chars → ~1¢
- Full library (17 scripts × ~300 chars): ~5¢ each render run, ~17¢ total
- Starter tier covers ~100 full-library renders/month
"""

import os
import re
import sys
import json
import argparse
from pathlib import Path
from dataclasses import dataclass
from typing import Optional, List
import requests


SCRIPT_DIR = Path(__file__).parent


def _load_env(path: Path):
    """Tiny .env loader (replacement for python-dotenv) — populates os.environ."""
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


@dataclass
class Script:
    """Parsed voiceover script from voiceover-library.md."""

    section: str          # "founder-vlog", "tradesman", "educational", "notebook-vs-unit"
    index: int            # ordinal within section
    title: str            # e.g. "Why I built Unit"
    slug: str             # e.g. "founder-1-why-i-built-unit"
    script_body: str      # the actual paste-into-ElevenLabs text
    word_count: int


def parse_voiceover_library(library_path: Path) -> List[Script]:
    """Parse voiceover-library.md into Script objects.

    The file structure is loose markdown:
        ## A. Founder vlog full scripts
        ### Founder Vlog 1 — "Why I built Unit"
        - Length: 90s / 245 words / ~98s
        ...
        **Visual notes:**
        ...
        **Script:**
        ```
        [the script body]
        ```
    """
    content = library_path.read_text(encoding="utf-8")
    scripts = []

    # Split on H2 sections to identify A/B/C/D buckets
    section_map = {
        "founder vlog": "founder-vlog",
        "tradesman demo": "tradesman",
        "educational": "educational",
        "notebook-vs-unit": "notebook-vs-unit",
        "notebook vs unit": "notebook-vs-unit",
    }

    # Walk H3 headings
    h3_pattern = re.compile(r"^### (.+)$", re.MULTILINE)
    matches = list(h3_pattern.finditer(content))

    for i, m in enumerate(matches):
        title_line = m.group(1).strip()
        # Skip the "How to use these in ElevenLabs" section headings and similar
        skip_keywords = [
            "how to use", "voice settings", "format pairing", "iteration",
            "workflow", "checklist", "tips", "settings", "pairing", "platform",
        ]
        if any(skip in title_line.lower() for skip in skip_keywords):
            continue

        start = m.end()
        end = matches[i + 1].start() if i + 1 < len(matches) else len(content)
        body = content[start:end]

        # Determine section by walking back to nearest H2
        h2_before = re.findall(
            r"^## (.+)$",
            content[: m.start()],
            re.MULTILINE,
        )
        section_label = "unknown"
        if h2_before:
            last_h2 = h2_before[-1].lower()
            for key, val in section_map.items():
                if key in last_h2:
                    section_label = val
                    break

        # Extract the script body — looking for the last fenced code block in the section
        # OR everything after "Script:" / "**Script**" if present
        script_body = extract_script_body(body)
        if not script_body:
            continue

        # Word count
        word_count = len(script_body.split())

        # Skip noise — real scripts are at least 30 words
        if word_count < 30:
            continue

        # Compute slug
        clean_title = re.sub(r"[^\w\s-]", "", title_line.lower())
        clean_title = re.sub(r"\s+", "-", clean_title.strip())
        index = sum(1 for s in scripts if s.section == section_label) + 1
        slug = f"{section_label}-{index}-{clean_title[:40]}".strip("-")

        scripts.append(
            Script(
                section=section_label,
                index=index,
                title=title_line,
                slug=slug,
                script_body=script_body,
                word_count=word_count,
            )
        )

    return scripts


def extract_script_body(section_text: str) -> Optional[str]:
    """Extract the TTS-ready script body from a section.

    Handles the actual voiceover-library.md format produced by the Sonnet agent:

        ### A1 — Title
        **Length:** ... | **Word count:** ... | **Duration:** ...
        **Visual notes:** ...
        ---
        [SCRIPT BODY GOES HERE]
        ---

    Strategy:
    1. Look for content between two `---` separators (current format)
    2. Otherwise look for fenced code blocks
    3. Otherwise look for content after "Script:" marker
    """
    # Format 1: between --- separators
    # Find all `---` lines (ATX-style hr)
    hr_matches = list(re.finditer(r"(?:^|\n)---\s*(?:\n|$)", section_text))
    if len(hr_matches) >= 2:
        first_end = hr_matches[0].end()
        second_start = hr_matches[1].start()
        body = section_text[first_end:second_start].strip()
        if body:
            return body
    if len(hr_matches) == 1:
        # only one `---` — assume it precedes the body, take everything after
        body = section_text[hr_matches[0].end():].strip()
        if body:
            return body

    # Format 2: fenced code blocks
    fences = re.findall(r"```(?:\w*)?\n(.*?)\n```", section_text, re.DOTALL)
    if fences:
        return fences[-1].strip()

    # Format 3: after "Script:" marker
    script_match = re.search(
        r"\*?\*?Script:?\*?\*?\s*\n(.+?)(?:\n##|\Z)",
        section_text,
        re.DOTALL,
    )
    if script_match:
        return script_match.group(1).strip()

    return None


def render_with_elevenlabs(
    text: str,
    api_key: str,
    voice_id: str,
    stability: float,
    clarity: float,
    style: float,
    speaker_boost: bool,
) -> bytes:
    """Call ElevenLabs Text-to-Speech API. Returns audio bytes (MP3)."""
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}"
    headers = {
        "Accept": "audio/mpeg",
        "Content-Type": "application/json",
        "xi-api-key": api_key,
    }
    payload = {
        "text": text,
        "model_id": "eleven_multilingual_v2",  # current best for English; supports voice clones
        "voice_settings": {
            "stability": stability,
            "similarity_boost": clarity,
            "style": style,
            "use_speaker_boost": speaker_boost,
        },
    }
    response = requests.post(url, headers=headers, json=payload, timeout=120)
    if response.status_code != 200:
        raise RuntimeError(
            f"ElevenLabs API error {response.status_code}: {response.text[:500]}"
        )
    return response.content


def script_belongs_to_week(script: Script, week: int) -> bool:
    """Map a script to which week of the 12-week-calendar it serves.

    Heuristic mapping:
    - Founder vlogs 1-4: rotated W1-W4 (one per week pre-launch and W4 retro)
    - Tradesman demos 1-5: rotated W3 onwards
    - Educational 1-5: rotated W4 onwards
    - Notebook vs Unit 1-3: every 2 weeks starting W3
    """
    # Simple modular mapping; refine when calendar drives this
    if script.section == "founder-vlog":
        return script.index == ((week - 1) % 4) + 1
    if script.section == "tradesman":
        if week < 3:
            return False
        return script.index == ((week - 3) % 5) + 1
    if script.section == "educational":
        if week < 4 or week % 2 != 0:
            return False
        return script.index == (((week - 4) // 2) % 5) + 1
    if script.section == "notebook-vs-unit":
        if week < 3 or week % 2 != 1:
            return False
        return script.index == (((week - 3) // 2) % 3) + 1
    return False


def main():
    parser = argparse.ArgumentParser(description="Render voiceovers from voiceover-library.md via ElevenLabs.")
    parser.add_argument("--library", default=None, help="Path to voiceover-library.md (defaults to repo)")
    parser.add_argument("--list", action="store_true", dest="list_scripts", help="List parsed scripts and exit")
    parser.add_argument("--week", type=int, default=None, help="Render only scripts mapped to this week (1-12)")
    parser.add_argument("--script", default=None, dest="script_id", help="Render one specific script by slug")
    parser.add_argument("--all", action="store_true", dest="render_all", help="Render every script (cost warning)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would render without calling API")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: ../sample-output/audio/)")
    args = parser.parse_args()

    library = args.library
    list_scripts = args.list_scripts
    week = args.week
    script_id = args.script_id
    render_all = args.render_all
    dry_run = args.dry_run
    output_dir = args.output_dir

    if library is None:
        library = (SCRIPT_DIR / ".." / ".." / "scripts" / "voiceover-library.md").resolve()
    else:
        library = Path(library).resolve()

    if not library.exists():
        print(f"Library not found: {library}", file=sys.stderr)
        sys.exit(1)

    scripts = parse_voiceover_library(library)

    if list_scripts:
        print(f"Parsed {len(scripts)} scripts from {library}:\n")
        for s in scripts:
            print(f"  [{s.section:18s}] #{s.index} '{s.title[:50]}' — {s.word_count}w — slug={s.slug}")
        return

    # Filter to render set
    if script_id:
        targets = [s for s in scripts if s.slug == script_id]
        if not targets:
            print(f"No script with slug '{script_id}'. Run --list to see slugs.", file=sys.stderr)
            sys.exit(1)
    elif week is not None:
        targets = [s for s in scripts if script_belongs_to_week(s, week)]
        if not targets:
            print(f"No scripts mapped to week {week}.", file=sys.stderr)
            sys.exit(1)
    elif render_all:
        targets = scripts
    else:
        print("Specify --week N, --script SLUG, --all, or --list. See --help.", file=sys.stderr)
        sys.exit(1)

    # Output dir
    if output_dir is None:
        output_dir = (SCRIPT_DIR / ".." / "sample-output" / "audio").resolve()
    else:
        output_dir = Path(output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    if dry_run:
        print(f"DRY RUN — would render {len(targets)} script(s) to {output_dir}:\n")
        total_chars = 0
        for s in targets:
            chars = len(s.script_body)
            total_chars += chars
            print(f"  {s.slug}.mp3 ← {chars} chars / {s.word_count} words")
        print(f"\nTotal: {total_chars} chars (~${total_chars / 1000 * 0.30:.2f} at ElevenLabs Starter)")
        return

    # Real render
    api_key = os.environ.get("ELEVENLABS_API_KEY", "").strip()
    voice_id = os.environ.get("ELEVENLABS_VOICE_ID", "").strip()
    if not api_key or not voice_id:
        print("ELEVENLABS_API_KEY and ELEVENLABS_VOICE_ID must be set in .env", file=sys.stderr)
        sys.exit(1)

    stability = float(os.environ.get("ELEVENLABS_STABILITY", "0.50"))
    clarity = float(os.environ.get("ELEVENLABS_CLARITY", "0.75"))
    style = float(os.environ.get("ELEVENLABS_STYLE", "0.0"))
    speaker_boost = os.environ.get("ELEVENLABS_SPEAKER_BOOST", "false").lower() == "true"

    print(f"Rendering {len(targets)} script(s) to {output_dir}...\n")
    for s in targets:
        out_path = output_dir / f"{s.slug}.mp3"
        if out_path.exists():
            print(f"  SKIP (already exists): {out_path.name}")
            continue

        print(f"  rendering: {s.slug} ({s.word_count}w)... ", end="", flush=True)
        try:
            audio = render_with_elevenlabs(
                s.script_body,
                api_key=api_key,
                voice_id=voice_id,
                stability=stability,
                clarity=clarity,
                style=style,
                speaker_boost=speaker_boost,
            )
            out_path.write_bytes(audio)
            print(f"OK ({len(audio)} bytes)")
        except Exception as e:
            print(f"FAIL: {e}")

    print(f"\nDone. Audio in {output_dir}")


if __name__ == "__main__":
    main()
