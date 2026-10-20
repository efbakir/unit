import Foundation

/// Icons are reserved for the Big 6 in Analytics and exercise detail.
/// Match complete names/aliases, never movement-family keywords or muscle groups.
/// Other exercises deliberately have no icon.
nonisolated enum ExerciseIconResolver {
    static func icon(name: String, muscleGroup: String = "", equipment: String? = nil) -> AppIcon? {
        let locale = Locale(identifier: "en_US_POSIX")
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: locale).lowercased(with: locale)
        let normalized = folded.split { !$0.isLetter && !$0.isNumber }
            .filter { $0 != "bb" }.joined()
        guard !normalized.isEmpty else { return nil }

        if ["pullup", "pullups", "bodyweightpullup", "weightedpullup"].contains(normalized) {
            return .liftPullup
        }
        // A generic name with explicit dumbbell/machine metadata is a variant,
        // not one of the canonical barbell lifts.
        guard equipment == nil || equipment == "" || equipment == "other" || equipment == "barbell" else { return nil }
        switch normalized {
        case "squat", "backsquat", "barbellsquat", "barbellbacksquat", "highbarsquat", "lowbarsquat", "highbarbacksquat", "lowbarbacksquat":
            return .liftSquat
        case "bench", "benchpress", "barbellbench", "barbellbenchpress", "flatbench", "flatbenchpress", "flatbarbellbenchpress":
            return .liftBench
        case "deadlift", "barbelldeadlift", "conventionaldeadlift", "sumodeadlift", "deadliftconv", "deadliftconventional":
            return .liftDeadlift
        case "ohp", "overheadpress", "barbelloverheadpress", "overheadbarbellpress", "militarypress", "shoulderpress", "standingbarbellpress":
            return .liftOverhead
        case "row", "barbellrow", "bentoverrow", "bentoverbarbellrow", "barbellbentoverrow", "bentoverrowbb":
            return .liftRow
        default:
            return nil
        }
    }
}

extension Exercise {
    var icon: AppIcon? {
        ExerciseIconResolver.icon(name: displayName, muscleGroup: muscleGroupRaw, equipment: equipmentRaw)
    }
}
