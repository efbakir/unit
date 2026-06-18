//
//  ProgramTemplate.swift
//  Unit
//
//  Value types describing a pre-built program that can be imported into the
//  user's library (Split + DayTemplates + Exercises). These are static
//  catalog data — not SwiftData models.
//

import Foundation

struct ProgramTemplate: Identifiable, Hashable {
    enum Level: String, CaseIterable, Identifiable {
        case beginner, intermediate, advanced
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .beginner: return "Beginner"
            case .intermediate: return "Intermediate"
            case .advanced: return "Advanced"
            }
        }
    }

    enum Goal: String, CaseIterable, Identifiable {
        case strength, hypertrophy, mixed
        var id: String { rawValue }
        var displayName: String {
            switch self {
            case .strength: return "Strength"
            case .hypertrophy: return "Hypertrophy"
            case .mixed: return "Mixed"
            }
        }
    }

    let id: UUID
    let name: String
    let level: Level
    let goal: Goal
    let daysPerWeek: Int
    let summary: String
    let description: String
    let days: [ProgramDay]
}

struct ProgramDay: Identifiable, Hashable {
    let id: UUID
    let name: String
    /// 1–7 (Sun–Sat); optional — omit for non-calendar-bound programs.
    let weekday: Int?
    let items: [ProgramItem]
}

struct ProgramItem: Identifiable, Hashable {
    let id: UUID
    let exerciseName: String
    let setCount: Int
    let repTarget: Int
    let notes: String?
    /// Which compound 1RM the user-supplied starting weight is derived from.
    /// `nil` for accessories (lateral raise, curl) where no canonical 1RM
    /// mapping exists — those exercises start with a blank weight per Q4.
    let oneRepMaxLift: OneRepMaxLift?
    /// Fraction of the user's 1RM (for `oneRepMaxLift`) that the program
    /// prescribes as the starting weight. `0.65` means 65%. Combined at
    /// import time: `startingWeight = floor(userOneRM * pct, plate: 2.5kg)`.
    /// `nil` when the program doesn't have a canonical starting prescription
    /// for the exercise (accessories, or programs where the user fills first).
    let startingWeightPct: Double?

    init(
        id: UUID = UUID(),
        exerciseName: String,
        setCount: Int,
        repTarget: Int,
        notes: String? = nil,
        oneRepMaxLift: OneRepMaxLift? = nil,
        startingWeightPct: Double? = nil
    ) {
        self.id = id
        self.exerciseName = exerciseName
        self.setCount = setCount
        self.repTarget = repTarget
        self.notes = notes
        self.oneRepMaxLift = oneRepMaxLift
        self.startingWeightPct = startingWeightPct
    }
}

/// The four compound lifts whose 1RM users may enter during onboarding's
/// program-pick flow. Each surfaced library program's main lifts reference
/// one of these via `ProgramItem.oneRepMaxLift`. Accessories use `nil`.
enum OneRepMaxLift: String, CaseIterable, Identifiable, Hashable {
    case bench
    case squat
    case deadlift
    case ohp

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bench: return "Bench"
        case .squat: return "Squat"
        case .deadlift: return "Deadlift"
        case .ohp: return "OHP"
        }
    }
}
