# Unit

**A zero-friction gym logger for athletes who already know how to train.**

Unit replaces the paper notebook and the Notes app with a tool that survives gym fatigue and earns its place on the dock through daily utility. The core paradigm is **Last time** — last session's weight and reps are pre-filled, and one tap confirms a set. The primary program unit is the **Template**, not 8-week cycles, not periodisation engines, not weekly increment rules.

Authoritative product / design docs:

- **[`PRODUCT.md`](PRODUCT.md)** — persona, voice, anti-references, design principles
- **[`DESIGN.md`](DESIGN.md)** — palette, typography, components, do/don't (mirrored machine-readably in [`DESIGN.json`](DESIGN.json))
- **[`CLAUDE.md`](CLAUDE.md)** — session-level intent doc for AI agents working on this repo
- [`docs/product-compass.md`](docs/product-compass.md) — live positioning decisions and the decision log
- [`docs/goals.md`](docs/goals.md) — measurable targets and v1 scope boundaries
- [`docs/AGENTS.md`](docs/AGENTS.md) — UX rules, product model, scope fences

## Tech stack

- **Swift 6** (strict concurrency)
- **SwiftUI** (NavigationStack, custom `AppScreen` template)
- **SwiftData** (local-first; no CloudKit in v1)
- **iOS 18+**
- **Live Activities** (rest timer on Lock Screen / Dynamic Island)
- **Swift Charts** (history sparklines, progress views)
- **Geist / Geist Mono** (bundled `.ttf` fonts in `Unit/Resources/Fonts/`)

## Project structure

```
Unit/
  UnitApp.swift              — App entry, ModelContainer
  ContentView.swift          — Root tab navigation + AppScreen wiring
  UI/
    DesignSystem.swift       — Atoms, molecules, organisms, AppScreen template (single file)
  Models/
    DayTemplate.swift        — Template (split + ordered exerciseIds + planned sets/reps)
    Exercise.swift           — Exercise (displayName, aliases, isBodyweight)
    WorkoutSession.swift     — Session (date, templateId, isCompleted)
    SetEntry.swift           — Set (weight, reps, rpe, isWarmup, isCompleted, setIndex)
  Features/
    Today/                   — TodayView, ActiveWorkoutView, TrainingWeekProgress, RestTimerAttributes
    Templates/                — TemplatesView, TemplateDetailView, AddTemplateView, ProgramLibrary*
    History/                  — HistoryView (single list), SessionDetailView, ExerciseProgressView
    Onboarding/               — Splash, import method, program-import, split-builder, exercises
    Settings/                 — SettingsView (weight unit, restart onboarding)
    Subscription/             — PaywallView, StoreManager
    ProgramLaunch/            — Quick-start affordances
  Resources/
    Fonts/                   — Geist + Geist Mono .ttf files
docs/                        — Product, design, references, claude/ intent spillovers
```

## Data model (SwiftData)

- **DayTemplate** — id, name, splitId, orderedExerciseIds, plannedSetsByExerciseId, plannedRepsByExerciseId, lastPerformedDate
- **Exercise** — id, displayName, aliases, notes, isBodyweight
- **WorkoutSession** — id, date, templateId, isCompleted
- **SetEntry** — id, sessionId, exerciseId, weight, reps, rpe, isWarmup, isCompleted, setIndex

**Rule:** Last-time values are computed at read-time from the most recent completed `SetEntry` for the same exercise (any template). They are never persisted.

## Out of v1 scope

The following were intentionally cut or deferred — see [`docs/claude/scope.md`](docs/claude/scope.md) for the full list:

- `ProgressionEngine`, auto-increment, deload rules → deferred post-v1
- 8-week cycles, `Cycle`, `WeekDetailView`, "Week N of M" → templates replace cycles
- Target-vs-actual weight columns → last-time pre-fill only
- Plate calculator, social / feeds / sharing, exercise discovery → not for this product
- CloudKit sync → local-first only
- Paywall on core logging → core logging is free

## Build and run

1. Open `Unit.xcodeproj` in Xcode 16+.
2. Select the **Unit** scheme and an iPhone simulator running iOS 18+.
3. Build and run (⌘R).

The **UnitWidgetExtension** target is built alongside the app and provides the rest timer Live Activity.

## License

Proprietary.
