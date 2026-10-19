//
//  TemplateDetailView.swift
//  Unit
//
//  Day detail: exercise list with editable targets; drag the handle to reorder, tap × to remove.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct TemplateDetailView: View {
    @Bindable var template: DayTemplate

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showingAddExercise = false
    @State private var draggedExerciseID: UUID?
    @State private var targetEditPayload: TargetEditPayload?
    /// Toast message shown after a non-destructive × removal. Bound to the
    /// `appToast(event:)` modifier owns the four-second Undo window.
    @State private var toastMessage: AppToastEvent?
    @State private var saveFailed = false
    /// Snapshot of the most recently removed exercise so Undo can restore it
    /// at its original index, with its prior planned sets/reps. Nil after a
    /// successful undo or after a fresh removal supersedes it.
    @State private var lastRemoved: RemovedExerciseSnapshot?

    private var orderedExercises: [Exercise] {
        template.orderedExerciseIds.compactMap { id in
            exercises.first(where: { $0.id == id })
        }
    }

    private var navigationTitleRaw: String {
        let trimmed = template.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Day" : trimmed
    }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if orderedExercises.isEmpty {
                    EmptyStateCard(
                        eyebrow: "Routine",
                        title: "No exercises yet.",
                        message: "Add exercises so this day can appear in your workout flow.",
                        buttonLabel: AppCopy.Workout.addExercise
                    ) {
                        showingAddExercise = true
                    }
                } else {
                    AppCardList(orderedExercises) { exercise in
                        exerciseRow(exercise)
                            .transition(AppBlurTransition(scales: true))
                    } trailing: {
                        AppCardListAddRow(AppCopy.Workout.addExercise) {
                            showingAddExercise = true
                        }
                    }
                }
            }
            .animation(AppMotion.allowsSpatialMotion(reduceMotion: reduceMotion, voiceOver: voiceOver) ? AppMotion.collectionChange : nil, value: template.orderedExerciseIds)
            .appScreenEnter()
        }
        .navigationBarTitleTruncated(navigationTitleRaw)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .appNavigationBarChrome()
        .sheet(isPresented: $showingAddExercise) {
            AppExercisePickerSheet(
                existingIds: Set(template.orderedExerciseIds)
            ) { exercise in
                addExercise(exercise)
            }
        }
        .sheet(item: $targetEditPayload) { payload in
            AppSetRepEditorSheet(
                subject: payload.exerciseName,
                initialSets: payload.setCount,
                initialReps: payload.reps,
                initialProgression: payload.progression
            ) { setCount, reps, progression in
                saveTarget(
                    setCount: setCount,
                    reps: reps,
                    progression: progression,
                    for: payload.exerciseID
                )
            }
        }
        .appToast(event: $toastMessage)
        .alert("Couldn't save routine", isPresented: $saveFailed) {
            Button(AppCopy.Nav.close, role: .cancel) { }
        } message: {
            Text("Your saved routine is unchanged. Try saving again.")
        }
        .tint(AppColor.accent)
    }

    private func persistRoutine() -> Bool {
        do {
            try modelContext.save()
            return true
        } catch {
            modelContext.rollback()
            saveFailed = true
            AppHaptic.error.fire()
            return false
        }
    }

    private func addExercise(_ exercise: Exercise) {
        var ids = template.orderedExerciseIds
        ids.append(exercise.id)
        template.orderedExerciseIds = ids
        _ = persistRoutine()
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: AppSpacing.md) {
            Button {
                targetEditPayload = targetEditPayload(for: exercise)
            } label: {
                HStack(spacing: AppSpacing.md) {
                    AppIcon.reorder.image(size: AppIconSize.readiness, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text(exercise.displayName)
                            .appFont(.title)
                            .foregroundStyle(AppColor.textPrimary)
                            .multilineTextAlignment(.leading)

                        HStack(spacing: AppSpacing.sm) {
                            exerciseTargetSubtitle(for: exercise)

                            Spacer(minLength: 0)

                            AppIcon.edit.image(size: AppIconSize.compact, weight: .semibold)
                                .foregroundStyle(AppColor.textSecondary)
                                .accessibilityHidden(true)
                        }
                        .padding(.horizontal, AppSpacing.sm)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                                .fill(AppColor.cardRowFill)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Edit target for \(exercise.displayName)")
            .accessibilityValue(targetAccessibilityValue(for: exercise))
            .accessibilityHint("Opens the target editor")

            Button {
                removeExerciseWithUndo(exercise)
            } label: {
                AppIcon.close.image(weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(minWidth: 44, minHeight: 44, alignment: .trailing)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Remove \(exercise.displayName)")
            .buttonStyle(ScaleButtonStyle())
        }
        .contentShape(Rectangle())
        .appReorderable(
            id: exercise.id,
            draggedID: $draggedExerciseID,
            reduceMotion: reduceMotion
        ) {
            exerciseDragPreview(for: exercise)
        }
        .onDrop(
            of: [UTType.text],
            delegate: TemplateExerciseReorderDropDelegate(
                targetExerciseID: exercise.id,
                template: template,
                modelContext: modelContext,
                draggedExerciseID: $draggedExerciseID,
                reduceMotion: reduceMotion
            )
        )
    }

    @ViewBuilder
    private func exerciseDragPreview(for exercise: Exercise) -> some View {
        AppReorderDragPreview {
            HStack(spacing: AppSpacing.md) {
                Text(exercise.displayName)
                    .appFont(.title)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(1)

                Spacer(minLength: AppSpacing.sm)

                exerciseTargetSubtitle(for: exercise)
            }
        }
    }

    @ViewBuilder
    private func exerciseTargetSubtitle(for exercise: Exercise) -> some View {
        if let progression = progressionSummary(for: exercise) {
            Text(progression)
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .monospacedDigit()
        } else if let planned = plannedTargetDisplay(for: exercise) {
            Text(WorkoutTargetFormatter.setRepDisplay(
                setCount: planned.setCount,
                reps: planned.reps
            ) ?? "")
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .monospacedDigit()
        } else {
            Text(ghostEmptySubtitle(for: exercise))
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func ghostEmptySubtitle(for exercise: Exercise) -> String {
        let hasAnyCompleted = sessions.contains(where: \.isCompleted)
        if !hasAnyCompleted {
            return AppCopy.EmptyState.noHistoryYet
        }
        return AppCopy.EmptyState.noPriorSets
    }

    private struct PlannedTargetDisplay {
        let setCount: Int
        let reps: Int
    }

    private struct TargetEditPayload: Identifiable {
        let exerciseID: UUID
        let exerciseName: String
        let setCount: Int
        let reps: Int
        let progression: DoubleProgressionConfiguration?

        var id: UUID { exerciseID }
    }

    private func plannedTargetDisplay(for exercise: Exercise) -> PlannedTargetDisplay? {
        storedPlannedTarget(for: exercise) ?? historyTargetDisplay(for: exercise)
    }

    private func storedPlannedTarget(for exercise: Exercise) -> PlannedTargetDisplay? {
        guard let plannedSets = template.plannedSets(for: exercise.id), plannedSets > 0,
              let plannedReps = template.plannedReps(for: exercise.id), plannedReps > 0 else {
            return nil
        }

        return PlannedTargetDisplay(setCount: plannedSets, reps: plannedReps)
    }

    private func historyTargetDisplay(for exercise: Exercise) -> PlannedTargetDisplay? {
        let sets = SetEntry.latestValidWorkingSets(for: exercise.id, in: sessions)
        guard let last = sets.last else { return nil }
        return PlannedTargetDisplay(setCount: sets.count, reps: last.reps)
    }

    private func targetEditPayload(for exercise: Exercise) -> TargetEditPayload {
        let target = plannedTargetDisplay(for: exercise)
            ?? PlannedTargetDisplay(
                setCount: AppSetRepEditorSheet.defaultSets,
                reps: AppSetRepEditorSheet.defaultReps
            )

        return TargetEditPayload(
            exerciseID: exercise.id,
            exerciseName: exercise.displayName,
            setCount: target.setCount,
            reps: target.reps,
            progression: template.progressionState(for: exercise.id)?.configuration(
                workingSetCount: target.setCount
            )
        )
    }

    private func targetAccessibilityValue(for exercise: Exercise) -> String {
        if let state = template.progressionState(for: exercise.id),
           let sets = template.plannedSets(for: exercise.id),
           sets > 0 {
            return "\(sets) sets, \(state.lowerRepBound) to \(state.upperRepBound) reps, plus \(WorkoutTargetFormatter.weightDisplay(state.weightIncrementKg))"
        }

        guard let planned = plannedTargetDisplay(for: exercise) else {
            return ghostEmptySubtitle(for: exercise)
        }

        return "\(planned.setCount) sets, \(planned.reps) reps"
    }

    @discardableResult
    private func saveTarget(
        setCount: Int,
        reps: Int,
        progression: DoubleProgressionConfiguration?,
        for exerciseID: UUID
    ) -> Bool {
        let previousSetCount = template.plannedSets(for: exerciseID)
        template.setPlannedSets(setCount, for: exerciseID)

        if let progression {
            let previous = template.progressionState(for: exerciseID)
            let targetReps = min(
                max(
                    previous?.currentAcceptedTargetReps ?? progression.lowerRepBound,
                    progression.lowerRepBound
                ),
                progression.upperRepBound
            )
            let configurationChanged = previous?.lowerRepBound != progression.lowerRepBound
                || previous?.upperRepBound != progression.upperRepBound
                || previous?.weightIncrementKg != progression.weightIncrementKg
                || previousSetCount != setCount
            let targetChanged = previous?.currentAcceptedTargetReps != targetReps
            let preservesAcceptedDecision = !configurationChanged && !targetChanged
            let state = ExerciseProgressionState(
                lowerRepBound: progression.lowerRepBound,
                upperRepBound: progression.upperRepBound,
                weightIncrementKg: progression.weightIncrementKg,
                currentAcceptedTargetWeightKg: previous?.currentAcceptedTargetWeightKg
                    ?? progressionSeedWeight(for: exerciseID),
                currentAcceptedTargetReps: targetReps,
                sourceWorkoutSessionID: preservesAcceptedDecision
                    ? previous?.sourceWorkoutSessionID
                    : nil,
                lastAcceptedReason: preservesAcceptedDecision
                    ? previous?.lastAcceptedReason
                    : nil
            )
            template.setProgressionState(state, for: exerciseID)
            template.setPlannedReps(targetReps, for: exerciseID)
        } else {
            template.setProgressionState(nil, for: exerciseID)
            template.setPlannedReps(reps, for: exerciseID)
        }
        return persistRoutine()
    }

    private func progressionSummary(for exercise: Exercise) -> String? {
        guard let sets = template.plannedSets(for: exercise.id), sets > 0,
              let state = template.progressionState(for: exercise.id) else {
            return nil
        }
        return WorkoutTargetFormatter.progressionConfigurationDisplay(
            setCount: sets,
            lowerRepBound: state.lowerRepBound,
            upperRepBound: state.upperRepBound,
            weightIncrementKg: state.weightIncrementKg
        )
    }

    private func progressionSeedWeight(for exerciseID: UUID) -> Double? {
        if let planned = template.plannedWeight(for: exerciseID), planned > 0 {
            return planned
        }

        return sessions.first(where: { candidate in
            candidate.templateId == template.id
                && candidate.isCompleted
                && candidate.setEntries.contains(where: {
                    $0.exerciseId == exerciseID
                        && $0.isCompleted
                        && !$0.isWarmup
                        && $0.weight > 0
                })
        })?
        .setEntries
        .filter {
            $0.exerciseId == exerciseID
                && $0.isCompleted
                && !$0.isWarmup
                && $0.weight > 0
        }
        .sorted { $0.setIndex < $1.setIndex }
        .last?
        .weight
    }

    /// Snapshot of a just-removed exercise so the toast Undo can restore the
    /// row at its original position with its prior planned target. Reordering
    /// or further edits in the meantime aren't a concern: the snapshot is
    /// scoped to a single four-second toast lifetime, and a new removal supersedes
    /// the prior snapshot before its toast fires.
    private struct RemovedExerciseSnapshot {
        let id = UUID()
        let exerciseName: String
        let templateState: DayTemplateExerciseStateSnapshot
    }

    /// Remove with snapshot — pairs with the bottom-anchored Undo toast. The
    /// canonical `removeExercise(_:)` is preserved for non-toast paths
    /// (programmatic / drag cleanup) so this helper only adds the user-facing
    /// undo path without forking deletion semantics.
    private func removeExerciseWithUndo(_ exercise: Exercise) {
        let id = exercise.id
        guard let templateState = template.removeExerciseAndCaptureState(id) else { return }

        let snapshot = RemovedExerciseSnapshot(
            exerciseName: exercise.displayName,
            templateState: templateState
        )
        guard persistRoutine() else { return }
        lastRemoved = snapshot
        toastMessage = .init(AppCopy.Toast.removedExercise(exercise.displayName), action: AppToastAction(id: snapshot.id, label: AppCopy.Toast.undo) {
            undoRemove(snapshotID: snapshot.id)
        })
    }

    private func undoRemove(snapshotID: UUID) {
        guard let snapshot = lastRemoved, snapshot.id == snapshotID else { return }
        template.restoreExerciseState(snapshot.templateState)
        guard persistRoutine() else { return }
        lastRemoved = nil
    }

}

private struct TemplateExerciseReorderDropDelegate: DropDelegate {
    let targetExerciseID: UUID
    let template: DayTemplate
    let modelContext: ModelContext
    @Binding var draggedExerciseID: UUID?
    var reduceMotion: Bool = false

    func dropEntered(info: DropInfo) {
        guard let draggedExerciseID,
              draggedExerciseID != targetExerciseID,
              let fromIndex = template.orderedExerciseIds.firstIndex(of: draggedExerciseID),
              let toIndex = template.orderedExerciseIds.firstIndex(of: targetExerciseID) else {
            return
        }

        withAnimation(reduceMotion ? nil : .appConfirm) {
            var ids = template.orderedExerciseIds
            let moved = ids.remove(at: fromIndex)
            ids.insert(moved, at: toIndex)
            template.orderedExerciseIds = ids
        }
        AppHaptic.select.fire()
    }

    func performDrop(info: DropInfo) -> Bool {
        try? modelContext.save()
        draggedExerciseID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let template = (try? container.mainContext.fetch(FetchDescriptor<DayTemplate>()))?.first

        return Group {
            if let template {
                TemplateDetailView(template: template)
                    .modelContainer(container)
            }
        }
    }
}
