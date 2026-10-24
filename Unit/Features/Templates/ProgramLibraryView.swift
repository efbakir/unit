//
//  ProgramLibraryView.swift
//  Unit
//
//  Browsable catalog of starter programs filtered via inline dropdown chips
//  above the list (iOS-native Menu with Picker for checkmarked selection).
//

import SwiftUI

/// Marker value used with `NavigationLink(value:)` to open the library.
struct ProgramLibraryDestination: Hashable {}

struct ProgramLibraryView: View {
    @State private var selectedLevel: ProgramTemplate.Level? = nil
    @State private var selectedGoal: ProgramTemplate.Goal? = nil
    @State private var selectedDays: Int? = nil

    private var filteredPrograms: [ProgramTemplate] {
        ProgramCatalog.all.filter { program in
            if let level = selectedLevel, program.level != level { return false }
            if let goal = selectedGoal, program.goal != goal { return false }
            if let days = selectedDays, program.daysPerWeek != days { return false }
            return true
        }
    }

    private var daysOptions: [Int] {
        Array(Set(ProgramCatalog.all.map(\.daysPerWeek))).sorted()
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                filterBar

                if filteredPrograms.isEmpty {
                    EmptyStateCard(
                        title: "No matching programs",
                        message: "Choose different filters.",
                        buttonLabel: "Clear filters"
                    ) {
                        selectedLevel = nil
                        selectedGoal = nil
                        selectedDays = nil
                    }
                        .transition(AppBlurTransition().animation(.appReveal))
                } else {
                    AppCardList(filteredPrograms) { program in
                        NavigationLink(value: program) {
                            programRow(program)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .transition(AppBlurTransition().animation(.appReveal))
                }
            }
            .appScreenEnter()
        }
        .navigationTitle("Program library")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(for: ProgramTemplate.self) { program in
            ProgramLibraryDetailView(program: program)
        }
        .appNavigationBarChrome()
    }

    private var filterBar: some View {
        AppFilterChipBar {
            AppDropdownChip(
                label: selectedLevel?.displayName ?? "Level",
                isActive: selectedLevel != nil
            ) {
                Picker("Level", selection: $selectedLevel) {
                    Text("All").tag(ProgramTemplate.Level?.none)
                    ForEach(ProgramTemplate.Level.allCases) { level in
                        Text(level.displayName).tag(Optional(level))
                    }
                }
            }

            AppDropdownChip(
                label: selectedGoal?.displayName ?? "Goal",
                isActive: selectedGoal != nil
            ) {
                Picker("Goal", selection: $selectedGoal) {
                    Text("All").tag(ProgramTemplate.Goal?.none)
                    ForEach(ProgramTemplate.Goal.allCases) { goal in
                        Text(goal.displayName).tag(Optional(goal))
                    }
                }
            }

            AppDropdownChip(
                label: selectedDays.map { "\($0) days" } ?? "Days/week",
                isActive: selectedDays != nil
            ) {
                Picker("Days/week", selection: $selectedDays) {
                    Text("All").tag(Int?.none)
                    ForEach(daysOptions, id: \.self) { days in
                        Text("\(days) days").tag(Optional(days))
                    }
                }
            }
        }
    }

    private func programRow(_ program: ProgramTemplate) -> some View {
        PreviewListRow(
            title: program.name,
            subtitle: "\(program.level.displayName) · \(program.goal.displayName) · \(program.daysPerWeek) days/week",
            showsDisclosure: true
        )
    }
}
