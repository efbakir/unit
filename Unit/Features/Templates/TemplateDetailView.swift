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
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @State private var showingAddExercise = false
    @State private var draggedExerciseID: UUID?
    @State private var targetEditPayload: TargetEditPayload?
    /// Toast message shown after a non-destructive × removal. Bound to the
    /// `appToast(message:action:)` modifier on the screen root; auto-dismiss is
    /// owned by `AppToast` (3s) so this view only sets it.
    @State private var toastMessage: String?
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
                    }
                }

                AppGhostButton(AppCopy.Workout.addExercise) {
                    showingAddExercise = true
                }
            }
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
                subtitle: payload.exerciseName,
                initialSets: payload.setCount,
                initialReps: payload.reps
            ) { setCount, reps in
                saveTarget(setCount: setCount, reps: reps, for: payload.exerciseID)
            }
        }
        .appToast(
            message: $toastMessage,
            action: lastRemoved == nil
                ? nil
                : AppToastAction(label: AppCopy.Toast.undo, handler: undoRemove)
        )
        .tint(AppColor.accent)
    }

    private func addExercise(_ exercise: Exercise) {
        var ids = template.orderedExerciseIds
        ids.append(exercise.id)
        template.orderedExerciseIds = ids
        try? modelContext.save()
    }

    private func exerciseRow(_ exercise: Exercise) -> some View {
        HStack(spacing: AppSpacing.sm) {
            Button {
                targetEditPayload = targetEditPayload(for: exercise)
            } label: {
                HStack(spacing: AppSpacing.sm) {
                    AppIcon.reorder.image(size: 15, weight: .semibold)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                        .accessibilityHidden(true)

                    Text(exercise.displayName)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)

                    exerciseTargetSubtitle(for: exercise)
                }
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Edit target for \(exercise.displayName)")
            .accessibilityValue(targetAccessibilityValue(for: exercise))

            Button {
                removeExerciseWithUndo(exercise)
            } label: {
                AppIcon.close.image(size: 15, weight: .semibold)
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
        HStack(spacing: AppSpacing.sm) {
            AppIcon.reorder.image(size: 15, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 44, alignment: .leading)

            Text(exercise.displayName)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            Spacer(minLength: AppSpacing.sm)

            exerciseTargetSubtitle(for: exercise)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: 320, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColor.cardBackground)
        )
    }

    @ViewBuilder
    private func exerciseTargetSubtitle(for exercise: Exercise) -> some View {
        if let planned = plannedTargetDisplay(for: exercise) {
            Text(WorkoutTargetFormatter.setRepCompact(setCount: planned.setCount, reps: planned.reps) ?? "")
                .font(AppFont.performance.font)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
        } else {
            Text(ghostEmptySubtitle(for: exercise))
                .font(AppFont.caption.font)
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
        // Ghost value: last completed set for this exercise across all sessions
        if let lastSession = sessions.first(where: {
            $0.isCompleted &&
            $0.setEntries.contains(where: { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup })
        }) {
            let sets = lastSession.setEntries
                .filter { $0.exerciseId == exercise.id && $0.isCompleted && !$0.isWarmup }
                .sorted { $0.setIndex < $1.setIndex }

            if let lastSet = sets.last, lastSet.reps > 0,
               exercise.isBodyweight || lastSet.weight > 0 {
                return PlannedTargetDisplay(setCount: max(sets.count, 1), reps: lastSet.reps)
            }
        }

        return nil
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
            reps: target.reps
        )
    }

    private func targetAccessibilityValue(for exercise: Exercise) -> String {
        guard let planned = plannedTargetDisplay(for: exercise) else {
            return ghostEmptySubtitle(for: exercise)
        }

        return "\(planned.setCount) sets, \(planned.reps) reps"
    }

    private func saveTarget(setCount: Int, reps: Int, for exerciseID: UUID) {
        template.setPlannedSets(setCount, for: exerciseID)
        template.setPlannedReps(reps, for: exerciseID)
        try? modelContext.save()
    }

    private func removeExercise(_ exerciseID: UUID) {
        var ids = template.orderedExerciseIds
        ids.removeAll { $0 == exerciseID }
        template.orderedExerciseIds = ids
        template.setPlannedSets(nil, for: exerciseID)
        template.setPlannedReps(nil, for: exerciseID)
        try? modelContext.save()
    }

    /// Snapshot of a just-removed exercise so the toast Undo can restore the
    /// row at its original position with its prior planned target. Reordering
    /// or further edits in the meantime aren't a concern: the snapshot is
    /// scoped to a single 3-second toast lifetime, and a new removal supersedes
    /// the prior snapshot before its toast fires.
    private struct RemovedExerciseSnapshot {
        let exerciseID: UUID
        let exerciseName: String
        let index: Int
        let plannedSets: Int?
        let plannedReps: Int?
    }

    /// Remove with snapshot — pairs with the bottom-anchored Undo toast. The
    /// canonical `removeExercise(_:)` is preserved for non-toast paths
    /// (programmatic / drag cleanup) so this helper only adds the user-facing
    /// undo path without forking deletion semantics.
    private func removeExerciseWithUndo(_ exercise: Exercise) {
        let id = exercise.id
        let ids = template.orderedExerciseIds
        guard let index = ids.firstIndex(of: id) else { return }

        let snapshot = RemovedExerciseSnapshot(
            exerciseID: id,
            exerciseName: exercise.displayName,
            index: index,
            plannedSets: template.plannedSets(for: id),
            plannedReps: template.plannedReps(for: id)
        )
        lastRemoved = snapshot

        var newIds = ids
        newIds.remove(at: index)
        template.orderedExerciseIds = newIds
        template.setPlannedSets(nil, for: id)
        template.setPlannedReps(nil, for: id)
        try? modelContext.save()

        toastMessage = AppCopy.Toast.removedExercise(exercise.displayName)
    }

    private func undoRemove() {
        guard let snapshot = lastRemoved else { return }
        var ids = template.orderedExerciseIds
        // Clamp the restore index in case the list shifted between removal
        // and undo (drag, another edit) — we still want a sane insertion.
        let safeIndex = min(max(snapshot.index, 0), ids.count)
        ids.insert(snapshot.exerciseID, at: safeIndex)
        template.orderedExerciseIds = ids
        template.setPlannedSets(snapshot.plannedSets, for: snapshot.exerciseID)
        template.setPlannedReps(snapshot.plannedReps, for: snapshot.exerciseID)
        try? modelContext.save()
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
        AppHaptic.reorderSwap.fire()
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
