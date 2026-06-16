# Unit — Claude Code context

> Session-level **intent document**. Read it, internalize it, then act.
> Framework: centralize intent → distribute execution → feedback loop. You get the *why*; decide the *how* within these fences.
> If a request conflicts with anything here, **pause and push back before executing**. That is the job.

This file is intentionally tight. Detail spills into:
- [`docs/claude/scope.md`](docs/claude/scope.md) — full v1 ships / does-not-ship list, push-back phrasing, deleted files
- [`docs/claude/design-system.md`](docs/claude/design-system.md) — full banned-list with rationale, parallel-implementation ban examples, full gatekeeper checklist
- [`docs/claude/harness.md`](docs/claude/harness.md) — full hook pattern list, skills, audit mode, order of operations

Other source-of-truth docs:
- Product: `PRODUCT.md` (root — persona, voice incl. **first-person singular rule**, anti-references, principles), `docs/product-compass.md`, `docs/goals.md`, `docs/AGENTS.md`
- Design: `DESIGN.md` (root — palette, type, components, do/don't) + `DESIGN.json` (machine-readable mirror), `docs/atomic-design-system.md`, `docs/visual-language.md`
- References: `docs/references/` (ios-screens/, details/, notes/) — and the canonical Figma file for card/row visual specs lives at node `166:8` (see `docs/claude/design-system.md` §Card composition)
- Marketing: `docs/launch-plan.md` (8-week strategic timeline) + `docs/marketing/` (operational infra: tools, playbooks, templates, anti-patterns, dated research). When marketing tactics in a request conflict with `docs/marketing/anti-patterns.md`, push back per §2.
- Decision log: `docs/decision-log.md` — append-only record of scope/design/direction changes. Read before answering "why did we…?" or proposing an experiment that may already have been tried. Index: `docs/INDEX.md`.

---

## North star

**Unit is a zero-friction gym logger. Every decision is judged by *seconds per set logged under fatigue*. Everything else is secondary.**

- **Gym Test**: one-handed, sweaty, ≤ 3 seconds to log a set.
- **Last time** values (pre-fill from last session; formerly "ghost values", still `metricIsGhost` in code) are the primary logging mechanism.
- **Templates** are the program unit — not cycles, not weeks, not engines.
- **Local-first, light-first, quiet UI.** No social, no feeds, no recommendations.

---

## §1. Session-start checklist (before the first Edit/Write)

1. Read this file to the end.
2. If the task involves UI, product direction, or scope: skim `docs/product-compass.md` §Pillars + §Decision log **and** `docs/goals.md` §v1 scope boundaries.
3. If the task involves any visual/component change: skim `DESIGN.md` (root — single-page system summary) and `docs/atomic-design-system.md`, then open `Unit/UI/DesignSystem.swift`. Reuse > extend > create.
4. If the task is non-trivial UI: list `docs/references/ios-screens/` and `docs/references/details/`. Pick the closest anchor. If none fits, ask the user before inventing.
5. **If the task involves user-facing copy** (marketing site, legal page, in-app text, App Store metadata, social post, support/contact): read `PRODUCT.md` §Brand Personality. The first-person singular rule (`I / me / my`, never `we / us / our`) is non-negotiable and applies across every surface.
6. If you are about to act on a "why did we…?" question, propose an experiment, or revisit a banned-list item: open `docs/decision-log.md` and check whether the answer (or a prior attempt) is already there. Append a new entry when you green-light a scope override or direction shift.
7. If unsure which doc covers your task, open `docs/INDEX.md` — one-liner catalog of every doc with a "use when" trigger.
8. State out loud (one line) which docs and references you consulted, then proceed.

---

## §2. Push-back mandate

The user has said: *"you should be better than me here — I should not repeat myself every prompt."* Translation: **drift prevention is your job, not theirs.**

When a request violates this file — push back **before** writing code. Cite the rule. Offer the in-scope alternative. Do not silently comply.

Phrasing: *"Before I do this — it conflicts with [rule] in [file:section]. The in-scope way to solve your underlying problem is [Y]. Want me to do Y instead, or is this an explicit override?"*

If the user explicitly overrides, proceed — and note the override in your response so the deviation is visible. Full phrasing template, ships/does-not-ship list, and per-banned-item alternatives are in [`docs/claude/scope.md`](docs/claude/scope.md).

---

## §3. Scope fence — banned from v1

Per compass decision 2026-03-26, these are **removed** or **deferred**. Claude keeps trying to re-add them. Stop.

| Banned | Why |
|---|---|
| `ProgressionEngine`, auto-increment, deload rules | Deferred post-v1. |
| 8-week cycles, `Cycle`, `WeekDetailView`, "Week N of M" | Templates replace cycles. |
| "Day N ·" rigid numbering prefixes | Use template/routine names. |
| Target-vs-actual weight UI | Last-time pre-fill only. |
| Plate calculator | Skipped. |
| Social / feeds / sharing / community | Anti-persona. |
| Exercise discovery / recommendation | Athletes choose their own. |
| Pricing component on landing | Removed. |
| Conditioning days in imported programs | Filter on import. |
| CloudKit sync | Post-v1. Local-first only. |
| ~~Paywall on core logging~~ | ~~Core logging is free.~~ **Lifted 2026-06-16** — v2 ships hard paywall after onboarding. See `docs/pricing.md` and `docs/decision-log.md` 2026-06-16. |

Files deleted from repo (don't recreate): see [`docs/claude/scope.md`](docs/claude/scope.md).

---

## §4. Design system — hard rules

### The 5 principles

1. **Keep it simple.** Default to removing. Fewer tokens, variants, words, screens.
2. **Reuse components.** Grep `Unit/UI/DesignSystem.swift` first. ~80% fit → use or extend. *New primitives require explicit user okay.*
3. **Light mode only.** No `.preferredColorScheme(.dark)`, no dark-first decisions.
4. **Portrait only.** No landscape support.
5. **Gatekeeper every UI change.** Run the inline checklist below. Fail-closed.

### Parallel-implementation ban (the #1 current drift)

Claude **invents a new struct / helper / modifier / variant when extending the existing canonical one would do.** This is worse than any hex literal — it bakes drift into the design system itself.

- **Default: extend > create.** Before any new `struct X: View` / `ViewModifier` / variant in `DesignSystem.swift`, grep for the closest primitive. Cover ~80% → extend with `style:` / `variant:` / `tone:`. Otherwise justify in one sentence.
- **One canonical modifier per concern.** `appScrollEdgeSoft(top:bottom:)` for fades behind bars. `AppCardList(data) { row }` for lists in cards. `AppGhostButton` for "Add X" triggers. Never fork.
- **Fix the canonical, migrate callers, don't create a parallel.**
- **Toolbar chrome defers to iOS-native.** No `.weight(...)` on `ToolbarItem` buttons.
- **Sheet roots are plain `VStack`.** No `ScrollView` / `AppCard` wrapper inside `.sheet { }`.

Concrete recent violations + full rules: [`docs/claude/design-system.md`](docs/claude/design-system.md).

### Gatekeeper checklist (run before every UI Edit/Write)

- [ ] I checked `Unit/UI/DesignSystem.swift` for an existing primitive that fits.
- [ ] For non-trivial UI I named the visual anchor from `docs/references/`. If none fits, I asked first.
- [ ] If introducing a new component / pattern not in the DS, I cited a source of truth (repo first, web second). If neither covers it, I asked.
- [ ] No new `struct X: View` / `ViewModifier` without a one-line justification.
- [ ] No parallel `LinearGradient` / `.mask` / `.scrollEdgeEffectStyle(.automatic, ...)` where `appScrollEdgeSoft(...)` exists.
- [ ] No new raw colors, fonts, spacings, or radii — only tokens.
- [ ] Light-mode correct. No landscape assumptions.
- [ ] Bug fix: confirmed whether the bug is at the atom/molecule layer. If yes, fix only `DesignSystem.swift`.
- [ ] `ToolbarItem` button has no `.weight(...)`.
- [ ] `.sheet { }` root is a plain `VStack` with `presentationDetents`.
- [ ] Screen wrapped in `AppScreen`. CTAs use `AppPrimaryButton`. Cards use `AppCard`. No `chevron.right`. No raw `Divider()`.
- [ ] Touch targets ≥ 44×44pt. No regular weight. No orange `#FF4400` (accent is `0x0A0A0A`).
- [ ] Copy is explicit. Bodyweight shows "BW", not "0 kg". No `–` / `—` placeholders.
- [ ] No `ProcessInfo.processInfo.environment["UNIT_*"]` scaffolding left in `ContentView.swift` or `Features/**/*.swift`.

### Banned in view code (top hits — full list with rationale in [`docs/claude/design-system.md`](docs/claude/design-system.md))

- Hex literals, `Color(red:..)`, `Color.black/.white/.gray/...`, `.foregroundStyle(.gray)`
- `.font(.system(size:))`, raw `.font(.body/.caption/.title)`, `.padding(<int>)`, hardcoded radii
- `chevron.right` / `chevron.forward`; `Divider()` where `AppDivider` applies
- Inline button/card chrome instead of `AppPrimaryButton` / `AppCard` / `AppScreen`
- `regular` font weight; orange `#FF4400`
- `.preferredColorScheme(.dark)`; landscape assumptions
- `.scrollEdgeEffectStyle(.automatic, ...)` or `.hard` — always `.soft` via `appScrollEdgeSoft(top:bottom:)`
- `LinearGradient` / `.mask` fade under fixed bars in `Features/**/*.swift`
- `.weight(.semibold/.bold/.heavy)` on `ToolbarItem` buttons
- `AppSecondaryButton(tone: .accentSoft, icon: .add, ...)` for "Add X" — use `AppGhostButton`
- `ScrollView` or `AppCard` as the **root** child of `.sheet { }`
- `AppCard(contentInset: 0)` outside `DesignSystem.swift` — use `AppCardList`
- Hand-composed `AppCard { AppDividedList(…) }` outside `DesignSystem.swift` — use `AppCardList(data) { row }`
- "0 kg" for bodyweight; `–` / `—` placeholder copy
- `ProcessInfo.processInfo.environment["UNIT_*"]` committed in non-test code

`Unit/UI/DesignSystem.swift` is the **only** place raw values live. **Prefer iOS-native over custom**: bottom sheets, tab bar, buttons, navigation.

---

## §5. Fix level — atoms > molecules > screens

A visual/spacing/shadow/radius/color bug on one screen is **almost always an atom or molecule problem**. Fix it there.

> "apply design system rules. follow the design system. make it consistent. make it system level"
> "identify the inconsistencies and fix them in the atom and molecules level"

Rule: after any visual fix, ask "would this bug appear on sibling screens if I only patched this one file?" If yes, **move the fix up a layer** — to `DesignSystem.swift` or the specific molecule — so every screen benefits in one change.

---

## §6. Verification — do not auto-trigger the simulator

**Default: do NOT run `xcodebuild`, `xcrun simctl`, or any simulator/screenshot command after UI edits.** The user runs multiple Claude agents in parallel; auto-triggering the simulator every cycle causes conflicts (boot races, screenshot collisions, install failures). The visual pass is the user's job, on their schedule.

After any UI edit, label the work explicitly: *"edits applied, not yet verified — visual pass is yours."* Do not say "done", "shipped", "verified", or "looks right" based on the code. Code-looks-right is not verification, and you are not allowed to verify it yourself unless asked.

**When to run the simulator anyway** — only on explicit user request:
- "screenshot it", "verify", "build and check", "is it live?", "did it work?", "run the verify skill", or an explicit `/ui-visual-verify` invocation
- A user-set scheduled/audit task that names simulator verification as part of its scope

When the user does ask, the loop is: build → install → launch → screenshot → compare → iterate → confirming screenshot. That loop only runs in that one turn, scoped to that one request. It is **not** a standing rule for every edit.

Compile checks (`xcodebuild build` only, no simulator boot, no screenshot) are also **not** required by default. Run them only if the user asks, or if the edit is large enough that you genuinely don't trust the diff. One agent compiling at a time is fine; a swarm of agents all racing `xcodebuild` is not.

If the user has waived verification entirely (background/scheduled/lid-closed run, see `feedback_unit_background_verification_waiver.md`), just label work "edits applied, not yet verified — visual pass pending" and stop.

---

## §7. Simplification bias

- adding vs removing → **remove**
- extending a token set vs collapsing → **collapse**
- new variant vs reuse → **reuse**
- explaining in copy vs making it obvious → **make it obvious, then cut the copy**

> *"radius font size etc they are too much. even colors are too much. simplify."*

If a change grows the design system rather than tightening it, justify the growth explicitly or don't ship it.

---

## §8. Harness — hooks + skills

Three layers of mechanical enforcement so Claude doesn't have to "remember". Full details in [`docs/claude/harness.md`](docs/claude/harness.md).

- **PreToolUse hook** (`.claude/hooks/ui-banned-list.sh`): blocks Edit/Write/MultiEdit when banned patterns hit Swift files under `Unit/` (excluding `DesignSystem.swift`). If it blocks legitimate work → fix the canonical primitive, never the hook.
- **Skills** (`.claude/skills/`): `/page-audit` (single-screen review), `/component-reuse-check` (before any new component), `/state-audit` (codebase sweep for state-loss bugs — view-local `@State` holding user input, keyboard/chrome overlap, persistence gaps; pairs with `docs/release-qa.md`), `/ui-visual-verify` (**user-invoked only** — never auto-trigger; per §6 simulator conflicts under parallel agents). Trigger `/page-audit`, `/component-reuse-check`, and `/state-audit` proactively. `/ui-visual-verify` only when the user asks.
- **Visual references** (`docs/references/`): aesthetic taste is not text-encodable. Name the closest anchor before any non-trivial UI edit. If no anchor fits, ask before inventing.

### Order of operations for any UI task

1. §1 session-start checklist (docs + references).
2. New component? → `/component-reuse-check` first.
3. Make the edit. Hook fires automatically — fix blocks at the canonical layer.
4. Label result "edits applied, not yet verified — visual pass is yours" (per §6). Do **not** auto-run `/ui-visual-verify` or the simulator.
5. Single-screen review/polish? → `/page-audit` at start or end.

Audit mode (overnight cron) details: [`docs/claude/harness.md`](docs/claude/harness.md) §5.

---

## §9. Prose style — low-mana + Demiculus communication

All `.md` files in this repo and all chat replies follow two mental models:
- **Low-mana** (https://demiculus.com/low-mana/) — minimize the reader's mental energy. Narrow the ask, binary questions, point to specific lines, smaller focused units.
- **Communication** (https://demiculus.com/communication/) — instant graspability. Pyramid principle (conclusion first), 5-second rule, no euphemism/jargon/inflation, demand specificity, answer directly.

Mechanical enforcement: `.claude/hooks/prose-banned-list.sh` (PreToolUse on Edit/Write/MultiEdit, `.md` only, this repo only) warns — does not block — when these hit: *leverage, synergy, cross-functional, in order to, utilize, operationalize, incentivize, ideate, holistic, robust, seamless/frictionless, best-in-class, cutting-edge, thought leader, paradigm shift, circle back, touch base, low-hanging fruit, move the needle, deep dive, going forward, win-win, downsizing/rightsizing, very, basically/essentially/actually, simply.* Skipped paths: `docs/references/`, `.claude/plans/`, `node_modules/`.

For an explicit tightening pass: invoke the `/low-mana` skill.
