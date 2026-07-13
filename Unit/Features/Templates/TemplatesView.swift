//
//  TemplatesView.swift
//  Unit
//
//  Program root: one active program, day list, and narrow edit surfaces.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TemplatesView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appTabSelection) private var appTabSelection

    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplitIdString: String = ""

    @State private var showingOnboarding = false
    @State private var showingSettings = false

    private var activeSplit: Split? {
        ActiveSplitStore.resolve(from: splits)
    }

    private var inactiveSplits: [Split] {
        guard let active = activeSplit else { return [] }
        return splits.filter { $0.id != active.id }
    }

    private var activeSession: WorkoutSession? {
        sessions.first(where: { !$0.isCompleted })
    }

    /// Sticky bottom CTA — surfaces "Continue workout" only when a session
    /// is already in progress, as a shortcut back to Today. Starting a
    /// workout deliberately lives on the Today tab: the Program tab is for
    /// viewing and editing routines, not initiating sessions.
    private var programsCTA: PrimaryButtonConfig? {
        guard activeSession != nil else { return nil }
        return PrimaryButtonConfig(
            label: AppCopy.Workout.continueWorkout,
            action: { appTabSelection(.today) }
        )
    }

    var body: some View {
        NavigationStack {
            AppScreen(
                primaryButton: programsCTA,
                showsNativeNavigationBar: true,
                usesOuterScroll: false
            ) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    if let split = activeSplit {
                        programContent(split: split)
                    } else {
                        emptyState
                    }
                }
                .appScreenEnter()
            }
            .navigationTitle("Programs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink(value: ProgramLibraryDestination()) {
                        Text("Browse")
                            .appToolbarTextStyle()
                    }
                    .accessibilityLabel("Browse program library")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Label("Settings", systemImage: AppIcon.settingsOutline.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .appNavigationBarChrome()
            .navigationDestination(for: Split.self) { split in
                ProgramDetailView(split: split)
            }
            .navigationDestination(for: DayTemplate.self) { template in
                TemplateDetailView(template: template)
            }
            .navigationDestination(for: ProgramLibraryDestination.self) { _ in
                ProgramLibraryView()
            }
            .navigationDestination(isPresented: $showingOnboarding) {
                OnboardingView()
            }
            .sheet(isPresented: $showingSettings) {
                NavigationStack {
                    SettingsView()
                }
                .appBottomSheetChrome()
            }
            .tint(AppColor.accent)
            .onAppear {
                FreestyleSessionSupport.cleanupOrphanedTemplates(
                    modelContext: modelContext,
                    templates: templates,
                    sessions: sessions
                )
            }
        }
    }

    @ViewBuilder
    private func programContent(split: Split) -> some View {
        let days = orderedTemplates(for: split)

        VStack(alignment: .leading, spacing: AppSpacing.md) {
            activeProgramCard(split: split, days: days)

            Button {
                FreestyleSessionSupport.startEmptyWorkout(modelContext: modelContext, activeSplit: split)
                appTabSelection(.today)
            } label: {
                AppGhostButtonLabel(title: AppCopy.Workout.freestyleSession)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, AppSpacing.xxs)
            .accessibilityLabel("Freestyle session, log without a program day")

            // MARK: All Programs (inactive splits)
            if !inactiveSplits.isEmpty {
                AppSectionHeader("All Programs")
                    .padding(.top, AppSpacing.md)

                AppCardList(inactiveSplits) { split in
                    let splitDays = orderedTemplates(for: split)
                    let dayCount = splitDays.count
                    let exerciseCount = splitDays.reduce(0) { $0 + $1.orderedExerciseIds.count }
                    NavigationLink(value: split) {
                        PreviewListRow(
                            title: split.name.isEmpty ? "Untitled Program" : split.name,
                            subtitle: "\(dayCount) day\(dayCount == 1 ? "" : "s") · \(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s")"
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private var emptyState: some View {
        EmptyStateCard(
            title: "No active program",
            message: "Add your training days and exercises so Unit can show your last session before every set."
        ) {
            VStack(spacing: AppSpacing.xs) {
                AppPrimaryButton("Create program") {
                    showingOnboarding = true
                }

                NavigationLink(value: ProgramLibraryDestination()) {
                    AppGhostButtonLabel(title: "Pick a starter program")
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
    }

    private func activeProgramCard(split: Split, days: [DayTemplate]) -> some View {
        let displayName = split.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Untitled Program"
            : split.name

        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                NavigationLink(value: split) {
                    HStack(alignment: .center, spacing: AppSpacing.sm) {
                        Text(displayName)
                            .appFont(.largeTitle)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)

                        AppTag(text: "Active", style: .muted, layout: .compactCapsule)

                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(displayName), active program")
                    .accessibilityHint("Opens program details")
                }
                .buttonStyle(ScaleButtonStyle())

                if !days.isEmpty {
                    PreviewListContainer {
                        ForEach(days, id: \.id) { template in
                            NavigationLink(value: template) {
                                PreviewListRow(
                                    title: template.displayName,
                                    subtitle: routineSummary(for: template)
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                }
            }
        }
    }

    private func orderedTemplates(for split: Split) -> [DayTemplate] {
        let byID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let linked = split.orderedTemplateIds.compactMap { byID[$0] }
        if !linked.isEmpty {
            return linked
        }
        return templates.filter { $0.splitId == split.id }
    }

    private func routineSummary(for template: DayTemplate) -> String {
        let exerciseNames = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id, $0.displayName) })
        let count = template.orderedExerciseIds.compactMap { exerciseNames[$0] }.count
        if count == 0 {
            return "Add exercises"
        }
        return "\(count) exercise\(count == 1 ? "" : "s")"
    }
}

struct EditProgramView: View {
    @Bindable var split: Split

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var showDeleteConfirmation = false
    @State private var showAddDay = false
    @State private var draggedTemplateID: UUID?

    private static let weekdayOrder = [2, 3, 4, 5, 6, 7, 1]

    private var baseTemplates: [DayTemplate] {
        let byID = Dictionary(uniqueKeysWithValues: templates.map { ($0.id, $0) })
        let linked = split.orderedTemplateIds.compactMap { byID[$0] }
        return linked.isEmpty ? templates.filter { $0.splitId == split.id } : linked
    }

    /// True when any routine in this Split is pinned to a calendar weekday
    /// (set in onboarding's "Training days" step). In weekday mode the
    /// per-routine weekday dictates order, so the list sorts by weekday and
    /// the drag-to-reorder affordance is hidden — drag would only juggle
    /// display order without changing which day a routine falls on.
    private var isWeekdayScheduled: Bool {
        baseTemplates.contains { $0.scheduledWeekday > 0 }
    }

    private var orderedTemplates: [DayTemplate] {
        let base = baseTemplates
        guard isWeekdayScheduled else { return base }
        return base.sorted { lhs, rhs in
            let lw = lhs.scheduledWeekday > 0 ? lhs.scheduledWeekday : Int.max
            let rw = rhs.scheduledWeekday > 0 ? rhs.scheduledWeekday : Int.max
            return lw < rw
        }
    }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                programNameSection
                routinesSection
            }
            .appScreenEnter()
        }
        .onChange(of: split.name) { _, _ in
            try? modelContext.save()
        }
        .onAppear {
            syncTemplateOrderIfNeeded()
        }
        .navigationTitle("Edit program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirmation = true
                } label: {
                    Label("Delete program", systemImage: AppIcon.trash.systemName)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Delete program")
            }
            ToolbarItem(placement: .confirmationAction) {
                Button { dismiss() } label: {
                    Label(AppCopy.Nav.done, systemImage: AppIcon.checkmark.systemName)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel(AppCopy.Nav.done)
            }
        }
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(for: DayTemplate.self) { template in
            TemplateDetailView(template: template)
        }
        .sheet(isPresented: $showAddDay) {
            AddTemplateView(split: split)
                .appBottomSheetChrome()
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Delete program",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete program", role: .destructive) {
                deleteProgram()
            }
        } message: {
            Text("Deletes this program and its routine days. Can't be undone.")
        }
    }

    // MARK: - Sections

    private var programNameSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Program Name")

            TextField("Program name", text: $split.name)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .textInputAutocapitalization(.words)
                .appInputFieldStyle()
        }
    }

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Routines")
            routinesList
            AppGhostButton(isWeekdayScheduled ? "Use flexible schedule" : "Add weekly schedule") {
                if isWeekdayScheduled {
                    clearSchedule()
                } else {
                    applyDefaultSchedule()
                }
            }
        }
    }

    private var routinesList: some View {
        AppCardList(orderedTemplates, row: { template in
            routineRow(template)
        }, trailing: {
            AppCardListAddRow("Add Routine") {
                showAddDay = true
            }
        })
    }

    // MARK: - Rows

    @ViewBuilder
    private func routineRow(_ template: DayTemplate) -> some View {
        if isWeekdayScheduled {
            weekdayRoutineRow(template)
        } else {
            draggableRoutineRow(template)
        }
    }

    private func weekdayRoutineRow(_ template: DayTemplate) -> some View {
        HStack(spacing: AppSpacing.sm) {
            NavigationLink(value: template) {
                PreviewListRow(
                    title: template.displayName,
                    subtitle: subtitle(for: template)
                )
            }
            .buttonStyle(ScaleButtonStyle())

            Menu {
                ForEach(Self.weekdayOrder, id: \.self) { weekday in
                    Button {
                        template.scheduledWeekday = weekday
                        try? modelContext.save()
                    } label: {
                        if template.scheduledWeekday == weekday {
                            Label(weekdayName(weekday), systemImage: AppIcon.checkmark.systemName)
                        } else {
                            Text(weekdayName(weekday))
                        }
                    }
                    .disabled(isWeekdayTaken(weekday, excluding: template.id))
                }
            } label: {
                Text(weekdayShort(template.scheduledWeekday) ?? "Day")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Change weekday for \(template.displayName)")
        }
    }

    private func draggableRoutineRow(_ template: DayTemplate) -> some View {
        HStack(spacing: AppSpacing.sm) {
            AppIcon.reorder.image(size: 15, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .accessibilityHidden(true)

            NavigationLink(value: template) {
                PreviewListRow(
                    title: template.displayName,
                    subtitle: subtitle(for: template)
                )
            }
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .appReorderable(
            id: template.id,
            draggedID: $draggedTemplateID,
            reduceMotion: reduceMotion
        ) {
            routineDragPreview(for: template)
        }
        .onDrop(
            of: [UTType.text],
            delegate: RoutineReorderDropDelegate(
                targetTemplateID: template.id,
                split: split,
                modelContext: modelContext,
                draggedTemplateID: $draggedTemplateID,
                reduceMotion: reduceMotion
            )
        )
    }

    @ViewBuilder
    private func routineDragPreview(for template: DayTemplate) -> some View {
        AppReorderDragPreview {
            HStack(spacing: AppSpacing.sm) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(template.displayName)
                        .font(AppFont.sectionHeader.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .lineLimit(1)
                    Text(subtitle(for: template))
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(1)
                }

                Spacer(minLength: AppSpacing.sm)
            }
        }
    }

    // MARK: - Helpers

    private func subtitle(for template: DayTemplate) -> String {
        let count = template.orderedExerciseIds.count
        return count == 0 ? "Add exercises" : "\(count) exercise\(count == 1 ? "" : "s")"
    }

    private func weekdayShort(_ weekday: Int) -> String? {
        guard weekday >= 1, weekday <= 7 else { return nil }
        return Calendar.current.shortWeekdaySymbols[weekday - 1]
    }

    private func weekdayName(_ weekday: Int) -> String {
        guard weekday >= 1, weekday <= 7 else { return "Day" }
        return Calendar.current.weekdaySymbols[weekday - 1]
    }

    private func isWeekdayTaken(_ weekday: Int, excluding templateID: UUID) -> Bool {
        orderedTemplates.contains { $0.id != templateID && $0.scheduledWeekday == weekday }
    }

    private func applyDefaultSchedule() {
        for (index, template) in baseTemplates.prefix(Self.weekdayOrder.count).enumerated() {
            template.scheduledWeekday = Self.weekdayOrder[index]
        }
        try? modelContext.save()
    }

    private func clearSchedule() {
        for template in baseTemplates {
            template.scheduledWeekday = 0
        }
        try? modelContext.save()
    }

    private func syncTemplateOrderIfNeeded() {
        if split.orderedTemplateIds.isEmpty {
            split.orderedTemplateIds = templates
                .filter { $0.splitId == split.id }
                .map(\.id)
            try? modelContext.save()
        }
    }

    private func deleteProgram() {
        let splitId = split.id
        let templatesToDelete = templates.filter { $0.splitId == splitId }
        let referencedTemplateIDs = Set(sessions.map(\.templateId))
        for t in templatesToDelete {
            if referencedTemplateIDs.contains(t.id) {
                // Keep the historical name resolvable without exposing this
                // routine in any live program.
                t.splitId = nil
            } else {
                modelContext.delete(t)
            }
        }
        modelContext.delete(split)
        try? modelContext.save()
        dismiss()
    }
}

private struct RoutineReorderDropDelegate: DropDelegate {
    let targetTemplateID: UUID
    let split: Split
    let modelContext: ModelContext
    @Binding var draggedTemplateID: UUID?
    var reduceMotion: Bool = false

    func dropEntered(info: DropInfo) {
        guard let draggedTemplateID,
              draggedTemplateID != targetTemplateID,
              let fromIndex = split.orderedTemplateIds.firstIndex(of: draggedTemplateID),
              let toIndex = split.orderedTemplateIds.firstIndex(of: targetTemplateID) else {
            return
        }

        withAnimation(reduceMotion ? nil : .appConfirm) {
            var ids = split.orderedTemplateIds
            let moved = ids.remove(at: fromIndex)
            ids.insert(moved, at: toIndex)
            split.orderedTemplateIds = ids
        }
        AppHaptic.reorderSwap.fire()
    }

    func performDrop(info: DropInfo) -> Bool {
        try? modelContext.save()
        draggedTemplateID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    TemplatesView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
