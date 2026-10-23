# Unit 2.1 (90) — decision clarity and shared UI

Installed in place and launched successfully on connected iPhone. All five training
tables unchanged before/after installation; 15 session records and 250 sets. Integrity ok.
Application Support and Preferences backed up in /private/tmp/unit-delivery90;
install, launch and preservation JSON stored there. No reset/uninstall/store upload.

## Changes
- Shared progression completion/History rows: Previous target, Logged, Suggested target,
  changing to Next target only after acceptance. Short reason; Use next workout action.
- Shared filter chips now visibly44pt,15pt sentence-case labels, neutral gray inactive fill.
- Native tab navigation no longer fades the entire navigation stack.
- Shared disclosure gap16pt; existing full-bleed list dividers retained.
- Current set source at top-right; Add set centered. Removed reorder toolbar action;
  direct drag retained. Workout scroll paints through outer gutter to timer edge.
- Inactive logged-row Undo controls replaced with non-interactive spacing. Found during
  regression checks: invisible buttons could still be selected by automation.

No new UI components, variants or tokens. Existing owners reused. No schema change.

## Research
Completed focused desk review: [decision needs](../research/2026-10-21-progression-decision-needs.md).
Official Hevy/Strong/Fitbod flows, saved Mobbin captures, visible App Store reviews
and clearly-limited discussion excerpts. Qualitative, not a representative study.

## Verification
Four distinct focused UI tests passed on compact iOS18 across these bundles:
- /private/tmp/unit-review90.xcresult: keyboard preparation/logging pass; other failures retained.
- /private/tmp/unit-review90b.xcresult: progression outcomes/accept/edit/repeat/persistence/
  next-workout-prefill and History/metric controls pass after outdated Finish selectors corrected.
- /private/tmp/unit-review90d.xcresult: four-set Undo/edit/next-exercise/relaunch pass after hidden Undo fix.
Failed intermediate Undo rerun: /private/tmp/unit-review90c.xcresult (retained, not concealed).
Reviewed progression suggestion, History filter and compact workout screenshots in
[build90 captures](../qa/build90/). Some History screenshots capture a content entrance
in flight; do not interpret that blur as a static treatment. Signed device build
succeeded (/private/tmp/unit-device90-build.log); guards pass.

Limits: no fresh iOS27 Simulator, full purchase, VoiceOver, AX or exhaustive
all-screen run. Physical install/launch confirmed; tactile/visual phone review is
for the user. Marketing artwork separator examples have not been comprehensively
reworked; no blanket claim that every divider across the entire product was audited.
Source remains local dirty main; no push.
