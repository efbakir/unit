# Unit — Agent Guidance

Quick orientation for AI agents working on the Unit codebase.
**The authoritative source is [`docs/AGENTS.md`](docs/AGENTS.md) and [`CLAUDE.md`](CLAUDE.md).** This root pointer just sits where tooling expects to find it.

## What this project is

Unit is a **zero-friction gym logging tool** for iOS. The primary program unit is the **Template** — a lightweight repeatable routine. The core UI paradigm is **Last time** — the app pre-fills weight and reps from the last session so the user can log a set with a single tap.

The **Gym Test** applies: logging a set (weight, reps) in **under 3 seconds** under physical stress. `ProgressionEngine`, 8-week cycles, target-vs-actual UI, and weekly increment rules are **out of scope for v1** and have been removed from the codebase. See [`docs/claude/scope.md`](docs/claude/scope.md) for the full banned list.

## Tech stack

- **Swift 6** (concurrency-safe), **SwiftUI** (NavigationStack), **SwiftData** (local-first; no CloudKit in v1).
- **iOS 18+** (Live Activities for rest timer).
- **Swift Charts** — no third-party charting.
- **Geist / Geist Mono** bundled `.ttf` fonts.

## Where to look

| Topic | Location |
|-------|----------|
| Session-level intent (read first) | [`CLAUDE.md`](CLAUDE.md) |
| Product (persona, voice, principles) | [`PRODUCT.md`](PRODUCT.md) |
| Design system (palette, type, components, do/don't) | [`DESIGN.md`](DESIGN.md) + [`DESIGN.json`](DESIGN.json) |
| UX rules + scope fences (full) | [`docs/AGENTS.md`](docs/AGENTS.md) |
| Atomic layers + tokens + banned patterns | [`docs/atomic-design-system.md`](docs/atomic-design-system.md) |
| Visual language (light-first, hierarchy, Gym Test) | [`docs/visual-language.md`](docs/visual-language.md) |
| Compass (decisions, positioning, decision log) | [`docs/product-compass.md`](docs/product-compass.md) |
| v1 ships / does-not-ship + push-back phrasing | [`docs/claude/scope.md`](docs/claude/scope.md) |
| Apple HIG reference | [`docs/apple-hig.md`](docs/apple-hig.md) |
| Visual references library (iOS screenshots) | [`docs/references/`](docs/references/) |

## Project structure (current)

| Folder | Contents |
|--------|----------|
| `Unit/Models/` | SwiftData models: `DayTemplate`, `Exercise`, `WorkoutSession`, `SetEntry` |
| `Unit/Features/Today/` | `TodayView`, `ActiveWorkoutView`, `TrainingWeekProgress`, `RestTimerAttributes` |
| `Unit/Features/Templates/` | `TemplatesView`, `TemplateDetailView`, `AddTemplateView`, `ProgramLibrary*View`, `ProgramDetailView`, `ExercisesListView` |
| `Unit/Features/History/` | `HistoryView` (single list), `SessionDetailView`, `ExerciseProgressView` |
| `Unit/Features/Onboarding/` | Splash → import method → program-import → split-builder → exercises |
| `Unit/Features/Settings/` | `SettingsView` (weight unit, restart onboarding) |
| `Unit/Features/Subscription/` | `PaywallView` (one-time lifetime purchase, never gates core logging) |
| `Unit/Features/ProgramLaunch/` | Quick-start support |
| `Unit/UI/` | `DesignSystem.swift` — atoms, molecules, organisms, `AppScreen` template |
| `Unit/Resources/Fonts/` | Geist + Geist Mono `.ttf` |

## Critical rules

- **Light mode only.** No `.preferredColorScheme(.dark)`, no dark-first decisions. Tokens may carry dark values for system compatibility, but visual review and screenshots happen in light mode.
- **Portrait only.** No landscape support.
- **Last time** is the primary pre-fill mechanism. Look up the last completed session for the same exercise (any template) and pre-fill weight + reps. Never display "0 kg" — bodyweight shows "BW", and unseen exercises show "No history yet".
- **Templates are the program unit.** Not cycles, not weeks, not engines.
- **Adaptive appearance via tokens only.** Use `AppColor` / `AppFont` / `AppSpacing` / `AppRadius` / `AppIcon` from `Unit/UI/DesignSystem.swift`. No raw `Color(...)`, hex literals, `.font(.system(...))`, or hardcoded paddings/radii in feature code. The harness PreToolUse hook (`.claude/hooks/ui-banned-list.sh`) enforces this mechanically.
- **Reuse > extend > create.** Before any new `struct X: View` / `ViewModifier` / variant, grep `DesignSystem.swift` and run the [`/component-reuse-check`](.claude/skills/component-reuse-check/) skill. Parallel implementations are the #1 drift in this codebase.
- **HIG compliance:** all interactive elements ≥ 44×44pt; never color alone for meaning; honor `accessibilityReduceMotion`.
- **No social features, no exercise discovery feed, no algorithmic progression in core flow.**

## Conventions

- `Unit/UI/DesignSystem.swift` is the **only** place raw values live (`AppColor`, `AppFont`, `AppSpacing`, `AppRadius`, `AppIcon`). Add new tokens there. Geist / Geist Mono are reached only via `AppFont.*` cases — never `Font.custom("Geist…")` directly.
- `AppCardList(data) { row }` is the canonical list-in-card primitive. Never compose `AppCard { AppDividedList(...) }` by hand — the hook blocks it.
- Sheet roots are plain `VStack` with `presentationDetents`. No `ScrollView` or `AppCard` as the root child of `.sheet { }`.
- Toolbar chrome defers to iOS-native — no `.weight(...)` on `ToolbarItem` buttons.
- `appScrollEdgeSoft(top:bottom:)` is the single canonical fade-behind-bar modifier. Never inline a `LinearGradient` or `.mask` for the same effect.
