# Target sheet and workout scroll polish

Scope: latest founder feedback; swiftui-pro (design/navigation/accessibility) and better-ui review. Existing dirty working tree retained. No version bump or phone installation.

| Severity | Owner | Before | After | Reason |
|---|---|---|---|---|
| Medium | SessionDetailView recommendation editors | Narrow weight field beside prominent reps stepper | Two equal-width native text fields, same existing appInputFieldStyle and performance font; weight decimal/reps integer keyboard | Consistent size, surface and input behavior |
| Medium | SessionDetailView evidenceLine | Proportional15 vs17 emphasized values | Existing15pt monospaced performance role throughout; next target bold | Comparable values remain the same size |
| Medium | AppCopy.Workout | Set the next target | Set a target next workout | Clarifies where the manual action happens |
| Medium | AppScreen child-owned scrolling | Fixed16pt outer vertical gutter, compensated by disabled clipping | Scroll viewport reaches its safe-area boundary; WorkoutDayList owns inner padding | Removes hidden strip above rest footer |
| Medium | ActiveWorkout native toolbar | Transparent header over scrolling cards | Native visible background using existing page color | Stable workout title/timer backdrop |

AppSheetScreen and OnboardingShell restore their fixed-content padding when bypassing the outer ScrollView. This preserves all non-workout consumers. No new components, tokens, variants or palette values. Shared AppInlineWeightField and AppStepper remain unchanged for their other consumers.

Checks: device compilation passed before final keyboard-focus adjustment; iOS18 Simulator logging completion/Undo/edit/automatic-next/relaunch passed. Target input widths and heights matched in Simulator. Screenshots inspected in docs/qa/target-polish-2026-10-21. Final keyboard/save validation result recorded below.

Not verified: physical-device visual behavior, iOS27 runtime, continuous frame-by-frame scroll motion, VoiceOver and larger Dynamic Type. Do not describe this as a whole-app QA pass. Source review covered touched owners and their consumers, not every past change.

Additional review finding: the old ViewThatFits composition created two editable copies of each field. Replaced it with one flexible HStack so focus has a single target per input. Both fields share the existing input style; Save validates weight and the recommendation's allowed rep interval. Empty/invalid text cannot overwrite the target. Keyboard dismissal reuses the existing AppSheetScreen keyboard control, mounted with the sheet so it is available on first focus.

Final verification: progression contract passed on iOS18 Simulator (unit-target-polish5.xcresult): equal input width/height, empty reps blocks Save, keyboard Done, edit/repeat/accept, persisted decisions, next-workout prefill, History detail. Logging flow passed in unit-target-polish.xcresult. Earlier validation runs failed on cursor selection and missing keyboard dismissal; fixed and rerun. Final Simulator build passed. Approve: inspected source/screenshot scope only; runtime motion/platform limits above remain.

## Phone delivery
At the user's request, built and installed development version2.1(91) in place on the connected iPhone. Device build succeeded. Backup and install receipts: /private/tmp/unit-delivery91. Compared all rows before/after:15 sessions,250 sets,9 templates,951 exercises,1 split identical; SQLite integrity ok. Launch was blocked by the locked device; unlock requested. No uninstall or data reset.
