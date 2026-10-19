# Native tab-bar correction — 2026-10-19

The prior Analytics screenshot showed a full-width forced edge behind the floating tab bar. Removed three overrides at their shared owners:

- `appScrollEdgeSoft` no longer forces `.hard` or `.soft`. Existing call sites remain compatible, with no appearance modification.
- `AppScreen` no longer adds an outer `.clipped()` around its native scrolling region.
- `ContentView` no longer applies a `UITabBarItem` title-font appearance override.

No replacement background, gradient, material, component or token. Native TabView owns its appearance; Analytics content and build84 remain unchanged. This supersedes the earlier hard-edge preference.

Apple reference: [scrollEdgeEffectStyle](https://developer.apple.com/documentation/swiftui/view/scrolledgeeffectstyle(_:for:)) documents that the scroll view renders an automatic effect by default.

Before: [R5 screenshot](../analytics-r5/ios27/r5-main.png). After: [main](r5-main.png), [scrolled](r5-main-scrolled.png), [detail](r5-detail.png).

Verification: focused `AnalyticsR5UITests/testNormalCardsSummaryAndDetails` on iPhone16/iOS27; final log `/private/tmp/unit-native-tabbar-final.log`. Source guard and whitespace checks passed. No phone install or version bump. Other shared-screen consumers were source-traced, not exhaustively screenshot-tested in this small correction.
