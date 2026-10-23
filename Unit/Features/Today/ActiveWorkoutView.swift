//
//  ActiveWorkoutView.swift
//  Unit
//
//  Active workout: command-panel logging for the current exercise and rest state.
//

import ActivityKit
import UserNotifications
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct ActiveWorkoutView: View {
    @Bindable var session: WorkoutSession
    var onFinished: ((WorkoutSession) -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @AppStorage("restDurationSeconds") private var restDurationSeconds = 120
    @AppStorage("unitSystem") private var unitSystem = "kg"
    @AppStorage("unit.preparedSetTargets") private var preparedSetTargetsData = Data()
    @SceneStorage("unit.loggingInputDrafts") private var inputDraftsData = Data()
    @State private var viewModel = ActiveWorkoutViewModel()
    @State private var restTimer = RestTimerManager()
    @State private var logging = WorkoutLoggingState()
    @State private var selectedExerciseID: UUID?
    @State private var expandedCompletedID: UUID?
    @State private var customSetCounts: [UUID: Int] = [:]
    @State private var showsCancelConfirmation = false
    @State private var showsSkipExerciseConfirmation = false
    @State private var showsFinishConfirmation = false
    @State private var showsRoutineUpdate = false
    @State private var pendingRoutineUpdatePrompt = false
    @State private var showsRenamePrompt = false
    @State private var showsDiscardRenamePrompt = false
    @State private var renameDraft = ""
    @State private var pendingRoutineUpdates: [WorkoutLoggingState.RoutineUpdate] = []
    @AppStorage("unit.activeWorkoutExerciseOrder") private var exerciseOrderData = Data()
    @State private var draggedExerciseID: UUID?
    @State private var showsAddExercise = false
    @State private var pendingExerciseForSetup: Exercise?
    @State private var setLoggedPhase = 0
    @State private var workoutFinishedPhase = 0
    @State private var guardActive = false
    @State private var saveFailed = false
    @State private var didTrackWorkoutStart = false
    @State private var trackedPreviewExerciseIDs: Set<UUID> = []
    /// Rest-alert problems (notifications off) are reported once per workout.
    /// Every set restarts the timer, so repeating it would cover the logging
    /// row after each set.
    @State private var didReportRestAlertIssue = false
    @State private var noKeyboardSetCount = 0
    @State private var editedRows: Set<String> = []
    @State private var removedSet: SetEntrySnapshot?
    @State private var setEditHintToast: AppToastEvent?
    @State private var editor: InlineEditor?
    @State private var weightText = ""
    @State private var repsText = ""
    @State private var scrollPosition = ScrollPosition(idType: String.self)
    @State private var currentRowBottom: CGFloat = 0
    @State private var visibleListHeight: CGFloat = 0
    @State private var listWidth: CGFloat = 0
    @FocusState private var focusedField: LoggingField?
    @AccessibilityFocusState private var currentRowFocused: Bool
    @ScaledMetric(relativeTo: .title) private var chipHeight = AppWorkoutMetrics.chipHeight
    @ScaledMetric(relativeTo: .title) private var compactChipHeight = AppWorkoutMetrics.compactChipHeight

    private enum LoggingField: Hashable {
        case weight(String)
        case reps(String)
        var rowID: String {
            switch self { case .weight(let id), .reps(let id): return id }
        }
        var isReps: Bool {
            if case .reps = self { return true }; return false
        }
    }

    /// Raw input is kept separate from validated targets and completed history.
    private struct InputDraft: Codable {
        let weight: String
        let reps: String
    }

    private struct InlineEditor {
        let exerciseID: UUID
        let number: Int
        let entryID: UUID?
        let isCurrent: Bool
        let isSetup: Bool
        let original: SetPrefill?
        let initialWeightText: String
        let initialRepsText: String
        var id: String { Self.id(exerciseID: exerciseID, number: number) }
        static func id(exerciseID: UUID, number: Int) -> String { "\(exerciseID)#\(number)" }
    }

    private var template: DayTemplate? { templates.first { $0.id == session.templateId } }
    private var isFreestyleSession: Bool { template?.name == FreestyleSessionSupport.templateName }
    private var workoutNavigationTitle: String {
        (template?.name ?? "Workout").truncatedForNavigationTitle(maxGlyphCount: 34)
    }
    private var orderedExerciseIDs: [UUID] {
        WorkoutLoggingState.orderedExerciseIDs(templateIDs: template?.orderedExerciseIds ?? [],
            sessionID: session.id, saved: exerciseOrderData)
    }
    private var orderedExercises: [Exercise] {
        orderedExerciseIDs.compactMap { id in exercises.first { $0.id == id } }
    }
    private var sectionModels: [WorkoutExerciseSectionModel] {
        orderedExercises.map { exercise in
            WorkoutExerciseSectionModel(
                exercise: exercise, lastActualText: nil,
                entries: currentEntries(for: exercise.id),
                prefill: viewModel.prefillSet(
                    for: exercise.id, currentSession: session, sessions: sessions,
                    acceptedProgressionTarget: template?.progressionState(for: exercise.id)?.acceptedTarget,
                    plannedReps: template?.plannedReps(for: exercise.id),
                    plannedWeightKg: template?.plannedWeight(for: exercise.id)
                ), plannedSetCount: plannedSetCount(for: exercise.id)
            )
        }
    }
    private var exerciseStates: [WorkoutLoggingState.ExerciseState] {
        sectionModels.map { section in
            .init(id: section.id, name: section.exercise.displayName,
                  plannedCount: section.plannedSetCount,
                  entries: section.entries.map {
                    .init(id: $0.id, weight: $0.weight, reps: $0.reps, setIndex: $0.setIndex,
                          isCompleted: $0.isCompleted, isWarmup: $0.isWarmup)
                  })
        }
    }
    private var currentExerciseID: UUID? {
        WorkoutLoggingState.currentExerciseID(in: exerciseStates, selectedID: selectedExerciseID)
    }
    private var currentSection: WorkoutExerciseSectionModel? {
        sectionModels.first { $0.id == currentExerciseID }
    }
    private var isWorkoutComplete: Bool {
        !exerciseStates.isEmpty && exerciseStates.allSatisfy(\.isComplete)
    }
    private var hasLoggedSets: Bool { session.setEntries.contains { $0.isValidCompletedWorkingSet } }
    private var upNextText: String? {
        WorkoutLoggingState.upNextText(exercises: exerciseStates, currentExerciseID: currentExerciseID)
    }
    private var preparedTargets: WorkoutLoggingState.Targets {
        WorkoutLoggingState.decodeTargets(preparedSetTargetsData)
    }
    private var defaultRestText: String {
        String(format: "%d:%02d", restDurationSeconds / 60, restDurationSeconds % 60)
    }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true, usesOuterScroll: false) {
            ScrollView {
                WorkoutDayList {
                    ForEach(sectionModels) { section in
                        exerciseContent(section)
                            .appReorderable(id: section.id, draggedID: $draggedExerciseID, reduceMotion: reduceMotion) {
                                AppReorderDragPreview {
                                    Text(section.exercise.displayName).font(AppFont.sectionHeader.font)
                                }
                            }
                            .onDrop(of: [.text], delegate: WorkoutExerciseDropDelegate(
                                targetID: section.id, draggedID: $draggedExerciseID,
                                onMove: moveExercise))
                            .id(section.id.uuidString)
                    }
                    if isFreestyleSession && !sectionModels.isEmpty { addExerciseButton }
                    if sectionModels.isEmpty { addExercisePrompt }
                }
                // Child-owned scrolling keeps its breathing room inside the
                // scroll content, so the viewport ends at the rest footer.
                .padding(.vertical, AppSpacing.md)
                .scrollTargetLayout()
                .appAnimation(AppMotion.collectionChange, value: orderedExerciseIDs, reduceMotion: reduceMotion)
                .appAnimation(AppMotion.collectionChange, value: session.setEntries.map(\.id), reduceMotion: reduceMotion)
                .appAnimation(AppMotion.collectionChange, value: currentExerciseID, reduceMotion: reduceMotion)
                .appAnimation(AppMotion.collectionChange, value: expandedCompletedID, reduceMotion: reduceMotion)
            }
            .scrollPosition($scrollPosition)
            .scrollDismissesKeyboard(.interactively)
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size in
                visibleListHeight = size.height
                listWidth = size.width
            }
            .coordinateSpace(name: "workout-list")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if let focusedField {
                VStack(spacing: 0) {
                    RestBar.progressLine(progress: restTimer.totalDuration > 0
                        ? Double(restTimer.secondsRemaining) / Double(restTimer.totalDuration) : 0,
                        endDate: restTimer.endDate, totalDuration: TimeInterval(restTimer.totalDuration),
                        isRunning: restTimer.isRunning,
                        spatial: AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver))
                    VStack(spacing: AppSpacing.sm) {
                        RestBar.status(timeText: restTimer.secondsRemaining > 0 ? restTimer.label : defaultRestText,
                            state: restTimer.isFinished ? .finished : (restTimer.isRunning ? .running : .idle),
                            spatial: AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver))
                        if let editor, editor.isCurrent, let section = currentSection,
                           section.id == editor.exerciseID {
                            AppPrimaryButton(
                                needsStartingTarget(section, row: editor.number) ? AppCopy.Workout.saveTarget : AppCopy.Workout.completeSetNumbered(editor.number),
                                isEnabled: canCommitEditor && !guardActive
                            ) {
                                if needsStartingTarget(section, row: editor.number) {
                                    saveStartingTarget(section: section, number: editor.number)
                                } else {
                                    completeSuggestedSet(section: section, number: editor.number)
                                }
                            }
                            .accessibilityIdentifier("keyboard-current-action")
                        }
                        HStack(spacing: AppSpacing.sm) {
                            keyboardButton(AppCopy.Workout.stepDown(unitSystem: unitSystem, reps: focusedField.isReps)) {
                                stepInput(direction: -1)
                            }
                            keyboardButton(AppCopy.Workout.stepUp(unitSystem: unitSystem, reps: focusedField.isReps)) {
                                stepInput(direction: 1)
                            }
                            keyboardButton(focusedField.isReps ? AppCopy.Workout.weightField : AppCopy.Workout.repsLabel) {
                                self.focusedField = focusedField.isReps ? .weight(focusedField.rowID) : .reps(focusedField.rowID)
                            }
                            .accessibilityLabel(focusedField.isReps ? AppCopy.Workout.editWeight : AppCopy.Workout.editReps)
                            keyboardButton(AppCopy.Nav.done, action: finishEditing)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(AppSpacing.md)
                }
                .background(AppColor.background.ignoresSafeArea(edges: .bottom))
                .overlay(alignment: .top) { AppDivider() }
            } else if isWorkoutComplete {
                // Every planned set is logged: rest is over, and the summary
                // (where next targets are accepted) is one tap away. The small
                // toolbar Finish alone was easy to miss.
                AppPrimaryButton(AppCopy.Workout.finishWorkout, isEnabled: !guardActive, action: requestFinish)
                    .accessibilityIdentifier("workout-complete-finish")
                    .padding(AppSpacing.md)
                    .background(AppColor.background.ignoresSafeArea(edges: .bottom))
                    .overlay(alignment: .top) { AppDivider() }
                    .transition(AppBlurTransition().animation(.appReveal))
            } else {
                RestBar(
                    timeText: restTimer.secondsRemaining > 0 ? restTimer.label : defaultRestText,
                    state: restTimer.isFinished ? .finished : (restTimer.isRunning ? .running : .idle),
                    progress: restTimer.totalDuration > 0
                        ? Double(restTimer.secondsRemaining) / Double(restTimer.totalDuration) : 0,
                    endDate: restTimer.endDate,
                    totalDuration: TimeInterval(restTimer.totalDuration),
                    canDecrease: restTimer.secondsRemaining > 15,
                    onDecrease: { adjustRestTimer(by: -20) },
                    onIncrease: { adjustRestTimer(by: 20) },
                    onSkip: skipRest
                )
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: AppSpacing.xs) {
                    Text(workoutNavigationTitle).font(AppFont.sectionHeader.font).lineLimit(1)
                    Text(session.date, style: .timer)
                        .font(AppFont.stepIndicator.font).foregroundStyle(AppColor.textSecondary)
                }
            }
            ToolbarItem(placement: .topBarLeading) {
                Group {
                    Button { showsCancelConfirmation = true } label: {
                        Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName).labelStyle(.iconOnly)
                    }
                }
                .tint(AppColor.textPrimary)
            }
            ToolbarItemGroup(placement: .topBarTrailing) {
                if hasLoggedSets {
                    Button(AppCopy.Workout.finishShort, action: requestFinish)
                        .tint(AppColor.textPrimary)
                }
            }
        }
        .toolbar(.hidden, for: .tabBar)
        .appNavigationBarChrome()
        // During logging, scrolling cards must not show through the title/timer.
        // This screen intentionally keeps the native navigation surface visible.
        .toolbarBackground(AppColor.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .tint(AppColor.textPrimary)
        .appHaptic(.success, trigger: setLoggedPhase)
        .appHaptic(.success, trigger: workoutFinishedPhase)
        .appHaptic(.success, trigger: restTimer.completionCount)
        .appToast(event: $setEditHintToast)
        .alert("Couldn't save workout", isPresented: $saveFailed) {
            Button(AppCopy.Nav.close, role: .cancel) { }
        }
        .alert(AppCopy.Workout.cancelWorkoutTitle, isPresented: $showsCancelConfirmation) {
            Button(AppCopy.Workout.cancelWorkoutAction, role: .destructive, action: cancelWorkout)
            Button(AppCopy.Workout.keepGoing, role: .cancel) { }
        } message: { Text(AppCopy.Workout.cancelWorkoutMessage) }
        .alert(AppCopy.Workout.skipExerciseTitle, isPresented: $showsSkipExerciseConfirmation) {
            Button(AppCopy.Workout.skipExerciseAction, role: .destructive, action: skipExercise)
            Button(AppCopy.Workout.keepLogging, role: .cancel) { }
        }
        .alert(AppCopy.Workout.finishWorkoutTitle, isPresented: $showsFinishConfirmation) {
            Button(AppCopy.Workout.finishWorkout, action: confirmFinish)
            Button(AppCopy.Nav.cancel, role: .cancel) { }
        } message: { Text(AppCopy.Workout.finishWorkoutMessage) }
        .alert(AppCopy.Workout.nameWorkoutTitle, isPresented: $showsRenamePrompt) {
            TextField(AppCopy.Workout.nameWorkoutFieldPlaceholder, text: $renameDraft)
            Button(AppCopy.Session.useName) {
                let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if let template, !trimmed.isEmpty {
                    template.name = trimmed
                }
                finishWorkout()
            }
            Button(AppCopy.Session.skipNaming, role: .cancel) {
                // Skip with a typed draft is the lossy path — funnel through a
                // second confirmation so the lifter can't lose a name with one
                // wrong tap (HIG: destructive flows ask once). Tapping Skip on
                // an empty field still dismisses cleanly because there is
                // nothing to discard.
                if !renameDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    showsDiscardRenamePrompt = true
                } else {
                    finishWorkout()
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
                finishWorkout()
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
        .confirmationDialog(AppCopy.Workout.updateRoutineTitle, isPresented: $showsRoutineUpdate, titleVisibility: .visible) {
            Button(AppCopy.Workout.updateRoutineAction) { applyRoutineUpdatesAndFinish() }
            Button(AppCopy.Workout.keepRoutineAction) { finishWorkout() }
            Button(AppCopy.Nav.cancel, role: .cancel) { }
        } message: {
            Text(AppCopy.Workout.updateRoutineMessage(pendingRoutineUpdates.map(\.name)))
        }
        .sheet(isPresented: $showsAddExercise) {
            AppExercisePickerSheet(existingIds: Set(template?.orderedExerciseIds ?? []), onSelect: addExerciseToWorkout)
        }
        .sheet(item: $pendingExerciseForSetup) { exercise in
            SetCountPickerSheet(exerciseName: exercise.displayName) { customSetCounts[exercise.id] = $0 }
                .presentationDetents([.medium])
                .appBottomSheetChrome()
        }
        .onAppear(perform: restoreWorkout)
        .onChange(of: upNextText) { _, next in restTimer.updateUpNext(next) }
        .onChange(of: restTimer.notificationIssue) { _, message in
            guard let message, !didReportRestAlertIssue else { return }
            didReportRestAlertIssue = true
            setEditHintToast = .init(message, kind: .information)
        }
        .onChange(of: restTimer.completionCount) { _, _ in
            AccessibilityNotification.Announcement(AppCopy.Workout.restFinishedInline).post()
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { restTimer.resumeFromBackground() }
        }
        .onChange(of: focusedField) { old, new in
            handleFocusChange(from: old, to: new)
        }
        .task(id: pendingRoutineUpdatePrompt) {
            guard pendingRoutineUpdatePrompt else { return }
            // Present after SwiftUI has committed the preceding alert dismissal.
            await Task.yield()
            guard !Task.isCancelled, !showsFinishConfirmation, !session.isCompleted else { return }
            showsRoutineUpdate = true
            pendingRoutineUpdatePrompt = false
        }
        .task(id: logging.lastLogAt) { await releaseLoggingGuard() }
        .task(id: logging.undo?.entryID) {
            guard logging.undo != nil else { return }
            do { try await Task.sleep(for: .seconds(WorkoutLoggingState.undoDuration)) } catch { return }
            logging.invalidateUndo()
        }
    }

    @ViewBuilder
    private func exerciseContent(_ section: WorkoutExerciseSectionModel) -> some View {
        let isCurrent = section.id == currentExerciseID
        if isCurrent || expandedCompletedID == section.id {
            ExerciseLoggingCard(
                name: section.exercise.displayName,
                isBodyweight: Binding(get: { section.exercise.isBodyweight }, set: { setBodyweight($0, exercise: section.exercise) }),
                onSkip: { jump(to: section.id); showsSkipExerciseConfirmation = true },
                onAddSet: { addSet(to: section) },
                onSelect: isCurrent ? nil : { jump(to: section.id) }
            ) {
                ForEach(WorkoutLoggingState.rows(for: state(for: section), isCurrent: isCurrent)) { row in
                    loggingRow(row, section: section)
                        .id(rowID(section.id, row.number))
                }
            }
            .transition(AppBlurTransition().animation(.appReveal))
        } else {
            exerciseSummary(section)
                .accessibilityIdentifier(section.hasReachedPlannedSetGoal
                    ? "completed-exercise-\(section.id)" : "upcoming-exercise-\(section.id)")
                .transition(AppBlurTransition().animation(.appReveal))
        }
    }

    private func exerciseSummary(_ section: WorkoutExerciseSectionModel) -> some View {
        ExerciseSummaryRow(
            name: section.exercise.displayName, summary: summary(for: section),
            isCompleted: section.hasReachedPlannedSetGoal,
            showsUndo: showsInlineUndo(for: section.id),
            onUndo: undoLastLog, onSelect: { jump(to: section.id) },
            detail: progressionSuggestion(for: section)?.text
        )
        .allowsHitTesting(!guardActive)
    }

    @ViewBuilder
    private func loggingRow(_ row: WorkoutLoggingState.Row, section: WorkoutExerciseSectionModel) -> some View {
        let id = rowID(section.id, row.number)
        if case .logged(let entryID) = row.kind,
           let entry = section.entries.first(where: { $0.id == entryID }), editor?.id != id {
            LoggedSetRow(
                number: row.number, value: valueText(weight: entry.weight, reps: entry.reps, exercise: section.exercise),
                showsUndo: logging.availableUndo(at: Date())?.entryID == entry.id,
                onUndo: undoLastLog,
                onEdit: { if beginEditing(section: section, row: row) { focusedField = .weight(id) } },
                onMarkNotDone: { _ = deleteSet(entry, exercise: section.exercise) }
            )
            .allowsHitTesting(!guardActive)
        } else if row.kind == .current || editor?.id == id {
            let setup = needsStartingTarget(section, row: row.number)
            CurrentSetRow(
                number: row.number, supportingText: row.kind == .current ? supportingText(for: section, row: row.number) : nil,
                isSetup: setup, isCTAEnabled: canPerformCurrentAction(section, number: row.number),
                showsCTA: row.kind == .current,
                showsAction: !(focusedField != nil && editor?.id == id && editor?.isCurrent == true),
                showsCompletion: { if case .logged = row.kind { return true }; return false }(),
                onComplete: { completeSuggestedSet(section: section, number: row.number) },
                onSaveTarget: { saveStartingTarget(section: section, number: row.number) }
            ) {
                valueFields(section: section, row: row)
            }
            .allowsHitTesting(!guardActive)
            .accessibilityFocused($currentRowFocused)
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.frame(in: .named("workout-list")).maxY
            } action: { bottom in
                if row.kind == .current { currentRowBottom = bottom }
            }
        } else {
            PlannedSetRow(number: row.number, value: plannedValueText(section, row: row.number)) {
                if beginEditing(section: section, row: row) { focusedField = .weight(id) }
            }
            .allowsHitTesting(!guardActive)
        }
    }

    @ViewBuilder
    private func valueFields(section: WorkoutExerciseSectionModel, row: WorkoutLoggingState.Row) -> some View {
        let load = editor?.id == rowID(section.id, row.number)
            ? parsedDisplayWeight : resolvedTarget(section, row: row.number).map { displayWeight($0.weight) }
        let needsWideLoad = (section.exercise.isBodyweight && (load ?? 0) > 0)
            || (load?.weightString.count ?? 0) > 5
        if dynamicTypeSize.isAccessibilitySize || needsWideLoad {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                weightField(section: section, row: row)
                repsField(section: section, row: row)
            }
        } else {
            HStack(spacing: AppSpacing.xs) {
                weightField(section: section, row: row)
                Text("×").font(AppFont.title.font).accessibilityHidden(true)
                repsField(section: section, row: row)
            }
        }
    }

    private func weightField(section: WorkoutExerciseSectionModel, row: WorkoutLoggingState.Row) -> some View {
        let id = rowID(section.id, row.number)
        let target = resolvedTarget(section, row: row.number)
        return HStack(spacing: AppSpacing.xs) {
            Spacer(minLength: 0)
            if section.exercise.isBodyweight && (editor?.id == id ? parsedDisplayWeight ?? 0 : displayWeight(target?.weight ?? 0)) > 0 {
                Text("BW +").accessibilityHidden(true)
            }
            TextField(section.exercise.isBodyweight ? AppCopy.Workout.bodyweightAbbrev : "", text: Binding(
                get: {
                    if section.exercise.isBodyweight && focusedField?.rowID != id
                        && (editor?.id == id ? parsedDisplayWeight ?? 0 : target?.weight ?? 0) == 0 { return "" }
                    return editor?.id == id ? weightText : inputWeight(target, section: section)
                },
                set: { text in guard ensureEditor(section: section, row: row) else { return }; weightText = text; editedRows.insert(id); retainInputDraft() }
            ))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: true, vertical: false)
            .keyboardType(.decimalPad)
            .focused($focusedField, equals: .weight(id))
            .accessibilityLabel(AppCopy.Workout.weightLabel(isBodyweight: section.exercise.isBodyweight, unitSystem: unitSystem))
            .accessibilityHint("Double-tap to edit.")
            .accessibilityIdentifier(editor?.id == id || (row.kind == .current && editor == nil) ? "logging-weight" : "weight-field-\(section.id)-\(row.number)")
            if !section.exercise.isBodyweight || (editor?.id == id ? parsedDisplayWeight ?? 0 : displayWeight(target?.weight ?? 0)) > 0 {
                Text(unitSystem).accessibilityHidden(true)
            }
            Spacer(minLength: 0)
        }
        .font((editor?.id == id && editor?.isCurrent == false ? AppFont.performance : (isCompact ? AppFont.setValueCompact : AppFont.setValue)).font)
        .tracking(AppFont.setValue.tracking)
        .monospacedDigit()
        .foregroundStyle(AppColor.textPrimary)
        .frame(minWidth: AppWorkoutMetrics.weightChipWidth, maxWidth: .infinity)
        .appInputFieldStyle(height: editor?.id == id && editor?.isCurrent == false ? AppWorkoutMetrics.rowHeight : (isCompact ? compactChipHeight : chipHeight), horizontalPadding: AppSpacing.smd)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            if beginEditing(section: section, row: row) { focusedField = .weight(id) }
        })
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColor.accent, lineWidth: AppWorkoutMetrics.focusLineWidth)
                .opacity(focusedField == .weight(id) ? 1 : 0)
                .allowsHitTesting(false)
        }
    }

    private func repsField(section: WorkoutExerciseSectionModel, row: WorkoutLoggingState.Row) -> some View {
        let id = rowID(section.id, row.number)
        return TextField(AppCopy.Workout.repsLabel.lowercased(), text: Binding(
            get: { editor?.id == id ? repsText : resolvedTarget(section, row: row.number).map { String($0.reps) } ?? "" },
            set: { text in guard ensureEditor(section: section, row: row) else { return }; repsText = text; editedRows.insert(id); retainInputDraft() }
        ))
        .frame(minWidth: 0, maxWidth: .infinity)
        .keyboardType(.numberPad)
        .focused($focusedField, equals: .reps(id))
        .font((editor?.id == id && editor?.isCurrent == false ? AppFont.performance : (isCompact ? AppFont.setValueCompact : AppFont.setValue)).font)
        .tracking(AppFont.setValue.tracking)
        .monospacedDigit()
        .multilineTextAlignment(.center)
        .foregroundStyle(AppColor.textPrimary)
        .frame(minWidth: 0, maxWidth: .infinity)
        .appInputFieldStyle(height: editor?.id == id && editor?.isCurrent == false ? AppWorkoutMetrics.rowHeight : (isCompact ? compactChipHeight : chipHeight), horizontalPadding: AppSpacing.smd)
        .contentShape(Rectangle())
        .simultaneousGesture(TapGesture().onEnded {
            if beginEditing(section: section, row: row) { focusedField = .reps(id) }
        })
        .overlay {
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColor.accent, lineWidth: AppWorkoutMetrics.focusLineWidth)
                .opacity(focusedField == .reps(id) ? 1 : 0)
                .allowsHitTesting(false)
        }
        .accessibilityLabel(AppCopy.Workout.repsLabel)
        .accessibilityHint("Double-tap to edit.")
        .accessibilityIdentifier(editor?.id == id || (row.kind == .current && editor == nil) ? "logging-reps" : "reps-field-\(section.id)-\(row.number)")
    }

    private var isCompact: Bool { listWidth > 0 && listWidth <= AppWorkoutMetrics.compactWidth }

    private func rowID(_ exerciseID: UUID, _ number: Int) -> String {
        InlineEditor.id(exerciseID: exerciseID, number: number)
    }
    private func state(for section: WorkoutExerciseSectionModel) -> WorkoutLoggingState.ExerciseState {
        WorkoutLoggingState.ExerciseState(id: section.id, name: section.exercise.displayName,
            plannedCount: section.plannedSetCount, entries: section.entries.map {
                .init(id: $0.id, weight: $0.weight, reps: $0.reps, setIndex: $0.setIndex,
                      isCompleted: $0.isCompleted, isWarmup: $0.isWarmup)
            })
    }
    private func currentEntries(for exerciseID: UUID) -> [SetEntry] {
        session.setEntries.filter { $0.exerciseId == exerciseID && $0.isValidCompletedWorkingSet }
            .sorted { $0.setIndex < $1.setIndex }
    }
    private func resolvedTarget(_ section: WorkoutExerciseSectionModel, row: Int) -> SetPrefill? {
        WorkoutLoggingState.resolvedTarget(in: preparedTargets, sessionID: session.id,
            exerciseID: section.id, row: row, fallback: section.prefill)
    }
    private func needsStartingTarget(_ section: WorkoutExerciseSectionModel, row: Int) -> Bool {
        guard let target = resolvedTarget(section, row: row) else { return true }
        return target.source == .planned && !section.exercise.isBodyweight
            && target.weight == 0 && template?.plannedWeight(for: section.id) == nil
    }
    private func plannedValueText(_ section: WorkoutExerciseSectionModel, row: Int) -> String {
        guard !needsStartingTarget(section, row: row), let target = resolvedTarget(section, row: row) else { return "" }
        return valueText(weight: target.weight, reps: target.reps, exercise: section.exercise)
    }
    private func valueText(weight: Double, reps: Int, exercise: Exercise) -> String {
        WorkoutTargetFormatter.loggingSetText(weightKg: weight, reps: reps, isBodyweight: exercise.isBodyweight, unitSystem: unitSystem)
    }
    /// The exercise-done preview: the same double-progression result the
    /// finish summary will offer, shown as soon as the planned sets are done.
    /// Read-only; nothing is saved until the lifter accepts after Finish.
    private func progressionSuggestion(for section: WorkoutExerciseSectionModel)
        -> (text: String, outcome: AnalyticsProgressionOutcome)? {
        guard section.hasReachedPlannedSetGoal, let template,
              case .recommendation(let recommendation)? = session.progressionEvaluation(
                  for: section.id, template: template, isBodyweight: section.exercise.isBodyweight
              ) else { return nil }
        let target = valueText(weight: recommendation.target.weightKg, reps: recommendation.target.reps,
                               exercise: section.exercise)
        switch recommendation.reason {
        case .allSetsReachedTop:
            let increment = template.progressionState(for: section.id)?.weightIncrementKg ?? 0
            return (AppCopy.Workout.exerciseDoneSuggestion(target, change:
                WorkoutTargetFormatter.loggingIncrementText(weightKg: increment, unitSystem: unitSystem)),
                .addWeight)
        case .addARep:
            return (AppCopy.Workout.exerciseDoneSuggestion(target, change: AppCopy.Workout.suggestionAddOneRep), .addRep)
        case .repeatTarget:
            return (AppCopy.Workout.exerciseDoneSuggestion(target, change: AppCopy.Workout.suggestionSameTarget),
                    .repeatTarget)
        }
    }
    private func summary(for section: WorkoutExerciseSectionModel) -> String {
        if section.hasReachedPlannedSetGoal {
            let entries = section.entries
            if let first = entries.first, entries.allSatisfy({ $0.weight == first.weight && $0.reps == first.reps }) {
                return "\(entries.count) × \(valueText(weight: first.weight, reps: first.reps, exercise: section.exercise))"
            }
            return "\(entries.count) sets"
        }
        guard let target = resolvedTarget(section, row: section.entries.count + 1),
              !needsStartingTarget(section, row: section.entries.count + 1) else { return "" }
        return "\(section.plannedSetCount) × \(valueText(weight: target.weight, reps: target.reps, exercise: section.exercise))"
    }
    private func supportingText(for section: WorkoutExerciseSectionModel, row: Int) -> String {
        if needsStartingTarget(section, row: row) { return AppCopy.Workout.noStartingTarget }
        if let prior = SetEntry.latestValidWorkingSets(for: section.id, in: sessions, excluding: session.id).last {
            let load = displayWeight(prior.weight).weightString
            let weight = section.exercise.isBodyweight
                ? (prior.weight > 0 ? "\(AppCopy.Workout.bodyweightAbbrev) + \(load)" : AppCopy.Workout.bodyweightAbbrev)
                : load
            return AppCopy.Workout.lastTimeValue(weight, prior.reps)
        }
        return AppCopy.Workout.startingTargetLabel
    }
    private func displayWeight(_ kg: Double) -> Double { unitSystem == "lb" ? kg * 2.20462 : kg }
    private func inputWeight(_ target: SetPrefill?, section: WorkoutExerciseSectionModel) -> String {
        guard let target else { return "" }
        let kg = target.weight
        if kg == 0 && !section.exercise.isBodyweight && template?.plannedWeight(for: section.id) == nil
            && target.source == .planned { return "" }
        return displayWeight(kg).weightString.replacingOccurrences(of: ".", with: Locale.current.decimalSeparator ?? ".")
    }
    private var parsedDisplayWeight: Double? {
        let value = Double(weightText.replacingOccurrences(of: ",", with: "."))
        return value.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
    }
    private var canCommitEditor: Bool {
        guard let editor, let exercise = exercises.first(where: { $0.id == editor.exerciseID }),
              (Int(repsText) ?? 0) > 0 else { return false }
        return parsedDisplayWeight != nil || (exercise.isBodyweight && weightText.isEmpty)
    }

    @discardableResult
    private func beginEditing(section: WorkoutExerciseSectionModel, row: WorkoutLoggingState.Row) -> Bool {
        if editor?.id == rowID(section.id, row.number) { return true }
        guard commitEditor() else { return false }
        logging.invalidateUndo()
        let entryID: UUID?
        let target: SetPrefill?
        if case .logged(let id) = row.kind, let entry = section.entries.first(where: { $0.id == id }) {
            entryID = id
            target = SetPrefill(weight: entry.weight, reps: entry.reps, source: .currentSession, note: entry.note)
        } else { entryID = nil; target = resolvedTarget(section, row: row.number) }
        let initialWeight = inputWeight(target, section: section)
        let initialReps = target.map { String($0.reps) } ?? ""
        editor = InlineEditor(exerciseID: section.id, number: row.number, entryID: entryID,
                              isCurrent: row.kind == .current, isSetup: needsStartingTarget(section, row: row.number), original: target,
                              initialWeightText: initialWeight, initialRepsText: initialReps)
        let draft = inputDrafts[inputDraftKey(rowID(section.id, row.number))]
        weightText = draft?.weight ?? initialWeight
        repsText = draft?.reps ?? initialReps
        if draft != nil { editedRows.insert(rowID(section.id, row.number)) }
        return true
    }
    @discardableResult
    private func ensureEditor(section: WorkoutExerciseSectionModel, row: WorkoutLoggingState.Row) -> Bool {
        beginEditing(section: section, row: row)
    }
    private func handleFocusChange(from old: LoggingField?, to new: LoggingField?) {
        if let new, editor?.id != new.rowID,
           let section = sectionModels.first(where: { section in
               WorkoutLoggingState.rows(for: state(for: section), isCurrent: section.id == currentExerciseID)
                   .contains { rowID(section.id, $0.number) == new.rowID }
           }), let row = WorkoutLoggingState.rows(for: state(for: section), isCurrent: section.id == currentExerciseID)
            .first(where: { rowID(section.id, $0.number) == new.rowID }) {
            if !beginEditing(section: section, row: row), let editor { focusedField = .weight(editor.id) }
        } else if old != nil && new == nil { commitEditor() }
    }
    @discardableResult
    private func commitEditor(saveSetup: Bool = false) -> Bool {
        guard let editor else { return true }
        if editor.isSetup && editor.isCurrent && !saveSetup { return true }
        if !saveSetup && weightText == editor.initialWeightText && repsText == editor.initialRepsText {
            removeInputDraft(editor.id)
            self.editor = nil
            return true
        }
        guard canCommitEditor, let exercise = exercises.first(where: { $0.id == editor.exerciseID }) else {
            retainInputDraft()
            setEditHintToast = .init("Enter a valid weight and reps.", kind: .error)
            AppHaptic.error.fire()
            return false
        }
        let weightKg = WorkoutLoggingState.canonicalWeight(originalKg: editor.original?.weight,
            displayWeight: parsedDisplayWeight ?? 0, weightChanged: weightText != editor.initialWeightText,
            unitSystem: unitSystem)
        let reps = Int(repsText) ?? 0
        let success: Bool
        if let entryID = editor.entryID, let entry = session.setEntries.first(where: { $0.id == entryID }) {
            success = updateSet(entry, exercise: exercise, weight: weightKg, reps: reps, note: entry.note)
        } else {
            success = savePreparedTarget(exercise: exercise, weight: weightKg, reps: reps,
                note: editor.original?.note ?? "", row: editor.isCurrent ? nil : editor.number,
                currentRow: editor.isCurrent ? editor.number : nil)
        }
        if success {
            removeInputDraft(editor.id)
            self.editor = nil
        }
        return success
    }
    private func keyboardButton(_ title: String, action: @escaping () -> Void) -> some View {
        AppSecondaryButton(title, detailAlignment: .center, action: action)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
    }

    private var inputDrafts: [String: InputDraft] {
        (try? JSONDecoder().decode([String: InputDraft].self, from: inputDraftsData)) ?? [:]
    }
    private func inputDraftKey(_ row: String) -> String { "\(session.id)#\(row)" }
    private func retainInputDraft() {
        guard let editor else { return }
        var drafts = inputDrafts.filter { $0.key.hasPrefix("\(session.id)#") }
        drafts[inputDraftKey(editor.id)] = InputDraft(weight: weightText, reps: repsText)
        if let encoded = try? JSONEncoder().encode(drafts) { inputDraftsData = encoded }
    }
    private func removeInputDraft(_ row: String) {
        var drafts = inputDrafts
        drafts.removeValue(forKey: inputDraftKey(row))
        if let encoded = try? JSONEncoder().encode(drafts) { inputDraftsData = encoded }
    }
    private func finishEditing() {
        let isSetup = editor?.isSetup == true && editor?.isCurrent == true
        let saved = commitEditor(saveSetup: isSetup)
        // Invalid input and durable save failures keep the draft available.
        if saved { focusedField = nil }
    }
    private func canPerformCurrentAction(_ section: WorkoutExerciseSectionModel, number: Int) -> Bool {
        guard !guardActive else { return false }
        if let editor {
            return editor.id == rowID(section.id, number) && canCommitEditor
        }
        return !needsStartingTarget(section, row: number)
    }

    private func stepInput(direction: Int) {
        guard let focusedField else { return }
        defer { retainInputDraft() }
        editedRows.insert(focusedField.rowID)
        if focusedField.isReps {
            repsText = String(WorkoutLoggingState.steppedReps(Int(repsText) ?? 1, direction: direction))
        } else {
            weightText = WorkoutLoggingState.steppedWeight(parsedDisplayWeight ?? 0, direction: direction, unitSystem: unitSystem).weightString
        }
    }
    private func saveStartingTarget(section: WorkoutExerciseSectionModel, number: Int) {
        guard editor?.id == rowID(section.id, number), commitEditor(saveSetup: true) else { return }
        focusedField = nil
    }
    private func savePreparedTarget(exercise: Exercise, weight: Double, reps: Int, note: String, row: Int? = nil, currentRow: Int? = nil) -> Bool {
        let target = SetPrefill(weight: weight, reps: reps, source: .prepared, note: note)
        guard let targets = WorkoutLoggingState.savingTarget(target, in: preparedTargets,
            sessionID: session.id, exerciseID: exercise.id, row: row, currentRow: currentRow),
            let encoded = try? JSONEncoder().encode(targets) else { return false }
        preparedSetTargetsData = encoded
        return true
    }
    private func clearPreparedTarget() {
        var targets = preparedTargets
        targets.removeValue(forKey: session.id.uuidString)
        if let encoded = try? JSONEncoder().encode(targets) { preparedSetTargetsData = encoded }
    }

    private func completeSuggestedSet(section: WorkoutExerciseSectionModel, number: Int) {
        guard logging.canLog(at: Date()), currentExerciseID == section.id,
              section.entries.count + 1 == number else { return }
        if let editor {
            guard editor.id == rowID(section.id, number), !editor.isSetup,
                  commitEditor() else { return }
        }
        focusedField = nil
        guard !needsStartingTarget(section, row: number),
              let target = resolvedTarget(section, row: number) else { return }
        completeSet(exercise: section.exercise, target: target, number: number)
    }
    private func completeSet(exercise: Exercise, target: SetPrefill, number: Int) {
        let now = Date()
        guard logging.canLog(at: now), target.weight.isFinite, target.weight >= 0, target.reps > 0 else { return }
        let entry = SetEntry(sessionId: session.id, exerciseId: exercise.id, weight: target.weight,
            reps: target.reps, rpe: 0, rir: -1, isWarmup: false, isCompleted: true,
            setIndex: (session.setEntries.filter { $0.exerciseId == exercise.id }.map(\.setIndex).max() ?? -1) + 1,
            note: target.note)
        entry.session = session
        modelContext.insert(entry)
        guard saveWorkoutChanges() else { return }
        withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
            logging.didLog(entryID: entry.id, exerciseID: exercise.id, at: Date())
            guardActive = true
            expandedCompletedID = nil
            if currentEntries(for: exercise.id).count >= plannedSetCount(for: exercise.id) {
                selectedExerciseID = WorkoutLoggingState.nextUnfinishedExerciseID(in: exerciseStates, after: exercise.id)
                if let selectedExerciseID {
                    // Keep the finished card (check + next-time suggestion) on screen
                    // when the next exercise sits right below it.
                    let followsDirectly = orderedExerciseIDs.firstIndex(of: selectedExerciseID)
                        == orderedExerciseIDs.firstIndex(of: exercise.id).map { $0 + 1 }
                    scrollPosition.scrollTo(id: (followsDirectly ? exercise.id : selectedExerciseID).uuidString,
                                            anchor: .top)
                }
            }
        }
        var suggestionAnnouncement = ""
        if let section = sectionModels.first(where: { $0.id == exercise.id }),
           let suggestion = progressionSuggestion(for: section) {
            suggestionAnnouncement = " \(exercise.displayName) done. \(suggestion.text)."
            if trackedPreviewExerciseIDs.insert(exercise.id).inserted {
                UnitAnalytics.shared.track(.progressionPreviewShown(outcome: suggestion.outcome))
            }
        }
        if !editedRows.contains(rowID(exercise.id, number)) { noKeyboardSetCount += 1 }
        setLoggedPhase &+= 1
        if isWorkoutComplete { restTimer.stop() }
        else { startRestTimer(sourceEntryID: entry.id) }
        AccessibilityNotification.Announcement("Set \(number) logged.\(suggestionAnnouncement) \(restTimer.isRunning ? AppCopy.Workout.restIdle(defaultRestText) : "")").post()
    }
    private func releaseLoggingGuard() async {
        guard logging.lastLogAt != nil else { return }
        do { try await Task.sleep(for: .seconds(WorkoutLoggingState.guardDuration)) } catch { return }
        guardActive = false
        currentRowFocused = true
        if currentRowBottom > visibleListHeight - AppSpacing.md, let currentSection {
            withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
                scrollPosition.scrollTo(id: rowID(currentSection.id, currentSection.entries.count + 1), anchor: .bottom)
            }
        }
    }
    private func showsInlineUndo(for exerciseID: UUID) -> Bool {
        logging.availableUndo(at: Date())?.exerciseID == exerciseID
    }
    private func undoLastLog() {
        guard !guardActive, let undo = logging.availableUndo(at: Date()),
              let entry = session.setEntries.first(where: { $0.id == undo.entryID }) else { return }
        modelContext.delete(entry)
        guard saveWorkoutChanges() else { return }
        withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil) {
            selectedExerciseID = undo.exerciseID
            logging.invalidateUndo()
        }
        handleRemovedEntry(undo.entryID)
        AppHaptic.tap.fire()
    }
    private func updateSet(_ entry: SetEntry, exercise: Exercise, weight: Double, reps: Int, note: String) -> Bool {
        guard reps > 0, weight.isFinite, weight >= 0 else { return false }
        entry.weight = weight; entry.reps = reps; entry.note = note
        guard saveWorkoutChanges() else { return false }
        logging.invalidateUndo()
        restTimer.updateUpNext(upNextText)
        return true
    }
    private func deleteSet(_ entry: SetEntry, exercise: Exercise) -> Bool {
        guard !guardActive else { return false }
        let snapshot = SetEntrySnapshot(entry)
        modelContext.delete(entry)
        guard saveWorkoutChanges() else { return false }
        logging.invalidateUndo()
        removedSet = snapshot
        selectedExerciseID = exercise.id
        handleRemovedEntry(snapshot.id)
        setEditHintToast = .init("Set removed", action: .init(id: snapshot.id, label: AppCopy.Toast.undo) {
            undoRemovedSet(snapshotID: snapshot.id)
        })
        AppHaptic.warning.fire()
        return true
    }
    private func undoRemovedSet(snapshotID: UUID) {
        guard let snapshot = removedSet, snapshot.id == snapshotID,
              !session.setEntries.contains(where: { $0.id == snapshotID }) else { return }
        modelContext.insert(snapshot.restore(in: session))
        guard saveWorkoutChanges() else { return }
        removedSet = nil
        restTimer.updateUpNext(upNextText)
        AppHaptic.tap.fire()
    }
    private func handleRemovedEntry(_ entryID: UUID) {
        if WorkoutLoggingState.shouldStopRest(removing: entryID, sourceEntryID: restTimer.sourceEntryID) {
            restTimer.stop()
        } else { restTimer.updateUpNext(upNextText) }
    }
    private func startRestTimer(sourceEntryID: UUID) {
        restTimer.start(totalSeconds: max(15, restDurationSeconds), upNext: upNextText, sourceEntryID: sourceEntryID)
    }
    private func adjustRestTimer(by delta: Int) {
        guard restTimer.isRunning, delta > 0 || restTimer.secondsRemaining > 15 else { return }
        restTimer.adjust(by: delta, minimumSeconds: 15)
        restDurationSeconds = max(15, restTimer.totalDuration)
    }
    private func skipRest() { logging.invalidateUndo(); restTimer.stop() }
    private func jump(to id: UUID) {
        guard !guardActive, commitEditor() else { return }
        // A first target is only saved by its explicit action. Keep its raw
        // draft, but release the editor so it cannot disable another exercise.
        if editor?.isSetup == true && editor?.exerciseID != id {
            retainInputDraft()
            editor = nil
        }
        focusedField = nil
        logging.invalidateUndo()
        selectedExerciseID = id
        expandedCompletedID = sectionModels.first(where: { $0.id == id })?.hasReachedPlannedSetGoal == true ? id : nil
        restTimer.updateUpNext(upNextText)
    }
    private func skipExercise() {
        guard let currentExerciseID,
              let next = WorkoutLoggingState.nextUnfinishedExerciseID(in: exerciseStates, after: currentExerciseID) else { return }
        jump(to: next)
    }
    private func addSet(to section: WorkoutExerciseSectionModel) {
        guard !guardActive, commitEditor() else { return }
        if editor?.isSetup == true && editor?.exerciseID != section.id {
            retainInputDraft()
            editor = nil
        }
        focusedField = nil
        logging.invalidateUndo()
        customSetCounts[section.id] = max(section.entries.count, section.plannedSetCount) + 1
        selectedExerciseID = section.id
        expandedCompletedID = nil
        restTimer.updateUpNext(upNextText)
    }
    private func setBodyweight(_ isBodyweight: Bool, exercise: Exercise) {
        logging.invalidateUndo()
        exercise.isBodyweight = isBodyweight
        _ = saveWorkoutChanges()
    }
    private func restoreWorkout() {
        if editor == nil, let section = currentSection,
           let row = WorkoutLoggingState.rows(for: state(for: section), isCurrent: true).first(where: { $0.kind == .current }),
           inputDrafts[inputDraftKey(rowID(section.id, row.number))] != nil {
            _ = beginEditing(section: section, row: row)
        }
        restTimer.enableForegroundAlerts()
        restTimer.resumeFromBackground()
        if !didTrackWorkoutStart { didTrackWorkoutStart = true; UnitAnalytics.shared.track(.workoutStarted) }
    }
    private func requestFinish() {
        guard commitEditor() else { return }
        focusedField = nil
        logging.invalidateUndo()
        showsFinishConfirmation = true
    }
    private func confirmFinish() {
        if isFreestyleSession { renameDraft = ""; showsRenamePrompt = true; return }
        pendingRoutineUpdates = WorkoutLoggingState.routineUpdates(exercises: exerciseStates,
            targets: preparedTargets, sessionID: session.id, isFreestyle: isFreestyleSession)
        if pendingRoutineUpdates.isEmpty { finishWorkout() }
        else { pendingRoutineUpdatePrompt = true }
    }
    private func applyRoutineUpdatesAndFinish() {
        for update in pendingRoutineUpdates {
            template?.setPlannedWeight(update.weight, for: update.exerciseID)
            template?.setPlannedReps(update.reps, for: update.exerciseID)
        }
        finishWorkout()
    }
    private func saveWorkoutChanges() -> Bool {
        guard viewModel.saveChanges(in: modelContext) else {
            saveFailed = true
            AppHaptic.error.fire()
            return false
        }
        return true
    }
    private func finishWorkout() {
        guard !session.isCompleted else { return }
        session.isCompleted = true
        if let template {
            session.captureProgressionRecords(
                template: template,
                exercises: exercises
            )
        }
        guard saveWorkoutChanges() else { return }
        clearPreparedTarget()
        exerciseOrderData = Data()
        restTimer.stop()
        let completedSetCount = session.setEntries.filter {
            $0.isCompleted && !$0.isWarmup
        }.count
        UnitAnalytics.shared.track(
            .workoutCompleted(
                duration: .value(for: Date().timeIntervalSince(session.date)),
                setCount: .value(for: completedSetCount),
                noKeyboardRatio: .value(
                    prefilledSets: noKeyboardSetCount,
                    completedSets: completedSetCount
                )
            )
        )
        EngagementPromptTracker().recordCompletedWorkout(sessionID: session.id)
        onFinished?(session)
        workoutFinishedPhase &+= 1
    }


    private func saveExerciseOrder(_ ids: [UUID]) {
        guard !guardActive else { return }
        // Keep the active set/editor on its UUID while neighboring exercises move.
        selectedExerciseID = currentExerciseID
        exerciseOrderData = WorkoutLoggingState.encodeExerciseOrder(ids, sessionID: session.id)
        restTimer.updateUpNext(upNextText)
    }

    private func moveExercise(_ sourceID: UUID, _ targetID: UUID) -> Bool {
        guard !guardActive, let source = orderedExerciseIDs.firstIndex(of: sourceID),
              let target = orderedExerciseIDs.firstIndex(of: targetID), source != target else { return false }
        var ids = orderedExerciseIDs
        ids.insert(ids.remove(at: source), at: target)
        saveExerciseOrder(ids)
        AppHaptic.select.fire()
        return true
    }

    private var addExerciseButton: some View {
        AppGhostButton(AppCopy.Workout.addExercise) { showsAddExercise = true }
    }
    private var addExercisePrompt: some View {
        EmptyStateCard(title: AppCopy.Workout.addFirstExerciseTitle,
            message: AppCopy.Workout.addFirstExerciseHint,
            buttonLabel: AppCopy.Workout.addExercise) { showsAddExercise = true }
    }
    private func addExerciseToWorkout(_ exercise: Exercise) {
        guard let template else { return }
        var ids = template.orderedExerciseIds
        guard !ids.contains(exercise.id) else { return }
        ids.append(exercise.id)
        template.orderedExerciseIds = ids
        guard saveWorkoutChanges() else { return }
        selectedExerciseID = exercise.id
        pendingExerciseForSetup = exercise
    }
    private func cancelWorkout() {
        template?.restoreLastPerformedDate(removing: session, sessions: sessions)
        modelContext.delete(session)
        guard saveWorkoutChanges() else { return }
        clearPreparedTarget()
        exerciseOrderData = Data()
        restTimer.stop()
    }
    private func plannedSetCount(for exerciseID: UUID) -> Int {
        if let custom = customSetCounts[exerciseID] {
            return custom
        }
        // The user's explicit routine plan is authoritative. History only
        // fills gaps for legacy/freestyle routines without a stored plan; an
        // early-finished session must not permanently shrink the next workout.
        if let templatePlan = template?.plannedSets(for: exerciseID), templatePlan > 0 {
            return templatePlan
        }
        if let latestTemplateCount = latestCompletedSetCount(for: exerciseID, matchingTemplate: true) {
            return latestTemplateCount
        }
        if let latestAnyCount = latestCompletedSetCount(for: exerciseID, matchingTemplate: false) {
            return latestAnyCount
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

    var id: UUID { exercise.id }

    var hasReachedPlannedSetGoal: Bool {
        entries.count >= plannedSetCount
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
                    label: AppCopy.Workout.setCountQuestion,
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

struct SetPrefill: Codable {
    enum Source: String, Equatable, Codable {
        case prepared
        case currentSession
        case acceptedProgression
        case priorSession
        case planned
    }

    let weight: Double
    let reps: Int
    let source: Source
    var note: String = ""
}

@MainActor
@Observable
final class ActiveWorkoutViewModel {
    /// Nonisolated: under default-MainActor isolation the implicit deinit is
    /// isolated and routes through `swift_task_deinitOnExecutor`'s back-deploy
    /// shim, which SIGABRTs (malloc double-free in `TaskLocal::StopLookupScope`)
    /// on iOS 26 runtimes when the last release happens with a task context.
    /// Empty body — releasing stored refs needs no isolation.
    nonisolated deinit {}

    /// All workout outcomes depend on a successful durable save. The closure
    /// is injectable for failure regression tests; production uses SwiftData.
    func saveChanges(in context: ModelContext, save: (() throws -> Void)? = nil) -> Bool {
        do {
            if let save { try save() } else { try context.save() }
            return true
        } catch {
            context.rollbackRestoringLoadedModels()
            return false
        }
    }

    func prefillSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession],
        acceptedProgressionTarget: DoubleProgressionTarget? = nil,
        plannedReps: Int? = nil,
        plannedWeightKg: Double? = nil
    ) -> SetPrefill? {
        let currentEntries = currentSession.setEntries
            .filter { $0.exerciseId == exerciseID && $0.isValidCompletedWorkingSet }
            .sorted { $0.setIndex < $1.setIndex }

        if let currentLast = currentEntries.last {
            return SetPrefill(
                weight: currentLast.weight,
                reps: currentLast.reps,
                source: .currentSession
            )
        }

        if let acceptedProgressionTarget,
           acceptedProgressionTarget.weightKg.isFinite,
           acceptedProgressionTarget.weightKg > 0,
           acceptedProgressionTarget.reps > 0 {
            return SetPrefill(
                weight: acceptedProgressionTarget.weightKg,
                reps: acceptedProgressionTarget.reps,
                source: .acceptedProgression
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
            // First session: use a pasted/program starting weight when present,
            // otherwise retain the editable reps-only empty-weight state.
            // Values remain canonical kilograms through persistence and logging;
            // conversion happens only at formatter and input boundaries.
            let seededKg = plannedWeightKg.flatMap {
                $0.isFinite && $0 >= 0 ? $0 : nil
            } ?? 0
            return SetPrefill(weight: seededKg, reps: plannedReps, source: .planned)
        }

        return nil
    }

    private func latestSessionSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession]
    ) -> SetEntry? {
        SetEntry.latestValidWorkingSets(
            for: exerciseID, in: sessions, excluding: currentSession.id
        ).last
    }

}

@MainActor
@Observable
final class RestTimerManager: NSObject, UNUserNotificationCenterDelegate {
    /// Injectable notification effects keep timer tests away from system permissions.
    struct NotificationClient {
        var authorizationStatus: () async -> UNAuthorizationStatus
        var requestAuthorization: () async -> Bool
        var add: (UNNotificationRequest) async throws -> Void
        var cancel: ([String]) -> Void

        static var live: Self {
            let center = UNUserNotificationCenter.current()
            return Self(
                authorizationStatus: { await center.notificationSettings().authorizationStatus },
                requestAuthorization: { (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false },
                add: { try await center.add($0) },
                cancel: {
                    center.removePendingNotificationRequests(withIdentifiers: $0)
                    center.removeDeliveredNotifications(withIdentifiers: $0)
                }
            )
        }
    }

    var secondsRemaining = 0
    var isRunning = false
    var completionCount = 0
    private(set) var finishedAt: Date?
    var isFinished: Bool { finishedAt != nil }
    var sourceEntryID: UUID? {
        didSet { defaults.set(sourceEntryID?.uuidString, forKey: Self.sourceEntryIDKey) }
    }
    private(set) var notificationIssue: String?
    private(set) var totalDuration = 0
    private(set) var endDate: Date?

    private let defaults: UserDefaults
    private let now: () -> Date
    private let notifications: NotificationClient
    private let usesLiveActivities: Bool
    private let automaticallyTicks: Bool
    private var notificationTask: Task<Void, Never>?
    private var task: Task<Void, Never>?
    private var activity: Activity<RestTimerAttributes>?
    private var startDate: Date?
    private var upNext: String?

    private nonisolated static let notificationPrefix = "unit.restTimer.finished."
    private static let notificationIDKey = "unit.restTimer.notificationID"
    private static let upNextKey = "unit.restTimer.upNext"
    private static let sourceEntryIDKey = "unit.restTimer.sourceEntryID"
    private static let finishedAtKey = "unit.restTimer.finishedAt"
    private static let endDateKey = "unit.restTimer.endDate"
    private static let totalDurationKey = "unit.restTimer.totalDuration"
    private static let finishedDisplayDuration: TimeInterval = 30

    // Keep deallocation nonisolated for the existing back-deployment shim.
    nonisolated deinit {}

    override convenience init() {
#if DEBUG
        // UI tests use an isolated store; retained system activities must not
        // restore another test's timer or outlive that isolated fixture.
        let usesLiveActivities = !CommandLine.arguments.contains("-ui-testing")
#else
        let usesLiveActivities = true
#endif
        self.init(defaults: .standard, now: Date.init, notifications: .live,
                  usesLiveActivities: usesLiveActivities)
    }

    init(
        defaults: UserDefaults,
        now: @escaping () -> Date,
        notifications: NotificationClient,
        usesLiveActivities: Bool = true,
        automaticallyTicks: Bool = true
    ) {
        self.defaults = defaults
        self.now = now
        self.notifications = notifications
        self.usesLiveActivities = usesLiveActivities
        self.automaticallyTicks = automaticallyTicks
        super.init()
        restoreFromPersistedState()
    }

    func enableForegroundAlerts() {
        UNUserNotificationCenter.current().delegate = self
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        notification.request.identifier.hasPrefix(Self.notificationPrefix) ? [.banner, .sound] : []
    }

    var label: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    func start(totalSeconds: Int, upNext: String? = nil, sourceEntryID: UUID? = nil) {
        task?.cancel()
        task = nil
        finishedAt = nil
        self.sourceEntryID = sourceEntryID
        notificationIssue = nil
        totalDuration = max(15, totalSeconds)
        secondsRemaining = totalDuration
        let start = now()
        startDate = start
        endDate = start.addingTimeInterval(TimeInterval(totalDuration))
        self.upNext = upNext
        isRunning = true
        persistState()
        scheduleCompletionNotification()
        if activity == nil { startActivity() } else { updateActivity() }
        startCountdownTask()
    }

    func pause() {
        guard isRunning, secondsRemaining > 0 else { return }
        cancelCompletionNotification()
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
        let start = now()
        startDate = start
        endDate = start.addingTimeInterval(TimeInterval(secondsRemaining))
        persistState()
        scheduleCompletionNotification()
        startActivity()
        startCountdownTask()
    }

    func resumeFromBackground() {
        if let end = endDate {
            let remaining = Int(ceil(end.timeIntervalSince(now())))
            if remaining <= 0 {
                completeIfFinished()
            } else {
                secondsRemaining = remaining
                isRunning = true
                startCountdownTask()
            }
        } else {
            clearExpiredFinishedState()
        }
    }

    func adjust(by delta: Int, minimumSeconds: Int = 15) {
        if isRunning {
            resumeFromBackground()
            guard isRunning else { return }
        }
        let minimum = max(15, minimumSeconds)
        let baseRemaining = secondsRemaining > 0 ? secondsRemaining : totalDuration
        let updatedRemaining = max(minimum, baseRemaining + delta)
        totalDuration = max(minimum, totalDuration + delta)
        secondsRemaining = updatedRemaining
        if isRunning {
            endDate = now().addingTimeInterval(TimeInterval(updatedRemaining))
            startDate = endDate?.addingTimeInterval(-TimeInterval(totalDuration))
            persistState()
            scheduleCompletionNotification()
            updateActivity()
        }
    }

    /// A plan edit changes only the notification/activity text, never the deadline.
    func updateUpNext(_ text: String?) {
        guard upNext != text else { return }
        upNext = text
        guard isRunning else { return }
        resumeFromBackground()
        guard isRunning else { return }
        persistState()
        scheduleCompletionNotification()
        updateActivity()
    }

    /// Skip/cancellation does not produce a completion event or finished state.
    func stop() {
        cancelCompletionNotification()
        task?.cancel()
        task = nil
        isRunning = false
        secondsRemaining = 0
        totalDuration = 0
        endDate = nil
        startDate = nil
        finishedAt = nil
        sourceEntryID = nil
        upNext = nil
        notificationIssue = nil
        clearPersistedState()
        endActivity()
    }

    private func completeIfFinished() {
        guard isRunning, let deadline = endDate else { return }
        secondsRemaining = 0
        isRunning = false
        totalDuration = 0
        endDate = nil
        startDate = nil
        upNext = nil
        finishedAt = deadline
        completionCount += 1
        persistState()
        endActivity()
        clearExpiredFinishedState()
        startCountdownTask()
    }

    private func clearExpiredFinishedState() {
        guard let finishedAt, now().timeIntervalSince(finishedAt) >= Self.finishedDisplayDuration else { return }
        stop()
    }

    private func restoreFromPersistedState() {
        sourceEntryID = defaults.string(forKey: Self.sourceEntryIDKey).flatMap(UUID.init(uuidString:))
        finishedAt = defaults.object(forKey: Self.finishedAtKey) as? Date
        var recoveredEnd = defaults.object(forKey: Self.endDateKey) as? Date
        var recoveredTotal = defaults.integer(forKey: Self.totalDurationKey)
        var recoveredStart: Date?
        var recoveredUpNext = defaults.string(forKey: Self.upNextKey)

        if usesLiveActivities, let liveActivity = Activity<RestTimerAttributes>.activities.first {
            let state = liveActivity.content.state
            if recoveredEnd == nil, finishedAt == nil {
                recoveredEnd = state.endDate
                recoveredTotal = max(15, Int(ceil(state.endDate.timeIntervalSince(state.startDate))))
            }
            recoveredStart = state.startDate
            recoveredUpNext = recoveredUpNext ?? state.upNext
            activity = liveActivity
        }

        guard let end = recoveredEnd else {
            clearExpiredFinishedState()
            if isFinished { endActivity(); startCountdownTask() }
            return
        }
        finishedAt = nil
        endDate = end
        startDate = recoveredStart ?? end.addingTimeInterval(-TimeInterval(max(15, recoveredTotal)))
        upNext = recoveredUpNext
        secondsRemaining = max(0, Int(ceil(end.timeIntervalSince(now()))))
        totalDuration = max(secondsRemaining, recoveredTotal)
        isRunning = true
        if end <= now() {
            // The system already owns the elapsed deadline. Never reschedule it.
            completeIfFinished()
        } else {
            startCountdownTask()
        }
    }

    private func persistState() {
        defaults.set(endDate, forKey: Self.endDateKey)
        defaults.set(totalDuration, forKey: Self.totalDurationKey)
        defaults.set(upNext, forKey: Self.upNextKey)
        defaults.set(finishedAt, forKey: Self.finishedAtKey)
        defaults.set(sourceEntryID?.uuidString, forKey: Self.sourceEntryIDKey)
    }

    private func clearPersistedState() {
        for key in [Self.endDateKey, Self.totalDurationKey, Self.upNextKey, Self.finishedAtKey, Self.sourceEntryIDKey] {
            defaults.removeObject(forKey: key)
        }
    }

    private func scheduleCompletionNotification() {
        cancelCompletionNotification()
        guard let deadline = endDate, isRunning, deadline > now() else { return }
        if usesLiveActivities { enableForegroundAlerts() }
        let identifier = Self.notificationPrefix + UUID().uuidString
        let next = upNext
        defaults.set(identifier, forKey: Self.notificationIDKey)
        notificationTask = Task { [weak self] in
            guard let self else { return }
            var status = await self.notifications.authorizationStatus()
            guard !Task.isCancelled else { return }
            if status == .notDetermined {
                _ = await self.notifications.requestAuthorization()
                status = await self.notifications.authorizationStatus()
            }
            guard !Task.isCancelled, self.endDate == deadline, self.isRunning, deadline > self.now() else { return }
            guard status == .authorized || status == .provisional else {
                self.notificationIssue = "Rest alerts are off. Enable notifications in Settings."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Rest finished"
            content.body = next.map { "Next: \($0)" } ?? "Start your next set."
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let request = UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: UNTimeIntervalNotificationTrigger(timeInterval: max(1, deadline.timeIntervalSince(self.now())), repeats: false)
            )
            do {
                try await self.notifications.add(request)
                // A late add from an old generation can remove only itself.
                if Task.isCancelled { self.notifications.cancel([identifier]) }
            } catch {
                guard !Task.isCancelled else { return }
                self.notificationIssue = "Rest alert could not be set."
            }
        }
    }

    private func cancelCompletionNotification() {
        notificationTask?.cancel()
        notificationTask = nil
        guard let identifier = defaults.string(forKey: Self.notificationIDKey) else { return }
        notifications.cancel([identifier])
        defaults.removeObject(forKey: Self.notificationIDKey)
    }

    private func startCountdownTask() {
        task?.cancel()
        guard automaticallyTicks, isRunning || isFinished else { task = nil; return }
        task = Task { [weak self] in
            while !Task.isCancelled {
                guard self?.tick() == true else { return }
                try? await Task.sleep(for: .milliseconds(500))
            }
        }
    }

    private func tick() -> Bool {
        if let endDate {
            secondsRemaining = max(0, Int(ceil(endDate.timeIntervalSince(now()))))
            if secondsRemaining == 0 { completeIfFinished(); return false }
        } else {
            clearExpiredFinishedState()
        }
        return isRunning || isFinished
    }

    private func startActivity() {
        guard usesLiveActivities, let endDate, let startDate else { return }
        let content = ActivityContent(
            state: RestTimerAttributes.ContentState(startDate: startDate, endDate: endDate, upNext: upNext),
            staleDate: endDate,
            relevanceScore: 100
        )
        activity = try? Activity<RestTimerAttributes>.request(attributes: RestTimerAttributes(), content: content, pushType: nil)
    }

    private func updateActivity() {
        guard usesLiveActivities, let endDate, let startDate else { return }
        let content = ActivityContent(
            state: RestTimerAttributes.ContentState(startDate: startDate, endDate: endDate, upNext: upNext),
            staleDate: endDate,
            relevanceScore: 100
        )
        let currentActivity = activity
        Task { await currentActivity?.update(content) }
    }

    private func endActivity() {
        let currentActivity = activity
        activity = nil
        Task { await currentActivity?.end(nil, dismissalPolicy: .immediate) }
    }
}

/// Same shared drag source as routine editing; commit order only on a real drop.
private struct WorkoutExerciseDropDelegate: DropDelegate {
    let targetID: UUID
    @Binding var draggedID: UUID?
    let onMove: (UUID, UUID) -> Bool

    func validateDrop(info: DropInfo) -> Bool {
        draggedID != nil && info.hasItemsConforming(to: [.text])
    }
    func dropUpdated(info: DropInfo) -> DropProposal? { DropProposal(operation: .move) }
    func performDrop(info: DropInfo) -> Bool {
        guard let source = draggedID else { return false }
        defer { draggedID = nil }
        return onMove(source, targetID)
    }
}
