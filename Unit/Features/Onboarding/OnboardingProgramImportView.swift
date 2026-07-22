//
//  OnboardingProgramImportView.swift
//  Unit
//
//  Screen 4 — Parse a pasted plan into structured day data, then continue
//  straight to the exercises step where editing and reordering live.
//

import SwiftUI

/// Single source of truth for paste-mode placeholder copy.
private enum ProgramPasteFormatGuide {
    /// One line: the title says paste, the subtitle only adds the one fact
    /// the controls don't show — typing works too. Format rules live in the
    /// format-examples sheet, not the header.
    static let subtitle = AppCopy.Onboarding.pasteSubtitle

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

    @State private var isParsing = false
    @State private var errorMessage: String?
    /// Drives the format-examples sheet. Inline disclosure was replaced with a
    /// sheet so the screen body stays a single fixed-height stack — TextEditor
    /// + ghost button + sticky CTA, no expand/collapse chrome competing with
    /// the editor.
    @State private var showingFormatSheet = false
    /// Bumped on parse failure so `AppHaptic.validationError` fires —
    /// silent rejection of a "Read program" tap is the worst-of-both-worlds.
    /// Pair with the auto-presented format sheet so the buzz lands alongside
    /// a visible path forward.
    @State private var parseErrorTrigger: Int = 0
    @FocusState private var isEditorFocused: Bool

    private var canParse: Bool {
        !vm.pastedProgramText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        @Bindable var vm = vm

        OnboardingShell(
            title: AppCopy.Onboarding.pasteTitle,
            subtitle: ProgramPasteFormatGuide.subtitle,
            ctaLabel: parseLabel,
            ctaEnabled: canParse && !isParsing,
            ctaDisabledReason: canParse ? nil : AppCopy.FormHint.onboardingImportPasteRequired,
            progressStep: progressStep,
            progressTotal: progressTotal,
            onContinue: {
                isEditorFocused = false
                Task { await parseProgram() }
            },
            onBack: onBack,
            // The editor owns scrolling. While it is focused, reclaim the
            // title/subtitle space for the input + sticky CTA and gate the
            // keyboard toolbar so its Done control cannot linger after focus.
            usesOuterScroll: false,
            showsKeyboardDismissToolbar: isEditorFocused,
            condensesHeader: isEditorFocused
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                AppTextEditor(
                    text: $vm.pastedProgramText,
                    placeholder: ProgramPasteFormatGuide.placeholderExamples,
                    // Flex the card so it owns the entire vertical space
                    // between the subtitle and the ghost button — gives long
                    // pastes room and matches the canonical "big input is the
                    // body of the screen" pattern (iOS Notes, Mail compose).
                    maxHeight: .infinity,
                    focus: $isEditorFocused
                )
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()

                if !isEditorFocused {
                    AppGhostButton("Show format examples") {
                        showingFormatSheet = true
                    }
                    .transition(.opacity)
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

        let result = ProgramImportParser.parseWithWarnings(
            vm.pastedProgramText,
            defaultUnit: vm.unitSystem
        )
        guard !result.days.isEmpty else {
            errorMessage = "Couldn't find exercises. Put each day on its own line, then list each exercise below it."
            // Auto-present the format sheet so the user sees a valid template
            // the moment the alert is dismissed — beats an alert with no path
            // forward. Idempotent: tapping "Read program" again on still-bad
            // input just keeps the sheet flagged for next show.
            showingFormatSheet = true
            parseErrorTrigger &+= 1
            return
        }
        vm.applyImportedProgram(result.days)
        // Pipe warnings through the viewmodel so the Exercises step can
        // render them as a footer ("2 lines skipped: …", "Only the first
        // 6 days were imported"). Setting AFTER applyImportedProgram is
        // important — that call doesn't touch `importWarnings` so the
        // assignment doesn't get clobbered.
        vm.importWarnings = result.warnings
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


#Preview {
    OnboardingProgramImportView(progressStep: 3, progressTotal: 4, onContinue: {}, onBack: {})
        .environment(OnboardingViewModel())
}
