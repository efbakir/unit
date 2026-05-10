//
//  ExerciseProgressView.swift
//  Unit
//
//  Exercise-focused progress: PR stat, weight timeline chart, per-session delta list.
//

import Charts
import SwiftUI

struct ExerciseProgressView: View {
    let exerciseId: UUID
    let exerciseName: String
    let isBodyweight: Bool
    let sessions: [WorkoutSession]
    let templates: [DayTemplate]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    struct SessionPoint: Identifiable {
        let id: UUID
        let date: Date
        let weight: Double
        let reps: Int
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

    // Best set per completed session (highest weight, then reps)
    private var sessionPoints: [SessionPoint] {
        sessions
            .filter(\.isCompleted)
            .compactMap { session -> SessionPoint? in
                let best = session.setEntries
                    .filter { $0.exerciseId == exerciseId && $0.isCompleted && !$0.isWarmup }
                    .max { lhs, rhs in lhs.weight == rhs.weight ? lhs.reps < rhs.reps : lhs.weight < rhs.weight }
                guard let best else { return nil }
                return SessionPoint(id: session.id, date: session.date, weight: best.weight, reps: best.reps, templateId: session.templateId)
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

                if sessionPoints.count > 1 {
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
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Best set")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                Text(WorkoutTargetFormatter.actualText(weightKg: pr.weight, setCount: 1, reps: pr.reps, isBodyweight: isBodyweight))
                    .font(AppFont.title.font)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            Spacer(minLength: 0)
            VStack(alignment: .trailing, spacing: AppSpacing.xs) {
                Text(isBodyweight ? "Best reps" : "Est. 1RM")
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                Text(isBodyweight ? "\(pr.reps)" : WorkoutTargetFormatter.weightDisplay(epley1RM ?? pr.weight))
                    .font(AppFont.title.font)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .appCardStyle()
    }

    // MARK: - Chart

    /// Padded Y-axis domain so two-or-three-point series with identical or
    /// near-identical weights still render labelled axes. Without this, Charts
    /// collapses the Y range to a single value and the axis labels disappear.
    private var chartYDomain: ClosedRange<Double> {
        let weights = sessionPoints.map(chartValue)
        guard let lo = weights.min(), let hi = weights.max() else { return 0...1 }
        let span = hi - lo
        let pad = max(span * 0.15, 5)
        return max(0, lo - pad)...(hi + pad)
    }

    private var chartCard: some View {
        SettingsSection(title: isBodyweight ? "Reps over time" : "Weight over time") {
            Chart(sessionPoints) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value(isBodyweight ? "Reps" : "Weight (kg)", chartValue(for: point))
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(AppColor.textPrimary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                PointMark(
                    x: .value("Date", point.date),
                    y: .value(isBodyweight ? "Reps" : "Weight (kg)", chartValue(for: point))
                )
                .foregroundStyle(AppColor.textPrimary)
                .symbolSize(30)
            }
            .chartXAxis {
                // `.automatic(desiredCount: 4)` lets Charts pick the stride based
                // on available width and data range — months at iPhone-SE width
                // with 6 months of data, quarters/years for multi-year history.
                // Fixes the prior crowding when 12+ month labels collided on
                // narrow widths under a hardcoded `.stride(by: .month)`.
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
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
            .chartYScale(domain: chartYDomain)
            .frame(minHeight: 160)
            .appAnimation(.appReveal, value: exerciseName, reduceMotion: reduceMotion)
        }
    }

    private func chartValue(for point: SessionPoint) -> Double {
        isBodyweight ? Double(point.reps) : point.weight
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
                Text(WorkoutTargetFormatter.actualText(weightKg: point.weight, setCount: 1, reps: point.reps, isBodyweight: isBodyweight))
                    .font(AppFont.body.font)
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
}
