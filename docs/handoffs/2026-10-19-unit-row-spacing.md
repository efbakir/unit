# Unit 2.1 (70): row spacing and navigation cues

Installed in place and launched normally on the connected iPhone. Application source: `62fef5c`; earlier padding commit: `1cf13e2`.

## Changes and owners

- `PreviewListRow` in `Unit/UI/DesignSystem.swift`: recessed rows own their horizontal inset and symmetric vertical breathing. Today’s identity-first content is centered within its existing minimum instead of being top-aligned. Programs’ compact rows now have a 64pt minimum and 16pt vertical padding; full row labels remain tappable. Existing stacked card-list rows keep their established padding.
- `PreviewListContainer`: removed the second layer of outer content padding. Separator overlays span the recessed surface edge to edge. Viewport estimates match the taller compact rows; overflow still reveals the next title. Today and Programs share this fix.
- `AppDividedList`: removed inset separator options; the training-week consumer now uses full-width separators. `AppCardList` already owns full-bleed dividers and retains that behavior.
- Shared preview disclosures and the active-program header reuse existing `AppColor.textTertiary` for lighter arrows. Days remain grouped rather than introducing individual card variants.
- No new components, tokens or visual variants. SF Pro, brand colors, radii, motion and logging behavior retained.

## Evidence

- Signed Debug build: **BUILD SUCCEEDED** (`/private/tmp/unit-row-spacing-70-final-build.log`).
- **2.1 (70)** installed over the existing app and launched without test flags. No uninstall or reset.
- Before/after stores are row-identical across all five tables: **9 templates, 12 workouts, 208 sets, 951 exercises, 1 split**. SQLite integrity OK; kg retained; recovery notice false.
- Guards and all 26 mutation fixtures passed. No tests or Simulator runs restarted, following the user’s phone-first instruction. New source compiled and launched; final visual spacing and touch feel remain for phone review.
- Evidence: `/Users/efbakir/.codex/worktrees/unit-release-20261019/evidence/row-spacing-70/` (install/launch JSON, preservation and binary provenance).
- Contextual source/screenshot scorecard: `docs/qa/design-evaluation/scorecards/2026-10-19-today-row-spacing.md`. No official post-fix visual score.

Review Today’s exercise rows and Programs’ grouped day rows on the phone. The separate PR113-inspired motion follow-on starts from `62fef5c` and is not included in build 70.
