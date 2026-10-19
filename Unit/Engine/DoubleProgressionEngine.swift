//
//  DoubleProgressionEngine.swift
//  Unit
//
//  Pure, deterministic double-progression calculation. No UI or persistence.
//

import Foundation

struct DoubleProgressionConfiguration: Codable, Equatable, Hashable, Sendable {
    let workingSetCount: Int
    let lowerRepBound: Int
    let upperRepBound: Int
    /// Canonical storage unit. UI converts pounds at the boundary.
    let weightIncrementKg: Double

    var isValid: Bool {
        workingSetCount > 0
            && lowerRepBound >= 1
            && upperRepBound >= lowerRepBound
            && weightIncrementKg.isFinite
            && weightIncrementKg > 0
    }
}

struct DoubleProgressionTarget: Codable, Equatable, Sendable {
    let weightKg: Double
    let reps: Int
}

enum DoubleProgressionReason: String, Codable, Equatable, Sendable {
    case allSetsReachedTop
    case addARep
    case repeatTarget
}

/// Persisted per routine/exercise. Values are absolute targets, so accepting
/// the same recommendation twice cannot apply an increment twice.
struct ExerciseProgressionState: Codable, Equatable, Sendable {
    let lowerRepBound: Int
    let upperRepBound: Int
    let weightIncrementKg: Double
    let currentAcceptedTargetWeightKg: Double?
    let currentAcceptedTargetReps: Int
    let sourceWorkoutSessionID: UUID?
    let lastAcceptedReason: DoubleProgressionReason?

    func configuration(workingSetCount: Int) -> DoubleProgressionConfiguration {
        DoubleProgressionConfiguration(
            workingSetCount: workingSetCount,
            lowerRepBound: lowerRepBound,
            upperRepBound: upperRepBound,
            weightIncrementKg: weightIncrementKg
        )
    }

    var acceptedTarget: DoubleProgressionTarget? {
        let configuration = configuration(workingSetCount: 1)
        guard configuration.isValid,
              sourceWorkoutSessionID != nil,
              let weightKg = currentAcceptedTargetWeightKg,
              weightKg.isFinite,
              weightKg > 0,
              currentAcceptedTargetReps >= lowerRepBound,
              currentAcceptedTargetReps <= upperRepBound else {
            return nil
        }
        return DoubleProgressionTarget(weightKg: weightKg, reps: currentAcceptedTargetReps)
    }
}

struct DoubleProgressionSet: Equatable, Sendable {
    let weightKg: Double
    let reps: Int
    let isWarmup: Bool
    let isCompleted: Bool
    let setIndex: Int
}

struct DoubleProgressionInput: Equatable, Sendable {
    let configuration: DoubleProgressionConfiguration
    let currentTargetReps: Int
    let sourceWorkoutSessionID: UUID
    let isBodyweightOnly: Bool
    let sets: [DoubleProgressionSet]
}

struct DoubleProgressionRecommendation: Equatable, Sendable {
    let target: DoubleProgressionTarget
    let reason: DoubleProgressionReason
    let sourceWorkoutSessionID: UUID
}

enum DoubleProgressionUnavailableReason: String, Codable, Equatable, Hashable, Sendable {
    case invalidConfiguration
    case invalidWeightIncrement
    case invalidTarget
    case incompleteWorkingSets
    case mixedWorkingSetWeights
    case invalidWorkingSetData
    case unsupportedBodyweightOnly
    case targetWeightOverflow
}

enum DoubleProgressionEvaluation: Equatable, Sendable {
    case recommendation(DoubleProgressionRecommendation)
    case unavailable(DoubleProgressionUnavailableReason)
}

enum DoubleProgressionEngine {
    private static let uniformLoadToleranceKg = 0.000_1

    static func evaluation(for input: DoubleProgressionInput) -> DoubleProgressionEvaluation {
        let configuration = input.configuration

        guard configuration.workingSetCount > 0,
              configuration.lowerRepBound >= 1,
              configuration.upperRepBound >= configuration.lowerRepBound else {
            return .unavailable(.invalidConfiguration)
        }

        guard configuration.weightIncrementKg.isFinite,
              configuration.weightIncrementKg > 0 else {
            return .unavailable(.invalidWeightIncrement)
        }

        guard input.currentTargetReps >= configuration.lowerRepBound,
              input.currentTargetReps <= configuration.upperRepBound else {
            return .unavailable(.invalidTarget)
        }

        guard !input.isBodyweightOnly else {
            return .unavailable(.unsupportedBodyweightOnly)
        }

        let nonWarmupSets = input.sets
            .filter { !$0.isWarmup }
            .sorted { $0.setIndex < $1.setIndex }
        let configuredSets = nonWarmupSets.prefix(configuration.workingSetCount)

        guard configuredSets.count == configuration.workingSetCount,
              configuredSets.allSatisfy(\.isCompleted) else {
            return .unavailable(.incompleteWorkingSets)
        }

        // Extra completed work is legitimate. It participates in the same
        // uniform-load/top-of-range check, while incomplete extra sets are not
        // evaluated and cannot block the configured working sets.
        let workingSets = nonWarmupSets.filter(\.isCompleted)

        guard let first = workingSets.first,
              workingSets.allSatisfy({ set in
                  set.weightKg.isFinite
                      && set.weightKg > 0
                      && set.reps > 0
              }) else {
            return .unavailable(.invalidWorkingSetData)
        }

        guard workingSets.allSatisfy({ set in
            abs(set.weightKg - first.weightKg) <= uniformLoadToleranceKg
        }) else {
            return .unavailable(.mixedWorkingSetWeights)
        }

        // A missed required target must never be rewarded with another rep.
        // Repeat the accepted target unchanged so the next step stays honest
        // and predictable. Extra work can affect the top-of-range outcome,
        // but only configured working sets determine whether today's target
        // was met.
        if configuredSets.contains(where: { $0.reps < input.currentTargetReps }) {
            return .recommendation(
                DoubleProgressionRecommendation(
                    target: DoubleProgressionTarget(
                        weightKg: first.weightKg,
                        reps: input.currentTargetReps
                    ),
                    reason: .repeatTarget,
                    sourceWorkoutSessionID: input.sourceWorkoutSessionID
                )
            )
        }

        let reachedTop = workingSets.allSatisfy {
            $0.reps >= configuration.upperRepBound
        }

        if reachedTop {
            let nextWeightKg = first.weightKg + configuration.weightIncrementKg
            guard nextWeightKg.isFinite else {
                return .unavailable(.targetWeightOverflow)
            }
            return .recommendation(
                DoubleProgressionRecommendation(
                    target: DoubleProgressionTarget(
                        weightKg: nextWeightKg,
                        reps: configuration.lowerRepBound
                    ),
                    reason: .allSetsReachedTop,
                    sourceWorkoutSessionID: input.sourceWorkoutSessionID
                )
            )
        }

        return .recommendation(
            DoubleProgressionRecommendation(
                target: DoubleProgressionTarget(
                    weightKg: first.weightKg,
                    reps: input.currentTargetReps < configuration.upperRepBound
                        ? input.currentTargetReps + 1
                        : configuration.upperRepBound
                ),
                reason: input.currentTargetReps < configuration.upperRepBound
                    ? .addARep
                    : .repeatTarget,
                sourceWorkoutSessionID: input.sourceWorkoutSessionID
            )
        )
    }

    static func recommendation(
        for input: DoubleProgressionInput
    ) -> DoubleProgressionRecommendation? {
        guard case .recommendation(let recommendation) = evaluation(for: input) else {
            return nil
        }
        return recommendation
    }

    /// Returns a new state containing the recommendation's absolute target.
    /// Reapplying the same recommendation is an idempotent overwrite.
    static func accepting(
        _ recommendation: DoubleProgressionRecommendation,
        into state: ExerciseProgressionState
    ) -> ExerciseProgressionState {
        ExerciseProgressionState(
            lowerRepBound: state.lowerRepBound,
            upperRepBound: state.upperRepBound,
            weightIncrementKg: state.weightIncrementKg,
            currentAcceptedTargetWeightKg: recommendation.target.weightKg,
            currentAcceptedTargetReps: recommendation.target.reps,
            sourceWorkoutSessionID: recommendation.sourceWorkoutSessionID,
            lastAcceptedReason: recommendation.reason
        )
    }
}
