//
//  AppCopy.swift
//  Unit
//
//  Central workout + navigation strings. Prefer these over ad-hoc literals in views.
//

import Foundation

enum AppCopy {
    enum Workout {
        static let finishShort = "Finish"
        static let saveFailedTitle = "Couldn’t save workout"
        static let saveFailedMessage = "Your previous data is unchanged. Try again."
        static let saveFailedToast = "\(saveFailedTitle). \(saveFailedMessage)"
        static func completeSetNumbered(_ number: Int) -> String { "Complete set \(number)" }
        static func lastTimeValue(_ setText: String) -> String { "Last time · \(setText)" }
        static let noStartingTarget = "No starting target yet"
        static let saveStartingTarget = "Save starting target"
        static let markNotDone = "Mark not done"
        static let addSet = "Add set"
        static func restIdle(_ time: String) -> String { "Rest \(time)" }
        static let restLabel = "Rest"
        /// Rest adjustment step, one source for buttons, VoiceOver and logic
        /// (30 seconds since 2026-10-23; was 20). The Lock Screen buttons use
        /// `RestTimerAttributes.stepSeconds`; a unit test keeps the two equal
        /// (this file is also built into the UI tests, which lack that type).
        static let restStepSeconds = 30
        static let restMinus = "−\(restStepSeconds)"
        static let restPlus = "+\(restStepSeconds)"
        static let restMinusLabel = "Subtract \(restStepSeconds) seconds"
        static let restPlusLabel = "Add \(restStepSeconds) seconds"
        static let restSkip = "Skip"
        static let restFinishedInline = "Rest finished"
        static func stepDown(unitSystem: String, reps: Bool) -> String { reps ? "−1" : (unitSystem == "lb" ? "−5" : "−2.5") }
        static func stepUp(unitSystem: String, reps: Bool) -> String { reps ? "+1" : (unitSystem == "lb" ? "+5" : "+2.5") }
        static let weightField = "Weight"
        static let editWeight = "Edit weight"
        static let editReps = "Edit reps"
        static let repsNext = "Reps ›"
        static func kgPrev(unitSystem: String) -> String { unitSystem == "lb" ? "‹ Lb" : "‹ Kg" }
        static let bodyweightToggle = "Bodyweight"
        static let startWorkout = "Start workout"
        static let continueWorkout = "Continue workout"
        static let completeSet = "Complete set"
        static let finishWorkout = "Finish workout"
        /// Freestyle session without a day template — Programs tab only (not on Today v1).
        static let freestyleSession = "Freestyle session"
        static let nextExercise = "Next exercise"
        /// Shown in place of the metric numeric when there is no prior set to display
        /// — tap opens manual entry. Reads as the starting-point on session 1 (first
        /// set ever) and stays accurate when an established user adds a brand-new
        /// exercise mid-session (first set for *this* exercise).
        static let logMetricHint = "Set weight and reps"
        static let saveTarget = "Save target"
        /// Adjust-result sheet — label above the optional note field (same row as weight/reps captions).
        static let adjustSetNoteLabel = "Note"
        /// Grey placeholder hinting how the note is used (supersets, equipment, etc.).
        static let adjustSetNotePlaceholder = "Superset curl"
        /// Sentence-case "Add exercise" — sheet title, primary CTA, and ghost button.
        static let addExercise = "Add exercise"
        /// Bodyweight abbreviation — shown in catalog rows, set tiles, ghost subtitles.
        static let bodyweightAbbrev = "BW"
        // Warm-up reminder + guidance sheet removed 2026-07-13:
        // Progression guidance stays post-workout — no coaching in the hot loop.
        /// Empty-state title shown when a freestyle session has no exercises yet.
        static let addFirstExerciseTitle = "Add your first exercise"
        /// Subtitle paired with `addFirstExerciseTitle`.
        static let addFirstExerciseHint = "Search the catalog or add your own."
        /// Title above the set-count picker sheet.
        static let setCountQuestion = "How many sets?"
        /// Supporting line in the set-count picker sheet.
        static func setCountPrompt(_ exerciseName: String) -> String { "Working sets for \(exerciseName)" }
        /// Title for the reusable routine-target editor sheet.
        static let editTarget = "Edit target"
        /// Labels inside the routine-target editor sheet.
        static let targetLabel = "Target"
        static let startingTargetLabel = "Starting target"
        static let targetSetsLabel = "Sets"
        static let targetRepsLabel = "Reps"
        static let progressionLabel = "Progression"
        static let progressionToggleLabel = "Increase reps, then weight"
        static let progressionExplanation = "Add weight when every set reaches the top."
        static let repRangeLabel = "Rep range"
        static let lowerRepsLabel = "Start reps"
        static let upperRepsLabel = "Top reps"
        static let weightIncrementLabel = "Weight increase"
        static let weightIncrementExplanation = "Smallest available step."
        static let nextTimeTitle = "Next time"
        static let lastResultLabel = "Last time"
        static let nextTargetLabel = "Next target"
        static let suggestedForNextTime = "Suggested"
        static let acceptedForNextTime = "Saved"
        static let repeatingForNextTime = "Kept"
        static let editedForNextTime = "Edited"
        static let noAutomaticTarget = "No automatic target"
        /// "Use next workout" was misread as "go to the next workout" in the
        /// 2026-10-23 persona panel; "Save" also matches the "Saved" status.
        /// Since 2026-10-24 Finish saves targets by itself; this shows only for
        /// a suggestion that could not be saved then.
        static let useThisTarget = "Save for next workout"
        /// After "Keep previous target" or an edit: back to the suggestion.
        static let useSuggestedTarget = "Use suggested target"
        /// Completed progression exercise during the workout. Read-only
        /// preview of the target Finish saves (2026-10-24); the summary
        /// offers "Keep previous target" and "Edit".
        static func exerciseDoneSuggestion(_ target: String, change: String) -> String {
            "Next time: \(target) · \(change)"
        }
        static func exerciseDoneNoSuggestion(_ reason: String) -> String {
            "No suggestion · \(reason)"
        }
        static let suggestionAddOneRep = "+1 rep"
        static let suggestionSameTarget = "same target"
        /// Pairs with the "Kept" status.
        static let keepPreviousTarget = "Keep previous target"
        static let edit = "Edit"
        static let editNextTarget = "Edit next target"
        static let targetsSaved = "Next targets saved"
        static let targetsSaveFailed = "Targets weren’t saved. Try again."
        static let allSetsReachedTopReason = "Every set reached the top."
        static let addARepReason = "Same weight. Add one rep."
        static let repeatTargetReason = "Keep this target."
        /// A repeated target names the planned sets that fell short
        /// (2026-10-24). Same target, no deload.
        static func stallReason(shortSets: [(number: Int, reps: Int)], targetReps: Int) -> String {
            guard let last = shortSets.last else { return repeatTargetReason }
            if shortSets.count == 1 {
                return "Set \(last.number): \(last.reps) of \(targetReps) reps. \(repeatTargetReason)"
            }
            let earlier = shortSets.dropLast().map { String($0.number) }.joined(separator: ", ")
            return "Sets \(earlier) and \(last.number): under \(targetReps) reps. \(repeatTargetReason)"
        }
        static let chooseTargetManually = "Set a target next workout."
        static let mixedWeightsUnavailable = "Weights varied."
        static let incompleteSetsUnavailable = "Some sets are unfinished."
        static let invalidIncrementUnavailable = "Set a weight increase."
        static let bodyweightUnavailable = "Added weight is required."
        static let invalidDataUnavailable = "No target available."

        /// Field caption above the weight input in `AdjustResultSheet`. The unit
        /// is read from `@AppStorage("unitSystem")` so a lifter in lb sees
        /// "Weight (lb)" — previously a hardcoded "Weight (kg)" leaked the
        /// developer-default unit into the most-used set-logging surface.
        /// Bodyweight exercises store only added external load in this field.
        /// Naming that meaning explicitly avoids making `10 kg` look like the
        /// lifter's bodyweight while preserving the existing storage model.
        static func weightLabel(isBodyweight: Bool, unitSystem: String) -> String {
            if isBodyweight { return "Added weight (\(unitSystem))" }
            return "Weight (\(unitSystem))"
        }

        /// Row title beside a field that already shows the unit.
        static func weightTitle(isBodyweight: Bool) -> String {
            isBodyweight ? "Added weight" : "Weight"
        }
        /// Unit beside the reps field in Edit set.
        static let repsUnit = "reps"

        /// Field caption above the reps input in `AdjustResultSheet`. Tokenized
        /// alongside `weightLabel` so all set-entry copy lives in one place
        /// instead of split between the design system and the view.
        static let repsLabel = "Reps"
        /// Lineup tag — shown next to the currently selected exercise in the lineup sheet.
        static let exerciseCurrentTag = "Current"
        /// PR badge headline — paired with a Verde checkmark inside `WorkoutCommandCard`.
        static let personalRecord = "Personal record"
        /// Compact PR chip on History session rows, detail headers, and set
        /// rows. VoiceOver expands it via `personalRecord`.
        static let prTag = "PR"
        /// Edit-mode title for `AdjustResultSheet` (tap a logged chip). Numbered to
        /// match the chip the user tapped — "Set 1", "Set 2", etc.
        static func editSet(_ setNumber: Int) -> String { "Set \(setNumber)" }
        /// Primary CTA in edit mode — replaces "Complete set" when correcting an existing entry.
        static let saveChanges = "Save changes"
        /// Destructive secondary in edit mode — removes the logged set.
        static let deleteSet = "Delete set"
        /// Edit workout menu action that opens a logged set's weight and reps.
        static let editSetAction = "Edit set"
        /// Prefix for the PR milestone delta line. Pairs with a kg×rep token (`Beat 145 kg × 8`).
        static func priorBest(_ priorBestText: String) -> String { "Beat \(priorBestText)" }

        // MARK: - Confirmation alerts
        // Each pair (title + destructive action + cancel + message) belongs together.
        // Destructive verbs name the *thing* being acted on, never a generic "OK"/"Yes" —
        // matches the "Delete project" not "Yes" rule and survives Dynamic Type.

        /// Cancel-the-whole-session alert (mid-workout). Destructive on a session
        /// with logged sets is genuinely lossy, so the message names the loss.
        static let cancelWorkoutTitle = "Cancel workout?"
        static let cancelWorkoutAction = "Cancel workout"
        static let cancelWorkoutMessage = "Logged sets will be lost."

        /// Skip-this-exercise alert. Action verb names the noun ("Skip exercise")
        /// so cancel/destructive read symmetrically with `cancelWorkout`.
        static let skipExerciseTitle = "Skip exercise?"
        static let skipExerciseAction = "Skip exercise"

        // MARK: - Exercise card menu (2026-10-24 benchmarks)
        /// VoiceOver name of the card's ⋯ menu; it holds more than editing.
        static let exerciseOptions = "Exercise options"
        static let swapExercise = "Swap exercise"
        static let removeAddedSet = "Remove added set"
        static let exerciseHistory = "Exercise history"
        static let addNote = "Add note"
        static let editNote = "Edit note"
        static let noteTitle = "Exercise note"
        static let notePlaceholder = "Seat 4, pin 6"
        static let noteMessage = "Shows every time you log this exercise."
        static let setRemoved = "Set removed"
        /// Lock Screen and rest-alert line under the next exercise's name.
        static func upNextDetail(setNumber: Int, value: String?) -> String {
            value.map { "Set \(setNumber) · \($0)" } ?? "Set \(setNumber)"
        }

        /// Save-and-end-session alert. Non-destructive but irreversible without
        /// undo, so the message previews the side effect.
        static let finishWorkoutTitle = "Finish workout?"
        static let finishWorkoutMessage = "Saves and ends your session."

        /// Inline naming prompt shown after a freestyle session finishes. Optional; the
        /// secondary "Skip" preserves the auto-name.
        static let nameWorkoutTitle = "Name this workout"
        static let nameWorkoutFieldPlaceholder = "Workout name"
        static let nameWorkoutMessage = "Helps you find it in History."

        /// Cancel labels paired with the destructive actions above. Two variants
        /// because "Keep going" reads naturally with cancel-workout (the lifter
        /// is mid-session) and "Keep logging" with skip-exercise (they're still
        /// on the current lift).
        static let keepGoing = "Keep going"
        static let keepLogging = "Keep logging"

        /// Warn-before-discard alert shown when the lifter tries to dismiss
        /// `AdjustResultSheet` with edited-but-unsaved fields. The title is a
        /// question (HIG: action sheets ask before they act), the destructive
        /// action names the thing (the entry), and the cancel keeps them in
        /// the sheet to finish typing.
        static let discardSetEntryTitle = "Discard this set?"
        static let discardSetEntryAction = "Discard"
        static let discardSetEntryMessage = "Your typed weight, reps, and note will be lost."
        /// Cancel label paired with `discardSetEntry*` — reads naturally
        /// because the lifter is mid-entry.
        static let keepEditing = "Keep editing"

        /// Single-fire toast surfaced after the user closes their first
        /// `AdjustResultSheet` edit. The gesture (tap a logged set chip to
        /// edit it) isn't visually labeled — the toast confirms the action
        /// they just discovered and signals it's reusable on every set.
        /// Persistence: `@AppStorage("hasSeenSetEditHint")`.
        static let setEditHint = "Tap a set to edit."
    }

    enum Nav {
        static let close = "Close"
        /// Dismiss button for alerts that only inform (Apple: "OK" only there).
        static let ok = "OK"
        static let history = "History"
        static let exercises = "Exercises"
        /// Generic dismiss for confirmations / form sheets. Pair with `role: .cancel`.
        static let cancel = "Cancel"
        /// Generic confirm-and-dismiss for sheet trailing toolbar buttons.
        static let done = "Done"
        /// Generic confirm-save action in form sheets (new exercise, etc.).
        static let save = "Save"
        /// Retry CTA on error alerts (saves, imports). Use sparingly.
        static let tryAgain = "Try again"
    }

    enum FeatureRequest {
        static let actionTitle = "Request a feature"
        static let accessibilityHint = "Opens the Unit feature request board in your browser."
        static let openError = "Couldn’t open feature requests"

        /// Public Unit feedback board. Keep this parameter-free so opening it
        /// never sends workout or analytics data from the app.
        static let portalURLString = "https://unitlift.featurebase.app"
        static let portalURL = URL(string: portalURLString)
    }

    enum Legal {
        static let termsOfService = "Terms of Service"
        static let privacyPolicy = "Privacy Policy"

        /// Unit uses Apple's standard EULA in App Store Connect. Keep this URL
        /// visible in-app and in the App Store description to satisfy the
        /// subscription metadata checklist.
        static let termsOfServiceURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        static let privacyPolicyURL = URL(string: "https://unitlift.app/privacy")
        static let support = "Contact me"
        static let supportURL = URL(string: "mailto:support@unitlift.app")
    }

    enum Session {
        static let markComplete = "Mark complete"
        static let discard = "Discard"
        static let useName = "Use name"
        static let skipNaming = "Skip"

        /// Warn-before-discard alert shown when the lifter taps Skip on the
        /// post-workout rename prompt *after* typing a draft name. Discarding
        /// loses unsaved text, so we ask once before the alert closes. If the
        /// lifter chooses "Keep editing", the rename alert re-opens with the
        /// draft preserved.
        static let discardWorkoutNameTitle = "Discard workout name?"
        static let discardWorkoutNameAction = "Discard"
        static func discardWorkoutNameMessage(_ draft: String) -> String {
            "You typed \"\(draft)\". Discarding will lose it."
        }

        /// Stale-session prompt — shown when the lifter returns the next day with
        /// an open session that has logged work. The destructive path is `discard`;
        /// the safe path is `markComplete`.
        static let staleSessionTitle = "Workout from yesterday"
        static let staleSessionMessage = "It’s still open. Save what you logged or discard it."
        /// Toast shown when a stale empty session is auto-discarded silently.
        static let staleEmptyDiscardedToast = "Discarded empty session from yesterday"
    }

    /// When there is no prior metric to show (ghost, in-session).
    enum EmptyState {
        /// No completed workouts in the app yet (Today card, lists).
        static let noHistoryYet = "No history yet"
        /// Per-exercise ghost when you've logged other work but not this lift (max 3 words).
        static let noPriorSets = "No prior sets"
        /// Active workout — no sessions completed yet (hint typography, not giant numbers).
        static let loggingColdStart = "First set"
        /// Active workout — no prior data for this exercise only (shown in hint chip + Log).
        static let loggingNoPrior = "First time"
    }

    enum History {
        /// Neutral label for routines scheduled earlier in the week that are still available to do.
        static let earlierThisWeek = "Earlier this week"

        /// Edit workout: correct or remove what was logged after Finish.
        static let editWorkout = "Edit workout"
        static let deleteWorkout = "Delete workout"
        static let deleteWorkoutMessage = "Removes this workout from History, PRs and Analytics. Can't be undone."
        /// Shown in Edit workout when a next target was saved from it: editing
        /// a logged set never changes a target the lifter saved.
        static let savedTargetsStay = "Next targets you saved stay the same."
        static let setRemoved = "Set removed"
        static let noLoggedSets = "No logged sets"
        static let setSaveFailedTitle = "Couldn't save set"
        static let setSaveFailedMessage = "Your changes are still here. Try saving again."
        static let saveFailed = "Couldn't save. Your workout is unchanged. Try again."
        static let invalidSetValues = "Enter a valid weight and reps."

        /// Paywall footer link for lapsed subscribers: History stays readable.
        static let viewHistory = "View workout history"
    }

    /// Settings > Data: export, backup and import of workout history.
    enum DataTransfer {
        static let exportTitle = "Export workouts"
        static let csvFile = "CSV file"
        static let noWorkoutsYet = "No workouts yet"
        static let exportAction = "Export"
        static let exportPreviewTitle = "Unit workouts"
        /// True for every iPhone backup (iCloud or computer) and Quick Start:
        /// the store lives in Application Support, which iOS backs up.
        static let storageBackup = "Included in iPhone backups"

        static func exportFileName(unitSystem: String) -> String {
            "Unit workouts (\(unitSystem == "lb" ? "lb" : "kg")).csv"
        }

        // MARK: Import from Strong or Hevy
        static let importTitle = "Import from Strong or Hevy"
        static let importSheetTitle = "Import history"
        static func fromSource(_ appName: String) -> String { "From \(appName)" }
        static let workoutsRow = "Workouts"
        static let setsRow = "Sets"
        static let datesRow = "Dates"
        static let alreadyInUnit = "Already in Unit"
        static let alreadyInUnitDetail = "Skipped, so nothing is added twice"
        static let skippedRows = "Skipped rows"
        static let skippedRowsDetail = "Timed, cardio and unreadable rows"
        static let weightsInFile = "Weights in this file"
        static let weightUnit = "Unit"
        static let exercisesSection = "Exercises"
        static let matchYours = "Match yours"
        static let newExercises = "New"
        static let recalculatedNote = "PRs and Analytics are recalculated with this history."
        static let nothingNew = "Nothing new to import."
        static let unknownFormat = "This file isn't a Strong or Hevy export."
        static let noWorkouts = "No workouts found in this file."
        static let readFailed = "Couldn't read this file."
        static let importFailedTitle = "Couldn't import"
        static let importFailedMessage = "Nothing was saved. Try again."

        static func importAction(_ count: Int) -> String {
            switch count {
            case 0: "Import"
            case 1: "Import 1 workout"
            default: "Import \(count.formatted()) workouts"
            }
        }

        static func imported(_ count: Int) -> String {
            count == 1 ? "Imported 1 workout" : "Imported \(count.formatted()) workouts"
        }

        static func dateRange(_ first: Date, _ last: Date) -> String {
            let start = first.formatted(.dateTime.month(.abbreviated).year())
            let end = last.formatted(.dateTime.month(.abbreviated).year())
            return start == end ? start : "\(start) to \(end)"
        }

        /// The first few new exercise names, so the lifter sees what will be added.
        static func nameList(_ names: [String]) -> String? {
            guard !names.isEmpty else { return nil }
            let shown = names.prefix(6).joined(separator: ", ")
            return names.count > 6 ? "\(shown) and \(names.count - 6) more" : shown
        }

        // MARK: Undo last import
        static let undoImportTitle = "Undo last import"
        static let undoImportConfirmTitle = "Undo import?"
        static let undoImportAction = "Undo import"
        static let importUndone = "Import undone"
        static let undoFailed = "Couldn't undo. Nothing was changed."

        static func workoutCount(_ count: Int) -> String {
            count == 1 ? "1 workout" : "\(count.formatted()) workouts"
        }

        static func undoImportMessage(_ count: Int) -> String {
            "Removes the \(workoutCount(count)) this import added. Workouts you logged in Unit stay."
        }
    }

    /// Copy for the exercise catalog — destructive flows in particular, which
    /// cascade through every template that references the deleted exercise.
    enum Exercises {
        /// Pre-delete confirmation title — names the exercise so the action is
        /// unambiguous (HIG: "Delete 'Project Alpha'?" not "Are you sure?").
        static func deleteTitle(_ exerciseName: String) -> String {
            "Delete \(exerciseName)?"
        }
        /// Destructive action button — names the noun so it survives the alert
        /// without context, matching `cancelWorkoutAction` / `skipExerciseAction`.
        static let deleteAction = "Delete exercise"
        /// Impact preview shown when one or more templates reference the
        /// exercise. Pluralizes "routine" because count varies.
        static func deleteImpactMessage(routineCount: Int) -> String {
            let plural = routineCount == 1 ? "routine" : "routines"
            return "In \(routineCount) \(plural). Removing it drops the exercise from all of them."
        }
        /// Message when the exercise isn't referenced by any template.
        static let deleteUnusedMessage = "This can’t be undone."
    }

    /// Form-validation hints surfaced under disabled primary CTAs. Each hint
    /// names the *unmet* gate, so a greyed `AppPrimaryButton` reads as a
    /// diagnostic instead of a dead button. Direct voice, no pronouns.
    enum FormHint {
        /// `vm.exercisesAreValid` — every day must have at least one named exercise.
        static let onboardingExercisesRequired = "Add an exercise to each day."
        /// `vm.splitIsValid` — every day slot needs a non-empty name.
        static let onboardingSplitNamesRequired = "Name each day."
        /// `vm.scheduleIsValid` (fixed mode) — pick a weekday for each day-template.
        static let onboardingScheduleRequired = "Pick a day for each workout."
        /// `canParse` on the program-import step — paste field is empty.
        static let onboardingImportPasteRequired = "Paste a program first."
        /// Add-day sheet — day name field is empty.
        static let dayNameRequired = "Add a routine name."
        /// Add-exercise sheet — exercise name field is empty.
        static let exerciseNameRequired = "Add an exercise name."
    }

    /// Onboarding step copy — titles, subtitles, CTAs. Minimal-language rule
    /// (2026-07-13, docs/decision-log.md): titles ≤ 4 words, neutral labels,
    /// no pronoun; every step has one concise subtitle that adds information
    /// the controls don't already show. The first-person rule bans corporate
    /// "we" — it does not require "my"/"I'll" in UI labels.
    enum Onboarding {
        static let splashTagline = "Progressive overload made simple."
        static let splashCTA = "Set up your program"
        static let unitTitle = "Choose weight unit"
        static let unitSubtitle = "You can change this later in Settings."
        static let methodTitle = "Choose your path"
        static let methodSubtitle = "Use your routine or find a ready-made match."
        static let methodPasteOption = "I have a program"
        static let methodPasteSubtitle = "Paste it from Notes, WhatsApp or anywhere else."
        static let methodLibraryOption = "I need a program"
        static let methodLibrarySubtitle = "Answer three questions to match ready-made programs."
        static let libraryGoalTitle = "What’s your training goal?"
        static let libraryGoalSubtitle = "Choose what you want to focus on."
        static let libraryLevelTitle = "How experienced are you?"
        static let libraryLevelSubtitle = "Pick the option closest to your current training."
        static let libraryDaysTitle = "How many training days?"
        static let libraryDaysSubtitle = "Only schedules supported by the ready-made catalog are shown."
        static let libraryResultsTitle = "Programs for you"
        static let libraryResultsSubtitle = "Based on your goal, experience, and schedule."
        static let libraryCTA = "Review program"
        static let libraryBestMatch = "Best match"
        static let libraryNoResults = "No ready-made program matches these answers yet."
        static func libraryShowMorePrograms(_ count: Int) -> String {
            count == 1 ? "See 1 more program" : "See \(count) more programs"
        }
        static let libraryShowFewerPrograms = "Show fewer programs"
        static let libraryGoalChip = "Goal"
        static let libraryLevelChip = "Level"
        static let libraryDaysChip = "Days/week"
        static let libraryExactMatchReason = "Matches your goal, experience, and schedule."
        static let libraryGoalMatchReason = "Matches your goal and schedule."
        static let libraryExperienceMatchReason = "Matches your experience and schedule."
        static let libraryScheduleMatchReason = "Closest ready-made fit for your schedule."
        static func trainingDays(_ count: Int) -> String {
            count == 1 ? "1 day/week" : "\(count) days/week"
        }
        static let pasteTitle = "Paste program"
        static let pasteSubtitle = "Paste or type your workouts, exercises, sets, reps, and weights."
        static let splitTitle = "Set training split"
        static let splitSubtitle = "Name each workout in your weekly split."
        static let scheduleTitle = "Set training days"
        static let scheduleSubtitle = "Choose fixed weekdays or use a flexible schedule."
        static let flexibleToggle = "Flexible schedule"
        static let flexibleSubtext = "No fixed weekdays."
        static let reviewUnitLabel = "Weight unit"
        static let previewTitle = "Review program"
        static let previewSubtitle = "Check the details before saving your program."
        static let previewCTA = "Save program"
        static let removeExercise = "Remove exercise"
        /// Review card for pasted lines the parser did not keep (benchmark
        /// 2026-10-24, setup row 2). Plain "skipped", never "didn't parse".
        static func importSkippedTitle(lines: Int, days: Int, weeks: Int = 0) -> String {
            var parts: [String] = []
            if lines > 0 { parts.append(lines == 1 ? "1 line" : "\(lines) lines") }
            if days > 0 { parts.append(days == 1 ? "1 day" : "\(days) days") }
            if weeks > 0 { parts.append(weeks == 1 ? "1 week" : "\(weeks) weeks") }
            let joined = parts.count > 1
                ? parts.dropLast().joined(separator: ", ") + " and " + (parts.last ?? "")
                : parts.joined()
            return joined + " skipped"
        }
        static let importSkippedWeeks = "Unit repeats the first week."
        static func importSkippedDays(_ names: [String]) -> String {
            "Unit keeps the first 6 days. Skipped: \(names.joined(separator: ", "))."
        }
        static func importSkippedMore(_ count: Int) -> String {
            "\(count) more"
        }
        static let previewCTASaving = "Saving…"
    }

    enum Preferences {
        static let anonymousAnalytics = "Anonymous analytics"
        static let anonymousAnalyticsCaption = "Helps me improve Unit. Never sends exercise names or weights."
        static let saveToAppleHealth = "Save to Apple Health"
        static let appleHealthDenied = "Allow Unit in the Apple Health app to save workouts."
    }

    /// Paywall copy — marketing surface only. Legal disclosure, renewal
    /// wording, Restore/Terms/Privacy, and failure states are compliance
    /// copy and live in the view untouched by minimal-language passes.
    enum Paywall {
        /// The billed amount leads, in the same line as the free period, so
        /// the trial wording cannot outrank the price (App Review 3.1.2).
        static func trialHeadline(duration: String, billedPrice: String) -> String {
            "\(billedPrice) after \(duration) free"
        }
        static func annualSavings(percent: Int) -> String {
            "Save \(percent)%"
        }
        static let standardHeadline = "Unlock Unit"
        static func supportingCopy(for goal: String?) -> String {
            switch goal {
            case "strength":
                return "Build strength with a program chosen for your goal and schedule."
            case "hypertrophy":
                return "Build muscle with a program chosen for your goal and schedule."
            case "mixed":
                return "Build strength and muscle with a program chosen for your goal and schedule."
            default:
                return "Turn your program into steady progress, one workout at a time."
            }
        }
        static let programReady = "Your program is ready"
        static let programFallbackTitle = "Your program"
        static func programDayCount(_ count: Int) -> String {
            count == 1 ? "1-day program" : "\(count)-day program"
        }
        static let choosePlan = "Choose your plan"
        /// Trial CTA. Never "$0.00": the billed amount must stay the most
        /// prominent price (App Review 3.1.2), so the context line above the
        /// button leads with it.
        static let startFreeTrial = "Start free trial"
        static func subscribeFor(_ billedPrice: String) -> String {
            "Subscribe for \(billedPrice)"
        }
        static func buyFor(_ price: String) -> String {
            "Buy for \(price)"
        }
        static func trialPurchaseContext(
            duration: String,
            billedPrice: String
        ) -> String {
            "\(billedPrice) after \(duration) free. No charge today. Auto-renews unless cancelled."
        }
        static func subscriptionPurchaseContext(_ price: String) -> String {
            "\(price). Auto-renews unless cancelled."
        }
        static func lifetimePurchaseContext(_ price: String) -> String {
            "\(price). One-time purchase."
        }
        static let pendingPurchaseContext =
            "Purchase pending approval. If it was declined, tap Restore purchases."

        static let includedFeatures = [
            "Next-workout targets",
            "One-tap set logging",
            "Last-time values",
            "Ready-made programs",
            "Progress history",
            "Lock Screen rest timer"
        ]

        // The selected offer, timing, reminder preference, and purchase action
        // stay on one surface so every promise is visible at the decision.
        static let timelineTitle = "What happens next"
        static let timelineTodayTitle = "Today"
        static let timelineTodayMessage = "Full Unit access starts immediately."
        static let timelineBeforeRenewalTitle = "Before renewal"
        static let timelineBeforeRenewalMessage = "Cancel anytime in App Store settings."
        static func timelineRenewalTitle(_ period: String?) -> String {
            period.map { "Every \($0)" } ?? "Renewal"
        }
        /// The real first-charge date sits in the sentence, as in the
        /// Blinkist and Mesh trial timelines (2026-10-24).
        static func timelineRenewalMessage(_ billedPrice: String, date: Date?) -> String {
            guard let date else { return "Renews at \(billedPrice) unless cancelled." }
            return "Next charge \(timelineDate(date)): \(billedPrice), unless cancelled."
        }
        static let lifetimeTimelineTitle = "Lifetime access"
        static let lifetimeTodayMessage = "Full Unit access starts immediately."
        static let lifetimePaymentTitle = "One payment"
        static func lifetimePaymentMessage(_ price: String) -> String {
            "\(price) once. No subscription renewal."
        }

        static let trialTimelineTitle = "How your free trial works"
        static let trialTimelineDayZeroMessage = "Full Unit access starts immediately."
        static func trialTimelineReminderTitle(dayCount: Int?) -> String {
            guard let dayCount else { return "Two days before" }
            return "Day \(max(0, dayCount - 2))"
        }
        static func trialTimelineReminderMessage(isOn: Bool, date: Date?) -> String {
            guard let date else {
                return isOn
                    ? "Unit reminds you two days before your trial ends."
                    : "Turn on a reminder for two days before your trial ends."
            }
            return isOn
                ? "Unit reminds you on \(timelineDate(date))."
                : "Turn on a reminder for \(timelineDate(date))."
        }
        /// "How do I cancel?" under the timeline (2026-10-24, Blinkist
        /// pattern). Unit's own path first, then the iPhone path.
        static let cancelHelpTitle = "How do I cancel?"
        static let cancelHelpInApp = "In Unit: Programs, then Settings, then Manage Subscription."
        static let cancelHelpOnPhone = "On your iPhone: Settings, then your name, then Subscriptions."
        static func cancelHelpDeadline(trialEnd: Date?) -> String {
            guard let trialEnd else {
                return "Cancel at least 24 hours before your next charge to stop it."
            }
            return "Cancel at least 24 hours before \(timelineDate(trialEnd)) and you pay nothing."
        }
        static let trialReminderLabel = "Remind me 2 days before"
        static let trialReminderCaption =
            "Optional. Notification permission is requested after purchase."
        static func trialTimelineEndTitle(dayCount: Int?) -> String {
            dayCount.map { "Day \($0)" } ?? "After the trial"
        }
        /// Real calendar dates in the timeline text ("Oct 31"), in the
        /// phone's format, so the charge day is never a sum to work out. The
        /// year shows only when it differs from this year.
        static func timelineDate(
            _ date: Date,
            now: Date = .now,
            calendar: Calendar = .current,
            locale: Locale = .autoupdatingCurrent
        ) -> String {
            let style = Date.FormatStyle.dateTime.month(.abbreviated).day().locale(locale)
            return calendar.isDate(date, equalTo: now, toGranularity: .year)
                ? date.formatted(style)
                : date.formatted(style.year())
        }
        static func trialTimelineEndMessage(_ billedPrice: String, date: Date?) -> String {
            guard let date else { return "Renews at \(billedPrice) unless cancelled." }
            return "You will be charged \(billedPrice) on \(timelineDate(date)). Cancel anytime before."
        }
        static func trialTimelineRewardTitle(for goal: String?) -> String {
            switch goal {
            case "strength": return "Keep getting stronger"
            case "hypertrophy": return "Keep building muscle"
            case "mixed": return "Keep building strength and muscle"
            default: return "Keep making progress"
            }
        }
        static let trialTimelineRewardMessage =
            "Your program, history, and next targets stay ready."
        // Social proof: a real, published five-star App Store review
        // (Türkiye storefront, v1.0, 2026-06-09: "Yıllardır aradığım gym
        // tracker app"). The user-facing quote is its English translation,
        // labeled as translated. A rating number stays off the paywall
        // until about 50 ratings exist; never an invented quote.
        static let reviewStars = "★★★★★"
        static let reviewStarsAccessibility = "5 out of 5 stars"
        static let reviewQuote = "\u{201C}The gym tracker app I\u{2019}ve been looking for for years.\u{201D}"
        static let reviewAttribution = "App Store review · translated from Turkish"
    }

    /// Today dashboard state copy. One status line per state — the title
    /// carries it; no eyebrow/title/message stacking that repeats itself.
    enum Today {
        static let noProgramTitle = "No program"
        static let noProgramCTA = "Add program"
        static let restDayTitle = "Rest day"
        static let restDayCTA = "Choose routine"
    }

    enum Engagement {
        static let feedbackTitle = "Help improve Unit"
        static let feedbackBody = "Unit is built by one person. Have 15 minutes to tell me what worked or got in your way?"
        static let bookCall = "Book a 15-minute call"
        static let emailFeedback = "Email feedback"
        static let noThanks = "No thanks"
        static let linkError = "Couldn’t open that link"
    }

    /// Shared transient-toast copy. The pill is narrow and time-bound, so the
    /// action label stays terse. Body strings name the affected noun so the
    /// undo target is never ambiguous.
    enum Toast {
        /// Trailing action label for an `AppToast` that supports a single
        /// reversal step (currently used for exercise removal).
        static let undo = "Undo"
        /// Body for a non-destructive exercise removal.
        static func removedExercise(_ name: String) -> String {
            let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.isEmpty ? "Removed exercise" : "Removed \(trimmed)"
        }
    }

    enum Search {
        /// Canonical placeholder for any exercise picker — catalog, in-workout, in-template.
        /// One word: the search affordance is the only input on the row, so a single
        /// "Search" reads cleaner than restating the noun.
        static let exercises = "Search"

        /// Empty-row hint inside an exercise picker when the underlying library
        /// has zero items (cold start, all already added). Caption-weight text,
        /// rendered inline as a list row — never a full empty-state card.
        static let noExercisesYet = "No exercises yet"
        /// Empty-row hint when an active query yields zero matches. Pair with the
        /// "Create X" affordance below it when a custom name is allowed.
        static let noMatchingExercises = "No matching exercises"
        /// Empty-state hint when filters are active and yield nothing.
        static let noExercisesMatchFilters = "No exercises match these filters"
    }
}
