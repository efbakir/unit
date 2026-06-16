#!/usr/bin/env python3
"""
quote_cards.py — Pillow-based social media quote-card generator for Unit.

Produces branded vertical (1080x1920) and horizontal (1200x675) PNGs for
attaching to TikTok/IG, X, and Reddit posts. No API keys required.

Brand spec (per docs/DESIGN.md, docs/marketing/anti-patterns.md, PRODUCT.md):
- Light mode (no dark backgrounds — Unit is light-first)
- Calm, expert, honest voice (no hype, no exclamation marks)
- Off-white background (#FAFAFA), accent #0A0A0A (per CLAUDE.md banned-list rules)
- System font (SF Pro on macOS); falls back to DejaVu Sans on Linux
- No emoji, no decorative gradients

Usage:
    python3 quote_cards.py                # generate all default cards
    python3 quote_cards.py --list         # list available cards
    python3 quote_cards.py --card launch  # generate one specific card
    python3 quote_cards.py --output-dir /tmp/cards  # custom output dir
"""

import os
import sys
import argparse
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont


# === Brand spec ===
BG_COLOR = (250, 250, 250)         # #FAFAFA off-white
TEXT_COLOR = (10, 10, 10)          # #0A0A0A near-black (per CLAUDE.md, NOT #FF4400)
SUBTLE_COLOR = (110, 110, 110)     # #6E6E6E for secondary text
ACCENT_LINE_COLOR = (10, 10, 10)   # for divider lines

# === Font discovery ===
FONT_CANDIDATES_BOLD = [
    "/System/Library/Fonts/SFNSRounded.ttf",
    "/System/Library/Fonts/Supplemental/Helvetica.ttc",
    "/System/Library/Fonts/Helvetica.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf",
    "/Library/Fonts/Arial Bold.ttf",
]
FONT_CANDIDATES_REGULAR = [
    "/System/Library/Fonts/SFNS.ttf",
    "/System/Library/Fonts/Helvetica.ttc",
    "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    "/Library/Fonts/Arial.ttf",
]


def find_font(candidates):
    for p in candidates:
        if os.path.exists(p):
            return p
    raise RuntimeError(f"No font found in {candidates}. Install a system font or pass --font-path.")


def load_font(size, bold=False):
    path = find_font(FONT_CANDIDATES_BOLD if bold else FONT_CANDIDATES_REGULAR)
    return ImageFont.truetype(path, size)


# === Card definitions ===
# Each card: (id, output_filename, dimensions, headline, subtext, footer)
# Headlines are pulled from docs/marketing/templates/ and twitter-x-30-day-content
CARDS = [
    {
        "id": "launch",
        "filename": "launch-quote-card.png",
        "size": (1080, 1920),
        "headline": "Three months solo.",
        "headline2": "Just shipped.",
        "subtext": "Unit — a 3-second gym logger for lifters who hate spreadsheets.",
        "footer": "Free on App Store",
    },
    {
        "id": "launch-twitter",
        "filename": "launch-quote-card-twitter.png",
        "size": (1200, 675),
        "headline": "Three months solo. Just shipped.",
        "headline2": None,
        "subtext": "Unit — a 3-second gym logger.",
        "footer": "Free on App Store",
    },
    {
        "id": "notebook",
        "filename": "notebook-vs-unit-card.png",
        "size": (1080, 1920),
        "headline": "Notebook: 8.1s",
        "headline2": "Unit: 2.4s",
        "subtext": "Same set. One hand. Same lift.",
        "footer": "Free on App Store",
    },
    {
        "id": "free-tier",
        "filename": "free-tier-promise-card.png",
        "size": (1080, 1920),
        "headline": "Core logging.",
        "headline2": "Free forever.",
        "subtext": "Set logging, ghost values, rest timer, history, PRs — never paywalled.",
        "footer": "Pro is for export and Health sync.",
    },
    {
        "id": "anti-bloat",
        "filename": "anti-bloat-card.png",
        "size": (1080, 1920),
        "headline": "No AI coach.",
        "headline2": "No social feed. Just sets.",
        "subtext": "Unit removes everything that slowed your last gym app down.",
        "footer": "Free on App Store",
    },
    {
        "id": "speed-claim",
        "filename": "speed-claim-card.png",
        "size": (1080, 1920),
        "headline": "Set logged.",
        "headline2": "2.4 seconds.",
        "subtext": "Ghost values pre-fill last session. Tap Done. Timer starts.",
        "footer": "Free on App Store",
    },
]


def render_card(card, output_dir):
    w, h = card["size"]
    img = Image.new("RGB", (w, h), BG_COLOR)
    draw = ImageDraw.Draw(img)

    # Margins
    margin_x = int(w * 0.08)
    margin_top = int(h * 0.18)

    # Headline sizing — bigger on vertical, scaled on horizontal
    if h > w:
        headline_size = int(w * 0.085)
        subtext_size = int(w * 0.035)
        footer_size = int(w * 0.030)
    else:
        headline_size = int(h * 0.13)
        subtext_size = int(h * 0.05)
        footer_size = int(h * 0.04)

    headline_font = load_font(headline_size, bold=True)
    subtext_font = load_font(subtext_size, bold=False)
    footer_font = load_font(footer_size, bold=False)

    # === Top: brand mark ===
    brand_size = int(headline_size * 0.4)
    brand_font = load_font(brand_size, bold=True)
    draw.text((margin_x, margin_top - brand_size - 16), "UNIT", font=brand_font, fill=TEXT_COLOR)
    # Underline accent
    brand_bbox = draw.textbbox((margin_x, margin_top - brand_size - 16), "UNIT", font=brand_font)
    line_y = brand_bbox[3] + 6
    draw.rectangle(
        [margin_x, line_y, brand_bbox[2], line_y + 3],
        fill=ACCENT_LINE_COLOR,
    )

    # === Headline (left-aligned, 1-2 lines) ===
    cursor_y = margin_top + int(headline_size * 0.5)
    draw.text((margin_x, cursor_y), card["headline"], font=headline_font, fill=TEXT_COLOR)
    cursor_y += headline_size + int(headline_size * 0.1)

    if card.get("headline2"):
        draw.text((margin_x, cursor_y), card["headline2"], font=headline_font, fill=TEXT_COLOR)
        cursor_y += headline_size + int(headline_size * 0.4)
    else:
        cursor_y += int(headline_size * 0.3)

    # === Subtext (wrapped) ===
    subtext = card["subtext"]
    sub_lines = wrap_text(subtext, subtext_font, w - 2 * margin_x, draw)
    for line in sub_lines:
        draw.text((margin_x, cursor_y), line, font=subtext_font, fill=SUBTLE_COLOR)
        cursor_y += subtext_size + 6

    # === Footer (bottom) ===
    footer = card["footer"]
    footer_bbox = draw.textbbox((0, 0), footer, font=footer_font)
    footer_w = footer_bbox[2] - footer_bbox[0]
    footer_x = margin_x  # left-aligned, calm
    footer_y = h - margin_x - footer_size
    draw.text((footer_x, footer_y), footer, font=footer_font, fill=TEXT_COLOR)

    # Save
    output_path = output_dir / card["filename"]
    output_dir.mkdir(parents=True, exist_ok=True)
    img.save(output_path, "PNG", optimize=True)
    return output_path


def wrap_text(text, font, max_width, draw):
    """Word-wrap text to fit max_width using the given font."""
    words = text.split()
    lines = []
    current = []
    for word in words:
        candidate = " ".join(current + [word])
        bbox = draw.textbbox((0, 0), candidate, font=font)
        width = bbox[2] - bbox[0]
        if width <= max_width:
            current.append(word)
        else:
            if current:
                lines.append(" ".join(current))
            current = [word]
    if current:
        lines.append(" ".join(current))
    return lines


def main():
    parser = argparse.ArgumentParser(description="Generate Unit-branded social quote cards.")
    parser.add_argument("--card", default=None, help="Render only this card by id (default: render all)")
    parser.add_argument("--output-dir", default=None, help="Output directory (default: ../sample-output relative to this script)")
    parser.add_argument("--list", action="store_true", dest="list_cards", help="List available cards and exit")
    args = parser.parse_args()

    if args.list_cards:
        print("Available cards:")
        for c in CARDS:
            print(f"  - {c['id']}: {c['filename']} ({c['size'][0]}×{c['size'][1]})")
        return

    if args.output_dir is None:
        script_dir = Path(__file__).parent
        output_dir = (script_dir / ".." / "sample-output").resolve()
    else:
        output_dir = Path(args.output_dir).resolve()

    targets = CARDS if args.card is None else [c for c in CARDS if c["id"] == args.card]
    if not targets:
        print(f"No card with id '{args.card}'. Run with --list to see available cards.", file=sys.stderr)
        sys.exit(1)

    for c in targets:
        path = render_card(c, output_dir)
        print(f"  wrote {path}")

    print(f"\nGenerated {len(targets)} card(s) in {output_dir}")


if __name__ == "__main__":
    main()
