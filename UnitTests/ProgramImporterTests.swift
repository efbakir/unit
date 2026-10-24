//
//  ProgramImporterTests.swift
//  UnitTests
//
//  Coverage for ProgramImporter's 1RM-derived starting weight math (per Q7
//  of the 2026-06-17 onboarding-redesign grilling). Each surfaced library
//  program has a canonical starting % published by its creator; this file
//  verifies the math for each, plus the plate-rounding helper, plus the
//  regression case where `oneRMs: nil` produces the same output as before.
//
//  Tests are pure-Swift (no SwiftData ModelContext), driven against
//  `ProgramImporter.startingWeight(for:oneRMs:)` and
//  `ProgramImporter.floorToPlate(_:grain:)` directly. The integration
//  layer (importProgram(_:into:oneRMs:) writing into a DayTemplate) is
//  exercised manually at check-in 4 via the simulator walkthrough.
//
//  Run via `xcodebuild test` or Xcode's ⌘U.
//

import XCTest
import SwiftData
@testable import Unit

/// Swift 6 strict concurrency: `ProgramItem`, `ProgramImporter`,
/// `ProgramCatalog` and friends are `@MainActor`-isolated. The whole test
/// class runs on MainActor so callers don't need per-method `await`.
@MainActor
final class ProgramImporterTests: XCTestCase {
    func testPastedUnitsDecideThePlainNumberUnit() {
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Bench 3x8 135 lbs\nRow 3x10 95", current: "kg"),
            "lb"
        )
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Squat 5x5 100kg", current: "lb"),
            "kg"
        )
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Deadlift 1x5 315#", current: "kg"),
            "lb"
        )
        // Unit-free or mixed text keeps the region guess.
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Bench press 4x8 60", current: "lb"),
            "lb"
        )
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Bench 60kg\nCurl 25 lb", current: "kg"),
            "kg"
        )
        // Words that merely contain the letters never count as units.
        XCTAssertEqual(
            OnboardingViewModel.inferredUnitSystem(from: "Kettlebell swing 3x15", current: "kg"),
            "kg"
        )
    }

    func testLegacyDraftOnRetiredStepsResumesOnTheirReplacement() {
        let suiteName = "OnboardingDraftMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defer { defaults.removePersistentDomain(forName: suiteName) }

        defaults.set("unitPicker", forKey: OnboardingPreferencesKeys.currentStep)
        defaults.set(["splash"], forKey: OnboardingPreferencesKeys.stepHistory)
        XCTAssertEqual(OnboardingPreferences.loadNavigation(defaults: defaults).step, .importMethod)

        defaults.set("schedule", forKey: OnboardingPreferencesKeys.currentStep)
        defaults.set(["splash", "unitPicker", "importMethod", "programImport"],
                     forKey: OnboardingPreferencesKeys.stepHistory)
        let navigation = OnboardingPreferences.loadNavigation(defaults: defaults)
        XCTAssertEqual(navigation.step, .exercises)
        XCTAssertEqual(navigation.history, [.splash, .importMethod, .programImport])
    }

    func testPickedCatalogProgramKeepsCatalogName() {
        guard let program = ProgramCatalog.all.first else {
            return XCTFail("Expected at least one catalog program")
        }
        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .library

        viewModel.applyPickedProgram(program)

        XCTAssertEqual(viewModel.pickedProgram?.name, program.name)
        XCTAssertEqual(viewModel.resolvedProgramName, program.name)
        XCTAssertNotEqual(
            program.days.map(\.name).joined(separator: " / "),
            program.name
        )
    }

    func testCatalogMatcherRecognizesCompleteImportedProgram() {
        guard let program = ProgramCatalog.all.first else {
            return XCTFail("Expected at least one catalog program")
        }
        let match = ProgramCatalog.matchingProgram(
            dayNames: program.days.map(\.name),
            exerciseNamesByDay: program.days.map { day in
                day.items.map(\.exerciseName)
            }
        )

        XCTAssertEqual(match?.id, program.id)
    }

    func testCatalogMatcherRejectsSimilarCustomProgram() {
        guard let program = ProgramCatalog.all.first else {
            return XCTFail("Expected at least one catalog program")
        }
        var exercises = program.days.map { day in day.items.map(\.exerciseName) }
        exercises[0][0] = "A different exercise"

        XCTAssertNil(
            ProgramCatalog.matchingProgram(
                dayNames: program.days.map(\.name),
                exerciseNamesByDay: exercises
            )
        )
    }

    func testPastedProgramStillDerivesNameFromDayLabels() {
        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .paste
        viewModel.dayNames = ["Push", "Pull", "Legs"]

        XCTAssertEqual(viewModel.resolvedProgramName, "Push / Pull / Legs")
    }

    // MARK: - Plate rounding (Q7 round-DOWN to 2.5 kg / 5 lb plate)

    func testFloorToPlate_exactPlate_returnsValue() {
        XCTAssertEqual(ProgramImporter.floorToPlate(85.0, grain: 2.5), 85.0)
        XCTAssertEqual(ProgramImporter.floorToPlate(100.0, grain: 2.5), 100.0)
        XCTAssertEqual(ProgramImporter.floorToPlate(2.5, grain: 2.5), 2.5)
    }

    func testFloorToPlate_betweenPlates_roundsDown() {
        XCTAssertEqual(ProgramImporter.floorToPlate(58.5, grain: 2.5), 57.5)
        XCTAssertEqual(ProgramImporter.floorToPlate(99.9, grain: 2.5), 97.5)
        XCTAssertEqual(ProgramImporter.floorToPlate(123.4, grain: 2.5), 122.5)
        // 112.5 / 2.5 = 45 exactly — should not round down to 110
        XCTAssertEqual(ProgramImporter.floorToPlate(112.5, grain: 2.5), 112.5)
    }

    func testFloorToPlate_invalidGrain_returnsValueUnchanged() {
        XCTAssertEqual(ProgramImporter.floorToPlate(100.0, grain: 0.0), 100.0)
        XCTAssertEqual(ProgramImporter.floorToPlate(100.0, grain: -1.0), 100.0)
    }

    // MARK: - startingWeight: skip / blank fallback paths

    func testStartingWeight_nilOneRMs_returnsNil() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 4,
            repTarget: 5,
            oneRepMaxLift: .bench,
            startingWeightPct: 0.70
        )
        XCTAssertNil(ProgramImporter.startingWeight(for: item, oneRMs: nil))
    }

    func testStartingWeight_skippedLift_returnsNil() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 4,
            repTarget: 5,
            oneRepMaxLift: .bench,
            startingWeightPct: 0.70
        )
        // User entered squat + deadlift but skipped bench
        let oneRMs: [OneRepMaxLift: Double] = [.squat: 140, .deadlift: 180]
        XCTAssertNil(ProgramImporter.startingWeight(for: item, oneRMs: oneRMs))
    }

    func testStartingWeight_zeroOneRM_returnsNil() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 4,
            repTarget: 5,
            oneRepMaxLift: .bench,
            startingWeightPct: 0.70
        )
        // Zero 1RM (e.g., user left field at "0") should not derive weight
        XCTAssertNil(ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 0]))
    }

    func testStartingWeight_accessoryItem_returnsNil() {
        // Lateral raise has no 1RM mapping — accessory always returns nil
        let item = ProgramItem(
            exerciseName: "Lateral Raise (DB)",
            setCount: 3,
            repTarget: 15
        )
        XCTAssertNil(ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]))
    }

    // MARK: - Per-program canonical math (Q7)

    /// Reddit PPL (Metallicadpa) — heavy compounds at 70% of 1RM.
    /// User 1RM bench = 100 kg → expected starting weight 70.0 kg (exact).
    func testStartingWeight_redditPPL_benchPress() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 4,
            repTarget: 6,
            oneRepMaxLift: .bench,
            startingWeightPct: 0.70
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]),
            70.0
        )
    }

    /// GZCLP T1 main lift — 85% of 1RM. 100 kg bench → 85.0 kg.
    func testStartingWeight_gzclpT1_bench() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 5,
            repTarget: 3,
            notes: "Tier 1",
            oneRepMaxLift: .bench,
            startingWeightPct: 0.85
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]),
            85.0
        )
    }

    /// GZCLP T2 volume lift — 65% of 1RM. 100 kg bench → 65.0 kg.
    func testStartingWeight_gzclpT2_bench() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 3,
            repTarget: 10,
            notes: "Tier 2",
            oneRepMaxLift: .bench,
            startingWeightPct: 0.65
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]),
            65.0
        )
    }

    /// 5/3/1 BBB main lift — 65% of TM, TM = 90% of 1RM → 58.5% of 1RM.
    /// 100 kg bench × 0.585 = 58.5 → floor to 57.5 kg.
    func testStartingWeight_531BBB_mainLift_bench() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 3,
            repTarget: 5,
            notes: "5/3/1 sets",
            oneRepMaxLift: .bench,
            startingWeightPct: 0.585
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]),
            57.5
        )
    }

    /// 5/3/1 BBB volume work — 50% of TM = 45% of 1RM. 100 kg → 45.0 kg.
    func testStartingWeight_531BBB_volumeWork_bench() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 5,
            repTarget: 10,
            notes: "BBB @ 50%",
            oneRepMaxLift: .bench,
            startingWeightPct: 0.45
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.bench: 100]),
            45.0
        )
    }

    /// nSuns top-set AMRAP — 58.5% of 1RM week 1. 180 kg deadlift → 105.0 kg
    /// (180 × 0.585 = 105.3 → floor to 105.0 — wait, 105.0 / 2.5 = 42 exact).
    func testStartingWeight_nSuns_topSet_deadlift() {
        let item = ProgramItem(
            exerciseName: "Deadlift (Conv)",
            setCount: 8,
            repTarget: 5,
            notes: "Top set AMRAP",
            oneRepMaxLift: .deadlift,
            startingWeightPct: 0.585
        )
        // 180 × 0.585 = 105.3 → floor(105.3 / 2.5) * 2.5 = 42 * 2.5 = 105.0
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.deadlift: 180]),
            105.0
        )
    }

    /// PHUL power day — 80% of 1RM. 140 kg squat → 112.0 → floor 110.0 kg
    /// (140 × 0.80 = 112.0 → 112.0 / 2.5 = 44.8 → floor 44 → 44 × 2.5 = 110.0).
    func testStartingWeight_phul_powerDay_squat() {
        let item = ProgramItem(
            exerciseName: "Back Squat (BB)",
            setCount: 4,
            repTarget: 5,
            notes: "Power",
            oneRepMaxLift: .squat,
            startingWeightPct: 0.80
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.squat: 140]),
            110.0
        )
    }

    /// PHUL hypertrophy day — 65% of 1RM. 140 kg squat (used by front squat
    /// pattern at 65%) → 140 × 0.65 = 91.0 → floor 90.0 kg.
    func testStartingWeight_phul_hypertrophyDay_frontSquat() {
        let item = ProgramItem(
            exerciseName: "Front Squat",
            setCount: 4,
            repTarget: 10,
            oneRepMaxLift: .squat,
            startingWeightPct: 0.65
        )
        XCTAssertEqual(
            ProgramImporter.startingWeight(for: item, oneRMs: [.squat: 140]),
            90.0
        )
    }

    // MARK: - Real catalog coverage (smoke test against shipped programs)

    /// The catalog keeps the dormant 1RM-derivation substrate on its strength
    /// programs (oneRepMaxLift + startingWeightPct). The 1RM onboarding screen
    /// was removed 2026-06-18, but these stamps and the math are kept for a
    /// future rep-max-input feature; this guards against them being stripped
    /// wholesale by accident.
    func testCatalog_retainsDormant1RMSubstrate() {
        let stampedPrograms = ProgramCatalog.all.filter { program in
            program.days.flatMap(\.items).contains {
                $0.oneRepMaxLift != nil && $0.startingWeightPct != nil
            }
        }
        XCTAssertGreaterThanOrEqual(stampedPrograms.count, 5)
    }

    /// Every program name shown in the app must be clear and jargon-free. The
    /// onboarding picker and the in-app program library both render
    /// `ProgramCatalog.all`, so this guards against a regression that
    /// reintroduces the insider codenames the founder rejected (Metallicadpa /
    /// GZCLP / nSuns / PHUL / Boring But Big / Reddit / the bare "PPL").
    func testCatalog_namesAreJargonFree() {
        let banned = ["metallicadpa", "gzclp", "nsuns", "phul", "boring but big", "reddit", "ppl"]
        for program in ProgramCatalog.all {
            let lowered = program.name.lowercased()
            for term in banned {
                XCTAssertFalse(
                    lowered.contains(term),
                    "Program name '\(program.name)' contains banned jargon '\(term)'"
                )
            }
        }
    }

    func testProgramMatcherOffersEverySupportedScheduleFromTwoToSixDays() {
        XCTAssertEqual(ProgramCatalog.supportedDays, [2, 3, 4, 5, 6])
    }

    func testProgramMatcherKeepsTrainingDaysAsAHardConstraint() {
        for days in ProgramCatalog.supportedDays {
            let profile = ProgramMatchProfile(
                goal: .mixed,
                level: .intermediate,
                daysPerWeek: days
            )
            let recommendations = ProgramCatalog.recommendations(for: profile)

            XCTAssertFalse(recommendations.isEmpty, "Expected at least one \(days)-day match")
            XCTAssertLessThanOrEqual(recommendations.count, 3)
            XCTAssertTrue(recommendations.allSatisfy { $0.daysPerWeek == days })
        }
    }

    func testProgramMatcherCanReturnTheFullScheduleMatchedCatalog() {
        let profile = ProgramMatchProfile(
            goal: .mixed,
            level: .intermediate,
            daysPerWeek: 4
        )

        let shortlist = ProgramCatalog.recommendations(for: profile)
        let fullMatches = ProgramCatalog.recommendations(
            for: profile,
            limit: ProgramCatalog.all.count
        )

        XCTAssertEqual(shortlist.count, 3)
        XCTAssertGreaterThan(fullMatches.count, shortlist.count)
        XCTAssertTrue(fullMatches.allSatisfy { $0.daysPerWeek == profile.daysPerWeek })
        XCTAssertEqual(Array(fullMatches.prefix(shortlist.count)), shortlist)
    }

    func testProgramMatcherRanksExactGoalAndExperienceFirst() throws {
        let profile = ProgramMatchProfile(
            goal: .mixed,
            level: .intermediate,
            daysPerWeek: 5
        )
        let first = try XCTUnwrap(ProgramCatalog.recommendations(for: profile).first)

        XCTAssertEqual(first.name, "Strength + Size 5-Day")
        XCTAssertEqual(first.goal, profile.goal)
        XCTAssertEqual(first.level, profile.level)
    }

    func testEveryCatalogProgramIsCompleteAndResolvesEveryExercise() {
        XCTAssertGreaterThanOrEqual(ProgramCatalog.all.count, 27)

        for program in ProgramCatalog.all {
            XCTAssertEqual(program.days.count, program.daysPerWeek, program.name)
            XCTAssertFalse(program.days.isEmpty, program.name)

            for item in program.days.flatMap(\.items) {
                XCTAssertGreaterThan(item.setCount, 0, "\(program.name) / \(item.exerciseName)")
                XCTAssertGreaterThan(item.repTarget, 0, "\(program.name) / \(item.exerciseName)")
                XCTAssertNotNil(
                    ExerciseCatalog.lookup(item.exerciseName),
                    "Missing catalog metadata for \(program.name) / \(item.exerciseName)"
                )
            }
        }
    }

    func testExerciseCatalogIncludesPublicDomainLibrary() throws {
        XCTAssertGreaterThanOrEqual(ExerciseCatalog.all.count, 850)

        let dumbbellCurl = try XCTUnwrap(
            ExerciseCatalog.lookup("Alternate Incline Dumbbell Curl")
        )
        XCTAssertEqual(dumbbellCurl.muscleGroup, .biceps)
        XCTAssertEqual(dumbbellCurl.equipment, .dumbbell)
        XCTAssertFalse(dumbbellCurl.isBodyweight)

        let airBike = try XCTUnwrap(ExerciseCatalog.lookup("Air Bike"))
        XCTAssertEqual(airBike.muscleGroup, .core)
        XCTAssertEqual(airBike.equipment, .bodyweight)
        XCTAssertTrue(airBike.isBodyweight)
    }

    func testExerciseCatalogHasUniqueNamesAndKeepsCuratedAliases() {
        let names = ExerciseCatalog.all.map { $0.displayName.lowercased() }
        XCTAssertEqual(Set(names).count, names.count)
        XCTAssertEqual(ExerciseCatalog.lookup("Dumbbell Bench Press")?.displayName, "DB Bench Press")
    }

    func testProgramSetupContextRoundTripsWithoutWorkoutContent() throws {
        let suiteName = "ProgramSetupContextStoreTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let context = ProgramSetupContext(
            source: .matchedLibrary,
            matchProfile: ProgramMatchProfile(
                goal: .strength,
                level: .advanced,
                daysPerWeek: 3
            )
        )

        ProgramSetupContextStore.save(context, defaults: defaults)

        XCTAssertEqual(ProgramSetupContextStore.load(defaults: defaults), context)
        ProgramSetupContextStore.clear(defaults: defaults)
        XCTAssertNil(ProgramSetupContextStore.load(defaults: defaults))
    }

    func testProgramMatchAnswersSurviveColdRelaunch() throws {
        let suiteName = "ProgramMatchDraftTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let original = OnboardingViewModel()
        original.importMethod = .library
        original.hasSelectedImportMethod = true
        original.preferredGoal = .hypertrophy
        original.preferredLevel = .beginner
        original.preferredDaysPerWeek = 2

        OnboardingPreferences.save(
            from: original,
            currentStep: .libraryPicker,
            history: [.splash, .unitPicker, .importMethod],
            defaults: defaults
        )

        let restored = OnboardingViewModel()
        OnboardingPreferences.load(into: restored, defaults: defaults)
        let navigation = OnboardingPreferences.loadNavigation(defaults: defaults)

        XCTAssertEqual(restored.programMatchProfile, original.programMatchProfile)
        XCTAssertEqual(navigation.step, .libraryPicker)
        // The retired unit step (2026-10-23) is dropped from Back history.
        XCTAssertEqual(navigation.history, [.splash, .importMethod])
    }

    func testCombatPowerProgramPreservesScheduleAndContrastOrder() throws {
        let program = try XCTUnwrap(
            ProgramCatalog.all.first {
                $0.id == UUID(uuidString: "00000000-0000-0000-0000-000000000011")
            }
        )

        XCTAssertEqual(program.name, "Combat Power")
        XCTAssertEqual(program.daysPerWeek, 3)
        XCTAssertEqual(program.days.map(\.name), ["Lower Power", "Upper Power", "Full Power"])
        XCTAssertEqual(program.days.map(\.weekday), [2, 4, 6])
        XCTAssertEqual(
            program.days[0].items.map(\.exerciseName),
            [
                "Back Squat (BB)",
                "Squat Jump",
                "Romanian DL",
                "Rotational Med Ball Wall Throw",
                "Push-Up Plus"
            ]
        )
        XCTAssertEqual(
            program.days[1].items.prefix(2).map(\.exerciseName),
            ["Bench Press", "Plyo Push-Up"]
        )
        XCTAssertEqual(
            program.days[2].items.prefix(2).map(\.exerciseName),
            ["Trap Bar Deadlift", "Broad Jump"]
        )
        XCTAssertEqual(program.days[2].items.map(\.setCount), [3, 3, 3, 3, 2])
        XCTAssertEqual(program.days[2].items.map(\.repTarget), [5, 3, 3, 8, 10])
        XCTAssertTrue(program.description.contains("open-mat Friday"))
    }

    func testCombatPowerExercisesResolveThroughCatalog() throws {
        let program = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "Combat Power" })

        for item in program.days.flatMap(\.items) {
            XCTAssertNotNil(
                ExerciseCatalog.lookup(item.exerciseName),
                "Missing catalog metadata for \(item.exerciseName)"
            )
        }
    }

    func testCombatPowerUsesOnlyItsExplicitProgressionContract() throws {
        let program = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "Combat Power" })
        let viewModel = OnboardingViewModel()
        viewModel.applyPickedProgram(program)
        let expected = combatPowerProgressionContract

        for exercise in viewModel.dayExercises.flatMap({ $0 }) {
            guard let expectedProgression = expected[exercise.name] else {
                XCTAssertNil(
                    exercise.progressionConfiguration,
                    "Fixed catalog item \(exercise.name) must remain fixed"
                )
                continue
            }
            let progression = try XCTUnwrap(exercise.progressionConfiguration)
            XCTAssertEqual(progression.lowerRepBound, expectedProgression.range.lowerBound)
            XCTAssertEqual(progression.upperRepBound, expectedProgression.range.upperBound)
            XCTAssertEqual(
                progression.weightIncrementKg,
                expectedProgression.incrementKg,
                accuracy: 0.000_001
            )
        }
    }

    func testCatalogProgressionRequiresExplicitItemRangeAndIncrement() throws {
        let expected = combatPowerProgressionContract

        for program in ProgramCatalog.all {
            for item in program.days.flatMap(\.items) {
                if program.name == "Combat Power",
                   let expectedProgression = expected[item.exerciseName] {
                    XCTAssertEqual(item.repRange, expectedProgression.range)
                    XCTAssertEqual(
                        item.weightIncrementKg ?? -1,
                        expectedProgression.incrementKg,
                        accuracy: 0.000_001
                    )
                    XCTAssertEqual(item.repTarget, expectedProgression.range.lowerBound)
                    XCTAssertNotNil(ProgramImporter.progressionConfiguration(for: item))
                } else {
                    XCTAssertNil(
                        item.repRange,
                        "\(program.name) / \(item.exerciseName) invents a rep range"
                    )
                    XCTAssertNil(
                        item.weightIncrementKg,
                        "\(program.name) / \(item.exerciseName) invents an increment"
                    )
                    XCTAssertNil(ProgramImporter.progressionConfiguration(for: item))
                }
            }
        }
    }

    func testReadyMadeProgramsWithoutRangesGetTheStandardRule() throws {
        let ppl = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "Push Pull Legs" })
        let items = ppl.days.flatMap(\.items)
        let weighted = try XCTUnwrap(items.first {
            !OnboardingViewModel.isBodyweightExercise(named: $0.exerciseName)
                && (1...20).contains($0.repTarget)
                && !$0.exerciseName.contains("DB")
        })
        let rule = try XCTUnwrap(
            ProgramImporter.libraryProgressionConfiguration(for: weighted, in: ppl, unitSystem: "kg")
        )
        XCTAssertEqual(rule.lowerRepBound, weighted.repTarget)
        XCTAssertEqual(rule.upperRepBound, weighted.repTarget + 2)
        XCTAssertEqual(rule.weightIncrementKg, 2.5, accuracy: 0.000_1)
        XCTAssertEqual(
            ProgramImporter.libraryProgressionConfiguration(for: weighted, in: ppl, unitSystem: "lb")?
                .weightIncrementKg ?? 0,
            5 / 2.20462,
            accuracy: 0.000_1
        )

        if let bodyweight = items.first(where: { OnboardingViewModel.isBodyweightExercise(named: $0.exerciseName) }) {
            XCTAssertNil(ProgramImporter.libraryProgressionConfiguration(for: bodyweight, in: ppl, unitSystem: "kg"))
        }

        let fiveThreeOne = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "5/3/1" })
        let percentItem = try XCTUnwrap(fiveThreeOne.days.flatMap(\.items).first { $0.startingWeightPct != nil })
        XCTAssertNil(
            ProgramImporter.libraryProgressionConfiguration(for: percentItem, in: fiveThreeOne, unitSystem: "kg"),
            "5/3/1 percentage work keeps its own cycle"
        )

        let combat = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "Combat Power" })
        for item in combat.days.flatMap(\.items) {
            XCTAssertEqual(
                ProgramImporter.libraryProgressionConfiguration(for: item, in: combat, unitSystem: "kg"),
                ProgramImporter.progressionConfiguration(for: item),
                "a program with its own ranges keeps them exactly"
            )
        }

        for program in ProgramCatalog.all {
            XCTAssertTrue(
                program.days.flatMap(\.items).contains {
                    ProgramImporter.libraryProgressionConfiguration(for: $0, in: program, unitSystem: "kg") != nil
                },
                "\(program.name) offers no next-target suggestion on any lift"
            )
        }
    }

    func testInvalidExplicitCatalogIncrementDoesNotConfigureProgression() {
        let item = ProgramItem(
            exerciseName: "Bench Press",
            setCount: 3,
            repTarget: 8,
            repRange: 8...10,
            weightIncrementKg: 0
        )

        XCTAssertNil(ProgramImporter.progressionConfiguration(for: item))
    }

    func testDirectCatalogImportPersistsOnlyExplicitCombatPowerProgression() throws {
        let program = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "Combat Power" })
        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )

        let split = ProgramImporter.importProgram(program, into: container.mainContext)
        let importedTemplates = try container.mainContext.fetch(FetchDescriptor<DayTemplate>())
            .filter { $0.splitId == split.id }
        let expected = combatPowerProgressionContract

        for day in program.days {
            let importedTemplate = try XCTUnwrap(
                importedTemplates.first { $0.displayName == day.name }
            )
            XCTAssertEqual(importedTemplate.orderedExerciseIds.count, day.items.count)

            for (index, item) in day.items.enumerated() {
                let exerciseID = importedTemplate.orderedExerciseIds[index]
                let state = importedTemplate.progressionState(for: exerciseID)
                guard let expectedProgression = expected[item.exerciseName] else {
                    XCTAssertNil(state, "Fixed item \(item.exerciseName) received progression")
                    continue
                }
                let progressionState = try XCTUnwrap(state)
                XCTAssertEqual(progressionState.lowerRepBound, expectedProgression.range.lowerBound)
                XCTAssertEqual(progressionState.upperRepBound, expectedProgression.range.upperBound)
                XCTAssertEqual(
                    progressionState.weightIncrementKg,
                    expectedProgression.incrementKg,
                    accuracy: 0.000_001
                )
            }
        }
    }

    func testPastedRepRangePersistsIntoSavedRoutine() throws {
        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .paste
        viewModel.applyImportedProgram([
            ImportedProgramDay(
                name: "Push",
                exercises: [
                    ImportedProgramExercise(
                        name: "Bench Press",
                        sets: 3,
                        reps: 8,
                        repRange: 8...10,
                        weightKg: 60
                    )
                ]
            )
        ])

        try viewModel.commit(modelContext: container.mainContext)

        let template = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<DayTemplate>()).first
        )
        let exerciseID = try XCTUnwrap(template.orderedExerciseIds.first)
        let state = try XCTUnwrap(template.progressionState(for: exerciseID))
        XCTAssertEqual(state.lowerRepBound, 8)
        XCTAssertEqual(state.upperRepBound, 10)
        XCTAssertEqual(state.currentAcceptedTargetReps, 8)
        XCTAssertNil(state.sourceWorkoutSessionID)
    }

    func testPastedFixedRepsPersistWithoutProgression() throws {
        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .paste
        viewModel.applyImportedProgram(
            ProgramImportParser.parse("Bench Press 3x8", defaultUnit: "kg")
        )

        try viewModel.commit(modelContext: container.mainContext)

        let template = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<DayTemplate>()).first
        )
        let exerciseID = try XCTUnwrap(template.orderedExerciseIds.first)
        XCTAssertNil(template.progressionState(for: exerciseID))
    }

    func testPastedWeightedBodyweightRangePersistsProgression() throws {
        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .paste
        viewModel.applyImportedProgram(
            ProgramImportParser.parse(
                "Weighted Pull-Up 4 × 5–7 +10 kg",
                defaultUnit: "kg"
            )
        )

        try viewModel.commit(modelContext: container.mainContext)

        let template = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<DayTemplate>()).first
        )
        let exerciseID = try XCTUnwrap(template.orderedExerciseIds.first)
        let exercise = try XCTUnwrap(
            container.mainContext.fetch(FetchDescriptor<Exercise>()).first {
                $0.id == exerciseID
            }
        )
        let state = try XCTUnwrap(template.progressionState(for: exerciseID))

        XCTAssertTrue(exercise.isBodyweight)
        XCTAssertEqual(
            template.plannedWeight(for: exerciseID) ?? -1,
            10,
            accuracy: 0.000_001
        )
        XCTAssertEqual(state.lowerRepBound, 5)
        XCTAssertEqual(state.upperRepBound, 7)
        XCTAssertEqual(state.currentAcceptedTargetReps, 5)
    }

    private var combatPowerProgressionContract: [
        String: (range: ClosedRange<Int>, incrementKg: Double)
    ] {
        [
            "Back Squat (BB)": (5...7, 2.5),
            "Romanian DL": (6...8, 2.5),
            "Rotational Med Ball Wall Throw": (6...8, 2),
            "Bench Press": (5...7, 2.5),
            "Weighted Pull-Up": (5...7, 2.5),
            "OHP (BB)": (5...7, 2.5),
            "Lateral Raise (DB)": (12...15, 1),
            "Trap Bar Deadlift": (5...7, 5),
            "DB Snatch": (3...5, 2.5),
            "Close-Grip Bench": (8...10, 2.5)
        ]
    }

    func testFiveThreeOneBBBKeepsVolumeSetsThroughSummaryHistoryAndAnalytics() throws {
        let originalActiveSplitID = UserDefaults.standard.string(
            forKey: ActiveSplitStore.defaultsKey
        )
        defer {
            if let originalActiveSplitID {
                UserDefaults.standard.set(originalActiveSplitID, forKey: ActiveSplitStore.defaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: ActiveSplitStore.defaultsKey)
            }
        }

        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = container.mainContext
        let program = try XCTUnwrap(ProgramCatalog.all.first { $0.name == "5/3/1" })

        let viewModel = OnboardingViewModel()
        viewModel.applyPickedProgram(program)
        try viewModel.commit(modelContext: context)

        let templates = try context.fetch(FetchDescriptor<DayTemplate>())
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        for template in templates {
            XCTAssertEqual(
                Set(template.orderedExerciseIds).count,
                template.orderedExerciseIds.count,
                "\(template.name) still lists one exercise twice"
            )
        }

        let benchDay = try XCTUnwrap(templates.first { $0.name == "Bench Day" })
        let main = try XCTUnwrap(exercises.first { $0.displayName == "Bench Press" })
        let volume = try XCTUnwrap(exercises.first { $0.displayName == "Bench Press · BBB @ 50%" })
        XCTAssertNotEqual(main.id, volume.id)
        XCTAssertEqual(benchDay.plannedSets(for: main.id), 3)
        XCTAssertEqual(benchDay.plannedReps(for: main.id), 5)
        XCTAssertEqual(benchDay.plannedSets(for: volume.id), 5)
        XCTAssertEqual(benchDay.plannedReps(for: volume.id), 10)

        let session = WorkoutSession(templateId: benchDay.id)
        context.insert(session)
        session.setEntries = (0..<3).map { index in
            SetEntry(
                sessionId: session.id,
                exerciseId: main.id,
                weight: 80,
                reps: 5,
                isCompleted: true,
                setIndex: index
            )
        } + (0..<5).map { index in
            SetEntry(
                sessionId: session.id,
                exerciseId: volume.id,
                weight: 50,
                reps: 10,
                isCompleted: true,
                setIndex: index
            )
        }
        session.isCompleted = true
        session.captureProgressionRecords(template: benchDay, exercises: exercises)
        try context.save()

        let order = exerciseOrderIndex(for: benchDay.orderedExerciseIds)
        XCTAssertEqual(order[main.id], benchDay.orderedExerciseIds.firstIndex(of: main.id))
        XCTAssertEqual(order[volume.id], benchDay.orderedExerciseIds.firstIndex(of: volume.id))
        XCTAssertEqual(exerciseOrderIndex(for: [main.id, main.id, volume.id])[main.id], 0)

        let analytics = AnalyticsSnapshot.make(
            sessions: [session],
            exercises: exercises,
            templates: templates,
            plannedDaysPerWeek: program.daysPerWeek
        )
        let logged = try XCTUnwrap(analytics.sessions.first)
        XCTAssertEqual(logged.sets.filter { $0.exerciseID == main.id }.count, 3)
        XCTAssertEqual(logged.sets.filter { $0.exerciseID == volume.id }.count, 5)

        let history = try XCTUnwrap(
            makeHistorySessionSnapshot(
                for: session,
                templateNamesByID: Dictionary.firstUniqueKeys(templates.map { ($0.id, $0.displayName) }),
                exercisesByID: Dictionary.firstUniqueKeys(exercises.map { ($0.id, $0) }),
                prSetEntryIDs: []
            )
        )
        XCTAssertEqual(history.exercises.first { $0.id == volume.id }?.sets.count, 5)
        XCTAssertEqual(history.templateName, "Bench Day")

        let split = try XCTUnwrap(try context.fetch(FetchDescriptor<Split>()).first { $0.name == "5/3/1" })
        XCTAssertEqual(EarlierWeekCatchup.orderedTemplates(for: split, templates: templates).count, 4)

        let duplicateID = UUID()
        let duplicateTemplate = DayTemplate(
            name: "Duplicate",
            orderedExerciseIds: [duplicateID, duplicateID],
            progressionStateByExerciseId: [
                duplicateID: ExerciseProgressionState(
                    lowerRepBound: 5,
                    upperRepBound: 7,
                    weightIncrementKg: 2.5,
                    currentAcceptedTargetWeightKg: 60,
                    currentAcceptedTargetReps: 5,
                    sourceWorkoutSessionID: UUID(),
                    lastAcceptedReason: .repeatTarget
                )
            ]
        )
        let duplicateSnapshot = AnalyticsSnapshot.make(
            sessions: [],
            exercises: [],
            templates: [duplicateTemplate],
            plannedDaysPerWeek: 4
        )
        XCTAssertEqual(duplicateSnapshot.templates.first?.targets.count, 1)

        let library = ProgramImporter.importProgram(
            program,
            into: context,
            oneRMs: [.bench: 100, .squat: 140, .deadlift: 180, .ohp: 60]
        )
        let libraryBench = try XCTUnwrap(
            try context.fetch(FetchDescriptor<DayTemplate>()).first {
                $0.splitId == library.id && $0.name == "Bench Day"
            }
        )
        XCTAssertEqual(libraryBench.plannedSets(for: volume.id), 5)
        XCTAssertEqual(libraryBench.plannedReps(for: volume.id), 10)
        XCTAssertEqual(libraryBench.plannedSets(for: main.id), 3)
        XCTAssertEqual(libraryBench.plannedWeight(for: main.id) ?? -1, 57.5, accuracy: 0.001)
        XCTAssertEqual(libraryBench.plannedWeight(for: volume.id) ?? -1, 45, accuracy: 0.001)
        XCTAssertEqual(
            Set(libraryBench.orderedExerciseIds).count,
            libraryBench.orderedExerciseIds.count
        )
    }

#if DEBUG
    func testCombatPowerSmokeSeedCreatesFourCompleteWeeksAndIsIdempotent() throws {
        let originalActiveSplitID = UserDefaults.standard.string(
            forKey: ActiveSplitStore.defaultsKey
        )
        defer {
            if let originalActiveSplitID {
                UserDefaults.standard.set(
                    originalActiveSplitID,
                    forKey: ActiveSplitStore.defaultsKey
                )
            } else {
                UserDefaults.standard.removeObject(forKey: ActiveSplitStore.defaultsKey)
            }
        }

        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: configuration
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 0))
        calendar.firstWeekday = 2
        let now = try XCTUnwrap(
            calendar.date(
                from: DateComponents(year: 2026, month: 8, day: 3, hour: 12)
            )
        )

        let firstResult = try CombatPowerSmokeTestSeeder.seed(
            in: container.mainContext,
            now: now,
            calendar: calendar
        )
        let secondResult = try CombatPowerSmokeTestSeeder.seed(
            in: container.mainContext,
            now: now,
            calendar: calendar
        )

        let splits = try container.mainContext.fetch(FetchDescriptor<Split>())
        let templates = try container.mainContext.fetch(FetchDescriptor<DayTemplate>())
        let sessions = try container.mainContext.fetch(FetchDescriptor<WorkoutSession>())
        let entries = try container.mainContext.fetch(FetchDescriptor<SetEntry>())
        let split = try XCTUnwrap(splits.first { $0.id == firstResult.splitID })
        let templateIDs = Set(split.orderedTemplateIds)
        let smokeSessions = sessions.filter { templateIDs.contains($0.templateId) }
        let smokeTemplates = templates.filter { $0.splitId == split.id }

        XCTAssertEqual(firstResult.completedSessionCount, 12)
        XCTAssertEqual(secondResult, firstResult)
        XCTAssertEqual(split.name, "Combat Power")
        XCTAssertEqual(ActiveSplitStore.currentId(), split.id)
        XCTAssertEqual(smokeTemplates.count, 3)
        XCTAssertEqual(smokeSessions.count, 12)
        XCTAssertTrue(smokeSessions.allSatisfy(\.isCompleted))
        XCTAssertEqual(entries.count, 208)
        XCTAssertEqual(
            smokeTemplates.reduce(0) { partialResult, template in
                partialResult + template.progressionStateByExerciseId.count
            },
            10
        )

        let sessionDays = smokeSessions.map { calendar.startOfDay(for: $0.date) }
        XCTAssertEqual(
            sessionDays.min(),
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 6))
        )
        XCTAssertEqual(
            sessionDays.max(),
            calendar.date(from: DateComponents(year: 2026, month: 7, day: 31))
        )
    }
#endif
}
