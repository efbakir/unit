//
//  WorkoutCSVExport.swift
//  Unit
//
//  Every logged set as one CSV row, in the column layout Strong exports.
//  The file opens in any spreadsheet and imports into apps that read
//  Strong CSV (Hevy, Liftosaur and others), so a lifter's data is never
//  trapped in Unit.
//

import CoreTransferable
import Foundation
import SwiftData
import UniformTypeIdentifiers

/// One logged set, copied out of SwiftData so the CSV text can be built off
/// the main actor.
nonisolated struct WorkoutCSVRow: Equatable, Sendable {
    let date: Date
    let workoutName: String
    let exerciseName: String
    /// "W" for a warm-up, otherwise the working-set number (1, 2, 3).
    let setOrder: String
    let weightKg: Double
    let reps: Int
    let note: String
    let rpe: Double
}

enum WorkoutCSVExport {
    /// Strong's comma layout. Weight carries no unit column, exactly like
    /// Strong; the file name names the unit instead.
    nonisolated static let header = "Date,Workout Name,Duration,Exercise Name,Set Order,Weight,Reps,Distance,Seconds,Notes,Workout Notes,RPE"

    /// Rows for every logged set, oldest workout first. Exercises follow the
    /// routine order, like the workout detail. Prepared but unlogged sets are
    /// left out, so the file holds only work that was done.
    static func rows(
        sessions: [WorkoutSession],
        exercises: [Exercise],
        templates: [DayTemplate]
    ) -> [WorkoutCSVRow] {
        let exerciseNames = Dictionary.firstUniqueKeys(exercises.map { ($0.id, $0.displayName) })
        let templatesByID = Dictionary.firstUniqueKeys(templates.map { ($0.id, $0) })
        var rows: [WorkoutCSVRow] = []

        for session in sessions.sorted(by: { $0.date < $1.date }) {
            let logged = session.setEntries.filter(\.isCompleted)
            guard !logged.isEmpty else { continue }
            let template = templatesByID[session.templateId]
            // Same fallback History uses when a routine no longer exists.
            let workoutName = template?.displayName ?? "Workout"
            let order = exerciseOrderIndex(for: template?.orderedExerciseIds ?? [])
            let setsByExercise = Dictionary(grouping: logged, by: \.exerciseId)
            let exerciseIDs = setsByExercise.keys.sorted { lhs, rhs in
                let left = order[lhs] ?? Int.max
                let right = order[rhs] ?? Int.max
                if left != right { return left < right }
                return (exerciseNames[lhs] ?? "") < (exerciseNames[rhs] ?? "")
            }

            for exerciseID in exerciseIDs {
                guard let exerciseName = exerciseNames[exerciseID] else { continue }
                // Stored set indexes keep gaps after a deleted set, so working
                // sets are numbered again from 1.
                var workingSetNumber = 0
                for entry in (setsByExercise[exerciseID] ?? []).sorted(by: { $0.setIndex < $1.setIndex }) {
                    let setOrder: String
                    if entry.isWarmup {
                        setOrder = "W"
                    } else {
                        workingSetNumber += 1
                        setOrder = String(workingSetNumber)
                    }
                    rows.append(WorkoutCSVRow(
                        date: session.date,
                        workoutName: workoutName,
                        exerciseName: exerciseName,
                        setOrder: setOrder,
                        weightKg: entry.weight,
                        reps: entry.reps,
                        note: entry.note.trimmingCharacters(in: .whitespacesAndNewlines),
                        rpe: entry.rpe
                    ))
                }
            }
        }
        return rows
    }

    /// The file text. Weights are written in the lifter's unit. Unit stores
    /// no workout end time, so Duration stays empty rather than invented.
    nonisolated static func csv(
        _ rows: [WorkoutCSVRow],
        unitSystem: String,
        timeZone: TimeZone = .current
    ) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let isPounds = unitSystem == "lb"

        var lines = [header]
        lines.reserveCapacity(rows.count + 1)
        for row in rows {
            lines.append([
                formatter.string(from: row.date),
                quoted(row.workoutName),
                "",
                quoted(row.exerciseName),
                row.setOrder,
                number(isPounds ? row.weightKg * 2.20462 : row.weightKg),
                String(row.reps),
                "0",
                "0",
                quoted(row.note),
                quoted(""),
                row.rpe > 0 ? number(row.rpe) : ""
            ].joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    /// Text fields are always quoted, as Strong writes them, so commas and
    /// line breaks inside names and notes survive.
    nonisolated static func quoted(_ text: String) -> String {
        "\"" + text.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// Up to two decimals with a "." separator in every locale: 61.235 kg
    /// logged as 135 lb is written back as 135, not 134.99.
    nonisolated static func number(_ value: Double) -> String {
        let rounded = (value * 100).rounded() / 100
        if rounded == rounded.rounded() {
            return String(format: "%.0f", rounded)
        }
        var text = String(format: "%.2f", rounded)
        while text.hasSuffix("0") { text.removeLast() }
        return text
    }
}

/// The share-sheet item. The file is built only when the receiving app asks
/// for it, so opening Settings never reads the whole history.
nonisolated struct WorkoutCSVFile: Transferable {
    let container: ModelContainer
    let unitSystem: String

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .commaSeparatedText) { file in
            SentTransferredFile(try await file.writeFile())
        }
    }

    func writeFile() async throws -> URL {
        let container = container
        let unitSystem = unitSystem
        let (rows, fileName) = try await MainActor.run {
            let context = ModelContext(container)
            let rows = WorkoutCSVExport.rows(
                sessions: try context.fetch(FetchDescriptor<WorkoutSession>()),
                exercises: try context.fetch(FetchDescriptor<Exercise>()),
                templates: try context.fetch(FetchDescriptor<DayTemplate>())
            )
            return (rows, AppCopy.DataTransfer.exportFileName(unitSystem: unitSystem))
        }
        let text = WorkoutCSVExport.csv(rows, unitSystem: unitSystem)
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent(fileName)
        try Data(text.utf8).write(to: url, options: .atomic)
        await MainActor.run { UnitAnalytics.shared.track(.dataExported) }
        return url
    }
}

extension FetchDescriptor where T == SetEntry {
    /// At most one logged set: enough to know whether there is any history,
    /// without loading it.
    static var anyLoggedSet: FetchDescriptor<SetEntry> {
        var descriptor = FetchDescriptor<SetEntry>(predicate: #Predicate { $0.isCompleted })
        descriptor.fetchLimit = 1
        return descriptor
    }
}
