import Foundation

/// Read-only analytics over value snapshots. Stored load is always canonical kg.
/// No clocks, model contexts, preferences, formatting, or schema writes live here.
nonisolated enum AnalyticsEngine {
    static let weightEpsilon = 0.01

    struct ExerciseInput: Sendable, Hashable {
        let id: UUID
        let name: String
        let isBodyweight: Bool
        let equipment: String?
        let muscleGroup: String
    }
    struct SetInput: Sendable, Hashable {
        let exerciseID: UUID
        let weight: Double
        let reps: Int
        var isCompleted = true
        var isWarmup = false
        var index = 0
        var isValid: Bool { isCompleted && !isWarmup && weight.isFinite && weight >= 0 && reps > 0 }
    }
    struct SessionInput: Sendable, Hashable {
        let id: UUID
        let date: Date
        let templateID: UUID
        var isCompleted = true
        let sets: [SetInput]
    }
    struct Target: Sendable, Hashable {
        let weight: Double
        let reps: Int
        let templateName: String
    }
    struct TemplateInput: Sendable, Hashable {
        let id: UUID
        let name: String
        let exerciseIDs: [UUID]
        let targets: [UUID: Target]
    }
    struct Input: Sendable, Hashable {
        let exercises: [ExerciseInput]
        let sessions: [SessionInput]
        let templates: [TemplateInput]
        /// Schedules have no historical versions. Use current routine count × 4.
        let plannedDaysPerWeek: Int
    }
    struct Performance: Sendable, Hashable {
        let weight: Double
        let reps: Int
        let date: Date
        let sessionID: UUID
        let templateID: UUID
        let setIndex: Int
    }
    enum Comparison: Sendable, Hashable {
        case up(weight: Double, reps: Int), same, belowBest, mixed, new, notRecent
        var isComparable: Bool {
            switch self { case .up, .same, .belowBest, .mixed: true; default: false }
        }
        var isUp: Bool { if case .up = self { true } else { false } }
    }
    enum Status: String, Sendable {
        case stronger = "Getting stronger", steady = "Holding steady"
        case fewer = "Fewer sessions lately", baseline = "Building a baseline"
    }
    enum Slot: String, CaseIterable, Sendable {
        case squat = "Squat", bench = "Bench Press", deadlift = "Deadlift"
        var aliases: Set<String> {
            switch self {
            case .squat: ["squat", "back squat", "barbell squat", "barbell back squat", "bb squat", "high bar squat", "low bar squat", "high bar back squat", "low bar back squat"]
            case .bench: ["bench press", "bench", "barbell bench press", "flat bench press", "flat bench", "flat barbell bench press", "bb bench press"]
            case .deadlift: ["deadlift", "conventional deadlift", "sumo deadlift", "barbell deadlift", "bb deadlift"]
            }
        }
    }
    struct WeeklyPoint: Identifiable, Sendable, Hashable {
        var id: Date { week }
        let week: Date
        let best: Performance
        let maxReps: Int
        /// Volume of the session containing this week's best set, not a weekly total.
        let volumeKg: Double
    }
    struct SessionResult: Identifiable, Sendable, Hashable {
        var id: UUID { best.sessionID }
        let best: Performance
        let sets: [Performance]
        let maxReps: Int
        let volumeKg: Double
        let estimatedOneRM: Double?
    }
    struct Lift: Identifiable, Sendable, Hashable {
        var id: UUID { exercise.id }
        let exercise: ExerciseInput
        let bodyweight: Bool
        let sessions: [SessionResult]
        let best: Performance?
        let comparison: Comparison
        let weeks: [WeeklyPoint]
        let target: Target?
        var latest: Performance? { sessions.last?.best }
    }
    struct Summary: Sendable {
        let status: Status
        let up: Int
        let comparable: Int
        let sessions: Int
        let planned: Int
        let firstDay: Date
        let lastDay: Date
    }
    struct Output: Sendable {
        let summary: Summary?
        let lifts: [UUID: Lift]
        let main: [Slot: UUID]
        let other: [UUID]
        let weekStarts: [Date]
        let today: Date
    }
    private struct DayBucket {
        // Retain the near-maximum frontier: epsilon equality is not transitive.
        // Keeping only one daily winner could lose a set needed by a wider window.
        var weightedCandidates: [Performance] = []
        var bodyweight: Performance?
    }
    private struct Accumulator {
        var days: [Date: DayBucket] = [:]
        var weighted = false
        var sessions: [SessionResult] = []
    }

    static func normalizedName(_ value: String) -> String {
        value.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .lowercased().replacingOccurrences(of: "[-_/]", with: " ", options: .regularExpression)
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
    static func slot(for exercise: ExerciseInput) -> Slot? {
        // Empty/unknown metadata is accepted. Explicit non-barbell equipment is not.
        guard exercise.equipment == nil || exercise.equipment == "" || exercise.equipment == "barbell" else { return nil }
        let name = normalizedName(exercise.name)
        return Slot.allCases.first { $0.aliases.contains(name) }
    }
    static func better(_ lhs: Performance, than rhs: Performance?, bodyweight: Bool) -> Bool {
        guard let rhs else { return true }
        if !bodyweight, abs(lhs.weight - rhs.weight) >= weightEpsilon { return lhs.weight > rhs.weight }
        if lhs.reps != rhs.reps { return lhs.reps > rhs.reps }
        if lhs.date != rhs.date { return lhs.date < rhs.date }
        return lhs.setIndex < rhs.setIndex
    }
    static func compare(_ a: Performance?, _ b: Performance?, bodyweight: Bool) -> Comparison {
        guard let a else { return .notRecent }
        guard let b else { return .new }
        let dw = bodyweight || abs(a.weight - b.weight) < weightEpsilon ? 0 : a.weight - b.weight
        let dr = a.reps - b.reps
        if dw == 0 && dr == 0 { return .same }
        if dw >= 0 && dr >= 0 { return .up(weight: dw, reps: dr) }
        if (dw < 0 && dr == 0) || (dw == 0 && dr < 0) { return .belowBest }
        // Deliberate policy switch: both lower remains Mixed, never a down claim.
        return .mixed
    }
    private static func best(_ values: some Sequence<Performance>, bodyweight: Bool) -> Performance? {
        let values = Array(values)
        let maximum = bodyweight ? 0 : (values.map(\.weight).max() ?? 0)
        return values.reduce(nil) { current, value in
            guard bodyweight || abs(value.weight - maximum) < weightEpsilon else { return current }
            guard let current else { return value }
            if value.reps != current.reps { return value.reps > current.reps ? value : current }
            if value.date != current.date { return value.date < current.date ? value : current }
            if value.sessionID != current.sessionID { return value.sessionID.uuidString < current.sessionID.uuidString ? value : current }
            return value.setIndex < current.setIndex ? value : current
        }
    }

    static func compute(_ input: Input, now: Date, calendar: Calendar) -> Output {
        let today = calendar.startOfDay(for: now)
        func day(_ offset: Int, from date: Date) -> Date { calendar.date(byAdding: .day, value: offset, to: date)! }
        let currentWeek = calendar.dateInterval(of: .weekOfYear, for: today)!.start
        let weekStarts = (-11...0).map { calendar.date(byAdding: .weekOfYear, value: $0, to: currentWeek)! }
        var accumulators: [UUID: Accumulator] = [:]
        var sessionDays: [Date] = []
        var lastTemplateDates: [UUID: Date] = [:]
        // Exactly one traversal of source sets; all windows derive from day buckets.
        for session in input.sessions where session.isCompleted {
            let date = calendar.startOfDay(for: session.date)
            guard date <= today else { continue }
            let groups = Dictionary(grouping: session.sets.filter(\.isValid), by: \.exerciseID)
            guard !groups.isEmpty else { continue }
            sessionDays.append(date)
            lastTemplateDates[session.templateID] = max(lastTemplateDates[session.templateID] ?? .distantPast, session.date)
            for (exerciseID, sets) in groups {
                let performances = sets.map { Performance(weight: $0.weight, reps: $0.reps, date: session.date, sessionID: session.id, templateID: session.templateID, setIndex: $0.index) }
                let loaded = performances.filter { $0.weight > 0 }
                let bodyweight = loaded.isEmpty
                guard let top = best(bodyweight ? performances : loaded, bodyweight: bodyweight) else { continue }
                let estimates = loaded.filter { (1...12).contains($0.reps) }.map { $0.reps == 1 ? $0.weight : $0.weight * (1 + Double($0.reps) / 30) }.filter(\.isFinite)
                let result = SessionResult(best: top, sets: performances.sorted { $0.setIndex < $1.setIndex }, maxReps: sets.map(\.reps).max() ?? 0, volumeKg: sets.reduce(0) { $0 + $1.weight * Double($1.reps) }, estimatedOneRM: estimates.max())
                if !bodyweight { accumulators[exerciseID, default: Accumulator()].weighted = true }
                accumulators[exerciseID, default: Accumulator()].sessions.append(result)
                var bucket = accumulators[exerciseID]?.days[date] ?? DayBucket()
                for value in loaded {
                    if let index = bucket.weightedCandidates.firstIndex(where: { $0.weight == value.weight }) {
                        if better(value, than: bucket.weightedCandidates[index], bodyweight: true) { bucket.weightedCandidates[index] = value }
                    } else { bucket.weightedCandidates.append(value) }
                }
                if let candidate = best(performances, bodyweight: true), better(candidate, than: bucket.bodyweight, bodyweight: true) { bucket.bodyweight = candidate }
                accumulators[exerciseID, default: Accumulator()].days[date] = bucket
            }
        }
        for id in Array(accumulators.keys) {
            for date in Array(accumulators[id]!.days.keys) {
                let values = accumulators[id]!.days[date]!.weightedCandidates
                let maximum = values.map(\.weight).max() ?? 0
                accumulators[id]!.days[date]!.weightedCandidates = values.filter { abs($0.weight - maximum) < weightEpsilon }
            }
        }
        sessionDays.sort()
        // Persistence can look back 14 days plus two stability days. Its oldest
        // comparison starts 55 days earlier; all older work is irrelevant here.
        let comparisonCutoff = day(-71, from: today)
        let comparisonDays = accumulators.mapValues { $0.days.filter { $0.key >= comparisonCutoff } }
        let firstWeightedDays = accumulators.mapValues { accumulator in
            accumulator.days.compactMap { $0.value.weightedCandidates.isEmpty ? nil : $0.key }.min()
        }
        func comparison(_ id: UUID, on date: Date) -> Comparison {
            let bodyweight = (firstWeightedDays[id] ?? nil).map { $0 > date } ?? true
            let aStart = day(-27, from: date), bStart = day(-55, from: date), bEnd = day(-28, from: date)
            var a: [Performance] = [], b: [Performance] = []
            for (dateKey, bucket) in comparisonDays[id] ?? [:] {
                let values = bodyweight ? bucket.bodyweight.map { [$0] } ?? [] : bucket.weightedCandidates
                if dateKey >= aStart && dateKey <= date { a.append(contentsOf: values) }
                if dateKey >= bStart && dateKey <= bEnd { b.append(contentsOf: values) }
            }
            return compare(best(a, bodyweight: bodyweight), best(b, bodyweight: bodyweight), bodyweight: bodyweight)
        }

        typealias Counts = (n: Int, u: Int, s: Int, p: Int, ratio: Double)
        var countCache: [Date: Counts] = [:]
        func counts(on date: Date) -> Counts {
            if let cached = countCache[date] { return cached }
            let states = accumulators.keys.map { comparison($0, on: date) }
            let n = states.filter(\.isComparable).count, u = states.filter(\.isUp).count
            let aStart = day(-27, from: date), bStart = day(-55, from: date), bEnd = day(-28, from: date)
            let s = sessionDays.filter { $0 >= aStart && $0 <= date }.count
            let p = max(0, input.plannedDaysPerWeek) * 4
            let previous = sessionDays.filter { $0 >= bStart && $0 <= bEnd }.count
            let result: Counts = (n, u, s, p, p > 0 ? Double(s) / Double(p) : min(1, Double(s) / Double(max(1, previous))))
            countCache[date] = result
            return result
        }
        func candidate(on date: Date) -> Status? {
            guard let first = sessionDays.first, first <= date else { return nil }
            let count = sessionDays.filter { $0 <= date }.count
            // §11 explicitly also keeps a single-session history in baseline.
            if calendar.dateComponents([.day], from: first, to: date).day! < 14 || count == 1 { return .baseline }
            let values = counts(on: date)
            if values.ratio < 0.5 { return .fewer }
            if values.n >= 2 && Double(values.u) / Double(values.n) >= 0.5 && values.ratio >= 0.75 { return .stronger }
            return .steady
        }
        let live = counts(on: today)
        let currentCandidate = candidate(on: today)
        var displayed = currentCandidate
        if currentCandidate != .baseline {
            for offset in 0...14 {
                let date = day(-offset, from: today)
                guard let current = candidate(on: date) else { break }
                let previous = candidate(on: day(-1, from: date))
                // Empty and baseline boundaries bypass persistence immediately.
                if current == .baseline || previous == nil || previous == .baseline {
                    displayed = current; break
                }
                if current == previous && current == candidate(on: day(-2, from: date)) {
                    displayed = current; break
                }
            }
        }
        let summary: Summary?
        if let displayed, let first = sessionDays.first, let last = sessionDays.last {
            summary = Summary(status: displayed, up: live.u, comparable: live.n, sessions: live.s, planned: live.p, firstDay: first, lastDay: last)
        } else { summary = nil }
        var lifts: [UUID: Lift] = [:]
        for exercise in input.exercises {
            guard let accumulator = accumulators[exercise.id] else { continue }
            let bodyweight = !accumulator.weighted
            // A positive added load makes even a BW-labelled movement weighted.
            let sessions = accumulator.sessions.sorted { $0.best.date == $1.best.date ? $0.id.uuidString < $1.id.uuidString : $0.best.date < $1.best.date }
            let daily = accumulator.days.values.flatMap { bodyweight ? $0.bodyweight.map { [$0] } ?? [] : $0.weightedCandidates }
            let grouped = Dictionary(grouping: daily.filter { $0.date >= weekStarts[0] }) { calendar.dateInterval(of: .weekOfYear, for: $0.date)!.start }
            let resultsByID = Dictionary(uniqueKeysWithValues: sessions.map { ($0.id, $0) })
            let weeks = weekStarts.compactMap { week -> WeeklyPoint? in
                guard let values = grouped[week], let top = best(values, bodyweight: bodyweight), let result = resultsByID[top.sessionID] else { return nil }
                return WeeklyPoint(week: week, best: top, maxReps: result.maxReps, volumeKg: result.volumeKg)
            }
            // Most recent containing routine, never a different routine's target.
            let lastTemplate = input.templates.filter { $0.exerciseIDs.contains(exercise.id) && lastTemplateDates[$0.id] != nil }.max {
                let a = lastTemplateDates[$0.id]!, b = lastTemplateDates[$1.id]!
                return a == b ? $0.id.uuidString > $1.id.uuidString : a < b
            }
            lifts[exercise.id] = Lift(exercise: exercise, bodyweight: bodyweight, sessions: sessions, best: best(daily, bodyweight: bodyweight), comparison: comparison(exercise.id, on: today), weeks: weeks, target: lastTemplate?.targets[exercise.id])
        }
        var main: [Slot: UUID] = [:]
        for slot in Slot.allCases {
            let candidates = input.exercises.filter { Self.slot(for: $0) == slot }.sorted { a, b in
                let aSessions = lifts[a.id]?.sessions ?? [], bSessions = lifts[b.id]?.sessions ?? []
                let aCount = aSessions.filter { $0.best.date >= weekStarts[0] }.count, bCount = bSessions.filter { $0.best.date >= weekStarts[0] }.count
                if aCount != bCount { return aCount > bCount }
                let aDate = aSessions.last?.best.date ?? .distantPast, bDate = bSessions.last?.best.date ?? .distantPast
                if aDate != bDate { return aDate > bDate }
                if a.name != b.name { return a.name.localizedStandardCompare(b.name) == .orderedAscending }
                return a.id.uuidString < b.id.uuidString
            }
            main[slot] = candidates.first?.id
        }
        let selected = Set(main.values)
        let other = lifts.values.filter { !selected.contains($0.id) }.sorted { a, b in
            if a.latest?.date != b.latest?.date { return (a.latest?.date ?? .distantPast) > (b.latest?.date ?? .distantPast) }
            return a.exercise.name.localizedStandardCompare(b.exercise.name) == .orderedAscending
        }.map(\.id)
        return Output(summary: summary, lifts: lifts, main: main, other: other, weekStarts: weekStarts, today: today)
    }
}

extension AnalyticsEngine {
    enum Metric: String, CaseIterable, Identifiable, Sendable {
        case weight = "Weight", reps = "Reps", volume = "Volume"
        var id: String { rawValue }
    }
    struct ChartPoint: Identifiable, Sendable {
        var id: Date { week }
        let week: Date
        let value: Double
        let best: Performance
    }
    struct ChartData: Sendable {
        let points: [ChartPoint]
        let xDomain: ClosedRange<Date>
        let xLabels: [Date]
        let yDomain: ClosedRange<Double>
        let yTicks: [Double]
    }
    static func chart(lift: Lift?, weekStarts: [Date], metric: Metric, unit: String) -> ChartData {
        let points = (lift?.weeks ?? []).map { week in
            let value: Double
            switch metric {
            case .weight: value = week.best.weight * (unit == "lb" ? 2.20462 : 1)
            case .reps: value = Double(week.best.reps)
            case .volume: value = lift?.bodyweight == true ? Double(week.best.reps) : week.volumeKg * (unit == "lb" ? 2.20462 : 1)
            }
            return ChartPoint(week: week.week, value: value, best: week.best)
        }
        let lo = points.map(\.value).min() ?? 0, hi = points.map(\.value).max() ?? 1
        let step: Double = metric == .reps ? 1 : unit == "lb" ? 0.5 : 0.25
        let pad = hi > lo ? max((hi - lo) * 0.1, step) : max(abs(hi) * 0.1, step)
        let lower = max(0, ((lo - pad) / step).rounded(.down) * step)
        let upper = max(lower + step, ((hi + pad) / step).rounded(.up) * step)
        let ticks = lo == hi ? [lower, upper] : [(lo / step).rounded(.down) * step, (hi / step).rounded(.up) * step]
        let start = weekStarts.first ?? .distantPast, end = weekStarts.last ?? .distantFuture
        // Keep the final label four weeks from its neighbour: its trailing
        // anchor needs more room than an interior, centred date label.
        let indices = [0, 4, 7, 11].filter { weekStarts.indices.contains($0) }
        return ChartData(points: points, xDomain: start...end, xLabels: indices.map { weekStarts[$0] }, yDomain: lower...upper, yTicks: Array(Set(ticks)).sorted())
    }
    static func estimatedOneRM(for lift: Lift, unit: String) -> Double? {
        guard !lift.bodyweight, let kg = lift.sessions.compactMap(\.estimatedOneRM).max(), kg >= (lift.best?.weight ?? 0) else { return nil }
        let increment = unit == "lb" ? 0.5 : 0.25
        let display = kg * (unit == "lb" ? 2.20462 : 1)
        return (display / increment).rounded() * increment / (unit == "lb" ? 2.20462 : 1)
    }
}
