# Unit — Design system rules (full detail)

> Spillover from `CLAUDE.md` §4. Read this before any UI change. The CLAUDE.md inline summary is enough for routine edits; this file has the full banned-list with rationale, the parallel-implementation ban examples, and the full gatekeeper checklist.

---

## The 5 principles (apply to every UI decision)

1. **Keep it simple.** Default to removing, not adding. Fewer tokens, fewer variants, fewer words, fewer screens. If a change grows the system, justify it out loud before shipping.
2. **Reuse components. Do not create new ones.** Before writing any new `View`, grep `Unit/UI/DesignSystem.swift` and the existing molecules/organisms. If something ~80% fits — use it or extend it. Duplicates are worse than imperfect reuse. *Creating a parallel component is an explicit decision that requires the user's okay.*
3. **Light mode only.** No dark-mode styling, no `.preferredColorScheme(.dark)`, no dark-first visual decisions. Tokens may have dark values for system compatibility, but visual review and screenshots happen in light mode.
4. **Portrait only.** The app does not rotate. Landscape is not supported.
5. **Gatekeeper every UI change.** Run the checklist below before Edit/Write on any `.swift` view file. Fail-closed.

---

## Parallel-implementation ban (the #1 current drift)

The most frequent recent failure mode: Claude **invents a new struct / helper / modifier / variant when extending the existing canonical one would do.** This is worse than any hex literal, because it bakes drift into the design system itself.

### Concrete violations from recent sessions (do not repeat)

- Created `AppStackedCardList` instead of extending `AppDividedList` with a `style:` param.
- Kept an `appScrollEdgeSoftTop(enabled:)` helper using `.automatic` when the only correct value is `.soft` and both edges should be covered — canonical is `appScrollEdgeSoft(top:bottom:)`.
- Added `.font(...).weight(.semibold)` on `TodayView` toolbar buttons while every other view used iOS-native default weight.
- Reached for `AppSecondaryButton(tone: .accentSoft, icon: .add)` where `AppGhostButton` was the right atom.
- Wrapped `.sheet` content in `ScrollView { AppCard { ... } }` — sheets already provide chrome.
- Fixed a LinearGradient fade inline on a screen when the canonical `appScrollEdgeSoft` already existed.

### Rules

1. **Default: extend > create.** Before declaring any new `struct X: View` (or new `ViewModifier`, or new variant token) in `Unit/UI/DesignSystem.swift`, grep the file for the closest existing primitive. If one covers ~80%, extend it with a `style:` / `variant:` / `tone:` param. If you still want to create a new one, state the justification in one sentence. *No silent new primitives.*
2. **One canonical modifier per concern.** `appScrollEdgeSoft(top:bottom:)` is now a pass-through compatibility entry point. Leave scroll-edge styling to SwiftUI defaults; do not force hard or soft effects (latest October 19 user correction). Never add a parallel `LinearGradient` mask to a `Features/**/*.swift` view to achieve the same effect.
3. **Fix the canonical, migrate callers, don't fork.** If the canonical helper is wrong, update it and its callers in the same change. Do not leave the old one limping while the new one ships.
4. **Toolbar chrome defers to iOS-native.** No `.weight(.semibold/.bold/.heavy)` on `ToolbarItem` buttons unless every toolbar in the app uses the same weight.
5. **Sheet roots are plain `VStack`.** `.sheet { }` content does not need its own `ScrollView` + `AppCard` wrapper. Sheets have chrome.

Cross-reference: `feedback_unit_scroll_edge_soft.md` in memory.

---

## Gatekeeper checklist (run before every UI Edit/Write)

- [ ] I opened `Unit/UI/DesignSystem.swift` and checked whether an existing atom/molecule/organism already fits.
- [ ] **For any non-trivial UI change, I named the visual anchor from `docs/references/`** (which file in `ios-screens/` or `details/` this change borrows rhythm/hierarchy/density from). If no reference fits, I asked the user before inventing. (See `docs/references/README.md`.)
- [ ] **If this change introduces a new component / UI pattern / behavior not already in the design system, I cited a source of truth before the diff** — repo first (`PRODUCT.md`, `DESIGN.md`, `docs/product-compass.md`, `docs/atomic-design-system.md`, `docs/visual-language.md`, `docs/AGENTS.md`, `Unit/UI/DesignSystem.swift`), web second (Apple HIG, lawsofux, NN/g, growth.design). If neither covers it, I asked the user before proceeding.
- [ ] **I am not adding a new `struct X: View` or new `ViewModifier` without a one-line justification** of why extending the nearest primitive wouldn't work.
- [ ] **I am not adding a parallel `LinearGradient` / `.mask` / `.scrollEdgeEffectStyle(.automatic, ...)`** when `appScrollEdgeSoft(...)` is the canonical modifier.
- [ ] The change introduces no new raw colors, fonts, spacings, or radii — only tokens.
- [ ] The change adds no net-new component without the user's explicit okay.
- [ ] The change is light-mode correct. No dark-mode-first decisions.
- [ ] The change does not assume landscape or rotated layout.
- [ ] If this is a bug fix, I confirmed whether the bug is at the atom/molecule layer. **If yes, I fix only `DesignSystem.swift` — not also the feature file.** (See `CLAUDE.md` §5.)
- [ ] If I edited a `ToolbarItem` button, I did not add `.weight(...)` unless I'm changing the convention app-wide in the same turn.
- [ ] If I edited `.sheet { }` content, the root is a plain `VStack` (no `ScrollView` / `AppCard` wrapper). Use `presentationDetents` for height.
- [ ] The screen is wrapped in `AppScreen`. All CTAs use `AppPrimaryButton`. Cards use `AppCard` / `appCardStyle()`. Navigation rows use shared disclosure; no raw glyph literals. No `Divider()` where `AppDivider` applies.
- [ ] Touch targets ≥ 44×44pt. No regular font weight. No orange `#FF4400` (accent is `0x0A0A0A`).
- [ ] Copy is explicit, not a `–` / `—` placeholder. Bodyweight shows "BW", not "0 kg".
- [ ] No `ProcessInfo.processInfo.environment["UNIT_*"]` / `UNIT_START_TAB` / `UNIT_AUTO_OPEN` screenshot-scaffolding left in `ContentView.swift` or any `Features/**/*.swift`. Revert temp scaffolding before turn end.

---

## Banned in view code (full list with rationale)

The hook (`.claude/hooks/ui-banned-list.sh`) enforces a subset of these mechanically. The rest are conventions Claude must enforce itself.

### Tokens, not raw values

- Hex literals, `Color(red:green:blue:)`, `Color.black/.white/.gray/.red/.green/.blue/.primary/.secondary`
- `.foregroundStyle(.gray)` / `.foregroundColor(.gray)`
- `.font(.system(size:...))`, raw `.font(.body/.caption/.title)` where an `AppFont.*` applies
- Hardcoded paddings (`.padding(16)`, `.padding(.horizontal, 20)`) — use `AppSpacing.*`
- Hardcoded corner radii — use `AppRadius.*`
- `regular` font weight
- Orange accent `#FF4400` (replaced by darkest black `0x0A0A0A`)

### Components, not inline chrome

- Raw `chevron.right` / `chevron.forward` literals; use shared navigation disclosure
- `Divider()` where `AppDivider` is required
- Inline button styling for primary CTAs — use `AppPrimaryButton`
- Inline card chrome — use `AppCard` / `appCardStyle()`
- Screens not wrapped in `AppScreen`
- `AppSecondaryButton(tone: .accentSoft, icon: .add, ...)` as a section "Add X" trigger — use `AppGhostButton`

### Canonical modifiers, not parallel implementations

- Inline `.scrollEdgeEffectStyle(...)` — route through `appScrollEdgeSoft(top:bottom:)`; this compatibility owner now leaves all edges at SwiftUI defaults.
- `LinearGradient` / `.mask` used as a fade under a fixed bar in `Features/**/*.swift` — use `appScrollEdgeSoft` only
- `.font(...).weight(.semibold/.bold/.heavy)` on `ToolbarItem` buttons — iOS-native default weight
- `ScrollView` or `AppCard` as the **root** child of `.sheet { }` — use plain `VStack` with `presentationDetents`
- Any new `struct X: View` / new `ViewModifier` / new variant added to `Unit/UI/DesignSystem.swift` **without an explicit one-line justification**

### Card composition

- `AppCard(contentInset: 0)` outside `Unit/UI/DesignSystem.swift` — produces 16pt text-from-edge instead of the canonical 24pt and collapses vertical inset to 0. The docstring reserves 0 for full-bleed media only. **Use `AppCardList` for any list-in-card surface.** Hook blocks this.
- `AppCard { … AppDividedList(…) … }` composed by hand outside `Unit/UI/DesignSystem.swift` — banned. **`AppCardList(data) { row }` is the canonical molecule** so card insets, divider insets, row horizontal padding, and row chrome cannot mismatch. Hook blocks this.
- Per-row shadowed cards in lists (one shadowed `AppCard` per row) — banned. The stacked variant of `AppDividedList` was deleted on purpose. A list is **one** `AppCard` containing rows separated by `AppDivider`, never N shadows in a column.

### Row-on-card recipe (the only "what goes inside an AppCard" pattern)

Any element nested inside `AppCard` (exercise rows, inline cells, chips inside a card body) follows this exact recipe — adopted 2026-04-27 from the Figma file as the canonical "row-inside-card" surface:

| Property | Token | Value |
|---|---|---|
| Background | `AppColor.cardRowFill` | `#F5F5F5` (light) |
| Radius | `AppRadius.sm` | 10 |
| Padding | `AppSpacing.sm` | 8 |
| Gap between sibling rows | `AppSpacing.sm` | 8 |
| Primary label | `AppFont.body` | 17 medium, `textPrimary` |
| Trailing / value label | `AppFont.caption` + `AppColor.textSecondary` | 15 medium, `#595959` |

**Do not** use `controlBackground` (`#E8E8E8`) for nested rows — `controlBackground` is intentionally darker and reserved for top-level controls / segmented inactive states. The outer `AppCard` itself stays at its defaults (24pt padding, 30pt radius, dual shadow); those already match Figma.

If a screen needs something that doesn't fit this recipe, push back per CLAUDE.md §2 and ask before introducing a new variant — adding ad-hoc fills inside cards is the parallel-implementation drift this section exists to prevent.

### Figma source of truth (card / row visual specs)

The canonical Figma file is `KvghAbkTdTmcfThMdp1S4p` (`Gym-app — Figma`), node **`166:8`** ("Day card — Push") — the source of truth for **padding, corner radii, shadow, and any element nested inside `AppCard`**.

URL: <https://www.figma.com/design/KvghAbkTdTmcfThMdp1S4p/Gym-app---Figma?node-id=166-8>

Fetch via the figma MCP (`get_design_context`, `get_screenshot`, `get_variable_defs`) before inventing a new card / row spec. When in doubt about card chrome or nested-row visuals, fetch this node first.

### Mode and orientation

- `.preferredColorScheme(.dark)` or any dark-mode-first styling decision
- Any landscape-only layout assumption

### Copy

- "0 kg" for bodyweight exercises (show "BW" or "No history yet")
- En-dash `–` / em-dash `—` as placeholder copy — write the explicit string

### Test scaffolding

- `ProcessInfo.processInfo.environment["UNIT_*"]` scaffolding committed in `ContentView.swift` or any `Features/**/*.swift` — test-only, must be reverted before turn end

---

## Single source of truth

`Unit/UI/DesignSystem.swift` is the **only** place raw values live. Every other file uses tokens. No exceptions without the user's explicit override.

---

## Native vs custom — the line (do not re-debate)

Two competing failure modes drift the codebase. **Both are equally bad.** This table closes the question.

| Surface | Use | Why |
|---|---|---|
| **Top toolbar — text buttons / icon buttons / titles** | iOS-native (`.toolbar { ToolbarItem }`, `Button`, `Label(systemImage:)`, `.navigationTitle`) | Defers to system styling, weight, and Dynamic Type. `appToolbarTextStyle()` exists for trailing text actions, but the chrome stays native. **Never apply `.weight(...)` to ToolbarItem buttons.** |
| **Sheet wrapper** | iOS-native (`.sheet(isPresented:)` / `.sheet(item:)`, `.presentationDetents`, `.appBottomSheetChrome()`) | The sheet shell is iOS. The *body* of the sheet is custom DS — wrap it in `AppSheetScreen`. **Never** put `ScrollView` or `AppCard` as the root child of `.sheet { }`. |
| **Search bar** | iOS-native via `.appExerciseSearchable(text:)` | Wraps `.searchable` to bake the canonical placement and animation. Pickers using search must use the sanctioned `List + .listStyle(.plain) + .appPlainListRowChrome()` recipe so the native search interacts with native scroll. |
| **Navigation chrome** | iOS-native (`NavigationStack`, `.navigationTitle`, `.navigationDestination`, `.appNavigationBarChrome()`) | Custom navigation has been deleted from the system. Don't reintroduce. |
| **System dialogs** | iOS-native (`.alert`, `.confirmationDialog`) | These are HIG modal primitives — never replace with a custom sheet. |
| **Inline option pickers (muscle group, equipment, etc.)** | iOS-native `Picker(...).pickerStyle(.menu)` **inside** a custom row (`AppListRow` or an `AppCardList` row) | The menu picker UI is iOS; the row chrome around it is DS. This is the row-on-card recipe: native control, custom container. |
| **Toggle (boolean preference)** | iOS-native `Toggle("", isOn:).labelsHidden().tint(AppColor.accent)` inside a custom row | Same rule as Picker: native control, DS row chrome. |
| **TextField (single-line)** | iOS-native `TextField(...)` styled with `.appInputFieldStyle()` | The text input itself is iOS; the surrounding fill / border / radius is DS. **Never** put a raw `TextField` in a `Form { Section }` — that pulls in iOS-native form chrome that fights the DS. |
| **TextEditor (multi-line)** | DS `AppTextEditor` | iOS `TextEditor` lacks placeholder support; `AppTextEditor` is the canonical multi-line input. |
| **Body content — buttons** | DS `AppPrimaryButton` / `AppSecondaryButton` / `AppGhostButton` only | Stress-screen CTAs must be Ink-on-Chalk; only the canonical primitives guarantee that. |
| **Body content — cards** | DS `AppCard` / `appCardStyle()` only | Bond-on-Milk fill contrast, 22pt radius, no shadow. Never `.background(...).clipShape(RoundedRectangle(...))` for card chrome. |
| **Body content — lists** | DS `AppCardList(data) { row }` (lists in card) or `AppDividedList` (lists outside card) | Hand-composed `AppCard { AppDividedList(...) }` is banned (hook blocks). |
| **Body content — sectioned forms / preference rows** | DS `SettingsSection` (title + AppCard wrapper) + `AppListRow(title:) { trailing }` | **Form { Section } is banned in feature code.** It produces native iOS form chrome that is off-system. |
| **Body content — segmented picker** | DS `AppSegmentedControl` only | The iOS `Picker(...).pickerStyle(.segmented)` is banned in feature code — visual style and animation diverge from `AppSegmentedControl` (which History / Settings / Today already use). |
| **Body content — dropdown chip** | DS `AppDropdownChip { Picker { … } }` | The chip is custom; the menu the chip opens is iOS-native. Both layers are right where they are. |
| **Body content — typography** | DS `AppFont.<case>.font` only | `.font(.system(...))`, `.font(.body)`, `.font(.title)`, `.fontWeight(...)`, `.bold()` are banned in feature code. |
| **Body content — colors** | DS `AppColor.<token>` only | `Color.black/.white/.gray/.primary/.secondary/.tertiary`, hex literals, `Color(red:green:blue:)` are banned in feature code. |
| **Body content — spacing / radii** | DS `AppSpacing.*` / `AppRadius.*` only | `.padding(<int>)`, `.cornerRadius(<int>)`, hardcoded `RoundedRectangle(cornerRadius: <int>)` are banned. `Spacer(minLength: 0)` is fine — zero is a valid escape, not a token. |
| **Body content — divider** | DS `AppDivider` only | Raw `Divider()` is banned in feature code. |
| **Body content — tab bar** | Native SwiftUI `TabView` / `UITabBar` chrome | Root tabs defer to the system for selection, state preservation, Dynamic Type, and accessibility. Do not recreate a custom tab bar. |
| **Body content — scroll-edge fade** | DS `appScrollEdgeSoft(top:bottom:)` only | Inline `LinearGradient` / `.mask` fades behind fixed bars are banned. |
| **Body content — set count / weight tweaks** | DS `AppStepper` | Native `Stepper` is too small for the Gym Test (44pt floor). |

**Read the table directionally:** the *control logic* is iOS-native (Picker, Toggle, TextField, sheet, toolbar, search). The *visual container* and the *chrome around the control* is custom DS (`AppListRow`, `AppCard`, `AppCardList`, `appInputFieldStyle`, `AppSheetScreen`, `appCardStyle`, `appNavigationBarChrome`). Drift happens when callers either reach for a native container (`Form`, `Section`, `Picker(.segmented)`) inside the DS world, or reinvent a control that iOS already provides.

If a request implies introducing a *new control type* not on this table, push back per CLAUDE.md §2 and ask before adding either layer.

---

**Prefer iOS-native over custom**: bottom sheets, tab bar chrome, buttons, arrows, navigation. Custom chrome only when system primitives genuinely can't express the design.
