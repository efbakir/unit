//
//  HistoryView.swift
//  Unit
//
//  List-first recent sessions, grouped by month.
//

import SwiftUI
import SwiftData

enum SessionHistoryMode: String, CaseIterable, Identifiable {
    case list = "List"
    case calendar = "Calendar"

    var id: String { rawValue }
}

enum SessionHistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Completed"
    case partial = "Partial"
    case skipped = "Skipped"
    case missed = "Missed"

    var id: Self { self }
}

/// History-calendar day classification — review-only, no planning states.
private enum CalendarDayStatus: Equatable {
    case `default`
    case completed
    case missed
    case today
    case future

    var isTappable: Bool {
        self == .completed || self == .missed
    }
}

enum SessionReviewState: Equatable {
    case completed
    case partial
    case skipped

    var title: String {
        switch self {
        case .completed: return "Completed"
        case .partial: return "Partial"
        case .skipped: return "Skipped"
        }
    }

    var markerColor: Color {
        switch self {
        case .completed: return AppColor.accent
        case .partial: return AppColor.warning
        case .skipped: return AppColor.error
        }
    }

    var tagStyle: AppTag.Style {
        switch self {
        case .completed:
            return .success
        case .partial:
            return .warning
        case .skipped:
            return .error
        }
    }
}

struct SessionSetSnapshot: Identifiable {
    let id: UUID
    let setIndex: Int
    let actualWeight: Double
    let actualReps: Int
    let note: String
    /// At-log-time PR flag derived by `PRHistory` — this set beat the
    /// all-time best when it was logged, mirroring the live workout's
    /// accent-chip semantics.
    let isPR: Bool
}

struct SessionExerciseSnapshot: Identifiable {
    let id: UUID
    let name: String
    let isBodyweight: Bool
    let sets: [SessionSetSnapshot]

    var hasPR: Bool {
        sets.contains { $0.isPR }
    }

    /// Exercise summary via `WorkoutTargetFormatter` compact `setxrepxkg` style.
    var previewPerformanceText: String? {
        guard let representativeSet = sets.first else { return nil }
        return WorkoutTargetFormatter.actualText(
            weightKg: representativeSet.actualWeight,
            setCount: max(sets.count, 1),
            reps: representativeSet.actualReps,
            isBodyweight: isBodyweight
        )
    }
}

struct SessionSnapshot: Identifiable {
    let id: UUID
    let date: Date
    let templateName: String
    let state: SessionReviewState
    let exercises: [SessionExerciseSnapshot]
    let contextNote: String?

    var completedExerciseCount: Int {
        exercises.count
    }

    var setCount: Int {
        exercises.reduce(0) { $0 + $1.sets.count }
    }

    var hasPR: Bool {
        exercises.contains { $0.hasPR }
    }

    /// Short caption showing total exercise count, e.g. “6 exercises”.
    var compactExerciseHeadline: String? {
        guard completedExerciseCount > 0 else { return nil }
        return "\(completedExerciseCount) exercise\(completedExerciseCount == 1 ? "" : "s")"
    }
}

struct SelectedSessionsPayload: Identifiable {
    let id = UUID()
    let date: Date
    let sessions: [SessionSnapshot]
}

private struct CalendarDayCellModel: Identifiable {
    let date: Date
    let dayNumber: Int
    let isToday: Bool
    let isSelected: Bool
    let sessionCount: Int
    let status: CalendarDayStatus
    let sessions: [SessionSnapshot]

    var id: Date { date }
}

struct RecentSessionsView: View {
    let showsCloseButton: Bool
    let initialMode: SessionHistoryMode

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplitIdString: String = ""

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var mode: SessionHistoryMode
    @State private var filter: SessionHistoryFilter = .all
    @State private var displayMonth: Date = Calendar.current.startOfMonth(for: Date())
    @State private var selectedDate: Date?
    @State private var selectedPayload: SelectedSessionsPayload?

    private var historySessions: [WorkoutSession] {
        sessions.filter { session in
            session.isCompleted ||
            session.setEntries.contains(where: { $0.isCompleted }) ||
            (!session.isCompleted && session.setEntries.isEmpty && !Calendar.current.isDateInToday(session.date))
        }
    }

    private var templateNamesByID: [UUID: String] {
        Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0.displayName) })
    }

    private var exercisesByID: [UUID: Exercise] {
        Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0) })
    }

    private var sessionSnapshots: [SessionSnapshot] {
        // Derive once per render from the FULL session list — the PR baseline
        // must see every completed session, not just the filtered subset.
        let prIDs = PRHistory.prSetEntryIDs(in: sessions)
        return historySessions.compactMap { makeSnapshot(for: $0, prSetEntryIDs: prIDs) }
    }

    private var sessionsByDay: [Date: [SessionSnapshot]] {
        Dictionary(grouping: sessionSnapshots, by: { Calendar.current.startOfDay(for: $0.date) })
    }

    private var routineTemplateIDs: [UUID] {
        ActiveSplitStore.resolve(from: splits)?.orderedTemplateIds ?? []
    }

    private var scheduleStartDate: Date? {
        ActiveSplitStore.resolve(from: splits)?.createdAt
    }

    /// Weekdays (1=Sun … 7=Sat) the active split actually pins a routine to.
    /// Excludes 0 (rotation) so `isMissedTrainingDay` only flags days the
    /// lifter committed to. Empty for flexible-schedule splits — nothing is
    /// "missed" in rotation mode.
    private var scheduledWeekdays: Set<Int> {
        let templateByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let ordered = routineTemplateIDs.compactMap { templateByID[$0] }
        return Set(ordered.map(\.scheduledWeekday).filter { $0 > 0 })
    }

    private var selectedDaySessions: [SessionSnapshot] {
        guard let selectedDate else { return [] }
        return sessionsByDay[selectedDate] ?? []
    }

    /// Routines scheduled earlier this week that are still available — neutral copy, not a home-screen “missed” nudge.
    private var earlierWeekItems: [EarlierWeekRoutineInfo] {
        guard let split = ActiveSplitStore.resolve(from: splits) else { return [] }
        let ordered = EarlierWeekCatchup.orderedTemplates(for: split, templates: templates)
        guard ordered.contains(where: { $0.scheduledWeekday > 0 }) else { return [] }
        return EarlierWeekCatchup.incompleteItems(
            orderedTemplates: ordered,
            scheduleStartDate: split.createdAt,
            sessions: sessions
        )
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            Group {
                if sessionSnapshots.isEmpty, earlierWeekItems.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        AppSegmentedControl(
                            selection: $mode,
                            items: SessionHistoryMode.allCases,
                            title: { $0.rawValue }
                        )

                        Group {
                            if mode == .list {
                                listContent
                            } else {
                                calendarContent
                            }
                        }
                        .transition(.opacity)
                    }
                    .appAnimation(.appState, value: mode, reduceMotion: reduceMotion)
                    .appAnimation(.appState, value: filter, reduceMotion: reduceMotion)
                }
            }
            .appScreenEnter()
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedPayload, onDismiss: {
            selectedDate = nil
        }) { payload in
            SessionSummarySheet(payload: payload)
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .onChange(of: displayMonth) { _, _ in
            syncCalendarSelectionIfNeeded()
        }
    }

    private var emptyState: some View {
        EmptyStateCard(
            title: "No sessions yet",
            message: "Completed workouts show up here."
        )
    }

    private func startWorkout(for templateId: UUID) {
        guard let template = templates.first(where: { $0.id == templateId }) else { return }

        let session = WorkoutSession(
            date: Date(),
            templateId: template.id,
            isCompleted: false
        )

        modelContext.insert(session)
        template.lastPerformedDate = session.date
        try? modelContext.save()

        if showsCloseButton {
            dismiss()
        }
    }

    private var sortedDays: [(date: Date, sessions: [SessionSnapshot])] {
        sessionsByDay
            .map { (date: $0.key, sessions: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.date > $1.date }
    }

    private var filteredSortedDays: [(date: Date, sessions: [SessionSnapshot])] {
        guard filter != .missed else { return [] }
        return sortedDays.compactMap { day in
            let matches = day.sessions.filter { sessionMatchesFilter($0) }
            guard !matches.isEmpty else { return nil }
            return (date: day.date, sessions: matches)
        }
    }

    private func sessionMatchesFilter(_ snapshot: SessionSnapshot) -> Bool {
        switch filter {
        case .all: return true
        case .completed: return snapshot.state == .completed
        case .partial: return snapshot.state == .partial
        case .skipped: return snapshot.state == .skipped
        case .missed: return false
        }
    }

    private var showsMissedInList: Bool {
        (filter == .all || filter == .missed) && !earlierWeekItems.isEmpty
    }

    /// Month-bucketed sessions, preserving the descending-date order from `filteredSortedDays`.
    private var monthSections: [(month: Date, sessions: [SessionSnapshot])] {
        let calendar = Calendar.current
        var buckets: [Date: [SessionSnapshot]] = [:]
        var order: [Date] = []
        for day in filteredSortedDays {
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: day.date)) ?? day.date
            if buckets[monthStart] == nil { order.append(monthStart) }
            buckets[monthStart, default: []].append(contentsOf: day.sessions)
        }
        return order.map { (month: $0, sessions: buckets[$0] ?? []) }
    }

    private var listContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            historyFilterChips

            if filteredSortedDays.isEmpty && !showsMissedInList {
                filteredEmptyState
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if showsMissedInList {
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text("This week")
                                .appCapsLabel(.smallLabel)
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, AppSpacing.xs)

                            ForEach(earlierWeekItems) { info in
                                EarlierWeekRoutineRow(info: info) {
                                    startWorkout(for: info.templateId)
                                }
                            }
                        }
                    }

                    ForEach(monthSections, id: \.month) { section in
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            Text(monthLabel(for: section.month))
                                .appCapsLabel(.smallLabel)
                                .foregroundStyle(AppColor.textSecondary)
                                .padding(.horizontal, AppSpacing.xs)

                            AppCardList(section.sessions) { snapshot in
                                Button {
                                    selectedPayload = SelectedSessionsPayload(date: snapshot.date, sessions: [snapshot])
                                } label: {
                                    historySessionRow(for: snapshot)
                                }
                                .accessibilityIdentifier("history-session-row")
                                .buttonStyle(ScaleButtonStyle())
                            }
                        }
                    }
                }
            }
        }
    }

    private func monthLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }

    @ViewBuilder
    private func historySessionRow(for snapshot: SessionSnapshot) -> some View {
        AppSessionHighlightRow(
            eyebrow: snapshot.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
            title: snapshot.templateName,
            caption: snapshot.compactExerciseHeadline
        ) {
            HStack(spacing: AppSpacing.xs) {
                if snapshot.hasPR {
                    historyPRTag()
                }
                AppTag(text: snapshot.state.title, style: snapshot.state.tagStyle, layout: .compactCapsule)
            }
        }
    }

    private var historyFilterChips: some View {
        AppFilterChipBar {
            ForEach(SessionHistoryFilter.allCases.filter { $0 == .completed || $0 == .missed }) { option in
                AppFilterChip(
                    label: option.rawValue,
                    isSelected: filter == option,
                    showsClearGlyphWhenSelected: true
                ) {
                    filter = (filter == option) ? .all : option
                }
            }
        }
    }

    private var filteredEmptyState: some View {
        AppEmptyHint("Nothing to show")
    }

    private var calendarContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    CalendarMonthHeader(displayMonth: $displayMonth)

                    CalendarGrid(
                        displayMonth: displayMonth,
                        sessionsByDay: sessionsByDay,
                        selectedDate: selectedDate,
                        routineTemplateIDs: routineTemplateIDs,
                        scheduledWeekdays: scheduledWeekdays,
                        scheduleStartDate: scheduleStartDate,
                        sessions: sessions,
                        onSelect: { day in
                            guard day.status.isTappable else { return }
                            selectedDate = day.date
                            let dayKey = Calendar.current.startOfDay(for: day.date)
                            let daySessions = sessionsByDay[dayKey] ?? []
                            if !daySessions.isEmpty {
                                selectedPayload = SelectedSessionsPayload(date: day.date, sessions: daySessions)
                            }
                        }
                    )
                }
            }

            calendarDetailSection
        }
    }

    @ViewBuilder
    private var calendarDetailSection: some View {
        if let selectedDate, selectedDaySessions.isEmpty, isMissedDay(selectedDate) {
            HistoryMissedDayCard(
                date: selectedDate,
                workoutName: assignedWorkoutName(on: selectedDate)
            )
        }
    }

    private func isMissedDay(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let day = calendar.startOfDay(for: date)
        guard (sessionsByDay[day] ?? []).isEmpty else { return false }
        return TrainingWeekProgressBuilder.isMissedTrainingDay(
            date: day,
            routineTemplateIDs: routineTemplateIDs,
            scheduledWeekdays: scheduledWeekdays,
            scheduleStartDate: scheduleStartDate,
            sessions: sessions
        )
    }

    /// Resolves the template name scheduled for a given weekday, or a neutral fallback.
    private func assignedWorkoutName(on date: Date) -> String {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        guard let split = ActiveSplitStore.resolve(from: splits) else { return "Assigned workout" }

        let templateByID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let routineTemplates = split.orderedTemplateIds.compactMap { templateByID[$0] }

        return routineTemplates.first(where: { $0.scheduledWeekday == weekday })?.displayName ?? "Assigned workout"
    }

    /// Drops the current selection when the visible month changes away from it.
    private func syncCalendarSelectionIfNeeded() {
        guard let selectedDate else { return }
        let calendar = Calendar.current
        if !calendar.isDate(selectedDate, equalTo: displayMonth, toGranularity: .month) {
            self.selectedDate = nil
        }
    }

    private func makeSnapshot(for session: WorkoutSession, prSetEntryIDs: Set<UUID>) -> SessionSnapshot? {
        makeHistorySessionSnapshot(
            for: session,
            templateNamesByID: templateNamesByID,
            exercisesByID: exercisesByID,
            prSetEntryIDs: prSetEntryIDs
        )
    }
}

/// Derives which historical sets were PRs *at the time they were logged* by
/// replaying completed sessions chronologically with a per-exercise running
/// best. Mirrors `ActiveWorkoutView.priorBest` exactly — keep the two in
/// lockstep: completed, non-warmup working sets only; completed sessions
/// only; weight ranks first, reps break ties; the first-ever log of an
/// exercise sets the baseline without firing (no baseline → no PR).
///
/// Pure derivation — nothing is persisted, so badges appear for sessions
/// logged before this feature existed and survive edits/deletes by
/// recomputing from stored truth. One divergence from the live screen:
/// editing an old set re-ranks everything after it here, while the live
/// session freezes at-log-time flags for unedited entries. Stored truth
/// wins in History.
enum PRHistory {
    static func prSetEntryIDs(in sessions: [WorkoutSession]) -> Set<UUID> {
        var bestByExercise: [UUID: (weight: Double, reps: Int)] = [:]
        var prIDs: Set<UUID> = []
        let ordered = sessions
            .filter(\.isCompleted)
            .sorted { $0.date < $1.date }
        for session in ordered {
            let entries = session.setEntries
                .filter { $0.isCompleted && !$0.isWarmup }
                .sorted { $0.setIndex < $1.setIndex }
            for entry in entries {
                guard let prior = bestByExercise[entry.exerciseId] else {
                    bestByExercise[entry.exerciseId] = (entry.weight, entry.reps)
                    continue
                }
                let beats = entry.weight > prior.weight
                    || (entry.weight == prior.weight && entry.reps > prior.reps)
                if beats {
                    prIDs.insert(entry.id)
                    bestByExercise[entry.exerciseId] = (entry.weight, entry.reps)
                }
            }
        }
        return prIDs
    }
}

/// Ink "PR" chip shared by the History session rows, detail header, and set
/// rows — same accent language as the live workout's PR set chip. Composition
/// of existing atoms only; lives here because all call sites are in this file.
@ViewBuilder
func historyPRTag() -> some View {
    AppTag(text: AppCopy.Workout.prTag, style: .accent, layout: .compactCapsule)
        .accessibilityLabel(AppCopy.Workout.personalRecord)
}

func makeHistorySessionSnapshot(
    for session: WorkoutSession,
    templateNamesByID: [UUID: String],
    exercisesByID: [UUID: Exercise],
    prSetEntryIDs: Set<UUID>
) -> SessionSnapshot? {
    let completedEntries = session.setEntries
        .filter { $0.isCompleted && !$0.isWarmup }
        .sorted { $0.setIndex < $1.setIndex }

    let isSkippedSession = !session.isCompleted && completedEntries.isEmpty

    guard !completedEntries.isEmpty || session.isCompleted || isSkippedSession else { return nil }

    let groupedEntries = Dictionary(grouping: completedEntries, by: \.exerciseId)
    let exerciseSnapshots = groupedEntries.compactMap { exerciseID, entries -> SessionExerciseSnapshot? in
        let exercise = exercisesByID[exerciseID]
        let name = exercise?.displayName ?? "Exercise"
        let sets = entries.map { entry in
            SessionSetSnapshot(
                id: entry.id,
                setIndex: entry.setIndex,
                actualWeight: entry.weight,
                actualReps: entry.reps,
                note: entry.note.trimmingCharacters(in: .whitespacesAndNewlines),
                isPR: prSetEntryIDs.contains(entry.id)
            )
        }
        .sorted { $0.setIndex < $1.setIndex }

        return SessionExerciseSnapshot(
            id: exerciseID,
            name: name,
            isBodyweight: exercise?.isBodyweight ?? false,
            sets: sets
        )
    }
    .sorted { $0.name < $1.name }

    let contextNote = completedEntries
        .map(\.note)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first(where: { !$0.isEmpty })

    return SessionSnapshot(
        id: session.id,
        date: session.date,
        templateName: templateNamesByID[session.templateId] ?? "Workout",
        state: session.isCompleted ? .completed : (isSkippedSession ? .skipped : .partial),
        exercises: exerciseSnapshots,
        contextNote: contextNote
    )
}

extension RecentSessionsView {
    init(showsCloseButton: Bool = true, initialMode: SessionHistoryMode = .list) {
        self.showsCloseButton = showsCloseButton
        self.initialMode = initialMode
        _mode = State(initialValue: initialMode)
    }
}

private struct EarlierWeekRoutineRow: View {
    let info: EarlierWeekRoutineInfo
    let onStart: () -> Void

    var body: some View {
        Button(action: onStart) {
            AppSessionHighlightCard(
                eyebrow: info.scheduledDate.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
                title: info.templateName,
                caption: "Planned for \(info.scheduledDayName) · Tap to start"
            ) {
                AppTag(text: "Missed", style: .warning, layout: .compactCapsule)
            }
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Start \(info.templateName), missed on \(info.scheduledDayName)")
    }
}

struct SessionSummarySheet: View {
    let payload: SelectedSessionsPayload

    @Environment(\.dismiss) private var dismiss

    private var headerTitle: String {
        let count = payload.sessions.count
        return count <= 1 ? "" : "\(count) sessions"
    }

    var body: some View {
        AppSheetScreen(
            title: headerTitle,
            dismissLabel: AppCopy.Nav.done,
            dismissActionPlacement: .confirmation,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                ForEach(payload.sessions) { snapshot in
                    SessionSummaryCard(snapshot: snapshot)
                }
            }
        }
    }
}

private struct SessionSummaryCard: View {
    let snapshot: SessionSnapshot

    var body: some View {
        AppSessionHighlightCard(
            eyebrow: snapshot.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
            title: snapshot.templateName,
            caption: snapshot.compactExerciseHeadline,
            trailing: {
                HStack(spacing: AppSpacing.xs) {
                    if snapshot.hasPR {
                        historyPRTag()
                    }
                    AppTag(text: snapshot.state.title, style: snapshot.state.tagStyle, layout: .compactCapsule)
                }
            }
        ) {
            VStack(alignment: .leading, spacing: 0) {
                if let contextNote = snapshot.contextNote {
                    AppTag(text: contextNote, style: .muted)
                        .padding(.horizontal, AppSpacing.lg)
                        .padding(.vertical, AppSpacing.md)
                }

                AppDividedList(snapshot.exercises) { exercise in
                    SessionExerciseSummary(exercise: exercise)
                        .appCardRowChrome()
                }
            }
        }
    }
}

struct SessionExerciseSummary: View {
    let exercise: SessionExerciseSnapshot

    private var areSetsUniform: Bool {
        guard let first = exercise.sets.first else { return true }
        return exercise.sets.allSatisfy {
            $0.actualWeight == first.actualWeight && $0.actualReps == first.actualReps
        }
    }

    private var hasAnyNote: Bool {
        exercise.sets.contains(where: { !$0.note.isEmpty })
    }

    private var showsPerSetBreakdown: Bool {
        !areSetsUniform || hasAnyNote
    }

    private var headerSummary: String? {
        guard areSetsUniform else { return nil }
        return exercise.previewPerformanceText
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
                Text(exercise.name)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // PR marker lives at the exercise grain only while the
                // uniform one-line summary hides the per-set rows; once the
                // breakdown renders, the per-set tags below carry it instead
                // — exactly one grain tagged at a time.
                if exercise.hasPR, !showsPerSetBreakdown {
                    historyPRTag()
                }

                if let headerSummary {
                    Text(headerSummary)
                        .font(AppFont.performance.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }

            if showsPerSetBreakdown {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(exercise.sets) { set in
                        setBreakdownRow(for: set)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func setBreakdownRow(for set: SessionSetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
                Text(setPositionLabel(for: set))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)

                Spacer(minLength: AppSpacing.sm)

                // Tag sits LEFT of the metric so the mono number column stays
                // flush right across PR and non-PR rows — same rule as the
                // exercise header above (tag before the trailing metric).
                if set.isPR {
                    historyPRTag()
                }

                Text(actualText(for: set))
                    .font(AppFont.performance.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .monospacedDigit()
            }

            if !set.note.isEmpty {
                Text(set.note)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private func setPositionLabel(for set: SessionSetSnapshot) -> String {
        "Set \(set.setIndex + 1)"
    }

    private func actualText(for set: SessionSetSnapshot) -> String {
        WorkoutTargetFormatter.actualText(
            weightKg: set.actualWeight,
            setCount: 1,
            reps: set.actualReps,
            isBodyweight: exercise.isBodyweight
        )
    }
}

private struct CalendarMonthHeader: View {
    @Binding var displayMonth: Date

    private var monthTitle: String {
        displayMonth.formatted(.dateTime.month(.wide).year())
    }

    private var canGoForward: Bool {
        displayMonth < Calendar.current.startOfMonth(for: Date())
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Text(monthTitle)
                .appFont(.largeTitle)
                .foregroundStyle(AppColor.textPrimary)

            Spacer(minLength: 0)

            HStack(spacing: AppSpacing.xs) {
                monthNavChevron(icon: .back, accessibilityLabel: "Previous month") {
                    shiftMonth(by: -1)
                }

                monthNavChevron(icon: .forward, accessibilityLabel: "Next month", isEnabled: canGoForward) {
                    shiftMonth(by: 1)
                }
            }
        }
    }

    private func monthNavChevron(
        icon: AppIcon,
        accessibilityLabel: String,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            AppIconCircle {
                icon
                    .image(size: AppIconCircleSize.icon, weight: AppIconCircleSize.weight)
                    .foregroundStyle(isEnabled ? AppColor.textPrimary : AppColor.textSecondary.opacity(0.45))
            }
            .frame(width: 44, height: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(!isEnabled)
        .accessibilityLabel(accessibilityLabel)
    }

    private func shiftMonth(by value: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: value, to: displayMonth) else { return }
        displayMonth = next
    }
}

private struct CalendarGrid: View {
    let displayMonth: Date
    let sessionsByDay: [Date: [SessionSnapshot]]
    let selectedDate: Date?
    let routineTemplateIDs: [UUID]
    let scheduledWeekdays: Set<Int>
    let scheduleStartDate: Date?
    let sessions: [WorkoutSession]
    let onSelect: (CalendarDayCellModel) -> Void

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.smd), count: 7)
    private let weekdayHeaders = ["MON", "TUE", "WED", "THU", "FRI", "SAT", "SUN"]

    private var dayCells: [CalendarDayCellModel?] {
        let calendar = Calendar.current
        let monthStart = calendar.startOfMonth(for: displayMonth)
        let today = calendar.startOfDay(for: Date())

        guard let dayRange = calendar.range(of: .day, in: .month, for: monthStart) else { return [] }

        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingCount = (weekday + 5) % 7
        var result: [CalendarDayCellModel?] = Array(repeating: nil, count: leadingCount)

        for offset in 0..<dayRange.count {
            guard let date = calendar.date(byAdding: .day, value: offset, to: monthStart) else { continue }
            let dayNumber = offset + 1
            let dayKey = calendar.startOfDay(for: date)
            let daySessions = sessionsByDay[dayKey] ?? []
            let isToday = calendar.isDate(date, inSameDayAs: today)
            let hasLogged = !daySessions.isEmpty
            let status: CalendarDayStatus

            if date > today {
                status = .future
            } else if isToday {
                status = hasLogged ? .completed : .today
            } else if hasLogged {
                status = .completed
            } else if TrainingWeekProgressBuilder.isMissedTrainingDay(
                date: date,
                routineTemplateIDs: routineTemplateIDs,
                scheduledWeekdays: scheduledWeekdays,
                scheduleStartDate: scheduleStartDate,
                sessions: sessions
            ) {
                status = .missed
            } else {
                status = .default
            }

            result.append(
                CalendarDayCellModel(
                    date: date,
                    dayNumber: dayNumber,
                    isToday: isToday,
                    isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false,
                    sessionCount: daySessions.count,
                    status: status,
                    sessions: daySessions.sorted { $0.date > $1.date }
                )
            )
        }

        return result
    }

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            HStack(spacing: AppSpacing.smd) {
                ForEach(weekdayHeaders, id: \.self) { header in
                    Text(header)
                        .appCapsLabel(.smallLabel)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.smd) {
                ForEach(Array(dayCells.enumerated()), id: \.offset) { _, cell in
                    if let cell {
                        CalendarDayCell(model: cell) {
                            onSelect(cell)
                        }
                    } else {
                        Color.clear
                            .frame(height: 40)
                    }
                }
            }
        }
    }
}

private struct CalendarDayCell: View {
    let model: CalendarDayCellModel
    let action: () -> Void

    private let shape = RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)

    var body: some View {
        Group {
            if model.status.isTappable {
                Button(action: action) { cellBody }
                    .buttonStyle(ScaleButtonStyle())
            } else {
                cellBody
            }
        }
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(model.status.isTappable ? [.isButton] : [])
    }

    private var cellBody: some View {
        Text("\(model.dayNumber)")
            .font(AppFont.body.font)
            .foregroundStyle(numberColor)
            .frame(minWidth: 36, minHeight: 38)
            .background(
                shape.fill(backgroundFill)
            )
            .overlay(
                shape.strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
    }

    private var backgroundFill: Color {
        if model.isSelected {
            return AppColor.textPrimary
        }
        switch model.status {
        case .completed:
            return AppColor.controlBackground
        case .today, .missed, .default, .future:
            return .clear
        }
    }

    private var numberColor: Color {
        if model.isSelected {
            return AppColor.background
        }
        switch model.status {
        case .completed, .missed, .today:
            return AppColor.textPrimary
        case .default, .future:
            return AppColor.textSecondary
        }
    }

    private var strokeColor: Color {
        if model.isSelected {
            return AppColor.textPrimary
        }
        switch model.status {
        case .missed, .today:
            return AppColor.border
        case .completed, .default, .future:
            return .clear
        }
    }

    private var strokeWidth: CGFloat {
        if model.isSelected { return 2 }
        switch model.status {
        case .missed, .today: return 1
        default: return 0
        }
    }

    private var accessibilityLabel: String {
        let dateLabel = model.date.formatted(date: .abbreviated, time: .omitted)
        let stateLabel: String
        switch model.status {
        case .default:
            stateLabel = "no session"
        case .missed:
            stateLabel = "missed assigned workout"
        case .completed:
            stateLabel = "logged session"
        case .today:
            stateLabel = "today"
        case .future:
            stateLabel = "upcoming"
        }
        let selected = model.isSelected ? ", selected" : ""
        return "\(dateLabel), \(stateLabel)\(selected)"
    }
}

/// Calendar detail shown when a past, missed assigned-workout day is selected.
private struct HistoryMissedDayCard: View {
    let date: Date
    let workoutName: String

    var body: some View {
        AppSessionHighlightCard(
            eyebrow: date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()),
            title: workoutName,
            caption: nil
        ) {
            AppTag(text: "Missed", style: .warning, layout: .compactCapsule)
        }
    }
}

private extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    NavigationStack {
        RecentSessionsView()
            .modelContainer(PreviewSampleData.makePreviewContainer())
    }
}
