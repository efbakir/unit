# Unit automatic exercise handoff — 2.1 (81)

- Existing WorkoutCommandCard now exposes optional `onSetConfirmationFinished`, reusing its existing cancellation-aware2.5s saved-set dwell. No second task/duration or new component/token/visual variant.
- ActiveWorkoutView uses that event to advance only if the same exercise still has all planned sets completed, another exercise exists, the session is unfinished, and no exercise picker/editor/cancel/finish/skip confirmation is open. Undo reducing completion or user navigation prevents a stale jump.
- The next exercise uses existing accepted-target/history/starting-target prefill and the build80 identity-scoped blur/fade. Empty history remains empty; no weights are invented and no next set is recorded automatically.
- goToNextExercise now preserves rest and its scheduled alert when leaving a completed exercise. Explicitly skipping an unfinished exercise still stops rest. No automatic Finish workout on the final exercise.
- No typography/layout, persistence-schema or recorded-history changes. Preparation and logging remain separate.

## Evidence and delivery
Static source guards/diff checks passed. Signed compilation succeeded. Build81 installed in place and launched normally. Before/after table hashes and checked preferences match, integrity ok, 218 sets retained. No tests or Simulator runs, per user instruction. Automatic handoff, modal interruption, Undo and timer continuity have not been exercised visually on the phone. Evidence `/private/tmp/unit-auto-next-81/`; log `/private/tmp/unit-auto-next-81-build.log`. Development-only; no store submission. Local tag `unit-dev-2.1-81-20261019`.
