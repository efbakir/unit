# Unit workout readout — 2.1 (84)

Tightened weight × reps spacing without changing the 36pt readout size. The existing WorkoutTargetFormatter now owns compact metric spacing: thin spaces around × and narrow nonbreaking spaces between weight and kg/lb. WorkoutCommandCard and SetProgressIndicator both use that owner. Original accessible metric text, input sizes, timer, padding, and logging behavior remain unchanged. No new tokens, components, or variants.

Source guards and diff checks passed; signed device compilation succeeded. No tests or Simulator runs, per request. Build 84 installed in place and launched normally. Before/after training-table counts and row hashes match: 9 templates, 13 sessions, 221 sets, 951 exercises, 1 split. Prepared targets match; database integrity ok. Visual appearance has not been reviewed on-device. Backups and delivery evidence: /private/tmp/unit-spacing-84/. Build log: /private/tmp/unit-spacing-84-build.log.

Development-only; no store submission. Local checkpoint: unit-dev-2.1-84-20261019.
