import Foundation

extension WorkoutTargetFormatter {
    static func analyticsWeight(_ kg: Double, unit: String, locale: Locale = .current, delta: Bool = false) -> String {
        var value = unit == "lb" ? kg * 2.20462 : kg
        let step = unit == "lb" ? 0.1 : 0.01
        if delta && kg > 0 && (value / step).rounded() == 0 { value = step }
        return "\(weightNumber(display: value, unit: unit, locale: locale)) \(unit)"
    }
    /// `onBodyweight` is the exercise's own bodyweight flag: added load then
    /// reads "BW + 10 kg", the same as while logging and in History.
    static func analyticsPerformance(_ value: AnalyticsEngine.Performance, bodyweight: Bool, unit: String, onBodyweight: Bool = false) -> String {
        "\(analyticsLoad(value.weight, bodyweight: bodyweight, onBodyweight: onBodyweight, unit: unit)) × \(value.reps.formatted())"
    }
    static func analyticsTarget(_ value: AnalyticsEngine.Target, unit: String, onBodyweight: Bool = false) -> String {
        "\(analyticsLoad(value.weight, bodyweight: false, onBodyweight: onBodyweight, unit: unit)) × \(value.reps.formatted())"
    }
    private static func analyticsLoad(_ kg: Double, bodyweight: Bool, onBodyweight: Bool, unit: String) -> String {
        if bodyweight || kg == 0 { return "BW" }
        let load = analyticsWeight(kg, unit: unit)
        return onBodyweight ? "BW + \(load)" : load
    }
    static func analyticsChange(_ state: AnalyticsEngine.Comparison, unit: String, spoken: Bool = false) -> String {
        switch state {
        case let .up(weight, reps):
            let value = weight > 0 ? analyticsWeight(weight, unit: unit, delta: true) : "\(reps.formatted()) \(reps == 1 ? "rep" : "reps")"
            return spoken ? "Up \(value)" : "+\(value)"
        case .same: return "Same"
        case .mixed: return "Mixed"
        case .belowBest: return "Below best"
        case .new, .notRecent: return spoken ? "No comparison yet" : "—"
        }
    }
    static func analyticsDate(_ date: Date, now: Date, calendar: Calendar = .current) -> String {
        if calendar.component(.year, from: date) == calendar.component(.year, from: now) {
            return date.formatted(.dateTime.month(.abbreviated).day())
        }
        return date.formatted(.dateTime.month(.abbreviated).day().year())
    }
    static func analyticsComparison(_ state: AnalyticsEngine.Comparison, unit: String) -> String {
        switch state {
        case .new: return "No previous comparison"
        case .notRecent: return "No sets in the last 4 weeks"
        default: return analyticsChange(state, unit: unit)
        }
    }
    /// Chart values are already converted into the selected display unit by the engine.
    static func analyticsChartValue(_ value: Double, metric: AnalyticsEngine.Metric, unit: String, locale: Locale = .current, spoken: Bool = false) -> String {
        let number = value.formatted(.number.locale(locale).grouping(.automatic).precision(.fractionLength(0...(metric == .reps ? 0 : unit == "lb" ? 1 : 2))))
        switch metric {
        case .reps: return "\(number) \(value == 1 ? "rep" : "reps")"
        case .weight:
            let spokenUnit = unit == "lb" ? (value == 1 ? "pound" : "pounds") : (value == 1 ? "kilogram" : "kilograms")
            return "\(number) \(spoken ? spokenUnit : unit)"
        case .volume:
            return "\(number) \(spoken ? (unit == "lb" ? "pound repetitions" : "kilogram repetitions") : "\(unit)·reps")"
        }
    }
    static func analyticsSummary(_ value: AnalyticsEngine.Summary, now: Date) -> String {
        if value.status == .baseline { return "First session \(analyticsDate(value.firstDay, now: now))." }
        if value.status == .fewer && value.sessions == 0 { return "Last session \(analyticsDate(value.lastDay, now: now))." }
        let sessions = value.planned > 0
            ? "\(value.sessions.formatted()) of \(value.planned.formatted()) sessions done."
            : "\(value.sessions.formatted()) \(value.sessions == 1 ? "session" : "sessions") done."
        return value.comparable < 2 ? sessions : "\(value.up.formatted()) of \(value.comparable.formatted()) lifts up. \(sessions)"
    }
    static func analyticsSpokenSet(_ value: AnalyticsEngine.Performance, bodyweight: Bool, unit: String) -> String {
        let load = bodyweight || value.weight == 0 ? "Bodyweight" : analyticsWeight(value.weight, unit: unit).replacingOccurrences(of: " kg", with: " kilograms").replacingOccurrences(of: " lb", with: " pounds")
        return "\(load) times \(value.reps.formatted())"
    }
    static func analyticsSpokenTarget(_ value: AnalyticsEngine.Target, unit: String) -> String {
        analyticsTarget(value, unit: unit).replacingOccurrences(of: "BW", with: "Bodyweight").replacingOccurrences(of: " kg", with: " kilograms").replacingOccurrences(of: " lb", with: " pounds").replacingOccurrences(of: " × ", with: " times ")
    }

}
