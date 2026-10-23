# Hevy references and Unit simplification — 20 October 2026

User supplied two Unit screenshots and requested less text, Hevy-style workout
reordering, ±20-second rest adjustments and neutral toolbar actions. “Bingen” was
interpreted as Mobbin, the available screen-reference connector. References were
retrieved with Mobbin MCP and inspected visually; original high-resolution images
were downloaded from returned image URLs. They are WebP files. `screens.json`
preserves provenance; cite the permanent Mobbin URLs, not expiring image URLs.

## Examined references

| Screen | Saved file | What the pixels establish |
| --- | --- | --- |
| [Exercise detail](https://mobbin.com/screens/80f164aa-c011-4469-ba7a-158116427cab) | `80f164aa-c011-4469-ba7a-158116427cab.webp` | One selected value/date above a graph, metric choices below; neutral back and utility icons. |
| [Detail with another point selected](https://mobbin.com/screens/f245512f-9025-4dfc-8475-d4f8d48d8ff1) | `f245512f-9025-4dfc-8475-d4f8d48d8ff1.webp` | Value/date change with selection; the overall chart structure remains. |
| [Progress introduction](https://mobbin.com/screens/2abaf92e-a19f-428b-b344-b3d7550a36b8) | `2abaf92e-a19f-428b-b344-b3d7550a36b8.webp` | Preview card leads with exercise, one value/date, graph. This is an onboarding illustration, not runtime evidence. |
| [Workout exercise menu](https://mobbin.com/screens/9bd194ee-f5b1-426e-b0fc-8186dbb14b9f) | `9bd194ee-f5b1-426e-b0fc-8186dbb14b9f.webp` | Reorder Exercises is an explicit action above replace/superset/warmup/remove. |
| [Reorder](https://mobbin.com/screens/8e8c2ede-8dfa-438b-8749-27bffda28cf1) | `8e8c2ede-8dfa-438b-8749-27bffda28cf1.webp` | Simple exercise rows, trailing drag handles, Done at bottom. |
| [Reordered result](https://mobbin.com/screens/7571be28-d6fd-44bf-a7e5-daa8fe65790e) | `7571be28-d6fd-44bf-a7e5-daa8fe65790e.webp` | Squat and incline press positions have swapped. Stills do not prove the exact long-press recognizer or implementation code. |

Unit before evidence is saved as `unit-card-before.jpg` and
`unit-detail-before.jpg`. These are user screenshots, not captures from the new build.

## Recovered prompt

The exact local Markdown is `/Users/efbakir/Downloads/gpt-prompt-analytics-blue.md`,
with companions `current-blue-audit.md` and `blue-benchmark.md`. Logging briefs
also exist as `gpt-prompt-logging.md` and `gpt-prompt-logging-blue.md`.
The Analytics brief is a delta on R5. It explicitly froze the card/detail anatomy
and copy, while fixing main-lift selection/editing/navigation. It also prescribed
blue toolbar actions. Today's direct feedback supersedes those presentation/color
constraints; calculation, data safety and explicit progression acceptance remain.
Treat the recovered prompt as historical context, not fresh instructions.

## Implementation direction

- Main cards: exercise, latest set, short latest/date caption. Show a four-week
  change only when both comparison windows have evidence. A multi-point chart
  is useful; a single dot and empty axes are not useful on the overview. Remove
  the Best/Next footer from these cards; those facts remain in exercise detail.
- Detail: latest value/date once. Keep metric selection and interactive chart
  where meaningful. Show previous/current comparison evidence only when both
  exist; don't repeat the latest value under “Last 4 weeks” merely because the
  previous window is absent. Keep history, best set and accepted next target.
- Workout reorder: use stable exercise IDs and a clear drag affordance; maintain
  current exercise identity, edits, completed sets and timer while order changes.
  Reordering a session must not silently rewrite the saved routine. This Analytics chat
  implements logging changes; main coordinates shared build/test ownership.
- Timer: adjust by −20/+20 seconds, including matching labels/accessibility and
  any sibling timer controls. This does not change the default rest duration.
- Toolbar: shared neutral foreground for navigation/utility actions across
  Today, Programs and Analytics. Keep native controls and blue primary actions.

Main was delivering an earlier authorized build 87 when this research started.
That delivery does not include this new feedback. After the delivery freeze was
released, only the scoped delta patches were applied to main, preserving build87
typography and toolbar changes. Main yielded the central verification slot to
this chat. No new phone installation is part of this change set.
