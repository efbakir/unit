//
//  ExerciseCatalog.swift
//  Unit
//
//  Structured catalog of seed exercises. Used by UnitApp to populate the
//  SwiftData store on first launch and by ProgramImporter to resolve
//  program templates to real Exercise models.
//

import Foundation
import SwiftData

struct CatalogExercise {
    let displayName: String
    let aliases: [String]
    let isBodyweight: Bool
    let muscleGroup: MuscleGroup
    let equipment: Equipment
}

enum ExerciseCatalog {
    private static let curated: [CatalogExercise] = [
        // MARK: Chest
        .init(displayName: "Bench Press", aliases: ["Bench Press (BB)", "Barbell Bench", "Bench Press (Barbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .barbell),
        .init(displayName: "Incline Bench Press", aliases: ["Incline BB Bench", "Incline Bench Press (Barbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .barbell),
        .init(displayName: "Close-Grip Bench", aliases: ["Close Grip Bench Press", "Close Grip Bench Press (Barbell)", "Bench Press - Close Grip (Barbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .barbell),
        .init(displayName: "DB Bench Press", aliases: ["Dumbbell Bench Press", "Bench Press (Dumbbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .dumbbell),
        .init(displayName: "Incline DB Press", aliases: ["Incline DB Bench", "Incline Bench Press (Dumbbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .dumbbell),
        .init(displayName: "DB Fly", aliases: ["Dumbbell Fly", "Chest Fly (Dumbbell)"], isBodyweight: false, muscleGroup: .chest, equipment: .dumbbell),
        .init(displayName: "Chest Press Machine", aliases: ["Machine Chest Press", "Chest Press (Machine)"], isBodyweight: false, muscleGroup: .chest, equipment: .machine),
        .init(displayName: "Pec Dec", aliases: ["Pec Deck", "Pectec", "Pec Deck (Machine)"], isBodyweight: false, muscleGroup: .chest, equipment: .machine),
        .init(displayName: "Cable Crossover", aliases: ["Cable Fly", "Cable Fly Crossovers"], isBodyweight: false, muscleGroup: .chest, equipment: .cable),
        .init(displayName: "Push-Up", aliases: ["Pushup", "Push Up"], isBodyweight: true, muscleGroup: .chest, equipment: .bodyweight),
        .init(displayName: "Push-Up Plus", aliases: ["Serratus Push-Up", "Stable Push-Up Plus"], isBodyweight: true, muscleGroup: .chest, equipment: .bodyweight),
        .init(displayName: "Plyo Push-Up", aliases: ["Plyometric Push-Up"], isBodyweight: true, muscleGroup: .chest, equipment: .bodyweight),
        .init(displayName: "Weighted Dips", aliases: ["Dips"], isBodyweight: false, muscleGroup: .chest, equipment: .bodyweight),

        // MARK: Back
        .init(displayName: "Deadlift (Conv)", aliases: ["Conventional Deadlift", "Deadlift", "Deadlift (Barbell)"], isBodyweight: false, muscleGroup: .back, equipment: .barbell),
        .init(displayName: "Trap Bar Deadlift", aliases: ["Trap-Bar Deadlift", "Hex Bar Deadlift"], isBodyweight: false, muscleGroup: .back, equipment: .barbell),
        .init(displayName: "Bent Over Row (BB)", aliases: ["Barbell Row", "Bent Over Row (Barbell)"], isBodyweight: false, muscleGroup: .back, equipment: .barbell),
        .init(displayName: "Pendlay Row", aliases: ["Pendlay Row (Barbell)"], isBodyweight: false, muscleGroup: .back, equipment: .barbell),
        .init(displayName: "T-Bar Row", aliases: ["T Bar Row"], isBodyweight: false, muscleGroup: .back, equipment: .barbell),
        .init(displayName: "Single-Arm DB Row", aliases: ["One-Arm DB Row", "DB Row", "Bent Over One Arm Row (Dumbbell)", "Dumbbell Row"], isBodyweight: false, muscleGroup: .back, equipment: .dumbbell),
        .init(displayName: "Lat Pulldown", aliases: ["Lat Pulldown (Cable)"], isBodyweight: false, muscleGroup: .back, equipment: .cable),
        .init(displayName: "Seated Cable Row", aliases: ["Cable Row", "Seated Row (Cable)", "Seated Cable Row - V Grip (Cable)"], isBodyweight: false, muscleGroup: .back, equipment: .cable),
        .init(displayName: "Chest-Supported Row", aliases: ["Machine Row"], isBodyweight: false, muscleGroup: .back, equipment: .machine),
        .init(displayName: "Pull-Up", aliases: ["Pullup", "Pull Up"], isBodyweight: true, muscleGroup: .back, equipment: .bodyweight),
        .init(displayName: "Weighted Pull-Up", aliases: ["Pull Up (Weighted)"], isBodyweight: false, muscleGroup: .back, equipment: .bodyweight),
        .init(displayName: "Chin-Up", aliases: ["Chinup", "Chin Up"], isBodyweight: true, muscleGroup: .back, equipment: .bodyweight),
        .init(displayName: "Face Pull", aliases: ["Face Pull (Cable)"], isBodyweight: false, muscleGroup: .back, equipment: .cable),

        // MARK: Shoulders
        .init(displayName: "OHP (BB)", aliases: ["Overhead Press", "OHP", "Military Press", "Overhead Press (Barbell)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .barbell),
        .init(displayName: "Push Press", aliases: [], isBodyweight: false, muscleGroup: .shoulders, equipment: .barbell),
        .init(displayName: "DB Shoulder Press", aliases: ["DB Press", "Seated DB Press", "Overhead Press (Dumbbell)", "Shoulder Press (Dumbbell)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .dumbbell),
        .init(displayName: "Single-Arm DB Press", aliases: ["One-Arm DB Press"], isBodyweight: false, muscleGroup: .shoulders, equipment: .dumbbell),
        .init(displayName: "Lateral Raise (DB)", aliases: ["Lateral Raise", "Side Raise", "Lateral Raise (Dumbbell)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .dumbbell),
        .init(displayName: "Rear Delt Fly", aliases: ["Reverse Fly", "Reverse Fly (Dumbbell)", "Rear Delt Reverse Fly (Dumbbell)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .dumbbell),
        .init(displayName: "Cable Lateral Raise", aliases: ["Lateral Raise (Cable)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .cable),
        .init(displayName: "Shrug (DB)", aliases: ["DB Shrug", "Shrug (Dumbbell)"], isBodyweight: false, muscleGroup: .shoulders, equipment: .dumbbell),

        // MARK: Biceps
        .init(displayName: "Barbell Curl", aliases: ["BB Curl", "Bicep Curl (Barbell)"], isBodyweight: false, muscleGroup: .biceps, equipment: .barbell),
        .init(displayName: "DB Curl", aliases: ["Curl", "Biceps Curl", "Dumbbell Curl", "Bicep Curl (Dumbbell)"], isBodyweight: false, muscleGroup: .biceps, equipment: .dumbbell),
        .init(displayName: "Hammer Curl", aliases: ["Hammer Curl (Dumbbell)"], isBodyweight: false, muscleGroup: .biceps, equipment: .dumbbell),
        .init(displayName: "Preacher Curl", aliases: ["Preacher Curl (Machine)"], isBodyweight: false, muscleGroup: .biceps, equipment: .machine),
        .init(displayName: "Cable Curl", aliases: ["Bicep Curl (Cable)"], isBodyweight: false, muscleGroup: .biceps, equipment: .cable),

        // MARK: Triceps
        .init(displayName: "Triceps Extension", aliases: ["Triceps", "Overhead Triceps Extension", "Triceps Extension (Dumbbell)"], isBodyweight: false, muscleGroup: .triceps, equipment: .dumbbell),
        .init(displayName: "Triceps Pushdown", aliases: ["Cable Pushdown", "Triceps Pushdown (Cable - Straight Bar)"], isBodyweight: false, muscleGroup: .triceps, equipment: .cable),
        .init(displayName: "Skullcrusher", aliases: ["Lying Triceps Extension", "Skullcrusher (Barbell)"], isBodyweight: false, muscleGroup: .triceps, equipment: .barbell),
        .init(displayName: "Triceps Dip", aliases: ["Bench Dip"], isBodyweight: true, muscleGroup: .triceps, equipment: .bodyweight),

        // MARK: Quads
        .init(displayName: "Back Squat (BB)", aliases: ["Back Squat", "Squat", "Squat (Barbell)"], isBodyweight: false, muscleGroup: .quads, equipment: .barbell),
        .init(displayName: "Front Squat", aliases: ["Front Squat (Barbell)"], isBodyweight: false, muscleGroup: .quads, equipment: .barbell),
        .init(displayName: "Goblet Squat", aliases: [], isBodyweight: false, muscleGroup: .quads, equipment: .dumbbell),
        .init(displayName: "Leg Press", aliases: ["Leg Press (Machine)"], isBodyweight: false, muscleGroup: .quads, equipment: .machine),
        .init(displayName: "Leg Extension", aliases: ["Leg Extension (Machine)"], isBodyweight: false, muscleGroup: .quads, equipment: .machine),
        .init(displayName: "Bulgarian Split Squat", aliases: ["Split Squat"], isBodyweight: false, muscleGroup: .quads, equipment: .dumbbell),
        .init(displayName: "Walking Lunge", aliases: ["Lunge", "Walking Lunge (Dumbbell)", "Lunge (Dumbbell)"], isBodyweight: false, muscleGroup: .quads, equipment: .dumbbell),
        .init(displayName: "Step-Up", aliases: [], isBodyweight: false, muscleGroup: .quads, equipment: .dumbbell),

        // MARK: Hamstrings
        .init(displayName: "Romanian DL", aliases: ["Romanian Deadlift", "RDL", "Romanian Deadlift (Barbell)"], isBodyweight: false, muscleGroup: .hamstrings, equipment: .barbell),
        .init(displayName: "DB Romanian DL", aliases: ["DB RDL", "Romanian Deadlift (Dumbbell)"], isBodyweight: false, muscleGroup: .hamstrings, equipment: .dumbbell),
        .init(displayName: "Hamstring Curl", aliases: ["Leg Curl", "Seated Leg Curl", "Seated Leg Curl (Machine)", "Lying Leg Curl (Machine)"], isBodyweight: false, muscleGroup: .hamstrings, equipment: .machine),
        .init(displayName: "Nordic Curl", aliases: [], isBodyweight: true, muscleGroup: .hamstrings, equipment: .bodyweight),
        .init(displayName: "Good Morning", aliases: ["Good Morning (Barbell)"], isBodyweight: false, muscleGroup: .hamstrings, equipment: .barbell),

        // MARK: Glutes
        .init(displayName: "Hip Thrust", aliases: ["Barbell Hip Thrust", "Hip Thrust (Barbell)"], isBodyweight: false, muscleGroup: .glutes, equipment: .barbell),
        .init(displayName: "Glute Bridge", aliases: [], isBodyweight: true, muscleGroup: .glutes, equipment: .bodyweight),
        .init(displayName: "Cable Kickback", aliases: [], isBodyweight: false, muscleGroup: .glutes, equipment: .cable),
        .init(displayName: "Glute Ham Raise", aliases: ["GHR"], isBodyweight: true, muscleGroup: .glutes, equipment: .bodyweight),

        // MARK: Calves
        .init(displayName: "Standing Calf Raise", aliases: ["Calf Raise", "Standing Calf Raise (Machine)"], isBodyweight: false, muscleGroup: .calves, equipment: .machine),
        .init(displayName: "Seated Calf Raise", aliases: ["Seated Calf Raise (Machine)", "Seated Calf Raise (Plate Loaded)"], isBodyweight: false, muscleGroup: .calves, equipment: .machine),
        .init(displayName: "DB Calf Raise", aliases: [], isBodyweight: false, muscleGroup: .calves, equipment: .dumbbell),

        // MARK: Core
        .init(displayName: "Plank", aliases: [], isBodyweight: true, muscleGroup: .core, equipment: .bodyweight),
        .init(displayName: "Hanging Leg Raise", aliases: ["Leg Raise"], isBodyweight: true, muscleGroup: .core, equipment: .bodyweight),
        .init(displayName: "Cable Crunch", aliases: [], isBodyweight: false, muscleGroup: .core, equipment: .cable),
        .init(displayName: "Pallof Press", aliases: [], isBodyweight: false, muscleGroup: .core, equipment: .cable),
        .init(displayName: "Ab Wheel", aliases: ["Ab Rollout"], isBodyweight: true, muscleGroup: .core, equipment: .other),

        // MARK: Forearms
        .init(displayName: "Wrist Curl", aliases: [], isBodyweight: false, muscleGroup: .forearms, equipment: .dumbbell),
        .init(displayName: "Reverse Curl", aliases: [], isBodyweight: false, muscleGroup: .forearms, equipment: .barbell),
        .init(displayName: "Iso Plate Hold", aliases: ["Plate Hold", "Isometric Plate Hold"], isBodyweight: false, muscleGroup: .forearms, equipment: .other),
        .init(displayName: "Rice Bucket", aliases: ["Rice Bucket Drill"], isBodyweight: false, muscleGroup: .forearms, equipment: .other),

        // MARK: Full body / conditioning
        .init(displayName: "Kettlebell Swing", aliases: ["KB Swing"], isBodyweight: false, muscleGroup: .fullBody, equipment: .kettlebell),
        .init(displayName: "DB Snatch", aliases: [], isBodyweight: false, muscleGroup: .fullBody, equipment: .dumbbell),
        .init(displayName: "Clean & Press", aliases: [], isBodyweight: false, muscleGroup: .fullBody, equipment: .barbell),
        .init(displayName: "Squat Jump", aliases: ["Jump Squat"], isBodyweight: true, muscleGroup: .fullBody, equipment: .bodyweight),
        .init(displayName: "Rotational Med Ball Wall Throw", aliases: ["Med-Ball Rotational Wall Throw", "Rotational Wall Throw"], isBodyweight: false, muscleGroup: .fullBody, equipment: .other),
        .init(displayName: "Broad Jump", aliases: [], isBodyweight: true, muscleGroup: .fullBody, equipment: .bodyweight),
        .init(displayName: "Box Jump", aliases: [], isBodyweight: true, muscleGroup: .fullBody, equipment: .bodyweight),
        .init(displayName: "Neck Training", aliases: ["Neck", "Neck Flexion and Extension"], isBodyweight: true, muscleGroup: .fullBody, equipment: .bodyweight)
    ]

    /// Unit's curated catalog stays first so its concise names and aliases win
    /// when the public-domain source contains the same movement.
    static let all: [CatalogExercise] = {
        var knownSignatures: Set<String> = []
        return (curated + publicDomain).filter { entry in
            let signatures = Set(([entry.displayName] + entry.aliases).map(normalize))
            guard signatures.isDisjoint(with: knownSignatures) else { return false }
            knownSignatures.formUnion(signatures)
            return true
        }
    }()

    /// Populate the local exercise database without changing, renaming, or
    /// unarchiving anything the lifter already owns. The picker invokes this
    /// lazily, so the full offline catalog does not slow the normal launch path.
    @MainActor
    @discardableResult
    static func ensurePersisted(
        in modelContext: ModelContext,
        existingExercises: [Exercise]
    ) -> Int {
        var exerciseBySignature: [String: Exercise] = [:]
        for exercise in existingExercises {
            for signature in ([exercise.displayName] + exercise.aliases).map(normalize) {
                exerciseBySignature[signature] = exercise
            }
        }

        var insertedCount = 0
        for entry in all {
            let signatures = ([entry.displayName] + entry.aliases).map(normalize)
            if signatures.contains(where: { exerciseBySignature[$0] != nil }) {
                continue
            }

            let exercise = Exercise(
                displayName: entry.displayName,
                aliases: entry.aliases,
                isBodyweight: entry.isBodyweight,
                muscleGroup: entry.muscleGroup,
                equipment: entry.equipment
            )
            modelContext.insert(exercise)
            for signature in signatures {
                exerciseBySignature[signature] = exercise
            }
            insertedCount += 1
        }

        if insertedCount > 0 {
            try? modelContext.save()
        }
        return insertedCount
    }

    /// Source: yuhonas/free-exercise-db (Unlicense / public domain), snapshot
    /// downloaded 2026-08-13. Unit imports names and basic classification only;
    /// it does not bundle the source dataset's instructions or imagery.
    private static let publicDomain: [CatalogExercise] = publicDomainRows
        .split(separator: "\n")
        .compactMap { row in
            let fields = row.split(separator: "|", omittingEmptySubsequences: false)
            guard fields.count == 3,
                  let equipment = Equipment(rawValue: String(fields[1])),
                  let muscleGroup = MuscleGroup(rawValue: String(fields[2])) else {
                return nil
            }
            return CatalogExercise(
                displayName: String(fields[0]),
                aliases: [],
                isBodyweight: equipment == .bodyweight,
                muscleGroup: muscleGroup,
                equipment: equipment
            )
        }

    private static let publicDomainRows = """
    3/4 Sit-Up|bodyweight|core
    90/90 Hamstring|bodyweight|hamstrings
    Ab Crunch Machine|machine|core
    Ab Roller|other|core
    Adductor|other|glutes
    Adductor/Groin|other|glutes
    Advanced Kettlebell Windmill|kettlebell|core
    Air Bike|bodyweight|core
    All Fours Quad Stretch|bodyweight|quads
    Alternate Hammer Curl|dumbbell|biceps
    Alternate Heel Touchers|bodyweight|core
    Alternate Incline Dumbbell Curl|dumbbell|biceps
    Alternate Leg Diagonal Bound|other|quads
    Alternating Cable Shoulder Press|cable|shoulders
    Alternating Deltoid Raise|dumbbell|shoulders
    Alternating Floor Press|kettlebell|chest
    Alternating Hang Clean|kettlebell|hamstrings
    Alternating Kettlebell Press|kettlebell|shoulders
    Alternating Kettlebell Row|kettlebell|back
    Alternating Renegade Row|kettlebell|back
    Ankle Circles|other|calves
    Ankle On The Knee|other|glutes
    Anterior Tibialis-SMR|other|calves
    Anti-Gravity Press|barbell|shoulders
    Arm Circles|other|shoulders
    Arnold Dumbbell Press|dumbbell|shoulders
    Around The Worlds|dumbbell|chest
    Atlas Stone Trainer|other|back
    Atlas Stones|other|back
    Axle Deadlift|other|back
    Back Flyes - With Bands|band|shoulders
    Backward Drag|other|quads
    Backward Medicine Ball Throw|other|shoulders
    Balance Board|other|calves
    Ball Leg Curl|other|hamstrings
    Band Assisted Pull-Up|other|back
    Band Good Morning|band|hamstrings
    Band Good Morning (Pull Through)|band|hamstrings
    Band Hip Adductions|band|glutes
    Band Pull Apart|band|shoulders
    Band Skull Crusher|band|triceps
    Barbell Ab Rollout|barbell|core
    Barbell Ab Rollout - On Knees|barbell|core
    Barbell Bench Press - Medium Grip|barbell|chest
    Barbell Curl|barbell|biceps
    Barbell Curls Lying Against An Incline|barbell|biceps
    Barbell Deadlift|barbell|back
    Barbell Full Squat|barbell|quads
    Barbell Glute Bridge|barbell|glutes
    Barbell Guillotine Bench Press|barbell|chest
    Barbell Hack Squat|barbell|quads
    Barbell Hip Thrust|barbell|glutes
    Barbell Incline Bench Press - Medium Grip|barbell|chest
    Barbell Incline Shoulder Raise|barbell|shoulders
    Barbell Lunge|barbell|quads
    Barbell Rear Delt Row|barbell|shoulders
    Barbell Rollout from Bench|barbell|core
    Barbell Seated Calf Raise|barbell|calves
    Barbell Shoulder Press|barbell|shoulders
    Barbell Shrug|barbell|back
    Barbell Shrug Behind The Back|barbell|back
    Barbell Side Bend|barbell|core
    Barbell Side Split Squat|barbell|quads
    Barbell Squat|barbell|quads
    Barbell Squat To A Bench|barbell|quads
    Barbell Step Ups|barbell|quads
    Barbell Walking Lunge|barbell|quads
    Battling Ropes|other|shoulders
    Bear Crawl Sled Drags|other|quads
    Behind Head Chest Stretch|other|chest
    Bench Dips|bodyweight|triceps
    Bench Jump|bodyweight|quads
    Bench Press - Powerlifting|barbell|triceps
    Bench Press - With Bands|band|chest
    Bench Press with Chains|barbell|triceps
    Bench Sprint|other|quads
    Bent-Arm Barbell Pullover|barbell|back
    Bent-Arm Dumbbell Pullover|dumbbell|chest
    Bent-Knee Hip Raise|bodyweight|core
    Bent Over Barbell Row|barbell|back
    Bent Over Dumbbell Rear Delt Raise With Head On Bench|dumbbell|shoulders
    Bent Over Low-Pulley Side Lateral|cable|shoulders
    Bent Over One-Arm Long Bar Row|barbell|back
    Bent Over Two-Arm Long Bar Row|barbell|back
    Bent Over Two-Dumbbell Row|dumbbell|back
    Bent Over Two-Dumbbell Row With Palms In|dumbbell|back
    Bent Press|kettlebell|core
    Bicycling|other|quads
    Bicycling, Stationary|machine|quads
    Board Press|barbell|triceps
    Body-Up|bodyweight|triceps
    Body Tricep Press|bodyweight|triceps
    Bodyweight Flyes|barbell|chest
    Bodyweight Mid Row|other|back
    Bodyweight Squat|bodyweight|quads
    Bodyweight Walking Lunge|other|quads
    Bosu Ball Cable Crunch With Side Bends|cable|core
    Bottoms-Up Clean From The Hang Position|kettlebell|forearms
    Bottoms Up|bodyweight|core
    Box Jump (Multiple Response)|other|hamstrings
    Box Skip|other|hamstrings
    Box Squat|barbell|quads
    Box Squat with Bands|barbell|quads
    Box Squat with Chains|barbell|quads
    Brachialis-SMR|other|biceps
    Bradford/Rocky Presses|barbell|shoulders
    Butt-Ups|bodyweight|core
    Butt Lift (Bridge)|bodyweight|glutes
    Butterfly|machine|chest
    Cable Chest Press|cable|chest
    Cable Crossover|cable|chest
    Cable Crunch|cable|core
    Cable Deadlifts|cable|quads
    Cable Hammer Curls - Rope Attachment|cable|biceps
    Cable Hip Adduction|cable|quads
    Cable Incline Pushdown|cable|back
    Cable Incline Triceps Extension|cable|triceps
    Cable Internal Rotation|cable|shoulders
    Cable Iron Cross|cable|chest
    Cable Judo Flip|cable|core
    Cable Lying Triceps Extension|cable|triceps
    Cable One Arm Tricep Extension|cable|triceps
    Cable Preacher Curl|cable|biceps
    Cable Rear Delt Fly|cable|shoulders
    Cable Reverse Crunch|cable|core
    Cable Rope Overhead Triceps Extension|cable|triceps
    Cable Rope Rear-Delt Rows|cable|shoulders
    Cable Russian Twists|cable|core
    Cable Seated Crunch|cable|core
    Cable Seated Lateral Raise|cable|shoulders
    Cable Shoulder Press|cable|shoulders
    Cable Shrugs|cable|back
    Cable Wrist Curl|cable|forearms
    Calf-Machine Shoulder Shrug|machine|back
    Calf Press|machine|calves
    Calf Press On The Leg Press Machine|machine|calves
    Calf Raise On A Dumbbell|dumbbell|calves
    Calf Raises - With Bands|band|calves
    Calf Stretch Elbows Against Wall|other|calves
    Calf Stretch Hands Against Wall|other|calves
    Calves-SMR|other|calves
    Car Deadlift|other|quads
    Car Drivers|barbell|shoulders
    Carioca Quick Step|other|glutes
    Cat Stretch|other|back
    Catch and Overhead Throw|other|back
    Chain Handle Extension|other|triceps
    Chain Press|other|chest
    Chair Leg Extended Stretch|other|hamstrings
    Chair Lower Back Stretch|other|back
    Chair Squat|machine|quads
    Chair Upper Body Stretch|other|shoulders
    Chest And Front Of Shoulder Stretch|other|chest
    Chest Push from 3 point stance|other|chest
    Chest Push (multiple response)|other|chest
    Chest Push (single response)|other|chest
    Chest Push with Run Release|other|chest
    Chest Stretch on Stability Ball|other|chest
    Child's Pose|other|back
    Chin-Up|bodyweight|back
    Chin To Chest Stretch|other|fullBody
    Circus Bell|other|shoulders
    Clean|barbell|hamstrings
    Clean Deadlift|barbell|hamstrings
    Clean Pull|barbell|quads
    Clean Shrug|barbell|back
    Clean and Jerk|barbell|shoulders
    Clean and Press|barbell|shoulders
    Clean from Blocks|barbell|quads
    Clock Push-Up|bodyweight|chest
    Close-Grip Barbell Bench Press|barbell|triceps
    Close-Grip Dumbbell Press|dumbbell|triceps
    Close-Grip EZ-Bar Curl with Band|barbell|biceps
    Close-Grip EZ-Bar Press|barbell|triceps
    Close-Grip EZ Bar Curl|barbell|biceps
    Close-Grip Front Lat Pulldown|cable|back
    Close-Grip Push-Up off of a Dumbbell|bodyweight|triceps
    Close-Grip Standing Barbell Curl|barbell|biceps
    Cocoons|bodyweight|core
    Conan's Wheel|other|quads
    Concentration Curls|dumbbell|biceps
    Cross-Body Crunch|bodyweight|core
    Cross Body Hammer Curl|dumbbell|biceps
    Cross Over - With Bands|band|chest
    Crossover Reverse Lunge|other|back
    Crucifix|other|shoulders
    Crunch - Hands Overhead|bodyweight|core
    Crunch - Legs On Exercise Ball|bodyweight|core
    Crunches|bodyweight|core
    Cuban Press|dumbbell|shoulders
    Dancer's Stretch|other|back
    Dead Bug|bodyweight|core
    Deadlift with Bands|barbell|back
    Deadlift with Chains|barbell|back
    Decline Barbell Bench Press|barbell|chest
    Decline Close-Grip Bench To Skull Crusher|barbell|triceps
    Decline Crunch|bodyweight|core
    Decline Dumbbell Bench Press|dumbbell|chest
    Decline Dumbbell Flyes|dumbbell|chest
    Decline Dumbbell Triceps Extension|dumbbell|triceps
    Decline EZ Bar Triceps Extension|barbell|triceps
    Decline Oblique Crunch|bodyweight|core
    Decline Push-Up|other|chest
    Decline Reverse Crunch|bodyweight|core
    Decline Smith Press|machine|chest
    Deficit Deadlift|barbell|back
    Depth Jump Leap|other|quads
    Dip Machine|machine|triceps
    Dips - Chest Version|other|chest
    Dips - Triceps Version|bodyweight|triceps
    Donkey Calf Raises|other|calves
    Double Kettlebell Alternating Hang Clean|kettlebell|hamstrings
    Double Kettlebell Jerk|kettlebell|shoulders
    Double Kettlebell Push Press|kettlebell|shoulders
    Double Kettlebell Snatch|kettlebell|shoulders
    Double Kettlebell Windmill|kettlebell|core
    Double Leg Butt Kick|bodyweight|quads
    Downward Facing Balance|other|glutes
    Drag Curl|barbell|biceps
    Drop Push|other|chest
    Dumbbell Alternate Bicep Curl|dumbbell|biceps
    Dumbbell Bench Press|dumbbell|chest
    Dumbbell Bench Press with Neutral Grip|dumbbell|chest
    Dumbbell Bicep Curl|dumbbell|biceps
    Dumbbell Clean|dumbbell|hamstrings
    Dumbbell Floor Press|dumbbell|triceps
    Dumbbell Flyes|dumbbell|chest
    Dumbbell Incline Row|dumbbell|back
    Dumbbell Incline Shoulder Raise|dumbbell|shoulders
    Dumbbell Lunges|dumbbell|quads
    Dumbbell Lying One-Arm Rear Lateral Raise|dumbbell|shoulders
    Dumbbell Lying Pronation|dumbbell|forearms
    Dumbbell Lying Rear Lateral Raise|dumbbell|shoulders
    Dumbbell Lying Supination|dumbbell|forearms
    Dumbbell One-Arm Shoulder Press|dumbbell|shoulders
    Dumbbell One-Arm Triceps Extension|dumbbell|triceps
    Dumbbell One-Arm Upright Row|dumbbell|shoulders
    Dumbbell Prone Incline Curl|dumbbell|biceps
    Dumbbell Raise|dumbbell|shoulders
    Dumbbell Rear Lunge|dumbbell|quads
    Dumbbell Scaption|dumbbell|shoulders
    Dumbbell Seated Box Jump|dumbbell|quads
    Dumbbell Seated One-Leg Calf Raise|dumbbell|calves
    Dumbbell Shoulder Press|dumbbell|shoulders
    Dumbbell Shrug|dumbbell|back
    Dumbbell Side Bend|dumbbell|core
    Dumbbell Squat|dumbbell|quads
    Dumbbell Squat To A Bench|dumbbell|quads
    Dumbbell Step Ups|dumbbell|quads
    Dumbbell Tricep Extension -Pronated Grip|dumbbell|triceps
    Dynamic Back Stretch|other|back
    Dynamic Chest Stretch|other|chest
    EZ-Bar Curl|barbell|biceps
    EZ-Bar Skullcrusher|barbell|triceps
    Elbow Circles|other|shoulders
    Elbow to Knee|bodyweight|core
    Elbows Back|other|chest
    Elevated Back Lunge|barbell|quads
    Elevated Cable Rows|cable|back
    Elliptical Trainer|machine|quads
    Exercise Ball Crunch|other|core
    Exercise Ball Pull-In|other|core
    Extended Range One-Arm Kettlebell Floor Press|kettlebell|chest
    External Rotation|dumbbell|shoulders
    External Rotation with Band|band|shoulders
    External Rotation with Cable|cable|shoulders
    Face Pull|cable|shoulders
    Farmer's Walk|other|forearms
    Fast Skipping|bodyweight|quads
    Finger Curls|barbell|forearms
    Flat Bench Cable Flyes|cable|chest
    Flat Bench Leg Pull-In|bodyweight|core
    Flat Bench Lying Leg Raise|bodyweight|core
    Flexor Incline Dumbbell Curls|dumbbell|biceps
    Floor Glute-Ham Raise|other|hamstrings
    Floor Press|barbell|triceps
    Floor Press with Chains|barbell|triceps
    Flutter Kicks|bodyweight|glutes
    Foot-SMR|other|calves
    Forward Drag with Press|other|chest
    Frankenstein Squat|barbell|quads
    Freehand Jump Squat|bodyweight|quads
    Frog Hops|other|quads
    Frog Sit-Ups|bodyweight|core
    Front Barbell Squat|barbell|quads
    Front Barbell Squat To A Bench|barbell|quads
    Front Box Jump|other|hamstrings
    Front Cable Raise|cable|shoulders
    Front Cone Hops (or hurdle hops)|other|quads
    Front Dumbbell Raise|dumbbell|shoulders
    Front Incline Dumbbell Raise|dumbbell|shoulders
    Front Leg Raises|bodyweight|hamstrings
    Front Plate Raise|other|shoulders
    Front Raise And Pullover|barbell|chest
    Front Squat (Clean Grip)|barbell|quads
    Front Squats With Two Kettlebells|kettlebell|quads
    Front Two-Dumbbell Raise|dumbbell|shoulders
    Full Range-Of-Motion Lat Pulldown|cable|back
    Gironda Sternum Chins|other|back
    Glute Ham Raise|machine|hamstrings
    Glute Kickback|bodyweight|glutes
    Goblet Squat|kettlebell|quads
    Good Morning|barbell|hamstrings
    Good Morning off Pins|barbell|hamstrings
    Gorilla Chin/Crunch|bodyweight|core
    Groin and Back Stretch|other|glutes
    Groiners|bodyweight|glutes
    Hack Squat|machine|quads
    Hammer Curls|dumbbell|biceps
    Hammer Grip Incline DB Bench Press|dumbbell|chest
    Hamstring-SMR|other|hamstrings
    Hamstring Stretch|other|hamstrings
    Handstand Push-Ups|bodyweight|shoulders
    Hang Clean|barbell|quads
    Hang Clean - Below the Knees|barbell|quads
    Hang Snatch|barbell|hamstrings
    Hang Snatch - Below Knees|barbell|hamstrings
    Hanging Bar Good Morning|barbell|hamstrings
    Hanging Leg Raise|bodyweight|core
    Hanging Pike|bodyweight|core
    Heaving Snatch Balance|barbell|quads
    Heavy Bag Thrust|other|chest
    High Cable Curls|cable|biceps
    Hip Circles (prone)|bodyweight|glutes
    Hip Extension with Bands|band|glutes
    Hip Flexion with Band|band|quads
    Hip Lift with Band|band|glutes
    Hug A Ball|other|back
    Hug Knees To Chest|other|back
    Hurdle Hops|other|hamstrings
    Hyperextensions (Back Extensions)|other|back
    Hyperextensions With No Hyperextension Bench|bodyweight|back
    IT Band and Glute Stretch|other|glutes
    Iliotibial Tract-SMR|other|glutes
    Inchworm|bodyweight|hamstrings
    Incline Barbell Triceps Extension|barbell|triceps
    Incline Bench Pull|barbell|back
    Incline Cable Chest Press|cable|chest
    Incline Cable Flye|cable|chest
    Incline Dumbbell Bench With Palms Facing In|dumbbell|chest
    Incline Dumbbell Curl|dumbbell|biceps
    Incline Dumbbell Flyes|dumbbell|chest
    Incline Dumbbell Flyes - With A Twist|dumbbell|chest
    Incline Dumbbell Press|dumbbell|chest
    Incline Hammer Curls|dumbbell|biceps
    Incline Inner Biceps Curl|dumbbell|biceps
    Incline Push-Up|bodyweight|chest
    Incline Push-Up Close-Grip|bodyweight|triceps
    Incline Push-Up Depth Jump|other|chest
    Incline Push-Up Medium|bodyweight|chest
    Incline Push-Up Reverse Grip|bodyweight|chest
    Incline Push-Up Wide|bodyweight|chest
    Intermediate Groin Stretch|other|hamstrings
    Intermediate Hip Flexor and Quad Stretch|other|quads
    Internal Rotation with Band|band|shoulders
    Inverted Row|other|back
    Inverted Row with Straps|other|back
    Iron Cross|dumbbell|shoulders
    Iron Crosses (stretch)|other|quads
    Isometric Chest Squeezes|bodyweight|chest
    Isometric Neck Exercise - Front And Back|bodyweight|fullBody
    Isometric Neck Exercise - Sides|bodyweight|fullBody
    Isometric Wipers|bodyweight|chest
    JM Press|barbell|triceps
    Jackknife Sit-Up|bodyweight|core
    Janda Sit-Up|bodyweight|core
    Jefferson Squats|barbell|quads
    Jerk Balance|barbell|shoulders
    Jerk Dip Squat|barbell|quads
    Jogging, Treadmill|machine|quads
    Keg Load|other|back
    Kettlebell Arnold Press|kettlebell|shoulders
    Kettlebell Dead Clean|kettlebell|hamstrings
    Kettlebell Figure 8|kettlebell|core
    Kettlebell Hang Clean|kettlebell|hamstrings
    Kettlebell One-Legged Deadlift|kettlebell|hamstrings
    Kettlebell Pass Between The Legs|kettlebell|core
    Kettlebell Pirate Ships|kettlebell|shoulders
    Kettlebell Pistol Squat|kettlebell|quads
    Kettlebell Seated Press|kettlebell|shoulders
    Kettlebell Seesaw Press|kettlebell|shoulders
    Kettlebell Sumo High Pull|kettlebell|back
    Kettlebell Thruster|kettlebell|shoulders
    Kettlebell Turkish Get-Up (Lunge style)|kettlebell|shoulders
    Kettlebell Turkish Get-Up (Squat style)|kettlebell|shoulders
    Kettlebell Windmill|kettlebell|core
    Kipping Muscle Up|other|back
    Knee Across The Body|other|glutes
    Knee Circles|bodyweight|calves
    Knee/Hip Raise On Parallel Bars|other|core
    Knee Tuck Jump|bodyweight|hamstrings
    Kneeling Arm Drill|other|shoulders
    Kneeling Cable Crunch With Alternating Oblique Twists|cable|core
    Kneeling Cable Triceps Extension|cable|triceps
    Kneeling Forearm Stretch|other|forearms
    Kneeling High Pulley Row|cable|back
    Kneeling Hip Flexor|other|quads
    Kneeling Jump Squat|barbell|glutes
    Kneeling Single-Arm High Pulley Row|cable|back
    Kneeling Squat|barbell|glutes
    Landmine 180's|barbell|core
    Landmine Linear Jammer|barbell|shoulders
    Lateral Bound|bodyweight|glutes
    Lateral Box Jump|other|glutes
    Lateral Cone Hops|other|glutes
    Lateral Raise - With Bands|band|shoulders
    Latissimus Dorsi-SMR|other|back
    Leg-Over Floor Press|kettlebell|chest
    Leg-Up Hamstring Stretch|other|hamstrings
    Leg Extensions|machine|quads
    Leg Lift|bodyweight|glutes
    Leg Press|machine|quads
    Leg Pull-In|bodyweight|core
    Leverage Chest Press|machine|chest
    Leverage Deadlift|machine|quads
    Leverage Decline Chest Press|machine|chest
    Leverage High Row|machine|back
    Leverage Incline Chest Press|machine|chest
    Leverage Iso Row|machine|back
    Leverage Shoulder Press|machine|shoulders
    Leverage Shrug|machine|back
    Linear 3-Part Start Technique|other|hamstrings
    Linear Acceleration Wall Drill|other|hamstrings
    Linear Depth Jump|other|quads
    Log Lift|other|shoulders
    London Bridges|other|back
    Looking At Ceiling|other|quads
    Low Cable Crossover|cable|chest
    Low Cable Triceps Extension|cable|triceps
    Low Pulley Row To Neck|cable|shoulders
    Lower Back-SMR|other|back
    Lower Back Curl|bodyweight|core
    Lunge Pass Through|kettlebell|hamstrings
    Lunge Sprint|machine|quads
    Lying Bent Leg Groin|other|glutes
    Lying Cable Curl|cable|biceps
    Lying Cambered Barbell Row|barbell|back
    Lying Close-Grip Bar Curl On High Pulley|cable|biceps
    Lying Close-Grip Barbell Triceps Extension Behind The Head|barbell|triceps
    Lying Close-Grip Barbell Triceps Press To Chin|barbell|triceps
    Lying Crossover|bodyweight|glutes
    Lying Dumbbell Tricep Extension|dumbbell|triceps
    Lying Face Down Plate Neck Resistance|other|fullBody
    Lying Face Up Plate Neck Resistance|other|fullBody
    Lying Glute|bodyweight|glutes
    Lying Hamstring|other|hamstrings
    Lying High Bench Barbell Curl|barbell|biceps
    Lying Leg Curls|machine|hamstrings
    Lying Machine Squat|machine|quads
    Lying One-Arm Lateral Raise|dumbbell|shoulders
    Lying Prone Quadriceps|bodyweight|quads
    Lying Rear Delt Raise|dumbbell|shoulders
    Lying Supine Dumbbell Curl|dumbbell|biceps
    Lying T-Bar Row|machine|back
    Lying Triceps Press|barbell|triceps
    Machine Bench Press|machine|chest
    Machine Bicep Curl|machine|biceps
    Machine Preacher Curls|machine|biceps
    Machine Shoulder (Military) Press|machine|shoulders
    Machine Triceps Extension|machine|triceps
    Medicine Ball Chest Pass|other|chest
    Medicine Ball Full Twist|other|core
    Medicine Ball Scoop Throw|other|shoulders
    Middle Back Shrug|dumbbell|back
    Middle Back Stretch|other|back
    Mixed Grip Chin|other|back
    Monster Walk|band|glutes
    Mountain Climbers|other|quads
    Moving Claw Series|other|hamstrings
    Muscle Snatch|barbell|hamstrings
    Muscle Up|other|back
    Narrow Stance Hack Squats|machine|quads
    Narrow Stance Leg Press|machine|quads
    Narrow Stance Squats|barbell|quads
    Natural Glute Ham Raise|bodyweight|hamstrings
    Neck-SMR|other|fullBody
    Neck Press|barbell|chest
    Oblique Crunches|bodyweight|core
    Oblique Crunches - On The Floor|bodyweight|core
    Olympic Squat|barbell|quads
    On-Your-Back Quad Stretch|other|quads
    On Your Side Quad Stretch|other|quads
    One-Arm Dumbbell Row|dumbbell|back
    One-Arm Flat Bench Dumbbell Flye|dumbbell|chest
    One-Arm High-Pulley Cable Side Bends|cable|core
    One-Arm Incline Lateral Raise|dumbbell|shoulders
    One-Arm Kettlebell Clean|kettlebell|hamstrings
    One-Arm Kettlebell Clean and Jerk|kettlebell|shoulders
    One-Arm Kettlebell Floor Press|kettlebell|chest
    One-Arm Kettlebell Jerk|kettlebell|shoulders
    One-Arm Kettlebell Military Press To The Side|kettlebell|shoulders
    One-Arm Kettlebell Para Press|kettlebell|shoulders
    One-Arm Kettlebell Push Press|kettlebell|shoulders
    One-Arm Kettlebell Row|kettlebell|back
    One-Arm Kettlebell Snatch|kettlebell|shoulders
    One-Arm Kettlebell Split Jerk|kettlebell|shoulders
    One-Arm Kettlebell Split Snatch|kettlebell|shoulders
    One-Arm Kettlebell Swings|kettlebell|hamstrings
    One-Arm Long Bar Row|barbell|back
    One-Arm Medicine Ball Slam|other|core
    One-Arm Open Palm Kettlebell Clean|kettlebell|hamstrings
    One-Arm Overhead Kettlebell Squats|kettlebell|quads
    One-Arm Side Deadlift|barbell|quads
    One-Arm Side Laterals|dumbbell|shoulders
    One-Legged Cable Kickback|cable|glutes
    One Arm Against Wall|other|back
    One Arm Chin-Up|other|back
    One Arm Dumbbell Bench Press|dumbbell|chest
    One Arm Dumbbell Preacher Curl|dumbbell|biceps
    One Arm Floor Press|barbell|triceps
    One Arm Lat Pulldown|cable|back
    One Arm Pronated Dumbbell Triceps Extension|dumbbell|triceps
    One Arm Supinated Dumbbell Triceps Extension|dumbbell|triceps
    One Half Locust|other|quads
    One Handed Hang|other|back
    One Knee To Chest|other|glutes
    One Leg Barbell Squat|barbell|quads
    Open Palm Kettlebell Clean|kettlebell|hamstrings
    Otis-Up|other|core
    Overhead Cable Curl|cable|biceps
    Overhead Lat|other|back
    Overhead Slam|other|back
    Overhead Squat|barbell|quads
    Overhead Stretch|other|core
    Overhead Triceps|bodyweight|triceps
    Pallof Press|cable|core
    Pallof Press With Rotation|cable|core
    Palms-Down Dumbbell Wrist Curl Over A Bench|dumbbell|forearms
    Palms-Down Wrist Curl Over A Bench|barbell|forearms
    Palms-Up Barbell Wrist Curl Over A Bench|barbell|forearms
    Palms-Up Dumbbell Wrist Curl Over A Bench|dumbbell|forearms
    Parallel Bar Dip|other|triceps
    Pelvic Tilt Into Bridge|other|back
    Peroneals-SMR|other|calves
    Peroneals Stretch|other|calves
    Physioball Hip Bridge|other|glutes
    Pin Presses|barbell|triceps
    Piriformis-SMR|other|glutes
    Plank|bodyweight|core
    Plate Pinch|other|forearms
    Plate Twist|other|core
    Platform Hamstring Slides|other|hamstrings
    Plie Dumbbell Squat|dumbbell|quads
    Plyo Kettlebell Pushups|kettlebell|chest
    Plyo Push-up|bodyweight|chest
    Posterior Tibialis Stretch|other|calves
    Power Clean|barbell|hamstrings
    Power Clean from Blocks|barbell|hamstrings
    Power Jerk|barbell|quads
    Power Partials|dumbbell|shoulders
    Power Snatch|barbell|hamstrings
    Power Snatch from Blocks|barbell|quads
    Power Stairs|other|hamstrings
    Preacher Curl|barbell|biceps
    Preacher Hammer Dumbbell Curl|dumbbell|biceps
    Press Sit-Up|barbell|core
    Prone Manual Hamstring|other|hamstrings
    Prowler Sprint|other|hamstrings
    Pull Through|cable|glutes
    Pullups|bodyweight|back
    Push-Up Wide|bodyweight|chest
    Push-Ups - Close Triceps Position|bodyweight|triceps
    Push-Ups With Feet Elevated|bodyweight|chest
    Push-Ups With Feet On An Exercise Ball|other|chest
    Push Press|barbell|shoulders
    Push Press - Behind the Neck|barbell|shoulders
    Push Up to Side Plank|bodyweight|chest
    Pushups|bodyweight|chest
    Pushups (Close and Wide Hand Positions)|bodyweight|chest
    Pyramid|other|back
    Quad Stretch|other|quads
    Quadriceps-SMR|other|quads
    Quick Leap|other|quads
    Rack Delivery|barbell|shoulders
    Rack Pull with Bands|barbell|back
    Rack Pulls|barbell|back
    Rear Leg Raises|bodyweight|quads
    Recumbent Bike|machine|quads
    Return Push from Stance|other|shoulders
    Reverse Band Bench Press|barbell|triceps
    Reverse Band Box Squat|barbell|quads
    Reverse Band Deadlift|barbell|back
    Reverse Band Power Squat|barbell|quads
    Reverse Band Sumo Deadlift|barbell|hamstrings
    Reverse Barbell Curl|barbell|biceps
    Reverse Barbell Preacher Curls|barbell|biceps
    Reverse Cable Curl|cable|biceps
    Reverse Crunch|bodyweight|core
    Reverse Flyes|dumbbell|shoulders
    Reverse Flyes With External Rotation|dumbbell|shoulders
    Reverse Grip Bent-Over Rows|barbell|back
    Reverse Grip Triceps Pushdown|cable|triceps
    Reverse Hyperextension|machine|hamstrings
    Reverse Machine Flyes|machine|shoulders
    Reverse Plate Curls|other|biceps
    Reverse Triceps Bench Press|barbell|triceps
    Rhomboids-SMR|other|back
    Rickshaw Carry|other|forearms
    Rickshaw Deadlift|other|quads
    Ring Dips|other|triceps
    Rocket Jump|bodyweight|quads
    Rocking Standing Calf Raise|barbell|calves
    Rocky Pull-Ups/Pulldowns|other|back
    Romanian Deadlift|barbell|hamstrings
    Romanian Deadlift from Deficit|barbell|hamstrings
    Rope Climb|other|back
    Rope Crunch|cable|core
    Rope Jumping|other|quads
    Rope Straight-Arm Pulldown|cable|back
    Round The World Shoulder Stretch|other|shoulders
    Rowing, Stationary|machine|quads
    Runner's Stretch|other|hamstrings
    Running, Treadmill|machine|quads
    Russian Twist|bodyweight|core
    Sandbag Load|other|quads
    Scapular Pull-Up|other|back
    Scissor Kick|bodyweight|core
    Scissors Jump|bodyweight|quads
    Seated Band Hamstring Curl|other|hamstrings
    Seated Barbell Military Press|barbell|shoulders
    Seated Barbell Twist|barbell|core
    Seated Bent-Over One-Arm Dumbbell Triceps Extension|dumbbell|triceps
    Seated Bent-Over Rear Delt Raise|dumbbell|shoulders
    Seated Bent-Over Two-Arm Dumbbell Triceps Extension|dumbbell|triceps
    Seated Biceps|bodyweight|biceps
    Seated Cable Rows|cable|back
    Seated Cable Shoulder Press|cable|shoulders
    Seated Calf Raise|machine|calves
    Seated Calf Stretch|other|calves
    Seated Close-Grip Concentration Barbell Curl|barbell|biceps
    Seated Dumbbell Curl|dumbbell|biceps
    Seated Dumbbell Inner Biceps Curl|dumbbell|biceps
    Seated Dumbbell Palms-Down Wrist Curl|dumbbell|forearms
    Seated Dumbbell Palms-Up Wrist Curl|dumbbell|forearms
    Seated Dumbbell Press|dumbbell|shoulders
    Seated Flat Bench Leg Pull-In|bodyweight|core
    Seated Floor Hamstring Stretch|other|hamstrings
    Seated Front Deltoid|bodyweight|shoulders
    Seated Glute|bodyweight|glutes
    Seated Good Mornings|barbell|back
    Seated Hamstring|other|hamstrings
    Seated Hamstring and Calf Stretch|other|hamstrings
    Seated Head Harness Neck Resistance|other|fullBody
    Seated Leg Curl|machine|hamstrings
    Seated Leg Tucks|bodyweight|core
    Seated One-Arm Dumbbell Palms-Down Wrist Curl|dumbbell|forearms
    Seated One-Arm Dumbbell Palms-Up Wrist Curl|dumbbell|forearms
    Seated One-arm Cable Pulley Rows|cable|back
    Seated Overhead Stretch|other|core
    Seated Palm-Up Barbell Wrist Curl|barbell|forearms
    Seated Palms-Down Barbell Wrist Curl|barbell|forearms
    Seated Side Lateral Raise|dumbbell|shoulders
    Seated Triceps Press|dumbbell|triceps
    Seated Two-Arm Palms-Up Low-Pulley Wrist Curl|cable|forearms
    See-Saw Press (Alternating Side Press)|dumbbell|shoulders
    Shotgun Row|cable|back
    Shoulder Circles|other|shoulders
    Shoulder Press - With Bands|band|shoulders
    Shoulder Raise|other|shoulders
    Shoulder Stretch|other|shoulders
    Side-Lying Floor Stretch|other|back
    Side Bridge|bodyweight|core
    Side Hop-Sprint|other|quads
    Side Jackknife|bodyweight|core
    Side Lateral Raise|dumbbell|shoulders
    Side Laterals to Front Raise|dumbbell|shoulders
    Side Leg Raises|bodyweight|glutes
    Side Lying Groin Stretch|other|glutes
    Side Neck Stretch|other|fullBody
    Side Standing Long Jump|other|quads
    Side To Side Chins|other|back
    Side Wrist Pull|other|shoulders
    Side to Side Box Shuffle|other|quads
    Single-Arm Cable Crossover|cable|chest
    Single-Arm Linear Jammer|barbell|shoulders
    Single-Arm Push-Up|bodyweight|chest
    Single-Cone Sprint Drill|other|quads
    Single-Leg High Box Squat|other|quads
    Single-Leg Hop Progression|other|quads
    Single-Leg Lateral Hop|other|quads
    Single-Leg Leg Extension|machine|quads
    Single-Leg Stride Jump|other|quads
    Single Dumbbell Raise|dumbbell|shoulders
    Single Leg Butt Kick|bodyweight|quads
    Single Leg Glute Bridge|bodyweight|glutes
    Single Leg Push-off|other|quads
    Sit-Up|bodyweight|core
    Sit Squats|other|quads
    Skating|other|quads
    Sled Drag - Harness|other|quads
    Sled Overhead Backward Walk|other|shoulders
    Sled Overhead Triceps Extension|other|triceps
    Sled Push|other|quads
    Sled Reverse Flye|other|shoulders
    Sled Row|other|back
    Sledgehammer Swings|other|core
    Smith Incline Shoulder Raise|barbell|shoulders
    Smith Machine Behind the Back Shrug|machine|back
    Smith Machine Bench Press|machine|chest
    Smith Machine Bent Over Row|machine|back
    Smith Machine Calf Raise|machine|calves
    Smith Machine Close-Grip Bench Press|machine|triceps
    Smith Machine Decline Press|machine|chest
    Smith Machine Hang Power Clean|machine|hamstrings
    Smith Machine Hip Raise|machine|core
    Smith Machine Incline Bench Press|machine|chest
    Smith Machine Leg Press|machine|quads
    Smith Machine One-Arm Upright Row|machine|shoulders
    Smith Machine Overhead Shoulder Press|machine|shoulders
    Smith Machine Pistol Squat|machine|quads
    Smith Machine Reverse Calf Raises|machine|calves
    Smith Machine Squat|machine|quads
    Smith Machine Stiff-Legged Deadlift|machine|hamstrings
    Smith Machine Upright Row|machine|back
    Smith Single-Leg Split Squat|machine|quads
    Snatch|barbell|quads
    Snatch Balance|barbell|quads
    Snatch Deadlift|barbell|hamstrings
    Snatch Pull|barbell|hamstrings
    Snatch Shrug|barbell|back
    Snatch from Blocks|barbell|quads
    Speed Band Overhead Triceps|band|triceps
    Speed Box Squat|barbell|quads
    Speed Squats|barbell|quads
    Spell Caster|dumbbell|core
    Spider Crawl|bodyweight|core
    Spider Curl|barbell|biceps
    Spinal Stretch|other|back
    Split Clean|barbell|quads
    Split Jerk|barbell|quads
    Split Jump|bodyweight|quads
    Split Snatch|barbell|hamstrings
    Split Squat with Dumbbells|dumbbell|quads
    Split Squats|other|hamstrings
    Squat Jerk|barbell|quads
    Squat with Bands|barbell|quads
    Squat with Chains|barbell|quads
    Squat with Plate Movers|barbell|quads
    Squats - With Bands|band|quads
    Stairmaster|machine|quads
    Standing Alternating Dumbbell Press|dumbbell|shoulders
    Standing Barbell Calf Raise|barbell|calves
    Standing Barbell Press Behind Neck|barbell|shoulders
    Standing Bent-Over One-Arm Dumbbell Triceps Extension|dumbbell|triceps
    Standing Bent-Over Two-Arm Dumbbell Triceps Extension|dumbbell|triceps
    Standing Biceps Cable Curl|cable|biceps
    Standing Biceps Stretch|other|biceps
    Standing Bradford Press|barbell|shoulders
    Standing Cable Chest Press|cable|chest
    Standing Cable Lift|cable|core
    Standing Cable Wood Chop|cable|core
    Standing Calf Raises|machine|calves
    Standing Concentration Curl|dumbbell|biceps
    Standing Dumbbell Calf Raise|dumbbell|calves
    Standing Dumbbell Press|dumbbell|shoulders
    Standing Dumbbell Reverse Curl|dumbbell|biceps
    Standing Dumbbell Straight-Arm Front Delt Raise Above Head|dumbbell|shoulders
    Standing Dumbbell Triceps Extension|dumbbell|triceps
    Standing Dumbbell Upright Row|dumbbell|back
    Standing Elevated Quad Stretch|other|quads
    Standing Front Barbell Raise Over Head|barbell|shoulders
    Standing Gastrocnemius Calf Stretch|other|calves
    Standing Hamstring and Calf Stretch|other|hamstrings
    Standing Hip Circles|bodyweight|glutes
    Standing Hip Flexors|other|quads
    Standing Inner-Biceps Curl|dumbbell|biceps
    Standing Lateral Stretch|other|core
    Standing Leg Curl|machine|hamstrings
    Standing Long Jump|bodyweight|quads
    Standing Low-Pulley Deltoid Raise|cable|shoulders
    Standing Low-Pulley One-Arm Triceps Extension|cable|triceps
    Standing Military Press|barbell|shoulders
    Standing Olympic Plate Hand Squeeze|other|forearms
    Standing One-Arm Cable Curl|cable|biceps
    Standing One-Arm Dumbbell Curl Over Incline Bench|dumbbell|biceps
    Standing One-Arm Dumbbell Triceps Extension|dumbbell|triceps
    Standing Overhead Barbell Triceps Extension|barbell|triceps
    Standing Palm-In One-Arm Dumbbell Press|dumbbell|shoulders
    Standing Palms-In Dumbbell Press|dumbbell|shoulders
    Standing Palms-Up Barbell Behind The Back Wrist Curl|barbell|forearms
    Standing Pelvic Tilt|other|back
    Standing Rope Crunch|cable|core
    Standing Soleus And Achilles Stretch|other|calves
    Standing Toe Touches|other|hamstrings
    Standing Towel Triceps Extension|bodyweight|triceps
    Standing Two-Arm Overhead Throw|other|shoulders
    Star Jump|bodyweight|quads
    Step-up with Knee Raise|bodyweight|glutes
    Step Mill|machine|quads
    Stiff-Legged Barbell Deadlift|barbell|hamstrings
    Stiff-Legged Dumbbell Deadlift|dumbbell|hamstrings
    Stiff Leg Barbell Good Morning|barbell|back
    Stomach Vacuum|bodyweight|core
    Straight-Arm Dumbbell Pullover|dumbbell|chest
    Straight-Arm Pulldown|cable|back
    Straight Bar Bench Mid Rows|barbell|back
    Straight Raises on Incline Bench|barbell|shoulders
    Stride Jump Crossover|other|quads
    Sumo Deadlift|barbell|hamstrings
    Sumo Deadlift with Bands|barbell|hamstrings
    Sumo Deadlift with Chains|barbell|hamstrings
    Superman|bodyweight|back
    Supine Chest Throw|other|triceps
    Supine One-Arm Overhead Throw|other|core
    Supine Two-Arm Overhead Throw|other|core
    Suspended Fallout|other|core
    Suspended Push-Up|other|chest
    Suspended Reverse Crunch|other|core
    Suspended Row|other|back
    Suspended Split Squat|other|quads
    Svend Press|other|chest
    T-Bar Row with Handle|barbell|back
    Tate Press|dumbbell|triceps
    The Straddle|other|hamstrings
    Thigh Abductor|machine|glutes
    Thigh Adductor|machine|glutes
    Tire Flip|other|quads
    Toe Touchers|bodyweight|core
    Torso Rotation|other|core
    Trail Running/Walking|other|quads
    Trap Bar Deadlift|other|quads
    Tricep Dumbbell Kickback|dumbbell|triceps
    Tricep Side Stretch|other|triceps
    Triceps Overhead Extension with Rope|cable|triceps
    Triceps Pushdown|cable|triceps
    Triceps Pushdown - Rope Attachment|cable|triceps
    Triceps Pushdown - V-Bar Attachment|cable|triceps
    Triceps Stretch|other|triceps
    Tuck Crunch|bodyweight|core
    Two-Arm Dumbbell Preacher Curl|dumbbell|biceps
    Two-Arm Kettlebell Clean|kettlebell|shoulders
    Two-Arm Kettlebell Jerk|kettlebell|shoulders
    Two-Arm Kettlebell Military Press|kettlebell|shoulders
    Two-Arm Kettlebell Row|kettlebell|back
    Underhand Cable Pulldowns|cable|back
    Upper Back-Leg Grab|other|hamstrings
    Upper Back Stretch|other|back
    Upright Barbell Row|barbell|shoulders
    Upright Cable Row|cable|back
    Upright Row - With Bands|band|back
    Upward Stretch|other|shoulders
    V-Bar Pulldown|cable|back
    V-Bar Pullup|bodyweight|back
    Vertical Swing|dumbbell|hamstrings
    Walking, Treadmill|machine|quads
    Weighted Ball Hyperextension|other|back
    Weighted Ball Side Bend|other|core
    Weighted Bench Dip|other|triceps
    Weighted Crunches|other|core
    Weighted Jump Squat|barbell|quads
    Weighted Pull Ups|other|back
    Weighted Sissy Squat|barbell|quads
    Weighted Sit-Ups - With Bands|other|core
    Weighted Squat|other|quads
    Wide-Grip Barbell Bench Press|barbell|chest
    Wide-Grip Decline Barbell Bench Press|barbell|chest
    Wide-Grip Decline Barbell Pullover|barbell|chest
    Wide-Grip Lat Pulldown|cable|back
    Wide-Grip Pulldown Behind The Neck|cable|back
    Wide-Grip Rear Pull-Up|bodyweight|back
    Wide-Grip Standing Barbell Curl|barbell|biceps
    Wide Stance Barbell Squat|barbell|quads
    Wide Stance Stiff Legs|barbell|hamstrings
    Wind Sprints|bodyweight|core
    Windmills|other|glutes
    World's Greatest Stretch|other|hamstrings
    Wrist Circles|bodyweight|forearms
    Wrist Roller|other|forearms
    Wrist Rotations with Straight Bar|barbell|forearms
    Yoke Walk|other|quads
    Zercher Squats|barbell|quads
    Zottman Curl|dumbbell|biceps
    Zottman Preacher Curl|dumbbell|biceps
    """

    /// Trimmed, case- and accent-insensitive: how names and aliases are compared.
    nonisolated static func normalize(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }

    /// Look up a catalog entry by name or alias (case/diacritic-insensitive).
    static func lookup(_ name: String) -> CatalogExercise? {
        let needle = normalize(name)
        return all.first { entry in
            if normalize(entry.displayName) == needle { return true }
            return entry.aliases.contains { normalize($0) == needle }
        }
    }
}
