//
//  OnboardingScheduleView.swift
//  Unit
//
//  Step between split-builder/program-import and exercises. Asks the user
//  which weekday each named day-template falls on so the calendar/today
//  logic doesn't silently infer schedule data the user never provided.
//
//  Also hosts an explicit "lift on a flexible schedule" toggle — opt-in to
//  rotation mode (every template gets `scheduledWeekday = 0`) for users
//  who don't anchor to specific weekdays.
//

import SwiftUI

struct OnboardingScheduleView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void
    var onBack: () -> Void

    /// Mon-first ordering. `id` is Apple's `Calendar.weekday`
    /// (1=Sun … 7=Sat) — what we persist on `DayTemplate.scheduledWeekday`.
    private struct WeekdaySegment: Identifiable, Hashable {
        let id: Int
        let letter: String
        let name: String
    }

    private static let segments: [WeekdaySegment] = [
        .init(id: 2, letter: "M", name: "Monday"),
        .init(id: 3, letter: "T", name: "Tuesday"),
        .init(id: 4, letter: "W", name: "Wednesday"),
        .init(id: 5, letter: "T", name: "Thursday"),
        .init(id: 6, letter: "F", name: "Friday"),
        .init(id: 7, letter: "S", name: "Saturday"),
        .init(id: 1, letter: "S", name: "Sunday"),
    ]

    /// Sensible Mon-anchored defaults so the picker arrives with valid
    /// selections — "I can change this later" promised in the subtitle.
    /// Without seeding, `dayWeekdays = [0,0,0]` from the viewmodel would
    /// leave Continue disabled and force the user to tap one chip per row
    /// just to advance, which fights the zero-friction onboarding goal.
    private static func defaultPattern(for count: Int) -> [Int] {
        switch count {
        case ...1: return [2]
        case 2:    return [2, 5]
        case 3:    return [2, 4, 6]
        case 4:    return [2, 3, 5, 6]
        case 5:    return [2, 3, 4, 5, 6]
        case 6:    return [2, 3, 4, 5, 6, 7]
        default:   return [2, 3, 4, 5, 6, 7, 1]
        }
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: AppCopy.Onboarding.scheduleTitle,
            subtitle: AppCopy.Onboarding.scheduleSubtitle,
            ctaLabel: "Continue",
            ctaEnabled: vm.scheduleIsValid,
            ctaDisabledReason: vm.scheduleIsValid ? nil : AppCopy.FormHint.onboardingScheduleRequired,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue,
            onBack: onBack
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                AppCard {
                    Toggle(isOn: $vm.useFlexibleSchedule) {
                        VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                            Text(AppCopy.Onboarding.flexibleToggle)
                                .font(AppFont.sectionHeader.font)
                                .foregroundStyle(AppColor.textPrimary)
                            Text(AppCopy.Onboarding.flexibleSubtext)
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    .tint(AppColor.accent)
                }

                if !vm.useFlexibleSchedule {
                    AppCardList(
                        data: Array(0..<vm.dayCount),
                        id: \.self,
                        rowVerticalInset: AppSpacing.lg
                    ) { i in
                        VStack(alignment: .leading, spacing: AppSpacing.md) {
                            AppSectionHeader(rowLabel(for: i)) {
                                if let name = selectedDayName(for: i) {
                                    Text(name)
                                        .font(AppFont.caption.font)
                                        .foregroundStyle(AppColor.textSecondary)
                                        .lineLimit(1)
                                        .accessibilityHidden(true)
                                }
                            }

                            AppSegmentedControl(
                                selection: weekdayBinding(for: i),
                                items: Self.segments,
                                size: .tall,
                                title: { $0.letter },
                                accessibilityLabel: { "\(rowLabel(for: i)), \($0.name)" },
                                isDisabled: { segment in
                                    isWeekdayTaken(segment.id, excluding: i)
                                }
                            )
                        }
                    }
                }
            }
            .onAppear { seedDefaultsIfNeeded() }
            .onChange(of: vm.dayCount) { _, _ in seedDefaultsIfNeeded() }
        }
    }

    private func seedDefaultsIfNeeded() {
        let count = vm.dayCount
        guard count > 0 else { return }
        while vm.dayWeekdays.count < count { vm.dayWeekdays.append(0) }
        if vm.dayWeekdays.count > count {
            vm.dayWeekdays = Array(vm.dayWeekdays.prefix(count))
        }
        let pattern = Self.defaultPattern(for: count)
        for i in 0..<count where !(1...7).contains(vm.dayWeekdays[i]) {
            vm.dayWeekdays[i] = pattern[i]
        }
        resolveScheduleCollisions()
    }

    /// One weekday per row. If two rows have landed on the same weekday (e.g.
    /// migrated from legacy data), keep the earlier row's choice and shift the
    /// later one to the next free weekday in Mon-first order.
    private func resolveScheduleCollisions() {
        let count = vm.dayCount
        guard count > 0 else { return }
        var taken: Set<Int> = []
        let order = Self.segments.map(\.id)
        for i in 0..<count {
            let current = vm.dayWeekdays[i]
            if (1...7).contains(current), !taken.contains(current) {
                taken.insert(current)
                continue
            }
            if let free = order.first(where: { !taken.contains($0) }) {
                vm.dayWeekdays[i] = free
                taken.insert(free)
            }
        }
    }

    private func isWeekdayTaken(_ weekday: Int, excluding index: Int) -> Bool {
        for (i, value) in vm.dayWeekdays.enumerated() where i != index {
            if value == weekday { return true }
        }
        return false
    }

    private func rowLabel(for index: Int) -> String {
        guard vm.dayNames.indices.contains(index) else { return "Day \(index + 1)" }
        let trimmed = vm.dayNames[index].trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "Day \(index + 1)" : trimmed
    }

    private func selectedDayName(for index: Int) -> String? {
        guard vm.dayWeekdays.indices.contains(index) else { return nil }
        let weekday = vm.dayWeekdays[index]
        return Self.segments.first(where: { $0.id == weekday })?.name
    }

    private func weekdayBinding(for index: Int) -> Binding<Int> {
        Binding(
            get: {
                guard vm.dayWeekdays.indices.contains(index) else { return Self.segments[0].id }
                let current = vm.dayWeekdays[index]
                return Self.segments.contains(where: { $0.id == current }) ? current : Self.segments[0].id
            },
            set: { newValue in
                guard vm.dayWeekdays.indices.contains(index) else { return }
                vm.dayWeekdays[index] = newValue
            }
        )
    }
}

#Preview {
    OnboardingScheduleView(progressStep: 4, progressTotal: 5, onContinue: {}, onBack: {})
        .environment({
            let vm = OnboardingViewModel()
            vm.seedSampleData()
            return vm
        }())
        .tint(AppColor.accent)
}
