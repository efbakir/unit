# Custom app icons — fallback de-risk scope (2026-05-31)

> **Why this exists:** a pull-the-trigger plan *if* Apple bounces the v1.0.0 IAPs under Guideline 3.1.1 ("purchase doesn't deliver the advertised features"). Today a Pro purchase delivers only founding-supporter status; all four advertised features are "coming soon". Shipping **one** real, advertised Pro feature flips that. Custom app icons is the smallest buildable one and is already committed in `docs/pricing.md` ("Custom app icons (4–6 variants)"). Not a scope-fence issue.
>
> Do not build yet. This is the scope, not the work. No simulator/build per CLAUDE.md §6.

---

## Headline

**The bottleneck is artwork, not code.** The Swift + project-config scaffolding is ~half a day. The 4–6 on-brand icon variants are a design task I can't produce — they gate the whole feature. Build only if review bounces, or to strengthen the first submission.

---

## What ships

- 3–6 alternate home-screen icons (`pricing.md` commits to **4–6**; 3 is the MVP floor). On-brand = light/quiet, accent `0x0A0A0A`. Candidate set: Light (default), Dark/Black, Mono.
- A Pro-gated **App icon** row in Settings → opens an icon picker sheet → tap to apply.
- Non-Pro tap → routes to the paywall (identical to the existing Export / Apple Health rows in `dataSection`).

## Work breakdown

1. **Assets (design — blocking, not codeable by me).** 4–6 variants, each a 1024×1024 PNG, **no alpha**. Add each as its own `*.appiconset` in `Unit/Assets.xcassets` (primary `AppIcon` already exists). Suggested names: `AppIconDark`, `AppIconMono`, …
2. **Project config** (`Unit.xcodeproj/project.pbxproj`, main target **Debug + Release** — both, kept in sync; widget target untouched):
   - add `ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`
   - add `ASSETCATALOG_COMPILER_ALTERNATE_APPICON_NAMES = "AppIconDark AppIconMono …"`
   - keep `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` (primary stays default)
3. **Icon model.** New enum — name it `HomeScreenIcon` or `AppIconChoice`. **Do NOT reuse `AppIcon`** — that name is already an SF-Symbol enum at `DesignSystem.swift:523`. Reusing it is the exact §4 parallel-naming trap. Each case: asset name (nil for primary), display label, thumbnail image.
4. **Apply logic.** Thin wrapper over `UIApplication.shared.setAlternateIconName(_:)` (main thread; `nil` = primary). Read current state with `.alternateIconName`; gate on `.supportsAlternateIcons`. No persistence needed — iOS remembers the choice across launches; just read it on appear to show the selected row.
5. **Picker UI — reuse-first (stays inside §4).** An `AppSheetScreen`-wrapped vertical list of `AppListRow`s: leading icon thumbnail + name + trailing checkmark on the selected one. Reuses `AppSheetScreen` + `AppListRow`, **no new grid primitive**.
   - Richer alternative (a `LazyVGrid` of icon swatches) needs a new tile component → **run `/component-reuse-check` first**. Recommend the list path for v1.
6. **Settings entry.** New row in `preferencesSection` (next to "Weight unit"). Pro gate mirrors `dataSection`: `store.isPurchased ? showPicker : (showingPaywall = true)`. Trailing = current icon name (Pro) or a `PRO` `AppTag` (non-Pro).
7. **Flip the "coming soon" framing.** Once shipped: change `PaywallView.swift` benefit row `"Custom app icons (coming soon)"` → `"Custom app icons"`, and reconcile the `asc-submission.md` Review-risk note + description. This row stops being a 3.1.1 liability — that's the whole point.

## Gotchas

- **System alert is unavoidable** — iOS shows "You have changed the icon for Unit" on every change. Do not try to suppress it (private API → rejection risk). Designed-around, not fought.
- Each `*.appiconset` should carry the full iPhone size set (or a single 1024 with `INCLUDE_ALL_APPICON_ASSETS`). No alpha channel.
- `project.pbxproj` edits must hit both main-target configs in sync — the 2026-05-12 bundle-ID entry in `decision-log.md` is the cautionary tale for config drift across configs.
- UIKit call from SwiftUI → wrap on the main actor.

## Reference anchor

`docs/references/ios-screens/neuecast__appearance-settings.png` — closest anchor for an appearance/icon-selection screen. `details/` is empty; if the picker grows past a simple list, confirm the anchor before inventing.

## De-risk math

- **Before:** Pro purchase delivers only founding status; 4/4 advertised features "coming soon".
- **After:** 1/4 advertised features is real + visible. A reviewer who buys Pro and changes the icon sees a delivered, advertised feature — materially strengthens the IAP review.
- **Cost:** ~0.5 day code/config + the artwork (the real cost).

## Gate before building

- Artwork exists first — code is inert without it.
- `/component-reuse-check` before declaring any new picker component (§4).
- No `xcodebuild` / simulator until the user asks (§6).
