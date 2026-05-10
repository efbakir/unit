//
//  MarketingSeed.swift
//  Unit
//
//  Debug-only utility that wipes existing sessions and fabricates ~5 weeks of
//  believable history for App Store / marketing screenshots. Program-agnostic:
//  works with whatever active split + templates the user already has.
//

import Foundation
import SwiftData
import OSLog

@MainActor
enum MarketingSeed {

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.unitlift.app",
        category: "MarketingSeed"
    )

    struct Outcome {
        let didSeed: Bool
        let sessionsInserted: Int
        let entriesInserted: Int
        let message: String
    }

    /// Wipes WorkoutSession + SetEntry, then seeds ~5 weeks of realistic
    /// history against the user's *current* active split. Idempotent.
    @discardableResult
    static func populateMonthOfHistory(in modelContext: ModelContext) -> Outcome {
        wipeSessions(in: modelContext)

        let allSplits = (try? modelContext.fetch(FetchDescriptor<Split>())) ?? []
        guard let split = ActiveSplitStore.resolve(from: allSplits) else {
            logger.error("No active split. Finish onboarding first.")
            return Outcome(didSeed: false, sessionsInserted: 0, entriesInserted: 0,
                           message: "No active program. Finish onboarding first.")
        }

        let allTemplates = (try? modelContext.fetch(FetchDescriptor<DayTemplate>())) ?? []
        let allExercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let exercisesByID = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })

        let templates: [DayTemplate] = split.orderedTemplateIds
            .compactMap { id in allTemplates.first(where: { $0.id == id }) }

        guard !templates.isEmpty else {
            logger.error("Active split has no templates. id=\(split.id, privacy: .public)")
            return Outcome(didSeed: false, sessionsInserted: 0, entriesInserted: 0,
                           message: "Active program has no routines. Add at least one routine first.")
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = .current

        let today = calendar.startOfDay(for: Date())
        guard let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) else {
            return Outcome(didSeed: false, sessionsInserted: 0, entriesInserted: 0,
                           message: "Date math failed.")
        }

        // Assign each template a target weekday. Honor scheduledWeekday when
        // set; otherwise cycle through Mon/Tue/Thu/Fri/Sat by template index.
        let fallbackWeekdays: [Int] = [2, 3, 5, 6, 7]
        let assignments: [(template: DayTemplate, weekday: Int)] = templates.enumerated().map { idx, template in
            let weekday = template.scheduledWeekday > 0
                ? template.scheduledWeekday
                : fallbackWeekdays[idx % fallbackWeekdays.count]
            return (template, weekday)
        }

        let weeksBack = 4
        var sessionsInserted = 0
        var entriesInserted = 0
        var lastPerformedByTemplate: [UUID: Date] = [:]

        for weekOffset in (0...weeksBack).reversed() {
            guard let weekStart = calendar.date(
                byAdding: .day,
                value: -7 * weekOffset,
                to: currentWeekStart
            ) else { continue }

            for (idx, assignment) in assignments.enumerated() {
                let weekdayOffset = (assignment.weekday - calendar.firstWeekday + 7) % 7
                guard let scheduledDate = calendar.date(
                    byAdding: .day,
                    value: weekdayOffset,
                    to: weekStart
                ) else { continue }

                if scheduledDate >= today { continue }

                let signal = sessionOutcome(weekOffset: weekOffset, templateIndex: idx)
                if signal == .missed { continue }

                // Always insert as completed. ContentView treats any
                // isCompleted=false session as an in-progress workout and
                // hides the tab bar — fatal for screenshots. Variety on the
                // calendar comes from the .missed branch above (no insert →
                // hollow ring) and from the trimmed-exercise variant below.
                let session = WorkoutSession(
                    date: scheduledDate.addingHours(workoutHourOfDay(for: scheduledDate)),
                    templateId: assignment.template.id,
                    isCompleted: true
                )
                modelContext.insert(session)
                sessionsInserted += 1

                let exerciseIDs = assignment.template.orderedExerciseIds
                let trimToCount: Int = signal == .trimmed
                    ? max(3, exerciseIDs.count / 2)
                    : exerciseIDs.count

                for exerciseID in exerciseIDs.prefix(trimToCount) {
                    guard let exercise = exercisesByID[exerciseID] else { continue }
                    let target = inferTarget(for: exercise)
                    let weight = progressedWeight(
                        base: target.weightKg,
                        weekOffset: weekOffset,
                        isBodyweight: exercise.isBodyweight
                    )

                    for setIdx in 0..<target.sets {
                        let entry = SetEntry(
                            sessionId: session.id,
                            exerciseId: exerciseID,
                            weight: weight,
                            reps: target.reps,
                            rpe: 0,
                            rir: -1,
                            isWarmup: false,
                            isCompleted: true,
                            setIndex: setIdx,
                            note: ""
                        )
                        entry.session = session
                        modelContext.insert(entry)
                        entriesInserted += 1
                    }
                }

                if let prior = lastPerformedByTemplate[assignment.template.id] {
                    if scheduledDate > prior { lastPerformedByTemplate[assignment.template.id] = scheduledDate }
                } else {
                    lastPerformedByTemplate[assignment.template.id] = scheduledDate
                }
            }
        }

        for template in templates {
            template.lastPerformedDate = lastPerformedByTemplate[template.id]
        }

        do {
            try modelContext.save()
        } catch {
            logger.error("Save failed: \(String(describing: error), privacy: .public)")
            return Outcome(didSeed: false, sessionsInserted: 0, entriesInserted: 0,
                           message: "SwiftData save failed: \(error.localizedDescription)")
        }

        logger.notice("Seeded \(sessionsInserted) sessions, \(entriesInserted) set entries across \(templates.count) templates.")
        return Outcome(
            didSeed: sessionsInserted > 0,
            sessionsInserted: sessionsInserted,
            entriesInserted: entriesInserted,
            message: "Seeded \(sessionsInserted) sessions and \(entriesInserted) sets across \(templates.count) routines."
        )
    }

    // MARK: - Wipe

    private static func wipeSessions(in modelContext: ModelContext) {
        let sessions = (try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []
        for session in sessions { modelContext.delete(session) }
        let orphanedEntries = (try? modelContext.fetch(FetchDescriptor<SetEntry>())) ?? []
        for entry in orphanedEntries { modelContext.delete(entry) }
        try? modelContext.save()
    }

    // MARK: - Outcome dial

    private enum SessionSignal { case completed, trimmed, missed }

    /// Mostly completed; missed days (no session inserted → hollow rings on
    /// the calendar) and trimmed days (shorter workouts — still completed,
    /// just half the exercises) sprinkled across the 5 weeks so the calendar
    /// reads like a real lifter, not a metronome. Keyed off
    /// (weekOffset, templateIndex) so the result is independent of how the
    /// user's program is scheduled.
    private static func sessionOutcome(weekOffset: Int, templateIndex: Int) -> SessionSignal {
        switch (weekOffset, templateIndex) {
        // Oldest week — first session is short (ramp-up), Friday missed.
        case (4, 0): return .trimmed
        case (4, 3): return .missed
        // Mid-program slump.
        case (3, 1): return .trimmed
        case (3, 2): return .missed
        // Travel week — missed Monday + Saturday.
        case (2, 0): return .missed
        case (2, 4): return .missed
        case (2, 2): return .trimmed
        // Last week was hectic — missed two routines.
        case (1, 1): return .missed
        case (1, 3): return .missed
        // Current week looks clean.
        default:     return .completed
        }
    }

    // MARK: - Target inference

    private struct TargetGuess {
        let weightKg: Double
        let reps: Int
        let sets: Int
    }

    /// Derive a believable working-set target from equipment + name without
    /// requiring an exact match against a hard-coded catalog. Intentionally
    /// coarse — looks like a typical lifter, not a programmed athlete.
    private static func inferTarget(for exercise: Exercise) -> TargetGuess {
        if exercise.isBodyweight {
            return TargetGuess(weightKg: 0, reps: 12, sets: 3)
        }

        let name = exercise.displayName.lowercased()
        let isHeavyCompound = ["squat", "deadlift", "rdl", "back squat"].contains { name.contains($0) }
        let isPress = ["bench", "ohp", "overhead", "press"].contains { name.contains($0) }
        let isRow = ["row", "pull"].contains { name.contains($0) }
        let isIso = ["curl", "lateral", "raise", "fly", "extension", "shrug", "kickback", "rear delt"].contains { name.contains($0) }

        switch exercise.equipment {
        case .barbell:
            if isHeavyCompound { return TargetGuess(weightKg: 100, reps: 5, sets: 4) }
            if isPress         { return TargetGuess(weightKg: 70,  reps: 6, sets: 4) }
            if isRow           { return TargetGuess(weightKg: 60,  reps: 8, sets: 3) }
            return TargetGuess(weightKg: 60, reps: 8, sets: 3)
        case .dumbbell:
            if isIso           { return TargetGuess(weightKg: 12,  reps: 12, sets: 3) }
            if isPress         { return TargetGuess(weightKg: 24,  reps: 8,  sets: 3) }
            return TargetGuess(weightKg: 22, reps: 10, sets: 3)
        case .cable:
            if isIso           { return TargetGuess(weightKg: 18,  reps: 12, sets: 3) }
            return TargetGuess(weightKg: 35, reps: 12, sets: 3)
        case .machine:
            if isIso           { return TargetGuess(weightKg: 30,  reps: 12, sets: 3) }
            return TargetGuess(weightKg: 50, reps: 10, sets: 3)
        case .kettlebell:
            return TargetGuess(weightKg: 24, reps: 10, sets: 3)
        case .band, .other, .bodyweight:
            return TargetGuess(weightKg: 0, reps: 12, sets: 3)
        }
    }

    // MARK: - Progression

    private static func progressedWeight(base: Double, weekOffset: Int, isBodyweight: Bool) -> Double {
        guard !isBodyweight, base > 0 else { return 0 }

        let weeklyDelta: Double
        switch base {
        case 80...:    weeklyDelta = 2.5
        case 30..<80:  weeklyDelta = 1.25
        default:       weeklyDelta = 1.0
        }

        let weight = base - Double(weekOffset) * weeklyDelta
        let rounded = (weight / 0.5).rounded() * 0.5
        return max(rounded, 0)
    }

    private static func workoutHourOfDay(for date: Date) -> Int {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2, 5: return 18  // Mon, Thu evenings
        case 3, 6: return 7   // Tue, Fri mornings
        case 4:    return 19  // Wed evenings
        case 7:    return 10  // Sat mornings
        default:   return 18
        }
    }
}

private extension Date {
    func addingHours(_ hours: Int) -> Date {
        Calendar.current.date(byAdding: .hour, value: hours, to: self) ?? self
    }
}
