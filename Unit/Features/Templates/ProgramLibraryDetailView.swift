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
                    SettingsSection(title: day.name, contentInset: AppSpacing.sm) {
                        AppDividedList(day.items) { item in
                            AppListRow(
                                title: item.exerciseName,
                                value: WorkoutTargetFormatter.setRepCompact(setCount: item.setCount, reps: item.repTarget) ?? "",
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
        .tint(AppColor.accent)
    }

    private var headerBlock: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(program.description)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textPrimary)
            HStack(spacing: AppSpacing.xs) {
                AppTag(text: program.level.displayName, style: .muted, layout: .compactCapsule)
                AppTag(text: program.goal.displayName, style: .muted, layout: .compactCapsule)
                AppTag(text: "\(program.daysPerWeek) days/week", style: .muted, layout: .compactCapsule)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func importProgram() {
        let split = ProgramImporter.importProgram(program, into: modelContext)
        ActiveSplitStore.setCurrent(split.id)
        appTabSelection(.program)
        dismiss()
    }
}
