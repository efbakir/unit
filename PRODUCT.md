# Product

## Register

product

## Users

Intermediate-to-advanced lifters (1–10+ years training) who already know their program. They follow a structured routine — written by a coach, copied from a community, or self-designed — and need a tool to **execute and track**, not to be **told what to do**.

**Behaviour:** trains 3–6×/week, currently logs in a Notes app or paper notebook, has abandoned at least one "smart" tracker for being too slow, too rigid, or too noisy.

**Context of use:** mid-workout, fatigued, often sweaty, one-handed, sometimes only 30 seconds between sets. The phone goes back in the pocket between every set. The app is launched, used for 2–5 seconds, and dismissed — over and over.

**Anti-persona:** beginners who need guidance on *what* to do; social lifters who want feeds, badges, leaderboards, friend activity. v1 is not designed for them.

## Product Purpose

Unit is the fastest, most trustworthy gym logging tool for athletes who already know how to train. It replaces the paper notebook and the Notes app with something that respects the lifter's expertise, survives gym fatigue, and earns its place on the dock through daily utility.

**Success looks like:** a tired user logs a completed set in ≤ 3 seconds, one-handed, without typing — because last time's weight and reps are already filled in and one tap confirms them. The app gets out of the way. The lifter forgets it's there.

The product wins by *removing* — friction, choices, words, screens — not by adding features, recommendations, or social loops.

## Brand Personality

**Three words:** calm, expert, honest.

**Voice:** utility-first, direct, no hype. No motivational copy ("crush your goals"), no competitor framing ("unlike other apps"), no marketing superlatives. Talk to the lifter as a peer who already knows the work. *"Faster than paper. Smarter than Notes. Your gym notebook, upgraded."*

**First-person singular — never "we".** Unit is a solo project (Efe Bakir, `DEVELOPER_NAME` in `lib/contact.ts`). All user-facing copy uses "I / me / my" — never "we / us / our / our team". Corporate "we" is dishonest for a one-person product and conflicts with the calm-expert-honest voice; the solo-founder identity is a positioning asset, not something to hide behind a fake-team pronoun. Applies to: marketing site, legal pages (privacy/terms define the entity as `{DEVELOPER_NAME} ("I," "me," or "my")`), in-app copy, App Store descriptions, support/contact ("Contact me", "I typically respond"), social posts. When the *product itself* is the actor, **Unit** is the subject ("Unit doesn't tell you what to lift"), not "we". The rule bans the fake corporate "we" — it does **not** require "I / my" in UI labels; neutral labels ("Weight unit", "Add program") are preferred inside the app, and pronouns appear only where a human is genuinely speaking (support, legal, founder copy). Pre-ship grep on any user-facing surface: `\bwe\b|\bwe'|\bour\b|\b us \b`.

**Emotional goal:** trust and flow. The interface should feel like a well-worn tool — the page in the notebook you've been writing in for a year — not a product trying to impress you. Quiet confidence over polish.

## Anti-references

Unit must not look or feel like:

- **Strong / Hevy / Jefit** — spreadsheet-dense layouts, parallel target-vs-actual columns, prescriptive weight targets, busy timer chrome, dashboard-style "today's workout" summaries. The whole "gym tracker app" visual category is the trap to avoid.
- **Strava / Nike Training Club** — social feeds, friend activity, achievement badges, streak gamification, "share your workout" prompts, motivational hero copy, lifestyle photography of athletes mid-jump.
- **Whoop / Oura** — dark-mode dashboards, neon data visualisation, gradient hero metrics, "recovery score" rings, HRV/sleep wellness aesthetics. Unit is not a wellness product; it is a working tool.
- **Generic fitness SaaS** — stock-photo athletes on the landing page, "transform your training" hero copy, pricing tiers up front, three-icon feature grids.

The shared failure mode across all four is **decoration that pretends to be utility**. If a pixel doesn't help log faster or read state more clearly under fatigue, it does not belong.

## Design Principles

Strategic principles that should guide every product and design decision. Visual rules live in DESIGN.md — these are about *posture*, not paint.

1. **Speed is the feature.** Every decision is judged against *seconds per set logged under fatigue*. A faster path beats a smarter path. A shorter screen beats a more informative one.
2. **History, not instructions.** Surface what the lifter did last time (the "Last time" pre-fill). Never prescribe what they should do next. Athlete autonomy is non-negotiable; the engine and target-vs-actual UI are explicitly out of scope for that reason.
3. **Invisible UI.** The best interaction is one the user doesn't notice. Anticipate (auto-fill, auto-timer, haptic confirm) instead of interrogating (confirmations, dialogs, "are you sure?"). The hot loop has no friction.
4. **Local trust.** Data lives on-device. The app works in airplane mode, in basement gyms, in elevators. No account required, no cloud dependency at v1, no telemetry that gates core function.
5. **Earn attention through utility.** No social pressure, no streaks, no engagement gamification, no notifications that aren't directly useful (PR detected, rest finished). The product earns its dock spot every day by being faster than paper — not by guilt-tripping the user back in.

## Accessibility & Inclusion

- **WCAG 2.2 AA contrast** for all text and interactive elements in both light and dark appearance. Numerics (weights, reps, timers) get extra contrast headroom because they're the data the user is actually reading mid-set.
- **Dynamic Type respected.** All copy uses `AppFont` tokens that scale with iOS Dynamic Type. Numerics use monospaced digits so columns stay aligned at every size. Layouts must not break or clip at the largest accessibility sizes.
- **Reduced Motion respected.** Honor `accessibilityReduceMotion`. No parallax, no elastic, no decorative motion when the system preference is on — only state-change feedback that survives reduction (cross-fades, opacity).
- **Touch targets ≥ 44×44pt** everywhere. The Gym Test (one-handed, sweaty, fatigued) is the floor, not the ceiling.
- **Light-first, system-honoring.** Light mode is the design baseline; dark mode follows the system trait but is never the design driver.
- **No color alone for state.** Success / warning / error always pair with an icon or label (HIG). Color-blind users get the same information.
