//
//  OnboardingSplitBuilderView.swift
//  Unit
//
//  Screen 4 — Define training split: number of days and a name for each.
//  Creates the conceptual Split + DayTemplate structure (committed later).
//

import SwiftUI

struct OnboardingSplitBuilderView: View {
    @Environment(OnboardingViewModel.self) private var vm
    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void
    var onBack: () -> Void

    @FocusState private var focusedDay: Int?

    private func dayNameBinding(for index: Int) -> Binding<String> {
        Binding(
            get: {
                guard vm.dayNames.indices.contains(index) else { return "" }
                return vm.dayNames[index]
            },
            set: { newValue in
                guard vm.dayNames.indices.contains(index) else { return }
                vm.dayNames[index] = newValue
            }
        )
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: "Your training split",
            ctaLabel: "Continue",
            ctaEnabled: vm.splitIsValid,
            ctaDisabledReason: vm.splitIsValid ? nil : AppCopy.FormHint.onboardingSplitNamesRequired,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue,
            onBack: onBack
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {

                AppCard {
                    HStack {
                        Text("Days per week")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer()
                        AppStepper(
                            value: "\(vm.dayCount)",
                            isDecrementEnabled: vm.dayCount > 2,
                            isIncrementEnabled: vm.dayCount < 6,
                            onDecrement: { vm.updateDayCount(vm.dayCount - 1) },
                            onIncrement: { vm.updateDayCount(vm.dayCount + 1) }
                        )
                    }
                }

                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    AppSectionHeader("Day names")

                    AppCardList(data: Array(0..<vm.dayCount), id: \.self) { i in
                        TextField("Day name", text: dayNameBinding(for: i))
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .focused($focusedDay, equals: i)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                            .submitLabel(i < vm.dayCount - 1 ? .next : .done)
                            .onSubmit {
                                if i < vm.dayCount - 1 { focusedDay = i + 1 }
                                else { focusedDay = nil }
                            }
                    }
                }
            }
        }
        .onChange(of: vm.dayCount) { _, newValue in
            guard let focusedDay else { return }
            if focusedDay >= newValue {
                self.focusedDay = max(0, newValue - 1)
            }
        }
    }
}

#Preview {
    OnboardingSplitBuilderView(progressStep: 3, progressTotal: 4, onContinue: {}, onBack: {})
        .environment(OnboardingViewModel())
        .tint(AppColor.accent)
}
