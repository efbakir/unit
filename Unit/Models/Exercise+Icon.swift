import Foundation

/// Movement patterns only. Analytics main-lift qualification remains exact-alias based.
nonisolated enum ExerciseIconResolver {
    static func icon(name: String, muscleGroup: String = "", equipment: String? = nil) -> AppIcon {
        let locale = Locale(identifier: "en_US_POSIX")
        let folded = name.folding(options: [.diacriticInsensitive, .caseInsensitive, .widthInsensitive], locale: locale).lowercased(with: locale)
        let words = folded.split { $0.isWhitespace || "-_/.,".contains($0) }.map(String.init)
        guard !words.isEmpty else { return .deadlift }
        let tokens = Set(words)
        func has(_ choices: String...) -> Bool { choices.contains(where: tokens.contains) }
        func phrase(_ first: String, _ seconds: String...) -> Bool {
            zip(words, words.dropFirst()).contains { $0 == first && seconds.contains($1) }
        }
        if has("row", "rows"), !has("rowing", "rower", "erg", "ergometer"), !phrase("upright", "row", "rows") { return .liftRow }
        if has("pullup", "pullups", "chinup", "chinups", "pulldown", "pulldowns", "latpulldown", "muscleup") || phrase("pull", "up", "ups", "down", "downs") || phrase("chin", "up", "ups") || phrase("muscle", "up") { return .liftPullup }
        if has("deadlift", "deadlifts", "rdl", "romanian") || phrase("stiff", "leg", "legged") || phrase("good", "morning") || phrase("rack", "pull") || phrase("hip", "hinge") { return .liftDeadlift }
        if has("squat", "squats", "thruster", "lunge", "lunges") || phrase("leg", "press") { return .liftSquat }
        if (has("bench") || phrase("floor", "press") || phrase("chest", "press")), !phrase("bench", "dip", "dips") { return .liftBench }
        if has("ohp") || ["overhead", "military", "shoulder", "push", "strict", "arnold", "landmine"].contains(where: { phrase($0, "press") }) { return .liftOverhead }
        if muscleGroup == "core" || has("plank", "crunch", "ab", "abs", "hollow") || phrase("sit", "up") { return .core }
        if equipment == "dumbbell" || equipment == "kettlebell" || has("dumbbell", "db", "kettlebell", "kb", "curl") { return .dumbbell }
        return .deadlift
    }
}

extension Exercise {
    var icon: AppIcon {
        ExerciseIconResolver.icon(name: displayName, muscleGroup: muscleGroupRaw, equipment: equipmentRaw)
    }
}
