//
//  TodayView.swift
//  Unit
//
//  Today: template-first dashboard — next workout, freestyle, or resume.
//

import SwiftUI
import SwiftData
import StoreKit

// MARK: - Dashboard state

enum TodayDashboardState {
    case noProgram
    case setupIncomplete(SetupIncompleteContext)
    case readyToday(ReadyTodayContext)
    case restDay(RestDayContext)
}

struct RestDayContext {
    let programName: String
}

struct ExerciseTarget: Identifiable {
    let id: UUID
    let exerciseName: String
    let displayTarget: String
    let supportingText: String?
    /// True when `displayTarget` is empty-state copy (not a reps/sets metric).
    let isEmptyHint: Bool

    init(
        id: UUID,
        exerciseName: String,
        displayTarget: String,
        supportingText: String? = nil,
        isEmptyHint: Bool = false
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.displayTarget = displayTarget
        self.supportingText = supportingText
        self.isEmptyHint = isEmptyHint
    }
}

struct ReadyTodayContext {
    let templateId: UUID
    let programName: String
    let templateName: String
    /// Shown when the user picked a different routine than the scheduled one for today.
    let scheduleNote: String?
    let previewTargets: [ExerciseTarget]
}

struct SetupIncompleteContext {
    let eyebrow: String
    let title: String
    let message: String
}

// MARK: - TodayView

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTabSelection) private var appTabSelection
    @Environment(\.requestReview) private var requestReview
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplitIdString: String = ""

    @State private var viewModel = TodayDashboardViewModel()
    @State private var showsHistory = false
    @State private var completionMoment: AppCelebrationMoment?
    @State private var launchSessionID: UUID?
    @State private var celebratedSessionIDs: Set<UUID> = []
    @State private var completedSessionDetail: WorkoutSession?
    @State private var showsCompletedSessionDetail = false
    @State private var staleSessionPrompt: WorkoutSession?
    @State private var toastMessage: AppToastEvent?
    @State private var showsRoutinePickSheet = false
    @State private var targetEdit: RoutineTargetEdit?
    @State private var reviewRequestTask: Task<Void, Never>?
    @State private var reviewRequestAttemptedForUITest = false
    /// Bumps when override storage changes so `dashboardState` recomputes.
    @State private var routinePickRefresh = 0

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let session = activeSession {
                    ActiveWorkoutView(session: session) { completedSession in
                        presentCompletedSession(completedSession, celebrates: true)
                    }
                    .transition(AppBlurTransition(scales: launchSessionID != nil).animation(launchAnimation))
                    .zIndex(1)
                } else {
                    dashboardContent
                        .transition(.opacity.animation(AppMotion.feedback))
                        .allowsHitTesting(activeSession == nil)
                }
            }
            .animation(launchAnimation, value: activeSession?.id)
            .appHaptic(.firm, trigger: launchSessionID) { _, new in new != nil }
            .navigationDestination(isPresented: $showsHistory) {
                RecentSessionsView(showsCloseButton: true)
            }
            .navigationDestination(for: DayTemplate.self) { template in
                TemplateDetailView(template: template)
            }
            .navigationDestination(isPresented: $showsCompletedSessionDetail) {
                if let session = completedSessionDetail {
                    let templateName = templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                    SessionDetailView(session: session, templateName: templateName, completionMoment: completionMoment)
                }
            }
            .tint(AppColor.accent)
            .onAppear {
                checkStaleSession()
                FreestyleSessionSupport.cleanupOrphanedTemplates(
                    modelContext: modelContext,
                    templates: templates,
                    sessions: sessions
                )
            }
            .onChange(of: activeSession) { oldValue, newValue in
                guard let previous = oldValue, newValue == nil else { return }
                launchSessionID = nil
                // Only show summary for the session that was just finished — not any older
                // completed workout (cancel deletes the session, so there is no match).
                let previousId = previous.id
                if let match = sessions.first(where: { $0.id == previousId && $0.isCompleted }) {
                    presentCompletedSession(match)
                }
            }
            .onChange(of: showsCompletedSessionDetail) { oldValue, newValue in
                guard oldValue, !newValue else { return }
                completedSessionDetail = nil
                completionMoment = nil
                scheduleReviewRequestIfNeeded()
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                scheduleReviewRequestIfNeeded()
            }
            .onDisappear {
                reviewRequestTask?.cancel()
                reviewRequestTask = nil
            }
            .alert(
                AppCopy.Session.staleSessionTitle,
                isPresented: Binding(
                    get: { staleSessionPrompt != nil },
                    set: { if !$0 { staleSessionPrompt = nil } }
                ),
                presenting: staleSessionPrompt
            ) { session in
                Button(AppCopy.Workout.continueWorkout, role: .cancel) {
                    staleSessionPrompt = nil
                }
                Button(AppCopy.Session.markComplete) {
                    saveStaleSession(session)
                }
                Button(AppCopy.Session.discard, role: .destructive) {
                    discardStaleSession(session)
                }
            } message: { _ in
                Text(AppCopy.Session.staleSessionMessage)
            }
            .appToast(event: $toastMessage)
            .overlay(alignment: .topLeading) {
                if CommandLine.arguments.contains("-ui-testing"),
                   reviewRequestAttemptedForUITest {
                    Text("Review request armed")
                        .frame(width: 1, height: 1)
                        .opacity(0.01)
                        .accessibilityIdentifier("review-request-armed")
                }
            }
        }
    }

    private var dashboardContent: some View {
        let _ = routinePickRefresh
        let state = viewModel.dashboardState(
            sessions: sessions,
            templates: templates,
            splits: splits,
            exercises: exercises
        )

        return AppScreen(
            primaryButton: dashboardPrimaryButton(for: state),
            showsNativeNavigationBar: true
        ) {
            // Hero: Up Next / Rest Day / Empty state — always the first, most
            // prominent surface on screen (compass: Today → Start in ≤ 2 taps).
            stateCard(for: state)
        }
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if routinePickerAllowed(for: state) {
                ToolbarItem(placement: .topBarLeading) {
                    Group {
                        Button {
                            showsRoutinePickSheet = true
                        } label: {
                            Label("Choose today's routine", systemImage: AppIcon.list.systemName)
                                .labelStyle(.iconOnly)
                        }
                    }
                    .tint(AppColor.textPrimary)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    Button(AppCopy.Nav.history) {
                        showsHistory = true
                    }
                    .appToolbarTextStyle()
                }
                .tint(AppColor.textPrimary)
            }
        }
        .sheet(item: $targetEdit) { target in
            AppSetRepEditorSheet(
                subject: target.exerciseName,
                initialSets: target.setCount,
                initialReps: target.reps,
                initialProgression: target.progression
            ) { sets, reps, progression in
                guard let template = templates.first(where: { $0.id == target.templateID }),
                      template.orderedExerciseIds.contains(target.exerciseID) else { return false }
                template.applyTarget(setCount: sets, reps: reps, progression: progression,
                                     for: target.exerciseID, sessions: sessions)
                do {
                    try modelContext.save()
                    return true
                } catch {
                    modelContext.rollbackRestoringLoadedModels()
                    AppHaptic.error.fire()
                    return false
                }
            }
        }
        .sheet(isPresented: $showsRoutinePickSheet) {
            routinePickSheet
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .appNavigationBarChrome()
    }

    private func dashboardPrimaryButton(for state: TodayDashboardState) -> PrimaryButtonConfig? {
        guard case .readyToday(let context) = state else { return nil }
        return PrimaryButtonConfig(label: AppCopy.Workout.startWorkout) {
            startWorkout(templateId: context.templateId)
        }
    }

    private func routinePickerAllowed(for state: TodayDashboardState) -> Bool {
        switch state {
        case .readyToday, .restDay:
            guard let split = ActiveSplitStore.resolve(from: splits) else { return false }
            let ordered = viewModel.orderedTemplates(for: split, templates: templates)
            return !ordered.isEmpty
        case .noProgram, .setupIncomplete:
            return false
        }
    }

    private var routinePickSheet: some View {
        Group {
            if let split = ActiveSplitStore.resolve(from: splits) {
                let ordered = viewModel.orderedTemplates(for: split, templates: templates)
                let hasSchedule = ordered.contains { $0.scheduledWeekday > 0 }
                let hasOverride = TodayRoutineOverride.effectiveTemplateId(orderedTemplateIds: ordered.map(\.id)) != nil
                TodayRoutinePickSheet(
                    orderedTemplates: ordered,
                    hasWeeklySchedule: hasSchedule,
                    todayWeekday: Calendar.current.component(.weekday, from: Date()),
                    hasActiveOverride: hasOverride,
                    onSelect: { id in
                        TodayRoutineOverride.set(templateId: id)
                        routinePickRefresh += 1
                        showsRoutinePickSheet = false
                    },
                    onUseDefault: {
                        TodayRoutineOverride.clear()
                        routinePickRefresh += 1
                        showsRoutinePickSheet = false
                    }
                )
            } else {
                AppColor.clear
                    .task { showsRoutinePickSheet = false }
            }
        }
    }

    @ViewBuilder
    private func stateCard(for state: TodayDashboardState) -> some View {
        switch state {
        case .noProgram:
            EmptyStateCard(
                title: AppCopy.Today.noProgramTitle,
                buttonLabel: AppCopy.Today.noProgramCTA
            ) {
                appTabSelection(.program)
            }

        case .setupIncomplete(let context):
            EmptyStateCard(
                eyebrow: context.eyebrow,
                title: context.title,
                message: context.message,
                buttonLabel: "Continue setup"
            ) {
                appTabSelection(.program)
            }

        case .readyToday(let context):
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("Up next")
                        .appFont(.muted)
                        .foregroundStyle(AppColor.textSecondary)
                    Text(context.templateName)
                        .appFont(.analyticsStatus)
                        .foregroundStyle(AppColor.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(context.programName)
                        .appFont(.caption)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let note = context.scheduleNote {
                        Text(note)
                            .appFont(.muted)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if let template = templates.first(where: { $0.id == context.templateId }) {
                    AppCardList(context.previewTargets, rowVerticalInset: AppSpacing.sm) { target in
                        Button {
                            guard let exercise = exercises.first(where: { $0.id == target.id }) else { return }
                            targetEdit = template.targetEdit(for: exercise, sessions: sessions,
                                defaultSets: AppSetRepEditorSheet.defaultSets,
                                defaultReps: AppSetRepEditorSheet.defaultReps)
                        } label: {
                            PreviewListRow(
                                title: target.exerciseName,
                                subtitle: target.displayTarget,
                                supportingText: target.supportingText,
                                isEmptyHint: target.isEmptyHint,
                                showsDisclosure: true
                            )
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityHint("Opens exercise target.")
                    }
                }
            }

        case .restDay(let context):
            EmptyStateCard(
                title: AppCopy.Today.restDayTitle,
                message: context.programName,
                buttonLabel: AppCopy.Today.restDayCTA
            ) {
                showsRoutinePickSheet = true
            }
        }
    }

    private func startWorkout(templateId: UUID) {
        guard let template = templates.first(where: { $0.id == templateId }) else { return }
        startWorkout(template)
    }

    private var launchAnimation: Animation? {
        guard launchSessionID != nil else { return nil }
        return AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver)
            ? AppMotion.settle : AppMotion.reveal
    }

    private func startWorkout(_ template: DayTemplate) {
        guard activeSession == nil else { return }
        // Save immediately. The launch accompanies the new session; it never
        // holds the first set behind a timer or replays when resuming the app.
        let session = template.startWorkoutSession(in: modelContext)
        guard !modelContext.hasChanges else {
            modelContext.rollbackRestoringLoadedModels()
            AppHaptic.error.fire()
            toastMessage = .init("Couldn't save workout. Your previous data is unchanged. Try again.", kind: .error)
            return
        }
        launchSessionID = session.id
    }

    private func checkStaleSession() {
        guard let session = activeSession else { return }

        // Hybrid stale check: prompt only when the session is on a previous
        // calendar day AND at least 4 hours have elapsed. Either signal alone
        // misfires — a 24-hr threshold mid-session prompts a long Tuesday rest;
        // a pure calendar-day check prompts at midnight on a session that just
        // crossed over. Both together lets a workout that runs into the next
        // morning finish naturally, while still catching yesterday's open
        // session the moment the lifter returns.
        let calendar = Calendar.current
        let staleHourThreshold: TimeInterval = 4 * 60 * 60
        let isPreviousDay = !calendar.isDateInToday(session.date)
        let isOldEnough = Date().timeIntervalSince(session.date) > staleHourThreshold
        guard isPreviousDay && isOldEnough else { return }

        // Auto-discard truly empty sessions; surface a toast so the user knows.
        let hasLoggedSets = session.setEntries.contains(where: { $0.isCompleted })
        if !hasLoggedSets {
            templates.first(where: { $0.id == session.templateId })?
                .restoreLastPerformedDate(removing: session, sessions: sessions)
            modelContext.delete(session)
            guard persistSessionChange() else { return }
            toastMessage = .init(AppCopy.Session.staleEmptyDiscardedToast)
            return
        }

        // Sessions with logged work require explicit Save / Discard.
        staleSessionPrompt = session
    }

    private func saveStaleSession(_ session: WorkoutSession) {
        session.isCompleted = true
        if let template = templates.first(where: { $0.id == session.templateId }) {
            session.captureProgressionRecords(
                template: template,
                exercises: exercises
            )
        }
        guard persistSessionChange() else { return }
        EngagementPromptTracker().recordCompletedWorkout(sessionID: session.id)
        presentCompletedSession(session, celebrates: true)
    }

    private func presentCompletedSession(_ session: WorkoutSession, celebrates: Bool = false) {
        // Only the successful-save callback produces an event. The query observer
        // can arrive before or after it, and history/relaunch never creates one.
        if celebrates, celebratedSessionIDs.insert(session.id).inserted {
            AppHaptic.success.fire()
            completionMoment = AppCelebrationMoment(
                style: sessions.filter(\.isCompleted).count <= 1 ? .shower : .popper,
                id: session.id
            )
        }
        completedSessionDetail = session
        guard !showsCompletedSessionDetail else { return }
        // The active-workout branch disappears when `isCompleted` changes.
        // Present on the next main-actor turn so NavigationStack receives the
        // destination after its Today content has settled.
        Task { @MainActor in
            await Task.yield()
            showsCompletedSessionDetail = true
        }
    }

    private func scheduleReviewRequestIfNeeded() {
        let tracker = EngagementPromptTracker()
        guard tracker.shouldRequestReview,
              activeSession == nil,
              !showsCompletedSessionDetail,
              scenePhase == .active,
              reviewRequestTask == nil else { return }

        reviewRequestTask = Task { @MainActor in
            defer { reviewRequestTask = nil }
            try? await Task.sleep(for: .seconds(2))
            guard !Task.isCancelled,
                  activeSession == nil,
                  !showsCompletedSessionDetail,
                  scenePhase == .active else { return }

            let currentTracker = EngagementPromptTracker()
            guard currentTracker.shouldRequestReview else { return }
            currentTracker.markReviewRequestAttempted()
            reviewRequestAttemptedForUITest = true

            // StoreKit review UI is intentionally suppressed in UI automation.
            // The durable attempt flag still lets the test verify the policy.
            guard !CommandLine.arguments.contains("-ui-testing") else { return }
            requestReview()
        }
    }

    private func discardStaleSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        _ = persistSessionChange()
    }

    private func persistSessionChange() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.processPendingChanges()
            modelContext.rollbackRestoringLoadedModels()
            AppHaptic.error.fire()
            toastMessage = .init("Couldn't save workout. Your previous data is unchanged. Try again.", kind: .error)
            return false
        }
    }

}

// MARK: - View Model

@MainActor
@Observable
final class TodayDashboardViewModel {
    /// Nonisolated for the same back-deploy-shim SIGABRT as
    /// `ActiveWorkoutViewModel.deinit` — see the comment there.
    nonisolated deinit {}

    func dashboardState(
        sessions: [WorkoutSession],
        templates: [DayTemplate],
        splits: [Split],
        exercises: [Exercise]
    ) -> TodayDashboardState {
        guard let split = ActiveSplitStore.resolve(from: splits) else { return .noProgram }

        let orderedTemplates = orderedTemplates(for: split, templates: templates)
        let orderedIds = orderedTemplates.map(\.id)
        let todayOverrideTemplateId = TodayRoutineOverride.effectiveTemplateId(orderedTemplateIds: orderedIds)

        guard !orderedTemplates.isEmpty else {
            return .setupIncomplete(
                SetupIncompleteContext(
                    eyebrow: "Programs",
                    title: "No routines yet",
                    message: "Add one to start logging."
                )
            )
        }

        // Weekday-aware scheduling when templates have scheduledWeekday set
        let hasSchedule = orderedTemplates.contains { $0.scheduledWeekday > 0 }
        if hasSchedule {
            return scheduledDashboardState(
                split: split,
                orderedTemplates: orderedTemplates,
                templates: templates,
                sessions: sessions,
                exercises: exercises,
                todayOverrideTemplateId: todayOverrideTemplateId
            )
        }

        // Legacy rotation: pick template with oldest lastPerformedDate.
        // If any template in the rotation was already completed today, treat
        // today as a rest day (matches scheduledDashboardState behaviour).
        let calendar = Calendar.current

        if let overrideId = todayOverrideTemplateId,
           let picked = orderedTemplates.first(where: { $0.id == overrideId }) {
            // Explicit user pick — honor it even if already completed today.
            return stateForTemplate(
                picked,
                split: split,
                templates: templates,
                sessions: sessions,
                exercises: exercises,
                scheduleNote: "Different routine for today"
            )
        }

        let completedTodayInRotation = orderedTemplates.contains { template in
            sessions.contains { session in
                session.templateId == template.id &&
                session.isCompleted &&
                calendar.isDateInToday(session.date)
            }
        }
        if completedTodayInRotation {
            return .restDay(RestDayContext(programName: split.name))
        }

        guard let nextTemplate = orderedTemplates
            .sorted(by: { ($0.lastPerformedDate ?? .distantPast) < ($1.lastPerformedDate ?? .distantPast) })
            .first else { return .noProgram }

        return stateForTemplate(
            nextTemplate,
            split: split,
            templates: templates,
            sessions: sessions,
            exercises: exercises,
            scheduleNote: nil
        )
    }

    private func scheduledDashboardState(
        split: Split,
        orderedTemplates: [DayTemplate],
        templates: [DayTemplate],
        sessions: [WorkoutSession],
        exercises: [Exercise],
        todayOverrideTemplateId: UUID?
    ) -> TodayDashboardState {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        let scheduledTemplate = orderedTemplates.first { $0.scheduledWeekday == todayWeekday }

        let activeTemplate: DayTemplate? = {
            if let oid = todayOverrideTemplateId,
               let picked = orderedTemplates.first(where: { $0.id == oid }) {
                return picked
            }
            return scheduledTemplate
        }()

        guard let template = activeTemplate else {
            return .restDay(RestDayContext(programName: split.name))
        }

        // Skip the completed-today guard when the user explicitly picked this
        // routine — the override is a "yes I want to do this" signal.
        let isExplicitOverride = todayOverrideTemplateId == template.id
        if !isExplicitOverride {
            let completedToday = sessions.contains { session in
                session.templateId == template.id &&
                session.isCompleted &&
                calendar.isDateInToday(session.date)
            }
            if completedToday {
                return .restDay(RestDayContext(programName: split.name))
            }
        }

        let note = scheduleOverrideNote(
            scheduledTemplate: scheduledTemplate,
            activeTemplate: template,
            todayOverrideTemplateId: todayOverrideTemplateId
        )

        return stateForTemplate(
            template,
            split: split,
            templates: templates,
            sessions: sessions,
            exercises: exercises,
            scheduleNote: note
        )
    }

    private func scheduleOverrideNote(
        scheduledTemplate: DayTemplate?,
        activeTemplate: DayTemplate,
        todayOverrideTemplateId: UUID?
    ) -> String? {
        guard todayOverrideTemplateId != nil else { return nil }
        if let scheduled = scheduledTemplate, scheduled.id != activeTemplate.id {
            return "Usually \(scheduled.displayName) today"
        }
        if scheduledTemplate == nil {
            return "Not in your weekly plan"
        }
        return nil
    }

    private func stateForTemplate(
        _ template: DayTemplate,
        split: Split,
        templates: [DayTemplate],
        sessions: [WorkoutSession],
        exercises: [Exercise],
        scheduleNote: String?
    ) -> TodayDashboardState {
        if template.orderedExerciseIds.isEmpty {
            return .setupIncomplete(
                SetupIncompleteContext(
                    eyebrow: split.name,
                    title: template.displayName,
                    message: "Add exercises to start this workout."
                )
            )
        }

        let previewTargets = exercisePreviews(
            for: template,
            sessions: sessions,
            exercises: exercises
        )

        guard !previewTargets.isEmpty else {
            return .setupIncomplete(
                SetupIncompleteContext(
                    eyebrow: split.name,
                    title: template.displayName,
                    message: "Add exercises to see targets here."
                )
            )
        }

        return .readyToday(
            ReadyTodayContext(
                templateId: template.id,
                programName: split.name,
                templateName: template.displayName,
                scheduleNote: scheduleNote,
                previewTargets: previewTargets
            )
        )
    }

    func orderedTemplates(
        for split: Split,
        templates: [DayTemplate]
    ) -> [DayTemplate] {
        let splitTemplates = templates.filter { $0.splitId == split.id }
        let templateByID = Dictionary.firstUniqueKeys(splitTemplates.map { ($0.id, $0) })
        let ordered = split.orderedTemplateIds.compactMap { templateByID[$0] }
        let orderedIDs = Set(ordered.map(\.id))
        return ordered + splitTemplates.filter { !orderedIDs.contains($0.id) }
            .sorted { $0.name < $1.name }
    }

    private func exercisePreviews(
        for template: DayTemplate,
        sessions: [WorkoutSession],
        exercises: [Exercise]
    ) -> [ExerciseTarget] {
        let hasAnyCompleted = sessions.contains(where: \.isCompleted)

        func emptyTarget(for exercise: Exercise) -> ExerciseTarget {
            if let plannedTarget = plannedTargetText(template: template, exerciseID: exercise.id) {
                return ExerciseTarget(
                    id: exercise.id,
                    exerciseName: exercise.displayName,
                    displayTarget: plannedTarget,
                    isEmptyHint: false
                )
            }
            return ExerciseTarget(
                id: exercise.id,
                exerciseName: exercise.displayName,
                displayTarget: hasAnyCompleted
                    ? AppCopy.EmptyState.noPriorSets
                    : AppCopy.EmptyState.noHistoryYet,
                isEmptyHint: true
            )
        }

        // Ghost values: last completed working sets per exercise from any session (newest first).
        // Matches TemplateDetailView / ActiveWorkout prefill — not limited to this template.
        return template.orderedExerciseIds.compactMap { exerciseID in
            guard let exercise = exercises.first(where: { $0.id == exerciseID }) else {
                return nil
            }

            if let acceptedTarget = template.progressionState(for: exerciseID)?.acceptedTarget,
               let setCount = template.plannedSets(for: exerciseID),
               let displayTarget = WorkoutTargetFormatter.completeTargetText(
                   weightKg: acceptedTarget.weightKg,
                   setCount: setCount,
                   reps: acceptedTarget.reps
               ) {
                return ExerciseTarget(
                    id: exercise.id,
                    exerciseName: exercise.displayName,
                    displayTarget: displayTarget,
                    supportingText: lastTimePreviewText(
                        for: exercise,
                        sessions: sessions
                    ),
                    isEmptyHint: false
                )
            }

            // Cold-start: planned target if onboarding set one, else explicit empty copy.
            let lastSets = SetEntry.latestValidWorkingSets(for: exerciseID, in: sessions)
            guard let representative = lastSets.last else {
                return emptyTarget(for: exercise)
            }

            let setCount = max(lastSets.count, 1)
            // Same wording as History: "3 × 8 at 80 kg" keeps the weight.
            let displayTarget = WorkoutTargetFormatter.completedPerformanceText(
                weightsKg: lastSets.map(\.weight),
                reps: lastSets.map(\.reps),
                isBodyweight: exercise.isBodyweight
            )
                ?? WorkoutTargetFormatter.setRepDisplay(
                    setCount: setCount,
                    reps: representative.reps
                )
                ?? "\(representative.reps)"

            return ExerciseTarget(
                id: exercise.id,
                exerciseName: exercise.displayName,
                displayTarget: displayTarget,
                isEmptyHint: false
            )
        }
    }

    private func plannedTargetText(template: DayTemplate, exerciseID: UUID) -> String? {
        guard let sets = template.plannedSets(for: exerciseID), sets > 0,
              let reps = template.plannedReps(for: exerciseID), reps > 0 else {
            return nil
        }
        if let weightKg = template.plannedWeight(for: exerciseID),
           let completeTarget = WorkoutTargetFormatter.completeTargetText(
               weightKg: weightKg,
               setCount: sets,
               reps: reps
           ) {
            return completeTarget
        }
        return WorkoutTargetFormatter.setRepDisplay(setCount: sets, reps: reps)
    }

    private func lastTimePreviewText(
        for exercise: Exercise,
        sessions: [WorkoutSession]
    ) -> String? {
        let sets = SetEntry.latestValidWorkingSets(for: exercise.id, in: sessions)
        guard let performance = WorkoutTargetFormatter.completedPerformanceText(
            weightsKg: sets.map(\.weight),
            reps: sets.map(\.reps),
            isBodyweight: exercise.isBodyweight
        ) else {
            return nil
        }
        return "Last time · \(performance)"
    }
}

// MARK: - Today's routine picker

private struct TodayRoutinePickSheet: View {
    let orderedTemplates: [DayTemplate]
    let hasWeeklySchedule: Bool
    let todayWeekday: Int
    let hasActiveOverride: Bool
    let onSelect: (UUID) -> Void
    let onUseDefault: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppSheetScreen(
            title: "Today's routine",
            primaryButton: hasActiveOverride
                ? PrimaryButtonConfig(
                    label: hasWeeklySchedule ? "Use scheduled day" : "Use the next routine",
                    action: onUseDefault
                )
                : nil,
            dismissLabel: AppCopy.Nav.done,
            onDismissAction: { dismiss() }
        ) {
            AppCardList(data: orderedTemplates, id: \.id) { template in
                Button {
                    onSelect(template.id)
                } label: {
                    routineRow(for: template)
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel(routineRowAccessibilityLabel(for: template))
            }
        }
    }

    @ViewBuilder
    private func routineRow(for template: DayTemplate) -> some View {
        let isToday = hasWeeklySchedule && template.scheduledWeekday == todayWeekday

        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(template.displayName)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.leading)

                if template.scheduledWeekday > 0, let w = weekdayShort(template.scheduledWeekday) {
                    Text(w)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppFont.muted.color)
                }
            }

            Spacer(minLength: 0)

            if isToday {
                AppTag(text: "Today", style: .accent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }

    private func routineRowAccessibilityLabel(for template: DayTemplate) -> String {
        let isToday = hasWeeklySchedule && template.scheduledWeekday == todayWeekday
        if isToday { return "\(template.displayName), today" }
        return template.displayName
    }

    private func weekdayShort(_ weekday: Int) -> String? {
        guard weekday >= 1, weekday <= 7 else { return nil }
        return Calendar.current.shortWeekdaySymbols[weekday - 1]
    }
}

#Preview {
    TodayView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
