# Unit 2.1 (85) — combined delivery

## Changes
- Final B full-day workout logging: inline current set, completed/planned rows, five-second Undo, automatic next exercise, persistent fixed rest bar, native keyboard editing and Finish Update/Keep. Saving a starting target prepares sets without logging.
- Fixed failed-edit draft preservation, current-row overrides, pounds round-trip drift, planned-row setup edits, duplicate empty weight units and native Finish dialog handoff.
- Analytics now includes valid legacy Bench Press history whose equipment is Other/unspecified; actual phone history contained four valid 72.5 kg × 7 sets. No stored equipment or history changed. Main lifts can be chosen/reordered with a native List editor; automatic selection uses logged lifts.
- Approved blue semantics at shared owners: focus, primary actions and chart selection. Charts/data, completed markers and PR tags remain ink. Shared chevrons are smaller and tertiary.
- Programs has icon-only Edit, no Active chip, and no exercise disclosure chevrons in day detail. Latest six-icon artwork is limited to supported Analytics exercises.

## Shared additions / reuse
Approved WorkoutDayList, ExerciseLoggingCard, CurrentSetRow, LoggedSetRow, PlannedSetRow, ExerciseSummaryRow, RestBar and setValue role reuse existing card/button/field/motion owners in DesignSystem.swift. Approved AppTag.ink variant, optional Analytics icon support and native feature-specific MainLiftsEditor. No new palette, schema or charting dependency.

## Source
Runtime checkpoint f4a4752 on main; includes Analytics 437d963, 6af80f6, ffc69be, documentation d421384 and icon ae4d8ef. Device build is 2.1 (85), development-only and not reserved/uploaded to App Store Connect.

## Evidence
- Integrated build 85: 75 unit tests passed (28 Analytics, 14 logging state, 8 timer, 25 progression persistence), iOS 27 Simulator. Result: /private/tmp/unit-build85-check.xcresult.
- Signed device-target build succeeded. Local codesign strict verification reported CSSMERR_TP_NOT_TRUSTED; device accepted the installation. AppIntents metadata extraction warning is present.
- Earlier focused logging UI runs passed on iOS 18.6 compact SE (2 flows: first target/Keep and full day/Update) and iOS 27 (full day/Update). Screenshots: docs/qa/logging-final-b. These precede the final blue/icon/Analytics integration; do not treat them as final combined visual proof.
- Previous Analytics comparison evidence: docs/qa/analytics-comparison-evidence. Latest native main-lift editor UI tests have not been rerun; engine regressions passed.
- Source guards and whitespace checks passed.

## Phone
Installed in place on connected iPhone 00008150-00064558340A401C. Full Library backup before installation: /private/tmp/unit-delivery85/before (plus before-live recovery copy). Post-install read-back confirms all five training tables and preferences identical; database integrity ok. No uninstall/reset/test flags used. Launch currently blocked by device lock, awaiting unlock. Evidence: /private/tmp/unit-delivery85.

## Remaining checks
Confirm normal launch after unlock and postlaunch data comparison. Physical haptics, Lock Screen rest delivery, purchase sandbox, full VoiceOver/Reduce Motion and latest combined visual sweep remain unverified. No public submission performed. Review the new whole-day workout screen and Analytics selections.
