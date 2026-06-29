//
//  ProgramImportParser.swift
//  Unit
//
//  Stage-based parser for pasted lifting programs. Replaces the regex-soup
//  that lived inline in `OnboardingProgramImportView.swift`. Pipeline:
//
//      Raw text
//        → 1. Sanitize lines
//        → 2. Classify each line (heading / exercise / comment / empty / noise)
//        → 3. Group exercises under headings into ImportedProgramDay
//        → 4. Tokenize each exercise line (slot-fill: sets, reps, weight,
//             duration, distance, side flag, bodyweight, intent, form notes)
//        → 5. Normalize tokens into ImportedProgramExercise + build the
//             parser-captured `note` (per-side · duration · distance ·
//             intent · form note) for detail the data model can't store
//             structurally yet.
//        → 6. Filter pure-conditioning lines (CLAUDE.md §3) into warnings.
//      [ImportedProgramDay] + [Warning] (via ProgramImportResult)
//
//  Vocabularies (Vocabulary enum below) are the single biggest correctness
//  lever — in-name modifiers stay glued to the exercise root so the catalog
//  doesn't alias `Pause Deadlift` into `Deadlift` (different exercises with
//  different ghost-value baselines); intent qualifiers are stripped and
//  surfaced as notes so `Heavy Goblet Squat` and `Goblet Squat` resolve to
//  the same catalog entry.
//
//  Deferred to v2 (per plan scope fence): per-side reps / duration /
//  distance / tempo / supersets / AMRAP as structured data-model fields.
//  The parser RECOGNIZES these patterns; the data they extract lives in
//  the `note` string for now and migrates to structured fields later.
//

import Foundation
import UIKit
import Vision

// MARK: - Public result type

/// Output of `ProgramImportParser.parseWithWarnings`. `days` is the parsed
/// program; `warnings` is a side-channel the UI uses to surface footers
/// (e.g. "2 lines skipped: Bike Intervals, Easy Bike Cooldown") so silent
/// drops never happen — the lifter always sees what the parser dropped.
struct ProgramImportResult: Equatable {
    var days: [ImportedProgramDay]
    var warnings: [Warning]

    enum Warning: Equatable {
        /// Parser hit the v1 6-day cap; trailing days were truncated.
        /// Includes the dropped day names so the UI can name them.
        case truncatedAtSixDays(droppedNames: [String])
        /// Pure-conditioning lines (`Bike Intervals`, `Easy Bike Cooldown`,
        /// `Treadmill 10min`) filtered per CLAUDE.md §3 scope fence.
        /// Includes the original line text so the lifter sees what dropped.
        case skippedConditioning(lines: [String])
        /// Lines that didn't classify as heading, exercise, or conditioning —
        /// previously dropped silently as `.noise`. Surfaces the count so a
        /// lifter who pasted free-text intro paragraphs or stray coach
        /// commentary sees the parser didn't keep them. Limited to the count
        /// (not the raw text) because the originals are often boilerplate the
        /// lifter doesn't need to re-read.
        case noisyLines(count: Int)
        /// Lines that had a recognizable exercise name but no prescription
        /// data (sets / reps / weight / duration). Previously dropped; now
        /// kept as `sets=nil, reps=nil` so the lifter can fill in-app. The
        /// warning surfaces the names so they're visible above the day list.
        case exerciseNameOnly(names: [String])
    }
}

// MARK: - Parser

enum ProgramImportParser {

    // MARK: Public API

    /// Convenience wrapper that returns just the days, discarding warnings.
    /// Kept for call sites that don't need the parser footer (tests, OCR
    /// pipelines, etc.).
    static func parse(_ rawText: String, defaultUnit: String = "kg") -> [ImportedProgramDay] {
        parseWithWarnings(rawText, defaultUnit: defaultUnit).days
    }

    /// Full parse with side-channel warnings for the UI footer.
    /// `defaultUnit` is the lifter's chosen unit ("kg" or "lb") from the
    /// unit-picker step — applied to bare numbers on a line that has no
    /// explicit `kg` / `lb` suffix.
    static func parseWithWarnings(_ rawText: String, defaultUnit: String = "kg") -> ProgramImportResult {
        let sanitized = sanitizeLines(rawText)
        guard !sanitized.isEmpty else {
            return ProgramImportResult(days: [], warnings: [])
        }

        let classifications = classifyLines(sanitized)
        let grouped = groupIntoDays(classifications, sanitizedLines: sanitized, defaultUnit: defaultUnit)

        var warnings: [ProgramImportResult.Warning] = []

        // Conditioning warning
        if !grouped.skippedConditioning.isEmpty {
            warnings.append(.skippedConditioning(lines: grouped.skippedConditioning))
        }

        // Noisy-line warning — un-parseable lines that previously dropped
        // silently. Surfaced as a count so the lifter can spot-check the
        // original paste and re-edit if something important was missed.
        if grouped.noisyLineCount > 0 {
            warnings.append(.noisyLines(count: grouped.noisyLineCount))
        }

        // 6-day cap warning
        let capped: [ImportedProgramDay]
        if grouped.days.count > 6 {
            let kept = Array(grouped.days.prefix(6))
            let dropped = Array(grouped.days.dropFirst(6)).map(\.name)
            warnings.append(.truncatedAtSixDays(droppedNames: dropped))
            capped = kept
        } else {
            capped = grouped.days
        }

        return ProgramImportResult(days: capped, warnings: warnings)
    }

    /// Vision OCR helper for image-paste paths. Kept untouched from the
    /// previous parser — the photo OCR flow may resurrect post-v1 and this
    /// is its only entry point.
    static func extractText(from data: Data) async -> String {
        guard let image = UIImage(data: data),
              let cgImage = image.cgImage else {
            return ""
        }

        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage)
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }

    // MARK: Stage 1 — Sanitize

    /// Per-line trimming + tab/bullet character normalization. Preserves
    /// empty lines (they're meaningful for heuristic day detection — a
    /// blank line followed by a short label is a strong heading signal).
    ///
    /// Also strips ChatGPT-style markdown wrappers (`**bold**`, `__under__`,
    /// trailing `:` after headings, leading blockquote `>`) so the parser
    /// can read both raw notes and AI-generated programs without leaving
    /// asterisks in day names.
    private static func sanitizeLines(_ rawText: String) -> [String] {
        rawText
            .components(separatedBy: .newlines)
            .map { line in
                var sanitized = line
                    .replacingOccurrences(of: "\t", with: " ")
                    .replacingOccurrences(of: "•", with: " ")
                    .replacingOccurrences(of: "·", with: " ")
                    .replacingOccurrences(of: "—", with: " — ") // em-dash gets space padding so it tokenizes cleanly
                    .replacingOccurrences(of: "–", with: " – ")
                    .trimmingCharacters(in: .whitespaces)

                // Strip leading blockquote chrome (Markdown / mail-reply style).
                while sanitized.hasPrefix(">") {
                    sanitized = String(sanitized.dropFirst()).trimmingCharacters(in: .whitespaces)
                }

                // Strip markdown emphasis wrappers without altering interior text.
                // `**Day 1: Push**` → `Day 1: Push`; `__Pull__ 4x8` → `Pull 4x8`.
                sanitized = stripMarkdownEmphasis(sanitized)

                // Normalize markdown / Notion / Bear table rows into the
                // canonical `Name NxR W` form so downstream stages don't
                // need a table-specific tokenizer. The separator row
                // (`| --- | --- |`) collapses to empty and is dropped
                // downstream as `.empty`.
                if let canonical = normalizedTableRow(sanitized) {
                    sanitized = canonical
                }

                return sanitized
            }
    }

    /// Recognize a `|`-delimited table row and rewrite it into the canonical
    /// `Name NxR W` form. Returns nil for non-table rows. Recognizes:
    /// - Header rows (`| Exercise | Sets | Reps | Weight |`) → empty (drops).
    /// - Separator rows (`| --- | --- |`) → empty (drops).
    /// - Data rows (`| Bench | 4 | 8 | 60 |`) → `Bench 4x8 60`.
    /// - Data rows with weight suffix (`| Bench | 4 | 8 | 60kg |`) → `Bench 4x8 60kg`.
    /// - Data rows without weight (`| Bench | 4 | 8 |`) → `Bench 4x8`.
    private static func normalizedTableRow(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("|"), trimmed.hasSuffix("|") else { return nil }

        let cells = trimmed
            .dropFirst()
            .dropLast()
            .components(separatedBy: "|")
            .map { $0.trimmingCharacters(in: .whitespaces) }

        guard cells.count >= 3 else { return nil }

        // Separator row: every cell is all `-` / `:` / whitespace.
        let separatorCharset = CharacterSet(charactersIn: "-:")
        let isSeparator = cells.allSatisfy { cell in
            !cell.isEmpty && cell.unicodeScalars.allSatisfy(separatorCharset.contains)
        }
        if isSeparator { return "" }

        // Header row: every cell is non-numeric (no digits at all).
        let isHeader = cells.allSatisfy { cell in
            !cell.isEmpty && !cell.contains(where: \.isNumber)
        }
        if isHeader { return "" }

        // Data row: first cell is name (must contain letters), second is sets
        // (integer), third is reps (integer). Fourth cell (if present) is the
        // weight — copy verbatim so explicit `kg`/`lb` suffixes survive.
        let name = cells[0]
        guard name.rangeOfCharacter(from: .letters) != nil,
              let sets = Int(cells[1].trimmingCharacters(in: .whitespaces)),
              let reps = Int(cells[2].trimmingCharacters(in: .whitespaces)) else {
            return nil
        }

        var canonical = "\(name) \(sets)x\(reps)"
        if cells.count >= 4 {
            let weightCell = cells[3].trimmingCharacters(in: .whitespaces)
            if !weightCell.isEmpty {
                canonical += " \(weightCell)"
            }
        }
        return canonical
    }

    /// Strips paired `**…**` and `__…__` markdown emphasis wrappers from
    /// anywhere in the line. Idempotent and safe on partial pairs (e.g. a
    /// bare `**` with no closer just gets dropped). Common in ChatGPT
    /// program outputs and Notion/Bear exports.
    private static func stripMarkdownEmphasis(_ line: String) -> String {
        var working = line
        // Two passes: bold-wrapper variants first (`**…**`, `__…__`), then
        // single-marker leftovers. Each pass uses a non-greedy regex so
        // multiple emphasis pairs on the same line don't collapse into one.
        for pattern in [#"\*\*([^*]+)\*\*"#, #"__([^_]+)__"#] {
            working = replacingMatches(in: working, pattern: pattern, with: "$1")
        }
        // Drop stray unmatched markers — leaves the readable text intact.
        working = working
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: "__", with: "")
        return working.trimmingCharacters(in: .whitespaces)
    }

    // MARK: Stage 2 — Classify

    enum LineClass: Equatable {
        case heading(String)
        case exercise
        case comment
        case empty
        case noise
    }

    private static func classifyLines(_ lines: [String]) -> [LineClass] {
        var result: [LineClass] = []
        result.reserveCapacity(lines.count)

        for (i, line) in lines.enumerated() {
            if line.isEmpty {
                result.append(.empty)
                continue
            }
            if line.hasPrefix("//") {
                result.append(.comment)
                continue
            }

            // Heading classifiers in priority order: markdown beats vocab
            // beats heuristic. If multiple could match, pick the most
            // explicit one so the lifter's intent ("I literally wrote
            // ## Day 1") wins over best-guess heuristics.
            if let h = markdownHeadingText(line) {
                result.append(.heading(h))
                continue
            }
            if let h = vocabHeadingText(line) {
                result.append(.heading(h))
                continue
            }
            if looksLikeExercise(line) {
                result.append(.exercise)
                continue
            }
            if isHeuristicHeading(line: line, atIndex: i, in: lines) {
                result.append(.heading(titleCaseHeading(line)))
                continue
            }
            result.append(.noise)
        }

        return result
    }

    /// Detects `#`, `##`, `###` style markdown headings. Strips the leading
    /// `#`s and any trailing `:` so `## Day 1:` and `### Push` both parse.
    private static func markdownHeadingText(_ line: String) -> String? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return nil }
        var text = trimmed
        while text.hasPrefix("#") {
            text.removeFirst()
        }
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: " \t:"))
        guard !text.isEmpty else { return nil }
        return titleCaseHeading(text)
    }

    /// Multi-word vocabulary match for known day labels. Tolerates trailing
    /// `:` and trailing free text after a space (so `Push: heavy day` and
    /// `Day 1 — Pull` both match `push` / `day 1`).
    private static func vocabHeadingText(_ line: String) -> String? {
        let lowered = line.lowercased().trimmingCharacters(in: .whitespaces)
        // Strip a single trailing `:` so vocab compares cleanly.
        let stripped = lowered.hasSuffix(":")
            ? String(lowered.dropLast()).trimmingCharacters(in: .whitespaces)
            : lowered

        if Vocabulary.dayHeadings.contains(stripped) {
            return titleCaseHeading(line)
        }

        // Prefix match — `push day` matches `push`; `day 1: pull` matches
        // `day 1`. Sorted longest-first so `post striking 1` beats `post
        // striking` when both prefix-match.
        let hasPrescriptionData = looksLikeExercise(line)
        let sorted = Vocabulary.dayHeadings.sorted { $0.count > $1.count }
        for name in sorted {
            if stripped == name {
                return titleCaseHeading(line)
            }

            // Do not let broad body-part headings steal prescribed exercise
            // lines. Without this, `Back Squat 3x5 100kg` matched the `back`
            // day-heading prefix and became a bogus day name.
            guard !hasPrescriptionData else { continue }

            if stripped.hasPrefix("\(name):")
                || stripped.hasPrefix("\(name) ")
                || stripped.hasPrefix("\(name)—")
                || stripped.hasPrefix("\(name) —")
                || stripped.hasPrefix("\(name)-")
                || stripped.hasPrefix("\(name) -") {
                return titleCaseHeading(line)
            }
        }
        return nil
    }

    /// Heuristic heading: looks like a label, sits at a structural break,
    /// is followed by exercise-shaped lines. Catches non-vocab labels the
    /// lifter invents (`WAVE 1`, `STRENGTH BLOCK A`, `HYPERTROPHY`).
    private static func isHeuristicHeading(line: String, atIndex i: Int, in lines: [String]) -> Bool {
        guard line.count <= 40 else { return false }
        if firstMatch(in: line, pattern: Regex.setsRepsAny) != nil { return false }
        if firstMatch(in: line, pattern: Regex.weightUnit) != nil { return false }

        let alphaCount = line.filter { $0.isLetter }.count
        guard Double(alphaCount) / Double(max(line.count, 1)) >= 0.5 else { return false }

        // Preceded by a blank line OR is the first non-blank line in the
        // document — labels never appear mid-exercise-list without a
        // visual break, and Apple Notes / chat exports almost always put
        // a blank line before a new section.
        let priorIsBlank: Bool
        if i == 0 {
            priorIsBlank = true
        } else {
            priorIsBlank = lines[i - 1].isEmpty
        }
        guard priorIsBlank else { return false }

        // Followed within 5 non-blank lines by ≥ 1 exercise-shaped line.
        // Guards against treating the last line of a free-text intro
        // ("Here's my program for the week") as a heading.
        var nonBlankCount = 0
        for j in (i + 1)..<lines.count {
            if nonBlankCount >= 5 { break }
            let next = lines[j]
            if next.isEmpty { continue }
            nonBlankCount += 1
            if looksLikeExercise(next) {
                return true
            }
        }
        return false
    }

    /// Quick "this line has prescription data" sniff used by both the
    /// classifier (to decide exercise vs heading) and the heading
    /// heuristic (to confirm a candidate is followed by real exercises).
    private static func looksLikeExercise(_ line: String) -> Bool {
        if firstMatch(in: line, pattern: Regex.setsRepsAny) != nil { return true }
        if firstMatch(in: line, pattern: Regex.weightUnit) != nil { return true }
        if firstMatch(in: line, pattern: Regex.standaloneDurationOrDistance) != nil { return true }
        // Wendler-style slash rep schemes (`5/3/1`, `8/6/4`) — common in
        // strength programs and previously dropped silently as noise.
        if firstMatch(in: line, pattern: Regex.slashRepScheme) != nil { return true }
        // Verbose `N sets` / `N reps` form (HeavySet PHUL rows, ChatGPT
        // narrative output). Without this sniff `A. Bench Press, 3-4
        // sets, 3-5 reps, 2:00 rest` classified as noise even though the
        // tokenizer can split it correctly downstream.
        if firstMatch(in: line, pattern: Regex.verboseSetsOrReps) != nil { return true }
        return false
    }

    // MARK: Stage 3 — Day Grouper

    private struct GroupedResult {
        var days: [ImportedProgramDay]
        var skippedConditioning: [String]
        /// Count of lines classified as `.noise` (un-parseable). Previously
        /// dropped silently; now surfaced as a warning footer so the lifter
        /// sees the parser didn't keep them.
        var noisyLineCount: Int
    }

    private static func groupIntoDays(
        _ classifications: [LineClass],
        sanitizedLines: [String],
        defaultUnit: String
    ) -> GroupedResult {
        var days: [ImportedProgramDay] = []
        var currentDayName = "Workout 1"
        var currentExercises: [ImportedProgramExercise] = []
        var skippedConditioning: [String] = []
        var noisyLineCount = 0

        func flush() {
            guard !currentExercises.isEmpty else { return }
            days.append(ImportedProgramDay(name: currentDayName, exercises: currentExercises))
            currentExercises = []
        }

        for (index, classification) in classifications.enumerated() {
            switch classification {
            case .heading(let name):
                flush()
                currentDayName = name
            case .exercise:
                let line = sanitizedLines[index]
                guard let tokenized = tokenizeExercise(line, defaultUnit: defaultUnit) else {
                    // Tokenizer dropped it (no letters survived cleanup) —
                    // count this as a noisy line so the lifter sees it
                    // didn't make it into the program.
                    noisyLineCount += 1
                    continue
                }
                if Filter.isPureConditioning(tokenized: tokenized) {
                    skippedConditioning.append(line)
                    continue
                }
                if var normalized = Normalizer.normalize(tokenized: tokenized) {
                    // Thread the raw line through so the Exercises step can
                    // render `From: <line>` under each parsed row in paste
                    // mode — catches mismatches between what the lifter
                    // typed and what the parser read.
                    normalized.originalLine = line
                    currentExercises.append(normalized)
                } else {
                    noisyLineCount += 1
                }
            case .noise:
                noisyLineCount += 1
            case .comment, .empty:
                continue
            }
        }
        flush()

        return GroupedResult(
            days: days,
            skippedConditioning: skippedConditioning,
            noisyLineCount: noisyLineCount
        )
    }

    // MARK: Stage 4 — Tokenizer

    /// All the structured data a single exercise line can carry. The
    /// `weightKg` / `sets` / `reps` triplet maps to existing model fields;
    /// `durationSeconds` / `distanceMeters` / `isPerSide` / `capturedIntent`
    /// / `capturedFormNotes` get composed into the `note` string by the
    /// normalizer (the data model can't store them structurally yet).
    struct TokenizedExercise: Equatable {
        var name: String
        var sets: Int?
        var reps: Int?
        var weightKg: Double?
        var durationSeconds: Int?
        var distanceMeters: Double?
        var isPerSide: Bool
        var isBodyweight: Bool
        var capturedIntent: [String]
        var capturedFormNotes: [String]
    }

    private static func tokenizeExercise(_ line: String, defaultUnit: String) -> TokenizedExercise? {
        var remaining = line

        // 1. Strip leading bullet / letter / number prefix (`- Squat`,
        // `A. Squat`, `1) Squat`).
        remaining = stripLeadingPrefix(remaining)

        // 2. Parenthesized form notes — capture FIRST so the contents
        // don't bleed into other patterns (`Bench (close grip) 4x8` would
        // try to parse `close grip` otherwise).
        var capturedFormNotes: [String] = []
        let parens = stripParenthesizedNotes(remaining)
        capturedFormNotes.append(contentsOf: parens.notes)
        remaining = parens.remaining

        // 3. Em-dash trailing form notes (`Bench 4x8 — close grip`).
        let dashed = stripEmDashTrailingNote(remaining)
        if let note = dashed.note { capturedFormNotes.append(note) }
        remaining = dashed.remaining

        // 4. Per-side flag (do this BEFORE sets×reps because `each side`
        // contains no digits but its position matters for cleanup).
        let sideResult = stripPerSideFlag(remaining)
        let isPerSide = sideResult.found
        remaining = sideResult.remaining

        // 5. Sets × duration/distance — `3x40m`, `6x20s`. Must come BEFORE
        // sets×reps so we don't read `3x40` as 3 sets of 40 reps.
        var sets: Int?
        var reps: Int?
        var durationSeconds: Int?
        var distanceMeters: Double?
        var weightKg: Double?

        if let r = matchSetsTimesDurationOrDistance(remaining) {
            sets = r.sets
            durationSeconds = r.durationSeconds
            distanceMeters = r.distanceMeters
            remaining = r.remaining
        }

        // 5a. Triple-`x` shorthand (`4x8x60`) — catch before plain sets×reps
        // so the third number doesn't leak into the name as a stray `X`.
        if sets == nil, reps == nil, let r = matchSetsTimesRepsTimesWeight(remaining, defaultUnit: defaultUnit) {
            sets = r.sets
            reps = r.reps
            weightKg = r.weightKg
            remaining = r.remaining
        }

        // 5b. Verbose "X sets x Y reps" (`4 sets x 8 reps`) and "X sets of Y
        // reps" (`4 sets of 8 reps`) — caught as one match so the connector
        // words (`sets`, `of`, `reps`) don't survive cleanup and leak into
        // the exercise name. Common in ChatGPT-generated programs and
        // long-form coach notes.
        if sets == nil, reps == nil, let r = matchSetsXRepsVerbose(remaining) {
            sets = r.sets
            reps = r.reps
            remaining = r.remaining
        }
        if sets == nil, reps == nil, let r = matchSetsOfReps(remaining) {
            sets = r.sets
            reps = r.reps
            remaining = r.remaining
        }

        // 5c. Wendler-style slash rep schemes (`5/3/1`, `8/6/4`). Treat as
        // sets=3 (one set per number) and reps=first number (the heaviest /
        // top set, which is what the lifter cares about for the ghost-value
        // baseline). Full scheme survives in `capturedFormNotes` so the
        // Exercises step shows "5/3/1 scheme" under the row.
        if sets == nil, reps == nil, let r = matchSlashRepScheme(remaining) {
            sets = r.sets
            reps = r.reps
            capturedFormNotes.append(r.scheme)
            remaining = r.remaining
        }

        // 6. Sets × reps (no trailing unit on the reps number).
        if sets == nil, reps == nil, let r = matchSetsTimesReps(remaining) {
            sets = r.sets
            reps = r.reps
            remaining = r.remaining
            // Strip the rep-range upper bound when present (`4x8-12 60kg`
            // → after consuming `4x8`, drop the `-12` so it doesn't leak
            // into the name or get mis-read as a weight by the bare-number
            // fallback). Bounded to `\d{1,3}` so unrelated dashes elsewhere
            // in the line stay intact.
            remaining = stripRepRangeUpperBound(remaining)
        }

        // 7. "4 sets" / "8 reps" word-form (fallback for verbose lines that
        // didn't hit one of the combined matchers above).
        if sets == nil, let r = matchSetsAlone(remaining) {
            sets = r.sets
            remaining = r.remaining
        }
        if reps == nil, let r = matchRepsAlone(remaining) {
            reps = r.reps
            remaining = r.remaining
        }

        // 8. Standalone duration / distance (no `Nx` prefix) —
        // `Cooldown 10min`, `Run 1km`. When the line already carries a full
        // sets×reps prescription, a trailing short duration is the rest-column
        // value of a pasted table (`Barbell Row 67.5 4x8 8 2dk`), not work —
        // strip it from the name but don't surface it as a work duration in
        // the note. A duration-only line (no reps, e.g. `Incline Walk 35dk`)
        // still captures it.
        if durationSeconds == nil, let r = matchStandaloneDuration(remaining) {
            remaining = r.remaining
            if sets == nil || reps == nil {
                durationSeconds = r.durationSeconds
            }
        }
        if distanceMeters == nil, let r = matchStandaloneDistance(remaining) {
            distanceMeters = r.distanceMeters
            remaining = r.remaining
        }

        // 9. Bodyweight tokens (BW / bodyweight). Capture flag and any
        // added weight (`+25kg`) before the generic weight matcher runs,
        // so `BW+25` and `BW 25kg` both land on `isBodyweight=true,
        // weightKg=25`. `weightKg` is declared at the top of the function
        // because step 5a (triple-`x` shorthand) may have already set it.
        var isBodyweight = false
        let bw = matchBodyweightTokens(remaining)
        if bw.found {
            isBodyweight = true
            if let added = bw.addedWeightKg {
                weightKg = added
            }
            remaining = bw.remaining
        }

        // 10. Explicit weight (60kg / 60lb / 60#).
        if weightKg == nil, let r = matchExplicitWeight(remaining) {
            weightKg = r.weightKg
            remaining = r.remaining
        }

        // 11. Bare-number weight fallback (60 in `Bench 4x8 60`). Skips
        // numbers immediately followed by `%`, `RPE`, or `RIR` — those
        // are intensity / autoregulation cues, not weights, and the
        // previous regression read `5x5 @ 80%` as `weightKg=80`. When a
        // skip hits, the cue is captured in the form notes so the lifter
        // still sees what was on the line.
        if weightKg == nil, let r = matchBareNumberAsWeight(remaining, defaultUnit: defaultUnit) {
            if r.rejected != nil {
                if let note = r.rejected {
                    capturedFormNotes.append(note)
                }
                remaining = r.remaining
            } else if let weight = r.weightKg {
                weightKg = weight
                remaining = r.remaining
            }
        }

        // 12. Intent qualifier strip (Heavy / Light / Explosive / Easy).
        // Only strip when followed by an alpha token — `Bench heavy`
        // (intent at end) stays in the name because we can't be sure
        // it's not part of a custom exercise name.
        let intent = stripIntentQualifiers(remaining)
        remaining = intent.remaining

        // 13. Cleanup leftover punctuation + collapse whitespace.
        //
        // Orphan time-of-day patterns (`2:00 rest`, `1:30 rest`) get stripped
        // FIRST, before the `:` → space normalization, so the `2:00` stays
        // recognizable as a time token. After that, normalize punctuation
        // (colons, commas, `@`, `%`) to spaces and strip connector words.
        remaining = replacingMatches(in: remaining, pattern: #"\b\d{1,2}:\d{2}\b"#, with: " ")

        remaining = remaining
            .replacingOccurrences(of: ":", with: " ")
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: "@", with: " ")
            .replacingOccurrences(of: "%", with: " ")

        // Strip stray connector tokens that survived prescription parsing —
        // `of`, `by`, `rest`, and isolated `x` / `X`. Done with word
        // boundaries so `Box Squat` keeps its `x` and `Bicycle` keeps its
        // `cy`. The space-flanked dash (` - `) is dropped because it
        // almost always separates verbose prescription from the name
        // (`Bench Press - 4 sets x 8 reps`); a hyphen with no surrounding
        // space stays so `Pull-up` survives.
        //
        // Orphan rep-range remnants (`3-` left from `3-4 sets` after
        // `matchSetsAlone` consumed the upper bound) get stripped via the
        // digit-dash patterns below.
        for pattern in [
            #"(?i)\b(of|by|rest)\b"#,
            #"(?i)\b[xX]\b"#,
            #"\b\d{1,3}\s*-(?![A-Za-z\d])"#,        // `3-` orphan with no following alpha/digit
            #"(?<![A-Za-z\d])-\s*\d{1,3}\b"#,       // `-3` orphan with no preceding alpha/digit
            #"\s+-\s+"#                              // space-flanked dash separator
        ] {
            remaining = replacingMatches(in: remaining, pattern: pattern, with: " ")
        }

        // After all the targeted strips, any remaining digit-only token
        // (no letters anywhere in it) is residue from a prescription that
        // didn't fully consume — drop it. Exercise names with embedded
        // digits keep at least one letter ("45-Degree Back Extension",
        // "T-Bar Row") so this only catches genuine residue.
        remaining = remaining
            .components(separatedBy: .whitespaces)
            .filter { token in
                guard !token.isEmpty else { return false }
                if token.rangeOfCharacter(from: .letters) != nil { return true }
                return false
            }
            .joined(separator: " ")

        remaining = remaining
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)

        guard remaining.rangeOfCharacter(from: .letters) != nil else { return nil }

        return TokenizedExercise(
            name: titleCaseName(remaining),
            sets: sets,
            reps: reps,
            weightKg: weightKg,
            durationSeconds: durationSeconds,
            distanceMeters: distanceMeters,
            isPerSide: isPerSide,
            isBodyweight: isBodyweight,
            capturedIntent: intent.stripped,
            capturedFormNotes: capturedFormNotes
        )
    }

    // MARK: Stage 5 — Normalizer (renamed namespace below)

    enum Normalizer {

        static func normalize(tokenized: TokenizedExercise) -> ImportedProgramExercise? {
            // Build the note from captures. Order matters — per-side
            // first because it's the most actionable cue ("oh, I should
            // do 5 on each side, not 5 total"); then prescription detail
            // (duration / distance) which the lifter wrote intentionally;
            // then intent qualifiers; then free-form form notes.
            var noteParts: [String] = []

            if tokenized.isPerSide {
                noteParts.append("Each side")
            }
            if let d = tokenized.durationSeconds {
                noteParts.append(formatDuration(seconds: d))
            }
            if let m = tokenized.distanceMeters {
                noteParts.append(formatDistance(meters: m))
            }
            for word in tokenized.capturedIntent {
                noteParts.append(word.capitalized)
            }
            for note in tokenized.capturedFormNotes {
                let trimmed = note.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    noteParts.append(trimmed)
                }
            }

            let note = noteParts.isEmpty ? nil : noteParts.joined(separator: " · ")

            // Determine sets / reps with sensible defaults.
            var sets = tokenized.sets
            var reps = tokenized.reps

            // Duration / distance prescription with no rep count: reps=1
            // is the placeholder — the lifter logs the time/distance via
            // the note; the rep field becomes a "this is one carry/hold"
            // counter. Better than dropping the line.
            if reps == nil && (tokenized.durationSeconds != nil || tokenized.distanceMeters != nil) {
                reps = 1
            }
            // Reps without sets → 1 set (rare; defensive).
            if reps != nil && sets == nil {
                sets = 1
            }

            // Pure noise — no prescription data at all and no name signal
            // either. Drop.
            guard sets != nil || reps != nil || tokenized.weightKg != nil || tokenized.durationSeconds != nil || tokenized.distanceMeters != nil else {
                return nil
            }

            return ImportedProgramExercise(
                name: tokenized.name,
                sets: sets,
                reps: reps,
                weightKg: tokenized.weightKg,
                note: note
            )
        }

        private static func formatDuration(seconds: Int) -> String {
            if seconds >= 60 && seconds % 60 == 0 {
                return "\(seconds / 60) min"
            }
            if seconds >= 60 {
                let minutes = seconds / 60
                let s = seconds % 60
                return "\(minutes) min \(s) s"
            }
            return "\(seconds) s"
        }

        private static func formatDistance(meters: Double) -> String {
            // Whole meters most of the time; preserve one decimal otherwise.
            if meters == floor(meters) {
                return "\(Int(meters)) m"
            }
            return String(format: "%.1f m", meters)
        }
    }

    // MARK: Stage 6 — Filter

    enum Filter {
        /// True when the tokenized line's name is *entirely* conditioning
        /// vocabulary. Two-pass check:
        ///
        /// 1. **Exact phrase match** — covers multi-word phrases that
        ///    aren't decomposable token-by-token, e.g. `bike intervals`
        ///    where `intervals` alone isn't conditioning but the phrase is.
        /// 2. **All-tokens-in-vocab fallback** — every space-separated
        ///    token of the name is in the conditioning set. Catches
        ///    `Treadmill cooldown`, `Bike sprints`, etc. without forcing
        ///    every n-gram into the vocabulary.
        ///
        /// `Inverted Row` and `Barbell Row` keep: `inverted`/`barbell`
        /// aren't in the vocab, so the all-tokens fallback fails.
        /// `Cable Crossover` keeps: neither token is conditioning. The
        /// risk is that single-word conditioning lines like just "Bike"
        /// always drop — which is the intent.
        static func isPureConditioning(tokenized: TokenizedExercise) -> Bool {
            let lowered = tokenized
                .name
                .lowercased()
                .trimmingCharacters(in: .whitespaces)
            if Vocabulary.conditioningPhrases.contains(lowered) {
                return true
            }
            let tokens = lowered.split(separator: " ").map(String.init)
            guard !tokens.isEmpty else { return false }
            return tokens.allSatisfy { Vocabulary.conditioningPhrases.contains($0) }
        }
    }

    // MARK: - Vocabulary

    enum Vocabulary {

        /// Multi-word day-heading vocabulary. Single-word entries (push /
        /// pull / weekdays / etc.) live here too for one lookup table.
        /// Lowercased; whitespace-trimmed; tested against the full
        /// trimmed line.
        static let dayHeadings: Set<String> = [
            // Body-part splits (single-word)
            "push", "pull", "legs", "upper", "lower", "full body", "arms",
            "chest", "back", "shoulders",
            // Weekdays — both full and common abbreviations
            "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday",
            "mon", "tue", "tues", "wed", "thu", "thur", "thurs", "fri", "sat", "sun",
            // Day / Workout / Session / Week numbering
            "day 1", "day 2", "day 3", "day 4", "day 5", "day 6", "day 7",
            "workout a", "workout b", "workout c", "workout d",
            "session 1", "session 2", "session 3", "session 4", "session 5",
            "week 1", "week 2", "week 3", "week 4", "week 5", "week 6",
            "week 7", "week 8", "week 9", "week 10", "week 11", "week 12",
            // Combat / hybrid contexts
            "main day", "off day", "rest day", "roll day", "lift day", "lifting day",
            "strength day", "volume day", "intensity day", "heavy day", "light day",
            "me upper", "me lower", "de upper", "de lower",
            "max effort upper", "max effort lower",
            "dynamic effort upper", "dynamic effort lower",
            "pre strike", "post strike", "pre striking", "post striking",
            "pre striking 1", "post striking 1", "post striking 2", "post striking 3",
            "pre grappling", "post grappling", "pre wrestling", "post wrestling",
            "pre roll", "post roll", "conditioning day", "accessory day",
            "arms day", "pump day", "leg day", "back day", "chest day",
            "shoulder day", "shoulders day"
        ]

        /// Intent / intensity qualifiers — stripped from `displayName`,
        /// surfaced as part of `note` so the lifter sees what the parser
        /// dropped. Strip only when followed by another alpha token so
        /// `Bench heavy` stays intact (might be the lifter's exercise name).
        static let intentQualifiers: Set<String> = [
            "heavy", "light", "easy", "hard", "working",
            "top", "top-set", "back-off", "back-set", "down", "down-set",
            "joker", "explosive", "dynamic", "speed", "velocity"
        ]

        /// Pure-conditioning phrases. The parser tokenizes the line
        /// normally, then drops it (with a warning) if the post-token
        /// `name` matches one of these whole-string. Match is whole-line,
        /// not substring — so `Inverted Row` (a strength move) doesn't get
        /// filtered just because `row` would be a cardio machine in
        /// isolation.
        static let conditioningPhrases: Set<String> = [
            "bike", "stationary bike", "bike intervals", "bike cooldown",
            "bike warmup", "bike sprints", "assault bike", "spin bike",
            "cycling", "cycle",
            "run", "running", "jog", "jogging", "sprint", "sprints",
            "treadmill", "elliptical", "stairmaster", "versaclimber",
            "erg", "erg row", "rowing erg", "rowing",
            "cardio", "conditioning", "cooldown", "cool down",
            "warmup", "warm up",
            "intervals", "tabata",
            // Walking / treadmill cardio. Single-word "walk"/"walking" stay
            // safe because compound strength names carry a non-conditioning
            // token ("Farmer's Walk", "Walking Lunge" both keep). The
            // multi-word phrases catch the common incline-treadmill finisher.
            "walk", "walking", "incline walk", "treadmill walk", "incline treadmill walk",
            "bike intervals", "easy bike cooldown"
        ]

        /// Side-flag phrases — order matters (longest first) so partial
        /// matches don't shadow more specific ones. Lowercased; the
        /// matcher does case-insensitive substring detection.
        static let sideFlags: [String] = [
            "each arm/leg", "each side", "each leg", "each arm",
            "per side", "per leg", "per arm",
            "alternating", "alternate",
            "e/s", "e/leg", "e/arm",
            "(l/r)", "(l)", "(r)", "l/r"
        ]
    }

    // MARK: - Regex patterns (named for readability)

    private enum Regex {
        /// Generic `NxM` with optional spaces around `x`/`×`. Doesn't care
        /// about trailing unit — used by classifier sniff and by both the
        /// sets×reps and sets×duration matchers (which then disambiguate
        /// on the trailing suffix).
        /// `NxM` sniff. Uses `(?!\d)` (negative lookahead for digit)
        /// instead of `\b` after the reps number so it still matches when
        /// the reps are immediately followed by a letter — e.g. `3x40m`
        /// (sets × distance), `6x20s` (sets × duration). The original
        /// `\b` failed silently on these because both `0` and `m` are
        /// word characters (no boundary between them), and the line
        /// was classified as `.noise` and dropped. The tokenizer
        /// disambiguates `3x40` (reps) vs `3x40m` (distance) via the
        /// trailing-unit reject in `matchSetsTimesReps`.
        static let setsRepsAny = #"\b(\d{1,2})\s*[x×]\s*(\d{1,3})(?!\d)"#

        /// `\d+` followed by a weight unit. Used to disqualify a line from
        /// being a heading and to find explicit weights inside an
        /// exercise line.
        static let weightUnit = #"\b\d{1,3}(?:[.,]\d+)?\s*(?:kg|kgs|lb|lbs|#)\b"#

        /// `\d+` followed by a duration or distance unit. `min` listed
        /// before `m` so `10min` doesn't match as `10 m + in`.
        /// Word-boundary anchored on both sides so `40m` parses but `40mg`
        /// (unlikely but possible) doesn't. Turkish `dk` (dakika / minute)
        /// and `sn` (saniye / second) are included so pasted TR programs
        /// (`35dk`, `60sn`) tokenize cleanly instead of leaking the unit
        /// into the exercise name. Longer alternatives precede shorter so
        /// `dakika` wins over `dk` and `sn` wins over `s` under ICU's
        /// ordered alternation.
        static let durationUnit = "(?:minutes|mins|min|dakika|dk|seconds|secs|sec|saniye|sn|s)"
        static let distanceUnit = "(?:kilometers|meters|miles|yards|feet|km|mi|ft|yd|m)"

        static let standaloneDurationOrDistance =
            #"\b\d{1,4}(?:[.,]\d+)?\s*"# + "(?:" + durationUnit + "|" + distanceUnit + ")" + #"\b"#

        /// Verbose sets/reps form: `4 sets`, `8 reps`, `3 set`, `12 rep`.
        /// Used by `looksLikeExercise` as a fallback sniff so HeavySet
        /// PHUL comma rows and ChatGPT narrative pastes classify as
        /// exercises instead of getting dropped silently.
        static let verboseSetsOrReps = #"(?i)\b\d{1,2}\s*(?:sets?|reps?)\b"#

        /// Wendler-style slash rep schemes: `5/3/1`, `8/6/4`, `12/10/8`. Two or
        /// three slash-separated single/double digits with no decimal points or
        /// other context. Anchored on both sides so `60/40` (a percentage or
        /// loading split) doesn't false-positive — it lacks the third member
        /// of the trio that signals "this is a rep scheme."
        static let slashRepScheme = #"\b\d{1,2}/\d{1,2}/\d{1,2}\b"#

        /// Triple-`x` notation (`4x8x60`) used by some old-school logging apps
        /// to mean "4 sets × 8 reps × 60 weight". Caught upfront so the third
        /// number doesn't leak into the name. Anchored on both sides so it
        /// doesn't match in the middle of a longer numeric sequence.
        static let setsRepsTimesWeight =
            #"\b(\d{1,2})\s*[x×]\s*(\d{1,3})\s*[x×]\s*(\d{1,4}(?:[.,]\d+)?)\b"#

        /// "X sets of Y reps" word form — caught as one match instead of two
        /// (`matchSetsAlone` + `matchRepsAlone`) so the `of` connector doesn't
        /// survive cleanup and leak into the exercise name. Case-insensitive.
        static let setsOfReps = #"(?i)\b(\d{1,2})\s*sets?\s+of\s+(\d{1,3})\s*reps?\b"#

        /// Verbose ChatGPT-style "X sets x Y reps" — `\d sets x \d reps`.
        /// Same goal as `setsOfReps`: catch both numbers in one match so the
        /// `sets` and `reps` words don't survive cleanup.
        static let setsXReps = #"(?i)\b(\d{1,2})\s*sets?\s*[x×]\s*(\d{1,3})\s*reps?\b"#
    }

    // MARK: - Match helpers — per-stage pattern extractors

    private static func stripLeadingPrefix(_ line: String) -> String {
        // Bullet, letter (A. / A) / A1.), or number (1. / 1) / 1:) prefix.
        let pattern = #"^\s*(?:[-*–—•]|[A-Za-z]\d?[.):]|\d+[.):])\s*"#
        return replacingMatches(in: line, pattern: pattern, with: "")
            .trimmingCharacters(in: .whitespaces)
    }

    private static func stripPerSideFlag(_ line: String) -> (remaining: String, found: Bool) {
        let lowered = line.lowercased()
        for flag in Vocabulary.sideFlags {
            if lowered.contains(flag) {
                // Case-insensitive removal.
                let range = lowered.range(of: flag)!
                let nsRange = NSRange(range, in: lowered)
                let nsLine = line as NSString
                var stripped = nsLine.replacingCharacters(in: nsRange, with: " ")
                stripped = collapseWhitespace(stripped)
                return (stripped, true)
            }
        }
        return (line, false)
    }

    private static func matchSetsTimesDurationOrDistance(_ line: String) -> (sets: Int, durationSeconds: Int?, distanceMeters: Double?, remaining: String)? {
        let pattern = #"\b(\d{1,2})\s*[x×]\s*(\d{1,4}(?:[.,]\d+)?)\s*("# + Regex.durationUnit + "|" + Regex.distanceUnit + #")\b"#
        guard let match = firstMatch(in: line, pattern: pattern),
              let setVal = Int(match[1]) else { return nil }

        let numeric = match[2].replacingOccurrences(of: ",", with: ".")
        let unit = match[3].lowercased()
        let value = Double(numeric) ?? 0

        var dur: Int? = nil
        var dist: Double? = nil
        if isDurationUnit(unit) {
            dur = secondsForDuration(value: value, unit: unit)
        } else {
            dist = metersForDistance(value: value, unit: unit)
        }

        let remaining = replacingFirst(in: line, match: match[0]).trimmingCharacters(in: .whitespaces)
        return (setVal, dur, dist, collapseWhitespace(remaining))
    }

    /// Triple-`x` shorthand: `4x8x60` → 4 sets × 8 reps × 60 weight. Catches
    /// the third number explicitly so it doesn't leak into the exercise
    /// name as a stray `X`. The weight is converted under the lifter's
    /// `defaultUnit` (lb → kg), same as the bare-number and explicit-weight
    /// paths, so the seeded first-session ghost shows the right value.
    private static func matchSetsTimesRepsTimesWeight(_ line: String, defaultUnit: String) -> (sets: Int, reps: Int, weightKg: Double, remaining: String)? {
        guard let match = firstMatch(in: line, pattern: Regex.setsRepsTimesWeight),
              let setVal = Int(match[1]),
              let repVal = Int(match[2]) else { return nil }
        let numeric = match[3].replacingOccurrences(of: ",", with: ".")
        guard let weight = Double(numeric) else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        // Convert under the lifter's chosen unit, same as the bare-number
        // path: `4x8x135` for an lb user is 135 lb → stored as kg. (This
        // returned the raw number as kg before — harmless while the weight
        // was discarded, but wrong once it seeds the first-session ghost.)
        let kg = defaultUnit == "lb" ? weight / 2.20462 : weight
        return (setVal, repVal, kg, collapseWhitespace(remaining))
    }

    /// Verbose "X sets x Y reps" — `4 sets x 8 reps`, common in ChatGPT
    /// programs. Caught as one match so `sets` and `reps` connector words
    /// don't survive cleanup and leak into the exercise name.
    private static func matchSetsXRepsVerbose(_ line: String) -> (sets: Int, reps: Int, remaining: String)? {
        guard let match = firstMatch(in: line, pattern: Regex.setsXReps),
              let setVal = Int(match[1]),
              let repVal = Int(match[2]) else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        return (setVal, repVal, collapseWhitespace(remaining))
    }

    /// "X sets of Y reps" — `4 sets of 8 reps`, common in coach notes.
    /// Same intent as `matchSetsXRepsVerbose`: consume the connector word
    /// (`of`) along with the two numbers so it doesn't survive cleanup.
    private static func matchSetsOfReps(_ line: String) -> (sets: Int, reps: Int, remaining: String)? {
        guard let match = firstMatch(in: line, pattern: Regex.setsOfReps),
              let setVal = Int(match[1]),
              let repVal = Int(match[2]) else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        return (setVal, repVal, collapseWhitespace(remaining))
    }

    /// Wendler-style slash rep scheme: `5/3/1`, `8/6/4`, `12/10/8`. The
    /// first number is the heaviest / top set (what the lifter cares about
    /// for the ghost-value baseline); the scheme is treated as sets=3 (one
    /// per number) and reps=first number. Full original scheme is returned
    /// so the caller can stash it in the form-notes for visibility.
    private static func matchSlashRepScheme(_ line: String) -> (sets: Int, reps: Int, scheme: String, remaining: String)? {
        guard let match = firstMatch(in: line, pattern: Regex.slashRepScheme) else { return nil }
        let parts = match[0].split(separator: "/").compactMap { Int($0) }
        guard parts.count == 3, let topReps = parts.first else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        return (parts.count, topReps, match[0] + " scheme", collapseWhitespace(remaining))
    }

    /// Strips the upper bound of a rep range that survived `matchSetsTimesReps`.
    /// `4x8-12 60kg` parses as sets=4 reps=8 and leaves `-12 60kg` behind; this
    /// runs before any bare-number weight matcher so the upper bound never
    /// leaks into the name or gets mis-read as a weight. The hyphen must be
    /// adjacent to whitespace or the end of a previous token — bounded
    /// strictly so `Pull-up` and other hyphenated names stay intact.
    private static func stripRepRangeUpperBound(_ line: String) -> String {
        let pattern = #"\s*-\s*\d{1,3}\b"#
        let stripped = replacingMatches(in: line, pattern: pattern, with: " ")
        return collapseWhitespace(stripped)
    }

    private static func matchSetsTimesReps(_ line: String) -> (sets: Int, reps: Int, remaining: String)? {
        // Plain `NxM` not followed by a duration / distance / weight unit.
        // Negative lookahead would be cleanest but NSRegularExpression's
        // lookahead support is limited; instead we match the broad pattern
        // then reject if the immediate suffix is a unit.
        guard let match = firstMatch(in: line, pattern: Regex.setsRepsAny),
              let setVal = Int(match[1]),
              let repVal = Int(match[2]) else { return nil }

        // Reject if the next non-space char is a unit letter (kg / lb / m
        // / s / min). Those should have been caught by the duration /
        // weight matchers earlier; if we got here, something's odd.
        if let range = line.range(of: match[0]) {
            let afterIndex = range.upperBound
            let suffix = String(line[afterIndex...]).trimmingCharacters(in: .whitespaces)
            let lower = suffix.lowercased()
            for unit in ["kg", "kgs", "lb", "lbs", "min", "mins", "minutes",
                         "dakika", "dk", "sec", "secs", "seconds", "saniye", "sn",
                         "m", "km", "mi", "ft", "yd", "s"]
            where lower.hasPrefix(unit) && (lower.count == unit.count || !lower.dropFirst(unit.count).first!.isLetter) {
                return nil
            }
        }

        let remaining = replacingFirst(in: line, match: match[0]).trimmingCharacters(in: .whitespaces)
        return (setVal, repVal, collapseWhitespace(remaining))
    }

    private static func matchSetsAlone(_ line: String) -> (sets: Int, remaining: String)? {
        let pattern = #"(?i)\b(\d{1,2})\s*sets?\b"#
        guard let match = firstMatch(in: line, pattern: pattern), let val = Int(match[1]) else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        return (val, collapseWhitespace(remaining))
    }

    private static func matchRepsAlone(_ line: String) -> (reps: Int, remaining: String)? {
        let pattern = #"(?i)\b(\d{1,3})\s*reps?\b"#
        guard let match = firstMatch(in: line, pattern: pattern), let val = Int(match[1]) else { return nil }
        let remaining = replacingFirst(in: line, match: match[0])
        return (val, collapseWhitespace(remaining))
    }

    private static func matchStandaloneDuration(_ line: String) -> (durationSeconds: Int, remaining: String)? {
        let pattern = #"\b(\d{1,4}(?:[.,]\d+)?)\s*("# + Regex.durationUnit + #")\b"#
        guard let match = firstMatch(in: line, pattern: pattern) else { return nil }
        let numeric = match[1].replacingOccurrences(of: ",", with: ".")
        let value = Double(numeric) ?? 0
        let unit = match[2].lowercased()
        let seconds = secondsForDuration(value: value, unit: unit)
        let remaining = replacingFirst(in: line, match: match[0])
        return (seconds, collapseWhitespace(remaining))
    }

    private static func matchStandaloneDistance(_ line: String) -> (distanceMeters: Double, remaining: String)? {
        let pattern = #"\b(\d{1,4}(?:[.,]\d+)?)\s*("# + Regex.distanceUnit + #")\b"#
        guard let match = firstMatch(in: line, pattern: pattern) else { return nil }
        let numeric = match[1].replacingOccurrences(of: ",", with: ".")
        let value = Double(numeric) ?? 0
        let unit = match[2].lowercased()
        let meters = metersForDistance(value: value, unit: unit)
        let remaining = replacingFirst(in: line, match: match[0])
        return (meters, collapseWhitespace(remaining))
    }

    private static func matchBodyweightTokens(_ line: String) -> (remaining: String, found: Bool, addedWeightKg: Double?) {
        // Patterns: `BW`, `bodyweight`, `body weight`, `BW+25kg`, `+25kg`
        // when adjacent to BW. Order: check added-weight form first so we
        // capture both flag and weight in one pass.
        let plusPattern = #"(?i)\b(?:bw|bodyweight|body\s*weight)\s*\+\s*(\d{1,3}(?:[.,]\d+)?)\s*(kg|kgs|lb|lbs)?\b"#
        if let m = firstMatch(in: line, pattern: plusPattern) {
            let numeric = m[1].replacingOccurrences(of: ",", with: ".")
            let value = Double(numeric) ?? 0
            let unit = (m.count > 2 ? m[2] : "kg").lowercased()
            let kg = unit.hasPrefix("lb") ? value / 2.20462 : value
            let remaining = replacingFirst(in: line, match: m[0])
            return (collapseWhitespace(remaining), true, kg)
        }

        let bwPattern = #"(?i)\b(bw|bodyweight|body\s*weight)\b"#
        if let m = firstMatch(in: line, pattern: bwPattern) {
            let remaining = replacingFirst(in: line, match: m[0])
            return (collapseWhitespace(remaining), true, nil)
        }

        return (line, false, nil)
    }

    private static func matchExplicitWeight(_ line: String) -> (weightKg: Double, remaining: String)? {
        let pattern = #"\b(\d{1,4}(?:[.,]\d+)?)\s*(kg|kgs|lb|lbs|#)\b"#
        guard let m = firstMatch(in: line, pattern: pattern) else { return nil }
        let numeric = m[1].replacingOccurrences(of: ",", with: ".")
        let unit = m[2].lowercased()
        guard let value = Double(numeric) else { return nil }
        let kg = (unit.hasPrefix("lb") || unit == "#") ? value / 2.20462 : value
        let remaining = replacingFirst(in: line, match: m[0])
        return (kg, collapseWhitespace(remaining))
    }

    /// Bare-number weight fallback. Returns one of:
    /// - `(weightKg: nil, rejected: "RPE 8", remaining: <stripped>)` — when
    ///   the number was a percentage / RPE / RIR cue and shouldn't be a weight.
    /// - `(weightKg: <kg>, rejected: nil, remaining: <stripped>)` — a real weight.
    /// - `nil` — no bare number found.
    ///
    /// The `rejected` form is captured as a form-note so the lifter sees what
    /// the parser read (e.g. `Bench 5x5 @ 80%` now logs sets=5 reps=5 with
    /// note "80%" instead of silently setting weight=80kg).
    private static func matchBareNumberAsWeight(_ line: String, defaultUnit: String) -> (weightKg: Double?, rejected: String?, remaining: String)? {
        let pattern = #"\b(\d{1,3}(?:[.,]\d+)?)\b"#
        guard let m = firstMatch(in: line, pattern: pattern) else { return nil }
        let numeric = m[1].replacingOccurrences(of: ",", with: ".")
        guard let value = Double(numeric) else { return nil }

        // What follows the matched number? If `%`, `RPE`, or `RIR`, this is
        // intensity / autoregulation, not a weight. Capture the cue and skip.
        if let range = line.range(of: m[0]) {
            let afterIndex = range.upperBound
            let suffix = String(line[afterIndex...]).trimmingCharacters(in: .whitespaces)
            let lower = suffix.lowercased()
            if lower.hasPrefix("%") {
                let remaining = replacingFirst(in: line, match: m[0])
                let cleaned = collapseWhitespace(remaining.replacingOccurrences(of: "%", with: " "))
                return (nil, "\(Int(value))%", cleaned)
            }
            if lower.hasPrefix("rpe") || lower.hasPrefix("rir") {
                // Strip the cue token along with the number — same pattern
                // as the rep-range remnant cleanup. Anchored on a word
                // boundary so "RPE" / "RIR" don't leak into the name.
                let cuePattern = #"(?i)\b(rpe|rir)\b"#
                let stripped = replacingMatches(in: line, pattern: cuePattern, with: " ")
                let remaining = replacingFirst(in: stripped, match: m[0])
                let cueWord = lower.hasPrefix("rpe") ? "RPE" : "RIR"
                return (nil, "\(cueWord) \(Int(value))", collapseWhitespace(remaining))
            }
        }

        let kg = defaultUnit == "lb" ? value / 2.20462 : value
        let remaining = replacingFirst(in: line, match: m[0])
        return (kg, nil, collapseWhitespace(remaining))
    }

    private static func stripIntentQualifiers(_ line: String) -> (remaining: String, stripped: [String]) {
        // Tokenize on whitespace; walk left-to-right; strip any token that
        // matches the intent vocabulary regardless of position. The
        // previous "only strip when followed by alpha" rule was meant to
        // protect lifter-named exercises like `Bench heavy`, but in
        // practice the parser runs AFTER sets/reps/weight extraction —
        // so `Barbell Deadlift 140kg Explosive 5x3` arrives here as
        // `Barbell Deadlift Explosive` (no successor) and the intent
        // word silently survived into the catalog name, fragmenting the
        // exercise into two entries (`Barbell Deadlift` vs `Barbell
        // Deadlift Explosive`). Stripping unconditionally keeps the
        // catalog deduplicated. False positive risk: a lifter who
        // literally named their exercise after an intent word (`Heavy
        // Day Special`) — vanishingly rare and they can rename in the
        // confirmation step.
        let tokens = line.split(separator: " ", omittingEmptySubsequences: false).map(String.init)
        var kept: [String] = []
        var stripped: [String] = []

        for token in tokens {
            let plain = token
                .lowercased()
                .trimmingCharacters(in: CharacterSet.punctuationCharacters)
            if Vocabulary.intentQualifiers.contains(plain) {
                stripped.append(plain)
            } else {
                kept.append(token)
            }
        }

        return (kept.joined(separator: " ").trimmingCharacters(in: .whitespaces), stripped)
    }

    private static func stripParenthesizedNotes(_ line: String) -> (remaining: String, notes: [String]) {
        let pattern = #"\(([^()]*)\)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return (line, []) }
        let nsLine = line as NSString
        let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
        guard !matches.isEmpty else { return (line, []) }

        var notes: [String] = []
        for m in matches where m.numberOfRanges > 1 {
            if let r = Range(m.range(at: 1), in: line) {
                let inner = String(line[r]).trimmingCharacters(in: .whitespaces)
                if !inner.isEmpty {
                    notes.append(inner)
                }
            }
        }

        let stripped = regex.stringByReplacingMatches(
            in: line,
            range: NSRange(location: 0, length: nsLine.length),
            withTemplate: " "
        )
        return (collapseWhitespace(stripped), notes)
    }

    private static func stripEmDashTrailingNote(_ line: String) -> (remaining: String, note: String?) {
        // Match `— note text` or `– note text` at the end of the line —
        // captures everything after the dash. Already space-padded by
        // sanitizeLines so the dash is a discrete token.
        let pattern = #"\s+[—–]\s+(.+)$"#
        guard let m = firstMatch(in: line, pattern: pattern) else { return (line, nil) }
        let note = m[1].trimmingCharacters(in: .whitespaces)
        let remaining = replacingFirst(in: line, match: m[0])
        return (collapseWhitespace(remaining), note.isEmpty ? nil : note)
    }

    // MARK: - Helpers

    private static func isDurationUnit(_ unit: String) -> Bool {
        ["minutes", "mins", "min", "dakika", "dk",
         "seconds", "secs", "sec", "saniye", "sn", "s"].contains(unit)
    }

    private static func secondsForDuration(value: Double, unit: String) -> Int {
        switch unit {
        case "minutes", "mins", "min", "dakika", "dk": return Int(value * 60)
        default: return Int(value)
        }
    }

    private static func metersForDistance(value: Double, unit: String) -> Double {
        switch unit {
        case "kilometers", "km": return value * 1000
        case "miles", "mi": return value * 1609.34
        case "yards", "yd": return value * 0.9144
        case "feet", "ft": return value * 0.3048
        default: return value
        }
    }

    private static func collapseWhitespace(_ text: String) -> String {
        text
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
    }

    /// Title-case a heading without `.capitalized`'s aggressive lowercasing
    /// of interior letters — preserves "MAIN DAY" → "Main Day" but also
    /// leaves "Day 1" alone (already in mixed case).
    private static func titleCaseHeading(_ line: String) -> String {
        let trimmed = line
            .trimmingCharacters(in: CharacterSet(charactersIn: " \t:-—–"))
        if trimmed.isEmpty { return line }
        return trimmed.capitalized
    }

    /// Capitalize an exercise name while preserving inner uppercase letters
    /// that look like initialisms (`KB`, `DB`, `RDL`). `.capitalized` alone
    /// would turn `KB` into `Kb`.
    private static func titleCaseName(_ line: String) -> String {
        let tokens = line.split(separator: " ").map(String.init)
        let capitalized = tokens.map { token -> String in
            // Preserve all-caps tokens up to 4 chars (initialisms).
            if token.count <= 4, token == token.uppercased(), token.contains(where: { $0.isLetter }) {
                return token
            }
            return token.capitalized
        }
        return capitalized.joined(separator: " ")
    }

    private static func firstMatch(in text: String, pattern: String) -> [String]? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        guard let match = regex.firstMatch(in: text, range: range) else { return nil }
        return (0..<match.numberOfRanges).compactMap { index in
            guard let range = Range(match.range(at: index), in: text) else { return nil }
            return String(text[range])
        }
    }

    private static func replacingFirst(in text: String, match: String) -> String {
        guard let range = text.range(of: match) else { return text }
        return text.replacingCharacters(in: range, with: " ")
    }

    private static func replacingMatches(in text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}
