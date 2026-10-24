# First run and paywall flows

- 13 sections: 12 user flows (launch, opener, unit, path, paste, ready-made, review, paywall, handoff, access refresh, Settings, prompts) plus the full analytics list.
- Taps from first launch to the paywall: ready-made path 8 taps on 7 screens; paste path 6 to 7 taps on 4 screens (2 to 3 of them are the iOS paste gesture). Both start with a 2 second opener.
- Risk 1 (was High, fixed 2026-10-23): paywall dead ends. Restore, Terms, Privacy and Support now show in every paywall state, and Restore works while a purchase is pending.
- Risk 2 (was High, fixed 2026-10-23): App Review and trust. The button now says "Start free trial" and the line above it starts with the billed price. The "Paid plan required after setup." line was removed by founder decision (2026-10-23).
- Risk 3 (Med, partly fixed 2026-10-23): wrong program data from setup. Fixed: comma decimals, a cut 7th day is reported, unit-free numbers are re-read when kg/lb changes. Still open: "RPE 8" is read as 8 kg and junk rows cannot be deleted.

Source: code at commit `499ecaf`, updated for commit `75fceb0` (paywall, setup and summary fixes) (branch `claude/app-finalization-launch-34a116`), read on 2026-10-23. That commit cut setup to 3 steps (the weight-unit and weekday screens are gone). Other sessions were editing this branch while this was written, so line numbers can drift. Nothing here was run on a phone or simulator; paste edge cases were checked by running a Mac copy of ProgramImportParser.swift. Where the code does not answer a question, the text says "unclear from code".

## How to read this doc

- Steps: screen -> action -> result.
- Edge cases: case -> what the app does today -> risk -> handled.
- Risk: High = can block paying, restoring or trusting the app. Med = wrong data, or a stuck user in some cases. Low = rare, cosmetic, or analytics only.
- Handled: yes = covered in code. partial = covered in some paths only. no = not covered.
- Links open the code line they name.

## Words used

- Apple purchase system (StoreKit): loads prices, shows the Apple purchase sheet, and tells the app what the Apple Account owns.
- Access (entitlement): Apple's answer to "does this Apple Account have an active plan?".
- Cache: the last access answer, saved on the phone so the app can open without waiting for Apple.
- Live purchase feed (`Transaction.updates`): Apple's stream of purchase changes while the app runs, such as renewals, refunds and Ask to Buy approvals.
- Database (SwiftData): permanent on-phone storage for programs, days, exercises and workouts.
- Settings storage (UserDefaults): small on-phone values such as the unit, drafts and flags.
- Event: one anonymous analytics signal sent to TelemetryDeck.
- Program = `Split` in code. Day or routine = `DayTemplate`.

---

## 1. App launch and routing

- **Purpose**: Pick the first screen: setup, a short spinner, the paywall, or the app.
- **Entry**: Every cold start. [UnitApp.swift:38](Unit/UnitApp.swift:38)
- **Steps**:
  - App start -> open the on-phone database -> if that fails, run on an empty temporary database and raise a warning flag. [UnitApp.swift:97](Unit/UnitApp.swift:97), [UnitApp.swift:123](Unit/UnitApp.swift:123)
  - App start -> analytics set up (section 13). [UnitApp.swift:41](Unit/UnitApp.swift:41)
  - Root screen built -> purchase manager created -> it reads the cached access answer, starts listening to Apple's live purchase feed, asks Apple for active purchases, and starts a 5 second timer. [ContentView.swift:22](Unit/ContentView.swift:22), [StoreManager.swift:627](Unit/Features/Subscription/StoreManager.swift:627)
  - Routing, checked in this order: [ContentView.swift:47](Unit/ContentView.swift:47)
    - No program saved -> setup. [ContentView.swift:31](Unit/ContentView.swift:31)
    - Program saved, access not known yet -> spinner. [ContentView.swift:39](Unit/ContentView.swift:39)
    - Program saved, no access -> paywall. [ContentView.swift:35](Unit/ContentView.swift:35)
    - Program saved, access -> tabs Today, Programs, Analytics. [ContentView.swift:56](Unit/ContentView.swift:56)
  - Returning user -> no spinner. The cached answer decides at once; Apple's answer corrects it a moment later if needed.
  - First install -> no cache -> setup shows anyway. If Apple has not answered 5 seconds after start, access counts as "none". [StoreManager.swift:958](Unit/Features/Subscription/StoreManager.swift:958)
- **Saved data**:
  - `storeManager.lastKnownEntitlement` (Settings storage): missing = never checked, empty = no access, otherwise the plan ID. [StoreManager.swift:520](Unit/Features/Subscription/StoreManager.swift:520)
  - `unit.persistenceRecoveryNotice` flag for the database warning. [UnitApp.swift:184](Unit/UnitApp.swift:184)
  - Database file `Application Support/Unit/Unit.store`. [UnitApp.swift:141](Unit/UnitApp.swift:141)
- **Events**: TelemetryDeck session start. `onboarding_started` when setup shows.
- **Edge cases**:
  - First launch -> setup; the access check runs quietly in the background -> Low -> yes.
  - Returning user with a plan -> tabs open from the cache -> Low -> yes.
  - Returning user without a plan -> paywall opens from the cache -> Low -> yes.
  - Offline launch with a plan -> tabs open from the cache, then Apple's on-phone data decides. If that data says "expired" (for example a weekly plan that renewed while the phone had no signal), access is removed and the paywall shows with no way to fix it offline. How fresh Apple's offline data is: unclear from code. The offline UI test skips Apple's check, so it does not cover this -> Med -> partial. [OnboardingPaywallFlowUITests.swift:737](UnitUITests/OnboardingPaywallFlowUITests.swift:737)
  - Apple's check hangs -> with a cache, the cached answer stays; on first install, access counts as "none" after 5 seconds and Restore can fix it -> Low -> yes.
  - Database cannot open (failed update of the data format, damaged file) -> the app runs on an empty temporary database: the user sees setup from the start plus the alert "Training data unavailable" that ends with "contact support". Nothing done in this session is saved. The alert has no contact button -> High (rare) -> partial. [ContentView.swift:64](Unit/ContentView.swift:64)
  - Launch-time data updates -> there is no versioned migration plan, only SwiftData's automatic update, with the case above as the fallback. Old drafts saved as "manual" or "history" open the ready-made path [OnboardingView.swift:266](Unit/Features/Onboarding/OnboardingView.swift:266). Old drafts parked on the removed unit or weekday screens resume on the next screen [OnboardingView.swift:107](Unit/Features/Onboarding/OnboardingView.swift:107). Old program names made of joined day names are repaired when Programs opens [TemplatesView.swift:259](Unit/Features/Templates/TemplatesView.swift:259) -> Low -> yes.
  - Paying user deletes their only program -> "no program" -> full setup again from the 2 second opener; `onboarding_started` and `program_setup_completed` fire again -> Low -> partial. [TemplatesView.swift:604](Unit/Features/Templates/TemplatesView.swift:604)
  - Refund or plan end noticed while the app is open -> the root swaps to the paywall at once, even in the middle of a workout. Logged sets are already saved -> Low -> partial.

## 2. Opener, carousel and paid-access notice

- **Purpose**: A short brand moment, three value slides, then start setup.
- **Entry**: First screen when no program exists. [OnboardingView.swift:374](Unit/Features/Onboarding/OnboardingView.swift:374)
- **Steps**:
  - Opener: black screen, logo, "Welcome to Unit", "Progressive overload made simple." -> taps do nothing -> after 2 seconds it fades into the carousel. With Reduce Motion or VoiceOver on there is no wait. [OnboardingSplashView.swift:31](Unit/Features/Onboarding/OnboardingSplashView.swift:31), [OnboardingSplashView.swift:104](Unit/Features/Onboarding/OnboardingSplashView.swift:104)
  - Carousel: 3 slides move on their own (first after 3 seconds, then every 4.5 seconds); swiping works. Slides: "Know what to lift next", "Build reps, then weight", "Log every set in one tap". Example weights follow the phone region (lb in the US, kg elsewhere). [OnboardingSplashView.swift:319](Unit/Features/Onboarding/OnboardingSplashView.swift:319), [OnboardingSplashView.swift:348](Unit/Features/Onboarding/OnboardingSplashView.swift:348)
  - Tap "Set up your program" -> "Choose your path". [OnboardingSplashView.swift:175](Unit/Features/Onboarding/OnboardingSplashView.swift:175), [OnboardingView.swift:379](Unit/Features/Onboarding/OnboardingView.swift:379)
- **Saved data**: Nothing until the button is tapped. Then the current step and its history are saved as a draft.
- **Events**: `onboarding_started`, `onboarding_slide_viewed`, then `onboarding_step_viewed` (method) on the button tap.
- **Edge cases**:
  - App closed on the carousel -> the 2 second opener plays again next time -> Low -> yes.
  - The opener cannot be skipped with a tap -> 2 seconds added to every fresh start -> Low -> no.
  - The largest text sizes -> slide text stops growing at xxxLarge and slides scroll -> Low -> yes. [OnboardingSplashView.swift:192](Unit/Features/Onboarding/OnboardingSplashView.swift:192)
  - User spends 1 to 2 minutes on setup before learning a paid plan is needed -> Med (trust, App Review) -> no.

## 3. Weight unit

- **Purpose**: Decide kg or lb for every weight in the app.
- **Entry**: No screen of its own any more (removed 2026-10-23). The unit is guessed, then confirmed on Review.
- **Steps**:
  - Setup opens -> unit = the unit already saved on this phone, else the phone region (lb only for US measurement regions, kg everywhere else). [OnboardingView.swift:345](Unit/Features/Onboarding/OnboardingView.swift:345), [OnboardingViewModel.swift:172](Unit/Features/Onboarding/OnboardingViewModel.swift:172)
  - Paste path, "Read program" -> if the text only uses "lb" (or "#") the unit becomes lb; if it only uses "kg" it becomes kg; mixed or no units keep the guess. [OnboardingProgramImportView.swift:145](Unit/Features/Onboarding/OnboardingProgramImportView.swift:145), [OnboardingViewModel.swift:203](Unit/Features/Onboarding/OnboardingViewModel.swift:203)
  - Review program -> "Weight unit" kg/lb switch at the top -> changes how weights are shown. [OnboardingProgramPreviewView.swift:133](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:133)
  - "Save program" -> the unit is saved for the whole app; it can be changed later in Settings. [OnboardingView.swift:539](Unit/Features/Onboarding/OnboardingView.swift:539)
  - The old "Choose weight unit" screen still exists in code but is never shown; drafts saved before 2026-10-23 skip it. [OnboardingView.swift:107](Unit/Features/Onboarding/OnboardingView.swift:107)
- **Saved data**: Draft `onboarding.unitSystem`; app-wide `unitSystem` after saving. Weights are always stored in kg.
- **Events**: `weight_unit_selected` when the Review switch is used. [OnboardingProgramPreviewView.swift:143](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:143)
- **Edge cases**:
  - Paste with plain numbers ("Bench 3x8 60") in a region that guesses the other unit -> the numbers are read in the guessed unit. The Review switch only converts the display (60 lb becomes 27.2 kg); it does not re-read 60 as kg. The user must retype every weight -> Med -> no.
  - Default weight steps follow the Review switch (2.5 kg, 2 kg for dumbbells, or 5 lb); custom steps stay as they are -> Low -> yes. [OnboardingViewModel.swift:180](Unit/Features/Onboarding/OnboardingViewModel.swift:180)
  - Unit changed later in Settings -> display converts, nothing is lost -> Low -> yes.

## 4. Path choice

- **Purpose**: Pick "I have a program" (paste) or "I need a program" (ready-made).
- **Entry**: "Set up your program". Step 1 of 3, "Choose your path".
- **Steps**:
  - Tap "I have a program" -> "Paste program". [OnboardingView.swift:478](Unit/Features/Onboarding/OnboardingView.swift:478)
  - Tap "I need a program" -> question 1.
  - The first tap moves on by itself. Coming back shows the choice selected and a "Continue" button. [OnboardingImportMethodView.swift:29](Unit/Features/Onboarding/OnboardingImportMethodView.swift:29)
- **Saved data**: `onboarding.importMethod`, `onboarding.hasSelectedImportMethod`.
- **Events**: `onboarding_step_viewed` (method), `program_source_selected` on every tap. [OnboardingView.swift:412](Unit/Features/Onboarding/OnboardingView.swift:412)
- **Edge cases**:
  - Switching path after some progress -> both drafts are kept; the path used last decides what is saved -> Low -> yes.
  - Paste chosen with nothing to paste -> Back is the only way out; the paste screen does not point to the ready-made path -> Low -> partial.

## 5. Paste import

- **Purpose**: Turn pasted text into days, exercises, sets, reps and weights.
- **Entry**: "I have a program". Step 2 of 3.
- **Steps**:
  - "Paste program" -> tap the text box, paste or type -> "Read program" turns on once there is text. An empty box shows "Paste a program first." [OnboardingProgramImportView.swift:56](Unit/Features/Onboarding/OnboardingProgramImportView.swift:56), [OnboardingProgramImportView.swift:66](Unit/Features/Onboarding/OnboardingProgramImportView.swift:66)
  - "Show format examples" -> sheet with 3 short rules (day names, exercises, weight). [OnboardingProgramImportView.swift:169](Unit/Features/Onboarding/OnboardingProgramImportView.swift:169)
  - Tap "Read program" -> the parser runs on the phone -> days found: "Review program". None found: alert "Couldn't read that program" with "Show examples" or "Keep editing". [OnboardingProgramImportView.swift:140](Unit/Features/Onboarding/OnboardingProgramImportView.swift:140), [OnboardingProgramImportView.swift:154](Unit/Features/Onboarding/OnboardingProgramImportView.swift:154)
  - What the parser does (behavior only):
    - A day starts at a heading: a "#" markdown line, a known word (Push, Pull, Legs, Upper, Lower, weekdays, "Day 1", "Workout A" and more), or a short line after an empty line that is followed by exercises. [ProgramImportParser.swift:278](Unit/Features/Onboarding/ProgramImportParser.swift:278)
    - A line counts as an exercise only if it has sets x reps, a weight with a unit, a time or distance, a "5/3/1" scheme, or "N sets" or "N reps". [ProgramImportParser.swift:415](Unit/Features/Onboarding/ProgramImportParser.swift:415)
    - Exercises before any heading go into "Workout 1". [ProgramImportParser.swift:447](Unit/Features/Onboarding/ProgramImportParser.swift:447)
    - A plain number after sets x reps is the weight; "kg" or "lb" after it sets the unit; "BW" means bodyweight. Comma decimals work here ("62,5").
    - A rep range ("3x8-10") switches on progression for that exercise. [OnboardingViewModel.swift:554](Unit/Features/Onboarding/OnboardingViewModel.swift:554)
    - Cardio lines (bike, run, treadmill, warm up and similar) are skipped and counted. [ProgramImportParser.swift:928](Unit/Features/Onboarding/ProgramImportParser.swift:928)
    - At most 6 days; later days are cut. [ProgramImportParser.swift:113](Unit/Features/Onboarding/ProgramImportParser.swift:113)
  - Results go to Review (section 7), with "From: <your line>" under each row, and "Check sets and reps" where sets and reps were guessed (3x8).
- **Saved data**: The text (`onboarding.pastedProgramText`) is saved on every keystroke. Parsed rows are saved as `onboarding.dayExercises`. Parser warnings are not saved. [OnboardingView.swift:353](Unit/Features/Onboarding/OnboardingView.swift:353)
- **Events**: `onboarding_step_viewed` (paste). Nothing for a read attempt, a success or a failure.
- **Edge cases** (inputs run through a Mac copy of the parser on 2026-10-23):
  - Empty or spaces only -> button off with a hint -> Low -> yes.
  - Random text -> no days -> alert -> Low -> yes.
  - Names only, no numbers ("Push / Bench Press / Incline Press") -> every exercise line is dropped. The alert says "Put each day on its own line, then list each exercise below it", which is not the real cause (sets x reps are missing) -> Med -> partial. [ProgramImportParser.swift:809](Unit/Features/Onboarding/ProgramImportParser.swift:809)
  - Some lines without numbers -> those lines are dropped; Review says "N lines didn't parse." without naming them -> Med -> partial. [OnboardingProgramPreviewView.swift:391](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:391)
  - 7 or more days -> day 7 and later are cut. The parser creates a warning, but Review never shows it -> Med -> no. [ProgramImportParser.swift:51](Unit/Features/Onboarding/ProgramImportParser.swift:51)
  - "RPE 8" or "RIR 2" written before the number -> read as a weight of 8 kg or 2 kg, and "RPE" stays in the name ("Bench RPE"). "@8 RPE" works. "@ 75% 1RM" leaves "1RM" in the name -> Med -> no. [ProgramImportParser.swift:1279](Unit/Features/Onboarding/ProgramImportParser.swift:1279)
  - Instruction lines with numbers ("Rest 90s between sets", "Total time 60 min") -> become exercises ("Between Sets", "Total Time"). Visible on Review, but rows cannot be deleted there -> Med -> partial.
  - Day heading with a long dash ("Day 1" + long dash + "Upper") -> the day name gets double spaces -> Low -> no. [ProgramImportParser.swift:171](Unit/Features/Onboarding/ProgramImportParser.swift:171)
  - Same heading twice -> two days with the same name -> Low -> yes.
  - Weekday headings (Monday, Wednesday) -> used as day names only; the program still starts as a rotation -> Low -> partial.
  - Long paste (thousands of lines) -> the parser runs on the main thread, so the "Reading…" line never appears and the screen freezes. Mac timing: 1,813 lines 0.9 s, 10,000 lines 2.6 s; phones are slower. There is no length limit -> Low -> no. [OnboardingProgramImportView.swift:140](Unit/Features/Onboarding/OnboardingProgramImportView.swift:140)
  - Emoji, markdown bold, tables, numbered lists, comma decimals -> handled -> Low -> yes.
  - App closed mid-paste -> the text comes back on the next launch -> Low -> yes.

## 6. Ready-made program path

- **Purpose**: Match the user to 1 of 27 catalog programs with 3 answers.
- **Entry**: "I need a program". Step 2 of 3, with "Q 01 / 03" to "Q 03 / 03".
- **Steps**:
  - Q1 "What's your training goal?" -> Get stronger, Build muscle, or Strength + muscle -> the first answer moves on. [OnboardingLibraryPickerView.swift:379](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:379)
  - Q2 "How experienced are you?" -> New, Consistent, or Experienced -> moves on. [OnboardingLibraryPickerView.swift:392](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:392)
  - Q3 "How many training days?" -> 2 to 6, with 3 already selected -> "Continue". Tapping another number does not move on; "Continue" is still needed. [OnboardingLibraryPickerView.swift:406](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:406), [OnboardingLibraryPickerView.swift:414](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:414)
  - "Programs for you" -> top 3 cards; number 1 has a "Best match" badge and is preselected (2026-10-23), so "Review program" works in one tap; each card shows goal, experience, days and a reason line; a tap on another card changes the choice. [OnboardingLibraryPickerView.swift:323](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:323)
  - "See N more programs" -> the rest for the same day count. "Show fewer programs" hides them again and clears a pick from the hidden part. [OnboardingLibraryPickerView.swift:196](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:196), [OnboardingLibraryPickerView.swift:340](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:340)
  - Answer chips at the top of the results change any answer; a change clears the pick. [OnboardingLibraryPickerView.swift:220](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:220)
  - Back moves one question back; answers stay. [OnboardingLibraryPickerView.swift:350](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:350)
  - Matching: the day count must match. Score = goal (same 6, "Strength + muscle" on either side 3, else 0) + experience (same 4, one level apart 2, else 0). Ties keep catalog order. [ProgramCatalog.swift:51](Unit/Data/ProgramCatalog.swift:51), [ProgramCatalog.swift:66](Unit/Data/ProgramCatalog.swift:66)
  - Programs per day count: 2 days 2, 3 days 11, 4 days 6, 5 days 4, 6 days 4.
  - Next-target rule: programs with their own rep ranges keep them. All other programs give weighted lifts Unit's standard rule: start at the program's reps, build up to 2 more, then add 2.5 kg (2 kg for dumbbells, 5 lb in pounds). Bodyweight, timed, 20+ rep and 5/3/1 percentage sets get no rule. Added in commit 499ecaf. [ProgramImporter.swift:176](Unit/Data/ProgramImporter.swift:176)
  - There is no separate program detail screen in setup. Review (section 7) is the detail. Weights start empty.
- **Saved data**: `onboarding.preferredGoal`, `onboarding.preferredLevel`, `onboarding.preferredDaysPerWeek`, `onboarding.pickedProgramID`. After saving: `programSetup.context` (source, goal, experience, days) for the paywall copy and purchase events. [ProgramTemplate.swift:86](Unit/Data/ProgramTemplate.swift:86)
- **Events**: `onboarding_step_viewed` (library), `program_match_selected` on every card tap. [OnboardingLibraryPickerView.swift:333](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:333)
- **Edge cases**:
  - No match -> cannot happen today (every day count from 2 to 6 has programs). If it did, a hint shows and the grey button gives no reason -> Low -> partial.
  - Beginner picks 5 or 6 days -> only intermediate or advanced programs exist; one still gets "Best match", and its reason line says "Closest ready-made fit for your schedule" -> Low -> partial.
  - Pick from "See N more programs" (rank 4 or lower) -> the event sends rank "unknown" -> Low -> no. [OnboardingLibraryPickerView.swift:201](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:201), [UnitAnalytics.swift:286](Unit/Analytics/UnitAnalytics.swift:286)
  - Going back from Review and tapping the picked card again -> every weight typed on Review is reset -> Low -> no. [OnboardingViewModel.swift:577](Unit/Features/Onboarding/OnboardingViewModel.swift:577)
  - App closed between questions -> answers and the current question come back -> Low -> yes.
  - 7 training days -> not offered (no catalog program has 7) -> Low -> yes.

## 7. Program review and save

- **Purpose**: Check the program, confirm the unit, add optional starting weights, save.
- **Entry**: After "Read program" (paste) or "Review program" (ready-made). Step 3 of 3.
- **Steps**:
  - "Review program" -> "Weight unit" switch, a box for paste problems, then one card per day (first one open) with exercise rows: sets x rep range and a weight step when a next-target rule is on, or sets x reps and "Tracking only" when it is off, plus a weight box. [OnboardingProgramPreviewView.swift:106](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:106), [OnboardingProgramPreviewView.swift:242](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:242)
  - Tap a row -> "Edit exercise" sheet: rename, sets 1 to 10, reps 1 to 30. [OnboardingProgramPreviewView.swift:266](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:266)
  - Type a weight -> it becomes the "Starting target" of the first workout. [OnboardingProgramPreviewView.swift:368](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:368)
  - "Save program" -> program, days and exercises are written to the database and set as the active program. Weekdays are not set: every new program is a rotation. The root then moves to the paywall, or to the tabs if a plan is already active. [OnboardingView.swift:522](Unit/Features/Onboarding/OnboardingView.swift:522), [OnboardingView.swift:527](Unit/Features/Onboarding/OnboardingView.swift:527), [OnboardingViewModel.swift:384](Unit/Features/Onboarding/OnboardingViewModel.swift:384)
  - The weekday screen ("Set training days") was removed from setup on 2026-10-23. It still exists in code; drafts saved before that date skip it. Weekdays can be set later in Programs.
- **Saved data**: Database: the program, its days (planned sets, reps, weights, progression), and exercises. Settings storage: `activeSplitId`, `unitSystem`, `programSetup.context`. All `onboarding.*` drafts are cleared.
- **Events**: `onboarding_step_viewed` (review), `weight_unit_selected` (switch), `program_setup_completed` after a successful save. [OnboardingView.swift:537](Unit/Features/Onboarding/OnboardingView.swift:537)
- **Edge cases**:
  - Comma decimal in a weight box ("62,5" with a German or Turkish region) -> read as 62.5 (fixed 2026-10-23) -> Low -> yes.
  - Zero typed as a weight -> ignored -> Low -> yes.
  - Pound weights with a stray decimal ("155.0") -> fixed 2026-10-23 with the shared rounding -> Low -> yes.
  - Junk row from a paste -> can be renamed, not deleted. There is no way to add a row or rename a day here -> Med -> no. [OnboardingProgramPreviewView.swift:183](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:183)
  - Exercise name cleared in the sheet -> that row is not saved; a day can end up with no exercises -> Low -> partial. [OnboardingViewModel.swift:426](Unit/Features/Onboarding/OnboardingViewModel.swift:426)
  - Ready-made program weekdays -> dropped; every new program starts as a rotation -> Low -> yes.
  - Save fails (for example a full disk) -> "Save failed" alert. The unsaved rows stay in memory: unclear from code whether the app still moves on to the paywall, and a second try may save two copies -> Low -> partial. [OnboardingView.swift:545](Unit/Features/Onboarding/OnboardingView.swift:545), [OnboardingViewModel.swift:482](Unit/Features/Onboarding/OnboardingViewModel.swift:482)
  - App closed on Review -> rows and weights come back; paste warnings do not -> Low -> partial.
  - Double tap on "Save program" -> blocked -> Low -> yes. [OnboardingView.swift:518](Unit/Features/Onboarding/OnboardingView.swift:518)

## 8. Paywall

- **Purpose**: Hard gate after setup. Show the saved program as the reward, the plans and the timeline, then try, buy or restore.
- **Entry**: A program is saved and Apple says there is no active plan. There is no close button. [ContentView.swift:52](Unit/ContentView.swift:52)
- **Steps**:
  - Paywall opens -> plans and trial eligibility load from Apple; a spinner shows meanwhile. [PaywallView.swift:45](Unit/Features/Subscription/PaywallView.swift:45), [StoreManager.swift:683](Unit/Features/Subscription/StoreManager.swift:683)
  - Title -> "Try all of Unit free for 7 days" when the selected plan has an eligible trial, else "Unlock Unit". The line below follows the goal answer (or a neutral line for paste). [PaywallView.swift:379](Unit/Features/Subscription/PaywallView.swift:379)
  - Program card -> "Your program is ready", the program name (or "3-day program"), and "Get stronger · New · 3 days/week" or the day names. [PaywallView.swift:388](Unit/Features/Subscription/PaywallView.swift:388)
  - "Choose your plan" -> Weekly, Monthly and Yearly are always listed; Lifetime only when Apple returns it. All prices come from Apple. Only the selected card shows its detail line ("7 days free · then $4.99/month" or "Auto-renews monthly · $1.15/week"). Yearly carries "Save N%", compared with 52 weeks of Weekly ("Save 80%" at US prices). [PaywallView.swift:569](Unit/Features/Subscription/PaywallView.swift:569), [PaywallView.swift:598](Unit/Features/Subscription/PaywallView.swift:598), [PaywallView.swift:638](Unit/Features/Subscription/PaywallView.swift:638), [PaywallView.swift:687](Unit/Features/Subscription/PaywallView.swift:687)
  - Default plan:
    - Eligible for the free trial -> Yearly (founder decision 2026-10-23). A 50/50 Yearly-vs-Monthly test is built but off. [StoreManager.swift:739](Unit/Features/Subscription/StoreManager.swift:739), [StoreManager.swift:1118](Unit/Features/Subscription/StoreManager.swift:1118)
    - Not eligible -> Weekly. If Weekly did not load -> the first plan that did. [StoreManager.swift:1155](Unit/Features/Subscription/StoreManager.swift:1155)
    - A tap by the user always wins over a late eligibility answer.
    - Decision and how to read the test: decision log 2026-10-23 [decision-log.md:10](docs/decision-log.md:10) and docs/pricing.md.
  - Timeline -> trial: Day 0 (access now), Day 5 (reminder), Day 7 (renews at the price). Subscription: Today, Before renewal, Every week or month or year. Lifetime: Today, One payment. [PaywallView.swift:250](Unit/Features/Subscription/PaywallView.swift:250)
  - Reminder card (trial plans only) -> "Remind me 2 days before", on by default (2026-10-23). Turning it on does not ask for notification permission yet. [PaywallView.swift:341](Unit/Features/Subscription/PaywallView.swift:341)
  - "Everything included" (6 features) and the renewal text ("auto-renews unless cancelled", "manage or cancel in App Store settings"). [PaywallView.swift:725](Unit/Features/Subscription/PaywallView.swift:725)
  - Sticky button -> "Start free trial" (trial), "Subscribe for $4.99/month", or "Buy for $44.99". The line above it, for a trial: "$4.99/month after 7 days free. No charge today. Auto-renews unless cancelled." (changed 2026-10-23 so the billed price leads). [PaywallView.swift:518](Unit/Features/Subscription/PaywallView.swift:518)
  - Tap the button -> Apple purchase sheet -> one of:
    - Success -> access on, reminder choice saved, root swaps to the tabs. [StoreManager.swift:814](Unit/Features/Subscription/StoreManager.swift:814)
    - User closes Apple's sheet -> stays on the paywall, no message. [StoreManager.swift:847](Unit/Features/Subscription/StoreManager.swift:847)
    - Pending (Ask to Buy, bank check) -> button and Restore turn grey; the line says "Purchase pending approval." [StoreManager.swift:852](Unit/Features/Subscription/StoreManager.swift:852)
    - Error, or a purchase that fails Apple's signature check -> alert "Something went wrong" with "Purchase failed. Try again in a moment." [StoreManager.swift:863](Unit/Features/Subscription/StoreManager.swift:863)
  - Footer -> "Restore Purchases · Terms of Service · Privacy Policy", then "Support" (opens a mail to support@unitlift.app). Shown in every paywall state, including loading and load failure (2026-10-23). Terms = Apple's standard license. [PaywallView.swift:784](Unit/Features/Subscription/PaywallView.swift:784)
  - Restore -> Apple sync -> plan found: tabs open. None: alert "No purchases to restore." No network: "Couldn't reach the App Store. Check your connection and try again." User closes the Apple sign-in: nothing happens. [StoreManager.swift:873](Unit/Features/Subscription/StoreManager.swift:873)
- **Saved data**: Access cache `storeManager.lastKnownEntitlement`. Reminder choice `unit.trial-reminder.staged`, then `unit.trial-reminder.enabled`. Test group `paywall.defaultPlanArm.v1`. One local notification `unit.trial-reminder`. Nothing is stored on a server.
- **Events**: `paywall_viewed`, `trial_reminder_preference_changed`, `purchase_started`, `trial_started`, `purchase_completed`, `purchase_outcome`, `restore_outcome`, `trial_reminder_authorization`. Details in section 13.
- **Edge cases**:
  - Plans do not load (offline, App Store down) -> "Couldn't load subscriptions", "Try again", and the footer (Restore, Terms, Privacy, Support). The button "Subscribe to continue" stays grey -> Med -> yes (footer added 2026-10-23).
  - Plans still loading -> spinner only, with the same missing footer -> Med -> partial. [PaywallView.swift:148](Unit/Features/Subscription/PaywallView.swift:148)
  - Some plans missing -> that card says "Unavailable" and is disabled, plus "Some plans couldn't load." and "Try again" -> Low -> yes. [PaywallView.swift:111](Unit/Features/Subscription/PaywallView.swift:111)
  - Ask to Buy declined, or bank check abandoned -> the button stays grey with "Purchase pending approval. If it was declined, tap Restore Purchases." Restore stays active; a restore that finds nothing ends the wait (2026-10-23) -> Med -> partial.
  - Ask to Buy approved later -> access opens through the live purchase feed. No `trial_started` or `purchase_completed` event is sent -> Low -> partial. [StoreManager.swift:989](Unit/Features/Subscription/StoreManager.swift:989)
  - Purchases blocked on the phone (Screen Time, parent limits) -> likely an error from Apple; the app shows the same "Try again in a moment" message every time -> Med -> no.
  - Double tap on the button -> the second tap is ignored -> Low -> yes. [StoreManager.swift:771](Unit/Features/Subscription/StoreManager.swift:771)
  - Reminder on, then a plan without a trial is picked -> the reminder switches off -> Low -> yes. [PaywallView.swift:49](Unit/Features/Subscription/PaywallView.swift:49)
  - Reminder on, notification permission denied -> access still opens, no reminder is set, and the app shows no trial end date anywhere -> Med -> partial.
  - Billed price prominence -> fixed 2026-10-23: no "$0.00" on the button; the billed price leads the line above it and stays the plan card's price -> Low -> yes.
  - "Save N%" badge -> compares Yearly with 52 weeks of Weekly ("Save 80%" at US prices; founder decision 2026-10-23) -> Low -> yes.
  - Lapsed subscriber -> same "Your program is ready" copy. History, Settings and support sit behind the wall, and there is no export -> Med -> no.
  - Support on the paywall -> a "Support" mail link sits in the footer (2026-10-23) -> Low -> yes.
  - Lifetime not set up in App Store Connect -> its card is hidden -> Low -> yes.

## 9. Post-purchase handoff

- **Purpose**: Take a new payer from the paywall to the first workout.
- **Entry**: Access turns on (purchase, restore, Ask to Buy approval, or a plan found at launch).
- **Steps**:
  - Access on -> the root swaps at once to the tabs, with Today selected. [ContentView.swift:56](Unit/ContentView.swift:56), [StoreManager.swift:1013](Unit/Features/Subscription/StoreManager.swift:1013)
  - Trial with the reminder on -> the iOS notification permission alert appears over Today -> if allowed, one reminder is set for 48 hours before the trial ends. [StoreManager.swift:842](Unit/Features/Subscription/StoreManager.swift:842), [StoreManager.swift:111](Unit/Features/Subscription/StoreManager.swift:111)
  - Today -> new programs are rotations, so Today shows the next routine (on a new program, normally the first one) with its starting targets and a start button. [TodayView.swift:603](Unit/Features/Today/TodayView.swift:603)
- **Saved data**: Access cache = plan ID. The reminder choice becomes final.
- **Events**: `trial_started` and `purchase_completed` (purchases made on this paywall only), `trial_reminder_authorization`.
- **Edge cases**:
  - Programs saved before 2026-10-23 with fixed weekdays -> on a non-training day Today says "Rest day" with "Choose routine" -> Low -> partial. [TodayView.swift:637](Unit/Features/Today/TodayView.swift:637)
  - No welcome or "start your first workout" moment after paying -> Low -> no.
  - The success vibration on the paywall may not play, because the paywall is removed in the same moment -> Low -> unclear from code. [PaywallView.swift:57](Unit/Features/Subscription/PaywallView.swift:57)
  - The "Unit Pro active" view inside the paywall never shows in normal use, because the root swaps first -> Low -> n/a. [PaywallView.swift:163](Unit/Features/Subscription/PaywallView.swift:163)

## 10. Access refresh, expiry, refund, offline, paywall again

- **Purpose**: Keep access in line with Apple at all times.
- **Entry**: Every cold start, every message on the live purchase feed, every restore.
- **Steps**:
  - Cold start -> the cached answer opens the right screen at once -> Apple's list of active purchases is read -> access on (any active plan) or off. [StoreManager.swift:917](Unit/Features/Subscription/StoreManager.swift:917)
  - Live feed -> new purchase or renewal: access on. Refund, upgrade or expiry: read the full list again, then on or off. [StoreManager.swift:968](Unit/Features/Subscription/StoreManager.swift:968)
  - Access off -> cache set to "none", trial reminder cancelled, root swaps to the paywall. [StoreManager.swift:1022](Unit/Features/Subscription/StoreManager.swift:1022)
  - An old "no access" answer that started before a newer purchase is ignored, so a fresh buyer is not thrown back to the paywall. [StoreManager.swift:223](Unit/Features/Subscription/StoreManager.swift:223)
  - Apple lists a subscription as active only when it is "subscribed" or "in grace period" (Apple docs). A failed renewal in billing retry is not active.
- **Saved data**: `storeManager.lastKnownEntitlement`, reminder settings.
- **Events**: `trial_reminder_authorization` on every cold start of a paying user. No event when access is lost, refunded or renewed.
- **Edge cases**:
  - Plan ends while the app stays open in the background -> no check when the app comes back to the front; access lasts until the next cold start or the next feed message -> Low -> partial.
  - Refund while a workout is open -> the paywall replaces the workout screen at once. Logged sets are already saved -> Low -> partial.
  - Renewal payment fails -> access ends at once unless Billing Grace Period is on in App Store Connect. Not visible in code -> Med -> unclear.
  - Offline -> see section 1 -> Med -> partial.
  - Reinstall -> setup runs again (data lived on the phone). Apple's purchase is found, so there is no paywall at the end -> Low -> yes.
  - New phone with the same Apple Account -> same as reinstall. Workout history does not move (no sync, no export) -> Med -> no.
  - Purchase with a broken signature -> ignored and logged -> Low -> yes.

## 11. Settings

- **Purpose**: Weight unit, analytics opt-out, plan status, restore, manage plan, feedback and legal links.
- **Entry**: Programs tab -> gear button (top right) -> sheet. Only reachable with an active plan. [TemplatesView.swift:83](Unit/Features/Templates/TemplatesView.swift:83), [TemplatesView.swift:109](Unit/Features/Templates/TemplatesView.swift:109)
- **Steps**:
  - Preferences -> "Weight unit" kg or lb (changes the display only; weights are stored in kg). "Anonymous analytics" switch, off by default (opt-in, 2026-10-24); off stops all events. The same switch is on setup step 1, and on the paywall while it is on. [SettingsView.swift:211](Unit/Features/Settings/SettingsView.swift:211), [UnitAnalytics.swift:339](Unit/Analytics/UnitAnalytics.swift:339)
  - Data -> "Storage: On this iPhone", "Account: None". The "Export data" row is hidden by an old v1 filter. There is no export anywhere in the app. [SettingsView.swift:187](Unit/Features/Settings/SettingsView.swift:187)
  - Subscription -> "Unit Pro" status ("Monthly active" and so on), "Restore Purchases", "Manage Subscription" (Apple's own sheet; hidden for Lifetime). [SettingsView.swift:240](Unit/Features/Settings/SettingsView.swift:240), [SettingsView.swift:282](Unit/Features/Settings/SettingsView.swift:282)
  - Feedback -> "Request a feature" opens unitlift.featurebase.app. [SettingsView.swift:336](Unit/Features/Settings/SettingsView.swift:336)
  - Legal -> Privacy Policy, Terms of Service, "Contact me" (an email with the app version and iOS version filled in). [SettingsView.swift:302](Unit/Features/Settings/SettingsView.swift:302), [SettingsView.swift:64](Unit/Features/Settings/SettingsView.swift:64)
  - Footer -> "Made with (heart emoji) in my room" and support@unitlift.app.
- **Saved data**: `unitSystem`, `analytics.enabled` (Settings storage).
- **Events**: `feedback_action` (portal). `restore_outcome` on restore.
- **Edge cases**:
  - Restore while the plan is active -> spinner, then nothing. The "Purchases restored" alert only shows when access was off before, which cannot happen on this screen -> Low -> partial. [SettingsView.swift:350](Unit/Features/Settings/SettingsView.swift:350)
  - Restore finds nothing -> access is removed, the root swaps to the paywall, and the paywall shows "No purchases to restore." -> Low -> yes.
  - Trial user -> status says "Monthly active". No trial end date and no next charge date -> Med -> no. [SettingsView.swift:358](Unit/Features/Settings/SettingsView.swift:358)
  - Lapsed user -> cannot open Settings at all (behind the paywall) -> Med -> no.
  - Analytics off -> no events at all, including purchases. No event about the opt-out itself -> Low -> yes.
  - docs/pricing.md still lists the removed unit and weekday steps [pricing.md:42](docs/pricing.md:42) and "export, theming" in Settings [pricing.md:52](docs/pricing.md:52). None of these exist now -> Low -> no.

## 12. Review prompt and feedback prompt

- **Purpose**: Ask for an App Store rating after workout 1 and invite feedback after workout 3.
- **Entry**: Finishing workouts.
- **Steps**:
  - Each finished workout -> its ID is counted, up to 3. [ActiveWorkoutView.swift:1054](Unit/Features/Today/ActiveWorkoutView.swift:1054), [EngagementPromptTracker.swift:44](Unit/UI/EngagementPromptTracker.swift:44)
  - After workout 1 -> when the summary closes, or later when Unit comes to the front on Today with no open workout -> wait 2 seconds -> Apple's rating request. Apple decides if it shows. Asked once. [TodayView.swift:482](Unit/Features/Today/TodayView.swift:482), [TodayView.swift:506](Unit/Features/Today/TodayView.swift:506)
  - Workout 3 summary -> "Help improve Unit" card at the bottom with "Book a 15-minute call", "Email feedback" and "No thanks". Shown once. [SessionDetailView.swift:759](Unit/Features/History/SessionDetailView.swift:759)
- **Saved data**: `engagement.v2_1.completedSessionIDs`, `engagement.v2_1.reviewRequestAttempted`, `engagement.v2_1.feedbackPromptShown`.
- **Events**: `feedback_action` (book, email, dismiss). No event when the rating request is made or when the card is shown.
- **Edge cases**:
  - Keys are fixed to "v2_1" in code -> both prompts happen once per install until someone changes the key by hand -> Low -> partial. [EngagementPromptTracker.swift:16](Unit/UI/EngagementPromptTracker.swift:16)
  - The card counts as "shown" even if the user never scrolls down to it -> Low -> no.
  - Yesterday's open workout saved with "Mark complete" -> also counts -> Low -> yes. [TodayView.swift:457](Unit/Features/Today/TodayView.swift:457)
  - Rating request during logging -> blocked (needs no open workout and a closed summary) -> Low -> yes.

## 13. Analytics

- **Purpose**: Anonymous funnel counts through TelemetryDeck. No names, exercises, weights, notes or receipts are sent.
- **Entry**: Set up at app start when "Anonymous analytics" is on (off by default since 2026-10-24: opt-in) and the app has a valid TelemetryDeck ID. [UnitApp.swift:41](Unit/UnitApp.swift:41), [UnitAnalytics.swift:328](Unit/Analytics/UnitAnalytics.swift:328)
- **Rules**:
  - Only names on an allow list are sent. [UnitAnalytics.swift:163](Unit/Analytics/UnitAnalytics.swift:163)
  - Five money events also get `default_plan` (monthly or annual) when this install is in the plan test: `paywall_viewed`, `purchase_started`, `purchase_outcome`, `trial_started`, `purchase_completed`. [UnitAnalytics.swift:351](Unit/Analytics/UnitAnalytics.swift:351)
  - TelemetryDeck's own session-start signal is on since commit 94be704 (one per app session). [UnitAnalytics.swift:17](Unit/Analytics/UnitAnalytics.swift:17)
  - Analytics off in Settings -> nothing is sent. [UnitAnalytics.swift:356](Unit/Analytics/UnitAnalytics.swift:356)

**Every event**

| Event | Properties | Fires when | Where |
|---|---|---|---|
| TelemetryDeck session start | TelemetryDeck defaults | Each app session | [UnitAnalytics.swift:17](Unit/Analytics/UnitAnalytics.swift:17) |
| `onboarding_started` | none | Setup appears; again on every cold start until setup is saved | [OnboardingView.swift:341](Unit/Features/Onboarding/OnboardingView.swift:341) |
| `onboarding_slide_viewed` | `slide`: next_target, double_progression, one_tap_logging | First time each carousel slide shows in a visit | [OnboardingView.swift:377](Unit/Features/Onboarding/OnboardingView.swift:377), [OnboardingSplashView.swift:147](Unit/Features/Onboarding/OnboardingSplashView.swift:147) |
| `onboarding_step_viewed` | `step`: method, paste, library, review (the unit and schedule values are never sent now) | Each forward move to a setup step; Back does not send it. Wired in commit 499ecaf | [OnboardingView.swift:494](Unit/Features/Onboarding/OnboardingView.swift:494) |
| `weight_unit_selected` | `unit`: kg, lb | Each use of the Review unit switch | [OnboardingProgramPreviewView.swift:143](Unit/Features/Onboarding/OnboardingProgramPreviewView.swift:143) |
| `program_source_selected` | `source`: paste, library | Every tap on a path card | [OnboardingView.swift:412](Unit/Features/Onboarding/OnboardingView.swift:412) |
| `program_match_selected` | `goal`, `experience`, `days`, `rank` (1 to 3, else "unknown") | Every tap on a program card | [OnboardingLibraryPickerView.swift:333](Unit/Features/Onboarding/OnboardingLibraryPickerView.swift:333) |
| `program_setup_completed` | `source`: paste, library | Program saved | [OnboardingView.swift:537](Unit/Features/Onboarding/OnboardingView.swift:537) |
| `paywall_viewed` | `trial_eligibility`: eligible, ineligible, unknown; `default_plan` | Once per paywall screen, after plans finish loading | [PaywallView.swift:515](Unit/Features/Subscription/PaywallView.swift:515) |
| `trial_reminder_preference_changed` | `is_enabled` | Every flip of the reminder switch | [PaywallView.swift:373](Unit/Features/Subscription/PaywallView.swift:373) |
| `trial_reminder_authorization` | `outcome`: scheduled, denied, not_authorized, invalid_expiration, failed, cancelled | After a purchase, after a feed message, and on every cold start of a paying user | [StoreManager.swift:1069](Unit/Features/Subscription/StoreManager.swift:1069), [StoreManager.swift:1073](Unit/Features/Subscription/StoreManager.swift:1073) |
| `purchase_started` | `tier`, `has_trial`, `reminder_requested`, `default_plan` | Buy button accepted | [StoreManager.swift:776](Unit/Features/Subscription/StoreManager.swift:776) |
| `trial_started` | `tier`, `program_source`, `goal`, `experience`, `days`, `default_plan` | Purchase on this paywall succeeded and it is a free trial | [StoreManager.swift:825](Unit/Features/Subscription/StoreManager.swift:825) |
| `purchase_completed` | same as `trial_started` | Every purchase on this paywall that succeeded, trials included | [StoreManager.swift:834](Unit/Features/Subscription/StoreManager.swift:834) |
| `purchase_outcome` | `tier`, `outcome`: cancelled, pending, failed; `default_plan` | Apple sheet closed, purchase pending, or error | [StoreManager.swift:850](Unit/Features/Subscription/StoreManager.swift:850), [StoreManager.swift:855](Unit/Features/Subscription/StoreManager.swift:855), [StoreManager.swift:865](Unit/Features/Subscription/StoreManager.swift:865) |
| `restore_outcome` | `outcome`: restored, nothing_found, failed | Restore finished (paywall or Settings) | [StoreManager.swift:896](Unit/Features/Subscription/StoreManager.swift:896), [StoreManager.swift:906](Unit/Features/Subscription/StoreManager.swift:906) |
| `workout_started` | none | Workout screen appears (also when a workout is resumed) | [ActiveWorkoutView.swift:998](Unit/Features/Today/ActiveWorkoutView.swift:998) |
| `workout_completed` | `duration`, `set_count`, `no_keyboard_ratio` (all in ranges) | Finish | [ActiveWorkoutView.swift:1045](Unit/Features/Today/ActiveWorkoutView.swift:1045) |
| `progression_preview_shown` | `outcome` | An exercise is done and its next target shows, once per exercise | [ActiveWorkoutView.swift:872](Unit/Features/Today/ActiveWorkoutView.swift:872) |
| `progression_recommendation_shown` | `outcome`: add_weight, add_rep, repeat, unsupported | Workout summary opens, once per outcome | [SessionDetailView.swift:781](Unit/Features/History/SessionDetailView.swift:781) |
| `progression_decision` | `action`: accept, repeat, edit (a `dismiss` value exists but is never sent); `outcome` | Next target accepted, repeated or edited | [SessionDetailView.swift:521](Unit/Features/History/SessionDetailView.swift:521) |
| `feedback_action` | `action`: book, email, dismiss, portal | Feedback card buttons and "Request a feature" | [SessionDetailView.swift:724](Unit/Features/History/SessionDetailView.swift:724), [SettingsView.swift:342](Unit/Features/Settings/SettingsView.swift:342) |

**Funnel gaps** (install -> setup done -> paywall -> trial or purchase -> first workout -> week 1)

- Install: no once-only first-open event. `onboarding_started` repeats on every cold start until setup is saved, so it counts launches, not people.
- Setup: no event for a paste attempt, a paste failure, or what the parser dropped. This is the most likely place the paste path fails.
- Setup: picks from "See N more programs" send rank "unknown".
- Setup: no event when saving fails.
- Paywall: no event when plans fail to load. `paywall_viewed` waits for the load, so people who leave during a slow load are not counted.
- Paywall: no event when a plan card is tapped.
- Purchase: `trial_started` and `purchase_completed` fire only for purchases made on this paywall. Ask to Buy approvals and purchases that arrive through the live feed are not counted.
- Purchase: trial-to-paid conversion, renewals, cancellations and refunds are not visible in app analytics. They need App Store Connect reports or App Store Server Notifications.
- Purchase: `purchase_completed` includes trials. Paid starts = `purchase_completed` minus `trial_started`.
- Purchase: `trial_reminder_authorization` repeats on every cold start, so its counts are not opt-ins. Use `trial_reminder_preference_changed` and `purchase_started.reminder_requested` instead.
- First workout: `workout_started` also fires on resume, and `workout_completed` has no "first workout" marker, so time to first workout needs extra work.
- Week 1: depends on the new session-start signal. People who turn analytics off are invisible (by design).

## Sources for the Apple rules in this doc

- App Store Review Guidelines 3.1.1 and 3.1.2 (restore for restorable purchases; describe what the user gets for the price; free trials allowed): https://developer.apple.com/app-store/review/guidelines/#in-app-purchase
- Apple, Auto-renewable subscriptions ("the amount that will be billed must be the most prominent pricing element"; sign-up screen needs the full renewal price and a way to restore; Terms and Privacy links in the app): https://developer.apple.com/app-store/subscriptions/
- Apple docs, `Transaction.currentEntitlements` (active = subscribed or in grace period; refunded purchases are left out): https://developer.apple.com/documentation/storekit/transaction/currententitlements
