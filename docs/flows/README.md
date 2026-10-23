# Unit flows

Every user flow in Unit 2.1 (build 94), how it works in code, and its edge cases. Written 2026-10-23 from the code, then updated for the fixes made the same day.

| Doc | Flows | Read when |
|---|---|---|
| [first-run-and-paywall.md](first-run-and-paywall.md) | Launch and routing, opener, path choice, paste import, ready-made programs, review, paywall, purchase, access refresh, Settings, review and feedback prompts, every analytics event | Changing setup, the paywall, purchases, Settings or analytics |
| [training-loop.md](training-loop.md) | Today, start workout, logging, rest timer, exercise done, finish, progression, History, Analytics tab, Programs | Changing anything a lifter touches after setup |

## How each flow is written

- Purpose, entry, steps (screen -> action -> result), saved data, events, edge cases.
- Edge case format: case -> what the app does -> risk (High / Med / Low) -> handled (yes / no / partial).
- Code links point at the file and line.

## Setup at a glance (build 94)

- Opener (2 s) -> carousel -> "Set up your program" ("Paid plan required after setup." under it).
- Step 1 of 3: I have a program / I need a program.
- Step 2 of 3: paste the program, or answer goal, experience and days, then pick a match (best match preselected).
- Step 3 of 3: review (weight unit switch here) -> Save program -> paywall.
- Taps to the paywall: ready-made 7; paste 4 plus the iOS paste gesture (2 to 3 taps).

## Still open (not fixed in build 94)

- "RPE 8" written before a number is read as 8 kg; junk rows can't be deleted on review.
- An ignored next-target suggestion only lives on in History.
- The "Workout from yesterday" check runs only on a cold launch.
- Ask to Buy: a declined request leaves the buy button grey until Restore or a relaunch.
- Full list with risk levels: the edge-case sections of both docs.
