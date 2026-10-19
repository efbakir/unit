# Analytics R5 screenshots and checks

These are real app captures from isolated iPhone16 Simulator test stores, not mockups or Efe's training history. Build setting remains2.1(84); this work is not installed on the phone.

## Review first: iOS27

- [Main](ios27/r5-main.png): original rounded native bottom navigation retained.
- [Scrolled](ios27/r5-main-scrolled.png): third main lift and compact other-exercise rows.
- [Weighted detail](ios27/r5-detail.png), [bodyweight detail](ios27/r5-detail-other.png), [summary sheet](ios27/r5-summary-info.png).
- [Empty](ios27/r5-empty.png), [baseline](ios27/r5-baseline.png), [fewer sessions](ios27/r5-fewer.png), [missing main lift](ios27/r5-never-logged-scrolled.png), [pounds](ios27/r5-pounds.png), [AX3](ios27/r5-ax3.png).

The corresponding iOS18 captures are in [ios18](ios18/). The older OS's flat native tab bar is expected platform behavior; no custom replacement or change to ContentView's bar composition/appearance was made.

## Run evidence

Integrated runs:46 tests on27 and48 on18 passed. The18 run includes the full progression acceptance/relaunch/history/unit-switch/next-workout journey. Tests use the same read-only engine/formatters as the page. DEBUG fixtures require explicit UI-test flags and an isolated store.

A screenshot review found overlapping final X-axis dates on27. The shared chart input now spaces labels at weeks0,4,7,11 (approximately every4weeks), preserving all12weeks of points. Post-fix runs passed21tests on each OS (18engine and3Analytics UI cases); final captures in both folders come from these runs. Logs: `/private/tmp/unit-analytics-r5-axis-ios27.log` and `/private/tmp/unit-analytics-r5-axis-ios18.log`. Result bundles: `/private/tmp/unit-analytics-r5-build/Logs/Test/`.

The earlier integrated27 run also enabled system dark appearance and Increase Contrast; Unit stayed light. Final post-axis captures use standard light appearance, so the ink chart is visible with normal grid contrast.

## Evidence boundaries

Captured/checked: section order, original27 bar, plain copy, weighted/BW detail, accepted Next, native metric switching, explanation sheet, empty/baseline/fewer/missing/lb/AX3. Empty/baseline/normal/fewer screenshots have distinct hashes. Color tokens meet AA text contrast; no palette changes.

Pending: physical iPhone12 under50ms budget, manual VoiceOver audio/Audio Graph navigation, AX5, system Reduce Motion toggle, chart held-scrub/cancel interaction,40+character/localization screenshots and first-frame loading timing. Native accessibility/gesture owners are implemented; these behaviors are not claimed as fully runtime-verified. See [handoff](../../handoffs/2026-10-19-analytics-r5.md) and [contextual scorecard](../design-evaluation/scorecards/2026-10-19-analytics-r5.md).
