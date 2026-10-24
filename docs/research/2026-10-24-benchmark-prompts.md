# Benchmark prompts for the Grok bot, 2026-10-24

- 5 prompts, one per main flow of Unit 2.1. Each asks the bot where Unit is weaker than similar apps.
- Every prompt asks for the same answer: a ranked table of downsides, what Unit does better, and the top 3 changes.
- Unit is described as in the PR #5 build: paywall headline "$29.99/year after 7 days free", badge "Save 80% vs weekly", and an "Anonymous analytics" switch on setup step 1 and on the paywall.
- Facts come from [first-run-and-paywall.md](../flows/first-run-and-paywall.md), [training-loop.md](../flows/training-loop.md) and the build-95 screenshots.

## How to use

1. Open a new bot chat for each flow.
2. Copy the whole block for that flow and paste it.
3. Attach the files listed for that flow, plus the phone captures.
4. If a table row has no evidence, reply: "Redo the table. Every row needs what the competitor's screen shows and a source."

| # | Flow | Attach from `docs/app-store-assets/2.1/source/` | Capture on a phone |
|---|---|---|---|
| 1 | First-run setup | `04-program-setup.png` | "Paste program" with a program pasted, "Programs for you", "Review program" |
| 2 | Paywall | none | The paywall, top half and bottom half |
| 3 | Active workout logging | `02-one-tap.png`, `06-lock-screen-timer.png` | A set row with the number pad open |
| 4 | Exercise done and summary | `07-exercise-done.png`, `01-next-target.png`, `03-double-progression.png` | none |
| 5 | History and Analytics | `05-progress-history.png` | Analytics tab, History list, one past workout |

- Setup shows only when no program is saved. The paywall shows only without an active plan. Capture both on a spare phone or the Simulator.
- Do not delete Unit on your training phone to reach these screens. Deleting it erases your workouts on that phone.

## 1. First-run setup

Attach: `04-program-setup.png`, plus captures of "Paste program", "Programs for you" and "Review program".

```text
Benchmark one flow of my iOS app, Unit, against similar apps. Flow: first-run setup, from first launch to a saved program. Goal: find where Unit is weaker.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Core loop: last time's weight and reps are already in the set row, one tap logs the set, and a rest timer starts by itself and shows on the Lock Screen. When an exercise is done, Unit suggests the next target (double progression: add reps up to the top of a range, then add weight). The lifter saves it on the post-workout summary. Unit never changes the routine on its own.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone: no account, no sign-up, no cloud sync, no export yet. No Apple Watch app. No Apple Health.
- Money: hard paywall right after setup. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99 one-time. Monthly and Yearly have a 7-day free trial. Yearly is preselected for people who can get the trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt and the attached screenshots as the truth for Unit.

THIS FLOW
- Who: someone who just installed Unit. Some bring a program from a coach, a forum, a PDF or their Notes app. Some need one.
- Job: get a program into the app and reach the first workout with the fewest taps and no wrong data.

ATTACHED
- Step 1, "Choose your path". It is one build older and does not show the analytics switch.
- If attached: "Paste program", "Programs for you" and "Review program".

WHAT THE USER SEES (exact labels in quotes)
1. Opener: black screen, logo, "Welcome to Unit", "Progressive overload made simple." It lasts 2 seconds. A tap cannot skip it.
2. Carousel: 3 slides that move by themselves: "Know what to lift next", "Build reps, then weight", "Log every set in one tap". Button: "Set up your program".
3. Step 1 of 3, "Choose your path": "I have a program" (Paste it from Notes, WhatsApp or anywhere else.) or "I need a program" (Answer three questions to match ready-made programs.). The first tap moves on. Under the cards: an "Anonymous analytics" switch, on by default ("Anonymous usage data. Turn off anytime.").
4. Paste path, step 2 of 3, "Paste program": a text box and "Read program". "Show format examples" opens 3 short rules. Unit reads the text on the phone. It finds day headings (Push, Day 1, Monday, a "#" line) and exercise lines with sets x reps and an optional weight ("Bench 3x8 60"). A rep range ("3x8-10") turns on next-target suggestions for that exercise. Cardio lines are skipped. At most 6 days. If nothing is found: alert "Couldn't read that program" with "Show examples" or "Keep editing".
5. Ready-made path, step 2 of 3, three questions: goal ("Get stronger", "Build muscle", "Strength + muscle"), experience ("New", "Consistent", "Experienced"), training days (2 to 6, 3 preselected, then "Continue"). Then "Programs for you": the top 3 of 27 catalog programs. Number 1 has a "Best match" badge and is preselected. Each card shows goal, experience, days and a reason line. "See N more programs" shows the rest for that day count.
6. Step 3 of 3, "Review program": a "Weight unit" kg/lb switch (guessed from the phone region), a box for paste problems, one card per day, one row per exercise (sets x rep range and weight step, or sets x reps and "Tracking only"), and an optional weight box per row. Tap a row to rename it or change sets (1 to 10) and reps (1 to 30). "Save program" saves and opens the paywall.
- Taps from first launch to the paywall: ready-made 8 taps on 7 screens. Paste 6 to 7 taps on 4 screens, 2 to 3 of them the iOS paste gesture. Plus the 2-second opener.

WHAT UNIT DOES NOT DO IN SETUP TODAY
- No import of past workouts from Hevy, Strong or a CSV. Programs only, and only by paste.
- No photo, PDF, spreadsheet or link import.
- Setup does not say a paid plan is needed. The paywall comes right after "Save program".
- Paste: "RPE 8" before a number is read as 8 kg. "Rest 90s between sets" becomes an exercise. Lines without sets x reps are dropped, and Review only says "N lines didn't parse." without naming them. "@ 75% 1RM" leaves "1RM" in the exercise name.
- Review: a wrong row can be renamed but not deleted. No adding a row, no renaming a day.
- Ready-made programs start with empty weights. The first workout asks for each weight.
- Every new program is a rotation (the next routine in order). Weekdays can be set later in the Programs tab.

COMPARE WITH
- Hevy, Strong, Boostcamp, Fitbod, JEFIT, Alpha Progression, Liftosaur.
- Any gym app that imports a program from pasted text, a photo, a PDF or a spreadsheet.

FOCUS ON
- Time and taps from install to the first logged set.
- Getting an existing program in: paste, photo, PDF, spreadsheet, link, or a program library.
- How each app picks a program for a beginner and explains the pick.
- Starting weights for the first workout.
- What happens when an import is wrong, and how the user fixes it.
- When each app first says it costs money.

NOT A DOWNSIDE (Unit skips these on purpose, do not rank them)
- AI-generated or adaptive programs. Unit matches ready-made programs. It never generates them.

ANSWER FORMAT (use exactly this, nothing before it)
1. Downsides, worst first, 5 to 10 rows:
| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
- Severity: High = loses a sale, a set, data or trust for many users. Med = slows or confuses users often. Low = rare or cosmetic.
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
- Fix: name the screen, the element and the change. One fix per row.
2. What Unit does better: up to 5 bullets. Each names the competitor it beats and how.
3. Top 3 changes: the 3 fixes to ship first, one line each, with the reason.

RULES
- Evidence only. Each row says what the competitor's screen or flow shows: screen name, button label, tap count or default value.
- Source: where you saw it (App Store screenshots, help center, YouTube walkthrough, Reddit thread) and its date. If you cannot verify it, write "unverified" and rank the row lower.
- No generic advice. Never write "improve onboarding", "add gamification", "make it more intuitive" or similar. If you cannot name the element to change, drop the row.
- Fixes must fit Unit: fast, one hand, few words. Prefer a smaller change over a new screen.
- Compare the same moment in each app.
- Only list a competitor where it is better. Do not pad.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```

## 2. Paywall

Attach: no file fits yet. Capture the paywall on a phone, top half and bottom half.

```text
Benchmark one screen of my iOS app, Unit, against similar apps. Screen: the paywall. Goal: find where Unit is weaker at turning a new user into a trial or a purchase, and at keeping their trust.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Core loop: last time's weight and reps are already in the set row, one tap logs the set, and a rest timer starts by itself and shows on the Lock Screen. When an exercise is done, Unit suggests the next target (double progression: add reps up to the top of a range, then add weight). The lifter saves it on the post-workout summary. Unit never changes the routine on its own.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone: no account, no sign-up, no cloud sync, no export yet. No Apple Watch app. No Apple Health.
- Money: hard paywall right after setup. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99 one-time. Monthly and Yearly have a 7-day free trial. Yearly is preselected for people who can get the trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt and the attached screenshots as the truth for Unit.

THIS SCREEN
- When: right after the user saves a program in setup, 1 to 3 minutes after install. Nothing is logged yet. The user has seen their program on a review screen, not the workout screen.
- No close button. Without a plan, nothing else in the app opens.
- Who: a new user who picked or pasted a program a minute ago. Many come from free apps or a Notes app.

ATTACHED
- The paywall, top half and bottom half. If no screenshot is attached, work from the text below.

WHAT IS ON SCREEN, TOP TO BOTTOM (one scrolling page, exact labels in quotes)
1. Headline when the selected plan has a free trial: "$29.99/year after 7 days free". Without a trial: "Unlock Unit".
2. One line that follows the setup goal, for example "Build strength with a program chosen for your goal and schedule." Paste users see "Turn your program into steady progress, one workout at a time."
3. Program card: a check icon, "Your program is ready", the program name (or "3-day program"), and "Get stronger · New · 3 days/week" or the day names.
4. "Choose your plan", 4 cards: Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99. Only the selected card shows its detail line, for example "7 days free · then $29.99/year" or "Auto-renews monthly · $1.15/week". Yearly carries the badge "Save 80% vs weekly" (Yearly vs 52 weeks of Weekly).
5. Default plan: Yearly for people who can get the trial. Weekly for people who cannot.
6. "How your free trial works": "Day 0" Full Unit access starts immediately. "Day 5" Unit reminds you two days before your trial ends. "Day 7" Renews at $29.99/year unless cancelled. Then "Keep getting stronger": Your program, history, and next targets stay ready.
7. Reminder card: "Remind me 2 days before", switch on by default. "Optional. Notification permission is requested after purchase."
8. "Everything included": Next-workout targets, One-tap set logging, Last-time values, Ready-made programs, Progress history, Lock Screen rest timer.
9. Renewal text: "After the free trial, the subscription auto-renews unless cancelled. Payment is charged to your Apple Account. You can manage or cancel in App Store settings."
10. Footer: "Anonymous analytics" switch (on by default), "Restore Purchases · Terms of Service · Privacy Policy", "Support".
11. Sticky button: "Start free trial". Line above it: "$29.99/year after 7 days free. No charge today. Auto-renews unless cancelled." Without a trial the button says "Subscribe for $2.99/week" (or the selected plan's price), or "Buy for $44.99".

AFTER THE TAP
- Apple's purchase sheet. On success the app opens on Today with the first workout ready to start. With the reminder on, iOS then asks for notification permission.
- If the user closes Apple's sheet: back on the paywall, no message.
- After purchase, the trial end date and the next charge date are not shown anywhere in the app.

WHAT UNIT DOES NOT DO HERE TODAY
- No free look at the workout screen before paying. The trial is the only way in.
- No ratings, reviews or user counts on the paywall.
- No "maybe later", no limited free mode.
- No exit offer, discount or win-back offer.
- A lapsed subscriber sees the same paywall and cannot open History, Settings or their data. No export.

COMPARE WITH
- Gym and fitness apps: Fitbod, Alpha Progression, MacroFactor, Ladder, Hevy (Pro), Strong (PRO), Boostcamp (Pro).
- Strong paywalls from other subscription apps, where they fit a hard paywall after onboarding: Opal, Headspace, Blinkist, Napper.

FOCUS ON
- Price clarity: is the billed price the most prominent price (Apple App Review Guideline 3.1.2)?
- Plan lineup and default: how many plans, which one is preselected, badge wording, weekly and lifetime plans.
- Trust: trial timeline, reminder, cancel wording, reviews, refund worries.
- What the user sees of the product before paying: sample workout, demo, video, screenshots.
- What happens when the user does not buy.
- Anything that could get this paywall rejected by App Review.

DECIDED, NOT A ROW
- The hard paywall itself (no free tier) is decided. Judge everything else inside that model. If you think the hard gate is the biggest risk, say so once, in one line under the table.

ANSWER FORMAT (use exactly this, nothing before it)
1. Downsides, worst first, 5 to 10 rows:
| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
- Severity: High = loses a sale, a set, data or trust for many users. Med = slows or confuses users often. Low = rare or cosmetic.
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
- Fix: name the screen, the element and the change. One fix per row.
2. What Unit does better: up to 5 bullets. Each names the competitor it beats and how.
3. Top 3 changes: the 3 fixes to ship first, one line each, with the reason.

RULES
- Evidence only. Each row says what the competitor's screen or flow shows: screen name, button label, tap count or default value.
- Source: where you saw it (App Store screenshots, help center, YouTube walkthrough, Reddit thread) and its date. If you cannot verify it, write "unverified" and rank the row lower.
- No generic advice. Never write "improve onboarding", "add gamification", "make it more intuitive" or similar. If you cannot name the element to change, drop the row.
- Fixes must fit Unit: fast, one hand, few words. Prefer a smaller change over a new screen.
- Compare the same moment in each app.
- Only list a competitor where it is better. Do not pad.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```

## 3. Active workout logging

Attach: `02-one-tap.png`, `06-lock-screen-timer.png`, plus a capture of a set row with the number pad open.

```text
Benchmark one flow of my iOS app, Unit, against similar apps. Flow: logging a workout, from opening the app to the last set, with the rest timer and the Lock Screen. Goal: find where Unit is weaker.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Core loop: last time's weight and reps are already in the set row, one tap logs the set, and a rest timer starts by itself and shows on the Lock Screen. When an exercise is done, Unit suggests the next target (double progression: add reps up to the top of a range, then add weight). The lifter saves it on the post-workout summary. Unit never changes the routine on its own.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone: no account, no sign-up, no cloud sync, no export yet. No Apple Watch app. No Apple Health.
- Money: hard paywall right after setup. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99 one-time. Monthly and Yearly have a 7-day free trial. Yearly is preselected for people who can get the trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt and the attached screenshots as the truth for Unit.

THIS FLOW
- Who: a lifter mid-workout. Tired, sweaty, one hand, often with the phone locked between sets.
- Job: log each set in 3 seconds or less without typing, and get called back when rest ends.

ATTACHED
- 02-one-tap.png: the workout screen with set 1 ready. The rest bar is idle, so its buttons are grey.
- 06-lock-screen-timer.png: the rest timer on the Lock Screen.
- If attached: a set row with the number pad open.

WHAT THE USER SEES (exact labels in quotes; the screenshots use lb, the app also does kg)
1. Today tab: "Up next", the routine name, one row per exercise with its target, and a sticky "Start workout". One tap starts the workout.
2. Workout screen: top bar with X (cancel), the routine name and a running clock, and "Finish" after the first logged set. Exercise cards in routine order. The current exercise is open. The others are closed cards ("Barbell Row", "3 × 95 lb × 8").
3. Current set row: "Set 1", source text on the right ("Last time 135 × 10"), two large fields (weight and reps), and a blue "Complete set 1". Planned sets below in grey ("2  140 lb × 8"). "+ Add set" under them.
4. What fills the current row, first match wins: numbers typed in this workout; the set just logged (set 2 copies set 1); the saved next target; the last set of the last workout with this exercise, from any routine; the program's starting target; else empty.
5. Log a set: one tap on "Complete set N". Success haptic, "Undo" for 5 seconds, rest starts, the next set becomes current. From app open to the first logged set: 2 taps.
6. Change a number: tap weight or reps. The number pad opens with a bar: "-2.5" and "+2.5" (5 for lb, 1 for reps), a "Reps"/"Weight" switch, "Done", and a pinned "Complete set N" that saves the number and logs the set in one tap.
7. First time on an exercise with no weight: the row says "No starting target yet". Type weight and reps, tap "Save target", then "Complete set 1". 3 to 4 taps plus typing.
8. Fix a logged set: tap it, then "Edit". Remove it: "Mark not done", with Undo for 4 seconds.
9. Exercise "..." menu: "Bodyweight" switch and "Skip exercise". Reorder: long-press a card and drag (no handle). Tap a closed card to jump to it.
10. Rest bar at the bottom: starts by itself after each set, 2:00 by default. A blue progress line, "Rest", the countdown, and "-30", "+30", "Skip". "+30" or "-30" also changes every later rest. When rest ends with the app open: "Rest finished.", a haptic, and an iOS banner with sound.
11. Lock Screen and Dynamic Island: a Live Activity with "Rest timer", the countdown and "Up next" with the next exercise. When rest ends in the background: a time-sensitive notification "Rest finished / Next: Bench Press · Set 2". The first rest ever asks for notification permission in the middle of the workout.
12. Finish: "Finish" -> "Finish workout? Saves and ends your session." If numbers were typed during the workout: "Update routine with today's weights?" (Update, Keep routine, Cancel). Then confetti, a haptic and the workout summary.

WHAT UNIT DOES NOT HAVE IN LOGGING TODAY
- No buttons on the Lock Screen or Dynamic Island: no Complete set, no +30, no Skip.
- No Apple Watch app.
- No swap or add exercise in a routine workout (only in a freestyle session).
- No warm-up sets. Every set is a working set.
- No note, RPE or RIR on a set.
- No supersets or circuits.
- One rest length for all exercises. No rest setting in Settings.
- No PR alert during the workout. PRs show in History only.
- An extra row from "+ Add set" cannot be removed.
- With no saved target, set 1 starts from the last set of the last workout, often the weakest set.

COMPARE WITH
- Strong, Hevy, Liftin', Alpha Progression, Boostcamp, JEFIT, Fitbod.

FOCUS ON
- Taps and seconds per set when the numbers are right, and when one number must change.
- How each app fills the next set: previous values, last session, target.
- Logging without opening the app: Lock Screen, Dynamic Island, Apple Watch, widgets.
- Rest timer: auto start, per-exercise rest, controls, alerts.
- Changing the plan mid-workout: swap, add, skip, reorder, supersets, warm-ups.
- One-hand reach and tap target size on a large iPhone.

NOT A DOWNSIDE (Unit skips these on purpose, do not rank them)
- Social feed or sharing, dark mode, plate calculator, target-vs-actual columns while logging, form videos, exercise recommendations, AI-generated workouts.

ANSWER FORMAT (use exactly this, nothing before it)
1. Downsides, worst first, 5 to 10 rows:
| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
- Severity: High = loses a sale, a set, data or trust for many users. Med = slows or confuses users often. Low = rare or cosmetic.
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
- Fix: name the screen, the element and the change. One fix per row.
2. What Unit does better: up to 5 bullets. Each names the competitor it beats and how.
3. Top 3 changes: the 3 fixes to ship first, one line each, with the reason.

RULES
- Evidence only. Each row says what the competitor's screen or flow shows: screen name, button label, tap count or default value.
- Source: where you saw it (App Store screenshots, help center, YouTube walkthrough, Reddit thread) and its date. If you cannot verify it, write "unverified" and rank the row lower.
- No generic advice. Never write "improve onboarding", "add gamification", "make it more intuitive" or similar. If you cannot name the element to change, drop the row.
- Fixes must fit Unit: fast, one hand, few words. Prefer a smaller change over a new screen.
- Compare the same moment in each app.
- Only list a competitor where it is better. Do not pad.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```

## 4. Exercise done and post-workout summary

Attach: `07-exercise-done.png`, `01-next-target.png`, `03-double-progression.png`.

```text
Benchmark one flow of my iOS app, Unit, against similar apps. Flow: the end of an exercise and the end of a workout, where Unit suggests the next target and the lifter saves it. Goal: find where Unit is weaker.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Core loop: last time's weight and reps are already in the set row, one tap logs the set, and a rest timer starts by itself and shows on the Lock Screen. When an exercise is done, Unit suggests the next target (double progression: add reps up to the top of a range, then add weight). The lifter saves it on the post-workout summary. Unit never changes the routine on its own.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone: no account, no sign-up, no cloud sync, no export yet. No Apple Watch app. No Apple Health.
- Money: hard paywall right after setup. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99 one-time. Monthly and Yearly have a 7-day free trial. Yearly is preselected for people who can get the trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt and the attached screenshots as the truth for Unit.

THIS FLOW
- Who: a lifter finishing an exercise mid-workout, then finishing the workout. Tired, wants to leave the gym.
- Job: know what to lift next time, trust why, and save it with the fewest taps.

ATTACHED
- 07-exercise-done.png: all 4 exercises done, each with its suggestion line, and "Finish workout".
- 01-next-target.png: the summary before saving.
- 03-double-progression.png: the summary after saving Bench Press.

HOW UNIT PICKS THE NEXT TARGET
- Only for exercises with progression on: "Increase reps, then weight" switched on in the exercise's target sheet, a rep range in a pasted program ("3x8-10"), or a ready-made program (start at the program's reps, build up 2 reps, then add 2.5 kg, 2 kg for dumbbells, or 5 lb).
- Double progression, checked at the end of each exercise:
  - Every set at the top of the range: add one weight step, reps back to the bottom. Reason: "Every set reached the top."
  - All sets on target but not at the top: same weight, one more rep. Reason: "Same weight. Add one rep."
  - Any set below the target reps: same target. Reason: "Keep this target."
  - No suggestion when sets used different weights ("Weights varied."), sets are unfinished, a bodyweight lift has no added weight, or a set has 0 weight or 0 reps.

WHAT THE USER SEES (exact labels in quotes; the screenshots use lb)
1. Exercise done: the last "Complete set 3" tap gives the same haptic as any set. The card closes to: name, "3 × 135 lb × 10" (or "3 sets" when sets differ), a check, and "Undo" for 5 seconds.
2. One line under it with a chart icon: "Suggested next: 140 lb × 8 · +5 lb", or "· +1 rep", or "· same target". Read-only. With no suggestion, a grey line gives the reason: "No suggestion · Weights varied." No line at all when progression is off.
3. The next exercise opens by itself and rest starts. After the last exercise, the rest bar becomes a full-width "Finish workout".
4. Summary: opens after "Finish workout" and confetti. Routine name and date, then "Next time" first.
5. One block per exercise: status ("Suggested"), name and "Edit", rows "Previous target", "Logged", "Suggested target", the reason line, a blue "Save for next workout" and a text button "Repeat previous target".
6. "Save for next workout": status turns "Saved", the row label turns "Next target", toast "Next targets saved", haptic. One tap per exercise. There is no "save all".
7. "Edit": sheet "Edit next target" with weight and reps, then "Save changes".
8. Below "Next time": exercise cards with PR tags. On the 3rd workout, a feedback card.
9. Back arrow without saving: nothing changes, and the next workout fills from last time.
10. A saved target fills set 1 next time, shows on Today ("3 × 9 at 60 kg") and in Analytics ("Next 140 lb × 8").

WHAT UNIT DOES NOT DO HERE TODAY
- A suggestion that is not saved shows nowhere else, except in that workout in History. After the next workout of that routine it can no longer be saved.
- Suggestions are not on Today and not in the next workout until saved.
- A stall gets "Keep this target." every time, with no other help.
- No suggestion for bodyweight-only lifts, mixed weights (one back-off set blocks it), percent-based programs, or exercises with progression off. When progression is off, nothing says why.
- Two formats: "140 lb × 8" on the done card, "3 × 8 at 140 lb" on the summary.
- Each routine keeps its own target, so the same lift in two routines gets two targets.
- On a 3-routine program, a saved target first fills a set in the second session of that routine, often near the end of the 7-day trial.

COMPARE WITH
- Alpha Progression, Liftosaur, Boostcamp, Fitbod, RP Hypertrophy, Hevy, Strong.

FOCUS ON
- When and where each app shows the next weight or reps: during the set, at exercise end, at workout end, or in the next workout.
- Whether the lifter must accept, and how many taps that takes.
- How each app explains why.
- What happens after a missed target or a stall.
- What happens when the lifter skips the summary.
- Bodyweight lifts, dumbbells, mixed weights and back-off sets.

NOT A DOWNSIDE (Unit skips these on purpose, do not rank them)
- Changing the routine without the lifter's okay, deload rules, cycles or periodization, RPE-based auto-adjusting, AI coaching.

ANSWER FORMAT (use exactly this, nothing before it)
1. Downsides, worst first, 5 to 10 rows:
| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
- Severity: High = loses a sale, a set, data or trust for many users. Med = slows or confuses users often. Low = rare or cosmetic.
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
- Fix: name the screen, the element and the change. One fix per row.
2. What Unit does better: up to 5 bullets. Each names the competitor it beats and how.
3. Top 3 changes: the 3 fixes to ship first, one line each, with the reason.

RULES
- Evidence only. Each row says what the competitor's screen or flow shows: screen name, button label, tap count or default value.
- Source: where you saw it (App Store screenshots, help center, YouTube walkthrough, Reddit thread) and its date. If you cannot verify it, write "unverified" and rank the row lower.
- No generic advice. Never write "improve onboarding", "add gamification", "make it more intuitive" or similar. If you cannot name the element to change, drop the row.
- Fixes must fit Unit: fast, one hand, few words. Prefer a smaller change over a new screen.
- Compare the same moment in each app.
- Only list a competitor where it is better. Do not pad.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```

## 5. Progress: History and Analytics

Attach: `05-progress-history.png`, plus captures of the Analytics tab, the History list and one past workout.

```text
Benchmark one flow of my iOS app, Unit, against similar apps. Flow: looking back at progress, in History and the Analytics tab. Goal: find where Unit is weaker.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Core loop: last time's weight and reps are already in the set row, one tap logs the set, and a rest timer starts by itself and shows on the Lock Screen. When an exercise is done, Unit suggests the next target (double progression: add reps up to the top of a range, then add weight). The lifter saves it on the post-workout summary. Unit never changes the routine on its own.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone: no account, no sign-up, no cloud sync, no export yet. No Apple Watch app. No Apple Health.
- Money: hard paywall right after setup. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99 one-time. Monthly and Yearly have a 7-day free trial. Yearly is preselected for people who can get the trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt and the attached screenshots as the truth for Unit.

THIS FLOW
- Who: a lifter at home or between sessions.
- Job: answer three questions fast. Am I getting stronger? What did I do last time? Did I hit a PR?

ATTACHED
- 05-progress-history.png: the progress page for one exercise (Bench Press).
- If attached: the Analytics tab, the History list and one past workout.

WHAT THE USER SEES (exact labels in quotes; the screenshot uses lb)
History (Today tab, top right "History")
1. A "List" / "Calendar" switch.
2. List: "This week" shows routines missed earlier this week ("Missed", "Tap to start"). Then rows by month: date, routine, "N exercises", a "PR" tag, and a state tag ("Completed", "Partial", "Skipped"). Filter chips "Completed" and "Missed".
3. Calendar: a month grid. Filled day = workout. Outlined day = missed scheduled day. Tap a day -> that day's workouts -> an exercise -> its progress page.
4. Workout detail: name, date, exercise cards ("3 × 8 at 60 kg", or one line per set when sets differ), PR tags, and the "Next time" block with that workout's suggestions.
5. PR rule: heavier than the best so far, or the same weight with more reps.

Analytics tab
6. "Last 4 weeks" card: "Getting stronger", "Holding steady", "Fewer sessions lately" or "Building a baseline", plus one line, for example "2 of 3 lifts up. 7 of 12 sessions done." Tap for "How this works".
7. "Main lifts", up to 3, picked automatically (squat, bench press and deadlift first), "Edit" to change: latest best set, date, 4-week change, 12-week chart, best set and next target.
8. "Other exercises": name and latest best set.
9. Exercise page: name, equipment and body area ("Barbell · Full Body"), latest set in large type ("135 lb × 10"), "Latest · Oct 23", a "Weight" / "Reps" / "Volume" switch, a 12-week chart you can scrub ("Heaviest set each week · 12 weeks"), "Next" (saved target and routine), "Best set", "Est. 1RM" with an info button, and "Recent" (last 2 workouts). A "4-week comparison" line ("60 kg × 8 -> 62.5 kg × 8") shows when both 4-week windows have data.

WHAT UNIT DOES NOT HAVE HERE TODAY
- No edit or delete of a past workout. A wrong set stays wrong.
- No export, and no import of history from Hevy, Strong or a spreadsheet.
- No sync and no in-app backup. History reaches a new phone only through a full iPhone backup restore.
- No Apple Health.
- No body weight or body measurements.
- No volume per muscle group.
- No "Next" target when progression is off, and no line saying why.
- PRs show only in History, not during the workout.
- History and Analytics cannot be opened during a workout.

COMPARE WITH
- Strong, Hevy, JEFIT, Alpha Progression, Liftin', Setgraph, Boostcamp.

FOCUS ON
- Answering "am I getting stronger?" in one look: which numbers, charts and time ranges.
- Finding "what did I do last time" for one exercise.
- PRs and records: what counts, where they show, when.
- Fixing mistakes in past workouts.
- Getting data in and out: export, import, backup, Apple Health.
- How much each screen asks the user to read.

NOT A DOWNSIDE (Unit skips these on purpose, do not rank them)
- Social sharing, streaks, badges, leaderboards, dark dashboards, recovery or readiness scores.

ANSWER FORMAT (use exactly this, nothing before it)
1. Downsides, worst first, 5 to 10 rows:
| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
- Severity: High = loses a sale, a set, data or trust for many users. Med = slows or confuses users often. Low = rare or cosmetic.
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
- Fix: name the screen, the element and the change. One fix per row.
2. What Unit does better: up to 5 bullets. Each names the competitor it beats and how.
3. Top 3 changes: the 3 fixes to ship first, one line each, with the reason.

RULES
- Evidence only. Each row says what the competitor's screen or flow shows: screen name, button label, tap count or default value.
- Source: where you saw it (App Store screenshots, help center, YouTube walkthrough, Reddit thread) and its date. If you cannot verify it, write "unverified" and rank the row lower.
- No generic advice. Never write "improve onboarding", "add gamification", "make it more intuitive" or similar. If you cannot name the element to change, drop the row.
- Fixes must fit Unit: fast, one hand, few words. Prefer a smaller change over a new screen.
- Compare the same moment in each app.
- Only list a competitor where it is better. Do not pad.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```
