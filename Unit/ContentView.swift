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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

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

    var body: some View {
        // Soft cross-fade between onboarding shells and the main tab view.
        // The native tap on the system tab bar is intentionally instant
        // (iOS-native expectation, see CLAUDE.md §4 "Prefer iOS-native"); this
        // transition only fires on the onboarding → main hand-off, which is a
        // root-view swap, not a tab swipe.
        ZStack {
            if needsOnboarding {
                OnboardingView()
                    .transition(.opacity)
            } else {
                mainTabView
                    .transition(.opacity)
            }
        }
        .appAnimation(.appEnter, value: needsOnboarding, reduceMotion: reduceMotion)
        .background(AppColor.background.ignoresSafeArea())
        // Hard paywall — presented once onboarding is complete and the
        // StoreKit entitlement check has resolved without finding a Pro
        // entitlement. There is no pre-onboarding price-disclosure screen:
        // the App Store listing already surfaces the subscription before
        // download, so an in-app "this app is paid" splash is redundant
        // (2026-06-18 reversal of the 2026-06-17 D0 decision — see
        // docs/decision-log.md). The `hasCheckedEntitlement` guard avoids
        // flashing the paywall over a subscribed user on cold launch before
        // the async check returns. Setter is a no-op; the user cannot dismiss
        // the wall — the only exit is a completed purchase flipping
        // `store.isPurchased`, which makes `get` return false.
        .fullScreenCover(isPresented: paywallGate) {
            PaywallView { /* dismiss flows via store.isPurchased onChange */ }
                .environment(store)
        }
        .onAppear {
            configureNavigationBarAppearance()
            configureSegmentedControlAppearance()
            configureTabBarAppearance()
        }
    }

    /// Reactive gate — true once onboarding is complete and the StoreKit
    /// entitlement check has resolved without finding a Pro entitlement.
    /// Setter is a no-op; SwiftUI cannot dismiss the cover programmatically.
    private var paywallGate: Binding<Bool> {
        Binding(
            get: { !needsOnboarding && store.hasCheckedEntitlement && !store.isPurchased },
            set: { _ in }
        )
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
