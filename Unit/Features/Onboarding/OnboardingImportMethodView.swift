//
//  OnboardingImportMethodView.swift
//  Unit
//
//  Screen 3 — Choose between an existing program and a ready-made match.
//

import SwiftUI

struct OnboardingImportMethodView: View {
    var progressStep: Int
    var progressTotal: Int
    var selectedMethod: OnboardingViewModel.ImportMethod?
    var onSelect: (OnboardingViewModel.ImportMethod) -> Void
    var onContinue: () -> Void
    var onBack: () -> Void

    var body: some View {
        OnboardingShell(
            title: AppCopy.Onboarding.methodTitle,
            subtitle: AppCopy.Onboarding.methodSubtitle,
            ctaEnabled: selectedMethod != nil,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: onContinue,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                AppOptionTileCard(
                    icon: .clipboard,
                    title: AppCopy.Onboarding.methodPasteOption,
                    subtitle: AppCopy.Onboarding.methodPasteSubtitle,
                    isSelected: selectedMethod == .paste
                ) {
                    onSelect(.paste)
                }

                AppOptionTileCard(
                    icon: .list,
                    title: AppCopy.Onboarding.methodLibraryOption,
                    subtitle: AppCopy.Onboarding.methodLibrarySubtitle,
                    isSelected: selectedMethod == .library
                ) {
                    onSelect(.library)
                }

                AnonymousAnalyticsToggle()
                    .padding(.top, AppSpacing.sm)
            }
        }
    }
}

#Preview {
    OnboardingImportMethodView(
        progressStep: 2,
        progressTotal: 4,
        selectedMethod: .library,
        onSelect: { _ in },
        onContinue: {},
        onBack: {}
    )
}
