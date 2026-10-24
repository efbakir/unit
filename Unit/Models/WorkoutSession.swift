//
//  WorkoutSession.swift
//  Unit
//
//  SwiftData model: one instance of a template performed on a date.
//

import Foundation
import SwiftData

enum ProgressionDecisionAction: String, Codable, Equatable, Sendable {
    case usedSuggestion
    case repeatedPreviousTarget
    case edited
}

struct CompletedProgressionSet: Codable, Equatable, Sendable {
    let weightKg: Double
    let reps: Int
}

/// The evidence and user decision for one configured exercise in one session.
/// Keeping this on the completed session preserves the recommendation exactly
/// as it appeared, even after the routine's next target changes again.
struct SessionProgressionRecord: Codable, Equatable, Sendable {
    let exerciseID: UUID
    let exerciseName: String
    let isBodyweight: Bool
    let configuredSetCount: Int
    let lowerRepBound: Int
    let upperRepBound: Int
    let weightIncrementKg: Double
    let previousTarget: DoubleProgressionTarget?
    let completedSets: [CompletedProgressionSet]
    let suggestedTarget: DoubleProgressionTarget?
    let recommendationReason: DoubleProgressionReason?
    let unavailableReason: DoubleProgressionUnavailableReason?
    var acceptedTarget: DoubleProgressionTarget?
    var decisionAction: ProgressionDecisionAction?
}

@Model
final class WorkoutSession {
    var id: UUID
    var date: Date
    var templateId: UUID
    var isCompleted: Bool = false
    /// Optional/additive v2.1 evidence map. Existing stores migrate with nil,
    /// and sessions created before progression keep their original behavior.
    var progressionRecordsByExerciseIdData: Data?

    @Relationship(deleteRule: .cascade)
    var setEntries: [SetEntry] = []

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        templateId: UUID,
        isCompleted: Bool = false,
        progressionRecordsByExerciseId: [UUID: SessionProgressionRecord] = [:]
    ) {
        self.id = id
        self.date = date
        self.templateId = templateId
        self.isCompleted = isCompleted
        self.progressionRecordsByExerciseIdData = Self.encodeProgressionRecords(
            progressionRecordsByExerciseId
        )
    }

    var progressionRecordsByExerciseId: [UUID: SessionProgressionRecord] {
        get { Self.decodeProgressionRecords(progressionRecordsByExerciseIdData) }
        set {
            guard let encoded = Self.encodeProgressionRecords(newValue) else {
                return
            }
            progressionRecordsByExerciseIdData = encoded
        }
    }

    func progressionRecord(for exerciseID: UUID) -> SessionProgressionRecord? {
        progressionRecordsByExerciseId[exerciseID]
    }

    func setProgressionRecord(
        _ record: SessionProgressionRecord?,
        for exerciseID: UUID
    ) {
        var records = progressionRecordsByExerciseId
        if let record {
            records[exerciseID] = record
        } else {
            records.removeValue(forKey: exerciseID)
        }
        progressionRecordsByExerciseId = records
    }

    /// Stores one absolute user decision. Repeating the same action overwrites
    /// the same record with the same values, so it cannot apply a second step.
    @discardableResult
    func recordProgressionDecision(
        target: DoubleProgressionTarget,
        action: ProgressionDecisionAction,
        for exerciseID: UUID
    ) -> Bool {
        guard var record = progressionRecord(for: exerciseID),
              target.weightKg.isFinite,
              target.weightKg > 0,
              target.reps >= record.lowerRepBound,
              target.reps <= record.upperRepBound else {
            return false
        }
        record.acceptedTarget = target
        record.decisionAction = action
        setProgressionRecord(record, for: exerciseID)
        return true
    }

    /// The double-progression result for one exercise, calculated from this
    /// session's current sets. The finish-time capture and the live
    /// exercise-done preview both call this, so the target shown when an
    /// exercise is done is the same target the summary later offers.
    /// Returns nil when the routine has no progression rule for the exercise.
    @MainActor
    func progressionEvaluation(
        for exerciseID: UUID,
        template: DayTemplate,
        isBodyweight: Bool
    ) -> DoubleProgressionEvaluation? {
        guard let progressionState = template.progressionState(for: exerciseID) else {
            return nil
        }
        let exerciseEntries = setEntries
            .filter { $0.exerciseId == exerciseID }
            .sorted { $0.setIndex < $1.setIndex }
        let isBodyweightOnly = isBodyweight
            && !exerciseEntries.contains(where: { $0.isCompleted && !$0.isWarmup && $0.weight > 0 })
        return DoubleProgressionEngine.evaluation(
            for: DoubleProgressionInput(
                configuration: progressionState.configuration(
                    workingSetCount: template.plannedSets(for: exerciseID) ?? 0
                ),
                currentTargetReps: progressionState.currentAcceptedTargetReps,
                sourceWorkoutSessionID: id,
                isBodyweightOnly: isBodyweightOnly,
                sets: exerciseEntries.map {
                    DoubleProgressionSet(
                        weightKg: $0.weight,
                        reps: $0.reps,
                        isWarmup: $0.isWarmup,
                        isCompleted: $0.isCompleted,
                        setIndex: $0.setIndex
                    )
                }
            )
        )
    }

    /// Captures each configured exercise once, at the post-workout boundary.
    /// Re-running this method is intentionally a no-op for existing records so
    /// reopening a summary cannot recalculate or duplicate an earlier result.
    /// `onlyExerciseIDs` limits a recapture to exercises whose logged sets
    /// were corrected after Finish (Edit workout).
    @MainActor
    @discardableResult
    func captureProgressionRecords(
        template: DayTemplate,
        exercises: [Exercise],
        evaluatePendingRecommendations: Bool = true,
        onlyExerciseIDs: Set<UUID>? = nil
    ) -> Bool {
        var records = progressionRecordsByExerciseId
        var didChange = false

        for exerciseID in template.orderedExerciseIds
        where records[exerciseID] == nil && onlyExerciseIDs?.contains(exerciseID) != false {
            guard let progressionState = template.progressionState(for: exerciseID),
                  let exercise = exercises.first(where: { $0.id == exerciseID }) else {
                continue
            }

            let configuredSetCount = template.plannedSets(for: exerciseID) ?? 0
            let exerciseEntries = setEntries
                .filter { $0.exerciseId == exerciseID }
                .sorted { $0.setIndex < $1.setIndex }
            let completedWorkingSets = exerciseEntries.filter {
                $0.isCompleted && !$0.isWarmup
            }
            let previousWeightKg = progressionState.currentAcceptedTargetWeightKg
                .flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
                ?? completedWorkingSets.first.map(\.weight)
            let previousTarget: DoubleProgressionTarget?
            if let previousWeightKg,
               previousWeightKg.isFinite,
               previousWeightKg > 0 {
                previousTarget = DoubleProgressionTarget(
                    weightKg: previousWeightKg,
                    reps: progressionState.currentAcceptedTargetReps
                )
            } else {
                previousTarget = nil
            }
            let completedSetRecords: [CompletedProgressionSet] = completedWorkingSets.compactMap { set in
                guard set.weight.isFinite, set.weight >= 0, set.reps > 0 else {
                    return nil
                }
                return CompletedProgressionSet(
                    weightKg: set.weight,
                    reps: set.reps
                )
            }

            // Backfill sessions accepted by an earlier v2.1 build. Their
            // routine state already contains the decision, so replaying the
            // engine from that advanced target would invent a second step.
            if progressionState.sourceWorkoutSessionID == id,
               let acceptedTarget = progressionState.acceptedTarget,
               let acceptedReason = progressionState.lastAcceptedReason {
                records[exerciseID] = SessionProgressionRecord(
                    exerciseID: exerciseID,
                    exerciseName: exercise.displayName,
                    isBodyweight: exercise.isBodyweight,
                    configuredSetCount: configuredSetCount,
                    lowerRepBound: progressionState.lowerRepBound,
                    upperRepBound: progressionState.upperRepBound,
                    weightIncrementKg: progressionState.weightIncrementKg,
                    previousTarget: nil,
                    completedSets: completedSetRecords,
                    // The previous MVP persisted the accepted absolute target
                    // and reason, but not the original suggestion or whether
                    // the user edited it. Leave those unknowable facts blank.
                    suggestedTarget: nil,
                    recommendationReason: acceptedReason,
                    unavailableReason: nil,
                    acceptedTarget: acceptedTarget,
                    decisionAction: nil
                )
                didChange = true
                continue
            }

            guard evaluatePendingRecommendations,
                  let evaluation = progressionEvaluation(
                      for: exerciseID,
                      template: template,
                      isBodyweight: exercise.isBodyweight
                  ) else { continue }

            let suggestedTarget: DoubleProgressionTarget?
            let recommendationReason: DoubleProgressionReason?
            let unavailableReason: DoubleProgressionUnavailableReason?
            switch evaluation {
            case .recommendation(let recommendation):
                suggestedTarget = recommendation.target
                recommendationReason = recommendation.reason
                unavailableReason = nil
            case .unavailable(let reason):
                suggestedTarget = nil
                recommendationReason = nil
                unavailableReason = reason
            }

            records[exerciseID] = SessionProgressionRecord(
                exerciseID: exerciseID,
                exerciseName: exercise.displayName,
                isBodyweight: exercise.isBodyweight,
                configuredSetCount: configuredSetCount,
                lowerRepBound: progressionState.lowerRepBound,
                upperRepBound: progressionState.upperRepBound,
                weightIncrementKg: progressionState.weightIncrementKg,
                previousTarget: previousTarget,
                completedSets: completedSetRecords,
                suggestedTarget: suggestedTarget,
                recommendationReason: recommendationReason,
                unavailableReason: unavailableReason,
                acceptedTarget: nil,
                decisionAction: nil
            )
            didChange = true
        }

        if didChange {
            progressionRecordsByExerciseId = records
        }
        return didChange
    }

    private static func encodeProgressionRecords(
        _ records: [UUID: SessionProgressionRecord]
    ) -> Data? {
        let stringKeyed = Dictionary(
            uniqueKeysWithValues: records.map { ($0.key.uuidString, $0.value) }
        )
        return try? JSONEncoder().encode(stringKeyed)
    }

    private static func decodeProgressionRecords(
        _ data: Data?
    ) -> [UUID: SessionProgressionRecord] {
        guard let data,
              let decoded = try? JSONDecoder().decode(
                  [String: SessionProgressionRecord].self,
                  from: data
              ) else {
            return [:]
        }
        return Dictionary(
            uniqueKeysWithValues: decoded.compactMap { key, value in
                guard let id = UUID(uuidString: key) else { return nil }
                return (id, value)
            }
        )
    }
}
