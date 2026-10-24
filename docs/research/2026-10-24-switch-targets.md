# Who Unit wins users from, 2026-10-24

Which big gym apps Unit should take users from, what Unit is aiming for, who the target user is, and a prompt to find the feature gaps.

## Answer first

- First target: **Strong** users. Same job (follow a set routine, log fast), same yearly price ($29.99), and Strong is the only big logger with no next-weight suggestion.
- Next: **Notes and spreadsheet loggers**, then **Hevy** users who want fewer taps and no feed.
- Then people who already pay for progression apps: **Fitbod, Alpha Progression, MacroFactor Workouts**. Unit costs less than half as much per year.
- Progression is no longer unique. Hevy Pro (since 2026), Alpha Progression, MacroFactor Workouts, Boostcamp Pro, StrongLifts and JEFIT Elite all suggest next weights. Unit's edge is the mix: one tap per set, a target the lifter accepts with a written reason, paste from Notes, no account.
- The biggest switch blocker is history. Hevy solved it with "Import Strong CSV". Unit has no import, no export and no Apple Watch app.
- Unit has 0 US App Store ratings today (version 2.0). Every app below has thousands.

## Unit's goal

- Product: the fastest, most trustworthy progression-guided gym logger ([product-compass.md](../product-compass.md)).
- North star: seconds per set logged, 3 seconds or less. Over 90% of sets logged without the keyboard ([goals.md](../goals.md)).
- Retention: day 1 over 60%, day 7 over 40%, day 30 over 25% ([goals.md](../goals.md)).
- Money: $11k MRR, about 4,400 yearly subscribers at $29.99 before fees and churn ([pricing.md](../pricing.md), locked 2026-06-17).

## Target user

- Beginner to experienced gym user who follows a set routine, ready-made or their own ([PRODUCT.md](../../PRODUCT.md)).
- Logs today in Notes, a paper notebook or another tracker. Wants speed and clarity, not feeds and dashboards.
- Uses the app mid-workout: tired, one hand, sometimes 30 seconds between sets. Opens it for 2 to 5 seconds, again and again.
- Three types ([use-cases.md](../use-cases.md)):
  - Architect: runs their own split from Notes, wants the numbers and the next target.
  - Grinder: trains by feel, wants to log and leave.
  - Recoverer: back after a break, wants a calm restart.
- Not the target: people who want form videos, AI-made plans, coaching, feeds or competition.

**What lifters say (Reddit, 2025 to 2026)**
- They expect free logging. One lifter deleted 5 apps in one sitting because each was "a free trial pretending to be a free app" (r/WorkoutRoutines, 2026-03-10).
- Notes is a real rival: "My favorite workout app is 'Notes'" (same thread).
- Hevy users asked for automatic progression: "Most important missing feature" (r/Hevy, 2025-11-04). Another wrote out double progression step by step. Hevy then shipped it as a paid feature.
- Taps hurt: "My biggest concern is all of the taps just to get through a workout" (r/Hevy, same thread).
- Other asks in that thread: different rest times for warm-up and heavy sets, one weight filled into every set, reorder sets, faster weight entry on the Watch, CSV import, Garmin.
- A long-time Strong user moved to Hevy because Strong's Watch sync "was so buggy" (r/WorkoutRoutines).

## The big gym apps

US App Store ratings count, read 2026-10-24 from Apple's public search API. It shows US iPhone reach, not downloads or revenue.

| App | US ratings | Model and US price | Next-weight suggestion | Fit as a source |
|---|---|---|---|---|
| Fitbod | 288,145 | No free version. $12.99 to $15.99/month, $79.99 to $95.99/year | Yes, in generated workouts | Med: people tired of random workouts |
| Strong | 108,539 | Free with 3 routines. PRO $4.99/month, $29.99/year, lifetime offered | No | **High** |
| Hevy | 99,683, and 17+ million users worldwide | Free with 4 routines and 3 months of stats. Pro $2.99/month, $23.99/year, $74.99 lifetime | Yes, Pro only ("Hevy Trainer") | High, if Unit is faster and calmer |
| StrongLifts 5x5 | 76,872 | One-program app. Pro $59.99/year | Yes, automatic | Med: people who outgrow 5x5 |
| JEFIT | 46,921 | Free. Elite $12.99/month, $69.99/year | Yes, Elite | Low: library and video fans |
| Boostcamp | 10,675 | Free program library. Pro $14.99/month, $59.99/year | Yes, Pro ("Auto-progression") | Med: named-program followers |
| MacroFactor Workouts | 4,803 (launched 2026-01-12) | Trial, no free tier. $11.99/month, $71.99/year | Yes, automatic | Med: already pays for progression |
| Alpha Progression | 2,237 | Free logging. Pro $12.99/month, $79.99/year | Yes, Pro, per set | Med: already pays for progression |
| **Unit** | 0 (version 2.0) | Hard paywall. $2.99/week, $4.99/month, $29.99/year, $44.99 lifetime | Yes, double progression the lifter accepts | |

- Not sources, different job: Ladder (212,119 ratings, coach-led classes), Liftoff (100,155, ranked and social), Peloton, Nike Training Club.
- New and small, same idea as Unit: Kova (May 2026, rule-based targets with a reason, $49.99/year) and GymNote+ (Nov 2025, turns Notes into workouts).

## Where to win users from, in order

1. **Strong users.** Same job, same yearly price. Strong shows no next weight and caps free users at 3 routines.
   - What stops them: Apple Watch app, plate and warm-up calculators, years of history.
   - Bridge: import Strong's CSV export.
2. **Notes and spreadsheet loggers.** Unit's paste path is built for them.
   - What stops them: free beats paid. The 7-day trial has to show a saved target filling a set.
3. **Hevy users who want less.** No feed, fewer taps, a suggestion with a reason.
   - What stops them: Hevy is cheaper and has a free tier, a Watch app, supersets and warm-up sets.
   - Bridge: Hevy exports CSV.
4. **Progression-app payers** (Fitbod, Alpha Progression, MacroFactor Workouts). Unit costs less than half per year and keeps their own program.
   - What stops them: no RPE or RIR, fewer features.
5. **Named-program followers** (Boostcamp, StrongLifts). 27 ready-made programs plus paste.
   - What stops them: percent-based programs such as 5/3/1 get no suggestions.

## What this means for the next features

- Build the bridge first: history import from Strong and Hevy CSV. Without it, years of data keep people where they are.
- Close the gaps Strong and Hevy share: Apple Watch, warm-up sets, supersets, set notes, export, Apple Health.
- Keep the edge: one tap per set, the reason behind each target, no account.
- The prompt below ranks these gaps with evidence.

## Gap benchmark prompt

Paste it into the Grok bot or a Claude chat with web search. No attachments needed. It ranks the features Unit skips on purpose too, marked "yes" in the "Skipped on purpose today" column.

```text
Research the feature gaps between my iOS app, Unit, and the biggest gym logging apps. Goal: a ranked list of features Unit should add so lifters can switch to it, each in its simplest form. Unit stays simple: every addition must keep a set at 3 seconds or less, one hand.

ABOUT UNIT
- iOS gym logger for people who follow a set routine: their own, a coach's, or a ready-made one. Beginner to experienced.
- Used mid-workout: tired, sweaty, one hand, 30 seconds to 3 minutes between sets. The phone goes back in the pocket after every set.
- North star: seconds per set logged. Target: 3 seconds or less, one tap, no typing.
- Constraints: iPhone only, portrait only, light mode only. All data stays on the phone. No account.
- Money: hard paywall right after setup, no free tier. Weekly $2.99, Monthly $4.99, Yearly $29.99, Lifetime $44.99. Monthly and Yearly have a 7-day free trial.
- Version 2.1 ships soon. The App Store page (id 6775008893) may still show the older version. Treat this prompt as the truth for Unit.

WHO UNIT WANTS TO WIN, IN ORDER
1. Strong users: same job and price, and Strong gives no next-weight suggestion.
2. People who log in the Notes app or a spreadsheet.
3. Hevy users who want fewer taps and no feed.
4. People who pay for progression apps: Fitbod, Alpha Progression, MacroFactor Workouts.
5. People who follow named programs: Boostcamp, StrongLifts.

WHAT UNIT HAS TODAY
- Logging: one tap per set with last time's numbers filled in, weight and rep steps on the number pad, undo, edit, bodyweight sets, skip, drag to reorder, "+ Add set", freestyle workouts.
- Rest: the timer starts by itself, "-30" / "+30" / "Skip", Lock Screen and Dynamic Island countdown (no buttons).
- Programs: paste a program as text, 27 ready-made programs matched by 3 questions, a program library with filters, weekday or rotation schedule.
- Progression: opt-in double progression per exercise. Shown when an exercise ends, saved by the lifter on the post-workout summary, with a written reason.
- History: list and calendar, PR tags, workout detail.
- Analytics: 4-week status, up to 3 main lifts with 12-week charts, best set, estimated 1RM, weight, reps and volume per exercise.

WHAT UNIT DOES NOT HAVE TODAY
- Apple Watch app, Apple Health, Strava, Garmin.
- History import from Strong or Hevy. Any export.
- Sync, web or a second device. No in-app backup.
- Warm-up sets, drop or failure sets, supersets, set notes, RPE or RIR.
- Swap or add an exercise inside a routine workout.
- Rest time per exercise or per set.
- Edit or delete a past workout.
- Body weight, body measurements, muscle-group stats.
- A screen to browse, rename or delete exercises.

COMPARE WITH
- Biggest by US App Store ratings: Fitbod, Strong, Hevy, StrongLifts 5x5, JEFIT.
- Program and progression apps: Boostcamp, Alpha Progression, MacroFactor Workouts.
- Skip coach, class and ranked apps (Ladder, Peloton, Nike Training Club, Liftoff). They do a different job.

WHAT TO DO
1. Build a feature matrix. Rows: features. Columns: the apps above plus Unit. Mark each cell Free, Paid or No. Use each app's own site, help center and App Store page.
2. Tag each feature Unit lacks, including the ones it skips on purpose today (list below):
   - Switch blocker: a Strong or Hevy user would not switch without it.
   - Expected: most big apps have it, and users notice when it is missing.
   - Nice to have.
3. Find demand for each gap: Reddit threads, App Store reviews, the apps' feature-request boards. Quote short phrases with link and date.
4. For each gap, describe the simplest version that fits Unit: one hand, 3 seconds per set, no new tab, few words. Say what to leave out.

ANSWER FORMAT (use exactly this, nothing before it)
1. Gaps, ranked by how much they stop people from switching, 15 to 25 rows. Rank the skipped features by the same rules, one row per line of the list below:
| # | Feature | Big apps that have it (free or paid) | Demand (quote, link, date) | Tag | Skipped on purpose today | Simplest Unit version | Leave out | Effort |
- Skipped on purpose today: "yes" for a line from the list below, else "no".
- Effort: S = copy or small layout change. M = new control, state or screen section. L = new feature, new screen or data model change.
2. Build order: the first 5 gaps to build, one line each, with the reason.
3. Do not copy: up to 5 things the big apps do that Unit should not, each with the reason.

FEATURES UNIT SKIPS ON PURPOSE TODAY (rank them like any other gap)
- Social: feed, following, sharing.
- Game features: leaderboards, streaks, badges.
- AI or generated workout plans, and exercise recommendations.
- Form videos.
- Plate calculator.
- Periodization: cycles, blocks, deload rules, RPE-based auto-adjusting.
- Dark mode.
- iPad and landscape.

RULES
- Evidence only. Each claim names the app's screen, setting or plan, with a source and date. If you cannot verify it, write "unverified".
- No generic advice. Never write "improve the UX" or "add more features". Name the feature and the change.
- Simple first. Prefer one control on an existing screen over a new screen.
- If you are not sure an app still works this way in 2026, say so.
- Plain English, short sentences.
```

## Sources

- Apple App Store search API, US ratings counts, read 2026-10-24: https://itunes.apple.com/search
- Hevy, About us (17+ million users), read 2026-10-24: https://www.hevyapp.com/about-us/
- Hevy Help Centre, 2026 features guide (free vs Pro, Hevy Trainer): https://help.hevyapp.com/hc/en-us/articles/33106320824727
- Hevy Help Centre, Hevy Trainer explained: https://help.hevyapp.com/hc/en-us/articles/38385724273047
- Hevy Help Centre, import Strong CSV and export: https://help.hevyapp.com/hc/en-us/articles/38001424401943
- Strong on the App Store (features, PRO prices): https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577
- StrongLifts 5x5 on the App Store ("Fully automated progression"): https://apps.apple.com/us/app/stronglifts-5x5-workout-plan/id488580022
- Boostcamp on the App Store ("Auto-progression sets your next weights"): https://apps.apple.com/us/app/boostcamp-workout-tracker/id1529354455
- MacroFactor Workouts on the App Store: https://apps.apple.com/us/app/macrofactor-workouts-tracker/id6737156524
- Kova, best progressive overload apps in 2026 (prices checked 2026-09-24; written by a competitor): https://www.kovalift.com/blog/best-progressive-overload-apps
- Garage Gym Reviews, best weightlifting apps (updated 2026-10-07): https://www.garagegymreviews.com/best-weightlifting-app
- r/Hevy, "What is Hevy missing? If anything?" (2025-11-04): https://www.reddit.com/r/Hevy/comments/1ont759/
- r/WorkoutRoutines, "Free workout apps that are actually worth the storage space in 2026" (2026-03-10): https://www.reddit.com/r/WorkoutRoutines/comments/1rpsqpu/

## Caveats

- Ratings count shows US iPhone reach only. It is not downloads or revenue.
- Prices come from App Store pages and reviews from mid to late 2026. Regional prices differ, and some apps list several prices per plan.
- Reddit quotes are single voices. Use them for direction, not size.
