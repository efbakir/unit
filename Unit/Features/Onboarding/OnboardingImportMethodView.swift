//
//  OnboardingImportMethodView.swift
//  Unit
//
//  Screen 3 — Choose how to bring an existing program into onboarding.
//

import SwiftUI

struct OnboardingImportMethodView: View {
    var progressStep: Int
    var progressTotal: Int
    var onSelect: (OnboardingViewModel.ImportMethod) -> Void
    var hasHistory: Bool = false
    var onBack: () -> Void

    var body: some View {
        OnboardingShell(
            title: "Add my program",
            subtitle: "I'll bring it in this way.",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                AppOptionTileCard(
                    icon: .clipboard,
                    title: "Paste program"
                ) {
                    onSelect(.paste)
                }

                if hasHistory {
                    AppOptionTileCard(
                        icon: .calendarClock,
                        title: "Use past workout"
                    ) {
                        onSelect(.history)
                    }
                }

                AppOptionTileCard(icon: .edit, title: "Build manually") {
                    onSelect(.manual)
                }
            }
        }
    }
}

#Preview {
    OnboardingImportMethodView(progressStep: 2, progressTotal: 4, onSelect: { _ in }, onBack: {})
}
