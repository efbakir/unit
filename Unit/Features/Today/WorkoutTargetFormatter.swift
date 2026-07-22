//
//  WorkoutTargetFormatter.swift
//  Unit
//
//  Shared target/result formatting for workout surfaces.
//

import Foundation

enum WorkoutTargetFormatter {

    /// Format a weight value with the user's preferred unit label (spaced, for labels and sentences).
    static func weightDisplay(_ kg: Double) -> String {
        let unit = UserDefaults.standard.string(forKey: "unitSystem") ?? "kg"
        if unit == "lb" {
            let lb = kg * 2.20462
            return "\(lb.weightString) lb"
        }
        return "\(kg.weightString) kg"
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
        guard reps > 0 else { return nil }
        if weightKg > 0 {
            return "\(weightDisplay(weightKg)) × \(reps)"
        }
        if isBodyweight || weightKg == 0 {
            return "BW × \(reps)"
        }
        return nil
    }
}
