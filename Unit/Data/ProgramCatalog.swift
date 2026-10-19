//
//  ProgramCatalog.swift
//  Unit
//
//  Curated starter programs. Each program references exercises from
//  ExerciseCatalog by displayName/alias — ProgramImporter resolves these to
//  real Exercise models on import.
//

import Foundation

enum ProgramCatalog {
    static let all: [ProgramTemplate] = [
        fullBody2Day,
        startingStrength,
        gzclp,
        strongCurves,
        upperLower4Day,
        fiveThreeOneBBB,
        strengthSize5Day,
        metallicadpaPPL,
        dumbbellPPL,
        arnoldSplit,
        nSuns531,
        phul,
        combatPower,
        upperLower2Day,
        barbellFoundation,
        heavyLightMedium,
        volumeRecoveryIntensity,
        goldenSix,
        balancedFullBody,
        fourFourEight,
        tenByTen,
        classicUpperLower,
        machineDumbbellUpperLower,
        classicBroSplit,
        dailyStrengthPractice,
        highVolumePowerbuilding,
        classicPushPullLegs
    ]

    static var supportedDays: [Int] {
        Array(Set(all.map(\.daysPerWeek))).sorted()
    }

    /// Ranks ready-made programs against the three answers Unit can honor
    /// today. Training days are a hard constraint; goal and experience rank
    /// the remaining choices. Stable catalog order breaks ties so the same
    /// answers always produce the same recommendations.
    static func recommendations(
        for profile: ProgramMatchProfile,
        limit: Int = 3
    ) -> [ProgramTemplate] {
        all.enumerated()
            .filter { $0.element.daysPerWeek == profile.daysPerWeek }
            .sorted { lhs, rhs in
                let lhsScore = recommendationScore(lhs.element, for: profile)
                let rhsScore = recommendationScore(rhs.element, for: profile)
                return lhsScore == rhsScore ? lhs.offset < rhs.offset : lhsScore > rhsScore
            }
            .prefix(max(1, limit))
            .map(\.element)
    }

    private static func recommendationScore(
        _ program: ProgramTemplate,
        for profile: ProgramMatchProfile
    ) -> Int {
        let goalScore: Int
        if program.goal == profile.goal {
            goalScore = 6
        } else if program.goal == .mixed || profile.goal == .mixed {
            goalScore = 3
        } else {
            goalScore = 0
        }

        let levelOrder: [ProgramTemplate.Level: Int] = [
            .beginner: 0,
            .intermediate: 1,
            .advanced: 2
        ]
        let distance = abs(
            (levelOrder[program.level] ?? 0) - (levelOrder[profile.level] ?? 0)
        )
        let levelScore = distance == 0 ? 4 : (distance == 1 ? 2 : 0)
        return goalScore + levelScore
    }

    /// Recognizes an imported catalog program from its ordered day and exercise
    /// structure. Used only to repair the legacy onboarding bug that saved a
    /// joined list of day names as the program title. Requiring the complete
    /// structure prevents similarly named pasted or custom programs from being
    /// renamed accidentally.
    static func matchingProgram(
        dayNames: [String],
        exerciseNamesByDay: [[String]]
    ) -> ProgramTemplate? {
        guard dayNames.count == exerciseNamesByDay.count else { return nil }

        return all.first { program in
            guard program.days.count == dayNames.count else { return false }

            for index in program.days.indices {
                let expectedDay = program.days[index]
                guard normalize(expectedDay.name) == normalize(dayNames[index]) else {
                    return false
                }

                let expectedExercises = expectedDay.items.map { canonicalExerciseName($0.exerciseName) }
                let actualExercises = exerciseNamesByDay[index].map(canonicalExerciseName)
                guard expectedExercises == actualExercises else { return false }
            }

            return true
        }
    }

    private static func canonicalExerciseName(_ name: String) -> String {
        normalize(ExerciseCatalog.lookup(name)?.displayName ?? name)
    }

    private static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    // MARK: - 0. Full Body 2-Day (Beginner, Mixed, 2 days)
    private static let fullBody2Day = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000012")!,
        name: "Full Body 2-Day",
        level: .beginner,
        goal: .mixed,
        daysPerWeek: 2,
        summary: "Two full-body sessions for building strength and muscle with a manageable schedule.",
        description: "A simple two-day plan for lifters who need more recovery or have limited training days. Each session covers a squat or hinge, a press, a pull and focused accessory work.",
        days: [
            ProgramDay(id: UUID(), name: "Full Body A", weekday: 3, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Bench Press", setCount: 3, repTarget: 6, oneRepMaxLift: .bench, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 8, oneRepMaxLift: .deadlift, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Plank", setCount: 3, repTarget: 45)
            ]),
            ProgramDay(id: UUID(), name: "Full Body B", weekday: 6, items: [
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 5, oneRepMaxLift: .deadlift, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 6, oneRepMaxLift: .ohp, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Bulgarian Split Squat", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "DB Curl", setCount: 2, repTarget: 12)
            ])
        ]
    )

    // MARK: - 1. Full Body (Beginner, Strength, 3 days) — SURFACED
    // Starting % from 1RM: main work sets (3×5) at 70%; the single heavy
    // deadlift set (1×5) at 75%. Conservative novice start that still leaves
    // room to add weight every session.
    private static let startingStrength = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Full Body",
        level: .beginner,
        goal: .strength,
        daysPerWeek: 3,
        summary: "A 3-day full-body barbell program. Squat, press and pull every session.",
        description: "Mark Rippetoe's classic novice protocol. Train 3 days a week, alternating between Workout A and Workout B. Add weight every session. The goal is building a strong base with low-rep, high-intensity compounds.",
        days: [
            ProgramDay(id: UUID(), name: "Workout A", weekday: 2, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Bench Press", setCount: 3, repTarget: 5, oneRepMaxLift: .bench, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 1, repTarget: 5, oneRepMaxLift: .deadlift, startingWeightPct: 0.75)
            ]),
            ProgramDay(id: UUID(), name: "Workout B", weekday: 4, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 5, oneRepMaxLift: .ohp, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 1, repTarget: 5, oneRepMaxLift: .deadlift, startingWeightPct: 0.75)
            ]),
            ProgramDay(id: UUID(), name: "Workout A (repeat)", weekday: 6, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Bench Press", setCount: 3, repTarget: 5, oneRepMaxLift: .bench, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 8)
            ])
        ]
    )

    // MARK: - 2. GZCLP (Beginner, Strength, 3 days) — SURFACED in onboarding library
    // Starting % per Cody Lefever's GZCL method: T1 (5×3 heavy compound) at 85%
    // of 1RM; T2 (3×10 volume compound) at 65%. T3 accessories left blank
    // (no canonical 1RM mapping). Source: r/gzcl wiki.
    private static let gzclp = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Beginner Linear",
        level: .beginner,
        goal: .strength,
        daysPerWeek: 3,
        summary: "A 3-day beginner program with heavy, volume and accessory tiers.",
        description: "A linear-progression take on Cody Lefever's GZCL method. Tier 1 is a heavy compound, Tier 2 is a volume compound, Tier 3 is accessory work. A clean next step after Starting Strength.",
        days: [
            ProgramDay(id: UUID(), name: "Day A1", weekday: 2, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 5, repTarget: 3, notes: "Tier 1", oneRepMaxLift: .squat, startingWeightPct: 0.85),
                ProgramItem(exerciseName: "Bench Press", setCount: 3, repTarget: 10, notes: "Tier 2", oneRepMaxLift: .bench, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 3, repTarget: 15, notes: "Tier 3")
            ]),
            ProgramDay(id: UUID(), name: "Day B1", weekday: 4, items: [
                ProgramItem(exerciseName: "OHP (BB)", setCount: 5, repTarget: 3, notes: "Tier 1", oneRepMaxLift: .ohp, startingWeightPct: 0.85),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 10, notes: "Tier 2", oneRepMaxLift: .deadlift, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Single-Arm DB Row", setCount: 3, repTarget: 15, notes: "Tier 3")
            ]),
            ProgramDay(id: UUID(), name: "Day A2", weekday: 6, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 5, repTarget: 3, notes: "Tier 1", oneRepMaxLift: .bench, startingWeightPct: 0.85),
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 10, notes: "Tier 2", oneRepMaxLift: .squat, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 15, notes: "Tier 3")
            ])
        ]
    )

    // MARK: - 3. Strong Curves (Beginner, Hypertrophy, 3 days)
    private static let strongCurves = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Strong Curves",
        level: .beginner,
        goal: .hypertrophy,
        daysPerWeek: 3,
        summary: "Glute-focused hypertrophy program with compound posterior-chain work.",
        description: "Bret Contreras's program built around the hip thrust as the centerpiece. Three full-body days heavy on glute-targeted compounds and accessories.",
        days: [
            ProgramDay(id: UUID(), name: "Workout A", weekday: 2, items: [
                ProgramItem(exerciseName: "Hip Thrust", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Walking Lunge", setCount: 2, repTarget: 12),
                ProgramItem(exerciseName: "Glute Bridge", setCount: 2, repTarget: 20)
            ]),
            ProgramDay(id: UUID(), name: "Workout B", weekday: 4, items: [
                ProgramItem(exerciseName: "Hip Thrust", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Bulgarian Split Squat", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "DB Romanian DL", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Cable Kickback", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "Plank", setCount: 3, repTarget: 45)
            ]),
            ProgramDay(id: UUID(), name: "Workout C", weekday: 6, items: [
                ProgramItem(exerciseName: "Hip Thrust", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Goblet Squat", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Good Morning", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Step-Up", setCount: 3, repTarget: 10)
            ])
        ]
    )

    // MARK: - 4. Upper / Lower 4-Day (Intermediate, Mixed, 4 days)
    private static let upperLower4Day = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Upper / Lower",
        level: .intermediate,
        goal: .mixed,
        daysPerWeek: 4,
        summary: "A 4-day upper and lower split. Two strength days, two size days.",
        description: "Two upper and two lower days per week. One session of each is strength-focused (lower reps), the other hypertrophy-focused (higher reps). Balanced, flexible and scales well.",
        days: [
            ProgramDay(id: UUID(), name: "Upper Strength", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 4, repTarget: 5, oneRepMaxLift: .bench, startingWeightPct: 0.75),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 4, repTarget: 5),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 6, oneRepMaxLift: .ohp, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "Barbell Curl", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Lower Strength", weekday: 3, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 4, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.75),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 6, oneRepMaxLift: .deadlift, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Leg Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Upper Size", weekday: 5, items: [
                ProgramItem(exerciseName: "Incline DB Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "DB Shoulder Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "DB Curl", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Triceps Pushdown", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Lower Size", weekday: 6, items: [
                ProgramItem(exerciseName: "Front Squat", setCount: 4, repTarget: 8, oneRepMaxLift: .squat, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Hip Thrust", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Leg Extension", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Seated Calf Raise", setCount: 4, repTarget: 15)
            ])
        ]
    )

    // MARK: - 5. 5/3/1 Boring But Big (Intermediate, Hypertrophy, 4 days) — SURFACED
    // Starting % per Wendler's "Beyond 5/3/1": training max (TM) = 90% of 1RM,
    // week 1 set 1 main work = 65% of TM = 0.585 of 1RM. BBB volume work
    // starts at 50% of TM = 0.45 of 1RM. Both on the same main lift each day.
    private static let fiveThreeOneBBB = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "5/3/1",
        level: .intermediate,
        goal: .hypertrophy,
        daysPerWeek: 4,
        summary: "Wendler's 5/3/1 paired with 5×10 volume work on the main lift.",
        description: "Each day hits one of the four main lifts using 5/3/1 percentages, then follows with 5×10 of the same lift at a lighter weight. Brutal volume, simple to run. Treat set counts here as a starting point. Follow Wendler's percentage scheme for loading.",
        days: [
            ProgramDay(id: UUID(), name: "Press Day", weekday: 2, items: [
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 5, notes: "5/3/1 sets", oneRepMaxLift: .ohp, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 5, repTarget: 10, notes: "BBB @ 50%", oneRepMaxLift: .ohp, startingWeightPct: 0.45),
                ProgramItem(exerciseName: "Pull-Up", setCount: 5, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Deadlift Day", weekday: 3, items: [
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 5, notes: "5/3/1 sets", oneRepMaxLift: .deadlift, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 5, repTarget: 10, notes: "BBB @ 50%", oneRepMaxLift: .deadlift, startingWeightPct: 0.45),
                ProgramItem(exerciseName: "Hanging Leg Raise", setCount: 5, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Bench Day", weekday: 5, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 3, repTarget: 5, notes: "5/3/1 sets", oneRepMaxLift: .bench, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Bench Press", setCount: 5, repTarget: 10, notes: "BBB @ 50%", oneRepMaxLift: .bench, startingWeightPct: 0.45),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 5, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Squat Day", weekday: 6, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, notes: "5/3/1 sets", oneRepMaxLift: .squat, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 5, repTarget: 10, notes: "BBB @ 50%", oneRepMaxLift: .squat, startingWeightPct: 0.45),
                ProgramItem(exerciseName: "Plank", setCount: 3, repTarget: 45)
            ])
        ]
    )

    // MARK: - 5b. Strength + Size 5-Day (Intermediate, Mixed, 5 days)
    private static let strengthSize5Day = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
        name: "Strength + Size 5-Day",
        level: .intermediate,
        goal: .mixed,
        daysPerWeek: 5,
        summary: "Five focused sessions combining heavy compounds with practical hypertrophy work.",
        description: "A weekday strength-and-size split for consistent lifters. The first two sessions prioritize the main lifts, followed by focused pull, push and leg sessions with moderate volume.",
        days: [
            ProgramDay(id: UUID(), name: "Upper Strength", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 4, repTarget: 5, oneRepMaxLift: .bench, startingWeightPct: 0.75),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 4, repTarget: 5),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 6, oneRepMaxLift: .ohp, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 8)
            ]),
            ProgramDay(id: UUID(), name: "Lower Strength", weekday: 3, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 4, repTarget: 5, oneRepMaxLift: .squat, startingWeightPct: 0.75),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 5, oneRepMaxLift: .deadlift, startingWeightPct: 0.75),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Pull Size", weekday: 4, items: [
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Face Pull", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "DB Curl", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Push Size", weekday: 5, items: [
                ProgramItem(exerciseName: "Incline DB Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "DB Shoulder Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "Triceps Pushdown", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Legs Size", weekday: 6, items: [
                ProgramItem(exerciseName: "Front Squat", setCount: 4, repTarget: 8, oneRepMaxLift: .squat, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Leg Press", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Walking Lunge", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Seated Calf Raise", setCount: 4, repTarget: 15)
            ])
        ]
    )

    // MARK: - 6. Metallicadpa PPL (Intermediate, Mixed, 6 days) — SURFACED in onboarding
    // The "Reddit PPL." Heavy compound working sets at 70% of 1RM (the standard
    // 5×6-8 rep-range working weight per Metallicadpa's r/Fitness wiki). Volume
    // day variants at ~65%. Front squat starts ~65% of back-squat 1RM. RDL at
    // ~65% of deadlift 1RM. Dumbbell + bodyweight accessories left blank.
    // Source: u/Metallicadpa, r/Fitness PPL wiki.
    private static let metallicadpaPPL = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "Push Pull Legs",
        level: .intermediate,
        goal: .mixed,
        daysPerWeek: 6,
        summary: "A 6-day push, pull and legs rotation. Two of each per week.",
        description: "High-frequency push/pull/legs with one heavy and one volume rotation per lift. Run two push, two pull, two legs days per week.",
        days: [
            ProgramDay(id: UUID(), name: "Push A (Heavy)", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 4, repTarget: 6, oneRepMaxLift: .bench, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 8, oneRepMaxLift: .ohp, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Incline DB Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Triceps Pushdown", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 3, repTarget: 15)
            ]),
            ProgramDay(id: UUID(), name: "Pull A (Heavy)", weekday: 3, items: [
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 5, oneRepMaxLift: .deadlift, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "Face Pull", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "Barbell Curl", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Legs A", weekday: 4, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 4, repTarget: 6, oneRepMaxLift: .squat, startingWeightPct: 0.70),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 8, oneRepMaxLift: .deadlift, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Leg Press", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Push B (Volume)", weekday: 5, items: [
                ProgramItem(exerciseName: "OHP (BB)", setCount: 4, repTarget: 8, oneRepMaxLift: .ohp, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Incline DB Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Pec Dec", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Skullcrusher", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Pull B (Volume)", weekday: 6, items: [
                ProgramItem(exerciseName: "Pull-Up", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Hammer Curl", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Rear Delt Fly", setCount: 3, repTarget: 15)
            ]),
            ProgramDay(id: UUID(), name: "Legs B", weekday: 7, items: [
                ProgramItem(exerciseName: "Front Squat", setCount: 4, repTarget: 8, oneRepMaxLift: .squat, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Hip Thrust", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Leg Extension", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Bulgarian Split Squat", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Seated Calf Raise", setCount: 4, repTarget: 15)
            ])
        ]
    )

    // MARK: - 7. Dumbbell PPL (Intermediate, Hypertrophy, 6 days)
    private static let dumbbellPPL = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        name: "Dumbbell Push Pull Legs",
        level: .intermediate,
        goal: .hypertrophy,
        daysPerWeek: 6,
        summary: "Six-day push/pull/legs using only dumbbells. Great for home gyms.",
        description: "All movements use dumbbells or bodyweight. Good option if you only own DBs or travel frequently. Runs the same push/pull/legs rotation twice a week.",
        days: [
            ProgramDay(id: UUID(), name: "Push A", weekday: 2, items: [
                ProgramItem(exerciseName: "DB Bench Press", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "DB Shoulder Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Incline DB Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Triceps Extension", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Pull A", weekday: 3, items: [
                ProgramItem(exerciseName: "Single-Arm DB Row", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Pull-Up", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Rear Delt Fly", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "DB Curl", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Hammer Curl", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Legs A", weekday: 4, items: [
                ProgramItem(exerciseName: "Goblet Squat", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "DB Romanian DL", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Bulgarian Split Squat", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "DB Calf Raise", setCount: 4, repTarget: 15)
            ]),
            ProgramDay(id: UUID(), name: "Push B", weekday: 5, items: [
                ProgramItem(exerciseName: "Incline DB Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Single-Arm DB Press", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "DB Fly", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Push-Up", setCount: 3, repTarget: 15)
            ]),
            ProgramDay(id: UUID(), name: "Pull B", weekday: 6, items: [
                ProgramItem(exerciseName: "Single-Arm DB Row", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Chin-Up", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Rear Delt Fly", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "DB Curl", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Legs B", weekday: 7, items: [
                ProgramItem(exerciseName: "Goblet Squat", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Walking Lunge", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "DB Romanian DL", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Step-Up", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "DB Calf Raise", setCount: 4, repTarget: 20)
            ])
        ]
    )

    // MARK: - 8. Arnold Split (Advanced, Hypertrophy, 6 days)
    private static let arnoldSplit = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
        name: "Arnold Split",
        level: .advanced,
        goal: .hypertrophy,
        daysPerWeek: 6,
        summary: "Classic 6-day bodybuilding split: Chest/Back, Shoulders/Arms, Legs.",
        description: "Arnold's classic split runs each muscle pairing twice a week with high volume. Best for advanced lifters who can recover from frequent, high-volume sessions.",
        days: [
            ProgramDay(id: UUID(), name: "Chest / Back A", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 5, repTarget: 8),
                ProgramItem(exerciseName: "Incline Bench Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "DB Fly", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Pull-Up", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 6)
            ]),
            ProgramDay(id: UUID(), name: "Shoulders / Arms A", weekday: 3, items: [
                ProgramItem(exerciseName: "OHP (BB)", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Rear Delt Fly", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Barbell Curl", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Skullcrusher", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Hammer Curl", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Legs A", weekday: 4, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 5, repTarget: 8),
                ProgramItem(exerciseName: "Romanian DL", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Leg Press", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 5, repTarget: 15)
            ]),
            ProgramDay(id: UUID(), name: "Chest / Back B", weekday: 5, items: [
                ProgramItem(exerciseName: "Incline DB Press", setCount: 5, repTarget: 10),
                ProgramItem(exerciseName: "Cable Crossover", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Weighted Dips", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Chin-Up", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "T-Bar Row", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Shoulders / Arms B", weekday: 6, items: [
                ProgramItem(exerciseName: "DB Shoulder Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Cable Lateral Raise", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Face Pull", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Preacher Curl", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Triceps Pushdown", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "DB Curl", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Legs B", weekday: 7, items: [
                ProgramItem(exerciseName: "Front Squat", setCount: 5, repTarget: 8),
                ProgramItem(exerciseName: "Hip Thrust", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Leg Extension", setCount: 4, repTarget: 15),
                ProgramItem(exerciseName: "Walking Lunge", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Seated Calf Raise", setCount: 5, repTarget: 15)
            ])
        ]
    )

    // MARK: - 9. nSuns 5/3/1 LP (Intermediate, Strength, 4 days) — SURFACED
    // High-volume 4-day variant of Wendler's 5/3/1 with rotating top-set
    // AMRAPs. Top set week 1 = 65% of training max (TM = 90% of 1RM) =
    // 0.585 of 1RM. Secondary lift (T2) runs 50-65% of TM. Sources: nSuns
    // spreadsheet, r/nSuns wiki. Encoded here as week-1 starting weights;
    // the rotating AMRAP-driven progression is post-paywall Phase C work.
    private static let nSuns531 = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
        name: "High-Volume 5/3/1",
        level: .intermediate,
        goal: .strength,
        daysPerWeek: 4,
        summary: "A higher-volume 4-day strength program with heavy top sets.",
        description: "nSuns's take on Wendler's 5/3/1, with much higher volume on the main lifts (8 sets ramping through %s of training max) plus a secondary lift each session. Top set is an AMRAP that drives weight progression. Bring serious training experience. This is a volume bomb.",
        days: [
            ProgramDay(id: UUID(), name: "Bench / OHP", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 8, repTarget: 5, notes: "Top set AMRAP", oneRepMaxLift: .bench, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 6, repTarget: 6, notes: "Ramping sets", oneRepMaxLift: .ohp, startingWeightPct: 0.50),
                ProgramItem(exerciseName: "Pull-Up", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Barbell Curl", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Squat / Sumo DL", weekday: 3, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 8, repTarget: 5, notes: "Top set AMRAP", oneRepMaxLift: .squat, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 6, repTarget: 5, notes: "Sumo, ramping", oneRepMaxLift: .deadlift, startingWeightPct: 0.50),
                ProgramItem(exerciseName: "Leg Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "OHP / Close-Grip Bench", weekday: 5, items: [
                ProgramItem(exerciseName: "OHP (BB)", setCount: 8, repTarget: 5, notes: "Top set AMRAP", oneRepMaxLift: .ohp, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Close-Grip Bench", setCount: 6, repTarget: 6, notes: "Ramping", oneRepMaxLift: .bench, startingWeightPct: 0.50),
                ProgramItem(exerciseName: "Pull-Up", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Deadlift / Front Squat", weekday: 6, items: [
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 8, repTarget: 5, notes: "Top set AMRAP", oneRepMaxLift: .deadlift, startingWeightPct: 0.585),
                ProgramItem(exerciseName: "Front Squat", setCount: 6, repTarget: 5, notes: "Ramping", oneRepMaxLift: .squat, startingWeightPct: 0.50),
                ProgramItem(exerciseName: "Romanian DL", setCount: 4, repTarget: 8, oneRepMaxLift: .deadlift, startingWeightPct: 0.50),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 3, repTarget: 12)
            ])
        ]
    )

    // MARK: - 10. PHUL — Power Hypertrophy Upper Lower (Intermediate, Mixed, 4 days) — SURFACED
    // Brandon Campbell's 4-day powerbuilding split. Power days hit main lifts
    // 3×3-5 at 80% of 1RM. Hypertrophy days hit secondary patterns 3×8-12 at
    // 65% of 1RM. Cleanest entry to intermediate powerbuilding for the
    // self-coached lifter. Source: Brandon Campbell, bodybuilding.com PHUL.
    private static let phul = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
        name: "Power + Size",
        level: .intermediate,
        goal: .mixed,
        daysPerWeek: 4,
        summary: "Two heavy power days and two higher-rep size days.",
        description: "Brandon Campbell's 4-day split blending Westside-style power sessions with bodybuilding-style volume. Two upper and two lower days per week. Each muscle gets hit once heavy, once high-rep. Clean entry point into intermediate powerbuilding.",
        days: [
            ProgramDay(id: UUID(), name: "Upper Power", weekday: 2, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 4, repTarget: 5, notes: "Power", oneRepMaxLift: .bench, startingWeightPct: 0.80),
                ProgramItem(exerciseName: "Incline DB Press", setCount: 4, repTarget: 8),
                ProgramItem(exerciseName: "Bent Over Row (BB)", setCount: 4, repTarget: 5, notes: "Power"),
                ProgramItem(exerciseName: "Pull-Up", setCount: 3, repTarget: 8),
                ProgramItem(exerciseName: "Skullcrusher", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Barbell Curl", setCount: 3, repTarget: 10)
            ]),
            ProgramDay(id: UUID(), name: "Lower Power", weekday: 3, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 4, repTarget: 5, notes: "Power", oneRepMaxLift: .squat, startingWeightPct: 0.80),
                ProgramItem(exerciseName: "Deadlift (Conv)", setCount: 3, repTarget: 5, notes: "Power", oneRepMaxLift: .deadlift, startingWeightPct: 0.80),
                ProgramItem(exerciseName: "Leg Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Hamstring Curl", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Standing Calf Raise", setCount: 4, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Upper Hypertrophy", weekday: 5, items: [
                ProgramItem(exerciseName: "Incline Bench Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "DB Bench Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Seated Cable Row", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Lat Pulldown", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "DB Shoulder Press", setCount: 4, repTarget: 10),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 3, repTarget: 15),
                ProgramItem(exerciseName: "DB Curl", setCount: 3, repTarget: 12),
                ProgramItem(exerciseName: "Triceps Pushdown", setCount: 3, repTarget: 12)
            ]),
            ProgramDay(id: UUID(), name: "Lower Hypertrophy", weekday: 6, items: [
                ProgramItem(exerciseName: "Front Squat", setCount: 4, repTarget: 10, oneRepMaxLift: .squat, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Romanian DL", setCount: 4, repTarget: 10, oneRepMaxLift: .deadlift, startingWeightPct: 0.65),
                ProgramItem(exerciseName: "Bulgarian Split Squat", setCount: 3, repTarget: 10),
                ProgramItem(exerciseName: "Leg Extension", setCount: 4, repTarget: 12),
                ProgramItem(exerciseName: "Seated Calf Raise", setCount: 4, repTarget: 15)
            ])
        ]
    )

    // MARK: - 11. Combat Power (Advanced, Mixed, 3 days)
    private static let combatPower = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000011")!,
        name: "Combat Power",
        level: .advanced,
        goal: .mixed,
        daysPerWeek: 3,
        summary: "Three power-focused sessions with contrast pairs and combat-sport durability work.",
        description: "A Monday, Wednesday and Friday strength-and-power plan for combat athletes. Main lifts are paired with an explosive movement. On an open-mat Friday, complete only Trap Bar Deadlift and Broad Jump, then skip the remaining work.",
        days: [
            ProgramDay(id: UUID(), name: "Lower Power", weekday: 2, items: [
                ProgramItem(exerciseName: "Back Squat (BB)", setCount: 3, repTarget: 5, repRange: 5...7, weightIncrementKg: 2.5, notes: "Contrast: follow each set with Squat Jump."),
                ProgramItem(exerciseName: "Squat Jump", setCount: 3, repTarget: 5, notes: "Perform after each Back Squat set."),
                ProgramItem(exerciseName: "Romanian DL", setCount: 3, repTarget: 6, repRange: 6...8, weightIncrementKg: 2.5),
                ProgramItem(exerciseName: "Rotational Med Ball Wall Throw", setCount: 3, repTarget: 6, repRange: 6...8, weightIncrementKg: 2, notes: "6 reps per side."),
                ProgramItem(exerciseName: "Push-Up Plus", setCount: 3, repTarget: 15, notes: "Serratus finisher.")
            ]),
            ProgramDay(id: UUID(), name: "Upper Power", weekday: 4, items: [
                ProgramItem(exerciseName: "Bench Press", setCount: 4, repTarget: 5, repRange: 5...7, weightIncrementKg: 2.5, notes: "Contrast: follow each set with Plyo Push-Up."),
                ProgramItem(exerciseName: "Plyo Push-Up", setCount: 3, repTarget: 6, notes: "Perform after each Bench Press set."),
                ProgramItem(exerciseName: "Weighted Pull-Up", setCount: 4, repTarget: 5, repRange: 5...7, weightIncrementKg: 2.5),
                ProgramItem(exerciseName: "OHP (BB)", setCount: 3, repTarget: 5, repRange: 5...7, weightIncrementKg: 2.5),
                ProgramItem(exerciseName: "Iso Plate Hold", setCount: 3, repTarget: 1, notes: "One timed hold per set; pair with Lateral Raise."),
                ProgramItem(exerciseName: "Lateral Raise (DB)", setCount: 3, repTarget: 12, repRange: 12...15, weightIncrementKg: 1, notes: "LME pairing; adjust reps if needed."),
                ProgramItem(exerciseName: "Rice Bucket", setCount: 3, repTarget: 1, notes: "Complete 2–3 rounds.")
            ]),
            ProgramDay(id: UUID(), name: "Full Power", weekday: 6, items: [
                ProgramItem(exerciseName: "Trap Bar Deadlift", setCount: 3, repTarget: 5, repRange: 5...7, weightIncrementKg: 5, notes: "Conventional deadlift is an alternative. Contrast with Broad Jump."),
                ProgramItem(exerciseName: "Broad Jump", setCount: 3, repTarget: 3, notes: "Perform after each deadlift set."),
                ProgramItem(exerciseName: "DB Snatch", setCount: 3, repTarget: 3, repRange: 3...5, weightIncrementKg: 2.5, notes: "3 reps per side."),
                ProgramItem(exerciseName: "Close-Grip Bench", setCount: 3, repTarget: 8, repRange: 8...10, weightIncrementKg: 2.5),
                ProgramItem(exerciseName: "Neck Training", setCount: 2, repTarget: 10, notes: "10 reps in each direction.")
            ])
        ]
    )

    // MARK: - Expanded weekly template catalog

    /// These are independent Unit representations of widely documented training
    /// methods. They include only the prescription facts Unit needs—days,
    /// exercises, sets and reps—and do not copy Liftosaur descriptions, scripts,
    /// progression engines or multi-week blocks.
    private static let upperLower2Day = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000013")!,
        name: "Upper / Lower 2-Day",
        level: .beginner,
        goal: .mixed,
        daysPerWeek: 2,
        summary: "One upper-body day and one lower-body day for a compact training week.",
        description: "A balanced two-day split for lifters who want focused sessions without training more than twice a week. Each major movement pattern is covered with straightforward working sets.",
        days: [
            catalogDay("Upper", weekday: 3, items: [
                ("Bench Press", 3, 8),
                ("Lat Pulldown", 3, 10),
                ("OHP (BB)", 3, 8),
                ("Seated Cable Row", 3, 10),
                ("DB Curl", 2, 12),
                ("Triceps Pushdown", 2, 12)
            ]),
            catalogDay("Lower", weekday: 6, items: [
                ("Back Squat (BB)", 3, 8),
                ("Romanian DL", 3, 8),
                ("Leg Press", 3, 10),
                ("Hamstring Curl", 3, 10),
                ("Standing Calf Raise", 3, 12),
                ("Plank", 3, 45)
            ])
        ]
    )

    private static let barbellFoundation = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000014")!,
        name: "Barbell Foundation",
        level: .beginner,
        goal: .strength,
        daysPerWeek: 3,
        summary: "Two alternating full-body sessions built around six barbell movements.",
        description: "A simple three-day strength routine. Alternate the two sessions, practice the main lifts often and begin with loads that leave clean reps in reserve.",
        days: [
            catalogDay("Foundation A", weekday: 2, items: [
                ("Back Squat (BB)", 3, 5),
                ("Bench Press", 3, 5),
                ("Bent Over Row (BB)", 3, 5)
            ]),
            catalogDay("Foundation B", weekday: 4, items: [
                ("Back Squat (BB)", 3, 5),
                ("OHP (BB)", 3, 5),
                ("Deadlift (Conv)", 1, 5)
            ]),
            catalogDay("Foundation A (repeat)", weekday: 6, items: [
                ("Back Squat (BB)", 3, 5),
                ("Bench Press", 3, 5),
                ("Bent Over Row (BB)", 3, 5)
            ])
        ]
    )

    private static let heavyLightMedium = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000015")!,
        name: "Heavy / Light / Medium 5×5",
        level: .intermediate,
        goal: .strength,
        daysPerWeek: 3,
        summary: "Three full-body days with heavy, lighter and medium-volume exposures.",
        description: "A weekly 5×5 structure for lifters moving beyond session-to-session progression. The same core lifts repeat at different workloads across the week.",
        days: [
            catalogDay("Heavy", weekday: 2, items: [
                ("Back Squat (BB)", 5, 5),
                ("Bench Press", 5, 5),
                ("Bent Over Row (BB)", 5, 5)
            ]),
            catalogDay("Light", weekday: 4, items: [
                ("Back Squat (BB)", 4, 5),
                ("OHP (BB)", 4, 5),
                ("Deadlift (Conv)", 3, 5)
            ]),
            catalogDay("Medium", weekday: 6, items: [
                ("Back Squat (BB)", 4, 5),
                ("Bench Press", 4, 5),
                ("Bent Over Row (BB)", 4, 5),
                ("Barbell Curl", 3, 10),
                ("Triceps Extension", 3, 10)
            ])
        ]
    )

    private static let volumeRecoveryIntensity = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000016")!,
        name: "Volume / Recovery / Intensity",
        level: .intermediate,
        goal: .strength,
        daysPerWeek: 3,
        summary: "A three-day strength week that moves from volume to recovery to intensity.",
        description: "Accumulate work early in the week, recover with a lighter middle session and finish with a low-volume heavy day. This creates a clear weekly rhythm without adding a cycle screen.",
        days: [
            catalogDay("Volume", weekday: 2, items: [
                ("Back Squat (BB)", 5, 5),
                ("Bench Press", 5, 5),
                ("Deadlift (Conv)", 1, 5)
            ]),
            catalogDay("Recovery", weekday: 4, items: [
                ("Front Squat", 2, 5),
                ("OHP (BB)", 3, 5),
                ("Chin-Up", 3, 8),
                ("Plank", 3, 45)
            ]),
            catalogDay("Intensity", weekday: 6, items: [
                ("Back Squat (BB)", 1, 5),
                ("Bench Press", 1, 5),
                ("Deadlift (Conv)", 1, 5),
                ("Pull-Up", 3, 8)
            ])
        ]
    )

    private static let goldenSix = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000017")!,
        name: "Golden Six",
        level: .beginner,
        goal: .hypertrophy,
        daysPerWeek: 3,
        summary: "Six classic movements repeated three times per week for full-body muscle gain.",
        description: "A concise full-body bodybuilding routine. Repeating the same six movements keeps setup simple while each session covers legs, chest, back, shoulders, arms and trunk.",
        days: [
            goldenSixDay("Golden Six A", weekday: 2),
            goldenSixDay("Golden Six B", weekday: 4),
            goldenSixDay("Golden Six C", weekday: 6)
        ]
    )

    private static let balancedFullBody = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000018")!,
        name: "Balanced Full Body",
        level: .beginner,
        goal: .mixed,
        daysPerWeek: 3,
        summary: "Alternating full-body sessions with compounds and balanced accessory work.",
        description: "A beginner-friendly three-day routine that balances strength practice with enough accessory work for even development. Alternate A and B across the week.",
        days: [
            catalogDay("Balanced A", weekday: 2, items: [
                ("Back Squat (BB)", 3, 5),
                ("Bench Press", 3, 5),
                ("Bent Over Row (BB)", 3, 8),
                ("Hamstring Curl", 3, 10),
                ("Face Pull", 3, 12),
                ("Standing Calf Raise", 2, 15)
            ]),
            catalogDay("Balanced B", weekday: 4, items: [
                ("Deadlift (Conv)", 3, 5),
                ("OHP (BB)", 3, 5),
                ("Lat Pulldown", 3, 8),
                ("Bulgarian Split Squat", 3, 10),
                ("Triceps Pushdown", 3, 12),
                ("Plank", 3, 45)
            ]),
            catalogDay("Balanced A (repeat)", weekday: 6, items: [
                ("Back Squat (BB)", 3, 5),
                ("Bench Press", 3, 5),
                ("Bent Over Row (BB)", 3, 8),
                ("Hamstring Curl", 3, 10),
                ("Face Pull", 3, 12),
                ("Standing Calf Raise", 2, 15)
            ])
        ]
    )

    private static let fourFourEight = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000019")!,
        name: "4 / 4 / 8 Barbell",
        level: .beginner,
        goal: .strength,
        daysPerWeek: 3,
        summary: "A three-day barbell routine pairing heavy sets of four with volume sets of eight.",
        description: "Bench and overhead press alternate between heavier and lighter roles while squats, deadlifts and pulling movements round out each session.",
        days: [
            catalogDay("4 / 4 / 8 A", weekday: 2, items: [
                ("Bench Press", 4, 4),
                ("OHP (BB)", 4, 8),
                ("Bent Over Row (BB)", 4, 8),
                ("Back Squat (BB)", 4, 4)
            ]),
            catalogDay("4 / 4 / 8 B", weekday: 4, items: [
                ("OHP (BB)", 4, 4),
                ("Bench Press", 4, 8),
                ("Chin-Up", 4, 8),
                ("Deadlift (Conv)", 4, 4)
            ]),
            catalogDay("4 / 4 / 8 A (repeat)", weekday: 6, items: [
                ("Bench Press", 4, 4),
                ("OHP (BB)", 4, 8),
                ("Bent Over Row (BB)", 4, 8),
                ("Back Squat (BB)", 4, 4)
            ])
        ]
    )

    private static let tenByTen = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000020")!,
        name: "10×10 Hypertrophy",
        level: .intermediate,
        goal: .hypertrophy,
        daysPerWeek: 3,
        summary: "High-volume 10×10 work organized across three focused sessions.",
        description: "A simple high-volume template built around one or two primary 10×10 movements per session, followed by smaller accessory work.",
        days: [
            catalogDay("Chest + Back", weekday: 2, items: [
                ("Bench Press", 10, 10),
                ("Seated Cable Row", 10, 10),
                ("Incline DB Press", 3, 10),
                ("Lat Pulldown", 3, 10)
            ]),
            catalogDay("Legs + Core", weekday: 4, items: [
                ("Back Squat (BB)", 10, 10),
                ("Hamstring Curl", 10, 10),
                ("Standing Calf Raise", 3, 12),
                ("Plank", 3, 45)
            ]),
            catalogDay("Shoulders + Arms", weekday: 6, items: [
                ("OHP (BB)", 10, 10),
                ("Barbell Curl", 10, 10),
                ("Triceps Pushdown", 10, 10),
                ("Lateral Raise (DB)", 3, 12)
            ])
        ]
    )

    private static let classicUpperLower = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000021")!,
        name: "Classic Upper / Lower",
        level: .intermediate,
        goal: .hypertrophy,
        daysPerWeek: 4,
        summary: "Four moderate-volume sessions training each muscle group twice per week.",
        description: "Two upper and two lower sessions with stable exercise selection and practical hypertrophy rep ranges. The second pair changes angles without changing the weekly structure.",
        days: [
            catalogDay("Upper A", weekday: 2, items: [
                ("Bench Press", 4, 8),
                ("Bent Over Row (BB)", 4, 8),
                ("Incline DB Press", 3, 10),
                ("Lat Pulldown", 3, 10),
                ("DB Curl", 3, 12),
                ("Triceps Pushdown", 3, 12)
            ]),
            catalogDay("Lower A", weekday: 3, items: [
                ("Back Squat (BB)", 4, 8),
                ("Romanian DL", 4, 8),
                ("Leg Press", 3, 12),
                ("Hamstring Curl", 3, 12),
                ("Standing Calf Raise", 4, 12)
            ]),
            catalogDay("Upper B", weekday: 5, items: [
                ("OHP (BB)", 4, 8),
                ("Pull-Up", 4, 8),
                ("DB Bench Press", 3, 10),
                ("Seated Cable Row", 3, 10),
                ("Hammer Curl", 3, 12),
                ("Skullcrusher", 3, 12)
            ]),
            catalogDay("Lower B", weekday: 6, items: [
                ("Deadlift (Conv)", 3, 6),
                ("Front Squat", 4, 8),
                ("Bulgarian Split Squat", 3, 10),
                ("Hamstring Curl", 3, 12),
                ("Seated Calf Raise", 4, 12)
            ])
        ]
    )

    private static let machineDumbbellUpperLower = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000022")!,
        name: "Machine + Dumbbell Upper / Lower",
        level: .beginner,
        goal: .hypertrophy,
        daysPerWeek: 4,
        summary: "A four-day upper/lower plan using machines, cables and dumbbells.",
        description: "A barbell-free hypertrophy option for gyms built around machines and dumbbells. Each muscle group is trained twice per week with familiar equipment.",
        days: [
            catalogDay("Upper A", weekday: 2, items: [
                ("Chest Press Machine", 4, 10),
                ("Seated Cable Row", 4, 10),
                ("DB Shoulder Press", 3, 10),
                ("Lat Pulldown", 3, 10),
                ("DB Curl", 3, 12),
                ("Triceps Pushdown", 3, 12)
            ]),
            catalogDay("Lower A", weekday: 3, items: [
                ("Leg Press", 4, 10),
                ("DB Romanian DL", 4, 10),
                ("Leg Extension", 3, 12),
                ("Hamstring Curl", 3, 12),
                ("Standing Calf Raise", 4, 12)
            ]),
            catalogDay("Upper B", weekday: 5, items: [
                ("DB Bench Press", 4, 10),
                ("Chest-Supported Row", 4, 10),
                ("Cable Lateral Raise", 3, 12),
                ("Lat Pulldown", 3, 10),
                ("Hammer Curl", 3, 12),
                ("Triceps Extension", 3, 12)
            ]),
            catalogDay("Lower B", weekday: 6, items: [
                ("Goblet Squat", 4, 10),
                ("DB Romanian DL", 4, 10),
                ("Bulgarian Split Squat", 3, 10),
                ("Hamstring Curl", 3, 12),
                ("Seated Calf Raise", 4, 12)
            ])
        ]
    )

    private static let classicBroSplit = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000023")!,
        name: "Classic Body-Part Split",
        level: .intermediate,
        goal: .hypertrophy,
        daysPerWeek: 5,
        summary: "Five focused sessions with one primary body area trained each day.",
        description: "A traditional bodybuilding week for lifters who prefer focused sessions and higher local volume. Each day has one clear training emphasis.",
        days: [
            catalogDay("Chest", weekday: 2, items: [
                ("Bench Press", 4, 8),
                ("Incline DB Press", 4, 10),
                ("Chest Press Machine", 3, 10),
                ("Cable Crossover", 3, 12),
                ("Push-Up", 3, 15)
            ]),
            catalogDay("Back", weekday: 3, items: [
                ("Deadlift (Conv)", 3, 5),
                ("Pull-Up", 4, 8),
                ("Bent Over Row (BB)", 4, 8),
                ("Seated Cable Row", 3, 10),
                ("Face Pull", 3, 12)
            ]),
            catalogDay("Legs", weekday: 4, items: [
                ("Back Squat (BB)", 4, 8),
                ("Romanian DL", 4, 8),
                ("Leg Press", 4, 10),
                ("Hamstring Curl", 3, 12),
                ("Standing Calf Raise", 4, 12)
            ]),
            catalogDay("Shoulders", weekday: 5, items: [
                ("OHP (BB)", 4, 8),
                ("DB Shoulder Press", 3, 10),
                ("Lateral Raise (DB)", 4, 12),
                ("Rear Delt Fly", 4, 12),
                ("Shrug (DB)", 3, 10)
            ]),
            catalogDay("Arms", weekday: 6, items: [
                ("Barbell Curl", 4, 10),
                ("Close-Grip Bench", 4, 8),
                ("Hammer Curl", 3, 12),
                ("Triceps Pushdown", 3, 12),
                ("Preacher Curl", 3, 12),
                ("Skullcrusher", 3, 12)
            ])
        ]
    )

    private static let dailyStrengthPractice = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000024")!,
        name: "Daily Strength Practice",
        level: .intermediate,
        goal: .strength,
        daysPerWeek: 5,
        summary: "Five short submaximal sessions built around frequent, clean practice.",
        description: "A low-fatigue weekday plan. Each session uses a squat, push, pull, hinge and trunk movement for two crisp working sets instead of one large weekly session.",
        days: [
            dailyPracticeDay("Practice A", weekday: 2, alternate: false),
            dailyPracticeDay("Practice B", weekday: 3, alternate: true),
            dailyPracticeDay("Practice A", weekday: 4, alternate: false),
            dailyPracticeDay("Practice B", weekday: 5, alternate: true),
            dailyPracticeDay("Practice A", weekday: 6, alternate: false)
        ]
    )

    private static let highVolumePowerbuilding = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000025")!,
        name: "High-Volume Powerbuilding",
        level: .advanced,
        goal: .mixed,
        daysPerWeek: 5,
        summary: "Two strength days followed by three higher-volume muscle-building days.",
        description: "A demanding five-day split combining low-rep compound practice with separate back, lower-body and chest-and-arm volume sessions.",
        days: [
            catalogDay("Upper Power", weekday: 2, items: [
                ("Bench Press", 4, 5),
                ("Bent Over Row (BB)", 4, 5),
                ("OHP (BB)", 3, 6),
                ("Weighted Pull-Up", 3, 6),
                ("Barbell Curl", 3, 8),
                ("Close-Grip Bench", 3, 8)
            ]),
            catalogDay("Lower Power", weekday: 3, items: [
                ("Back Squat (BB)", 4, 5),
                ("Deadlift (Conv)", 3, 5),
                ("Leg Press", 3, 8),
                ("Hamstring Curl", 3, 10),
                ("Standing Calf Raise", 4, 10)
            ]),
            catalogDay("Back + Shoulders", weekday: 4, items: [
                ("Pull-Up", 4, 10),
                ("Seated Cable Row", 4, 12),
                ("DB Shoulder Press", 4, 10),
                ("Lateral Raise (DB)", 4, 15),
                ("Face Pull", 4, 15)
            ]),
            catalogDay("Lower Volume", weekday: 5, items: [
                ("Front Squat", 4, 10),
                ("Romanian DL", 4, 10),
                ("Leg Press", 4, 15),
                ("Hamstring Curl", 4, 15),
                ("Seated Calf Raise", 4, 15)
            ]),
            catalogDay("Chest + Arms", weekday: 6, items: [
                ("Incline DB Press", 4, 10),
                ("DB Bench Press", 4, 12),
                ("Cable Crossover", 3, 15),
                ("DB Curl", 4, 12),
                ("Triceps Pushdown", 4, 12),
                ("Hammer Curl", 3, 15)
            ])
        ]
    )

    private static let classicPushPullLegs = ProgramTemplate(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000026")!,
        name: "Classic Push Pull Legs",
        level: .advanced,
        goal: .hypertrophy,
        daysPerWeek: 6,
        summary: "A six-day push, pull and legs rotation with two weekly exposures.",
        description: "A high-frequency hypertrophy split for experienced lifters. The second rotation changes angles while preserving the same push, pull and legs structure.",
        days: [
            catalogDay("Push A", weekday: 2, items: [
                ("Bench Press", 4, 8),
                ("OHP (BB)", 3, 8),
                ("Incline DB Press", 3, 10),
                ("Lateral Raise (DB)", 4, 12),
                ("Triceps Pushdown", 3, 12)
            ]),
            catalogDay("Pull A", weekday: 3, items: [
                ("Deadlift (Conv)", 3, 5),
                ("Pull-Up", 4, 8),
                ("Bent Over Row (BB)", 4, 8),
                ("Face Pull", 3, 12),
                ("Barbell Curl", 3, 10)
            ]),
            catalogDay("Legs A", weekday: 4, items: [
                ("Back Squat (BB)", 4, 8),
                ("Romanian DL", 4, 8),
                ("Leg Press", 3, 12),
                ("Hamstring Curl", 3, 12),
                ("Standing Calf Raise", 4, 15)
            ]),
            catalogDay("Push B", weekday: 5, items: [
                ("OHP (BB)", 4, 8),
                ("DB Bench Press", 4, 10),
                ("Cable Crossover", 3, 12),
                ("Cable Lateral Raise", 4, 12),
                ("Skullcrusher", 3, 12)
            ]),
            catalogDay("Pull B", weekday: 6, items: [
                ("Weighted Pull-Up", 4, 6),
                ("Seated Cable Row", 4, 10),
                ("Single-Arm DB Row", 3, 10),
                ("Rear Delt Fly", 3, 12),
                ("Hammer Curl", 3, 12)
            ]),
            catalogDay("Legs B", weekday: 7, items: [
                ("Front Squat", 4, 8),
                ("DB Romanian DL", 4, 10),
                ("Bulgarian Split Squat", 3, 10),
                ("Leg Extension", 3, 12),
                ("Seated Calf Raise", 4, 15)
            ])
        ]
    )

    private static func catalogDay(
        _ name: String,
        weekday: Int?,
        items: [(exercise: String, sets: Int, reps: Int)]
    ) -> ProgramDay {
        ProgramDay(
            id: UUID(),
            name: name,
            weekday: weekday,
            items: items.map { item in
                ProgramItem(
                    exerciseName: item.exercise,
                    setCount: item.sets,
                    repTarget: item.reps
                )
            }
        )
    }

    private static func goldenSixDay(_ name: String, weekday: Int) -> ProgramDay {
        catalogDay(name, weekday: weekday, items: [
            ("Back Squat (BB)", 4, 10),
            ("Bench Press", 3, 10),
            ("Chin-Up", 3, 8),
            ("OHP (BB)", 4, 10),
            ("Barbell Curl", 3, 10),
            ("Plank", 3, 45)
        ])
    }

    private static func dailyPracticeDay(
        _ name: String,
        weekday: Int,
        alternate: Bool
    ) -> ProgramDay {
        if alternate {
            return catalogDay(name, weekday: weekday, items: [
                ("Front Squat", 2, 5),
                ("OHP (BB)", 2, 5),
                ("Seated Cable Row", 2, 5),
                ("Romanian DL", 2, 5),
                ("Plank", 2, 30)
            ])
        }

        return catalogDay(name, weekday: weekday, items: [
            ("Goblet Squat", 2, 5),
            ("Bench Press", 2, 5),
            ("Pull-Up", 2, 5),
            ("Kettlebell Swing", 2, 10),
            ("Plank", 2, 30)
        ])
    }
}
