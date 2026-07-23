//
//  SessionDetailView.swift
//  Unit
//
//  Read-only session detail grouped by exercise.
//

import SwiftUI
import SwiftData

struct SessionDetailView: View {
    let session: WorkoutSession
    let templateName: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]
    /// Full session history — the PR baseline must replay every completed
    /// session, not just the one on display.
    @Query(sort: \WorkoutSession.date, order: .reverse) private var allSessions: [WorkoutSession]
    @State private var showsFeedbackInvitation = false
    @State private var toastMessage: String?

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

                if !exerciseSnapshots.isEmpty {
                    AppCardList(exerciseSnapshots) { exercise in
                        SessionExerciseSummary(exercise: exercise)
                            .padding(.vertical, AppSpacing.sm)
                    }
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
        .appToast(message: $toastMessage)
        .onAppear {
            presentFeedbackInvitationIfNeeded()
        }
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

                AppPrimaryButton(AppCopy.Engagement.bookCall) {
                    open(EngagementPromptTracker.bookingURL)
                }

                AppGhostButton(AppCopy.Engagement.emailFeedback) {
                    guard let url = EngagementPromptTracker.feedbackEmailURL() else {
                        toastMessage = AppCopy.Engagement.linkError
                        return
                    }
                    open(url)
                }

                Button(AppCopy.Engagement.noThanks) {
                    withAnimation(.appState) {
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

    private func presentFeedbackInvitationIfNeeded() {
        let tracker = EngagementPromptTracker()
        guard tracker.shouldShowFeedback(for: session.id) else { return }
        tracker.markFeedbackPromptShown()
        showsFeedbackInvitation = true
    }

    private func open(_ url: URL) {
        openURL(url) { accepted in
            if !accepted {
                toastMessage = AppCopy.Engagement.linkError
            }
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
