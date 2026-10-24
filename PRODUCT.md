# Product

## Register

product

## Users

Beginner-to-experienced gym users following a structured routine. They may choose a ready-made program or bring one from a coach, community, or their own notes. They need a tool to **execute, track, and clarify the next small step**, not one that takes control of their training.

**Behaviour:** trains consistently or is trying to establish consistency, currently logs in a Notes app, paper notebook, or another tracker, and values speed and clarity over feeds and dashboards.

**Context of use:** mid-workout, fatigued, often sweaty, one-handed, sometimes only 30 seconds between sets. The phone goes back in the pocket between every set. The app is launched, used for 2–5 seconds, and dismissed — over and over.

**Anti-persona:** users seeking exercise-form instruction, adaptive recovery coaching, automatic program generation, feeds, badges, or leaderboards. Unit provides starter programs, but it is not a full coaching service.

## Product Purpose

Unit is the fastest, most trustworthy progression-guided gym logger. It replaces the paper notebook and the Notes app with something that survives gym fatigue, makes the next step understandable, and earns its place on the dock through daily utility.

**Success looks like:** a tired user logs a completed set in ≤ 3 seconds, one-handed, without typing — because last time's weight and reps are already filled in and one tap confirms them. The app gets out of the way. The lifter forgets it's there.

The product wins by removing friction, repeated decisions, words, screens, and social loops. Version 2.1 adds one calm answer to “What should I do differently next time?” without adding work to the active set flow.

## Brand Personality

**Three words:** calm, expert, honest.

**Voice:** plain, factual and minimal. State what happened and what to do next. No personality, motivational language, jokes, metaphors or marketing slogans in app copy. For example: "Rest finished" and "Start your next set."

**First-person singular — never "we".** Unit is a solo project (Efe Bakir, `DEVELOPER_NAME` in `lib/contact.ts`). All user-facing copy uses "I / me / my" — never "we / us / our / our team". Corporate "we" is dishonest for a one-person product and conflicts with the calm-expert-honest voice; the solo-founder identity is a positioning asset, not something to hide behind a fake-team pronoun. Applies to: marketing site, legal pages (privacy/terms define the entity as `{DEVELOPER_NAME} ("I," "me," or "my")`), in-app copy, App Store descriptions, support/contact ("Contact me", "I typically respond"), social posts. When the *product itself* is the actor, **Unit** is the subject ("Unit shows the next target"), not "we". The rule bans the fake corporate "we" — it does **not** require "I / my" in UI labels; neutral labels ("Weight unit", "Add program") are preferred inside the app, and pronouns appear only where a human is genuinely speaking (support, legal, founder copy). Pre-ship grep on any user-facing surface: `\bwe\b|\bwe'|\bour\b|\b us \b`.

**Emotional goal:** trust and flow. The interface should feel like a well-worn tool — the page in the notebook you've been writing in for a year — not a product trying to impress you. Quiet confidence over polish.

## Anti-references

Unit must not look or feel like:

- **Strong / Hevy / Jefit** — spreadsheet-dense layouts, parallel target-vs-actual columns, opaque per-set prescriptions, busy timer chrome, dashboard-style "today's workout" summaries. The whole "gym tracker app" visual category is the trap to avoid.
- **Strava / Nike Training Club** — social feeds, friend activity, achievement badges, streak gamification, "share your workout" prompts, motivational hero copy, lifestyle photography of athletes mid-jump.
- **Whoop / Oura** — dark-mode dashboards, neon data visualisation, gradient hero metrics, "recovery score" rings, HRV/sleep wellness aesthetics. Unit is not a wellness product; it is a working tool.
- **Generic fitness SaaS** — stock-photo athletes on the landing page, "transform your training" hero copy, pricing tiers up front, three-icon feature grids.

The shared failure mode across all four is **decoration that pretends to be utility**. If a pixel doesn't help log faster or read state more clearly under fatigue, it does not belong.

## Design Principles

Strategic principles that should guide every product and design decision. Visual rules live in DESIGN.md — these are about *posture*, not paint.

1. **Speed is the feature.** Every decision is judged against *seconds per set logged under fatigue*. A faster path beats a smarter path. A shorter screen beats a more informative one.
2. **Transparent targets, final say.** Surface what the lifter did last time, then save the smallest next-session change when they explicitly configure double progression. Explain the calculation, save it when the workout is finished, and keep the previous target or an edit one tap away.
3. **Invisible UI.** The best interaction is one the user doesn't notice. Anticipate (auto-fill, auto-timer, haptic confirm) instead of interrogating (confirmations, dialogs, "are you sure?"). The hot loop has no friction.
4. **Local trust.** Data lives on-device. The app works in airplane mode, in basement gyms, in elevators. No account required, no cloud dependency at v1, no telemetry that gates core function.
5. **Earn attention through utility.** No social pressure, no streaks, no engagement gamification, no notifications that aren't directly useful (PR detected, rest finished). The product earns its dock spot every day by being faster than paper — not by guilt-tripping the user back in.

## Accessibility & Inclusion

- **WCAG 2.2 AA contrast** for all text and interactive elements in Unit's light-only appearance. Numerics (weights, reps, timers) get extra contrast headroom because they're the data the user is actually reading mid-set.
- **Dynamic Type respected.** All copy uses `AppFont` tokens that scale with iOS Dynamic Type. Numerics use monospaced digits so columns stay aligned at every size. Layouts must not break or clip at the largest accessibility sizes.
- **Reduced Motion respected.** Honor `accessibilityReduceMotion`. No parallax, no elastic, no decorative motion when the system preference is on — only state-change feedback that survives reduction (cross-fades, opacity).
- **Touch targets ≥ 44×44pt** everywhere. The Gym Test (one-handed, sweaty, fatigued) is the floor, not the ceiling.
- **Light-only.** After the recorded two-second black onboarding brand opener, Unit intentionally renders its established light appearance regardless of the system trait for this release. The opener is a transition, not dark mode, and must not spread into the product UI.
- **No color alone for state.** Success / warning / error always pair with an icon or label (HIG). Color-blind users get the same information.
