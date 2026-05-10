---
name: page-audit
description: Audits a single SwiftUI screen in Unit against the design system, the references library, and the AGENTS.md gatekeeper checklist. Use whenever the user asks to "review", "audit", "check", "fix", or "polish" a specific screen (TodayView, HistoryView, TemplatesView, ActiveWorkoutView, OnboardingShell, etc.), shares a simulator screenshot of one screen, or says things like "make this consistent", "follow the system", "feels off on this page", "is this on-brand", "clean this up". Trigger even if the user does not say the word "audit" — if a single-screen visual review is implied, run this. Produces a severity-ranked report tied to atoms/molecules, not screens, so fixes land at the right layer.
---

# /page-audit

Audit one Unit screen end-to-end against the design system, the visual references, and the AGENTS.md gatekeeper checklist. Every finding is tied to a fix-level (atom / molecule / screen) per AGENTS.md §6 — fixing at the wrong layer is itself a violation.

## Input required

One of:
- A view file path: `Unit/Features/<area>/<Screen>View.swift`
- A simulator screenshot path
- A screen name the user mentioned (resolve to the file before starting)

If ambiguous, ask: "Which screen — the file path, or the simulator screenshot?"

## Sources of truth (read in this order, do not skip)

1. `AGENTS.md` §4 banned-list, §5 design-system rules, §6 fix-level, §7 verification gates
2. `Unit/UI/DesignSystem.swift` — every existing atom, molecule, modifier, token
3. `docs/atomic-design-system.md`
4. `docs/visual-language.md`
5. `docs/references/ios-screens/` and `docs/references/details/` — the visual taste anchors
6. The view file itself (if not already loaded)

If `docs/references/` has no anchor for this screen type, name that gap in the report. Do not invent visual decisions.

## Process

### 1. Load context
- Open the view file. Read it end to end.
- Open `Unit/UI/DesignSystem.swift` and grep for any atoms or modifiers the screen *should* be using but isn't.
- List `docs/references/ios-screens/` and pick the closest anchor. Name it.

### 2. Banned-list scan (mechanical)
The PreToolUse hook (`.Codex/hooks/ui-banned-list.sh`) blocks new violations. The audit catches existing ones. Check for:

- `chevron.right` / `chevron.forward`
- Hex literals, `Color(red:..)`, `Color.black/.white/.gray/etc.`
- `.foregroundStyle(.gray)` / `.foregroundColor(.gray)`
- `.font(.system(size:))`, raw `.body`/`.caption` where `AppFont.*` exists
- Hardcoded `.padding(<int>)` / `.cornerRadius(<int>)` / `RoundedRectangle(cornerRadius: <int>)`
- `.preferredColorScheme(.dark)`, dark-mode-first decisions
- `.scrollEdgeEffectStyle(.automatic)` / `.hard` (canonical: `appScrollEdgeSoft(top:bottom:)`)
- `LinearGradient` / `.mask` used as a fade behind a fixed bar
- `.weight(.regular)`, `#FF4400`, `0xFF4400`
- `Text("–")` / `Text("—")` / `Text("0 kg")` placeholder copy
- `ToolbarItem` with `.weight(.semibold/.bold/.heavy)`
- `.sheet { }` whose root is `ScrollView` or `AppCard`
- `ProcessInfo.processInfo.environment["UNIT_*"]` scaffolding

### 3. Parallel-implementation scan
For every `struct X: View` / `ViewModifier` / new variant defined in feature code: name the closest existing primitive in `DesignSystem.swift`. If a primitive covers ~80%, this is a §5 parallel-ban violation. Recommend: extend the primitive with `style:` / `tone:` / `variant:` and migrate the call site.

### 4. Layout / rhythm / hierarchy review
With the named reference open alongside the screen:
- Section header weight + casing — match reference?
- List row height + divider treatment — match reference?
- Spacing rhythm (vertical) — uniform or jumpy?
- Number alignment — `.monospacedDigit()` on dynamic numbers?
- Empty state — explicit copy, or placeholder dash?
- Sheet content — plain `VStack`, not `ScrollView { AppCard { ... } }`?
- Toolbar buttons — iOS-native default weight?
- Touch targets — ≥ 44×44pt?

### 5. Fix-level classification (AGENTS.md §6)
For each finding, ask: would this same bug appear on sibling screens if I patched only this file?

- **Atom-level** — token wrong (color, spacing, radius, font). Fix in `DesignSystem.swift`. One change, every screen benefits.
- **Molecule-level** — shared component wrong (`AppCard`, `AppDividedList`, `AppPrimaryButton`, etc.). Fix in `DesignSystem.swift` molecule definition.
- **Screen-only** — composition wrong on this screen alone (wrong atom chosen, wrong order). Fix in the feature file.

If a finding could be screen-only OR atom — prefer atom. Screen-only is the last resort, not the default.

### 6. Verification plan
Before declaring done, the next agent must:
- Build + install + launch on iOS Simulator (per §7).
- Screenshot the audited screen via `xcrun simctl io booted screenshot`.
- Screenshot at least 2 sibling screens to confirm atom/molecule fixes haven't regressed anything else.
- Compare against the named reference.

If the user has waived verification (background/scheduled run — see `feedback_unit_background_verification_waiver.md`), state that explicitly and skip.

## Output format (use exactly)

```markdown
# [Screen name] — page audit

**Anchor reference**: docs/references/ios-screens/<file>.png — borrowing [rhythm / hierarchy / density / specific element]
**Sources consulted**: AGENTS.md §[sections], DesignSystem.swift, [other docs]

## Banned-token violations
| File:Line | Violation | Fix |
|---|---|---|
| ... | chevron.right at row trailing | Use AppDisclosureIndicator or remove |

## Parallel-implementation risks
| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|

## Atom/molecule fixes (system-level — fix here, every screen benefits)
| Layer | File | Issue | Recommended change |
|---|---|---|---|
| atom  | DesignSystem.swift | AppSpacing.md is 12pt, ref shows 16pt rhythm | Bump to 16pt; check 3+ sibling screens after |
| molecule | DesignSystem.swift (AppCard) | shadow too heavy vs ref | Soften to AppShadow.subtle |

## Screen-only fixes (last resort)
| File:Line | Issue | Recommended change |
|---|---|---|

## Layout / rhythm / hierarchy notes
- [Concrete observations vs the named reference. Bullets, not paragraphs.]

## Verification plan
1. Apply atom/molecule fixes first. Build.
2. Screenshot [audited screen] + [2 named sibling screens].
3. Compare against [reference file].
4. Then apply screen-only fixes.

## Reference gap
[If `docs/references/` had no good anchor, say so. Suggest what reference image would close the gap, e.g. "Need a reference for stats-heavy detail screens — Apple Sports live game would be a fit."]
```

## What this skill does NOT do

- Does not run the build or take screenshots itself — it produces the audit report. Verification is a separate step (see `xcode-bug-hunter` skill or §7 verification gates).
- Does not auto-apply fixes. Recommendations only. The user or a follow-up turn applies them.
- Does not audit business logic, data integrity, or crashes. That is `xcode-bug-hunter`'s job. Page-audit is purely visual + design-system.

## Why this works

Aesthetic drift is invisible at the diff level. The hook catches the mechanical banned list. This skill catches everything the hook can't — rhythm, hierarchy, fix-level, anchor adherence — by forcing a structured pass against the named reference and the design system in one place. AGENTS.md §5 says "fail-closed: if a gate fails, fix it before proceeding"; this skill makes the gates explicit per screen.
