# Unit v2 release audit — 2026-06-20

Code-level visual, interaction, and release-risk audit. No simulator was run; screenshots remain the verification gate.

## Release verdict

**Do not submit this build yet.** The highest-risk defects affect stored weight, data retention, onboarding trust, purchase management, and the first-run visuals.

| Severity | Finding | Evidence | User impact |
|---|---|---|---|
| P0 | Pound entries are saved without converting back to kilograms | `ActiveWorkoutView.swift:1424`, `:1481`, `:1055`; formatter converts stored values again in `WorkoutTargetFormatter.swift:14-29` | Entering 225 lb can render as about 496 lb and corrupt history/PRs |
| P0 | The v2 onboarding carousel assets are empty | `MarketingShotLogging`, `MarketingShotProgram`, and `MarketingShotPrivacy` imagesets contain only `Contents.json`; fallback at `OnboardingSplashView.swift:338-377` | All three value slides ship as blank phone placeholders with a photo icon |
| P0 | A persistent-store open error deletes the local database | `UnitApp.swift:50-55`, `:83-98` | A migration/corruption/open failure can erase the user's entire training history |
| P0 | v1 says core logging is free; v2 immediately hard-locks every existing user | `ContentView.swift:55-77`; public v1 App Store description | Updating can turn a free local notebook into an undisclosed non-dismissible subscription wall |
| P1 | “Start your first workout” opens the paywall, not a workout | `OnboardingProgramPreviewView.swift:66`; `ContentView.swift:55-77` | The primary onboarding CTA is behaviorally false at the highest-trust moment |
| P1 | Existing subscribers cannot manage their subscription in-app | `SettingsView.swift:158-167`, `:225-259` | The Subscription section exists but is deliberately not rendered in v2 |
| P1 | Paywall mixes localized StoreKit pricing with hardcoded USD copy | `PaywallView.swift:199-224` | Turkish and other non-US users can see a local price beside “~$5/mo” and an unverified “Save 50%” |
| P1 | Planned set count is overridden by the most recent logged count | `ActiveWorkoutView.swift:1210-1224` | Finishing early with one set can make the next workout stop at one set; the template plan is ignored |
| P1 | Deleting exercises/programs damages historical labels | `ExercisesListView.swift:174-181`; `TemplatesView.swift:475-483`; history resolves names from live models | Past sessions degrade to generic “Exercise” / “Workout” after deletion |
| P1 | History marks scheduled weekdays as missed before the user owned the program | `TrainingWeekProgress.swift:168-194` | Browsing older months can show an invented backlog of missed workouts |
| P1 | Onboarding says schedule can be changed later, but no editor exists | `OnboardingScheduleView.swift:63`; no post-onboarding write to `scheduledWeekday` | Users are locked into the onboarding schedule unless they rebuild data |
| P1 | Weighted sets can be saved with no weight; entering 0 temporarily reads as BW | `ActiveWorkoutView.swift:1424-1443` | A Bench Press set can be stored as zero and then display “No prior sets” despite being logged |
| P1 | Parser review cannot correct names, sets, or reps | `OnboardingProgramPreviewView.swift:126-180` | Misparsed defaults can only be noticed via an unexplained star and are committed before the paywall |
| P1 | Stale sessions cannot be resumed | `TodayView.swift:128-145`, `:301-338` | Returning to a valid previous-day workout forces Mark Complete or Discard |
| P2 | Default rest time is 30 seconds and resets each workout | `ActiveWorkoutView.swift:23` | Strength users repeatedly tap `+30` to reach a usable rest period |
| P2 | Onboarding progress denominator changes after path choice | `OnboardingView.swift:303` | A paste user sees 1/4, then the flow changes to 3/5 |
| P2 | Onboarding state restores data but always restarts at the splash | `OnboardingView.swift:181`, `:211` | A quit preserves fields but forces the user to replay the whole navigation path |
| P2 | Library VoiceOver hint describes a removed 1RM screen | `OnboardingLibraryPickerView.swift:65` | Accessibility users receive false next-step guidance |
| P2 | Freestyle completion may remove the view before its rename alert appears | `ActiveWorkoutView.swift:632-644`, `:1186-1191` | The optional workout-name prompt can flash or never appear |
| P2 | Canceled freestyle sessions can leave hidden templates behind | `FreestyleSessionSupport.swift:20-31`; cleanup ignores non-empty orphans | Repeated cancel flows accumulate invisible data |

## Design critique

### What works well

- The active workout keeps one current command surface and preserves the one-tap Last time path.
- Tokens, touch targets, motion reduction, native toolbar behavior, and the banned-token scan are consistently handled.
- Program, history, and exercise lists mostly reuse `AppCardList`, `PreviewListRow`, and shared sheet atoms.
- v1 communicates the logging mechanism clearly once the screenshots reach the active-workout examples.

### Issues

- The product promise and the v2 handoff are no longer honest: “Start” means “subscribe,” and “works offline” is not true for a new user who reaches an unloaded hard paywall.
- Onboarding demonstrates value with placeholder images, then prevents correction of most parsed data.
- Several trust failures are irreversible or hidden: local-store reset, destructive history labels, pounds corruption, and retroactive missed days.
- Secondary surfaces have drifted: one custom history sheet, two exercise-progress implementations, stale subscription settings, and feature-local motion/page-dot primitives.

### Suggested improvements

- Block submission on the P0/P1 data and purchase defects.
- Make the paywall handoff explicit and truthful before the final onboarding tap.
- Let users review and correct every parser-derived field before committing.
- Preserve historical display names independently of editable/deletable templates and exercises.
- Treat schedule and rest duration as editable preferences, not onboarding-only decisions.

### Quick wins

- Add the three real carousel images or remove the image region entirely.
- Change the final onboarding CTA to accurately describe the paywall handoff.
- Re-enable Settings subscription management.
- Remove hardcoded `$5/mo`, “Save 50%,” and stale 1RM accessibility copy.
- Add “Continue workout” to the stale-session alert.

### Strategic improvements

- Add a non-destructive SwiftData recovery/migration policy before promising local trust.
- Define one canonical exercise-progress page and delete the unused duplicate.
- Add program creation dates or schedule effective dates before showing missed history.
- Update the v2 App Store listing before release; the v1 free-forever copy cannot remain.

## Component reuse check — release audit remediation surfaces

### Existing primitives surveyed

- `AppSheetScreen` — canonical sheet title, dismiss action, scrolling, and sticky CTA.
- `AppCardList` / `AppCardListAddRow` — canonical grouped rows and add affordance.
- `AppSegmentedControl` — already expresses weekday and small-option selection.
- `SettingsSection` + `AppDividedList` — already express subscription management rows.
- `AppGhostButton`, `AppSecondaryButton`, `AppPrimaryButton` — already cover retry, inline, and dominant actions.
- `AppToast` — already covers reversible removals and short confirmation.
- `AppEmptyHint` / `EmptyStateCard` — already cover empty and load-failure messaging.

### Recommendation

**USE EXISTING**

No remediation in this audit requires a new UI primitive. Use `AppSheetScreen` for the history summary, `SettingsSection` for subscription management, `AppSegmentedControl` for schedule editing, and existing buttons for retry/resume actions. Fix the existing canonical molecule when behavior is shared.

### Confirmation needed from user?

No. No new primitive is recommended.

---

# OnboardingSplashView — page audit

**Anchor reference**: `docs/references/ios-screens/bevel__onboarding-fitness.png` — borrowing full-screen hierarchy and a single clear continuation action
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, PRODUCT.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| `OnboardingSplashView.swift:234` | `ParallaxEntry: ViewModifier` | `appScreenEnter` / `AppMotion` | Move the canonical behavior to `DesignSystem.swift` or remove it |
| `OnboardingSplashView.swift:382` | `PageDots` | native page control | Explicitly justify/promote it; it is currently feature-local primitive chrome |
| `OnboardingSplashView.swift:338` | `MarketingSlideImage` | `AppCard` surface tokens | Keep only if the real assets ship; do not ship the placeholder fallback |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `DesignSystem.swift` motion | Splash owns a parallel ViewModifier | Centralize or remove the modifier |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `OnboardingSplashView.swift:338-377` | All three imagesets are empty | Add final assets or remove the image frame before release |
| `OnboardingSplashView.swift:25-169` | Forced 1.4s opener plus auto carousel delays setup | Let the user continue immediately; keep motion optional |

## Layout / rhythm / hierarchy notes

- The carousel structure is clear, but empty phone frames make the build look unfinished.
- The opener, three auto-advancing slides, and setup flow are long before a non-dismissible paywall.
- Reduce Motion is honored.

## Verification plan

1. Replace/remove placeholders.
2. Screenshot opener plus all three slides at iPhone SE and a current Pro size.
3. Compare against `bevel__onboarding-fitness.png` and the v1 App Store sequence.
4. Verify Reduce Motion and Dynamic Type.

## Reference gap

Need a light-mode, no-account utility onboarding reference without sign-in chrome.

---

# Onboarding setup screens — page audit

**Anchor reference**: `docs/references/ios-screens/linear__create-issue-sheet.png` — borrowing compact input hierarchy and clear validation
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| `OnboardingShell.swift:268` | `OnboardingProgressBar` in feature code | typography/progress atoms | Move to `DesignSystem.swift` if retained as shared onboarding chrome |
| `OnboardingView.swift:376` | `OnboardingFlow` | `AppScreen` + motion tokens | Keep as page coordinator, but do not fork another transition container |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `OnboardingShell` | Progress total changes between paths | Use path-neutral progress until the method is selected |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `OnboardingView.swift:181,211` | Draft restores to splash, not the saved step | Persist/restore the current step and navigation history |
| `OnboardingScheduleView.swift:63` | “change this later” is false | Add a post-onboarding schedule editor or remove the promise |
| `OnboardingLibraryPickerView.swift:65` | Stale 1RM VoiceOver hint | Describe the actual preview step |

## Layout / rhythm / hierarchy notes

- Unit/import option tiles are simple and coherent.
- Seven-segment weekday controls repeated per routine become dense on 5-7 day programs.
- Disabled CTA reasons are explicit where needed.

## Verification plan

1. Test both 4-step and 5-step paths.
2. Screenshot unit, import method, schedule, and library screens.
3. Verify largest Dynamic Type and VoiceOver hints.
4. Force-quit mid-flow and confirm exact restoration.

## Reference gap

Need a reference for multi-row weekday assignment at accessibility sizes.

---

# OnboardingProgramPreviewView — page audit

**Anchor reference**: `docs/references/ios-screens/hevy__workout-tab.png` — borrowing program/routine hierarchy, not its blue styling
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, decision-log.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Uses `AppDisclosureCard`, `AppDividedList`, and `AppInlineWeightField` | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `AppInlineWeightField` | Empty input has no visible meaning or validation | Add accessible empty/error semantics if the field remains optional |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `OnboardingProgramPreviewView.swift:66` | CTA says workout but opens paywall | Use truthful handoff copy |
| `:126-180` | Names/sets/reps are not editable | Allow correction before commit |
| `:159-163` | Star has no visible legend | Replace with explicit row-level warning/action |
| `:255-278` | Warning gives counts, not affected lines | Show the exact lines or fields requiring review |

## Layout / rhythm / hierarchy notes

- Collapsed day cards keep long programs manageable.
- Only the first day expanded is a good default.
- “From:” source lines and parser notes described in the model comments are not rendered, so visual review cannot catch silent parser errors.

## Verification plan

1. Test a clean paste, noisy paste, conditioning lines, and library program.
2. Screenshot expanded/collapsed and warning states.
3. Confirm all parsed fields can be corrected before commit.
4. Verify CTA destination and copy match.

## Reference gap

Need a reference for reviewing AI/parser-transformed structured data before commit.

---

# PaywallView — page audit

**Anchor reference**: `docs/references/ios-screens/opal__trial-paywall.png` — borrowing tier clarity and legal disclosure placement, not dark styling
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, pricing.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Uses `AppSelectableTierCard` and `AppScreen` | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `AppSelectableTierCard` | Verify equal-height and selection state at large Dynamic Type | Fix in the card if clipping occurs |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `PaywallView.swift:199-224` | Localized price mixed with USD sublabel/discount | Derive all comparative copy from StoreKit or remove it |
| `:82-86` | Empty products can flash failure before load starts | Represent initial/loading/failed states explicitly |
| `:302-304` | Restore can silently no-op while loading | Disable with progress or queue the restore |
| `ContentView.swift:55-77` | v1 users are hard-locked on update | Ensure App Store disclosure and migration communication are explicit |

## Layout / rhythm / hierarchy notes

- Benefit list, tiers, disclosure, footer, and sticky CTA are structurally sound.
- Six benefits plus three plans plus disclosure is dense; the tier choice should remain above the fold on smaller phones.
- “Annually” should be “Annual” for consistency with the disclosure.

## Verification plan

1. Screenshot loading, loaded, failure, restore, and purchase-pending states.
2. Test Turkish storefront/localized prices.
3. Test iPhone SE and largest Dynamic Type.
4. Verify Terms, Privacy, Restore, and subscription management paths.

## Reference gap

Need a light-mode hard-paywall reference with no trial and three recurring tiers.

---

# TodayView — page audit

**Anchor reference**: `docs/references/ios-screens/alma__home.png` — borrowing one dominant hero card and restrained supporting density
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, PRODUCT.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Hero reuses `EmptyStateCard` and `PreviewListContainer` | — | Keep existing primitives; consider renaming only if semantics become misleading |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `EmptyStateCard` | Used for empty, ready, and rest-day states | Confirm the molecule supports active hero semantics without empty-state styling drift |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `TodayView.swift:128-145` | Stale alert has no resume option | Add Continue workout |
| `:231-258` | Rest day has no inline action | Surface Choose routine in the hero instead of relying on a small toolbar icon |

## Layout / rhythm / hierarchy notes

- Start remains the dominant action in the ready state.
- Off-schedule training is less discoverable than scheduled training.
- Stale-session handling interrupts before users can inspect/resume their work.

## Verification plan

1. Screenshot no program, incomplete, ready, rest day, override, and stale-session states.
2. Compare hero rhythm to `alma__home.png`.
3. Verify start in two taps and off-schedule recovery.
4. Test long titles and large Dynamic Type.

## Reference gap

Need a reference for a quiet rest-day state with an optional train-anyway action.

---

# ActiveWorkoutView — page audit

**Anchor reference**: `docs/references/ios-screens/future__live-session.png` — borrowing one hero metric, one dominant action, and bottom session state; `hevy__active-workout.png` for expected data only
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, PRODUCT.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| `ActiveWorkoutView.swift:1375` | `AdjustResultSheet` | `AppSheetScreen` + input atoms | It already composes the canonical sheet; do not create another set editor |
| `:1625` | `SetCountPickerSheet` | `AppSetRepEditorSheet` / `AppSegmentedControl` | Keep only if set-only selection remains materially distinct |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `WorkoutCommandCard` | Must represent a zero-weight non-BW set coherently or disallow it | Fix validation/display contract at the shared molecule boundary |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `ActiveWorkoutView.swift:1424-1481` | lb input saved as kg | Convert display input to kg before persistence |
| `:1210-1224` | History overrides template set count | Prefer explicit template plan; history is fallback only |
| `:23` | 30-second default resets | Persist a sensible user preference |
| `:632-644` | Finish then rename alert races view removal | Capture name before completion or present rename from the parent |
| `:699-701` | Any disappearance stops timer/live activity | Restrict stop to finish/cancel, not generic disappearance |

## Layout / rhythm / hierarchy notes

- The single-command-card paradigm is aligned with the Gym Test.
- Progression suggestion chips weaken “history, not instructions”; keep them subordinate and verify they do not crowd the hero.
- Warm-up reminder plus next-exercise bar creates two bottom layers on the first set.

## Verification plan

1. Test kg/lb, BW, weighted BW, blank weight, and zero weight.
2. Screenshot first set, rest running/paused/ready, PR, completed exercise, and finish.
3. Switch app state during rest and confirm Live Activity continuity.
4. Verify one-tap logging stays under three seconds.

## Reference gap

Current references cover the command card well; need a light-mode reference for editable completed-set chips.

---

# TemplatesView / ProgramDetailView — page audit

**Anchor reference**: `docs/references/ios-screens/hevy__workout-tab.png` — borrowing program grouping, routine preview density, and active-workout resume affordance
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Uses `AppCard`, `AppCardList`, `PreviewListRow`, and canonical buttons | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `PreviewListRow` | Rows have intentionally no chevron, so tap affordance depends on styling | Verify pressed state and accessibility hint are sufficient across program lists |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `TemplatesView.swift:475-483` | Delete program removes names used by history | Archive/snapshot names; warn accurately |
| `TemplatesView.swift:266-275` | Scheduled routines cannot be reordered or rescheduled | Add explicit schedule editing with existing segmented control |

## Layout / rhythm / hierarchy notes

- One active-program card plus inactive-program list has clear hierarchy.
- Freestyle is visually quiet but may be too easy to miss for users without today's scheduled routine.
- Active workout recovery through the sticky CTA is good.

## Verification plan

1. Screenshot active, inactive, empty, and active-workout states.
2. Test long program/routine names.
3. Delete a program and inspect historical sessions.
4. Verify schedule editing once added.

## Reference gap

The Hevy structural anchor is sufficient.

---

# TemplateDetailView — page audit

**Anchor reference**: `docs/references/ios-screens/hevy__workout-tab.png` — borrowing routine list density while retaining Unit's chevron-free rows
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Reuses `AppCardList`, `AppSetRepEditorSheet`, and `AppExercisePickerSheet` | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `AppCardList` row interaction | Drag, edit, and remove coexist in one row | Verify gesture priority in the canonical reorder modifier |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `TemplateDetailView.swift:70-79` | Custom principal title and hidden toolbar background diverge from canonical nav chrome | Use the native truncated title plus `appNavigationBarChrome()` |

## Layout / rhythm / hierarchy notes

- Targets are compact and aligned.
- Edit target, drag, and remove are dense but maintain 44pt targets.
- Immediate remove with Undo is preferable to a confirmation for this reversible action.

## Verification plan

1. Screenshot empty and populated routines.
2. Test edit/drag/remove gesture conflicts.
3. Verify nav-bar scroll transition against sibling detail screens.
4. Test long exercise names and accessibility sizes.

## Reference gap

Need a reference for drag-reorder rows with a separate remove action.

---

# RecentSessionsView — page audit

**Anchor reference**: `docs/references/ios-screens/apple-sports__featured-games.png` — borrowing grouped-card row rhythm; v1 screenshot 4 for Unit's calendar intent
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| `HistoryView.swift:636-670` | `SessionSummarySheet` | `AppSheetScreen` | Replace custom `NavigationStack + ScrollView` sheet shell |
| `:617-634` | `EarlierWeekRoutineRow` | `AppSessionHighlightCard` + existing button | Keep composition, but expose the action visibly |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `AppSessionHighlightCard` | A tappable “Missed” card has no visible Start affordance | Add an existing button/action slot if this pattern repeats |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `TrainingWeekProgress.swift:168-194` | Missed days have no schedule effective date | Bound missed status to program/schedule creation |
| `HistoryView.swift:622` | Tapping a missed-history card starts a workout without explicit CTA copy | Add a visible Start action |
| `:21-24,303-319` | Partial/Skipped filters are mostly unreachable in normal flow | Remove dead filters or define/persist those states intentionally |

## Layout / rhythm / hierarchy notes

- List/calendar switch is clear.
- Four filter chips plus two modes adds more state than the available history states justify.
- Calendar day color is paired with borders/labels for accessibility.

## Verification plan

1. Screenshot empty, list, calendar, filtered-empty, missed, and multi-session days.
2. Browse months before program creation.
3. Verify explicit start behavior for missed routines.
4. Compare grouped rows to the Apple Sports anchor.

## Reference gap

Need a light-mode calendar-history reference with missed versus completed states.

---

# SessionDetailView — page audit

**Anchor reference**: `docs/references/ios-screens/apple-sports__match-detail-sheet.png` — borrowing compact hierarchy for read-only event detail
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Uses `AppCardList` and shared `SessionExerciseSummary` | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `SessionExerciseSummary` | Summary formatting is shared by full screen and sheet | Keep one implementation and fix there |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `SessionDetailView.swift:45` | Exercises sort alphabetically, not in workout order | Preserve the recorded/template order |
| `TemplatesView.swift:475-483` | Deleted template names become “Workout” | Snapshot session display names |

## Layout / rhythm / hierarchy notes

- Session name/date hierarchy is clear.
- Uniform sets collapse cleanly; non-uniform sets expand with aligned metrics.
- Alphabetical ordering breaks the user's memory of workout sequence.

## Verification plan

1. Screenshot uniform, mixed-set, notes, PR, and missing-model states.
2. Verify order matches the workout.
3. Delete an exercise/program and inspect the detail.
4. Test large Dynamic Type.

## Reference gap

The Apple Sports event-detail reference is sufficient for hierarchy.

---

# ExercisesListView / ExerciseDetailView — page audit

**Anchor reference**: `docs/references/ios-screens/hevy__exercise-picker.png` and `hevy__exercise-detail.png` — borrowing picker row hierarchy and sparse chart treatment
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| `ExercisesListView.swift:401` | Fallback `"-"` placeholder | Use explicit copy or eliminate unreachable fallback |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| `ExerciseProgressView.swift:11` | Entire second exercise-progress page | `ExerciseDetailView` | Consolidate and delete the unused duplicate |
| `ExercisesListView.swift:186` | `ExerciseFilterChips` | `AppFilterChipBar` | Screen-specific composition is acceptable; do not promote another filter primitive |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `AppCardList` / chart section | Exercise detail hand-builds past-session rows inside `appCardStyle()` | Use canonical grouped-list primitives |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `ExercisesListView.swift:174-181` | Delete removes historical name source | Archive exercises or snapshot names; warn about history |
| `:374-376` | Detail includes active sessions and warmups | Match completed, non-warmup history rules |
| `:366-505` | Detail and dead `ExerciseProgressView` disagree on metrics/formulas | Pick one canonical definition |

## Layout / rhythm / hierarchy notes

- Search and muscle/equipment filters align with the reference.
- Two horizontal filter rows consume substantial vertical space before results.
- Chart hierarchy is readable but lacks axis formatting consistency and unit-aware labels.

## Verification plan

1. Screenshot default, filtered, no-results, custom exercise, and detail states.
2. Test delete with historical sessions.
3. Compare chart labels/spacing to `hevy__exercise-detail.png`.
4. Verify lb units and bodyweight charts.

## Reference gap

Existing exercise references are sufficient.

---

# SettingsView — page audit

**Anchor reference**: `docs/references/ios-screens/neuecast__appearance-settings.png` — borrowing grouped settings rhythm and clear selection state
**Sources consulted**: AGENTS.md §4-7, DesignSystem.swift, atomic-design-system.md, visual-language.md, pricing.md

## Banned-token violations

| File:Line | Violation | Fix |
|---|---|---|
| — | Mechanical banned-token scan is clean | — |

## Parallel-implementation risks

| File:Line | New struct/modifier | Closest existing primitive | Recommendation |
|---|---|---|---|
| — | Uses `SettingsSection`, `AppDividedList`, and `AppSegmentedControl` | — | Keep existing primitives |

## Atom/molecule fixes (system-level — fix here, every screen benefits)

| Layer | File | Issue | Recommended change |
|---|---|---|---|
| molecule | `SettingsSection` | No issue found in shared chrome | — |

## Screen-only fixes (last resort)

| File:Line | Issue | Recommended change |
|---|---|---|
| `SettingsView.swift:158-167` | Subscription management is hidden in a subscription build | Render Restore and Manage subscription |
| `:209-221` | Unit switch exposes the lb persistence defect | Fix storage conversion before allowing this control to ship |
| `:175-207` | Data rows are informational only | Keep them concise; add export only when implemented |

## Layout / rhythm / hierarchy notes

- Data, preference, and legal grouping is clean.
- The most important paid-user controls are missing.
- Footer voice is distinct but should not push legal rows offscreen at accessibility sizes.

## Verification plan

1. Screenshot subscribed and unsubscribed settings.
2. Test Manage subscription and Restore.
3. Switch kg/lb with existing history and verify values remain stable.
4. Test external links and mail composer fallback.

## Reference gap

Need a settings reference for subscription management inside a small utility app.

## App Store v1 baseline

- The current listing is version 1.0, released 2026-06-07, and promises local, no-account, always-working logging.
- Screenshot 1 is generic (“Your gym notebook is upgraded”); screenshots 2-3 explain the actual one-tap/Last time mechanism.
- Public launch feedback independently identified the same ordering issue: the first screenshot says little, while the clean minimal look is acceptable.
- For v2, lead with the one-tap mechanism and disclose the paid requirement before download. Do not retain “core logging is free forever” language.

## Verification status

Audit complete at code/reference level. No build, simulator, or screenshot verification was run because repository policy requires an explicit user request for that pass.
