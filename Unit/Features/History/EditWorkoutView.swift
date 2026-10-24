//
//  EditWorkoutView.swift
//  Unit
//
//  Corrects a finished workout: edit or delete a logged set, or delete the
//  whole workout. Same pattern as Programs > Edit program: the pencil opens
//  it, the trash deletes with a confirm, the checkmark closes. Every change
//  saves at once.
//

import SwiftData
import SwiftUI

/// The set an Edit set sheet is open for.
struct PastSetDraft: Identifiable {
    let id: UUID
    let exerciseName: String
    let setNumber: Int
    let weightKg: Double
    let reps: Int
    let isBodyweight: Bool
}

struct EditWorkoutView: View {
    @Bindable var session: WorkoutSession
    /// Deletes the workout and leaves the detail screen. False when the save
    /// failed and the workout is still there.
    let onDeleteWorkout: () -> Bool

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @AppStorage("unitSystem") private var unitSystem = "kg"

    @State private var editingSet: PastSetDraft?
    @State private var showsDeleteConfirmation = false
    @State private var removedSet: SetEntrySnapshot?
    @State private var toastMessage: AppToastEvent?
    /// Set just before the workout is deleted, so the screen never reads it again.
    @State private var isDeleting = false

    private var editorContext: PastWorkoutEditor.Context {
        PastWorkoutEditor.Context(
            modelContext: modelContext,
            sessions: allSessions,
            templates: templates,
            exercises: exercises
        )
    }

    private var exerciseSnapshots: [SessionExerciseSnapshot] {
        makeSessionDetailExerciseSnapshots(
            for: session,
            exercises: exercises,
            templates: templates,
            prSetEntryIDs: PRHistory.prSetEntryIDs(in: allSessions)
        )
    }

    private var hasSavedTarget: Bool {
        session.progressionRecordsByExerciseId.values.contains { $0.acceptedTarget != nil }
    }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            if !isDeleting {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    if hasSavedTarget {
                        Text(AppCopy.History.savedTargetsStay)
                            .font(AppFont.muted.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if exerciseSnapshots.isEmpty {
                        AppEmptyHint(AppCopy.History.noLoggedSets)
                    } else {
                        AppCardList(exerciseSnapshots) { exercise in
                            SessionExerciseSummary(
                                exercise: exercise,
                                onEditSet: { beginEditing($0, in: exercise) },
                                onDeleteSet: deleteSet
                            )
                            .padding(.vertical, AppSpacing.sm)
                        }
                    }
                }
                .appScreenEnter()
            }
        }
        .navigationTitle(AppCopy.History.editWorkout)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Group {
                    Button(role: .destructive) {
                        showsDeleteConfirmation = true
                    } label: {
                        Label(AppCopy.History.deleteWorkout, systemImage: AppIcon.trash.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(AppCopy.History.deleteWorkout)
                    .accessibilityIdentifier("delete-workout")
                    .confirmationDialog(
                        AppCopy.History.deleteWorkout,
                        isPresented: $showsDeleteConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(AppCopy.History.deleteWorkout, role: .destructive, action: deleteWorkout)
                    } message: {
                        Text(AppCopy.History.deleteWorkoutMessage)
                    }
                }
                .tint(AppColor.textPrimary)
            }
            ToolbarItem(placement: .confirmationAction) {
                Group {
                    Button { dismiss() } label: {
                        Label(AppCopy.Nav.done, systemImage: AppIcon.checkmark.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(AppCopy.Nav.done)
                    .accessibilityIdentifier("edit-workout-done")
                }
                .tint(AppColor.textPrimary)
            }
        }
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .appToast(event: editingSet == nil ? $toastMessage : .constant(nil))
        .sheet(item: $editingSet) { draft in
            EditSetSheet(draft: draft, unitSystem: unitSystem) { weightKg, reps in
                saveSet(draft, weightKg: weightKg, reps: reps)
            }
        }
    }

    private func beginEditing(_ set: SessionSetSnapshot, in exercise: SessionExerciseSnapshot) {
        toastMessage = nil
        editingSet = PastSetDraft(
            id: set.id,
            exerciseName: exercise.name,
            setNumber: set.setIndex + 1,
            weightKg: set.actualWeight,
            reps: set.actualReps,
            isBodyweight: exercise.isBodyweight
        )
    }

    private func saveSet(_ draft: PastSetDraft, weightKg: Double, reps: Int) -> Bool {
        guard let entry = session.setEntries.first(where: { $0.id == draft.id }),
              PastWorkoutEditor.update(entry, weightKg: weightKg, reps: reps, in: session, editorContext) else {
            AppHaptic.error.fire()
            return false
        }
        AppHaptic.tap.fire()
        return true
    }

    /// Removes at once with Undo, like a logged set in a live workout. The
    /// last set left asks the Delete workout question instead.
    private func deleteSet(_ set: SessionSetSnapshot) {
        guard let entry = session.setEntries.first(where: { $0.id == set.id }) else { return }
        guard session.setEntries.contains(where: { $0.isCompleted && $0.id != set.id }) else {
            showsDeleteConfirmation = true
            return
        }
        guard let snapshot = PastWorkoutEditor.delete(entry, from: session, editorContext) else {
            toastMessage = .init(AppCopy.History.saveFailed, kind: .error)
            AppHaptic.error.fire()
            return
        }
        removedSet = snapshot
        toastMessage = .init(
            AppCopy.History.setRemoved,
            action: .init(id: snapshot.id, label: AppCopy.Toast.undo) {
                undoRemovedSet(snapshotID: snapshot.id)
            }
        )
        AppHaptic.warning.fire()
    }

    private func undoRemovedSet(snapshotID: UUID) {
        guard let snapshot = removedSet, snapshot.id == snapshotID else { return }
        guard PastWorkoutEditor.restore(snapshot, in: session, editorContext) else {
            toastMessage = .init(AppCopy.History.saveFailed, kind: .error)
            AppHaptic.error.fire()
            return
        }
        removedSet = nil
        AppHaptic.tap.fire()
    }

    private func deleteWorkout() {
        isDeleting = true
        guard onDeleteWorkout() else {
            isDeleting = false
            toastMessage = .init(AppCopy.History.saveFailed, kind: .error)
            AppHaptic.error.fire()
            return
        }
        AppHaptic.warning.fire()
    }
}
