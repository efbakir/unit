//
//  ProgramCatalog.swift
//  Unit
//
//  Ten curated starter programs. Each program references exercises from
//  ExerciseCatalog by displayName/alias — ProgramImporter resolves these to
//  real Exercise models on import.
//

import Foundation

enum ProgramCatalog {
    static let all: [ProgramTemplate] = [
        startingStrength,
        gzclp,
        strongCurves,
        upperLower4Day,
        fiveThreeOneBBB,
        metallicadpaPPL,
        dumbbellPPL,
        arnoldSplit,
        nSuns531,
        phul
    ]

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
}
