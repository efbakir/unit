#!/usr/bin/env python3
"""
ig_account_fetch.py — Pull public Instagram account data for an account study.

Tier 0 of docs/marketing/account-studies/README.md. Given a handle, fetches
profile stats + recent posts via Apify's Instagram scrapers (no Instagram
login, public data only), saves raw JSON into the account's study folder,
and prints a summary shaped for study.md sections 1-4:
followers, cadence, format split, engagement, top posts by views with the
first caption line as the hook.

Setup (once):
1. Sign up free at https://apify.com (founder does this — $5/mo credit renews monthly)
2. Apify Console → Settings → API & Integrations → copy the API token
3. Paste into docs/marketing/automation/python/.env as APIFY_TOKEN=apify_api_...

Usage:
    python3 ig_account_fetch.py journal.bingen              # profile + last 30 posts
    python3 ig_account_fetch.py noah.rolette --limit 50     # more posts
    python3 ig_account_fetch.py journal.bingen --profile-only

Cost at Apify pay-per-result (verified 2026-06: profile $1.60/1k, posts $1.50/1k):
- One study (1 profile + 30 posts): ~$0.05
- Free $5/mo credit covers ~100 studies/month. No card needed.
"""

import os
import re
import sys
import json
import argparse
import urllib.error
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, List


SCRIPT_DIR = Path(__file__).resolve().parent
ACCOUNT_STUDIES_DIR = SCRIPT_DIR.parents[1] / "account-studies"
APIFY_BASE = "https://api.apify.com/v2"
PROFILE_ACTOR = "apify~instagram-profile-scraper"
POSTS_ACTOR = "apify~instagram-scraper"
# run-sync holds the HTTP connection while the actor runs; IG scrapes for
# ≤50 posts normally finish in 30-90s. Apify caps the sync wait at 300s.
HTTP_TIMEOUT_S = 330


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
            k, v = k.strip(), v.strip()
            if k and k not in os.environ:
                os.environ[k] = v


_load_env(SCRIPT_DIR / ".env")


def run_actor_sync(actor: str, payload: dict, token: str) -> List[dict]:
    """Start an actor run and return its dataset items when it finishes. Stdlib HTTP."""
    # Token goes in the Authorization header, not the query string — keeps the
    # secret out of any URL logging. (Apify accepts either; header is cleaner.)
    qs = urllib.parse.urlencode({"clean": "true", "format": "json"})
    url = f"{APIFY_BASE}/acts/{actor}/run-sync-get-dataset-items?{qs}"
    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {token}"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=HTTP_TIMEOUT_S) as resp:
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        detail = e.read().decode("utf-8", errors="replace")[:300]
        if e.code == 401:
            sys.exit("Apify rejected the token (401). Re-copy it from Console → Settings → API & Integrations.")
        sys.exit(f"Apify error {e.code} on {actor}: {detail}")
    except urllib.error.URLError as e:
        sys.exit(f"Network error reaching Apify ({e.reason}). Check connection and retry.")
    items = json.loads(body)
    if not isinstance(items, list):
        sys.exit(f"Unexpected Apify response shape from {actor}: {str(items)[:300]}")
    return items


def kebab(handle: str) -> str:
    return re.sub(r"[._]+", "-", handle.strip().lstrip("@")).strip("-").lower()


def views_of(post: dict) -> Optional[int]:
    """Reel/video play count across the field names Apify has used."""
    for key in ("videoPlayCount", "igPlayCount", "videoViewCount", "playCount"):
        v = post.get(key)
        if isinstance(v, (int, float)) and v > 0:
            return int(v)
    return None


def first_line(caption: Optional[str]) -> str:
    if not caption:
        return "(no caption)"
    line = caption.strip().splitlines()[0]
    return line[:110] + ("…" if len(line) > 110 else "")


def parse_ts(post: dict) -> Optional[datetime]:
    ts = post.get("timestamp") or post.get("takenAt")
    if not ts:
        return None
    try:
        return datetime.fromisoformat(str(ts).replace("Z", "+00:00"))
    except ValueError:
        return None


def fmt_int(n) -> str:
    return f"{n:,}" if isinstance(n, (int, float)) else "?"


def summarize(profile: Optional[dict], posts: List[dict], handle: str) -> str:
    lines = [f"# {handle} — fetched {datetime.now(timezone.utc).date()}", ""]

    if profile:
        followers = profile.get("followersCount")
        lines += [
            f"- Followers {fmt_int(followers)} · following {fmt_int(profile.get('followsCount'))}"
            f" · posts {fmt_int(profile.get('postsCount'))}"
            f" · {'verified' if profile.get('verified') else 'not verified'}"
            f" · {'PRIVATE' if profile.get('private') else 'public'}",
            f"- Name: {profile.get('fullName') or '?'}",
            f"- Bio: {(profile.get('biography') or '').strip() or '(empty)'}",
            "",
        ]
    else:
        followers = None

    if not posts:
        lines.append("No posts returned (private account, empty profile, or scrape blocked).")
        return "\n".join(lines)

    dated = sorted((p for p in posts if parse_ts(p)), key=parse_ts)
    if len(dated) >= 2:
        span_days = max((parse_ts(dated[-1]) - parse_ts(dated[0])).days, 1)
        per_week = len(dated) / (span_days / 7)
        lines.append(
            f"- Cadence: {len(dated)} posts over {span_days} days "
            f"({parse_ts(dated[0]).date()} → {parse_ts(dated[-1]).date()}) = **{per_week:.1f}/week**"
        )

    kinds = {}
    for p in posts:
        kind = "reel" if (p.get("productType") == "clips" or p.get("type") == "Video") else \
               "carousel" if p.get("type") == "Sidecar" else "image"
        kinds[kind] = kinds.get(kind, 0) + 1
    lines.append("- Format mix: " + " · ".join(f"{k} {v}" for k, v in sorted(kinds.items(), key=lambda x: -x[1])))

    likes = [p.get("likesCount") for p in posts if isinstance(p.get("likesCount"), int) and p.get("likesCount") >= 0]
    comments = [p.get("commentsCount") for p in posts if isinstance(p.get("commentsCount"), int)]
    if likes and isinstance(followers, int) and followers > 0:
        avg_eng = (sum(likes) / len(likes) + (sum(comments) / len(comments) if comments else 0)) / followers
        lines.append(f"- Engagement: avg {fmt_int(round(sum(likes)/len(likes)))} likes"
                     f" · {fmt_int(round(sum(comments)/len(comments))) if comments else '?'} comments"
                     f" · **{avg_eng*100:.2f}%** of followers per post")

    viewed = [(views_of(p), p) for p in posts if views_of(p)]
    viewed.sort(key=lambda x: -x[0])
    if viewed:
        med = viewed[len(viewed)//2][0]
        lines += ["", f"## Top posts by views (median {fmt_int(med)})", ""]
        for v, p in viewed[:7]:
            ratio = f" ({v/med:.1f}× median)" if med else ""
            lines += [f"- **{fmt_int(v)} views{ratio}** · {fmt_int(p.get('likesCount'))} likes · "
                      f"{(parse_ts(p).date() if parse_ts(p) else '?')} · {p.get('url') or ''}",
                      f"  - Hook: {first_line(p.get('caption'))}"]
        lines += ["", "## Bottom of the pack (hook autopsy material)", ""]
        for v, p in viewed[-3:]:
            lines += [f"- {fmt_int(v)} views · {first_line(p.get('caption'))}"]

    return "\n".join(lines)


def main():
    ap = argparse.ArgumentParser(description="Fetch public IG account data into account-studies/<handle>/")
    ap.add_argument("handle", help="Instagram username, with or without @")
    ap.add_argument("--limit", type=int, default=30, help="number of recent posts to fetch (default 30)")
    ap.add_argument("--profile-only", action="store_true", help="skip the posts scrape")
    args = ap.parse_args()

    token = os.environ.get("APIFY_TOKEN", "").strip()
    if not token:
        sys.exit(
            "APIFY_TOKEN is not set.\n"
            "One-time setup: sign up free at https://apify.com, copy the API token from\n"
            "Console → Settings → API & Integrations, paste it into\n"
            f"{SCRIPT_DIR / '.env'} as APIFY_TOKEN=apify_api_..."
        )

    handle = args.handle.strip().lstrip("@")
    out_dir = ACCOUNT_STUDIES_DIR / kebab(handle)
    out_dir.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now(timezone.utc).strftime("%Y-%m-%d")

    print(f"[1/2] Profile: {handle} …", flush=True)
    profile_items = run_actor_sync(PROFILE_ACTOR, {"usernames": [handle]}, token)
    profile = profile_items[0] if profile_items else None
    (out_dir / f"data-{stamp}-profile.json").write_text(
        json.dumps(profile_items, indent=2, ensure_ascii=False), encoding="utf-8")

    posts: List[dict] = []
    if not args.profile_only:
        print(f"[2/2] Last {args.limit} posts …", flush=True)
        posts = run_actor_sync(POSTS_ACTOR, {
            "directUrls": [f"https://www.instagram.com/{handle}/"],
            "resultsType": "posts",
            "resultsLimit": args.limit,
            "addParentData": False,
        }, token)
        (out_dir / f"data-{stamp}-posts.json").write_text(
            json.dumps(posts, indent=2, ensure_ascii=False), encoding="utf-8")

    summary = summarize(profile, posts, handle)
    summary_path = out_dir / f"data-{stamp}-summary.md"
    summary_path.write_text(summary + "\n", encoding="utf-8")

    print("\n" + summary)
    print(f"\nSaved: {out_dir}/data-{stamp}-{{profile,posts}}.json + summary.md")


if __name__ == "__main__":
    main()
