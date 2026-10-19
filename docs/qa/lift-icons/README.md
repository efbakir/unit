# Exercise icons

Approved on 19 October 2026. Six supplied 24×24 filled SVGs use template-rendered, vector-preserving image sets. No dark duplicates. Assets retain the dotted names from the handoff.

- `AppIcon` owns asset/system rendering. Its internal `Glyph` uses body-relative scaling. `liftIconsAreSymbols` is false; `liftImagesetOpticalScale` is 1.
- `ExerciseIconResolver` owns movement-pattern matching. It normalizes with POSIX locale and matches whole tokens/phrases. Main-lift qualification is unchanged.
- Existing `AppMainLiftCard.iconTile` and `AppIconCircle` own tiles. Cards use 30/20pt, rows 32/20pt, detail 44/28pt. The explicit size table takes precedence over the handoff's conflicting generic 1.6 ratio. Exercise tiles and glyphs cap at 2×; text does not.
- Exercise icons are decorative. Native navigation and control icons stay SF Symbols. The app stays light-only.

## Future custom SF Symbols conversion

In Apple's SF Symbols app, export the static template for `figure.strengthtraining.traditional`. Place each supplied path in Regular-M and align it to the template guides. Validate templates in SF Symbols, then replace the six imagesets with symbolsets using the same asset names. Set `AppIcon.liftIconsAreSymbols` to true and rerun the rendering checks. These interim assets are vectors, not validated custom SF Symbols.

Reference: https://developer.apple.com/documentation/technologyoverviews/custom-sf-symbols

## Rendering notes

Wide native exercise symbols are fitted to the same square glyph bounds as the supplied vectors; otherwise symbols such as `figure.core.training` exceed the tile. This sizing is scoped to exercise glyphs; toolbar and other native icons retain their font sizing.

The dark preview requests a dark environment but retains Unit's approved light-only semantic palette. It is not evidence of a supported dark theme. The contrast preview sets UIKit's high-contrast trait; it does not test the complete system accessibility setting or VoiceOver interaction.

## Verification — 19 October 2026

- iPhone 16 Simulator, iOS 27: Analytics missing-lift, pounds, and AX3 UI test passed. Captures are in this folder.
- Resolver tests cover over 60 names, punctuation/full-width/diacritics, Turkish uppercase inputs, false friends, equipment fallbacks, rename, and unchanged main-lift classification.
- All six assets load by dotted name, report template rendering, and render nonempty pixels.
- Real SwiftUI-rendered comparisons show all six assets and three native fallbacks at row/detail sizes in light, requested-dark, AX3, and high-contrast UIKit traits.
- iOS 18 deployment target retained; no iOS 18 runtime or physical-device verification in this icon pass. Existing unrelated test-target concurrency warnings remain.
- No version change, installation, schema change, or training-data write.
