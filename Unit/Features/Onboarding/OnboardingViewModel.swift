//
//  OnboardingViewModel.swift
//  Unit
//
//  Transient onboarding state. No SwiftData @Model — all writes happen
//  atomically in commit() when the user taps "Create My Program".
//

import Foundation
import Observation
import SwiftData

// MARK: - Supporting Types

struct OnboardingExercise: Identifiable, Equatable, Hashable, Codable {
    static let defaultPlannedSets: Int = 3
    static let defaultPlannedReps: Int = 8
    static let plannedSetsRange: ClosedRange<Int> = 1...10
    static let plannedRepsRange: ClosedRange<Int> = 1...30

    var id = UUID()
    var name: String
    var plannedSets: Int = OnboardingExercise.defaultPlannedSets
    var plannedReps: Int = OnboardingExercise.defaultPlannedReps
}

struct ImportedProgramExercise: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    var weightKg: Double?
}

struct ImportedProgramDay: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var exercises: [ImportedProgramExercise]
}

// MARK: - ViewModel

@Observable
final class OnboardingViewModel {

    // MARK: Path

    enum SetupPath { case build }
    var setupPath: SetupPath = .build

    enum ImportMethod {
        case paste
        case history
        case manual
    }
    var importMethod: ImportMethod = .manual

    // MARK: Units

    /// "kg" or "lb". Written to AppStorage("unitSystem") after commit.
    var unitSystem: String = "kg"

    // MARK: Split

    var dayCount: Int = 3
    /// Default day labels are pre-filled (`"Day 1"`, `"Day 2"`, …) so the
    /// Split Builder advances without forcing the user to think up names
    /// before they have exercise context. Renaming happens in-place from
    /// the day editor on the Exercises step, where each day's contents
    /// inform the natural label (e.g. "Push" / "Pull" / "Legs").
    var dayNames: [String] = OnboardingViewModel.defaultDayNames(count: 3)
    var dayExercises: [[OnboardingExercise]] = [[], [], []]
    /// Weekday assignment per day-template. 1=Sun, 2=Mon … 7=Sat. 0 = unset.
    /// Stays 0 across all entries when `useFlexibleSchedule == true` —
    /// rotation mode is the explicit opt-out from a fixed weekly schedule.
    var dayWeekdays: [Int] = [0, 0, 0]
    /// When true, commit() writes every template with `scheduledWeekday = 0`
    /// (rotation). Set by the schedule step's "I lift on a flexible schedule"
    /// toggle so users who don't anchor to weekdays still complete onboarding.
    var useFlexibleSchedule: Bool = false

    // MARK: Start Date

    enum StartOption { case today, nextMonday, custom }
    var startOption: StartOption = .today
    var customDate: Date = Date()

    // MARK: - Computed Helpers

    var startDate: Date {
        let cal = Calendar.current
        switch startOption {
        case .today:
            return cal.startOfDay(for: Date())
        case .nextMonday:
            let weekday = cal.component(.weekday, from: Date())
            let days = weekday == 2 ? 7 : (9 - weekday) % 7
            return cal.date(byAdding: .day, value: days, to: cal.startOfDay(for: Date())) ?? Date()
        case .custom:
            return cal.startOfDay(for: customDate)
        }
    }

    var weightUnitLabel: String { unitSystem }

    /// Display a kg value in the user's chosen unit.
    func displayWeight(_ kg: Double) -> Double {
        unitSystem == "lb" ? kg * 2.20462 : kg
    }

    /// Convert a user-entered display value back to kg for storage.
    func storeWeightKg(_ displayValue: Double) -> Double {
        unitSystem == "lb" ? displayValue / 2.20462 : displayValue
    }

    // MARK: - Day Management

    func clampPlannedSets(_ value: Int) -> Int {
        min(OnboardingExercise.plannedSetsRange.upperBound,
            max(OnboardingExercise.plannedSetsRange.lowerBound, value))
    }

    func clampPlannedReps(_ value: Int) -> Int {
        min(OnboardingExercise.plannedRepsRange.upperBound,
            max(OnboardingExercise.plannedRepsRange.lowerBound, value))
    }

    func adjustPlannedSets(dayIndex: Int, exerciseId: UUID, delta: Int) {
        guard dayExercises.indices.contains(dayIndex),
              let i = dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseId }) else { return }
        dayExercises[dayIndex][i].plannedSets = clampPlannedSets(dayExercises[dayIndex][i].plannedSets + delta)
    }

    func adjustPlannedReps(dayIndex: Int, exerciseId: UUID, delta: Int) {
        guard dayExercises.indices.contains(dayIndex),
              let i = dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseId }) else { return }
        dayExercises[dayIndex][i].plannedReps = clampPlannedReps(dayExercises[dayIndex][i].plannedReps + delta)
    }

    static func defaultDayNames(count: Int) -> [String] {
        (1...max(1, count)).map { "Day \($0)" }
    }

    func updateDayCount(_ newCount: Int) {
        let count = max(2, min(6, newCount))
        dayCount = count
        // New slots get a `"Day N"` placeholder so `splitIsValid` stays
        // true by default — see `dayNames` declaration. User-edited names
        // are preserved; only freshly-appended slots receive the default.
        while dayNames.count < count { dayNames.append("Day \(dayNames.count + 1)") }
        if dayNames.count > count { dayNames = Array(dayNames.prefix(count)) }
        while dayExercises.count < count { dayExercises.append([]) }
        if dayExercises.count > count { dayExercises = Array(dayExercises.prefix(count)) }
        while dayWeekdays.count < count { dayWeekdays.append(0) }
        if dayWeekdays.count > count { dayWeekdays = Array(dayWeekdays.prefix(count)) }
    }

    // MARK: - Sample Seeding

    func seedSampleData() {
        dayCount = 3
        dayNames = ["Push", "Pull", "Legs"]
        dayWeekdays = [2, 4, 6] // Mon / Wed / Fri

        let pushExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Bench Press", plannedSets: 3, plannedReps: 8),
            OnboardingExercise(name: "Overhead Press", plannedSets: 3, plannedReps: 8),
            OnboardingExercise(name: "Tricep Pushdown", plannedSets: 3, plannedReps: 12)
        ]
        let pullExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Barbell Row", plannedSets: 3, plannedReps: 8),
            OnboardingExercise(name: "Lat Pulldown", plannedSets: 3, plannedReps: 10),
            OnboardingExercise(name: "Pull-up", plannedSets: 3, plannedReps: 8)
        ]
        let legsExs: [OnboardingExercise] = [
            OnboardingExercise(name: "Back Squat", plannedSets: 3, plannedReps: 5),
            OnboardingExercise(name: "Romanian Deadlift", plannedSets: 3, plannedReps: 8),
            OnboardingExercise(name: "Leg Press", plannedSets: 3, plannedReps: 10)
        ]
        dayExercises = [pushExs, pullExs, legsExs]
    }

    // MARK: - Validation

    var splitIsValid: Bool {
        dayNames.allSatisfy { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    /// True when the schedule step's CTA can advance: either the user opted
    /// into flexible (rotation) mode, or every day-template has a weekday in
    /// 1...7 picked. Same weekday across multiple rows is allowed — the
    /// downstream calendar/today logic resolves duplicates by orderedTemplate
    /// position, so PPL users can hit Push twice a week.
    var scheduleIsValid: Bool {
        if useFlexibleSchedule { return true }
        guard dayWeekdays.count >= dayCount else { return false }
        return dayWeekdays.prefix(dayCount).allSatisfy { (1...7).contains($0) }
    }

    var exercisesAreValid: Bool {
        dayExercises.allSatisfy { day in
            !day.isEmpty &&
            day.allSatisfy { !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        }
    }

    // MARK: - Commit

    func commit(modelContext: ModelContext) throws {
        // 1. Resolve exercises (name lookup or create)
        var nameToExercise: [String: Exercise] = [:]
        let existing = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        for ex in existing { nameToExercise[ex.displayName.lowercased()] = ex }

        var exerciseMap: [UUID: Exercise] = [:]
        for day in dayExercises {
            for onbEx in day {
                let displayName = onbEx.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !displayName.isEmpty else { continue }
                let key = displayName.lowercased()
                let isBodyweight = isBodyweightExercise(named: displayName)
                if let match = nameToExercise[key] {
                    if isBodyweight && !match.isBodyweight {
                        match.isBodyweight = true
                    }
                    exerciseMap[onbEx.id] = match
                } else {
                    let ex = Exercise(
                        displayName: displayName,
                        isBodyweight: isBodyweight
                    )
                    modelContext.insert(ex)
                    exerciseMap[onbEx.id] = ex
                    nameToExercise[key] = ex
                }
            }
        }

        // 2. Create Split
        let splitName = dayNames.joined(separator: " / ")
        let split = Split(name: splitName)
        modelContext.insert(split)

        // 3. Create DayTemplates
        var templateIds: [UUID] = []
        for (i, name) in dayNames.enumerated() {
            let dayOnbExs = dayExercises[i].filter {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            let exerciseIds = dayOnbExs.compactMap { exerciseMap[$0.id]?.id }
            var setsPlan: [UUID: Int] = [:]
            var repsPlan: [UUID: Int] = [:]
            for onbEx in dayOnbExs {
                guard let resolvedId = exerciseMap[onbEx.id]?.id else { continue }
                setsPlan[resolvedId] = onbEx.plannedSets
                repsPlan[resolvedId] = onbEx.plannedReps
            }
            let resolvedWeekday: Int = {
                guard !useFlexibleSchedule,
                      dayWeekdays.indices.contains(i),
                      (1...7).contains(dayWeekdays[i]) else { return 0 }
                return dayWeekdays[i]
            }()
            let tmpl = DayTemplate(
                name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                splitId: split.id,
                orderedExerciseIds: exerciseIds,
                scheduledWeekday: resolvedWeekday,
                plannedSetsByExerciseId: setsPlan,
                plannedRepsByExerciseId: repsPlan
            )
            modelContext.insert(tmpl)
            templateIds.append(tmpl.id)
        }
        split.orderedTemplateIds = templateIds

        try modelContext.save()

        ActiveSplitStore.setCurrent(split.id)
    }
}

extension OnboardingViewModel {
    func isBodyweightExercise(named exerciseName: String) -> Bool {
        let name = normalizedExerciseName(exerciseName)
        let bodyweightKeywords = [
            "pull up", "chin up", "push up", "dip", "plank", "hanging leg raise",
            "ab wheel rollout", "sit up", "crunch", "mountain climber", "burpee",
            "bodyweight squat"
        ]
        return bodyweightKeywords.contains { name.contains($0) }
    }

    func applyImportedProgram(_ days: [ImportedProgramDay]) {
        let sanitizedDays = days.compactMap { day -> ImportedProgramDay? in
            let exercises = day.exercises.filter {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            guard !exercises.isEmpty else { return nil }
            return ImportedProgramDay(name: day.name, exercises: exercises)
        }
        guard !sanitizedDays.isEmpty else { return }

        dayCount = min(6, max(1, sanitizedDays.count))
        dayNames = Array(sanitizedDays.prefix(dayCount).enumerated().map { index, day in
            let trimmed = day.name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Workout \(index + 1)" : trimmed
        })
        // Paste parser doesn't carry weekday metadata yet — user picks in the
        // schedule step. Reset to unset so stale values from a prior path
        // don't survive a re-import.
        dayWeekdays = Array(repeating: 0, count: dayCount)
        useFlexibleSchedule = false

        dayExercises = Array(sanitizedDays.prefix(dayCount).map { day in
            day.exercises.map { exercise in
                OnboardingExercise(
                    name: exercise.name,
                    plannedSets: clampPlannedSets(exercise.sets ?? OnboardingExercise.defaultPlannedSets),
                    plannedReps: clampPlannedReps(exercise.reps ?? OnboardingExercise.defaultPlannedReps)
                )
            }
        })
    }

    private func normalizedExerciseName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }
}

// MARK: - Common Exercise Library (suggestions)

enum ExerciseLibrary {
    static let suggestions: [String] = [
        // Chest
        "Bench Press", "Incline Bench Press", "Decline Bench Press",
        "Close-Grip Bench Press", "Pin Press", "Floor Press",
        "Dumbbell Bench Press", "Incline Dumbbell Press", "Decline Dumbbell Press",
        "Dumbbell Floor Press", "Dumbbell Flye", "Incline Dumbbell Flye",
        "Cable Fly", "Cable Crossover", "Machine Chest Press", "Pec Deck",
        "Push-up", "Incline Push-up", "Decline Push-up", "Diamond Push-up",
        "Dip", "Bench Dip", "Dumbbell Pullover",
        // Shoulders
        "Overhead Press", "Push Press", "Behind-the-Neck Press",
        "Dumbbell Shoulder Press", "Arnold Press", "Machine Shoulder Press",
        "Landmine Press",
        "Lateral Raise", "Cable Lateral Raise", "Machine Lateral Raise",
        "Front Raise", "Cable Front Raise",
        "Rear Delt Fly", "Reverse Pec Deck", "Face Pull", "Upright Row",
        // Triceps
        "Tricep Pushdown", "Rope Pushdown", "Overhead Tricep Extension",
        "Skull Crusher", "Dumbbell Skull Crusher", "JM Press",
        "Tricep Kickback", "Cable Kickback",
        // Back
        "Pull-up", "Chin-up", "Neutral-Grip Pull-up", "Weighted Pull-up",
        "Barbell Row", "Pendlay Row", "Yates Row",
        "Dumbbell Row", "Chest-Supported Row", "Single-Arm Dumbbell Row",
        "T-Bar Row", "Meadows Row", "Seal Row",
        "Lat Pulldown", "Straight-Arm Pulldown", "Cable Row", "Seated Cable Row",
        "Inverted Row", "Rack Pull", "Shrug", "Dumbbell Shrug",
        // Biceps
        "Barbell Curl", "EZ-Bar Curl",
        "Dumbbell Curl", "Incline Dumbbell Curl", "Hammer Curl", "Concentration Curl",
        "Preacher Curl", "Spider Curl",
        "Cable Curl", "Cable Hammer Curl", "Reverse Curl",
        // Quads
        "Back Squat", "Front Squat", "High-Bar Squat", "Low-Bar Squat",
        "Box Squat", "Pause Squat",
        "Leg Press", "Hack Squat", "Pendulum Squat", "Belt Squat",
        "Goblet Squat", "Dumbbell Squat", "Smith Machine Squat",
        "Leg Extension", "Sissy Squat",
        "Bulgarian Split Squat", "Split Squat",
        "Lunge", "Reverse Lunge", "Walking Lunge", "Step-Up", "Pistol Squat",
        // Hamstrings & Glutes
        "Deadlift", "Sumo Deadlift", "Trap Bar Deadlift",
        "Deficit Deadlift", "Snatch-Grip Deadlift",
        "Romanian Deadlift", "Stiff-Leg Deadlift", "Dumbbell Romanian Deadlift",
        "Leg Curl", "Seated Leg Curl", "Lying Leg Curl", "Nordic Curl",
        "Good Morning",
        "Hip Thrust", "Barbell Hip Thrust", "Single-Leg Hip Thrust", "Glute Bridge",
        "Glute Kickback", "Glute-Ham Raise",
        "Back Extension", "45° Back Extension",
        // Calves
        "Standing Calf Raise", "Seated Calf Raise",
        "Donkey Calf Raise", "Leg Press Calf Raise",
        // Core
        "Plank", "Side Plank", "Ab Wheel Rollout",
        "Hanging Leg Raise", "Hanging Knee Raise", "Toes-to-Bar",
        "Cable Crunch", "Crunch", "Sit-up", "Decline Sit-up",
        "Russian Twist", "Pallof Press", "Cable Woodchop",
        "L-Sit", "Dead Bug", "Bird Dog", "V-Up",
        // Olympic & Power
        "Power Clean", "Hang Clean", "Clean and Jerk",
        "Snatch", "Hang Snatch", "Clean Pull", "Snatch Pull",
        "Kettlebell Swing", "Kettlebell Snatch", "Turkish Get-Up",
        // Carries & Functional
        "Farmer's Walk", "Suitcase Carry", "Overhead Carry",
        "Sled Push", "Sled Drag",
        "Landmine Row", "Landmine Squat"
    ]

    static func filtered(by query: String) -> [String] {
        guard !query.isEmpty else { return suggestions }
        let q = query.lowercased()
        return suggestions.filter { $0.lowercased().contains(q) }
    }
}
