//
//  OnboardingProgramPreviewView.swift
//  Unit
//
//  Phase B-4 — the wow surface. Replaces the 548-line `OnboardingExercisesView`.
//  Shows the user's program populated with their numbers (1RM-derived for
//  library path, paste-derived for paste path), confirms parser warnings
//  inline (Q6), and hands off to the paywall via the sticky bottom CTA.
//
//  Decisions locked 2026-06-17 (Q5 + Q6):
//   - Vertical day cards stacked (not tabs / not swipe).
//   - First day expanded, others collapsed (user-picked over my "all expanded").
//   - Inline weight edit only — exercise names + sets/reps stay fixed.
//   - Sticky bottom "Choose a plan" CTA — one action; commits the program
//     and hands off to the hard paywall (subscription required before logging).
//   - Paste warnings inline: banner for noisy lines + dropped conditioning;
//     ✱ hint on rows where sets/reps look like a parser default (3×10).
//   - Empty-state fallback when parse produced zero exercises.
//

import SwiftUI

struct OnboardingProgramPreviewView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var progressStep: Int
    var progressTotal: Int
    /// True while the parent is writing the program to SwiftData. Disables
    /// the CTA and swaps the label to a saving copy.
    var isCommitting: Bool = false
    var onContinue: () -> Void
    var onBack: () -> Void

    /// Per-day expansion state. Day 0 starts true (the wow lands without a
    /// tap); the rest open on demand. Keyed by day index, not by name —
    /// names can be edited post-paywall and we don't want state to leak.
    @State private var expandedDays: [Int: Bool] = [0: true]
    @State private var editingExercise: PreviewExerciseEditTarget?
    @State private var demoSetLogged = false

    private struct PreviewExerciseEditTarget: Identifiable {
        let dayIndex: Int
        let exerciseID: UUID
        var id: UUID { exerciseID }
    }

    private var hasAnyExercise: Bool {
        vm.dayExercises.flatMap { $0 }.isEmpty == false
    }

    var body: some View {
        OnboardingShell(
            title: previewTitle,
            subtitle: previewSubtitle,
            ctaLabel: ctaLabel,
            ctaEnabled: ctaEnabled,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: ctaAction,
            onBack: onBack
        ) {
            if hasAnyExercise {
                content
            } else {
                emptyParseState
            }
        }
        .appHaptic(.setLogged, trigger: demoSetLogged) { old, new in
            !old && new
        }
        .sheet(item: $editingExercise) { target in
            AppSheetScreen(
                title: "Edit exercise",
                dismissLabel: AppCopy.Nav.done,
                dismissActionPlacement: .confirmation,
                onDismissAction: { editingExercise = nil },
                usesOuterScroll: false
            ) {
                exerciseEditor(for: target)
            }
            .presentationDetents([.medium])
            .appBottomSheetChrome()
        }
    }

    // Sticky CTA — routed through OnboardingShell's pinned bottom button (the
    // same AppScreen(primaryButton:) every other onboarding step uses) so the
    // button stays at the screen edge instead of scrolling off with the program
    // list when every day is expanded.
    private var ctaLabel: String {
        guard hasAnyExercise else { return "Back to import" }
        return isCommitting ? "Opening plans…" : "Choose a plan"
    }

    private var ctaEnabled: Bool {
        hasAnyExercise ? !isCommitting : true
    }

    private var ctaAction: () -> Void {
        hasAnyExercise ? onContinue : onBack
    }

    private var previewTitle: String {
        switch vm.importMethod {
        case .library: return "Your program"
        case .paste: return "Here's what I read"
        }
    }

    private var previewSubtitle: String {
        "Review every field now. A subscription is required before logging."
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: AppSpacing.md) {
            warningBanner
            loggingDemoCard

            ForEach(Array(vm.dayExercises.enumerated()), id: \.offset) { dayIndex, exercises in
                AppDisclosureCard(
                    isExpanded: bindingForDay(dayIndex)
                ) {
                    dayHeader(dayIndex: dayIndex, exercises: exercises)
                } content: {
                    VStack(spacing: 0) {
                        AppDivider()
                        AppDividedList(exercises) { exercise in
                            exerciseRow(dayIndex: dayIndex, exercise: exercise)
                                .appCardRowChrome()
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var loggingDemoCard: some View {
        if let exercise = demoExercise {
            AppCard {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                            Text("Ready to log set #1?")
                                .font(AppFont.sectionHeader.font)
                                .foregroundStyle(AppColor.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            if demoSetLogged {
                                AppIcon.checkmarkFilled.image(size: 15, weight: .semibold)
                                    .foregroundStyle(AppColor.accent)
                                    .accessibilityHidden(true)
                            }
                        }

                        Text(exercise.name)
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Last time: \(demoValueText(for: exercise))")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .monospacedDigit()
                    }

                    if demoSetLogged {
                        HStack(spacing: AppSpacing.sm) {
                            AppIcon.checkmarkFilled.image(size: 15, weight: .semibold)
                                .foregroundStyle(AppColor.accent)
                                .accessibilityHidden(true)

                            Text("Set logged")
                                .font(AppFont.body.font)
                                .foregroundStyle(AppColor.accent)
                        }
                        .frame(minHeight: 44)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .fill(AppColor.accentSoft)
                        )
                    } else {
                        AppGhostButton("Same as last time") {
                            // Demo only: visual state + haptic. No model write,
                            // no WorkoutSession, no SetEntry, no history.
                            demoSetLogged = true
                        }
                    }
                }
            }
        }
    }

    private var demoExercise: OnboardingExercise? {
        for exercises in vm.dayExercises {
            if let exercise = exercises.first { return exercise }
        }
        return nil
    }

    private func demoValueText(for exercise: OnboardingExercise) -> String {
        let weight = formatted(exercise.plannedWeightKg)
        guard !weight.isEmpty else {
            return "\(exercise.plannedReps) reps"
        }
        return "\(weight)\(vm.unitSystem) × \(exercise.plannedReps)"
    }

    private var dayName: (Int) -> String {
        { idx in
            guard idx < vm.dayNames.count else { return "Day \(idx + 1)" }
            let candidate = vm.dayNames[idx].trimmingCharacters(in: .whitespacesAndNewlines)
            return candidate.isEmpty ? "Day \(idx + 1)" : candidate
        }
    }

    @ViewBuilder
    private func dayHeader(dayIndex: Int, exercises: [OnboardingExercise]) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(dayName(dayIndex))
                .font(AppFont.title.font)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(exerciseCountLabel(exercises.count))
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
        }
    }

    private func exerciseCountLabel(_ count: Int) -> String {
        count == 1 ? "1 exercise" : "\(count) exercises"
    }

    @ViewBuilder
    private func exerciseRow(
        dayIndex: Int,
        exercise: OnboardingExercise
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(exercise.name)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .multilineTextAlignment(.leading)

                HStack(spacing: AppSpacing.xxs) {
                    Text("\(exercise.plannedSets)×\(exercise.plannedReps)")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()

                    if isParserDefault(exercise) {
                        Text("Check sets and reps")
                            .font(AppFont.muted.font)
                            .foregroundStyle(AppColor.warningOnSoft)
                    }
                }

                if vm.importMethod == .paste, !exercise.originalLine.isEmpty {
                    Text("From: \(exercise.originalLine)")
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppColor.textTertiary)
                        .lineLimit(2)
                }

                if !exercise.note.isEmpty {
                    Text(exercise.note)
                        .font(AppFont.muted.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Button {
                editingExercise = PreviewExerciseEditTarget(
                    dayIndex: dayIndex,
                    exerciseID: exercise.id
                )
            } label: {
                AppIcon.edit.image(size: 15, weight: .semibold)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel("Edit \(exercise.name), sets, and reps")

            weightField(dayIndex: dayIndex, exercise: exercise)
        }
    }

    @ViewBuilder
    private func exerciseEditor(for target: PreviewExerciseEditTarget) -> some View {
        if let index = exerciseIndex(for: target) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AppSectionHeader("Exercise")
                    TextField(
                        "Exercise name",
                        text: Binding(
                            get: { vm.dayExercises[target.dayIndex][index].name },
                            set: { vm.dayExercises[target.dayIndex][index].name = $0 }
                        )
                    )
                    .font(AppFont.body.font)
                    .textInputAutocapitalization(.words)
                    .appInputFieldStyle()
                }

                AppCardList(data: ["Sets", "Reps"], id: \.self) { label in
                    HStack(spacing: AppSpacing.md) {
                        Text(label)
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer(minLength: 0)
                        previewStepper(label: label, target: target, index: index)
                    }
                }
            }
        } else {
            AppEmptyHint("Exercise unavailable")
        }
    }

    private func previewStepper(label: String, target: PreviewExerciseEditTarget, index: Int) -> some View {
        let exercise = vm.dayExercises[target.dayIndex][index]
        let value = label == "Sets" ? exercise.plannedSets : exercise.plannedReps
        let range = label == "Sets"
            ? OnboardingExercise.plannedSetsRange
            : OnboardingExercise.plannedRepsRange

        return AppStepper(
            value: "\(value)",
            isDecrementEnabled: value > range.lowerBound,
            isIncrementEnabled: value < range.upperBound,
            onDecrement: {
                if label == "Sets" {
                    vm.dayExercises[target.dayIndex][index].plannedSets = max(range.lowerBound, value - 1)
                } else {
                    vm.dayExercises[target.dayIndex][index].plannedReps = max(range.lowerBound, value - 1)
                }
            },
            onIncrement: {
                if label == "Sets" {
                    vm.dayExercises[target.dayIndex][index].plannedSets = min(range.upperBound, value + 1)
                } else {
                    vm.dayExercises[target.dayIndex][index].plannedReps = min(range.upperBound, value + 1)
                }
            }
        )
    }

    private func exerciseIndex(for target: PreviewExerciseEditTarget) -> Int? {
        guard vm.dayExercises.indices.contains(target.dayIndex) else { return nil }
        return vm.dayExercises[target.dayIndex].firstIndex { $0.id == target.exerciseID }
    }

    /// Heuristic for Q6's "name-only with default sets/reps" hint. Triggers
    /// only when the exercise came from the paste path AND the sets/reps
    /// match the parser fallback. Library-picked exercises get explicit set
    /// counts from the program template and never trip this.
    private func isParserDefault(_ exercise: OnboardingExercise) -> Bool {
        guard vm.importMethod == .paste else { return false }
        return exercise.plannedSets == OnboardingExercise.defaultPlannedSets
            && exercise.plannedReps == OnboardingExercise.defaultPlannedReps
            && exercise.originalLine.isEmpty == false
    }

    @ViewBuilder
    private func weightField(
        dayIndex: Int,
        exercise: OnboardingExercise
    ) -> some View {
        AppInlineWeightField(
            text: Binding(
                get: { formatted(exercise.plannedWeightKg) },
                set: { commit(weight: $0, dayIndex: dayIndex, exerciseID: exercise.id) }
            ),
            unitSuffix: vm.unitSystem
        )
    }

    /// Displays kg internally; converts to lb at the boundary if user picked lb.
    /// Empty string for nil — the inline field renders an empty input then.
    private func formatted(_ kg: Double?) -> String {
        guard let kg, kg > 0 else { return "" }
        let display = vm.unitSystem == "lb" ? kg * 2.20462 : kg
        if display == display.rounded() {
            return String(format: "%.0f", display)
        }
        return String(format: "%.1f", display)
    }

    private func commit(weight raw: String, dayIndex: Int, exerciseID: UUID) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard dayIndex < vm.dayExercises.count,
              let idx = vm.dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseID }) else { return }
        if trimmed.isEmpty {
            vm.dayExercises[dayIndex][idx].plannedWeightKg = nil
            return
        }
        guard let value = Double(trimmed), value > 0 else { return }
        let kg = vm.unitSystem == "lb" ? value / 2.20462 : value
        vm.dayExercises[dayIndex][idx].plannedWeightKg = kg
    }

    private func bindingForDay(_ index: Int) -> Binding<Bool> {
        Binding(
            get: { expandedDays[index] ?? false },
            set: { expandedDays[index] = $0 }
        )
    }

    // MARK: - Warnings

    @ViewBuilder
    private var warningBanner: some View {
        let noisy = noisyLinesCount
        let conditioningLines = skippedConditioningLines
        if noisy > 0 || conditioningLines.isEmpty == false {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                if noisy > 0 {
                    Text(noisy == 1
                         ? "1 line didn't parse."
                         : "\(noisy) lines didn't parse.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                if conditioningLines.isEmpty == false {
                    Text(conditioningLines.count == 1
                         ? "1 cardio line skipped."
                         : "\(conditioningLines.count) cardio lines skipped.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
            }
            .padding(.horizontal, AppSpacing.md)
            .padding(.vertical, AppSpacing.sm)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .fill(AppColor.controlBackground)
            )
        }
    }

    private var noisyLinesCount: Int {
        for warning in vm.importWarnings {
            if case .noisyLines(let count) = warning {
                return count
            }
        }
        return 0
    }

    private var skippedConditioningLines: [String] {
        for warning in vm.importWarnings {
            if case .skippedConditioning(let lines) = warning {
                return lines
            }
        }
        return []
    }

    // MARK: - Empty state

    @ViewBuilder
    private var emptyParseState: some View {
        VStack(spacing: AppSpacing.md) {
            Text("Unit couldn't read your routine.")
                .font(AppFont.title.font)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text("Paste it again or pick a program from the library.")
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.xl)
    }
}

#Preview {
    NavigationStack {
        OnboardingProgramPreviewView(
            progressStep: 5,
            progressTotal: 5,
            onContinue: {},
            onBack: {}
        )
    }
    .environment(OnboardingViewModel())
}
