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
    var onBack: () -> Void

    var body: some View {
        OnboardingShell(
            title: AppCopy.Onboarding.methodTitle,
            subtitle: AppCopy.Onboarding.methodSubtitle,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                // 2-choice rewrite (Phase B-3, Q1 + Q3 locked 2026-06-17).
                // Manual builder DELETED — the self-coached intermediate
                // persona pastes or picks. Hidden programs still live in
                // ProgramCatalog.all for a future "browse all" surface.
                // Use-past-workout (history) path also removed: it required
                // existing sessions which a brand-new v2 install never has.
                AppOptionTileCard(
                    icon: .clipboard,
                    title: AppCopy.Onboarding.methodPasteOption
                ) {
                    onSelect(.paste)
                }

                AppOptionTileCard(icon: .list, title: AppCopy.Onboarding.methodLibraryOption) {
                    onSelect(.library)
                }
            }
        }
    }
}

#Preview {
    OnboardingImportMethodView(progressStep: 2, progressTotal: 4, onSelect: { _ in }, onBack: {})
}
