# Unit — Goals

> Measurable targets for v1. Source of truth: `product-compass.md`.

---

## Primary KPI

**Seconds per set logged** — the time from the moment the user is ready to log a set to the moment it's recorded. Target: ≤ 3 seconds for a last-time set (one tap, no typing).

---

## Core experience targets

| Goal | Target | How we measure |
|------|--------|----------------|
| **Gym Test** | Log a set in ≤ 3 seconds under physical stress | Manual QA: one-handed, sweaty-finger simulation on device |
| **Taps to start** | ≤ 2 taps from app launch to first set logged | Count: open → tap Start → tap Done |
| **Last-time hit rate** | > 90% of sets logged without keyboard | Analytics: % of sets where weight and reps match the last-time pre-fill exactly |
| **Template creation** | < 2 minutes for any path (paste, redo, manual) | Manual QA: time each onboarding flow end-to-end |
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

## v1 scope boundaries

**Ships:**
- Template-based logging with Last time pre-fill
- Three onboarding paths (text-paste, redo-from-history, manual builder)
- Auto rest timer with Lock Screen / Dynamic Island
- History view (list + calendar)
- Exercise library with search and custom exercise creation
- Haptic confirmation on set logged
- PR detection and notification

**Does not ship:**
- ProgressionEngine (auto-increment, fail modes, deload)
- CloudKit sync
- Social features (feed, profiles, sharing)
- Exercise discovery / recommendation
- Subscription paywall on core logging

---

## Design constraints (always active)

- Swift 6, SwiftUI, SwiftData, local-first
- Atomic design system (`DESIGN_SYSTEM.md`) — no raw values in view files
- Light-first, follows system appearance
- 44×44 pt minimum touch targets
- No chevrons anywhere in the app
- Every screen uses `AppScreen` wrapper
