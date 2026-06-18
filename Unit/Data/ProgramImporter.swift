//
//  ProgramImporter.swift
//  Unit
//
//  Converts a ProgramTemplate into live SwiftData models: Split, DayTemplates,
//  and ensures referenced Exercises exist (creating new ones from
//  ExerciseCatalog metadata when needed).
//

import Foundation
import SwiftData

enum ProgramImporter {
    /// Plate granularity for starting-weight rounding. 2.5 kg matches the
    /// smallest standard barbell plate at most gyms; convert to lb at the
    /// presentation layer if the user's unit pick is pounds. Round DOWN per
    /// Q7 ("start light, leave room to grow" — Wendler convention).
    private static let plateGrainKg: Double = 2.5

    /// Creates a Split + DayTemplates for the program. Exercises referenced in
    /// the template are matched against existing rows (by name or alias) and
    /// created from ExerciseCatalog metadata when missing. Returns the new
    /// Split.
    ///
    /// When `oneRMs` is provided, each `ProgramItem` with non-nil
    /// `oneRepMaxLift` + `startingWeightPct` gets a stamped starting weight
    /// (1RM × pct, floored to the nearest 2.5 kg plate) written to the
    /// `DayTemplate.plannedWeightByExerciseId` map. Items without a 1RM
    /// mapping, or lifts the user skipped (absent from `oneRMs`), get no
    /// stamped weight — they'll show blank on first log per Q4 + Q7.
    ///
    /// Backwards-compatible: callers that omit `oneRMs` produce the same
    /// `DayTemplate` planned-maps as before.
    @MainActor
    @discardableResult
    static func importProgram(
        _ template: ProgramTemplate,
        into context: ModelContext,
        oneRMs: [OneRepMaxLift: Double]? = nil
    ) -> Split {
        let existingExercises = (try? context.fetch(FetchDescriptor<Exercise>())) ?? []
        var exerciseByNormalizedName: [String: Exercise] = [:]
        for exercise in existingExercises {
            for signature in [exercise.displayName] + exercise.aliases {
                exerciseByNormalizedName[normalize(signature)] = exercise
            }
        }

        func resolveExercise(named name: String) -> Exercise {
            if let match = exerciseByNormalizedName[normalize(name)] {
                return match
            }
            let catalogEntry = ExerciseCatalog.lookup(name)
            let exercise = Exercise(
                displayName: catalogEntry?.displayName ?? name,
                aliases: catalogEntry?.aliases ?? [],
                isBodyweight: catalogEntry?.isBodyweight ?? false,
                muscleGroup: catalogEntry?.muscleGroup ?? .fullBody,
                equipment: catalogEntry?.equipment ?? .other
            )
            context.insert(exercise)
            for signature in [exercise.displayName] + exercise.aliases {
                exerciseByNormalizedName[normalize(signature)] = exercise
            }
            return exercise
        }

        let split = Split(name: template.name)
        context.insert(split)

        var dayTemplates: [DayTemplate] = []
        for day in template.days {
            var exerciseIds: [UUID] = []
            var plannedSets: [UUID: Int] = [:]
            var plannedReps: [UUID: Int] = [:]
            var plannedWeights: [UUID: Double] = [:]
            for item in day.items {
                let exercise = resolveExercise(named: item.exerciseName)
                exerciseIds.append(exercise.id)
                if item.setCount > 0 { plannedSets[exercise.id] = item.setCount }
                if item.repTarget > 0 { plannedReps[exercise.id] = item.repTarget }
                if let weight = startingWeight(for: item, oneRMs: oneRMs) {
                    // Multiple items on the same day may reference the same
                    // exercise (e.g. 5/3/1 BBB has both main 5/3/1 work AND
                    // BBB volume work on the same lift). The map is keyed by
                    // exerciseId, so the LATER entry wins. Keep the heavier
                    // starting weight (main work, higher %) — the BBB volume
                    // appears after main work in the template but at a lower
                    // %, so an unguarded write would erase the heavier number
                    // the user actually wants pre-filled. Take the max.
                    if let existing = plannedWeights[exercise.id] {
                        plannedWeights[exercise.id] = max(existing, weight)
                    } else {
                        plannedWeights[exercise.id] = weight
                    }
                }
            }
            let dayTemplate = DayTemplate(
                name: day.name,
                splitId: split.id,
                orderedExerciseIds: exerciseIds,
                scheduledWeekday: day.weekday ?? 0,
                plannedSetsByExerciseId: plannedSets,
                plannedRepsByExerciseId: plannedReps,
                plannedWeightByExerciseId: plannedWeights
            )
            context.insert(dayTemplate)
            dayTemplates.append(dayTemplate)
        }

        split.orderedTemplateIds = dayTemplates.map(\.id)

        try? context.save()
        return split
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Returns the canonical starting weight for `item` given the user's
    /// `oneRMs` dictionary, or `nil` if the item has no 1RM mapping, no
    /// starting percentage, or the user skipped the relevant lift.
    /// Floored to `plateGrainKg` per Q7 (round DOWN to nearest 2.5 kg).
    static func startingWeight(
        for item: ProgramItem,
        oneRMs: [OneRepMaxLift: Double]?
    ) -> Double? {
        guard let oneRMs,
              let lift = item.oneRepMaxLift,
              let pct = item.startingWeightPct,
              let oneRM = oneRMs[lift],
              oneRM > 0 else {
            return nil
        }
        return floorToPlate(oneRM * pct, grain: plateGrainKg)
    }

    /// Floors `value` to the nearest multiple of `grain`. Inputs are in kg.
    /// Examples: `floorToPlate(58.5, grain: 2.5) == 57.5`,
    /// `floorToPlate(85.0, grain: 2.5) == 85.0`.
    static func floorToPlate(_ value: Double, grain: Double) -> Double {
        guard grain > 0 else { return value }
        return (value / grain).rounded(.down) * grain
    }
}
