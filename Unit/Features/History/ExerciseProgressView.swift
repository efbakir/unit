//
//  ExerciseProgressView.swift
//  Unit
//
//  Exercise-focused progress: weight, reps, volume, and chronological sessions.
//

import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exerciseId: UUID
    let exerciseName: String
    let isBodyweight: Bool
    let sessions: [WorkoutSession]
    let templates: [DayTemplate]

    @AppStorage("unitSystem") private var unitSystem = "kg"
    @State private var selectedMetric: ProgressMetric
    @State private var selectedChartDate: Date?

    private enum ProgressMetric: String, CaseIterable, Identifiable {
        case weight = "Weight"
        case reps = "Reps"
        case volume = "Volume"

        var id: String { rawValue }
    }

    struct SessionPoint: Identifiable {
        let id: UUID
        let date: Date
        let weight: Double
        let reps: Int
        let maxReps: Int
        let volumeKg: Double
        let totalReps: Int
        let templateId: UUID
    }

    private struct SessionRowItem: Identifiable {
        let point: SessionPoint
        let prev: SessionPoint?
        var id: UUID { point.id }
    }

    private static let sessionDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    init(
        exerciseId: UUID,
        exerciseName: String,
        isBodyweight: Bool,
        sessions: [WorkoutSession],
        templates: [DayTemplate]
    ) {
        self.exerciseId = exerciseId
        self.exerciseName = exerciseName
        self.isBodyweight = isBodyweight
        self.sessions = sessions
        self.templates = templates
        _selectedMetric = State(initialValue: isBodyweight ? .reps : .weight)
    }

    // Best set per completed session (highest weight, then reps)
    private var sessionPoints: [SessionPoint] {
        sessions
            .filter(\.isCompleted)
            .compactMap { session -> SessionPoint? in
                let workingSets = session.setEntries
                    .filter { $0.exerciseId == exerciseId && $0.isCompleted && !$0.isWarmup }
                let best = workingSets.max {
                    lhs, rhs in lhs.weight == rhs.weight
                        ? lhs.reps < rhs.reps
                        : lhs.weight < rhs.weight
                }
                guard let best else { return nil }
                return SessionPoint(
                    id: session.id,
                    date: session.date,
                    weight: best.weight,
                    reps: best.reps,
                    maxReps: workingSets.map(\.reps).max() ?? best.reps,
                    volumeKg: workingSets.reduce(0) {
                        $0 + ($1.weight * Double($1.reps))
                    },
                    totalReps: workingSets.reduce(0) { $0 + $1.reps },
                    templateId: session.templateId
                )
            }
            .sorted { $0.date < $1.date }
    }

    private var allTimePR: SessionPoint? {
        sessionPoints.max { lhs, rhs in lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight }
    }

    private var epley1RM: Double? {
        guard !isBodyweight else { return nil }
        guard let pr = allTimePR else { return nil }
        guard pr.reps > 1 else { return pr.weight }
        return pr.weight * (1.0 + Double(pr.reps) / 30.0)
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                if let pr = allTimePR {
                    prCard(pr: pr)
                        // Identity-keyed numeric cross-fade — switching exercises
                        // (or a new PR landing) re-runs the entrance instead of
                        // popping in place.
                        .id(pr.id)
                        .transition(.opacity)
                }

                if !sessionPoints.isEmpty {
                    chartCard
                }

                if !sessionPoints.isEmpty {
                    sessionListCard
                } else {
                    EmptyStateCard(
                        title: "No data yet",
                        message: "Sets for \(exerciseName) show up here once you log them."
                    )
                }
            }
            .appScreenEnter()
        }
        .navigationBarTitleTruncated(exerciseName)
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
    }

    // MARK: - PR Card

    private func prCard(pr: SessionPoint) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(bestSetEvidence(for: pr))
                .font(AppFont.title.font)
                .foregroundStyle(AppColor.textPrimary)
                .monospacedDigit()
                .appNumericValue(value: bestSetEvidence(for: pr))

            Text(totalVolumeEvidence(for: pr))
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
                .monospacedDigit()

            if !isBodyweight, let epley1RM {
                Text("Estimated 1RM · \(WorkoutTargetFormatter.weightDisplay(epley1RM))")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
            }
        }
        .appCardStyle()
    }

    // MARK: - Chart

    /// Padded Y-axis domain so two-or-three-point series with identical or
    /// near-identical weights still render labelled axes. Without this, Charts
    /// collapses the Y range to a single value and the axis labels disappear.
    private var chartYDomain: ClosedRange<Double> {
        let values = sessionPoints.map(metricValue)
        guard let lo = values.min(), let hi = values.max() else { return 0...1 }
        let span = hi - lo
        let minimumPad = selectedMetric == .weight ? 5.0 : 1.0
        let pad = max(span * 0.15, minimumPad)
        return max(0, lo - pad)...(hi + pad)
    }

    /// Keep short histories fully labelled. Longer histories show evenly
    /// distributed dates, while chart selection exposes every session.
    private var chartXAxisDates: [Date] {
        let dates = sessionPoints.map(\.date)
        let maximumLabelCount = 4
        guard dates.count > maximumLabelCount else { return dates }

        let lastIndex = dates.count - 1
        return (0..<maximumLabelCount).map { position in
            let progress = Double(position) / Double(maximumLabelCount - 1)
            let index = Int((Double(lastIndex) * progress).rounded())
            return dates[index]
        }
    }

    private var selectedChartPoint: SessionPoint? {
        guard let selectedChartDate else { return nil }
        return sessionPoints.min { lhs, rhs in
            abs(lhs.date.timeIntervalSince(selectedChartDate))
                < abs(rhs.date.timeIntervalSince(selectedChartDate))
        }
    }

    private var chartReadoutPoint: SessionPoint? {
        selectedChartPoint ?? sessionPoints.last
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSegmentedControl(
                selection: $selectedMetric,
                items: ProgressMetric.allCases,
                title: { $0.rawValue }
            )

            SettingsSection(title: metricSectionTitle) {
                if let point = chartReadoutPoint {
                    HStack(alignment: .firstTextBaseline) {
                        Text(selectedChartDate == nil
                            ? "Latest · \(chartDateText(for: point.date))"
                            : chartDateText(for: point.date))
                            .foregroundStyle(AppColor.textSecondary)

                        Spacer(minLength: AppSpacing.sm)

                        Text(chartReadoutValue(for: point))
                            .foregroundStyle(AppColor.textPrimary)
                    }
                    .font(AppFont.caption.font)
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                }

                Chart(sessionPoints) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value(metricAxisLabel, metricValue(for: point))
                    )
                    .interpolationMethod(.monotone)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineStyle(StrokeStyle(lineWidth: 2))

                    PointMark(
                        x: .value("Date", point.date),
                        y: .value(metricAxisLabel, metricValue(for: point))
                    )
                    .foregroundStyle(AppColor.textPrimary)
                    .symbolSize(30)

                    if let selectedChartPoint, selectedChartPoint.id == point.id {
                        RuleMark(x: .value("Selected date", selectedChartPoint.date))
                            .foregroundStyle(AppColor.textSecondary.opacity(0.5))
                    }
                }
                .chartXAxis {
                    AxisMarks(values: chartXAxisDates) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppColor.border.opacity(0.4))
                        AxisTick()
                            .foregroundStyle(AppColor.border)
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                        AxisGridLine()
                            .foregroundStyle(AppColor.border.opacity(0.4))
                    }
                }
                .chartXScale(
                    range: .plotDimension(
                        startPadding: AppSpacing.smd,
                        endPadding: AppSpacing.smd
                    )
                )
                .chartXSelection(value: $selectedChartDate)
                .chartYScale(domain: chartYDomain)
                .frame(minHeight: 160)

                Text("Tap or drag for exact values.")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
        }
    }

    private var metricSectionTitle: String {
        switch selectedMetric {
        case .weight: return "Weight over time"
        case .reps: return "Reps over time"
        case .volume: return "Volume per session"
        }
    }

    private var metricAxisLabel: String {
        switch selectedMetric {
        case .weight:
            return "Weight (\(unitSystem))"
        case .reps:
            return "Reps"
        case .volume:
            return isBodyweight ? "Total reps" : "Volume (\(unitSystem)·reps)"
        }
    }

    private func metricValue(for point: SessionPoint) -> Double {
        switch selectedMetric {
        case .weight:
            return unitSystem == "lb" ? point.weight * 2.20462 : point.weight
        case .reps:
            return Double(point.maxReps)
        case .volume:
            if isBodyweight { return Double(point.totalReps) }
            return unitSystem == "lb" ? point.volumeKg * 2.20462 : point.volumeKg
        }
    }

    private func chartDateText(for date: Date) -> String {
        date.formatted(.dateTime.month(.abbreviated).day())
    }

    private func chartReadoutValue(for point: SessionPoint) -> String {
        switch selectedMetric {
        case .weight:
            if isBodyweight && point.weight <= 0 { return "BW" }
            return WorkoutTargetFormatter.weightDisplay(point.weight)
        case .reps:
            return "\(point.maxReps) reps"
        case .volume:
            return volumeText(for: point)
        }
    }

    // MARK: - Session list

    private var sessionRowItems: [SessionRowItem] {
        let reversed = Array(sessionPoints.reversed())
        return reversed.enumerated().map { idx, point in
            let prev = reversed.dropFirst(idx + 1).first { $0.templateId == point.templateId }
            return SessionRowItem(point: point, prev: prev)
        }
    }

    private var sessionListCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("Sessions")
            AppCardList(sessionRowItems) { item in
                sessionRow(point: item.point, prev: item.prev)
            }
        }
    }

    private func sessionRow(point: SessionPoint, prev: SessionPoint?) -> some View {
        let templateName = templates.first(where: { $0.id == point.templateId })?.name ?? "Session"
        let delta = prev.map { isBodyweight ? Double(point.reps - $0.reps) : point.weight - $0.weight }

        return HStack {
            VStack(alignment: .leading, spacing: AppSpacing.xxs) {
                Text(templateName)
                    .font(AppFont.body.font)
                Text(Self.sessionDateFormatter.string(from: point.date))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: AppSpacing.xxs) {
                Text(
                    WorkoutTargetFormatter.milestoneText(
                        weightKg: point.weight,
                        reps: point.reps,
                        isBodyweight: isBodyweight
                    ) ?? "\(point.reps) reps"
                )
                    .font(AppFont.body.font)
                    .monospacedDigit()
                Text(volumeText(for: point))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .monospacedDigit()
                if let d = delta {
                    if d > 0 {
                        Text(isBodyweight ? "+\(Int(d)) reps" : "+\(WorkoutTargetFormatter.weightDisplay(d))")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.success)
                            .monospacedDigit()
                    } else if d < 0 {
                        Text(isBodyweight ? "-\(Int(abs(d))) reps" : "-\(WorkoutTargetFormatter.weightDisplay(abs(d)))")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.error)
                            .monospacedDigit()
                    } else {
                        Text("No change")
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .layoutPriority(1)
            .fixedSize(horizontal: true, vertical: false)
        }
        .accessibilityElement(children: .combine)
    }

    private func volumeText(for point: SessionPoint) -> String {
        if isBodyweight {
            return "\(point.totalReps) total reps"
        }
        return WorkoutTargetFormatter.volumeDisplay(
            volumeKg: point.volumeKg,
            unitSystem: unitSystem
        ) ?? "—"
    }

    private func bestSetEvidence(for point: SessionPoint) -> String {
        if isBodyweight {
            return "Best set · \(point.reps) reps"
        }
        return "Best set · \(WorkoutTargetFormatter.weightDisplay(point.weight)) × \(point.reps)"
    }

    private func totalVolumeEvidence(for point: SessionPoint) -> String {
        if isBodyweight {
            let reps = WorkoutTargetFormatter.groupedCountDisplay(point.totalReps)
                ?? "\(point.totalReps)"
            return "Total reps · \(reps)"
        }
        let volume = WorkoutTargetFormatter.volumeDisplay(
            volumeKg: point.volumeKg,
            unitSystem: unitSystem
        ) ?? "—"
        return "Total volume · \(volume)"
    }
}
