# Progression decision needs — completed focused review

Small qualitative sample, not representative user research. Search results and
published reviews reveal hypotheses; do not treat frequency as prevalence.

## Evidence
- https://www.reddit.com/r/Hevy/comments/1twmxtm/target_reps_for_programmes/
  User confuses previous performed reps with intended programme targets.
- https://www.reddit.com/r/Hevy/comments/1s39sya/please_explain_this_like_im_a_toddler/
  Users ask whether shown reps are predictions or previous results; one ignores them.
- https://www.reddit.com/r/Hevy/comments/1wnbplo/can_someone_explain_the_weight_progression_logic/
  Unexpected lower recommendations undermine understanding/trust.
- https://apps.apple.com/us/app/strong-workout-tracker-gym-log/id464254577?platform=iphone&see-all=reviews
  Visible reviews value tracking and easy gym use; also report reliability issues.
- https://www.hevyapp.com/features/exercise-programming-options/
  Official flow preloads earlier set/weight/reps, with edits allowed.

## Applied decisions
Keep actual results, previous plan and proposed plan distinct. Labels are now
Previous target / Logged / Suggested target before acceptance, and Next target
after acceptance. This avoids calling an unaccepted suggestion the saved next
workout. Retain exact values, a short reason, Edit and explicit acceptance; no
bulk auto-accept, no hidden target mutation. Graphs and tables remain.

## Expanded competitor and review check
- https://help.strongapp.io/article/105-about-templates
  Strong distinguishes a reusable template from completed workout history.
- https://help.fitbod.me/hc/en-us/articles/29486697282711-Exercise-Details-Screen-Sets-Reps-and-Weight-Fields-Explained
  Fitbod documents editable weight/reps, history and what to do when recommendations do not fit.
- https://apps.apple.com/us/app/fitbod-gym-fitness-planner/id1041517543?platform=iphone&see-all=reviews
  Inspected visible reviews: users value reduced planning effort and seeing past/next work;
  complaints include undiscoverable set removal and linked edits changing other values.
  These are individual reports, not verified product defects or prevalence estimates.
- https://www.reddit.com/r/fitbod/comments/1ctzaz4/
  Search-index excerpt reports surprise when a weight-only request changes reps.
  Full thread fetch failed, so this is supporting context only, not independently read evidence.

## Applied outcomes
- Separate Previous target, Logged, Suggested target and saved Next target.
- Existing acceptance button says Use next workout, making its consequence explicit.
- One short reason remains visible; edited targets retain comparison evidence.
- Preserve manual edit, repeat previous target, per-exercise acceptance and persistence guards.
- Keep tables/graphs: reducing cognitive effort means aligning facts, not deleting them.
- No new prediction algorithm, auto-accept or unrequested metrics.

This bounded research pass is complete. It combines official workflows, saved
Mobbin screenshots, visible App Store reviews and user-discussion excerpts. It
is qualitative desk research, not observed usability testing or proof that the
new layout improves task completion. Runtime tests check behavior; founder review
on the phone checks visual usefulness. A future user study should ask users to
identify the proposed change, explain why, and predict what acceptance will save.
