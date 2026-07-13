//
//  OnboardingUnitPickerView.swift
//  Unit
//
//  Screen 2 — Pick the weight unit (kg / lb) used everywhere in the app.
//  Auto-advances on tap, mirroring OnboardingImportMethodView.
//

import SwiftUI

struct OnboardingUnitPickerView: View {
    var progressStep: Int
    var progressTotal: Int
    var onSelect: (String) -> Void
    var onBack: () -> Void

    var body: some View {
        OnboardingShell(
            title: AppCopy.Onboarding.unitTitle,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                AppOptionTileCard(iconText: "kg", title: "Kilograms") {
                    onSelect("kg")
                }

                AppOptionTileCard(iconText: "lb", title: "Pounds") {
                    onSelect("lb")
                }
            }
        }
    }
}

#Preview {
    OnboardingUnitPickerView(progressStep: 1, progressTotal: 4, onSelect: { _ in }, onBack: {})
}
