//
//  ImportHistorySheet.swift
//  Unit
//
//  Preview of a Strong or Hevy history before anything is saved: what comes
//  in, what is already in Unit, and which exercises are new. Built from the
//  same parts as Settings.
//

import SwiftUI

/// Gives a plan an identity for `sheet(item:)`.
struct ImportPlanItem: Identifiable {
    let id = UUID()
    let plan: WorkoutHistoryImportPlan
}

struct ImportHistorySheet: View {
    private struct Row: Identifiable {
        let title: String
        let value: String
        var subtitle: String? = nil

        var id: String { title }
    }

    let plan: WorkoutHistoryImportPlan
    /// Saves the plan with the chosen unit. False keeps the sheet open.
    let onImport: (ImportWeightUnit) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var weightUnit: ImportWeightUnit
    @State private var isImporting = false
    @State private var importFailed = false

    init(
        plan: WorkoutHistoryImportPlan,
        defaultUnit: ImportWeightUnit,
        onImport: @escaping (ImportWeightUnit) -> Bool
    ) {
        self.plan = plan
        self.onImport = onImport
        _weightUnit = State(initialValue: defaultUnit)
    }

    var body: some View {
        AppSheetScreen(
            title: AppCopy.DataTransfer.importSheetTitle,
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.DataTransfer.importAction(plan.workouts.count),
                isEnabled: !plan.workouts.isEmpty && !isImporting,
                isLoading: isImporting,
                disabledReason: plan.workouts.isEmpty ? AppCopy.DataTransfer.nothingNew : nil,
                action: runImport
            ),
            dismissLabel: AppCopy.Nav.cancel,
            onDismissAction: { dismiss() }
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                SettingsSection(title: AppCopy.DataTransfer.fromSource(plan.source.appName), contentInset: AppSpacing.sm) {
                    AppDividedList(summaryRows) { row in
                        AppListRow(title: row.title, value: row.value, subtitle: row.subtitle)
                    }
                }

                if plan.needsWeightUnit {
                    SettingsSection(title: AppCopy.DataTransfer.weightsInFile, contentInset: AppSpacing.sm) {
                        AppListRow(title: AppCopy.DataTransfer.weightUnit) {
                            AppSegmentedControl(
                                selection: $weightUnit,
                                items: ImportWeightUnit.allCases,
                                label: AppCopy.DataTransfer.weightsInFile,
                                title: { $0.rawValue }
                            )
                        }
                    }
                }

                SettingsSection(title: AppCopy.DataTransfer.exercisesSection, contentInset: AppSpacing.sm) {
                    AppDividedList(exerciseRows) { row in
                        AppListRow(title: row.title, value: row.value, subtitle: row.subtitle)
                    }
                }

                Text(AppCopy.DataTransfer.recalculatedNote)
                    .font(AppFont.muted.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .presentationDetents([.large])
        .appBottomSheetChrome()
        .interactiveDismissDisabled(isImporting)
        .alert(AppCopy.DataTransfer.importFailedTitle, isPresented: $importFailed) {
            Button(AppCopy.Nav.close, role: .cancel) { }
        } message: {
            Text(AppCopy.DataTransfer.importFailedMessage)
        }
    }

    private var summaryRows: [Row] {
        var rows = [
            Row(title: AppCopy.DataTransfer.workoutsRow, value: plan.workouts.count.formatted()),
            Row(title: AppCopy.DataTransfer.setsRow, value: plan.setCount.formatted())
        ]
        if let first = plan.firstDate, let last = plan.lastDate {
            rows.append(Row(title: AppCopy.DataTransfer.datesRow, value: AppCopy.DataTransfer.dateRange(first, last)))
        }
        if plan.duplicateCount > 0 {
            rows.append(Row(
                title: AppCopy.DataTransfer.alreadyInUnit,
                value: plan.duplicateCount.formatted(),
                subtitle: AppCopy.DataTransfer.alreadyInUnitDetail
            ))
        }
        if plan.skippedRowCount > 0 {
            rows.append(Row(
                title: AppCopy.DataTransfer.skippedRows,
                value: plan.skippedRowCount.formatted(),
                subtitle: AppCopy.DataTransfer.skippedRowsDetail
            ))
        }
        return rows
    }

    private var exerciseRows: [Row] {
        var rows = [Row(title: AppCopy.DataTransfer.matchYours, value: plan.matchedExerciseNames.count.formatted())]
        rows.append(Row(
            title: AppCopy.DataTransfer.newExercises,
            value: plan.newExerciseNames.count.formatted(),
            subtitle: AppCopy.DataTransfer.nameList(plan.newExerciseNames)
        ))
        return rows
    }

    /// Lets the button show its loading state before the save runs.
    private func runImport() {
        guard !isImporting else { return }
        isImporting = true
        Task { @MainActor in
            await Task.yield()
            let saved = onImport(weightUnit)
            isImporting = false
            if saved {
                dismiss()
            } else {
                importFailed = true
            }
        }
    }
}
