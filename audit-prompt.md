# Task: Overnight App Audit for Unit

You are auditing the Unit iOS app. Your job is to check whether the current codebase and UI are aligned with the product compass, design system, and goals — and whether the app is App Store ready.

## Step 0 — Load context (in order)

Read these files in order before doing anything else:

1. `CLAUDE.md` — session-level intent doc (push-back mandate, scope fence, design system hard rules, harness)
2. `PRODUCT.md` — persona, voice, anti-references, design principles
3. `DESIGN.md` — palette, typography (Geist / Geist Mono), components, do/don't
4. `docs/product-compass.md` — strategic decisions, pillars, decision log
5. `docs/AGENTS.md` — UX rules, product model, scope fences
6. `docs/atomic-design-system.md` — atoms/molecules/organisms/templates rules
7. `docs/visual-language.md` — visual hierarchy + Gym Test visual rules
8. `docs/goals.md` — measurable targets and v1 scope boundaries
9. `docs/claude/scope.md` — full v1 ships / does-not-ship list and deleted files

Internalise the rules. Every finding you report must reference a specific rule from one of these files.

## Step 1 — Static code audit

Scan every `.swift` file under the project source directory (this repo currently uses `Unit/` for sources). Check for:

### Compass alignment

- [ ] Any UI that references "cycle", "week of", "week N of 8", or "weekly increase" as a required/prominent concept (should be demoted per `docs/product-compass.md` decision log 2026-03-26)
- [ ] Any active `ProgressionEngine` concepts surfaced in UI (should be deferred per compass + `docs/AGENTS.md`). Note: `Unit/Engine/`, `Cycle.swift`, `ProgressionRule*.swift`, and `Unit/Features/Cycles/` were deleted from the repo — flag any reintroduction.
- [ ] Any "Day N ·" prefixes that imply rigid day numbering (should use template/routine names only)
- [ ] Any social features, sharing, or community code (explicitly out of scope)

### Design system compliance

Use `docs/atomic-design-system.md` and `Unit/UI/DesignSystem.swift` as the enforcement surface. Flag:

- [ ] Raw colours (hex strings, `Color.black`, `Color.gray`, `.foregroundStyle(.gray)`, etc.) instead of `AppColor.*` (or other approved tokens)
- [ ] Raw fonts (`.font(.system(size: ...))`) instead of `AppFont.*` where appropriate
- [ ] Raw spacing/padding numbers instead of `AppSpacing.*` in new/updated code paths
- [ ] Raw corner radius values instead of `AppRadius.*`
- [ ] Any use of `chevron.right` or `chevron.forward` (banned)
- [ ] Any `Divider()` where `AppDivider` is required
- [ ] Any screen not wrapped in `AppScreen` (unless explicitly legacy/migration; still flag)
- [ ] Any inline button styling instead of `AppPrimaryButton` for primary CTAs
- [ ] Any inline card chrome instead of `AppCard` / `appCardStyle()`
- [ ] Any "0 kg" displayed for bodyweight exercises (should show "BW" or the DS-approved representation; never default to 0)

### Edge cases

- [ ] Zero templates (empty state)
- [ ] Exercise has no history (should show “No history yet”, not “0 kg”)
- [ ] Session interruption (force quit) — should be resumable
- [ ] Very long exercise names (truncation / wrapping)
- [ ] Very high weight values (e.g. 999 kg) (layout)
- [ ] Bodyweight exercises (BW not 0 kg)

## Step 2 — Build and screenshot

Build the app for the iOS Simulator and take screenshots. Prefer the following approach:

1. Determine the app bundle identifier from the built `.app` (via `Info.plist`) or from build settings.
2. Build for an iPhone simulator (default: iPhone 16 Pro).
3. Boot the simulator if needed.
4. Install the app to the booted simulator.
5. Launch the app.
6. Navigate to reachable screens manually (if you can) and capture screenshots using `xcrun simctl io booted screenshot ...`.

If navigation automation is limited, at minimum capture:

1. Today screen (empty state — no template)
2. Today screen (with template loaded)
3. Active workout / session screen (first set)
4. Active workout mid-workout (some sets complete)
5. Exercise list sheet (if present)
6. Templates/Program screen
7. Edit Template screen
8. History screen (list)
9. History screen (calendar/heatmap if present)
10. Settings screen

Save screenshots into `audit-screenshots/` (create the folder if missing).

## Step 3 — Visual audit

For each screenshot, check:

### Compass alignment (visual)

- Does the Today screen allow ≤ 2 taps to start logging? (Goal: `docs/goals.md`)
- Is “Week N of 8” / cycle progress prominent? (Should not be; compass 2026-03-26)
- Is “Weekly Increase” visible anywhere? (Should not be in v1)
- Does the session screen have a prominent Done action with large tap target? (Gym Test)
- Are last-time values visible (prefilled from last session)?
- Is the rest timer visible and positioned correctly (and triggered on Done)?
- Does history show one card per session (not one per exercise)?

### Design system (visual)

- Consistent card corner radius (`AppRadius.card`)
- Strong typography hierarchy (heading > body > caption) per DS + `docs/visual-language.md`
- Touch targets visually large enough (≥ 44pt)
- Spacing rhythm consistent (no cramped clusters, no arbitrary gaps)
- No chevrons visible (banned)
- Light-first appearance (no dark-mode-optimized UI)

### App Store readiness

- No placeholder texts ("Lorem ipsum", "TODO", "Test")
- No debug UI elements visible
- No broken layouts, clipping, or overlaps
- Every screen has a clear navigation path back
- Empty states are handled gracefully
- Branding is consistent (name, icon, copy tone)

## Step 4 — Write the report

Create `audit-report.md` with this structure:

```markdown
# Unit App Audit Report
**Date:** [today]
**Build:** Unit (simulator) — include commit hash if available

## Executive Summary
[2-3 sentences: is the app compass-aligned? Is it App Store ready? What's the #1 blocker?]

## Compass Alignment Score
[X/10 — how well does the UI reflect the current compass decisions?]

## Findings

### Critical (blocks App Store submission or contradicts compass)
[List each with: what, where (file + line or screen), which rule it violates, suggested fix]

### Major (significant UX or consistency issue)
[Same format]

### Minor (polish, edge cases)
[Same format]

## Design System Violations
| File | Line | Violation | Rule | Fix |
|------|------|-----------|------|-----|
| ... | ... | ... | ... | ... |

## Edge Case Coverage
| Scenario | Status | Notes |
|----------|--------|-------|
| Zero templates (empty state) | ✅/❌ | ... |
| No exercise history | ✅/❌ | ... |
| Session interruption recovery | ✅/❌ | ... |
| Long exercise names | ✅/❌ | ... |
| Bodyweight exercises | ✅/❌ | ... |
| Very high weight values | ✅/❌ | ... |

## Screenshots
[Reference each screenshot with its findings]

## App Store Readiness Checklist
- [ ] No placeholder text
- [ ] No debug UI
- [ ] All empty states handled
- [ ] All screens navigable
- [ ] No crashes on happy path
- [ ] Consistent branding
- [ ] Privacy policy link (if required)
- [ ] App icon present
```

Be thorough. Be specific. Reference file paths, line numbers, and exact rule names from the source documents. The goal is a report the user can wake up to and immediately start fixing things.

