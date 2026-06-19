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
//   - Sticky bottom "Start your first workout" CTA — one action.
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
    }

    // Sticky CTA — routed through OnboardingShell's pinned bottom button (the
    // same AppScreen(primaryButton:) every other onboarding step uses) so the
    // button stays at the screen edge instead of scrolling off with the program
    // list when every day is expanded.
    private var ctaLabel: String {
        guard hasAnyExercise else { return "Back to import" }
        return isCommitting ? "Starting…" : "Start your first workout"
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
        switch vm.importMethod {
        case .library: return "Tap a weight to adjust before starting."
        case .paste: return "Tap a weight to adjust before starting."
        }
    }

    @ViewBuilder
    private var content: some View {
        VStack(spacing: AppSpacing.md) {
            warningBanner

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
                        Text("✱")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .accessibilityLabel("Defaulted sets and reps; tap to override post-subscribe")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            weightField(dayIndex: dayIndex, exercise: exercise)
        }
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
    /// Empty string for nil — TextField shows the "—" prompt then.
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
            Text("We couldn't read your routine.")
                .font(AppFont.title.font)
                .foregroundStyle(AppColor.textPrimary)
                .multilineTextAlignment(.center)

            Text("Try paste again or pick a program from the library.")
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
