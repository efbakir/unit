//
//  TodayView.swift
//  Unit
//
//  Today: template-first dashboard — next workout, freestyle, or resume.
//

import SwiftUI
import SwiftData

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
    let id = UUID()
    let exerciseName: String
    let displayTarget: String
    let lastPerformanceLabel: String?
    /// True when `displayTarget` is empty-state copy (not a reps/sets metric).
    let isEmptyHint: Bool

    init(
        exerciseName: String,
        displayTarget: String,
        lastPerformanceLabel: String?,
        isEmptyHint: Bool = false
    ) {
        self.exerciseName = exerciseName
        self.displayTarget = displayTarget
        self.lastPerformanceLabel = lastPerformanceLabel
        self.isEmptyHint = isEmptyHint
    }
}

struct ReadyTodayContext {
    let templateId: UUID
    let programName: String
    let templateName: String
    /// Shown when the user picked a different routine than the scheduled one for today.
    let scheduleNote: String?
    let lastPerformedLabel: String?
    let previewTargets: [ExerciseTarget]
    let lastSessionDate: Date?
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

    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplitIdString: String = ""

    @State private var viewModel = TodayDashboardViewModel()
    @State private var showsHistory = false
    @State private var completedSessionDetail: WorkoutSession?
    @State private var staleSessionPrompt: WorkoutSession?
    @State private var toastMessage: String?
    @State private var showsRoutinePickSheet = false
    /// Bumps when override storage changes so `dashboardState` recomputes.
    @State private var routinePickRefresh = 0

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let session = activeSession {
                    ActiveWorkoutView(session: session)
                } else {
                    dashboardContent
                }
            }
            .navigationDestination(isPresented: $showsHistory) {
                RecentSessionsView(showsCloseButton: true)
            }
            .navigationDestination(isPresented: Binding(
                get: { completedSessionDetail != nil },
                set: { if !$0 { completedSessionDetail = nil } }
            )) {
                if let session = completedSessionDetail {
                    let templateName = templates.first(where: { $0.id == session.templateId })?.name ?? "Workout"
                    SessionDetailView(session: session, templateName: templateName)
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
                // Only show summary for the session that was just finished — not any older
                // completed workout (cancel deletes the session, so there is no match).
                let previousId = previous.id
                if let match = sessions.first(where: { $0.id == previousId && $0.isCompleted }) {
                    completedSessionDetail = match
                }
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
            .appToast(message: $toastMessage)
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
            showsNativeNavigationBar: true,
            usesOuterScroll: false
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
                    Button {
                        showsRoutinePickSheet = true
                    } label: {
                        Label("Choose today's routine", systemImage: AppIcon.list.systemName)
                            .labelStyle(.iconOnly)
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppCopy.Nav.history) {
                    showsHistory = true
                }
                .appToolbarTextStyle()
            }
        }
        .sheet(isPresented: $showsRoutinePickSheet) {
            routinePickSheet
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .appNavigationBarChrome()
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
                Color.clear
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
            EmptyStateCard(
                eyebrow: "Up next",
                title: context.templateName,
                message: context.programName,
                note: context.scheduleNote,
                buttonLabel: AppCopy.Workout.startWorkout,
                action: {
                    startWorkout(templateId: context.templateId)
                }
            ) {
                if !context.previewTargets.isEmpty {
                    PreviewListContainer {
                        ForEach(Array(context.previewTargets.enumerated()), id: \.offset) { _, target in
                            PreviewListRow(
                                title: target.exerciseName,
                                subtitle: target.displayTarget,
                                trailingLabel: target.lastPerformanceLabel,
                                isEmptyHint: target.isEmptyHint
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
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

    private func startWorkout(_ template: DayTemplate) {
        template.startWorkoutSession(in: modelContext)
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
            modelContext.delete(session)
            try? modelContext.save()
            toastMessage = AppCopy.Session.staleEmptyDiscardedToast
            return
        }

        // Sessions with logged work require explicit Save / Discard.
        staleSessionPrompt = session
    }

    private func saveStaleSession(_ session: WorkoutSession) {
        session.isCompleted = true
        try? modelContext.save()
        // Land on SessionDetailView via the existing completedSessionDetail path.
        completedSessionDetail = session
    }

    private func discardStaleSession(_ session: WorkoutSession) {
        modelContext.delete(session)
        try? modelContext.save()
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

        let lastDate = lastCompletedDate(for: template.id, sessions: sessions)
        let lastLabel: String? = lastDate.map { date in
            let days = Calendar.current.dateComponents([.day], from: Calendar.current.startOfDay(for: date), to: Calendar.current.startOfDay(for: Date())).day ?? 0
            switch days {
            case 0: return "Today"
            case 1: return "Yesterday"
            default: return "\(days) days ago"
            }
        }

        return .readyToday(
            ReadyTodayContext(
                templateId: template.id,
                programName: split.name,
                templateName: template.name,
                scheduleNote: scheduleNote,
                lastPerformedLabel: lastLabel,
                previewTargets: previewTargets,
                lastSessionDate: lastDate
            )
        )
    }

    func orderedTemplates(
        for split: Split,
        templates: [DayTemplate]
    ) -> [DayTemplate] {
        let splitTemplates = templates.filter { $0.splitId == split.id }
        let templateByID = Dictionary(uniqueKeysWithValues: splitTemplates.map { ($0.id, $0) })
        let ordered = split.orderedTemplateIds.compactMap { templateByID[$0] }
        return ordered.isEmpty ? splitTemplates.sorted { $0.name < $1.name } : ordered
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
                    exerciseName: exercise.displayName,
                    displayTarget: plannedTarget,
                    lastPerformanceLabel: nil,
                    isEmptyHint: false
                )
            }
            return ExerciseTarget(
                exerciseName: exercise.displayName,
                displayTarget: hasAnyCompleted
                    ? AppCopy.EmptyState.noPriorSets
                    : AppCopy.EmptyState.noHistoryYet,
                lastPerformanceLabel: nil,
                isEmptyHint: true
            )
        }

        // Ghost values: last completed working sets per exercise from any session (newest first).
        // Matches TemplateDetailView / ActiveWorkout prefill — not limited to this template.
        return template.orderedExerciseIds.compactMap { exerciseID in
            guard let exercise = exercises.first(where: { $0.id == exerciseID }) else {
                return nil
            }

            // Cold-start: planned target if onboarding set one, else explicit empty copy.
            guard let ghostSession = sessions.first(where: { session in
                session.isCompleted &&
                session.setEntries.contains(where: {
                    $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup
                })
            }) else {
                return emptyTarget(for: exercise)
            }

            let lastSets = ghostSession.setEntries
                .filter { $0.exerciseId == exerciseID && $0.isCompleted && !$0.isWarmup }
                .sorted { $0.setIndex < $1.setIndex }

            guard let representative = lastSets.last, representative.reps > 0 else {
                return emptyTarget(for: exercise)
            }

            if !exercise.isBodyweight, representative.weight <= 0 {
                return emptyTarget(for: exercise)
            }

            let setCount = max(lastSets.count, 1)
            let displayTarget = WorkoutTargetFormatter.setRepCompact(setCount: setCount, reps: representative.reps)
                ?? "\(representative.reps)"

            let lastPerformanceLabel: String
            if representative.weight > 0 {
                lastPerformanceLabel = "Last \(WorkoutTargetFormatter.weightCompact(representative.weight))"
            } else {
                lastPerformanceLabel = "Last BW"
            }

            return ExerciseTarget(
                exerciseName: exercise.displayName,
                displayTarget: displayTarget,
                lastPerformanceLabel: lastPerformanceLabel,
                isEmptyHint: false
            )
        }
    }

    private func lastCompletedDate(for templateID: UUID, sessions: [WorkoutSession]) -> Date? {
        sessions.first { $0.isCompleted && $0.templateId == templateID }?.date
    }

    private func plannedTargetText(template: DayTemplate, exerciseID: UUID) -> String? {
        guard let sets = template.plannedSets(for: exerciseID), sets > 0,
              let reps = template.plannedReps(for: exerciseID), reps > 0 else {
            return nil
        }
        return WorkoutTargetFormatter.setRepCompact(setCount: sets, reps: reps)
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
                    .font(AppFont.productAction.font)
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
