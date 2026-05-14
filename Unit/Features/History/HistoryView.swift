//
//  HistoryView.swift
//  Unit
//
//  List-first recent sessions, grouped by month.
//

import SwiftUI
import SwiftData

enum SessionHistoryFilter: String, CaseIterable, Identifiable {
    case all = "All"
    case completed = "Completed"
    case partial = "Partial"
    case skipped = "Skipped"
    case missed = "Missed"

    var id: Self { self }
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
}

struct SessionExerciseSnapshot: Identifiable {
    let id: UUID
    let name: String
    let isBodyweight: Bool
    let sets: [SessionSetSnapshot]

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

struct RecentSessionsView: View {
    let showsCloseButton: Bool

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]

    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplitIdString: String = ""

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var filter: SessionHistoryFilter = .all
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
        historySessions.compactMap(makeSnapshot(for:))
    }

    private var sessionsByDay: [Date: [SessionSnapshot]] {
        Dictionary(grouping: sessionSnapshots, by: { Calendar.current.startOfDay(for: $0.date) })
    }

    /// Routines scheduled earlier this week that are still available — neutral copy, not a home-screen “missed” nudge.
    private var earlierWeekItems: [EarlierWeekRoutineInfo] {
        guard let split = ActiveSplitStore.resolve(from: splits) else { return [] }
        let ordered = EarlierWeekCatchup.orderedTemplates(for: split, templates: templates)
        guard ordered.contains(where: { $0.scheduledWeekday > 0 }) else { return [] }
        return EarlierWeekCatchup.incompleteItems(orderedTemplates: ordered, sessions: sessions)
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            Group {
                if sessionSnapshots.isEmpty, earlierWeekItems.isEmpty {
                    emptyState
                } else {
                    listContent
                        .appAnimation(.appState, value: filter, reduceMotion: reduceMotion)
                }
            }
            .appScreenEnter()
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .sheet(item: $selectedPayload) { payload in
            SessionSummarySheet(payload: payload)
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
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
            AppTag(text: snapshot.state.title, style: snapshot.state.tagStyle, layout: .compactCapsule)
        }
    }

    private var historyFilterChips: some View {
        AppFilterChipBar {
            ForEach(SessionHistoryFilter.allCases.filter { $0 != .all }) { option in
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

    private func makeSnapshot(for session: WorkoutSession) -> SessionSnapshot? {
        makeHistorySessionSnapshot(
            for: session,
            templateNamesByID: templateNamesByID,
            exercisesByID: exercisesByID
        )
    }
}

func makeHistorySessionSnapshot(
    for session: WorkoutSession,
    templateNamesByID: [UUID: String],
    exercisesByID: [UUID: Exercise]
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
                note: entry.note.trimmingCharacters(in: .whitespacesAndNewlines)
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
    init(showsCloseButton: Bool = true) {
        self.showsCloseButton = showsCloseButton
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
                caption: "Planned for \(info.scheduledDayName)"
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
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    ForEach(payload.sessions) { snapshot in
                        SessionSummaryCard(snapshot: snapshot)
                    }
                }
                .padding(.horizontal, AppSpacing.md)
                .padding(.bottom, AppSpacing.lg)
            }
            .appScrollEdgeSoft()
            .navigationTitle(headerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Nav.done) {
                        dismiss()
                    }
                    .appToolbarTextStyle()
                }
            }
            .appNavigationBarChrome()
        }
        .background(AppColor.background.ignoresSafeArea())
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
                AppTag(text: snapshot.state.title, style: snapshot.state.tagStyle, layout: .compactCapsule)
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

#Preview {
    NavigationStack {
        RecentSessionsView()
            .modelContainer(PreviewSampleData.makePreviewContainer())
    }
}
