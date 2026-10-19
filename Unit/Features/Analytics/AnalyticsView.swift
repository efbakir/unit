import SwiftData
import SwiftUI

/// Analytics page; ContentView remains the native tab/navigation owner.
struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @AppStorage("unitSystem") private var unit = "kg"
    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplit = ""
    @State private var store = AnalyticsStore()
    @State private var revision = 0
    @State private var showsExplanation = false
    @State private var error: AppToastEvent?

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            if let output = store.output {
                if let summary = output.summary {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Button { showsExplanation = true } label: {
                            AppStatusSummaryCard(word: summary.status.rawValue, sentence: WorkoutTargetFormatter.analyticsSummary(summary, now: output.today))
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityIdentifier("analytics-summary")
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            AppSectionHeader("Main lifts")
                            VStack(spacing: AppSpacing.smd) {
                                ForEach(AnalyticsEngine.Slot.allCases, id: \.self) { slot in
                                    let lift = output.main[slot].flatMap { output.lifts[$0] }
                                    if let lift, lift.latest != nil {
                                        NavigationLink(value: lift.id) { mainCard(slot, lift: lift, output: output) }
                                            .buttonStyle(ScaleButtonStyle())
                                            .accessibilityIdentifier("analytics-main-\(slot.rawValue)")
                                    } else {
                                        mainCard(slot, lift: nil, output: output)
                                    }
                                }
                            }
                        }
                        if !output.other.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                AppSectionHeader("Other exercises")
                                AppCardList(data: output.other, id: \.self, rowVerticalInset: AppSpacing.xs) { id in
                                    if let lift = output.lifts[id], let latest = lift.latest {
                                        NavigationLink(value: id) {
                                            HStack(spacing: AppSpacing.sm) {
                                                AppMainLiftCard.iconTile(Self.icon(for: lift.exercise), side: AppSpacing.xl)
                                                AppListRow(title: lift.exercise.name, style: .cardListContent, showsDisclosure: true) {
                                                    Text(WorkoutTargetFormatter.analyticsPerformance(latest, bodyweight: lift.bodyweight, unit: unit))
                                                        .font(AppFont.caption.font).monospacedDigit()
                                                        .foregroundStyle(AppColor.textSecondary)
                                                        .minimumScaleFactor(0.7)
                                                }
                                            }
                                        }
                                        .buttonStyle(ScaleButtonStyle())
                                        .accessibilityIdentifier("analytics-other-\(id.uuidString)")
                                    }
                                }
                            }
                        }
                    }
                } else {
                    EmptyStateCard(title: "No workouts yet", message: "Finish a workout to see progress.")
                        .accessibilityIdentifier("analytics-empty")
                }
            } else {
                AppStatusSummaryCard(word: "Building a baseline", sentence: "LAST 4 WEEKS")
                    .redacted(reason: .placeholder).accessibilityHidden(true)
            }
        }
        .navigationTitle("Analytics")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .navigationDestination(for: UUID.self) { id in
            if let lift = store.output?.lifts[id] {
                ExerciseProgressView(exerciseId: id, exerciseName: lift.exercise.name, isBodyweight: lift.bodyweight, sessions: store.sessions, templates: store.templates, analytics: store.output)
            }
        }
        .sheet(isPresented: $showsExplanation) { explanationSheet }
        .appToast(event: $error)
        .task(id: revision) { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in revision += 1 }
        .onChange(of: activeSplit) { _, _ in revision += 1 }
        .onChange(of: phase) { _, phase in if phase == .active { revision += 1 } }
    }
    private func reload() async {
        do { try await store.refresh(context: context, now: Date(), calendar: .current) }
        catch { self.error = AppToastEvent(error.localizedDescription, kind: .error) }
    }
    private func mainCard(_ slot: AnalyticsEngine.Slot, lift: AnalyticsEngine.Lift?, output: AnalyticsEngine.Output) -> some View {
        AppMainLiftCard(title: slot.rawValue, icon: Self.icon(for: slot), lift: lift,
                        chart: AnalyticsEngine.chart(lift: lift, weekStarts: output.weekStarts, metric: lift?.bodyweight == true ? .reps : .weight, unit: unit), unit: unit, now: output.today)
    }
    static func icon(for slot: AnalyticsEngine.Slot) -> AppIcon {
        switch slot { case .squat: .squat; case .bench: .dumbbell; case .deadlift: .deadlift }
    }
    static func icon(for exercise: AnalyticsEngine.ExerciseInput) -> AppIcon {
        if exercise.muscleGroup == "shoulders" { return .deadlift }
        let name = exercise.name.lowercased()
        if exercise.muscleGroup == "back" && ["pull-up", "chin", "pulldown"].contains(where: name.contains) { return .climbing }
        return exercise.muscleGroup == "core" ? .core : .dumbbell
    }
    private var explanationSheet: some View {
        VStack(spacing: 0) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Each lift compares its best set from the last 4 weeks with the 4 weeks before.")
                            .font(AppFont.body.font)
                        AppDividedList(data: [
                            ("Up", "More weight or reps, nothing less"),
                            ("Same", "No change"),
                            ("Mixed", "Weight and reps both changed"),
                            ("Below best", "Less weight or reps, the other the same")
                        ], id: \.0) { item in
                            HStack(alignment: .top, spacing: AppSpacing.md) {
                                Text(item.0).font(AppFont.sectionHeader.font).frame(maxWidth: .infinity, alignment: .leading)
                                Text(item.1).font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary).frame(maxWidth: .infinity, alignment: .leading)
                            }.padding(.vertical, AppSpacing.smd)
                        }
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            AppSectionHeader("Status")
                            AppDividedList(data: [
                                ("Getting stronger", "Half or more of your lifts up, most planned sessions done"),
                                ("Holding steady", "Anything else"),
                                ("Fewer sessions lately", "Under half of planned sessions done"),
                                ("Building a baseline", "Under 2 weeks of sessions")
                            ], id: \.0) { item in
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text(item.0).font(AppFont.sectionHeader.font)
                                    Text(item.1).font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                                }.padding(.vertical, AppSpacing.smd)
                            }
                        }
                        Text("Warm-up sets don't count. The status changes after 3 days.")
                            .font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                    }.padding(AppSpacing.md)
                }
                .navigationTitle("How this works").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showsExplanation = false } } }
                .appNavigationBarChrome()
            }
        }
        .presentationDetents([.medium, .large]).presentationDragIndicator(.visible)
        .appBottomSheetChrome()
    }
}


#Preview("Analytics · light") {
    NavigationStack { AnalyticsView() }
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .preferredColorScheme(.light)
}

#Preview("Analytics · system dark, Unit stays light") {
    NavigationStack { AnalyticsView() }
        .modelContainer(PreviewSampleData.makePreviewContainer())
        .environment(\.colorScheme, .dark)
        .preferredColorScheme(.light)
}
