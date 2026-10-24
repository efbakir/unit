## 1. Downsides, worst first

| # | Where Unit is weaker | Who does it better | What their screen or flow shows | Source | Severity | Fix for Unit | Effort |
|---|---|---|---|---|---|---|---|
| 1 | Cost is never mentioned until "Save program" opens a hard paywall, after the user did all the setup work. | Hevy, Boostcamp | Hevy shows its "HEVY PRO" paywall inside onboarding with all prices ($2.99 monthly, $23.99 yearly, $74.99 lifetime) plus "Not now" and "Skip" (OBSERVED, Mobbin). Boostcamp tags every program card Free or Pro (REVIEWER, HelloChen 2026). | [S1], [S11] | High | Step 1 "Choose your path": add one line under the two cards, "Unit Pro is needed to save a program. Price shown before you pay." | S |
| 2 | Lines the parser drops are not named. Review only says "N lines didn't parse", so exercises vanish silently. | Zealo | "Review Import" shows each parsed name next to its match, with "Auto-matched / Needs review / Manual" badges and a filter for "Low" and "No Match". Nothing saves until "Confirm & Create Templates" (DOCUMENTED). | [S16] | High | Review program: make the "N lines didn't parse" banner expand to list each dropped line's raw text under its day card. | M |
| 3 | "RPE 8" is read as 8 kg and "@ 75% 1RM" leaves "1RM" in the exercise name, so the user gets wrong weights and messy names. | Liftosaur | Its text format reads "@8" as an RPE target and "80%" as a percent of 1RM, and never as a weight (DOCUMENTED). | [S13] | High | Paste parser: treat "RPE n", "@ n" and "n% 1RM" as a note on the row, never as kg, and strip them from the exercise name. | M |
| 4 | Review can't delete or add a row or rename a day, so a bad import can only be fixed by pasting again. | Liftosaur, Hevy | Liftosaur's editor has "+ Exercise" and "+ Day", deletes from a three-dot menu, and renames from "Edit day" (DOCUMENTED). Hevy routines can reorder, replace and remove exercises (DOCUMENTED). | [S13], [S3] | Med | Review program: add a swipe-left "Delete" on each exercise row (one-handed). Add-row and rename-day are follow-ups. | M |
| 5 | Ready-made programs start with empty weights, so a beginner has no starting number. | Boostcamp, Liftosaur | Boostcamp "Program Onboarding" asks the 1RM for squat, bench, deadlift and overhead press, with a "1 Rep Max Estimate Calculator" (reps and weight in) on the same screen (OBSERVED, 2022 blog image). A 2023 Reddit post says the label said 1RM but the field was used as a training max. Liftosaur opens "Set 1 Rep Maxes" before start, and its first workout shows weights like "5 x 95lb" (DOCUMENTED). Note: Alpha Progression also leaves first weights empty (DOCUMENTED), so this is not universal. | [S8], [S9], [S10], [S14] | Med | Review program: add one optional "Starting weight" field per main lift at the top. It fills every empty row for that lift. | M |
| 6 | No import from Hevy, Strong or CSV, so switchers have to retype everything. | Hevy, Liftosaur | Hevy: Profile > Settings > Export & Import Data > "Import Strong CSV". Liftosaur: "Upload CSV file from Hevy". Both import history only, not programs (DOCUMENTED). | [S4], [S5], [S15] | Med | Step 1 "Choose your path": add a third, smaller link, "Coming from Hevy or Strong?", that opens a CSV file picker. | L |
| 7 | No photo, PDF or spreadsheet import. Coach plans that live in a file have to be typed out. | Zealo, Repport | Zealo "Import trainer plan" has "Choose from Files" (PDF, DOCX, XLSX, CSV) and "Choose Screenshots" (up to 10 images), parsed on-device. Its own guide says photo import may be missing in some builds. Repport says it takes PDFs, spreadsheets, screenshots and text (DOCUMENTED, marketing page). | [S16], [S17] | Med | Paste program screen: add "Import a file" next to "Read program". It extracts the text and feeds the same parser. | L |
| 8 | No way to import a program from a share link. | Liftosaur, Hevy | Liftosaur "Choose a program" has "Import" top right: paste a link, tap "Add", then confirm "Do you want to import program X?" (OBSERVED on the help-page screenshot). Hevy shares a routine or folder as a link that the receiver saves (DOCUMENTED). | [S12], [S2] | Low | Paste program screen: if the pasted text is a URL, fetch the page text and run "Read program" on it. | L |
| 9 | Every program is a rotation, so weekly-wave programs like 5/3/1 can't keep their week structure. | Boostcamp, Liftosaur | Boostcamp asks "Choose your weekly structure" (Mon/Wed/Fri) and splits the program into Week 1, 2, 3 (OBSERVED, 2022 blog images). Liftoscript uses "# Week 1" and "## Day 1" headings (DOCUMENTED). | [S9], [S13] | Low | Paste parser: when "Week 2" headings appear, keep only Week 1 and show "Unit runs Week 1 as a repeat. Weeks 2+ were skipped." on Review. | S |
| 10 | The 2-second opener can't be skipped, and the carousel moves on its own. | Hevy, Fitbod | Hevy's intro carousel has "Skip" (OBSERVED). Every Fitbod question step has "Skip" in the header (OBSERVED). | [S1], [S6] | Low | Opener: let a tap anywhere skip to "Set up your program". | S |

## 2. What Unit does better

- **No account before the first program (vs Strong and Hevy).** Unit's flow has no sign-up step (INFERENCE from the prompt). Strong prompts every user to sign up "before using Strong" (DOCUMENTED, 2021 page). Hevy's sign-up is screen 2 of its Mobbin flow (OBSERVED).
- **Fewer questions to a pick (vs Fitbod).** Unit asks 3 things (goal, experience, days). Fitbod asks 8 steps, plus notifications, body stats and a "Join Fitbod" account screen. Its Mobbin flow is 39 screens (OBSERVED).
- **Plain-text paste with no syntax (vs Liftosaur).** Unit reads "Bench 3x8 60" as written. Liftosaur needs "Bench Press / 3x8 60kg" with slashes, and a syntax error blocks the editor until it's fixed (DOCUMENTED).
- **Progression turns on from a rep range (vs Liftosaur).** In Unit, "3x8-10" is enough. Liftosaur needs a "progress: lp(5lb)" script on the line (DOCUMENTED).
- **Picks for you (vs Hevy).** Unit shows its top 3 with a "Best match" badge. Hevy's Explore gives Level, Goal and Equipment filters over "Show all 26 programs", and the user does the picking (OBSERVED).

## 3. Top 3 changes

1. Say Unit Pro is needed on Step 1, before the setup work (row 1). A paywall after 6 to 8 taps of effort costs trust and sales.
2. List the dropped lines on Review (row 2). A silently missing exercise is lost data, and the user can't fix what they can't see.
3. Stop reading "RPE 8" and "% 1RM" as weight (row 3). A wrong weight on day one breaks trust in the import.

---

## Sources

All accessed 2026-10-24 (MYT). Publish dates are given where the page shows one.

- [S0] Unit asset `docs/app-store-assets/2.1/source/04-program-setup.png`, efbakir/unit, main (read-only via raw.githubusercontent). OBSERVED: "STEP 02 / 05", "Add program", "Paste routine", "Choose program".
- [S1] Mobbin, Hevy iOS onboarding flow: https://mobbin.com/flows/a38ff0a3-66d1-41b1-9644-308171c57ce9 (capture date unknown).
- [S2] Hevy, Share folders and routines: https://www.hevyapp.com/features/share-folders-routines/ (undated).
- [S3] Hevy, Track workouts / routines: https://www.hevyapp.com/features/track-workouts/ (undated).
- [S4] Hevy Help, Importing Strong Data into Hevy: https://help.hevyapp.com/hc/en-us/articles/35687878672663-Importing-Strong-Data-into-Hevy and https://www.hevyapp.com/import/strong/ (undated). Path confirmed by Reddit r/Hevy, 2025-02-02: https://www.reddit.com/r/Hevy/comments/1ig1n8n/import_strong_data_to_hevy/
- [S5] Hevy Explore programs screen, Mobbin: https://mobbin.com/screens/e9573e72-406e-476d-9218-b7902620154a (capture date unknown).
- [S6] Mobbin, Fitbod iOS onboarding flow: https://mobbin.com/flows/66d6670d-aebb-4e65-a90b-42b71cff135c (capture date unknown).
- [S7] Strong Help, Why do I need a Strong account? (updated 2021-09-21): https://help.strongapp.io/article/143-strong-account . Strong PRO (updated 2021-05-19): https://help.strongapp.io/article/132-strong-pro
- [S8] Boostcamp, 5/3/1 for Beginners program page ("enter your Training Max" during onboarding, built-in 1RM calculator; undated): https://www.boostcamp.app/coaches/jim-wendler/5-3-1-for-beginners
- [S9] Boostcamp blog, 5/3/1 for Beginners App & Program Guide (screenshots under a 2022-09-21 path): https://www.boostcamp.app/blogs/5-3-1-for-beginners-app-program-guide
- [S10] Reddit r/Boostcamp, 1RM vs TM label bug, 2023-07-04: https://www.reddit.com/r/Boostcamp/comments/14qmyyq/possible_bug_app_asking_for_1rm_but_uses_it_as/
- [S11] YouTube, HelloChen, "Is This The BEST FREE Fitness App... Boostcamp Review", published about 2026-08 (listed as "2 months ago"): https://www.youtube.com/watch?v=ffvAAQ3pt2c . Transcript read via TubeAlfred. Not watched.
- [S12] Liftosaur, Built-in Programs (undated, screenshot shows Sep 2026): https://www.liftosaur.com/features/built-in-programs
- [S13] Liftosaur, Program Editor and Liftoscript: https://www.liftosaur.com/features/program-editor , https://www.liftosaur.com/features/liftoscript (undated).
- [S14] Alpha Progression guide (undated): https://alphaprogression.com/en/blog/alpha-progression-guide . Reddit r/alphaprogression, dev reply 2026-09-01: https://www.reddit.com/r/alphaprogression/comments/1w3kdbh/app_beginner_question/
- [S15] Liftosaur, Import and Export (Hevy CSV): https://www.liftosaur.com/features/import-export (undated).
- [S16] Zealo, How to Import Your Trainer's Program, 2025-04: https://www.zealofitness.com/learn/import-trainer-program
- [S17] Repport home page (undated, marketing): https://getrepport.app/

## Gaps

- The phone captures in the brief weren't attached. Unit's flow, labels and tap counts all come from the brief's written description and were not checked on a device.
- The repo screenshot doesn't match the brief. The 2.1 asset shows "STEP 02 / 05" and "Add program" with "Paste routine" and "Choose program". The brief describes "Step 1 of 3, Choose your path". The brief says the asset is one build older. I trusted the brief.
- Mobbin capture dates are unknown for Hevy and Fitbod. Their onboarding, paywall and prices may differ in 2026. Unverified.
- No usable Mobbin flows for Strong, Boostcamp, JEFIT, Alpha Progression or Liftosaur. A Mobbin search for "Alpha Progression" returned other apps. Their screens come from help pages, blog images or docs.
- Boostcamp's 1RM screens are 2022 blog images. The current layout and wording are unverified.
- Strong's account and PRO pages date from 2021. I couldn't confirm the 2026 flow or whether Strong shows a paywall during setup (unverified).
- JEFIT: I only found its routine database (Workout > Find, "Set Plan"). I found nothing on its onboarding or import, so it's left out of the table.
- Zealo and Repport are small apps. Zealo's own guide says photo import may be missing in some builds. Repport's claims are marketing copy only.
- No competitor tap counts. I didn't count taps from install to the first set for any app. The screen counts (Hevy 18, Fitbod 39) are Mobbin captures, not taps.
- "Rest 90s becomes an exercise" (from the brief) has no row of its own. Liftosaur reads "90s" as rest (DOCUMENTED), and the same parser work as row 3 would cover it.
- How Unit's "Programs for you" explains a pick, beyond the "Best match" badge, isn't described in the brief, so I didn't compare it.
- AI plan builders (HevyGPT, the Liftosaur MCP) are excluded from the ranking, per the brief.
