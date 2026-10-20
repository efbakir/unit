# Implementation prompt: Unit active workout logging + rest (Final B)

> Efe: paste everything below the line into the coding model. Attach these files from `final-B/`:
> - `final-B-a.png`, `final-B-b.png`, `final-B-c.png`, `final-B-d.png`, `final-B-e.png`, `final-B-f.png`, `final-B-g.png`
> - `final-B-compact.png` and `final-B-board.png`
>
> The wireframes use illustrative data and Geist / Geist Mono, which is Unit's real AppFont. Circles with a check are `checkmark.circle.fill`. ✕ = `xmark`, ⋯ = `ellipsis`, ✎ = `pencil`, ↺ = `arrow.uturn.backward`.

---

## Contents
0. How to work (read first)
1. Goal and voice
2. Scope and non-goals
3. Files to touch
4. Data model (no schema change)
5. Screen structure and states
6. Layout spec (sizes, fonts, colours)
7. Every user-facing string
8. Interactions
9. Rest timer model
10. Live Activity and notifications
11. Accessibility and Dynamic Type
12. Motion and Reduce Motion
13. Edge cases
14. Offline and data integrity
15. Existing bugs this change must fix
16. Tests
17. Acceptance criteria
18. Checklist
Appendix: verified Apple API references

## 0. How to work (read first)
- **Repo and stack.** `efbakir/unit`: SwiftUI + SwiftData, deployment target iOS 18.0. Work in Efe's local checkout.
- **Read first:** `CLAUDE.md`, `DESIGN.md`, `DESIGN_SYSTEM.md`, `docs/visual-language.md`, and the latest `docs/handoffs/2026-10-19-unit-*` notes. They cover builds 75–82: the upNext fix, auto-advance, and the reserved slots and blur.
- **No invented data or copy.** Don't invent data, fields, metrics or copy beyond this spec. If something needs data the models don't have, stop and list it under **"Questions / blocked"**.
- **Components need approval.** At the top of your first answer, list "New components requiring approval", one line each. Expected:
  - `WorkoutDayList`
  - `ExerciseLoggingCard`
  - `CurrentSetRow`
  - `LoggedSetRow`
  - `PlannedSetRow`
  - `ExerciseSummaryRow`
  - `RestBar`
  - an `AppFont.setValue` case (Geist Mono bold 30, relative to `.title`)

  Build approved components in `Unit/UI/DesignSystem.swift` using its existing patterns. Reuse `AppPrimaryButton`, `AppColor`, `AppFont`, `AppSpacing`, `AppRadius`, `AppHaptic` and `AppToast`. No one-off styles inside the screen.
- **Logic goes in a pure type.** Put the row-state derivation, guard timing, upNext text and Finish diff in a pure, testable type: `Unit/Features/Today/WorkoutLoggingState.swift` (new). Views only render it.
- **No SwiftData schema changes.** No migration, and no field added to `SetEntry`, `WorkoutSession`, `Exercise` or `DayTemplate`. If you think one is required, stop and ask.
- **Small diffs.** Keep changes small and reviewable. Old `WorkoutCommandCard`, `SetProgressIndicator`, `RestTimerControl` and `SessionStateBar` code may be deleted only after you've confirmed no other screen uses it (grep). Otherwise leave it in place, unused by this screen.

## 1. Goal and voice
In the gym, one tap logs the set you're about to do. You can always see the whole day, and nothing on screen is said twice.

Voice: ultra-minimal. Short nouns. No exclamation marks, no coaching, no emoji. Use only the strings in §7.

## 2. Scope and non-goals
**In scope:**
- `ActiveWorkoutView` (active logging and rest)
- the rest timer, its notification and its Live Activity
- the Finish flow's routine-update prompt

**Out of scope:**
- Analytics, Programs, onboarding, purchases/paywall, the tab bar, the Today tab outside this screen, and the History UI
- the progression engine (`DoubleProgressionEngine`, `captureProgressionRecords`). Call it exactly as today.
- Live Activity buttons and `LiveActivityIntent`. Keep the Live Activity display-only (§10).
- Warm-up sets, RPE/RIR UI, supersets, plate math, per-exercise rest durations, and dark mode work

## 3. Files to touch
- `Unit/Features/Today/ActiveWorkoutView.swift` (2,061 lines)
  - **`ActiveWorkoutView`:**
    - `body` (L387) currently uses `.safeAreaInset(edge: .bottom)` with `SessionStateBar` and keeps `.toolbar(.hidden, for: .tabBar)`.
    - `sectionModels`, `currentSection`, `nextSection`, `selectedExerciseIndex`
    - `completeSuggestedSet` (L920), `completeSet` (L982), `updateSet` (L1068), `deleteSet` (L1091), `undoRemovedSet` (L1106)
    - `savePreparedTarget` (L950), `preparedTargets`, `clearPreparedTarget`
    - `startRestTimer` (L864), `adjustRestTimer` (L884), `toggleRestTimer` (L851), `goToNextExercise` (L894), `advanceAfterCompletedSet` (L907)
    - `finishWorkout` (L1144), `plannedSetCount` (L1192), `isLoggingSet`, `setLoggedPhase`, `noKeyboardSetCount`, `showsReadyState`, `restDurationSeconds` (`@AppStorage`, default 120)
  - **`AdjustResultSheet` (L1270):** its `.prepare` / edit modes are replaced by inline editing. Keep it only if another caller exists.
  - **`ActiveWorkoutViewModel.prefillSet` (L1655):** keep its precedence: current session → accepted progression → prior session → planned.
  - **`RestTimerManager` (L1726):** see §9 and §10.
  - **`SetPrefill` (L1618):** stays Codable and unchanged.
- `Unit/Features/Today/RestTimerAttributes.swift`: `ContentState(startDate, endDate, upNext)`. No change to the shape.
- `UnitWidget/RestTimerLiveActivity.swift`: render `upNext` as today, plus the `isStale` handling in §10.
- Models, read and write as today with no schema change:
  - `Unit/Models/SetEntry.swift`: `weight` (canonical kg), `reps`, `isWarmup`, `isCompleted`, `setIndex`, `note`, `isValidCompletedWorkingSet`, `SetEntrySnapshot`
  - `WorkoutSession.swift`
  - `Exercise.swift`: `isBodyweight`
  - `DayTemplate.swift`: `plannedSets/Reps/Weight(for:)`, `setPlannedReps/Weight(_:for:)`
- `Unit/Features/Today/WorkoutTargetFormatter.swift`: all weight, reps, BW and kg/lb formatting. This includes `compactLoadText(sets:reps:weightKg:isBodyweight:)` and `weightDisplay`.
- `Unit/UI/AppCopy.swift`: add the new strings from §7 under `AppCopy.Workout`.
- `Unit/UI/DesignSystem.swift`: the approved components and the `AppFont.setValue` case.
- Tests: `UnitTests/WorkoutLoggingStateTests.swift` (new) and `UnitUITests/ActiveWorkoutLoggingUITests.swift` (new). Keep `ProgressionPersistenceTests` and `ProgressionContractUITests` green, and update their identifiers if needed.

## 4. Data model (no schema change)
- **A logged set** is a `SetEntry` with `isCompleted == true` and `isWarmup == false`, inserted by `completeSet`. Rows are ordered by `setIndex`.
  - Display numbers are positions 1…k, not `setIndex`, so gaps left by deletions renumber.
  - Completed rows are always contiguous at the top of an exercise.
- **A planned row** has no `SetEntry`. Planned rows number `k+1 … plannedSetCount(for:)`; use the existing function plus `customSetCounts`. "+ Add set" adds 1 to `customSetCounts[exercise.id]` for this session, as today.
- **Prefilled values** for planned rows come from `ActiveWorkoutViewModel.prefillSet`, overridden by session-only targets.
- **Session-only targets** are stored in the existing `@AppStorage("unit.preparedSetTargets")` JSON, of type `[sessionID: [key: SetPrefill]]`. Extend the keys in a backward-compatible way:
  - `"<exerciseID>"`: an exercise-level target, as today. It's written by "Save starting target" and by edits to the current row.
  - `"<exerciseID>#<n>"`: a per-row override, written when the user edits upcoming row n.

  Values resolve in this order: per-row override → exercise-level target → `prefillSet`. Existing stored data must still decode.
- **Template writes.** `DayTemplate` is written only by the opt-in Finish prompt (§8.9). Remove the template writes from `savePreparedTarget`.
- **Bodyweight.**
  - `Exercise.isBodyweight` changes only through an explicit user choice: the ⋯ menu's "Bodyweight" toggle. Remove every `if weight == 0 { exercise.isBodyweight = true }` (L963, L996, L1079).
  - On bodyweight exercises, `weight` stores the added load as today: 0 → "BW", 10 → "BW + 10 kg".
  - On weighted exercises, 0 is stored as 0 and shown as "0 kg".

## 5. Screen structure and states (see the PNGs)
Top to bottom:
1. **Nav.** Leading ✕ (cancel, existing alert). Centre: day name, with elapsed time in mono below it. Trailing "Finish" text button, shown when at least one working set is logged (`final-B-b.png`).
2. **One `ScrollView`** with a `LazyVStack` of exercises in template order, 8 pt apart. Each exercise is one of:
   - **Completed exercise** (every planned row logged and not current): a one-line `ExerciseSummaryRow` with check, name and summary (`final-B-d.png`).
   - **Current exercise:** an `ExerciseLoggingCard` with the title and ⋯, then completed rows, the current row, planned rows, and "+ Add set".
   - **Upcoming exercises:** dim one-liners with name and summary, grouped in one translucent block.
3. **Fixed `RestBar`** in `.safeAreaInset(edge: .bottom)`. It's hidden while the keyboard is up; its time then moves to the keyboard toolbar.

**The current exercise** is the first exercise in order that has an unlogged planned row. If the user taps a dim upcoming exercise, it becomes current for this session; it's a manual jump, and its card expands.

**The current row** is the first unlogged row of the current exercise.

**End of day** (no frame): when every planned row of every exercise is logged, there is no current row. The list ends with `AppPrimaryButton("Finish workout")`, the nav "Finish" hides, and rest stops (as today, when `nextSection == nil`).

**States to match:**

| PNG | State | Notes |
|---|---|---|
| `final-B-a` | Before the first set | No Finish; rest idle |
| `final-B-b` | Just after set 2 | Undo inline; rest 2:00 running |
| `final-B-c` | Rest running | Undo expired |
| `final-B-d` | Bench done → Incline set 1 | Undo on the summary line; rest continues |
| `final-B-e` | Editing set 1 | CTA disabled; rest time in the toolbar |
| `final-B-f` | First-time target | CTA hidden; Save starting target in its slot |
| `final-B-g` | Completed-row menu | Row highlighted; `Menu` |
| `final-B-compact` | 375 × 667 | Same layout; 28 pt value |

## 6. Layout spec (pt; tokens from `Unit/UI/DesignSystem.swift`)
**Screen and nav**
- Screen background: `AppColor.background` (#F5F5F5). Content horizontal inset: 16 (`AppSpacing.md`). Content starts below the nav.
- Nav: 44 pt circular ✕ (white, `AppColor.cardBackground`). Title in `AppFont.sectionHeader`; elapsed time in `AppFont.stepIndicator` with `AppColor.textSecondary`.
- Finish: a capsule, height 44, horizontal padding 16, `AppColor.cardBackground`, text `AppFont.productAction` at 15 semibold. If no 15 pt semibold case exists, use `.caption` with semibold and list it for approval.

**Exercise card**
- `AppColor.cardBackground`, radius `AppRadius.card` (22). Padding: 10 on the sides and top, 0 at the bottom.
- Title row: `AppFont.productHeading` (24 bold). ⋯ is a 44 pt circle with `AppColor.cardRowFill`.

**Logged set row** (48 pt; 56 pt while editing)
- Leading padding 12, trailing 14.
- Index column 30 wide, `stepIndicator`, `textTertiary`.
- Value: `AppFont.performance` at 17 bold mono, `textPrimary`.
- Trailing `checkmark.circle.fill` at 20 pt, `textPrimary`.
- The Undo slot sits to its left: "Undo", 15 semibold, underlined, with a ≥44 × 44 hit area. It must not change the row's height or width.
- Pressed: `AppColor.controlBackground` fill, radius 12.

**Planned set row:** 48 pt, same columns, all text `textDisabled`, no glyph.

**Current set row**
- Container: `AppColor.cardRowFill`, radius 16, padding 12, vertical margin 2.
- Contents, top to bottom:
  1. "Set n": `AppFont.muted` semibold, `textSecondary`
  2. 6 pt gap, then the value line: [weight chip] × [reps chip], 8 pt gap
     - chips: white, radius 12, height 54 (50 on compact), horizontal padding 12
     - weight chip min width 140, reps chip min width 64
     - value: `AppFont.setValue` (Geist Mono bold 30, tracking −0.5; 28 on the compact width class)
     - the × is mono 22 bold
     - a focused chip gets a 2 pt `textPrimary` outline
  3. 8 pt gap, then the sub-line in `AppFont.muted`, `textSecondary`
  4. 10 pt gap, then the CTA: `AppPrimaryButton`, full width, 56 pt tall (the component's 60 pt slot is fine; ≥ 50 required), black fill `textPrimary`, label `productAction`
     - Disabled: `controlBackground` fill, `textDisabled` label
     - Setup variant: an outlined secondary button of the same size in the same slot
- Total height ≈ 196. Use `@ScaledMetric` for chip heights so Dynamic Type grows them.

**Lists and bars**
- Card footer: "+ Add set", a 44 pt row, 15 semibold.
- `ExerciseSummaryRow`: 52 pt, white, radius 16, padding 0 × 16. Check 22 pt, name 16 semibold. The summary goes trailing, `muted` mono, `textSecondary`.
- Upcoming block: `cardBackground` at 60% opacity, radius 16. Rows are 48 pt with a 1 pt `AppColor.border` hairline between them. Name in `caption`, `textSecondary`; summary in `muted` mono, `textDisabled`.
- `RestBar`: white, 1 pt top `border`. Content height 60, plus the bottom safe area.
  - Running: a 3 pt progress line at the very top (track `controlBackground`, fill `textPrimary`); "Rest" in `caption`; the time in Geist Mono 24 bold.
  - Controls: −15, +15, Skip, each 44 × 44 minimum, `controlBackground`, radius 10.
  - Idle: "Rest 2:00" in `caption`, `textTertiary`. Finished: "Rest finished." 17 bold.
- Keyboard toolbar (`ToolbarItemGroup(placement: .keyboard)`): leading "Rest m:ss" when rest is running, in `muted`; then the step chips; trailing "Done" as a black capsule.

## 7. Every user-facing string (no others)
**Kept from `AppCopy` (use the existing constant):**
- `Workout.lastResultLabel` "Last time"
- `startingTargetLabel` "Starting target"
- `editSet(n)` "Set n"
- `edit` "Edit"
- `bodyweightAbbrev` "BW"
- `finishWorkout` "Finish workout"
- `finishWorkoutTitle` "Finish workout?"
- `finishWorkoutMessage` "Saves and ends your session."
- `cancelWorkoutTitle` / `cancelWorkoutAction` / `cancelWorkoutMessage`
- `skipExerciseTitle` / `skipExerciseAction`
- `Toast.undo` "Undo"
- `done` "Done"
- `cancel` "Cancel"
- "Couldn't save workout"
- "Rest alerts are off. Enable notifications in Settings."
- "Rest alert could not be set."
- the "Set removed" toast
- notification title "Rest finished"

**New:**

| Key | String |
|---|---|
| `finishShort` | Finish |
| `completeSetNumbered(n)` | Complete set {n} |
| `lastTimeValue(w, r)` | Last time {w} × {r} (no unit; the unit is in the value above) |
| `noStartingTarget` | No starting target yet |
| `saveStartingTarget` | Save starting target |
| `markNotDone` | Mark not done |
| `addSet` | + Add set |
| `restIdle(t)` | Rest {m:ss} |
| `restLabel` | Rest |
| `restMinus` / `restPlus` / `restSkip` | −15 / +15 / Skip |
| `restFinishedInline` | Rest finished. |
| `stepDown/stepUp` | −2.5 / +2.5 (kg) or −5 / +5 (lb); reps −1 / +1 |
| `repsNext` / `kgPrev` | Reps › / ‹ Kg (‹ Lb in lb) |
| `bodyweightToggle` | Bodyweight |
| `updateRoutineTitle` | Update routine with today's weights? |
| `updateRoutineMessage(names)` | {Exercise A, Exercise B} |
| `updateRoutineAction` / `keepRoutineAction` | Update / Keep routine |

**Number formats:**
- Values follow `WorkoutTargetFormatter`: "72.5 kg × 7", "BW × 10", "BW + 10 kg × 8".
- Summaries: "4 × 72.5 kg × 7" via `compactLoadText`. If the logged sets differ, "4 sets".
- Trim trailing zeros, use tabular digits, and convert to lb only for display.

## 8. Interactions
1. **Complete set n (prefilled path)** calls `completeSet` with the row's resolved values. Then:
   - haptic: the existing `setLoggedPhase` → `AppHaptic.success`
   - `noKeyboardSetCount += 1` if no field was edited for this row
   - the row collapses and the next row expands (§12)
   - rest starts (§9)
   - the Undo window opens (8.4)
   - the 400 ms guard starts (8.3)

   The old 2.5 s "✓ dwell" and `advanceAfterCompletedSet`'s delay are removed. The list is always visible, so the hand-off is the row change itself.
2. **Last planned row of an exercise.** The card collapses to an `ExerciseSummaryRow`. The next unfinished exercise expands with row 1 current. `ScrollPosition.scrollTo(id: nextExercise.id, anchor: .top)` runs in the same transaction, and rest keeps running. If no exercise remains, go to the end-of-day state (§5).
3. **400 ms guard.** Replace the one-runloop `isLoggingSet` reset (`DispatchQueue.main.async`, L991) with `lastLogAt: Date?`. `completeSet` returns early if `now − lastLogAt < 0.4 s`. For those 400 ms, the new current row and the just-completed row also get `.allowsHitTesting(false)`. Don't grey them, so nothing flashes.
   - Why 400 ms: double taps land within about 300 ms, and real sets are at least 20 s apart.
   - Undo stays tappable after 400 ms.
4. **Inline Undo.**
   - Shown on the just-completed row, or on the `ExerciseSummaryRow` if that set finished the exercise.
   - Lasts 5 s, or until the next state-changing action: another Complete, any edit, Add set, Finish, Skip rest, or an exercise jump.
   - Undo deletes that `SetEntry` (via a snapshot like `deleteSet`, but without the "Set removed" toast), stops the rest it started (§9), restores that row as current and re-expands its exercise. Haptic: `AppHaptic.tap`.
5. **Tap a logged row** (the whole row, `contentShape(Rectangle())`) opens a SwiftUI `Menu` with:
   - **Edit** (`pencil`): the row edits in place (`final-B-e.png`). Saving calls `updateSet` and never logs.
   - **Mark not done** (`arrow.uturn.backward`, `role: .destructive`): calls `deleteSet`, keeps the existing "Set removed" + Undo toast, and applies the rest rules in §9.
6. **Edit in place (logged, current or planned row).**
   - Tapping the weight or reps chip focuses a `TextField` bound through `@FocusState`. Weight uses `.keyboardType(.decimalPad)`; reps uses `.numberPad`.
   - Toolbar steps:
     - weight: ±2.5 kg (±5 lb), never below 0
     - reps: ±1, min 1
     - "Reps ›" moves focus to reps; "‹ Kg" moves it back
     - Done commits and dismisses
   - Commit rules: logged row → `updateSet`; current row → exercise-level session target (it also updates later planned rows that have no per-row override); planned row n → per-row override `"<id>#<n>"`.
   - Reps 0 is not committable (the field reverts). It does **not** delete, unlike today's `updateSet` L1075.
   - While any field is focused, the CTA is `.disabled(true)`.
   - `.scrollDismissesKeyboard(.interactively)`.
7. **Tap a planned row** focuses its weight chip, i.e. edit mode for planned values. It never completes.
8. **First-time target** (no `prefillSet` result, or a `.planned` source with weight missing on a weighted exercise; mirrors `hasUsableStartingTarget`):
   - The current row shows empty chips (placeholder "kg" / "reps" in `textDisabled`), "No starting target yet", and "Save starting target", outlined, in the CTA slot. **No CTA** until the target is saved.
   - Save requires reps > 0 and weight ≥ 0. It writes the exercise-level session target only: no `SetEntry`, no rest, no template write.
   - The slot then becomes "Complete set 1" in place, with no layout jump.
9. **Finish.**
   - Nav "Finish" shows the existing alert (title, message, "Finish workout" / "Cancel").
   - On confirm, before `clearPreparedTarget()`: collect the template exercises in this session whose exercise-level session target was saved this session and that have at least one logged working set.
   - If that list is not empty, show `confirmationDialog(updateRoutineTitle)` with the message listing their names, and the actions "Update" / "Keep routine".
     - Update: for each one, write `setPlannedWeight/Reps` = the first logged working set's weight/reps today.
     - Then run the existing `finishWorkout()`, unchanged.
   - Freestyle sessions (`isFreestyleSession`) never prompt.
10. **⋯ menu** (exercise card): "Bodyweight" (a toggle that writes `exercise.isBodyweight` explicitly) and "Skip exercise" (existing confirmation and behaviour).
11. **Remove** from this screen: the ☰ lineup sheet (`showLineup`, `exerciseListSheet`), the pause toggle, and the `SessionStateBar` / `WorkoutCommandCard` / `SetProgressIndicator` usage. Add exercise remains at the end of the list if `addExercisePrompt` exists today; otherwise list it in Questions.

## 9. Rest timer model
- `RestTimerManager` stays the single owner, persisted in UserDefaults as today, restored on init, with `resumeFromBackground()` on `scenePhase == .active`.
- **Start.** Every successful Complete calls `startRestTimer(seconds: restDurationSeconds)`, except the last set of the whole day, which calls `restTimer.stop()` as today. Track `restSourceEntryID` = the ID of the entry that started this rest. This is `@State`; persist it next to the timer keys in UserDefaults as `unit.restTimer.sourceEntryID`.
- **−15 / +15** call `adjust(by: ∓15, minimumSeconds: 15)`. −15 is disabled when `secondsRemaining ≤ 15`. Replace `restTimerAdjustStepSeconds = 30` with 15. Keep the current behaviour that writes the adjusted total back to `restDurationSeconds`, so it remains the default for the next rest.
- **Skip** calls `stop()`; the bar goes to idle immediately. No "Rest finished." and no notification.
- **Finish.** `completeIfFinished` sets the inline state "Rest finished." + `AppHaptic.success` (the existing `completionCount` observer). This holds until the next Complete, or 30 s, then the bar goes idle.
- **Deleting or un-logging** (fixes Strong-class bug 6.1.1, "timer not stopped on delete"):
  - If the removed entry (Undo, Mark not done, or a reps → 0 path if one remains) is `restSourceEntryID` and rest is running or finished, call `restTimer.stop()`. That also cancels the notification and ends the Live Activity.
  - Otherwise keep rest, but refresh `upNext`.
- **upNext.**
  - A single pure function, `WorkoutLoggingState.upNextText(...)`, returns:
    - "{current exercise} · Set {k+1}" while the current exercise has unlogged planned rows
    - otherwise "{next exercise} · Set 1"
    - otherwise nil
  - It counts only `isValidCompletedWorkingSet` entries and uses `plannedSetCount` including `customSetCounts`.
  - Recompute it, and call a new `restTimer.updateUpNext(_:)`, whenever entries, the plan or the current exercise change during rest. `updateUpNext` updates the Live Activity and reschedules the notification with the **same** `endDate`.
- **Pause** is removed from the UI, which removes Strong-class bug 6.3.2, "paused timers firing". Keep `pause()`/`resume()` only if they're referenced elsewhere.
- **Inline rule.** The in-app bar never shows `upNext`; the current row already does.

## 10. Live Activity and notifications
- **Keep** `Activity.request(attributes:content:pushType: nil)` with `ActivityContent(state:staleDate: endDate, relevanceScore: 100)`, plus `update(_:)` and `end(nil, dismissalPolicy: .immediate)`.
- **Widget.** Render the countdown with `Text(timerInterval:pauseTime:countsDown:showsHours:)` and `ProgressView(timerInterval:countsDown:)`, so it ticks while the app is suspended. When `context.isStale`, show "Rest finished" with no countdown.
- **No buttons and no intents** in this change.
- **Notification.**
  - Keep the per-generation identifier scheme and the cancel logic: `removePendingNotificationRequests(withIdentifiers:)` plus delivered.
  - Body: "Next: {upNext}", or "Start your next set." if nil (existing).
  - Add `content.interruptionLevel = .timeSensitive`. This needs the Time Sensitive Notifications capability: confirm in Xcode; if it's missing, the system treats the alert as active, so it's harmless.
  - Keep asking for permission on the first rest, as today.

## 11. Accessibility and Dynamic Type
- **Current row:** one combined element (`accessibilityElement(children: .combine)`) for the label and value, for example "Set 3, 72.5 kilograms, 7 reps. Last time 72.5 kilograms, 6 reps." The weight and reps chips are separate buttons with hint "Double-tap to edit." The CTA is a separate button, "Complete set 3".
- **Logged row:** label "Set 1, 72.5 kilograms, 7 reps, done". Actions via `accessibilityAction(named:)`: "Edit", "Mark not done", and "Undo" while it's shown.
- **Planned row:** "Set 4, planned, 72.5 kilograms, 7 reps". Hint "Double-tap to edit."
- **After Complete:** post `AccessibilityNotification.Announcement("Set 2 logged. Rest 2 minutes.")`, then move VoiceOver focus to the new CTA with `@AccessibilityFocusState` once the 400 ms guard ends.
- **Rest bar:** `accessibilityLabel("Rest")`, with the value as remaining time in words. The buttons are "Subtract 15 seconds", "Add 15 seconds", "Skip rest". "Rest finished." is announced once.
- **Dynamic Type:**
  - Chips use `@ScaledMetric`.
  - At accessibility sizes, the value line stacks weight above reps (`ViewThatFits`). The CTA stays full width and its label wraps. Rows grow; nothing is clipped. Row heights in §6 are minimums.
  - Use `.dynamicTypeSize(...DynamicTypeSize.accessibility3)` on the rest bar only.
- State is never colour alone: done = glyph + label. Hit targets are at least 44 pt. Use `AppColor` tokens only.

## 12. Motion and Reduce Motion
- **Row change:** `withAnimation(.easeInOut(duration: 0.25))` wraps the state change that collapses row n and expands row n+1. Expanding uses `.transition(.opacity)` on the CTA and sub-line inside a height-animating container.
- **Exercise change:** the same animation plus `scrollTo(id:anchor: .top)`.
- **Numbers:** use `.contentTransition(.numericText())` for values changed by the steppers and for the rest time.
- **Reduce Motion** (`accessibilityReduceMotion`): no height animation and no scrolling animation. Apply the new layout, then crossfade with `.animation(.easeInOut(duration: 0.2), value:)` and opacity transitions only. Haptics still fire.
- **No layout shift from Undo** appearing or disappearing: the slot is reserved and its opacity changes.
- **CTA travel budget:** 48 pt per set inside an exercise. Auto-scroll only if the CTA's bottom would come within 16 pt of the rest bar's top; then scroll the minimum needed, anchored to the current row's ID. Document the measured values in the PR description.

## 13. Edge cases
- **Add set after all sets are done:** "+ Add set" adds a planned row, which becomes current (CTA). The exercise re-expands if it had collapsed. A tap on the collapsed summary row also expands it.
- **More than planned:** extra logged rows just extend the list.
- **Mark not done on a middle set:** later logged rows renumber; the current row becomes k+1 again.
- **Mark not done on the only logged set:** the nav "Finish" hides again.
- **Manual jump:** tapping an upcoming exercise makes it current. The partially done exercise you left becomes a compact card with its logged rows and dim planned rows and **no CTA**; tapping it makes it current again. A jump never stops rest (today `goToNextExercise` stops it).
- **Leaving and coming back** (backgrounded, killed, relaunched): the timer restores from UserDefaults or the Live Activity. If it expired, the bar shows "Rest finished.", the notification has already fired, and no Undo is shown after relaunch.
- **Bodyweight:** chips show "BW" and reps. The weight chip edits added load; 0 shows "BW". Use the existing `weightLabel(isBodyweight:unitSystem:)` for the field's accessibility label.
- **lb units:** steps of ±5 lb; storage stays canonical kg via `WorkoutTargetFormatter`.
- **Save fails** (`saveWorkoutChanges` false): no row change, no rest, the existing alert, and the guard is released.
- **Long exercise names** wrap to two lines in the card title and truncate in one-liners. Values never truncate; they wrap per §11.
- **Session from yesterday:** the existing stale-session flow is unchanged.

## 14. Offline and data integrity
- **Offline:** everything is local. No network calls are added.
- **Saves:** each Complete, Edit, Undo and Mark not done saves immediately via `viewModel.saveChanges` → `ModelContext.save()`.
- **No schema change, no migration, no deletion of existing data.** Old sessions, the `preparedSetTargets` JSON, timer keys and Live Activities must all still load.
- **Template:** never written except via §8.9 Update.
- **Exercise.isBodyweight:** never written except via the ⋯ toggle.
- **Undo** restores exactly: same `id` and `setIndex`, via `SetEntrySnapshot`.
- **Analytics events:** keep `workoutCompleted` and `noKeyboardRatio` unchanged.

## 15. Existing bugs this change must fix (each needs a test)
1. **Save target recorded a set** (before build 77). Save starting target must never insert a `SetEntry` or start rest.
2. **Double-tap guard.** One-runloop `isLoggingSet` plus a CTA that stays enabled during the 2.5 s ✓ meant a double tap logged a duplicate. Replace it with the 400 ms guard (§8.3).
3. **Deleting a set didn't adjust rest** (`deleteSet` L1091). Apply §9's deletion rules and refresh upNext.
4. **"Save target" silently overwrote the template, and 0 kg made the exercise bodyweight for good** (L961–963, L996, L1079). Session-only targets, the opt-in Finish prompt, and the explicit Bodyweight toggle fix this.
5. **Rest named the next exercise while sets remained:** stale `upNext` after edits, added sets or deletions. Use the single `upNextText` with recompute (§9).
6. **Abrupt transitions:** the card swap, blur and dwell are replaced by §12.

## 16. Tests
**`UnitTests/WorkoutLoggingStateTests.swift`**

Use an in-memory `ModelContainer` and an injected `now`.
1. Row derivation: 0, 2 and 4 of 4 logged; current = first unlogged; planned rows numbered; custom set count +1.
2. A middle deletion renumbers; completed rows stay contiguous.
3. Guard: Complete twice within 399 ms → 1 entry; at 401 ms → 2 entries.
4. Undo inside 5 s removes the entry, stops rest when the entry is `restSourceEntryID`, and restores the current row. After 5 s, or after the next action, Undo is unavailable.
5. Mark not done on the rest-source entry stops rest and cancels the notification (check via an injected notification-center protocol). On a non-source entry, rest keeps running and upNext is refreshed.
6. upNext: sets remain → same exercise · Set k+1; last set → next exercise · Set 1; last exercise → nil; after Add set during rest → updated; after a deletion → updated.
7. Save starting target: no `SetEntry`, no rest, template unchanged, `isBodyweight` unchanged with 0 kg.
8. Finish diff: an exercise with a session target and logged sets → listed; without a session target → not listed; freestyle → no prompt. Update writes the first logged working set's values; Keep leaves the template unchanged.
9. Per-row override precedence, and backward decoding of old `preparedSetTargets` JSON.
10. Bodyweight formatting "BW × 10", "BW + 10 kg × 8"; lb steps ±5; trailing zeros trimmed.
11. Rest −15 disabled at ≤ 15 s; +15 updates `endDate`, the Live Activity content and the notification deadline. Skip produces no "Rest finished".
12. Restore: persisted endDate in the future → running; in the past → finished, with no notification rescheduled.

**`UnitUITests/ActiveWorkoutLoggingUITests.swift`**

Seeded launch arguments, as `ProgressionContractUITests` uses.
- Log 4 Bench sets with taps only; the CTA moves exactly one row each time.
- Bench collapses and Incline becomes current.
- Edit set 1 via the menu while the CTA is disabled.
- Mark not done.
- First-time target.
- Finish with Update and with Keep routine.

## 17. Acceptance criteria
- The screens match `final-B-a…g` and `final-B-compact` in structure, order, type hierarchy and copy.
- Only the current row has a CTA. No empty circles anywhere. Tab bar hidden. No ☰.
- All strings come from §7 only. Every fact appears once per screen (see the dedup audit in `final-B/final-B.md`).
- All §15 bugs are fixed, each with a passing test. All §16 tests pass. No new warnings. Existing tests stay green.
- The PR description includes:
  - simulator screenshots on iPhone 16 and iPhone SE (3rd gen) of states a–g, end of day, AX3, Reduce Motion (a short screen recording of a row change), and lb units
  - the measured CTA travel per set
  - the answer lists: new components for approval, Questions / blocked, files changed

## 18. Checklist
- [ ] Read the repo docs and handoffs; listed components for approval
- [ ] `WorkoutLoggingState` is pure, with injected `now`
- [ ] Rows (logged, current, planned), summary and upcoming lines per §5–6
- [ ] 400 ms guard, inline Undo, Menu Edit / Mark not done
- [ ] Inline editing with keyboard toolbar; CTA disabled while focused
- [ ] First-time target: CTA hidden, session-only save
- [ ] Rest bar ±15 / Skip / finished; rest-source deletion rule; upNext recompute
- [ ] Live Activity stale handling; time-sensitive notification
- [ ] Finish prompt opt-in; no other template or bodyweight writes
- [ ] A11y, Dynamic Type, Reduce Motion per §11–12
- [ ] No schema change; old data loads
- [ ] Tests green; screenshots attached

## Appendix: verified Apple API references
All of these resolve on developer.apple.com. Use no APIs outside this list without saying so.

**SwiftUI: scrolling and layout**
- ScrollPosition: https://developer.apple.com/documentation/swiftui/scrollposition
- scrollTo(id:anchor:): https://developer.apple.com/documentation/swiftui/scrollposition/scrollto(id:anchor:)
- scrollPosition(_:anchor:): https://developer.apple.com/documentation/swiftui/view/scrollposition(_:anchor:)
- scrollPosition(id:anchor:): https://developer.apple.com/documentation/swiftui/view/scrollposition(id:anchor:)
- scrollTargetLayout(isEnabled:): https://developer.apple.com/documentation/swiftui/view/scrolltargetlayout(isenabled:)
- ScrollViewReader (fallback): https://developer.apple.com/documentation/swiftui/scrollviewreader and https://developer.apple.com/documentation/swiftui/scrollviewproxy/scrollto(_:anchor:)
- scrollDismissesKeyboard: https://developer.apple.com/documentation/swiftui/view/scrolldismisseskeyboard(_:)
- LazyVStack: https://developer.apple.com/documentation/swiftui/lazyvstack
- safeAreaInset: https://developer.apple.com/documentation/swiftui/view/safeareainset(edge:alignment:spacing:content:)
- ViewThatFits: https://developer.apple.com/documentation/swiftui/viewthatfits
- ScaledMetric: https://developer.apple.com/documentation/swiftui/scaledmetric
- contentShape: https://developer.apple.com/documentation/swiftui/view/contentshape(_:eofill:)

**SwiftUI: animation and motion**
- withAnimation: https://developer.apple.com/documentation/swiftui/withanimation(_:_:)
- easeInOut(duration:): https://developer.apple.com/documentation/swiftui/animation/easeinout(duration:)
- animation(_:value:): https://developer.apple.com/documentation/swiftui/view/animation(_:value:)
- transition: https://developer.apple.com/documentation/swiftui/view/transition(_:)
- AnyTransition.opacity: https://developer.apple.com/documentation/swiftui/anytransition/opacity
- contentTransition: https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)
- numericText: https://developer.apple.com/documentation/swiftui/contenttransition/numerictext(countsdown:)
- accessibilityReduceMotion: https://developer.apple.com/documentation/swiftui/environmentvalues/accessibilityreducemotion

**SwiftUI: controls, input and state**
- allowsHitTesting: https://developer.apple.com/documentation/swiftui/view/allowshittesting(_:)
- disabled: https://developer.apple.com/documentation/swiftui/view/disabled(_:)
- Menu: https://developer.apple.com/documentation/swiftui/menu
- ButtonRole.destructive: https://developer.apple.com/documentation/swiftui/buttonrole/destructive
- alert: https://developer.apple.com/documentation/swiftui/view/alert(_:ispresented:actions:message:)
- confirmationDialog: https://developer.apple.com/documentation/swiftui/view/confirmationdialog(_:ispresented:titlevisibility:actions:message:)
- FocusState: https://developer.apple.com/documentation/swiftui/focusstate
- focused(_:equals:): https://developer.apple.com/documentation/swiftui/view/focused(_:equals:)
- ToolbarItemPlacement.keyboard: https://developer.apple.com/documentation/swiftui/toolbaritemplacement/keyboard
- keyboardType: https://developer.apple.com/documentation/swiftui/view/keyboardtype(_:)
- decimalPad: https://developer.apple.com/documentation/uikit/uikeyboardtype/decimalpad
- numberPad: https://developer.apple.com/documentation/uikit/uikeyboardtype/numberpad
- ToolbarItemGroup: https://developer.apple.com/documentation/swiftui/toolbaritemgroup
- sensoryFeedback (if not using AppHaptic): https://developer.apple.com/documentation/swiftui/view/sensoryfeedback(_:trigger:)
- ScenePhase: https://developer.apple.com/documentation/swiftui/scenephase

**SwiftUI: timers in views and widgets**
- Text(timerInterval:…): https://developer.apple.com/documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:)
- ProgressView(timerInterval:…): https://developer.apple.com/documentation/swiftui/progressview/init(timerinterval:countsdown:label:currentvaluelabel:)

**Accessibility**
- accessibilityElement(children:): https://developer.apple.com/documentation/swiftui/view/accessibilityelement(children:)
- accessibilityLabel: https://developer.apple.com/documentation/swiftui/view/accessibilitylabel(_:)-5f0zj
- accessibilityValue: https://developer.apple.com/documentation/swiftui/view/accessibilityvalue(_:)
- accessibilityHint: https://developer.apple.com/documentation/swiftui/view/accessibilityhint(_:)
- accessibilityAction(named:): https://developer.apple.com/documentation/swiftui/view/accessibilityaction(named:_:)
- accessibilityAddTraits: https://developer.apple.com/documentation/swiftui/view/accessibilityaddtraits(_:)
- AccessibilityFocusState: https://developer.apple.com/documentation/swiftui/accessibilityfocusstate
- accessibilityFocused(_:equals:): https://developer.apple.com/documentation/swiftui/view/accessibilityfocused(_:equals:)
- AccessibilityNotification.Announcement: https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement
- Announcement.post(): https://developer.apple.com/documentation/accessibility/accessibilitynotification/announcement/post()
- dynamicTypeSize: https://developer.apple.com/documentation/swiftui/view/dynamictypesize(_:)

**ActivityKit and WidgetKit**
- ActivityKit: https://developer.apple.com/documentation/activitykit
- request: https://developer.apple.com/documentation/activitykit/activity/request(attributes:content:pushtype:)
- update: https://developer.apple.com/documentation/activitykit/activity/update(_:)
- end: https://developer.apple.com/documentation/activitykit/activity/end(_:dismissalpolicy:)
- ActivityContent: https://developer.apple.com/documentation/activitykit/activitycontent/init(state:staledate:relevancescore:)
- ActivityViewContext.isStale: https://developer.apple.com/documentation/widgetkit/activityviewcontext/isstale

**UserNotifications**
- UNMutableNotificationContent: https://developer.apple.com/documentation/usernotifications/unmutablenotificationcontent
- interruptionLevel: https://developer.apple.com/documentation/usernotifications/unnotificationcontent/interruptionlevel
- timeSensitive: https://developer.apple.com/documentation/usernotifications/unnotificationinterruptionlevel/timesensitive
- removePendingNotificationRequests: https://developer.apple.com/documentation/usernotifications/unusernotificationcenter/removependingnotificationrequests(withidentifiers:)
- The Time Sensitive Notifications capability: confirm in Xcode (no doc URL verified).

**SwiftData**
- ModelContext.save(): https://developer.apple.com/documentation/swiftdata/modelcontext/save()

**Human Interface Guidelines**
- https://developer.apple.com/design/human-interface-guidelines/buttons
- https://developer.apple.com/design/human-interface-guidelines/motion
- https://developer.apple.com/design/human-interface-guidelines/accessibility
- https://developer.apple.com/design/human-interface-guidelines/live-activities
- https://developer.apple.com/design/human-interface-guidelines/playing-haptics
