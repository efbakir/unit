#!/usr/bin/env python3
"""
buffer_schedule.py — Schedule social posts to Buffer via the Buffer API.

Per docs/marketing/automation-map.md:
- ✅ TikTok / IG Reels / YouTube Shorts / X scheduling — automated via this script
- ❌ Reddit posting — NEVER via Buffer or any 3rd-party scheduler (ban risk)

Per safety rules:
- Posting to social channels requires explicit user confirmation
- This script prompts for confirmation by default; --yes flag skips for orchestration

Usage:
    python3 buffer_schedule.py --list-channels
    python3 buffer_schedule.py \\
        --channel tiktok \\
        --text "Logging a set in 2.4s. One-handed. Sweaty." \\
        --media sample-output/video/tradesman-1-bench-press.mp4 \\
        --when "2026-05-13 10:00:00 ET"
    python3 buffer_schedule.py --dry-run --channel tiktok --text "test" --media sample.mp4 --when "now"
"""

import os
import sys
import argparse
from pathlib import Path
from datetime import datetime, timezone
from zoneinfo import ZoneInfo
import requests


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

BUFFER_API_BASE = "https://api.bufferapp.com/1"

# Channel slug → env-var mapping for profile IDs
CHANNEL_ENV_MAP = {
    "tiktok": "BUFFER_TIKTOK_PROFILE_ID",
    "ig": "BUFFER_IG_PROFILE_ID",
    "instagram": "BUFFER_IG_PROFILE_ID",
    "x": "BUFFER_X_PROFILE_ID",
    "twitter": "BUFFER_X_PROFILE_ID",
    "yt": "BUFFER_YT_SHORTS_PROFILE_ID",
    "youtube": "BUFFER_YT_SHORTS_PROFILE_ID",
}


def get_token() -> str:
    token = os.environ.get("BUFFER_ACCESS_TOKEN", "").strip()
    if not token:
        print("BUFFER_ACCESS_TOKEN not set in .env", file=sys.stderr)
        sys.exit(1)
    return token


def list_profiles(token: str):
    """List all Buffer profiles available to this token."""
    url = f"{BUFFER_API_BASE}/profiles.json?access_token={token}"
    r = requests.get(url, timeout=30)
    r.raise_for_status()
    return r.json()


def parse_when(when_str: str) -> int:
    """Parse a flexible time string and return Unix timestamp.

    Accepts:
    - "now" → current time + 60s buffer (Buffer rejects "right now" sometimes)
    - "2026-05-13 10:00:00 ET" → that local time
    - "2026-05-13T14:00:00Z" → UTC
    - Unix int → as-is
    """
    when_str = when_str.strip()
    if when_str == "now":
        return int(datetime.now(timezone.utc).timestamp()) + 60

    if when_str.isdigit():
        return int(when_str)

    # Try ISO 8601 first
    try:
        dt = datetime.fromisoformat(when_str.replace("Z", "+00:00"))
        return int(dt.timestamp())
    except ValueError:
        pass

    # Try "YYYY-MM-DD HH:MM:SS TZ" with named timezone
    parts = when_str.rsplit(" ", 1)
    if len(parts) == 2:
        dt_str, tz_str = parts
        tz_aliases = {"ET": "America/New_York", "PT": "America/Los_Angeles", "UTC": "UTC"}
        tz_name = tz_aliases.get(tz_str.upper(), tz_str)
        try:
            tz = ZoneInfo(tz_name)
            dt = datetime.strptime(dt_str, "%Y-%m-%d %H:%M:%S")
            dt = dt.replace(tzinfo=tz)
            return int(dt.timestamp())
        except (ValueError, KeyError):
            pass

    raise ValueError(f"Could not parse --when value: {when_str!r}")


def upload_media(media_path: Path, token: str, profile_id: str) -> dict:
    """Upload media to Buffer and return reference. Buffer's media upload is
    a multipart POST; the response contains URLs that go in the update payload.

    Note: Buffer has been deprecating direct media uploads in favor of profile-
    pre-attached media. This function uses the legacy v1 endpoint which still
    works for video at the time of this script's creation. If it stops working,
    fall back to passing a publicly accessible URL via `--media-url`.
    """
    url = f"{BUFFER_API_BASE}/profiles/{profile_id}/uploads.json?access_token={token}"
    with media_path.open("rb") as f:
        files = {"media": (media_path.name, f, "video/mp4" if media_path.suffix.lower() == ".mp4" else "image/png")}
        r = requests.post(url, files=files, timeout=300)
    r.raise_for_status()
    return r.json()


def create_update(
    token: str,
    profile_id: str,
    text: str,
    scheduled_at: int,
    media_path: Path | None = None,
    media_url: str | None = None,
) -> dict:
    """Schedule a single post via Buffer's `updates/create` endpoint."""
    url = f"{BUFFER_API_BASE}/updates/create.json"
    data = {
        "access_token": token,
        "profile_ids[]": profile_id,
        "text": text,
        "scheduled_at": scheduled_at,
    }

    if media_path:
        upload = upload_media(media_path, token, profile_id)
        # Buffer returns various keys depending on type; pass through
        if "url" in upload:
            data["media[link]"] = upload["url"]
        if "thumbnail" in upload:
            data["media[thumbnail]"] = upload["thumbnail"]
        if "picture" in upload:
            data["media[picture]"] = upload["picture"]
    elif media_url:
        data["media[link]"] = media_url

    r = requests.post(url, data=data, timeout=120)
    r.raise_for_status()
    return r.json()


def main():
    parser = argparse.ArgumentParser(description="Schedule a single Buffer update.")
    parser.add_argument("--channel", help="Channel slug (tiktok, ig, x, yt)")
    parser.add_argument("--text", help="Post body text")
    parser.add_argument("--media", dest="media_path", default=None, help="Path to image or video to attach")
    parser.add_argument("--media-url", default=None, help="Publicly accessible media URL (alternative to --media)")
    parser.add_argument("--when", dest="when_str", help="Schedule time (e.g., '2026-05-13 10:00:00 ET' or 'now')")
    parser.add_argument("--list-channels", action="store_true", help="List Buffer profiles available and exit")
    parser.add_argument("--dry-run", action="store_true", help="Show payload without calling API")
    parser.add_argument("--yes", action="store_true", help="Skip confirmation (for orchestration)")
    args = parser.parse_args()

    channel = args.channel
    text = args.text
    media_path = args.media_path
    if media_path:
        if not Path(media_path).exists():
            print(f"Media file not found: {media_path}", file=sys.stderr)
            sys.exit(1)
    media_url = args.media_url
    when_str = args.when_str
    list_channels = args.list_channels
    dry_run = args.dry_run
    yes = args.yes

    token = get_token()

    if list_channels:
        profiles = list_profiles(token)
        print(f"Found {len(profiles)} Buffer profile(s):\n")
        for p in profiles:
            print(f"  {p.get('service', '?'):10s} | id={p.get('id', '?')} | name={p.get('formatted_username', p.get('service_username', '?'))}")
        print("\nAdd these IDs to your .env (BUFFER_TIKTOK_PROFILE_ID, etc.)")
        return

    if not channel or not text or not when_str:
        print("Required: --channel, --text, --when. Run with --list-channels first if you don't have profile IDs yet.", file=sys.stderr)
        sys.exit(1)

    env_var = CHANNEL_ENV_MAP.get(channel.lower())
    if not env_var:
        print(f"Unknown channel '{channel}'. Use one of: {', '.join(CHANNEL_ENV_MAP.keys())}", file=sys.stderr)
        sys.exit(1)
    profile_id = os.environ.get(env_var, "").strip()
    if not profile_id:
        print(f"{env_var} not set in .env", file=sys.stderr)
        sys.exit(1)

    scheduled_ts = parse_when(when_str)
    scheduled_dt = datetime.fromtimestamp(scheduled_ts, tz=timezone.utc).astimezone()

    if media_path:
        media_path = Path(media_path).resolve()

    print(f"Scheduling to {channel} (profile {profile_id})")
    print(f"  when: {scheduled_dt.isoformat()} (Unix {scheduled_ts})")
    print(f"  text: {text[:60]}{'...' if len(text) > 60 else ''}")
    if media_path:
        print(f"  media: {media_path.name} ({media_path.stat().st_size // 1024} KB)")
    elif media_url:
        print(f"  media URL: {media_url}")
    else:
        print(f"  media: (none)")

    if dry_run:
        print("\nDRY RUN — not calling API.")
        return

    if not yes:
        confirm = input("\nProceed with scheduling? [y/N]: ")
        if confirm.strip().lower() != "y":
            print("Cancelled.")
            sys.exit(0)

    result = create_update(
        token=token,
        profile_id=profile_id,
        text=text,
        scheduled_at=scheduled_ts,
        media_path=media_path,
        media_url=media_url,
    )

    if result.get("success"):
        print(f"\nOK. Buffer update id: {result.get('updates', [{}])[0].get('id', '?')}")
    else:
        print(f"\nBuffer reported failure: {result}")
        sys.exit(1)


if __name__ == "__main__":
    main()
