import Foundation
import SwiftData

/// The only bridge from actor-confined SwiftData objects to pure Sendable values.
@MainActor
enum AnalyticsSnapshot {
    static func make(sessions: [WorkoutSession], exercises: [Exercise], templates: [DayTemplate], plannedDaysPerWeek: Int, pinnedMainIDs: [UUID] = []) -> AnalyticsEngine.Input {
        AnalyticsEngine.Input(
            exercises: exercises.map { .init(id: $0.id, name: $0.displayName, isBodyweight: $0.isBodyweight, equipment: Equipment(rawValue: $0.equipmentRaw).flatMap { $0 == .other ? nil : $0.rawValue }, muscleGroup: $0.muscleGroupRaw, aliases: $0.aliases) },
            sessions: sessions.filter(\.isCompleted).map { session in
                .init(id: session.id, date: session.date, templateID: session.templateId, sets: session.setEntries.filter(\.isValidCompletedWorkingSet).map {
                    .init(exerciseID: $0.exerciseId, weight: $0.weight, reps: $0.reps, index: $0.setIndex)
                })
            },
            templates: templates.map { template in
                .init(id: template.id, name: template.displayName, exerciseIDs: template.orderedExerciseIds,
                      targets: Dictionary(uniqueKeysWithValues: template.orderedExerciseIds.compactMap { id in
                    guard let target = template.progressionState(for: id)?.acceptedTarget else { return nil }
                    return (id, AnalyticsEngine.Target(weight: target.weightKg, reps: target.reps, templateName: template.displayName))
                }))
            },
            plannedDaysPerWeek: plannedDaysPerWeek,
            pinnedMainIDs: pinnedMainIDs
        )
    }
}
