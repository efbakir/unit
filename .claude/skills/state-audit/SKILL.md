---
name: state-audit
description: Codebase-wide audit for the bug class where view-local SwiftUI `@State` holding user-entered data is lost on navigation back/forward, sheet dismiss/re-present, app backgrounding, or force-quit. Use whenever the user asks to "audit state", "find state-loss bugs", "what edge cases am I missing", "release prep", "check before App Store", "find sheets that lose drafts", "find keyboard overlap issues", or asks about preventing the kind of regression where typed text disappears after navigation. Trigger proactively before any TestFlight or App Store submission. Pairs with `docs/release-qa.md` (the manual on-device gauntlet) — this skill is the code-level backstop.
---

# /state-audit

Code-level sweep for the bug class that the on-device gauntlet (`docs/release-qa.md`) catches manually. Read every screen with user input and flag any view-local `@State` that won't survive the lifecycle events Unit users hit constantly: nav back/forward, sheet dismiss/re-present, backgrounding, force-quit.

## When to use

- Before every TestFlight or App Store submission.
- After any large refactor of `OnboardingFlow`, `ActiveWorkoutView`, or any sheet-based flow.
- After CLAUDE.md updates that change navigation or persistence patterns.
- When the user says any variant of "what else am I missing" before shipping.

Do **not** use for:
- Single-screen visual reviews → `/page-audit`.
- New-component decisions → `/component-reuse-check`.
- Visual verification → `/ui-visual-verify` (user-invoked only).

## Sources of truth (read in this order)

1. `CLAUDE.md` §6 verification, §1 session-start (which docs matter).
2. `docs/release-qa.md` — the manual gauntlet; this skill is its code-level pair.
3. `Unit/Features/Onboarding/OnboardingView.swift` — the canonical pattern: `OnboardingFlow` uses `.id(step)` so every step view is destroyed/recreated; state lives on `OnboardingViewModel` + `OnboardingPreferences`.
4. `Unit/Features/Today/ActiveWorkoutView.swift` — known hotspot for sheet drafts and rename alerts.
5. `Unit/Features/Templates/*.swift` — sheet-based add flows.
6. `Unit/UI/DesignSystem.swift` — `AppScreen`, `AppTextEditor`, sheet primitives.

## Process

### 1. Grep for the bug class

Run these searches across `Unit/Features/`:

```
grep -rn "@State private var .*= \"\"" Unit/Features/
grep -rn "@State private var .*: String" Unit/Features/
grep -rn "TextEditor\|TextField" Unit/Features/
grep -rn "usesOuterScroll: false" Unit/Features/
grep -rn "\.sheet(" Unit/Features/
grep -rn "\.id(" Unit/Features/
```

Cross-reference results. The dangerous combinations are:

| Pattern | Risk |
|---|---|
| `@State` holding a `String`/`Int`/`Bool` bound to a `TextField`/`TextEditor`/`Toggle` | Data loss on view dispose |
| `@State` in any view rendered inside `OnboardingFlow` (anything reachable from `OnboardingView.swift`'s `stepView`) | Resets on every back/forward |
| `@State` in a `.sheet { }` content view holding user-entered data | Resets on swipe-dismiss + re-present |
| `usesOuterScroll: false` on `AppScreen`/`OnboardingShell` combined with `TextEditor` or `TextField` | Keyboard pushes customHeader under nav bar |
| `.id(value)` on a view containing `@State` | Resets when `value` changes |

### 2. Triage each finding into 4 buckets

- **CRITICAL — silent data loss**: user-entered data discarded with no warning, no recovery path. Block on this for App Store.
- **HIGH — visible state loss**: user-entered data discarded but obvious (sheet closes, screen reloads). Annoying, not catastrophic. Fix before release.
- **MEDIUM — papercut**: ephemeral state that should reset anyway but is doing so at the wrong moment.
- **LOW / nit**: notes for the next refactor.

For each finding, write **one line** with `file:line` + description + repro steps. Skip anything you can't pin to a specific file and line.

### 3. Propose fix layer

Per CLAUDE.md §5, every bug has a natural fix layer. The choices:

- **Lift to `OnboardingViewModel`** — for onboarding step state. Persist via `OnboardingPreferences.save/load`.
- **Lift to a per-screen `@Observable` view-model owned by the parent** — for active workout and template editing.
- **`@AppStorage`** — for anything that must survive force-quit (settings, hints, one-shot flags).
- **`Unit/UI/DesignSystem.swift`** — for layout/keyboard/chrome issues that show on >1 screen. Never fix at the screen.

State the fix layer in each finding. Do not write the fix in this skill — surface findings only.

### 4. Reuse the audit-agent prompt

For deeper sweeps (especially across `Features/Today/`, `Features/Templates/`, `Features/History/`, `Features/Settings/`), spawn an Explore agent with this exact prompt skeleton:

```
You are auditing the Unit iOS app for state-loss and edge-case bugs.
Onboarding uses OnboardingFlow with .id(step) so each step view is
destroyed and recreated on every back/forward. Same pattern shows up
in sheets and any .id()-keyed view.

Audit categories — search across Unit/Features/:

1. View-local @State holding user-entered data lost on nav, sheet
   dismiss, or tab switch.
2. Keyboard / usesOuterScroll: false combinations with text input.
3. Persistence gaps — fields in memory only with no UserDefaults/
   SwiftData backing.
4. App-lifecycle blind spots (background, force-quit, atomic commits).
5. Empty / max data edges.

Output format:
## CRITICAL — user data loss
## HIGH — visible state loss
## MEDIUM — papercuts
## LOW / nits

One line per finding with file:line. Skip anything not pinnable to a
file. Note categories that turn up clean ("No issues in X").
Under 600 words.
```

### 5. Report

Final output to the user:

1. **Findings table** (CRITICAL / HIGH / MEDIUM / LOW with file:line).
2. **Recommended fix layer** per finding (one of the four above).
3. **What turned up clean** (so the user knows scope was covered).
4. **Triage prompt**: "Want me to fix the CRITICAL ones now, or land all of them as a batch after you've seen them?"

Do not auto-fix. Findings are the deliverable; the user triages.

## Out of scope

- Visual / design-system audit → `/page-audit`.
- Atomic-write correctness of `commit()` and Core Data / SwiftData persistence — read `docs/release-qa.md` §4 and verify on device.
- App Store review guideline compliance — separate checklist.
- Performance / large-data-set profiling — Instruments, not this skill.

## Background — why this exists

This skill was created after a paste-step regression (`OnboardingProgramImportView` lost the user's typed text on back-navigation because `pastedText` was view-local `@State` instead of living on `OnboardingViewModel`). The bug was unobservable from reading the code — every test that mounted the view fresh worked. The only way to catch it was to actually navigate back. Same bug class lives anywhere `@State` holds user input inside a destroy-and-recreate-on-event surface.

The on-device gauntlet (`docs/release-qa.md`) catches this by walking it on a real device. This skill catches it by reading code. Run both before release; they cover different blind spots.
