//
//  OnboardingProgramImportView.swift
//  Unit
//
//  Screen 4 — Parse a pasted plan into structured day data, then continue
//  straight to the exercises step where editing and reordering live.
//

import SwiftUI
import Vision

/// Single source of truth for paste-mode placeholder copy.
private enum ProgramPasteFormatGuide {
    /// Combined intro (replaces separate subtitle + footer under the editor). Full rules stay in the format sheet.
    static let subtitle =
        "Paste from Notes, chat, or a document. One day per line, exercises below."

    /// Placeholder is examples only — short, by design (long rules live in the format examples sheet).
    /// Bare numbers (no `kg` / `lb`) are easier for the user to type; the parser
    /// reads any trailing number after `setsxreps` as a weight in the user's
    /// chosen unit (set in step 1, the unit picker). `BW` stays for
    /// bodyweight-only moves where no number applies.
    static let placeholderExamples = [
        "Push",
        "Bench press 4x8 60",
        "Incline DB press 3x10 22",
        "",
        "Pull",
        "Deadlift 3x5 100",
        "Pull-up 4x8 BW",
    ].joined(separator: "\n")
}

struct OnboardingProgramImportView: View {
    @Environment(OnboardingViewModel.self) private var vm

    var progressStep: Int
    var progressTotal: Int
    var onContinue: () -> Void
    var onBack: () -> Void

    @State private var pastedText = ""
    @State private var isParsing = false
    @State private var errorMessage: String?
    /// Drives the format-examples sheet. Inline disclosure was replaced with a
    /// sheet so the screen body stays a single fixed-height stack — TextEditor
    /// flexes, ghost button + CTA pin to the bottom safe area. An inline
    /// expansion would push the sticky CTA past the screen edge and force the
    /// outer ScrollView the editor never plays nicely with.
    @State private var showingFormatSheet = false
    /// Bumped on parse failure so `AppHaptic.validationError` fires —
    /// silent rejection of a "Read program" tap is the worst-of-both-worlds.
    /// Pair with the auto-presented format sheet so the buzz lands alongside
    /// a visible path forward.
    @State private var parseErrorTrigger: Int = 0

    private var canParse: Bool {
        !pastedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        OnboardingShell(
            title: "Paste your program",
            subtitle: ProgramPasteFormatGuide.subtitle,
            ctaLabel: parseLabel,
            ctaEnabled: canParse && !isParsing,
            // No gate caption: the placeholder ("Push / Bench press 4x8 60 /
            // …") + the disabled "Read program" label make the requirement
            // self-evident; the extra line just doubles the chrome above the
            // CTA.
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: { Task { await parseProgram() } },
            onBack: onBack,
            // Editor screens own their own scroll (the `TextEditor` is a
            // UITextView underneath). Wrapping in `AppScreen`'s outer
            // `ScrollView` was breaking tap-to-focus and letting the disclosure
            // push the sticky CTA past the safe-area bottom.
            usesOuterScroll: false
            // Note: deliberately *not* opting into `showsKeyboardDismissToolbar`.
            // iOS 26 renders `ToolbarItemGroup(placement: .keyboard)` content as
            // a persistent floating Liquid Glass accessory pill at the bottom
            // safe area — even when the keyboard is dismissed. That pill not
            // only pollutes the layout but also steals bottom-inset space,
            // shoving the sticky "Read program" CTA mid-screen. Users dismiss
            // the keyboard with the system swipe-down gesture or by tapping
            // "Read program" (which submits and removes focus).
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                // No `.frame(maxHeight: .infinity)` — the editor card stays at
                // its natural `minHeight: 220` and the inner `TextEditor`
                // (a UITextView) scrolls internally once pasted content
                // exceeds 220pt. Letting the card flex to fill the full
                // vertical area made a 3-line paste look like a giant empty
                // text field; iOS-native paste UX is a fixed-height card with
                // internal scroll.
                AppTextEditor(
                    text: $pastedText,
                    placeholder: ProgramPasteFormatGuide.placeholderExamples
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

                AppGhostButton("Show format examples") {
                    showingFormatSheet = true
                }

                if isParsing {
                    HStack(spacing: AppSpacing.sm) {
                        ProgressView()
                            .controlSize(.small)
                        Text("Reading exercises, reps, and weights.")
                            .font(AppFont.body.font)
                            .foregroundStyle(AppColor.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .sheet(isPresented: $showingFormatSheet) {
            ProgramFormatGuideSheet()
                .presentationDetents([.medium, .large])
                .appBottomSheetChrome()
        }
        .alert("Couldn't read that program", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("Got it", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .appHaptic(.validationError, trigger: parseErrorTrigger)
    }

    private var parseLabel: String {
        isParsing ? "Reading…" : "Read program"
    }

    @MainActor
    private func parseProgram() async {
        guard !isParsing else { return }
        isParsing = true
        defer { isParsing = false }

        let parsed = ProgramImportParser.parse(pastedText, defaultUnit: vm.unitSystem)
        guard !parsed.isEmpty else {
            errorMessage = "Couldn't find exercises. Put each day on its own line, then list each exercise below it."
            // Auto-present the format sheet so the user sees a valid template
            // the moment the alert is dismissed — beats an alert with no path
            // forward. Idempotent: tapping "Read program" again on still-bad
            // input just keeps the sheet flagged for next show.
            showingFormatSheet = true
            parseErrorTrigger &+= 1
            return
        }
        vm.applyImportedProgram(parsed)
        onContinue()
    }
}

private struct ProgramFormatGuideSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        AppSheetScreen(
            title: "Format examples",
            dismissLabel: AppCopy.Nav.done,
            dismissActionPlacement: .confirmation,
            onDismissAction: { dismiss() },
            usesOuterScroll: false
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                ruleSection(
                    title: "Day names",
                    body: "One day name per line: Push, Pull, Legs, Upper, Lower, Full body, Arms, Chest, Back, Shoulders, Day 1–6, or a weekday."
                )
                ruleSection(
                    title: "Exercises",
                    body: "Below each day, one exercise per line: name, then setsxreps, then weight. Example: Bench press 4x8 60."
                )
                ruleSection(
                    title: "Weight",
                    body: "Plain numbers use your chosen unit. Add kg or lb to override per line. Use BW for bodyweight moves."
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func ruleSection(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(title)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)
            Text(body)
                .font(AppFont.body.font)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Parser

enum ProgramImportParser {
    private static let knownDayNames = [
        "push", "pull", "legs", "upper", "lower", "full body", "arms",
        "chest", "back", "shoulders", "day 1", "day 2", "day 3", "day 4", "day 5", "day 6",
        "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
    ]

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

    /// `defaultUnit` is the user's chosen unit (`"kg"` or `"lb"`) from step 1,
    /// applied to any number on a line that has *no* explicit `kg` / `lb`
    /// suffix. Lets the user type `Bench press 4x8 60` and have `60` parsed
    /// as their unit instead of being silently dropped.
    static func parse(_ rawText: String, defaultUnit: String = "kg") -> [ImportedProgramDay] {
        let lines = rawText
            .components(separatedBy: .newlines)
            .map { sanitizeLine($0) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else { return [] }

        var days: [ImportedProgramDay] = []
        var currentDayName = "Workout 1"
        var currentExercises: [ImportedProgramExercise] = []

        func flushCurrentDay() {
            guard !currentExercises.isEmpty else { return }
            days.append(ImportedProgramDay(name: currentDayName, exercises: currentExercises))
            currentExercises = []
        }

        for line in lines {
            if line.hasPrefix("//") {
                continue
            }

            if let heading = parsedDayHeading(from: line) {
                flushCurrentDay()
                currentDayName = heading
                continue
            }

            if let exercise = parsedExercise(from: line, defaultUnit: defaultUnit) {
                currentExercises.append(exercise)
            }
        }

        flushCurrentDay()

        if days.isEmpty {
            let exercises = lines.compactMap { parsedExercise(from: $0, defaultUnit: defaultUnit) }
            if !exercises.isEmpty {
                days = [ImportedProgramDay(name: "Workout 1", exercises: exercises)]
            }
        }

        return Array(days.prefix(6))
    }

    private static func sanitizeLine(_ line: String) -> String {
        line
            .replacingOccurrences(of: "\t", with: " ")
            .replacingOccurrences(of: "•", with: " ")
            .replacingOccurrences(of: "·", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parsedDayHeading(from line: String) -> String? {
        let lowered = line.lowercased()
        guard knownDayNames.contains(where: { lowered == $0 || lowered.hasPrefix("\($0):") || lowered.hasPrefix("\($0) ") }) else {
            return nil
        }
        return titleCaseHeading(line)
    }

    private static func titleCaseHeading(_ line: String) -> String {
        line
            .replacingOccurrences(of: ":", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }

    private static func parsedExercise(from line: String, defaultUnit: String = "kg") -> ImportedProgramExercise? {
        var remaining = line
        guard remaining.rangeOfCharacter(from: .letters) != nil else { return nil }

        let setsRepsPattern = #"(?i)\b(\d{1,2})\s*[x×]\s*(\d{1,3})\b"#
        let setsPattern = #"(?i)\bsets?\s*[:\-]?\s*(\d{1,2})\b"#
        let repsPattern = #"(?i)\breps?\s*[:\-]?\s*(\d{1,3})\b"#
        let weightPattern = #"(?i)\b(\d{1,3}(?:[.,]\d+)?)\s*(kg|kgs|lb|lbs)\b"#
        let bodyweightPattern = #"(?i)\b(bodyweight|bw)\b"#
        // Bare-number fallback for users who type `Bench press 4x8 60` without
        // a unit suffix. Runs *after* setsxreps + explicit-weight matches are
        // stripped, so `4x8` and `60kg` don't double-count. Treated as the
        // user's chosen unit.
        let implicitWeightPattern = #"\b(\d{1,3}(?:[.,]\d+)?)\b"#

        var sets: Int?
        var reps: Int?
        var weightKg: Double?

        if let match = firstMatch(in: remaining, pattern: setsRepsPattern),
           let setValue = Int(match[1]), let repValue = Int(match[2]) {
            sets = setValue
            reps = repValue
            remaining = remaining.replacingOccurrences(of: match[0], with: " ")
        }

        if sets == nil, let match = firstMatch(in: remaining, pattern: setsPattern), let setValue = Int(match[1]) {
            sets = setValue
            remaining = remaining.replacingOccurrences(of: match[0], with: " ")
        }

        if reps == nil, let match = firstMatch(in: remaining, pattern: repsPattern), let repValue = Int(match[1]) {
            reps = repValue
            remaining = remaining.replacingOccurrences(of: match[0], with: " ")
        }

        if let match = firstMatch(in: remaining, pattern: weightPattern) {
            let numericString = match[1].replacingOccurrences(of: ",", with: ".")
            let unit = match[2].lowercased()
            if let value = Double(numericString) {
                weightKg = unit.hasPrefix("lb") ? value / 2.20462 : value
            }
            remaining = remaining.replacingOccurrences(of: match[0], with: " ")
        } else if firstMatch(in: remaining, pattern: bodyweightPattern) != nil {
            remaining = replacingMatches(in: remaining, pattern: bodyweightPattern, with: " ")
        } else if let match = firstMatch(in: remaining, pattern: implicitWeightPattern) {
            // Bare number → user's chosen unit. Convert to kg for storage.
            let numericString = match[1].replacingOccurrences(of: ",", with: ".")
            if let value = Double(numericString) {
                weightKg = defaultUnit == "lb" ? value / 2.20462 : value
            }
            remaining = remaining.replacingOccurrences(of: match[0], with: " ")
        }

        remaining = replacingMatches(in: remaining, pattern: #"(?i)\b\d+\b"#, with: " ")
        remaining = remaining.replacingOccurrences(of: "-", with: " ")
        remaining = remaining.replacingOccurrences(of: "/", with: " ")
        remaining = remaining.replacingOccurrences(of: "(", with: " ")
        remaining = remaining.replacingOccurrences(of: ")", with: " ")
        remaining = remaining
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard remaining.rangeOfCharacter(from: .letters) != nil else { return nil }
        let cleanedName = remaining.capitalized

        return ImportedProgramExercise(
            name: cleanedName,
            sets: sets,
            reps: reps,
            weightKg: weightKg
        )
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

    private static func replacingMatches(in text: String, pattern: String, with replacement: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: replacement)
    }
}

#Preview {
    OnboardingProgramImportView(progressStep: 3, progressTotal: 4, onContinue: {}, onBack: {})
        .environment(OnboardingViewModel())
}
