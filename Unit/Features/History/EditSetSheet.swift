//
//  EditSetSheet.swift
//  Unit
//
//  Weight and reps of one logged set in a finished workout. Built from the
//  same parts as the routine target editor: a sheet shell, a card of rows,
//  inline number fields.
//

import SwiftUI

struct EditSetSheet: View {
    private enum Field: CaseIterable {
        case weight
        case reps
    }

    let draft: PastSetDraft
    let unitSystem: String
    /// Saves the corrected values (weight in kg). False keeps the sheet open.
    let onSave: (_ weightKg: Double, _ reps: Int) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var weightText: String
    @State private var repsText: String
    @State private var saveFailed = false
    private let initialWeightText: String

    init(
        draft: PastSetDraft,
        unitSystem: String,
        onSave: @escaping (_ weightKg: Double, _ reps: Int) -> Bool
    ) {
        self.draft = draft
        self.unitSystem = unitSystem
        self.onSave = onSave
        let displayWeight = unitSystem == "lb" ? draft.weightKg * 2.20462 : draft.weightKg
        let weightText = draft.isBodyweight && draft.weightKg == 0 ? "" : displayWeight.weightString
        self.initialWeightText = weightText
        _weightText = State(initialValue: weightText)
        _repsText = State(initialValue: String(draft.reps))
    }

    var body: some View {
        AppSheetScreen(
            title: AppCopy.Workout.editSet(draft.setNumber),
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.Workout.saveChanges,
                isEnabled: parsedValues != nil,
                disabledReason: parsedValues == nil ? AppCopy.History.invalidSetValues : nil,
                action: save
            ),
            dismissLabel: AppCopy.Nav.cancel,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                AppSectionHeader(draft.exerciseName)

                AppCardList(data: Field.allCases, id: \.self) { field in
                    HStack(spacing: AppSpacing.md) {
                        Text(title(for: field))
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textPrimary)
                        Spacer(minLength: 0)
                        AppInlineWeightField(
                            text: field == .weight ? $weightText : $repsText,
                            unitSuffix: field == .weight ? unitSystem : AppCopy.Workout.repsUnit,
                            accessibilityLabel: title(for: field),
                            keyboardType: field == .weight ? .decimalPad : .numberPad
                        )
                    }
                }
            }
        }
        .presentationDetents([.medium])
        .appBottomSheetChrome()
        .alert(AppCopy.History.setSaveFailedTitle, isPresented: $saveFailed) {
            Button(AppCopy.Nav.close, role: .cancel) { }
        } message: {
            Text(AppCopy.History.setSaveFailedMessage)
        }
    }

    private func title(for field: Field) -> String {
        switch field {
        case .weight: AppCopy.Workout.weightTitle(isBodyweight: draft.isBodyweight)
        case .reps: AppCopy.Workout.repsLabel
        }
    }

    /// Weight in kg and reps, or nil while either field is not a usable
    /// number. A blank weight means no added load on a bodyweight lift.
    private var parsedValues: (weightKg: Double, reps: Int)? {
        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayWeight: Double
        if trimmedWeight.isEmpty, draft.isBodyweight {
            displayWeight = 0
        } else if let value = Double(trimmedWeight.replacingOccurrences(of: ",", with: ".")),
                  value.isFinite, value >= 0 {
            displayWeight = value
        } else {
            return nil
        }
        guard let reps = Int(repsText.trimmingCharacters(in: .whitespacesAndNewlines)),
              (1...999).contains(reps) else { return nil }
        let weightKg = WorkoutLoggingState.canonicalWeight(
            originalKg: draft.weightKg,
            displayWeight: displayWeight,
            weightChanged: weightText != initialWeightText,
            unitSystem: unitSystem
        )
        return (weightKg, reps)
    }

    private func save() {
        guard let values = parsedValues else { return }
        if onSave(values.weightKg, values.reps) {
            dismiss()
        } else {
            saveFailed = true
        }
    }
}
