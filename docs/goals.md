# Unit — Goals for version 2.1

> Measurable targets for version 2.1. Source of truth: `product-compass.md`.

---

## Primary KPI

**Seconds per set logged** — the time from the moment the user is ready to log a set to the moment it's recorded. Target: ≤ 3 seconds for a last-time set (one tap, no typing).

---

## Core experience targets

| Goal | Target | How we measure |
|------|--------|----------------|
| **Gym Test** | Log a set in ≤ 3 seconds under physical stress | Manual QA: one-handed, sweaty-finger simulation on device |
| **Taps to start** | ≤ 2 taps from app launch to first set logged | Count: open → tap Start → tap Done |
| **No-keyboard hit rate** | > 90% of sets logged without keyboard | Analytics: % of sets where weight and reps match an accepted target or Last time pre-fill exactly |
| **Progression trust** | 100% of accepted targets are explicit and idempotent | Test + manual QA: dismiss changes nothing; accepting twice never compounds |
| **Template creation** | < 2 minutes for either path (paste import, starter library) | Manual QA: time each onboarding flow end-to-end |
| **Session completion** | > 80% of started sessions reach "Finish" | Analytics: started vs finished sessions |
| **App launch to interactive** | < 500ms | Instruments profiling on baseline device |

---

## Retention targets

| Metric | Target | Rationale |
|--------|--------|-----------|
| **Day 1 retention** | > 60% | User created a template and logged at least one set on first day |
| **Day 7 retention** | > 40% | User returned and logged at least one session in the first week |
| **Day 30 retention** | > 25% | Sustained use; the app has replaced their previous method |

---

## v2.1 scope boundaries

**Ships:**
- Template-based logging with Last time pre-fill
- Two onboarding paths: text-paste import and starter program library
- Auto rest timer with Lock Screen / Dynamic Island
- History view (one chronological list grouped by month)
- Private Profile tab with completed-working-set analytics and exercise history
- Exercise library with search and custom exercise creation
- Haptic confirmation on set logged
- PR detection and notification
- Current access model follows `docs/pricing.md`: onboarding is free; post-onboarding app access is gated
- Opt-in double progression per routine/exercise
- Post-workout next targets with explanation, saved at Finish, with Keep previous target and Edit
- Saved-target prefill before Last time (set 1 of this routine's last workout, then any routine's)

**Does not ship:**
- Legacy ProgressionEngine behavior (cycles, fail modes, deloads, periodisation)
- CloudKit sync
- Social features (feed, public profiles, sharing)
- Exercise discovery / recommendation
- Manual-builder onboarding as a first-run path
- Redo-from-history onboarding as a first-run path

---

## Design constraints (always active)

- Swift 6, SwiftUI, SwiftData, local-first
- Atomic design system (`DESIGN.md`, `docs/claude/design-system.md`, `Unit/UI/DesignSystem.swift`) — no raw values in view files
- Light-only visual system
- 44×44 pt minimum touch targets
- No navigation chevrons for routine rows
- Every screen uses `AppScreen` wrapper
