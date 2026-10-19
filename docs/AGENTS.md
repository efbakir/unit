# AGENTS.md — Rules for AI agents working on Unit

> Read `docs/product-compass.md` before every task. Use `docs/goals.md` and `docs/claude/scope.md` for the release boundary, `docs/pricing.md` for access, `PRODUCT.md` for product and voice, and `DESIGN.md` for the visual system. If active sources conflict, stop and name the conflict.

---

## What Unit is (progression pivot, 2026-08-03)

Unit is a **zero-friction, progression-guided gym logging tool** for beginner-to-experienced gym users. People can choose a ready-made program or bring their own. The primary metric is **seconds per set logged**. Unit is not an AI coach, social platform, exercise-instruction product, or periodisation planner: it gives one transparent next-session suggestion while the user keeps final control.

**Core loop:** Open app → see today's template → tap Start → log sets with one tap each → finish.

---

## Architecture rules

| Rule | Detail |
|------|--------|
| **Language** | Swift 6, strict concurrency |
| **UI** | SwiftUI only. Every view uses the atomic design system (`DesignSystem.swift`). No raw values in view files. |
| **Data** | SwiftData, local-first. No network calls required for core functionality. |
| **Design system** | Read `DESIGN.md`, `docs/atomic-design-system.md`, and `Unit/UI/DesignSystem.swift` before creating or modifying any view. No exceptions. |
| **Screen wrapper** | Every screen uses `AppScreen`. No custom nav bars. |
| **No chevrons** | `chevron.right` and `chevron.forward` are banned everywhere except the system back button. |

---

## Product model (current)

| Concept | What it is now | What it is NOT |
|---------|---------------|----------------|
| **Template** | A lightweight, repeatable collection of exercises (e.g. "Push Day A"). Not bound to a week or cycle. The primary program unit. | Not an 8-week cycle. Not a periodisation plan. |
| **Session** | A single workout instance. May be linked to a template or freestyle. | Not a "Day" within a numbered week. |
| **Last time values** | Global fallback prefill from the most recent session for that exercise. | Not the same as an accepted progression target, which is scoped to one routine and exercise and takes precedence. |
| **Starting target** | Explicit sets, reps, and weight saved with the current template/program, used only when no accepted target or valid prior session exists. | Not completed history and never labelled "Last time". |
| **"No history yet"** | Shown only when no accepted target, valid prior session, or explicit starting value exists. Fields are empty; user fills in manually. | Not "0 kg". Never show 0 as a default. |
| **Rest timer** | Auto-starts on "Done" tap. Visible on Lock Screen and Dynamic Island. | Not optional / hidden. |
| **Cycles** | Retired legacy container; out of scope for v2.1. | Templates are the program unit. Do not restore week/cycle UI. |
| **DoubleProgressionEngine** | One pure, deterministic v2.1 calculator. It evaluates completed working sets and proposes the smallest next target after a workout. | Not the old cycle/failure/deload engine. It never mutates a routine before acceptance. |
| **Schedule** | Optional weekday assignment or flexible rotation that helps Today choose the next template. Editable after onboarding. | Not a cycle, mandatory calendar, or rigid program container. History remains list-only. |

---

## UX rules

- **Gym Test:** A user must be able to log a set in ≤ 3 seconds under physical stress.
- **One-tap Done:** The primary interaction is a large (44×44 pt minimum) "Done" button/checkbox. Haptic feedback on tap.
- **No keyboard for happy path:** An accepted target, Last time value, or Starting target keeps normal set logging one-tap. Keyboard only appears when the user explicitly edits a value.
- **≤ 2 taps to start:** From app launch to first logged set must be 2 taps or fewer (Today → Start → Done).
- **No social features.** No feed, no likes, no leaderboards, no sharing prompts.
- **No progression UI in the hot loop.** Suggestions and edits happen after the exercise or workout. Accepted targets prefill the next matching routine/exercise.

---

## Onboarding

Two first-run paths ship in v2.1:

1. **Text-paste import** — user pastes a routine from Notes/WhatsApp. Basic exercise name-matching builds a structured template.
2. **Starter program library** — user chooses a ready-made program and reviews it before saving.

Manual template editing remains available after onboarding. Redo-from-history
and manual-builder onboarding are not first-run paths in v2.1.

The schedule step supports weekday assignment or flexible rotation. Scheduling
guides Today; it does not create cycle/week structure or a History calendar.

---

## What NOT to build (v1 scope fences)

- CloudKit sync
- Exercise discovery feed
- Social / community features
- Progression algorithms beyond opt-in double progression (fail modes, deloads, periodisation, recovery adaptation)
- Mandatory cycle/week/day structure
- Changes to the current post-onboarding access gate (`docs/pricing.md`)
- Any feature that increases taps-to-log

---

## When in doubt

Ask: "Does this make logging a set faster or slower?" If slower, don't ship it in v1.
