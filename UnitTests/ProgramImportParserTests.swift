//
//  ProgramImportParserTests.swift
//  UnitTests
//
//  Coverage for the stage-based pasted-program parser. The primary fixture
//  is the real 4-day hybrid program the user pasted that hit the original
//  parser's blind spots (multi-word headings, intent qualifiers,
//  duration-based work, per-side notation). Secondary fixtures come from
//  the web research — HeavySet PHUL markdown, Tactical Barbell continuation
//  lines, Boostcamp Reddit PPL, headless paste, conditioning-only paste.
//
//  Each test asserts:
//   - Day count and names (heading detection)
//   - Per-exercise name (in-name modifier preservation + intent stripping)
//   - Sets / reps / weight (slot-filling correctness)
//   - Note string (per-side / duration / distance / intent capture)
//   - Warnings (conditioning skips, 6-day cap)
//
//  Run via `xcodebuild test` or Xcode's ⌘U.
//

import XCTest
@testable import Unit

@MainActor
final class WorkoutTargetFormatterTests: XCTestCase {
    func testSetRepCompactContainsOnlySetsAndReps() {
        let preview = WorkoutTargetFormatter.setRepCompact(setCount: 4, reps: 8)

        XCTAssertEqual(preview, "4x8")
        XCTAssertFalse(preview?.contains("kg") ?? true)
        XCTAssertFalse(preview?.contains("BW") ?? true)
        XCTAssertNil(WorkoutTargetFormatter.setRepCompact(setCount: 0, reps: 8))
        XCTAssertNil(WorkoutTargetFormatter.setRepCompact(setCount: 4, reps: 0))
    }

    func testExplicitZeroLoggedSetFormatsAsBodyweight() {
        XCTAssertEqual(
            WorkoutTargetFormatter.setMetricText(
                weightKg: 0,
                reps: 12,
                isBodyweight: false
            ),
            "BWx12"
        )
        XCTAssertEqual(
            WorkoutTargetFormatter.actualText(
                weightKg: 0,
                setCount: 3,
                reps: 12,
                isBodyweight: false
            ),
            "3x12xBW"
        )
    }

    func testMissingPlannedWeightStillDoesNotBecomeBodyweight() {
        XCTAssertNil(
            WorkoutTargetFormatter.compactLoadText(
                sets: 3,
                reps: 8,
                weightKg: nil,
                isBodyweight: false
            )
        )
    }
}

/// Swift 6 strict concurrency: `OnboardingViewModel`, `Exercise`, and most
/// of the Unit host module is `@MainActor`-isolated. Annotating the whole
/// suite is simpler than `await`-ing every call — these are CPU-bound
/// regex tests with no async work, so main-actor cost is irrelevant.
@MainActor
final class ProgramImportParserTests: XCTestCase {

    // MARK: - Primary: the user's pasted 4-day program

    /// Real paste from the user. The fixture that motivated the rewrite —
    /// every line that broke the old parser is in here. The expected
    /// output is the gold standard for this test suite.
    func testUserProgram_FourDayHybrid_AllDaysDetected() {
        let input = """
        MAIN DAY
        Broad Jumps 4x3
        Barbell Deadlift 140kg Explosive 5x3
        Weighted Pull Ups 4x5
        Landmine Press 4x5 each side
        Pendlay Row 4x8
        Front Rack KB Carry 3x40m
        Curls 2x12

        POST STRIKING 1
        Pause Deadlift 140kg 4x5
        Weighted Pull Ups 4x6
        Danish Floor Press 4x8 each side
        Heavy KB Swings 3x15
        Band Pull Aparts 3x20

        POST STRIKING 2
        Romanian Deadlift 3x8
        Landmine Press 3x8 each side
        Inverted Row 3x12
        Heavy Goblet Squat 3x10
        Bike Intervals 6x20s

        POST WRESTLING
        Zercher Squat 3x5
        Standing Landmine Press 3x6 each side
        Suitcase Carry 3x40m each side
        Band Anti Rotation Hold 3x20s each side
        Neck Band Extensions 2x20
        Easy Bike Cooldown 10min
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        XCTAssertEqual(result.days.count, 4, "Expected 4 days from the user's hybrid program")
        XCTAssertEqual(result.days.map(\.name),
                       ["Main Day", "Post Striking 1", "Post Striking 2", "Post Wrestling"])

        // Conditioning lines filtered (Bike Intervals + Easy Bike Cooldown).
        let conditioningWarning = result.warnings.first { warning in
            if case .skippedConditioning = warning { return true }
            return false
        }
        XCTAssertNotNil(conditioningWarning,
                        "Expected a conditioning-skipped warning")
        if case .skippedConditioning(let lines) = conditioningWarning {
            XCTAssertEqual(lines.count, 2, "Expected 2 conditioning lines filtered")
        }

        // No truncation warning — only 4 days, under the 6 cap.
        XCTAssertFalse(result.warnings.contains { warning in
            if case .truncatedAtSixDays = warning { return true }
            return false
        })
    }

    /// Day 1 (MAIN DAY) — the seven strength exercises.
    func testUserProgram_MainDay_ExerciseDetails() {
        let result = ProgramImportParser.parseWithWarnings(Self.userProgram, defaultUnit: "kg")
        let mainDay = result.days[0]

        XCTAssertEqual(mainDay.exercises.count, 7)

        // Broad Jumps 4x3 — simple sets×reps, no weight, no note.
        XCTAssertEqual(mainDay.exercises[0].name, "Broad Jumps")
        XCTAssertEqual(mainDay.exercises[0].sets, 4)
        XCTAssertEqual(mainDay.exercises[0].reps, 3)
        XCTAssertNil(mainDay.exercises[0].weightKg)

        // Barbell Deadlift 140kg Explosive 5x3 — order-insensitive
        // tokenization; "Explosive" stripped + surfaced in note.
        XCTAssertEqual(mainDay.exercises[1].name, "Barbell Deadlift")
        XCTAssertEqual(mainDay.exercises[1].sets, 5)
        XCTAssertEqual(mainDay.exercises[1].reps, 3)
        XCTAssertEqual(mainDay.exercises[1].weightKg ?? 0, 140, accuracy: 0.01)
        XCTAssertTrue(mainDay.exercises[1].note?.contains("Explosive") ?? false,
                      "Expected 'Explosive' in note; got: \(mainDay.exercises[1].note ?? "nil")")

        // Weighted Pull Ups 4x5 — in-name "Weighted" preserved.
        XCTAssertEqual(mainDay.exercises[2].name, "Weighted Pull Ups")
        XCTAssertEqual(mainDay.exercises[2].sets, 4)
        XCTAssertEqual(mainDay.exercises[2].reps, 5)

        // Landmine Press 4x5 each side — per-side flag captured.
        XCTAssertEqual(mainDay.exercises[3].name, "Landmine Press")
        XCTAssertEqual(mainDay.exercises[3].sets, 4)
        XCTAssertEqual(mainDay.exercises[3].reps, 5)
        XCTAssertTrue(mainDay.exercises[3].note?.contains("Each side") ?? false,
                      "Expected 'Each side' in note; got: \(mainDay.exercises[3].note ?? "nil")")

        // Pendlay Row 4x8 — proper-noun preserved.
        XCTAssertEqual(mainDay.exercises[4].name, "Pendlay Row")
        XCTAssertEqual(mainDay.exercises[4].sets, 4)
        XCTAssertEqual(mainDay.exercises[4].reps, 8)

        // Front Rack KB Carry 3x40m — distance captured, reps placeholder=1.
        XCTAssertEqual(mainDay.exercises[5].name, "Front Rack KB Carry")
        XCTAssertEqual(mainDay.exercises[5].sets, 3)
        XCTAssertEqual(mainDay.exercises[5].reps, 1, "Carry reps should default to 1 placeholder")
        XCTAssertTrue(mainDay.exercises[5].note?.contains("40 m") ?? false,
                      "Expected '40 m' in note; got: \(mainDay.exercises[5].note ?? "nil")")

        // Curls 2x12 — minimal line.
        XCTAssertEqual(mainDay.exercises[6].name, "Curls")
        XCTAssertEqual(mainDay.exercises[6].sets, 2)
        XCTAssertEqual(mainDay.exercises[6].reps, 12)
    }

    /// Day 2 (POST STRIKING 1) — Pause Deadlift modifier glue + Heavy
    /// intent stripping in adjacent lines.
    func testUserProgram_PostStriking1_PauseAndHeavyHandling() {
        let result = ProgramImportParser.parseWithWarnings(Self.userProgram, defaultUnit: "kg")
        let day2 = result.days[1]

        XCTAssertEqual(day2.exercises.count, 5)

        // Pause Deadlift 140kg 4x5 — "Pause" is in §B.1 (in-name modifier)
        // and stays glued; result is "Pause Deadlift", NOT "Deadlift".
        XCTAssertEqual(day2.exercises[0].name, "Pause Deadlift",
                       "Pause is part of the exercise identity — must not strip")
        XCTAssertEqual(day2.exercises[0].sets, 4)
        XCTAssertEqual(day2.exercises[0].reps, 5)
        XCTAssertEqual(day2.exercises[0].weightKg ?? 0, 140, accuracy: 0.01)

        // Danish Floor Press 4x8 each side — "Danish" is proper-noun,
        // "Floor" is in-name modifier; both stay.
        XCTAssertEqual(day2.exercises[2].name, "Danish Floor Press")
        XCTAssertTrue(day2.exercises[2].note?.contains("Each side") ?? false)

        // Heavy KB Swings 3x15 — "Heavy" stripped + surfaced.
        XCTAssertEqual(day2.exercises[3].name, "KB Swings",
                       "Heavy is intent (§B.2), not part of name")
        XCTAssertTrue(day2.exercises[3].note?.lowercased().contains("heavy") ?? false)
    }

    /// Day 3 (POST STRIKING 2) — Bike Intervals filtered; Heavy Goblet
    /// Squat stripped.
    func testUserProgram_PostStriking2_ConditioningDropped() {
        let result = ProgramImportParser.parseWithWarnings(Self.userProgram, defaultUnit: "kg")
        let day3 = result.days[2]

        // 5 exercises in the paste; Bike Intervals dropped → 4 in result.
        XCTAssertEqual(day3.exercises.count, 4)

        // Make sure Bike Intervals isn't anywhere in the names.
        XCTAssertFalse(day3.exercises.contains { $0.name.lowercased().contains("bike") },
                       "Bike Intervals should have been filtered as conditioning")

        // Heavy Goblet Squat 3x10 — name resolves to "Goblet Squat",
        // intent surfaces in note.
        let gobletSquat = day3.exercises.first { $0.name == "Goblet Squat" }
        XCTAssertNotNil(gobletSquat, "Heavy intent should strip to clean name")
        XCTAssertTrue(gobletSquat?.note?.lowercased().contains("heavy") ?? false)
    }

    /// Day 4 (POST WRESTLING) — Suitcase Carry with both per-side AND
    /// distance; Band Anti Rotation Hold with per-side AND duration;
    /// Easy Bike Cooldown filtered.
    func testUserProgram_PostWrestling_CompoundNotes() {
        let result = ProgramImportParser.parseWithWarnings(Self.userProgram, defaultUnit: "kg")
        let day4 = result.days[3]

        // 6 in paste; Easy Bike Cooldown dropped → 5.
        XCTAssertEqual(day4.exercises.count, 5)

        // Suitcase Carry 3x40m each side — both flags captured.
        let suitcase = day4.exercises.first { $0.name == "Suitcase Carry" }
        XCTAssertNotNil(suitcase)
        XCTAssertTrue(suitcase?.note?.contains("Each side") ?? false)
        XCTAssertTrue(suitcase?.note?.contains("40 m") ?? false)

        // Band Anti Rotation Hold 3x20s each side — duration in seconds.
        let hold = day4.exercises.first { $0.name.contains("Anti Rotation") }
        XCTAssertNotNil(hold)
        XCTAssertTrue(hold?.note?.contains("20 s") ?? false,
                      "Expected '20 s' in note; got: \(hold?.note ?? "nil")")
        XCTAssertTrue(hold?.note?.contains("Each side") ?? false)
    }

    // MARK: - Secondary: format variants from web research

    /// HeavySet PHUL — markdown heading `## Upper Power (Day 1)` + letter
    /// prefixed comma-row format. The most-common community format.
    func testHeavySetPHUL_markdownHeadingAndCommaRows() {
        let input = """
        ## Upper Power (Day 1)
        A. Bench Press, 3-4 sets, 3-5 reps, 2:00 rest
        B. Barbell Row, 3-4 sets, 3-5 reps, 2:00 rest

        ## Lower Hypertrophy (Day 4)
        A. Front Squat, 3-4 sets, 8-12 reps, 1:00 rest
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        XCTAssertEqual(result.days.count, 2)
        XCTAssertTrue(result.days[0].name.contains("Upper Power"),
                      "Got: \(result.days[0].name)")
        XCTAssertTrue(result.days[1].name.contains("Lower Hypertrophy"))

        // Bench Press parses; letter prefix `A.` stripped.
        let bench = result.days[0].exercises.first
        XCTAssertEqual(bench?.name, "Bench Press")
        XCTAssertNotNil(bench?.sets)
    }

    /// Reddit-shaped compact line: name SxR with no day heading. Parser
    /// opens an implicit `Workout 1` and gives the lifter something to
    /// rename in the Exercises step.
    func testHeadlessPaste_impliedWorkout1() {
        let input = """
        Squat 5x5 100kg
        Bench Press 5x5 80kg
        Barbell Row 5x5 60kg
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        XCTAssertEqual(result.days.count, 1)
        XCTAssertEqual(result.days[0].name, "Workout 1",
                       "Headless paste should open implicit Workout 1")
        XCTAssertEqual(result.days[0].exercises.count, 3)
        XCTAssertEqual(result.days[0].exercises[0].weightKg ?? 0, 100, accuracy: 0.01)
        XCTAssertEqual(result.days[0].exercises[1].weightKg ?? 0, 80, accuracy: 0.01)
    }

    /// Conditioning-only paste should return an empty days array so the
    /// UI's "Couldn't find exercises" error path triggers. Behavior
    /// matches the prior parser's failure-mode contract.
    func testConditioningOnlyPaste_returnsEmpty() {
        let input = """
        Bike Intervals 6x20s
        Run 30min
        Treadmill 5min cooldown
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        XCTAssertTrue(result.days.isEmpty,
                      "Conditioning-only paste should produce no days")
        XCTAssertFalse(result.warnings.isEmpty,
                       "Should emit at least a conditioning-skipped warning")
    }

    // MARK: - Vocabulary + bodyweight detection

    func testVocabExpansion_BodyweightDetection() {
        // Use the static form so we don't have to construct an
        // `OnboardingViewModel` — its `@Observable` + `@MainActor`
        // initialization SIGABRTs in some Swift 6 test harnesses before
        // the main actor is fully established, and the vocabulary is a
        // pure function anyway.
        // Existing entries still work.
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Pull-up"))
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Push-up"))

        // New entries added for the user's program.
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Inverted Row"))
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Band Pull Aparts"))
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Face Pull"))
        XCTAssertTrue(OnboardingViewModel.isBodyweightExercise(named: "Neck Extension"))

        // Sanity: still false on actual weighted lifts.
        XCTAssertFalse(OnboardingViewModel.isBodyweightExercise(named: "Barbell Deadlift"))
        XCTAssertFalse(OnboardingViewModel.isBodyweightExercise(named: "Bench Press"))
    }

    func testIntentStripping_HeavyGobletSquat_GobletSquatWithHeavyNote() {
        let result = ProgramImportParser.parse(
            "Heavy Goblet Squat 3x10", defaultUnit: "kg"
        )
        XCTAssertEqual(result.first?.exercises.first?.name, "Goblet Squat")
        XCTAssertTrue(result.first?.exercises.first?.note?
            .lowercased().contains("heavy") ?? false)
    }

    func testInNameModifier_PauseDeadlift_PreservedNotStrippedToDeadlift() {
        let result = ProgramImportParser.parse(
            "Pause Deadlift 140kg 4x5", defaultUnit: "kg"
        )
        XCTAssertEqual(result.first?.exercises.first?.name, "Pause Deadlift",
                       "Pause Deadlift and Deadlift are different exercises")
    }

    func testInNameModifier_RomanianDeadlift_Preserved() {
        let result = ProgramImportParser.parse(
            "Romanian Deadlift 3x8", defaultUnit: "kg"
        )
        XCTAssertEqual(result.first?.exercises.first?.name, "Romanian Deadlift")
    }

    func testInitialism_KB_Preserved() {
        // KB Swings — "KB" stays capitalized through titleCaseName.
        let result = ProgramImportParser.parse(
            "KB Swings 3x15", defaultUnit: "kg"
        )
        XCTAssertEqual(result.first?.exercises.first?.name, "KB Swings",
                       "Initialisms like KB / DB / RDL should preserve case")
    }

    // MARK: - Day-heading edge cases

    func testHeading_AllCaps_NotInVocab_HeuristicCatches() {
        let input = """
        WAVE 1
        Squat 5x5
        Bench 5x5

        WAVE 2
        Deadlift 3x5
        """
        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")
        XCTAssertEqual(result.days.count, 2,
                       "Heuristic heading should catch lifter-invented labels")
        XCTAssertEqual(result.days[0].name, "Wave 1")
        XCTAssertEqual(result.days[1].name, "Wave 2")
    }

    func testHeading_ColonSuffix_StrippedCleanly() {
        let input = """
        Push:
        Bench 5x5

        Pull:
        Row 5x5
        """
        let result = ProgramImportParser.parse(input, defaultUnit: "kg")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].name, "Push")
        XCTAssertEqual(result[1].name, "Pull")
    }

    func testHeading_CommonPushPullLowerSplit_DetectsLowerDay() {
        let input = """
        Push
        Bench Press 4x8 60kg
        Incline DB Press 3x10 22kg

        Pull
        Deadlift 3x5 100kg
        Pull-Up 4x8 BW

        Lower
        Back Squat 3x5 100kg
        Romanian Deadlift 3x8 80kg
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        XCTAssertEqual(result.days.count, 3)
        XCTAssertEqual(result.days.map(\.name), ["Push", "Pull", "Lower"])
        XCTAssertEqual(result.days[2].exercises.map(\.name), ["Back Squat", "Romanian Deadlift"])
    }

    // MARK: - Real-world failure modes (release-audit 2026-05-13 §1.2)
    //
    // Each test below pins one of the eight silent bugs traced during the
    // AAA-quality release audit, plus the two structural drops (markdown
    // tables, ChatGPT-style verbose lines). If any of these regress the
    // parser is leaking wrong data into the lifter's first session.

    /// Bug 1: `Bench 4x8-12 60kg` (rep range upper bound) used to leak the
    /// upper bound into the exercise name as "Bench -12".
    func testFailureCase_RepRange_UpperBoundStripped() {
        let result = ProgramImportParser.parse("Bench 4x8-12 60kg", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Bench")
        XCTAssertEqual(ex?.sets, 4)
        XCTAssertEqual(ex?.reps, 8)
        XCTAssertEqual(ex?.weightKg ?? 0, 60, accuracy: 0.01)
    }

    /// Bug 2: `Bench 5x5 @ 80%` (percentage of 1RM) used to be read as
    /// weight=80kg. Should reject the bare number, capture "80%" as a
    /// note, and leave weight nil.
    func testFailureCase_PercentageNotAWeight() {
        let result = ProgramImportParser.parse("Bench 5x5 @ 80%", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Bench")
        XCTAssertEqual(ex?.sets, 5)
        XCTAssertEqual(ex?.reps, 5)
        XCTAssertNil(ex?.weightKg, "80% is a percentage, not a weight")
        XCTAssertTrue(ex?.note?.contains("80%") ?? false,
                      "Expected '80%' in note; got: \(ex?.note ?? "nil")")
    }

    /// Bug 3: `Squat 5/3/1` (Wendler) used to drop silently as noise.
    /// Should parse as sets=3 reps=5 (top set) with the scheme in the note.
    func testFailureCase_WendlerSlashScheme() {
        let result = ProgramImportParser.parse("Squat 5/3/1", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertNotNil(ex, "Wendler 5/3/1 must be parsed, not dropped")
        XCTAssertEqual(ex?.name, "Squat")
        XCTAssertEqual(ex?.sets, 3)
        XCTAssertEqual(ex?.reps, 5, "Top set reps should drive the prefill baseline")
        XCTAssertTrue(ex?.note?.contains("5/3/1") ?? false,
                      "Expected '5/3/1' in note; got: \(ex?.note ?? "nil")")
    }

    /// Bug 4: `Bench 4 sets of 8 reps` used to produce name "Bench Of"
    /// because the `of` connector survived the alone-matchers' consumption.
    func testFailureCase_VerboseOfConnector() {
        let result = ProgramImportParser.parse("Bench 4 sets of 8 reps", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Bench")
        XCTAssertEqual(ex?.sets, 4)
        XCTAssertEqual(ex?.reps, 8)
    }

    /// Bug 5: `Squat 4x8x60` (triple-x notation) used to produce name
    /// "Squat X" because the second `x` separator survived cleanup.
    func testFailureCase_TripleXShorthand() {
        let result = ProgramImportParser.parse("Squat 4x8x60", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Squat")
        XCTAssertEqual(ex?.sets, 4)
        XCTAssertEqual(ex?.reps, 8)
        XCTAssertEqual(ex?.weightKg ?? 0, 60, accuracy: 0.01)
    }

    /// Bug 6: `**Day 1: Push**` (ChatGPT markdown) used to leak asterisks
    /// into the day name.
    func testFailureCase_MarkdownBoldHeading() {
        let input = """
        **Day 1: Push**
        Bench 4x8 60kg
        """
        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")
        XCTAssertEqual(result.days.count, 1)
        let dayName = result.days.first?.name ?? ""
        XCTAssertFalse(dayName.contains("*"),
                       "Markdown asterisks should be stripped; got: '\(dayName)'")
        XCTAssertTrue(dayName.lowercased().contains("day 1"),
                      "Day name should preserve 'Day 1'; got: '\(dayName)'")
    }

    /// Bug 7: `Bench Press - 4 sets x 8 reps @ 80kg` (ChatGPT verbose form)
    /// used to produce name "Bench Press - X" because the dash and stray
    /// `x` connector survived cleanup.
    func testFailureCase_ChatGPTVerboseLine() {
        let result = ProgramImportParser.parse(
            "Bench Press - 4 sets x 8 reps @ 80kg",
            defaultUnit: "kg"
        )
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Bench Press")
        XCTAssertEqual(ex?.sets, 4)
        XCTAssertEqual(ex?.reps, 8)
        XCTAssertEqual(ex?.weightKg ?? 0, 80, accuracy: 0.01)
    }

    /// Bug 8: `Squat 5x5 @8 RPE` used to be read as weight=8kg. Should
    /// reject as autoregulation cue and surface "RPE 8" in the note.
    func testFailureCase_RPENotAWeight() {
        let result = ProgramImportParser.parse("Squat 5x5 @8 RPE", defaultUnit: "kg")
        let ex = result.first?.exercises.first
        XCTAssertEqual(ex?.name, "Squat")
        XCTAssertEqual(ex?.sets, 5)
        XCTAssertEqual(ex?.reps, 5)
        XCTAssertNil(ex?.weightKg, "@ 8 RPE is autoregulation, not a weight")
        XCTAssertTrue(ex?.note?.contains("RPE") ?? false,
                      "Expected RPE in note; got: \(ex?.note ?? "nil")")
    }

    /// Structural 1: Markdown / Notion / Bear table rows used to drop as
    /// noise because the pipe-delimited form had no setsxreps shape.
    func testStructural_MarkdownTable_Parsed() {
        let input = """
        | Exercise | Sets | Reps | Weight |
        | --- | --- | --- | --- |
        | Bench Press | 4 | 8 | 60 |
        | Barbell Row | 3 | 10 | 50 |
        """
        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")
        XCTAssertEqual(result.days.first?.exercises.count, 2,
                       "Both data rows should parse; header + separator drop")
        let bench = result.days.first?.exercises.first
        XCTAssertEqual(bench?.name, "Bench Press")
        XCTAssertEqual(bench?.sets, 4)
        XCTAssertEqual(bench?.reps, 8)
        XCTAssertEqual(bench?.weightKg ?? 0, 60, accuracy: 0.01)
    }

    /// Structural 2: Markdown table rows with explicit unit suffix.
    func testStructural_MarkdownTable_ExplicitUnit() {
        let input = """
        | Exercise | Sets | Reps | Weight |
        | Bench | 4 | 8 | 60kg |
        | Squat | 5 | 5 | 100kg |
        """
        let result = ProgramImportParser.parse(input, defaultUnit: "lb")
        XCTAssertEqual(result.first?.exercises.count, 2)
        // 60kg parses as 60kg regardless of defaultUnit because the row
        // has an explicit `kg` suffix.
        XCTAssertEqual(result.first?.exercises[0].weightKg ?? 0, 60, accuracy: 0.01)
        XCTAssertEqual(result.first?.exercises[1].weightKg ?? 0, 100, accuracy: 0.01)
    }

    /// Noisy lines (un-parseable free text) used to drop silently. Now they
    /// surface as a count so the lifter sees the parser didn't keep them.
    func testNoisyLines_WarningSurfaced() {
        let input = """
        Push
        Bench 4x8 60kg
        Notes from coach: aim for RPE 8 across the board
        """
        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")
        let hasNoisyWarning = result.warnings.contains { warning in
            if case .noisyLines = warning { return true }
            return false
        }
        XCTAssertTrue(hasNoisyWarning,
                      "Free-text coach notes should surface as a noisyLines warning, not drop silently")
    }

    // MARK: - Weight seed path (parser weight → first-session "Last time" ghost)

    // The parser already extracts `weightKg` (see the table / explicit-unit
    // tests above). These verify the weight survives the rest of the chain —
    // import → onboarding state → DayTemplate → first-session ghost — instead
    // of being silently discarded the way it was before this fix.

    /// A pasted weight round-trips through the DayTemplate planned-weight map
    /// (the persisted seed) and is readable per exercise.
    func testWeightSeed_DayTemplate_RoundTrips() {
        let squat = UUID()
        let bench = UUID()
        let template = DayTemplate(
            name: "Push",
            plannedWeightByExerciseId: [squat: 100, bench: 60]
        )
        XCTAssertEqual(template.plannedWeight(for: squat) ?? 0, 100, accuracy: 0.01)
        XCTAssertEqual(template.plannedWeight(for: bench) ?? 0, 60, accuracy: 0.01)
    }

    /// No seed → nil, so a paste without weights leaves the field blank
    /// (never "0 kg"). Confirms the additive map is safe for old templates.
    func testWeightSeed_DayTemplate_AbsentReturnsNil() {
        let template = DayTemplate(name: "Push")
        XCTAssertNil(template.plannedWeight(for: UUID()),
                     "A template with no seeded weight must read as blank, not 0")
    }

    /// `applyImportedProgram` carries the parser's `weightKg` into onboarding
    /// state. Before the fix this hop dropped the weight on the floor.
    func testWeightSeed_ApplyImportedProgram_CarriesWeightKg() {
        let vm = OnboardingViewModel()
        let day = ImportedProgramDay(
            name: "Push",
            exercises: [ImportedProgramExercise(name: "Bench", sets: 4, reps: 8, weightKg: 60)]
        )
        vm.applyImportedProgram([day])
        XCTAssertEqual(vm.dayExercises.first?.first?.plannedWeightKg ?? 0, 60, accuracy: 0.01,
                       "Pasted weight must reach onboarding state, not be discarded")
    }

    /// The first-session ghost (`.planned` source) is seeded from the pasted
    /// weight when one exists. (kg user → no conversion.)
    func testWeightSeed_Prefill_SeedsPlannedWeight() {
        UserDefaults.standard.set("kg", forKey: "unitSystem")
        let vm = ActiveWorkoutViewModel()
        let session = WorkoutSession(templateId: UUID())
        let prefill = vm.prefillSet(
            for: UUID(),
            currentSession: session,
            sessions: [],
            plannedReps: 5,
            plannedWeightKg: 100
        )
        XCTAssertEqual(prefill?.source, .planned)
        XCTAssertEqual(prefill?.weight ?? -1, 100, accuracy: 0.01,
                       "First-session ghost should show the seeded weight")
        XCTAssertEqual(prefill?.reps, 5)
    }

    /// Prefills stay in canonical kilograms for every display unit. Conversion
    /// belongs at the text-field/formatter boundary so logging 225 lb cannot be
    /// persisted as 225 kg and converted a second time.
    func testWeightSeed_Prefill_RemainsCanonicalKgForLb() {
        UserDefaults.standard.set("lb", forKey: "unitSystem")
        defer { UserDefaults.standard.set("kg", forKey: "unitSystem") }
        let vm = ActiveWorkoutViewModel()
        let session = WorkoutSession(templateId: UUID())
        let prefill = vm.prefillSet(
            for: UUID(),
            currentSession: session,
            sessions: [],
            plannedReps: 5,
            plannedWeightKg: 100
        )
        XCTAssertEqual(prefill?.weight ?? -1, 100, accuracy: 0.01,
                       "Prefill storage must remain kilograms; the UI converts it to lb")
    }

    /// No seed → weight 0 (blank): the unchanged behaviour for manually-built
    /// programs that carry no pasted weight.
    func testWeightSeed_Prefill_NoSeedIsZeroWeight() {
        UserDefaults.standard.set("kg", forKey: "unitSystem")
        let vm = ActiveWorkoutViewModel()
        let session = WorkoutSession(templateId: UUID())
        let prefill = vm.prefillSet(
            for: UUID(),
            currentSession: session,
            sessions: [],
            plannedReps: 5
        )
        XCTAssertEqual(prefill?.source, .planned)
        XCTAssertEqual(prefill?.weight ?? -1, 0, accuracy: 0.01,
                       "Without a seed the first-session ghost weight stays blank (0)")
    }

    /// Triple-`x` notation respects the lifter's unit: `4x8x135` for an lb
    /// user is 135 lb, stored as ~61.2 kg (not 135 kg). Regression guard for
    /// the unit bug that only surfaced once the weight reached the ghost.
    func testWeightSeed_TripleX_RespectsLbDefaultUnit() {
        let kg = ProgramImportParser.parse("Squat 4x8x135", defaultUnit: "lb")
            .first?.exercises.first?.weightKg ?? 0
        XCTAssertEqual(kg, 135 / 2.20462, accuracy: 0.01,
                       "Triple-x weight must convert lb → kg like the other weight paths")
    }

    // MARK: - Turkish tab-separated table paste (v2 robustness)

    /// Real paste from a Turkish user: a tab-separated 5-column table
    /// (Egzersiz / Ağırlık / Set x Rep / RPE / Dinlenme) with a header row
    /// and a trailing conditioning row. The header must be skipped, the RPE
    /// and rest columns ignored, the weight (which sits BEFORE the NxR)
    /// captured, and "Incline Walk" filtered as conditioning.
    func testTurkishTablePaste_HeaderSkipped_ColumnsIgnored() {
        let input = """
        Egzersiz\tAğırlık (kg)\tSet x Rep\tRPE\tDinlenme
        Barbell Bent Over Row\t67.5\t4x8\t8\t2dk
        Barbell OHP\t55\t4x8\t8\t2dk
        Lat Pulldown\t42.5\t3x10\t7\t60sn
        Cable Row\t42.5\t3x10\t7\t60sn
        Rear Delt Fly\t75\t3x12\t7\t60sn
        Face Pull\t30\t3x12\t7\t60sn
        Barbell Curl\t30\t3x10\t7\t60sn
        Hammer Curl\t16\t3x10\t7\t60sn
        Incline Walk\t—\t35dk\t—\t—
        """

        let result = ProgramImportParser.parseWithWarnings(input, defaultUnit: "kg")

        // Exactly one day (no heading), 8 strength exercises in order.
        XCTAssertEqual(result.days.count, 1, "Expected a single workout day")
        let day = result.days[0]
        XCTAssertEqual(day.exercises.map(\.name), [
            "Barbell Bent Over Row", "Barbell OHP", "Lat Pulldown", "Cable Row",
            "Rear Delt Fly", "Face Pull", "Barbell Curl", "Hammer Curl",
        ], "Header row must be skipped; Incline Walk filtered as conditioning")

        // Slot-filling: weight is the bare number BEFORE the NxR; the RPE
        // (8/7) and rest (2dk/60sn) columns must not corrupt weight or reps.
        XCTAssertEqual(day.exercises[0].sets, 4)
        XCTAssertEqual(day.exercises[0].reps, 8)
        XCTAssertEqual(day.exercises[0].weightKg ?? 0, 67.5, accuracy: 0.01)

        XCTAssertEqual(day.exercises[2].name, "Lat Pulldown")
        XCTAssertEqual(day.exercises[2].sets, 3)
        XCTAssertEqual(day.exercises[2].reps, 10)
        XCTAssertEqual(day.exercises[2].weightKg ?? 0, 42.5, accuracy: 0.01)

        // The Turkish header row must never become an exercise.
        XCTAssertFalse(
            day.exercises.contains { $0.name.localizedCaseInsensitiveContains("Egzersiz") },
            "The header row leaked in as an exercise"
        )

        // Incline Walk (duration-only cardio) filtered as conditioning.
        let conditioning = result.warnings.first {
            if case .skippedConditioning = $0 { return true }
            return false
        }
        XCTAssertNotNil(conditioning, "Expected Incline Walk filtered as conditioning")
    }

    // MARK: - Fixture data

    /// Verbatim user paste used by the per-day tests so they stay aligned
    /// to one source of truth.
    private static let userProgram = """
    MAIN DAY
    Broad Jumps 4x3
    Barbell Deadlift 140kg Explosive 5x3
    Weighted Pull Ups 4x5
    Landmine Press 4x5 each side
    Pendlay Row 4x8
    Front Rack KB Carry 3x40m
    Curls 2x12

    POST STRIKING 1
    Pause Deadlift 140kg 4x5
    Weighted Pull Ups 4x6
    Danish Floor Press 4x8 each side
    Heavy KB Swings 3x15
    Band Pull Aparts 3x20

    POST STRIKING 2
    Romanian Deadlift 3x8
    Landmine Press 3x8 each side
    Inverted Row 3x12
    Heavy Goblet Squat 3x10
    Bike Intervals 6x20s

    POST WRESTLING
    Zercher Squat 3x5
    Standing Landmine Press 3x6 each side
    Suitcase Carry 3x40m each side
    Band Anti Rotation Hold 3x20s each side
    Neck Band Extensions 2x20
    Easy Bike Cooldown 10min
    """
}

// MARK: - PR history derivation

/// Coverage for `PRHistory.prSetEntryIDs(in:)` — the History-side mirror of
/// `ActiveWorkoutView.priorBest`. Lives in this file because the UnitTests
/// target lists source files explicitly in project.pbxproj (no synchronized
/// folders); same precedent as the weight-seed tests above.
@MainActor
final class PRHistoryTests: XCTestCase {

    private func makeSession(
        daysAgo: Int,
        isCompleted: Bool = true,
        entries: [SetEntry]
    ) -> WorkoutSession {
        let session = WorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!,
            templateId: UUID(),
            isCompleted: isCompleted
        )
        session.setEntries = entries
        return session
    }

    private func entry(
        _ exerciseID: UUID,
        weight: Double,
        reps: Int,
        setIndex: Int = 0,
        isWarmup: Bool = false,
        isCompleted: Bool = true
    ) -> SetEntry {
        SetEntry(
            sessionId: UUID(),
            exerciseId: exerciseID,
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            isCompleted: isCompleted,
            setIndex: setIndex
        )
    }

    /// First-ever log of an exercise sets the baseline without firing —
    /// matches the live workout's "no baseline → no PR" rule.
    func testFirstEverLog_IsNotAPR() {
        let bench = UUID()
        let sessions = [makeSession(daysAgo: 1, entries: [entry(bench, weight: 100, reps: 8)])]
        XCTAssertTrue(PRHistory.prSetEntryIDs(in: sessions).isEmpty)
    }

    func testHeavierSetInLaterSession_IsAPR() {
        let bench = UUID()
        let old = entry(bench, weight: 100, reps: 8)
        let new = entry(bench, weight: 105, reps: 8)
        let sessions = [
            makeSession(daysAgo: 7, entries: [old]),
            makeSession(daysAgo: 1, entries: [new]),
        ]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: sessions), [new.id])
    }

    /// Weight ranks first, reps break ties — same comparator as `priorBest`.
    func testSameWeightMoreReps_IsAPR_SameWeightSameReps_IsNot() {
        let bench = UUID()
        let base = entry(bench, weight: 100, reps: 8)
        let moreReps = entry(bench, weight: 100, reps: 9)
        let equal = entry(bench, weight: 100, reps: 9)
        let sessions = [
            makeSession(daysAgo: 7, entries: [base]),
            makeSession(daysAgo: 4, entries: [moreReps]),
            makeSession(daysAgo: 1, entries: [equal]),
        ]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: sessions), [moreReps.id])
    }

    /// Warmups neither badge nor raise the baseline — a heavy warmup single
    /// must not suppress the working-set PR that follows.
    func testWarmupSets_NeverBadge_AndDoNotRaiseBaseline() {
        let bench = UUID()
        let base = entry(bench, weight: 100, reps: 8)
        let heavyWarmup = entry(bench, weight: 140, reps: 1, setIndex: 0, isWarmup: true)
        let working = entry(bench, weight: 105, reps: 8, setIndex: 1)
        let sessions = [
            makeSession(daysAgo: 7, entries: [base]),
            makeSession(daysAgo: 1, entries: [heavyWarmup, working]),
        ]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: sessions), [working.id])
    }

    /// Abandoned (incomplete) sessions are invisible: their sets never badge
    /// and never raise the baseline — mirrors `priorBest` filtering to
    /// completed prior sessions.
    func testIncompleteSessions_AreInvisible() {
        let bench = UUID()
        let base = entry(bench, weight: 100, reps: 8)
        let abandoned = entry(bench, weight: 120, reps: 8)
        let working = entry(bench, weight: 110, reps: 8)
        let sessions = [
            makeSession(daysAgo: 7, entries: [base]),
            makeSession(daysAgo: 4, isCompleted: false, entries: [abandoned]),
            makeSession(daysAgo: 1, entries: [working]),
        ]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: sessions), [working.id])
    }

    /// Earlier sets in the same session count toward the baseline for later
    /// ones — two ascending sets in the very first session: the second fires.
    func testWithinFirstSession_SecondAscendingSet_IsAPR() {
        let bench = UUID()
        let first = entry(bench, weight: 100, reps: 8, setIndex: 0)
        let second = entry(bench, weight: 105, reps: 8, setIndex: 1)
        let sessions = [makeSession(daysAgo: 1, entries: [first, second])]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: sessions), [second.id])
    }

    /// Replay must order by session date, not by array position.
    func testChronologyFollowsDate_NotArrayOrder() {
        let bench = UUID()
        let old = entry(bench, weight: 100, reps: 8)
        let new = entry(bench, weight: 105, reps: 8)
        let newerFirst = [
            makeSession(daysAgo: 1, entries: [new]),
            makeSession(daysAgo: 7, entries: [old]),
        ]
        XCTAssertEqual(PRHistory.prSetEntryIDs(in: newerFirst), [new.id])
    }

    /// Baselines are per-exercise — a bench baseline must not make the first
    /// squat log a PR.
    func testExercisesAreIndependent() {
        let bench = UUID()
        let squat = UUID()
        let sessions = [
            makeSession(daysAgo: 7, entries: [entry(bench, weight: 100, reps: 8)]),
            makeSession(daysAgo: 1, entries: [entry(squat, weight: 90, reps: 8)]),
        ]
        XCTAssertTrue(PRHistory.prSetEntryIDs(in: sessions).isEmpty)
    }
}

// MARK: - Parser-default sets/reps flag

/// The "Check sets and reps" hint must fire only when the parser actually
/// fell back to the 3×8 default — never on an explicitly written 3x8 line
/// (the value-equality heuristic it replaces couldn't tell them apart).
@MainActor
final class ParserDefaultFlagTests: XCTestCase {
    private func mappedExercises(_ text: String) -> [OnboardingExercise] {
        let vm = OnboardingViewModel()
        vm.applyImportedProgram(ProgramImportParser.parse(text, defaultUnit: "kg"))
        return vm.dayExercises.flatMap { $0 }
    }

    func testExplicitThreeByEight_doesNotFlag() {
        let exercises = mappedExercises("Day 1\nSquat 3x8 100")
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.plannedSets, 3)
        XCTAssertEqual(exercises.first?.plannedReps, 8)
        XCTAssertNotEqual(exercises.first?.usedDefaultSetsReps, true,
                          "Explicit 3x8 must not read as a parser fallback")
    }

    /// A bare name-only line ("Squat") is dropped by the normalizer as
    /// noise, so the surviving defaulted case is weight-only: sets and reps
    /// both come back nil and the mapping fills in 3×8.
    func testWeightOnlyLine_flagsDefaultedSetsReps() {
        let exercises = mappedExercises("Day 1\nSquat 100kg")
        XCTAssertEqual(exercises.count, 1)
        XCTAssertEqual(exercises.first?.plannedSets, OnboardingExercise.defaultPlannedSets)
        XCTAssertEqual(exercises.first?.plannedReps, OnboardingExercise.defaultPlannedReps)
        XCTAssertEqual(exercises.first?.usedDefaultSetsReps, true,
                       "A weight-only line takes parser default sets/reps and must carry the flag")
    }

    func testExplicitNonDefault_doesNotFlag() {
        let exercises = mappedExercises("Day 1\nBench Press 4x8 80")
        XCTAssertEqual(exercises.first?.plannedSets, 4)
        XCTAssertEqual(exercises.first?.plannedReps, 8)
        XCTAssertNotEqual(exercises.first?.usedDefaultSetsReps, true)
    }
}
