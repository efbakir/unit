//
//  TrainingWeekProgress.swift
//  Unit
//
//  Week strip + weekly overview for the Today dashboard.
//

import Foundation
import SwiftUI

// MARK: - Models

struct TodayWeekStripItem: Identifiable, Hashable {
    let id: String
    let weekStart: Date
    let shortLabel: String
    let presentation: Presentation

    enum Presentation: Hashable {
        /// Current ISO week — black capsule with label.
        case chip
        /// Previous / next week — circle with glyph.
        case circle(CircleGlyph)
    }

    enum CircleGlyph: Hashable {
        case check
        case minus
        case weekNumber(Int)
    }
}

struct TodayWeekOverviewDay: Identifiable, Hashable {
    let id: Date
    let title: String
    let subtitle: String
    let state: DayState

    enum DayState: Hashable {
        case completed
        case missed
        case upcoming
    }
}

enum TrainingWeekProgressBuilder {
    /// Three items: previous ISO week, current, next.
    static func weekStripItems(
        calendar: Calendar = .current,
        routineTemplateIDs: [UUID],
        sessions: [WorkoutSession]
    ) -> [TodayWeekStripItem] {
        let k = routineTemplateIDs.count
        let templateIDs = Set(routineTemplateIDs)
        let now = Date()
        guard k > 0,
              let currentInterval = calendar.dateInterval(of: .weekOfYear, for: now),
              let prevStart = calendar.date(byAdding: .weekOfYear, value: -1, to: currentInterval.start),
              let nextStart = calendar.date(byAdding: .weekOfYear, value: 1, to: currentInterval.start)
        else { return [] }

        let currentStart = currentInterval.start
        let completed = sessions.filter(\.isCompleted)

        let prevItem = buildPreviousWeek(
            weekStart: prevStart,
            calendar: calendar,
            routineCount: k,
            templateIDs: templateIDs,
            sessions: completed
        )
        let currentItem = buildCurrentWeekChip(
            weekStart: currentStart,
            calendar: calendar
        )
        let nextItem = buildNextWeekCircle(
            weekStart: nextStart,
            calendar: calendar
        )

        return [prevItem, currentItem, nextItem]
    }

    static func overviewDays(
        weekStart: Date,
        calendar: Calendar = .current,
        now: Date = Date(),
        routineTemplateIDs: [UUID],
        sessions: [WorkoutSession]
    ) -> [TodayWeekOverviewDay] {
        let templateIDs = Set(routineTemplateIDs)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: weekStart) else {
            return []
        }

        let completedSessions = sessions.filter(\.isCompleted)
        let startOfToday = calendar.startOfDay(for: now)

        var days: [TodayWeekOverviewDay] = []
        var dayCursor = interval.start

        let formatter = DateFormatter()
        formatter.locale = calendar.locale
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")

        while dayCursor < interval.end {
            let dayStart = calendar.startOfDay(for: dayCursor)
            let hadSession = completedSessions.contains { session in
                templateIDs.contains(session.templateId)
                    && calendar.isDate(session.date, inSameDayAs: dayStart)
            }

            let isPast = dayStart < startOfToday
            let isToday = calendar.isDateInToday(dayCursor)

            let state: TodayWeekOverviewDay.DayState
            if isToday {
                state = hadSession ? .completed : .upcoming
            } else if isPast {
                state = hadSession ? .completed : .missed
            } else {
                state = .upcoming
            }

            let title = formatter.string(from: dayCursor)
            let subtitle: String
            switch state {
            case .completed:
                subtitle = "Completed"
            case .missed:
                subtitle = "Missed"
            case .upcoming:
                subtitle = isToday ? "Today" : "Upcoming"
            }

            days.append(
                TodayWeekOverviewDay(
                    id: dayStart,
                    title: title,
                    subtitle: subtitle,
                    state: state
                )
            )

            guard let next = calendar.date(byAdding: .day, value: 1, to: dayCursor) else { break }
            dayCursor = next
        }

        return days
    }

    /// Past calendar day where the lifter actually had a routine scheduled
    /// and didn't log a session. Three guards in order:
    ///
    /// 1. **Past date** — today and future days are never "missed".
    /// 2. **Date's weekday is in `scheduledWeekdays`** — the lifter only
    ///    "misses" a day they had explicitly assigned in onboarding (e.g.
    ///    Mon/Wed/Fri). Tuesdays for a 3-day push/pull/legs lifter are
    ///    rest days by design, not missed workouts. Pass an empty set for
    ///    flexible-schedule (rotation-mode) splits — every day is fair
    ///    game, so nothing is technically "missed".
    /// 3. **No completed session** from any routine template on that day.
    ///
    /// `scheduledWeekdays` uses iOS `Calendar` weekday numbering
    /// (1 = Sunday, 7 = Saturday), matching `DayTemplate.scheduledWeekday`.
    /// The 0 value (rotation) should never appear in this set — callers
    /// must filter it out before constructing.
    static func isMissedTrainingDay(
        date: Date,
        calendar: Calendar = .current,
        now: Date = Date(),
        routineTemplateIDs: [UUID],
        scheduledWeekdays: Set<Int>,
        sessions: [WorkoutSession]
    ) -> Bool {
        guard !routineTemplateIDs.isEmpty else { return false }
        guard !scheduledWeekdays.isEmpty else { return false }
        let dayStart = calendar.startOfDay(for: date)
        let startOfToday = calendar.startOfDay(for: now)
        guard dayStart < startOfToday else { return false }
        if calendar.isDateInToday(date) { return false }

        let weekday = calendar.component(.weekday, from: dayStart)
        guard scheduledWeekdays.contains(weekday) else { return false }

        let templateIDs = Set(routineTemplateIDs)
        let completedSessions = sessions.filter(\.isCompleted)
        let hadSession = completedSessions.contains { session in
            templateIDs.contains(session.templateId)
                && calendar.isDate(session.date, inSameDayAs: dayStart)
        }
        return !hadSession
    }

    // MARK: - Strip items

    private static func buildPreviousWeek(
        weekStart: Date,
        calendar: Calendar,
        routineCount: Int,
        templateIDs: Set<UUID>,
        sessions: [WorkoutSession]
    ) -> TodayWeekStripItem {
        let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let inWeek = sessions.filter { session in
            templateIDs.contains(session.templateId)
                && session.date >= weekStart
                && session.date < weekEnd
        }
        let distinct = Set(inWeek.map(\.templateId))
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        let id = "\(calendar.component(.yearForWeekOfYear, from: weekStart))-\(weekOfYear)"

        let glyph: TodayWeekStripItem.CircleGlyph
        if distinct.count >= routineCount {
            glyph = .check
        } else {
            glyph = .minus
        }

        return TodayWeekStripItem(
            id: id,
            weekStart: weekStart,
            shortLabel: "W\(weekOfYear)",
            presentation: .circle(glyph)
        )
    }

    private static func buildCurrentWeekChip(
        weekStart: Date,
        calendar: Calendar
    ) -> TodayWeekStripItem {
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        let id = "\(calendar.component(.yearForWeekOfYear, from: weekStart))-\(weekOfYear)-current"
        return TodayWeekStripItem(
            id: id,
            weekStart: weekStart,
            shortLabel: "W\(weekOfYear)",
            presentation: .chip
        )
    }

    private static func buildNextWeekCircle(
        weekStart: Date,
        calendar: Calendar
    ) -> TodayWeekStripItem {
        let weekOfYear = calendar.component(.weekOfYear, from: weekStart)
        let id = "\(calendar.component(.yearForWeekOfYear, from: weekStart))-\(weekOfYear)-next"
        return TodayWeekStripItem(
            id: id,
            weekStart: weekStart,
            shortLabel: "W\(weekOfYear)",
            presentation: .circle(.weekNumber(weekOfYear))
        )
    }
}

// MARK: - Formatting

extension TrainingWeekProgressBuilder {
    static func weekRangeTitle(weekStart: Date, calendar: Calendar = .current) -> String {
        let start = calendar.startOfDay(for: weekStart)
        guard let end = calendar.date(byAdding: .day, value: 6, to: start) else { return "" }
        let df = DateFormatter()
        df.locale = calendar.locale
        df.setLocalizedDateFormatFromTemplate("d MMM")
        return "\(df.string(from: start))–\(df.string(from: end))"
    }
}

// MARK: - Views

struct TrainingWeekStripView: View {
    let items: [TodayWeekStripItem]
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(items) { item in
                    weekStripSegment(item)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Week overview")
        .accessibilityHint("Shows which days you trained this week")
    }

    @ViewBuilder
    private func weekStripSegment(_ item: TodayWeekStripItem) -> some View {
        switch item.presentation {
        case .chip:
            Text(item.shortLabel)
                .font(AppFont.stepIndicator.font)
                .foregroundStyle(AppColor.accentForeground)
                .padding(.horizontal, AppSpacing.md)
                .padding(.vertical, AppSpacing.xs)
                .background(AppColor.textPrimary)
                .clipShape(Capsule(style: .continuous))
                .layoutPriority(1)

        case .circle(let glyph):
            AppIconCircle(diameter: 40, surface: .control) {
                Group {
                    switch glyph {
                    case .check:
                        AppIcon.checkmark.image(size: 15, weight: .semibold)
                            .foregroundStyle(AppColor.success)
                    case .minus:
                        AppIcon.remove.image(size: 16, weight: .semibold)
                            .foregroundStyle(AppColor.textSecondary)
                    case .weekNumber(let n):
                        Text("\(n)")
                            .font(AppFont.stepIndicator.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .monospacedDigit()
                    }
                }
            }
            .accessibilityLabel(weekAccessibilityLabel(item, glyph: glyph))
        }
    }

    private func weekAccessibilityLabel(_ item: TodayWeekStripItem, glyph: TodayWeekStripItem.CircleGlyph) -> String {
        switch glyph {
        case .check:
            return "Week \(item.shortLabel), all routines completed"
        case .minus:
            return "Week \(item.shortLabel), missed sessions"
        case .weekNumber(let n):
            return "Week \(n)"
        }
    }
}

struct TodayWeekOverviewSheet: View {
    struct WeekOverviewTab: Identifiable, Hashable {
        let id: String
        let segmentTitle: String
        let navigationTitle: String
        let days: [TodayWeekOverviewDay]
    }

    let tabs: [WeekOverviewTab]
    @State private var selectedTabID: String
    @Environment(\.dismiss) private var dismiss

    init(tabs: [WeekOverviewTab], initialTabID: String) {
        self.tabs = tabs
        _selectedTabID = State(initialValue: initialTabID)
    }

    private var selectedDays: [TodayWeekOverviewDay] {
        tabs.first(where: { $0.id == selectedTabID })?.days ?? []
    }

    private var selectedNavigationTitle: String {
        tabs.first(where: { $0.id == selectedTabID })?.navigationTitle ?? ""
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 0) {
                if tabs.count > 1 {
                    AppSegmentedControl(
                        selection: $selectedTabID,
                        items: tabs,
                        title: { $0.segmentTitle }
                    )
                    .padding(.horizontal, AppSpacing.md)
                    .padding(.top, AppSpacing.sm)
                }

                ScrollView {
                    AppDividedList(
                        selectedDays,
                        dividerLeading: AppSpacing.md
                    ) { day in
                        HStack(alignment: .center) {
                            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                                Text(day.title)
                                    .font(AppFont.sectionHeader.font)
                                    .foregroundStyle(AppColor.textPrimary)

                                Text(day.subtitle)
                                    .font(AppFont.caption.font)
                                    .foregroundStyle(AppColor.textSecondary)
                            }

                            Spacer(minLength: 0)

                            dayStatusIcon(day.state)
                        }
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.smd)
                    }
                    .padding(.vertical, AppSpacing.sm)
                }
            }
            .background(AppColor.background)
            .navigationTitle(selectedNavigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(AppCopy.Nav.done) {
                        dismiss()
                    }
                    .appToolbarTextStyle()
                }
            }
            .appNavigationBarChrome()
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
    }

    @ViewBuilder
    private func dayStatusIcon(_ state: TodayWeekOverviewDay.DayState) -> some View {
        switch state {
        case .completed:
            AppIcon.checkmarkFilled.image(size: 20, weight: .semibold)
                .foregroundStyle(AppColor.success)
        case .missed:
            AppIcon.minusCircle.image(size: 20, weight: .semibold)
                .foregroundStyle(AppColor.textSecondary)
        case .upcoming:
            AppIcon.circle.image(size: 20, weight: .semibold)
                .foregroundStyle(AppColor.textDisabled)
        }
    }
}
