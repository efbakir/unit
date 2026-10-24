# Unit — Competitor pain points

> Competitor evidence that informs Unit decisions. This file does not expand the roadmap. `product-compass.md` and `goals.md` remain authoritative.

## 30-second read

- **Keep the primary promise:** Log each set in seconds.
- **Strengthen the second-order value:** Finish the workout knowing the next small progression step.
- **Progression boundary:** One opt-in double-progression suggestion, shown after the workout, explained, saved at Finish, and one tap to keep the previous target or edit.
- **Later trust work:** Clean export and explicit Apple Health sync.
- **Not Unit's wedge:** Stretch recommendations, cardio programming, social features, or exercise discovery.

## Priority map

| Priority | User problem | Unit response | Scope |
|---|---|---|---|
| **Now** | “What should I do next time?” requires thought | Transparent post-workout double-progression suggestion | v2.1 |
| **Now** | Previous performance is hard to use mid-workout | Last time or accepted-target prefill | v2.1 |
| **Guardrail** | Suggested loads can be confusing or impossible | User-defined increment, clear units, Edit or Keep previous target on the summary | v2.1 quality |
| **Later** | Export and sync exist but are not trustworthy | Clear boundaries, status, and usable output | Later |
| **No new scope** | Users want stretches matched to a plan | Custom exercises cover self-added mobility | Existing capability |

## 1. Progression must be transparent and optional

**Evidence:** An Alpha Progression user could not tell whether easy workouts were intentional, whether manual changes would break the algorithm, or how cardio affected it.

**Pain:** The app asks for trust without showing its reasoning. The user must either obey a doubtful target or override it blindly.

**Unit decision:**

- Evaluate double progression only after the workout.
- Explain the suggestion in one line.
- Let the athlete edit, accept, or dismiss it.
- Dismissal changes nothing; repeated acceptance never compounds.
- Keep progression controls out of the active set flow.

**Scope:** Core v2.1. Cycles, fail counters, deloads, readiness, and recovery adaptation remain out.

## 2. Every suggested load must be feasible

**Evidence:** An Alpha Progression user received a total-load suggestion that could not be assembled with the available dumbbells.

**Pain:** A mathematically valid suggestion becomes useless at the rack and weakens trust in future recommendations.

**Unit decision:**

- The athlete defines the increment per routine and exercise.
- Label weight and increment units clearly enough to prevent total-versus-per-hand mistakes.
- Let the athlete edit the saved target, or keep the previous one, on the summary.
- Do not add an equipment inventory or plate calculator in v2.1.

**Research check:** Test dumbbell exercises specifically. Add a loading-type model only if users still create infeasible targets despite clear configuration.

## 3. Previous performance must be immediately useful

**Evidence:** A user wanted to analyze progressive overload, but Alpha Progression's CSV reportedly required AI cleanup before it was workable.

**Pain:** The data exists, but the user cannot quickly turn it into the next lifting decision.

**Unit decision:**

- Show Last time values directly in the set row.
- Let an explicitly accepted target take precedence for the same routine and exercise.
- Make exercise history answer “What did I lift last time?” without a dense dashboard.

**Scope:** Core v2.1. Clean CSV export is Later.

## 4. Data ownership must feel real

**Evidence:**

- Alpha Progression's export was reportedly unusable without cleanup.
- A long-term user enabled Apple Health sync but could not tell whether historical workouts should transfer or whether sync had failed.

**Pain:** “Export” and “sync” create trust only when the user can see what moved, what did not, and why.

**Unit decision now:**

- Keep workout history reliable, local, and available offline.
- State plainly that cloud and Health backfill are not included.
- Avoid controls that imply unsupported transfer behavior.

**Later:**

- Export a predictable CSV with one row per set.
- For Health sync, state the date boundary, show status and errors, and prevent duplicate backfills.

## 5. Complete-session requests are real but not the wedge

**Evidence:** A request for stretches matched to the current plan received 14 upvotes.

**Pain:** Users experience lifting and mobility as one session and dislike switching tools.

**Unit decision:**

- Users may add mobility work through custom exercises.
- Do not add recommended stretches, videos, or an exercise-discovery surface.
- Reconsider plan-matched mobility only after repeated retention evidence.

**Scope:** No new v2.1 feature.

## Evidence ledger

| ID | Source | Signal | Research lead |
|---|---|---|---|
| AP-01 | `r/alphaprogression` — “Downloading progress” | Export required AI cleanup | `u/councilmom`, `u/Lautjelief` |
| AP-02 | `r/alphaprogression` — “Weight suggestions for exercises where the total weight is tracked” | Suggested load was not physically feasible | `u/rulonlisu` |
| AP-03 | `r/alphaprogression` — “Question from new user regarding workout intensity” | User could not understand or trust algorithm behavior | `u/Itsasmallmatter` |
| AP-04 | `r/alphaprogression` — “Sync Historical Workout Data” | Historical Apple Health behavior was unclear | `u/Significant_Leg_7335` |
| AP-05 | `r/alphaprogression` — “Feature request: Add stretch exercises” | Plan-matched stretching request; 14 upvotes | `u/rulonlisu` |

## What to research next

The current evidence validates progression guardrails, but it does not yet prove Unit's acquisition promise.

1. **Logging friction:** What makes a set take longer than three seconds to record?
2. **Setup friction:** Why do lifters abandon an app before completing their first routine?
3. **Progression value:** Does one clear next-session target create enough value to pay or switch?
4. **Switching trigger:** What failure would make an Alpha Progression user try Unit today?

## Evidence rule

For every new finding, record:

- **Outcome:** What was the user trying to do?
- **Failure:** What blocked them or required a workaround?
- **Cost:** Did it waste time, create doubt, or risk losing data?
- **Unit decision:** Now, Later, No, or Research-only?
- **Signal:** One request, repeated pattern, engagement, or explicit switching intent?

Public usernames are stored only for possible interview invitations. Do not automate outreach or send repeated unsolicited messages.
