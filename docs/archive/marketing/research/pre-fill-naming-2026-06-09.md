# Pre-fill feature naming — research + decision (2026-06-09)

> Why "Ghost values" became **"Last time"**, and the positioning wedges it opens.
> Decision recorded in `docs/decision-log.md` (2026-06-09). Paired feature: the cold-start seed-from-paste fix (same date).

**The question.** What should Unit call the feature where starting an exercise pre-fills each set's weight + reps from the last session (now also from a pasted program on day one)? "Ghost values" felt unclear. Two independent research scans + a scored naming workflow answered it.

---

## Decision

- **In-app label: "Last time."** The inline metric already renders "Last 60kg" / "Last BW", so this is consistent, not new.
- **Confirm button: "Same as last time."** Weak as a standing label, strong as a one-tap confirm.
- **No coined proper noun.** Describe the feature in plain first-person sentences everywhere. Don't replace "ghost" with another metaphor.
- **Don't ship "Previous"** — clear, but it's the generic category word Hevy / Strong / Boostcamp already own; zero wedge.

---

## Scan 1 — how competitors market it

| App | In-app label | Marketing treatment |
|---|---|---|
| **Hevy** | "PREVIOUS" column (verified) + "Previous Workout Values" | **Headline** — dedicated feature page + help docs. Most explicit in the category. |
| **Strong** (market leader) | "Previous" column | **Never marketed** — absent from App Store listing + landing page. |
| **Boostcamp** | "previous column" → "auto-fill" | Buried efficiency tip. |
| **Jefit** | "Pre-fill Value" (branded setting) | Settings-level. |
| **Setgraph** | "pre-fills your last set's numbers" | Semi-headline; tightest benefit copy ("makes it obvious what you need to beat"). |
| **Fitbod** | reframes as AI **"recommended"** | Algorithm-forward — Unit's anti-persona. |

- Category noun for the displayed reference = **"Previous."** Verb for the action = **"pre-fill / auto-fill."**
- **No competitor uses "ghost," "remembers," "carries over," or "pick up where you left off."** "Ghost" is unclaimed but unvalidated.

## Scan 2 — how lifters actually talk (reviews / forums)

Reddit was unreachable; quotes are from App Store / Play reviews + review aggregators.

| Phrase lifters reach for | Frequency |
|---|---|
| "previous" (workout / session / values) | ~9 |
| "last time" / "last week" / "what I did last" | ~7 |
| "remembers" / "holds" / "keeps" | ~6 |
| "pre-fill / auto-fill / populated" | ~6 (developer/review vocab, **not** lifter-spoken) |
| "ghost" | **0** |
| "carries over" | **0** |

Frustration in apps that *lack* it: *"having to go back to previous workouts in the calendar just to see what weight I was at"*; *"I have to constantly change the weight of an exercise I've done a thousand times."* Core sentence: **"I shouldn't have to remember or re-type what I already did"** — which is the Gym Test almost verbatim.

## Naming workflow — scored candidates

12 candidates, each scored 1–10 on clarity-under-fatigue, lifter-vocabulary, brand-voice, distinctiveness, inline-label fit, then an adversarial "does it beat the proven baseline 'Previous'?" test.

| Rank | Candidate | Total | Beats "Previous"? |
|---|---|---|---|
| 1 | **Last time** | 39 | **Yes** — only candidate that did |
| 2 | Previous (baseline) | 37 | — (it's the thing to beat) |
| 2 | Last session | 37 | No |
| 4 | Remembered | 35 | No (good marketing word, weak label) |
| 4 | From last time | 35 | No |
| 6 | What I lifted | 33 | No (great voice, slow to parse) |

"Last time" won because it's the lifter's spoken phrase, reads as personal memory not an algorithm's recommendation, and matches the app's existing "Last 60kg" inline rendering. Rejected: "Last week" (lies on deloads/rest weeks), "Last set" (collides with the set finished 90s ago).

## Positioning wedges (ranked)

1. **Day one — "On day one I already know your numbers."** Paste a program and Unit reads the weights out of it; first session is already filled in. **No competitor can claim this** — their "previous" column is empty until you've logged a session. Enabled by the seed-from-paste fix.
2. **Anti-AI — "My own history, not a recommendation."** Directly attacks Fitbod hiding the same data behind "AI recommended."
3. **Incumbent jab — "The feature Strong has and never mentions."** Honest, on-brand; reframes the leader's strongest hidden feature as Unit's headline.

Do NOT: coin a new metaphor, ship "Previous," use "pre-fill / auto-fill" in headlines, or market it as "smart / AI / recommended." Don't claim Strong lacks the feature — they have it and hide it.

## Rename scope (audit)

"Ghost" spans two unrelated domains:
- **`AppGhostButton` / `AppGhostButtonLabel`** — a quiet button *style*. **Do not rename** (pure churn across 6 view files, design-system-drift risk).
- **"Ghost values"** — the pre-fill feature. Changes here: ~3 user-facing copy sites, ~45 doc/comment mentions, and one optional internal `metricIsGhost` → `metricIsPreFilled` (behaviour-identical, fine to leave). Historical / append-only records (decision log, compass decision-log rows, dated plans) left intact.
