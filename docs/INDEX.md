# Unit — Docs Index

> One-liner catalog of every doc under `docs/`. Open this on demand from CLAUDE.md §1 when you don't know which doc applies.
> Loaded on-demand only — does NOT live in CLAUDE.md.

**Conventions:**
- **live** — current source of truth.
- **archive** — superseded / completed / reference-only. See `docs/archive/`.
- Subdirs (`docs/claude/`, `docs/marketing/`, `docs/references/`) have their own README — open those, not the individual files inside, unless cited.

---

## Product & strategy

| Path | What it is | Use when |
|---|---|---|
| `docs/product-compass.md` | Strategic north star, decision log, MVP boundary, voice | Starting a task or settling a scope question |
| `docs/goals.md` | Measurable v1 targets — Gym Test specs, KPIs | Reviewing release criteria or KPIs |
| `docs/launch-plan.md` | 8-week launch roadmap (Apr–Jun 2026): ship, pricing, marketing | Planning launch phase or weekly cadence |
| `docs/values.md` | 5 core values: make money, touch lives, fix your own, sell it, market matters | Aligning a feature or stakeholder message |
| `docs/product-manifesto.md` | Long-form "why Unit": veteran lifter problem, templates not plans, invisible UI | Explaining Unit to team/investors |
| `docs/pricing.md` | Subscription tiers, trial & win-back, Pro gates | Changing pricing or paywall scope |
| `docs/use-cases.md` | 3 archetypes (Architect, Grinder, Recoverer) and how Unit serves them | Validating a feature against actual users |
| `docs/app-positioning.md` | One-liner, positioning statement, key messages, voice | Writing copy or pitching the app |

## Design system & visual

| Path | What it is | Use when |
|---|---|---|
| `docs/atomic-design-system.md` | Tokens in `DesignSystem.swift` — atoms, molecules, organisms, templates | Adding a view or checking token names |
| `docs/visual-language.md` | Light-only theme, color roles, typography, design constraints | Reviewing UI specs or color/font decisions |
| `docs/design-principles.md` | 6 principles: minimalism, clarity, speed, consistency, accessibility, atoms | Justifying a UI change or resolving conflicts |
| `docs/apple-hig.md` | HIG alignment: touch targets, tabs, typography, contrast, motion, VoiceOver | Auditing UI for HIG compliance / a11y |

## Marketing & positioning

| Path | What it is | Use when |
|---|---|---|
| `docs/marketing/README.md` | The marketing plan — one reel a day to TikTok + IG (slimmed 2026-06-11; old playbooks in `docs/archive/marketing/`) | Any marketing task — open this first |
| `docs/competitors.md` | 5 direct competitors (Hevy, Strong, Fitbod, sheets, bloatware) — strengths/weaknesses | Understanding market or differentiating |
| `docs/competitors-analysis.md` | Deeper matrix — features, UX under stress, IA takeaways | Benchmarking a feature or interaction pattern |
| `docs/app-store-copy.md` | App Store Connect copy — name, subtitle, description, keywords | Updating App Store metadata |
| `docs/app-store-localization/README.md` | International rollout — metadata localization tiers, regional pricing, per-locale copy (de/es-MX/pt-BR/fr/tr) | Localizing App Store metadata or reviewing regional pricing |

## Research & foundations

| Path | What it is | Use when |
|---|---|---|
| `docs/behavior-change.md` | Summary of Wendel — Fogg MAP, identity habits, friction reduction | Designing for adoption / habit formation |
| `docs/mental-models.md` | Mental models — identity change, process over goals, simplicity, next step | Defending a UX decision or retention strategy |
| `docs/cognitive-principles.md` | Psychology — friction, clarity, commitment, consistency | A/B testing copy or onboarding flows |
| `docs/skills-reference.md` | External skill references (iOS, SwiftUI, HealthKit, fitness) and takeaways | Adjacent-domain research |

## Release & QA

| Path | What it is | Use when |
|---|---|---|
| `docs/release-qa.md` | The gauntlet — manual on-device checklist for state persistence, keyboard, lifecycle, empty/max data | Before every TestFlight or App Store submission. Pairs with the `/state-audit` skill. |
| `docs/next-app-playbook.md` | Portable retrospective — what Unit taught, distilled for app #2's day one | Starting the next app. Self-deleting: absorb, then remove. |
| `docs/app-store-submission/final-submit-checklist.md` | v2.1 (build 36) ASC handoff — clean-main provenance gate + screenshot capture runbook | Submitting v2.1 to App Review |

## Agent harness & Claude

| Path | What it is | Use when |
|---|---|---|
| `docs/AGENTS.md` | Rules for AI agents — v1 scope, architecture, product model | Read first every session (referenced by CLAUDE.md) |
| `docs/claude/scope.md` | CLAUDE.md §2–§4 spillover — ships/does-not-ship, push-back phrasing | Deciding scope or handling out-of-scope requests |
| `docs/claude/design-system.md` | 5 UI principles, parallel-impl ban, gatekeeper checklist | Reviewing a UI change or creating a component |
| `docs/claude/harness.md` | Hooks, skills, audit mode | Debugging a blocked Edit or understanding enforcement |
| `docs/decision-log.md` | Append-only log of scope/design/direction changes (started 2026-05-01) | Asking "why did we…?" or avoiding redoing experiments |
| `docs/custom-instructions.md` | Product execution context for any agent — role, source of truth | Syncing agent context across sessions |

## References (open the README, not the screenshots)

| Path | What it is | Use when |
|---|---|---|
| `docs/references/README.md` | Index of iOS screens, design details, notes (`details/`, `ios-screens/`, `notes/`) | Visual anchoring before any non-trivial UI change |

## Top-level

| Path | What it is | Use when |
|---|---|---|
| `docs/readme.md` | Quick orientation — what Unit does, who it's for, tech stack | First-time reader |

---

## Archive (moved to `docs/archive/`)

| Path | What it is | Why archived |
|---|---|---|
| `docs/archive/geminiresearch-mvp-pivot.md` | Long research dump that informed the 2026-03-26 pivot | Superseded by `product-compass.md` + `launch-plan.md` as living decisions |
| `docs/archive/geminiresearch-1.md` | Periodization models (linear, DUP, block) | Reference for `ProgressionEngine`, deferred post-v1 |
| `docs/archive/geminiresearch-2.md` | Algorithmic progressive overload, 8-week periodization | Reference for `ProgressionEngine`, deferred post-v1 |
| `docs/archive/cleanup-spec.md` | Refactoring spec — theme rename, file deletions, extractions | Already executed; historical record only |

> Archived 2026-05-01 via `git mv` — history preserved.
