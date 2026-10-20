# Logging motion feedback — 20 October 2026

## State and ownership

Source review of build85 feedback baseline `8e3cf4d`. Dedicated branch: `codex/unit-qa-release`; main merged as `48ae7cb`. The only merge conflict was the timer test helper's explicit `@MainActor`; main's version was retained. Main advanced independently after that merge. Cherry-pick only the motion implementation checkpoint, not the merge checkpoint.

Applied directly: only `RestBar` in `Unit/UI/DesignSystem.swift`. No timer persistence, notifications, models, haptics, navigation, version, editor or CurrentSetRow edits. `ActiveWorkoutView.swift` remains byte-identical to the merged baseline. The patch below is a proposal for Main, not an applied change.

## References and reuse decision

Read CLAUDE.md, docs/AGENTS.md, DESIGN.md, product-compass.md, atomic-design-system.md and visual-language.md. Visual anchor: the existing Final B rest bar in `docs/specs/2026-10-20-logging-final-b.md`, with the user's later explicit blue-progress correction. Existing native SF typography is retained despite the older wireframe font description.

Applied skills: swiftui-pro, 12-principles-of-animation, component-reuse-check. No haptic change; axiom-haptics was unnecessary. Plate was read only: `Plate/Components/Motion/PlateSteps.swift` and `PlateReveal.swift` show transition-owned blur/fades without replaying loaded content. Unit's existing `AppMotion`/`AppBlurTransition` already cover that concern.

Reuse check: extend existing `RestBar(timeText:state:progress:canDecrease:onDecrease:onIncrease:onSkip:)` with optional `endDate` and `totalDuration` inputs; retain the existing `ScaleButtonStyle`, `AppColor.accent`, `AppMotion.transition` and accessibility gates. No new design primitive, token or variant.

## Applied rest-bar change

- Blue line uses `AppColor.accent`.
- Normal-motion progress reads `(deadline - timeline.date) / totalDuration`, clamped to 0...1, on SwiftUI's display timeline. The line's transaction disables inherited interpolation. No elapsed-duration animation, new countdown, model clock or notification scheduling.
- The caller must pass the manager's actual deadline/duration using the patch below. The old fraction remains a compatible fallback; existing callers compile without wiring, but smooth draining requires these new arguments.
- Reduce Motion or VoiceOver pauses decorative frame updates. When the parent updates, the width is sampled from the actual deadline/current time. Status fades remain; countdown numerals fade instead of rolling. No travel, blur or bounce in the rest bar.
- Running, idle, finished and control layers remain mounted and fade with the shared transition. Hidden controls cannot receive taps or accessibility focus. The last visible running label is retained for its exit fade, so finishing does not replace it with the default rest duration during removal.
- `ViewThatFits` keeps the normal single line, with a stacked fallback when larger text cannot fit. It retains the existing minimum heights and 44pt buttons. No fixed-height clipping.

## Instant-change audit

Locations refer to this branch's merged logging source and updated shared owner. These are source findings; no claim of observed frame behavior.

| Change | Source location | Source evidence | Action / owner |
| --- | --- | --- | --- |
| Rest line | DesignSystem.swift:6755 | Previously width came only from whole-second remaining/total; Ink fill. | Applied blue deadline/display-timeline drawing; Main must wire new arguments. |
| Rest idle → running → finished / Skip | DesignSystem.swift:6798,6829 | Previous if/else replaced the label hierarchy and inserted/removed controls without a state-bound animation. | Applied mounted opacity layers with AppMotion.transition; reserved control space. |
| Current → logged → next row | ActiveWorkoutView.swift:158,664; DesignSystem.swift:6617,6663 | Entry-ID changes have a collection animation; CurrentSetRow and LoggedSetRow already own explicit opacity transitions. Not an entirely unanimated path. Planned-row exit lacks an explicit transition owner. | Main: retain existing transaction; consider AppBlurTransition at the row-content boundary for the planned/current swap, not a second delayed handoff. Logging agent owns CurrentSetRow. |
| Check ↔ edit fields | ActiveWorkoutView.swift:570; DesignSystem.swift:6617,6663 | Different row branches swap; existing outer opacity transitions cover mount/unmount, but text/focus setup changes have no separate bound animation. | Logging agent: preserve native field identity and immediate typing; use opacity only around non-input state labels. Do not animate raw typed numbers. |
| Starting target → Complete set | ActiveWorkoutView.swift:639; DesignSystem.swift:6584,6597 | isSetup swaps two button types. The inner opacity transition has no animation bound to isSetup; the entry-ID collection trigger does not change. | Logging agent: bind AppMotion.transition to isSetup at the existing CTA slot, or retain two opacity layers. Preserve save-before-log behavior. |
| Complete exercise → summary / next exercise | ActiveWorkoutView.swift:674; DesignSystem.swift:6691 | Normal Complete has collectionChange; the whole card/summary replacement has no explicit content transition. | Main composition: use existing AppBlurTransition().animation(AppMotion.transition) on the changing content, keep list/scroll identity. Avoid replayed entrances/stagger. |
| Summary completion check / summary text | DesignSystem.swift:6702,6714 | Optional check and Undo hierarchy changes when isCompleted changes; no bound content transition. | Main's summary owner: stabilize check/Undo slots and fade summary text; preserve the new summary layout being developed elsewhere. |
| Inline Undo appearance/expiry | DesignSystem.swift:6654,6719 | Reserved slots already animate opacity using AppMotion.transition. | Retain; no new bounce, delay, haptic or duplicate toast. |
| Undo latest set | ActiveWorkoutView.swift:703 | Entry list animation plus explicit selection transaction; the explicit transaction checks Reduce Motion but omits VoiceOver. | Proposed patch below closes the VoiceOver gate. Main owns exercise reopening. |
| Mark not done / toast Undo restore | ActiveWorkoutView.swift:723,738 | Entry identities change, so the existing collection owner handles layout. Selected exercise/card identity can also change without its own content transition. | Main composition: reuse the card/summary transition; keep exact snapshot identity and source-set rest-stop behavior. |
| Manual exercise jump / Add set | ActiveWorkoutView.swift:761,774 | selectedExerciseID/customSetCounts changes may not change entry IDs, so the current list animation trigger is insufficient by itself. | Main composition: animate current-exercise/row-identity changes with the same collection owner; accessibility uses layout-at-once plus content fade. |
| Auto-scroll after Complete | ActiveWorkoutView.swift:695 | Explicit withAnimation checks only Reduce Motion. VoiceOver can receive animated scroll despite shared appAnimation's separate gate. | Proposed patch adds VoiceOver to every existing direct collection transaction. |
| Keyboard rest bar ↔ toolbar | ActiveWorkoutView.swift:168,204 | System keyboard inserts/removes bottom bar; no independent rest animation needed. | Preserve native keyboard timing. Logging agent owns focus/editor. Do not animate TextField bindings. |

Animation-principles findings: `timing-consistent` applies to missing isSetup/current-exercise triggers; `staging-one-focal-point` favors one row/card transition rather than simultaneous new bursts or staggers. Rest progress is a clock indicator, where constant-speed change is appropriate; it must not use eased catch-up toward old samples. Existing ScaleButtonStyle already supplies pressed feedback, gated for accessibility.

## Main integration patch (not applied here)

Apply the two RestBar arguments to the final caller, retaining all concurrent editor and summary work. The three transaction changes prevent VoiceOver travel; existing opacity transitions keep fades. If surrounding lines have moved, integrate these small changes manually. The patch passed `git apply --check` against the merged baseline.

```diff
--- a/Unit/Features/Today/ActiveWorkoutView.swift
+++ b/Unit/Features/Today/ActiveWorkoutView.swift
@@ -17,6 +17,7 @@
     @Environment(\.modelContext) private var modelContext
     @Environment(\.scenePhase) private var scenePhase
     @Environment(\.accessibilityReduceMotion) private var reduceMotion
+    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
     @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
     @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
     @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
@@ -172,6 +173,8 @@
                     state: restTimer.isFinished ? .finished : (restTimer.isRunning ? .running : .idle),
                     progress: restTimer.totalDuration > 0
                         ? Double(restTimer.secondsRemaining) / Double(restTimer.totalDuration) : 0,
+                    endDate: restTimer.endDate,
+                    totalDuration: TimeInterval(restTimer.totalDuration),
                     canDecrease: restTimer.secondsRemaining > 15,
                     onDecrease: { adjustRestTimer(by: -15) },
                     onIncrease: { adjustRestTimer(by: 15) },
@@ -671,7 +674,7 @@
         entry.session = session
         modelContext.insert(entry)
         guard saveWorkoutChanges() else { return }
-        withAnimation(reduceMotion ? nil : AppMotion.collectionChange) {
+        withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
             logging.didLog(entryID: entry.id, exerciseID: exercise.id, at: Date())
             guardActive = true
             expandedCompletedID = nil
@@ -692,7 +695,7 @@
         guardActive = false
         currentRowFocused = true
         if currentRowBottom > visibleListHeight - AppSpacing.md, let currentSection {
-            withAnimation(reduceMotion ? nil : AppMotion.collectionChange) {
+            withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
                 scrollPosition.scrollTo(id: rowID(currentSection.id, currentSection.entries.count + 1), anchor: .bottom)
             }
         }
@@ -705,7 +708,7 @@
               let entry = session.setEntries.first(where: { $0.id == undo.entryID }) else { return }
         modelContext.delete(entry)
         guard saveWorkoutChanges() else { return }
-        withAnimation(reduceMotion ? nil : AppMotion.collectionChange) {
+        withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
             selectedExerciseID = undo.exerciseID
             logging.invalidateUndo()
         }
```

Copy of this patch: `/private/tmp/unit-logging-motion-active-view.patch`. No `ActiveWorkoutView` change is included in the motion checkpoint.

## Source checks and remaining verification

- `scripts/check-guards.sh`: PASS.
- `git diff --check`: PASS.
- `swiftc -frontend -parse Unit/UI/DesignSystem.swift`: PASS (syntax only, not type checking).
- Checked the installed iOS SDK interface: AnimationTimelineSchedule.animation(minimumInterval:paused:) exists.
- Proposed ActiveWorkoutView patch: `git apply --check` PASS against baseline.
- No independent build, test run, Simulator, device installation or version change.

Main's queued build must type-check the new RestBar inputs. Then review normal-motion blue draining at default and compact widths; ±15 changes; deadline reached in foreground/background; Skip; restart; keyboard disappearance/reappearance; AX3 stacked rest layout; VoiceOver focus excludes hidden controls; Reduce Motion has only fades, no rolling numerals or animated scroll. Confirm label/control crossfade without a height jump. Log several sets, delete a middle/source set, Undo, collapse/advance and perform first-time setup to inspect the other owners' fixes together.

Do not call the full logging motion audit fixed until Main/logging-agent items above are integrated and visually exercised. Existing timer persistence/notifications are untouched.
