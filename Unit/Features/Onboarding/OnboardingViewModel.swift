//
//  OnboardingViewModel.swift
//  Unit
//
//  Transient onboarding state. No SwiftData @Model — all writes happen
//  atomically in commit() when the user taps "Save program" on the
//  program preview (which saves the program, then presents the hard paywall).
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
    /// First-session starting target (kg), carried from
    /// `ImportedProgramExercise.weightKg`. It remains explicitly planned—not
    /// mislabeled as history—so a pasted program's numbers aren't discarded.
    /// `nil` when the paste carried no weight — the field stays
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
    /// from the deleted v1 search sheet carry "", so the row stays clean.
    /// Codable default "" same pattern as `note` above; no migration.
    var originalLine: String = ""
    /// True when the paste parser found no explicit sets/reps on the line
    /// and fell back to the 3×8 default — drives the "Check sets and reps"
    /// hint on the preview. Recorded at mapping time so an explicitly
    /// written "3x8" never trips the hint (value equality can't tell the
    /// two apart). `Optional<Bool>` decodes to `nil` on drafts persisted
    /// before this field existed — same no-migration pattern as
    /// `plannedWeightKg`; `nil` reads as "not defaulted".
    var usedDefaultSetsReps: Bool? = nil
    /// Present only when the source explicitly supports progressive overload:
    /// a pasted rep range or an eligible ready-made program item.
    var progressionConfiguration: DoubleProgressionConfiguration? = nil
}

struct ImportedProgramExercise: Identifiable, Equatable {
    var id = UUID()
    var name: String
    var sets: Int?
    var reps: Int?
    /// Full pasted range (`8...10`). A single target such as `3×8` remains
    /// nil and therefore fixed unless the user enables progression later.
    var repRange: ClosedRange<Int>? = nil
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

    enum ImportMethod: Equatable {
        case paste
        case library
    }
    var importMethod: ImportMethod = .library
    /// Distinguishes the default value above from a choice the lifter has
    /// explicitly made. Returning to the step keeps the chosen card selected
    /// and switches navigation from auto-advance to the sticky CTA.
    var hasSelectedImportMethod = false

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

    var preferredGoal: ProgramTemplate.Goal? = nil
    var preferredLevel: ProgramTemplate.Level? = nil
    var preferredDaysPerWeek: Int? = nil

    var programMatchProfile: ProgramMatchProfile? {
        guard let preferredGoal,
              let preferredLevel,
              let preferredDaysPerWeek else { return nil }
        return ProgramMatchProfile(
            goal: preferredGoal,
            level: preferredLevel,
            daysPerWeek: preferredDaysPerWeek
        )
    }

    /// Program template picked from the 1–3 catalog matches. Nil until the
    /// user taps a result on `OnboardingLibraryPickerView`. Drives the program
    /// preview, where the user fills in their own weights inline.
    var pickedProgram: ProgramTemplate? = nil

    // MARK: Units

    /// "kg" or "lb". Written to AppStorage("unitSystem") after commit.
    var unitSystem: String = "kg"

    /// First-run guess from the phone's region: pounds only where the region
    /// measures in US units. Changeable on review and in Settings.
    static var regionDefaultUnitSystem: String {
        Locale.current.measurementSystem == .us ? "lb" : "kg"
    }

    /// Unit's default weight steps follow the chosen unit (2.5 kg, 2 kg for
    /// dumbbells, or 5 lb). Called when the unit changes on review, so a
    /// pounds lifter never sees "+5.5 lb" from a kg default. Custom steps
    /// are left alone.
    func convertDefaultWeightSteps(to newUnit: String) {
        let pound = 5 / 2.20462
        dayExercises = dayExercises.map { day in
            day.map { exercise in
                guard let rule = exercise.progressionConfiguration,
                      [2.5, 2, pound].contains(where: { abs(rule.weightIncrementKg - $0) < 0.000_1 })
                else { return exercise }
                let isDumbbell = exercise.name.contains("DB")
                    || exercise.name.localizedCaseInsensitiveContains("dumbbell")
                var converted = exercise
                converted.progressionConfiguration = DoubleProgressionConfiguration(
                    workingSetCount: rule.workingSetCount,
                    lowerRepBound: rule.lowerRepBound,
                    upperRepBound: rule.upperRepBound,
                    weightIncrementKg: newUnit == "lb" ? pound : (isDumbbell ? 2 : 2.5)
                )
                return converted
            }
        }
    }

    /// Plain pasted numbers mean the unit the lifter had in mind. When the
    /// paste names no unit at all, switching kg/lb on review re-reads those
    /// numbers in the new unit instead of converting them (60 stays 60).
    func rereadPlainPastedWeights() {
        guard importMethod == .paste, pickedProgram == nil,
              !pastedProgramText.isEmpty,
              !Self.mentionsWeightUnit(pastedProgramText) else { return }
        let result = ProgramImportParser.parseWithWarnings(pastedProgramText, defaultUnit: unitSystem)
        guard !result.days.isEmpty else { return }
        applyImportedProgram(result.days)
        importWarnings = result.warnings
    }

    static func mentionsWeightUnit(_ text: String) -> Bool {
        text.lowercased().range(of: #"\d\s*(kgs?\b|lbs?\b|#)"#, options: .regularExpression) != nil
    }

    /// When pasted text names only one unit (`60kg`, `135 lb`, `135#`), use
    /// it for plain numbers too. Mixed or unit-free text keeps `current`.
    static func inferredUnitSystem(from text: String, current: String) -> String {
        let lowered = text.lowercased()
        let mentionsPounds = lowered.range(of: #"\d\s*(lbs?\b|#)"#, options: .regularExpression) != nil
        let mentionsKilograms = lowered.range(of: #"\d\s*kgs?\b"#, options: .regularExpression) != nil
        if mentionsPounds && !mentionsKilograms { return "lb" }
        if mentionsKilograms && !mentionsPounds { return "kg" }
        return current
    }
    /// `unitSystem` has a parser-safe default, but the onboarding card should
    /// not read as chosen until the lifter taps it.
    var hasSelectedUnit = false

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

    /// The persisted Split title. Catalog picks retain the title the user saw
    /// in the library; pasted programs continue to derive a useful title from
    /// their day labels.
    var resolvedProgramName: String {
        if importMethod == .library,
           let pickedProgram,
           !pickedProgram.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return pickedProgram.name.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let allGeneric = dayNames.allSatisfy { isGenericDayName($0) }
        if allGeneric && !dayNames.isEmpty {
            return "\(dayNames.count)-Day Split"
        }
        return dayNames.joined(separator: " / ")
    }

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
            var seenInDay: [String: Int] = [:]
            for onbEx in day {
                let displayName = onbEx.name.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !displayName.isEmpty else { continue }
                let nameKey = displayName.lowercased()
                let occurrence = seenInDay[nameKey, default: 0]
                seenInDay[nameKey] = occurrence + 1
                // Same lift twice on one day (5/3/1, then BBB volume) needs two
                // exercise ids. One id collapses the plans and crashes summaries.
                let resolvedName = occurrence == 0
                    ? displayName
                    : ProgramImporter.repeatedExerciseDisplayName(
                        displayName,
                        note: onbEx.note,
                        occurrence: occurrence
                    )
                let resolvedKey = resolvedName.lowercased()
                let isBodyweight = isBodyweightExercise(named: displayName)
                if let match = nameToExercise[resolvedKey] {
                    match.isArchived = false
                    if isBodyweight && !match.isBodyweight {
                        match.isBodyweight = true
                    }
                    exerciseMap[onbEx.id] = match
                } else {
                    let ex = Exercise(
                        displayName: resolvedName,
                        isBodyweight: isBodyweight
                    )
                    modelContext.insert(ex)
                    exerciseMap[onbEx.id] = ex
                    nameToExercise[resolvedKey] = ex
                }
            }
        }

        // 2. Create Split
        //
        // Catalog picks keep the program title shown in the library. Pasted
        // programs derive a useful title from their day labels, with a concise
        // fallback when every label is generic.
        let split = Split(name: resolvedProgramName)
        modelContext.insert(split)

        // 3. Create DayTemplates
        var templateIds: [UUID] = []
        for (i, name) in dayNames.enumerated() {
            let dayOnbExs = dayExercises[i].filter {
                !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
            // Never save an empty routine (every row removed or renamed to
            // nothing on Review).
            guard !dayOnbExs.isEmpty else { continue }
            let exerciseIds = dayOnbExs.compactMap { exerciseMap[$0.id]?.id }
            var setsPlan: [UUID: Int] = [:]
            var repsPlan: [UUID: Int] = [:]
            var weightPlan: [UUID: Double] = [:]
            var progressionPlan: [UUID: ExerciseProgressionState] = [:]
            for onbEx in dayOnbExs {
                guard let resolvedExercise = exerciseMap[onbEx.id] else { continue }
                let resolvedId = resolvedExercise.id
                setsPlan[resolvedId] = onbEx.plannedSets
                repsPlan[resolvedId] = onbEx.plannedReps
                // Only seed a real, positive weight — a 0 or absent paste
                // weight leaves the field blank so the ghost reads as "no
                // weight yet", not "0 kg".
                if let w = onbEx.plannedWeightKg, w > 0 { weightPlan[resolvedId] = w }
                // Preserve every explicit imported rep range. Bodyweight
                // movements may still use added external load (for example,
                // weighted pull-ups); the finish-time evaluator distinguishes
                // those from unsupported bodyweight-only sessions using the
                // weights the lifter actually completed.
                if let configuration = onbEx.progressionConfiguration,
                   configuration.isValid {
                    progressionPlan[resolvedId] = ExerciseProgressionState(
                        lowerRepBound: configuration.lowerRepBound,
                        upperRepBound: configuration.upperRepBound,
                        weightIncrementKg: configuration.weightIncrementKg,
                        currentAcceptedTargetWeightKg: nil,
                        currentAcceptedTargetReps: configuration.lowerRepBound,
                        sourceWorkoutSessionID: nil,
                        lastAcceptedReason: nil
                    )
                }
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
                plannedWeightByExerciseId: weightPlan,
                progressionStateByExerciseId: progressionPlan
            )
            modelContext.insert(tmpl)
            templateIds.append(tmpl.id)
        }
        split.orderedTemplateIds = templateIds

        try modelContext.save()

        ActiveSplitStore.setCurrent(split.id)
    }
}

// MARK: - Review edits

extension OnboardingViewModel {
    /// Everything a Review removal can change, so Undo restores it exactly.
    struct RemovedExerciseSnapshot: Equatable {
        let id = UUID()
        let exerciseName: String
        let dayIndex: Int
        let removedDay: Bool
        let dayCount: Int
        let dayNames: [String]
        let dayExercises: [[OnboardingExercise]]
        let dayWeekdays: [Int]
    }

    /// The program's last remaining exercise cannot be removed; Review would
    /// have nothing left to save.
    var canRemoveExercise: Bool {
        dayExercises.reduce(0) { $0 + $1.count } > 1
    }

    /// Removes one exercise on Review (benchmark 2026-10-24, setup row 4).
    /// Removing a day's last exercise removes the day too.
    @discardableResult
    func removeExercise(dayIndex: Int, exerciseID: UUID) -> RemovedExerciseSnapshot? {
        guard canRemoveExercise,
              dayExercises.indices.contains(dayIndex),
              let index = dayExercises[dayIndex].firstIndex(where: { $0.id == exerciseID }) else {
            return nil
        }
        let removesDay = dayExercises[dayIndex].count == 1
        let snapshot = RemovedExerciseSnapshot(
            exerciseName: dayExercises[dayIndex][index].name,
            dayIndex: dayIndex,
            removedDay: removesDay,
            dayCount: dayCount,
            dayNames: dayNames,
            dayExercises: dayExercises,
            dayWeekdays: dayWeekdays
        )
        if removesDay {
            dayExercises.remove(at: dayIndex)
            if dayNames.indices.contains(dayIndex) { dayNames.remove(at: dayIndex) }
            if dayWeekdays.indices.contains(dayIndex) { dayWeekdays.remove(at: dayIndex) }
            dayCount = dayExercises.count
        } else {
            dayExercises[dayIndex].remove(at: index)
        }
        return snapshot
    }

    func undoRemoval(_ snapshot: RemovedExerciseSnapshot) {
        dayCount = snapshot.dayCount
        dayNames = snapshot.dayNames
        dayWeekdays = snapshot.dayWeekdays
        dayExercises = snapshot.dayExercises
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
            "bodyweight squat", "squat jump", "broad jump", "plyo push up",
            "push up plus",
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

        pickedProgram = nil
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
                let plannedSets = clampPlannedSets(exercise.sets ?? OnboardingExercise.defaultPlannedSets)
                let plannedReps = clampPlannedReps(exercise.reps ?? OnboardingExercise.defaultPlannedReps)
                let progressionConfiguration = exercise.repRange.map { range in
                    DoubleProgressionConfiguration(
                        workingSetCount: plannedSets,
                        lowerRepBound: range.lowerBound,
                        upperRepBound: range.upperBound,
                        weightIncrementKg: unitSystem == "lb" ? 5 / 2.20462 : 2.5
                    )
                }
                return OnboardingExercise(
                    name: exercise.name,
                    plannedSets: plannedSets,
                    plannedReps: plannedReps,
                    plannedWeightKg: exercise.weightKg,
                    note: exercise.note ?? "",
                    originalLine: exercise.originalLine ?? "",
                    usedDefaultSetsReps: exercise.sets == nil || exercise.reps == nil,
                    progressionConfiguration: progressionConfiguration
                )
            }
        })
    }

    /// Library-pick adapter (Phase B-3). Translates a `ProgramTemplate` from
    /// `ProgramCatalog.all` into the in-memory onboarding
    /// state shared with the paste path, so the downstream preview step renders
    /// the picked program through the same pipeline paste uses. Weights start
    /// blank (`plannedWeightKg: nil`); the user fills them in inline on the
    /// program preview. The 1RM-entry screen was removed 2026-06-18.
    func applyPickedProgram(_ template: ProgramTemplate) {
        pickedProgram = template
        importWarnings = []

        let templateDays = template.days
        guard !templateDays.isEmpty else { return }

        dayCount = min(max(templateDays.count, Self.dayCountRange.lowerBound), Self.dayCountRange.upperBound)
        dayNames = Array(templateDays.prefix(dayCount).map(\.name))
        // Library programs declare canonical weekdays. Keep them as defaults
        // that the schedule review can confirm or edit before commit.
        dayWeekdays = Array(templateDays.prefix(dayCount).map { $0.weekday ?? 0 })
        useFlexibleSchedule = false

        dayExercises = Array(templateDays.prefix(dayCount).map { day in
            day.items.map { item in
                let progressionConfiguration = ProgramImporter.libraryProgressionConfiguration(
                    for: item,
                    in: template,
                    unitSystem: unitSystem
                )
                return OnboardingExercise(
                    name: item.exerciseName,
                    plannedSets: clampPlannedSets(item.setCount > 0 ? item.setCount : OnboardingExercise.defaultPlannedSets),
                    plannedReps: clampPlannedReps(item.repTarget > 0 ? item.repTarget : OnboardingExercise.defaultPlannedReps),
                    plannedWeightKg: nil,
                    note: item.notes ?? "",
                    originalLine: "",
                    progressionConfiguration: progressionConfiguration
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
