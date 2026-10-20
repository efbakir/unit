# Workout summary feedback — 20 October 2026

## Request and boundary

Efe requested completed checks at the far right, a common left edge for exercise
titles, and the same shared summary component for completed and upcoming
exercises. Upcoming exercises must have individual flat cards without grouped
separators. This explicitly supersedes the grouped upcoming block in the Final B
brief and the general per-row card prohibition for this workout summary family
only. Programs and History retain their existing list rules.

Started from a clean Programs worktree and merged main at `8e3cf4d`, preserving
the already integrated Programs changes. No new primitive, variant, token,
dependency or data change was needed.

## Owners and changes

- `DesignSystem.swift` → `ExerciseSummaryRow`: reuses `AppCard`, the existing
  summary radius, fonts, grayscale roles and 52pt minimum content height. Its
  12pt horizontal inset matches the expanded exercise header's existing
  8pt card inset plus 4pt header padding. The title can wrap to two lines.
  Completed rows place the reserved Undo slot before the final trailing check;
  upcoming rows have neither Undo nor a check. The selection button announces
  completed/upcoming state and the summary. Undo remains a separate control.
- `ActiveWorkoutView.swift` → `exerciseSummary` and `upcomingExercises`: both
  collapsed paths call the same `ExerciseSummaryRow` configuration. Upcoming
  groups produce individual cards directly in the existing workout list rhythm,
  retaining exercise IDs and the upcoming accessibility identifier.
- Current/expanded logging cards, target calculation, keyboard/focus editors,
  set rows, skip handling, Undo timing, rest, motion, native navigation and
  persistence are unchanged. Existing selection calls `jump(to:)` as before.

## Reuse and reference evidence

The source consumer search found one existing `ExerciseSummaryRow` call and a
separate upcoming `AppCardList` composition. Both now share the existing owner;
there are no other summary consumers to migrate. The expanded sibling
`ExerciseLoggingCard` supplied the common title inset. The existing
`docs/qa/logging-final-b/ios18-compact/final-b-end-of-day.png` capture was inspected
as the before-state anchor; it shows the old leading checks. It is historical
evidence, not a rendering of this change.

## Verification

- Source guards: PASS (`scripts/check-guards.sh`).
- Changed-source UI banned-list hook: PASS.
- Diff whitespace: PASS.
- Source boundary comparison: PASS; only `ExerciseSummaryRow` changed in the
  design system and only the collapsed-summary composition changed in the
  workout screen. RestBar, CurrentSetRow, editors and logging actions are intact.
- No build, test execution, Simulator, phone operation or version change in
  this pass. Edits applied, not yet verified in runtime; central visual pass
  remains required.

Central checks: compare current, completed and upcoming title left edges; check
each upcoming card has its own surface and gap without separators; confirm no
upcoming check, final trailing completed checks, and stationary checks during
Undo expiry. Exercise completed/open, upcoming/jump, skip confirmation and Undo;
review long names, empty targets and large Dynamic Type/VoiceOver. Confirm
current-row keyboard and rest behavior after integrating the parallel changes.
