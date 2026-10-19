# Unit — Product Compass

> Single source of truth for **what we believe**, **what we decided**, and **what's still open**.
> Read this before changing positioning, the website, or MVP scope.
> Update this file first — then cascade to downstream docs.

---

## Vision

A world where every lifter's training knowledge lives in a tool as fast and trusted as their own memory — with clear next steps instead of opaque algorithms or social feeds.

## Mission

Build the fastest, most trustworthy progression-guided gym logger for beginner-to-experienced users. Replace the paper notebook and the Notes app with something that survives gym fatigue, makes the next step understandable, and earns its place on the dock through daily utility.

## Values

| Value | What it means in practice |
|-------|---------------------------|
| **Speed over features** | Every design and engineering decision is judged by its impact on *seconds per set logged*. If a feature adds friction, it waits. |
| **Athlete autonomy** | Unit may recommend the smallest next-session change, but the lifter accepts or edits it and keeps control of the program. |
| **Invisible UI** | The best interaction is one the user doesn't notice. Last time pre-fill, haptic confirmation, auto-timers — the app anticipates, not interrogates. |
| **Local trust** | Data lives on-device. No account required, no cloud dependency at v1. The app works in airplane mode, in a basement gym, always. |
| **Honest simplicity** | No hype, no dark patterns, no social pressure. The voice is direct, the interface is quiet, the product earns attention through utility. |

---

## User segment

**Primary:** Beginner-to-experienced gym user following a structured routine. They may choose one of Unit's ready-made programs or bring a routine from a coach, community, or their own notes. They need a tool to execute, track, and understand the smallest next step without surrendering control to a black box.

**Defining behaviours:** Trains consistently or is trying to establish consistency. Values fast logging, a visible previous performance, and an understandable next target over feeds, dashboards, and opaque coaching.

**Anti-persona:** Someone seeking exercise-form instruction, adaptive recovery coaching, automatic program generation, or social competition. Unit supplies starter programs and progression guidance, not a full coaching service.

---

## Pillars

| Pillar | Current intent |
|--------|----------------|
| **North star** | **Fast, trustworthy logging under fatigue.** Success metric: *seconds per set logged*. We fill the "notebook gap" — faster than paper, smarter than Notes, zero complexity fatigue. Progression insight is a reward for logging, not a prerequisite. |
| **Non-negotiables** | Gym Test (≤ 3s per set under stress) · Last time (pre-filled from last session) · Local-first · No social feed · One-tap "Done" (44×44 pt min) · Haptic confirmation · Auto rest timer with Lock Screen / Dynamic Island |
| **MVP boundary** | **Version 2.1 adds transparent double progression to the log + template path.** It is opt-in per routine/exercise, evaluated after the workout, and never changes a routine before acceptance. Cycles, deloads, readiness, RIR/RPE adaptation, and program generation stay out. Hard access gate after onboarding follows `docs/pricing.md`. |
| **Voice** | Utility-first, direct, no hype. No competitor-framed copy. *"Faster than paper. Smarter than Notes. Your gym notebook, upgraded."* |

---

## Decision log

| Date | Decision | Rationale | Supersedes |
|------|----------|-----------|------------|
| 2026-10-19 | **Make personal progress a third native tab** | The user requested Profile for local training analytics. Reuse recorded working-set history and clearly separate accepted next targets; no social identity, strength score or active-logging controls. | Two-tab navigation only; all progression/autonomy rules remain |
| 2026-08-13 | **Put trial reassurance and purchase on one surface** | The hard paywall keeps the personalized program payoff, all available StoreKit plans, selected-offer timeline, optional Day 5 reminder, disclosure, and direct purchase action together. Eligible trials use a localized `Try for 0.00` action; non-trial offers remain truthful. | The two-page paywall and automatic reminder portions of the 2026-08-13 decisions; not the hard gate, StoreKit truthfulness, or direct plan comparison |
| 2026-08-13 | **Partially superseded: Make purchase options directly comparable** | Page two shows Weekly, Monthly, and Yearly as the three primary recurring choices. Configured Lifetime remains visible but is separated as a one-time alternative. Legal actions stay fully tappable while visually subordinate to plan, price, and purchase. | The later one-surface decision keeps direct comparison but supersedes page two and the separate Lifetime grouping. |
| 2026-08-13 | **Superseded: Separate trial reassurance from plan purchase** | The hard paywall uses two native pages: personalized program payoff and StoreKit-derived timing first, plan choice and purchase disclosure second. A verified introductory-trial purchase may request notifications after access unlocks and schedule one Day 5 reminder; there is no paywall toggle. | Superseded by the later 2026-08-13 one-surface decision; the hard gate and StoreKit truthfulness rules remain. |
| 2026-08-12 | **Make subscription timing visible before purchase** | The paywall keeps the selected StoreKit plan on one page, collapses alternative tiers behind `Change`, and shows a connected Day 0 → cancel-before-renewal window → renewal timeline. It does not add a notification choice to the purchase decision. | The hidden `What happens next?` sheet; the always-expanded four-tier stack; the short-lived reminder toggle; not the price-near-CTA rule |
| 2026-08-12 | **Lead marketing with `Know what to lift next`** | The verified 2.1 progression feature is now the clearest promise. Marketing explains the full loop in order: one-tap logging, transparent next target, explicit acceptance. The first two-second onboarding brand beat may use a black surface; the carousel and product remain light. | The 2026-03-26 speed-only website hero decision; not the three-second logging requirement |
| 2026-08-12 | **Ready-made programs are matched, never generated** | The starter path asks only goal, experience, and supported training days, then ranks 1–3 catalog programs. Days stay a hard constraint. Duration and equipment wait until the catalog can honor them. | The filter-first starter-library onboarding |
| 2026-08-04 | **Progression, rename, and current reliability work ship together as 2.1** | Version 2.0 is live; no separate 2.2 release is required before testing the new promise. App Store identity becomes `Unit: Progressive Overload` / `Gym Workout Log & Tracker` only with the verified feature. | The 2026-08-03 `v2.2` release label; the feature boundary itself is unchanged |
| 2026-08-03 | **Transparent progression-guided logger** | Unit may recommend the smallest next-session change while preserving the user’s program and final control. The active workout must still pass the three-second Gym Test. | Pure-logger positioning and the blanket progression ban |
| 2026-03-26 | **Primary promise is zero-friction logging**, not auto-adjusting coach | "Complexity fatigue" + "notebook gap" research: intermediate+ lifters default to Notes apps. Open space = Zero-Friction Execution Engine. | "Adaptive Periodization Engine" narrative |
| 2026-03-26 | **8-week cycles demoted** to optional layer | Rigid scheduling frustrates users who miss days. Templates replace cycles as primary program unit. | "8-week cycle as main container" |
| 2026-03-26 | **Algorithmic overload rules removed from v1** | Auto-suggestions feel like a black box to veterans. History-as-guide via ghost values instead. | Engine rules (hit→increment, miss→repeat, 3 misses→deload) |
| 2026-03-26 | **Hero headline leads with speed/utility** | Website + App Store copy lead with notebook gap, not engine. Engine story returns as secondary once logging speed is validated. | "The only gym logger that auto-adjusts your 8-week plan" |
| 2026-03-26 | **Superseded: Three frictionless onboarding paths** | Text-paste import, redo-from-history, manual builder. Solves "15-minute setup" retention killer. Superseded by the current two-path onboarding direction: text-paste import and starter program library. | Full 8-week cycle configuration upfront |
| 2026-03-26 | **Active Workspace is the UX centre** | Today → Start → Log in ≤ 2 taps. Session screen is where the user lives. | Program-tree navigation to reach a day |
| 2026-03-26 | **Rest timer auto-starts on Done**, visible on Lock Screen / Dynamic Island | App is minimised between sets. Timer must follow the user outside the app. | — |
| 2026-03-26 | **Superseded: All three template import options ship in v1** | Text-paste, redo-from-history, manual builder. Superseded by the current two-path onboarding direction: text-paste import and starter program library. | — |
| 2026-03-26 | **Ghost value cold start: empty + global lookup** | Never logged → empty fields with "No history yet". Logged anywhere (any template) → ghost fills globally by exercise. | — |
| 2026-04-28 | **Superseded: Paywall strategy deferred; gates power-user features only** | Phase 0 (TestFlight): no paywall surfaces, retention validation only. Phase 1 (App Store launch, Weeks 1–4): free for everything, one quiet "Unit Pro is coming" Settings card collecting founding-member intent locally. Phase 2 (Week 5+, conditional on ≥30 users at 3+ sessions/wk for 2 wks): paywall flips, gating off-Gym-Test features only — CSV + Markdown export, Apple Health sync, custom app icons, custom template accent colors, founding badge. Superseded by the 2026-06-16 / 2026-06-29 hard-gate pricing decisions in `docs/pricing.md` and `docs/decision-log.md`. | $9.99/$49.99 proposal in `launch-plan.md §2`; the prior `pricing.md` Pro-gate list (template-count cap, 30-day history cap, PR detection, widgets) which would have violated `docs/claude/scope.md` line 77 |
| 2026-06-29 | **Two onboarding paths for v1** | v1 onboarding is text-paste import and starter program library only. Manual-builder and redo-from-history are no longer first-run paths. | 2026-03-26 three-path onboarding decisions |
| 2026-06-29 | **Hard access gate follows pricing source of truth** | Onboarding is free; post-onboarding app access is gated according to `docs/pricing.md`. This carries forward the 2026-06-16 hard-gate pricing direction and resolves the old soft-gate plan. | 2026-04-28 deferred / power-user-only paywall strategy |

---

## Open questions

- **Bodyweight progression:** External-load rules remain out of scope until a separate product decision.
- **Progression expansion:** Validate opt-in double progression before considering any additional algorithm or bodyweight rule.

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

**Execution constraints (still active):** Swift 6, SwiftUI, SwiftData, local-first. Atomic design system. Light-only for this release after the recorded two-second black onboarding opener. No CloudKit sync at v1. No exercise discovery feed.
