//
//  TodayRoutineOverride.swift
//  Unit
//
//  Optional per-calendar-day pick for which program routine shows on Today.
//

import Foundation

enum TodayRoutineOverride {
    private static let templateKey = "unit.todayRoutineOverride.templateId"
    private static let dayKey = "unit.todayRoutineOverride.dayAnchor"

    /// Returns a stored override only when its day anchor matches today and the template is still in the program.
    ///
    /// Called from `TodayView.body` via `dashboardState`, so it must not touch
    /// UserDefaults unless a stored value actually exists: a redundant
    /// `removeObject` during view update re-invalidates the view and locks the
    /// main thread in an infinite body → write → body loop (hard hang on
    /// launch, observed on iOS 27).
    static func effectiveTemplateId(orderedTemplateIds: [UUID]) -> UUID? {
        let ud = UserDefaults.standard
        guard ud.string(forKey: dayKey) != nil || ud.string(forKey: templateKey) != nil else {
            return nil
        }
        let todayAnchor = dayAnchor(for: Date())
        guard ud.string(forKey: dayKey) == todayAnchor else {
            clear()
            return nil
        }
        guard let raw = ud.string(forKey: templateKey),
              let id = UUID(uuidString: raw),
              orderedTemplateIds.contains(id) else {
            clear()
            return nil
        }
        return id
    }

    static func set(templateId: UUID) {
        let ud = UserDefaults.standard
        ud.set(templateId.uuidString, forKey: templateKey)
        ud.set(dayAnchor(for: Date()), forKey: dayKey)
    }

    static func clear() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: templateKey)
        ud.removeObject(forKey: dayKey)
    }

    private static func dayAnchor(for date: Date) -> String {
        let c = Calendar.current
        let y = c.component(.year, from: date)
        let m = c.component(.month, from: date)
        let d = c.component(.day, from: date)
        return String(format: "%04d-%02d-%02d", y, m, d)
    }
}
