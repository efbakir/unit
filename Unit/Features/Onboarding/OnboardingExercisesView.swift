//
//  OnboardingExercisesView.swift
//  Unit
//
//  Screen 5 — Add exercises per training day.
//  Search or type to add. Minimum 1 exercise per day.
//

import SwiftUI
import UniformTypeIdentifiers

struct OnboardingExercisesView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var progressStep: Int
    var progressTotal: Int
    /// True while the parent is writing the program to SwiftData. Disables the
    /// CTA and swaps the label to a saving copy so the user gets a clear
    /// in-flight signal and a re-entrancy guard against double-tap.
    var isCommitting: Bool = false
    var onContinue: () -> Void
    var onBack: () -> Void

    @State private var selectedDayIndex: Int = 0
    @State private var showingAddSheet: Bool = false
    @FocusState private var focusedExerciseID: UUID?
    @State private var draggedExerciseID: UUID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    /// Bound to the screen's `appToast(message:action:)`. Set when the user
    /// taps × on an exercise; auto-dismisses after 3 s. Pairs with `lastRemoved`.
    @State private var toastMessage: String?
    /// Snapshot of the most recently removed exercise so the toast Undo can
    /// reinsert at the original index. Cleared on successful undo.
    @State private var lastRemoved: RemovedOnboardingSnapshot?

    /// Snapshot for `lastRemoved` — captures the day, index, and the full
    /// exercise value type. `OnboardingExercise` is a struct, so the copy is a
    /// genuine snapshot (no shared SwiftData identity to drift).
    private struct RemovedOnboardingSnapshot {
        let exercise: OnboardingExercise
        let dayIndex: Int
        let index: Int
    }

    private func exerciseNameBinding(dayIndex: Int, exerciseID: UUID) -> Binding<String> {
        Binding(
            get: {
                guard vm.dayExercises.indices.contains(dayIndex),
                      let i = vm.dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseID }) else {
                    return ""
                }
                return vm.dayExercises[dayIndex][i].name
            },
            set: { newValue in
                guard vm.dayExercises.indices.contains(dayIndex),
                      let i = vm.dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseID }) else {
                    return
                }
                vm.dayExercises[dayIndex][i].name = newValue
            }
        )
    }

    var body: some View {
        @Bindable var vm = vm
        let dayExs = vm.dayExercises.indices.contains(selectedDayIndex) ? vm.dayExercises[selectedDayIndex] : []

        OnboardingShell(
            title: "Add exercises",
            ctaLabel: isCommitting ? "Saving…" : "Start training",
            ctaEnabled: vm.exercisesAreValid && !isCommitting,
            // Hide the gate caption during the brief commit window — the
            // "Saving…" label is the status; the hint is only useful while
            // the user can still act on it.
            ctaDisabledReason: (isCommitting || vm.exercisesAreValid) ? nil : AppCopy.FormHint.onboardingExercisesRequired,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue,
            onBack: onBack,
            content: {
                if dayExs.isEmpty {
                    // Empty state owns the Add Exercise affordance inline,
                    // vertically centered in the available scroll area —
                    // matches the "nothing here yet, do this" anchor pattern
                    // used by other empty states (no competing CTAs above
                    // the disabled "Start training" button at the bottom).
                    // The bottom-floating overlay is suppressed in this state
                    // (see `floatingAccessory:`) so there is exactly one pill
                    // on screen at any time.
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        AppFloatingPillButton(
                            AppCopy.Workout.addExercise,
                            icon: .add,
                            style: .elevated
                        ) {
                            showingAddSheet = true
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity)
                    // Claim the full ScrollView viewport so the Spacers above
                    // and below the pill have something to push against —
                    // without this the inner VStack hugs the pill's natural
                    // size and "centered" collapses to top-aligned.
                    .containerRelativeFrame(.vertical)
                } else {
                    VStack(alignment: .leading, spacing: AppSpacing.md) {
                        AppCardList(dayExs, rowVerticalInset: AppSpacing.lg) { ex in
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                HStack(spacing: AppSpacing.sm) {
                                    AppIcon.reorder.image(size: 15, weight: .semibold)
                                        .foregroundStyle(AppColor.textSecondary)
                                        .frame(width: 44, height: 44)
                                        .accessibilityHidden(true)

                                    TextField("Exercise name", text: exerciseNameBinding(dayIndex: selectedDayIndex, exerciseID: ex.id))
                                        .font(AppFont.body.font)
                                        .foregroundStyle(AppColor.textPrimary)
                                        .focused($focusedExerciseID, equals: ex.id)
                                        .textInputAutocapitalization(.words)
                                        .autocorrectionDisabled()
                                        .submitLabel(.done)
                                        .frame(minWidth: 0, maxWidth: .infinity)

                                    Button {
                                        removeOnboardingExerciseWithUndo(ex, dayIndex: selectedDayIndex)
                                    } label: {
                                        AppIcon.close.image(size: 15, weight: .semibold)
                                            .foregroundStyle(AppColor.textSecondary)
                                            .frame(width: 44, height: 44)
                                            .contentShape(Rectangle())
                                    }
                                }

                                HStack(spacing: AppSpacing.sm) {
                                    plannedStepper(
                                        label: "Sets",
                                        value: ex.plannedSets,
                                        range: OnboardingExercise.plannedSetsRange,
                                        onDecrement: { vm.adjustPlannedSets(dayIndex: selectedDayIndex, exerciseId: ex.id, delta: -1) },
                                        onIncrement: { vm.adjustPlannedSets(dayIndex: selectedDayIndex, exerciseId: ex.id, delta: 1) }
                                    )
                                    plannedStepper(
                                        label: "Reps",
                                        value: ex.plannedReps,
                                        range: OnboardingExercise.plannedRepsRange,
                                        onDecrement: { vm.adjustPlannedReps(dayIndex: selectedDayIndex, exerciseId: ex.id, delta: -1) },
                                        onIncrement: { vm.adjustPlannedReps(dayIndex: selectedDayIndex, exerciseId: ex.id, delta: 1) }
                                    )
                                }
                            }
                            // Compensates the optical whitespace baked into the
                            // 44pt tap-target frames around the ≡ / × glyphs at
                            // the top of the row — the row chrome's 24pt
                            // vertical inset is symmetric, but the centered
                            // 15pt glyphs leave ~14.5pt of empty space above
                            // their visible tops, while the stepper pill at
                            // the bottom hugs the chrome with no equivalent
                            // optical buffer. Pulling the content up matches
                            // visible top whitespace to bottom.
                            .padding(.top, -AppSpacing.md)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                focusedExerciseID = ex.id
                            }
                            .appReorderable(
                                id: ex.id,
                                draggedID: $draggedExerciseID,
                                reduceMotion: reduceMotion
                            ) {
                                onboardingExerciseDragPreview(for: ex)
                            }
                            .onDrop(
                                of: [UTType.text],
                                delegate: ExerciseReorderDropDelegate(
                                    targetExerciseID: ex.id,
                                    exercises: $vm.dayExercises[selectedDayIndex],
                                    draggedExerciseID: $draggedExerciseID,
                                    reduceMotion: reduceMotion
                                )
                            )
                        }
                    }
                }
            },
            stickyAccessory: {
                AppFilterChipBar {
                    ForEach(0..<vm.dayCount, id: \.self) { i in
                        AppFilterChip(
                            label: vm.dayNames[i],
                            isSelected: selectedDayIndex == i,
                            showsTrailingDot: vm.dayExercises[i].isEmpty
                        ) {
                            selectedDayIndex = i
                        }
                    }
                }
            },
            floatingAccessory: {
                // Suppressed in the empty state — the inline pill in `content:`
                // already serves the same affordance, vertically centered. Once
                // the user has at least one exercise, the bottom-floating pill
                // takes over so adding more never requires scrolling to the
                // bottom of a long list. `.elevated` keeps the black-fill
                // weight unique to the sticky "Start training" primary CTA
                // below — two black pills in the same chrome read as competing
                // primaries.
                if !dayExs.isEmpty {
                    AppFloatingPillButton(
                        AppCopy.Workout.addExercise,
                        icon: .add,
                        style: .elevated
                    ) {
                        showingAddSheet = true
                    }
                }
            }
        )
        .sheet(isPresented: $showingAddSheet, onDismiss: {
            focusedExerciseID = nil
        }) {
            ExerciseSearchSheet(dayIndex: selectedDayIndex)
                .environment(vm)
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .onChange(of: selectedDayIndex) { _, _ in
            focusedExerciseID = nil
            draggedExerciseID = nil
        }
        .onChange(of: vm.dayCount) { _, newValue in
            if selectedDayIndex >= newValue {
                selectedDayIndex = max(0, newValue - 1)
            }
            focusedExerciseID = nil
            draggedExerciseID = nil
        }
        .appToast(
            message: $toastMessage,
            action: lastRemoved == nil
                ? nil
                : AppToastAction(label: AppCopy.Toast.undo, handler: undoRemoveOnboardingExercise)
        )
    }

    private func removeOnboardingExerciseWithUndo(_ ex: OnboardingExercise, dayIndex: Int) {
        guard vm.dayExercises.indices.contains(dayIndex),
              let index = vm.dayExercises[dayIndex].firstIndex(where: { $0.id == ex.id }) else { return }
        lastRemoved = RemovedOnboardingSnapshot(exercise: ex, dayIndex: dayIndex, index: index)
        vm.dayExercises[dayIndex].remove(at: index)
        if focusedExerciseID == ex.id {
            focusedExerciseID = nil
        }
        toastMessage = AppCopy.Toast.removedExercise(ex.name)
    }

    private func undoRemoveOnboardingExercise() {
        guard let snapshot = lastRemoved,
              vm.dayExercises.indices.contains(snapshot.dayIndex) else {
            lastRemoved = nil
            return
        }
        // Clamp the restore index in case the user reordered or removed
        // another row before tapping undo.
        let dayList = vm.dayExercises[snapshot.dayIndex]
        let safeIndex = min(max(snapshot.index, 0), dayList.count)
        vm.dayExercises[snapshot.dayIndex].insert(snapshot.exercise, at: safeIndex)
        lastRemoved = nil
    }

    @ViewBuilder
    private func plannedStepper(
        label: String,
        value: Int,
        range: ClosedRange<Int>,
        onDecrement: @escaping () -> Void,
        onIncrement: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(label)
                .appCapsLabel(.smallLabel)
                .foregroundStyle(AppColor.textSecondary)
            AppStepper(
                value: "\(value)",
                minimumValueWidth: AppSpacing.md,
                isDecrementEnabled: value > range.lowerBound,
                isIncrementEnabled: value < range.upperBound,
                onDecrement: onDecrement,
                onIncrement: onIncrement
            )
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func onboardingExerciseDragPreview(for ex: OnboardingExercise) -> some View {
        HStack(spacing: AppSpacing.sm) {
            AppIcon.reorder.image(size: 15, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
                .frame(width: 44, alignment: .leading)

            Text(ex.name.isEmpty ? "Exercise" : ex.name)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .lineLimit(1)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 56)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppColor.cardBackground)
        )
    }
}

private struct ExerciseReorderDropDelegate: DropDelegate {
    let targetExerciseID: UUID
    @Binding var exercises: [OnboardingExercise]
    @Binding var draggedExerciseID: UUID?
    var reduceMotion: Bool = false

    func dropEntered(info: DropInfo) {
        guard let draggedExerciseID,
              draggedExerciseID != targetExerciseID,
              let fromIndex = exercises.firstIndex(where: { $0.id == draggedExerciseID }),
              let toIndex = exercises.firstIndex(where: { $0.id == targetExerciseID }) else {
            return
        }

        withAnimation(reduceMotion ? nil : .appConfirm) {
            let movedExercise = exercises.remove(at: fromIndex)
            exercises.insert(movedExercise, at: toIndex)
        }
        AppHaptic.reorderSwap.fire()
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedExerciseID = nil
        return true
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        DropProposal(operation: .move)
    }
}

// MARK: - Exercise Search Sheet

struct ExerciseSearchSheet: View {
    @Environment(OnboardingViewModel.self) private var vm
    @Environment(\.dismiss) private var dismiss
    let dayIndex: Int

    @State private var query: String = ""

    private var filteredSuggestions: [String] {
        let existing = vm.dayExercises[dayIndex].map { $0.name.lowercased() }
        return ExerciseLibrary.filtered(by: query).filter { !existing.contains($0.lowercased()) }
    }

    private var showCustomOption: Bool {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return false }
        return !ExerciseLibrary.suggestions.contains(where: { $0.lowercased() == q.lowercased() })
            && !vm.dayExercises[dayIndex].contains(where: { $0.name.lowercased() == q.lowercased() })
    }

    var body: some View {
        NavigationStack {
            List {
                if showCustomOption {
                    let trimmed = query.trimmingCharacters(in: .whitespaces)
                    Button {
                        addExercise(name: trimmed)
                    } label: {
                        HStack(spacing: AppSpacing.sm) {
                            AppIcon.addCircle.image()
                                .foregroundStyle(AppColor.accent)
                            Text("Add \"\(trimmed)\"")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.textPrimary)
                        }
                        .frame(minHeight: 44, alignment: .leading)
                    }
                    .appPlainListRowChrome()
                }

                ForEach(filteredSuggestions, id: \.self) { name in
                    Button {
                        addExercise(name: name)
                    } label: {
                        Text(name)
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .frame(minHeight: 44, alignment: .leading)
                    }
                    .appPlainListRowChrome()
                }

                // Empty-row hint when both the catalog and the create-affordance
                // have nothing to show. Same pattern as the in-workout picker.
                if filteredSuggestions.isEmpty && !showCustomOption {
                    Text(query.trimmingCharacters(in: .whitespaces).isEmpty
                         ? AppCopy.Search.noExercisesYet
                         : AppCopy.Search.noMatchingExercises)
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .frame(minHeight: 44, alignment: .leading)
                        .appPlainListRowChrome(separator: .hidden)
                }
            }
            .listSectionSpacing(0)
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(AppColor.sheetBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(AppCopy.Workout.addExercise)
            .navigationBarTitleDisplayMode(.inline)
            .appExerciseSearchable(text: $query)
            .onSubmit(of: .search) {
                let trimmed = query.trimmingCharacters(in: .whitespaces)
                guard !trimmed.isEmpty else { return }
                addExercise(name: trimmed)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Nav.done) { dismiss() }
                        .appToolbarTextStyle()
                }
            }
            .appNavigationBarChrome()
            .tint(AppColor.accent)
        }
    }

    private func addExercise(name: String) {
        let ex = OnboardingExercise(name: name)
        vm.dayExercises[dayIndex].append(ex)
        query = ""
        dismiss()
    }
}

#Preview {
    OnboardingExercisesView(progressStep: 4, progressTotal: 4, onContinue: {}, onBack: {})
        .environment({
            let vm = OnboardingViewModel()
            vm.seedSampleData()
            return vm
        }())
        .tint(AppColor.accent)
}
