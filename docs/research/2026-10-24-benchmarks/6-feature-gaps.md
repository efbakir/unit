## 1. Gaps ranked by how much they stop people from switching

Review links go to each app's App Store reviews page. The quote is from the named reviewer on that date (US App Store review feed, pulled 2026-10-24).

| # | Feature | Big apps that have it (free or paid) | Demand (quote, link, date) | Tag | Skipped on purpose today | Simplest Unit version | Leave out | Effort |
|---|---|---|---|---|---|---|---|---|
| 1 | Import history from Strong / Hevy CSV | Hevy (free, Strong CSV only). Strong: no import ("on our radar", staff, 2024-12-07). MFW: no history import | "the inability to import workouts... is about to make me jump ship" ([Strong review][r-strong], Madmonkee1, 2026-07-27). "allows to import my workouts and program from other apps like Strong/Hevy" ([MFW review][r-mfw], pradrep, 2026-01-21) | Switch blocker | no | Settings > Import > pick a Strong or Hevy CSV from Files. Map exercises by name, show "12 new exercises will be created", then import into History so PRs, e1RM and charts fill in | Routine import, superset links, Fitbod/JEFIT formats, repeated or scheduled imports | L |
| 2 | Apple Watch logging | Strong, Hevy (free), Fitbod, StrongLifts, JEFIT. Not Boostcamp, Alpha, MFW | "No Apple Watch integration - means I have to carry my phone around in the gym" ([MFW review][r-mfw], clsanchez77, 2026-02-14). "One feature I'd love to see is an Apple Watch app." ([MFW review][r-mfw], kus4real, 2026-08-06) | Switch blocker | no | Watch shows the current set prefilled from last time. One big "Done" tap logs it and starts the rest timer. Phone stays the source of truth | Standalone Watch workouts without the phone, editing routines on the Watch, heart-rate charts | L |
| 3 | Export all data (CSV) | Strong, Hevy (free), Alpha (free), Fitbod, StrongLifts, MFW. Boostcamp: no native export | "Can't even get to years worth of data to export somewhere else!" ([StrongLifts review][r-sl], CAG42, 2026-02-03). "until I have a way to regularly export my data" ([Strong review][r-strong], danielwewo, 2026-07-18) | Switch blocker | no | Settings > Export CSV, one row per set, shared through the iOS share sheet. Keep it working even when the subscription has lapsed | JSON, PDF reports, scheduled exports | M |
| 4 | Edit or delete a past workout | Strong, Hevy (free), Fitbod, StrongLifts (edits flow to Health) | "couldn't edit a finished workout if you discovered an error" ([JEFIT review][r-jefit], Prof542, 2025-07-03). "once it's finished the workouts seem locked in. And if I make a mistake it's an issue." ([Alpha review][r-alpha], Hobgoblinvintage, 2026-03-13) | Expected | no | History > workout > Edit: reuse the live logging screen to change weight, reps, add or delete sets. Delete workout with a confirm | Changing the workout date or time, adding exercises after the fact (v2) | M |
| 5 | Swap or add an exercise in a routine workout | Hevy (free, "Replace Exercise"), Strong, MFW (with suggestions), JEFIT, Alpha, Boostcamp | "easy workout swaps for when a machine is taken" ([MFW review][r-mfw], Chud-Bot, 2026-08-31). "replace exercises in real time!!!" ([Hevy review][r-hevy], lindsaylouwho24, 2026-10-13) | Expected | no | Exercise "..." menu > Replace or Add exercise, searching your own exercise list. Ask "Just today / Update program" | Suggested alternatives, equipment filters, muscle filters | M |
| 6 | Warm-up, drop and failure set tags | Strong (free), Hevy (free), JEFIT, Boostcamp, Alpha, MFW, Fitbod (warm-up toggle) | "distinction between warmup, regular, failure, and drop sets" ([Strong review][r-strong], HugeTig, 2025-12-25). "A great feature to add would be drop sets" ([Fitbod review][r-fitbod], Dei27, 2026-09-03) | Expected | no | Long-press a set number > W / Normal / D / F. Warm-ups are left out of volume, PRs and progression | Myoreps, partials, cluster sets, colour-coded set types | M |
| 7 | Backup and restore (iCloud) | Strong, Hevy (free account sync), Alpha (optional account), Fitbod, MFW. Unit has none | "I updated and lost all my data." ([Boostcamp review][r-boost], MrBloobaDooba, 2026-09-12). "Lost all my workouts" ([JEFIT review][r-jefit], Dspeedyg, 2026-03-05) | Expected | no | Turn on iCloud (CloudKit private database) so data survives a new phone, plus a "Last backed up" line in Settings. Still no account | Web app, Android, a Unit account, real-time multi-device editing | L |
| 8 | Exercise notes (pinned) | Strong (free), Hevy (free, pinned notes since 3.2.2), MFW, JEFIT | "I wish there were a spot to leave notes on machine settings" ([Fitbod review][r-fitbod], srubyl78, 2026-07-07). "pinned notes for each workout to remind you of seat settings" ([Hevy review][r-hevy], Bhammer23, 2026-10-19) | Expected | no | One line of text per exercise that sticks across workouts ("Seat 4, pin 6"), shown under the exercise name | Per-set notes, photos, workout-level notes | S |
| 9 | Supersets | Strong, Hevy (free), Fitbod, JEFIT, Boostcamp, Alpha, MFW | "missing some basic functionality like supersets and better rest length customization" ([Alpha review][r-alpha], evantn, 2025-02-27). "Why Can I Not Save Supersets Into The Future?" ([Boostcamp review][r-boost], Zixxer10r, 2026-09-23) | Expected | no | Link two exercises in a routine. Logging alternates A1, B1, A2, B2, and rest starts only after B | Giant sets, circuits, timed rounds | L |
| 10 | Rest time per exercise | Strong (separate warm-up / working times), Hevy (free, 5 s to 5 min), JEFIT, MFW | "Having to add 15 seconds X 4 every time is a pain." ([Hevy review][r-hevy], Rwill40, 2026-10-08). Warm-up vs heavy rest times asked for in r/Hevy ([thread](https://www.reddit.com/r/Hevy/comments/1ont759/), 2025-11-04, from source md, not re-checked) | Expected | no | Remember the last rest length used per exercise (or a set value on the exercise) and start the timer from it | Per-set rest values, rest rules by set type | S |
| 11 | Apple Health write | Hevy (free), Fitbod, StrongLifts, Alpha, Boostcamp (bodyweight), MFW (since 2026-02-08). Unit: none | "it would be great if it connects with the Apple Health" ([JEFIT review][r-jefit], Vish12Math, 2026-04-14). "synchronize with Apple health so I can also track my calories" ([Hevy review][r-hevy], Andy01001, 2026-10-09) | Expected | no | Write a "Traditional Strength Training" workout with start, end and duration when you finish | Reading heart rate, calorie maths, reading data back | M |
| 12 | RPE or RIR per set | Hevy (free), Strong (in the reps keyboard), Boostcamp, Alpha (RIR), MFW (RIR) | "Love the ability to track perceived exertion." ([Hevy review][r-hevy], Qurdyman, 2026-10-18). Against: "Using RIR system is a very questionable decision for the average lifter." ([MFW review][r-mfw], Vash1053, 2026-04-27) | Nice to have | no | Optional RPE chip in set edit (6 to 10), off by default in Settings | RPE-driven progression or auto-adjust (that is on the skip list) | M |
| 13 | Exercise list screen (browse, rename, delete) | Strong, Hevy (7 custom exercises free), JEFIT, Alpha, MFW | "I'd also like the ability to delete exercises I've created." ([Strong review][r-strong], csutech5, 2025-11-29). "you can't delete archived exercises you created" ([Strong review][r-strong], Just an other, 2025-06-19) | Expected | no | Settings > Exercises: list, search, rename, merge duplicates, delete (with a warning when history exists) | Videos, muscle diagrams, equipment tags | M |
| 14 | Body weight log | Hevy (free, weight and waist), Alpha (free measurements), JEFIT, StrongLifts (via Health), Boostcamp (Health sync), MFW, Strong (measurements, tier unverified) | "I've been using this to track my lifts and measurements and it's perfect for both" ([JEFIT review][r-jefit], Zack attack2168, 2026-07-21). "make logging my bodyweight and workouts easier and easier" ([Boostcamp review][r-boost], ftgfghnhtftnyftnyd, 2026-05-05) | Nice to have | no | One weight entry plus a 12-week line, using the chart you already have. Read from Apple Health if allowed | Tape measurements, body fat, progress photos | M |
| 15 | Sets per muscle group | Hevy (muscle distribution free, sets per muscle Pro), Boostcamp (Pro heatmap), JEFIT (muscle map), MFW, Fitbod | "the weekly view of how many total working sets per week is the #1 thing I track" ([Hevy review][r-hevy], Astro-Chance, 2026-10-18) | Nice to have | no | Weekly hard sets per muscle as a plain list in Analytics. Needs one primary muscle per exercise | Body heatmap, recovery percentages | M |
| 16 | Strava / Garmin | Hevy (free Strava), Fitbod (Strava). Garmin: asked of Strong and Fitbod, not found in either | "Need Garmin Integration NOW" ([Strong review][r-strong], htdfjigbvft, 2026-09-17). "no integration with Garmin" ([Fitbod review][r-fitbod], OliverClosoff, 2026-08-12) | Nice to have | no | Lean on Apple Health (row 11). Many Garmin and Strava setups can sync with Health (not verified per device) | Native Strava OAuth, Garmin Connect IQ app | L |
| 17 | Warm-up calculator | Strong (PRO), Hevy (Pro), StrongLifts, Alpha (Pro), MFW (smart warm-up planner), Fitbod (toggle) | "I should be able to set a target weight for working sets and let it do it for me" ([Fitbod review][r-fitbod], lucian_cap001, 2026-08-02). Against forcing it: "I don't necessarily want to warmup before each new lift." ([StrongLifts review][r-sl], birdperson088, 2026-10-17) | Nice to have | no | "Add warm-ups" in the exercise menu fills 2-3 W sets (for example bar, 50%, 75%) from the first working weight. Never automatic | Plate breakdown per warm-up (plate calculator is skipped), forced warm-up screens | M |
| 18 | Plate calculator | Strong (PRO), Hevy (free), StrongLifts, Boostcamp (Pro), Alpha (Pro), MFW | "basically required to even lift" ([Boostcamp review][r-boost], Killian rhodes, 2022-11-14) | Nice to have | yes | Keep skipped | All of it | M |
| 19 | Dark mode | Hevy (Theme setting), StrongLifts ("Light & Dark mode support"), Boostcamp (made free per a 2024 review), JEFIT (2025), Strong (a 2025 review says dark mode keeps reverting) | "Please add dark mode on IOS." ([JEFIT review][r-jefit], dMinor17, 2025-04-22) | Expected | yes | Keep skipped. Revisit if Watch ships, since Watch is dark anyway | All of it | M |
| 20 | Periodization: cycles, blocks, deloads, RPE auto-adjust | Alpha (Pro), MFW, StrongLifts (deload), Boostcamp programs | "I'd love to be able to program deloads." ([Hevy review][r-hevy], Kritikal Critic, 2026-10-16) | Nice to have | yes | Keep skipped. Pasted programs can already spell out a deload week | All of it | L |
| 21 | Form videos | Hevy, Strong, Fitbod, JEFIT (1,400+), Alpha, MFW (Jeff Nippard), StrongLifts | "the short video demonstrations of each exercise are helpful" ([Hevy review][r-hevy], lizzyliz543, 2026-10-19) | Nice to have | yes | Keep skipped | All of it | L |
| 22 | AI or generated plans and exercise picks | Fitbod (core), Hevy (Trainer, Pro), JEFIT (AI Adaptive Plan), Alpha (generators, Pro), MFW | Against: "no stupid AI or leaderboards being crammed down your throat" ([Strong review][r-strong], Florida Jit 26, 2026-08-28). "No stupid AI prompts" ([Hevy review][r-hevy], Realuse6738, 2026-10-07) | Nice to have | yes | Keep skipped | All of it | L |
| 23 | Social: feed, following, sharing | Hevy (free feed, follow, leaderboards), Alpha (plan sharing), Strong (share sheet) | "the social aspect is also very cool with a group of friends" ([Hevy review][r-hevy], AHAM7, 2026-10-21). Against: "a waste" ([Hevy review][r-hevy], Isabel_123_456, 2026-10-17) | Nice to have | yes | Keep skipped | All of it | L |
| 24 | Game features: leaderboards, streaks, badges | Hevy (streaks, badges, leaderboards), Fitbod (streak), JEFIT (badges, points), Alpha (achievements) | "One of my favorite features is the workout streak." ([Fitbod review][r-fitbod], TCUGIRLY, 2026-10-07). Against: "I hate that I lose my streak if I go on vacation." ([Fitbod review][r-fitbod], BGMNH77, 2026-08-10) | Nice to have | yes | Keep skipped | All of it | M |
| 25 | iPad and landscape | Hevy, StrongLifts, Boostcamp, MFW ship iPad screenshots. Strong, Fitbod, JEFIT, Alpha do not | "there is not a true full screen for iPad" ([Boostcamp review][r-boost], Major.Minor, 2022-02-28) | Nice to have | yes | Keep skipped | All of it | L |

## 2. Build order

1. Import Strong / Hevy CSV (#1): Strong users are first in the win order, and Strong's own export "cannot be imported back into Strong", so their years of history only move if Unit reads that file.
2. CSV export (#3): cheap once the import schema exists, and it answers the "trapped data" fear that sits next to a hard paywall (StrongLifts reviews show the backlash).
3. Edit or delete a past workout (#4): a wrong set today corrupts PRs, e1RM and progression forever. It reuses the logging screen.
4. Swap or add an exercise mid-workout (#5): a taken machine breaks the routine on day one. Without it, program followers fall back to Notes.
5. Apple Watch logging (#2): the biggest single ask by volume (195 review mentions of "watch"), but L effort. Ship it after the cheap trust items, and use it as the hook in the paid pitch.

## 3. Do not copy

1. A free tier that hides history or export (Hevy keeps 3 months of history free; StrongLifts users locked out of their own data): it breaks Unit's "your data, your phone" promise and drives 1-star reviews.
2. Streaks and badges (Fitbod, JEFIT): reviewers complain when vacations or injuries break streaks, and Strong fans praise having none.
3. AI-generated plans and "AI coach" text (Fitbod): reviewers call it "AI bloat" and "cheap AI". Unit's edge is a written reason for each change.
4. Forced warm-up or recommendation screens between sets (StrongLifts' 2026 Watch and warm-up changes): "Way too many taps" breaks one tap per set.
5. A social feed (Hevy): it is Hevy's moat and needs accounts and servers. It conflicts with "no account, data on the phone".

---

## Feature matrix (supporting step 1)

Free = in the free tier. Paid = paid tier or the app has no free tier (Fitbod, StrongLifts, MFW and Unit are paid-only). "?" = not verified this session. "Free?" or "Paid?" = present, tier not verified.

| Feature | Fitbod | Strong | Hevy | StrongLifts | JEFIT | Boostcamp | Alpha | MFW | Unit |
|---|---|---|---|---|---|---|---|---|---|
| Import other app's history | ? | No | Free | ? | ? | ? | ? | No | No |
| Apple Watch app | Paid | Free? | Free | Paid | Free? | No | No | No | No |
| CSV export | Paid | Free? | Free | Paid | ? | No | Free | Paid | No |
| Sync or backup | Paid | Free? | Free | Paid? | Free? | Free? | Free | Paid | No |
| Edit or delete past workout | Paid | Free? | Free | Paid | ? | ? | ? | ? | No |
| Swap exercise mid-workout | Paid | Free? | Free | ? | Free? | ? | Free? | Paid | No |
| Warm-up / drop / failure tags | Paid | Free | Free | Paid | Free? | Free? | Free? | Paid | No |
| Warm-up calculator | Paid? | Paid | Paid | Paid | ? | ? | Paid | Paid | No |
| Supersets | Paid | Free? | Free | ? | Free? | Free? | Free? | Paid | No |
| Exercise notes | ? | Free | Free | ? | Free? | ? | ? | Paid | No |
| Rest time per exercise | ? | Free? | Free | ? | Free? | ? | ? | Paid | No |
| Auto rest timer | Paid | Free | Free | Paid | Free? | Free? | Free | Paid | Paid |
| RPE / RIR | ? | Paid? | Free | ? | ? | Free? | Free? | Paid | No |
| Apple Health | Paid | Free? | Free | Paid | ? | Free? | Free? | Paid | No |
| Strava / Garmin | Paid (Strava) | No? | Free (Strava) | ? | ? | ? | ? | ? | No |
| Body weight / measurements | ? | Paid? | Free | Paid | Free? | Free? | Free | Paid | No |
| Muscle-group stats | Paid | ? | Free / Paid | ? | Free? | Paid | ? | Paid | No |
| Progression suggestions | Paid | No? | Paid | Paid | Paid? | Paid | Paid | Paid | Paid |
| Plate calculator | ? | Paid | Free | Paid | ? | Paid | Paid | Paid | No |
| Dark mode | ? | Free? | Free? | Paid | Free? | Free | ? | ? | No |
| Social feed | ? | No? | Free | ? | ? | ? | ? | ? | No |

## Sources

App Store pages (descriptions, version, ratings count, iPad screenshots and Watch support read 2026-10-24 via the iTunes lookup API):
- Strong 6.5.1 (2026-10-08), 108,539 ratings: https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577
- Hevy 3.2.3 (2026-10-23), 99,597 ratings: https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350
- Fitbod 8.37.0 (2026-10-19), 288,106 ratings: https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543
- StrongLifts 4.4.4 (2026-10-22), 76,872 ratings: https://apps.apple.com/us/app/stronglifts-5x5-workout-plan/id488580022
- JEFIT 17.2.9 (2026-10-23), 46,922 ratings: https://apps.apple.com/us/app/jefit-workout-plan-gym-tracker/id449810000
- Boostcamp v266 (2026-10-02), 10,675 ratings: https://apps.apple.com/us/app/boostcamp-workout-tracker/id1529354455
- Alpha Progression 7.7 (2026-10-06), 2,237 ratings: https://apps.apple.com/us/app/alpha-progression-gym-tracker/id1462277793
- MacroFactor Workouts 1.4.1 (2026-10-03), 4,799 ratings: https://apps.apple.com/us/app/macrofactor-workouts-tracker/id6737156524
- Unit (0 ratings): https://apps.apple.com/us/app/unit-gym-workout-log/id6775008893

App Store reviews (3,417 US reviews, 2020-10 to 2026-10-22, from https://itunes.apple.com/us/rss/customerreviews/page=N/id=ID/sortby=mostrecent/json, pulled 2026-10-24). Each quote above names the reviewer and date:
- [r-strong]: https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577?see-all=reviews
- [r-hevy]: https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350?see-all=reviews
- [r-fitbod]: https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543?see-all=reviews
- [r-sl]: https://apps.apple.com/us/app/stronglifts-5x5-workout-plan/id488580022?see-all=reviews
- [r-jefit]: https://apps.apple.com/us/app/jefit-workout-plan-gym-tracker/id449810000?see-all=reviews
- [r-boost]: https://apps.apple.com/us/app/boostcamp-workout-tracker/id1529354455?see-all=reviews
- [r-alpha]: https://apps.apple.com/us/app/alpha-progression-gym-tracker/id1462277793?see-all=reviews
- [r-mfw]: https://apps.apple.com/us/app/macrofactor-workouts-tracker/id6737156524?see-all=reviews

[r-strong]: https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577?see-all=reviews
[r-hevy]: https://apps.apple.com/us/app/hevy-workout-tracker-gym-log/id1458862350?see-all=reviews
[r-fitbod]: https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543?see-all=reviews
[r-sl]: https://apps.apple.com/us/app/stronglifts-5x5-workout-plan/id488580022?see-all=reviews
[r-jefit]: https://apps.apple.com/us/app/jefit-workout-plan-gym-tracker/id449810000?see-all=reviews
[r-boost]: https://apps.apple.com/us/app/boostcamp-workout-tracker/id1529354455?see-all=reviews
[r-alpha]: https://apps.apple.com/us/app/alpha-progression-gym-tracker/id1462277793?see-all=reviews
[r-mfw]: https://apps.apple.com/us/app/macrofactor-workouts-tracker/id6737156524?see-all=reviews

Help centers and product pages (read 2026-10-24 unless a date is given):
- Strong rest timer: https://help.strongapp.io/article/231-rest-timer
- Strong warm-up calculator (PRO): https://help.strongapp.io/article/171-warm-up-calculator
- Strong plate calculator (PRO): https://help.strongapp.io/article/169-plate-calculator
- Strong export ("cannot be imported back into Strong"): https://help.strongapp.io/article/235-export-workout-data
- Strong edit past workout: https://help.strongapp.io/article/249-how-do-i-edit-a-past-workout
- Strong RPE: https://help.strongapp.io/article/230-about-rpe
- Strong notes: https://help.strongapp.io/article/134-about-notes
- Strong staff on CSV import, 2024-12-07: https://www.reddit.com/r/strongapp/comments/1h8orix/ (from earlier search, Reddit not opened directly)
- Hevy import Strong CSV: https://help.hevyapp.com/hc/en-us/articles/38001424401943 and https://help.hevyapp.com/hc/en-us/articles/35687878672663
- Hevy free vs Pro guide: https://help.hevyapp.com/hc/en-us/articles/33106320824727
- Hevy rest timer: https://www.hevyapp.com/features/workout-rest-timer/ and https://help.hevyapp.com/hc/en-us/articles/35385404949143
- Hevy edit and delete workouts: https://www.hevyapp.com/features/best-way-to-track-workouts/ and https://help.hevyapp.com/hc/en-us/articles/35119576252951
- StrongLifts app page: https://stronglifts.com/app/
- StrongLifts warm-up: https://support.stronglifts.com/article/87-warmup
- StrongLifts Apple Watch: https://support.stronglifts.com/article/111-apple-watch
- StrongLifts Apple Health: https://support.stronglifts.com/article/32-apple-health
- StrongLifts export (updated 2026-10-17): https://support.stronglifts.com/article/131-export
- Fitbod edit past workout: https://help.fitbod.me/hc/en-us/articles/360006335593
- Fitbod supersets: https://help.fitbod.me/hc/en-us/articles/360006427813
- Fitbod export path (third party, Gript, updated 2026-08-25): https://griptapp.com/help/import-from-fitbod
- Boostcamp Apple Health: https://www.boostcamp.app/features/apple-health
- Boostcamp Watch status (search summary of r/Boostcamp posts 1v4vhef and 1q18bme, not opened): https://www.reddit.com/r/Boostcamp/comments/1v4vhef/
- MFW Apple Health write (2026-02-08): https://macrofactor.com/wo-version-1-1-3/
- MFW integrations (no direct Watch): https://help.macrofactorapp.com/en/articles/354-integrations-workouts
- MFW export: https://help.macrofactorapp.com/en/articles/356-export-your-data-workouts

Reddit (from the source md, not re-checked because Reddit blocks fetching here):
- r/Hevy, 2025-11-04: https://www.reddit.com/r/Hevy/comments/1ont759/
- r/WorkoutRoutines, 2026-03-10: https://www.reddit.com/r/WorkoutRoutines/comments/1rpsqpu/

Screens (screens/ folder, read 2026-10-24):
- 01 Hevy Settings: https://mobbin.com/screens/79183161-da9e-48ea-969d-a7ab9bbb3afc
- 02 Hevy Strava: https://mobbin.com/screens/27058086-32da-41d3-9bba-87cd95468ee6
- 03 Hevy set type: https://mobbin.com/screens/7367dd04-c301-4fbd-ba30-2ec99c1e527c
- 04 Bevel set type: https://mobbin.com/screens/51f23ef6-a082-45af-b363-4e7c417b5e64
- 05 Hevy exercise menu: https://mobbin.com/screens/9bd194ee-f5b1-426e-b0fc-8186dbb14b9f
- 06 Hevy replace exercise: https://mobbin.com/screens/7e32b889-148a-4a79-b39a-0e19713b8174
- 07 Hevy superset tags: https://mobbin.com/screens/21e8a290-0d00-47c1-83f9-ad4b567f3ca0
- 08 Hevy notes and rest: https://mobbin.com/screens/972dd1a0-a420-43a8-8345-c7a527dd6da8
- 09 Centr edit log: https://mobbin.com/screens/fd07d024-9fed-46c2-80fc-9629f3e24324
- 10-11 Strong App Store screenshots 3 and 4, 12 StrongLifts App Store screenshot 10, 13 Alpha App Store screenshot 8 (pages listed above)

## Gaps

- Reddit could not be fetched (blocked). Demand quotes come from App Store reviews instead. The two Reddit threads are cited from the source md and not re-checked.
- Refero returned "subscription is not active", so all reference screens come from Mobbin and App Store screenshots. Mobbin has no Strong, StrongLifts, JEFIT or Alpha screens for these patterns that I found, so Hevy dominates the board.
- No YouTube transcripts were used.
- Watch support for each app comes from App Store device metadata plus help pages, not from using the apps.
- Many matrix cells are "?" or carry a "?" on the tier. Strong PRO features (RPE, measurements) come partly from a third-party site (AppCandid) and are unverified.
- Strong CSV columns were not inspected. Check a real Strong export before building row 1.
- Review mention counts (for example 195 for "watch") are keyword counts across all 8 apps, not unique users. They show topic weight, not demand size.
- Garmin or Strava to Apple Health sync (row 16) is not verified per device.
- Prices were not re-checked beyond the App Store descriptions and the source md.
