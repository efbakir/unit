# App motion audit — build 85 feedback

Source-only audit requested by the main chat after gym feedback. Baseline: main
`8e3cf4d`, merged into `codex/unit-analytics-review` at `8138098`. This report is
the only new task edit. No production fixes, builds, Simulator operations, phone
operations, data changes, version changes or new design tokens/components.

Read: repository guidance and motion documentation; `swiftui-pro` (including
views/accessibility), `12-principles-of-animation`, and `swiftui-atomic-design`.
Exact line references below refer to this baseline. Paths are repository-relative.
Main assigns implementation ownership after JOI research; this report does not
authorize overlapping edits to the shared design-system file.

## Evidence and severity

These are source-confirmed state/transaction gaps, **not observed device glitches**.
Native controls may contribute their own transactions; visible duration and
layout impact require integrated interaction checks. P2 means a normal interaction
has a concrete motion gap; P3 means a lower-priority verification target. No P0/P1
or data-integrity issue was established. Rule names below adapt the animation
skill's timing, staging, follow-through and continuity principles to SwiftUI.

## Proposed fixes, worst first

| ID | Severity / rule | Trigger and exact source | Mechanism and minimal patch at existing owner |
| --- | --- | --- | --- |
| M1 | P2 — continuity / follow-through | Main lifts editor: Add, then Use automatic. `Unit/Features/Analytics/MainLiftsEditor.swift:51`, `:81`, `:82` | Add/reset mutate `draft` directly. The conditional footer is outside the native List and has no transition or local animation, so it changes the List's available height immediately. Keep the native List and its move/delete behavior. Stabilize the footer slot, or apply an existing fade plus scoped `AppMotion.collectionChange` to that footer/container keyed to footer visibility. Handle Add/reset row updates at this editor; do not wrap dismissal or the sheet in an animation. Preserve focus and selection. |
| M2 | P2 — continuity / stable identity | Save reordered or replaced main lifts. `Unit/Features/Analytics/AnalyticsView.swift:38`, `:103`, `:107`; `Unit/Features/Analytics/AnalyticsStore.swift:47` | Main cards use a plain VStack/ForEach. Other exercises use animated AppCardList, but main cards have no ID-keyed collection owner. Store output arrives after an awaited background calculation; animating the Done button cannot span this refresh. Apply existing collection motion at the main-card VStack, keyed to the published `mainIDs`, and existing transitions on inserted/removed cards. Keep model/store logic free of UI animation; keep stable UUID identity and avoid whole-page entrance replay. |
| M3 | P2 — staging / continuity | Toggle flexible schedule in onboarding. `Unit/Features/Onboarding/OnboardingScheduleView.swift:75`, `:88`, `:119` | The Toggle is native, but the custom weekday-card branch has no transition/animation owner. Existing row motion only applies while AppCardList is mounted; it cannot own removal of the entire section. Apply `AppBlurTransition` at the weekday section and a scoped existing collection transaction to this content stack keyed to `useFlexibleSchedule`. Leave the Toggle and weekday control behavior native/current. Reduce Motion/VoiceOver retain a fade without spatial layout animation. |
| M4 | P2 — staging / local-only animation | Focus/unfocus pasted-plan editor. `Unit/Features/Onboarding/OnboardingProgramImportView.swift:96`, `:100`; `Unit/Features/Onboarding/OnboardingShell.swift:107` | Header condensation animates only `headerStack`; the sibling format-examples button has `.transition(.opacity)` with no animation attached there or in its content stack. Header animation is not proof of a button fade or smooth editor resizing. Give this existing conditional button an explicit existing reveal transition and scope any necessary layout animation to the import body using focus state. Keep keyboard/focus immediate; do not animate text binding or the entire shell. The synchronous parser's temporary `isParsing` state is not evidence of a visible waiting animation. |
| M5 | P2 — continuity / local-only animation | Switch Weight/Reps/Volume in exercise progress. `Unit/Features/History/ExerciseProgressView.swift:81`, `:83`; `Unit/UI/DesignSystem.swift:5934`, `:6270`, `:6374` | Segmented-control chrome animates locally (or is a native Picker); the sibling chart/caption replaces metric/domain/series immediately. The chart only disables inherited animation for Reduce Motion; it has no metric-change owner. At **AppTrendChart**, use the existing content-transition/opacity vocabulary keyed to metric for the plot/caption, while retaining the mounted chart and direct scrub state. Do not numerically interpolate kg into reps/volume or animate scrub gestures. No global change to the segmented control or native Picker. |
| M6 | P2 — continuity / stable hierarchy | Add weekly schedule / Use flexible schedule in Edit program. `Unit/Features/Templates/TemplatesView.swift:404`, `:428`, `:549`, `:556` | AppCardList watches item IDs, but changing schedule mode keeps those IDs and replaces each row's weekday/drag branch. Its collection-ID animation therefore does not cover the branch change. Preserve the common row/navigation hierarchy where possible and fade the existing accessory region using AppMotion feedback; scope any necessary row layout animation to schedule mode. Retain AppCardList for actual insert/reorder and native Menu behavior. Do not add a parallel routine-row component. |
| V1 | P3 — staging / local-only animation | Paywall: switch between trial, regular subscription and lifetime. `Unit/Features/Subscription/PaywallView.swift:119`, `:228`, `:233`, `:597`; `Unit/UI/DesignSystem.swift:3111` | Selected-card chrome and timeline text have local animation; timeline identity changes by item-ID array and the reminder branch has its own transition. Neither proves that neighboring feature/disclosure positions move smoothly. **Do not restore ancestor-wide withAnimation:** the shared card explicitly records an iPhone SE sticky-CTA clipping regression from that approach. Verify first; if abrupt sibling displacement is visible, stabilize the existing body slots or scope existing motion to timeline/reminder content only. Preserve the sticky CTA's independent layout. |

Six P2 candidates and one P3 verification target. M1/M2 are the smallest
Analytics-owned batch; M3/M4 are onboarding; M5 touches shared chart ownership;
M6 is Programs. V1 requires the main chat's compact-device paywall verification
before any patch. These are ownership proposals, not assigned production edits.

## Coverage and things to preserve

- **Today/dashboard:** `TodayView.swift:265` / `:270` replace the selected routine
  and dismiss its native picker sheet. `:320` keys preview rows by position.
  Routine title/count/preview can change with no dashboard-local swap owner, but
  the update happens behind sheet dismissal. Check the visible handoff first;
  do not introduce an artificial delay or replace sheet navigation. If needed,
  scope existing blur/fade to routine identity, rather than root or row indices.
  Start/resume/logging transitions are outside this audit's implementation scope.
- **Programs/main/detail/library:** existing AppCardList/AppDividedList own
  collection insertion/removal (`DesignSystem.swift:3726`, `:3731`). Template
  detail additionally keys collection motion to ordered exercise IDs
  (`TemplateDetailView.swift:67`). Program library empty/results branches already
  have explicit transitions (`ProgramLibraryView.swift:41`, `:49`). Do not count
  those as missing motion merely because the mutation lacks withAnimation.
- **Analytics/info/editor/detail:** explanation and estimate sheets use native
  presentation. Keep those native. Initial async placeholder replacement is a
  separate load-state opportunity, not a reason to animate already-loaded data
  every foreground/save refresh. Preserve chart accessibility descriptors and
  immediate direct manipulation. Editor Cancel still discards changes.
- **History:** list/calendar mode has explicit branch transitions and a
  state-keyed transaction (`HistoryView.swift:254–262`). Recommendation acceptance
  has a local state transaction (`SessionDetailView.swift:302`). No missing-owner
  defect established there. Filter/menu/native navigation should retain platform
  behavior; parent animation alone is not proof every status Text fades.
- **Onboarding:** step identity plus AppBlurTransition lives in OnboardingFlow
  (`OnboardingView.swift:543–544`). AppDisclosureCard owns preview expansion
  (`DesignSystem.swift:4073`); day-count rows use AppCardList. Avoid double
  entrances or wrapping editable drafts in flow-level animations.
- **Replay audit:** AppRevealSession plus AppScreenEnter remembers named reveal
  IDs (`DesignSystem.swift:516–524`); paywall supplies a session (`PaywallView.swift:43`).
  Splash scene/accessibility tasks are cancellable and retain phase/selection.
  No repeat-on-scroll defect established. Staged paywall header/program calls
  have only view-lifetime memory; exercise retry/re-entry before alleging a replay.
  Legacy `.appScreenEnter()` calls are intentionally immediate (`:552`), so
  their presence is not proof of animation and their lack of staging is not a bug.

## Integration verification after ownership approval

Main coordinates one runtime pass after integration. Capture the interaction,
not just the settled screenshot. Check ordinary motion, Reduce Motion and
VoiceOver; preserve fades while eliminating travel/blur/bounce in accessible
settings. Existing `appAnimation` disables spatial animation, while
AppBlurTransition independently gates its blur/scale. A new use must keep both
behaviors in view.

1. Editor Add/delete/reset/reorder, footer appearance, Cancel and Done; confirm
   stable focus and correct saved main IDs after asynchronous refresh.
2. Flexible/weekly schedule toggle; routine weekday/drag accessories; no typing
   or keyboard animation delay.
3. Paste focus/unfocus and validation error; keyboard and sticky action remain
   usable on a compact screen with large text.
4. Chart metric changes and immediate scrub/release; no interpolation between
   incompatible units, stale selection or descriptor mismatch.
5. Paywall trial/nontrial/lifetime, missing/retried products and repeated entry
   on compact/large-text layouts; sticky CTA never clips or changes reachability.
6. Return to tabs/scroll back; no unnecessary reveal replay. Native tabs, sheets,
   menus, pickers and navigation remain system-owned.

Reuse AppMotion, AppBlurTransition, AppCardList/AppDividedList, AppTrendChart,
AppTimeline, AppScreenEnter/AppRevealSession and existing row owners. No new
palette, type scale, components or animation durations are required. Blue action
accent and grayscale remain. Do not change logging, RestBar, SwiftData schema,
workout values or progression acceptance as part of this report.

## Assigned follow-up implementation

After audit checkpoint `22d0530`, main authorized small feature-local fixes,
keeping shared design-system code and runtime operations centrally owned.

- **M1 applied:** existing editor VStack keys collection motion to footer
  visibility; the existing button has an explicit opacity transition. Native
  List move/delete, drafts, Done/Cancel and persistence are unchanged. This fixes
  the footer ownership gap, not every possible native row-update behavior.
- **M3 applied:** existing schedule body keys collection motion to flexible mode,
  and its weekday section uses existing AppBlurTransition. Native Toggle and
  controls are unchanged. Existing gates drop spatial motion for Reduce Motion
  or VoiceOver while the section transition retains a fade.
- **M4 applied narrowly:** format-examples button now supplies its own explicit
  opacity animation instead of relying on the sibling header transaction. No
  whole-editor layout animation was added; keyboard resizing remains native.
- **M2 applied in a separate follow-up:** main subsequently assigned collection
  changes explicitly. The existing main-card VStack keys collection motion to
  UUID order; rows reuse AppBlurTransition. A presentation flag leaves first
  display unanimated. No root entrance, loading delay, metric-value animation or
  store changes. Unchanged main IDs do not trigger the collection transaction.
- **M5 deferred:** AppTrendChart is shared DesignSystem ownership, excluded from
  the implementation assignment.
- **M6 deferred:** the safe fix needs common weekday/drag row anatomy, rather
  than a speculative animation wrapper around replaced interactive hierarchies.
  Programs ownership and an interaction check are needed before that restructure.
- **V1 deferred:** compact-device regression risk requires main's paywall check;
  broad paywall animation remains explicitly excluded.

Existing source guards, UI banned-pattern hook on all three edited features and
whitespace checks pass. No build or tests were run here, as assigned. **Applied,
not runtime-verified**; main owns the integrated build and visual/motion checks.
