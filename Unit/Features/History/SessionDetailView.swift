//
//  SessionDetailView.swift
//  Unit
//
//  Read-only session detail grouped by exercise.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    @Bindable var session: WorkoutSession
    let templateName: String
    var completionMoment: AppCelebrationMoment? = nil

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

    private struct ProgressionRecommendationRow: Identifiable {
        let exerciseID: UUID
        let exerciseName: String
        let isBodyweight: Bool
        let record: SessionProgressionRecord

        var id: UUID { exerciseID }

        var displayTarget: DoubleProgressionTarget? {
            record.acceptedTarget ?? record.suggestedTarget
        }
    }

    private var exerciseSnapshots: [SessionExerciseSnapshot] {
        let prIDs = PRHistory.prSetEntryIDs(in: allSessions)
        let templateOrder = templates.first(where: { $0.id == session.templateId })?.orderedExerciseIds ?? []
        let orderByID = Dictionary(uniqueKeysWithValues: templateOrder.enumerated().map { ($0.element, $0.offset) })
        let grouped = Dictionary(grouping: session.setEntries.filter(\.isCompleted), by: \.exerciseId)
        return grouped.compactMap { exerciseID, entries -> SessionExerciseSnapshot? in
            guard let exercise = exercises.first(where: { $0.id == exerciseID }) else { return nil }
            let sortedEntries = entries.sorted { $0.setIndex < $1.setIndex }
            let sets = sortedEntries.map { entry in
                SessionSetSnapshot(
                    id: entry.id,
                    setIndex: entry.setIndex,
                    actualWeight: entry.weight,
                    actualReps: entry.reps,
                    note: entry.note.trimmingCharacters(in: .whitespacesAndNewlines),
                    isPR: prIDs.contains(entry.id)
                )
            }
            return SessionExerciseSnapshot(
                id: exerciseID,
                name: exercise.displayName,
                isBodyweight: exercise.isBodyweight,
                sets: sets
            )
        }
        .sorted { lhs, rhs in
            let left = orderByID[lhs.id] ?? Int.max
            let right = orderByID[rhs.id] ?? Int.max
            return left == right ? lhs.name < rhs.name : left < right
        }
    }

    private var progressionTemplate: DayTemplate? {
        templates.first(where: { $0.id == session.templateId })
    }

    private var progressionRecommendations: [ProgressionRecommendationRow] {
        guard session.isCompleted else { return [] }
        let records = session.progressionRecordsByExerciseId
        let templateOrder = progressionTemplate?.orderedExerciseIds ?? []
        let orderByID = Dictionary(
            uniqueKeysWithValues: templateOrder.enumerated().map {
                ($0.element, $0.offset)
            }
        )
        return records.values.map { record in
            return ProgressionRecommendationRow(
                exerciseID: record.exerciseID,
                exerciseName: record.exerciseName,
                isBodyweight: record.isBodyweight,
                record: record
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
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(templateName)
                        .font(AppFont.title.font)
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
                    progressionCard
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
                                .padding(.vertical, AppSpacing.sm)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .accessibilityHint("Opens progress history for \(exercise.name).")
                    }
                }

                if completionMoment == nil, !progressionRecommendations.isEmpty {
                    progressionCard
                }

                if showsFeedbackInvitation {
                    feedbackInvitationCard
                }
            }
            .appScreenEnter()
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .appNavigationBarChrome()
        .toolbar(.hidden, for: .tabBar)
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

    private var progressionCard: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader(AppCopy.Workout.nextTimeTitle)

            AppCardList(progressionRecommendations) { recommendation in
                progressionRow(recommendation)
            }
        }
    }

    @ViewBuilder
    private func progressionRow(_ recommendation: ProgressionRecommendationRow) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(statusText(recommendation.record))
                    .font(AppFont.muted.font)
                    .contentTransition(.opacity)
                    .animation(AppMotion.feedback, value: statusText(recommendation.record))
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                if recommendation.displayTarget != nil,
                   isActionable(recommendation) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .center, spacing: AppSpacing.md) {
                            recommendationExerciseName(
                                recommendation.exerciseName,
                                reservesIntrinsicWidth: true
                            )

                            Spacer(minLength: 0)

                            recommendationEditButton(recommendation)
                        }

                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            recommendationExerciseName(recommendation.exerciseName)
                            recommendationEditButton(recommendation)
                        }
                    }
                } else {
                    recommendationExerciseName(recommendation.exerciseName)
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.smd) {
                if let previousTarget = recommendation.record.previousTarget,
                   let previousTargetText = completeTargetText(
                       previousTarget,
                       setCount: recommendation.record.configuredSetCount
                   ) {
                    evidenceLine(label: "Previous target", value: previousTargetText)
                }

                if let actualText = actualPerformanceText(recommendation.record) {
                    evidenceLine(label: "Logged", value: actualText)
                }

                if let accepted = recommendation.record.acceptedTarget,
                   let suggested = recommendation.record.suggestedTarget,
                   accepted != suggested,
                   let suggestedText = completeTargetText(
                       suggested,
                       setCount: recommendation.record.configuredSetCount
                   ) {
                    evidenceLine(label: "Suggested", value: suggestedText)
                }

                if let target = recommendation.displayTarget,
                   let targetText = completeTargetText(
                       target,
                       setCount: recommendation.record.configuredSetCount
                   ) {
                    evidenceLine(label: recommendation.record.acceptedTarget == nil ? "Suggested target" : "Next target", value: targetText, emphasized: true)
                }
            }

            Text(explanationText(recommendation.record))
                .contentTransition(.opacity)
                .animation(AppMotion.feedback, value: explanationText(recommendation.record))
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if isActionable(recommendation),
               recommendation.record.acceptedTarget == nil,
               recommendation.record.suggestedTarget != nil {
                AppPrimaryButton(
                    AppCopy.Workout.useThisTarget,
                    isEnabled: isValidRecommendation(recommendation)
                ) {
                    useSuggestedTarget(recommendation)
                }
                .accessibilityLabel(
                    "\(AppCopy.Workout.useThisTarget) for \(recommendation.exerciseName)"
                )
                .transition(AppBlurTransition().animation(.appReveal))

                if recommendation.record.recommendationReason != .repeatTarget {
                    AppGhostButton(AppCopy.Workout.repeatPreviousTarget) {
                        repeatPreviousTarget(recommendation)
                    }
                    .accessibilityLabel(
                        "\(AppCopy.Workout.repeatPreviousTarget) for \(recommendation.exerciseName)"
                    )
                    .transition(AppBlurTransition().animation(.appReveal))
                }
            }
        }
        .padding(.vertical, AppSpacing.sm)
        .appAnimation(.appState, value: recommendation.record.acceptedTarget != nil, reduceMotion: reduceMotion)
        .overlay {
            AppCelebration(moment: acceptedExerciseID == recommendation.exerciseID ? acceptedMoment : nil)
        }
    }

    @ViewBuilder
    private func recommendationExerciseName(
        _ exerciseName: String,
        reservesIntrinsicWidth: Bool = false
    ) -> some View {
        if reservesIntrinsicWidth {
            Text(exerciseName)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)
                .fixedSize(horizontal: true, vertical: true)
        } else {
            Text(exerciseName)
                .font(AppFont.sectionHeader.font)
                .foregroundStyle(AppColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func recommendationEditButton(
        _ recommendation: ProgressionRecommendationRow
    ) -> some View {
        Button(AppCopy.Workout.edit) {
            beginEditing(recommendation)
        }
        .font(AppFont.body.font)
        .foregroundStyle(AppColor.textSecondary)
        .frame(minWidth: 44, minHeight: 44, alignment: .leading)
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(
            "Edit next target for \(recommendation.exerciseName)"
        )
    }

    private func evidenceLine(label: String, value: String, emphasized: Bool = false) -> some View {
        AppListRow(title: label, style: .cardListContent) {
            Text(value)
                .appNumericValue(value: value)
                .font(AppFont.performance.font)
                .bold(emphasized)
                .foregroundStyle(emphasized ? AppColor.textPrimary : AppColor.textSecondary)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var recommendationEditSheet: some View {
        AppSheetScreen(
            title: AppCopy.Workout.editNextTarget,
            primaryButton: PrimaryButtonConfig(
                label: AppCopy.Workout.saveChanges,
                isEnabled: parsedEditingWeightKg != nil && parsedEditingReps != nil,
                action: saveEditedRecommendation
            ),
            dismissLabel: AppCopy.Nav.cancel,
            onDismissAction: { editingRecommendationID = nil },
            showsKeyboardDismissToolbar: true
        ) {
            VStack(alignment: .center, spacing: AppSpacing.xl) {
                if let recommendation = editingRecommendation {
                    Text(recommendation.exerciseName)
                        .font(AppFont.productHeading.font)
                        .foregroundStyle(AppColor.textPrimary)
                        .multilineTextAlignment(.center)

                    HStack(alignment: .bottom, spacing: AppSpacing.lg) {
                        recommendationWeightEditor(for: recommendation)
                        recommendationRepsEditor(for: recommendation)
                    }
                }
            }
            .frame(maxWidth: .infinity)
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
        .appToast(event: $toastMessage)
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
                .font(AppFont.performance.font)
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
                .font(AppFont.performance.font)
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
        guard let target = recommendation.displayTarget else { return }
        editingWeightText = displayedWeight(target.weightKg)
        editingRepsText = String(target.reps)
        editingRecommendationID = recommendation.id
    }

    private func saveEditedRecommendation() {
        guard let recommendation = editingRecommendation,
              let weightKg = parsedEditingWeightKg,
              let reps = parsedEditingReps else { return }
        let target = DoubleProgressionTarget(
            weightKg: weightKg,
            reps: reps
        )
        let saved = persistTarget(
            target,
            for: recommendation,
            action: .edited,
            reason: recommendation.record.recommendationReason ?? .repeatTarget
        )
        if saved { editingRecommendationID = nil }
    }

    private func useSuggestedTarget(_ recommendation: ProgressionRecommendationRow) {
        guard let target = recommendation.record.suggestedTarget,
              let reason = recommendation.record.recommendationReason else {
            return
        }
        persistTarget(
            target,
            for: recommendation,
            action: .usedSuggestion,
            reason: reason
        )
    }

    private func repeatPreviousTarget(_ recommendation: ProgressionRecommendationRow) {
        guard let target = recommendation.record.previousTarget else { return }
        persistTarget(
            target,
            for: recommendation,
            action: .repeatedPreviousTarget,
            reason: .repeatTarget
        )
    }

    @discardableResult
    private func persistTarget(
        _ target: DoubleProgressionTarget,
        for recommendation: ProgressionRecommendationRow,
        action: ProgressionDecisionAction,
        reason: DoubleProgressionReason
    ) -> Bool {
        guard isActionable(recommendation),
              let template = progressionTemplate,
              target.weightKg.isFinite,
              target.weightKg > 0,
              target.reps >= recommendation.record.lowerRepBound,
              target.reps <= recommendation.record.upperRepBound else {
            return false
        }
        let previousTarget = template.progressionState(for: recommendation.exerciseID)?.acceptedTarget
        let absoluteRecommendation = DoubleProgressionRecommendation(
            target: target,
            reason: reason,
            sourceWorkoutSessionID: session.id
        )
        guard template.acceptProgressionRecommendation(
            absoluteRecommendation,
            for: recommendation.exerciseID
        ) else {
            return false
        }

        guard session.recordProgressionDecision(
            target: target,
            action: action,
            for: recommendation.exerciseID
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
                pendingAcceptedExerciseID = recommendation.exerciseID
                if editingRecommendationID == nil { playAcceptedMomentIfNeeded() }
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

    private func isValidRecommendation(_ recommendation: ProgressionRecommendationRow) -> Bool {
        guard let target = recommendation.record.suggestedTarget else { return false }
        return recommendation.record.configuredSetCount > 0
            && target.weightKg.isFinite
            && target.weightKg > 0
            && target.reps >= recommendation.record.lowerRepBound
            && target.reps <= recommendation.record.upperRepBound
    }

    private func isActionable(_ recommendation: ProgressionRecommendationRow) -> Bool {
        guard let template = progressionTemplate,
              let currentState = template.progressionState(
                  for: recommendation.exerciseID
              ),
        !hasNewerCompletedSession(for: recommendation.exerciseID) else {
            return false
        }
        guard recommendation.record.acceptedTarget == nil else {
            return currentState.sourceWorkoutSessionID == session.id
        }

        guard template.plannedSets(for: recommendation.exerciseID)
                == recommendation.record.configuredSetCount,
              currentState.lowerRepBound == recommendation.record.lowerRepBound,
              currentState.upperRepBound == recommendation.record.upperRepBound,
              abs(
                  currentState.weightIncrementKg
                      - recommendation.record.weightIncrementKg
              ) <= 0.000_1,
              currentState.currentAcceptedTargetReps
                == recommendation.record.previousTarget?.reps else {
            return false
        }
        if let currentWeight = currentState.currentAcceptedTargetWeightKg,
           let previousWeight = recommendation.record.previousTarget?.weightKg {
            return abs(currentWeight - previousWeight) <= 0.000_1
        }
        return true
    }

    private func hasNewerCompletedSession(for exerciseID: UUID) -> Bool {
        allSessions.contains { candidate in
            candidate.id != session.id
                && candidate.templateId == session.templateId
                && candidate.isCompleted
                && candidate.date > session.date
                && candidate.setEntries.contains(where: {
                    $0.exerciseId == exerciseID
                        && $0.isCompleted
                        && !$0.isWarmup
                })
        }
    }

    private func statusText(_ record: SessionProgressionRecord) -> String {
        if record.unavailableReason != nil {
            return AppCopy.Workout.noAutomaticTarget
        }
        switch record.decisionAction {
        case .usedSuggestion:
            return AppCopy.Workout.acceptedForNextTime
        case .repeatedPreviousTarget:
            return AppCopy.Workout.repeatingForNextTime
        case .edited:
            return AppCopy.Workout.editedForNextTime
        case nil:
            return record.acceptedTarget == nil
                ? AppCopy.Workout.suggestedForNextTime
                : AppCopy.Workout.acceptedForNextTime
        }
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

    private func explanationText(_ record: SessionProgressionRecord) -> String {
        if let reason = record.unavailableReason {
            switch reason {
            case .mixedWorkingSetWeights:
                return "\(AppCopy.Workout.mixedWeightsUnavailable) \(AppCopy.Workout.chooseTargetManually)"
            case .incompleteWorkingSets:
                return "\(AppCopy.Workout.incompleteSetsUnavailable) \(AppCopy.Workout.chooseTargetManually)"
            case .invalidWeightIncrement:
                return AppCopy.Workout.invalidIncrementUnavailable
            case .unsupportedBodyweightOnly:
                return AppCopy.Workout.bodyweightUnavailable
            case .invalidConfiguration, .invalidTarget, .invalidWorkingSetData, .targetWeightOverflow:
                return "\(AppCopy.Workout.invalidDataUnavailable) \(AppCopy.Workout.chooseTargetManually)"
            }
        }

        switch record.recommendationReason {
        case .allSetsReachedTop:
            return AppCopy.Workout.allSetsReachedTopReason
        case .addARep:
            return AppCopy.Workout.addARepReason
        case .repeatTarget:
            return AppCopy.Workout.repeatTargetReason
        case nil:
            return AppCopy.Workout.invalidDataUnavailable
        }
    }

    private func backfillAcceptedProgressionRecordsIfNeeded() {
        guard let template = progressionTemplate else { return }
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

                Button(AppCopy.Engagement.noThanks) {
                    UnitAnalytics.shared.track(.feedbackAction(action: .dismiss))
                    withAnimation(AppMotion.allowsSpatialMotion(reduceMotion: UIAccessibility.isReduceMotionEnabled, voiceOver: UIAccessibility.isVoiceOverRunning) ? .appState : nil) {
                        showsFeedbackInvitation = false
                    }
                }
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 44)
                .buttonStyle(ScaleButtonStyle())
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
        guard !didTrackRecommendations else { return }
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
