//
//  OnboardingLibraryPickerView.swift
//  Unit
//
//  Ready-made program path. Three catalog-backed questions rank existing
//  programs; Unit never claims to generate a new routine. The answers live in
//  OnboardingViewModel so back navigation and cold relaunch preserve progress.
//

import SwiftUI

struct OnboardingLibraryPickerView: View {
    @Environment(OnboardingViewModel.self) private var vm
    @State private var displayedStage: Stage?
    @State private var showsAllPrograms = false

    private static let defaultDaysPerWeek = 3
    private static let recommendationShortlistLimit = 3

    var progressStep: Int
    var progressTotal: Int
    var onUpdate: () -> Void
    var onContinue: () -> Void
    var onBack: () -> Void

    private enum Stage: Equatable {
        case goal
        case level
        case days
        case results
    }

    private struct DayCountOption: Identifiable, Hashable {
        let value: Int
        var id: Int { value }
    }

    private var stage: Stage {
        displayedStage ?? inferredStage
    }

    private var inferredStage: Stage {
        if vm.preferredGoal == nil { return .goal }
        if vm.preferredLevel == nil { return .level }
        if vm.preferredDaysPerWeek == nil { return .days }
        return .results
    }

    private var dayCountOptions: [DayCountOption] {
        ProgramCatalog.supportedDays.map { DayCountOption(value: $0) }
    }

    private var matchingPrograms: [ProgramTemplate] {
        guard let profile = vm.programMatchProfile else { return [] }
        return ProgramCatalog.recommendations(
            for: profile,
            limit: ProgramCatalog.all.count
        )
    }

    private var recommendedPrograms: [ProgramTemplate] {
        Array(matchingPrograms.prefix(Self.recommendationShortlistLimit))
    }

    private var additionalPrograms: [ProgramTemplate] {
        Array(matchingPrograms.dropFirst(Self.recommendationShortlistLimit))
    }

    var body: some View {
        OnboardingShell(
            title: title,
            subtitle: subtitle,
            ctaLabel: ctaLabel,
            ctaEnabled: ctaEnabled,
            progressStep: progressStep,
            progressTotal: progressTotal,
            progressDetail: progressDetail,
            onContinue: handleContinue,
            onBack: handleBack
        ) {
            stageContent
        } stickyAccessory: {
            if stage == .results {
                answerBar
            }
        }
        .onAppear {
            if displayedStage == nil {
                displayedStage = inferredStage
            }
            if stage == .days {
                preselectDefaultDaysIfNeeded()
            }
        }
    }

    private var ctaLabel: String {
        stage == .results ? AppCopy.Onboarding.libraryCTA : "Continue"
    }

    private var ctaEnabled: Bool {
        switch stage {
        case .goal: vm.preferredGoal != nil
        case .level: vm.preferredLevel != nil
        case .days: vm.preferredDaysPerWeek != nil
        case .results: vm.pickedProgram != nil
        }
    }

    private var progressDetail: OnboardingProgressBar.Detail? {
        switch stage {
        case .goal:
            OnboardingProgressBar.Detail(
                label: "Q 01 / 03",
                accessibilityLabel: "question 1 of 3"
            )
        case .level:
            OnboardingProgressBar.Detail(
                label: "Q 02 / 03",
                accessibilityLabel: "question 2 of 3"
            )
        case .days:
            OnboardingProgressBar.Detail(
                label: "Q 03 / 03",
                accessibilityLabel: "question 3 of 3"
            )
        case .results:
            nil
        }
    }

    private var title: String {
        switch stage {
        case .goal: AppCopy.Onboarding.libraryGoalTitle
        case .level: AppCopy.Onboarding.libraryLevelTitle
        case .days: AppCopy.Onboarding.libraryDaysTitle
        case .results: AppCopy.Onboarding.libraryResultsTitle
        }
    }

    private var subtitle: String {
        switch stage {
        case .goal: AppCopy.Onboarding.libraryGoalSubtitle
        case .level: AppCopy.Onboarding.libraryLevelSubtitle
        case .days: AppCopy.Onboarding.libraryDaysSubtitle
        case .results: AppCopy.Onboarding.libraryResultsSubtitle
        }
    }

    @ViewBuilder
    private var stageContent: some View {
        switch stage {
        case .goal:
            VStack(spacing: AppSpacing.sm) {
                ForEach(ProgramTemplate.Goal.allCases) { goal in
                    AppOptionTileCard(
                        title: goal.matcherDisplayName,
                        isSelected: vm.preferredGoal == goal
                    ) {
                        selectGoal(goal)
                    }
                }
            }

        case .level:
            VStack(spacing: AppSpacing.sm) {
                ForEach(ProgramTemplate.Level.allCases) { level in
                    AppOptionTileCard(
                        title: level.matcherDisplayName,
                        isSelected: vm.preferredLevel == level
                    ) {
                        selectLevel(level)
                    }
                }
            }

        case .days:
            AppSegmentedControl(
                selection: dayCountBinding,
                items: dayCountOptions,
                size: .weekday,
                label: "Training days",
                title: { "\($0.value)" },
                accessibilityLabel: { AppCopy.Onboarding.trainingDays($0.value) }
            )

        case .results:
            if recommendedPrograms.isEmpty {
                AppEmptyHint(AppCopy.Onboarding.libraryNoResults)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(recommendedPrograms.enumerated()), id: \.element.id) { index, program in
                        programOption(program, rank: index + 1)
                    }

                    if !additionalPrograms.isEmpty {
                        if showsAllPrograms {
                            ForEach(Array(additionalPrograms.enumerated()), id: \.element.id) { index, program in
                                programOption(
                                    program,
                                    rank: Self.recommendationShortlistLimit + index + 1
                                )
                            }
                        }

                        AppGhostButton(
                            showsAllPrograms
                                ? AppCopy.Onboarding.libraryShowFewerPrograms
                                : AppCopy.Onboarding.libraryShowMorePrograms(additionalPrograms.count)
                        ) {
                            toggleAdditionalPrograms()
                        }
                        .accessibilityIdentifier("show-all-matching-programs")
                    }
                }
            }
        }
    }

    private var answerBar: some View {
        AppFilterChipBar {
            AppDropdownChip(
                label: vm.preferredGoal?.matcherDisplayName ?? AppCopy.Onboarding.libraryGoalChip,
                isActive: true
            ) {
                Picker(AppCopy.Onboarding.libraryGoalChip, selection: goalBinding) {
                    ForEach(ProgramTemplate.Goal.allCases) { goal in
                        Text(goal.matcherDisplayName).tag(Optional(goal))
                    }
                }
            }

            AppDropdownChip(
                label: vm.preferredLevel?.matcherDisplayName ?? AppCopy.Onboarding.libraryLevelChip,
                isActive: true
            ) {
                Picker(AppCopy.Onboarding.libraryLevelChip, selection: levelBinding) {
                    ForEach(ProgramTemplate.Level.allCases) { level in
                        Text(level.matcherDisplayName).tag(Optional(level))
                    }
                }
            }

            AppDropdownChip(
                label: vm.preferredDaysPerWeek.map { "\($0) days" } ?? AppCopy.Onboarding.libraryDaysChip,
                isActive: true
            ) {
                Picker(AppCopy.Onboarding.libraryDaysChip, selection: daysBinding) {
                    ForEach(ProgramCatalog.supportedDays, id: \.self) { days in
                        Text(AppCopy.Onboarding.trainingDays(days)).tag(Optional(days))
                    }
                }
            }
        }
    }

    private var goalBinding: Binding<ProgramTemplate.Goal?> {
        Binding(
            get: { vm.preferredGoal },
            set: {
                vm.preferredGoal = $0
                vm.pickedProgram = nil
                showsAllPrograms = false
                onUpdate()
            }
        )
    }

    private var levelBinding: Binding<ProgramTemplate.Level?> {
        Binding(
            get: { vm.preferredLevel },
            set: {
                vm.preferredLevel = $0
                vm.pickedProgram = nil
                showsAllPrograms = false
                onUpdate()
            }
        )
    }

    private var daysBinding: Binding<Int?> {
        Binding(
            get: { vm.preferredDaysPerWeek },
            set: {
                vm.preferredDaysPerWeek = $0
                vm.pickedProgram = nil
                showsAllPrograms = false
                onUpdate()
            }
        )
    }

    private var dayCountBinding: Binding<DayCountOption?> {
        Binding(
            get: { vm.preferredDaysPerWeek.map { DayCountOption(value: $0) } },
            set: { option in
                if let option {
                    selectDays(option.value)
                }
            }
        )
    }

    private func recommendationSubtitle(for program: ProgramTemplate) -> String {
        guard let profile = vm.programMatchProfile else { return program.summary }
        let metadata = "\(program.goal.matcherDisplayName) · \(program.level.matcherDisplayName) · \(program.daysPerWeek) days/week"
        let reason: String

        switch (program.goal == profile.goal, program.level == profile.level) {
        case (true, true):
            reason = AppCopy.Onboarding.libraryExactMatchReason
        case (true, false):
            reason = AppCopy.Onboarding.libraryGoalMatchReason
        case (false, true):
            reason = AppCopy.Onboarding.libraryExperienceMatchReason
        case (false, false):
            reason = AppCopy.Onboarding.libraryScheduleMatchReason
        }

        return "\(metadata)\n\(reason)"
    }

    private func programOption(_ program: ProgramTemplate, rank: Int) -> some View {
        AppOptionTileCard(
            title: program.name,
            subtitle: recommendationSubtitle(for: program),
            badge: rank == 1 ? AppCopy.Onboarding.libraryBestMatch : nil,
            isSelected: vm.pickedProgram?.id == program.id
        ) {
            vm.applyPickedProgram(program)
            if let profile = vm.programMatchProfile {
                UnitAnalytics.shared.track(
                    .programMatchSelected(profile: profile, rank: rank)
                )
            }
            onUpdate()
        }
    }

    private func toggleAdditionalPrograms() {
        if showsAllPrograms,
           let pickedProgramID = vm.pickedProgram?.id,
           additionalPrograms.contains(where: { $0.id == pickedProgramID }) {
            vm.pickedProgram = nil
            onUpdate()
        }
        showsAllPrograms.toggle()
    }

    private func handleBack() {
        switch stage {
        case .results:
            displayedStage = .days
        case .days:
            displayedStage = .level
        case .level:
            displayedStage = .goal
        case .goal:
            onBack()
        }
    }

    private func handleContinue() {
        switch stage {
        case .goal where vm.preferredGoal != nil:
            displayedStage = .level
        case .level where vm.preferredLevel != nil:
            preselectDefaultDaysIfNeeded()
            displayedStage = .days
        case .days where vm.preferredDaysPerWeek != nil:
            displayedStage = .results
        case .results where vm.pickedProgram != nil:
            onContinue()
        default:
            break
        }
    }

    private func selectGoal(_ goal: ProgramTemplate.Goal) {
        let wasUnanswered = vm.preferredGoal == nil
        if vm.preferredGoal != goal {
            vm.preferredGoal = goal
            vm.pickedProgram = nil
            showsAllPrograms = false
            onUpdate()
        }
        if wasUnanswered {
            displayedStage = .level
        }
    }

    private func selectLevel(_ level: ProgramTemplate.Level) {
        let wasUnanswered = vm.preferredLevel == nil
        if vm.preferredLevel != level {
            vm.preferredLevel = level
            vm.pickedProgram = nil
            showsAllPrograms = false
            onUpdate()
        }
        if wasUnanswered {
            preselectDefaultDaysIfNeeded()
            displayedStage = .days
        }
    }

    private func preselectDefaultDaysIfNeeded() {
        guard vm.preferredDaysPerWeek == nil,
              ProgramCatalog.supportedDays.contains(Self.defaultDaysPerWeek) else { return }
        vm.preferredDaysPerWeek = Self.defaultDaysPerWeek
        vm.pickedProgram = nil
        onUpdate()
    }

    private func selectDays(_ days: Int) {
        let wasUnanswered = vm.preferredDaysPerWeek == nil
        if vm.preferredDaysPerWeek != days {
            vm.preferredDaysPerWeek = days
            vm.pickedProgram = nil
            showsAllPrograms = false
            onUpdate()
        }
        if wasUnanswered {
            displayedStage = .results
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingLibraryPickerView(
            progressStep: 3,
            progressTotal: 5,
            onUpdate: {},
            onContinue: {},
            onBack: {}
        )
        .environment(OnboardingViewModel())
    }
}
