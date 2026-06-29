//
//  ExercisesListView.swift
//  Unit
//
//  Exercise library with aliases and exercise-level progress review.
//

import Charts
import SwiftUI
import SwiftData

/// Captured deletion intent — held while the confirmation alert is on screen
/// so the message can preview impact (`affectedTemplateCount`).
private struct PendingExerciseDeletion: Identifiable {
    let id = UUID()
    let exerciseId: UUID
    let exerciseName: String
    let affectedTemplateCount: Int
    let hasHistory: Bool
}

struct ExercisesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @State private var showingAddExercise = false
    @State private var query = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var selectedEquipment: Equipment? = nil
    @State private var pendingDeletion: PendingExerciseDeletion?

    private var filteredExercises: [Exercise] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let needle = trimmed.lowercased()
        return exercises.filter { exercise in
            guard !exercise.isArchived else { return false }
            if let muscle = selectedMuscle, exercise.muscleGroup != muscle { return false }
            if let equipment = selectedEquipment, exercise.equipment != equipment { return false }
            guard !trimmed.isEmpty else { return true }
            if exercise.displayName.lowercased().contains(needle) { return true }
            return exercise.aliases.contains { $0.lowercased().contains(needle) }
        }
    }

    var body: some View {
        List {
            Section {
                ExerciseFilterChips(
                    selectedMuscle: $selectedMuscle,
                    selectedEquipment: $selectedEquipment
                )
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
            }
            .listSectionSeparator(.hidden, edges: .bottom)

            ForEach(filteredExercises, id: \.id) { exercise in
                NavigationLink(value: exercise) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(spacing: AppSpacing.sm) {
                            Text(exercise.displayName)
                                .font(AppFont.body.font)
                            if exercise.isBodyweight {
                                Text(AppCopy.Workout.bodyweightAbbrev)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                        }
                        Text(exerciseCaption(for: exercise))
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                    .frame(minHeight: 44, alignment: .leading)
                }
            }
            .onDelete(perform: deleteExercises)
            .appPlainListRowChrome()

            // Empty-row hint covers cold start (no exercises seeded), full
            // delete (user removed everything), and zero-match filters. Three
            // states share one row recipe — disambiguated by message.
            if filteredExercises.isEmpty {
                Text(emptyHintMessage)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(minHeight: 44, alignment: .leading)
                    .appPlainListRowChrome(separator: .hidden)
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppColor.background.ignoresSafeArea())
        .appScrollEdgeSoft()
        .appScreenEnter()
        .navigationTitle("Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Exercise.self) { exercise in
            ExerciseDetailView(exercise: exercise)
        }
        .appExerciseSearchable(text: $query)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddExercise = true
                } label: {
                    Label("Add exercise", systemImage: AppIcon.addCircle.systemName)
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Add exercise")
            }
        }
        .appNavigationBarChrome()
        .sheet(isPresented: $showingAddExercise) {
            AddExerciseView()
                .appBottomSheetChrome()
                .presentationDetents([.large])
        }
        .alert(
            pendingDeletion.map { AppCopy.Exercises.deleteTitle($0.exerciseName) } ?? "",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            presenting: pendingDeletion
        ) { pending in
            Button(AppCopy.Exercises.deleteAction, role: .destructive) {
                confirmDelete(pending)
            }
            Button(AppCopy.Nav.cancel, role: .cancel) {}
        } message: { pending in
            if pending.hasHistory {
                Text("Removes this exercise from routines and the exercise library. Its name stays attached to past sessions.")
            } else if pending.affectedTemplateCount > 0 {
                Text(AppCopy.Exercises.deleteImpactMessage(routineCount: pending.affectedTemplateCount))
            } else {
                Text(AppCopy.Exercises.deleteUnusedMessage)
            }
        }
    }

    private var emptyHintMessage: String {
        let hasFilters = selectedMuscle != nil || selectedEquipment != nil
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return AppCopy.Search.noMatchingExercises
        }
        if hasFilters {
            return AppCopy.Search.noExercisesMatchFilters
        }
        return AppCopy.Search.noExercisesYet
    }

    private func exerciseCaption(for exercise: Exercise) -> String {
        var parts: [String] = [exercise.muscleGroup.displayName, exercise.equipment.displayName]
        if !exercise.aliases.isEmpty {
            parts.append(exercise.aliases.joined(separator: " • "))
        }
        return parts.joined(separator: " · ")
    }

    /// Capture the swipe-to-delete intent and stage a confirmation alert. Swipe
    /// only ever passes one offset (no EditMode is enabled here), so we present
    /// per-exercise — a multi-select alert would be ambiguous about scope.
    private func deleteExercises(at offsets: IndexSet) {
        guard let firstOffset = offsets.first else { return }
        let exercise = filteredExercises[firstOffset]
        let allTemplates = (try? modelContext.fetch(FetchDescriptor<DayTemplate>())) ?? []
        let allSessions = (try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        let affected = allTemplates.filter { $0.orderedExerciseIds.contains(exercise.id) }.count
        let hasHistory = allSessions.contains { session in
            session.setEntries.contains { $0.exerciseId == exercise.id }
        }
        pendingDeletion = PendingExerciseDeletion(
            exerciseId: exercise.id,
            exerciseName: exercise.displayName,
            affectedTemplateCount: affected,
            hasHistory: hasHistory
        )
    }

    /// Apply the staged deletion: cascade-remove the UUID from every referencing
    /// template, then delete the exercise itself. The cascade is what the
    /// confirmation alert preview (impact count) is warning about.
    private func confirmDelete(_ pending: PendingExerciseDeletion) {
        let allTemplates = (try? modelContext.fetch(FetchDescriptor<DayTemplate>())) ?? []
        for template in allTemplates where template.orderedExerciseIds.contains(pending.exerciseId) {
            template.orderedExerciseIds.removeAll { $0 == pending.exerciseId }
        }
        if let exercise = exercises.first(where: { $0.id == pending.exerciseId }) {
            if pending.hasHistory {
                exercise.isArchived = true
            } else {
                modelContext.delete(exercise)
            }
        }
        try? modelContext.save()
    }
}

private struct ExerciseFilterChips: View {
    @Binding var selectedMuscle: MuscleGroup?
    @Binding var selectedEquipment: Equipment?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            AppFilterChipBar(contentInset: AppSpacing.md) {
                AppFilterChip(
                    label: "All muscles",
                    isSelected: selectedMuscle == nil,
                    action: { selectedMuscle = nil }
                )
                ForEach(MuscleGroup.allCases) { group in
                    AppFilterChip(
                        label: group.displayName,
                        isSelected: selectedMuscle == group,
                        action: {
                            selectedMuscle = selectedMuscle == group ? nil : group
                        }
                    )
                }
            }
            AppFilterChipBar(contentInset: AppSpacing.md) {
                AppFilterChip(
                    label: "All equipment",
                    isSelected: selectedEquipment == nil,
                    action: { selectedEquipment = nil }
                )
                ForEach(Equipment.allCases) { equipment in
                    AppFilterChip(
                        label: equipment.displayName,
                        isSelected: selectedEquipment == equipment,
                        action: {
                            selectedEquipment = selectedEquipment == equipment ? nil : equipment
                        }
                    )
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
    }
}

private enum AddExerciseClassificationRow: String, Identifiable, CaseIterable {
    case muscle
    case equipment
    case bodyweight

    var id: String { rawValue }

    var title: String {
        switch self {
        case .muscle: return "Muscle group"
        case .equipment: return "Equipment"
        case .bodyweight: return "Bodyweight"
        }
    }
}

struct AddExerciseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var aliasesText = ""
    @State private var isBodyweight = false
    @State private var muscleGroup: MuscleGroup = .fullBody
    @State private var equipment: Equipment = .other

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        AppSheetScreen(
            title: "New exercise",
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.Nav.save,
                isEnabled: canSave,
                action: save
            ),
            dismissLabel: AppCopy.Nav.cancel,
            dismissActionPlacement: .cancellation,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AppSectionHeader("Exercise")

                    TextField("Exercise name", text: $displayName)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .textInputAutocapitalization(.words)
                        .appInputFieldStyle()

                    TextField("Aliases (comma separated)", text: $aliasesText)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .textInputAutocapitalization(.words)
                        .appInputFieldStyle()
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AppSectionHeader("Classification")

                    AppCardList(
                        data: AddExerciseClassificationRow.allCases,
                        id: \.id
                    ) { row in
                        HStack(spacing: AppSpacing.sm) {
                            Text(row.title)
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textPrimary)

                            Spacer(minLength: 0)

                            classificationControl(for: row)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func classificationControl(for row: AddExerciseClassificationRow) -> some View {
        switch row {
        case .muscle:
            Picker("Muscle group", selection: $muscleGroup) {
                ForEach(MuscleGroup.allCases) { group in
                    Text(group.displayName).tag(group)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(AppColor.textPrimary)
        case .equipment:
            Picker("Equipment", selection: $equipment) {
                ForEach(Equipment.allCases) { eq in
                    Text(eq.displayName).tag(eq)
                }
            }
            .pickerStyle(.menu)
            .labelsHidden()
            .tint(AppColor.textPrimary)
        case .bodyweight:
            Toggle("", isOn: $isBodyweight)
                .labelsHidden()
                .tint(AppColor.accent)
        }
    }

    private func save() {
        let aliases = aliasesText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let exercise = Exercise(
            displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
            aliases: aliases,
            isBodyweight: isBodyweight,
            muscleGroup: muscleGroup,
            equipment: equipment
        )
        modelContext.insert(exercise)
        try? modelContext.save()
        dismiss()
    }
}

private struct ExerciseSessionSummary: Identifiable {
    let id: UUID
    let sessionDate: Date
    let templateName: String
    let topSetText: String
    let estimatedOneRM: Double
    let totalVolume: Double
}

struct ExerciseDetailView: View {
    let exercise: Exercise

    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    private var summaries: [ExerciseSessionSummary] {
        sessions.filter(\.isCompleted).compactMap { session in
            let entries = session.setEntries
                .filter { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup }
                .sorted { $0.setIndex < $1.setIndex }

            guard !entries.isEmpty else { return nil }

            let oneRMs = entries.map { estimateOneRM(weight: $0.weight, reps: $0.reps) }
            let topOneRM = oneRMs.max() ?? 0
            let totalVolume = entries.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
            guard let topSet = entries.max(by: { lhs, rhs in
                if lhs.weight == rhs.weight {
                    return lhs.reps < rhs.reps
                }
                return lhs.weight < rhs.weight
            }) else { return nil }

            return ExerciseSessionSummary(
                id: session.id,
                sessionDate: session.date,
                templateName: templateName(for: session.templateId),
                topSetText: WorkoutTargetFormatter.actualText(
                    weightKg: topSet.weight,
                    setCount: 1,
                    reps: topSet.reps,
                    isBodyweight: exercise.isBodyweight
                ),
                estimatedOneRM: topOneRM,
                totalVolume: totalVolume
            )
        }
    }

    private var trendAscending: [ExerciseSessionSummary] {
        summaries.sorted { $0.sessionDate < $1.sessionDate }
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(exercise.displayName)
                        .appFont(.largeTitle)
                    Text("Brzycki 1RM and session volume")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .appCardStyle()

                if summaries.isEmpty {
                    EmptyStateCard(
                        title: "No sessions yet",
                        message: "Sessions for this exercise show up here once you log them."
                    )
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Estimated 1RM trend")
                            .font(AppFont.sectionHeader.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Chart(trendAscending) { item in
                            LineMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AppColor.textPrimary)
                            PointMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("1RM", item.estimatedOneRM)
                            )
                            .foregroundStyle(AppColor.textPrimary)
                        }
                        .frame(height: 180)
                    }
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Session volume")
                            .font(AppFont.sectionHeader.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Chart(trendAscending) { item in
                            BarMark(
                                x: .value("Date", item.sessionDate),
                                y: .value("Volume", item.totalVolume)
                            )
                            .foregroundStyle(AppColor.accentSoft)
                        }
                        .frame(height: 160)
                    }
                    .appCardStyle()

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("Past sessions")
                            .font(AppFont.sectionHeader.font)
                            .foregroundStyle(AppColor.textPrimary)

                        ForEach(summaries) { summary in
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                HStack {
                                    Text(summary.templateName)
                                        .font(AppFont.body.font)
                                    Spacer(minLength: 0)
                                    Text(summary.sessionDate, style: .date)
                                        .font(AppFont.caption.font)
                                        .foregroundStyle(AppColor.textSecondary)
                                }
                                Text("Top set: \(summary.topSetText)")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                                Text("Est. 1RM: \(WorkoutTargetFormatter.weightDisplay(summary.estimatedOneRM)) • Volume: \(Int(summary.totalVolume))")
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, AppSpacing.sm)

                            if summary.id != summaries.last?.id {
                                AppDivider()
                            }
                        }
                    }
                    .appCardStyle()
                }
            }
            .appScreenEnter()
        }
        .navigationTitle("Exercise")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
    }

    private func templateName(for templateId: UUID) -> String {
        templates.first { $0.id == templateId }?.name ?? "Custom"
    }

    private func estimateOneRM(weight: Double, reps: Int) -> Double {
        guard reps > 0 else { return 0 }
        let denominator = 1.0278 - (0.0278 * Double(reps))
        guard denominator > 0 else { return 0 }
        return weight / denominator
    }

    private func formatWeight(_ value: Double) -> String {
        value == floor(value) ? "\(Int(value))" : String(format: "%.1f", value)
    }
}

#Preview {
    NavigationStack {
        ExercisesListView()
            .modelContainer(PreviewSampleData.makePreviewContainer())
    }
}
