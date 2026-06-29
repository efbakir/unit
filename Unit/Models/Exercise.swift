//
//  Exercise.swift
//  Unit
//
//  SwiftData model: exercise definition (display name, aliases, bodyweight flag,
//  muscle group, equipment).
//

import Foundation
import SwiftData

enum MuscleGroup: String, CaseIterable, Codable, Identifiable {
    case chest, back, shoulders, quads, hamstrings, glutes
    case biceps, triceps, core, calves, forearms, fullBody

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .chest: return "Chest"
        case .back: return "Back"
        case .shoulders: return "Shoulders"
        case .quads: return "Quads"
        case .hamstrings: return "Hamstrings"
        case .glutes: return "Glutes"
        case .biceps: return "Biceps"
        case .triceps: return "Triceps"
        case .core: return "Core"
        case .calves: return "Calves"
        case .forearms: return "Forearms"
        case .fullBody: return "Full Body"
        }
    }
}

enum Equipment: String, CaseIterable, Codable, Identifiable {
    case barbell, dumbbell, machine, cable, bodyweight, kettlebell, band, other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .barbell: return "Barbell"
        case .dumbbell: return "Dumbbell"
        case .machine: return "Machine"
        case .cable: return "Cable"
        case .bodyweight: return "Bodyweight"
        case .kettlebell: return "Kettlebell"
        case .band: return "Band"
        case .other: return "Other"
        }
    }
}

@Model
final class Exercise {
    var id: UUID
    var displayName: String
    var aliasesData: Data?
    var notes: String
    var isBodyweight: Bool
    /// Hidden from pickers after deletion while remaining available to resolve
    /// historical set names. Deleting the model would turn old sessions into
    /// anonymous "Exercise" rows because SetEntry stores only the UUID.
    var isArchived: Bool = false
    var muscleGroupRaw: String = MuscleGroup.fullBody.rawValue
    var equipmentRaw: String = Equipment.other.rawValue

    init(
        id: UUID = UUID(),
        displayName: String,
        aliases: [String] = [],
        notes: String = "",
        isBodyweight: Bool = false,
        isArchived: Bool = false,
        muscleGroup: MuscleGroup = .fullBody,
        equipment: Equipment = .other
    ) {
        self.id = id
        self.displayName = displayName
        self.aliasesData = (try? JSONEncoder().encode(aliases)) ?? nil
        self.notes = notes
        self.isBodyweight = isBodyweight
        self.isArchived = isArchived
        self.muscleGroupRaw = muscleGroup.rawValue
        self.equipmentRaw = equipment.rawValue
    }

    var aliases: [String] {
        get {
            guard let data = aliasesData,
                  let decoded = try? JSONDecoder().decode([String].self, from: data) else {
                return []
            }
            return decoded
        }
        set {
            aliasesData = try? JSONEncoder().encode(newValue)
        }
    }

    var muscleGroup: MuscleGroup {
        get { MuscleGroup(rawValue: muscleGroupRaw) ?? .fullBody }
        set { muscleGroupRaw = newValue.rawValue }
    }

    var equipment: Equipment {
        get { Equipment(rawValue: equipmentRaw) ?? .other }
        set { equipmentRaw = newValue.rawValue }
    }
}
