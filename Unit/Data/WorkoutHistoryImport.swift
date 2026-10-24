//
//  WorkoutHistoryImport.swift
//  Unit
//
//  Reads workout history exported by Strong or Hevy. Checked against real
//  files (2026-10-24):
//  - Strong 6.2.3 and later: semicolons, every value quoted, "Weight (kg)".
//  - Strong, older comma layout: plain "Weight", no unit anywhere.
//  - Strong, per-row layout (older, Android): a "Weight Unit" column.
//  - Hevy: "weight_kg" or "weight_lbs", set_type normal/warmup/dropset/failure.
//  Rows that are not weight-and-reps sets (rest timers, notes, timed holds,
//  cardio) are left out. Pure value code: nothing here touches SwiftData.
//

import Foundation

nonisolated enum WorkoutHistorySource: String, Sendable {
    case strong
    case hevy

    var appName: String {
        switch self {
        case .strong: "Strong"
        case .hevy: "Hevy"
        }
    }
}

nonisolated enum ImportWeightUnit: String, CaseIterable, Identifiable, Sendable {
    case kg
    case lb

    var id: String { rawValue }

    func kilograms(_ value: Double) -> Double {
        self == .lb ? value / 2.20462 : value
    }
}

nonisolated struct ImportedSet: Equatable, Sendable {
    /// The number as written in the file.
    let weight: Double
    /// Nil when the file gives no unit; the lifter picks one before import.
    let unit: ImportWeightUnit?
    let reps: Int
    let isWarmup: Bool
    /// 0 when the file has none.
    let rpe: Double
    let note: String

    func weightKg(assuming fallback: ImportWeightUnit) -> Double {
        (unit ?? fallback).kilograms(weight)
    }
}

nonisolated struct ImportedExercise: Equatable, Sendable {
    let name: String
    var sets: [ImportedSet]
}

nonisolated struct ImportedWorkout: Equatable, Sendable {
    let title: String
    let date: Date
    var exercises: [ImportedExercise]

    var setCount: Int { exercises.reduce(0) { $0 + $1.sets.count } }
}

nonisolated struct WorkoutHistoryFile: Equatable, Sendable {
    let source: WorkoutHistorySource
    /// Strong's comma layout has no unit anywhere, so the lifter picks one.
    let needsWeightUnit: Bool
    /// Oldest first.
    let workouts: [ImportedWorkout]
    /// Set rows that could not be used: timed or cardio sets, blank reps,
    /// impossible numbers, unreadable dates.
    let skippedRowCount: Int
}

nonisolated enum WorkoutHistoryImportError: Error, Equatable {
    case unknownFormat
    case noWorkouts
}

nonisolated enum WorkoutHistoryParser {
    /// Heaviest believable load. Anything above is a typo or a unit mix-up.
    static let maximumWeightKg = 1_000.0

    static func parse(_ text: String, timeZone: TimeZone = .current) throws -> WorkoutHistoryFile {
        var body = Substring(text)
        if body.hasPrefix("\u{FEFF}") { body = body.dropFirst() }
        guard let firstLine = body.split(whereSeparator: \.isNewline).first else {
            throw WorkoutHistoryImportError.unknownFormat
        }
        let delimiter: UInt8 = firstLine.filter { $0 == ";" }.count > firstLine.filter { $0 == "," }.count
            ? UInt8(ascii: ";")
            : UInt8(ascii: ",")
        let rows = records(in: String(body), delimiter: delimiter)
        guard let header = rows.first else { throw WorkoutHistoryImportError.unknownFormat }
        let columns = Dictionary(
            header.enumerated().map { ($0.element.trimmingCharacters(in: .whitespaces).lowercased(), $0.offset) },
            uniquingKeysWith: { first, _ in first }
        )
        let dataRows = rows.dropFirst()
        let decimalComma = delimiter == UInt8(ascii: ";")

        let file: WorkoutHistoryFile
        if columns["exercise_title"] != nil, columns["start_time"] != nil {
            file = try parseHevy(dataRows, columns: columns, timeZone: timeZone)
        } else if columns["exercise name"] != nil, columns["set order"] != nil, columns["date"] != nil {
            file = try parseStrong(dataRows, columns: columns, decimalComma: decimalComma, timeZone: timeZone)
        } else {
            throw WorkoutHistoryImportError.unknownFormat
        }
        guard !file.workouts.isEmpty else { throw WorkoutHistoryImportError.noWorkouts }
        return file
    }

    // MARK: - Strong

    private static func parseStrong(
        _ rows: ArraySlice<[String]>,
        columns: [String: Int],
        decimalComma: Bool,
        timeZone: TimeZone
    ) throws -> WorkoutHistoryFile {
        let weightColumn: Int?
        let fixedUnit: ImportWeightUnit?
        if let kilograms = columns["weight (kg)"] {
            weightColumn = kilograms
            fixedUnit = .kg
        } else if let pounds = columns["weight (lbs)"] ?? columns["weight (lb)"] {
            weightColumn = pounds
            fixedUnit = .lb
        } else {
            weightColumn = columns["weight"]
            fixedUnit = nil
        }
        guard let weightColumn,
              let dateColumn = columns["date"],
              let exerciseColumn = columns["exercise name"],
              let setOrderColumn = columns["set order"],
              let repsColumn = columns["reps"] else {
            throw WorkoutHistoryImportError.unknownFormat
        }
        let unitColumn = columns["weight unit"]
        let needsUnit = fixedUnit == nil && unitColumn == nil
        var dates = DateReader(
            formats: ["yyyy-MM-dd HH:mm:ss", "yyyy-MM-dd HH:mm", "yyyy-MM-dd'T'HH:mm:ss"],
            timeZone: timeZone
        )

        var builder = WorkoutBuilder()
        for row in rows {
            let setOrder = field(row, setOrderColumn).lowercased()
            // Rest timers and exercise notes have their own rows; they are not sets.
            if setOrder == "rest timer" || setOrder == "note" { continue }
            let name = field(row, exerciseColumn)
            guard !name.isEmpty else { continue }
            let isWarmup: Bool
            switch setOrder {
            case "w": isWarmup = true
            case "d", "f": isWarmup = false
            default:
                guard Int(setOrder) != nil || number(setOrder, decimalComma: false) != nil else {
                    builder.skippedRowCount += 1
                    continue
                }
                isWarmup = false
            }
            let rowUnit: ImportWeightUnit? = fixedUnit ?? unitColumn.flatMap { column in
                switch field(row, column).lowercased() {
                case "kg", "kgs": .kg
                case "lb", "lbs": .lb
                default: nil
                }
            }
            guard let date = dates.date(field(row, dateColumn)),
                  let set = makeSet(
                      weightText: field(row, weightColumn),
                      unit: rowUnit,
                      repsText: field(row, repsColumn),
                      isWarmup: isWarmup,
                      rpeText: columns["rpe"].map { field(row, $0) } ?? "",
                      note: columns["notes"].map { field(row, $0) } ?? "",
                      decimalComma: decimalComma
                  ) else {
                builder.skippedRowCount += 1
                continue
            }
            let title = columns["workout name"].map { field(row, $0) } ?? ""
            let key = columns["workout #"].map { field(row, $0) } ?? "\(field(row, dateColumn))|\(title)"
            builder.add(set, exercise: name, workoutKey: key, title: title, date: date)
        }
        return builder.file(source: .strong, needsWeightUnit: needsUnit)
    }

    // MARK: - Hevy

    private static func parseHevy(
        _ rows: ArraySlice<[String]>,
        columns: [String: Int],
        timeZone: TimeZone
    ) throws -> WorkoutHistoryFile {
        let weightColumn: Int
        let unit: ImportWeightUnit
        if let kilograms = columns["weight_kg"] {
            weightColumn = kilograms
            unit = .kg
        } else if let pounds = columns["weight_lbs"] {
            weightColumn = pounds
            unit = .lb
        } else {
            throw WorkoutHistoryImportError.unknownFormat
        }
        guard let titleColumn = columns["title"],
              let startColumn = columns["start_time"],
              let exerciseColumn = columns["exercise_title"],
              let repsColumn = columns["reps"] else {
            throw WorkoutHistoryImportError.unknownFormat
        }
        var dates = DateReader(
            formats: ["d MMM yyyy, HH:mm", "d MMM yyyy, HH:mm:ss", "d MMM yyyy HH:mm", "yyyy-MM-dd HH:mm:ss"],
            timeZone: timeZone
        )

        var builder = WorkoutBuilder()
        for row in rows {
            let name = field(row, exerciseColumn)
            guard !name.isEmpty else { continue }
            let isWarmup: Bool
            switch columns["set_type"].map({ field(row, $0).lowercased() }) ?? "normal" {
            case "warmup": isWarmup = true
            case "normal", "failure", "dropset", "": isWarmup = false
            default:
                builder.skippedRowCount += 1
                continue
            }
            let start = field(row, startColumn)
            let title = field(row, titleColumn)
            let workoutKey = "\(start)|\(title)"
            // Hevy repeats the exercise note on every set row; keep it once.
            let exerciseNote = builder.hasSets(in: workoutKey, exercise: name)
                ? ""
                : (columns["exercise_notes"].map { field(row, $0) } ?? "")
            guard let date = dates.date(start),
                  let set = makeSet(
                      weightText: field(row, weightColumn),
                      unit: unit,
                      repsText: field(row, repsColumn),
                      isWarmup: isWarmup,
                      rpeText: columns["rpe"].map { field(row, $0) } ?? "",
                      note: exerciseNote,
                      decimalComma: false
                  ) else {
                builder.skippedRowCount += 1
                continue
            }
            builder.add(set, exercise: name, workoutKey: workoutKey, title: title, date: date)
        }
        return builder.file(source: .hevy, needsWeightUnit: false)
    }

    // MARK: - Shared

    /// Groups set rows into workouts in file order. An exercise listed twice
    /// in one workout becomes one exercise with its sets in order.
    private struct WorkoutBuilder {
        private var workouts: [ImportedWorkout] = []
        private var indexByKey: [String: Int] = [:]
        var skippedRowCount = 0

        func hasSets(in workoutKey: String, exercise: String) -> Bool {
            guard let index = indexByKey[workoutKey] else { return false }
            return workouts[index].exercises.contains { $0.name == exercise }
        }

        mutating func add(_ set: ImportedSet, exercise: String, workoutKey: String, title: String, date: Date) {
            let index: Int
            if let existing = indexByKey[workoutKey] {
                index = existing
            } else {
                index = workouts.count
                indexByKey[workoutKey] = index
                workouts.append(ImportedWorkout(title: title, date: date, exercises: []))
            }
            if let exerciseIndex = workouts[index].exercises.firstIndex(where: { $0.name == exercise }) {
                workouts[index].exercises[exerciseIndex].sets.append(set)
            } else {
                workouts[index].exercises.append(ImportedExercise(name: exercise, sets: [set]))
            }
        }

        func file(source: WorkoutHistorySource, needsWeightUnit: Bool) -> WorkoutHistoryFile {
            WorkoutHistoryFile(
                source: source,
                needsWeightUnit: needsWeightUnit,
                workouts: workouts.sorted { $0.date < $1.date },
                skippedRowCount: skippedRowCount
            )
        }
    }

    /// A weight-and-reps set, or nil for a row Unit cannot log: timed holds
    /// and cardio (no reps), and impossible numbers. A blank weight is 0,
    /// which Unit shows as bodyweight on a bodyweight exercise.
    private static func makeSet(
        weightText: String,
        unit: ImportWeightUnit?,
        repsText: String,
        isWarmup: Bool,
        rpeText: String,
        note: String,
        decimalComma: Bool
    ) -> ImportedSet? {
        guard let repsValue = number(repsText, decimalComma: decimalComma),
              repsValue >= 1, repsValue <= 1_000,
              repsValue == repsValue.rounded() else { return nil }
        let weight: Double
        if weightText.isEmpty {
            weight = 0
        } else if let value = number(weightText, decimalComma: decimalComma), value.isFinite, value >= 0 {
            weight = value
        } else {
            return nil
        }
        guard (unit ?? .kg).kilograms(weight) <= maximumWeightKg else { return nil }
        let rpe = number(rpeText, decimalComma: decimalComma).flatMap { (1...10).contains($0) ? $0 : nil } ?? 0
        return ImportedSet(
            weight: weight,
            unit: unit,
            reps: Int(repsValue),
            isWarmup: isWarmup,
            rpe: rpe,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private static func number(_ text: String, decimalComma: Bool) -> Double? {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return Double(decimalComma ? trimmed.replacingOccurrences(of: ",", with: ".") : trimmed)
    }

    /// One formatter per layout, and each distinct date string read once:
    /// every set row of a workout repeats the same start time.
    private struct DateReader {
        private let formatters: [DateFormatter]
        private var cache: [String: Date?] = [:]

        init(formats: [String], timeZone: TimeZone) {
            formatters = formats.map { format in
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.calendar = Calendar(identifier: .gregorian)
                formatter.timeZone = timeZone
                formatter.dateFormat = format
                return formatter
            }
        }

        mutating func date(_ text: String) -> Date? {
            if let cached = cache[text] { return cached }
            let parsed = formatters.lazy.compactMap { $0.date(from: text) }.first
            cache[text] = parsed
            return parsed
        }
    }

    private static func field(_ row: [String], _ index: Int) -> String {
        row.indices.contains(index) ? row[index].trimmingCharacters(in: .whitespacesAndNewlines) : ""
    }

    /// RFC 4180 records: quoted fields may hold the delimiter, line breaks
    /// and doubled quotes. Works on UTF-8 bytes; every structural character
    /// is ASCII, so multi-byte names pass through untouched.
    static func records(in text: String, delimiter: UInt8) -> [[String]] {
        let quote = UInt8(ascii: "\""), newline = UInt8(ascii: "\n"), carriageReturn = UInt8(ascii: "\r")
        var records: [[String]] = []
        var record: [String] = []
        var field: [UInt8] = []
        var inQuotes = false
        var bytes = Array(text.utf8)
        bytes.append(newline)
        var index = 0
        while index < bytes.count {
            let byte = bytes[index]
            if inQuotes {
                if byte == quote {
                    if index + 1 < bytes.count, bytes[index + 1] == quote {
                        field.append(quote)
                        index += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(byte)
                }
            } else if byte == quote {
                inQuotes = true
            } else if byte == delimiter {
                record.append(String(decoding: field, as: UTF8.self))
                field.removeAll(keepingCapacity: true)
            } else if byte == newline || byte == carriageReturn {
                if byte == carriageReturn, index + 1 < bytes.count, bytes[index + 1] == newline { index += 1 }
                record.append(String(decoding: field, as: UTF8.self))
                field.removeAll(keepingCapacity: true)
                if !(record.count == 1 && record[0].isEmpty) { records.append(record) }
                record.removeAll(keepingCapacity: true)
            } else {
                field.append(byte)
            }
            index += 1
        }
        return records
    }
}
