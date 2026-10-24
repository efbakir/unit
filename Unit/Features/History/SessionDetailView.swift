//
//  SessionDetailView.swift
//  Unit
//
//  Session detail grouped by exercise. "···" > Edit workout edits it.
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
    @State private var toastMessage: AppToastEvent?
    @State private var editingRecommendationID: UUID?
    @State private var editingWeightText = ""
    @State private var editingRepsText = ""
    @FocusState private var editingTargetField: String?
    @State private var didTrackRecommendations = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    /// Next-target choices made here. Finish already saved the suggestions;
    /// these save on "Save all" or when the screen goes away (2026-10-24).
    @State private var pendingTargets: [UUID: DoubleProgressionTarget] = [:]
    @State private var savedMoment: AppCelebrationMoment?
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

        /// Where "Change…" starts. Without a suggestion (weights varied, sets
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
        // A native title gives the bar its own edge, so the floating back
        // and menu buttons never sit on card content.
        .navigationTitle(templateName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !isReadOnly {
                // Away from the target choices, with a full label (2026-10-24).
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(AppCopy.History.editWorkout, systemImage: AppIcon.edit.systemName) {
                            showsEditWorkout = true
                        }
                        .accessibilityIdentifier("edit-workout")
                    } label: {
                        Label(AppCopy.History.moreActions, systemImage: AppIcon.more.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityIdentifier("session-more")
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
        .appToast(event: editingRecommendationID == nil ? $toastMessage : .constant(nil))
        .sheet(
            isPresented: Binding(
                get: { editingRecommendationID != nil },
                set: { if !$0 { editingRecommendationID = nil } }
            ),
            onDismiss: { editingRecommendationID = nil }
        ) {
            recommendationEditSheet
        }
        .onAppear {
            backfillAcceptedProgressionRecordsIfNeeded()
            presentFeedbackInvitationIfNeeded()
            trackRecommendationsIfNeeded()
        }
        // Leaving keeps every choice: nothing made here is lost.
        .onDisappear { savePendingTargets(announces: false) }
    }

    private var detailStack: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(session.date.formatted(.dateTime.month(.abbreviated).day().hour().minute()))
                .font(AppFont.caption.font)
                .foregroundStyle(AppColor.textSecondary)
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

    /// Direction A (2026-10-24): a header with what happened and one
    /// "Save all", then one card per exercise with the next target as the hero
    /// and every target choice in one control under it.
    @ViewBuilder
    private var progressionSections: some View {
        let rows = progressionRecommendations
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            progressionHeader(rows)
            ForEach(rows) { recommendation in
                progressionCard(recommendation)
            }
        }
    }

    private func progressionHeader(_ rows: [ProgressionRecommendationRow]) -> some View {
        let changes = rows.compactMap { row -> Int? in
            guard let next = nextTarget(row), let previous = row.record.previousTarget else { return nil }
            return next == previous ? 0 : (next.isAbove(previous) ? 1 : -1)
        }
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    AppSectionHeader(AppCopy.Workout.nextTimeTitle)
                    Text(AppCopy.Workout.nextTimeCount(
                        up: changes.filter { $0 > 0 }.count,
                        same: changes.filter { $0 == 0 }.count,
                        down: changes.filter { $0 < 0 }.count
                    ))
                    .font(AppFont.sectionHeader.font)
                    .foregroundStyle(AppColor.textPrimary)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                // Finish confetti and the saved burst stay in this text area,
                // never over the cards or their actions.
                .overlay { AppCelebration(moment: savedMoment ?? completionMoment).clipped() }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("next-time-header")

                if !isReadOnly, rows.contains(where: \.isActionable) {
                    AppPrimaryButton(AppCopy.Workout.saveAll) {
                        savePendingTargets(announces: true)
                    }
                    .accessibilityIdentifier("save-all-targets")
                }
            }
        }
    }

    private func progressionCard(_ recommendation: ProgressionRecommendationRow) -> some View {
        let record = recommendation.record
        let next = nextTarget(recommendation)
        return AppCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text(recommendation.exerciseName)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if let previous = record.previousTarget,
                   let text = completeTargetText(previous, setCount: record.configuredSetCount) {
                    Text(AppCopy.Workout.lastTarget(text))
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                        .monospacedDigit()
                }
                if let next, let heroText = completeTargetText(next, setCount: record.configuredSetCount) {
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        Text(heroText)
                            .appNumericValue(value: heroText)
                            .font(AppFont.title.font)
                            .foregroundStyle(AppColor.textPrimary)
                            .monospacedDigit()
                            .fixedSize(horizontal: false, vertical: true)
                        AppTag(text: changeChip(next, from: record), style: .muted, layout: .compactCapsule)
                        Spacer(minLength: 0)
                    }
                }
                Text(reasonText(recommendation, next: next))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .contentTransition(.opacity)
                    .fixedSize(horizontal: false, vertical: true)
                if recommendation.editTarget != nil {
                    targetChoiceControl(recommendation)
                        .padding(.top, AppSpacing.xs)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .appAnimation(.appState, value: next, reduceMotion: reduceMotion)
    }

    private enum TargetChoice: Hashable, Identifiable {
        case suggested
        case previous
        case change
        /// A plain ID keeps the segmented control's ID-based init out of play.
        var id: String { "\(self)" }
    }

    /// `+1 rep | Keep 3 × 9 | Change…`. Tapping only selects; "Change…" opens
    /// the sheet. At accessibility sizes the three segments do not fit, so one
    /// "Change…" button opens the sheet with every option instead.
    @ViewBuilder
    private func targetChoiceControl(_ recommendation: ProgressionRecommendationRow) -> some View {
        let choices = targetChoices(recommendation)
        let selection: Binding<TargetChoice> = Binding(
            get: { selectedChoice(recommendation) },
            set: { choose($0, for: recommendation) }
        )
        if dynamicTypeSize.isAccessibilitySize {
            AppSecondaryButton(AppCopy.Workout.changeTarget) { beginEditing(recommendation) }
                .accessibilityIdentifier("change-target-\(recommendation.exerciseName)")
        } else {
            AppSegmentedControl(
                selection: selection,
                items: choices,
                label: AppCopy.Workout.nextTargetFor(recommendation.exerciseName),
                title: { (choice: TargetChoice) -> String in choiceTitle(choice, for: recommendation) }
            )
            .accessibilityIdentifier("target-choice-\(recommendation.exerciseName)")
        }
    }

    private func targetChoices(_ recommendation: ProgressionRecommendationRow) -> [TargetChoice] {
        let record = recommendation.record
        var choices: [TargetChoice] = []
        if let suggested = record.suggestedTarget, suggested != record.previousTarget { choices.append(.suggested) }
        if record.previousTarget != nil { choices.append(.previous) }
        return choices + [.change]
    }

    private func choiceTitle(_ choice: TargetChoice, for recommendation: ProgressionRecommendationRow) -> String {
        let record = recommendation.record
        switch choice {
        case .suggested:
            return record.suggestedTarget.map { changeChip($0, from: record) } ?? AppCopy.Workout.suggestedForNextTime
        case .previous:
            return AppCopy.Workout.keepTarget(record.previousTarget.flatMap {
                WorkoutTargetFormatter.setRepDisplay(setCount: record.configuredSetCount, reps: $0.reps)
            } ?? "")
        case .change:
            return AppCopy.Workout.changeTarget
        }
    }

    private func selectedChoice(_ recommendation: ProgressionRecommendationRow) -> TargetChoice {
        let record = recommendation.record
        guard let next = nextTarget(recommendation) else { return .change }
        if next == record.suggestedTarget, record.suggestedTarget != record.previousTarget { return .suggested }
        if next == record.previousTarget { return .previous }
        return .change
    }

    private func choose(_ choice: TargetChoice, for recommendation: ProgressionRecommendationRow) {
        switch choice {
        case .suggested: pendingTargets[recommendation.id] = recommendation.record.suggestedTarget
        case .previous: pendingTargets[recommendation.id] = recommendation.record.previousTarget
        case .change: beginEditing(recommendation)
        }
    }

    /// The target the next workout will use: a choice made here, else what
    /// Finish saved, else the target that stays.
    private func nextTarget(_ recommendation: ProgressionRecommendationRow) -> DoubleProgressionTarget? {
        let record = recommendation.record
        return pendingTargets[recommendation.id] ?? record.acceptedTarget
            ?? record.suggestedTarget ?? record.previousTarget
    }

    /// "+1 rep", "+2.5 kg" or "Same", measured from the previous target.
    private func changeChip(_ next: DoubleProgressionTarget, from record: SessionProgressionRecord) -> String {
        guard let previous = record.previousTarget else { return AppCopy.Workout.sameTarget }
        let weightChange = next.weightKg - previous.weightKg
        if abs(weightChange) >= 0.01 {
            return WorkoutTargetFormatter.signedWeightChangeText(weightKg: weightChange, unitSystem: unitSystem)
        }
        let repChange = next.reps - previous.reps
        return repChange == 0 ? AppCopy.Workout.sameTarget : AppCopy.Workout.repChange(repChange)
    }

    /// Why this target, or what the lifter changed. Never a reason that
    /// contradicts the target shown above it.
    private func reasonText(_ recommendation: ProgressionRecommendationRow, next: DoubleProgressionTarget?) -> String {
        let record = recommendation.record
        let suggestedText = record.suggestedTarget.flatMap { suggested in
            suggested.weightKg == record.previousTarget?.weightKg
                ? WorkoutTargetFormatter.setRepDisplay(setCount: record.configuredSetCount, reps: suggested.reps)
                : completeTargetText(suggested, setCount: record.configuredSetCount)
        }
        if let next, let suggested = record.suggestedTarget, next != suggested {
            if next == record.previousTarget, let suggestedText {
                return AppCopy.Workout.keptReason(suggestedWas: suggestedText)
            }
            return AppCopy.Workout.changedReason(suggestedWas: suggestedText)
        }
        if let next, record.suggestedTarget == nil, next != record.previousTarget {
            return AppCopy.Workout.changedReason(suggestedWas: nil)
        }
        return explanationText(record, offersEdit: recommendation.editTarget != nil)
    }

    /// "Change…": the exercise, its last target, weight and reps. At
    /// accessibility sizes it also lists Suggested and Keep previous target.
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
                    Text(AppCopy.Workout.changeSheetSubtitle(
                        last: record.previousTarget.flatMap { completeTargetText($0, setCount: record.configuredSetCount) }
                    ))
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                    if dynamicTypeSize.isAccessibilitySize {
                        ForEach(targetChoices(recommendation).filter { $0 != .change }) { choice in
                            AppSecondaryButton(sheetOptionTitle(choice, for: recommendation)) {
                                choose(choice, for: recommendation)
                                editingRecommendationID = nil
                            }
                        }
                    }

                    HStack(alignment: .bottom, spacing: AppSpacing.lg) {
                        recommendationWeightEditor(for: recommendation)
                        recommendationRepsEditor(for: recommendation)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .presentationDetents([.medium, .large])
        .appBottomSheetChrome()
        .appToast(event: $toastMessage)
    }

    private func sheetOptionTitle(_ choice: TargetChoice, for recommendation: ProgressionRecommendationRow) -> String {
        switch choice {
        case .suggested: return AppCopy.Workout.suggestedOption(choiceTitle(.suggested, for: recommendation))
        case .previous: return AppCopy.Workout.keepPreviousOption
        case .change: return AppCopy.Workout.changeTarget
        }
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
        guard recommendation.editTarget != nil,
              let target = nextTarget(recommendation) ?? recommendation.editTarget else { return }
        editingWeightText = displayedWeight(target.weightKg)
        editingRepsText = String(target.reps)
        editingRecommendationID = recommendation.id
    }

    /// The sheet sets a choice; it saves with the others (Save all or leave).
    private func saveEditedRecommendation() {
        guard let recommendation = editingRecommendation,
              let weightKg = parsedEditingWeightKg,
              let reps = parsedEditingReps else { return }
        let typed = DoubleProgressionTarget(weightKg: weightKg, reps: reps)
        let record = recommendation.record
        // A retyped suggestion or previous target keeps the exact stored value.
        pendingTargets[recommendation.id] = switch record.decisionAction(saving: typed) {
        case .usedSuggestion: record.suggestedTarget ?? typed
        case .repeatedPreviousTarget: record.previousTarget ?? typed
        case .edited: typed
        }
        editingRecommendationID = nil
    }

    /// Saves every choice that differs from what is stored, in one save.
    /// `announces` adds the toast, haptic and burst for "Save all"; leaving
    /// the screen saves quietly.
    private func savePendingTargets(announces: Bool) {
        guard !isReadOnly, !isDeleted, let template = progressionTemplate else { return }
        var decisions: [(ProgressionDecisionAction, DoubleProgressionReason)] = []
        for row in progressionRecommendations {
            guard let target = pendingTargets[row.id], target != row.record.acceptedTarget,
                  isActionable(row.record), target.weightKg.isFinite, target.weightKg > 0,
                  target.reps >= row.record.lowerRepBound,
                  target.reps <= row.record.upperRepBound else { continue }
            let action = row.record.decisionAction(saving: target)
            let reason = action == .repeatedPreviousTarget
                ? DoubleProgressionReason.repeatTarget : (row.record.recommendationReason ?? .repeatTarget)
            guard session.saveProgressionDecision(target, action: action, reason: reason,
                                                  for: row.exerciseID, template: template) else {
                modelContext.rollbackRestoringLoadedModels()
                toastMessage = .init(AppCopy.Workout.targetsSaveFailed, kind: .error)
                return
            }
            decisions.append((action, reason))
        }
        pendingTargets = [:]
        if !decisions.isEmpty {
            do {
                try modelContext.save()
            } catch {
                modelContext.rollbackRestoringLoadedModels()
                toastMessage = .init(AppCopy.Workout.targetsSaveFailed, kind: .error)
                AppHaptic.error.fire()
                return
            }
            for (action, reason) in decisions {
                UnitAnalytics.shared.track(.progressionDecision(
                    action: analyticsDecision(for: action),
                    outcome: analyticsOutcome(for: reason)
                ))
            }
        }
        guard announces else { return }
        AppHaptic.success.fire()
        savedMoment = AppCelebrationMoment(style: .burst)
        toastMessage = .init(AppCopy.Workout.targetsSaved, kind: .success)
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
            return AppCopy.Workout.allSetsReachedTopReason(
                topReps: record.upperRepBound,
                increment: WorkoutTargetFormatter.signedWeightChangeText(weightKg: record.weightIncrementKg,
                                                                        unitSystem: unitSystem)
                    .replacingOccurrences(of: "+", with: "")
            )
        case .addARep:
            return AppCopy.Workout.addARepReason(targetReps: record.previousTarget?.reps ?? record.lowerRepBound)
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
