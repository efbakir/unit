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
    /// First-session weight seed (kg), carried from
    /// `ImportedProgramExercise.weightKg`. Becomes the "Last time" ghost
    /// weight on the very first session so a pasted program's numbers aren't
    /// discarded. `nil` when the paste carried no weight — the field stays
    /// blank, exactly as before. `Optional<Double>` decodes via
    /// `decodeIfPresent`, so onboarding drafts persisted before this field
    /// existed migrate to `nil` cleanly (no stored-data migration needed).
    var plannedWeightKg: Double? = nil
    /// Parser-captured detail that the data model can't represent
    /// structurally yet (per-side, duration, distance, tempo, intent
    /// qualifiers, parenthesized form notes). Carried from
    /// `ImportedProgramExercise.note` into onboarding state so the
    /// Exercises confirmation step can render it as a muted hint under
    /// the exercise name — the lifter sees what the parser saw before
    /// committing. Empty string is the canonical "no note" sentinel so
    /// the Codable persistence in `OnboardingPreferences` stays simple
    /// (no Optional<String> migration on stored data). Not persisted to
    /// the `Exercise` model — these details are v2 structural work
    /// (per-side reps, duration on `SetEntry`, etc.).
    var note: String = ""
    /// Original sanitized line from the paste — surfaced under each
    /// exercise row on the Exercises step (paste path only) as a
    /// `From: <raw line>` muted hint so the lifter sees what the parser
    /// read, side-by-side with the parsed name + sets + reps. Catches
    /// the 8 silent-corruption modes the parser hardening pass closed
    /// (rep ranges, RPE %, Wendler 5/3/1, ChatGPT verbose form, markdown
    /// tables) before they commit to a real Split. Empty string is the
    /// canonical "no source line" sentinel — manually-added exercises
    /// from `OnboardingExerciseSearchSheet` carry "", so the row stays clean.
    /// Codable default "" same pattern as `note` above; no migration.
    var originalLine: String = ""
}

struct ImportedProgramExercise: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    var weightKg: Double?
    /// Free-form parser note — assembled by `ProgramImportParser.Normalizer`
    /// from per-side / duration / distance / intent / paren-form-cue
    /// tokens that the data model can't store structurally. Threaded into
    /// `OnboardingExercise.note` by `applyImportedProgram(_:)` so the
    /// Exercises step can surface it. `nil` if the parser found nothing
    /// noteworthy — distinct from "" so an empty parser result reads as
    /// "no detail captured" rather than "detail explicitly cleared".
    var note: String? = nil
    /// Raw sanitized line this exercise came from — propagated through
    /// the parser so the Exercises step can render a `From: <line>` hint
    /// under each row when `importMethod == .paste`. Lifter scans this
    /// against the parsed name + sets + reps to catch mismatches before
    /// commit (rep ranges parsed as weight, RPE % as kg, etc.). `nil`
    /// for non-paste paths (history fast-track, manual build).
    var originalLine: String? = nil
}

struct ImportedProgramDay: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var exercises: [ImportedProgramExercise]
}

// MARK: - ViewModel

@Observable
final class OnboardingViewModel {

    /// Nonisolated for the same back-deploy-shim SIGABRT as
    /// `ActiveWorkoutViewModel.deinit` — see the comment there. (This class
    /// is MainActor via the module's default isolation, so its implicit
    /// deinit was isolated too.)
    nonisolated deinit {}

    // MARK: Path

    enum SetupPath { case build }
    var setupPath: SetupPath = .build

    enum ImportMethod {
        case paste
        case library
    }
    var importMethod: ImportMethod = .library

    /// Raw text in the paste step's editor. Lives on the viewmodel (not as
    /// view-local `@State`) so step swaps through `OnboardingFlow` — which
    /// disposes and re-creates each step via `.id(step)` — preserve whatever
    /// the user typed. Persisted via `OnboardingPreferences` so a
    /// quit-and-relaunch mid-paste returns the user to the same draft.
    var pastedProgramText: String = ""

    /// Warnings emitted by the last successful `ProgramImportParser` run.
    /// The Exercises step renders these as a muted footer ("2 lines
    /// skipped: Bike Intervals, Easy Bike Cooldown") so the parser's drops
    /// are never invisible to the lifter. Reset to `[]` when
    /// `applyImportedProgram(_:)` runs again. Not persisted across
    /// app relaunch — these are step-local context, not user data.
    var importWarnings: [ProgramImportResult.Warning] = []

    // MARK: Library path (Phase B-3)

    /// Program template picked from the onboarding library (Q1 surfaced set:
    /// Reddit PPL / GZCLP / 5/3/1 BBB / nSuns / PHUL). nil until the user
    /// taps a card on `OnboardingLibraryPickerView`. Drives the 1RM screen
    /// (which only fires for library path) and the program preview's
    /// starting-weight stamping.
    var pickedProgram: ProgramTemplate? = nil

    /// User-entered compound 1RMs from `Onboarding1RMInputView`. Keyed by
    /// lift; skipped lifts are absent. Threaded into `ProgramImporter`'s
    /// `oneRMs:` parameter at commit time to stamp starting weights into
    /// `DayTemplate.plannedWeightByExerciseId`. Empty dictionary = user
    /// skipped all 4 lifts → program preview shows blank weights.
    var oneRMs: [OneRepMaxLift: Double] = [:]

    // MARK: Units

    /// "kg" or "lb". Written to AppStorage("unitSystem") after commit.
    var unitSystem: String = "kg"

    // MARK: Split

    /// Allowed training days per week: 1 (full-body, same workout each
    /// session) through 7 (every day). The split-builder stepper and every
    /// restore/clamp path read this single range so the bound never drifts
    /// across files.
    static let dayCountRange: ClosedRange<Int> = 1...7

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
        let count = min(max(newCount, Self.dayCountRange.lowerBound), Self.dayCountRange.upperBound)
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
        //
        // Synthesize a concise name when all day labels are generic
        // placeholders (`Day 1`, `Workout 2`, `Session 3`). The join-on-` / `
        // form ("Workout 1 / Workout 2 / Push / Pull") was visually noisy in
        // the Today eyebrow and the Templates list after paste-import when
        // the lifter hadn't renamed every day yet. The synthesized "4-Day
        // Split" is still editable post-commit from `TemplatesView`, but
        // gives the cleaner default. Mixed-naming pastes (some custom + some
        // generic) keep the original join — the lifter named those days
        // intentionally.
        let splitName: String = {
            let allGeneric = dayNames.allSatisfy { isGenericDayName($0) }
            if allGeneric && dayNames.count > 0 {
                return "\(dayNames.count)-Day Split"
            }
            return dayNames.joined(separator: " / ")
        }()
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
            var weightPlan: [UUID: Double] = [:]
            for onbEx in dayOnbExs {
                guard let resolvedId = exerciseMap[onbEx.id]?.id else { continue }
                setsPlan[resolvedId] = onbEx.plannedSets
                repsPlan[resolvedId] = onbEx.plannedReps
                // Only seed a real, positive weight — a 0 or absent paste
                // weight leaves the field blank so the ghost reads as "no
                // weight yet", not "0 kg".
                if let w = onbEx.plannedWeightKg, w > 0 { weightPlan[resolvedId] = w }
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
                plannedRepsByExerciseId: repsPlan,
                plannedWeightByExerciseId: weightPlan
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
    /// Static probe — callers (and unit tests) can hit the vocabulary
    /// without instantiating `OnboardingViewModel`. Constructing the
    /// viewmodel from a `@MainActor`-unestablished test harness can
    /// SIGABRT in Swift 6 if the `@Observable` macro tries to register
    /// observers before the actor is live. The instance method below
    /// preserves the existing call-site signature
    /// (`vm.isBodyweightExercise(named:)`) by forwarding here.
    static func isBodyweightExercise(named exerciseName: String) -> Bool {
        let name = exerciseName
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
        let bodyweightKeywords = [
            "pull up", "chin up", "push up", "dip", "plank", "hanging leg raise",
            "ab wheel rollout", "sit up", "crunch", "mountain climber", "burpee",
            "bodyweight squat",
            // Vocab expansion — these all reliably default to BW in real
            // programs (`Inverted Row 3x12`, `Band Pull Aparts 3x20`,
            // `Face Pull 4x15`, `Neck Extension 2x20`). The lifter can
            // still log added weight; the flag just means the ghost-value
            // baseline doesn't read as "0 kg" on session 1.
            "inverted row", "band pull apart", "band pull aparts",
            "face pull", "neck extension", "neck flexion",
            "muscle up", "ring dip", "ring row",
            "knees to elbows", "toes to bar"
        ]
        return bodyweightKeywords.contains { name.contains($0) }
    }

    func isBodyweightExercise(named exerciseName: String) -> Bool {
        Self.isBodyweightExercise(named: exerciseName)
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

        dayCount = min(max(sanitizedDays.count, Self.dayCountRange.lowerBound), Self.dayCountRange.upperBound)
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
                    plannedReps: clampPlannedReps(exercise.reps ?? OnboardingExercise.defaultPlannedReps),
                    plannedWeightKg: exercise.weightKg,
                    note: exercise.note ?? "",
                    originalLine: exercise.originalLine ?? ""
                )
            }
        })
    }

    /// Library-pick adapter (Phase B-3). Translates a `ProgramTemplate` from
    /// `ProgramCatalog.surfacedInOnboarding` into the in-memory onboarding
    /// state shared with paste + (legacy) manual paths, so the downstream
    /// exercises/preview step renders the picked program through the same
    /// pipeline that paste uses. Starting weights are NOT computed here —
    /// they fill in via `applyOneRMs()` after the user types their 1RMs
    /// on `Onboarding1RMInputView`.
    func applyPickedProgram(_ template: ProgramTemplate) {
        pickedProgram = template
        oneRMs = [:]
        importWarnings = []

        let templateDays = template.days
        guard !templateDays.isEmpty else { return }

        dayCount = min(max(templateDays.count, Self.dayCountRange.lowerBound), Self.dayCountRange.upperBound)
        dayNames = Array(templateDays.prefix(dayCount).map(\.name))
        // Library programs always declare weekdays — write through; the
        // schedule step is bypassed for the library path.
        dayWeekdays = Array(templateDays.prefix(dayCount).map { $0.weekday ?? 0 })
        useFlexibleSchedule = false

        dayExercises = Array(templateDays.prefix(dayCount).map { day in
            day.items.map { item in
                OnboardingExercise(
                    name: item.exerciseName,
                    plannedSets: clampPlannedSets(item.setCount > 0 ? item.setCount : OnboardingExercise.defaultPlannedSets),
                    plannedReps: clampPlannedReps(item.repTarget > 0 ? item.repTarget : OnboardingExercise.defaultPlannedReps),
                    plannedWeightKg: nil,
                    note: item.notes ?? "",
                    originalLine: ""
                )
            }
        })
    }

    /// Walks the currently-picked program's items and stamps starting weights
    /// onto `dayExercises[].plannedWeightKg` wherever a 1RM mapping +
    /// percentage exists AND the user supplied that 1RM in `oneRMs`. Items
    /// without a stamp keep `nil` and show blank on first log per Q4 fallback.
    /// Idempotent — safe to call repeatedly if the user re-enters 1RMs.
    func applyOneRMs() {
        guard let template = pickedProgram else { return }
        let templateDays = template.days.prefix(dayCount)
        for (dayIndex, day) in templateDays.enumerated() where dayIndex < dayExercises.count {
            var dayItems = Array(zip(day.items, dayExercises[dayIndex]))
            for (itemIndex, pair) in dayItems.enumerated() {
                let (programItem, onboardingExercise) = pair
                let stamped = ProgramImporter.startingWeight(for: programItem, oneRMs: oneRMs)
                var updated = onboardingExercise
                updated.plannedWeightKg = stamped
                dayItems[itemIndex] = (programItem, updated)
            }
            dayExercises[dayIndex] = dayItems.map(\.1)
        }
    }

    private func normalizedExerciseName(_ name: String) -> String {
        name
            .lowercased()
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
    }

    /// True when a day-template name is a generic placeholder (`Day N`,
    /// `Workout N`, `Session N`). Used at commit time to decide whether to
    /// synthesize a concise split name ("4-Day Split") or join the labels
    /// verbatim — generic-only placements never give the lifter a useful
    /// joined name, so the synthesized form scans cleaner everywhere.
    private func isGenericDayName(_ name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let pattern = #"^(day|workout|session)\s+\d+$"#
        return trimmed.range(of: pattern, options: .regularExpression) != nil
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
