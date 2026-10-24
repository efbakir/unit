## 1. Downsides, worst first

| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
|---|---|---|---|---|---|---|---|
| 1 | A past workout can't be edited or deleted, so one typo stays in History, charts, PRs and "Next" for good | Strong, Hevy, Alpha Progression, JEFIT, Boostcamp | Strong: History > "..." > "Edit Workout", change sets, weights, reps and start/end time, then Save. Hevy: Workout Detail has an "Edit Workout" link; "..." > "Delete Workout" with a confirm popup. Alpha: "You can open past workouts again and edit or delete them" | Strong help (upd. Feb 22, 2022); Hevy delete help (no date, read Oct 24, 2026); Mobbin Hevy Workout Detail (Sep 2025 capture); Alpha guide (Sep 2026) | High | Workout detail: add an "Edit" button in the top bar that reopens the logged sets for editing, plus "Delete workout" at the bottom behind a confirm. Recompute PR tags and "Next" after saving | M |
| 2 | No sync and no backup: a lost or replaced phone loses all history | Liftin', Strong, Alpha Progression | Liftin': "iCloud sync keeps iPhone, iPad and Mac on the same page". Strong: "Automatically back up your data with Cloud Sync!". Alpha: an optional account is "the only way your data can be restored" | Liftin' App Store (v54.0.1, Oct 13, 2026); Strong App Store (read Oct 24, 2026); Alpha guide (Sep 2026) | High | Settings: add an "iCloud backup" switch (CloudKit private database) with a "Last backed up" date under it | M |
| 3 | No export, so the user can't keep a copy of their own data | Strong, Alpha Progression, Liftin', Setgraph | Strong: Settings > "Export Strong Data" gives a CSV. Alpha: free CSV export of the full workout history and measurements. Liftin': "Export everything as CSV whenever you want". Setgraph: Settings > Account > Export (CSV) | Strong help (upd. Apr 27, 2021); Alpha guide (Sep 2026); Liftin' App Store (Oct 13, 2026); Setgraph App Store and r/Setgraph post (date unverified) | High | Settings: add an "Export data (CSV)" row that opens the share sheet with one row per set (date, routine, exercise, weight, reps, state) | S |
| 4 | No import, so a Hevy or Strong user starts from zero and the "Last 4 weeks" card says "Building a baseline" for weeks | Hevy, Liftin' | Hevy: Profile > Settings > "Export & Import Data" > "Import Strong CSV". Existing workouts are untouched, unmatched exercises become custom, and the import can be reverted. Liftin': "Import your history from Hevy" | Hevy import help (no date, read Oct 24, 2026); Liftin' App Store (Oct 13, 2026) | Med | Settings: add "Import from Hevy or Strong (CSV)" with a mapping step for unmatched exercises and a one-tap "Undo import" | L |
| 5 | A PR only shows later in History, not at the moment the set is logged | Hevy, Setgraph | Hevy: "When you check off a set and achieve a Personal Record, a banner will appear" (toggle "Live Personal Record Notification"). Setgraph: a toast names the record broken with an absolute change like "+5 lb" | Hevy Live PR help (no date; feature called "recently added" on r/Hevy, Jul 7, 2025); Setgraph 26.8.0 notes (Aug 18, 2026) | Med | Workout screen, set row: when a checked set passes Unit's PR rule, show the same "PR" tag inline next to the set, no banner | M |
| 6 | History and the exercise page can't be opened during a workout, so "what did I do last time?" needs leaving the session | Strong, Hevy | Strong: the Exercise Detail screen (History, Charts, Records tabs) opens "From the Log Workout screen, simply tap on the name of the Exercise". Hevy: set records can be seen by "tapping on the exercise from within the workout" | Strong exercise detail help (upd. Feb 8, 2021); Hevy Set vs Personal Records help (no date) | Med | Workout screen, exercise header: make the exercise name tappable to open its Exercise page as a sheet (chart, "Best set", "Recent") | S |
| 7 | No volume per muscle group, so a user can't see that, for example, back is undertrained | Hevy, Alpha Progression | Hevy: Profile > Statistics > "Set Count per Muscle Group" (primary = 1 set, secondary = 0.5; Pro). Workout Detail shows "Muscle Split" bars (Legs 69%, Core 17%, Back 11%). Month report lists sets per muscle (Shoulders 27, Triceps 22.5). Alpha: "Sets per muscle" chart (Pro) | Hevy help (no date); Mobbin Hevy Workout Detail and August Report (Sep 2025 capture); Alpha guide (Sep 2026) | Med | Analytics: add a "Sets per muscle · last 4 weeks" card under "Other exercises", with one bar per muscle group | M |
| 8 | No Apple Health, so Unit workouts don't show in Fitness or Health | Strong, Liftin', Alpha Progression, Hevy | Strong: Profile > Settings > App Integrations > Apple Health > "Connect"; workouts appear outside Strong, including Activity Rings. Liftin': "Heart rate and workouts go to Apple Health". Alpha: syncs workouts with calories, body weight, body fat. Hevy writes workouts to Health | Strong Health help (date not shown); Liftin' App Store (Oct 13, 2026); Alpha guide (Sep 2026); Hevy Apple Health help section (no date) | Med | Settings: add an "Apple Health" switch that saves each finished workout as a strength training workout (start, end, duration) | M |
| 9 | No body weight or measurements next to strength trends | Strong, Hevy, Alpha Progression | Strong: Measurements with Weight and Body Fat % synced to Apple Health; circumferences are PRO. Hevy: Profile > "Measures", one graph per measurement, and "Update Bodyweight" during a live workout. Alpha: free body measurements, charts in Pro | Strong measurements help (upd. Feb 9, 2021); Hevy body measurements page (no date); Alpha guide (Sep 2026) | Low | Analytics: add a "Body weight" row below "Main lifts" that reads weight from Apple Health (needs row 8) with a 12-week line | M |
| 10 | Only one PR rule (heavier, or same weight with more reps) and one "Best set"; no best per rep count | Hevy, Strong, Setgraph | Hevy: "Set Records" table, Reps / Personal Best: 3 = 100kg, 5 = 95kg, 8 = 75kg, 10 = 20kg, and PRs for Heaviest Weight, Best 1RM, Best Set Volume, Best Session Volume. Strong: Records tab with best at each rep up to 12. Setgraph: Records tab with rep ranges like "1-12 · 225 lb" | Mobbin Hevy exercise Summary (Sep 2025 capture); Strong Records help (upd. Feb 25, 2021); Setgraph 26.8.0 notes (Aug 18, 2026) | Low | Exercise page: under "Best set", add a collapsed "Best at each rep" list (1 to 12 reps, heaviest weight and date) | S |

## 2. What Unit does better

- **A plain verdict, not just numbers (beats Hevy).** Unit's "Last 4 weeks" card says "Getting stronger" or "Holding steady" with "2 of 3 lifts up. 7 of 12 sessions done." and "How this works". Hevy's August Report (Mobbin, Sep 2025) shows "2 new PRs", sets per muscle and top exercises, but no line that answers "am I getting stronger?".
- **Missed days are visible (beats Hevy).** Unit shows "Missed" / "Tap to start" in "This week", a "Missed" filter chip, and outlined calendar days for missed scheduled days. Hevy's Calendar (Mobbin, Sep 2025) only fills days with a workout, so missed plan days are not shown.
- **"Next" target on the exercise page (beats Hevy and Strong).** Unit shows "Next" next to "Best set" and "Est. 1RM". Hevy's exercise Summary (Mobbin, Sep 2025) shows the chart, PRs and Strength Level with no next target. Strong's Exercise Detail tabs (About, History, Charts, Records) list no next target (Strong help, Feb 2021; unsure this is still true in 2026).
- **Fewer words to the answer (beats Hevy).** Unit's exercise page puts "Best set · 135 lb × 10", "Estimated 1RM" and a Weight / Reps / Volume switch on one screen. Hevy splits the same job across Summary, History, How to and Leaderboard tabs, plus a Strength Level block (Mobbin, Sep 2025).

## 3. Top 3 changes

1. **Edit and delete a past workout (row 1).** Every PR, chart and "Next" is built on History, so one wrong set breaks the whole answer to "am I getting stronger?". Strong, Hevy, Alpha, JEFIT and Boostcamp all allow it.
2. **iCloud backup (row 2).** Losing months of lifts is the worst possible outcome for a logger, and Liftin' and Strong both promise sync on their App Store pages.
3. **Inline "PR" tag on the set row during the workout (row 5).** It answers "did I hit a PR?" at the moment it happens, reuses the existing tag and rule, and Hevy and Setgraph both do it.

---

## Sources

All links read on Oct 24, 2026 (Asia/Kuala_Lumpur) unless noted. "Upd." is the page's own last-updated date.

**Unit**
- Unit App Store asset `docs/app-store-assets/2.1/source/05-progress-history.png`, efbakir/unit main branch, https://raw.githubusercontent.com/efbakir/unit/main/docs/app-store-assets/2.1/source/05-progress-history.png (saved as `screens/unit-05-progress-history.png`).
- Unit behaviour as written in the benchmark prompt "## 5. Progress: History and Analytics" (attachment 01M5NZPRZAPYTJ5E4DQ7G5YA1A.md, lines 360-441).

**Mobbin (iOS, Hevy; dates seen in the screens are Aug to Sep 2025)**
- Hevy exercise History with set medals: https://mobbin.com/screens/4d2233ca-a56c-4244-bde5-821bf3f1b6a9
- Hevy exercise Summary chart, "Year" range: https://mobbin.com/screens/f245512f-9025-4dfc-8475-d4f8d48d8ff1
- Hevy Personal Records: https://mobbin.com/screens/14db3357-172d-401e-9179-05f032ec2a26
- Hevy Set Records table: https://mobbin.com/screens/69d88520-1cf0-45b3-82a1-d801ed57a610
- Hevy Workout Detail with "Edit Workout" and Muscle Split: https://mobbin.com/screens/f388fe19-e9de-44ef-8faa-b4c9c192f6ad
- Hevy Workout Detail muscle split: https://mobbin.com/screens/1b7f04f9-146e-443d-b958-9aa2f9ac670f
- Hevy August Report, Main Muscle Groups: https://mobbin.com/screens/fd40caeb-3856-4132-bb20-db1c59cc671a
- Hevy August Report, PRs: https://mobbin.com/screens/9fb09e5a-3a45-4ec7-921d-afbc46cc9f48
- Hevy Calendar: https://mobbin.com/screens/d231a99c-8ab0-44f4-bdd7-e07eadbfae9f
- Hevy "No data yet" chart: https://mobbin.com/screens/b5330051-d68c-4c25-8387-f6c96f4797ab
- Hevy Save Workout ("When" field): https://mobbin.com/screens/20836ef4-59fa-4564-a45b-283c718cfd7d

**Strong**
- Edit a past workout (upd. Feb 22, 2022): https://help.strongapp.io/article/249-how-do-i-edit-a-past-workout
- Adjust workout date: https://help.strongapp.io/article/167-adjust-workout-date
- Export data (upd. Apr 27, 2021): https://help.strongapp.io/article/235-export-workout-data
- Apple Health sync (no date shown): https://help.strongapp.io/article/147-sync-with-apple-health
- Measurements (upd. Feb 9, 2021): https://help.strongapp.io/article/238-add-measurements
- Exercise Detail screen (upd. Feb 8, 2021): https://help.strongapp.io/article/237-about-exercise-detail
- Records screen (upd. Feb 25, 2021): https://help.strongapp.io/article/216-exercise-records-screen
- App Store listing ("Cloud Sync", CSV export): https://apps.apple.com/ai/app/strong-workout-tracker-gym-log/id464254577

**Hevy**
- Delete sets, workouts: https://help.hevyapp.com/hc/en-us/articles/38030200802583
- Import Strong data: https://help.hevyapp.com/hc/en-us/articles/35687878672663-Importing-Strong-Data-into-Hevy
- Import and export: https://help.hevyapp.com/hc/en-us/articles/38001424401943
- Live PR notification: https://help.hevyapp.com/hc/en-us/articles/36012016405655 and https://www.hevyapp.com/features/live-pr/
- Set Records vs Personal Records: https://help.hevyapp.com/hc/en-us/articles/38279531346455
- Sets per Muscle Group: https://help.hevyapp.com/hc/en-us/articles/44128140257431-How-Does-Sets-per-Muscle-Group-Work
- Body measurements: https://www.hevyapp.com/features/track-body-measurements/
- Apple Health help section: https://help.hevyapp.com/hc/en-us/sections/36957443687831-Apple-Health
- r/Hevy "PR Notifications broken on AW?" (Jul 7, 2025): https://www.reddit.com/r/Hevy/comments/1lu3gxb/

**Others**
- Alpha Progression guide ("at the time of writing, September 2026"): https://alphaprogression.com/en/blog/alpha-progression-guide
- Liftin' App Store (v54.0.1, Oct 13, 2026): https://apps.apple.com/us/app/liftin-gym-workout-tracker/id1445041669
- Setgraph 26.8.0 Personal Records (Aug 18, 2026): https://setgraph.app/articles/setgraph-26-8-0-personal-records-and-share-cards
- Setgraph App Store: https://apps.apple.com/gb/app/setgraph-workout-log/id1209781676 ; r/Setgraph CSV export post (date unverified): https://www.reddit.com/r/Setgraph/comments/1rcqoy3/
- JEFIT FAQ (edit past workouts; date not shown): https://www.jefit.com/support/faq
- Boostcamp v1.5.4 notes on r/Boostcamp (edit/delete workouts; date unverified, likely 2022): https://www.reddit.com/r/Boostcamp/comments/y0lcpd/

## Gaps

- **No phone captures attached.** The Unit side comes from the written prompt plus one App Store asset. Nothing was checked on a device.
- **The Unit screenshot doesn't match the prompt text.** `05-progress-history.png` shows "Weight over time", "Latest · Aug 12", a "Sessions" list with "+5.0 lb" deltas and about 3 weeks of axis dates. The prompt describes "Barbell · Full Body", "Latest · Oct 23", a "Heaviest set each week · 12 weeks" chart, "Next", "Recent" (last 2 workouts) and a "4-week comparison" line. The asset may be older than the current build. I used the prompt text as the current state.
- **Only Hevy is on Mobbin.** Strong, JEFIT, Alpha Progression, Liftin', Setgraph and Boostcamp rows rest on help pages, App Store text and release notes, not screens.
- **Strong docs are old** (2021 to 2022). I'm not sure Strong still works this way in 2026. The App Store listing read today still lists Cloud Sync, CSV export and Apple Health.
- **Hevy help articles show no date.** Hevy Mobbin captures are from Aug to Sep 2025.
- **Reddit pages were blocked** for full reads (network block). User pain about lost history or uneditable workouts (for example r/strongapp "Lost all my workouts", r/hardyapp "Unable to edit workout history") is unverified and not used as evidence.
- **"No Next when progression is off, and no line saying why":** no competitor screen or doc found that shows a reason line. Not ranked. Alpha Progression has recommendations that can move down and can be turned off, but whether it explains why is unverified.
- **Chart range** (Hevy "Year" dropdown, Boostcamp daily/weekly/monthly) vs Unit's fixed 12 weeks was considered and cut to keep 10 rows. Low severity.
- **Paywall scope:** several competitor features are Pro-only (Hevy sets per muscle, Strong charts and body measurements, Alpha charts). Whether Unit's Analytics is free is unverified, so no "free vs paid" claim is made.
- **Not done:** Refero and TubeAlfred YouTube transcripts were not used. Mobbin plus docs covered every row.
