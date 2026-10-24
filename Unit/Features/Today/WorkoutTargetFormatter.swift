//
//  WorkoutTargetFormatter.swift
//  Unit
//
//  Shared target/result formatting for workout surfaces.
//

import Foundation

enum WorkoutTargetFormatter {

    /// Final B logging distinguishes explicit zero external load from bodyweight.
    /// Kept scoped so historical/progression presentation retains its contracts.
    static func loggingSetText(weightKg: Double, reps: Int, isBodyweight: Bool, unitSystem: String) -> String {
        "\(loadText(weightKg: weightKg, isBodyweight: isBodyweight, unitSystem: unitSystem)) × \(reps)"
    }

    /// Positive weight step in the same number style (`+2.5 kg`, `+5 lb`).
    static func loggingIncrementText(weightKg: Double, unitSystem: String) -> String {
        "+\(weightNumber(kg: weightKg, unit: unitSystem)) \(unitSystem)"
    }

    /// The one way a weight number is written on screen (decision 2026-10-24):
    /// the phone's decimal mark, up to 2 decimals in kg and 1 in lb, trailing
    /// zeros dropped. Every set, target and Analytics value goes through it.
    static func weightNumber(display value: Double, unit: String, locale: Locale = .current) -> String {
        value.formatted(
            .number.locale(locale).grouping(.automatic)
                .precision(.fractionLength(0...(unit == "lb" ? 1 : 2)))
        )
    }

    static func weightNumber(kg: Double, unit: String, locale: Locale = .current) -> String {
        weightNumber(display: unit == "lb" ? kg * 2.20462 : kg, unit: unit, locale: locale)
    }

    /// Load in one set: "80 kg", "BW", "BW + 10 kg". Bodyweight is chosen
    /// explicitly and never inferred from zero (Final B), so a weighted lift
    /// logged at zero reads "0 kg".
    static func loadText(weightKg: Double, isBodyweight: Bool, unitSystem: String) -> String {
        let load = "\(weightNumber(kg: weightKg, unit: unitSystem)) \(unitSystem)"
        guard isBodyweight else { return load }
        return weightKg > 0 ? "BW + \(load)" : "BW"
    }

    private static var preferredUnit: String {
        UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
    }

    private static let englishNumberLocale = Locale(identifier: "en_US")

    /// Unit token beside the active set-entry weight field. Bodyweight means
    /// `BW` only while added load is blank or zero; a positive external load
    /// keeps the user's chosen kg/lb meaning.
    static func weightInputSuffix(
        displayWeight: Double?,
        isBodyweight: Bool,
        unitSystem: String
    ) -> String? {
        if isBodyweight {
            if let displayWeight, displayWeight > 0 {
                return unitSystem
            }
            return AppCopy.Workout.bodyweightAbbrev
        }
        return displayWeight == 0 ? AppCopy.Workout.bodyweightAbbrev : nil
    }

    /// Format a weight value with the user's preferred unit label (spaced, for labels and sentences).
    static func weightDisplay(_ kg: Double) -> String {
        let unit = preferredUnit
        return "\(weightNumber(kg: kg, unit: unit)) \(unit)"
    }

    /// Compact display spacing shared by the large workout readout and set chips.
    /// Thin operator spaces avoid full monospaced cells around ×; narrow,
    /// nonbreaking unit spaces keep the amount and its unit together.
    /// Callers retain the original sentence for accessibility.
    static func compactMetricSpacing(_ text: String) -> String {
        text
            .replacingOccurrences(of: " × ", with: "\u{2009}×\u{2009}")
            .replacingOccurrences(of: " kg", with: "\u{202F}kg")
            .replacingOccurrences(of: " lb", with: "\u{202F}lb")
    }

    /// Inline weight token for compact metrics (`60kg`, `132.5lb`).
    static func weightCompact(_ kg: Double) -> String {
        let unit = UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
        if unit == "lb" {
            let lb = kg * 2.20462
            return "\(lb.weightString)lb"
        }
        return "\(kg.weightString)kg"
    }

    /// Sets and reps only (no weight), e.g. `4x8`.
    static func setRepCompact(setCount: Int, reps: Int) -> String? {
        guard setCount > 0, reps > 0 else { return nil }
        return "\(setCount)x\(reps)"
    }

    /// Canonical readable sets-and-reps prescription (`3 × 8`). Use on
    /// program, Today, and configuration surfaces where clarity outranks the
    /// dense logging shorthand provided by `setRepCompact`.
    static func setRepDisplay(setCount: Int, reps: Int) -> String? {
        guard setCount > 0, reps > 0 else { return nil }
        return "\(setCount) × \(reps)"
    }

    /// Canonical readable double-progression range (`3 × 8–10`).
    static func repRangeDisplay(
        setCount: Int,
        lowerRepBound: Int,
        upperRepBound: Int
    ) -> String? {
        guard setCount > 0,
              lowerRepBound > 0,
              upperRepBound >= lowerRepBound else {
            return nil
        }
        return "\(setCount) × \(lowerRepBound)–\(upperRepBound)"
    }

    /// Canonical positive equipment increment (`+2.5 kg`, `+5 lb`).
    static func weightIncrementDisplay(_ weightIncrementKg: Double) -> String? {
        guard weightIncrementKg.isFinite, weightIncrementKg > 0 else {
            return nil
        }
        return "+\(weightDisplay(weightIncrementKg))"
    }

    /// Canonical grouped number for Unit's English workout copy. Keeping the
    /// decimal point and thousands separator stable avoids ambiguous evidence
    /// such as `1.800 kg·reps` when the device language is English but its
    /// region uses a comma decimal separator.
    static func groupedNumberDisplay(_ value: Double) -> String? {
        guard value.isFinite, value >= 0 else { return nil }
        return value.formatted(
            .number
                .locale(englishNumberLocale)
                .grouping(.automatic)
                .precision(.fractionLength(0...1))
        )
    }

    static func groupedCountDisplay(_ value: Int) -> String? {
        guard value >= 0 else { return nil }
        return value.formatted(
            .number
                .locale(englishNumberLocale)
                .grouping(.automatic)
        )
    }

    /// Canonical total-volume evidence (`1,800 kg·reps`). The supplied value
    /// remains kilograms internally and is converted exactly once for pounds.
    static func volumeDisplay(volumeKg: Double, unitSystem: String) -> String? {
        guard volumeKg.isFinite, volumeKg >= 0 else { return nil }
        let displayVolume = unitSystem == "lb" ? volumeKg * 2.20462 : volumeKg
        guard let number = groupedNumberDisplay(displayVolume) else { return nil }
        return "\(number) \(unitSystem)·reps"
    }

    /// One shared progression-configuration summary, e.g.
    /// `3 × 8–10 · +2.5 kg`.
    static func progressionConfigurationDisplay(
        setCount: Int,
        lowerRepBound: Int,
        upperRepBound: Int,
        weightIncrementKg: Double
    ) -> String? {
        guard let range = repRangeDisplay(
            setCount: setCount,
            lowerRepBound: lowerRepBound,
            upperRepBound: upperRepBound
        ), let increment = weightIncrementDisplay(weightIncrementKg) else {
            return nil
        }
        return "\(range) · \(increment)"
    }

    /// Canonical inline load: `setxrepxkg` when set count is known (`> 0`), else `kgxrep` or `BWxrep`.
    /// Weight wins when present — including on bodyweight exercises (e.g. weighted pull-ups).
    static func compactLoadText(sets: Int?, reps: Int?, weightKg: Double?, isBodyweight: Bool) -> String? {
        guard let reps, reps > 0 else { return nil }

        let setCount = sets ?? 0
        let w = weightKg ?? 0

        if w > 0 {
            if setCount > 0 {
                return "\(setCount)x\(reps)x\(weightCompact(w))"
            }
            return "\(weightCompact(w))x\(reps)"
        }

        guard isBodyweight else { return nil }

        if setCount > 0 {
            return "\(setCount)x\(reps)xBW"
        }
        return "BWx\(reps)"
    }

    /// Single logged set or ghost row: no set index, `kgxrep` / `BWxrep`.
    static func setMetricText(
        weightKg: Double,
        reps: Int,
        isBodyweight: Bool,
        bodyweightLabel: String = "BW"
    ) -> String? {
        _ = bodyweightLabel
        return compactLoadText(
            sets: nil,
            reps: reps,
            weightKg: weightKg,
            isBodyweight: isBodyweight || weightKg == 0
        )
    }

    /// Full session or planned target: `setxrepxkg` / `BW` token.
    static func performanceText(
        weightKg: Double,
        setCount: Int,
        reps: Int,
        isBodyweight: Bool,
        bodyweightLabel: String = "BW"
    ) -> String? {
        _ = bodyweightLabel
        return compactLoadText(sets: setCount, reps: reps, weightKg: weightKg, isBodyweight: isBodyweight)
    }

    /// Complete, sentence-friendly prescription for progression surfaces.
    /// Automatic progression requires external load, so every valid result
    /// includes both the amount and the user's preferred unit.
    static func completeTargetText(
        weightKg: Double,
        setCount: Int,
        reps: Int
    ) -> String? {
        guard weightKg.isFinite, weightKg > 0, setCount > 0, reps > 0 else {
            return nil
        }
        return "\(setCount) × \(reps) at \(weightDisplay(weightKg))"
    }

    /// Exact completed working-set evidence. Uniform work uses the same
    /// sentence shape as a prescription; varying reps or loads retain their
    /// real sequence instead of implying every set matched the final set.
    static func completedPerformanceText(
        weightsKg: [Double],
        reps: [Int],
        isBodyweight: Bool
    ) -> String? {
        guard !weightsKg.isEmpty,
              weightsKg.count == reps.count,
              weightsKg.allSatisfy({ $0.isFinite && $0 >= 0 }),
              reps.allSatisfy({ $0 > 0 }) else {
            return nil
        }

        let firstWeight = weightsKg[0]
        let firstReps = reps[0]
        let uniformWeight = weightsKg.allSatisfy {
            abs($0 - firstWeight) <= 0.000_1
        }
        let uniformReps = reps.allSatisfy { $0 == firstReps }

        if uniformWeight, uniformReps {
            if firstWeight > 0, isBodyweight {
                return "\(reps.count) × \(firstReps) at \(loadText(weightKg: firstWeight, isBodyweight: true, unitSystem: preferredUnit))"
            }
            if firstWeight > 0 {
                return completeTargetText(
                    weightKg: firstWeight,
                    setCount: reps.count,
                    reps: firstReps
                )
            }
            if isBodyweight {
                return "\(reps.count) × \(firstReps) at BW"
            }
            return nil
        }

        let repSequence = reps.map(String.init).joined(separator: "/")
        if uniformWeight {
            if firstWeight > 0 {
                return "\(loadText(weightKg: firstWeight, isBodyweight: isBodyweight, unitSystem: preferredUnit)) · \(repSequence) reps"
            }
            return isBodyweight ? "BW · \(repSequence) reps" : nil
        }

        let weightSequence = weightsKg.map { weightKg in
            loadText(weightKg: weightKg, isBodyweight: isBodyweight, unitSystem: preferredUnit)
        }.joined(separator: "/")
        return "\(weightSequence) · \(repSequence) reps"
    }

    static func volumeText(setCount: Int, reps: Int) -> String? {
        setRepCompact(setCount: setCount, reps: reps)
    }

    static func trustedTargetText(weightKg: Double, setCount: Int, reps: Int, isBodyweight: Bool) -> String? {
        performanceText(
            weightKg: weightKg,
            setCount: setCount,
            reps: reps,
            isBodyweight: isBodyweight,
            bodyweightLabel: "BW"
        )
    }

    static func actualText(weightKg: Double, setCount: Int, reps: Int, isBodyweight: Bool) -> String {
        performanceText(
            weightKg: weightKg,
            setCount: setCount,
            reps: reps,
            isBodyweight: isBodyweight || weightKg == 0
        ) ?? (reps > 0 ? "\(reps)" : "0")
    }

    static func lastText(weightKg: Double, setCount: Int, reps: Int, isBodyweight: Bool) -> String {
        "Last \(actualText(weightKg: weightKg, setCount: setCount, reps: reps, isBodyweight: isBodyweight))"
    }

    /// Sentence-friendly weight×rep token for the PR milestone caption (`145 kg × 8`, `BW × 12`).
    /// Intentionally distinct from `compactLoadText` (`145kgx8`): readability over chip density,
    /// since the milestone line gets one quiet beat of attention before fading.
    static func milestoneText(weightKg: Double, reps: Int, isBodyweight: Bool) -> String? {
        guard reps > 0, weightKg >= 0 else { return nil }
        return loggingSetText(weightKg: weightKg, reps: reps, isBodyweight: isBodyweight, unitSystem: preferredUnit)
    }
}
