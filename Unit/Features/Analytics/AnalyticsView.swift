import SwiftData
import SwiftUI

/// Analytics page; ContentView remains the native tab/navigation owner.
struct AnalyticsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage("unitSystem") private var unit = "kg"
    @AppStorage(ActiveSplitStore.defaultsKey) private var activeSplit = ""
    @AppStorage("unit.analytics.mainLiftIDs") private var pinnedRaw = ""
    @State private var store = AnalyticsStore()
    @State private var revision = 0
    @State private var showsExplanation = false
    @State private var showsMainLiftEditor = false
    @State private var error: AppToastEvent?
    @State private var initialLoadFailed = false
    @State private var hasPresentedMainLifts = false

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
                        if !output.mainIDs.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                AppSectionHeader("Main lifts") {
                                    AppGhostButton(AppCopy.Workout.edit, layout: .inline) { showsMainLiftEditor = true }
                                        .accessibilityLabel("Edit main lifts")
                                        .accessibilityHint("Choose up to 3 main lifts.")
                                        .accessibilityIdentifier("analytics-edit-main")
                                }
                                VStack(spacing: AppSpacing.smd) {
                                    ForEach(output.mainIDs, id: \.self) { id in
                                        if let lift = output.lifts[id] {
                                            NavigationLink(value: id) { mainCard(lift, output: output) }
                                                .buttonStyle(ScaleButtonStyle())
                                                .accessibilityHint("Opens details.")
                                                .accessibilityIdentifier("analytics-main-\(lift.exercise.name)")
                                                .transition(AppBlurTransition(scales: true).animation(hasPresentedMainLifts ? .appReveal : nil))
                                        }
                                    }
                                }
                                .appAnimation(AppMotion.collectionChange, value: output.mainIDs, reduceMotion: reduceMotion)
                                .onAppear { hasPresentedMainLifts = true }
                            }
                        }
                        // Above Other exercises: that list grows with every exercise logged.
                        if output.muscleSets.contains(where: { $0.sets > 0 }) {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                AppSectionHeader("Sets per muscle · last 4 weeks")
                                AppCardList(output.muscleSets, rowVerticalInset: AppSpacing.xs) { row in
                                    AppListRow(
                                        title: MuscleGroup(rawValue: row.muscle)?.displayName ?? "Other",
                                        value: "\(row.sets.formatted()) \(row.sets == 1 ? "set" : "sets")",
                                        subtitle: row.muscle.isEmpty ? "Muscle unknown" : nil,
                                        style: .cardListContent
                                    )
                                    .accessibilityElement(children: .combine)
                                    .accessibilityIdentifier("analytics-muscle-\(row.muscle.isEmpty ? "other" : row.muscle)")
                                }
                                Text("Each set counts once, for its main muscle.")
                                    .font(AppFont.caption.font).tracking(AppFont.title.tracking).foregroundStyle(AppColor.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        if !output.other.isEmpty {
                            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                                AppSectionHeader("Other exercises")
                                AppCardList(data: output.other, id: \.self, rowVerticalInset: AppSpacing.xs) { id in
                                    if let lift = output.lifts[id], let latest = lift.latest {
                                        NavigationLink(value: id) {
                                            AppListRow(
                                                title: lift.exercise.name,
                                                value: WorkoutTargetFormatter.analyticsPerformance(latest, bodyweight: lift.bodyweight, unit: unit, onBodyweight: lift.exercise.isBodyweight),
                                                style: .cardListContent,
                                                showsDisclosure: true
                                            )
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
            } else if initialLoadFailed {
                VStack(alignment: .leading, spacing: AppSpacing.md) {
                    EmptyStateCard(title: "Couldn’t load progress", message: "Try again.")
                    AppSecondaryButton("Retry") { revision += 1 }
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
        .sheet(isPresented: $showsMainLiftEditor) {
            if let output = store.output {
                MainLiftsEditor(output: output, automaticIDs: store.automaticMainIDs, pinnedRaw: $pinnedRaw)
            }
        }
        .appToast(event: $error)
        .task(id: revision) { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in revision += 1 }
        .onChange(of: activeSplit) { _, _ in revision += 1 }
        .onChange(of: pinnedRaw) { _, _ in revision += 1 }
        .onChange(of: phase) { _, phase in if phase == .active { revision += 1 } }
    }
    private func reload() async {
        initialLoadFailed = false
        do {
            try await store.refresh(context: context, now: Date(), calendar: .current, pinnedMainIDs: AnalyticsEngine.parsedMainIDs(pinnedRaw))
            self.error = nil
        } catch {
            guard !Task.isCancelled else { return }
            initialLoadFailed = store.output == nil
            self.error = AppToastEvent(error.localizedDescription, kind: .error)
        }
    }
    private func mainCard(_ lift: AnalyticsEngine.Lift, output: AnalyticsEngine.Output) -> some View {
        AppMainLiftCard(title: lift.exercise.name, icon: AnalyticsEngine.slot(for: lift.exercise).map(Self.icon(for:)) ?? Self.icon(for: lift.exercise), lift: lift,
                        chart: AnalyticsEngine.chart(lift: lift, weekStarts: output.weekStarts, metric: lift.bodyweight ? .reps : .weight, unit: unit), unit: unit, now: output.today)
    }
    static func icon(for slot: AnalyticsEngine.Slot) -> AppIcon {
        switch slot { case .squat: .liftSquat; case .bench: .liftBench; case .deadlift: .liftDeadlift }
    }
    static func icon(for exercise: AnalyticsEngine.ExerciseInput) -> AppIcon? {
        ExerciseIconResolver.icon(name: exercise.name, muscleGroup: exercise.muscleGroup, equipment: exercise.equipment)
    }
    private var explanationSheet: some View {
        VStack(spacing: 0) {
            NavigationStack {
                AppScreen(showsNativeNavigationBar: true) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        Text("Each lift compares its best set from the last 4 weeks with the 4 weeks before.")
                            .font(AppFont.body.font)
                        AppCardList(data: [
                            ("Up", "More weight or reps, nothing less"),
                            ("Same", "No change"),
                            ("Mixed", "Weight and reps both changed"),
                            ("Below best", "Less weight or reps, the other the same")
                        ], id: \.0) { item in
                            AppListRow(title: item.0, subtitle: item.1, style: .cardListContent)
                        }
                        VStack(alignment: .leading, spacing: AppSpacing.sm) {
                            AppSectionHeader("Status")
                            AppCardList(data: [
                                ("Getting stronger", "Half or more of your lifts up, most planned sessions done"),
                                ("Holding steady", "Anything else"),
                                ("Fewer sessions lately", "Under half of planned sessions done"),
                                ("Building a baseline", "Under 2 weeks of sessions")
                            ], id: \.0) { item in
                                AppListRow(title: item.0, subtitle: item.1, style: .cardListContent)
                            }
                        }
                        Text("Warm-up sets don’t count. The status changes after 3 days.")
                            .font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                    }
                }
                .navigationTitle("How this works").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Group {
                            Button { showsExplanation = false } label: {
                                Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName).labelStyle(.iconOnly)
                            }
                        }
                        .tint(AppColor.textPrimary)
                    }
                }
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
