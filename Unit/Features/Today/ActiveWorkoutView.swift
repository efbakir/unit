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
    @AppStorage("unitSystem") private var unitSystem = "kg"
    @AppStorage("unit.preparedSetTargets") private var preparedSetTargetsData = Data()
    @SceneStorage("unit.loggingInputDrafts") private var inputDraftsData = Data()
    @State private var viewModel = ActiveWorkoutViewModel()
    /// The app's one rest timer, shared with the Lock Screen buttons.
    @State private var restTimer = RestTimerManager.shared
    @State private var logging = WorkoutLoggingState()
    @State private var selectedExerciseID: UUID?
    @State private var expandedCompletedID: UUID?
    /// Sets in this workout that were a personal record when logged.
    @State private var livePRIDs: Set<UUID> = []
    @State private var swapTarget: Exercise?
    @State private var historyExercise: Exercise?
    @State private var noteExercise: Exercise?
    @State private var showsNotDoneQuestion = false
    /// Rows are built once per change, not on every redraw (rest ticks redraw twice a second).
    @State private var sectionCache = SectionModelCache()
    /// The set values the PR tags were last worked out for.
    @State private var prFingerprint: [String] = []
    @State private var showsCancelConfirmation = false
    @State private var showsSkipExerciseConfirmation = false
    @State private var showsFinishConfirmation = false
    @State private var showsRenamePrompt = false
    @State private var showsDiscardRenamePrompt = false
    @State private var renameDraft = ""
    @AppStorage("unit.activeWorkoutExerciseOrder") private var exerciseOrderData = Data()
    @State private var draggedExerciseID: UUID?
    @State private var showsAddExercise = false
    @State private var pendingExerciseForSetup: Exercise?
    @State private var setLoggedPhase = 0
    @State private var workoutFinishedPhase = 0
    @State private var guardActive = false
    @State private var saveFailed = false
    @State private var didTrackWorkoutStart = false
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
    /// This workout's own order, swaps, added exercises and set counts. Saved
    /// with the session, so a relaunch keeps them; the routine never changes.
    private var sessionPlan: WorkoutLoggingState.SessionPlan {
        get { WorkoutLoggingState.plan(from: exerciseOrderData, sessionID: session.id) }
        nonmutating set { exerciseOrderData = WorkoutLoggingState.encode(newValue) }
    }
    /// Set count picked for an added or freestyle exercise.
    private var customSetCounts: [UUID: Int] {
        get { sessionPlan.setCounts }
        nonmutating set { sessionPlan.setCounts = newValue }
    }
    /// Rows added with "+ Add set", counted apart so only those can be removed.
    private var addedSetCounts: [UUID: Int] {
        get { sessionPlan.addedSets }
        nonmutating set { sessionPlan.addedSets = newValue }
    }
    /// The last unfinished exercise, once skipped, stays closed for this workout.
    private var skippedExerciseIDs: Set<UUID> {
        get { sessionPlan.skipped }
        nonmutating set { sessionPlan.skipped = newValue }
    }
    private var orderedExerciseIDs: [UUID] {
        WorkoutLoggingState.orderedExerciseIDs(templateIDs: template?.orderedExerciseIds ?? [], plan: sessionPlan)
    }
    /// A swapped-in exercise keeps the routine exercise's sets and reps.
    private func planSourceID(for exerciseID: UUID) -> UUID {
        WorkoutLoggingState.planSourceID(for: exerciseID, in: sessionPlan)
    }
    private var orderedExercises: [Exercise] {
        orderedExerciseIDs.compactMap { id in exercises.first { $0.id == id } }
    }
    private var sectionModels: [WorkoutExerciseSectionModel] {
        let key: [AnyHashable] = [loggedSetFingerprint, exerciseOrderData, preparedSetTargetsData,
                                  sessions.count, template?.id, exercises.count, unitSystem]
        if sectionCache.key == key { return sectionCache.models }
        let models = buildSectionModels()
        sectionCache.key = key
        sectionCache.models = models
        return models
    }
    private func buildSectionModels() -> [WorkoutExerciseSectionModel] {
        orderedExercises.map { exercise in
            WorkoutExerciseSectionModel(
                exercise: exercise, lastActualText: nil,
                entries: currentEntries(for: exercise.id),
                prefill: viewModel.prefillSet(
                    for: exercise.id, currentSession: session, sessions: sessions,
                    acceptedProgressionTarget: template?.progressionState(for: exercise.id)?.acceptedTarget,
                    plannedReps: template?.plannedReps(for: planSourceID(for: exercise.id)),
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
        WorkoutLoggingState.currentExerciseID(in: exerciseStates, selectedID: selectedExerciseID,
                                              skipped: skippedExerciseIDs)
    }
    private var currentSection: WorkoutExerciseSectionModel? {
        sectionModels.first { $0.id == currentExerciseID }
    }
    private var isDayDone: Bool {
        WorkoutLoggingState.isDayDone(exerciseStates, skipped: skippedExerciseIDs)
    }
    private var hasLoggedSets: Bool { session.setEntries.contains { $0.isValidCompletedWorkingSet } }
    private var upNext: WorkoutLoggingState.UpNext? {
        WorkoutLoggingState.upNext(exercises: exerciseStates, currentExerciseID: currentExerciseID,
                                   skipped: skippedExerciseIDs)
    }
    /// "Set 2 · 135 lb × 10" for the Lock Screen and rest alert; only the set
    /// number when that row has no starting target yet.
    private var upNextDetail: String? {
        guard let upNext else { return nil }
        let value = sectionModels.first(where: { $0.id == upNext.exerciseID }).flatMap { section -> String? in
            guard !needsStartingTarget(section, row: upNext.setNumber),
                  let target = resolvedTarget(section, row: upNext.setNumber) else { return nil }
            return valueText(weight: target.weight, reps: target.reps, exercise: section.exercise)
        }
        return AppCopy.Workout.upNextDetail(setNumber: upNext.setNumber, value: value)
    }
    private var restUpNext: [String?] { [upNext?.name, upNextDetail] }
    private var preparedTargets: WorkoutLoggingState.Targets {
        WorkoutLoggingState.decodeTargets(preparedSetTargetsData)
    }
    /// Changes when a set is logged, edited or removed, the only times PRs can change.
    private var loggedSetFingerprint: [String] {
        session.setEntries.map { "\($0.id)|\($0.weight)|\($0.reps)|\($0.isCompleted)" }
    }
    /// Exercises with sets still open (skipped ones included), for the Finish question.
    private var unfinishedExercises: [WorkoutLoggingState.ExerciseState] {
        exerciseStates.filter { !$0.isComplete }
    }
    /// "Bench Press rest": the running rest belongs to the set that started it;
    /// otherwise it is the current exercise's next rest.
    private var restTitle: String {
        let id = restTimer.isRunning || restTimer.isFinished ? (restTimer.sourceExerciseID ?? currentExerciseID) : currentExerciseID
        guard let name = exercises.first(where: { $0.id == id })?.displayName else { return AppCopy.Workout.restLabel }
        return AppCopy.Workout.restTitle(name)
    }
    /// The rest the current exercise's next set starts (its own, else the default).
    private var defaultRestText: String {
        RestTimerManager.clockText(restTimer.restSeconds(for: currentExerciseID))
    }

    var body: some View {
        // Split in two so the compiler can type-check each chain in time.
        workoutScreen
        .alert(AppCopy.Workout.notDoneTitle(unfinishedExercises.map(\.name)), isPresented: $showsNotDoneQuestion) {
            Button(AppCopy.Workout.finishAnyway, action: confirmFinish)
            if let first = unfinishedExercises.first {
                Button(AppCopy.Workout.goTo(first.name)) { jump(to: first.id) }
            }
            Button(AppCopy.Nav.cancel, role: .cancel) { }
        }
        .sheet(item: $noteExercise) { exercise in
            ExerciseNoteSheet(exerciseName: exercise.displayName, note: exercise.notes) { saveNote($0, for: exercise) }
                .presentationDetents([.medium])
                .appBottomSheetChrome()
        }
        // A sheet, so the workout stays underneath: half height, drag up for all.
        .sheet(item: $historyExercise) { exercise in
            NavigationStack {
                ExerciseProgressView(exerciseId: exercise.id, exerciseName: exercise.displayName,
                                     isBodyweight: exercise.isBodyweight, sessions: sessions, templates: templates)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button { historyExercise = nil } label: {
                                Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName).labelStyle(.iconOnly)
                            }
                            .tint(AppColor.textPrimary)
                            .accessibilityIdentifier("exercise-history-close")
                        }
                    }
            }
            .presentationDetents([.medium, .large])
            .appBottomSheetChrome()
        }
        .sheet(isPresented: $showsAddExercise) {
            AppExercisePickerSheet(existingIds: Set(orderedExerciseIDs), onSelect: addExerciseToWorkout)
        }
        .sheet(item: $swapTarget) { exercise in
            AppExercisePickerSheet(title: AppCopy.Workout.swapExercise, existingIds: Set(orderedExerciseIDs)) {
                swap(exercise, with: $0)
            }
        }
        .sheet(item: $pendingExerciseForSetup) { exercise in
            SetCountPickerSheet(exerciseName: exercise.displayName) { customSetCounts[exercise.id] = $0 }
                .presentationDetents([.medium])
                .appBottomSheetChrome()
        }
        .onAppear(perform: restoreWorkout)
        .onChange(of: loggedSetFingerprint, initial: true) { _, fingerprint in
            // Complete set already worked these out for the set it logged.
            guard fingerprint != prFingerprint else { return }
            prFingerprint = fingerprint
            livePRIDs = PRHistory.prSetEntryIDs(inOpen: session, history: sessions)
        }
        .onChange(of: restUpNext) { _, _ in refreshRestUpNext() }
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
        .task(id: logging.lastLogAt) { await releaseLoggingGuard() }
        .task(id: logging.undo?.entryID) {
            guard logging.undo != nil else { return }
            do { try await Task.sleep(for: .seconds(WorkoutLoggingState.undoDuration)) } catch { return }
            logging.invalidateUndo()
        }
    }

    /// The screen with its toolbar, haptics and alerts.
    private var workoutScreen: some View {
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
                    if !sectionModels.isEmpty { addExerciseButton }
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
        .safeAreaInset(edge: .bottom, spacing: 0) { bottomBar }
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
        .appHaptic(.success, trigger: setLoggedPhase)
        .appHaptic(.success, trigger: workoutFinishedPhase)
        .appHaptic(.success, trigger: restTimer.completionCount)
        .appToast(event: $setEditHintToast)
        .alert(AppCopy.Workout.saveFailedTitle, isPresented: $saveFailed) {
            Button(AppCopy.Nav.ok, role: .cancel) { }
        } message: {
            Text(AppCopy.Workout.saveFailedMessage)
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
    }

    /// Fixed bottom chrome: the keyboard bar while typing, Finish once the day
    /// is done, otherwise the rest bar. Kept out of `body` so it type-checks fast.
    @ViewBuilder
    private var bottomBar: some View {
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
                        spatial: AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver),
                        title: restTitle)
                    if let editor, editor.isCurrent, let section = currentSection,
                       section.id == editor.exerciseID {
                        AppPrimaryButton(
                            needsStartingTarget(section, row: editor.number) ? AppCopy.Workout.saveTarget : AppCopy.Workout.completeSetNumbered(editor.number),
                            isEnabled: canCommitEditor
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
        } else if isDayDone && hasLoggedSets {
            // Every planned set is logged (or the rest was skipped): rest is
            // over, and the summary (where next targets are accepted) is one
            // tap away. The small toolbar Finish alone was easy to miss.
            AppPrimaryButton(AppCopy.Workout.finishWorkout, action: requestFinish)
                .allowsHitTesting(!guardActive)
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
                onDecrease: { adjustRestTimer(by: -AppCopy.Workout.restStepSeconds) },
                onIncrease: { adjustRestTimer(by: AppCopy.Workout.restStepSeconds) },
                onSkip: skipRest,
                title: restTitle
            )
            .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        }
    }

    @ViewBuilder
    private func exerciseContent(_ section: WorkoutExerciseSectionModel) -> some View {
        let isCurrent = section.id == currentExerciseID
        if isCurrent || expandedCompletedID == section.id {
            ExerciseLoggingCard(
                name: section.exercise.displayName,
                hasNote: !section.exercise.notes.isEmpty,
                isBodyweight: Binding(get: { section.exercise.isBodyweight }, set: { setBodyweight($0, exercise: section.exercise) }),
                onSkip: { jump(to: section.id); showsSkipExerciseConfirmation = true },
                onAddSet: { addSet(to: section) },
                onSelect: isCurrent ? nil : { jump(to: section.id) },
                onShowHistory: { showHistory(of: section.exercise) },
                onSwap: section.entries.isEmpty ? { swapExercise(section.exercise) } : nil,
                onEditNote: { editNote(of: section.exercise) },
                onRemoveAddedSet: canRemoveAddedSet(section) ? { removeAddedSet(from: section) } : nil
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
        // Only this workout here; next time lives on the summary (2026-10-24).
        return ExerciseSummaryRow(
            name: section.exercise.displayName, summary: summary(for: section),
            isCompleted: section.hasReachedPlannedSetGoal,
            showsUndo: showsInlineUndo(for: section.id),
            onUndo: undoLastLog, onSelect: { jump(to: section.id) },
            showsPR: section.entries.contains { livePRIDs.contains($0.id) },
            isSkipped: skippedExerciseIDs.contains(section.id) && !section.hasReachedPlannedSetGoal
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
                isPR: livePRIDs.contains(entry.id),
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
        .font(valueFont(for: id).font)
        .tracking(valueFont(for: id).tracking)
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
        .font(valueFont(for: id).font)
        .tracking(valueFont(for: id).tracking)
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

    /// Inline edits of a done row use the row size; the current set uses the
    /// large value. Each keeps its own tracking.
    private func valueFont(for id: String) -> AppFont {
        editor?.id == id && editor?.isCurrent == false ? .performance : (isCompact ? .setValueCompact : .setValue)
    }

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
    /// Same set-block wording as History and Today: "3 × 8 at 80 kg", or
    /// "80 kg · 8/8/7 reps" when the sets differ.
    private func summary(for section: WorkoutExerciseSectionModel) -> String {
        if section.hasReachedPlannedSetGoal {
            let entries = section.entries
            return WorkoutTargetFormatter.completedPerformanceText(
                weightsKg: entries.map(\.weight), reps: entries.map(\.reps),
                isBodyweight: section.exercise.isBodyweight
            ) ?? "\(entries.count) sets"
        }
        guard let target = resolvedTarget(section, row: section.entries.count + 1),
              !needsStartingTarget(section, row: section.entries.count + 1) else { return "" }
        let count = section.plannedSetCount
        return WorkoutTargetFormatter.completedPerformanceText(
            weightsKg: Array(repeating: target.weight, count: count),
            reps: Array(repeating: target.reps, count: count),
            isBodyweight: section.exercise.isBodyweight
        ) ?? "\(count) × \(valueText(weight: target.weight, reps: target.reps, exercise: section.exercise))"
    }
    /// "Last time" reads the workout set 1 was prefilled from: row N shows
    /// set N of it, and a set that did not exist then shows nothing.
    private func supportingText(for section: WorkoutExerciseSectionModel, row: Int) -> String? {
        if needsStartingTarget(section, row: row) { return AppCopy.Workout.noStartingTarget }
        let lastTime = SetEntry.latestValidWorkingSets(for: section.id, in: sessions, excluding: session.id,
                                                       preferringTemplate: session.templateId)
        if !lastTime.isEmpty {
            guard lastTime.indices.contains(row - 1) else { return nil }
            let prior = lastTime[row - 1]
            return AppCopy.Workout.lastTimeValue(WorkoutTargetFormatter.loggingSetText(
                weightKg: prior.weight, reps: prior.reps,
                isBodyweight: section.exercise.isBodyweight, unitSystem: unitSystem
            ))
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
    /// The 400 ms double-tap guard blocks taps (rows stop hit-testing) but never
    /// greys the button: a grey flash after every set read as a slow app.
    private func canPerformCurrentAction(_ section: WorkoutExerciseSectionModel, number: Int) -> Bool {
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
                selectedExerciseID = WorkoutLoggingState.nextUnfinishedExerciseID(
                    in: exerciseStates, after: exercise.id, skipped: skippedExerciseIDs)
                if let selectedExerciseID {
                    // Keep the finished card (check + logged sets) on screen
                    // when the next exercise sits right below it.
                    let followsDirectly = orderedExerciseIDs.firstIndex(of: selectedExerciseID)
                        == orderedExerciseIDs.firstIndex(of: exercise.id).map { $0 + 1 }
                    scrollPosition.scrollTo(id: (followsDirectly ? exercise.id : selectedExerciseID).uuidString,
                                            anchor: .top)
                }
            }
        }
        if !editedRows.contains(rowID(exercise.id, number)) { noKeyboardSetCount += 1 }
        // The tag is the only PR cue: no banner, sound or second haptic.
        livePRIDs = PRHistory.prSetEntryIDs(inOpen: session, history: sessions)
        prFingerprint = loggedSetFingerprint
        let isPR = livePRIDs.contains(entry.id)
        let prAnnouncement = isPR ? " \(AppCopy.Workout.personalRecord)." : ""
        setLoggedPhase &+= 1
        if isDayDone { restTimer.stop() }
        else { startRestTimer(sourceEntryID: entry.id, exerciseID: exercise.id) }
        AccessibilityNotification.Announcement("Set \(number) logged.\(prAnnouncement) \(restTimer.isRunning ? AppCopy.Workout.restIdle(restTimer.label) : "")").post()
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
        refreshRestUpNext()
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
        setEditHintToast = .init(AppCopy.Workout.setRemoved, action: .init(id: snapshot.id, label: AppCopy.Toast.undo) {
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
        refreshRestUpNext()
        AppHaptic.tap.fire()
    }
    private func handleRemovedEntry(_ entryID: UUID) {
        if WorkoutLoggingState.shouldStopRest(removing: entryID, sourceEntryID: restTimer.sourceEntryID) {
            restTimer.stop()
        } else { refreshRestUpNext() }
    }
    /// Rest after a set belongs to that set's exercise.
    private func startRestTimer(sourceEntryID: UUID, exerciseID: UUID) {
        restTimer.start(totalSeconds: restTimer.restSeconds(for: exerciseID), upNext: upNext?.name,
                        upNextDetail: upNextDetail, sourceEntryID: sourceEntryID, sourceExerciseID: exerciseID)
    }
    private func refreshRestUpNext() {
        restTimer.updateUpNext(upNext?.name, detail: upNextDetail)
    }
    private func adjustRestTimer(by delta: Int) { restTimer.adjustAndRemember(by: delta) }
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
        skippedExerciseIDs.remove(id)
        selectedExerciseID = id
        expandedCompletedID = sectionModels.first(where: { $0.id == id })?.hasReachedPlannedSetGoal == true ? id : nil
        refreshRestUpNext()
    }
    /// Skipped means skipped for today: the card closes and says "Skipped", and
    /// the app never comes back to it by itself. Tapping the card reopens it;
    /// Finish asks before leaving it undone.
    private func skipExercise() {
        guard let currentExerciseID, !guardActive, commitEditor() else { return }
        if editor?.isSetup == true {
            retainInputDraft()
            editor = nil
        }
        focusedField = nil
        logging.invalidateUndo()
        skippedExerciseIDs.insert(currentExerciseID)
        expandedCompletedID = nil
        selectedExerciseID = WorkoutLoggingState.nextUnfinishedExerciseID(
            in: exerciseStates, after: currentExerciseID, skipped: skippedExerciseIDs)
        if isDayDone { restTimer.stop() } else { refreshRestUpNext() }
    }
    private func addSet(to section: WorkoutExerciseSectionModel) {
        guard !guardActive, commitEditor() else { return }
        if editor?.isSetup == true && editor?.exerciseID != section.id {
            retainInputDraft()
            editor = nil
        }
        focusedField = nil
        logging.invalidateUndo()
        // Same row count as before: one more than the plan or the logged sets.
        let base = customSetCounts[section.id] ?? basePlannedSetCount(for: section.id)
        addedSetCounts[section.id] = max(section.entries.count, section.plannedSetCount) + 1 - base
        skippedExerciseIDs.remove(section.id)
        selectedExerciseID = section.id
        expandedCompletedID = nil
        refreshRestUpNext()
    }
    /// Only a row added with "+ Add set" that is still open can be removed.
    private func canRemoveAddedSet(_ section: WorkoutExerciseSectionModel) -> Bool {
        addedSetCounts[section.id, default: 0] > 0 && section.plannedSetCount > section.entries.count
    }
    private func removeAddedSet(from section: WorkoutExerciseSectionModel) {
        guard !guardActive, canRemoveAddedSet(section), commitEditor() else { return }
        focusedField = nil
        logging.invalidateUndo()
        let exerciseID = section.id
        addedSetCounts[exerciseID, default: 0] -= 1
        if addedSetCounts[exerciseID] == 0 { addedSetCounts[exerciseID] = nil }
        if section.entries.count >= plannedSetCount(for: exerciseID) {
            // The removed row was the last open one, so the exercise is done.
            selectedExerciseID = WorkoutLoggingState.nextUnfinishedExerciseID(
                in: exerciseStates, after: exerciseID, skipped: skippedExerciseIDs)
            expandedCompletedID = nil
            if isDayDone { restTimer.stop() }
        }
        refreshRestUpNext()
        setEditHintToast = .init(AppCopy.Workout.setRemoved, action: .init(id: UUID(), label: AppCopy.Toast.undo) {
            addedSetCounts[exerciseID, default: 0] += 1
            skippedExerciseIDs.remove(exerciseID)
            selectedExerciseID = exerciseID
            refreshRestUpNext()
        })
        AppHaptic.warning.fire()
    }
    private func swapExercise(_ exercise: Exercise) {
        guard commitEditor() else { return }
        focusedField = nil
        swapTarget = exercise
    }
    private func showHistory(of exercise: Exercise) {
        guard commitEditor() else { return }
        focusedField = nil
        historyExercise = exercise
    }
    private func editNote(of exercise: Exercise) {
        guard commitEditor() else { return }
        focusedField = nil
        noteExercise = exercise
    }
    private func saveNote(_ note: String, for exercise: Exercise) {
        guard note != exercise.notes else { return }
        exercise.notes = note
        _ = saveWorkoutChanges()
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
        // Skipped or half-done exercises get a clear question instead.
        if unfinishedExercises.isEmpty { showsFinishConfirmation = true } else { showsNotDoneQuestion = true }
    }
    /// No "Update routine with today's weights?" step (removed 2026-10-24):
    /// the next workout already starts from this one, so its answer changed
    /// nothing the lifter would see.
    private func confirmFinish() {
        if isFreestyleSession { renameDraft = ""; showsRenamePrompt = true; return }
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
            session.applySuggestedTargets(to: template)
        }
        guard saveWorkoutChanges() else { return }
        // Only a live finish has a real end time. Runs in the background.
        HealthWorkoutSync.saveFinishedWorkout(sessionID: session.id, start: session.date, end: Date())
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
        sessionPlan.exerciseIDs = ids
        refreshRestUpNext()
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
        guard let template, !orderedExerciseIDs.contains(exercise.id) else { return }
        if isFreestyleSession {
            // The hidden Freestyle routine is this workout's own list.
            template.orderedExerciseIds.append(exercise.id)
            guard saveWorkoutChanges() else { return }
        } else {
            // A routine workout adds for today only; the routine is unchanged.
            sessionPlan.additions.append(exercise.id)
        }
        selectedExerciseID = exercise.id
        pendingExerciseForSetup = exercise
    }
    /// Swap uses the lifter's own exercise list (no suggestions) and only
    /// before the first set; the new exercise keeps the planned sets and reps.
    private func swap(_ old: Exercise, with new: Exercise) {
        guard currentEntries(for: old.id).isEmpty else { return }
        sessionPlan = WorkoutLoggingState.swapping(old.id, with: new.id, in: sessionPlan)
        logging.invalidateUndo()
        selectedExerciseID = new.id
        expandedCompletedID = nil
        refreshRestUpNext()
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
        (customSetCounts[exerciseID] ?? basePlannedSetCount(for: exerciseID)) + addedSetCounts[exerciseID, default: 0]
    }

    private func basePlannedSetCount(for exerciseID: UUID) -> Int {
        // The user's explicit routine plan is authoritative. History only
        // fills gaps for legacy/freestyle routines without a stored plan; an
        // early-finished session must not permanently shrink the next workout.
        if let templatePlan = template?.plannedSets(for: planSourceID(for: exerciseID)), templatePlan > 0 {
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

/// Built rows for the last set of inputs; a class so `body` can refill it
/// without invalidating the view.
private final class SectionModelCache {
    var key: [AnyHashable] = []
    var models: [WorkoutExerciseSectionModel] = []
}

/// Read or edit an exercise's note. The card no longer shows the note; the
/// "..." menu's Notes item opens this sheet.
private struct ExerciseNoteSheet: View {
    let exerciseName: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var draft: String

    init(exerciseName: String, note: String, onSave: @escaping (String) -> Void) {
        self.exerciseName = exerciseName
        self.onSave = onSave
        _draft = State(initialValue: note)
    }

    var body: some View {
        AppSheetScreen(
            title: AppCopy.Workout.notes,
            primaryButton: PrimaryButtonConfig(label: AppCopy.Nav.save, action: save),
            onDismissAction: { dismiss() },
            usesOuterScroll: false
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(exerciseName).font(AppFont.body.font).foregroundStyle(AppColor.textSecondary)
                TextField(AppCopy.Workout.notePlaceholder, text: $draft, axis: .vertical)
                    .lineLimit(3...6)
                    .font(AppFont.body.font)
                    .appInputFieldStyleMultiline(minHeight: 96)
                    .accessibilityIdentifier("exercise-note-field")
                Text(AppCopy.Workout.noteMessage).font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private func save() {
        onSave(draft.trimmingCharacters(in: .whitespacesAndNewlines))
        dismiss()
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
                    size: .weekday,
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

    /// Set 1 of this routine's last workout with the exercise, else of any
    /// routine's. The first set is the planned working set; the last one is
    /// often a fatigue drop.
    private func latestSessionSet(
        for exerciseID: UUID,
        currentSession: WorkoutSession,
        sessions: [WorkoutSession]
    ) -> SetEntry? {
        SetEntry.latestValidWorkingSets(
            for: exerciseID, in: sessions, excluding: currentSession.id,
            preferringTemplate: currentSession.templateId
        ).first
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
    /// The exercise whose set started this rest; −30 / +30 save to it.
    private(set) var sourceExerciseID: UUID?
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
    private var upNextDetail: String?

    private nonisolated static let notificationPrefix = "unit.restTimer.finished."
    private static let notificationIDKey = "unit.restTimer.notificationID"
    private static let upNextKey = "unit.restTimer.upNext"
    private static let upNextDetailKey = "unit.restTimer.upNextDetail"
    private static let sourceEntryIDKey = "unit.restTimer.sourceEntryID"
    private static let sourceExerciseIDKey = "unit.restTimer.sourceExerciseID"
    /// Global default rest (120 s at first), used by exercises without their own.
    private static let defaultRestKey = "restDurationSeconds"
    private static let restByExerciseKey = "unit.restSecondsByExercise"
    private static let finishedAtKey = "unit.restTimer.finishedAt"
    private static let endDateKey = "unit.restTimer.endDate"
    private static let totalDurationKey = "unit.restTimer.totalDuration"
    private static let finishedDisplayDuration: TimeInterval = 30

    // Keep deallocation nonisolated for the existing back-deployment shim.
    nonisolated deinit {}

    /// One timer for the workout screen and the Lock Screen intents, so a
    /// button on either side changes the same rest.
    static let shared = RestTimerManager()

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

    var label: String { Self.clockText(secondsRemaining) }

    static func clockText(_ seconds: Int) -> String {
        Duration.seconds(max(0, seconds)).formatted(.time(pattern: .minuteSecond))
    }

    /// The rest a set of this exercise starts: the length last set for it with
    /// −30 / +30, else the global default. Never under 15 s.
    func restSeconds(for exerciseID: UUID?) -> Int {
        let saved = exerciseID.flatMap { restByExercise[$0.uuidString] }
        let fallback = defaults.object(forKey: Self.defaultRestKey) as? Int ?? 120
        return max(15, saved ?? fallback)
    }

    /// −30 / +30 from the rest bar or the Lock Screen. The new length is kept
    /// for the exercise whose set started this rest (2026-10-24; it used to
    /// change every later rest).
    func adjustAndRemember(by delta: Int) {
        if isRunning { resumeFromBackground() }
        guard isRunning, delta > 0 || secondsRemaining > 15 else { return }
        adjust(by: delta, minimumSeconds: 15)
        guard let sourceExerciseID else { return }
        var saved = restByExercise
        saved[sourceExerciseID.uuidString] = max(15, totalDuration)
        defaults.set(saved, forKey: Self.restByExerciseKey)
    }

    private var restByExercise: [String: Int] {
        defaults.dictionary(forKey: Self.restByExerciseKey) as? [String: Int] ?? [:]
    }

    func start(totalSeconds: Int, upNext: String? = nil, upNextDetail: String? = nil,
               sourceEntryID: UUID? = nil, sourceExerciseID: UUID? = nil) {
        task?.cancel()
        task = nil
        finishedAt = nil
        self.sourceEntryID = sourceEntryID
        self.sourceExerciseID = sourceExerciseID
        notificationIssue = nil
        totalDuration = max(15, totalSeconds)
        secondsRemaining = totalDuration
        let start = now()
        startDate = start
        endDate = start.addingTimeInterval(TimeInterval(totalDuration))
        self.upNext = upNext
        self.upNextDetail = upNextDetail
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
    func updateUpNext(_ text: String?, detail: String? = nil) {
        guard upNext != text || upNextDetail != detail else { return }
        upNext = text
        upNextDetail = detail
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
        sourceExerciseID = nil
        upNext = nil
        upNextDetail = nil
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
        upNextDetail = nil
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
        sourceExerciseID = defaults.string(forKey: Self.sourceExerciseIDKey).flatMap(UUID.init(uuidString:))
        finishedAt = defaults.object(forKey: Self.finishedAtKey) as? Date
        var recoveredEnd = defaults.object(forKey: Self.endDateKey) as? Date
        var recoveredTotal = defaults.integer(forKey: Self.totalDurationKey)
        var recoveredStart: Date?
        var recoveredUpNext = defaults.string(forKey: Self.upNextKey)
        var recoveredUpNextDetail = defaults.string(forKey: Self.upNextDetailKey)

        if usesLiveActivities, let liveActivity = Activity<RestTimerAttributes>.activities.first {
            let state = liveActivity.content.state
            if recoveredEnd == nil, finishedAt == nil {
                recoveredEnd = state.endDate
                recoveredTotal = max(15, Int(ceil(state.endDate.timeIntervalSince(state.startDate))))
            }
            recoveredStart = state.startDate
            recoveredUpNext = recoveredUpNext ?? state.upNext
            recoveredUpNextDetail = recoveredUpNextDetail ?? state.upNextDetail
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
        upNextDetail = recoveredUpNextDetail
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
        defaults.set(upNextDetail, forKey: Self.upNextDetailKey)
        defaults.set(finishedAt, forKey: Self.finishedAtKey)
        defaults.set(sourceEntryID?.uuidString, forKey: Self.sourceEntryIDKey)
        defaults.set(sourceExerciseID?.uuidString, forKey: Self.sourceExerciseIDKey)
    }

    private func clearPersistedState() {
        for key in [Self.endDateKey, Self.totalDurationKey, Self.upNextKey, Self.upNextDetailKey,
                    Self.finishedAtKey, Self.sourceEntryIDKey, Self.sourceExerciseIDKey] {
            defaults.removeObject(forKey: key)
        }
    }

    private func scheduleCompletionNotification() {
        cancelCompletionNotification()
        guard let deadline = endDate, isRunning, deadline > now() else { return }
        if usesLiveActivities { enableForegroundAlerts() }
        let identifier = Self.notificationPrefix + UUID().uuidString
        let next = [upNext, upNextDetail].compactMap { $0 }.joined(separator: " · ")
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
            content.title = AppCopy.Workout.restFinishedInline
            content.body = next.isEmpty ? "Start your next set." : "Next: \(next)"
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
            state: RestTimerAttributes.ContentState(startDate: startDate, endDate: endDate,
                                                    upNext: upNext, upNextDetail: upNextDetail),
            staleDate: endDate,
            relevanceScore: 100
        )
        activity = try? Activity<RestTimerAttributes>.request(attributes: RestTimerAttributes(), content: content, pushType: nil)
    }

    private func updateActivity() {
        guard usesLiveActivities, let endDate, let startDate else { return }
        let content = ActivityContent(
            state: RestTimerAttributes.ContentState(startDate: startDate, endDate: endDate,
                                                    upNext: upNext, upNextDetail: upNextDetail),
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
