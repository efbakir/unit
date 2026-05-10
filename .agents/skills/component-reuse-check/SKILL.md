---
name: component-reuse-check
description: Pre-flight check before declaring any new SwiftUI struct/View/ViewModifier/variant in Unit. Use BEFORE writing the code, whenever the next edit will introduce a new `struct X: View`, a new `ViewModifier`, a new variant case in `DesignSystem.swift`, a new card / list / button style, or a new layout container. Also trigger if the user says "make a new component", "create a card", "build a view for X", "we need a Y picker", or anything that sounds like net-new UI surface. Returns either a recommended existing primitive to extend, or an explicit one-line justification template if a new primitive is genuinely needed. This is the single biggest drift in Unit (AGENTS.md §5 parallel-implementation ban) — run this skill *before* the diff, not after.
---

# /component-reuse-check

The most frequent drift in Unit is **inventing a parallel struct/modifier when extending the canonical one would do**. AGENTS.md §5 calls this out as the #1 failure mode. This skill runs *before* the new code is written and forces an explicit choice: extend an existing primitive, or justify the new one in one sentence.

Treat this as a gate, not a suggestion. If the skill recommends extending a primitive and you bypass it without an explicit user override, the work fails AGENTS.md §5.

## Input required

A description of what you're about to build. Either:
- "I'm about to create `struct CompactTemplateCard: View` for the templates list."
- "I want to add a new variant to `AppCard` called `tone: .stacked`."
- "I need a list row style with a leading icon and trailing weight badge."

If the input is ambiguous, ask one clarifying question before searching.

## Sources of truth

1. `Unit/UI/DesignSystem.swift` — the *only* file that may define new atoms, molecules, or modifiers
2. `docs/atomic-design-system.md` — the inventory of atoms and molecules with intended use
3. `AGENTS.md` §5 parallel-implementation ban — the rule being enforced
4. The closest existing call sites (grep for the proposed primitive's nearest cousin)

## Process

### 1. Inventory existing primitives (mechanical)
Grep `Unit/UI/DesignSystem.swift` for primitives of the same kind as the proposed component:

```bash
# Cards
grep -nE '^(public[[:space:]]+|internal[[:space:]]+)?struct[[:space:]]+App[A-Z][A-Za-z]*Card' Unit/UI/DesignSystem.swift

# Buttons
grep -nE '^(public[[:space:]]+|internal[[:space:]]+)?struct[[:space:]]+App[A-Z][A-Za-z]*Button' Unit/UI/DesignSystem.swift

# Lists / list rows
grep -nE 'AppDividedList|AppListRow|AppStacked' Unit/UI/DesignSystem.swift

# Modifiers
grep -nE 'extension View|^public func app[A-Z]|^func app[A-Z]' Unit/UI/DesignSystem.swift

# All structs
grep -nE '^(public[[:space:]]+|internal[[:space:]]+)?struct[[:space:]]+[A-Z]' Unit/UI/DesignSystem.swift
```

List every primitive that could plausibly cover the proposed use case. For each, name the variant API it currently supports (`tone:`, `style:`, `variant:`, `size:`).

### 2. ~80% match test
For each candidate primitive, ask: does this cover *at least 80%* of the proposed component's behavior with the parameters it already exposes?

- **Yes, with existing params** → use the primitive directly. No new code needed in `DesignSystem.swift`. Stop here.
- **Yes, with one new param** → extend the primitive with `style: .new` / `tone: .new` / `variant: .new`. Migrate any other callers if the new variant is more general than the old default.
- **No, not even close** → proceed to step 3.

### 3. Justification template (only if no primitive fits)
If no existing primitive covers ~80%, the new component requires an explicit one-line justification per AGENTS.md §5 rule 1. Format:

> New primitive: `[Name]`. Justification: [one sentence on why no existing primitive — `AppCard` / `AppDividedList` / `AppGhostButton` / etc. — could be extended. Reference the closest cousin and the specific behavior it cannot express.]

If you cannot write a one-sentence justification that passes the smell test, the answer is to extend an existing primitive. Iterate.

### 4. Placement decision
Even if a new primitive is justified:

- It goes in `Unit/UI/DesignSystem.swift`. Never in a `Features/**/*.swift` file. AGENTS.md §5: "Unit/UI/DesignSystem.swift is the only place raw values live" — and by extension, the only place new design-system primitives live.
- If the new primitive is genuinely screen-specific (used in exactly one screen, never reused), challenge that assumption: most "screen-specific" components turn out to be reusable molecules.

## Output format

```markdown
## Component reuse check — [proposed name]

### Existing primitives surveyed
- `AppCard(style:tone:padding:)` — [short summary of what it does today]
- `AppDividedList(style:)` — [short summary]
- ... [rest]

### Recommendation
**[USE EXISTING / EXTEND EXISTING / NEW PRIMITIVE]**

[If USE]: Use `AppX` with `style: .y, tone: .z`. No new code in DesignSystem.swift. Sample call:
```swift
AppCard(style: .stacked, tone: .neutral) { ... }
```

[If EXTEND]: Extend `AppX` with `style: .new`. Diff plan:
1. Add case `.new` to `AppX.Style`.
2. Branch on `.new` inside the body.
3. Migrate any `AppX(style: .old)` call sites where `.new` would be the better default.

[If NEW]: Justification: [one-sentence why no existing primitive could be extended].
Closest cousin: `AppX`. Why it doesn't work: [one specific behavior it cannot express].
Placement: `Unit/UI/DesignSystem.swift`.

### Confirmation needed from user?
[Yes / No. New primitives always need confirmation per AGENTS.md §5 Principle 2: "Creating a parallel component is an explicit decision that requires the user's okay."]
```

## What this skill does NOT do

- Does not write the code — it makes the reuse-vs-create decision and stops.
- Does not refactor existing primitives. If the audit recommends extending `AppCard`, the actual extension is a separate edit (and triggers the PreToolUse hook).
- Does not check business logic or data flow — purely a structural / DS question.

## Why this works

Three rules from AGENTS.md §5 enforce themselves through this skill:
- *"Default: extend > create. No silent new primitives."* — the justification template makes silence impossible.
- *"One canonical modifier per concern."* — the inventory step surfaces parallel modifiers.
- *"Fix the canonical, migrate callers, don't fork."* — the EXTEND path includes call-site migration.

The user has called this drift out repeatedly across 30+ sessions (see `feedback_unit_recurring_rules.md` rule 3). This skill catches it at the moment of decision instead of after the diff lands.
