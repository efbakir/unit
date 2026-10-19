# Unit scroll-driven native bars — 2.1 (79)

## Correction
Build76 forced navigation material visible at rest, producing a differently coloured header strip. Both AppScreen and appNavigationBarChrome now use `toolbarBackgroundVisibility(.automatic, for: .navigationBar)` and no custom background style. ContentView only sets navigation text/tint; it no longer installs standard, compact or scroll-edge background appearances. SwiftUI/UIKit own the transition between unscrolled and scroll-under states.

AppScreen’s pinned header/action regions are layout siblings, with no scrolling content behind them. They now match the page surface without always-visible material/separators. Actual native bars retain their automatic material/separation. Existing hard vertical scroll-edge styling, native sheets and tabs remain. No gradients reintroduced. No sizes, spacing, typography, card styling, list separators, data schema, components or tokens changed.

Apple sources: [SwiftUI automatic toolbar background visibility](https://developer.apple.com/documentation/swiftui/view/toolbarbackgroundvisibility(_:for:)), [TN3106: remove custom navigation backgrounds for modern system effects](https://developer.apple.com/documentation/technotes/tn3106-customizing-uinavigationbar-appearance).

## Evidence and delivery
Static guards/diff checks passed. No tests or Simulator runs, per user instruction. Runtime before/after scrolling visual confirmation remains pending. Signed build succeeded. Build79 installed in place and launched normally. Before/after table hashes and checked preferences match, integrity ok, 214 sets retained. Preservation evidence: files under `/private/tmp/unit-scroll-bars-79/`, log `/private/tmp/unit-scroll-bars-79-build.log`. Development-only, no public submission. Checkpoint tag `unit-dev-2.1-79-20261019`.
