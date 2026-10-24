# Unit benchmark 4: Exercise done and post-workout summary

Research date: 2026-10-24 (Asia/Kuala_Lumpur). Read-only. Same moment compared in each app: the end of an exercise, the end of a workout, and the first set of the next workout.

## 1. Downsides, worst first

| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
|---|---|---|---|---|---|---|---|
| 1 | An unsaved suggestion is lost after the next workout of that routine. It never shows on Today or in the next workout until saved. | Boostcamp, Hevy, Liftosaur | Boostcamp: "Your targets are waiting when you open the workout." The next workout's Target column shows "10 lb x 5" with "+5 lb" under it (screen 06). Hevy: "Routine values are always updated unless you adjust the settings on the 'save workout' screen." Liftosaur applies the rule when you finish, and you can "Suppress" it (screens 04, 05). | S1, S2, S3, S4 | High | Next workout, set 1 of each exercise: keep the unsaved suggestion as a "Use 140 × 8" chip. One tap fills it. Show the same chip on Today. Nothing saves without the tap. | M |
| 2 | The summary needs one tap per exercise. There's no save-all. A 6-exercise workout means 6 taps to keep every suggestion. | Liftosaur, Strong | Liftosaur needs zero taps (it applies by default, with an opt-out "Suppress" under each exercise). Strong's finish prompt has "Update Values Only", which updates every value in one tap. | S3, S5 | High | Post-workout summary, top of the "Next time" list: add a "Save all 6" button. The per-exercise "Save for next workout" and "Edit" stay. | M |
| 3 | The Done card shows "Suggested next: 140 lb × 8 · +5 lb" but not why. The reason line only shows on the summary. | Boostcamp, Fitbod, Liftosaur | Boostcamp's in-app copy: "You hit all 8 reps, so the weight goes up." Fitbod's "Reps and Weight" sheet explains how it learns (screen 08). Liftosaur has a "Why is the weight adjusted?" sheet for rounded weights. | S2, S6, S3 | Med | Exercise Done card: add the existing reason line under "Suggested next", for example "Every set reached the top." | S |
| 4 | Mixed weights or back-off sets get no suggestion ("No suggestion · Weights varied."). | Liftosaur, Alpha Progression | Liftosaur rules can target single sets (for example `weights[2]`) and preview "Exercise Changes" per set (screen 04). Alpha gives a recommendation per set, which can differ set to set (screen 07: a "220 / 8" row under set 1). | S3, S7 | Med | Exercise Done card: for varied weights, suggest from the heaviest set only, labelled "Top set: 140 × 8 · +5 lb". Back-off sets stay as logged. | M |
| 5 | Small or heavy weight jumps (for example dumbbells, 7.5 to 10 kg) still get "+1 step", even when the jump is large. | Alpha Progression, RP Hypertrophy | Alpha: with a 7.5 kg dumbbell where the next is 10 kg, it recommends more reps first. RP: if the next increment is too big (10 lb to 15 lb dumbbells), it adds a rep to each set instead. | S7, S8 | Med | Done card and summary: if the next step is a big jump for that load, suggest "+1 rep" past the top, with the reason "Next weight is a big jump. Add one rep." The size threshold is a design choice, not a sourced number. | M |
| 6 | Bodyweight lifts with no added weight get no suggestion, and nothing says why. | Liftosaur, Fitbod | Liftosaur has a `bodyweight` variable for lifts like pull-ups. Fitbod suggests reps only for bodyweight moves. | S3, S6 | Med | Done card: for bodyweight sets at or above target, show "Suggested next: 3 × 9 · +1 rep". Where there's still no suggestion, say why, for example "No suggestion · Bodyweight". | M |
| 7 | A stall always gets "Keep this target." It doesn't say which set fell short. | Boostcamp, Hevy Trainer | Boostcamp: "The weakest set sets the next rep target." When no set reached the bottom of the range, it estimates a weight (140 × 7 gives 135 lb × 8). Hevy Trainer has "Reminders to push hard if progression stalls." | S2, S9 | Med | Summary reason line on a miss: name the short set, for example "Set 3: 6 of 8. Keep this target." Same target, no deload. | S |
| 8 | The same target is written two ways: "140 lb × 8 · +5 lb" on the Done card and "3 × 9 at 60 kg" on Today. | Boostcamp (partly verified) | Boostcamp's logging screen uses one "10 lb x 5" form with the change "+5 lb" under it (screen 06). Unverified whether it uses that form on every screen. | S4 | Low | Today and the Done card: use one format, "3 × 8 · 140 lb", with the change as a small tag. | S |
| 9 | After saving, nothing in the next workout marks which lifts went up. | Hevy Trainer, Boostcamp | Hevy Trainer: "When looking at your next Trainer workout, you'll also see a small indication next to the movements you've made progress on." Boostcamp shows "+5 lb" under the target (screen 06). | S9, S4 | Low | Next workout, exercise header: a small "+5 lb" or "+1 rep" tag when a saved target went up. | S |
| 10 | Targets are per routine. In a 3-routine program, a saved target first applies late in the trial. | Alpha Progression, Hevy | Alpha uses your history for recommendations across plans and standalone workouts. Hevy's "Previous" column can read from "Any workout" or "Same routine". | S7, S1 | Low (impact on Unit users unverified) | "Edit next target" sheet: add an "Also use in other routines" switch, off by default. | M |

Not counted as downsides (per the prompt): Liftosaur, Hevy and Boostcamp changing the plan without the lifter's okay; RP's set counts from pump, soreness and feedback (screen 12); Fitbod's adaptive engine; RIR or RPE autoregulation.

## 2. What Unit does better

- Nothing changes without the lifter's okay. Liftosaur, Hevy and Boostcamp rewrite the plan by default, and Hevy can't update values silently when Rep Range is on.
- It explains the suggestion in plain words ("Every set reached the top."). Liftosaur's preview reads "weights[1..5]: += 5lb" (screen 04), and Fitbod's engine is opaque ("Fitbod learns your capacity").
- It says when there's no suggestion ("No suggestion · Weights varied."). In Hevy, rep ranges quietly stop values from updating, and the Save Workout screen shows no progression at all (screen 09).
- Strong's finish prompt only appears when you change something, and it asks "Update Template" or "Keep Original Template" without suggesting a next weight. Unit gives a real next target plus "Repeat previous target" in one tap. (Strong doc dated 2021, so it may be stale.)
- Double progression is in the core flow. Boostcamp auto-progression, Alpha recommendations and Hevy Trainer ($2.99/mo) are Pro features. Unit's own pricing is unverified here.

## 3. Top 3 changes

1. Keep an unsaved suggestion as a one-tap "Use 140 × 8" chip on set 1 and Today. It's the only High-severity data-loss risk, and the fix keeps the lifter in control.
2. Add "Save all N" to the summary. It cuts 4 to 8 taps to 1 when you're tired at the end of a session, where Liftosaur needs 0 and Strong needs 1.
3. Put the reason line on the Done card, and name the short set on a stall. It's a small copy change that answers "why?" at the moment the lifter looks.

## Sources (all accessed 2026-10-24)

- S1 Hevy Help, "routine values" article: https://help.hevyapp.com/hc/en-us/articles/34105442929943 (page date unverified). German article on "Routine aktualisieren" / "Originalroutine beibehalten" ("Update routine" / "Keep original routine"): https://help.hevyapp.com/hc/de/articles/38387296276375. Reddit r/Hevy post 1mpom7t asking for auto-progression in the columns (2025-08-14). App Store id1458862350, v3.2.3, 2026-10-23.
- S2 Boostcamp, Auto-progression: https://www.boostcamp.app/features/auto-progression ("Updated October 2026"). App Store id1529354455, v266, 2026-10-02.
- S3 Liftosaur, Progressions: https://www.liftosaur.com/features/progressions (page date unverified), with screens 04 and 05. Reddit r/liftosaur threads 1lb849p (suppress added) and 1sdap7z (override request): titles only, bodies were blocked. App Store id1661880849, v124, 2026-10-13.
- S4 Boostcamp App Store screenshot 2 (screen 06), App Store v266, 2026-10-02.
- S5 Strong Help, "Update template": https://help.strongapp.io/article/177-update-template (last updated 2021-05-26). App Store id464254577, v6.5.1, 2026-10-08.
- S6 Fitbod Help article 43489869175063 (2026-09-15). Mobbin screen "Reps and Weight": https://mobbin.com/screens/385f0888-5f84-48bb-9e98-83c730d5dc7b (seen 2026-10-24). App Store id1041517543, v8.37.0.
- S7 Alpha Progression blog post "Progression recommendations", plus the guide and glossary on alpha-progression.com (post dates unverified). App Store id1462277793, v7.7, 2026-10-06. Screenshot 3 (screen 07).
- S8 RP Hypertrophy Help article 43864744488599 ("Updated September 30, 2026"). App Store id1555614554, v1.8.0, 2026-10-17. Screenshot 4 (screen 12).
- S9 Hevy Trainer: https://www.hevyapp.com/features/workout-plan-generator/ (page date unverified). Hevy Help article 33106320824727.
- Unit: screens 01 (PR #5 branch `cursor/app-review-fixes-6a81`), 02 and 03 (main), from the efbakir/unit repo, read 2026-10-24. Unit rules and labels come from the prompt.
- Mobbin: Hevy Save Workout (09), Hevy PREVIOUS column (10), Bevel "Update template" (11), seen 2026-10-24.
- YouTube via TubeAlfred: transcript of GXFMcMcBIIg, "How To Use RP Hypertrophy App (Full Review)", Quick How To's (about 2024). Read, not watched. Generic, and not cited in the table.

## Gaps

- Competitor tap counts are unverified unless quoted above (Liftosaur 0 taps and Strong 1 tap come from their docs, not from a test).
- Strong's doc is from 2021, so the 2026 flow may differ. Two 2025 r/strongapp threads (1kn6psc, 1kuue9e) about Strong's update-template options couldn't be read (Reddit blocked the fetch).
- Strong, Alpha, Liftosaur, Boostcamp and RP aren't on Mobbin. Their screens are App Store marketing shots or doc images, which may be staged.
- Boostcamp, Alpha and Hevy Trainer progression are Pro features, and I couldn't test them live.
- Unit's screens 02 and 03 come from an older main build, with labels "Use this target" and "ACCEPTED FOR NEXT TIME" that don't match the prompt's current labels. No current-build screenshot of the summary, the "Edit next target" sheet or the toast.
- Refero wasn't searched in depth. One YouTube transcript was read, and it was low value. TubeAlfred credits are low.
- Unit's pricing is unverified, so the "free vs Pro" bullet is conditional.
- Severity is my judgement from the prompt's scale. No usage data.
