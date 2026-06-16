# Unit — monetization strategy (merged recommendation, 2026-05-31)

> Point-in-time synthesis, not a new source of truth. **Authoritative pricing stays `docs/pricing.md`.** This memo merges (a) a pasted external research summary, (b) a second Unit-specific research synthesis, and (c) Unit's own locked decisions, then resolves the conflicts. The founder approved it on 2026-05-31. The deep-research workflow that was running in parallel was stopped once the decision locked.

## Bottom line

Launch **free** now (Pro deferred + hidden, per the 2026-05-31 decouple decision). When Pro ships in v1.1+, monetize with **free-forever core + a soft, off-path paywall on genuine premium features** — not a hard paywall, not weekly pricing, not a price cut. Grandfather every pre-paywall install forever (now wired into the v1.0 build).

## Decisions locked

| Question | Decision | Why |
|---|---|---|
| Weekly pricing | **No** | Health & Fitness is the documented exception to "weekly converts more" — category annual revenue grew 51%→61% (2023→2025) while weekly is a churn cliff (~65% gone in 30 days). Weekly fitness pricing is the dark-pattern category Unit's trust moat is defined against, and it conflicts with `pricing.md` ("permanence, not extraction"). Apple 3.1.2(a) review risk on loggers adds to it. |
| Prices | **Keep $4.99/mo · $29.99/yr · $44.99 lifetime** | Locked in `pricing.md` (Liftosaur parity; Lifetime at 1.5× yearly = generous, not extractive). The external research proposed cutting to $3.99/$24.99/$59.99 — rejected: it contradicts the locked tiers and the $59.99 lifetime is *more* extractive than the rationale allows. Revisit only with real conversion data. |
| Paywall type | **Soft, off-path** | The research's "hard paywall at end of onboarding" would gate the core loop — breaks the free-forever sacred promise (`pricing.md`), CLAUDE.md §3, and even contradicts its own "don't gate the core loop" line. The hard-paywall conversion edge (RevenueCat ~10.7% vs ~2.1%) is measured on apps where the whole app is the paid product, not free-forever tools whose free top-of-funnel *is* the marketing. |
| Paywall placement | **On the off-path feature** (export, Health, cloud, Watch) — already how Settings is wired | Never "paywall after N workouts / N days of history." Core logging, ghost values, history, PRs stay free forever. |
| Trial | **7-day, on monthly + annual** (per `pricing.md`) | Annual-only-trial is a defensible LTV optimization — park it as a possible tweak for when Pro ships, don't change now. |
| Grandfathering | **Yes — shipped in v1.0** | `InstallProvenance` (in `UnitApp.swift`) records first-launch version + date in the Keychain (survives reinstall). When the paywall ships, every install predating it keeps full Pro free forever — framed as a gift in release notes. This is the single best idea from the research: it kills the 1-star "you gated what was free" brigade *and* reinforces the trust brand. |
| Pro teaser at launch | **Silent in-app** | The research argues "don't tease Pro — it pollutes the Gym Test thesis." Adopted: no in-app Pro surface in v1.0 (already enforced by `LaunchConfig.proAvailable = false`). A founding-rate teaser on the landing page only is optional. |

## Phasing

1. **Now (v1.0):** ship free, zero purchase surface (flag off). Grandfather marker records silently. Goal: installs + interviews + unprompted "I'd pay for X" signals.
2. **v1.1 build:** build ONE genuinely-premium feature behind the flag. Order: custom app icons (scoped, `.claude/plans/custom-app-icons-scope-2026-05-31.md`) → analytics → template sharing → export. Never gate: logging, ghosts, history, basic charts, custom exercises.
3. **v1.1 ship:** flip `LaunchConfig.proAvailable = true`, submit the 3 IAPs for review, soft off-path paywall, prominent Restore, grandfather all v1.0 installs, announce 2 weeks ahead (in-app + release notes).

## The founder's "hard paywall = annoying" question, answered

**Half right.** A hard paywall on the *core* (the onboarding wall the research suggested) is exactly the brand-killing, 1-star move to avoid. But a *soft* paywall on real off-path extras, with grandfathering, is not annoying — hard-vs-soft year-1 retention is ~27% vs ~28%, so charging for extras doesn't lose real users; it loses people who'd never pay. The rule: **never gate the core; charge confidently for off-path extras.** The annoyance was never "paywall" — it's "paywall on the wrong thing."

## Confidence note

The conversion numbers above come from the pasted research (Adapty / RevenueCat, 2024–2026), not independently re-verified here — the verification workflow was stopped once the decision locked. They directionally match known industry data and are not load-bearing for the decision (the decision rests on Unit's brand + the free-forever promise, not on a specific conversion %). Re-run `deep-research` before betting real money on any single figure.
