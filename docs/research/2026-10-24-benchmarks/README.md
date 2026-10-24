# Benchmarks of Unit's main flows, 2026-10-24

Results of the 6 Grok prompts in [2026-10-24-benchmark-prompts.md](../2026-10-24-benchmark-prompts.md). Each report compares one Unit flow with similar apps (Hevy, Strong, Fitbod, Boostcamp, Liftosaur, Alpha Progression, JEFIT, Liftin', others) and ranks where Unit is weaker.

| # | Flow | Report | Top 3 the bot would ship |
|---|---|---|---|
| 1 | First-run setup | [1-first-run-setup.md](1-first-run-setup.md) | Say Pro is needed on step 1; list dropped lines on Review; stop reading RPE and % as weight |
| 2 | Paywall | [2-paywall.md](2-paywall.md) | Move the analytics switch off the paywall; History readable for lapsed users; real charge dates |
| 3 | Active logging | [3-active-logging.md](3-active-logging.md) | Live Activity buttons; rest per exercise; next-set numbers on the Lock Screen |
| 4 | Exercise done and summary | [4-exercise-done-summary.md](4-exercise-done-summary.md) | Keep unsaved suggestions as a one-tap chip; "Save all"; reason line on the done card |
| 5 | History and Analytics | [5-history-analytics.md](5-history-analytics.md) | Edit and delete past workouts; iCloud backup; inline PR tag |
| 6 | Feature gaps (switch blockers) | [6-feature-gaps.md](6-feature-gaps.md) | Build order: Strong/Hevy CSV import, CSV export, edit/delete past workouts, swap exercise, Apple Watch |

## Strongest signal across reports

- The trust layer: edit or delete a past workout, export, and import. It shows up in reports 1, 2, 5 and 6. Hevy and Strong both have it.
- Swap an exercise in a routine workout shows up in reports 3 and 6, and in both persona panels.

## Conflicts with recorded decisions (founder decides)

- Report 1, row 1 (say Pro is needed on step 1) reverses the founder's 2026-10-23 removal of "Paid plan required after setup.".
- Report 2, row 8 (Yearly for everyone) and row 9 ("Save 49% vs monthly") reverse the founder's 2026-10-23 choices (Weekly for customers without a trial, "Save 80%").
- Report 5, row 2 and report 6, row 7 (iCloud backup) conflict with the scope fence in `CLAUDE.md` §3 (CloudKit sync is post-v1).
- Report 4, rows 1 and 9 (a suggestion chip on set 1, a "+5 lb" tag on the exercise header) touch the rule "target-vs-actual UI during active logging" in `CLAUDE.md` §3. Accepted targets may prefill; the active set row stays unchanged.
- Report 2, row 2 (analytics switch on the paywall, on by default) is an App Review risk for the 2.1 submission. The switch was added in PR #5.

## Caveats

- No report used the apps hands-on. Evidence is Mobbin screens (mostly Hevy), help pages, App Store pages and reviews. Strong's help pages date from 2021 and 2022.
- Several reports worked from older Unit screenshots in the repo and trusted the prompt text instead.
- Reference boards (Mobbin images) are not stored in this public repo.
