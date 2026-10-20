# Build85 gym feedback — integrated source handoff

## Result
The feedback package is integrated on main. No phone operation or version/build change was performed during this pass. The phone remains on previously delivered 2.1 (85); these changes are source/Simulator only until Efe requests another installation.

## Dedicated chats and changes
- Unit · Programs navigation: ExerciseSummaryRow is shared by completed/upcoming exercises, each in a separate flat card. Titles align; completed check sits after Undo at the far trailing edge. Flat exercise-ID list preserves identity through current/completed transitions. Programs schedule-mode row branches use existing fades/collection motion.
- Unit · Logging and rest redesign: one shared blue primary action for Save target/Complete, explicit separate behavior. Full-width balanced native inputs. Current action and equal-width accessory buttons live in SwiftUI safeAreaInset above the keyboard; no constrained keyboard ToolbarItem. Drafts remain separate from valid targets/history.
- Unit · QA and release: RestBar blue deadline-based timeline, stable fading label/control slots, reduced-motion/VoiceOver gates; chart metric drawing fades without interpolating incompatible units or delaying direct scrub. Debug UI tests do not inherit/create external Live Activities. Normal device behavior is unchanged.
- Unit Analytics implementation: exact app-motion audit, footer transition, onboarding schedule/paste-format fades, main-card ID-keyed collection motion after first display. Native controls/navigation remain native.
- Unit · Icons and color: actual Mobbin JOI main/completed/highlight/detail evidence and official identity check. Shared Analytics summary is editorial/page-level; Best/Next labels use existing muted style. Workout title roles are existing17pt, numeric values retain30/28pt. Blue plus grayscale retained. No new icon work.

## Existing owners reused / modified
DesignSystem.swift: ExerciseSummaryRow, ExerciseLoggingCard, CurrentSetRow, AppPrimaryButton, RestBar, AppTrendChart, AppStatusSummaryCard, AppMainLiftCard, existing AppMotion/AppFont/AppSpacing/AppRadius/AppColor. Feature owners: ActiveWorkoutView, MainLiftsEditor, AnalyticsView, TemplatesView and onboarding schedule/import compositions. No new design component, token, palette color, asset or dependency. No model/schema/progression change. Native TabView untouched.

## JOI reference and decisions
Primary source: Mobbin MCP, specifically Joi: Daily Planner & Organizer. Main/completed/highlight/detail screenshots and a reference comparison live in docs/research/joi-evidence-2026-10-20; mapping and links in docs/research/2026-10-20-joi-visual-language.md. Borrow restrained hierarchy and surfaces, not JOI coral/dark panels/faint numeric text/custom bottom navigation. Exact JOI font sizes/motion are not inferred from stills. This is a bounded shared-system simplification, not a claim every app screen was redesigned.

## Verification
- Production source through01b9c9c; test-wait adjustmentb01cebe. Build passed for iOS27 and iOS18.6 Simulator. Guards and whitespace checks pass.
- iOS27: existing four-set/Undo/edit/automatic next/relaunch test passed; Analytics normal/main/info/detail + Weight/Reps/Volume test passed. /private/tmp/unit-gym-feedback-check.xcresult. That initial suite had one outdated hidden-control existence assertion failure; it is not a wholly passing run.
- A follow-up exposed constrained iOS27 keyboard toolbar layout and keyboard-layout timing. Replaced toolbar with full-width safe-area controls and checked real hit readiness. Final explicit prepare→keyboard Complete regression PASSED on iOS27 (/private/tmp/unit-gym-keyboard-final27.xcresult) and compact iOS18.6 SE (/private/tmp/unit-gym-keyboard-final18.xcresult). Saving target created no set; explicit Complete created one and advanced.
- The two failed-run diagnostic collectors stalled in simctl diagnose (600-second capture). Stopped only those diagnostic subprocesses after tests finished; Xcode closed readable result bundles. No successful run was interrupted.
- Viewed actual screenshots: individual current/upcoming/completed cards, trailing check/Undo, blue rest line, Analytics summary and keyboard actions. On iOS27 and compact18 buttons are single-line, full-width and reachable above the keyboard. Files: docs/qa/build85-gym-feedback. Screens show isolated fixture values, not Efe’s training data.
- Existing tests/unit model evidence from build85 remains historical; no full unit or purchase regression suite rerun here because this pass changes presentation.

## Limits / next review
Full live motion recording/frame measurement, physical haptics, VoiceOver/Reduce Motion interaction, invalid-input relaunch, long/localized names and all onboarding/Programs variants have not received fresh exhaustive runtime review. Source gates and relevant focused flows were checked. Paywall broad reflow remains a verification target; no speculative ancestor animation was added because of earlier compact CTA clipping. The app-wide audit records these boundaries. No claim of bug-free/full-release readiness.

## Review
Look at the logging keyboard Save target versus Complete action, aligned exercise headers and trailing checks, individual upcoming cards, and Analytics’ quieter summary. Ask for installation when ready; do not overwrite the current gym session or auto-upgrade the phone.
