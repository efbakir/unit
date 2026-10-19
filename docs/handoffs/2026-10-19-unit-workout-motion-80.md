# Unit workout layout and motion — 2.1 (80)

## Root causes and applied changes
- SetProgressIndicator was24pt before the first log and44pt once an editable chip appeared. Every state now reserves the existing44pt interactive height; visible24pt chips are unchanged. This removes the first-save20pt downward jump.
- WorkoutCommandCard previously removed its CTA after the2.5s confirmation, removed Adjust when completed, and removed supporting copy when a starting target became a logged set. Those changes moved the timer. The existing60pt CTA slot now stays in layout (hidden/noninteractive after completion); the metric keeps its Adjust-caption space; a support/badge line stays reserved. No font, icon or button sizes changed. These reserved spaces can make the unlogged/finished card taller than before; they deliberately replace state-dependent collapsed geometry.
- RestTimerControl had separate idle/running label branches. It now keeps one hierarchy and a flexible centre column; +/- remain anchored and chrome crossfades. Existing text, numeric motion and touch sizes are retained.
- Exercise UUID keys only the card’s exercise-content region inside a ZStack, reusing AppBlurTransition/transition timing from PlateSteps. The timer is outside this identity boundary. The old screen-level withAnimation on exercise selection is removed. Legitimate layout changes (long names/stacked PR evidence) use collectionChange; they are not forced into a fixed-height card. Outgoing-card callbacks cannot prepare/log a different exercise after a handoff.
- PR badge/evidence stay inline when they fit and stack when necessary. Pending prior-exercise PR feedback is invalidated at a handoff. Existing2.5s saved confirmation and single haptic remain.
- Set-chip state replacements reuse asymmetric normal-blur arrival and0.92 shrink/blur removal, including deletion/Undo; existing exact-set snapshots and save-before-success ordering are unchanged. No new view, token, style variant, schema or logging delay.

## Read-only references
- `/Users/efbakir/plate/Plate/Components/Motion/PlateSteps.swift`: identity-scoped blur/fade handoffs.
- `/Users/efbakir/plate/Plate/Components/Motion/PlateReveal.swift`: one removal and fade-only reduced-motion behavior.
- `/Users/efbakir/plate/docs/2-design/design-system.md`: Motion, take/give back, instant changes.
Plate was not modified.

## Evidence and delivery
Static source guards/diff checks passed. Final signed compilation succeeded. Build80 installed in place and launched normally; before/after table hashes and checked preferences match, integrity ok, 216 sets retained. No tests or Simulator runs, per instruction; no runtime visual verification claimed. Review first set, final-set checkmark expiry, next exercise, long exercise names, PR and Delete/Undo on the phone. Existing Reduce Motion/VoiceOver gates remain, but these paths were not exercised. Evidence `/private/tmp/unit-workout-motion-80/`; build log `/private/tmp/unit-workout-motion-80-build.log`. Development-only, no store submission. Local tag `unit-dev-2.1-80-20261019`.
