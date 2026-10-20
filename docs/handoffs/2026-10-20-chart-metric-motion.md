# Chart metric motion — M5

## Source finding and change

`AppTrendChart` matched current main byte-for-byte before this edit. The metric picker owns only its chrome; the sibling chart had no metric-change presentation owner. This establishes a source gap, not an observed phone glitch. Native runtime behavior remains unverified.

Extended the existing `AppTrendChart` only, in `Unit/UI/DesignSystem.swift`:

- Keep the Chart, selected-date state, gesture state, descriptor and overlay mounted. No `.id(metric)`, snapshot chart, cached chart data, root reveal or new primitive/token.
- On a selected-metric change, apply the new data/domain immediately with chart drawing animation disabled. Hide that replacement in its initial transaction, then reveal the drawing and caption using the existing `AppMotion.transition` after one cancellable yield. No duration-based delay and no interpolation from kg to reps/volume.
- The scrub overlay sits outside the drawing opacity modifier and stays fully present. Scrub mutations have no animation attached. Clear the previous selection on the effective selected metric, including the bodyweight reps override; hide stale tooltip values during the metric handoff.
- The first mount sets only a presentation marker in a disabled-animation transaction. It never fades in on initial load, ordinary data refresh, tab return or a steady metric.
- This is opacity-only in all appearance/accessibility settings. No travel, blur, bounce or new haptic.

No `ExerciseProgressView`, native Picker, ActiveWorkoutView, CurrentSetRow, RestBar, timer, model or calculation changes.

## Evidence and queue

- `scripts/check-guards.sh`: PASS.
- `git diff --check`: PASS.
- `swiftc -frontend -parse Unit/UI/DesignSystem.swift`: PASS, syntax only.
- Ownership check: only AppTrendChart differs from this worktree's previous checkpoint.
- No build, test run, Simulator or device operation. Main owns integrated runtime verification.

Main should record Weight → Reps → Volume → Weight on the exercise detail chart, including rapid metric switches and an immediate scrub after each tap. Check the caption, Y domain, tooltip, release/cancel and Audio Graph descriptor use the selected metric. Confirm no impossible intermediate values, chart remount, focus loss or new page entrance. Repeat Reduce Motion and VoiceOver; the intended presentation is a fade, with direct manipulation immediate. The existing AnalyticsR5 UI test already taps the three metrics, but its settled assertions alone cannot establish motion quality or scrub responsiveness.
