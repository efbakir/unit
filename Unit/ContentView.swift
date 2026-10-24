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

    @State private var selectedTab: RootTab = .today
    @State private var store: StoreManager
    @AppStorage(PersistenceRecoveryState.noticeKey) private var showsPersistenceRecoveryNotice = false

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
        }
        .alert("Training data unavailable", isPresented: $showsPersistenceRecoveryNotice) {
            Button("Continue temporarily", role: .cancel) { }
        } message: {
            Text("Unit couldn’t open the local training store. Your existing data was left untouched, but changes in this session won’t be saved. Close the app and contact support before logging another workout.")
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
        // Native tabs own their transitions; never fade the whole navigation stack.
        // Entitlement/onboarding/root swaps above remain immediate (iOS 27).
        TabView(selection: $selectedTab) {
            Tab(RootTab.today.title, systemImage: RootTab.today.systemImage, value: RootTab.today) {
                TodayView()
                    .tint(AppColor.textPrimary)
            }

            Tab(RootTab.program.title, systemImage: RootTab.program.systemImage, value: RootTab.program) {
                TemplatesView()
                    .tint(AppColor.textPrimary)
            }

            Tab(RootTab.profile.title, systemImage: RootTab.profile.systemImage, value: RootTab.profile) {
                profileTab
                    .tint(AppColor.textPrimary)
            }
        }
        .tint(AppColor.accent)
        .toolbar(hasActiveSession ? .hidden : .visible, for: .tabBar)
        .environment(store)
        .environment(\.appTabSelection, AppTabSelection { tab in
            selectedTab = tab
        })
    }

    private var profileTab: some View {
        NavigationStack { AnalyticsView() }
    }

    private func configureNavigationBarAppearance() {
        let titleColor = UIColor(AppColor.textPrimary)
        // Anchor inline title to `.headline` and large title to `.largeTitle` so
        // each grows at the rate that text style expects under Dynamic Type.
        let titleFont = UIFont.geist(.bold, size: 17, relativeTo: .headline)
        let largeTitleFont = UIFont.geist(.bold, size: 34, relativeTo: .largeTitle)

        // Preserve Unit's typography/tint; leave every bar background and
        // scroll-edge appearance to UIKit/SwiftUI's native defaults.
        let navBar = UINavigationBar.appearance()
        navBar.tintColor = UIColor(AppColor.textPrimary)
        navBar.titleTextAttributes = [.foregroundColor: titleColor, .font: titleFont]
        navBar.largeTitleTextAttributes = [.foregroundColor: titleColor, .font: largeTitleFont]
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
            return "Analytics"
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
