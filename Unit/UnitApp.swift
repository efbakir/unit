//
//  UnitApp.swift
//  Unit
//
//  Logging-first SwiftData app — iOS 18+, Swift 6, SwiftUI, SwiftData.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct UnitApp: App {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "app.unitlift",
        category: "SwiftData"
    )

    private static let schema = Schema([
            Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self
        ])
    var sharedModelContainer: ModelContainer

    @MainActor
    init() {
        self.sharedModelContainer = Self.makeSharedModelContainer()
    }

    private static func makeSharedModelContainer() -> ModelContainer {
        let isRunningPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isRunningPreviews {
            return makeInMemoryContainer(orDieWith: "Could not create preview ModelContainer.")
        }

        do {
            let storeURL = try persistentStoreURL()
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            return try makePersistentContainer(configuration: configuration)
        } catch {
            logger.error("Persistent ModelContainer failed. Falling back to in-memory store. Error: \(String(describing: error), privacy: .public)")
            return makeInMemoryContainer(orDieWith: "Could not create fallback ModelContainer.")
        }
    }

    private static func makePersistentContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            logger.error("Persistent store open failed. Resetting local store. Error: \(String(describing: error), privacy: .public)")
            resetStoreFiles(at: configuration.url)
            return try ModelContainer(for: schema, configurations: [configuration])
        }
    }

    private static func makeInMemoryContainer(orDieWith message: String) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("\(message) \(error)")
        }
    }

    private static func persistentStoreURL() throws -> URL {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directoryURL = appSupportURL.appendingPathComponent("Unit", isDirectory: true)
        if !fileManager.fileExists(atPath: directoryURL.path) {
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }
        return directoryURL.appendingPathComponent("Unit.store")
    }

    private static func resetStoreFiles(at storeURL: URL) {
        let fileManager = FileManager.default
        let sidecarURLs = [
            storeURL,
            URL(fileURLWithPath: storeURL.path + "-shm"),
            URL(fileURLWithPath: storeURL.path + "-wal")
        ]

        for url in sidecarURLs where fileManager.fileExists(atPath: url.path) {
            do {
                try fileManager.removeItem(at: url)
            } catch {
                logger.error("Failed to remove store file at \(url.path, privacy: .public): \(String(describing: error), privacy: .public)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}

enum PreviewSampleData {
    private static let splitName = "4-Day Strength"

    private struct ExerciseSeed {
        let name: String
        let aliases: [String]
        let isBodyweight: Bool
        let baseWeightKg: Double
        let reps: Int
    }

    private static let exerciseSeeds: [ExerciseSeed] = [
        // Day 1 — OHP + Upper
        .init(name: "Copenhagen Plank", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 20),
        .init(name: "Pallof Press", aliases: [], isBodyweight: false, baseWeightKg: 20, reps: 10),
        .init(name: "Broad Jump", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 3),
        .init(name: "Med Ball Overhead Slam", aliases: ["Med Ball Slam"], isBodyweight: false, baseWeightKg: 10, reps: 5),
        .init(name: "OHP (BB)", aliases: ["Overhead Press", "OHP"], isBodyweight: false, baseWeightKg: 50, reps: 4),
        .init(name: "Weighted Pull-Up", aliases: ["Pull-Up"], isBodyweight: false, baseWeightKg: 15, reps: 5),
        .init(name: "Incline DB Press", aliases: [], isBodyweight: false, baseWeightKg: 30, reps: 8),
        .init(name: "Pendlay Row", aliases: [], isBodyweight: false, baseWeightKg: 70, reps: 6),
        .init(name: "Lateral Raise (DB)", aliases: ["Lateral Raise"], isBodyweight: false, baseWeightKg: 10, reps: 12),
        .init(name: "Shrug (DB)", aliases: ["DB Shrug"], isBodyweight: false, baseWeightKg: 35, reps: 15),
        .init(name: "Ball Plank", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 1),
        .init(name: "Neck", aliases: ["Neck Work"], isBodyweight: true, baseWeightKg: 0, reps: 10),
        // Day 2 — Full Body Power
        .init(name: "DB Side to Side", aliases: [], isBodyweight: false, baseWeightKg: 16, reps: 10),
        .init(name: "Suitcase Hold", aliases: [], isBodyweight: false, baseWeightKg: 30, reps: 20),
        .init(name: "DB Snatch", aliases: [], isBodyweight: false, baseWeightKg: 20, reps: 8),
        .init(name: "BB Side to Side", aliases: [], isBodyweight: false, baseWeightKg: 20, reps: 4),
        .init(name: "Deadlift (Conv)", aliases: ["Conventional Deadlift", "Deadlift"], isBodyweight: false, baseWeightKg: 120, reps: 4),
        .init(name: "Bench Press", aliases: ["Bench Press (BB)"], isBodyweight: false, baseWeightKg: 80, reps: 8),
        .init(name: "Front Squat", aliases: [], isBodyweight: false, baseWeightKg: 60, reps: 6),
        .init(name: "Bent Over Row (BB)", aliases: ["Barbell Row"], isBodyweight: false, baseWeightKg: 60, reps: 8),
        .init(name: "Weighted Dips", aliases: ["Dips"], isBodyweight: false, baseWeightKg: 10, reps: 6),
        .init(name: "Hamstring", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 12),
        .init(name: "Core", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 15),
        .init(name: "Curl", aliases: ["Biceps Curl"], isBodyweight: false, baseWeightKg: 16, reps: 8),
        // Day 4 — Bench + Upper (new exercises only)
        .init(name: "Suitcase Carry", aliases: [], isBodyweight: false, baseWeightKg: 30, reps: 10),
        .init(name: "Hamstring/Calf Iso", aliases: ["Hamstring / Calf Iso"], isBodyweight: true, baseWeightKg: 0, reps: 45),
        .init(name: "Close-Grip Bench", aliases: ["Close Grip Bench Press"], isBodyweight: false, baseWeightKg: 60, reps: 8),
        .init(name: "Single-Arm DB Row", aliases: ["One-Arm DB Row"], isBodyweight: false, baseWeightKg: 40, reps: 10),
        .init(name: "Pec Dec", aliases: ["Pectec", "Pec Deck"], isBodyweight: false, baseWeightKg: 40, reps: 12),
        .init(name: "Triceps Extension", aliases: ["Triceps"], isBodyweight: false, baseWeightKg: 15, reps: 8),
        // Day 5 — Lower + Unilateral (new exercises only)
        .init(name: "Rotational Med Ball Throw", aliases: [], isBodyweight: false, baseWeightKg: 10, reps: 5),
        .init(name: "Bird Dog", aliases: [], isBodyweight: true, baseWeightKg: 0, reps: 8),
        .init(name: "Hamstring Curl", aliases: ["Hamstring Curl (DB Prone)", "Nordic Curl"], isBodyweight: false, baseWeightKg: 40, reps: 10),
        .init(name: "Back Squat (BB)", aliases: ["Back Squat", "Squat"], isBodyweight: false, baseWeightKg: 100, reps: 4),
        .init(name: "Romanian DL", aliases: ["Romanian Deadlift", "RDL"], isBodyweight: false, baseWeightKg: 80, reps: 7),
        .init(name: "Bulgarian Split Squat", aliases: [], isBodyweight: false, baseWeightKg: 30, reps: 8),
        .init(name: "Single-Arm DB Press", aliases: ["One-Arm DB Press"], isBodyweight: false, baseWeightKg: 20, reps: 8)
    ]

    private static let programDays: [(name: String, weekday: Int, exercises: [String])] = [
        ("OHP + Upper", 2, [                    // Monday
            "Copenhagen Plank", "Pallof Press", "Broad Jump", "Med Ball Overhead Slam",
            "OHP (BB)", "Weighted Pull-Up", "Incline DB Press", "Pendlay Row",
            "Lateral Raise (DB)", "Shrug (DB)", "Ball Plank", "Neck"
        ]),
        ("Full Body Power", 3, [                // Tuesday
            "DB Side to Side", "Suitcase Hold", "DB Snatch", "BB Side to Side",
            "Deadlift (Conv)", "Bench Press", "Front Squat", "Bent Over Row (BB)",
            "Weighted Dips", "Hamstring", "Core", "Curl"
        ]),
        ("Bench + Upper", 5, [                  // Thursday
            "Pallof Press", "Suitcase Carry", "Hamstring/Calf Iso",
            "Bench Press", "OHP (BB)", "Weighted Pull-Up", "Close-Grip Bench",
            "Single-Arm DB Row", "Pec Dec", "Curl", "Triceps Extension"
        ]),
        ("Lower + Unilateral", 6, [             // Friday
            "Rotational Med Ball Throw", "Bird Dog", "Hamstring Curl", "Neck",
            "Back Squat (BB)", "Romanian DL", "Bulgarian Split Squat", "Single-Arm DB Press"
        ])
    ]

    @MainActor
    static func makePreviewContainer() -> ModelContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        guard let container = buildContainer(config: config) else {
            preconditionFailure("Preview container creation failed.")
        }
        _ = seedIfNeeded(in: container.mainContext)
        return container
    }

    @MainActor
    private static func buildContainer(config: ModelConfiguration) -> ModelContainer? {
        try? ModelContainer(
            for: Split.self,
            Exercise.self,
            DayTemplate.self,
            WorkoutSession.self,
            SetEntry.self,
            configurations: config
        )
    }

    @MainActor
    @discardableResult
    static func seedIfNeeded(in modelContext: ModelContext) -> Bool {
        if let existing = try? modelContext.fetch(FetchDescriptor<Split>()), !existing.isEmpty {
            return false
        }
        return ensureProgramForCurrentUser(in: modelContext)
    }

    @MainActor
    @discardableResult
    static func ensureProgramForCurrentUser(in modelContext: ModelContext) -> Bool {
        var allExercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
        let allSplits = (try? modelContext.fetch(FetchDescriptor<Split>())) ?? []
        let allTemplates = (try? modelContext.fetch(FetchDescriptor<DayTemplate>())) ?? []
        let allSessions = (try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []

        var didChange = false

        func normalized(_ value: String) -> String {
            value
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
        }

        func exerciseMatches(_ exercise: Exercise, seed: ExerciseSeed) -> Bool {
            let names = [exercise.displayName] + exercise.aliases
            let desiredNames = [seed.name] + seed.aliases
            let normalizedNames = Set(names.map(normalized))
            return desiredNames.map(normalized).contains(where: normalizedNames.contains)
        }

        // Seed catalog entries that aren't already in the store. Back-fill taxonomy
        // on existing rows that match by name or alias.
        for entry in ExerciseCatalog.all {
            let signatures = Set(([entry.displayName] + entry.aliases).map(normalized))
            if let existing = allExercises.first(where: { exercise in
                let names = ([exercise.displayName] + exercise.aliases).map(normalized)
                return names.contains(where: signatures.contains)
            }) {
                if existing.muscleGroupRaw == MuscleGroup.fullBody.rawValue,
                   entry.muscleGroup != .fullBody {
                    existing.muscleGroupRaw = entry.muscleGroup.rawValue
                    didChange = true
                }
                if existing.equipmentRaw == Equipment.other.rawValue,
                   entry.equipment != .other {
                    existing.equipmentRaw = entry.equipment.rawValue
                    didChange = true
                }
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
            allExercises.append(exercise)
            didChange = true
        }

        var exerciseByName: [String: Exercise] = [:]
        for seed in exerciseSeeds {
            if let existingExercise = allExercises.first(where: { exerciseMatches($0, seed: seed) }) {
                exerciseByName[seed.name] = existingExercise
                continue
            }

            let exercise = Exercise(
                displayName: seed.name,
                aliases: seed.aliases,
                isBodyweight: seed.isBodyweight
            )
            modelContext.insert(exercise)
            allExercises.append(exercise)
            exerciseByName[seed.name] = exercise
            didChange = true
        }

        let split = allSplits.first(where: { normalized($0.name) == normalized(splitName) }) ?? {
            let split = Split(name: splitName)
            modelContext.insert(split)
            didChange = true
            return split
        }()

        let templatesForSplit = allTemplates.filter { $0.splitId == split.id }
        var orderedTemplates: [DayTemplate] = []

        for day in programDays {
            let exerciseIDs = day.exercises.compactMap { exerciseByName[$0]?.id }
            let template = templatesForSplit.first(where: { normalized($0.name) == normalized(day.name) }) ?? {
                let template = DayTemplate(name: day.name, splitId: split.id, orderedExerciseIds: exerciseIDs, scheduledWeekday: day.weekday)
                modelContext.insert(template)
                didChange = true
                return template
            }()

            if template.splitId != split.id {
                template.splitId = split.id
                didChange = true
            }

            if template.orderedExerciseIds != exerciseIDs {
                template.orderedExerciseIds = exerciseIDs
                didChange = true
            }

            if template.scheduledWeekday != day.weekday {
                template.scheduledWeekday = day.weekday
                didChange = true
            }

            orderedTemplates.append(template)
        }

        let orderedTemplateIDs = orderedTemplates.map(\.id)
        if split.orderedTemplateIds != orderedTemplateIDs {
            split.orderedTemplateIds = orderedTemplateIDs
            didChange = true
        }

        var mondayBasedCalendar = Calendar(identifier: .gregorian)
        mondayBasedCalendar.locale = .current
        mondayBasedCalendar.timeZone = .current
        mondayBasedCalendar.firstWeekday = 2

        let today = mondayBasedCalendar.startOfDay(for: Date())
        let currentWeekStart = mondayBasedCalendar.date(
            from: mondayBasedCalendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        let seedDate = mondayBasedCalendar.date(byAdding: .day, value: -7, to: currentWeekStart) ?? today

        if let firstTemplate = orderedTemplates.first,
           !allSessions.contains(where: { $0.templateId == firstTemplate.id }) {
            let session = WorkoutSession(
                date: seedDate,
                templateId: firstTemplate.id,
                isCompleted: true
            )
            modelContext.insert(session)

            let demoEntries: [(String, Double, Int)] = [
                ("OHP (BB)", 50, 4),
                ("Weighted Pull-Up", 15, 5),
                ("Incline DB Press", 30, 8),
                ("Pendlay Row", 70, 6),
                ("Lateral Raise (DB)", 10, 12),
                ("Shrug (DB)", 35, 15)
            ]

            for (index, entry) in demoEntries.enumerated() {
                guard let exercise = exerciseByName[entry.0] else { continue }
                let setEntry = SetEntry(
                    sessionId: session.id,
                    exerciseId: exercise.id,
                    weight: entry.1,
                    reps: entry.2,
                    isWarmup: false,
                    isCompleted: true,
                    setIndex: index
                )
                setEntry.session = session
                modelContext.insert(setEntry)
            }

            firstTemplate.lastPerformedDate = seedDate
            didChange = true
        }

        if didChange {
            try? modelContext.save()
        }

        return didChange
    }

    @MainActor
    static func hasAnyProgram(in modelContext: ModelContext) -> Bool {
        ((try? modelContext.fetch(FetchDescriptor<Split>())) ?? []).isEmpty == false
    }
}
