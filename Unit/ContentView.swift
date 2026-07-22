//
//  ContentView.swift
//  Unit
//
//  Root: Tab navigation (Today, Program).
//
import SwiftData
import SwiftUI
import UIKit

struct ContentView: View {
    @Query(sort: \Split.name) private var splits: [Split]
    @Query(sort: \WorkoutSession.date, order: .reverse) private var sessions: [WorkoutSession]

    @State private var selectedTab: RootTab = .today
    @State private var store: StoreManager
    #if DEBUG
    @State private var presentsOnboardingAtLaunch = true
    #endif
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

    private var shouldShowOnboarding: Bool {
        #if DEBUG
        return presentsOnboardingAtLaunch || needsOnboarding
        #else
        return needsOnboarding
        #endif
    }

    private var shouldShowPaywall: Bool {
        return !needsOnboarding && store.hasCheckedEntitlement && !store.isPurchased
    }

    private var shouldShowEntitlementLoading: Bool {
        !needsOnboarding && !store.hasCheckedEntitlement
    }

    var body: some View {
        // Root swaps must be immediate. SwiftData-backed @Query values can
        // hydrate after the first frame; opacity transitions here can leave
        // the whole root invisible on iOS 27's Xcode launcher path.
        ZStack {
            if shouldShowOnboarding {
                OnboardingView(onCompletion: completeOnboarding)
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

    private func completeOnboarding() {
        #if DEBUG
        presentsOnboardingAtLaunch = false
        #endif
    }

    private var entitlementLoadingView: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()
            ProgressView()
                .tint(AppColor.accent)
        }
    }

    private var mainTabView: some View {
        // Tab swaps are intentionally instant — iOS-native expectation
        // (Mail, Messages, Settings, Calendar). The .selection haptic is the
        // delight signal; visual content motion fights TabView's own swap and
        // reads as buggy. CLAUDE.md §4 (Prefer iOS-native: tab bar).
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label(RootTab.today.title, systemImage: RootTab.today.systemImage)
                }
                .tag(RootTab.today)

            TemplatesView()
                .tabItem {
                    Label(RootTab.program.title, systemImage: RootTab.program.systemImage)
                }
                .tag(RootTab.program)
        }
        .tint(AppColor.accent)
        .toolbar(hasActiveSession ? .hidden : .visible, for: .tabBar)
        .appHaptic(.tabChange, trigger: selectedTab)
        .environment(store)
        .environment(\.appTabSelection, AppTabSelection { tab in
            selectedTab = tab
        })
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

    var title: String {
        switch self {
        case .today:
            return "Today"
        case .program:
            return "Programs"
        }
    }

    var systemImage: String {
        switch self {
        case .today:
            return AppIcon.todayTab.systemName
        case .program:
            return AppIcon.program.systemName
        }
    }

    var icon: AppIcon {
        switch self {
        case .today:
            return .todayTab
        case .program:
            return .program
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
