//
//  Onboarding1RMInputView.swift
//  Unit
//
//  Library path's 1RM input screen (Phase B-3). 4 lifts (Q4 lock):
//  Bench / Squat / Deadlift / OHP — all blank, all skippable. The dict
//  passed to `onContinue` contains only lifts with a non-nil entry; the
//  preview screen falls back to blank weights for skipped lifts.
//
//  Paste path skips this screen entirely (the paste already had weights).
//

import SwiftUI

struct Onboarding1RMInputView: View {
    var progressStep: Int
    var progressTotal: Int
    /// "kg" or "lb" — drives the unit suffix on each row + the dict's
    /// numeric interpretation (we store kg internally; convert at boundary).
    var unitSystem: String
    var onContinue: ([OneRepMaxLift: Double]) -> Void
    var onBack: () -> Void

    @State private var entries: [OneRepMaxLift: String] = [:]
    @FocusState private var focusedLift: OneRepMaxLift?

    private let lifts: [OneRepMaxLift] = [.bench, .squat, .deadlift, .ohp]

    private var unitSuffix: String { unitSystem }

    /// Per the unit system: convert raw text to kg (no-op for kg, ÷ 2.205 for lb).
    private func parseToKg(_ raw: String) -> Double? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed), value > 0 else { return nil }
        if unitSystem == "lb" {
            return value / 2.20462
        }
        return value
    }

    /// Builds the dict for `onContinue` from the current text entries.
    private var oneRMsKg: [OneRepMaxLift: Double] {
        var out: [OneRepMaxLift: Double] = [:]
        for lift in lifts {
            if let raw = entries[lift], let kg = parseToKg(raw) {
                out[lift] = kg
            }
        }
        return out
    }

    var body: some View {
        OnboardingShell(
            title: "Your 1-rep maxes",
            subtitle: "I'll start your weights from these. Skip any you don't know.",
            progressStep: progressStep,
            progressTotal: progressTotal,
            onBack: onBack
        ) {
            VStack(spacing: AppSpacing.md) {
                AppCardList(lifts) { lift in
                    row(for: lift)
                }

                Button {
                    focusedLift = nil
                    onContinue(oneRMsKg)
                } label: {
                    Text("Skip all")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(ScaleButtonStyle())
                .accessibilityLabel("Skip all 1-rep maxes")

                AppPrimaryButton("Continue") {
                    focusedLift = nil
                    onContinue(oneRMsKg)
                }
            }
        }
    }

    @ViewBuilder
    private func row(for lift: OneRepMaxLift) -> some View {
        AppListRow(title: lift.displayName) {
            HStack(spacing: AppSpacing.xs) {
                TextField(
                    "",
                    text: Binding(
                        get: { entries[lift] ?? "" },
                        set: { entries[lift] = $0 }
                    ),
                    prompt: Text("0").foregroundStyle(AppColor.textSecondary)
                )
                .keyboardType(.decimalPad)
                .focused($focusedLift, equals: lift)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: 80)
                .submitLabel(.done)

                Text(unitSuffix)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .frame(minWidth: 22, alignment: .leading)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedLift = lift
        }
    }
}

#Preview {
    NavigationStack {
        Onboarding1RMInputView(
            progressStep: 4,
            progressTotal: 5,
            unitSystem: "kg",
            onContinue: { _ in },
            onBack: {}
        )
    }
}
