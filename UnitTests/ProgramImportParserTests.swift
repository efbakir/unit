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
