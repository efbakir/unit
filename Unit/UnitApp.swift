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
    private static let uiTestingArgument = "-ui-testing"
    private static let uiTestingResetArgument = "-ui-testing-reset"
    private static let uiTestingSeedTwoCompletedWorkoutsArgument = "-ui-testing-seed-engagement-two"
    private static let progressionContractUITestArgument = "-ui-testing-progression-contract"
    private static let appStoreScreenshotUITestArgument = "-ui-testing-app-store-screenshot"
    private static let startingTargetUITestArgument = "-ui-testing-starting-target"
#if DEBUG
    private static let combatPowerSmokeTestArgument = "-smoke-test-combat-power"
#endif
    var sharedModelContainer: ModelContainer

    @MainActor
    init() {
        let start = ContinuousClock.now
        self.sharedModelContainer = Self.makeSharedModelContainer()
        UnitAnalytics.shared.configure()
        // Lock Screen rest buttons run in this process and drive the same timer.
        RestTimerIntentHandler.adjust = { RestTimerManager.shared.adjustAndRemember(by: $0) }
        RestTimerIntentHandler.skip = { RestTimerManager.shared.stop() }
#if DEBUG
        if CommandLine.arguments.contains(Self.uiTestingArgument) {
            if CommandLine.arguments.contains("-ui-testing-health-allow") { HealthWorkoutSync.store = FakeHealthWorkoutStore(allowsAccess: true) }
            if CommandLine.arguments.contains("-ui-testing-health-deny") { HealthWorkoutSync.store = FakeHealthWorkoutStore(allowsAccess: false) }
        }
        if CommandLine.arguments.contains(Self.uiTestingArgument), CommandLine.arguments.contains("-ui-testing-analytics-r5") {
            do { try ProgressionContractUITestSeeder.seedAnalytics(in: sharedModelContainer.mainContext) }
            catch { Self.logger.error("Analytics UI-test fixture failed: \(String(describing: error), privacy: .public)") }
        }
        if CommandLine.arguments.contains(Self.progressionContractUITestArgument)
            || CommandLine.arguments.contains(Self.appStoreScreenshotUITestArgument) {
            do {
                try ProgressionContractUITestSeeder.seed(
                    in: sharedModelContainer.mainContext,
                    usesUSStorefrontPresentation: CommandLine.arguments.contains(
                        Self.appStoreScreenshotUITestArgument
                    )
                )
                Self.logger.info("Progression contract UI-test seed ready")
            } catch {
                Self.logger.error(
                    "Progression contract UI-test seed failed: \(String(describing: error), privacy: .public)"
                )
            }
        }
        if CommandLine.arguments.contains("-ui-testing"), CommandLine.arguments.contains("-ui-testing-logging-finalb") {
            do { try StartingTargetUITestSeeder.seedLogging(in: sharedModelContainer.mainContext) }
            catch { Self.logger.error("Logging UI-test fixture failed: \(String(describing: error), privacy: .public)") }
        }
        if CommandLine.arguments.contains(Self.startingTargetUITestArgument) {
            do {
                try StartingTargetUITestSeeder.seed(
                    in: sharedModelContainer.mainContext
                )
                Self.logger.info("Starting-target UI-test seed ready")
            } catch {
                Self.logger.error(
                    "Starting-target UI-test seed failed: \(String(describing: error), privacy: .public)"
                )
            }
        }
        if CommandLine.arguments.contains(Self.combatPowerSmokeTestArgument) {
            do {
                let result = try CombatPowerSmokeTestSeeder.seed(
                    in: sharedModelContainer.mainContext
                )
                Self.logger.info(
                    "Combat Power smoke seed ready: \(result.completedSessionCount, privacy: .public) completed sessions, active split \(result.splitID.uuidString, privacy: .public)"
                )
            } catch {
                Self.logger.error(
                    "Combat Power smoke seed failed: \(String(describing: error), privacy: .public)"
                )
            }
        }
#endif
        Self.logger.info("Launch: ModelContainer ready in \(ContinuousClock.now - start, privacy: .public)")
    }

    private static func makeSharedModelContainer() -> ModelContainer {
        let isRunningPreviews = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        if isRunningPreviews {
            return makeInMemoryContainer(orDieWith: "Could not create preview ModelContainer.")
        }

        do {
            let isRunningUITests = CommandLine.arguments.contains(uiTestingArgument)
            let storeURL = try persistentStoreURL(isRunningUITests: isRunningUITests)
            if isRunningUITests, CommandLine.arguments.contains(uiTestingResetArgument) {
                try resetUITestState(at: storeURL)
            }
            if isRunningUITests,
               CommandLine.arguments.contains(uiTestingSeedTwoCompletedWorkoutsArgument) {
                EngagementPromptTracker.seedCompletedWorkoutCountForUITesting(2)
            }
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try makePersistentContainer(configuration: configuration)
            UserDefaults.standard.set(false, forKey: PersistenceRecoveryState.noticeKey)
            return container
        } catch {
            logger.error("Persistent ModelContainer failed. Falling back to in-memory store. Error: \(String(describing: error), privacy: .public)")
            // Never delete the user's local training store automatically. A
            // migration/open failure is recoverable; erased workout history is
            // not. The in-memory fallback keeps the UI alive while ContentView
            // presents a clear warning that changes will not persist.
            UserDefaults.standard.set(true, forKey: PersistenceRecoveryState.noticeKey)
            return makeInMemoryContainer(orDieWith: "Could not create fallback ModelContainer.")
        }
    }

    private static func makePersistentContainer(configuration: ModelConfiguration) throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeInMemoryContainer(orDieWith message: String) -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("\(message) \(error)")
        }
    }

    private static func persistentStoreURL(isRunningUITests: Bool = false) throws -> URL {
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
        let filename = isRunningUITests ? "UnitUITests.store" : "Unit.store"
        return directoryURL.appendingPathComponent(filename)
    }

    /// UI tests use their own persistent store so relaunch coverage remains
    /// realistic without touching the simulator's normal Unit data. The reset
    /// flag is passed on the first launch of a test journey only.
    private static func resetUITestState(at storeURL: URL) throws {
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleIdentifier)
        }

        let fileManager = FileManager.default
        for suffix in ["", "-shm", "-wal"] {
            let url = URL(fileURLWithPath: storeURL.path + suffix)
            if fileManager.fileExists(atPath: url.path) {
                try fileManager.removeItem(at: url)
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .appFeedbackScene()
                .preferredColorScheme(.light)
        }
        .modelContainer(sharedModelContainer)
    }
}

enum PersistenceRecoveryState {
    static let noticeKey = "unit.persistenceRecoveryNotice"
}

#if DEBUG
/// A deterministic, isolated progression journey for UI automation. The
/// launch is deliberately parked at a fully logged, unfinished workout so the
/// test reaches post-workout recommendations through the real Finish action.
/// Stable IDs make relaunches idempotent: accepted or edited targets are never
/// recalculated or replaced by the seeder.
enum ProgressionContractUITestSeeder {
    private static let splitID = UUID(
        uuidString: "31000000-0000-0000-0000-000000000001"
    )!
    private static let templateID = UUID(
        uuidString: "31000000-0000-0000-0000-000000000002"
    )!
    private static let sessionID = UUID(
        uuidString: "31000000-0000-0000-0000-000000000003"
    )!

    private struct ExerciseSeed {
        let id: UUID
        let name: String
        let currentWeightKg: Double
        let currentTargetReps: Int
        let completedWeightsKg: [Double]
        let completedReps: [Int]
    }

    private static let exerciseSeeds: [ExerciseSeed] = [
        ExerciseSeed(
            id: UUID(uuidString: "31000000-0000-0000-0000-000000000011")!,
            name: "Bench Press",
            currentWeightKg: 60,
            currentTargetReps: 10,
            completedWeightsKg: [60, 60, 60],
            completedReps: [10, 10, 10]
        ),
        ExerciseSeed(
            id: UUID(uuidString: "31000000-0000-0000-0000-000000000012")!,
            name: "Barbell Row",
            currentWeightKg: 40,
            currentTargetReps: 8,
            completedWeightsKg: [40, 40, 40],
            completedReps: [8, 8, 8]
        ),
        ExerciseSeed(
            id: UUID(uuidString: "31000000-0000-0000-0000-000000000013")!,
            name: "Back Squat",
            currentWeightKg: 50,
            currentTargetReps: 9,
            completedWeightsKg: [50, 50, 50],
            completedReps: [9, 8, 9]
        ),
        ExerciseSeed(
            id: UUID(uuidString: "31000000-0000-0000-0000-000000000014")!,
            name: "Deadlift",
            currentWeightKg: 30,
            currentTargetReps: 8,
            completedWeightsKg: [30, 32.5, 30],
            completedReps: [8, 8, 8]
        )
    ]

    @MainActor
    static func seed(
        in modelContext: ModelContext,
        usesUSStorefrontPresentation: Bool = false
    ) throws {
        let unitSystem = usesUSStorefrontPresentation ? "lb" : "kg"
        UserDefaults.standard.set(unitSystem, forKey: "unitSystem")
        // Open the launch gate immediately while StoreKitTest restores the
        // matching transaction owned by the UI test process.
        UserDefaults.standard.set(
            StoreManager.Tier.weekly.rawValue,
            forKey: "storeManager.lastKnownEntitlement"
        )

        let splits = try modelContext.fetch(FetchDescriptor<Split>())
        if splits.contains(where: { $0.id == splitID }) {
            ActiveSplitStore.setCurrent(splitID)
            TodayRoutineOverride.set(templateId: templateID)
            return
        }

        let seeds: [ExerciseSeed]
        let progressionIncrementKg: Double
        if usesUSStorefrontPresentation {
            let poundsToKilograms = 1 / 2.20462
            seeds = [
                ExerciseSeed(
                    id: exerciseSeeds[0].id,
                    name: "Bench Press",
                    currentWeightKg: 135 * poundsToKilograms,
                    currentTargetReps: 10,
                    completedWeightsKg: Array(repeating: 135 * poundsToKilograms, count: 3),
                    completedReps: [10, 10, 10]
                ),
                ExerciseSeed(
                    id: exerciseSeeds[1].id,
                    name: "Barbell Row",
                    currentWeightKg: 95 * poundsToKilograms,
                    currentTargetReps: 8,
                    completedWeightsKg: Array(repeating: 95 * poundsToKilograms, count: 3),
                    completedReps: [8, 8, 8]
                ),
                ExerciseSeed(
                    id: exerciseSeeds[2].id,
                    name: "Back Squat",
                    currentWeightKg: 115 * poundsToKilograms,
                    currentTargetReps: 9,
                    completedWeightsKg: Array(repeating: 115 * poundsToKilograms, count: 3),
                    completedReps: [9, 8, 9]
                ),
                ExerciseSeed(
                    id: exerciseSeeds[3].id,
                    name: "Deadlift",
                    currentWeightKg: 135 * poundsToKilograms,
                    currentTargetReps: 8,
                    completedWeightsKg: [135, 140, 135].map { $0 * poundsToKilograms },
                    completedReps: [8, 8, 8]
                )
            ]
            progressionIncrementKg = 5 * poundsToKilograms
        } else {
            seeds = exerciseSeeds
            progressionIncrementKg = 2.5
        }

        let exerciseIDs = seeds.map(\.id)
        let progressionStates = Dictionary(
            uniqueKeysWithValues: seeds.map { seed in
                (
                    seed.id,
                    ExerciseProgressionState(
                        lowerRepBound: 8,
                        upperRepBound: 10,
                        weightIncrementKg: progressionIncrementKg,
                        currentAcceptedTargetWeightKg: seed.currentWeightKg,
                        currentAcceptedTargetReps: seed.currentTargetReps,
                        sourceWorkoutSessionID: nil,
                        lastAcceptedReason: nil
                    )
                )
            }
        )
        let plannedSets = Dictionary(
            uniqueKeysWithValues: seeds.map { ($0.id, 3) }
        )
        let plannedReps = Dictionary(
            uniqueKeysWithValues: seeds.map {
                ($0.id, $0.currentTargetReps)
            }
        )
        let plannedWeights = Dictionary(
            uniqueKeysWithValues: seeds.map {
                ($0.id, $0.currentWeightKg)
            }
        )

        let split = Split(
            id: splitID,
            name: "Strength Program",
            orderedTemplateIds: [templateID],
            createdAt: Date()
        )
        let template = DayTemplate(
            id: templateID,
            name: "Upper A",
            splitId: split.id,
            orderedExerciseIds: exerciseIDs,
            lastPerformedDate: Date(),
            scheduledWeekday: Calendar.current.component(.weekday, from: Date()),
            plannedSetsByExerciseId: plannedSets,
            plannedRepsByExerciseId: plannedReps,
            plannedWeightByExerciseId: plannedWeights,
            progressionStateByExerciseId: progressionStates
        )
        modelContext.insert(split)
        modelContext.insert(template)

        let exercises = seeds.map { seed in
            Exercise(
                id: seed.id,
                displayName: seed.name,
                isBodyweight: false,
                muscleGroup: .fullBody,
                equipment: .barbell
            )
        }
        for exercise in exercises {
            modelContext.insert(exercise)
        }

        // Give the production History chart enough real progression evidence
        // to communicate a trend in App Store and release-gate screenshots.
        // These completed sessions stay deterministic, isolated to the UI-test
        // store, and intentionally include only Bench Press so the contract's
        // other recommendation branches remain unchanged.
        let benchPressID = seeds[0].id
        let historyWeights: [Double]
        if usesUSStorefrontPresentation {
            historyWeights = [120, 125, 130].map { $0 / 2.20462 }
        } else {
            historyWeights = [55.0, 57.5, 60.0]
        }
        let historyReps = [8, 9, 9]
        for historyIndex in historyWeights.indices {
            let historySession = WorkoutSession(
                id: UUID(
                    uuidString: String(
                        format: "31000000-0000-0000-0000-%012d",
                        101 + historyIndex
                    )
                )!,
                date: Calendar.current.date(
                    byAdding: .day,
                    value: -21 + (historyIndex * 7),
                    to: Date()
                ) ?? Date(),
                templateId: template.id,
                isCompleted: true
            )
            modelContext.insert(historySession)

            for setIndex in 0..<3 {
                let entry = SetEntry(
                    sessionId: historySession.id,
                    exerciseId: benchPressID,
                    weight: historyWeights[historyIndex],
                    reps: historyReps[historyIndex],
                    isWarmup: false,
                    isCompleted: true,
                    setIndex: setIndex
                )
                entry.session = historySession
                modelContext.insert(entry)
            }
        }

        let session = WorkoutSession(
            id: sessionID,
            date: Date(),
            templateId: template.id,
            isCompleted: false
        )
        modelContext.insert(session)

        for seed in seeds {
            for setIndex in seed.completedReps.indices {
                let entry = SetEntry(
                    sessionId: session.id,
                    exerciseId: seed.id,
                    weight: seed.completedWeightsKg[setIndex],
                    reps: seed.completedReps[setIndex],
                    isWarmup: false,
                    isCompleted: true,
                    setIndex: setIndex
                )
                entry.session = session
                modelContext.insert(entry)
            }
        }

        ActiveSplitStore.setCurrent(split.id)
        TodayRoutineOverride.set(templateId: template.id)
        try modelContext.save()
    }
}

/// Runs the real paste → onboarding model → SwiftData commit pipeline for the
/// first-session regression journey. Relaunches are idempotent, so the test can
/// prove that the planned target survives a cold start before logging it.
enum StartingTargetUITestSeeder {
    private static let programText = """
    Upper A

    Bench Press 3x8-10 60
    Barbell Row 3x8-10 40
    Back Squat 3x8-10 50
    Deadlift 3x8-10 30
    """

    @MainActor
    static func seed(in modelContext: ModelContext) throws {
        UserDefaults.standard.set("kg", forKey: "unitSystem")
        UserDefaults.standard.set(
            StoreManager.Tier.weekly.rawValue,
            forKey: "storeManager.lastKnownEntitlement"
        )

        let existingSplits = try modelContext.fetch(FetchDescriptor<Split>())
        if let split = existingSplits.first(where: { $0.name == "Upper A" }),
           let templateID = split.orderedTemplateIds.first {
            ActiveSplitStore.setCurrent(split.id)
            TodayRoutineOverride.set(templateId: templateID)
            return
        }

        let parsed = ProgramImportParser.parseWithWarnings(
            programText,
            defaultUnit: "kg"
        )
        guard !parsed.days.isEmpty else {
            throw CocoaError(.coderReadCorrupt)
        }

        let viewModel = OnboardingViewModel()
        viewModel.importMethod = .paste
        viewModel.unitSystem = "kg"
        viewModel.applyImportedProgram(parsed.days)
        viewModel.dayWeekdays = Array(
            repeating: Calendar.current.component(.weekday, from: Date()),
            count: viewModel.dayCount
        )
        try viewModel.commit(modelContext: modelContext)

        let splits = try modelContext.fetch(FetchDescriptor<Split>())
        guard let split = splits.first(where: { $0.name == "Upper A" }),
              let templateID = split.orderedTemplateIds.first else {
            throw CocoaError(.coderValueNotFound)
        }
        ActiveSplitStore.setCurrent(split.id)
        TodayRoutineOverride.set(templateId: templateID)
    }
}

extension StartingTargetUITestSeeder {
    /// Isolated test store only. Idempotent so a relaunch exercises saved drafts.
    @MainActor static func seedLogging(in context: ModelContext) throws {
        let isFirstLaunch = try context.fetchCount(FetchDescriptor<Split>()) == 0
        try seed(in: context)
        guard isFirstLaunch else { return }
        let templates = try context.fetch(FetchDescriptor<DayTemplate>())
        let exercises = try context.fetch(FetchDescriptor<Exercise>())
        guard let template = templates.first,
              let benchID = template.orderedExerciseIds.first else { return }
        template.setPlannedSets(4, for: benchID)
        if CommandLine.arguments.contains("-logging-empty-target") {
            template.setPlannedWeight(nil, for: benchID)
            template.setPlannedReps(nil, for: benchID)
        }
        if CommandLine.arguments.contains("-logging-bodyweight"),
           let bench = exercises.first(where: { $0.id == benchID }) {
            bench.isBodyweight = true
            template.setPlannedWeight(0, for: benchID)
        }
        if CommandLine.arguments.contains("-logging-history") {
            // One finished Bench Press workout (3 × 8 at 55 kg) to beat.
            let finished = WorkoutSession(date: Date().addingTimeInterval(-2 * 86_400),
                                          templateId: template.id, isCompleted: true)
            context.insert(finished)
            for index in 0..<3 {
                let set = SetEntry(sessionId: finished.id, exerciseId: benchID, weight: 55, reps: 8,
                                   isCompleted: true, setIndex: index)
                set.session = finished
                context.insert(set)
            }
        }
        UserDefaults.standard.set(CommandLine.arguments.contains("-logging-lb") ? "lb" : "kg", forKey: "unitSystem")
        UserDefaults.standard.set(120, forKey: "restDurationSeconds")
        try context.save()
    }
}

struct CombatPowerSmokeTestSeedResult: Equatable {
    let splitID: UUID
    let completedSessionCount: Int
}

/// One-time developer seed for testing the real Combat Power program on a
/// physical phone. It is launch-argument gated, idempotent, and additive: it
/// never deletes the lifter's existing programs or history.
enum CombatPowerSmokeTestSeeder {
    private static let programID = UUID(
        uuidString: "00000000-0000-0000-0000-000000000011"
    )!

    private struct ProgressionSeed {
        let lowerRepBound: Int
        let upperRepBound: Int
        let weightIncrementKg: Double
    }

    private struct ExerciseHistorySeed {
        let weightsKg: [Double]
        let reps: [Int]
        let note: String
        let progression: ProgressionSeed?

        init(
            weightsKg: [Double],
            reps: [Int],
            note: String = "",
            progression: ProgressionSeed? = nil
        ) {
            precondition(weightsKg.count == 4 && reps.count == 4)
            self.weightsKg = weightsKg
            self.reps = reps
            self.note = note
            self.progression = progression
        }
    }

    private static let histories: [String: ExerciseHistorySeed] = [
        "Back Squat (BB)": .init(
            weightsKg: [90, 90, 90, 92.5],
            reps: [5, 6, 7, 5],
            progression: .init(lowerRepBound: 5, upperRepBound: 7, weightIncrementKg: 2.5)
        ),
        "Squat Jump": .init(weightsKg: [0, 0, 0, 0], reps: [5, 5, 5, 5]),
        "Romanian DL": .init(
            weightsKg: [70, 70, 70, 72.5],
            reps: [6, 7, 8, 8],
            progression: .init(lowerRepBound: 6, upperRepBound: 8, weightIncrementKg: 2.5)
        ),
        "Rotational Med Ball Wall Throw": .init(
            weightsKg: [6, 6, 6, 8],
            reps: [6, 7, 8, 6],
            note: "Per side",
            progression: .init(lowerRepBound: 6, upperRepBound: 8, weightIncrementKg: 2)
        ),
        "Push-Up Plus": .init(weightsKg: [0, 0, 0, 0], reps: [15, 15, 15, 15]),
        "Bench Press": .init(
            weightsKg: [70, 70, 70, 72.5],
            reps: [5, 6, 7, 7],
            progression: .init(lowerRepBound: 5, upperRepBound: 7, weightIncrementKg: 2.5)
        ),
        "Plyo Push-Up": .init(weightsKg: [0, 0, 0, 0], reps: [6, 6, 6, 6]),
        "Weighted Pull-Up": .init(
            weightsKg: [10, 10, 10, 12.5],
            reps: [5, 6, 7, 5],
            progression: .init(lowerRepBound: 5, upperRepBound: 7, weightIncrementKg: 2.5)
        ),
        "OHP (BB)": .init(
            weightsKg: [40, 40, 40, 42.5],
            reps: [5, 6, 7, 7],
            progression: .init(lowerRepBound: 5, upperRepBound: 7, weightIncrementKg: 2.5)
        ),
        "Iso Plate Hold": .init(
            weightsKg: [10, 10, 12.5, 12.5],
            reps: [1, 1, 1, 1],
            note: "30 sec hold"
        ),
        "Lateral Raise (DB)": .init(
            weightsKg: [8, 8, 8, 8],
            reps: [12, 13, 14, 15],
            progression: .init(lowerRepBound: 12, upperRepBound: 15, weightIncrementKg: 1)
        ),
        "Rice Bucket": .init(
            weightsKg: [0, 0, 0, 0],
            reps: [1, 1, 1, 1],
            note: "2–3 rounds"
        ),
        "Trap Bar Deadlift": .init(
            weightsKg: [120, 120, 120, 125],
            reps: [5, 6, 7, 5],
            progression: .init(lowerRepBound: 5, upperRepBound: 7, weightIncrementKg: 5)
        ),
        "Broad Jump": .init(weightsKg: [0, 0, 0, 0], reps: [3, 3, 3, 3]),
        "DB Snatch": .init(
            weightsKg: [20, 20, 20, 22.5],
            reps: [3, 4, 5, 5],
            note: "Per side",
            progression: .init(lowerRepBound: 3, upperRepBound: 5, weightIncrementKg: 2.5)
        ),
        "Close-Grip Bench": .init(
            weightsKg: [60, 60, 60, 62.5],
            reps: [8, 9, 10, 8],
            progression: .init(lowerRepBound: 8, upperRepBound: 10, weightIncrementKg: 2.5)
        ),
        "Neck Training": .init(
            weightsKg: [0, 0, 0, 0],
            reps: [10, 10, 10, 10],
            note: "Each direction"
        )
    ]

    @MainActor
    static func seed(
        in modelContext: ModelContext,
        now: Date = Date(),
        calendar sourceCalendar: Calendar = .current
    ) throws -> CombatPowerSmokeTestSeedResult {
        guard let program = ProgramCatalog.all.first(where: { $0.id == programID }) else {
            preconditionFailure("Combat Power must remain in ProgramCatalog.")
        }

        let split = try existingCompleteSplit(for: program, in: modelContext)
            ?? ProgramImporter.importProgram(program, into: modelContext)
        let allTemplates = try modelContext.fetch(FetchDescriptor<DayTemplate>())
        let templates = program.days.compactMap { day in
            allTemplates.first {
                $0.splitId == split.id && normalized($0.displayName) == normalized(day.name)
            }
        }
        guard templates.count == program.days.count else {
            preconditionFailure("Imported Combat Power templates are incomplete.")
        }

        let allExercises = try modelContext.fetch(FetchDescriptor<Exercise>())
        let exerciseByID = Dictionary(uniqueKeysWithValues: allExercises.map { ($0.id, $0) })
        var calendar = sourceCalendar
        calendar.firstWeekday = 2
        let today = calendar.startOfDay(for: now)
        let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        ) ?? today
        let firstTrainingDay = calendar.date(
            byAdding: .day,
            value: -28,
            to: currentWeekStart
        ) ?? currentWeekStart
        split.createdAt = firstTrainingDay

        let existingSessions = try modelContext.fetch(FetchDescriptor<WorkoutSession>())
        var completedSessionCount = 0

        for weekIndex in 0..<4 {
            for dayIndex in program.days.indices {
                let day = program.days[dayIndex]
                let template = templates[dayIndex]
                let weekdayOffset = max((day.weekday ?? 2) - 2, 0)
                let dayOffset = ((weekIndex - 4) * 7) + weekdayOffset
                let sessionDay = calendar.date(
                    byAdding: .day,
                    value: dayOffset,
                    to: currentWeekStart
                ) ?? firstTrainingDay
                let sessionDate = calendar.date(
                    byAdding: .hour,
                    value: 18,
                    to: sessionDay
                ) ?? sessionDay
                let sessionID = smokeSessionID(weekIndex: weekIndex, dayIndex: dayIndex)

                if existingSessions.contains(where: { $0.id == sessionID }) {
                    completedSessionCount += 1
                    template.lastPerformedDate = sessionDate
                    continue
                }

                let session = WorkoutSession(
                    id: sessionID,
                    date: sessionDate,
                    templateId: template.id,
                    isCompleted: true
                )
                modelContext.insert(session)

                for (itemIndex, item) in day.items.enumerated() {
                    guard template.orderedExerciseIds.indices.contains(itemIndex),
                          let exercise = exerciseByID[template.orderedExerciseIds[itemIndex]] else {
                        continue
                    }
                    let history = histories[item.exerciseName]
                        ?? ExerciseHistorySeed(
                            weightsKg: [0, 0, 0, 0],
                            reps: Array(repeating: item.repTarget, count: 4)
                        )

                    for setIndex in 0..<item.setCount {
                        let entry = SetEntry(
                            sessionId: session.id,
                            exerciseId: exercise.id,
                            weight: history.weightsKg[weekIndex],
                            reps: history.reps[weekIndex],
                            rir: weekIndex < 2 ? 2 : 1,
                            isWarmup: false,
                            isCompleted: true,
                            setIndex: setIndex,
                            note: setIndex == 0 ? history.note : ""
                        )
                        entry.session = session
                        modelContext.insert(entry)
                    }
                }

                template.lastPerformedDate = sessionDate
                completedSessionCount += 1
            }
        }

        configureProgression(
            program: program,
            templates: templates,
            exerciseByID: exerciseByID
        )
        ActiveSplitStore.setCurrent(split.id)
        try modelContext.save()

        return CombatPowerSmokeTestSeedResult(
            splitID: split.id,
            completedSessionCount: completedSessionCount
        )
    }

    @MainActor
    private static func existingCompleteSplit(
        for program: ProgramTemplate,
        in modelContext: ModelContext
    ) throws -> Split? {
        let splits = try modelContext.fetch(FetchDescriptor<Split>())
        let templates = try modelContext.fetch(FetchDescriptor<DayTemplate>())
        return splits.first { split in
            guard normalized(split.name) == normalized(program.name) else { return false }
            let splitDayNames = split.orderedTemplateIds.compactMap { templateID in
                templates.first(where: { $0.id == templateID })?.displayName
            }
            return splitDayNames.map(normalized) == program.days.map { normalized($0.name) }
        }
    }

    @MainActor
    private static func configureProgression(
        program: ProgramTemplate,
        templates: [DayTemplate],
        exerciseByID: [UUID: Exercise]
    ) {
        for dayIndex in program.days.indices {
            let day = program.days[dayIndex]
            let template = templates[dayIndex]
            for (itemIndex, item) in day.items.enumerated() {
                guard template.orderedExerciseIds.indices.contains(itemIndex),
                      let history = histories[item.exerciseName],
                      let progression = history.progression else {
                    continue
                }
                let exerciseID = template.orderedExerciseIds[itemIndex]
                guard exerciseByID[exerciseID] != nil else { continue }
                let latestWeight = history.weightsKg[3]
                let latestReps = history.reps[3]
                template.setPlannedSets(item.setCount, for: exerciseID)
                template.setPlannedReps(latestReps, for: exerciseID)
                template.setPlannedWeight(latestWeight, for: exerciseID)
                template.setProgressionState(
                    ExerciseProgressionState(
                        lowerRepBound: progression.lowerRepBound,
                        upperRepBound: progression.upperRepBound,
                        weightIncrementKg: progression.weightIncrementKg,
                        currentAcceptedTargetWeightKg: latestWeight,
                        currentAcceptedTargetReps: latestReps,
                        sourceWorkoutSessionID: nil,
                        lastAcceptedReason: nil
                    ),
                    for: exerciseID
                )
            }
        }
    }

    private static func smokeSessionID(weekIndex: Int, dayIndex: Int) -> UUID {
        let ordinal = (weekIndex * 3) + dayIndex + 1
        return UUID(
            uuidString: String(
                format: "20000000-0000-0000-0000-%012d",
                ordinal
            )
        )!
    }

    private static func normalized(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive], locale: .current)
    }
}

extension ProgressionContractUITestSeeder {
    /// DEBUG + isolated UI-test store only. No production store is ever seeded.
    @MainActor static func seedAnalytics(in context: ModelContext) throws {
        guard CommandLine.arguments.contains("-ui-testing"), try context.fetchCount(FetchDescriptor<Split>()) == 0 else { return }
        let args = CommandLine.arguments
        UserDefaults.standard.set(args.contains("-analytics-lb") ? "lb" : "kg", forKey: "unitSystem")
        let split = Split(name: "Analytics fixture")
        context.insert(split)
        let names = [args.contains("-analytics-catalog-names") ? "Back Squat (BB)" : "Squat", "Bench Press", args.contains("-analytics-catalog-names") ? "Deadlift (Conv)" : "Deadlift", "Overhead Press", "Barbell Row", "Pull-Up", "Biceps Curl", "Hanging Leg Raise"]
        let muscles: [MuscleGroup] = [.quads, .chest, .back, .shoulders, .back, .back, .biceps, .core]
        let exercises = names.enumerated().map { index, name in
            Exercise(displayName: name, isBodyweight: index == 5 || index == 7, muscleGroup: muscles[index], equipment: index == 5 || index == 7 ? .bodyweight : .barbell)
        }
        for exercise in exercises { context.insert(exercise) }
        let templates = ["Push A", "Lower A", "Pull A"].map { DayTemplate(name: $0, splitId: split.id, orderedExerciseIds: exercises.map(\.id)) }
        for template in templates { context.insert(template) }
        split.orderedTemplateIds = templates.map(\.id)
        for template in templates {
            for (index, exercise) in exercises.prefix(3).enumerated() {
                template.setProgressionState(ExerciseProgressionState(lowerRepBound: 3, upperRepBound: 8, weightIncrementKg: 2.5, currentAcceptedTargetWeightKg: [102.5, 82.5, 135][index], currentAcceptedTargetReps: 5, sourceWorkoutSessionID: UUID(), lastAcceptedReason: .allSetsReachedTop), for: exercise.id)
            }
        }
        ActiveSplitStore.setCurrent(split.id)
        let calendar = Calendar.current, now = Date()
        let offsets: [Int]
        if args.contains("-analytics-empty") { offsets = [] }
        else if args.contains("-analytics-baseline") { offsets = [0] }
        else if args.contains("-analytics-fewer") { offsets = [-210, -200] }
        else { offsets = Array(stride(from: -77, through: 0, by: 7)) + [-3, -6, -9, -12, -15, -18, -21] }
        for (index, offset) in offsets.enumerated() {
            let session = WorkoutSession(date: calendar.date(byAdding: .day, value: offset, to: now)!, templateId: templates[index % 3].id, isCompleted: true)
            context.insert(session)
            for (exerciseIndex, exercise) in exercises.enumerated() {
                if args.contains("-analytics-missing") && exerciseIndex == 2 { continue }
                let progress = max(0, min(11, (offset + 77) / 7))
                let weights: [Double] = [90 + Double(progress), 72.5 + Double(progress / 3) * 2.5, 120 + Double(progress), 40 + Double(progress / 2), 60 + Double(progress), 0, 16, 0]
                for setIndex in 0..<3 {
                    let entry = SetEntry(sessionId: session.id, exerciseId: exercise.id, weight: weights[exerciseIndex], reps: exercise.isBodyweight ? 7 + progress / 4 : 5, isCompleted: true, setIndex: setIndex)
                    context.insert(entry); session.setEntries.append(entry)
                }
            }
        }
        try context.save()
    }
}

#endif

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
