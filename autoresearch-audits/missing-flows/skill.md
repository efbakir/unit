# missing-flows — v0

> Iterated file for the missing-flows skill. Agent edits this to sharpen detection of broken / missing flows and edge-case data states. Equivalent to `train.py` in autoresearch.
>
> Scope: the **user journey**. A flow is a sequence of taps a user can realistically execute. A missing flow is when that sequence leads to a dead end, a crash, a wrong state, or a screen that isn't there. If the issue is a raw-color violation, that's `visual-consistency`. If it's a `!` force-unwrap, that's `bug-hunter`. This skill catches what users will email you about after they download the app.

---

## Read these once per session (mandatory context)

- `CLAUDE.md` §1 (North star — every decision judged by "seconds per set logged under fatigue"), §4 (banned v1 scope), §7 (verification)
- `docs/goals.md` — §v1 scope boundaries (what SHIPS and what DOES NOT)
- `AGENTS.md` or `agents.md` — UX rules and product model
- `audit-prompt.md` Step 1 "Edge cases" section — seed list of known-missing data states
- `Unit/ContentView.swift` — tab structure, top-level nav
- `Unit/UnitApp.swift` — root app wiring, first-launch flag

---

## What to look for (v0 rules)

### Dead-end flows (severity: critical if on happy path, major otherwise)

- **`button-opens-nothing`** — a button fires but produces no visible change: no navigation, no sheet, no state mutation. Usually an `action: { }` that was stubbed and never filled.
- **`cell-not-tappable-but-looks-tappable`** — a card or row styled like it should navigate (has a chevron analog, has an "affordance" border/shadow) but has no `.onTapGesture` or `NavigationLink` wrapper.
- **`pushed-view-has-no-back`** — a detail view in `NavigationStack` that hides the back button without providing a custom dismiss, trapping the user.
- **`sheet-has-no-dismiss`** — a `.sheet` or `.fullScreenCover` presents content with no visible close/cancel button. User can only swipe down; if the sheet has a long form, swipe-down is not discoverable.
- **`modal-action-without-success-signal`** — a primary action in a sheet succeeds (writes data) but the sheet doesn't dismiss and there's no visible confirmation. User re-taps, double-writes.

### Missing empty states (severity: major)

- **`empty-templates-no-cta`** — `TemplatesView` with zero templates shows nothing or shows a list header with no body. Should present the three onboarding paths: text-paste, redo-from-history, manual builder (per `CLAUDE.md §2 MVP scope`).
- **`empty-history-no-guidance`** — `HistoryView` with zero sessions. Should explain what to do, not render a blank chart.
- **`empty-exercise-history-zero-kg`** — a never-logged exercise renders the Last time value as `0 kg` instead of the `"No history yet"` prompt.
- **`empty-calendar-silent`** — `CalendarTabView` with no session data renders a blank heatmap instead of an affordance.
- **`search-no-results-no-message`** — exercise library / template search that returns zero matches silently. No "no results for X" copy.

### First-launch / onboarding edge cases (severity: critical — this is the single most-critical flow)

Onboarding is where new users bounce. Any break here is a user loss. Three onboarding paths must all end with at least one template and a viable first workout (per `CLAUDE.md §2 Ships in v1`):

- **`onboarding-path-incomplete`** — a path (text-paste / redo-from-history / manual builder) that can complete without producing a template. User lands on Today with nothing to do.
- **`onboarding-skip-leaves-app-broken`** — a "Skip" button on any onboarding screen that skips past template creation without backfilling.
- **`onboarding-back-resets-progress`** — pressing back in onboarding nukes previous step's answers.
- **`onboarding-long-program-paste-truncates`** — a very long program pasted into the import flow fails silently, parses partially, or crashes.
- **`onboarding-unknown-exercise-name-drops-set`** — paste contains an exercise not in the built-in library (`ExerciseLibrary`). Does the flow let the user add it as a custom exercise, or silently drop the whole line?

### Back-stack / navigation structure (severity: major)

- **`deep-link-from-history-dead`** — tapping a past session from history: does it open a readable detail or a blank? Is there a "repeat this workout" CTA?
- **`tab-switch-loses-mid-flow-state`** — start creating a template, switch tabs, come back: is the in-progress template lost? Should be preserved (draft) or explicitly discarded with a prompt.
- **`active-workout-tab-switch`** — start an active workout, switch tabs, come back: rest timer still running? Current set intact? Live Activity correct?

### Edge-case data states (severity: minor-to-major — judge by user impact)

Seed list from `audit-prompt.md` Step 1:

- **`long-exercise-name-truncates-ugly`** — "Barbell Bulgarian Split Squat with Front Foot Elevated" etc. Does it truncate to `…` or break layout?
- **`huge-weight-breaks-layout`** — 999 kg / 2,000 lbs. Does the weight field render or overflow?
- **`many-sets-slow`** — 10+ sets on one exercise in Active Workout. Does scroll work? Is the Done button always visible?
- **`many-exercises-on-template`** — template with 15+ exercises. Does the list perform? Can the user find the bottom?
- **`special-chars-exercise-name`** — `"Dips — Weighted (V2)"` with em-dash, parens. Does save/parse handle?
- **`bodyweight-with-weight-field-shown`** — a bodyweight exercise that still renders the weight input (and expects a number).
- **`pr-notification-missing-on-bodyweight`** — bodyweight exercise PR (more reps than ever before) — does the PR banner fire?
- **`rest-timer-backgrounded-across-lock`** — start rest timer, lock phone for 2 minutes, unlock: timer accurate? Live Activity still visible?

### Gym Test violations (severity: critical if ≥ 3s, major if adds tap count)

Core MVP spec per `CLAUDE.md §1`: **logging a set must take ≤ 3 seconds, one-handed, under fatigue.**

- **`log-set-more-than-two-taps`** — any path where logging the next set requires > 2 taps.
- **`ghost-value-not-prefilled`** — weight/reps field is empty instead of prefilled from last session.
- **`done-button-not-reachable-one-handed`** — Done CTA positioned out of thumb reach on a 6.7" screen (too high, off-center). Manual review from screenshot.
- **`modal-between-sets`** — an unnecessary modal/alert/toast between sets that requires dismissal before the next log.

---

## How to run (v0 procedure)

### Pass 1 — flow map construction

Read these files and build a **mental flow map** (don't commit a file for it):

- `Unit/ContentView.swift` — tab root
- `Unit/Features/Today/TodayView.swift`
- `Unit/Features/Today/ActiveWorkoutView.swift`
- `Unit/Features/Templates/TemplatesView.swift`
- `Unit/Features/Templates/TemplateDetailView.swift`
- `Unit/Features/History/HistoryView.swift`
- `Unit/Features/History/CalendarTabView.swift`
- `Unit/Features/Onboarding/OnboardingView.swift`
- `Unit/Features/Onboarding/OnboardingShell.swift`
- `Unit/Features/Onboarding/OnboardingViewModel.swift`

For each `NavigationLink`, `.sheet`, `.fullScreenCover`, `Button(action:)` and `.onTapGesture` you encounter, ask three questions:

1. Where does this go?
2. Is there a back / close path from there?
3. What happens if the underlying data is empty / long / zero / malformed?

Any answer of "nowhere", "no", or "crashes/blank" → candidate finding.

### Pass 2 — simulator flow drills

If simulator is bootable, run one drill per iter (rotate):

- iter `N mod 5 == 0`: **Fresh install drill.** Delete app → reinstall → launch → go through onboarding path A (text-paste). Back-button-stress: press back on every screen. Any dead end?
- iter `N mod 5 == 1`: **Empty states drill.** Fresh install → skip onboarding if possible → visit every tab with zero data. Every screen must show guidance or a CTA, never a silent blank.
- iter `N mod 5 == 2`: **Gym Test timing drill.** Populated app → tap "Start today's workout" → start a stopwatch → log three sets at full speed, one-handed, phone in right hand. Note total elapsed time and tap count in the description of any finding.
- iter `N mod 5 == 3`: **Active workout stress drill.** Start workout → mid-set, tap every tab → return → is state intact? Background app for 30s → return. Live Activity visible?
- iter `N mod 5 == 4`: **Edge data drill.** Create an exercise named `"Dumbbell Romanian Deadlift — Single Leg, B-stance"`. Log 999 kg × 99 reps. Create a template with 15 exercises, 5 sets each. Does anything break?

Screenshot each step to `audit-screenshots/flows-<iter>-<step>.png`.

### Pass 3 — goals.md cross-check

Read `docs/goals.md` §v1 scope boundaries. For each "Ships in v1" item, confirm it is reachable from a cold start:

- Template-based logging with Last time values (pre-filled from last session) → reachable?
- Three onboarding paths → all three actually selectable and completable?
- Auto rest timer with Lock Screen / Dynamic Island → visible on lock screen during a set?
- History view (list + calendar) → both modes reachable?
- Exercise library (search + custom exercise creation) → both actions reachable from a sensible place (not just onboarding — see `project_unit_exercise_library.md` in memory: library must be surfaced app-wide)?
- Haptic confirmation on set logged → verify `UIImpactFeedbackGenerator` / `.sensoryFeedback` on the Done-a-set path (coordinate with `bug-hunter` skill).
- PR detection + notification → a PR must fire a visible, dismissible banner.

Anything not reachable or not working → file a finding with `rule = missing-v1-scope-item` and `file = docs/goals.md`, `line = <line of the ship item>`.

---

## Confidence threshold

Before filing:

1. **Can I describe the exact tap sequence that reproduces the dead end / edge case?** If not → don't file.
2. **Is the thing I'm missing listed in `docs/goals.md` §v1 "Ships"** OR **listed in `CLAUDE.md §5` "empty states" / `audit-prompt.md` Step 1** OR **obviously broken from a user's POV (button opens nothing, blank screen)?** If not → don't file.
3. **Am I filing something that's actually deferred per `CLAUDE.md §4`?** (cycles, ProgressionEngine, social, etc.) If so → don't file; that's compass-aligned absence, not a missing flow.

---

## Candidate probes (draw from here when signal goes silent)

- **`live-activity-rest-timer-drift`** — start a workout's rest timer, check Live Activity on lock screen, compare elapsed to in-app timer. Drift ≥ 2s → file.
- **`paywall-on-core-logging`** — any paywall / `StoreManager` prompt that appears during the core log-a-set / create-a-template / view-history flow. Paywall on core logging is banned per `CLAUDE.md §4`.
- **`import-program-filter-conditioning`** — paste a program that includes conditioning days (e.g. "Sunday: 20min Zone 2"). Are those filtered out per `CLAUDE.md §4 Conditioning days in imported programs`? Or do they appear as templates?
- **`history-session-count-per-day-wrong`** — log two sessions in one day. Does history show 2 cards or merge into 1?
- **`template-duplicate-allowed`** — create two templates with the same name. Is that OK, confusing, or blocked? Check against goals.md — probably OK, but the UI should distinguish them.
- **`offline-first-write`** — airplane mode on, log a set, airplane off. Does anything try to sync (shouldn't, app is local-first per `CLAUDE.md §1`)? Does anything break assuming network?
- **`notification-permission-deny`** — deny notification permission at the permission prompt. Does PR notification flow fail gracefully or crash?

---

## What NOT to file (false-positive discipline)

- **Do not** file "missing cycle view" / "missing Week N of M progress" — banned per `CLAUDE.md §4`. Those flows are intentionally not present.
- **Do not** file "missing social share" / "missing community feed" — anti-persona, banned.
- **Do not** file "missing dark mode" — light-mode-only per `CLAUDE.md §5 Principle 3`.
- **Do not** file "missing landscape layout" — portrait-only per `CLAUDE.md §5 Principle 4`.
- **Do not** file "missing paywall prompt on logging" — core logging is free, paywall is banned on core per `CLAUDE.md §4`.
- **Do not** file "plate calculator missing" — deferred per `CLAUDE.md §4`.
- **Do not** file "auto-increment / ProgressionEngine missing from UI" — deferred per `CLAUDE.md §4`. Last time values (pre-filled from last session) are the in-scope alternative.
- **Do not** file "CloudKit sync missing" — post-v1 per `CLAUDE.md §4`.

If the human marks a finding `false_positive` because it's actually a banned-v1 item, the correct next-iter action is to add it to this exclusion list — not to try to justify it. The v1 scope fence is the source of truth.
