//
//  ActiveWorkoutView.swift
//  Unit
//
//  Active workout: command-panel logging for the current exercise and rest state.
//

import ActivityKit
import SwiftUI
import SwiftData

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    @State private var viewModel = ActiveWorkoutViewModel()
    @State private var restTimer = RestTimerManager()
    @State private var restDurationSeconds = 30
    @State private var showLineup = false
    @State private var adjustResultPayload: AdjustResultPayload?
    @State private var selectedExerciseIndex = 0
    @State private var showsReadyState = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsCancelConfirmation = false
    @State private var showsSkipExerciseConfirmation = false
    @State private var showsFinishConfirmation = false
    @State private var showsRenamePrompt = false
    @State private var renameDraft = ""
    /// Drives the "Discard workout name?" confirmation when the lifter taps
    /// Skip *after* typing a draft. Set true from the Skip-button handler on
    /// `showsRenamePrompt`; on confirm, `renameDraft` is cleared; on cancel,
    /// `showsRenamePrompt` re-opens with the draft preserved so the lifter
    /// can finish typing without re-entering anything.
    @State private var showsDiscardRenamePrompt = false
    @State private var showsAddExercise = false
    @State private var pendingExerciseForSetup: Exercise?
    @State private var customSetCounts: [UUID: Int] = [:]
    /// Drives the warm-up guidance bottom sheet — opened from the inline reminder text
    /// above the command card. The reminder itself only renders for an exercise's first
    /// set; the sheet is informational and dismissible at any time.
    @State private var showsWarmupGuide: Bool = false
    /// Bumped on every successful `completeSet`. Drives `AppHaptic.setLogged`
    /// on `WorkoutCommandCard`, so the haptic lives at the atom layer instead
    /// of being fired imperatively from the view-model. Wraps via `&+=` to
    /// stay non-monotonic-safe.
    @State private var setLoggedPhase: Int = 0
    /// Re-entrancy guard. Two ultra-fast "Done" taps inside the same runloop
    /// could fire `completeSet` twice → duplicate `SetEntry` insert, double
    /// `setLoggedPhase` bump, double rest-timer start. Flipped true on entry,
    /// reset on the next runloop tick so legitimate next-set logging works.
    @State private var isLoggingSet: Bool = false
    /// Bumped exactly once when the lifter finishes the workout. Drives the
    /// session-finish success notification haptic.
    @State private var workoutFinishedPhase: Int = 0
    /// Bumped each time a logged set beats the all-time prior best for that exercise.
    /// Drives a heavy-impact haptic on top of `setLoggedPhase`'s `.success` so the
    /// PR moment is a distinct, milestone-feeling tap. Pure derivation in `completeSet`
    /// — no eager scan elsewhere.
    @State private var setPRPhase: Int = 0
    /// IDs of `SetEntry`s logged this session that were PRs at log time. `progressSteps`
    /// reads this to flip the chip to accent chrome, so the milestone persists visually
    /// for the rest of the workout (the haptic only fires once at log).
    @State private var prSetEntryIDs: Set<UUID> = []
    /// Sentence-case description of the prior best the most recent PR-set beat — fed to
    /// `WorkoutCommandCard.priorBestText`. Only the *most recent* PR's delta is shown,
    /// since the badge auto-hides ~3s. Set on PR detection in `completeSet`; the badge
    /// itself manages the dwell, so we never need to clear this — stale text is hidden
    /// behind the `prBadgeVisible` flag.
    @State private var lastPRPriorText: String? = nil
    /// Set entry currently open in the edit sheet (tap a logged chip in
    /// `SetProgressIndicator`). Drives `.sheet(item:)` for `AdjustResultSheet` in
    /// edit mode — same atom as new-set logging, just seeded from the existing entry.
    @State private var editingSetPayload: EditSetPayload? = nil
    /// One-shot reinforcement toast surfaced after the user dismisses their
    /// first set-edit sheet — confirms the just-discovered tap-to-edit gesture
    /// is reusable on every set. Persisted across launches so it never repeats.
    @AppStorage("hasSeenSetEditHint") private var hasSeenSetEditHint: Bool = false
    /// Bound to `appToast(message:)` on the screen root; the watcher on
    /// `editingSetPayload` sets it to the hint copy and clears the AppStorage flag.
    @State private var setEditHintToast: String? = nil
    /// Active when the lifter has just tapped a "+ 1 rep" / "+ 2.5 kg" suggestion
    /// chip — drives the metric-hero numeric cross-fade to the bumped target while
    /// the AdjustResultSheet opens. Cleared on sheet dismiss; never persisted.
    @State private var pendingSuggestionPreview: PendingSuggestionPreview? = nil
    /// Plus / minus on the rest timer adjust by this many seconds (minimum rest stays 30s).
    private static let restTimerAdjustStepSeconds = 30

    private var template: DayTemplate? {
        templates.first(where: { $0.id == session.templateId })
    }

    private var workoutNavigationTitle: String {
        (template?.name ?? "Workout").truncatedForNavigationTitle(maxGlyphCount: 34)
    }

    private var isFreestyleSession: Bool {
        template?.name == FreestyleSessionSupport.templateName
    }

    private var orderedExercises: [Exercise] {
        guard let template else { return [] }
        return template.orderedExerciseIds.compactMap { id in
            exercises.first(where: { $0.id == id })
        }
    }

    private var sectionModels: [WorkoutExerciseSectionModel] {
        orderedExercises.map { exercise in
            let plannedSetCount = plannedSetCount(for: exercise.id)
            let entries = currentEntries(for: exercise.id).filter { !$0.isWarmup }
            let prefill = viewModel.prefillSet(
                for: exercise.id,
                currentSession: session,
                sessions: sessions,
                plannedReps: template?.plannedReps(for: exercise.id)
            )

            return WorkoutExerciseSectionModel(
                exercise: exercise,
                lastActualText: lastActualText(for: exercise),
                entries: entries,
                prefill: prefill,
                plannedSetCount: plannedSetCount,
                suggestion: setSuggestion(from: prefill, isBodyweight: exercise.isBodyweight),
                priorSessionSetCount: priorSessionSetCount(for: exercise)
            )
        }
    }

    /// Compute the progressive-overload nudge for this section, if any. Only
    /// fires for prior-session prefills — once a set lands in the current
    /// session, the supporting slot empties and the chips disappear with it.
    private func setSuggestion(from prefill: SetPrefill?, isBodyweight: Bool) -> SetSuggestion? {
        guard let prefill, prefill.source == .priorSession else { return nil }
        let unitSystem = UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
        return SetSuggestion.compute(
            lastWeightKg: prefill.weight,
            lastReps: prefill.reps,
            isBodyweight: isBodyweight,
            unitSystem: unitSystem
        )
    }

    /// Number of working sets the lifter logged for this exercise in their most
    /// recent completed session. Feeds the metric hero's "Last 3×8×80kg"
    /// formatting so a chip-tap preview keeps the same set-count component
    /// (only reps or weight changes) and the per-glyph cross-fade lands cleanly.
    private func priorSessionSetCount(for exercise: Exercise) -> Int? {
        guard let lastSession = sessions.first(where: {
            $0.id != session.id &&
            $0.isCompleted &&
            $0.setEntries.contains(where: { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup })
        }) else { return nil }
        let count = lastSession.setEntries.filter {
            $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup
        }.count
        return count > 0 ? count : nil
    }

    /// Open the existing AdjustResultSheet pre-filled to the bumped target,
    /// and stage the same target as a `pendingSuggestionPreview` so the metric
    /// hero cross-fades to the new value while the sheet opens. The preview
    /// is cleared by the sheet's `onDismiss`. Reuses the same surface as
    /// `onSecondaryAction` ("Adjust") — the chip is just a smarter prefill,
    /// not a new sheet.
    private func presentSuggestionSheet(
        for section: WorkoutExerciseSectionModel,
        kind: SetSuggestionKind
    ) {
        guard let suggestion = section.suggestion else { return }
        let bumped: SetPrefill
        switch kind {
        case .reps:
            bumped = suggestion.repBumpedPrefill
        case .weight:
            guard let weightPrefill = suggestion.weightBumpedPrefill else { return }
            bumped = weightPrefill
        }
        withAnimation(reduceMotion ? nil : .appReveal) {
            pendingSuggestionPreview = PendingSuggestionPreview(
                exerciseId: section.exercise.id,
                bumpedWeight: bumped.weight,
                bumpedReps: bumped.reps
            )
        }
        adjustResultPayload = AdjustResultPayload(
            exercise: section.exercise,
            prefill: bumped
        )
    }

    /// Build the chip row passed to `WorkoutCommandCard`. One entry for the
    /// rep bump (always available when there's a prior-session anchor) and an
    /// optional second entry for the weight bump (suppressed for bodyweight).
    private func suggestionActions(
        for section: WorkoutExerciseSectionModel
    ) -> [WorkoutCommandCard.SuggestionAction] {
        guard let suggestion = section.suggestion else { return [] }
        var actions: [WorkoutCommandCard.SuggestionAction] = []
        actions.append(
            WorkoutCommandCard.SuggestionAction(label: suggestion.repChipLabel) {
                presentSuggestionSheet(for: section, kind: .reps)
            }
        )
        if suggestion.nextWeightKg != nil {
            actions.append(
                WorkoutCommandCard.SuggestionAction(label: suggestion.weightChipLabel) {
                    presentSuggestionSheet(for: section, kind: .weight)
                }
            )
        }
        return actions
    }

    private var recommendedExerciseIndex: Int {
        guard !sectionModels.isEmpty else { return 0 }
        return sectionModels.firstIndex(where: { !$0.hasReachedPlannedSetGoal }) ?? max(sectionModels.count - 1, 0)
    }

    private var isWorkoutComplete: Bool {
        !sectionModels.isEmpty && sectionModels.allSatisfy(\.hasReachedPlannedSetGoal)
    }

    private var nextSection: WorkoutExerciseSectionModel? {
        guard selectedExerciseIndex < sectionModels.count - 1 else { return nil }
        return sectionModels[selectedExerciseIndex + 1]
    }

    private var currentSection: WorkoutExerciseSectionModel? {
        guard sectionModels.indices.contains(selectedExerciseIndex) else { return nil }
        return sectionModels[selectedExerciseIndex]
    }

    private var primaryButton: PrimaryButtonConfig? {
        guard isWorkoutComplete else { return nil }
        return PrimaryButtonConfig(label: AppCopy.Workout.finishWorkout) {
            showsFinishConfirmation = true
        }
    }

    private var nextExerciseBarState: SessionStateBar.State? {
        guard let nextSection, !isWorkoutComplete else { return nil }
        return .nextExercise(subtitle: nextSection.exercise.displayName)
    }

    /// Show the warmup reminder when the lifter hasn't logged a working set for
    /// the *current* exercise yet. Lives in the bottom safe-area inset (above
    /// the next-exercise CTA) so the page reads top-down: nav, card, warmup,
    /// next-exercise.
    private var showsWarmupReminder: Bool {
        guard let section = currentSection else { return false }
        return !hasLoggedWorkingSet(for: section.exercise.id)
    }

    private func emptyMetricPlaceholder() -> String {
        let hasAnyCompleted = sessions.contains(where: \.isCompleted)
        if !hasAnyCompleted {
            return AppCopy.EmptyState.noHistoryYet
        }
        return AppCopy.EmptyState.noPriorSets
    }

    /// True while the rest timer is running and ≤ 3 seconds remain.
    /// Drives `AppHaptic.restFinalCountdown` on the screen — with a
    /// `false → true` filter so the haptic fires once when the lifter
    /// enters the heads-up window, not on every tick. Visual treatment
    /// is intentionally absent (numeric countdown already cross-fades;
    /// pulse / ring fill is decorative motion).
    private var isRestFinalCountdown: Bool {
        restTimer.isRunning && restTimer.secondsRemaining > 0 && restTimer.secondsRemaining <= 3
    }

    private var timerDisplayText: String {
        if showsReadyState && restTimer.secondsRemaining == 0 && !restTimer.isRunning {
            return "Ready"
        }

        if restTimer.secondsRemaining > 0 {
            return restTimer.label
        }

        let minutes = restDurationSeconds / 60
        let seconds = restDurationSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    private var timerControlState: RestTimerControl.State {
        if showsReadyState && restTimer.secondsRemaining == 0 && !restTimer.isRunning {
            return .ready
        }

        if restTimer.isRunning {
            return .running
        }

        if restTimer.secondsRemaining > 0 {
            return .paused
        }

        return .idle
    }

    /// Inline reminder rendered above the command card before the lifter logs the
    /// first working set for an exercise. Two-line muted caption — reminder on top,
    /// tap affordance below — both in `textSecondary` so the block reads as one quiet
    /// note rather than a hyperlink. Disappears once a working set is logged.
    private var warmupReminderText: some View {
        Button {
            showsWarmupGuide = true
        } label: {
            Text("\(AppCopy.Workout.warmupReminder)\n\(AppCopy.Workout.warmupReminderLink)")
                .appFont(.muted)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens warm-up guidance")
    }

    @ViewBuilder
    private func workoutMainColumn(for section: WorkoutExerciseSectionModel) -> some View {
        VStack(spacing: AppSpacing.lg) {
            WorkoutCommandCard(
                progressSteps: progressSteps(for: section),
                exerciseName: section.exercise.displayName,
                metricValue: metricValue(for: section),
                metricSupportingText: nil,
                metricIsHint: metricIsPlaceholder(for: section),
                metricIsGhost: metricIsGhost(for: section),
                state: workoutCommandCardState(for: section),
                primaryLabel: AppCopy.Workout.completeSet,
                onPrimaryAction: section.hasReachedPlannedSetGoal ? nil : {
                    completeSuggestedSet(
                        exercise: section.exercise,
                        prefill: section.prefill
                    )
                },
                onSecondaryAction: section.hasReachedPlannedSetGoal ? nil : {
                    adjustResultPayload = AdjustResultPayload(
                        exercise: section.exercise,
                        prefill: section.prefill
                    )
                },
                setLoggedSignal: setLoggedPhase,
                setPRSignal: setPRPhase,
                priorBestText: lastPRPriorText,
                timerValue: timerDisplayText,
                timerState: timerControlState,
                onTimerDecrease: adjustRestTimerAction,
                onTimerToggle: toggleRestTimerAction,
                onTimerIncrease: increaseRestTimerAction,
                suggestionActions: suggestionActions(for: section)
            )

            if isFreestyleSession {
                addExerciseButton
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
    }

    private func workoutCommandCardState(for section: WorkoutExerciseSectionModel) -> WorkoutCommandCard.State {
        if section.hasReachedPlannedSetGoal {
            return .completed
        }
        return .active
    }

    private func metricValue(for section: WorkoutExerciseSectionModel) -> String {
        if let preview = pendingSuggestionPreview,
           preview.exerciseId == section.exercise.id,
           let setCount = section.priorSessionSetCount {
            return WorkoutTargetFormatter.lastText(
                weightKg: preview.bumpedWeight,
                setCount: setCount,
                reps: preview.bumpedReps,
                isBodyweight: section.exercise.isBodyweight
            )
        }
        if let lastValues = lastLoggedValues(for: section.exercise.id) {
            return WorkoutTargetFormatter.setMetricText(
                weightKg: lastValues.weight,
                reps: lastValues.reps,
                isBodyweight: section.exercise.isBodyweight
            ) ?? emptyMetricPlaceholder()
        }
        if let lastActual = section.lastActualText {
            return lastActual
        }
        return emptyMetricPlaceholder()
    }

    private func metricIsPlaceholder(for section: WorkoutExerciseSectionModel) -> Bool {
        if lastLoggedValues(for: section.exercise.id) != nil { return false }
        if section.lastActualText != nil { return false }
        return true
    }

    private func metricIsGhost(for section: WorkoutExerciseSectionModel) -> Bool {
        if lastLoggedValues(for: section.exercise.id) != nil { return false }
        return section.lastActualText != nil
    }

    /// All-time best working set for `exerciseID`, drawn from completed prior sessions
    /// and from already-logged working sets in the current session — minus `entryID` if
    /// supplied. Returns nil when there's no prior data to beat (a brand-new exercise),
    /// which means the first log is *not* flagged a PR. Conservative on purpose: a PR
    /// signal only feels meaningful when there was a baseline.
    private func priorBest(for exerciseID: UUID, excluding entryID: UUID? = nil) -> (weight: Double, reps: Int)? {
        let priorSessionEntries = sessions
            .filter { $0.isCompleted }
            .flatMap { session in
                session.setEntries.filter { entry in
                    entry.exerciseId == exerciseID
                        && entry.isCompleted
                        && !entry.isWarmup
                }
            }
        let currentSessionEntries = session.setEntries.filter { entry in
            entry.exerciseId == exerciseID
                && entry.isCompleted
                && !entry.isWarmup
                && entry.id != entryID
        }
        let combined = priorSessionEntries + currentSessionEntries
        return combined
            .max { lhs, rhs in
                lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight
            }
            .map { ($0.weight, $0.reps) }
    }

    var body: some View {
        AppScreen(
            primaryButton: primaryButton,
            showsNativeNavigationBar: true
        ) {
            if let currentSection {
                workoutMainColumn(for: currentSection)
            } else {
                addExercisePrompt
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if showsWarmupReminder {
                    warmupReminderText
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(AppColor.background)
                }
                if let nextExerciseBarState {
                    SessionStateBar(
                        state: nextExerciseBarState,
                        onAdvance: nextSection == nil ? nil : goToNextExerciseAction
                    )
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(workoutNavigationTitle)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showsCancelConfirmation = true
                } label: {
                    Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(AppCopy.Nav.close)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if !sectionModels.isEmpty {
                    Button {
                        showLineup = true
                    } label: {
                        Label(AppCopy.Nav.exercises, systemImage: AppIcon.list.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(AppCopy.Nav.exercises)
                }
                if session.setEntries.contains(where: { $0.isCompleted }) && !isWorkoutComplete {
                    Button {
                        showsFinishConfirmation = true
                    } label: {
                        Label(AppCopy.Workout.finishWorkout, systemImage: AppIcon.checkmark.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(AppCopy.Workout.finishWorkout)
                }
            }
        }
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        // Final-3s heads-up: a single warning haptic when the rest countdown
        // enters the ≤3s window while running. No visual emphasis — brand
        // doctrine treats final-seconds pulses / ring fills as decorative,
        // and the haptic survives Reduce Motion (it is permitted tactile
        // feedback). The closure filter fires only on `false → true` so we
        // don't haptic-spam every tick.
        .appHaptic(.restFinalCountdown, trigger: isRestFinalCountdown) { old, new in
            !old && new
        }
        // Rest finished → soft success on transition to ready. Distinct from
        // the warning above so the lifter can hear/feel "now". Filter mirrors
        // the heads-up: only `false → true`.
        .appHaptic(.restReady, trigger: showsReadyState) { old, new in
            !old && new
        }
        // Workout finished → success haptic, fired from the screen rather
        // than imperatively in `finishWorkout` so it survives Reduce Motion
        // gating identically to the in-flow haptics.
        .appHaptic(.workoutFinished, trigger: workoutFinishedPhase)
        .sheet(isPresented: $showsWarmupGuide) {
            WarmupGuideSheet()
                .presentationDetents([.medium])
                .appBottomSheetChrome()
        }
        .sheet(isPresented: $showLineup) {
            exerciseListSheet
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .sheet(item: $adjustResultPayload, onDismiss: {
            withAnimation(reduceMotion ? nil : .appReveal) {
                pendingSuggestionPreview = nil
            }
        }) { payload in
            AdjustResultSheet(
                exerciseName: payload.exercise.displayName,
                isBodyweight: payload.exercise.isBodyweight,
                mode: .log(prefill: payload.prefill),
                onSave: { weight, reps, note in
                    completeSet(
                        exercise: payload.exercise,
                        weight: weight,
                        reps: reps,
                        note: note
                    )
                }
            )
            .presentationDetents([.medium, .large])
            .appBottomSheetChrome()
        }
        .sheet(item: $editingSetPayload) { payload in
            AdjustResultSheet(
                exerciseName: payload.exercise.displayName,
                isBodyweight: payload.exercise.isBodyweight,
                mode: .edit(
                    weight: payload.entry.weight,
                    reps: payload.entry.reps,
                    note: payload.entry.note,
                    setNumber: payload.setNumber
                ),
                onSave: { weight, reps, note in
                    updateSet(
                        payload.entry,
                        exercise: payload.exercise,
                        weight: weight,
                        reps: reps,
                        note: note
                    )
                },
                onDelete: {
                    deleteSet(payload.entry, exercise: payload.exercise)
                }
            )
            .presentationDetents([.medium, .large])
            .appBottomSheetChrome()
        }
        // Fires the set-edit hint once, the first time the user *closes* an
        // edit sheet — by then the toast is no longer occluded by the sheet,
        // and the user has just successfully discovered the gesture, so the
        // copy reads as reinforcement ("you can do that on any set anytime").
        .onChange(of: editingSetPayload != nil) { wasShowing, isShowing in
            guard wasShowing, !isShowing, !hasSeenSetEditHint else { return }
            hasSeenSetEditHint = true
            setEditHintToast = AppCopy.Workout.setEditHint
        }
        .appToast(message: $setEditHintToast)
        .sheet(isPresented: $showsAddExercise) {
            AppExercisePickerSheet(
                existingIds: Set(template?.orderedExerciseIds ?? [])
            ) { exercise in
                addExerciseToWorkout(exercise)
            }
        }
        .sheet(item: $pendingExerciseForSetup) { exercise in
            SetCountPickerSheet(exerciseName: exercise.displayName) { count in
                customSetCounts[exercise.id] = count
            }
            .presentationDetents([.height(320)])
            .appBottomSheetChrome()
        }
        .alert(AppCopy.Workout.cancelWorkoutTitle, isPresented: $showsCancelConfirmation) {
            Button(AppCopy.Workout.cancelWorkoutAction, role: .destructive) {
                cancelWorkout()
            }
            Button(AppCopy.Workout.keepGoing, role: .cancel) {}
        } message: {
            Text(AppCopy.Workout.cancelWorkoutMessage)
        }
        .alert(AppCopy.Workout.skipExerciseTitle, isPresented: $showsSkipExerciseConfirmation) {
            Button(AppCopy.Workout.skipExerciseAction, role: .destructive) {
                goToNextExercise()
            }
            Button(AppCopy.Workout.keepLogging, role: .cancel) {}
        } message: {
            if let currentSection {
                let remaining = currentSection.plannedSetCount - currentSection.entries.count
                Text("\(remaining) set\(remaining == 1 ? "" : "s") still unlogged for \(currentSection.exercise.displayName).")
            }
        }
        .alert(AppCopy.Workout.finishWorkoutTitle, isPresented: $showsFinishConfirmation) {
            Button(AppCopy.Workout.finishWorkout) {
                finishWorkout()
                if template?.name == FreestyleSessionSupport.templateName {
                    renameDraft = ""
                    showsRenamePrompt = true
                }
            }
            Button(AppCopy.Nav.cancel, role: .cancel) {}
        } message: {
            Text(AppCopy.Workout.finishWorkoutMessage)
        }
        .alert(AppCopy.Workout.nameWorkoutTitle, isPresented: $showsRenamePrompt) {
            TextField(AppCopy.Workout.nameWorkoutFieldPlaceholder, text: $renameDraft)
            Button(AppCopy.Session.useName) {
                let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if let template, !trimmed.isEmpty {
                    template.name = trimmed
                    try? modelContext.save()
                }
                renameDraft = ""
            }
            Button(AppCopy.Session.skipNaming, role: .cancel) {
                // Skip with a typed draft is the lossy path — funnel through a
                // second confirmation so the lifter can't lose a name with one
                // wrong tap (HIG: destructive flows ask once). Tapping Skip on
                // an empty field still dismisses cleanly because there is
                // nothing to discard.
                if !renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showsDiscardRenamePrompt = true
                }
            }
        } message: {
            Text(AppCopy.Workout.nameWorkoutMessage)
        }
        .alert(
            AppCopy.Session.discardWorkoutNameTitle,
            isPresented: $showsDiscardRenamePrompt
        ) {
            Button(AppCopy.Session.discardWorkoutNameAction, role: .destructive) {
                renameDraft = ""
            }
            Button(AppCopy.Workout.keepEditing, role: .cancel) {
                // Re-open the rename alert with the typed draft intact so the
                // lifter resumes typing exactly where they left off — same
                // pattern Mail uses for "Keep Draft" on attempted discard.
                showsRenamePrompt = true
            }
        } message: {
            Text(AppCopy.Session.discardWorkoutNameMessage(
                renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
            ))
        }
        .onAppear {
            selectedExerciseIndex = recommendedExerciseIndex
        }
        .onChange(of: sectionModels.count) { _, newValue in
            guard newValue > 0 else {
                selectedExerciseIndex = 0
                return
            }
            selectedExerciseIndex = min(selectedExerciseIndex, newValue - 1)
        }
        .onChange(of: restTimer.completionCount) { _, newValue in
            guard newValue > 0 else { return }
            showsReadyState = true
        }
        .onDisappear {
            restTimer.stop()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active, restTimer.endDate != nil {
                restTimer.resumeFromBackground()
            }
        }
    }

    private var addExercisePrompt: some View {
        AppCard {
            VStack(alignment: .center, spacing: AppSpacing.md) {
                Text(AppCopy.Workout.addFirstExerciseTitle)
                    .font(AppFont.productHeading.font)
                    .foregroundStyle(AppColor.textPrimary)

                Text(AppCopy.Workout.addFirstExerciseHint)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.center)

                AppPrimaryButton(AppCopy.Workout.addExercise) {
                    showsAddExercise = true
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var addExerciseButton: some View {
        AppGhostButton(AppCopy.Workout.addExercise) {
            showsAddExercise = true
        }
    }

    private var exerciseListSheet: some View {
        AppSheetScreen(
            title: AppCopy.Nav.exercises,
            dismissLabel: AppCopy.Nav.done,
            dismissActionPlacement: .confirmation,
            onDismissAction: { showLineup = false }
        ) {
            VStack(spacing: AppSpacing.sm) {
                ForEach(exerciseLineupFragments) { fragment in
                    switch fragment {
                    case .grouped(let pairs):
                        AppCardList(data: pairs.map { LineupRowItem(index: $0.index, section: $0.section) }, id: \.id) { item in
                            Button {
                                selectedExerciseIndex = item.index
                                showLineup = false
                            } label: {
                                exerciseLineupRowContent(index: item.index, section: item.section)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel(
                                exerciseLineupAccessibilityLabel(
                                    name: item.section.exercise.displayName,
                                    isCurrent: item.index == selectedExerciseIndex,
                                    isDone: item.section.hasReachedPlannedSetGoal
                                )
                            )
                        }
                    case .rich(let index, let section):
                        AppCardList(data: [LineupRowItem(index: index, section: section)], id: \.id) { item in
                            Button {
                                selectedExerciseIndex = item.index
                                showLineup = false
                            } label: {
                                exerciseLineupRowContent(index: item.index, section: item.section)
                            }
                            .buttonStyle(ScaleButtonStyle())
                            .accessibilityLabel(
                                exerciseLineupAccessibilityLabel(
                                    name: item.section.exercise.displayName,
                                    isCurrent: item.index == selectedExerciseIndex,
                                    isDone: item.section.hasReachedPlannedSetGoal
                                )
                            )
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private struct LineupRowItem {
        let index: Int
        let section: WorkoutExerciseSectionModel
        var id: UUID { section.id }
    }

    private enum ExerciseLineupFragment: Identifiable {
        case grouped([(index: Int, section: WorkoutExerciseSectionModel)])
        case rich(index: Int, section: WorkoutExerciseSectionModel)

        var id: String {
            switch self {
            case .grouped(let pairs):
                "g-" + pairs.map { "\($0.index)-\($0.section.id.uuidString)" }.joined(separator: "|")
            case .rich(let index, let section):
                "r-\(index)-\(section.id.uuidString)"
            }
        }
    }

    /// Name-only rows are merged into one card with hairlines; rows with last-session subtitle stay on their own card.
    private var exerciseLineupFragments: [ExerciseLineupFragment] {
        var result: [ExerciseLineupFragment] = []
        var nameOnlyRun: [(index: Int, section: WorkoutExerciseSectionModel)] = []

        func flushRun() {
            guard !nameOnlyRun.isEmpty else { return }
            result.append(.grouped(nameOnlyRun))
            nameOnlyRun = []
        }

        for (index, section) in sectionModels.enumerated() {
            if exerciseListSubtitle(for: section) != nil {
                flushRun()
                result.append(.rich(index: index, section: section))
            } else {
                nameOnlyRun.append((index: index, section: section))
            }
        }
        flushRun()
        return result
    }

    @ViewBuilder
    private func exerciseLineupRowContent(index: Int, section: WorkoutExerciseSectionModel) -> some View {
        let isCurrent = index == selectedExerciseIndex
        let isDone = section.hasReachedPlannedSetGoal

        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(section.exercise.displayName)
                    .font(AppFont.productAction.font)
                    .foregroundStyle(isDone ? AppColor.textSecondary : AppColor.textPrimary)
                    .multilineTextAlignment(.leading)

                if let subtitle = exerciseListSubtitle(for: section) {
                    Text(subtitle)
                        .font(AppFont.caption.font)
                        .foregroundStyle(isDone ? AppColor.textDisabled : AppColor.textSecondary)
                }
            }

            Spacer(minLength: 0)

            if isCurrent && !isDone {
                AppTag(text: AppCopy.Workout.exerciseCurrentTag, style: .accent)
            } else if isDone {
                AppIconCircle(diameter: 24, surface: .tinted(AppColor.success, opacity: 0.1)) {
                    AppIcon.checkmark.image(size: 12, weight: .bold)
                        .foregroundStyle(AppColor.success)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func exerciseListSubtitle(for section: WorkoutExerciseSectionModel) -> String? {
        section.lastActualText
    }

    private func exerciseLineupAccessibilityLabel(name: String, isCurrent: Bool, isDone: Bool) -> String {
        if isDone { return "\(name), completed" }
        if isCurrent { return "\(name), current exercise" }
        return name
    }

    private func lastLoggedValues(for exerciseID: UUID) -> (weight: Double, reps: Int)? {
        let entries = currentEntries(for: exerciseID).filter { !$0.isWarmup }
        guard let last = entries.last else { return nil }
        return (last.weight, last.reps)
    }

    private func currentEntries(for exerciseID: UUID) -> [SetEntry] {
        session.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }
    }

    private func progressSteps(for section: WorkoutExerciseSectionModel) -> [SetProgressIndicator.Step] {
        (0..<section.plannedSetCount).map { index in
            let state: SetProgressIndicator.Step.State
            var reps: Int?
            var weightText: String?
            var isPR: Bool = false
            var isEditing: Bool = false
            var onTap: (() -> Void)? = nil

            if index < section.entries.count {
                let entry = section.entries[index]
                state = .completed
                reps = entry.reps
                if entry.weight > 0 {
                    weightText = WorkoutTargetFormatter.weightCompact(entry.weight)
                } else if section.exercise.isBodyweight {
                    weightText = "BW"
                }
                isPR = prSetEntryIDs.contains(entry.id)
                isEditing = editingSetPayload?.entry.id == entry.id
                onTap = {
                    editingSetPayload = EditSetPayload(
                        entry: entry,
                        exercise: section.exercise,
                        setNumber: index + 1
                    )
                }
            } else if !section.hasReachedPlannedSetGoal && index == section.entries.count {
                state = .current
            } else {
                state = .upcoming
            }

            return SetProgressIndicator.Step(
                id: index,
                label: "\(index + 1)",
                state: state,
                reps: reps,
                weightText: weightText,
                isPR: isPR,
                isEditing: isEditing,
                onTap: onTap
            )
        }
    }

    private func nextSetHelperText(for section: WorkoutExerciseSectionModel) -> String? {
        guard !section.hasReachedPlannedSetGoal else { return nil }
        let nextSetNumber = min(section.entries.count + 1, section.plannedSetCount)
        return "Next: Set \(nextSetNumber)"
    }

    private var adjustRestTimerAction: (() -> Void)? {
        guard currentSection != nil, !isWorkoutComplete else { return nil }
        return { adjustRestTimer(by: -Self.restTimerAdjustStepSeconds) }
    }

    private var increaseRestTimerAction: (() -> Void)? {
        guard currentSection != nil, !isWorkoutComplete else { return nil }
        return { adjustRestTimer(by: Self.restTimerAdjustStepSeconds) }
    }

    private var toggleRestTimerAction: (() -> Void)? {
        guard currentSection != nil, !isWorkoutComplete else { return nil }
        return { toggleRestTimer() }
    }

    private var goToNextExerciseAction: (() -> Void)? {
        guard nextSection != nil else { return nil }
        return {
            if let currentSection, !currentSection.hasReachedPlannedSetGoal {
                showsSkipExerciseConfirmation = true
            } else {
                goToNextExercise()
            }
        }
    }

    private func lastActualText(for exercise: Exercise) -> String? {
        guard let lastSession = sessions.first(where: {
            $0.id != session.id &&
            $0.isCompleted &&
            $0.setEntries.contains(where: { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup })
        }) else {
            return nil
        }

        let sets = lastSession.setEntries
            .filter { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup }
            .sorted { $0.setIndex < $1.setIndex }

        return sets.last.map {
            WorkoutTargetFormatter.lastText(
                weightKg: $0.weight,
                setCount: sets.count,
                reps: $0.reps,
                isBodyweight: exercise.isBodyweight
            )
        }
    }

    private func toggleRestTimer() {
        if restTimer.isRunning {
            restTimer.pause()
            return
        }

        if restTimer.secondsRemaining > 0 {
            restTimer.resume()
        } else {
            startRestTimer(seconds: restDurationSeconds)
        }
    }

    private func startRestTimer(seconds: Int) {
        showsReadyState = false
        restDurationSeconds = max(30, seconds)
        restTimer.start(totalSeconds: restDurationSeconds, upNext: nextSection?.exercise.displayName)
    }

    private func adjustRestTimer(by delta: Int) {
        if restTimer.secondsRemaining > 0 {
            showsReadyState = false
            restTimer.adjust(by: delta, minimumSeconds: 30)
            restDurationSeconds = max(30, restTimer.totalDuration)
        } else {
            restDurationSeconds = max(30, restDurationSeconds + delta)
        }
    }

    private func goToNextExercise() {
        guard selectedExerciseIndex < sectionModels.count - 1 else { return }
        showsReadyState = false
        restTimer.stop()
        withAnimation(reduceMotion ? nil : .appExit) {
            selectedExerciseIndex += 1
        }
    }

    private func completeSuggestedSet(
        exercise: Exercise,
        prefill: SetPrefill?
    ) {
        if let prefill, prefill.source != .planned {
            completeSet(
                exercise: exercise,
                weight: prefill.weight,
                reps: prefill.reps
            )
            return
        }

        adjustResultPayload = AdjustResultPayload(
            exercise: exercise,
            prefill: prefill
        )
    }

    private func completeSet(
        exercise: Exercise,
        weight: Double,
        reps: Int,
        note: String = ""
    ) {
        guard !isLoggingSet else { return }
        isLoggingSet = true
        DispatchQueue.main.async { isLoggingSet = false }

        let setIndex = (currentEntries(for: exercise.id).map(\.setIndex).max() ?? -1) + 1

        let entry = SetEntry(
            sessionId: session.id,
            exerciseId: exercise.id,
            weight: weight,
            reps: reps,
            rpe: 0,
            rir: -1,
            isWarmup: false,
            isCompleted: true,
            setIndex: setIndex,
            note: note
        )
        entry.session = session

        // The metric value displayed by `WorkoutCommandCard` reads through
        // `currentEntries`, which mutates as soon as we insert. Wrapping the
        // insertion in `withAnimation` lets SwiftUI propagate the transaction
        // through `@Query` re-renders, so the card's `.contentTransition(.numericText())`
        // engages — the next prefill weight × reps cross-fades into view
        // instead of flickering. `nil` under Reduce Motion preserves the
        // mutation but skips the cross-fade.
        withAnimation(reduceMotion ? nil : .appReveal) {
            modelContext.insert(entry)
            try? modelContext.save()
            showsReadyState = false
        }

        // Trigger the success haptic on `WorkoutCommandCard` via the bound
        // `setLoggedSignal` (replaces the previous raw UIKit impact). The
        // haptic fires regardless of Reduce Motion — accessibility doctrine
        // explicitly permits tactile feedback.
        setLoggedPhase &+= 1

        // Compare against the prior all-time best (excluding the just-inserted
        // entry). When it beats the baseline, mark the entry so its chip flips
        // to accent chrome and stack a heavy-impact haptic on top of the
        // success cue. No baseline → no PR (first-ever log doesn't fire).
        if let prior = priorBest(for: exercise.id, excluding: entry.id) {
            let beats = weight > prior.weight
                || (weight == prior.weight && reps > prior.reps)
            if beats {
                prSetEntryIDs.insert(entry.id)
                lastPRPriorText = WorkoutTargetFormatter.milestoneText(
                    weightKg: prior.weight,
                    reps: prior.reps,
                    isBodyweight: exercise.isBodyweight
                ).map(AppCopy.Workout.priorBest)
                setPRPhase &+= 1
            }
        }

        let completedWorkingSetCount = currentEntries(for: exercise.id)
            .filter { !$0.isWarmup }
            .count
        let plannedCount = plannedSetCount(for: exercise.id)

        if completedWorkingSetCount >= plannedCount {
            if nextSection == nil {
                restTimer.stop()
            } else {
                startRestTimer(seconds: restDurationSeconds)
            }
        } else {
            startRestTimer(seconds: restDurationSeconds)
        }
    }

    /// Tap a logged chip → edit sheet → save: replace weight/reps/note in place.
    /// No new haptic, no PR badge — this is a correction, not a celebration.
    /// PR flag for *this* entry is re-evaluated against the current baseline; other
    /// entries keep their original at-log-time flags so an unrelated edit doesn't
    /// retroactively demote earlier milestones.
    private func updateSet(
        _ entry: SetEntry,
        exercise: Exercise,
        weight: Double,
        reps: Int,
        note: String
    ) {
        guard reps > 0 else {
            deleteSet(entry, exercise: exercise)
            return
        }
        withAnimation(reduceMotion ? nil : .appReveal) {
            entry.weight = weight
            entry.reps = reps
            entry.note = note
            try? modelContext.save()
        }
        reevaluatePRFlag(for: entry, exerciseID: exercise.id)
    }

    /// Tap a logged chip → edit sheet → delete (or save with reps == 0). Removes
    /// the entry, drops any stale PR flag for it, and lets the rest timer keep
    /// running — the user is mid-rest correcting a typo, not finishing the set
    /// over again. Set indices are intentionally not renumbered: `currentEntries`
    /// sorts by `setIndex`, gaps are harmless, and the next `completeSet` writes
    /// a fresh trailing index via `currentEntries.count`.
    private func deleteSet(_ entry: SetEntry, exercise: Exercise) {
        withAnimation(reduceMotion ? nil : .appExit) {
            modelContext.delete(entry)
            try? modelContext.save()
        }
        prSetEntryIDs.remove(entry.id)
        AppHaptic.setDeleted.fire()
    }

    /// Re-evaluate just the edited entry's PR flag against the current baseline.
    /// Unedited entries retain their at-log-time flags — matching the existing
    /// semantic (the chip Ink chrome marks "this was a PR moment when you logged it",
    /// not "this is the current all-time best"). The 3-second PR badge does not
    /// re-fire on edit; this only tracks the persistent chip color.
    private func reevaluatePRFlag(for entry: SetEntry, exerciseID: UUID) {
        if let prior = priorBest(for: exerciseID, excluding: entry.id) {
            let beats = entry.weight > prior.weight
                || (entry.weight == prior.weight && entry.reps > prior.reps)
            if beats {
                prSetEntryIDs.insert(entry.id)
            } else {
                prSetEntryIDs.remove(entry.id)
            }
        } else {
            prSetEntryIDs.remove(entry.id)
        }
    }

    private func hasLoggedWorkingSet(for exerciseID: UUID) -> Bool {
        session.setEntries.contains { entry in
            entry.exerciseId == exerciseID
                && entry.isCompleted
                && !entry.isWarmup
        }
    }

    private func finishWorkout() {
        restTimer.stop()
        session.isCompleted = true
        try? modelContext.save()
        workoutFinishedPhase &+= 1
    }

    private func addExerciseToWorkout(_ exercise: Exercise) {
        guard let template else { return }
        var ids = template.orderedExerciseIds
        guard !ids.contains(exercise.id) else { return }
        ids.append(exercise.id)
        template.orderedExerciseIds = ids
        try? modelContext.save()
        selectedExerciseIndex = ids.count - 1
        pendingExerciseForSetup = exercise
    }

    private func cancelWorkout() {
        restTimer.stop()
        modelContext.delete(session)
        try? modelContext.save()
    }

    private func plannedSetCount(for exerciseID: UUID) -> Int {
        if let custom = customSetCounts[exerciseID] {
            return custom
        }
        if let latestTemplateCount = latestCompletedSetCount(for: exerciseID, matchingTemplate: true) {
            return latestTemplateCount
        }
        if let latestAnyCount = latestCompletedSetCount(for: exerciseID, matchingTemplate: false) {
            return latestAnyCount
        }
        if let templatePlan = template?.plannedSets(for: exerciseID), templatePlan > 0 {
            return templatePlan
        }
        return 3
    }

    private func latestCompletedSetCount(for exerciseID: UUID, matchingTemplate: Bool) -> Int? {
        let candidates = sessions.filter { candidate in
            candidate.id != session.id &&
            candidate.isCompleted &&
            (!matchingTemplate || candidate.templateId == session.templateId) &&
            candidate.setEntries.contains(where: {
                $0.exerciseId == exerciseID &&
                $0.isCompleted &&
                !$0.isWarmup
            })
        }

        guard let latest = candidates.max(by: { $0.date < $1.date }) else {
            return nil
        }

        let setCount = latest.setEntries.filter {
            $0.exerciseId == exerciseID &&
            $0.isCompleted &&
            !$0.isWarmup
        }.count

        return setCount > 0 ? setCount : nil
    }
}

private struct WorkoutExerciseSectionModel: Identifiable {
    let exercise: Exercise
    let lastActualText: String?
    let entries: [SetEntry]
    let prefill: SetPrefill?
    let plannedSetCount: Int
    /// Non-nil only when `prefill.source == .priorSession` — i.e. there's a
    /// prior-session anchor to bump from. Drives the `+ 1 rep` / `+ 2.5 kg`
    /// chips rendered in `WorkoutCommandCard.metricSupportingSlot`.
    let suggestion: SetSuggestion?
    /// Number of working sets the lifter logged for this exercise in their most
    /// recent completed session — feeds the `pendingSuggestionPreview` cross-fade
    /// so a chip tap keeps the same set-count component (only weight or reps
    /// changes).
    let priorSessionSetCount: Int?

    var id: UUID { exercise.id }

    var hasReachedPlannedSetGoal: Bool {
        entries.count >= plannedSetCount
    }
}

/// Presentation-only progressive-overload nudge — derived from the most recent
/// completed prior-session set, recomputed on every render, never persisted.
/// Pairs with the suggestion chips in `WorkoutCommandCard.metricSupportingSlot`.
///
/// Both `+ 1 rep` and `+ 2.5 kg` (or `+ 5 lb`) chips render side by side for
/// weighted exercises so the lifter picks which axis to push without the app
/// deciding for them. Bodyweight exercises only expose the rep chip — no
/// plates to add. The chip is the only progression-suggestion surface in the
/// app by doctrine: PRODUCT.md principle 2 ("History, not instructions") is
/// partially relaxed here, scoped to two tap-to-accept hints. No engine, no
/// rule storage, no per-exercise progression model. If a future request asks
/// for a "third chip", "configurable increment", or "auto-accept" — push back.
struct SetSuggestion: Equatable {
    let lastWeightKg: Double
    let lastReps: Int
    /// One more than `lastReps`. Always available — every lift can take a rep.
    let nextReps: Int
    /// `lastWeightKg` plus the smallest legal increment for the user's unit.
    /// `nil` for bodyweight (no plates to add).
    let nextWeightKg: Double?

    /// Smallest legal weight increment in kilograms, sized to the user's unit
    /// system. Internal storage is kg; lb users see "+ 5 lb" because
    /// 5 lb ≈ 2.268 kg.
    static func smallestIncrementKg(unitSystem: String) -> Double {
        unitSystem == "lb" ? 5.0 / 2.20462 : 2.5
    }

    static func compute(
        lastWeightKg: Double,
        lastReps: Int,
        isBodyweight: Bool,
        unitSystem: String
    ) -> SetSuggestion {
        SetSuggestion(
            lastWeightKg: lastWeightKg,
            lastReps: lastReps,
            nextReps: lastReps + 1,
            nextWeightKg: isBodyweight
                ? nil
                : lastWeightKg + smallestIncrementKg(unitSystem: unitSystem)
        )
    }

    var repChipLabel: String { "+ 1 rep" }

    var weightChipLabel: String {
        let unit = UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
        return unit == "lb" ? "+ 5 lb" : "+ 2.5 kg"
    }

    /// Bumped prefill for the rep chip — same weight, +1 rep.
    var repBumpedPrefill: SetPrefill {
        SetPrefill(weight: lastWeightKg, reps: nextReps, source: .priorSession)
    }

    /// Bumped prefill for the weight chip — same reps, +smallest increment.
    /// `nil` when `nextWeightKg` is unavailable (bodyweight exercise).
    var weightBumpedPrefill: SetPrefill? {
        nextWeightKg.map {
            SetPrefill(weight: $0, reps: lastReps, source: .priorSession)
        }
    }
}

/// Which axis the lifter chose to push when tapping a suggestion chip.
enum SetSuggestionKind {
    case reps
    case weight
}

/// Transient preview state — when the lifter taps a suggestion chip, the
/// metric hero shows the bumped target (animated via `numericText` cross-fade)
/// while the AdjustResultSheet opens for confirmation. Cleared on sheet
/// dismiss; never persisted.
private struct PendingSuggestionPreview: Equatable {
    let exerciseId: UUID
    let bumpedWeight: Double
    let bumpedReps: Int
}

private struct AdjustResultPayload: Identifiable {
    let exercise: Exercise
    let prefill: SetPrefill?

    var id: UUID { exercise.id }
}

/// Tap a logged chip in `SetProgressIndicator` to seed this. Carries both the
/// exercise (for the title + bodyweight flag) and the entry being edited (so the
/// sheet can seed weight × reps × note from the existing values, not from prefill).
private struct EditSetPayload: Identifiable {
    let entry: SetEntry
    let exercise: Exercise
    /// 1-based number shown on the chip the user tapped — drives the sheet title.
    let setNumber: Int

    var id: UUID { entry.id }
}

private struct AdjustResultSheet: View {
    /// Drives the sheet's seed values, primary CTA, and trailing destructive action.
    /// `.log` is the original new-set flow (prefill from prior session). `.edit` is
    /// the new chip-tap flow (seed from the existing entry, expose Delete set).
    enum Mode {
        case log(prefill: SetPrefill?)
        case edit(weight: Double, reps: Int, note: String, setNumber: Int)
    }

    let exerciseName: String
    let isBodyweight: Bool
    let mode: Mode
    let onSave: (_ weight: Double, _ reps: Int, _ note: String) -> Void
    /// Edit mode only — when non-nil, a destructive "Delete set" secondary appears
    /// beneath "Save changes". Log mode passes nil.
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    /// Lifter's chosen weight unit, surfaced here so the Weight field caption
    /// reads "Weight (lb)" for lb users instead of the developer-default
    /// "Weight (kg)". Same `@AppStorage` key the unit picker and the rest of
    /// the app already share — never duplicated.
    @AppStorage("unitSystem") private var unitSystem: String = "kg"
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var noteText = ""
    @State private var seeded = false
    /// Snapshot of the seeded values after `onAppear` runs. `isDirty` compares
    /// current text against these so the warn-before-discard alert only fires
    /// when the lifter actually edited a field — opening the sheet, glancing
    /// at the prefill, and swiping away with no changes stays a clean dismiss.
    @State private var seededWeightText = ""
    @State private var seededRepsText = ""
    @State private var seededNoteText = ""
    /// Drives the "Discard this set?" confirmation alert. Funnels both the
    /// swipe-down attempt (intercepted via `interactiveDismissDisabled`) and
    /// the explicit Cancel toolbar tap through the same prompt so the lifter
    /// can never lose typed reps/weight/note silently.
    @State private var showsDiscardConfirmation = false

    /// True once the lifter has edited any field away from its seeded value.
    /// Drives both `interactiveDismissDisabled` (blocks swipe-down) and the
    /// Cancel button's confirmation gate. Pure derived state — no side effects.
    private var isDirty: Bool {
        weightText != seededWeightText
        || repsText != seededRepsText
        || noteText != seededNoteText
    }

    private var parsedWeight: Double {
        Double(weightText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func seedWeightText(_ value: Double) -> String {
        let separator = Locale.current.decimalSeparator ?? "."
        return value.weightString.replacingOccurrences(of: ".", with: separator)
    }

    private var parsedReps: Int {
        Int(repsText) ?? 0
    }

    private var effectiveIsBodyweight: Bool {
        guard parsedWeight == 0 else { return false }
        return isBodyweight ? weightText.isEmpty : !weightText.isEmpty
    }

    private var canSave: Bool {
        parsedReps > 0
    }

    private var isEditMode: Bool {
        if case .edit = mode { return true }
        return false
    }

    private var primaryLabel: String {
        isEditMode ? AppCopy.Workout.saveChanges : AppCopy.Workout.completeSet
    }

    private var navigationTitle: String {
        if case .edit(_, _, _, let setNumber) = mode {
            return AppCopy.Workout.editSet(setNumber)
        }
        return exerciseName
    }

    /// Cancel-button handler routed through `AppSheetScreen.onDismissAction`.
    /// Mirrors the swipe-down guard (`interactiveDismissDisabled(isDirty)`)
    /// so a typed weight/reps/note is never silently lost — both gestures
    /// funnel into the same `showsDiscardConfirmation` alert.
    private func handleDismiss() {
        if isDirty {
            showsDiscardConfirmation = true
        } else {
            dismiss()
        }
    }

    var body: some View {
        AppSheetScreen(
            title: navigationTitle,
            primaryButton: PrimaryButtonConfig(
                label: primaryLabel,
                isEnabled: canSave,
                action: {
                    onSave(parsedWeight, parsedReps, noteText)
                    dismiss()
                }
            ),
            dismissLabel: AppCopy.Nav.cancel,
            dismissActionPlacement: .cancellation,
            // Cancel button routes through the confirmation alert when the
            // lifter has typed something — matches the swipe-down guard
            // (`interactiveDismissDisabled` below) so there is exactly one
            // warn-before-discard surface, not a split between gestures.
            onDismissAction: handleDismiss
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(spacing: AppSpacing.sm) {
                    manualInputField(
                        title: AppCopy.Workout.weightLabel(isBodyweight: isBodyweight, unitSystem: unitSystem),
                        text: $weightText,
                        keyboardType: .decimalPad,
                        suffix: effectiveIsBodyweight ? AppCopy.Workout.bodyweightAbbrev : nil
                    )

                    manualInputField(
                        title: AppCopy.Workout.repsLabel,
                        text: $repsText,
                        keyboardType: .numberPad
                    )
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text(AppCopy.Workout.adjustSetNoteLabel)
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)

                    TextField(
                        AppCopy.Workout.adjustSetNotePlaceholder,
                        text: $noteText,
                        axis: .vertical
                    )
                    .font(AppFont.body.font)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3...5)
                    .appInputFieldStyleMultiline(
                        minHeight: 96,
                        horizontalPadding: AppSpacing.md,
                        verticalPadding: AppSpacing.smd,
                        elevated: true
                    )
                }
                .padding(.top, AppSpacing.md)

                // Destructive "Delete set" stays inline at the end of the
                // scroll content (edit mode only) so it never visually competes
                // with the sticky primary CTA below. Quiet by design — rarely
                // tapped, doubly-confirming via the system delete sheet.
                if isEditMode, let onDelete {
                    AppSecondaryButton(
                        AppCopy.Workout.deleteSet,
                        tone: .destructive,
                        action: {
                            onDelete()
                            dismiss()
                        }
                    )
                    .padding(.top, AppSpacing.md)
                }
            }
        }
        // Block the swipe-down gesture while there are unsaved edits. iOS
        // forwards the gesture into a no-op; the explicit Cancel button stays
        // available and feeds the same discard-confirmation alert below.
        .interactiveDismissDisabled(isDirty)
        .alert(
            AppCopy.Workout.discardSetEntryTitle,
            isPresented: $showsDiscardConfirmation
        ) {
            Button(AppCopy.Workout.discardSetEntryAction, role: .destructive) {
                dismiss()
            }
            Button(AppCopy.Workout.keepEditing, role: .cancel) {}
        } message: {
            Text(AppCopy.Workout.discardSetEntryMessage)
        }
        .onAppear {
            guard !seeded else { return }
            seeded = true
            switch mode {
            case .log(let prefill):
                guard let prefill else { return }
                if prefill.weight > 0 {
                    weightText = seedWeightText(prefill.weight)
                }
                repsText = "\(prefill.reps)"
            case .edit(let weight, let reps, let note, _):
                if weight > 0 {
                    weightText = seedWeightText(weight)
                }
                repsText = "\(reps)"
                noteText = note
            }
            // Snapshot the post-seed values so `isDirty` only flips true on a
            // real user edit. Setting these *after* the switch covers both
            // `.log` (which only writes weight/reps) and `.edit` (which writes
            // all three) without duplicating the assignment per case.
            seededWeightText = weightText
            seededRepsText = repsText
            seededNoteText = noteText
        }
    }

    @ViewBuilder
    private func manualInputField(
        title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        suffix: String? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(title)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)

            HStack(spacing: AppSpacing.xs) {
                TextField("0", text: text)
                    .keyboardType(keyboardType)
                    .font(AppFont.numericInput.font)
                    .tracking(AppFont.numericInput.tracking)
                    .multilineTextAlignment(.center)

                if let suffix {
                    Text(suffix)
                        .font(AppFont.productAction.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .appInputFieldStyle(height: 64, horizontalPadding: AppSpacing.sm, elevated: true)
        }
    }
}

private struct SetCountOption: Hashable, Identifiable {
    let value: Int
    var id: Int { value }
}

private struct SetCountPickerSheet: View {
    let exerciseName: String
    let onSelect: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selection: SetCountOption = SetCountOption(value: 3)

    private static let options: [SetCountOption] = (1...6).map { SetCountOption(value: $0) }

    var body: some View {
        AppSheetScreen(
            title: AppCopy.Workout.setCountQuestion,
            primaryButton: PrimaryButtonConfig(label: AppCopy.Nav.done, action: commitSelection),
            onDismissAction: { dismiss() },
            usesOuterScroll: false
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(AppCopy.Workout.setCountPrompt(exerciseName))
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                AppSegmentedControl(
                    selection: $selection,
                    items: Self.options,
                    size: .tall,
                    title: { "\($0.value)" }
                )
            }
        }
    }

    private func commitSelection() {
        onSelect(selection.value)
        dismiss()
    }
}

struct SetPrefill {
    enum Source {
        case currentSession
        case priorSession
        case planned
    }

    let weight: Double
    let reps: Int
    let source: Source
}

@MainActor
@Observable
final class ActiveWorkoutViewModel {
    func prefillSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession],
        plannedReps: Int? = nil
    ) -> SetPrefill? {
        let currentEntries = currentSession.setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }

        if let currentLast = currentEntries.last {
            return SetPrefill(
                weight: currentLast.weight,
                reps: currentLast.reps,
                source: .currentSession
            )
        }

        if let reference = latestSessionSet(
            for: exerciseID,
            currentSession: currentSession,
            sessions: sessions
        ) {
            return SetPrefill(
                weight: reference.weight,
                reps: reference.reps,
                source: .priorSession
            )
        }

        if let plannedReps, plannedReps > 0 {
            return SetPrefill(weight: 0, reps: plannedReps, source: .planned)
        }

        return nil
    }

    private func latestSessionSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession]
    ) -> SetEntry? {
        guard let session = latestSession(
            for: exerciseID,
            currentSession: currentSession,
            sessions: sessions
        ) else {
            return nil
        }

        return session.setEntries
            .filter { $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup }
            .sorted { $0.setIndex < $1.setIndex }
            .last
    }

    private func latestSession(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession]
    ) -> WorkoutSession? {
        sessions.first { session in
            session.id != currentSession.id &&
            session.isCompleted &&
            session.setEntries.contains(where: { $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup })
        }
    }
}

@MainActor
@Observable
final class RestTimerManager {
    var secondsRemaining = 0
    var isRunning = false
    var completionCount = 0
    private(set) var totalDuration = 0

    private var task: Task<Void, Never>?
    private var activity: Activity<RestTimerAttributes>?
    private(set) var endDate: Date?
    private var startDate: Date?
    private var upNext: String?

    /// Persisted across app launches so a force-quit during rest doesn't
    /// desync the in-app timer from the Live Activity (compass: timer follows
    /// the user, including outside the app).
    private static let endDateKey = "unit.restTimer.endDate"
    private static let totalDurationKey = "unit.restTimer.totalDuration"

    init() {
        restoreFromPersistedState()
    }

    var label: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    func start(totalSeconds: Int, upNext: String? = nil) {
        stop()
        totalDuration = totalSeconds
        secondsRemaining = totalSeconds
        let now = Date()
        startDate = now
        endDate = now.addingTimeInterval(TimeInterval(totalSeconds))
        self.upNext = upNext
        isRunning = true
        persistState()
        startActivity()
        startCountdownTask()
    }

    func pause() {
        guard isRunning, secondsRemaining > 0 else { return }
        task?.cancel()
        task = nil
        isRunning = false
        endDate = nil
        startDate = nil
        clearPersistedState()
        endActivity()
    }

    func resume() {
        guard !isRunning, secondsRemaining > 0 else { return }
        isRunning = true
        let now = Date()
        startDate = now
        endDate = now.addingTimeInterval(TimeInterval(secondsRemaining))
        persistState()
        startActivity()
        startCountdownTask()
    }

    func resumeFromBackground() {
        guard let end = endDate else { return }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        if remaining <= 0 {
            completeIfFinished()
        } else {
            secondsRemaining = remaining
            isRunning = true
            startCountdownTask()
        }
    }

    func adjust(by delta: Int, minimumSeconds: Int = 30) {
        let baseRemaining = secondsRemaining > 0 ? secondsRemaining : totalDuration
        let updatedRemaining = max(minimumSeconds, baseRemaining + delta)
        let updatedTotal = max(minimumSeconds, totalDuration + delta)

        secondsRemaining = updatedRemaining
        totalDuration = updatedTotal

        if isRunning {
            let now = Date()
            startDate = now
            endDate = now.addingTimeInterval(TimeInterval(updatedRemaining))
            persistState()
            updateActivity()
        }
    }

    func stop() {
        task?.cancel()
        task = nil
        isRunning = false
        secondsRemaining = 0
        totalDuration = 0
        endDate = nil
        startDate = nil
        upNext = nil
        clearPersistedState()
        endActivity()
    }

    private func completeIfFinished() {
        secondsRemaining = 0
        isRunning = false
        totalDuration = 0
        endDate = nil
        startDate = nil
        upNext = nil
        completionCount += 1
        clearPersistedState()
        endActivity()
    }

    /// Reconstruct timer state on init from UserDefaults; if defaults are
    /// empty (e.g. after a reinstall mid-rest) fall back to the live Activity.
    private func restoreFromPersistedState() {
        let defaults = UserDefaults.standard
        var recoveredEnd: Date?
        var recoveredTotal: Int = 0
        var recoveredStart: Date?
        var recoveredUpNext: String?

        if let stored = defaults.object(forKey: Self.endDateKey) as? Date {
            recoveredEnd = stored
            recoveredTotal = defaults.integer(forKey: Self.totalDurationKey)
        }

        if let liveActivity = Activity<RestTimerAttributes>.activities.first {
            let liveState = liveActivity.content.state
            if recoveredEnd == nil {
                recoveredEnd = liveState.endDate
                recoveredTotal = max(30, Int(liveState.endDate.timeIntervalSinceNow))
            }
            recoveredStart = liveState.startDate
            recoveredUpNext = liveState.upNext
            activity = liveActivity
        }

        guard let end = recoveredEnd else { return }
        let remaining = Int(ceil(end.timeIntervalSinceNow))
        if remaining <= 0 {
            // Timer expired while the app was killed — surface the Ready state.
            clearPersistedState()
            completionCount += 1
            return
        }

        endDate = end
        startDate = recoveredStart ?? end.addingTimeInterval(-TimeInterval(max(remaining, recoveredTotal)))
        upNext = recoveredUpNext
        secondsRemaining = remaining
        totalDuration = max(remaining, recoveredTotal)
        isRunning = true
        startCountdownTask()
    }

    private func persistState() {
        let defaults = UserDefaults.standard
        if let endDate {
            defaults.set(endDate, forKey: Self.endDateKey)
            defaults.set(totalDuration, forKey: Self.totalDurationKey)
        } else {
            clearPersistedState()
        }
    }

    private func clearPersistedState() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.endDateKey)
        defaults.removeObject(forKey: Self.totalDurationKey)
    }

    private func startCountdownTask() {
        task?.cancel()
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard let manager = self, let end = manager.endDate else { return }

                let remaining = Int(ceil(end.timeIntervalSinceNow))
                if remaining <= 0 {
                    manager.completeIfFinished()
                    return
                }

                manager.secondsRemaining = remaining
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func startActivity() {
        guard let endDate, let startDate else { return }
        let attributes = RestTimerAttributes()
        let state = RestTimerAttributes.ContentState(
            startDate: startDate,
            endDate: endDate,
            upNext: upNext
        )
        let content = ActivityContent(state: state, staleDate: endDate.addingTimeInterval(60))
        activity = try? Activity<RestTimerAttributes>.request(
            attributes: attributes,
            content: content,
            pushType: nil
        )
    }

    private func updateActivity() {
        guard let endDate, let startDate else { return }
        let updatedState = RestTimerAttributes.ContentState(
            startDate: startDate,
            endDate: endDate,
            upNext: upNext
        )
        let updatedContent = ActivityContent(state: updatedState, staleDate: endDate.addingTimeInterval(60))
        let currentActivity = activity
        Task { @MainActor [currentActivity] in
            await currentActivity?.update(updatedContent)
        }
    }

    private func endActivity() {
        let currentActivity = activity
        activity = nil

        Task { @MainActor [currentActivity] in
            await currentActivity?.end(nil, dismissalPolicy: .immediate)
        }
    }
}

// MARK: - Warmup guide sheet

private struct WarmupGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppSheetScreen(
            title: AppCopy.Workout.warmupGuideTitle,
            dismissLabel: AppCopy.Nav.done,
            dismissActionPlacement: .confirmation,
            onDismissAction: { dismiss() },
            usesOuterScroll: false
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                Text(AppCopy.Workout.warmupGuideRepRule)
                Text(AppCopy.Workout.warmupGuideLoadRule)
                Text(AppCopy.Workout.warmupGuideTempoRule)
            }
            .font(AppFont.body.font)
            .foregroundStyle(AppColor.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
