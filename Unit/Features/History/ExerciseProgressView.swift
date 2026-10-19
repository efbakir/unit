import SwiftData
import SwiftUI

/// Analytics and History share the same detail and immutable calculation result.
struct ExerciseProgressView: View {
    let exerciseId: UUID
    let exerciseName: String
    let isBodyweight: Bool
    let sessions: [WorkoutSession]
    let templates: [DayTemplate]
    private let initialAnalytics: AnalyticsEngine.Output?
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var phase
    @AppStorage("unitSystem") private var unit = "kg"
    @State private var store = AnalyticsStore()
    @State private var revision = 0
    @State private var metric: AnalyticsEngine.Metric = .weight
    @State private var showsEstimate = false
    @State private var error: AppToastEvent?

    struct SessionPoint: Identifiable {
        let id: UUID
        let date: Date
        let weight: Double
        let reps: Int
        let maxReps: Int
        let volumeKg: Double
        let totalReps: Int
        let templateId: UUID
        let estimatedOneRM: Double?
    }

    init(exerciseId: UUID, exerciseName: String, isBodyweight: Bool, sessions: [WorkoutSession], templates: [DayTemplate], analytics: AnalyticsEngine.Output? = nil) {
        self.exerciseId = exerciseId; self.exerciseName = exerciseName
        self.isBodyweight = isBodyweight; self.sessions = sessions; self.templates = templates
        initialAnalytics = analytics
        _metric = State(initialValue: isBodyweight ? .reps : .weight)
    }
    private var output: AnalyticsEngine.Output? { store.output ?? initialAnalytics }
    private var lift: AnalyticsEngine.Lift? { output?.lifts[exerciseId] }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            if let lift, let output, let latest = lift.latest {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    HStack(spacing: AppSpacing.smd) {
                        AppIconCircle(diameter: AppSpacing.xxl, shape: .roundedRect(radius: AppRadius.sm), surface: .control) {
                            (AnalyticsEngine.slot(for: lift.exercise).map(AnalyticsView.icon(for:)) ?? AnalyticsView.icon(for: lift.exercise)).image(size: AppIconSize.readiness).foregroundStyle(AppColor.textSecondary)
                        }.accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(exerciseName).appFont(.productHeading).fixedSize(horizontal: false, vertical: true)
                            Text(metadata(lift.exercise)).font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                        }
                    }
                    AppCard(contentInset: AppSpacing.md, cornerRadius: AppRadius.md) {
                        VStack(alignment: .leading, spacing: AppSpacing.smd) {
                            AppMainLiftCard.metric(latest, bodyweight: lift.bodyweight, unit: unit, numberStyle: .splashTitle)
                                .accessibilityLabel(Self.performanceText(for: Self.point(lift.sessions.last!), isBodyweight: lift.bodyweight, unit: unit))
                            Text("\(Self.comparisonText(for: lift, unit: unit)) vs. previous 4 weeks")
                                .font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                            Text("\(WorkoutTargetFormatter.analyticsDate(latest.date, now: output.today))\(routineSuffix(latest.templateID))")
                                .font(AppFont.muted.font).foregroundStyle(AppColor.textSecondary)
                            if !lift.bodyweight {
                                AppSegmentedControl(selection: $metric, items: AnalyticsEngine.Metric.allCases, label: "Progress metric", title: { $0.rawValue })
                            }
                            AppTrendChart(data: AnalyticsEngine.chart(lift: lift, weekStarts: output.weekStarts, metric: lift.bodyweight ? .reps : metric, unit: unit), caption: lift.bodyweight ? "Most reps per week · 12 weeks" : "Best set per week · 12 weeks", interactive: true, height: AppChartMetrics.compactHeight, unit: unit, bodyweight: lift.bodyweight)
                        }
                    }
                    if let target = lift.target {
                        AppCard(contentInset: AppSpacing.md, cornerRadius: AppRadius.md) {
                            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                    Text("Next").font(AppFont.caption.font).foregroundStyle(AppColor.textSecondary)
                                    Text(WorkoutTargetFormatter.analyticsTarget(target, unit: unit)).font(AppFont.sectionHeader.font).monospacedDigit()
                                }
                                Spacer(minLength: AppSpacing.sm)
                                Text(target.templateName).font(AppFont.muted.font).foregroundStyle(AppColor.textSecondary)
                            }
                        }
                    }
                    AppCardList(data: detailRows(lift), id: \.self, rowVerticalInset: AppSpacing.xs) { row in
                        if row == "Best set", let best = lift.best {
                            AppListRow(title: "Best set", style: .cardListContent) {
                                VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                                    Text(WorkoutTargetFormatter.analyticsPerformance(best, bodyweight: lift.bodyweight, unit: unit)).font(AppFont.sectionHeader.font).monospacedDigit()
                                    Text(WorkoutTargetFormatter.analyticsDate(best.date, now: output.today)).font(AppFont.muted.font).foregroundStyle(AppColor.textSecondary)
                                }
                            }
                        } else if let estimate = AnalyticsEngine.estimatedOneRM(for: lift, unit: unit) {
                            Button { showsEstimate = true } label: {
                                HStack(spacing: AppSpacing.sm) {
                                    Text("Est. 1RM").font(AppFont.caption.font)
                                    AppIcon.info.image(size: AppIconSize.compact).accessibilityHidden(true)
                                    Spacer(minLength: AppSpacing.sm)
                                    Text(WorkoutTargetFormatter.analyticsWeight(estimate, unit: unit)).font(AppFont.sectionHeader.font).monospacedDigit()
                                }.foregroundStyle(AppColor.textPrimary).frame(minHeight: AppSpacing.xxl)
                            }.buttonStyle(ScaleButtonStyle())
                        }
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AppSectionHeader("Recent")
                        AppCardList(Array(lift.sessions.suffix(2).reversed()), rowVerticalInset: AppSpacing.xs) { session in
                            AppListRow(title: WorkoutTargetFormatter.analyticsDate(session.best.date, now: output.today), style: .cardListContent) {
                                Text(session.sets.map { WorkoutTargetFormatter.analyticsRecentSet($0, unit: unit) }.joined(separator: " · "))
                                    .font(AppFont.caption.font).foregroundStyle(AppColor.textPrimary).monospacedDigit()
                                    .multilineTextAlignment(.trailing).fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else if output != nil {
                EmptyStateCard(title: "No workouts yet", message: "Finish a workout to see progress.")
            } else {
                Text(exerciseName).appFont(.productHeading).redacted(reason: .placeholder)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .appToast(event: $error)
        .task(id: revision) {
            do { try await store.refresh(context: context, now: Date(), calendar: .current) }
            catch { self.error = AppToastEvent(error.localizedDescription, kind: .error) }
        }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in revision += 1 }
        .onReceive(NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)) { _ in revision += 1 }
        .onChange(of: phase) { _, phase in if phase == .active { revision += 1 } }
        .sheet(isPresented: $showsEstimate) {
            VStack {
                NavigationStack {
                    Text("Estimated from your best set. Not a tested max.")
                        .font(AppFont.body.font).foregroundStyle(AppColor.textPrimary).padding(AppSpacing.md)
                        .navigationTitle("Est. 1RM").navigationBarTitleDisplayMode(.inline)
                        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showsEstimate = false } } }
                        .appNavigationBarChrome()
                }
            }.presentationDetents([.medium]).appBottomSheetChrome()
        }
    }
    private func detailRows(_ lift: AnalyticsEngine.Lift) -> [String] {
        AnalyticsEngine.estimatedOneRM(for: lift, unit: unit) == nil ? ["Best set"] : ["Best set", "Est. 1RM"]
    }
    private func routineSuffix(_ id: UUID) -> String {
        guard let name = (store.templates.isEmpty ? templates : store.templates).first(where: { $0.id == id })?.displayName else { return "" }
        return " · \(name)"
    }
    private func metadata(_ exercise: AnalyticsEngine.ExerciseInput) -> String {
        [exercise.equipment.flatMap(Equipment.init(rawValue:))?.displayName, MuscleGroup(rawValue: exercise.muscleGroup)?.displayName].compactMap { $0 }.joined(separator: " · ")
    }
    static func point(_ value: AnalyticsEngine.SessionResult) -> SessionPoint {
        SessionPoint(id: value.id, date: value.best.date, weight: value.best.weight, reps: value.best.reps, maxReps: value.maxReps, volumeKg: value.volumeKg, totalReps: value.sets.reduce(0) { $0 + $1.reps }, templateId: value.best.templateID, estimatedOneRM: value.estimatedOneRM)
    }
    static func comparisonText(for lift: AnalyticsEngine.Lift, unit: String) -> String {
        WorkoutTargetFormatter.analyticsChange(lift.comparison, unit: unit)
    }
    /// Compatibility projection for History callers; calculations have one owner.
    static func sessionPointsByExercise(
        in sessions: [WorkoutSession], matching exerciseID: UUID? = nil,
        now: Date = Date(), calendar: Calendar = .current
    ) -> [UUID: [SessionPoint]] {
        let snapshots: [AnalyticsEngine.SessionInput] = sessions.filter(\.isCompleted).map { session in
            .init(id: session.id, date: session.date, templateID: session.templateId, sets: session.setEntries.filter {
                $0.isValidCompletedWorkingSet && (exerciseID == nil || $0.exerciseId == exerciseID)
            }.map { .init(exerciseID: $0.exerciseId, weight: $0.weight, reps: $0.reps, index: $0.setIndex) })
        }
        let ids = Set(snapshots.flatMap { $0.sets.map(\.exerciseID) })
        // This API projects session evidence only. Names/equipment are unknown
        // here and are never rendered or inferred by this compatibility bridge.
        let input = AnalyticsEngine.Input(exercises: ids.map {
            .init(id: $0, name: "", isBodyweight: false, equipment: nil, muscleGroup: "")
        }, sessions: snapshots, templates: [], plannedDaysPerWeek: 0)
        return AnalyticsEngine.compute(input, now: now, calendar: calendar).lifts.mapValues {
            $0.sessions.map(Self.point)
        }
    }

    static func performanceText(for point: SessionPoint, isBodyweight: Bool, unit: String? = nil) -> String {
        if let unit {
            return "\(isBodyweight || point.weight == 0 ? "BW" : WorkoutTargetFormatter.analyticsWeight(point.weight, unit: unit)) × \(point.reps.formatted())"
        }
        return WorkoutTargetFormatter.milestoneText(
            weightKg: point.weight, reps: point.reps, isBodyweight: isBodyweight
        ) ?? "\(point.reps) reps"
    }

    /// Compare the heaviest set only within one routine. A load increase with
    /// fewer reps is not labelled progress; show the previous evidence instead.
    static func comparisonText(for point: SessionPoint, previous: SessionPoint?, isBodyweight: Bool) -> String {
        guard let previous, previous.templateId == point.templateId else {
            return "First recorded session for this routine"
        }
        if point.weight == previous.weight, point.reps != previous.reps {
            let delta = point.reps - previous.reps
            return "\(delta > 0 ? "+" : "")\(delta) reps at the same load"
        }
        if point.reps == previous.reps, point.weight != previous.weight {
            let delta = point.weight - previous.weight
            return "\(delta > 0 ? "+" : "−")\(WorkoutTargetFormatter.weightDisplay(abs(delta))) at \(point.reps) reps"
        }
        return "Previous · \(performanceText(for: previous, isBodyweight: isBodyweight))"
    }
}
