//
//  ContentView.swift
//  Unit
//
//  Root: native tab navigation (Today, Programs, Profile).
//
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.displayName) private var exercises: [Exercise]
    @Query(sort: \DayTemplate.name) private var templates: [DayTemplate]

    @State private var selectedTab: RootTab = .today
    @State private var store: StoreManager
    @AppStorage(PersistenceRecoveryState.noticeKey) private var showsPersistenceRecoveryNotice = false
    @AppStorage("unitSystem") private var unitSystem = "kg"

    init() {
        _splits = Query(sort: \Split.name)
        _sessions = Query(sort: \WorkoutSession.date, order: .reverse)
        _store = State(initialValue: StoreManager())
    }

    private var hasActiveSession: Bool {
        sessions.contains { !$0.isCompleted }
    }

    /// Any user without a program still needs setup, even if they have
    /// historical/freestyle sessions that onboarding can convert.
    private var needsOnboarding: Bool {
        splits.isEmpty
    }

    private var shouldShowPaywall: Bool {
        !needsOnboarding && store.hasCheckedEntitlement && !store.isPurchased
    }

    private var shouldShowEntitlementLoading: Bool {
        !needsOnboarding && !store.hasCheckedEntitlement
    }

    var body: some View {
        // Root swaps must be immediate. SwiftData-backed @Query values can
        // hydrate after the first frame; opacity transitions here can leave
        // the whole root invisible on iOS 27's Xcode launcher path.
        ZStack {
            if needsOnboarding {
                OnboardingView()
            } else if shouldShowEntitlementLoading {
                entitlementLoadingView
            } else if shouldShowPaywall {
                PaywallView(onDismiss: { /* root swap happens via store.isPurchased */ })
                    .environment(store)
            } else {
                mainTabView
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .onAppear {
            configureNavigationBarAppearance()
            configureSegmentedControlAppearance()
            configureTabBarAppearance()
        }
        .alert("Training data unavailable", isPresented: $showsPersistenceRecoveryNotice) {
            Button("Continue temporarily", role: .cancel) { }
        } message: {
            Text("Unit couldn't open the local training store. Your existing data was left untouched, but changes in this session won't be saved. Close the app and contact support before logging another workout.")
        }
    }

    private var entitlementLoadingView: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ProgressView()
                .tint(AppColor.accent)
        }
    }

    private var mainTabView: some View {
        // Native tabs retain their stacks; only the arriving page fades out of blur.
        // Entitlement/onboarding/root swaps above remain immediate (iOS 27).
        TabView(selection: $selectedTab) {
            Tab(RootTab.today.title, systemImage: RootTab.today.systemImage, value: RootTab.today) {
                TodayView()
                    .appTabEntrance(isSelected: selectedTab == .today)
            }

            Tab(RootTab.program.title, systemImage: RootTab.program.systemImage, value: RootTab.program) {
                TemplatesView()
                    .appTabEntrance(isSelected: selectedTab == .program)
            }

            Tab(RootTab.profile.title, systemImage: RootTab.profile.systemImage, value: RootTab.profile) {
                profileTab
                    .appTabEntrance(isSelected: selectedTab == .profile)
            }
        }
        .tint(AppColor.accent)
        .toolbar(hasActiveSession ? .hidden : .visible, for: .tabBar)
        .environment(store)
        .environment(\.appTabSelection, AppTabSelection { tab in
            selectedTab = tab
        })
    }

    // Page composition uses existing primitives; no new component or variant.
    private var profileTab: some View {
        let now = Date()
        let start = Calendar.current.date(byAdding: .day, value: -29, to: Calendar.current.startOfDay(for: now)) ?? now
        let finished = sessions.filter { $0.isCompleted && $0.date <= now }
        let recent = finished.filter { $0.date >= start }
        let workingSets = recent.flatMap(\.setEntries).filter(\.isValidCompletedWorkingSet)
        let metrics = [
            (title: "Workouts", value: "\(recent.filter { $0.setEntries.contains(where: \.isValidCompletedWorkingSet) }.count)"),
            (title: "Working sets", value: WorkoutTargetFormatter.groupedCountDisplay(workingSets.count) ?? "0"),
            (title: "Total reps", value: WorkoutTargetFormatter.groupedCountDisplay(workingSets.reduce(0) { $0 + $1.reps }) ?? "0")
        ]
        let points = ExerciseProgressView.sessionPointsByExercise(in: finished)
        let loggedExercises = exercises.filter { points[$0.id] != nil }.sorted {
            let lhs = points[$0.id]?.last?.date ?? .distantPast
            let rhs = points[$1.id]?.last?.date ?? .distantPast
            return lhs == rhs ? $0.displayName < $1.displayName : lhs > rhs
        }

        return NavigationStack {
            AppScreen(showsNativeNavigationBar: true) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AppSectionHeader("Last 30 days")
                        AppCardList(data: metrics, id: \.title) { metric in
                            AppListRow(title: metric.title, value: metric.value, style: .cardListContent)
                                .accessibilityElement(children: .combine)
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AppSectionHeader("Progressive overload")
                        if loggedExercises.isEmpty {
                            EmptyStateCard(
                                title: "Progress starts with a workout",
                                message: "Finish a workout with working sets to see your weight, reps and volume here."
                            )
                        } else {
                            Text("Heaviest working set, compared with the previous session in the same routine. Tap an exercise for its full history.")
                                .font(AppFont.caption.font)
                                .foregroundStyle(AppColor.textSecondary)
                            AppCardList(loggedExercises) { exercise in
                                NavigationLink(value: exercise) {
                                    AppListRow(
                                        title: exercise.displayName,
                                        subtitle: profileEvidence(for: exercise, points: points[exercise.id] ?? []),
                                        leadingIcon: .chart,
                                        style: .cardListContent
                                    )
                                }
                                .buttonStyle(.plain)
                                .accessibilityHint("Opens weight, reps and working-set volume history")
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        AppSectionHeader("Training log")
                        AppCardList(data: ["History", "Settings"], id: \.self) { destination in
                            NavigationLink(value: destination) {
                                AppListRow(
                                    title: destination,
                                    subtitle: destination == "History" ? "All sessions and next-target decisions" : "Weight unit, subscription and data",
                                    leadingIcon: destination == "History" ? .calendarClock : .settingsOutline,
                                    style: .cardListContent
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Based on completed working sets saved on this iPhone. Warmups, unfinished workouts and invalid entries are excluded. Missing workouts are not estimated.")
                        .font(AppFont.caption.font)
                        .foregroundStyle(AppColor.textSecondary)
                }
                .appScreenEnter()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .appNavigationBarChrome()
            .navigationDestination(for: Exercise.self) { exercise in
                ExerciseProgressView(
                    exerciseId: exercise.id,
                    exerciseName: exercise.displayName,
                    isBodyweight: exercise.isBodyweight,
                    sessions: sessions,
                    templates: templates
                )
            }
            .navigationDestination(for: String.self) { destination in
                if destination == "History" {
                    RecentSessionsView(showsCloseButton: false)
                } else {
                    SettingsView(showsCloseButton: false)
                }
            }
        }
    }

    private func profileEvidence(for exercise: Exercise, points: [ExerciseProgressView.SessionPoint]) -> String {
        guard let latest = points.last else { return "No completed working sets" }
        let previous = points.dropLast().last { $0.templateId == latest.templateId }
        let template = templates.first { $0.id == latest.templateId }
        let routine = template?.displayName ?? "Past routine"
        let date = latest.date.formatted(.dateTime.month(.abbreviated).day())
        let performance = ExerciseProgressView.performanceText(for: latest, isBodyweight: exercise.isBodyweight)
        let comparison = ExerciseProgressView.comparisonText(for: latest, previous: previous, isBodyweight: exercise.isBodyweight)
        var evidence = "\(performance) · \(date) · \(routine)\n\(comparison)"
        if let template,
           let target = template.progressionState(for: exercise.id)?.acceptedTarget,
           let targetText = WorkoutTargetFormatter.completeTargetText(
                weightKg: target.weightKg,
                setCount: template.plannedSets(for: exercise.id) ?? 0,
                reps: target.reps
           ) {
            evidence += "\nAccepted next target · \(targetText)"
        }
        return evidence
    }

    private func configureNavigationBarAppearance() {
        let titleColor = UIColor(AppColor.textPrimary)
        // Anchor inline title to `.headline` and large title to `.largeTitle` so
        // each grows at the rate that text style expects under Dynamic Type.
        let titleFont = UIFont.geist(.bold, size: 17, relativeTo: .headline)
        let largeTitleFont = UIFont.geist(.bold, size: 34, relativeTo: .largeTitle)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [.foregroundColor: titleColor, .font: titleFont]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor, .font: largeTitleFont]

        let scrollEdgeAppearance = UINavigationBarAppearance()
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: titleColor, .font: titleFont]
        scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: titleColor, .font: largeTitleFont]

        let navBar = UINavigationBar.appearance()
        navBar.tintColor = titleColor
        navBar.standardAppearance = appearance
        navBar.compactAppearance = appearance
        navBar.scrollEdgeAppearance = scrollEdgeAppearance
    }

    private func configureSegmentedControlAppearance() {
        let segmentedControl = UISegmentedControl.appearance()
        segmentedControl.backgroundColor = UIColor(AppColor.controlBackground)
        segmentedControl.selectedSegmentTintColor = UIColor(AppColor.cardBackground)
        let normalFont = UIFont.geist(.medium, size: 14, relativeTo: .footnote)
        let selectedFont = UIFont.geist(.semibold, size: 14, relativeTo: .footnote)
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor(AppColor.textSecondary), .font: normalFont],
            for: .normal
        )
        segmentedControl.setTitleTextAttributes(
            [.foregroundColor: UIColor(AppColor.textPrimary), .font: selectedFont],
            for: .selected
        )
    }

    private func configureTabBarAppearance() {
        let tabFont = UIFont.geist(.medium, size: 10, relativeTo: .caption2)
        let attributes: [NSAttributedString.Key: Any] = [.font: tabFont]
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes(attributes, for: .selected)
    }
}

struct AppTabSelection {
    let select: (RootTab) -> Void

    func callAsFunction(_ tab: RootTab) {
        select(tab)
    }
}

private struct AppTabSelectionKey: EnvironmentKey {
    static let defaultValue = AppTabSelection { _ in }
}

extension EnvironmentValues {
    var appTabSelection: AppTabSelection {
        get { self[AppTabSelectionKey.self] }
        set { self[AppTabSelectionKey.self] = newValue }
    }
}

enum RootTab: String, CaseIterable, Hashable {
    case today
    case program
    case profile

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .program:
            return "Programs"
        case .profile:
            return "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            return AppIcon.todayTab.systemName
        case .program:
            return AppIcon.program.systemName
        case .profile:
            return AppIcon.chart.systemName
        }
    }

    var icon: AppIcon {
        switch self {
        case .today:
            return .todayTab
        case .program:
            return .program
        case .profile:
            return .chart
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
