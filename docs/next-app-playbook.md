# Learnings from Unit (app #1) — read before the first commit of app #2

> Portable retrospective. Unit was the first app; this is what its design + build process taught, distilled into actions for the next one. Self-contained — you do not need the Unit repo open to use it.
>
> **How to use:** Do the Day-1 sequence (§5) before writing feature code. Keep §6 as the seed for app #2's own `CLAUDE.md`. Once absorbed, delete this file — its job is to seed, not to linger.

---

## 1. The one lesson behind all the others

Unit's cost was not too little upfront work. It was **load-bearing decisions left provisional and unenforced for ~6 weeks, then reversed at high cost.**

The right *artifacts* were there early — visual references on day 1, a `CLAUDE.md` on day 2. What was missing was a *lock* and a *machine to hold the lock*. The hook that finally stopped the design drift did not exist until week 4.5. The decision log and doc index did not exist until week 5. By then the same UI rules had been restated across 30+ sessions.

**Translation for app #2:** lock fewer things, lock them hard, and make the lock a hook — not something you have to remember each session.

---

## 2. The five root causes (with the actual evidence)

| # | What happened in Unit | The number | Fix for app #2 |
|---|---|---|---|
| 1 | Core product model was wrong, reversed late | A whole progression-engine + cycles architecture built then deleted; a Calendar tab built then killed (1,263 → 543 lines) for a <5% edge case | Write the one-sentence north star + the "does not ship" list *before* any feature code |
| 2 | Identity churned | Name changed once; bundle ID changed 3× (last because it wasn't available globally); deploy target iOS 26 → 18; voice "we" → "I" caught in week 5 and find-replaced everywhere | Lock name, check bundle-ID availability, pick deploy target by reach, pick voice — all in hour 1 |
| 3 | Design system sprawled, then got collapsed | The DS file reached 4,863 lines — ~26% of all app code — across 27 revisions; the standing note became "colors are too much, sizes too much, simplify" | Lock small foundation scales first; build only the ~6–8 primitives that compose everything |
| 4 | Visual bugs were the #1 blocker | Caused by token sprawl + new structs invented instead of reused + bugs patched per-screen so they recurred on siblings | Fix every visual bug at the atom/molecule layer, never the screen |
| 5 | Enforcement came last | Hook week 4.5; decision log + index week 5; after "30+ sessions of repeating the same rules" | Commit the harness as commit #2, before screen 1 |

Root cause 5 is why 1–4 survived so long. Build the machine first.

---

## 3. Two myths to drop (you held both)

**Myth: "collect more inspiration / explain the visual design better."** Unit *had* references on day 1. The gap was that they were not **binding** — nothing forced each screen to name the reference it borrowed from until a checklist arrived later. Fix: make "name the anchor" a required, enforced step from screen 1. Not more images — binding images.

**Myth: "finish the design system to 95%, then build screens."** This risks the opposite of Unit's failure. Unit's DS was *too big*, not too incomplete. A 95%-in-a-vacuum system means primitives you never use — and it still drifts, because completeness does not prevent parallel implementations; enforcement does. The version that works:

1. **Lock foundations small** — one scale each (~5 colors, ~4 type sizes, ~4 spacings, ~3 radii). This is the part you *can* finish upfront, and it is exactly where Unit sprawled.
2. **Build ~6–8 canonical primitives only** — screen wrapper, card, list-in-card, primary button, quiet/ghost button, row, sheet. The handful that compose everything.
3. **Turn the hook on before screen 1** — block raw values and new parallel structs.
4. **Fix bugs at the atom layer.**

The completeness that matters is *locked foundations + live enforcement*, not component coverage.

---

## 4. The design-system rules that earned their place

App-agnostic. They cost Unit weeks to discover; adopt them on day 1.

- **Extend > create.** Before any new view/modifier/variant, grep for the nearest primitive. If it covers ~80%, extend it with a parameter. A new primitive needs a one-line written justification. *Inventing a parallel component is worse than any hardcoded value — it bakes drift into the system itself.* This was Unit's single biggest recurring drift.
- **One canonical solution per concern.** One way to fade a scroll edge, one way to render a list-in-card, one "add X" trigger. Never fork; fix the canonical and migrate callers.
- **Native control, custom container.** Let the OS own the control logic (pickers, toggles, text fields, sheets, toolbar, search). Own only the visual container around it. Most "should this be custom?" debates die on this one line — write it down once so it is not re-litigated. Unit needed a whole "do not re-debate" table because this kept reopening.
- **Tokens are the only place raw values live.** No hex, no magic numbers, no raw font calls in screen code — anywhere except the one design-system file.
- **Atoms > molecules > screens.** A visual bug on one screen is almost always a token or component bug. Ask: "would this bug appear on sibling screens if I only patched this file?" If yes, fix it one layer up so every screen benefits at once.
- **Remove before adding.** Adding vs removing → remove. New variant vs reuse → reuse. Explaining in copy vs making it obvious → make it obvious, cut the copy. If a change grows the system, justify the growth out loud or do not ship it.

---

## 5. Day-1 sequence for app #2 (before any feature code)

1. **One sentence**: what the app is + the single metric every decision is judged by, plus one **"does not ship"** list. (Unit's metric: time-to-log a set under fatigue. Yours will differ — but name it, and judge every feature against it.)
2. **Lock identity in hour 1**: name, bundle-ID availability check (it is first-come-first-served globally), deploy target chosen by device reach not newest APIs, and the writing voice.
3. **Pin references** for every screen type you can foresee; make "name the anchor" a required step per screen.
4. **Lock foundation tokens** (small scales) and **build the 6–8 primitives. Then stop** — do not pre-build components you cannot yet justify.
5. **Commit the harness as commit #2**: the hook, a one-page `CLAUDE.md`, an empty decision log.

Then build screens: extend-not-create, fix bugs at the atom layer, log every scope or direction reversal as it happens.

The point: app #2 should *start* on day 1 where Unit only arrived in week 5.

---

## 6. What to port from Unit (the harness)

Recreate these in app #2 — they are the machine that holds the locks:

- **PreToolUse hook** (`.claude/hooks/ui-banned-list.sh` in Unit): blocks edits that introduce raw colors/fonts/spacings/radii or a new parallel `struct`/modifier into screen code (excluding the one design-system file). If it ever blocks legitimate work, fix the canonical primitive — never weaken the hook.
- **One-page `CLAUDE.md`**: north star + metric; "does not ship" fence; the §4 rules above; atoms-before-screens; verification discipline. Keep it tight — Unit's grew to need three spillover files; resist that.
- **Append-only `decision-log.md`**: one entry per scope/design/direction reversal — *Decision / Why / Implication*. Newest on top, never edit past entries. This is what stops re-litigating settled calls and re-running failed experiments.
- **A doc index** the moment you pass ~10 docs — Unit reached 85 docs with half of them invisible to fresh sessions before an index existed.
- **Verification discipline**: code-looks-right is not verification. Label work "applied, not yet verified" until something actually runs it. Do not say "done" off the diff alone.

---

*Source: derived from Unit's `docs/decision-log.md`, `docs/claude/{scope,design-system,harness}.md`, `CLAUDE.md`, and git history (2026-03-26 → 2026-05-13, 99 commits).*
