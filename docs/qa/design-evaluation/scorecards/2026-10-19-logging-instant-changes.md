# Logging instant-change audit

**Date**: 2026-10-19
**Mode**: contextual
**Status**: provisional
**Evidence**: user-reported physical-device behavior on build81, source audit against3362661; no new runtime visual evidence.
**Anchor**: PlateSteps and PlateReveal, read-only Plate design-system Motion; existing Unit shared owners.

## Baseline
| Dimension | Weight | Score | Evidence | Top defect + exact fix | Layer | Blind spot |
|---|---:|---:|---|---|---|---|
| System fidelity | 25% | 7 | Existing motion/icon owners | Reuse circular icon instead of another drawing | Atom | Other primary-button consumers not rendered |
| Coherence/restraint | 20% | 7 | One CTA and saved outcome | Keep a single clear crossfade | Molecule | Current physical appearance |
| Craft | 20% | 5 | Repeated reported sharp swaps | Persist the CTA layers; animate opacity directly | Molecule | Perceived timing not measured |
| Gym Test | 25% | 6 | Existing immediate save path | Prevent layout replacement when strip overflows | Organism | Manual rapid-tap journey |
| Accessibility/verification | 10% | 5 | Existing motion gates and targets | Keep fades without spatial effects | Molecule | Runtime VoiceOver/Reduce Motion |

**Weighted baseline**:6.2/10. Original baseline retained; no post-change score or official pass claimed.

## Audit findings, worst first
Line references below name build81 source before these changes. Applied means source changed, not visually verified.

| Area/state | Evidence and cause | Owner correction | Status |
|---|---|---|---|
| CTA saved icon → text | DesignSystem.swift:1378–1393 conditionally inserts/removes the icon with ancestor-controlled animation; user reports sharp return | AppPrimaryButton keeps label/icon mounted and binds280ms opacity animation directly to each layer; removes quarter-size pop | Applied; runtime pending |
| Last-set CTA → next exercise | DesignSystem.swift:4152 clears saved state and advances in the same update, allowing old label to flash | Existing completion event returns whether navigation took over; an advancing card keeps its saved mark for its outgoing transition | Applied; runtime pending |
| Set strip becomes too wide | DesignSystem.swift:2192 ViewThatFits replaces a fitted row with another ScrollView hierarchy | SetProgressIndicator uses one horizontal ScrollView,44pt viewport, native short-content centering and animated current/final-set visibility | Applied; runtime pending |
| Edited set changes chip width | Existing strip animation watches states only, while edited kg/reps change without state changes | Same owner also animates chip-text layout changes with collectionChange | Applied; runtime pending |
| Last/history/planned → logged value | DesignSystem.swift:4302 sends an entire mixed sentence through150ms numericText | WorkoutCommandCard uses280ms opacity for mixed metric copy/colour; genuine counters retain numeric behavior | Applied; runtime pending |
| Empty weight → prepared target | DesignSystem.swift:4254 swaps different control branches directly | Existing metricHero wraps hint/numeric branches in a local identity-scoped blur/fade; reserved slot and input behavior retained | Applied; runtime pending |
| Rest play ↔ pause | Existing icon changes its systemName directly inside a stable row; capsule/icon disappearance uses shorter150ms timing | RestTimerControl uses native SF Symbol replace and280ms content fades; Reduce Motion/VoiceOver use opacity | Applied; runtime pending |
| Weight suffix kg/lb ↔ BW | Existing suffix Text changes directly | Existing editor’s suffix uses a local opacity transition; input typing is not animated | Applied; runtime pending |
| Circular confirmation artwork | Existing CTA uses AppIcon.checkmark while checkmarkFilled already exists | Reuse checkmark.circle.fill in monochrome: filled circle, transparent tick revealing button fill; same24pt size | Applied; runtime pending |
| Disabled/loading button states | Existing primary state changes use short feedback and conditional spinner | Shared owner crossfades state colours/text/spinner with content transition; pressed style remains crisp and unchanged | Applied; runtime pending |
| Adjust/supporting captions | Completed state replaces the whole metric Button with plain content; supporting opacity is outside its local animation modifier | Keep the metric control hierarchy stable, disable its action after completion, and bind caption opacity locally after the changing property | Applied; runtime pending |
| Timer/CTA/set-strip geometry | Build80 reserves existing touch/status/CTA slots and keeps timer outside exercise identity | Retained; no font/control/padding changes or new fixed-height card | Source reviewed; runtime pending |
| Alerts, keyboard, menus, sheet presentation | Native platform behavior | Retained; no custom keyboard animation, delayed save, new haptic or duplicated native transition | Source reviewed; runtime pending |

## Consumer scope
AppPrimaryButton is used directly in DesignSystem, OnboardingSplashView, SessionDetailView and TemplatesView, and indirectly through AppScreen/AppSheetScreen PrimaryButtonConfig (including onboarding/paywall/editor actions). The same enabled/disabled/loading/saved layer rules apply to each. SetProgressIndicator and mixed metric changes are workout-owned; rest control changes apply to WorkoutCommandCard and SessionStateBar. No page-specific button override or parallel component.

## Hard gates
| Gate | Result | Evidence |
|---|---|---|
| Source banned patterns | PASS | Static shared-owner guard |
| Touch targets | PASS | Existing60pt primary and44pt set-strip geometry retained |
| Text contrast | UNVERIFIED | Existing colour pairs retained; no rendered measurement |
| Non-colour meaning/reduced motion | UNVERIFIED | Circular check plus saved accessibility value; spatial gating source reviewed only |
| Gym Test | UNVERIFIED | No new delay in persistence/action; no runtime timing |
| Dead affordances | UNVERIFIED | Existing state/action guards retained; no runtime pass |
| Distinct state rendering | UNVERIFIED | No motion capture/screenshots this pass |
| Light/portrait | PASS | Existing shell settings unchanged |

## Carry forward
Inspect ordinary-set icon→label, last-set outgoing check→next exercise, first target save, a long strip, edited/removed/Undo chip, rest pause/resume and reduced motion. No new tests/Simulator runs, following the user’s instruction. This audit does not claim visual verification or a completed full-device matrix.
