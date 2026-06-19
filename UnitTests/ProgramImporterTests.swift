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
@testable import Unit

/// Swift 6 strict concurrency: `ProgramItem`, `ProgramImporter`,
/// `ProgramCatalog` and friends are `@MainActor`-isolated. The whole test
/// class runs on MainActor so callers don't need per-method `await`.
@MainActor
final class ProgramImporterTests: XCTestCase {
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

    /// Every surfaced program in the onboarding library subset should have at
    /// least one main lift with a non-nil oneRepMaxLift + startingWeightPct.
    /// Catches a regression where %s get accidentally stripped from the
    /// catalog (which would silently degrade the wow moment to blank fields).
    func testSurfacedPrograms_eachHasAtLeastOneStampedLift() {
        for program in ProgramCatalog.surfacedInOnboarding {
            let stampedItems = program.days.flatMap(\.items).filter {
                $0.oneRepMaxLift != nil && $0.startingWeightPct != nil
            }
            XCTAssertFalse(
                stampedItems.isEmpty,
                "Program '\(program.name)' has no 1RM-stamped items — wow moment broken"
            )
        }
    }

    /// The surfaced subset should have exactly 5 programs (the clear universal
    /// set re-curated 2026-06-18: Full Body, Upper / Lower, 5/3/1, Power + Size,
    /// Push Pull Legs).
    func testSurfacedPrograms_countIsFive() {
        XCTAssertEqual(ProgramCatalog.surfacedInOnboarding.count, 5)
    }

    /// The surfaced set must carry the clear, jargon-free names. Guards against
    /// a regression that reintroduces the insider codenames the founder rejected
    /// (Metallicadpa / GZCLP / nSuns / PHUL / Boring But Big).
    func testSurfacedPrograms_useClearNames() {
        let names = Set(ProgramCatalog.surfacedInOnboarding.map(\.name))
        XCTAssertEqual(
            names,
            ["Full Body", "Upper / Lower", "5/3/1", "Power + Size", "Push Pull Legs"]
        )
    }
}
