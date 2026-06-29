//
//  EarlierWeekCatchup.swift
//  Unit
//
//  Shared logic for “still available this week” routines — used from History, not as a Today-home nudge.
//

import Foundation

struct EarlierWeekRoutineInfo: Identifiable {
    let id = UUID()
    let templateName: String
    let templateId: UUID
    /// Full weekday label (e.g. “Monday”) for accessibility and subtitles.
    let scheduledDayName: String
    let scheduledDate: Date
}

enum EarlierWeekCatchup {
    /// Routines scheduled on an earlier weekday this week that have not been completed yet (Mon–Sun week).
    static func incompleteItems(
        orderedTemplates: [DayTemplate],
        scheduleStartDate: Date? = nil,
        sessions: [WorkoutSession]
    ) -> [EarlierWeekRoutineInfo] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let todayWeekday = calendar.component(.weekday, from: today)

        var mondayCalendar = Calendar(identifier: .gregorian)
        mondayCalendar.firstWeekday = 2
        guard let weekInterval = mondayCalendar.dateInterval(of: .weekOfYear, for: today) else { return [] }
        let weekStart = weekInterval.start

        let todayOffset = (todayWeekday + 5) % 7

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"

        var items: [EarlierWeekRoutineInfo] = []
        for template in orderedTemplates {
            let wd = template.scheduledWeekday
            guard wd > 0, wd != todayWeekday else { continue }
            let templateOffset = (wd + 5) % 7
            guard templateOffset < todayOffset else { continue }

            let wasPerformed = sessions.contains { session in
                session.templateId == template.id &&
                    session.isCompleted &&
                    session.date >= weekStart &&
                    session.date < today.addingTimeInterval(86400)
            }
            if !wasPerformed {
                let scheduledDate = calendar.date(byAdding: .day, value: templateOffset - todayOffset, to: today) ?? today
                if let scheduleStartDate,
                   scheduledDate < calendar.startOfDay(for: scheduleStartDate) {
                    continue
                }
                items.append(EarlierWeekRoutineInfo(
                    templateName: template.displayName,
                    templateId: template.id,
                    scheduledDayName: dayFormatter.string(from: scheduledDate),
                    scheduledDate: scheduledDate
                ))
            }
        }
        return items
    }

    static func orderedTemplates(for split: Split, templates: [DayTemplate]) -> [DayTemplate] {
        let splitTemplates = templates.filter { $0.splitId == split.id }
        let templateByID = Dictionary(uniqueKeysWithValues: splitTemplates.map { ($0.id, $0) })
        let ordered = split.orderedTemplateIds.compactMap { templateByID[$0] }
        return ordered.isEmpty ? splitTemplates.sorted { $0.name < $1.name } : ordered
    }
}
