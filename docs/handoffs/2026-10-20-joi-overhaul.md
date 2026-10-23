# JOI visual overhaul

This continues the original JOI request beyond build 86's four small adjustments.
Reference: `docs/research/2026-10-20-joi-visual-language.md` and its actual Mobbin
comparison sheet. Borrow open page hierarchy, quiet secondary controls and
restrained grouping. Retain Unit's blue, SF fonts, legible workout numbers,
separate exercise summary cards and native navigation.

## Shared system

- Existing `AppColor.background` becomes near-white #FAFAFA. Secondary controls
  use #F0F0F0 and their active fill #E5E5E5. Accent remains #0068E0.
- `AppCard`, its modifier and `SettingsSection` default to 16pt gutters;
  `AppCardRowChrome` and `AppListRow` align to the same gutter.
- `PreviewListContainer` no longer puts a gray rounded surface inside a card.
- `EmptyStateCard` presents leading-aligned content on the page.
- `AppSectionHeader` uses existing 15pt secondary typography.
- Exercise summaries give the name its own line and allow metadata to wrap.
  Upcoming exercises retain readable active text; completed titles are quieter.
- Stacked preview rows now render their supporting evidence, rather than only
  announcing it to VoiceOver.
- Confirmed primary actions reject repeat activation while showing the outcome.
- Earlier title/pencil alignment, plain exercise menu and dark toolbar edits
  are included.

No new design-system components, variants, font roles, dependencies or schema.
Existing numeric sizes, button heights and card radius tokens remain.

## Screens and states

- Today: page-level routine heading, full exercise list, fixed Start action.
- Programs: open program heading and Edit pencil, full routine list.
- Routine and library detail: plain targets and shared list groups.
- Logging: one expanded exercise, separate completed/upcoming cards, one native
  Finish action, one empty-workout add action.
- Analytics: open detail result above its chart, readable Next/Recent stacks,
  shared explanation-sheet layout and retry after failed first fetch.
- History: open calendar, consistent month headings.
- Settings/setup: fewer unnecessary wrappers, consistent section rhythm.
- Recovered routines omitted from stale program ordering. Save failures retain
  editor drafts and keep affected screens open. Switching away from an unsaved
  target releases the editor while retaining the raw draft.

## Verification

Built and exercised on the dedicated iOS 27 Simulator with isolated fixtures.
Six focused UI tests passed across three runs:
- Four-set logging, Undo, editing, automatic next exercise and relaunch.
- Keyboard starting-target preparation followed by explicit logging.
- Analytics normal, explanation sheet, weighted metrics and bodyweight detail.
- Analytics empty, baseline and fewer-sessions states.
- Programs navigation and edit access.
- Complete workout and update flow.

The finish test initially failed because scripted deletion at the start of a
native text field inserted 65 before 60. The test now uses the visible weight
step controls and passes; no production workaround was added for that test.

Screenshots: [review captures](../qa/joi-overhaul-2026-10-20/).
Visually inspected logging, keyboard, Analytics detail/info, Today rest state,
Programs and routine detail. These captures use test data, not personal history.
Source guards and whitespace checks pass. Existing test concurrency and
AppIntents extraction warnings remain; this is not a warning-free claim.

Evidence bundles (local temporary files):
- `/private/tmp/unit-joi-overhaul-check.xcresult`: four passing tests.
- `/private/tmp/unit-joi-overhaul-final.xcresult`: Programs pass and initial finish-test failure.
- `/private/tmp/unit-joi-overhaul-finish.xcresult`: corrected finish test pass.

Limits: no fresh iOS 18, physical-device, purchase, VoiceOver or large-text run.
Save-error recovery and stale ordering fixes were source-reviewed, not exercised
with injected storage failures. Settings, library and setup have shared styling
changes but were not all independently captured in this pass.
No version change, phone installation, push or App Store action in this pass.
