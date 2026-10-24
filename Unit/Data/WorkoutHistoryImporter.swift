//
//  WorkoutHistoryImporter.swift
//  Unit
//
//  Writes a parsed Strong or Hevy history into SwiftData as finished
//  workouts, and undoes the last import. Imported workouts feed History,
//  PR tags, "Last time", the exercise pages and Analytics like any other
//  finished workout. They never change Programs, Today or the rotation:
//  each workout title gets a hidden routine, the same way Freestyle does.
//

import Foundation
import SwiftData

/// What the preview shows before anything is saved.
struct WorkoutHistoryImportPlan: Equatable {
    let source: WorkoutHistorySource
    let needsWeightUnit: Bool
    /// Workouts not yet in Unit, oldest first.
    let workouts: [ImportedWorkout]
    /// Workouts that start in the same minute as one already in Unit.
    let duplicateCount: Int
    let skippedRowCount: Int
    let matchedExerciseNames: [String]
    let newExerciseNames: [String]

    var setCount: Int { workouts.reduce(0) { $0 + $1.setCount } }
    var firstDate: Date? { workouts.first?.date }
    var lastDate: Date? { workouts.last?.date }
}

/// Everything one import added, so it can be undone.
struct WorkoutHistoryImportBatch: Codable, Equatable {
    let date: Date
    let source: String
    let sessionIDs: [UUID]
    let templateIDs: [UUID]
    let exerciseIDs: [UUID]

    var workoutCount: Int { sessionIDs.count }
}

enum WorkoutHistoryImporter {
    static let lastBatchKey = "unit.import.lastBatch"

    // MARK: - Preview

    static func plan(
        for file: WorkoutHistoryFile,
        existingSessions: [WorkoutSession],
        exercises: [Exercise]
    ) -> WorkoutHistoryImportPlan {
        let existingMinutes = Set(existingSessions.map { minute($0.date) })
        var seenMinutes = Set<Int>()
        var newWorkouts: [ImportedWorkout] = []
        for workout in file.workouts {
            let key = minute(workout.date)
            guard !existingMinutes.contains(key), seenMinutes.insert(key).inserted else { continue }
            newWorkouts.append(workout)
        }

        let resolver = ExerciseResolver(exercises: exercises)
        var matched: [String] = []
        var new: [String] = []
        var seenNames = Set<String>()
        for workout in newWorkouts {
            for exercise in workout.exercises where seenNames.insert(ExerciseCatalog.normalize(exercise.name)).inserted {
                if resolver.existing(named: exercise.name) != nil {
                    matched.append(exercise.name)
                } else {
                    new.append(exercise.name)
                }
            }
        }
        return WorkoutHistoryImportPlan(
            source: file.source,
            needsWeightUnit: file.needsWeightUnit,
            workouts: newWorkouts,
            duplicateCount: file.workouts.count - newWorkouts.count,
            skippedRowCount: file.skippedRowCount,
            matchedExerciseNames: matched,
            newExerciseNames: new
        )
    }

    // MARK: - Import

    /// Inserts every workout in the plan and saves once. Throws (with
    /// nothing changed) when the save fails.
    @discardableResult
    static func importHistory(
        _ plan: WorkoutHistoryImportPlan,
        weightUnit: ImportWeightUnit,
        into context: ModelContext,
        defaults: UserDefaults = .standard,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws -> WorkoutHistoryImportBatch {
        let existingExercises = try context.fetch(FetchDescriptor<Exercise>())
        var resolver = ExerciseResolver(exercises: existingExercises)
        var templatesByTitle: [String: DayTemplate] = [:]
        var templateIDs: [UUID] = []
        var sessionIDs: [UUID] = []

        for workout in plan.workouts {
            let title = workout.title.trimmingCharacters(in: .whitespacesAndNewlines)
            let routineName = title.isEmpty ? "Workout" : title
            let template: DayTemplate
            if let existing = templatesByTitle[routineName] {
                template = existing
            } else {
                // No program: hidden from Programs and Today, like Freestyle.
                template = DayTemplate(name: routineName, splitId: nil)
                context.insert(template)
                templatesByTitle[routineName] = template
                templateIDs.append(template.id)
            }

            let session = WorkoutSession(date: workout.date, templateId: template.id, isCompleted: true)
            context.insert(session)
            sessionIDs.append(session.id)

            var routineOrder = template.orderedExerciseIds
            for importedExercise in workout.exercises {
                let exercise = resolver.resolve(importedExercise.name, in: context)
                if !routineOrder.contains(exercise.id) { routineOrder.append(exercise.id) }
                for (index, set) in importedExercise.sets.enumerated() {
                    let entry = SetEntry(
                        sessionId: session.id,
                        exerciseId: exercise.id,
                        weight: set.weightKg(assuming: weightUnit),
                        reps: set.reps,
                        rpe: set.rpe,
                        isWarmup: set.isWarmup,
                        isCompleted: true,
                        setIndex: index,
                        note: set.note
                    )
                    entry.session = session
                    context.insert(entry)
                }
            }
            if routineOrder != template.orderedExerciseIds {
                template.orderedExerciseIds = routineOrder
            }
        }

        do {
            try save(context)
        } catch {
            context.rollbackRestoringLoadedModels()
            throw error
        }
        let batch = WorkoutHistoryImportBatch(
            date: Date(),
            source: plan.source.rawValue,
            sessionIDs: sessionIDs,
            templateIDs: templateIDs,
            exerciseIDs: resolver.createdIDs
        )
        if let data = try? JSONEncoder().encode(batch) {
            defaults.set(data, forKey: lastBatchKey)
        }
        return batch
    }

    // MARK: - Undo

    static func lastBatch(defaults: UserDefaults = .standard) -> WorkoutHistoryImportBatch? {
        defaults.data(forKey: lastBatchKey).flatMap { try? JSONDecoder().decode(WorkoutHistoryImportBatch.self, from: $0) }
    }

    /// Removes what the last import added. Workouts logged in Unit stay, and
    /// an exercise the import created stays when other work uses it.
    static func undo(
        _ batch: WorkoutHistoryImportBatch,
        in context: ModelContext,
        defaults: UserDefaults = .standard,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let sessionIDs = batch.sessionIDs
        let importedSessions = try context.fetch(FetchDescriptor<WorkoutSession>(
            predicate: #Predicate { sessionIDs.contains($0.id) }
        ))
        importedSessions.forEach(context.delete)

        let remainingSessions = try context.fetch(FetchDescriptor<WorkoutSession>())
            .filter { !sessionIDs.contains($0.id) }
        let referencedTemplateIDs = Set(remainingSessions.map(\.templateId))
        let templateIDs = batch.templateIDs
        let importedTemplates = try context.fetch(FetchDescriptor<DayTemplate>(
            predicate: #Predicate { templateIDs.contains($0.id) }
        ))
        for template in importedTemplates where !referencedTemplateIDs.contains(template.id) {
            context.delete(template)
        }

        let usedExerciseIDs = Set(remainingSessions.flatMap { $0.setEntries.map(\.exerciseId) })
        let listedExerciseIDs = Set(
            try context.fetch(FetchDescriptor<DayTemplate>())
                .filter { !templateIDs.contains($0.id) }
                .flatMap(\.orderedExerciseIds)
        )
        let exerciseIDs = batch.exerciseIDs
        let createdExercises = try context.fetch(FetchDescriptor<Exercise>(
            predicate: #Predicate { exerciseIDs.contains($0.id) }
        ))
        for exercise in createdExercises
        where !usedExerciseIDs.contains(exercise.id) && !listedExerciseIDs.contains(exercise.id) {
            context.delete(exercise)
        }

        do {
            try save(context)
        } catch {
            context.rollbackRestoringLoadedModels()
            throw error
        }
        defaults.removeObject(forKey: lastBatchKey)
    }

    private static func minute(_ date: Date) -> Int {
        Int((date.timeIntervalSince1970 / 60).rounded(.down))
    }
}

/// Finds the Unit exercise for an imported name: one of yours (name or
/// alias), then Unit's catalog (which knows the Strong and Hevy names of its
/// lifts). Anything else becomes a new exercise with its original name. No
/// fuzzy guessing, so dumbbell and barbell work never merge.
private struct ExerciseResolver {
    private var bySignature: [String: Exercise] = [:]
    private(set) var createdIDs: [UUID] = []

    init(exercises: [Exercise]) {
        for exercise in exercises {
            for signature in [exercise.displayName] + exercise.aliases {
                let key = ExerciseCatalog.normalize(signature)
                if bySignature[key] == nil { bySignature[key] = exercise }
            }
        }
    }

    func existing(named name: String) -> Exercise? {
        if let exercise = bySignature[ExerciseCatalog.normalize(name)] { return exercise }
        guard let entry = ExerciseCatalog.lookup(name) else { return nil }
        for signature in [entry.displayName] + entry.aliases {
            if let exercise = bySignature[ExerciseCatalog.normalize(signature)] { return exercise }
        }
        return nil
    }

    mutating func resolve(_ name: String, in context: ModelContext) -> Exercise {
        if let exercise = existing(named: name) {
            // Remember the imported spelling, so later workouts skip the catalog search.
            bySignature[ExerciseCatalog.normalize(name)] = exercise
            return exercise
        }
        let exercise: Exercise
        if let entry = ExerciseCatalog.lookup(name) {
            exercise = Exercise(
                displayName: entry.displayName,
                aliases: entry.aliases,
                isBodyweight: entry.isBodyweight,
                muscleGroup: entry.muscleGroup,
                equipment: entry.equipment
            )
        } else {
            exercise = Exercise(displayName: name)
        }
        context.insert(exercise)
        createdIDs.append(exercise.id)
        for signature in [exercise.displayName, name] + exercise.aliases {
            bySignature[ExerciseCatalog.normalize(signature)] = exercise
        }
        return exercise
    }
}
