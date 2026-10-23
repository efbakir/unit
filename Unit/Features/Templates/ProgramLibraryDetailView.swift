//
//  ProgramLibraryDetailView.swift
//  Unit
//
//  Detail view for a catalog program: shows description + per-day exercise
//  breakdown, and a primary button to import the program as the user's new
//  split.
//

import SwiftUI
import SwiftData

struct ProgramLibraryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appTabSelection) private var appTabSelection

    let program: ProgramTemplate

    @State private var showingConfirmation = false
    @State private var importFailed = false

    var body: some View {
        AppScreen(
            primaryButton: PrimaryButtonConfig(
                label: "Use this program",
                isEnabled: true,
                action: { showingConfirmation = true }
            ),
            showsNativeNavigationBar: true
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                headerBlock
                ForEach(program.days) { day in
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AppSectionHeader(day.name)
                        AppCardList(day.items, rowVerticalInset: AppSpacing.sm) { item in
                            AppListRow(
                                title: item.exerciseName,
                                value: prescriptionText(for: item),
                                subtitle: item.notes,
                                style: .display
                            )
                        }
                    }
                }
            }
            .appScreenEnter()
        }
        .navigationTitle(program.name)
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .confirmationDialog(
            "Import \(program.name)?",
            isPresented: $showingConfirmation,
            titleVisibility: .visible
        ) {
            Button("Import") { importProgram() }
            Button(AppCopy.Nav.cancel, role: .cancel) {}
        } message: {
            Text("Adds the program to your list. Missing exercises are created automatically.")
        }
        .alert("Couldn't import program", isPresented: $importFailed) {
            Button(AppCopy.Nav.close, role: .cancel) { }
        } message: {
            Text("Your saved programs are unchanged. Try again.")
        }
        .tint(AppColor.accent)
    }

    private func prescriptionText(for item: ProgramItem) -> String {
        guard let repRange = item.repRange else {
            return WorkoutTargetFormatter.setRepDisplay(
                setCount: item.setCount,
                reps: item.repTarget
            ) ?? ""
        }
        return WorkoutTargetFormatter.repRangeDisplay(
            setCount: item.setCount,
            lowerRepBound: repRange.lowerBound,
            upperRepBound: repRange.upperBound
        ) ?? ""
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(program.description)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
            Text("\(program.level.displayName) · \(program.goal.displayName) · \(program.daysPerWeek) days/week")
                .appFont(.caption)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func importProgram() {
        let split = ProgramImporter.importProgram(program, into: modelContext)
        guard !modelContext.hasChanges else {
            modelContext.rollbackRestoringLoadedModels()
            importFailed = true
            AppHaptic.error.fire()
            return
        }
        ActiveSplitStore.setCurrent(split.id)
        appTabSelection(.program)
        dismiss()
    }
}
