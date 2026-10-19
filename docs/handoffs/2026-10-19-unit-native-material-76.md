# Unit native material bars — 2.1 (76)

## Changed at shared owners
- `ContentView.configureNavigationBarAppearance`: native default material at standard, compact and scroll-edge sizes; stop clearing the system separator. Existing title fonts/colours retained.
- `appNavigationBarChrome` and `AppScreen`: native SwiftUI `.bar` material and visible native bar background; no opaque colour/transparent edge override.
- Existing `appScrollEdgeSoft` name retained for caller compatibility. Its policy now uses native hard vertical scroll-edge effects on iOS26+ (including iOS27), soft horizontal content clipping and the native material navigation-bar fallback on iOS18. This is the user’s explicit replacement for the old soft-only policy.
- `AppScreenChromeBackground`: system `.bar` material on pinned headers and primary/secondary action bars. Existing `AppDivider` gives their full-width boundary as an overlay, preserving geometry. Manual top/bottom gradients and their scroll-driven state are removed. Explicit viewport clipping keeps content out of pinned chrome.
- `appBottomSheetChrome`: no forced opaque sheet background; iOS owns the sheet surface. Native tabs, toolbar buttons and pickers retain their native treatments.
- No new component, token or variant. No sizing, typography, padding, radii, palette-value or content-card changes. Shared source-of-truth rules and decision log updated.

## Evidence and limits
- Signed iPhone Debug compilation succeeded: `/private/tmp/unit-material-76-build.log`.
- Static guards and whitespace checks passed. No tests or Simulator runs, per instruction. No runtime visual or iOS18 validation claimed. Review Today/Programs/Analytics headers, a scrolled History page and an editor sheet on the phone.
- [Apple HIG scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views) describes native hard edges as opaque blur with a defined boundary, in contrast with the softer fade. The API is available from iOS26; this is not presented as an iOS27-only API.

## Delivery
Normal launch succeeded. Before/after table hashes and checked preferences are identical. Integrity ok. Counts: ZDAYTEMPLATE=9, ZWORKOUTSESSION=13, ZSETENTRY=213, ZEXERCISE=951, ZSPLIT=1. Build76 installed in place; launch/readback evidence in `/private/tmp/unit-material-76/`. Signed artifact in `/private/tmp/unit-motion-build/Build/Products/Debug-iphoneos/Unit.app`. Local checkpoint tag `unit-dev-2.1-76-20261019`; development-only, no remote push or public submission.
