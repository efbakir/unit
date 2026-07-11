//
//  AppCopy.swift
//  Unit
//
//  Central workout + navigation strings. Prefer these over ad-hoc literals in views.
//

import Foundation

enum AppCopy {
    enum Workout {
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
        static let logMetricHint = "Log first set"
        /// Adjust-result sheet — label above the optional note field (same row as weight/reps captions).
        static let adjustSetNoteLabel = "Note"
        /// Grey placeholder hinting how the note is used (supersets, equipment, etc.).
        static let adjustSetNotePlaceholder = "Superset curl"
        /// Sentence-case "Add exercise" — sheet title, primary CTA, and ghost button.
        static let addExercise = "Add exercise"
        /// Bodyweight abbreviation — shown in catalog rows, set tiles, ghost subtitles.
        static let bodyweightAbbrev = "BW"
        /// First-set reminder shown above the command card before any working set lands.
        /// Disappears once the lifter logs a set for the current exercise.
        static let warmupReminder = "Don't forget to warm up."
        /// Tap-affordance second line paired with `warmupReminder`. Opens the guidance sheet.
        /// Rendered in the same secondary tone as the reminder (no underline, no accent) so
        /// the whole block reads as one quiet two-line caption, not a hyperlink.
        static let warmupReminderLink = "Tap to learn how."
        /// Title of the warm-up guidance bottom sheet.
        static let warmupGuideTitle = "Warm-up sets"
        /// Body paragraphs of the warm-up guidance sheet — deliberately short so the
        /// lifter can scan it once and dismiss. Order matters: rep-range rule first,
        /// then load advice, then tempo cue.
        static let warmupGuideRepRule = "If your working set is 8–10 reps, do 3–4 reps per warm-up. For lower reps, do half of your working reps."
        static let warmupGuideLoadRule = "Stay light. Don't chase a pump. The warm-up is a primer, not part of the work."
        static let warmupGuideTempoRule = "Push explosive on the way up. Slow on the way down."
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
        static let targetSetsLabel = "Sets"
        static let targetRepsLabel = "Reps"

        /// Field caption above the weight input in `AdjustResultSheet`. The unit
        /// is read from `@AppStorage("unitSystem")` so a lifter in lb sees
        /// "Weight (lb)" — previously a hardcoded "Weight (kg)" leaked the
        /// developer-default unit into the most-used set-logging surface.
        /// Bodyweight exercises drop the unit suffix: the value is optional
        /// added load, so "Weight" alone reads cleaner than "Weight (kg)" on
        /// an empty field that may stay empty.
        static func weightLabel(isBodyweight: Bool, unitSystem: String) -> String {
            if isBodyweight { return "Weight" }
            return "Weight (\(unitSystem))"
        }

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
        static let setEditHint = "Tap any set to edit it."
    }

    enum Nav {
        static let close = "Close"
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

    enum Legal {
        static let termsOfService = "Terms of Service"
        static let privacyPolicy = "Privacy Policy"

        /// Unit uses Apple's standard EULA in App Store Connect. Keep this URL
        /// visible in-app and in the App Store description to satisfy the
        /// subscription metadata checklist.
        static let termsOfServiceURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")
        static let privacyPolicyURL = URL(string: "https://unitlift.app/privacy")
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
        static let staleSessionMessage = "It's still open. Save what you logged or discard it."
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
        static let deleteUnusedMessage = "This can't be undone."
    }

    /// Form-validation hints surfaced under disabled primary CTAs. Each hint
    /// names the *unmet* gate, so a greyed `AppPrimaryButton` reads as a
    /// diagnostic instead of a dead button. Direct voice, no pronouns.
    enum FormHint {
        /// `vm.exercisesAreValid` — every day must have at least one named exercise.
        static let onboardingExercisesRequired = "Add at least one named exercise to every day."
        /// `vm.splitIsValid` — every day slot needs a non-empty name.
        static let onboardingSplitNamesRequired = "Name every day to continue."
        /// `vm.scheduleIsValid` (fixed mode) — pick a weekday for each day-template.
        static let onboardingScheduleRequired = "Pick a weekday for every workout."
        /// `canParse` on the program-import step — paste field is empty.
        static let onboardingImportPasteRequired = "Paste your program above to continue."
        /// Add-day sheet — day name field is empty.
        static let dayNameRequired = "Name the day to create it."
        /// Add-exercise sheet — exercise name field is empty.
        static let exerciseNameRequired = "Name the exercise to save it."
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
