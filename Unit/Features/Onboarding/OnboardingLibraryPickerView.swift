//
//  OnboardingLibraryPickerView.swift
//  Unit
//
//  Library path's first screen (Phase B-3). Shows the 5 surfaced programs
//  from `ProgramCatalog.surfacedInOnboarding` (Q1 data-driven lock 2026-06-17:
//  Reddit PPL, GZCLP, 5/3/1 BBB, nSuns, PHUL). One tap → `Onboarding1RMInputView`.
//
//  No manual-build escape hatch on this screen — Phase B-3 deletes that path
//  per Q1. If the user wants a program not on this list, they take the
//  Paste path from `OnboardingImportMethodView`.
//

import SwiftUI

struct OnboardingLibraryPickerView: View {
    var progressStep: Int
    var progressTotal: Int
    var onPick: (ProgramTemplate) -> Void
    var onBack: () -> Void

    private var programs: [ProgramTemplate] {
        ProgramCatalog.surfacedInOnboarding
    }

    var body: some View {
        OnboardingShell(
            title: "Pick a program",
            subtitle: "I'll start you with the standard prescription.",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.sm) {
                ForEach(programs) { program in
                    Button {
                        onPick(program)
                    } label: {
                        programCard(for: program)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityHint("Sets up the program and asks for your 1-rep maxes.")
                }
            }
        }
    }

    @ViewBuilder
    private func programCard(for program: ProgramTemplate) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(program.name)
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    AppTag(
                        text: "\(program.daysPerWeek) days",
                        style: .muted,
                        layout: .compactCapsule
                    )
                }

                Text(program.summary)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview {
    NavigationStack {
        OnboardingLibraryPickerView(
            progressStep: 3,
            progressTotal: 5,
            onPick: { _ in },
            onBack: {}
        )
    }
}
