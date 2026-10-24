1. Downsides, worst first

| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
|---|---|---|---|---|---|---|---|
| 1 | Can't log a set or control rest from the Lock Screen. Unit's Live Activity is view only: "REST TIMER 0:52", "UP NEXT Barbell Row", no buttons. | Hevy | Lock Screen Live Activity "Deadlift (Barbell) Set 3 of 4, 90 kg x 5 reps" with a check button. Help: "mark set as completed without unlocking your phone or opening the app", rest "-15s / +15s / Skip" from the widget. A Strong user left for Hevy over this. (DOCUMENTED + OBSERVED + REVIEWER) | Hevy help 35649846517399 (read 2026-10-24); Mobbin 05e35802 and 6f5fad08 (~2025); Strong App Store review, v6.3.2, 2026-04-24: "uninstalled and went with Hevy... never built Dynamic Island and lock screen access" | High | Live Activity: add a "Complete set N" check button and -30 / +30 / Skip buttons (LiveActivityIntent). Same values as the in-app row. | M |
| 2 | One rest length for everything, no per-exercise rest, no rest setting in Settings. | Hevy, Strong, Boostcamp, Alpha Progression, JEFIT | Hevy: "Rest Timer: 2min 30s" link under each exercise name, plus a Default Rest Timer in Settings. Strong: per-exercise "Auto Rest Timer" with Working and Warm-up tabs, default 2:00. Boostcamp: "tap the timer icon next to an exercise name", 5 s steps up to 60 min or off. Alpha Progression: per exercise type, per-exercise override. JEFIT: "custom rest timer... for any exercise". (DOCUMENTED + OBSERVED) | Hevy help 35385404949143 + Mobbin 71e7447a (~Sep 2025); Strong help 231 (updated 2021-02-08, not sure still exact in 2026); boostcamp.app/features/rest-timer (Oct 2026); Alpha Progression guide (updated 2026-10-15); JEFIT App Store v17.2.9 (2026-10-23) | Med | Workout screen rest bar: tap the "2:00" to pick this exercise's rest; save it on the exercise for next time. | M |
| 3 | Live Activity and "Rest finished" alert don't show the next set's numbers. Unit shows "Up next" + exercise name only. | Hevy, Alpha Progression | Hevy rest Live Activity: "Next: set 2 of 3 (110 kg x 5-6 reps)". Alpha Progression Live Activity shows "Current exercise, Current set, Weight and repetition recommendation, Live rest timer". Liftin' says the Live Activity keeps "the current set" on the Lock Screen (layout unverified). (OBSERVED + DOCUMENTED) | Mobbin 6f5fad08 (~2025); Alpha Progression guide (2026-10-15); Liftin' App Store v54.0.1 (2026-10-13) | Med | Live Activity + notification: add the prefilled line, e.g. "Set 2 · 135 lb × 10", under "Up next". | S |
| 4 | No warm-up sets. | Hevy, Strong, Boostcamp, Liftin', Alpha Progression | Hevy: orange "W" rows above set 1, "Add Warm Up Sets" in the three-dots menu. Boostcamp: "Add Warmup Sets" in the exercise menu, default 40%×5, 60%×5, 80%×3. Liftin': warm-up calculator, transcript read: "Set one is 10 reps at 50% of the first working sets weight". Alpha Progression: "3 warm-up sets" chip (Pro, not tracked as sets). (OBSERVED + DOCUMENTED) | Mobbin c6586a84 (~2025); hevyapp.com/features/track-workouts; boostcamp.app/features/plate-calculator; YouTube oOm92xyvSN0 Rich Aesthetic (~Apr 2026, transcript read); Alpha Progression App Store screenshot v7.7 (2026-10-06) | Med | "..." menu: add "Add warm-up sets" that inserts 2 grey W rows above Set 1 (excluded from volume and prefill). | M |
| 5 | Can't swap an exercise in a routine workout (machine taken). | Boostcamp, Hevy, Alpha Progression, JEFIT | Boostcamp: "Swap Exercise" under the sets, then "Just This Workout, or This and Future Workouts", keeps the prescription. Hevy three-dots menu: replace. Alpha Progression: replace with a similar-exercise list. JEFIT screenshot title "Swap/Remove Any Exercises As Needed". (DOCUMENTED + OBSERVED) | boostcamp.app/features/swap-exercises + App Store screenshot v266 (2026-10-02); hevyapp.com/features/track-workouts; Alpha Progression guide (2026-10-15); JEFIT App Store v17.2.9 | Med | "..." menu: add "Swap exercise" next to "Skip exercise", this workout only, keep sets and reps. | M |
| 6 | A set added with "+ Add set" can't be removed. | Hevy, Boostcamp | Hevy: "Swipe left on a set to reveal the red Delete button". Boostcamp: "swipe left on the set" to delete a set you added. (DOCUMENTED) | hevyapp.com/features/track-workouts (read 2026-10-24); boostcamp.app/blogs/tips-and-tricks-to-using-boostcamp-app (read 2026-10-24) | Med | Planned grey set rows: swipe left shows "Delete", with the same 4 s Undo toast as "Mark not done". | S |
| 7 | No PR alert during the workout. | Hevy | "When you check off a set and achieve a Personal Record, a banner will appear", with a sound. Toggle: Profile > gear > Workouts > Live Personal Record Notification. (DOCUMENTED) | Hevy help 36012016405655 (read 2026-10-24) | Low | After "Complete set", if it beats the best for that exercise, show "New PR" in the existing Undo toast. | S |
| 8 | Rest +/- step is 30 s, and it changes every later rest. | Hevy, Strong, JEFIT, Alpha Progression | Hevy -15 / +15 / Skip. Strong -10s / +10s / Skip. JEFIT "-15s" / "+15s" around the ring. Alpha Progression: adjust the current rest "without changing the default". (OBSERVED + DOCUMENTED) | Mobbin 71e7447a; Strong App Store screenshot (listing v6.5.1, 2026-10-08, image may be older); JEFIT App Store screenshot v17.2.9; Alpha Progression guide | Low | Rest bar: change -30 / +30 to -15 / +15 and apply to this rest only. | S |
| 9 | No RPE or RIR on a set. | Boostcamp, Hevy, Alpha Progression, Liftin' | Boostcamp: Reps / RPE switch on the keypad with 6 to 10 buttons ("6 Moderate", "8 Hard"). Hevy: RPE per set via a setting. Alpha Progression: "Weight, reps and RIR in two taps". Liftin' v51.0: "Unified view for tracking reps and RPE/RIR". (OBSERVED + DOCUMENTED) | Boostcamp App Store screenshot v266 (2026-10-02, marketing mock); hevyapp.com/features/track-workouts; Alpha Progression App Store (2026-10-06); Liftin' release notes v51.0 (2026-05-11) | Low | Number pad bar: add a third "RPE" tab next to Reps / Weight, optional, never required. | M |
| 10 | Complete button sits in the set card, not a fixed bottom bar (unverified on the current build). | Fitbod | Fixed "LOG SET" button at the bottom of the workout screen, plus "Log All Sets". (OBSERVED) Unit's position is INFERENCE from an older asset (02-one-tap.png). | Mobbin 95917d9d; Unit repo asset 02-one-tap.png (main 765437b, 2026-08-13) | Low | Workout screen: pin "Complete set N" in a bottom bar when the keypad is closed, like the keypad bar already does. | S |

2. What Unit does better

- Undo right after logging. Unit gives Undo for 5 s after each set and 4 s after "Mark not done". Fitbod users had to ask for an undo button after swipe deletes (r/fitbod 1o6dbms, 2025-10-14, REVIEWER).
- Rest end alert names what's next. Unit's "Rest finished / Next: Bench Press · Set 2". Strong's own 6.1.1 notes (2025-07-02) say "Timer notifications may not include next set details (simple timer mode)". Not sure this is still true for Strong in 2026.
- Asks for notification permission at the right moment (during the first rest). Fitbod only sends a rest push if you enabled it in settings (Fitbod help 360006340194, DOCUMENTED).

3. Top 3 changes

1. Live Activity "Complete set N" + -30 / +30 / Skip buttons: the only High row, and a real reviewer left Strong for Hevy over it.
2. Per-exercise rest by tapping the rest bar time: at least 5 of the 7 apps have it, and one 2:00 for squats and curls means a lot of +/- taps every workout.
3. Next set "135 lb × 10" in the Live Activity and notification: S effort, and it makes the Lock Screen useful before buttons ship.

---

## Sources (all read 2026-10-24 UTC+8 unless noted)

Unit
- Prompt text "## 3. Active workout logging" (treated as truth for Unit's current UI).
- Repo efbakir/unit, main 765437b (2026-08-13 13:51 UTC+8): docs/app-store-assets/2.1/source/02-one-tap.png, 06-lock-screen-timer.png.

Hevy
- Live Activity help: https://help.hevyapp.com/hc/en-us/articles/35649846517399
- Rest timer help: https://help.hevyapp.com/hc/en-us/articles/35385404949143
- Live PR help: https://help.hevyapp.com/hc/en-us/articles/36012016405655
- Update routine vs keep original: https://help.hevyapp.com/hc/en-us/articles/38387296276375
- Track workouts page: https://www.hevyapp.com/features/track-workouts/
- Mobbin (version unknown, ~2025): https://mobbin.com/screens/05e35802-ead1-4983-ab63-99070dd21c6a , https://mobbin.com/screens/184c2861-65d0-4764-a3d3-6808a961264e , https://mobbin.com/screens/6f5fad08-23a6-4698-9868-2289969a1d5e , https://mobbin.com/screens/71e7447a-9e62-4ed3-9151-83ddff8c9f47 , https://mobbin.com/screens/1c4a0238-dffb-4b0e-9dfb-e74d1ef62fb1 , https://mobbin.com/screens/c6586a84-385d-4098-888f-6c95503d1784
- Reddit r/Hevy 1hhvo2t "Feature Request: Complete Next Set from Lock Screen" (title only, page blocked).

Strong
- App Store: https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577 (v6.5.1 2026-10-08; v6.5.0 2026-08-12 "New: Live Activity and Dynamic Island support for rest timers"; v6.1.1 2025-07-02 notes; review v6.3.2 2026-04-24)
- Rest timer help: https://help.strongapp.io/article/231-rest-timer (last updated 2021-02-08)

Liftin'
- App Store: https://apps.apple.com/us/app/liftin-gym-workout-tracker/id1445041669 (v54.0.1 2026-10-13; v54.0 2026-10-09; v53.0 2026-09-27; v51.0 2026-05-11)
- Site: https://liftinapp.co/
- YouTube "Liftin' Review: The Pro Way to Track Workouts on iPhone, iPad, and Mac!", Rich Aesthetic, ~Apr 2026: https://www.youtube.com/watch?v=oOm92xyvSN0 (transcript read, not watched)

Alpha Progression
- Guide: https://alphaprogression.com/en/blog/alpha-progression-guide (published 2026-09-10, updated 2026-10-15)
- App Store: https://apps.apple.com/us/app/alpha-progression-gym-tracker/id1462277793 (v7.7, 2026-10-06; v6.8 added Live Activity)

Boostcamp
- Rest timer: https://www.boostcamp.app/features/rest-timer (updated Oct 2026)
- Swap: https://www.boostcamp.app/features/swap-exercises
- Warm-ups: https://www.boostcamp.app/features/plate-calculator
- Tips: https://www.boostcamp.app/blogs/tips-and-tricks-to-using-boostcamp-app
- Features: https://www.boostcamp.app/features
- App Store: https://apps.apple.com/us/app/id1529354455 (v266, 2026-10-02)

JEFIT
- App Store: https://apps.apple.com/us/app/jefit-workout-plan-gym-tracker/id449810000 (v17.2.9, 2026-10-23)

Fitbod
- Mobbin: https://mobbin.com/screens/95917d9d-901a-474c-b86c-ef7994cb5181 , https://mobbin.com/screens/7d5103b0-d6f6-4d15-b173-407f5b0c1e5f
- Rest timer help: https://help.fitbod.me/hc/en-us/articles/360006340194-Rest-Timer
- Reddit: https://www.reddit.com/r/fitbod/comments/1o6dbms/undo_button/ (2025-10-14)

Platform
- Apple HIG Live Activities; ActivityKit LiveActivityIntent (iOS 17+) allows buttons in a Live Activity.

## Gaps

- No phone capture of the number pad set row was attached. I worked from the prompt text.
- Unit's repo asset 02-one-tap.png shows an older UI (black "Complete set", "- 2:00 ▶ +", "SET 1 2 3" pills, "Next exercise Barbell Row" bar) that does not match the prompt text. Prompt text treated as truth. Row 10 depends on this and is marked unverified.
- No hands-on use of any app. No tap counts or seconds per set were measured for competitors, so none are claimed. Unit's 2 taps comes from the prompt.
- Mobbin has no Strong, Liftin', Alpha Progression, Boostcamp or JEFIT screens. Used App Store screenshots (marketing, may not match the shipping UI; Boostcamp's has "Lorem ipsum" text) and help pages.
- Strong's new Live Activity (v6.5.0, 2026-08-12) layout and buttons: unverified.
- Liftin' and Alpha Progression Live Activity buttons: unverified. JEFIT rest auto-start, mid-rest controls on the Lock Screen and end alert: unverified.
- Strong help images are from ~2021. Not sure they match Strong in 2026.
- Hevy Mobbin screens are ~2025. Hevy help pages were read 2026-10-24.
- Reddit pages blocked for the fetch tool; cited by title only.
- "Set 1 falls back to the weakest last set": I found no competitor source that clearly shows a better Set 1 fallback, so no row.
- Watch is a Unit constraint, so not ranked. Strong, Hevy, Liftin', JEFIT and Fitbod have Watch apps; Alpha Progression does not.
- Supersets and notes are missing in Unit and present in Hevy, Strong, Liftin', Alpha Progression, but they did not make the top 10 here.
