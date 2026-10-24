//
//  SessionDetailView.swift
//  Unit
//
//  Session detail grouped by exercise. The pencil opens Edit workout.
//

import SwiftUI
import SwiftData

/// First index wins when a routine lists the same exercise twice.
func exerciseOrderIndex(for ids: [UUID]) -> [UUID: Int] {
    Dictionary.firstUniqueKeys(ids.enumerated().map { ($0.element, $0.offset) })
}

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    let templateName: String
    var completionMoment: AppCelebrationMoment? = nil
    /// Lapsed-subscriber History: no edits, no saved targets, no writes.
    var isReadOnly = false

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    /// Full session history — the PR baseline must replay every completed
    /// session, not just the one on display.
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @AppStorage("unitSystem") private var unitSystem = "kg"
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var showsFeedbackInvitation = false
    @State private var acceptedMoment: AppCelebrationMoment?
    @State private var acceptedExerciseID: UUID?
    @State private var pendingAcceptedExerciseID: UUID?
    @State private var toastMessage: AppToastEvent?
    @State private var editingRecommendationID: UUID?
    @State private var editingWeightText = ""
    @State private var editingRepsText = ""
    @FocusState private var editingTargetField: String?
    @State private var didTrackRecommendations = false
    @State private var showsEditWorkout = false
    /// Set just before the workout is deleted, so the screen never reads it again.
    @State private var isDeleted = false

    private struct ProgressionRecommendationRow: Identifiable {
        let exerciseID: UUID
        let exerciseName: String
        let isBodyweight: Bool
        let record: SessionProgressionRecord
        /// Computed once per render: the check scans every workout.
        let isActionable: Bool

        var id: UUID { exerciseID }

        var displayTarget: DoubleProgressionTarget? {
            record.acceptedTarget ?? record.suggestedTarget
        }

        /// Where Edit starts. Without a suggestion (weights varied, sets
        /// unfinished) the lifter sets the next target from the previous one.
        var editTarget: DoubleProgressionTarget? {
            guard isActionable else { return nil }
            if let displayTarget { return displayTarget }
            switch record.unavailableReason {
            case .mixedWorkingSetWeights, .incompleteWorkingSets, .invalidWorkingSetData:
                return record.previousTarget
            default:
                return nil
            }
        }
    }

    private var exerciseSnapshots: [SessionExerciseSnapshot] {
        makeSessionDetailExerciseSnapshots(
            for: session,
            exercises: exercises,
            templates: templates,
            prSetEntryIDs: PRHistory.prSetEntryIDs(in: allSessions)
        )
    }

    private var progressionTemplate: DayTemplate? {
        templates.first(where: { $0.id == session.templateId })
    }

    private var progressionRecommendations: [ProgressionRecommendationRow] {
        guard session.isCompleted else { return [] }
        let records = session.progressionRecordsByExerciseId
        let templateOrder = progressionTemplate?.orderedExerciseIds ?? []
        let orderByID = exerciseOrderIndex(for: templateOrder)
        return records.values.map { record in
            return ProgressionRecommendationRow(
                exerciseID: record.exerciseID,
                exerciseName: record.exerciseName,
                isBodyweight: record.isBodyweight,
                record: record,
                isActionable: isActionable(record)
            )
        }
        .sorted { lhs, rhs in
            let left = orderByID[lhs.exerciseID] ?? Int.max
            let right = orderByID[rhs.exerciseID] ?? Int.max
            return left == right
                ? lhs.exerciseName < rhs.exerciseName
                : left < right
        }
    }

    var body: some View {
        AppScreen(
            showsNativeNavigationBar: true
        ) {
            // Once the workout is deleted, nothing here may read it while the
            // screen leaves. The modifiers below stay, so the pop completes.
            if !isDeleted {
                detailStack
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isReadOnly {
                // Same entry as Programs > Edit program.
                ToolbarItem(placement: .topBarTrailing) {
                    Group {
                        Button { showsEditWorkout = true } label: {
                            Label(AppCopy.History.editWorkout, systemImage: AppIcon.edit.systemName)
                                .labelStyle(.iconOnly)
                        }
                        .accessibilityLabel(AppCopy.History.editWorkout)
                        .accessibilityIdentifier("edit-workout")
                    }
                    .tint(AppColor.textPrimary)
                }
            }
        }
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
        .navigationDestination(isPresented: $showsEditWorkout) {
            EditWorkoutView(session: session, onDeleteWorkout: deleteWorkout)
        }
        .onChange(of: showsEditWorkout) { _, isPresented in
            // Second step of a delete: Edit workout has closed, now leave too.
            if !isPresented, isDeleted { dismiss() }
        }
        .overlay { AppCelebration(moment: completionMoment) }
        .appToast(event: editingRecommendationID == nil ? $toastMessage : .constant(nil))
        .sheet(
            isPresented: Binding(
                get: { editingRecommendationID != nil },
                set: { if !$0 { editingRecommendationID = nil } }
            ),
            onDismiss: playAcceptedMomentIfNeeded
        ) {
            recommendationEditSheet
        }
        .onAppear {
            backfillAcceptedProgressionRecordsIfNeeded()
            presentFeedbackInvitationIfNeeded()
            trackRecommendationsIfNeeded()
        }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(templateName)
                    .appFont(.productHeading)
                    .foregroundStyle(AppColor.textPrimary)
                    .lineLimit(2)
                    .truncationMode(.tail)

                Text(session.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Right after Finish, decisions come first: the next targets
            // are the payoff of the workout and were below the whole log.
            if completionMoment != nil, !progressionRecommendations.isEmpty {
                progressionSections
            }

            if !exerciseSnapshots.isEmpty {
                AppCardList(exerciseSnapshots) { exercise in
                    NavigationLink {
                        ExerciseProgressView(
                            exerciseId: exercise.id,
                            exerciseName: exercise.name,
                            isBodyweight: exercise.isBodyweight,
                            sessions: allSessions,
                            templates: templates
                        )
                    } label: {
                        SessionExerciseSummary(exercise: exercise)
                            .appNavigationDisclosure()
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityHint("Opens progress history for \(exercise.name).")
                }
            }

            if completionMoment == nil, !progressionRecommendations.isEmpty {
                progressionSections
            }

            if showsFeedbackInvitation {
                feedbackInvitationCard
            }
        }
        .appScreenEnter()
    }

    /// Saved targets in one card, exercises without one in another
    /// (2026-10-24). Each row is compact; tapping it opens the details.
    @ViewBuilder
    private var progressionSections: some View {
        let rows = progressionRecommendations
        let withTarget = rows.filter { $0.displayTarget != nil }
        let withoutTarget = rows.filter { $0.displayTarget == nil }
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            if !withTarget.isEmpty {
                progressionSection(AppCopy.Workout.nextTimeTitle, rows: withTarget)
            }
            if !withoutTarget.isEmpty {
                progressionSection(AppCopy.Workout.noAutomaticTarget, rows: withoutTarget)
            }
        }
    }

    private func progressionSection(_ title: String, rows: [ProgressionRecommendationRow]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader(title)
            AppCardList(rows) { recommendation in
                progressionRow(recommendation)
            }
        }
    }

    @ViewBuilder
    private func progressionRow(_ recommendation: ProgressionRecommendationRow) -> some View {
        let content = progressionRowContent(recommendation)
            .appAnimation(.appState, value: recommendation.record.acceptedTarget, reduceMotion: reduceMotion)
            .overlay {
                AppCelebration(moment: acceptedExerciseID == recommendation.exerciseID ? acceptedMoment : nil)
            }
        if recommendation.editTarget != nil {
            Button { beginEditing(recommendation) } label: {
                content
                    .appNavigationDisclosure()
                    .contentShape(Rectangle())
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityHint(AppCopy.Workout.opensNextTarget)
            .accessibilityIdentifier("next-target-\(recommendation.exerciseName)")
        } else {
            content
        }
    }

    /// The next target is the one strong element; name and change stay quiet.
    private func progressionRowContent(_ recommendation: ProgressionRecommendationRow) -> some View {
        let targetText = recommendation.displayTarget.flatMap {
            completeTargetText($0, setCount: recommendation.record.configuredSetCount)
        }
        return VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text(recommendation.exerciseName)
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            if let targetText {
                HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                    Text(targetText)
                        .appNumericValue(value: targetText)
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .monospacedDigit()
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: AppSpacing.sm)
                    Text(changeTag(recommendation.record))
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .contentTransition(.opacity)
                }
            } else {
                Text(explanationText(recommendation.record, offersEdit: recommendation.editTarget != nil))
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, AppSpacing.sm)
        .accessibilityElement(children: .combine)
    }

    /// What changed, or the lifter's own decision.
    private func changeTag(_ record: SessionProgressionRecord) -> String {
        switch record.decisionAction {
        case .repeatedPreviousTarget: return AppCopy.Workout.repeatingForNextTime
        case .edited: return AppCopy.Workout.editedForNextTime
        case .usedSuggestion, nil: break
        }
        guard record.acceptedTarget != nil else { return AppCopy.Workout.notSavedForNextTime }
        switch record.recommendationReason {
        case .allSetsReachedTop:
            return WorkoutTargetFormatter.loggingIncrementText(weightKg: record.weightIncrementKg,
                                                              unitSystem: unitSystem)
        case .addARep: return AppCopy.Workout.suggestionAddOneRep
        case .repeatTarget, nil: return AppCopy.Workout.suggestionSameTarget
        }
    }

    private func evidenceLine(label: String, value: String) -> some View {
        AppListRow(title: label, style: .cardListContent) {
            Text(value)
                .appNumericValue(value: value)
                .font(AppFont.performance.font)
                .foregroundStyle(AppColor.textSecondary)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// One place to change a next target: the evidence, the editable
    /// target and one shortcut to the other option (2026-10-24).
    private var recommendationEditSheet: some View {
        AppSheetScreen(
            title: editingRecommendation?.exerciseName ?? AppCopy.Workout.editNextTarget,
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.Workout.saveChanges,
                isEnabled: parsedEditingWeightKg != nil && parsedEditingReps != nil,
                action: saveEditedRecommendation
            ),
            dismissLabel: AppCopy.Nav.cancel,
            onDismissAction: { editingRecommendationID = nil },
            showsKeyboardDismissToolbar: true
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.lg) {
                if let recommendation = editingRecommendation {
                    let record = recommendation.record
                    VStack(alignment: .leading, spacing: AppSpacing.smd) {
                        if let previous = record.previousTarget,
                           let text = completeTargetText(previous, setCount: record.configuredSetCount) {
                            evidenceLine(label: AppCopy.Workout.previousTargetLabel, value: text)
                        }
                        if let actualText = actualPerformanceText(record) {
                            evidenceLine(label: AppCopy.Workout.loggedLabel, value: actualText)
                        }
                        if let suggested = record.suggestedTarget, suggested != record.acceptedTarget,
                           let text = completeTargetText(suggested, setCount: record.configuredSetCount) {
                            evidenceLine(label: AppCopy.Workout.suggestedForNextTime, value: text)
                        }
                        Text(explanationText(record, offersEdit: true))
                            .font(AppFont.caption.font)
                            .foregroundStyle(AppColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(alignment: .bottom, spacing: AppSpacing.lg) {
                        recommendationWeightEditor(for: recommendation)
                        recommendationRepsEditor(for: recommendation)
                    }

                    if let shortcut = editShortcut(for: recommendation) {
                        AppGhostButton(shortcut.label) {
                            persistTarget(shortcut.target, for: recommendation,
                                          action: shortcut.action, reason: shortcut.reason)
                            editingRecommendationID = nil
                        }
                        .accessibilityIdentifier("next-target-shortcut")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
        .appToast(event: $toastMessage)
    }

    /// "Use previous" while the suggestion is saved; "Use suggested" after
    /// the lifter kept the previous target or edited it.
    private func editShortcut(for recommendation: ProgressionRecommendationRow)
        -> (label: String, target: DoubleProgressionTarget, action: ProgressionDecisionAction, reason: DoubleProgressionReason)? {
        let record = recommendation.record
        let current = record.acceptedTarget ?? record.suggestedTarget
        if let suggested = record.suggestedTarget, let reason = record.recommendationReason,
           current != suggested,
           let text = completeTargetText(suggested, setCount: record.configuredSetCount) {
            return (AppCopy.Workout.useSuggested(text), suggested, .usedSuggestion, reason)
        }
        if let previous = record.previousTarget, current != nil, current != previous,
           let text = completeTargetText(previous, setCount: record.configuredSetCount) {
            return (AppCopy.Workout.usePrevious(text), previous, .repeatedPreviousTarget, .repeatTarget)
        }
        return nil
    }

    private func recommendationWeightEditor(
        for recommendation: ProgressionRecommendationRow
    ) -> some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            Text(AppCopy.Workout.weightLabel(
                isBodyweight: recommendation.isBodyweight,
                unitSystem: unitSystem
            ))
            .font(AppFont.sectionHeader.font)
            .foregroundStyle(AppColor.textPrimary)

            TextField("", text: $editingWeightText)
                .focused($editingTargetField, equals: "weight")
                .keyboardType(.decimalPad)
                .font(AppFont.numericInput.font)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .appInputFieldStyle()
                .accessibilityLabel(AppCopy.Workout.nextTargetLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private func recommendationRepsEditor(
        for recommendation: ProgressionRecommendationRow
    ) -> some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            Text(AppCopy.Workout.targetRepsLabel)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)

            TextField("", text: $editingRepsText)
                .focused($editingTargetField, equals: "reps")
                .keyboardType(.numberPad)
                .font(AppFont.numericInput.font)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .appInputFieldStyle()
                .accessibilityLabel(AppCopy.Workout.repsLabel)
        }
        .frame(maxWidth: .infinity)
    }

    private var editingRecommendation: ProgressionRecommendationRow? {
        guard let editingRecommendationID else { return nil }
        return progressionRecommendations.first { $0.id == editingRecommendationID }
    }

    private func beginEditing(_ recommendation: ProgressionRecommendationRow) {
        toastMessage = nil
        guard let target = recommendation.editTarget else { return }
        editingWeightText = displayedWeight(target.weightKg)
        editingRepsText = String(target.reps)
        editingRecommendationID = recommendation.id
    }

    private func saveEditedRecommendation() {
        guard let recommendation = editingRecommendation,
              let weightKg = parsedEditingWeightKg,
              let reps = parsedEditingReps else { return }
        let typed = DoubleProgressionTarget(
            weightKg: weightKg,
            reps: reps
        )
        let record = recommendation.record
        let action = record.decisionAction(saving: typed)
        // A retyped suggestion or previous target saves the exact stored value.
        let target = switch action {
        case .usedSuggestion: record.suggestedTarget ?? typed
        case .repeatedPreviousTarget: record.previousTarget ?? typed
        case .edited: typed
        }
        let saved = persistTarget(
            target,
            for: recommendation,
            action: action,
            reason: action == .repeatedPreviousTarget ? .repeatTarget : (record.recommendationReason ?? .repeatTarget)
        )
        if saved { editingRecommendationID = nil }
    }

    @discardableResult
    private func persistTarget(
        _ target: DoubleProgressionTarget,
        for recommendation: ProgressionRecommendationRow,
        action: ProgressionDecisionAction,
        reason: DoubleProgressionReason
    ) -> Bool {
        guard isActionable(recommendation.record),
              let template = progressionTemplate,
              target.weightKg.isFinite,
              target.weightKg > 0,
              target.reps >= recommendation.record.lowerRepBound,
              target.reps <= recommendation.record.upperRepBound else {
            return false
        }
        let previousTarget = template.progressionState(for: recommendation.exerciseID)?.acceptedTarget
        guard session.saveProgressionDecision(
            target,
            action: action,
            reason: reason,
            for: recommendation.exerciseID,
            template: template
        ) else {
            modelContext.rollbackRestoringLoadedModels()
            return false
        }

        do {
            try modelContext.save()
            UnitAnalytics.shared.track(
                .progressionDecision(
                    action: analyticsDecision(for: action),
                    outcome: analyticsOutcome(for: reason)
                )
            )
            if previousTarget != target {
                // Going back to the previous target is not a celebration.
                if action != .repeatedPreviousTarget {
                    pendingAcceptedExerciseID = recommendation.exerciseID
                    if editingRecommendationID == nil { playAcceptedMomentIfNeeded() }
                }
                AppHaptic.success.fire()
            }
            toastMessage = .init(AppCopy.Workout.targetsSaved, kind: .success)
            return true
        } catch {
            modelContext.rollbackRestoringLoadedModels()
            toastMessage = .init(AppCopy.Workout.targetsSaveFailed, kind: .error)
            AppHaptic.error.fire()
            return false
        }
    }

    private func playAcceptedMomentIfNeeded() {
        guard let exerciseID = pendingAcceptedExerciseID else { return }
        acceptedExerciseID = exerciseID
        acceptedMoment = AppCelebrationMoment(style: .burst)
        pendingAcceptedExerciseID = nil
    }

    private func isActionable(_ record: SessionProgressionRecord) -> Bool {
        guard !isReadOnly,
              let template = progressionTemplate,
              let currentState = template.progressionState(
                  for: record.exerciseID
              ),
        !hasNewerCompletedSession(for: record.exerciseID) else {
            return false
        }
        guard record.acceptedTarget == nil else {
            return currentState.sourceWorkoutSessionID == session.id
        }

        guard template.plannedSets(for: record.exerciseID)
                == record.configuredSetCount,
              currentState.lowerRepBound == record.lowerRepBound,
              currentState.upperRepBound == record.upperRepBound,
              abs(
                  currentState.weightIncrementKg
                      - record.weightIncrementKg
              ) <= 0.000_1,
              currentState.currentAcceptedTargetReps
                == record.previousTarget?.reps else {
            return false
        }
        if let currentWeight = currentState.currentAcceptedTargetWeightKg,
           let previousWeight = record.previousTarget?.weightKg {
            return abs(currentWeight - previousWeight) <= 0.000_1
        }
        return true
    }

    private func hasNewerCompletedSession(for exerciseID: UUID) -> Bool {
        session.hasNewerCompletedWorkout(for: exerciseID, in: allSessions)
    }

    /// Edit workout calls this after its confirm. The screen stops reading
    /// the workout first, then deletes it, closes Edit workout and leaves
    /// once that pop is done (`onChange` above). A dismiss from here would
    /// not pop while Edit workout is on top. False when the save failed and
    /// nothing was deleted.
    private func deleteWorkout() -> Bool {
        isDeleted = true
        let context = PastWorkoutEditor.Context(
            modelContext: modelContext,
            sessions: allSessions,
            templates: templates,
            exercises: exercises
        )
        guard PastWorkoutEditor.deleteWorkout(session, context) else {
            isDeleted = false
            return false
        }
        showsEditWorkout = false
        return true
    }

    private func completeTargetText(
        _ target: DoubleProgressionTarget,
        setCount: Int
    ) -> String? {
        WorkoutTargetFormatter.completeTargetText(
            weightKg: target.weightKg,
            setCount: setCount,
            reps: target.reps
        )
    }

    private func actualPerformanceText(_ record: SessionProgressionRecord) -> String? {
        WorkoutTargetFormatter.completedPerformanceText(
            weightsKg: record.completedSets.map(\.weightKg),
            reps: record.completedSets.map(\.reps),
            isBodyweight: record.isBodyweight
        )
    }

    /// With Edit on the block, the reason stands alone; "Set a target next
    /// workout." stays only where this summary can no longer set one.
    private func explanationText(_ record: SessionProgressionRecord, offersEdit: Bool) -> String {
        let manual = offersEdit ? "" : " \(AppCopy.Workout.chooseTargetManually)"
        if let reason = record.unavailableReason {
            switch reason {
            case .mixedWorkingSetWeights:
                return AppCopy.Workout.mixedWeightsUnavailable + manual
            case .incompleteWorkingSets:
                return AppCopy.Workout.incompleteSetsUnavailable + manual
            case .invalidWeightIncrement:
                return AppCopy.Workout.invalidIncrementUnavailable
            case .unsupportedBodyweightOnly:
                return AppCopy.Workout.bodyweightUnavailable
            case .invalidConfiguration, .invalidTarget, .invalidWorkingSetData, .targetWeightOverflow:
                return AppCopy.Workout.invalidDataUnavailable + manual
            }
        }

        switch record.recommendationReason {
        case .allSetsReachedTop:
            return AppCopy.Workout.allSetsReachedTopReason
        case .addARep:
            return AppCopy.Workout.addARepReason
        case .repeatTarget:
            return AppCopy.Workout.stallReason(
                shortSets: record.shortSets,
                targetReps: record.previousTarget?.reps ?? 0
            )
        case nil:
            return AppCopy.Workout.invalidDataUnavailable
        }
    }

    private func backfillAcceptedProgressionRecordsIfNeeded() {
        guard !isReadOnly, let template = progressionTemplate else { return }
        let didChange = session.captureProgressionRecords(
            template: template,
            exercises: exercises,
            evaluatePendingRecommendations: false
        )
        if didChange {
            try? modelContext.save()
        }
    }

    private var parsedEditingReps: Int? {
        guard let recommendation = editingRecommendation,
              let reps = Int(editingRepsText),
              (recommendation.record.lowerRepBound...recommendation.record.upperRepBound).contains(reps)
        else { return nil }
        return reps
    }

    private var parsedEditingWeightKg: Double? {
        guard let displayWeight = Double(
            editingWeightText.replacingOccurrences(of: ",", with: ".")
        ),
        displayWeight.isFinite,
        displayWeight > 0 else {
            return nil
        }
        return unitSystem == "lb" ? displayWeight / 2.20462 : displayWeight
    }

    private func displayedWeight(_ weightKg: Double) -> String {
        let displayWeight = unitSystem == "lb" ? weightKg * 2.20462 : weightKg
        return displayWeight.weightString
    }

    private var feedbackInvitationCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(AppCopy.Engagement.feedbackTitle)
                        .font(AppFont.title.font)
                        .foregroundStyle(AppColor.textPrimary)

                    Text(AppCopy.Engagement.feedbackBody)
                        .font(AppFont.body.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                feedbackBookingButton

                AppGhostButton(AppCopy.Engagement.emailFeedback) {
                    guard let url = EngagementPromptTracker.feedbackEmailURL() else {
                        toastMessage = .init(AppCopy.Engagement.linkError, kind: .error)
                        return
                    }
                    UnitAnalytics.shared.track(.feedbackAction(action: .email))
                    open(url)
                }

                AppGhostButton(AppCopy.Engagement.noThanks, layout: .inline) {
                    UnitAnalytics.shared.track(.feedbackAction(action: .dismiss))
                    withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: UIAccessibility.isReduceMotionEnabled, voiceOver: UIAccessibility.isVoiceOverRunning) ? .appState : nil) {
                        showsFeedbackInvitation = false
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("feedback-invitation")
    }

    @ViewBuilder
    private var feedbackBookingButton: some View {
        if progressionRecommendations.isEmpty {
            AppPrimaryButton(AppCopy.Engagement.bookCall) {
                UnitAnalytics.shared.track(.feedbackAction(action: .book))
                open(EngagementPromptTracker.bookingURL)
            }
        } else {
            AppGhostButton(AppCopy.Engagement.bookCall) {
                UnitAnalytics.shared.track(.feedbackAction(action: .book))
                open(EngagementPromptTracker.bookingURL)
            }
        }
    }

    private func presentFeedbackInvitationIfNeeded() {
        guard !isReadOnly else { return }
        let tracker = EngagementPromptTracker()
        guard tracker.shouldShowFeedback(for: session.id) else { return }
        tracker.markFeedbackPromptShown()
        showsFeedbackInvitation = true
    }

    private func open(_ url: URL) {
        openURL(url) { accepted in
            if !accepted {
                toastMessage = .init(AppCopy.Engagement.linkError, kind: .error)
            }
        }
    }

    private func trackRecommendationsIfNeeded() {
        guard !isReadOnly, !didTrackRecommendations else { return }
        didTrackRecommendations = true
        let outcomes = Set(progressionRecommendations.map {
            analyticsOutcome(for: $0.record.recommendationReason)
        })
        for outcome in outcomes {
            UnitAnalytics.shared.track(.progressionRecommendationShown(outcome: outcome))
        }
    }

    private func analyticsOutcome(for reason: DoubleProgressionReason?) -> AnalyticsProgressionOutcome {
        switch reason {
        case .allSetsReachedTop: .addWeight
        case .addARep: .addRep
        case .repeatTarget: .repeatTarget
        case nil: .unsupported
        }
    }

    private func analyticsDecision(for action: ProgressionDecisionAction) -> AnalyticsProgressionDecision {
        switch action {
        case .usedSuggestion: .accept
        case .repeatedPreviousTarget: .repeatTarget
        case .edited: .edit
        }
    }
}

#Preview {
    NavigationStack {
        let container = PreviewSampleData.makePreviewContainer()
        let session = (try? container.mainContext.fetch(FetchDescriptor<WorkoutSession>()))?.first

        Group {
            if let session {
                SessionDetailView(session: session, templateName: "Push")
                    .modelContainer(container)
            }
        }
    }
}
