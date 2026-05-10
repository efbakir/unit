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
            title: "Add your program",
            subtitle: "Choose how to create your template.",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                OnboardingOptionCard(
                    icon: .clipboard,
                    title: "Paste program"
                ) {
                    onSelect(.paste)
                }

                if hasHistory {
                    OnboardingOptionCard(
                        icon: .calendarClock,
                        title: "Use past workout"
                    ) {
                        onSelect(.history)
                    }
                }

                OnboardingOptionCard(icon: .edit, title: "Build manually") {
                    onSelect(.manual)
                }
            }
        }
    }
}

struct OnboardingOptionCard: View {
    var icon: AppIcon? = nil
    var iconText: String? = nil
    let title: String
    var badge: String? = nil
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                if icon != nil || iconText != nil {
                    iconBubble
                }

                Text(title)
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)

                Spacer(minLength: 0)

                if let badge {
                    AppTag(text: badge, style: .accent, layout: .compactCapsule)
                }
            }
            .appCardStyle()
        }
        .buttonStyle(ScaleButtonStyle())
    }

    @ViewBuilder
    private var iconBubble: some View {
        AppIconCircle(
            diameter: 40,
            shape: .roundedRect(radius: AppRadius.md),
            surface: .accentSoft
        ) {
            Group {
                if let icon {
                    icon.image(size: 18, weight: .semibold)
                } else if let iconText {
                    Text(iconText)
                        .font(AppFont.stepIndicator.font)
                }
            }
            .foregroundStyle(AppColor.accent)
        }
    }
}

#Preview {
    OnboardingImportMethodView(progressStep: 2, progressTotal: 4, onSelect: { _ in }, onBack: {})
}
