# Unit — Product Compass

> Single source of truth for **what we believe**, **what we decided**, and **what's still open**.
> Read this before changing positioning, the website, or MVP scope.
> Update this file first — then cascade to downstream docs.

---

## Vision

A world where every lifter's training knowledge lives in a tool as fast and trusted as their own memory — not locked behind algorithms, social feeds, or subscription gates.

## Mission

Build the fastest, most trustworthy gym logging tool for intermediate-to-advanced athletes. Replace the paper notebook and the Notes app with something that respects the lifter's expertise, survives gym fatigue, and earns its place on the dock through daily utility.

## Values

| Value | What it means in practice |
|-------|---------------------------|
| **Speed over features** | Every design and engineering decision is judged by its impact on *seconds per set logged*. If a feature adds friction, it waits. |
| **Athlete autonomy** | The lifter decides what to lift, when to progress, and how to structure their training. We show history, not instructions. |
| **Invisible UI** | The best interaction is one the user doesn't notice. Last time pre-fill, haptic confirmation, auto-timers — the app anticipates, not interrogates. |
| **Local trust** | Data lives on-device. No account required, no cloud dependency at v1. The app works in airplane mode, in a basement gym, always. |
| **Honest simplicity** | No hype, no dark patterns, no social pressure. The voice is direct, the interface is quiet, the product earns attention through utility. |

---

## User segment

**Primary:** Intermediate-to-advanced lifter (1–10+ years training) who already knows their program. They follow a structured routine — written by a coach, copied from a community, or self-designed — and need a tool to *execute and track*, not to be *told what to do*.

**Defining behaviours:** Trains 3–6×/week. Currently uses a Notes app, paper notebook, or a tracker they've outgrown. Has abandoned at least one "smart" app because it was too slow, too rigid, or too noisy. Values speed and control over recommendations and community.

**Anti-persona:** The beginner who needs guidance on *what* to do. The social lifter who wants likes, leaderboards, or community feeds. These users may find value in Unit eventually, but v1 is not designed for them.

---

## Pillars

| Pillar | Current intent |
|--------|----------------|
| **North star** | **Fast, trustworthy logging under fatigue.** Success metric: *seconds per set logged*. We fill the "notebook gap" — faster than paper, smarter than Notes, zero complexity fatigue. Progression insight is a reward for logging, not a prerequisite. |
| **Non-negotiables** | Gym Test (≤ 3s per set under stress) · Last time (pre-filled from last session) · Local-first · No social feed · One-tap "Done" (44×44 pt min) · Haptic confirmation · Auto rest timer with Lock Screen / Dynamic Island |
| **MVP boundary** | **Log + template path ships v1.** Templates are lightweight repeatable routines, not bound to weeks or cycles. `ProgressionEngine` deferred to post-v1. Onboarding: text-paste import, redo-from-history, manual builder. |
| **Voice** | Utility-first, direct, no hype. No competitor-framed copy. *"Faster than paper. Smarter than Notes. Your gym notebook, upgraded."* |

---

## Decision log

| Date | Decision | Rationale | Supersedes |
|------|----------|-----------|------------|
| 2026-03-26 | **Primary promise is zero-friction logging**, not auto-adjusting coach | "Complexity fatigue" + "notebook gap" research: intermediate+ lifters default to Notes apps. Open space = Zero-Friction Execution Engine. | "Adaptive Periodization Engine" narrative |
| 2026-03-26 | **8-week cycles demoted** to optional layer | Rigid scheduling frustrates users who miss days. Templates replace cycles as primary program unit. | "8-week cycle as main container" |
| 2026-03-26 | **Algorithmic overload rules removed from v1** | Auto-suggestions feel like a black box to veterans. History-as-guide via ghost values instead. | Engine rules (hit→increment, miss→repeat, 3 misses→deload) |
| 2026-03-26 | **Hero headline leads with speed/utility** | Website + App Store copy lead with notebook gap, not engine. Engine story returns as secondary once logging speed is validated. | "The only gym logger that auto-adjusts your 8-week plan" |
| 2026-03-26 | **Three frictionless onboarding paths** | Text-paste import, redo-from-history, manual builder. Solves "15-minute setup" retention killer. | Full 8-week cycle configuration upfront |
| 2026-03-26 | **Active Workspace is the UX centre** | Today → Start → Log in ≤ 2 taps. Session screen is where the user lives. | Program-tree navigation to reach a day |
| 2026-03-26 | **Rest timer auto-starts on Done**, visible on Lock Screen / Dynamic Island | App is minimised between sets. Timer must follow the user outside the app. | — |
| 2026-03-26 | **All three template import options ship in v1** | Text-paste, redo-from-history, manual builder. | — |
| 2026-03-26 | **Ghost value cold start: empty + global lookup** | Never logged → empty fields with "No history yet". Logged anywhere (any template) → ghost fills globally by exercise. | — |
| 2026-04-28 | **Paywall strategy: deferred presentation; gates power-user features only** | Phase 0 (TestFlight): no paywall surfaces, retention validation only. Phase 1 (App Store launch, Weeks 1–4): free for everything, one quiet "Unit Pro is coming" Settings card collecting founding-member intent locally. Phase 2 (Week 5+, conditional on ≥30 users at 3+ sessions/wk for 2 wks): paywall flips, gating off-Gym-Test features only — CSV + Markdown export, Apple Health sync, custom app icons, custom template accent colors, founding badge. Pricing locks at $4.99 / $29.99 / $44.99 (Liftosaur parity) with $19.99/yr win-back, per `docs/pricing.md`. Resolves the `pricing.md` ↔ `launch-plan.md §2` conflict. | $9.99/$49.99 proposal in `launch-plan.md §2`; the prior `pricing.md` Pro-gate list (template-count cap, 30-day history cap, PR detection, widgets) which would have violated `docs/claude/scope.md` line 77 |

---

## Open questions

- **Progression Engine resurrection:** When does auto-adjustment return? Opt-in "Coach mode"? v2 headline? Permanently shelved?
- **Data model migration:** Cycle → Week → Day schema needs to support unbound templates without breaking existing data.

---

## Prior decisions (archaeology)

> **2026-03-26:** The pillars above reflect a strategic pivot. This section is preserved as context, not current direction.

**Historical core narrative:** Unit = Adaptive Periodization Engine, not a passive logger.
**Historical differentiator:** "The only gym logger that auto-adjusts your 8-week plan when you fail."
**Historical user:** Intermediate–advanced lifter wanting *what to lift next*, not just history.
**Historical UI:** Target vs actual — target weight shown before the set; engine updates future weeks.
**Historical container:** 8-week cycle with per-exercise rules (increment, base weight, failure tolerance).
**Historical engine rules:** Hit → increment. Miss → repeat. 3 consecutive misses → 10% deload.
**Historical monetization:** One-time purchase, engine as premium differentiator.

**Execution constraints (still active):** Swift 6, SwiftUI, SwiftData, local-first. Atomic design system. Light-first. No CloudKit sync at v1. No exercise discovery feed.
