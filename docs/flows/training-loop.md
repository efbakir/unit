# Training loop flows

- 10 flows below: Today, Start, Logging, Rest timer, Exercise done, Finish, Progression, History, Analytics, Programs.
- Log one set: 1 tap when the row is prefilled ("Complete set N"). App open to first logged set: 2 taps. First set of a new exercise with no weight: 3 to 4 taps plus typing.
- Risk 1 (was High, fixed 2026-10-23): progression was off for 26 of 27 library programs. Programs without their own ranges now give weighted lifts the standard rule (program reps to +2, then +2.5 kg, 2 kg for dumbbells, 5 lb).
- Risk 2 (was High, fixed 2026-10-24): editing sets, rep range or weight step no longer drops a saved target (2026-10-23), and Finish now saves every suggestion, so a skipped summary loses nothing.
- Risk 3 (was Med, fixed 2026-10-23): canceling a started workout no longer counts that routine as done; cancel restores its last-performed date.

Source: branch `claude/app-finalization-launch-34a116`, written at commit `94be704`, updated for commits `499ecaf` and `75fceb0` (2026-10-23) and for the 2026-10-24 progression changes on `claude/progression-loop-7006dd`. Nothing here was tested on a phone; the exercise-done line, summary and Finish flow were checked in Simulator UI tests. Also updated for the 2026-10-24 logging changes (PRs #16 to #18).

## How to read this doc

- Steps: screen -> action -> result.
- Edge cases: case -> what the app does today -> risk -> handled.
- Risk: High = breaks the progression promise or loses training data. Med = wrong state, lost decision, or friction every workout. Low = cosmetic or rare.
- Handled: yes = covered in code. partial = covered in some paths only. no = not covered.
- Links open the exact code line.

## Words used

- Program: a set of routines (code name `Split`).
- Routine: one training day, for example Push (code name `DayTemplate`).
- Workout: one session (code name `WorkoutSession`). Set: one logged set (`SetEntry`).
- Prefill: the numbers already in the set row before you tap.
- Typed target: numbers typed during a workout. Kept for that workout only.
- Suggestion: next-time numbers the app proposes. Saved target: the next target saved for the routine, by Finish or by the lifter on the summary (Keep previous target, Edit). It prefills next time.
- Progression on: an exercise with "Increase reps, then weight" switched on in its target sheet.
- Database (SwiftData): permanent storage. Settings storage (UserDefaults): small permanent values. Screen memory (SceneStorage): survives iOS closing the app, not a force quit. Memory only (@State): gone when the app restarts.

---

## 1. Today screen

**Purpose**
- Show what to train today and start it in one tap.

**Entry**
- App open (Today is the first tab).
- Back from the post-workout summary.
- During a workout the tab bar is hidden, so Today is the only tab ([ActiveWorkoutView.swift:293](Unit/Features/Today/ActiveWorkoutView.swift:293), [ContentView.swift:99](Unit/ContentView.swift:99)).

**Steps**
- Today -> open -> app picks one state from the active program, its schedule and today's workouts ([TodayView.swift:537](Unit/Features/Today/TodayView.swift:537)).
- No program -> "No program" + "Add program" -> Programs tab ([TodayView.swift:317](Unit/Features/Today/TodayView.swift:317)). Not seen in practice: with 0 programs the app shows onboarding instead ([ContentView.swift:31](Unit/ContentView.swift:31)).
- Setup incomplete -> program with no routines: "No routines yet. Add one to start logging." Routine with no exercises: "Add exercises to start this workout." -> "Continue setup" -> Programs tab ([TodayView.swift:325](Unit/Features/Today/TodayView.swift:325), [TodayView.swift:692](Unit/Features/Today/TodayView.swift:692)).
- Next workout -> "Up next", routine name, program name, optional note, one row per exercise with its target -> sticky "Start workout" ([TodayView.swift:335](Unit/Features/Today/TodayView.swift:335), [TodayView.swift:267](Unit/Features/Today/TodayView.swift:267)).
- Next workout -> tap an exercise row -> target sheet (sets, reps or rep range, progression switch, weight step) -> "Save changes" writes the routine ([TodayView.swift:238](Unit/Features/Today/TodayView.swift:238)).
- Rest day -> "Rest day" + program name + "Choose routine" -> routine pick sheet ([TodayView.swift:381](Unit/Features/Today/TodayView.swift:381)).
- Workout in progress -> the whole tab becomes the workout screen, no dashboard ([TodayView.swift:103](Unit/Features/Today/TodayView.swift:103)).
- Catch-up of an earlier missed day -> not on Today. It lives in History, section "This week" (flow 8). The code says it is "used from History, not as a Today-home nudge" ([EarlierWeekCatchup.swift:5](Unit/Features/Today/EarlierWeekCatchup.swift:5)).
- Week progress -> not on Today. A week strip and week sheet exist in code, but nothing shows them ([TrainingWeekProgress.swift:277](Unit/Features/Today/TrainingWeekProgress.swift:277)). Only the "missed day" rule is used, by the History calendar.
- Top right "History" -> flow 8.

**How "Up next" is chosen**
- Weekly schedule (any routine has a weekday): the routine for today's weekday. Already done today -> Rest day. Nothing scheduled today -> Rest day ([TodayView.swift:615](Unit/Features/Today/TodayView.swift:615)).
- Flexible schedule: the routine started longest ago. Any routine done today -> Rest day ([TodayView.swift:572](Unit/Features/Today/TodayView.swift:572)).
- Manual pick: list icon (top left) or "Choose routine" -> pick -> used for today only, with a note: "Different routine for today", "Usually Push today" or "Not in your weekly plan". "Use scheduled day" or "Use the next routine" removes the pick ([TodayView.swift:849](Unit/Features/Today/TodayView.swift:849), [TodayRoutineOverride.swift:21](Unit/Features/Today/TodayRoutineOverride.swift:21)).

**What each exercise row shows (first match wins)** ([TodayView.swift:741](Unit/Features/Today/TodayView.swift:741))
1. Saved target: "3 × 9 at 60 kg", second line "Last time · 3 × 8 at 60 kg" (this routine's last workout first).
2. Last workout with this exercise, this routine first, else any routine: "3 × 8" (sets and set 1 reps, no weight).
3. Starting target from the program: "3 × 8 at 60 kg" or "3 × 8".
4. Nothing: "No history yet" (no workouts at all) or "No prior sets".

**Saved data**
- Today pick: settings storage `unit.todayRoutineOverride.*`, today only.
- Target sheet: routine planned sets, reps and progression rule (database).
- Active program: settings storage `activeSplitId`.

**Edge cases**
- Workout left open from yesterday -> when Today appears: an empty one is deleted with toast "Discarded empty session from yesterday"; one with sets shows "Workout from yesterday" with Continue workout / Mark complete / Discard ([TodayView.swift:417](Unit/Features/Today/TodayView.swift:417)) -> Med -> partial. The check runs only when Today appears, which during an open workout means a cold launch. An app resumed from background the next day shows yesterday's workout with a long clock and no prompt.
- Flexible schedule, workout started then canceled -> the routine still counts as started, so "Up next" moved to another routine. Fixed 2026-10-23: cancel restores the last-performed date ([DayTemplate.swift:330](Unit/Models/DayTemplate.swift:330)) -> Low -> yes.
- Scheduled routine done today -> Today says "Rest day" right after training -> Low -> partial (correct, but no "done today" state).
- Missed scheduled day and nothing scheduled today -> "Rest day"; the missed routine is only offered in History -> Med (habit) -> partial.
- Row with history but no accepted target -> shows last workout's set count, not the plan (plan 4 sets, row says "3 × 8"), and no weight ([TodayView.swift:799](Unit/Features/Today/TodayView.swift:799)) -> Low -> no.
- Picked routine already done today -> allowed, a second workout -> Low -> yes.
- Two routines on one weekday -> blocked in Edit program (taken days are disabled) -> Low -> yes.
- Yesterday check needs workouts loaded when Today first appears; if data loads later, the check is skipped and never repeated -> Low -> unclear from code.

---

## 2. Start workout

**Purpose**
- Create a workout and open logging with the fewest taps.

**Entry**
- Today: sticky "Start workout".
- History: a row in "This week" (missed routine).
- Programs: "Freestyle session" (no routine).
- Not available: start a chosen routine from Programs or routine detail. The code keeps starting on Today only ([TemplatesView.swift:40](Unit/Features/Templates/TemplatesView.swift:40)); use Today's routine pick.

**Steps**
- Today -> "Start workout" -> workout saved at once, routine "last started" date stamped ([DayTemplate.swift:323](Unit/Models/DayTemplate.swift:323)) -> blur and scale launch with a firm haptic -> workout screen ([TodayView.swift:403](Unit/Features/Today/TodayView.swift:403)).
- History -> tap "Planned for Monday · Tap to start" -> same save, no launch animation -> History closes -> workout screen ([HistoryView.swift:296](Unit/Features/History/HistoryView.swift:296)).
- Programs -> "Freestyle session" -> hidden "Freestyle" routine + workout created -> app switches to Today -> "Add your first exercise" card ([TemplatesView.swift:134](Unit/Features/Templates/TemplatesView.swift:134), [FreestyleSessionSupport.swift:39](Unit/Features/Templates/FreestyleSessionSupport.swift:39)).
- Relaunch with a workout open -> Today opens that workout directly, no launch animation.

**Saved data**
- `WorkoutSession` in the database (date = start time, not finished).
- Routine `lastPerformedDate` (used by the flexible schedule).

**Edge cases**
- Save fails -> rollback, toast "Couldn't save workout. Your previous data is unchanged. Try again." -> Low -> yes.
- A workout is already open -> Today blocks a second start; other start buttons are out of reach because the tab bar is hidden. The Freestyle button itself has no check ([TemplatesView.swift:134](Unit/Features/Templates/TemplatesView.swift:134)) -> Low -> partial.
- Accidental start -> only exit is X, then "Cancel workout"; the routine stays up next (fixed 2026-10-23, flow 1) -> Low -> yes.
- History catch-up row starts a workout on one tap, no confirm -> Low -> no.
- Freestyle save result is not checked ([FreestyleSessionSupport.swift:53](Unit/Features/Templates/FreestyleSessionSupport.swift:53)) -> Low -> no.
- Unused freestyle routines are deleted when Today or Programs appears ([FreestyleSessionSupport.swift:24](Unit/Features/Templates/FreestyleSessionSupport.swift:24)) -> Low -> yes.

---

## 3. Active logging

**Purpose**
- Log each set in 3 seconds or less, one hand.

**Entry**
- Any started or resumed workout.

**Screen, top to bottom** ([ActiveWorkoutView.swift:161](Unit/Features/Today/ActiveWorkoutView.swift:161))
- Nav bar: X (cancel), routine name + running clock, "Finish" (only after 1 logged set).
- Exercise cards in routine order. The current exercise is open ([DesignSystem.swift:6540](Unit/UI/DesignSystem.swift:6540)). Others are closed cards: upcoming ("3 × 60 kg × 8") or done (flow 5) ([DesignSystem.swift:6717](Unit/UI/DesignSystem.swift:6717)).
- Open card: name, pinned note line (if any), "..." menu (Exercise history, Swap exercise before the first set, Add note or Edit note, Bodyweight switch, Remove added set when one is open, Skip exercise), set rows, "+ Add set".
- Set rows: logged (number, "60 kg × 8", "PR" tag when it beat the best so far, Undo space, check), current ("Set N" + source text, weight × reps fields, blue "Complete set N"), planned (grey number and value).
- Bottom: rest bar, always visible (flow 4). Uncommitted edit: swapped for "Finish workout" once every planned set is logged (flow 5).

**Prefill order (what the current row shows, first match wins)** ([ActiveWorkoutView.swift:1222](Unit/Features/Today/ActiveWorkoutView.swift:1222), [WorkoutLoggingState.swift:158](Unit/Features/Today/WorkoutLoggingState.swift:158))
1. Typed for this exact set in this workout.
2. Typed for this exercise in this workout.
3. Your last logged set of this exercise in this workout (set 2 copies set 1).
4. Saved target, this routine only ([ActiveWorkoutView.swift:1254](Unit/Features/Today/ActiveWorkoutView.swift:1254)).
5. Last time: set 1 of this routine's newest finished workout with this exercise, else set 1 of the newest from any routine. Until 2026-10-24 it used the last set, often the weakest ([ActiveWorkoutView.swift:1294](Unit/Features/Today/ActiveWorkoutView.swift:1294)).
6. Starting target from the program: planned reps, plus planned weight if any. No weight -> row says "No starting target yet" and needs "Save target".
7. Empty fields.
- This matches the expected order (accepted target -> last time -> starting target -> empty), with 3 extra layers on top (1 to 3).
- Source text, top right of the current row: "Last time 60 × 8" from the same workout as step 5, set N on row N, nothing on a set that did not exist then (also when the prefill is the saved target); "Starting target" when only the plan exists; "No starting target yet" when weight is missing ([ActiveWorkoutView.swift:659](Unit/Features/Today/ActiveWorkoutView.swift:659)).

**Steps**
- Log a set: current row -> "Complete set N" -> set saved -> success haptic, 0.4 s tap lock, "Undo" for 5 s, rest starts, next row becomes current ([ActiveWorkoutView.swift:808](Unit/Features/Today/ActiveWorkoutView.swift:808), [ActiveWorkoutView.swift:820](Unit/Features/Today/ActiveWorkoutView.swift:820)).
- Change numbers first: tap weight or reps -> number pad + bottom bar with rest status, a pinned "Complete set N", and 4 buttons: "-2.5" / "+2.5" (lb: 5, reps: 1), "Reps" or "Weight" switch, "Done" -> "Complete set N" saves the typed numbers and logs in one tap ([ActiveWorkoutView.swift:197](Unit/Features/Today/ActiveWorkoutView.swift:197)).
- First time, no weight: row shows "No starting target yet" and a grey "Save target" -> tap weight, type, (switch, type reps if empty) -> "Save target" or "Done" -> numbers kept for this workout, no set logged -> "Complete set 1" ([ActiveWorkoutView.swift:790](Unit/Features/Today/ActiveWorkoutView.swift:790)).
- Edit a logged set: tap the row -> menu "Edit" -> fields open in place -> "Done" -> set updated ([ActiveWorkoutView.swift:886](Unit/Features/Today/ActiveWorkoutView.swift:886)).
- Undo: "Undo" beside the newest set (5 s) -> set deleted, that exercise reopens, rest stops if this set started it ([ActiveWorkoutView.swift:874](Unit/Features/Today/ActiveWorkoutView.swift:874)).
- Remove a set: row menu -> "Mark not done" -> set deleted -> toast "Set removed" with Undo for 4 s ([ActiveWorkoutView.swift:894](Unit/Features/Today/ActiveWorkoutView.swift:894)).
- Add set: "+ Add set" -> one more planned row, this workout only ([ActiveWorkoutView.swift:951](Unit/Features/Today/ActiveWorkoutView.swift:951)).
- Remove an added row: "..." -> "Remove added set" (only while a row added with "+ Add set" is open) -> row gone, toast "Set removed" with Undo for 4 s. Rows from the routine plan cannot be removed.
- PR: a logged set that beats the best so far (finished workouts, then this workout's earlier sets) shows the "PR" tag on its row and on the closed done card. Same rule as History. No banner, sound or extra haptic.
- Exercise history: "..." -> "Exercise history" -> the exercise page (same as from Analytics) -> back returns to the same set. Other tabs stay hidden.
- Bodyweight: "..." -> "Bodyweight" switch -> changes the exercise everywhere, all routines and history ([ActiveWorkoutView.swift:964](Unit/Features/Today/ActiveWorkoutView.swift:964)). Weight 0 -> "BW × 12". Positive weight -> "BW + 10 kg × 8". 0 kg on a normal exercise logs "0 kg × 8"; it never turns into BW by itself.
- Warm-ups: not available. Every set is a working set. Warm-up code exists but nothing uses it ([WarmupGenerator.swift:11](Unit/Engine/WarmupGenerator.swift:11)).
- Reorder: long-press a card -> drag onto another card -> order saved for this workout only ([ActiveWorkoutView.swift:1047](Unit/Features/Today/ActiveWorkoutView.swift:1047)). No drag handle is shown.
- Skip exercise: "..." -> "Skip exercise" -> confirm -> next unfinished exercise opens; the skipped one comes back after the others ([ActiveWorkoutView.swift:946](Unit/Features/Today/ActiveWorkoutView.swift:946)). On the last unfinished exercise: its card closes, rest stops and "Finish workout" replaces the rest bar (no Finish when nothing is logged); tapping the card reopens it.
- Jump: tap a closed card -> it becomes current ([ActiveWorkoutView.swift:932](Unit/Features/Today/ActiveWorkoutView.swift:932)).
- Add exercise mid-workout: "Add exercise" at the end of the list -> picker (own list, search, create) -> "How many sets?" 1 to 6. Freestyle adds to its hidden routine; a routine workout adds for this workout only, the routine is unchanged.
- Swap exercise: "..." -> "Swap exercise" (only before its first set) -> picker -> the new exercise takes the same place with the routine's planned sets and reps; its weight comes from its own history. This workout only; next time the routine exercise is back. No suggestions.
- Notes: "..." -> "Add note" -> one line under the exercise name ("Seat 4, pin 6"), kept on the exercise, so it shows in every routine and workout. Clear it by saving an empty note. Set notes: none; old ones stay when a set is edited and show in History.
- Keyboard: decimal pad for weight, number pad for reps. Scrolling hides the keyboard and saves valid edits. Invalid numbers -> toast "Enter a valid weight and reps.", the field stays open ([ActiveWorkoutView.swift:713](Unit/Features/Today/ActiveWorkoutView.swift:713)).

**Saved data**
- Each Complete, Edit, Undo and Mark not done: database, at once.
- Typed targets: settings storage `unit.preparedSetTargets`, per workout ([ActiveWorkoutView.swift:28](Unit/Features/Today/ActiveWorkoutView.swift:28)).
- Raw typing not yet saved: screen memory `unit.loggingInputDrafts` ([ActiveWorkoutView.swift:29](Unit/Features/Today/ActiveWorkoutView.swift:29)).
- Session plan: settings storage `unit.activeWorkoutExerciseOrder`, per workout: order, swaps, added exercises, set counts, "+ Add set" rows, the skipped last exercise.
- Memory only, lost on restart: which exercise you jumped to.
- Bodyweight switch and pinned note: the exercise itself (all routines).

**Edge cases**
- Double tap on Complete -> second tap ignored for 0.4 s -> Low -> yes.
- Save fails -> alert "Couldn't save workout", nothing logged -> Med -> yes.
- Skip on the last unfinished exercise -> used to do nothing; fixed 2026-10-24 (card closes, Finish shows) -> Low -> yes.
- Accidental "+ Add set" -> "Remove added set" in the "..." menu, with Undo (fixed 2026-10-24) -> Med -> yes.
- Swapped-out routine exercise -> the summary lists it as "Some sets are unfinished", like a skipped one -> Low -> partial.
- Numbers edited on the current row (any set) -> kept for this workout; the next workout starts from set 1 of this one. The "Update routine with today's weights?" dialog was removed 2026-10-24: its answer never changed the next workout -> Low -> yes.
- Set 1 misses reps -> set 2 copies the lower reps; the accepted target is no longer visible for sets 2 and up -> Med -> partial (no target on the row, by design).
- Source text says "Last time" even when the prefill is the saved target, so the higher number has no explanation -> Med -> no.
- Bodyweight source text reads "Last time 0 × 12", not "BW × 12"; weighted rows show no unit ([ActiveWorkoutView.swift:654](Unit/Features/Today/ActiveWorkoutView.swift:654)) -> Low -> no.
- lb users saw "155.0" in fields and source text -> fixed 2026-10-23: weights round to one decimal and drop ".0" ([DesignSystem.swift:1087](Unit/UI/DesignSystem.swift:1087)) -> Low -> yes.
- Long-press anywhere on the open card can start a drag while typing -> Low -> unclear from code (needs a device check).
- Notifications off -> one self-dismissing notice per workout: "Rest alerts are off. Enable notifications in Settings." (fixed 2026-10-23; it used to return after every set and stay until closed) ([ActiveWorkoutView.swift:379](Unit/Features/Today/ActiveWorkoutView.swift:379)).
- Bodyweight switched mid-workout -> past workouts of that exercise also display as BW -> Low -> partial.
- "Last time" used the last set of the last workout, often the weakest -> fixed 2026-10-24: set 1 starts from set 1 of this routine's last workout -> Low -> yes.

---

## 4. Rest timer

**Purpose**
- Count rest without attention and call the lifter back on time.

**Entry**
- Starts by itself after each logged set, except the final set of the workout ([ActiveWorkoutView.swift:856](Unit/Features/Today/ActiveWorkoutView.swift:856)).

**Steps**
- Complete set -> rest starts with that exercise's own length, else the default (120 s at first, never under 15 s) ([ActiveWorkoutView.swift:923](Unit/Features/Today/ActiveWorkoutView.swift:923)).
- Rest bar -> blue progress line, "Rest" + countdown, buttons "-30", "+30", "Skip" (30-second steps since 2026-10-23; were 20). Buttons work only while running; "-30" is off at 15 s or less ([DesignSystem.swift:6780](Unit/UI/DesignSystem.swift:6780)).
- "+30" or "-30" -> new end time; the new length is saved for the exercise whose set started this rest (since 2026-10-24; it used to change every later rest). The idle bar shows the current exercise's length. There is no rest setting in Settings ([ActiveWorkoutView.swift:926](Unit/Features/Today/ActiveWorkoutView.swift:926)).
- "Skip" -> bar back to idle, no "finished" state, no alert; it also removes the set's Undo ([ActiveWorkoutView.swift:931](Unit/Features/Today/ActiveWorkoutView.swift:931)).
- Ends with the app open -> "Rest finished." + 0:00 for 30 s, success haptic, VoiceOver line, plus an iOS banner with sound -> idle ([ActiveWorkoutView.swift:1384](Unit/Features/Today/ActiveWorkoutView.swift:1384)).
- Phone locked or app in background -> Lock Screen and Dynamic Island Live Activity: "Rest timer", countdown, progress bar, "Up next" with the exercise name and the next set's line "Set 2 · 60 kg × 8" (only "Set 1" when that row has no starting target) ([RestTimerLiveActivity.swift:16](UnitWidget/RestTimerLiveActivity.swift:16)).
- Ends in background -> Live Activity shows "Rest finished"; time-sensitive notification "Rest finished / Next: Bench Press · Set 2 · 60 kg × 8" ([ActiveWorkoutView.swift:1574](Unit/Features/Today/ActiveWorkoutView.swift:1574)).
- Back to the app -> time recalculated from the saved end time; Live Activity closed ([ActiveWorkoutView.swift:1436](Unit/Features/Today/ActiveWorkoutView.swift:1436)).
- First rest ever -> iOS asks for notification permission in the middle of the workout.

**Saved data**
- Settings storage `unit.restTimer.*` (end time, length, up next and next-set line, finished time, the set and exercise that started it), `unit.restSecondsByExercise` (length per exercise) and `restDurationSeconds` (default).
- Live Activity state, owned by iOS.

**Edge cases**
- Undo or "Mark not done" on the set that started rest -> rest stops -> Low -> yes.
- Plan changes during rest (add set, jump, edit) -> "Up next" text updates, end time unchanged -> Low -> yes.
- App killed during rest -> timer restored from saved state or the Live Activity ([ActiveWorkoutView.swift:1521](Unit/Features/Today/ActiveWorkoutView.swift:1521)) -> Med -> yes.
- Notifications off -> warning toast in the app (flow 3), no alert when the phone is locked; the Live Activity still counts down -> Med -> partial.
- Lock Screen and expanded Dynamic Island: −30 / +30 / Skip during rest (2026-10-24), the same steps as the app; they run after Face ID unlocks the phone. No "Complete set" from the Lock Screen yet -> Low -> partial.
- Finish or cancel during rest -> timer stopped, Live Activity closed -> Low -> yes.
- Rest ends while the app stays closed -> "Rest finished" stays on the Lock Screen until the app opens -> Low -> partial.
- Rest length per exercise -> remembered from −30 / +30 (2026-10-24) -> Low -> yes.
- Idle bar still shows "Rest 2:00" with grey buttons; it can look like a paused timer -> Low -> partial.
- A new timer object is built on every Today redraw and reads saved timer state each time ([ActiveWorkoutView.swift:31](Unit/Features/Today/ActiveWorkoutView.swift:31), [ActiveWorkoutView.swift:1350](Unit/Features/Today/ActiveWorkoutView.swift:1350)) -> Low -> unclear from code, likely harmless.

---

## 5. Exercise done moment

**Purpose**
- Close an exercise, show its result, move on without a tap.

**Entry**
- The last planned set of an exercise is logged.

**Steps (what the lifter sees, in order)**
- "Complete set 3" -> same success haptic as any set. No special sound or motion for "exercise done" ([ActiveWorkoutView.swift:855](Unit/Features/Today/ActiveWorkoutView.swift:855)).
- Card closes into a small card with grey text: name, "3 × 60 kg × 10" (or "3 sets" when sets differ), "Undo" for 5 s, check ([ActiveWorkoutView.swift:639](Unit/Features/Today/ActiveWorkoutView.swift:639), [DesignSystem.swift:6717](Unit/UI/DesignSystem.swift:6717)).
- No next-time line on the done card since 2026-10-24 (founder): it shows only the name, the logged sets, a PR tag and the check. Next targets live on the summary.
- No line when progression is off. When the rule gives no suggestion, a muted line without the icon says why: "No suggestion · Weights varied.", "· Added weight is required." or "· Set a weight increase." (2026-10-23).
- Next unfinished exercise opens. If it is the next card in the list, the screen scrolls so the finished card stays on top; otherwise it scrolls to the next exercise ([ActiveWorkoutView.swift:834](Unit/Features/Today/ActiveWorkoutView.swift:834)).
- Rest starts; the Lock Screen "Up next" names the next exercise, Set 1.
- After 0.4 s the tap lock lifts. VoiceOver hears "Set 3 logged. Rest 2:00".
- Last exercise of the day -> every card closed with checks (and suggestion lines), no rest. The rest bar becomes a full-width "Finish workout" button (2026-10-23); the small "Finish" stays in the nav bar.

**Saved data**
- The set only. Finish calculates and saves the next target.

**Edge cases**
- Undo within 5 s -> exercise reopens, the line disappears -> Low -> yes.
- Set edited after the exercise is done -> line recalculates live -> Low -> yes.
- Next unfinished exercise is not directly below (after a skip) -> finished card and its Undo scroll out of view -> Low -> partial.
- Tap a finished card -> it opens with its sets, no suggestion line inside; you must tap the next exercise to continue -> Low -> partial.
- Sets with different numbers -> card says "3 sets", the numbers are hidden -> Low -> no.
- Done card and summary used two formats -> moot since 2026-10-24: the done card no longer shows next time -> Low -> yes.
- All exercises done -> full-width "Finish workout" replaces the rest bar -> Low -> yes (2026-10-23).
- "+ Add set" used -> no line until the extra set is logged -> Low -> yes.

---

## 6. Finish workout

**Purpose**
- Save the workout, record progression evidence, show the result.

**Entry**
- "Finish" (top right, after at least 1 logged set) or X (top left).

**Steps**
- All or some sets done -> "Finish" -> any open edit saved first -> alert "Finish workout? Saves and ends your session." -> "Finish workout" ([ActiveWorkoutView.swift:979](Unit/Features/Today/ActiveWorkoutView.swift:979), [ActiveWorkoutView.swift:315](Unit/Features/Today/ActiveWorkoutView.swift:315)).
- Freestyle -> alert "Name this workout" -> "Use name" or "Skip". Skip with a typed name asks "Discard workout name?" ([ActiveWorkoutView.swift:319](Unit/Features/Today/ActiveWorkoutView.swift:319)).
- No "Update routine with today's weights?" dialog since 2026-10-24 ([ActiveWorkoutView.swift:1004](Unit/Features/Today/ActiveWorkoutView.swift:1004)).
- Save -> workout marked done, progression evidence captured once per exercise with progression on, every suggested target saved to the routine (2026-10-24), typed targets and order cleared, rest stopped ([ActiveWorkoutView.swift:1016](Unit/Features/Today/ActiveWorkoutView.swift:1016), [WorkoutSession.swift:156](Unit/Models/WorkoutSession.swift:156)).
- "Save to Apple Health" on (Settings > Preferences) -> the workout is saved to Apple Health as strength training, from its start to the Finish tap, in the background. Skipped under 1 minute or over 4 hours ([ActiveWorkoutView.swift:1039](Unit/Features/Today/ActiveWorkoutView.swift:1039), [HealthWorkoutStore.swift:25](Unit/Data/HealthWorkoutStore.swift:25)).
- Today -> confetti (first workout: shower, later: popper) + success haptic -> post-workout summary opens ([TodayView.swift:459](Unit/Features/Today/TodayView.swift:459)).
- Summary -> routine name, date, exercise cards with PR tags, "Next time" section (flow 7), feedback card on the 3rd workout -> back arrow returns to Today. After the first workout, the iOS review prompt shows 2 s after returning ([TodayView.swift:480](Unit/Features/Today/TodayView.swift:480)).
- Nothing logged -> no "Finish"; only X.
- Cancel -> X -> "Cancel workout? Logged sets will be lost." -> "Cancel workout" -> workout and its sets deleted, no undo ([ActiveWorkoutView.swift:1075](Unit/Features/Today/ActiveWorkoutView.swift:1075)).
- App killed mid-workout, then opened -> the same workout opens. Back: logged sets, typed targets, order, rest timer. Lost: raw typing after a force quit, "+ Add set" rows, jump or skip choice.
- Next day (previous calendar day and 4 h or more since start) on a cold launch -> empty workout deleted with a toast; with sets -> "Workout from yesterday" alert ([TodayView.swift:417](Unit/Features/Today/TodayView.swift:417)).

**Saved data**
- Workout marked finished, plus progression evidence per exercise (database).
- Routine next target, planned weight and reps, for every exercise with a suggestion.
- Apple Health workout (strength training, start and end), only if "Save to Apple Health" is on and iOS allows it.
- Engagement counters: review ask after the 1st workout, feedback card on the 3rd.

**Edge cases**
- Some sets not done -> the alert gives no warning; exercises with progression on show "Some sets are unfinished" in the summary -> Low -> partial.
- Save fails -> alert, workout stays open -> Med -> yes.
- "Mark complete" or "Discard" from the yesterday alert leave typed targets and order keys behind ([TodayView.swift:446](Unit/Features/Today/TodayView.swift:446)) -> Low -> no.
- Cancel used to make a flexible schedule skip this routine -> fixed 2026-10-23: cancel restores the routine's last-performed date -> Low -> yes.
- App resumed from background the next day -> no yesterday alert until a cold launch -> Med -> no.
- Subscription ends mid-workout -> paywall covers the app; the workout is kept ([ContentView.swift:35](Unit/ContentView.swift:35)) -> Low -> partial.
- Workout crossing midnight -> listed on the start day -> Low -> by design.
- Workout saved with "Mark complete" from the "Workout from yesterday" alert -> not saved to Apple Health: Unit stores no end time -> Low -> by design.
- Workout deleted later -> its Apple Health copy stays until the delete flow calls `HealthWorkoutSync.removeWorkout` -> Low -> no (waits on History delete).

---

## 7. Post-workout progression

**Purpose**
- Save the smallest next step at Finish. The lifter can keep the previous target or edit it.

**Entry**
- Summary right after Finish.
- Later: History -> the workout.

**When it runs**
- Only for exercises with progression on in this routine: "Increase reps, then weight" in the target sheet ([DesignSystem.swift:4739](Unit/UI/DesignSystem.swift:4739)), a rep range in a pasted program, or a ready-made program (its own ranges, or the standard rule added 2026-10-23) ([ProgramImporter.swift:165](Unit/Data/ProgramImporter.swift:165)).

**Inputs** ([WorkoutSession.swift:125](Unit/Models/WorkoutSession.swift:125))
- Planned working sets (routine), rep range (start reps to top reps), weight step, current target reps, this workout's sets (warm-ups ignored).
- "Previous target" on screen = the accepted weight, or else your first set's weight, with the current target reps ([WorkoutSession.swift:185](Unit/Models/WorkoutSession.swift:185)).

**Rules, checked in this order** ([DoubleProgressionEngine.swift:113](Unit/Engine/DoubleProgressionEngine.swift:113))
1. Broken settings (0 sets, bad range, step 0 or less, target reps outside the range) -> no target, "No target available." (step problem: "Set a weight increase.").
2. Bodyweight exercise with no added weight on any set -> no target, "Added weight is required."
3. Fewer completed sets than planned -> no target, "Some sets are unfinished."
4. Any set with 0 kg or 0 reps -> no target, "No target available."
5. Not every set at the same weight (extra or back-off sets count) -> no target, "Weights varied."
6. Any planned set below the target reps -> same weight you lifted, same target reps, "Keep this target." The summary names the short sets: "Set 3: 6 of 8 reps. Keep this target." (2026-10-24).
7. Every set, extra sets too, at or above top reps -> weight + step, reps back to start reps, "Every set reached the top."
8. Otherwise -> same weight, target reps + 1, "Same weight. Add one rep." Already at top reps -> "Keep this target."
- "Weights varied", "Some sets are unfinished" and "No target available" also add "Set a target next workout." ([SessionDetailView.swift:633](Unit/Features/History/SessionDetailView.swift:633)).

**Weight step**
- Default 2.5 kg. lb users 5 lb (stored as 2.268 kg). Pasted programs use the same defaults ([OnboardingViewModel.swift:524](Unit/Features/Onboarding/OnboardingViewModel.swift:524)). Combat Power sets its own (1, 2, 2.5 or 5 kg); other ready-made programs use 2.5 kg, 2 kg for dumbbells, or 5 lb.
- The lifter can type any step above 0 in the target sheet.
- Bodyweight with added weight: the added weight steps up. Bodyweight only (reps only): not supported.

**Where it appears**
- At exercise done: read-only line (flow 5).
- Summary page: a "Next time" card with saved targets, then a "No automatic target" card, each row compact. Right after Finish they come first; from History they sit below the exercise list ([SessionDetailView.swift](Unit/Features/History/SessionDetailView.swift)). Tap a row to see the details or change it.
- Today: the saved target is the row's main line, "Last time" under it. Inside the workout only as set 1's prefill.

**Steps**
- Summary -> one row per exercise: name (small, grey), next target (large, darkest) and a tag ("+2.5 kg", "+1 rep", "same target", "Kept", "Edited", or "Not saved" for an old suggestion). Rows without a target show the reason instead.
- Finish already saved the target as fixed numbers (saving twice cannot add a second step) and updated the routine's planned weight and reps ([WorkoutSession.swift:156](Unit/Models/WorkoutSession.swift:156), [DayTemplate.swift:210](Unit/Models/DayTemplate.swift:210)). "Save for next workout" remains only for a suggestion Finish could not save.
- Tap a row -> one sheet: Previous target, Logged, the reason, editable weight and reps, and one shortcut ("Use previous: 3 × 9 at 107 kg", or "Use suggested: ..." after a change). "Save changes" saves what the fields hold; a retyped suggestion or previous target counts as that, anything else as "Edited".
- The sheet keeps Save grey while reps are outside the range or the weight is empty.
- Back arrow without deciding -> the saved targets stay; the next workout starts from them.
- Next workout -> set 1 of that exercise prefills the saved target ([ActiveWorkoutView.swift:1254](Unit/Features/Today/ActiveWorkoutView.swift:1254)); Today row shows "3 × 9 at 60 kg"; Analytics shows "Next 60 kg × 9".
- History -> open that workout -> same block with the decision and its evidence.

**Saved data**
- On the workout: evidence and decision per exercise (`progressionRecordsByExerciseIdData`).
- On the routine: accepted target per exercise (`progressionStateByExerciseIdData`), plus planned weight and reps.

**Edge cases**
- Ready-made programs: only Combat Power defines ranges (10 of 245 catalog items). Since 2026-10-23 every other program gives weighted lifts the standard rule at import (program reps to +2, then +2.5 kg / 2 kg dumbbells / 5 lb); bodyweight, timed or 20+ rep work and 5/3/1 percentage sets get none ([ProgramImporter.swift:165](Unit/Data/ProgramImporter.swift:165)) -> Med -> yes.
- Sets, rep range or weight step changed in the target sheet after accepting -> the accepted weight is kept and reps clamp into the new range (fixed 2026-10-23; it used to be dropped silently) ([DayTemplate.swift:377](Unit/Models/DayTemplate.swift:377)) -> Low -> yes.
- Summary skipped -> nothing lost: Finish already saved the suggestion (2026-10-24). After the next workout of this routine the old block can no longer be changed ([SessionDetailView.swift:589](Unit/Features/History/SessionDetailView.swift:589)) -> Med -> yes.
- Bodyweight-only exercises never get a suggestion -> Med -> no (by design today).
- One back-off set at another weight -> no suggestion for the whole exercise -> Med -> no.
- Skipped exercise with progression on -> listed as "No automatic target. Some sets are unfinished." -> Low -> partial.
- No-target blocks (weights varied, sets unfinished, no target available) have Edit since 2026-10-24, starting from the previous target ([SessionDetailView.swift:58](Unit/Features/History/SessionDetailView.swift:58)) -> Med -> yes.
- Edit sheet: reps outside the range keep "Save changes" grey, with no message ([SessionDetailView.swift:673](Unit/Features/History/SessionDetailView.swift:673)) -> Low -> no.
- First evaluated workout shows a "Previous target" the lifter never set (start reps + first set weight) -> Low -> no.
- Rule changed after the workout -> that old block shows no buttons -> Low -> yes.
- Same exercise in two routines -> separate targets per routine; "Last time" mixes routines -> Low -> by design.
- Save fails -> rollback, toast "Targets weren’t saved. Try again." -> Low -> yes.
- Missed reps at a heavier weight than the target -> "Keep this target" at the heavier weight you lifted -> Low -> by design.
- "+1 rep" is always one rep, even when most sets beat the target by 3 -> Low -> by design.

---

## 8. History

**Purpose**
- Review past workouts and records.

**Entry**
- Today -> "History" (top right). Not reachable during a workout; one exercise's page is, from the card's "..." menu (flow 3).

**Steps**
- History -> "List" or "Calendar" switch ([HistoryView.swift:245](Unit/Features/History/HistoryView.swift:245)).
- List -> "This week" (weekly schedules only): routines missed earlier this week, tag "Missed", "Tap to start" -> starts that workout (flow 2) ([HistoryView.swift:375](Unit/Features/History/HistoryView.swift:375)).
- List -> months -> rows: date, routine, "N exercises", "PR" tag, state tag (Completed, Partial, Skipped) -> tap -> workout detail ([HistoryView.swift:385](Unit/Features/History/HistoryView.swift:385)).
- Filter chips "Completed" and "Missed" (tap again to clear). "Missed" shows only this week's missed routines ([HistoryView.swift:434](Unit/Features/History/HistoryView.swift:434)).
- Calendar -> month grid: filled day = workout; outlined = missed scheduled day, or today -> tap a workout day -> sheet with that day's workouts -> exercise -> progress page; tap a missed day -> "Missed" card with the routine name ([HistoryView.swift:452](Unit/Features/History/HistoryView.swift:452)).
- Workout detail -> name, date, exercise cards (same numbers: "3 × 8 at 60 kg"; different numbers: one line per set), PR tags, notes -> tap an exercise -> progress page (flow 9); "Next time" block (flow 7) ([SessionDetailView.swift:95](Unit/Features/History/SessionDetailView.swift:95)).
- Edit a past workout (added 2026-10-24): workout detail -> pencil (top right, also on the summary right after Finish) -> "Edit workout" lists every logged set -> tap a set -> menu "Edit set" / "Delete set" ([EditWorkoutView.swift](Unit/Features/History/EditWorkoutView.swift)).
  - "Edit set" -> sheet with Weight and Reps -> "Save changes" -> saved at once ([EditSetSheet.swift](Unit/Features/History/EditSetSheet.swift)).
  - "Delete set" -> removed at once, toast "Set removed" with Undo. The last set left asks the Delete workout question instead.
  - Trash (top right) -> "Delete workout" confirm -> workout and its sets deleted -> back to History (or Today from the summary). Checkmark closes Edit workout.
- Imported history (added 2026-10-24): workouts from a Strong or Hevy import show like any other, named as in the file, on hidden routines. They feed PR tags, "Last time", the progress page and Analytics, and have no "Next time" block.
- Lapsed subscriber (added 2026-10-24): paywall -> "View workout history" (only when the phone has logged sets) -> the same History, read-only: no "This week" start rows, no "Next time" buttons, no pencil; top right "Export" ([ReadOnlyHistorySheet.swift](Unit/Features/History/ReadOnlyHistorySheet.swift)).

**PR badges** ([HistoryView.swift:548](Unit/Features/History/HistoryView.swift:548))
- Replays all finished workouts in date order, per exercise. The first set ever is the baseline.
- A set is a PR when it is heavier than the best so far, or the same weight with more reps.
- Shown on History rows, exercise cards and set lines, and during the workout on logged sets and done cards (same replay, run on the open workout).

**Saved data**
- Database, at once: a catch-up start, an edited set, a deleted set or workout ([WorkoutSession+Editing.swift](Unit/Models/WorkoutSession+Editing.swift)).
- After an edit: PR tags, Analytics, the progress page and "Last time" recalculate from the saved sets. A saved next target never changes. The workout's "Next time" block: a saved decision keeps its target and shows the corrected sets; an unsaved suggestion on the routine's newest workout is recalculated; an unsaved one on an older workout is removed.
- Deleting the routine's newest workout restores its last-done date, so the rotation offers the right routine next.

**Edge cases**
- Wrong numbers in a past workout -> Edit workout fixes or deletes them -> Med -> yes.
- Deleting the workout a saved target came from -> the target stays on the routine; change it in the routine's target sheet -> Low -> by design.
- Set numbers after a deleted set keep their gap ("Set 1", "Set 3") -> Low -> no.
- Adding a set or changing the date of a past workout -> not possible -> Low -> no.
- First workout with ramp-up sets -> later heavier sets get "PR" (the baseline is the first set, not the first workout) -> Low -> no.
- Lighter set with many more reps -> never a PR -> Low -> by design.
- Program switch -> past "missed" days follow the new program's weekdays (from the day that program was created) -> Low -> partial.
- Catch-up row starts on one tap -> Low -> no.
- Unfinished workouts show as "Partial" and have no "Next time" block -> Low -> yes.

---

## 9. Analytics

**Purpose**
- Show if each lift is going up.

**Entry**
- Analytics tab (hidden during a workout).

**Steps**
- Analytics -> "Last 4 weeks" card: "Getting stronger", "Holding steady", "Fewer sessions lately" or "Building a baseline", plus one line ("2 of 3 lifts up. 7 of 12 sessions done.") -> tap -> "How this works" ([AnalyticsView.swift:23](Unit/Features/Analytics/AnalyticsView.swift:23)).
- "Main lifts" (up to 3) -> card: latest best set, date, 4-week change, 12-week chart, Best, Next (accepted target) -> tap -> detail ([AnalyticsView.swift:30](Unit/Features/Analytics/AnalyticsView.swift:30), [DesignSystem.swift:6427](Unit/UI/DesignSystem.swift:6427)).
- "Edit" -> Main lifts editor: reorder or remove shown lifts, add from the list (max 3), "Use automatic", Cancel or Done ([MainLiftsEditor.swift:4](Unit/Features/Analytics/MainLiftsEditor.swift:4)).
- "Sets per muscle · last 4 weeks" -> one row per muscle, most sets first, "Other" ("Muscle unknown") last; a muscle trained in the last 12 weeks but not the last 4 shows "0 sets". Read-only ([AnalyticsView.swift:55](Unit/Features/Analytics/AnalyticsView.swift:55)).
- "Other exercises" -> name + latest best set -> detail ([AnalyticsView.swift:74](Unit/Features/Analytics/AnalyticsView.swift:74)).
- Detail -> latest set (large), "4-week comparison" with "60 kg × 8 -> 62.5 kg × 8", Weight / Reps / Volume picker (not for bodyweight), chart you can scrub, "Next" card, Best set, Est. 1RM with an info popover, Recent (last 2 workouts) ([ExerciseProgressView.swift:42](Unit/Features/History/ExerciseProgressView.swift:42)).

**Rules**
- Best set: heaviest weight, then most reps. Bodyweight: most reps.
- Compare: best set of the last 28 days vs the 28 days before -> Up, Same, Below best, Mixed, or no comparison ([AnalyticsEngine.swift:186](Unit/Features/Analytics/AnalyticsEngine.swift:186)).
- Status: under 14 days or 1 workout -> baseline; under half of planned workouts (routines × 4) -> fewer; at least 2 lifts compared, half or more up, and 75% of planned workouts done -> stronger; else steady. A new status must hold 3 days in a row ([AnalyticsEngine.swift:290](Unit/Features/Analytics/AnalyticsEngine.swift:290)).
- Main lifts: Squat, Bench Press and Deadlift found by name (barbell or no equipment set), trained in the last 12 weeks; then the most trained compound lifts of the last 8 weeks ([AnalyticsEngine.swift:342](Unit/Features/Analytics/AnalyticsEngine.swift:342)).
- Est. 1RM: weight × (1 + reps / 30), for 1 to 12 reps ([AnalyticsEngine.swift:231](Unit/Features/Analytics/AnalyticsEngine.swift:231)).
- Sets per muscle: completed working sets (no warm-ups) in the same 28 days as the status, each counted once for the exercise's main muscle ([AnalyticsEngine.swift:239](Unit/Features/Analytics/AnalyticsEngine.swift:239)).
- Muscle: the saved one unless it is the default Full Body (onboarding saves names only); then the exercise library by name or alias, ignoring spacing, plurals, "bicep/tricep" and "DB/BB"; else unknown. Nothing is saved. The detail page shows the muscle only when known ([ExerciseCatalog.swift:1099](Unit/Data/ExerciseCatalog.swift:1099)).

**Saved data**
- Chosen main lifts: settings storage `unit.analytics.mainLiftIDs`. Everything else is calculated.

**Edge cases**
- No finished workouts -> "No workouts yet. Finish a workout to see progress." -> Low -> yes.
- Load error -> "Couldn't load progress" + Retry -> Low -> yes.
- Refresh -> on every save, new day, time zone change, app back to front -> Low -> yes.
- Flexible schedule trained less often than the routine count per week -> "Fewer sessions lately" -> Low -> partial.
- No "Next" when progression is off, and no hint why -> Low -> no.

---

## 10. Programs

**Purpose**
- Set what Today shows: programs, routines, exercises, targets, schedule.

**Entry**
- Programs tab (hidden during a workout).

**Steps**
- Programs -> active program name + pencil (Edit program), routine list (-> routine detail), "Freestyle session", "Other programs" ([TemplatesView.swift:128](Unit/Features/Templates/TemplatesView.swift:128)).
- Other program -> detail -> "Use this program" -> "Switch to X?" -> becomes active; Today follows ([ProgramDetailView.swift:45](Unit/Features/Templates/ProgramDetailView.swift:45)).
- "Browse" (top left) -> library with Level, Goal and Days filters -> program -> "Use this program" -> "Import X?" -> new copy of the program, missing exercises created, set active, back to Programs ([ProgramLibraryView.swift:70](Unit/Features/Templates/ProgramLibraryView.swift:70), [ProgramLibraryDetailView.swift:99](Unit/Features/Templates/ProgramLibraryDetailView.swift:99)).
- Edit program -> name (saves as you type); routines: flexible = drag to reorder, weekly = weekday menu per routine (taken days off); "Add routine" (New day sheet); "Add weekly schedule" (Mon, Tue, Wed... in list order) or "Use flexible schedule"; trash -> "Delete program" ([TemplatesView.swift:287](Unit/Features/Templates/TemplatesView.swift:287)).
- Routine detail -> exercises with a target line ("3 × 8-10 · +2.5 kg", "3 × 8" or "No history yet") -> tap -> target sheet: Sets; Reps, or Start reps and Top reps; "Increase reps, then weight" switch; "Weight increase" -> "Save changes" ([TemplateDetailView.swift:57](Unit/Features/Templates/TemplateDetailView.swift:57), [DesignSystem.swift:4739](Unit/UI/DesignSystem.swift:4739)).
- Routine detail -> "×" -> exercise removed, toast with Undo for 4 s ([TemplateDetailView.swift:318](Unit/Features/Templates/TemplateDetailView.swift:318)); long-press drag to reorder ([TemplateDetailView.swift:167](Unit/Features/Templates/TemplateDetailView.swift:167)).
- Routine detail -> "Add exercise" -> picker: search name or alias, "Create 'X'", "Restore 'X'" for a deleted one; one pick per open ([DesignSystem.swift:4980](Unit/UI/DesignSystem.swift:4980)).

**Saved data**
- Programs, routines (order, weekday, planned sets, reps, weight, progression rule) and new exercises in the database.
- Active program: settings storage `activeSplitId`.

**Edge cases**
- Delete program -> routines with history are kept hidden (names stay in History), others deleted; last program deleted -> onboarding ([TemplatesView.swift:604](Unit/Features/Templates/TemplatesView.swift:604)) -> Med -> yes.
- Delete or rename one routine -> not possible -> Med -> no.
- "Add weekly schedule" with 3 routines -> Mon, Tue, Wed, back to back -> Low -> partial (each day can be changed).
- Unschedule one routine in weekly mode -> not possible (no "none" in the menu) -> Low -> no.
- Same library program imported twice -> two copies -> Low -> no.
- Import confirm says "Adds the program to your list", but it also becomes the active program -> Low -> no.
- Target sheet changed after accepting a suggestion -> accepted weight kept, reps clamp into the new range (fixed 2026-10-23, flow 7) -> Low -> yes.
- Swipe down on the target sheet -> edits dropped, no question -> Low -> partial.
- Exercise library screen (delete, rename, bodyweight) exists in code, but nothing opens it ([ExercisesListView.swift:21](Unit/Features/Templates/ExercisesListView.swift:21)) -> Low -> no.
- Program edits during a workout -> not reachable (tab bar hidden) -> Low -> yes.

---

## Code in this area that nothing opens

- Week strip and week sheet ([TrainingWeekProgress.swift:277](Unit/Features/Today/TrainingWeekProgress.swift:277)).
- Warm-up generator ([WarmupGenerator.swift:11](Unit/Engine/WarmupGenerator.swift:11)).
- Exercise library, add-exercise form, exercise detail ([ExercisesListView.swift:21](Unit/Features/Templates/ExercisesListView.swift:21)).
- Today "No program" and Programs "No active program" states; onboarding shows instead ([ContentView.swift:31](Unit/ContentView.swift:31)).
