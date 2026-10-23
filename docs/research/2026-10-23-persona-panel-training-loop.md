# Persona panel round 2: the main training flows, 2026-10-23

Synthetic test of Unit's training loop with Claude agents (MiroFish method, same 20 personas as [round 1](2026-10-23-persona-panel.md)). Treat it as hypotheses to check with real users, not as user research.

## Answer first

- Logging is fast when the number in the row is right. On set 1 it is often wrong, so about half of all sets need a reps edit (+3 s).
- Nobody stopped because a set was slow. People stopped over price (5 of 10 who stopped), a bad fit for strength programs, no export, and the stall.
- The biggest gaps: no swap in a routine workout (10 of 20 needed one), suggestions lost when the summary is skipped, and no way to fix History or export data.

## Setup

- God's-eye rule: all 20 start the 7-day trial, including those who left at the paywall in round 1.
- Timeline: workout 1 in detail, weeks 1 to 4, month 3.
- Events: busy gym (swap or reorder), wrong weight logged, missed reps, a missed week, a 3-session stall, phone locked between sets.
- Variable: T-A today ("Rest day" after training) vs T-B, not built ("Done today · Next: X", with suggested weights on Today's rows).
- Then a Reddit-style thread at week 5, where the founder announces 4 fixes in round 3, and 8 interviews at month 3.
- Product truth: [training-loop.md](../flows/training-loop.md) and the build-95 screenshots. Transcripts stay in the session scratchpad.

## Speed (target: 3 s per set)

- Median 3 to 5 s per set. 3 s happens only with the phone in hand, Unit in front, and the right number in the row: about 1 set in 4.
- What adds time:
  - Reps edits: +3 s on about half of all sets.
  - Locked phone or another app in front: +1 to 3 s on most sets. The Lock Screen timer has no button.
  - First set with no weight: 10 to 16 s.
  - Heavy top sets: 8 to 14 s.

## Checked in code

The main complaints match the code:

- Set 1 takes the last set of the newest workout with that exercise, from any routine. That is often the weakest set ([ActiveWorkoutView.swift:1275](../../Unit/Features/Today/ActiveWorkoutView.swift:1275)).
- Later sets copy the set just logged ([ActiveWorkoutView.swift:1243](../../Unit/Features/Today/ActiveWorkoutView.swift:1243)).
- In a routine workout, the exercise "..." menu has only Bodyweight and Skip. There is no swap.
- Skip on the last exercise does nothing after you confirm it ([ActiveWorkoutView.swift:967](../../Unit/Features/Today/ActiveWorkoutView.swift:967)).
- Sets store a note, but there is no field to type one.
- Export: the Settings row is hidden and has no code behind it ([SettingsView.swift:187](../../Unit/Features/Settings/SettingsView.swift:187)).
- Round 1 correction: the round-1 seed said "Export is in Settings". That was wrong, so the round-1 line "export works" does not count.

## Top problems

| # | Problem | Screen | Hit | Severity |
|---|---|---|---|---|
| 1 | Set 1 starts from the wrong number. Worst for top sets, 5/3/1 waves and a lift trained in two routines | Active workout, current row | All 4 segments (5 of 5 intermediates, 5 of 5 strength) | High |
| 2 | No swap in a routine workout. Skip on the last exercise does nothing | Exercise card "..." | 10 of 20 needed a swap | High |
| 3 | Suggestions are lost when the summary is skipped or only partly saved | Summary "Next time" | About 3 of 5 per segment | High |
| 4 | "Update routine with today's weights?" is unclear and appears even after reps-only edits | Finish dialog | 5 of 5 intermediates; beginners avoided it | Med |
| 5 | A wrong set can be fixed only during the workout. No edit in History, no export | History, Settings | Most | Med (High for trust) |
| 6 | Locked phone: no "Complete set" on the Lock Screen | Live Activity | About 15 of 20 | Med |
| 7 | A stall gets "Keep this target." 3 times and nothing else | Summary | Everyone who reached it | Med |
| 8 | No reason shown when progression is off (fixed reps, bodyweight) | Done card, summary | 4 of 5 intermediates | Med |
| 9 | "+30" changes every later rest, not just this exercise | Rest bar | 4 of 5 strength | Low to Med |
| 10 | No note or RPE on a set | Logged set | 3 of 5 strength | High for them |

## What people liked (keep it)

- The rest timer that starts by itself and follows to the Lock Screen.
- "Suggested next" the moment an exercise ends.
- One tap when the number is right, and set 2 copying set 1.
- Accepting a target stays a deliberate tap, with Edit.
- Small steps (+1 rep), no streaks, a calm return after a missed week.
- Light mode only.

## T-A vs T-B

- T-B was read right by 8 of 8, and 7 of 8 named it a top delight. People who skip the summary got more suggestions to the bar.
- Month-3 retention was the same on both (about 50%).
- T-B is only worth building with a one-tap save that fills set 1. Without it, 6 of 8 retyped the number, and one reflex tap logged a wrong set.

## Month 3 (role-play estimate)

- About 10 of 20 still train with Unit. The agents call this inflated.
- 4 of 5 intermediates never saw a saved target fill a set inside the 7-day trial, because each routine comes once a week. The core payoff lands after the paywall decision.

## Proposed changes (Efe decides)

| # | Change | Screen | Effort | Note |
|---|---|---|---|---|
| 1 | Set 1 fills the saved target, else set 1 of this routine row last time | Active workout | M | Biggest speed win. Set 2 keeps copying set 1. A lift twice in one routine anchors on its row. |
| 2 | Skip works on the last exercise | Active workout | S | Bug. |
| 3 | "Swap for today" in the "..." menu, using the existing exercise picker | Active workout | M | The lifter picks; no recommendations (scope). |
| 4 | Ask "Update routine with today's weights?" only when a weight changed, never for progression lifts | Finish | S | |
| 5 | Done card and summary say why there is no suggestion, with Edit | Done card, summary | S | Only where a rule was expected, to avoid noise. |
| 6 | Today: "Done today · Next: X" plus a one-tap save for unsaved suggestions | Today | M | A second place to accept a target. Needs Efe's okay. |
| 7 | CSV export in Settings > Data | Settings | M | Trust; Lifetime buyers ask for it. |
| 8 | "Complete set" on the Lock Screen | Live Activity | M | Reopens a "by design" call. |
| 9 | A note on a set | Logged set menu | S to M | The model already stores notes. |

Not recommended now:
- Stall or deload hint: CLAUDE.md §3 bans deload rules.
- RPE and percent loading: L effort, strength segment only.
- Dark mode: light only.
- Sharing client logs: social is out of scope.

## Caveats

- The same kind of model wrote the personas and read the app, so they share blind spots.
- All personas already wanted a logger. Real people convert and stay less.
- Numbers are role-play estimates. Use the ordering and the reasons.
