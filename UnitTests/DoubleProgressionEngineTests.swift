import XCTest
@testable import Unit

@MainActor
final class DoubleProgressionEngineTests: XCTestCase {
    private let sessionID = UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!

    func testAllWorkingSetsAtTopMovesToNextWeightAndLowerBound() {
        let result = recommendation(reps: [10, 10, 10])

        XCTAssertEqual(result?.target.weightKg ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 8)
        XCTAssertEqual(result?.reason, .allSetsReachedTop)
    }

    func testMixedRepsKeepsWeightAndAddsOneTargetRep() {
        let result = recommendation(reps: [10, 9, 8])

        XCTAssertEqual(result?.target.weightKg ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 9)
        XCTAssertEqual(result?.reason, .addARep)
    }

    func testMissedRequiredTargetRepeatsSameWeightAndReps() {
        let result = recommendation(reps: [9, 8, 7], currentTargetReps: 8)

        XCTAssertEqual(result?.target.weightKg ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 8)
        XCTAssertEqual(result?.reason, .repeatTarget)
    }

    func testOneMissAmongOtherwiseTopSetsStillRepeatsTarget() {
        let result = recommendation(reps: [10, 10, 8], currentTargetReps: 9)

        XCTAssertEqual(result?.target.weightKg ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 9)
        XCTAssertEqual(result?.reason, .repeatTarget)
    }

    func testTargetAtUpperBoundRepeatsWhenAnySetMisses() {
        let result = recommendation(reps: [10, 9, 8], currentTargetReps: 10)

        XCTAssertEqual(result?.target.reps, 10)
        XCTAssertEqual(result?.reason, .repeatTarget)
    }

    func testExtraBelowCeilingSetDoesNotPromiseAnUnchangedRepIncrease() {
        let result = recommendation(reps: [10, 10, 10, 9], currentTargetReps: 10)
        XCTAssertEqual(result?.target.weightKg, 60)
        XCTAssertEqual(result?.target.reps, 10)
        XCTAssertEqual(result?.reason, .repeatTarget)
    }

    func testPartialCompletionProducesNoRecommendation() {
        let input = input(reps: [10, 10])

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.incompleteWorkingSets)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testIncompleteWorkingSetDoesNotSatisfyRequiredCount() {
        let input = makeInput(
            sets: [
                set(reps: 10, index: 0),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2, isCompleted: false)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.incompleteWorkingSets)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testMixedWorkingSetLoadsProduceNoRecommendation() {
        let input = makeInput(
            sets: [
                set(weightKg: 60, reps: 10, index: 0),
                set(weightKg: 62.5, reps: 10, index: 1),
                set(weightKg: 60, reps: 10, index: 2)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.mixedWorkingSetWeights)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testWarmupsDoNotAffectProgression() {
        let input = makeInput(
            sets: [
                set(weightKg: 20, reps: 5, index: 0, isWarmup: true),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2),
                set(reps: 10, index: 3)
            ]
        )

        let result = DoubleProgressionEngine.recommendation(for: input)
        XCTAssertEqual(result?.target.weightKg ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 8)
    }

    func testOnlyWarmupsProduceNoRecommendation() {
        let input = makeInput(
            sets: [
                set(weightKg: 20, reps: 10, index: 0, isWarmup: true),
                set(weightKg: 30, reps: 10, index: 1, isWarmup: true),
                set(weightKg: 40, reps: 10, index: 2, isWarmup: true)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.incompleteWorkingSets)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testBodyweightOnlyExerciseProducesNoRecommendation() {
        let input = makeInput(
            isBodyweightOnly: true,
            sets: [
                set(weightKg: 0, reps: 10, index: 0),
                set(weightKg: 0, reps: 10, index: 1),
                set(weightKg: 0, reps: 10, index: 2)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.unsupportedBodyweightOnly)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testBodyweightExerciseWithExternalLoadCanProgress() {
        let input = makeInput(
            isBodyweightOnly: false,
            sets: [
                set(weightKg: 10, reps: 10, index: 0),
                set(weightKg: 10, reps: 10, index: 1),
                set(weightKg: 10, reps: 10, index: 2)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.recommendation(for: input)?.target.weightKg ?? -1,
            12.5,
            accuracy: 0.000_001
        )
    }

    func testZeroLoadProducesNoRecommendation() {
        let input = input(reps: [10, 10, 10], weightKg: 0)

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.invalidWorkingSetData)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testInvalidStructuralConfigurationsAreUnavailable() {
        let invalidConfigurations = [
            DoubleProgressionConfiguration(
                workingSetCount: 0,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: 2.5
            ),
            DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 0,
                upperRepBound: 10,
                weightIncrementKg: 2.5
            ),
            DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 10,
                upperRepBound: 8,
                weightIncrementKg: 2.5
            ),
            DoubleProgressionConfiguration(
                workingSetCount: -1,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: 2.5
            )
        ]

        for configuration in invalidConfigurations {
            let input = makeInput(
                configuration: configuration,
                sets: [
                    set(reps: 10, index: 0),
                    set(reps: 10, index: 1),
                    set(reps: 10, index: 2)
                ]
            )
            XCTAssertEqual(
                DoubleProgressionEngine.evaluation(for: input),
                .unavailable(.invalidConfiguration)
            )
            XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
        }
    }

    func testInvalidWeightIncrementsAreUnavailable() {
        let invalidIncrements: [Double] = [0, -2.5, .infinity, .nan]

        for weightIncrementKg in invalidIncrements {
            let configuration = DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: weightIncrementKg
            )
            let input = makeInput(
                configuration: configuration,
                sets: [
                    set(reps: 10, index: 0),
                    set(reps: 10, index: 1),
                    set(reps: 10, index: 2)
                ]
            )

            XCTAssertEqual(
                DoubleProgressionEngine.evaluation(for: input),
                .unavailable(.invalidWeightIncrement)
            )
            XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
        }
    }

    func testInvalidWorkingSetDataIsUnavailable() {
        let invalidSets = [
            [
                set(weightKg: 0, reps: 10, index: 0),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2)
            ],
            [
                set(weightKg: .infinity, reps: 10, index: 0),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2)
            ],
            [
                set(reps: 0, index: 0),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2)
            ]
        ]

        for sets in invalidSets {
            let input = makeInput(sets: sets)
            XCTAssertEqual(
                DoubleProgressionEngine.evaluation(for: input),
                .unavailable(.invalidWorkingSetData)
            )
            XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
        }
    }

    func testInvalidTargetIsUnavailable() {
        for currentTargetReps in [7, 11] {
            let input = input(
                reps: [10, 9, 8],
                currentTargetReps: currentTargetReps
            )

            XCTAssertEqual(
                DoubleProgressionEngine.evaluation(for: input),
                .unavailable(.invalidTarget)
            )
            XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
        }
    }

    func testUnavailableReasonRoundTripsThroughCodable() throws {
        let reason = DoubleProgressionUnavailableReason.mixedWorkingSetWeights
        let encoded = try JSONEncoder().encode(reason)

        XCTAssertEqual(
            try JSONDecoder().decode(DoubleProgressionUnavailableReason.self, from: encoded),
            reason
        )
    }

    func testConfigurationValidityStillRejectsInvalidIncrement() {
        let invalidConfigurations = [
            DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: -2.5
            ),
            DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: .infinity
            ),
            DoubleProgressionConfiguration(
                workingSetCount: 3,
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: .nan
            )
        ]

        for configuration in invalidConfigurations {
            XCTAssertFalse(configuration.isValid)
        }
    }

    func testTargetOutsideConfiguredRangeIsInvalid() {
        XCTAssertNil(recommendation(reps: [10, 9, 8], currentTargetReps: 7))
        XCTAssertNil(recommendation(reps: [10, 9, 8], currentTargetReps: 11))
    }

    func testExtraCompletedWorkingSetAtTopParticipatesAndCanProgress() {
        let result = recommendation(reps: [10, 10, 10, 10])

        XCTAssertEqual(result?.target.weightKg ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 8)
    }

    func testExtraCompletedWorkingSetBelowTopKeepsWeight() {
        let result = recommendation(reps: [10, 10, 10, 9])

        XCTAssertEqual(result?.target.weightKg ?? -1, 60, accuracy: 0.000_001)
        XCTAssertEqual(result?.target.reps, 9)
    }

    func testIncompleteConfiguredSetCannotBeReplacedByCompletedExtraSet() {
        let input = makeInput(
            sets: [
                set(reps: 10, index: 0),
                set(reps: 10, index: 1),
                set(reps: 10, index: 2, isCompleted: false),
                set(reps: 10, index: 3)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.incompleteWorkingSets)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testWeightOverflowProducesNoRecommendation() {
        let configuration = DoubleProgressionConfiguration(
            workingSetCount: 3,
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: .greatestFiniteMagnitude
        )
        let input = makeInput(
            configuration: configuration,
            sets: [
                set(weightKg: .greatestFiniteMagnitude, reps: 10, index: 0),
                set(weightKg: .greatestFiniteMagnitude, reps: 10, index: 1),
                set(weightKg: .greatestFiniteMagnitude, reps: 10, index: 2)
            ]
        )

        XCTAssertEqual(
            DoubleProgressionEngine.evaluation(for: input),
            .unavailable(.targetWeightOverflow)
        )
        XCTAssertNil(DoubleProgressionEngine.recommendation(for: input))
    }

    func testRepTargetAtIntegerMaximumDoesNotOverflow() {
        let configuration = DoubleProgressionConfiguration(
            workingSetCount: 3,
            lowerRepBound: Int.max - 1,
            upperRepBound: Int.max,
            weightIncrementKg: 2.5
        )
        let input = makeInput(
            configuration: configuration,
            currentTargetReps: Int.max,
            sets: [
                set(reps: Int.max - 1, index: 0),
                set(reps: Int.max - 1, index: 1),
                set(reps: Int.max - 1, index: 2)
            ]
        )

        XCTAssertEqual(DoubleProgressionEngine.recommendation(for: input)?.target.reps, Int.max)
    }

    func testSemanticallyInvalidAcceptedStateIsInert() {
        let invalidStates = [
            ExerciseProgressionState(
                lowerRepBound: 0,
                upperRepBound: 10,
                weightIncrementKg: 2.5,
                currentAcceptedTargetWeightKg: 60,
                currentAcceptedTargetReps: 8,
                sourceWorkoutSessionID: sessionID,
                lastAcceptedReason: .addARep
            ),
            ExerciseProgressionState(
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: 2.5,
                currentAcceptedTargetWeightKg: 60,
                currentAcceptedTargetReps: 11,
                sourceWorkoutSessionID: sessionID,
                lastAcceptedReason: .addARep
            ),
            ExerciseProgressionState(
                lowerRepBound: 8,
                upperRepBound: 10,
                weightIncrementKg: -.infinity,
                currentAcceptedTargetWeightKg: 60,
                currentAcceptedTargetReps: 8,
                sourceWorkoutSessionID: sessionID,
                lastAcceptedReason: .addARep
            )
        ]

        for state in invalidStates {
            XCTAssertNil(state.acceptedTarget)
        }
    }

    func testAcceptingSameRecommendationTwiceDoesNotCompoundWeight() throws {
        let recommendation = try XCTUnwrap(recommendation(reps: [10, 10, 10]))
        let initial = progressionState()

        let acceptedOnce = DoubleProgressionEngine.accepting(recommendation, into: initial)
        let acceptedTwice = DoubleProgressionEngine.accepting(recommendation, into: acceptedOnce)

        XCTAssertEqual(acceptedOnce, acceptedTwice)
        XCTAssertEqual(acceptedTwice.currentAcceptedTargetWeightKg ?? -1, 62.5, accuracy: 0.000_001)
        XCTAssertNotEqual(acceptedTwice.currentAcceptedTargetWeightKg, 65)
        XCTAssertEqual(acceptedTwice.sourceWorkoutSessionID, sessionID)
    }

    func testEditedAbsoluteTargetPersistsExactlyThroughAcceptance() {
        let edited = DoubleProgressionRecommendation(
            target: DoubleProgressionTarget(weightKg: 61.25, reps: 9),
            reason: .addARep,
            sourceWorkoutSessionID: sessionID
        )

        let accepted = DoubleProgressionEngine.accepting(edited, into: progressionState())

        XCTAssertEqual(accepted.currentAcceptedTargetWeightKg ?? -1, 61.25, accuracy: 0.000_001)
        XCTAssertEqual(accepted.currentAcceptedTargetReps, 9)
    }

    func testFivePoundIncrementIsStoredAndAppliedInKilograms() {
        let fivePoundsInKg = 5 / 2.20462
        let configuration = DoubleProgressionConfiguration(
            workingSetCount: 3,
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: fivePoundsInKg
        )
        let input = makeInput(
            configuration: configuration,
            sets: [
                set(weightKg: 60, reps: 10, index: 0),
                set(weightKg: 60, reps: 10, index: 1),
                set(weightKg: 60, reps: 10, index: 2)
            ]
        )

        let result = DoubleProgressionEngine.recommendation(for: input)
        XCTAssertEqual(configuration.weightIncrementKg, fivePoundsInKg, accuracy: 0.000_000_1)
        XCTAssertEqual(result?.target.weightKg ?? -1, 60 + fivePoundsInKg, accuracy: 0.000_000_1)
        XCTAssertEqual((result?.target.weightKg ?? 0) * 2.20462, 60 * 2.20462 + 5, accuracy: 0.000_001)
    }

    private func recommendation(
        reps: [Int],
        weightKg: Double = 60,
        currentTargetReps: Int = 8
    ) -> DoubleProgressionRecommendation? {
        DoubleProgressionEngine.recommendation(
            for: input(
                reps: reps,
                weightKg: weightKg,
                currentTargetReps: currentTargetReps
            )
        )
    }

    private func input(
        reps: [Int],
        weightKg: Double = 60,
        currentTargetReps: Int = 8
    ) -> DoubleProgressionInput {
        makeInput(
            currentTargetReps: currentTargetReps,
            sets: reps.enumerated().map { index, reps in
                set(weightKg: weightKg, reps: reps, index: index)
            }
        )
    }

    private func makeInput(
        configuration: DoubleProgressionConfiguration = DoubleProgressionConfiguration(
            workingSetCount: 3,
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: 2.5
        ),
        currentTargetReps: Int = 8,
        isBodyweightOnly: Bool = false,
        sets: [DoubleProgressionSet]
    ) -> DoubleProgressionInput {
        DoubleProgressionInput(
            configuration: configuration,
            currentTargetReps: currentTargetReps,
            sourceWorkoutSessionID: sessionID,
            isBodyweightOnly: isBodyweightOnly,
            sets: sets
        )
    }

    private func set(
        weightKg: Double = 60,
        reps: Int,
        index: Int,
        isWarmup: Bool = false,
        isCompleted: Bool = true
    ) -> DoubleProgressionSet {
        DoubleProgressionSet(
            weightKg: weightKg,
            reps: reps,
            isWarmup: isWarmup,
            isCompleted: isCompleted,
            setIndex: index
        )
    }

    private func progressionState() -> ExerciseProgressionState {
        ExerciseProgressionState(
            lowerRepBound: 8,
            upperRepBound: 10,
            weightIncrementKg: 2.5,
            currentAcceptedTargetWeightKg: 60,
            currentAcceptedTargetReps: 8,
            sourceWorkoutSessionID: nil,
            lastAcceptedReason: nil
        )
    }
}
