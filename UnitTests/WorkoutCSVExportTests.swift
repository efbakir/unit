import SwiftData
import XCTest
@testable import Unit

@MainActor
final class WorkoutCSVExportTests: XCTestCase {
    private lazy var container: ModelContainer = {
        do {
            return try ModelContainer(
                for: Split.self, Exercise.self, DayTemplate.self, WorkoutSession.self, SetEntry.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        } catch {
            fatalError("In-memory store failed: \(error)")
        }
    }()
    private var context: ModelContext { container.mainContext }
    private let utc = TimeZone(identifier: "UTC")!

    func testHeaderMatchesStrongCommaLayout() {
        XCTAssertEqual(
            WorkoutCSVExport.header,
            "Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE"
        )
        XCTAssertEqual(WorkoutCSVExport.csv([], unitSystem: "kg"), WorkoutCSVExport.header + "\n")
    }

    func testRowsKeepLoggedSetsOnlyInRoutineOrderWithWarmupsAndRenumbering() throws {
        let squat = Exercise(displayName: "Back Squat (BB)")
        let bench = Exercise(displayName: "Bench Press")
        let template = DayTemplate(name: "Day 1 · Upper A", orderedExerciseIds: [bench.id, squat.id])
        let session = WorkoutSession(date: Date(timeIntervalSince1970: 1_000), templateId: template.id, isCompleted: true)
        [squat, bench].forEach(context.insert)
        context.insert(template)
        context.insert(session)
        addSet(to: session, exercise: squat, weight: 100, reps: 5, index: 0)
        addSet(to: session, exercise: bench, weight: 20, reps: 10, index: 0, isWarmup: true)
        addSet(to: session, exercise: bench, weight: 60, reps: 8, index: 1)
        // Index 2 was deleted during the workout; numbering must not skip.
        addSet(to: session, exercise: bench, weight: 60, reps: 7, index: 3)
        addSet(to: session, exercise: bench, weight: 60, reps: 6, index: 4, isCompleted: false)

        let rows = WorkoutCSVExport.rows(sessions: [session], exercises: [squat, bench], templates: [template])

        XCTAssertEqual(rows.map(\.exerciseName), ["Bench Press", "Bench Press", "Bench Press", "Back Squat (BB)"])
        XCTAssertEqual(rows.map(\.setOrder), ["W", "1", "2", "1"])
        XCTAssertEqual(rows.map(\.reps), [10, 8, 7, 5])
        XCTAssertEqual(Set(rows.map(\.workoutName)), ["Upper A"])
    }

    func testWorkoutsWithoutLoggedSetsAreLeftOutAndMissingRoutinesFallBack() throws {
        let row = Exercise(displayName: "Barbell Row")
        let empty = WorkoutSession(date: Date(timeIntervalSince1970: 2_000), templateId: UUID(), isCompleted: true)
        let orphan = WorkoutSession(date: Date(timeIntervalSince1970: 1_000), templateId: UUID(), isCompleted: true)
        context.insert(row)
        context.insert(empty)
        context.insert(orphan)
        addSet(to: orphan, exercise: row, weight: 70, reps: 8, index: 0)

        let rows = WorkoutCSVExport.rows(sessions: [empty, orphan], exercises: [row], templates: [])

        XCTAssertEqual(rows.count, 1)
        XCTAssertEqual(rows.first?.workoutName, "Workout")
    }

    func testCSVQuotesTextConvertsPoundsAndKeepsBodyweightAndRPE() {
        let rows = [
            WorkoutCSVRow(
                date: Date(timeIntervalSince1970: 0),
                workoutName: "Push, \"heavy\"",
                exerciseName: "Pull-Up",
                setOrder: "1",
                weightKg: 0,
                reps: 12,
                note: "grip\nwide",
                rpe: 8
            ),
            WorkoutCSVRow(
                date: Date(timeIntervalSince1970: 60),
                workoutName: "Push",
                exerciseName: "Bench Press",
                setOrder: "2",
                weightKg: 135 / 2.20462,
                reps: 5,
                note: "",
                rpe: 0
            )
        ]

        let pounds = WorkoutCSVExport.csv(rows, unitSystem: "lb", timeZone: utc)

        let expected = [
            WorkoutCSVExport.header,
            #"1970-01-01 00:00:00,"Push, ""heavy""",,"Pull-Up",1,0,12,0,0,"grip"#,
            #"wide","",8"#,
            #"1970-01-01 00:01:00,"Push",,"Bench Press",2,135,5,0,0,"","","#
        ].joined(separator: "\n") + "\n"
        XCTAssertEqual(pounds, expected)
    }

    func testNumbersUseTwoDecimalsWithAPeriodInEveryLocale() {
        XCTAssertEqual(WorkoutCSVExport.number(61.23492), "61.23")
        XCTAssertEqual(WorkoutCSVExport.number(62.5), "62.5")
        XCTAssertEqual(WorkoutCSVExport.number(100), "100")
        XCTAssertEqual(WorkoutCSVExport.number(0), "0")
    }

    func testFileNameNamesTheUnit() {
        XCTAssertEqual(AppCopy.DataTransfer.exportFileName(unitSystem: "lb"), "Unit workouts (lb).csv")
        XCTAssertEqual(AppCopy.DataTransfer.exportFileName(unitSystem: "kg"), "Unit workouts (kg).csv")
    }

    func testWrittenFileHoldsTheStoreContents() async throws {
        let bench = Exercise(displayName: "Bench Press")
        let template = DayTemplate(name: "Push", orderedExerciseIds: [bench.id])
        let session = WorkoutSession(date: Date(), templateId: template.id, isCompleted: true)
        context.insert(bench)
        context.insert(template)
        context.insert(session)
        addSet(to: session, exercise: bench, weight: 60, reps: 8, index: 0)
        try context.save()

        let url = try await WorkoutCSVFile(container: container, unitSystem: "kg").writeFile()
        let text = try String(contentsOf: url, encoding: .utf8)

        XCTAssertEqual(url.lastPathComponent, "Unit workouts (kg).csv")
        XCTAssertTrue(text.hasPrefix(WorkoutCSVExport.header + "\n"))
        XCTAssertTrue(text.contains(",\"Push\",,\"Bench Press\",1,60,8,0,0,"))
    }

    private func addSet(
        to session: WorkoutSession,
        exercise: Exercise,
        weight: Double,
        reps: Int,
        index: Int,
        isWarmup: Bool = false,
        isCompleted: Bool = true
    ) {
        let entry = SetEntry(
            sessionId: session.id,
            exerciseId: exercise.id,
            weight: weight,
            reps: reps,
            isWarmup: isWarmup,
            isCompleted: isCompleted,
            setIndex: index
        )
        entry.session = session
        context.insert(entry)
    }
}
