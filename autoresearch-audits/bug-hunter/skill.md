# bug-hunter — v0

> This is the **iterated file** for the bug-hunter skill. The agent edits this overnight to sharpen detection. Equivalent to `train.py` in autoresearch.
>
> Scope: runtime and correctness bugs. Not design. Not flows. If the issue is about colors/spacing/layout, it belongs to `visual-consistency`. If it's about a dead-end tap or missing empty state, it belongs to `missing-flows`. You only file what a user would experience as "the app did the wrong thing / crashed / lost my data."

---

## What to look for (v0 rules)

File a finding for any of the following. Each bullet gives you the `rule` slug. Use it verbatim in `findings.tsv`.

### Crash risks (severity: critical)

- **`force-unwrap-on-optional`** — `!` on a property or result that can be nil in a realistic path. Pay special attention to `@Query` result access, `URL(string:)!`, force-cast `as!`, `try!` outside test files.
- **`force-unwrap-first-last`** — `.first!` or `.last!` on a collection that can be empty (empty templates, empty sets, empty history).
- **`array-out-of-bounds`** — `array[i]` where `i` is derived from user input, `@State` counter, or index into a filtered array without bounds check.
- **`dict-missing-key`** — unchecked `[key]!` on a Dictionary.
- **`fatal-error-reachable`** — `fatalError(...)` in a code path a user can reach. Onboarding edge cases, first-launch states, migration paths are prime suspects.
- **`swiftdata-context-save-no-try`** — `try? modelContext.save()` that silently eats errors on log-critical paths. Set-logging save failures must surface, not drop.

### Data correctness (severity: critical or major — judge by blast radius)

- **`log-write-without-save`** — A set/session is mutated on a `@Model` but `modelContext.save()` is not called before the view dismisses. If the user backgrounds the app at that moment, the log is lost.
- **`session-interruption-not-resumable`** — `ActiveWorkoutView` initializes fresh-state without restoring an in-flight `WorkoutSession` from SwiftData. Force-quit mid-workout = work lost.
- **`ghost-value-stale`** — prefill reads from a query that doesn't filter by `exerciseID` or that picks the wrong last-session (e.g. ordering ascending instead of descending).
- **`bw-shown-as-zero`** — bodyweight exercises render `"0 kg"` instead of `"BW"` or `"No history yet"`. Cited in `CLAUDE.md §5 Banned`.
- **`weight-unit-mismatch`** — a value is written in one unit (kg) and read as another (lbs) anywhere in the logging path.
- **`pr-detection-off-by-one`** — PR logic compares to `<=` when it should be `<`, or includes/excludes the current set incorrectly.

### Concurrency (severity: major)

- **`swift6-mainactor-violation`** — UI property accessed off the main actor without `@MainActor` annotation or `await MainActor.run`. Swift 6 strict concurrency surfaces these at compile-time, but mark anyway for manual review.
- **`task-cancellation-leak`** — `.task { ... }` spawns a background unit of work without honoring cancellation, and the work touches `@State` / SwiftData after the view dismisses.
- **`timer-retain-cycle`** — `Timer.scheduledTimer` or `Task.sleep` captures `self` strongly in a view, preventing deallocation. Live Activity rest-timer code is a likely spot.

### State / view model bugs (severity: major or minor)

- **`onboarding-path-skip`** — a tap in onboarding advances the `OnboardingViewModel.step` beyond completion without running its side-effect (e.g. creating the first template). Check `OnboardingShell.swift`, `OnboardingViewModel.swift` against each step's `onNext` handler.
- **`sheet-dismiss-loses-edit`** — a sheet wraps form state and pops on swipe-down without confirming unsaved changes. Gym Test says logging is fast, not destructive; an accidental dismiss that nukes 3 reps counts.
- **`button-no-op`** — a button or tap area has no action, or its action is `{ }` (dead button). Grep for `Button(action: { })`, `.onTapGesture { }` with empty body, and `action: {}` in any `AppPrimaryButton` / `AppGhostButton`.
- **`navigation-stack-orphan`** — `NavigationLink` pushes a view that has no back button (hidden) or no dismiss action, leaving the user stuck.

---

## How to run (v0 procedure)

### Pass 1 — grep sweep (cheap)

Use the `Grep` tool. For each rule above, run the corresponding pattern. Examples:

- `force-unwrap-on-optional` → search `type: "swift"`, pattern `\!\s*\.` or `\)\!` (filter out comments, strings, and operator overloads). Exclude `*Tests.swift`.
- `force-unwrap-first-last` → pattern `\.first!\|\.last!` in `Unit/**`.
- `array-out-of-bounds` → pattern `\[[a-z]+\]` near `@State` / loop indices (manual judgment — grep narrows, you confirm).
- `bw-shown-as-zero` → pattern `"0 kg"|\\"0 kg\\"` in `Unit/**`.
- `log-write-without-save` → find `@Model` mutations in view bodies / `onChange` / button actions without a nearby `modelContext.save()`.
- `button-no-op` → pattern `(?:action|onTapGesture)\s*:?\s*\{\s*\}` in `Unit/**/*.swift`.

Every match is a **candidate**, not a confirmed finding. Read the file around the match (±20 lines) and judge whether the pattern actually fires in a realistic code path. If yes, file. If no, skip silently.

### Pass 2 — targeted reads

After the grep sweep, read these files in full at least once per session (they're the highest-density bug sources):

- `Unit/Features/Today/ActiveWorkoutView.swift` — set-logging path, session resumption
- `Unit/Features/Today/TodayView.swift` — Last time values (pre-fill from last session), PR detection, empty state
- `Unit/Features/Onboarding/OnboardingViewModel.swift` — step advancement, side-effects
- `Unit/Models/WorkoutSession.swift` — SwiftData model, save semantics
- `Unit/Models/SetEntry.swift` — unit handling, PR fields
- `UnitWidget/RestTimerLiveActivity.swift` — timer lifecycle, background tasks

When you read these, look for issues that grep missed: state machines that skip states, async tasks that mutate state after dismissal, save-vs-dismiss race conditions.

### Pass 3 — simulator smoke (optional; skip if headless)

If the simulator is bootable, launch the app and exercise **one** bug-likely path per iter (rotate through runs):

- iter `N mod 4 == 0`: fresh install → first template create → first set logged → force-quit → relaunch. Did the set survive?
- iter `N mod 4 == 1`: bodyweight exercise in active workout. Does the weight field show `BW` / `No history yet`, not `0 kg`?
- iter `N mod 4 == 2`: bury app mid-set for 10s, return. State intact?
- iter `N mod 4 == 3`: new user, tap every button on the splash and onboarding screens in order. Any dead button? Any crash?

Screenshot each step to `audit-screenshots/bug-hunter-<iter>-<step>.png` so a finding can cite a visual.

---

## Confidence threshold (do not file below this)

Before appending a row, ask yourself:

1. **Can I point at a specific file + line + rule?** If not → don't file.
2. **Can I describe the exact trigger?** (fresh install, specific tap sequence, specific data state). If not → don't file.
3. **Would a fix require changing Swift code?** If it's a copy nit or color swap, it's not a bug — that's `visual-consistency`.

If all three are yes → file it. The cost of a false positive is higher than the cost of a miss, because false positives erode the verdict signal the skill trains on.

---

## Candidate probes (draw from here when signal goes silent)

If you complete 2 iterations with 0 novel findings, pick one of these, add it to the "What to look for" list above, and try it next iter. Commit the skill.md change with a clear message.

- **`color-literal-in-logic`** — `Color.init(red:green:blue:)` used outside DesignSystem.swift, potentially embedded in runtime logic (e.g. a switch on severity that returns a hardcoded color).
- **`haptic-missing-on-log`** — set-log action that does not call `UIImpactFeedbackGenerator` / `.sensoryFeedback(...)`. `docs/goals.md` lists haptic confirmation as a v1 ship feature.
- **`preview-crashes`** — SwiftUI `#Preview` blocks that depend on `@Environment(\.modelContext)` without an in-memory ModelContainer; crashes in Xcode previews are a sign of fragile DI.
- **`deprecated-api-usage`** — uses of APIs marked `@available(*, deprecated)` or pre-iOS-18 patterns (`NavigationView`, `onChange(of:perform:)` single-arg, etc.).
- **`unchecked-network-or-disk-io`** — file read or URL fetch in a View body or `.onAppear` without error handling; user sees partial/empty state and doesn't know.
- **`locale-date-formatter-missing-timezone`** — `DateFormatter` / `ISO8601DateFormatter` used without explicit timezone in a way that skews day-of-week / streak calculations.

---

## What NOT to file (false-positive discipline)

Past Claude audits on this repo have produced these classes of false positives. Do not repeat:

- **Do not** flag `!` in string interpolation or comments. Limit the regex to code.
- **Do not** flag `try?` in tests or preview code. Those are intentional.
- **Do not** flag `fatalError` behind `#if DEBUG` or in code clearly marked "unreachable by construction."
- **Do not** flag `Color.primary` / `Color.secondary` as banned — those are semantic, allowed by `CLAUDE.md §5` (banned list is `Color.black/.white/.gray/.red/.green/.blue`). Only these six are raw.
- **Do not** file "`0 kg`" findings for string literals inside tests or mock data. Filter to `Unit/Features/**` and `Unit/UI/**`.

When the human marks a finding `false_positive`, your job on the next iter is to add a new exclusion here so the same class of FP never re-appears.
