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

    @AppStorage("hasSeenPriceDisclosure") private var hasSeenPriceDisclosure: Bool = false

    @State private var selectedTab: RootTab = .today
    @State private var store: StoreManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Uses `UserDefaults.standard` in the app; pass an isolated suite in `#Preview` so canvas state does not touch real onboarding flags.
    init(userDefaults: UserDefaults = .standard) {
        _splits = Query(sort: \Split.name)
        _sessions = Query(sort: \WorkoutSession.date, order: .reverse)
        _store = State(initialValue: StoreManager())
        _hasSeenPriceDisclosure = AppStorage(wrappedValue: false, "hasSeenPriceDisclosure", store: userDefaults)
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
        // Stacked gates — one fullScreenCover whose item is computed from
        // (a) D0 price-disclosure has not been seen, and (b) the StoreKit
        // entitlement check has resolved without finding a Pro entitlement.
        // D0 always sits ABOVE the paywall — new users and v1 users alike
        // see it first per Q8 (2026-06-17 decision). Setter is a no-op; the
        // only exits are tapping "Continue setup" (flips
        // `hasSeenPriceDisclosure`) or completing a purchase (flips
        // `store.isPurchased`). Both cause `get` to return a different
        // value, which SwiftUI handles as a cover dismiss + re-present.
        .fullScreenCover(item: onboardingGate) { gate in
            switch gate {
            case .priceDisclosure:
                OnboardingPriceDisclosureView {
                    hasSeenPriceDisclosure = true
                }
            case .paywall:
                PaywallView { /* dismiss flows via store.isPurchased onChange */ }
                    .environment(store)
            }
        }
        .onAppear {
            configureNavigationBarAppearance()
            configureSegmentedControlAppearance()
            configureTabBarAppearance()
        }
    }

    /// Distinct gating states the user passes through before reaching the
    /// main app. Order matters: `.priceDisclosure` (D0) always wins when it
    /// applies — even over the paywall — so v1 users get the disclosure
    /// before the wall.
    private enum OnboardingGate: Identifiable, Hashable {
        case priceDisclosure
        case paywall
        var id: Self { self }
    }

    /// Reactive gate selector — re-evaluated on every render. Returns the
    /// highest-priority gate that should be presented, or `nil` if the user
    /// is free to use the main app. Setter is a no-op; SwiftUI cannot
    /// dismiss the cover programmatically via this binding.
    private var onboardingGate: Binding<OnboardingGate?> {
        Binding(
            get: {
                // Step 1: D0 disclosure shows if it hasn't been acknowledged
                // and the user isn't already subscribed. Fires before the
                // entitlement check so it lands fast on cold launch; the
                // potential redundancy of showing D0 to a subscribed user
                // who deleted UserDefaults is acceptable and uncommon.
                if !hasSeenPriceDisclosure && !store.isPurchased {
                    return .priceDisclosure
                }
                // Step 2: paywall shows after D0 has been acknowledged,
                // onboarding is complete, and the StoreKit check has
                // confirmed there is no Pro entitlement. The
                // `hasCheckedEntitlement` guard avoids flashing the paywall
                // over a subscribed user on cold launch before the async
                // check returns.
                if !needsOnboarding && store.hasCheckedEntitlement && !store.isPurchased {
                    return .paywall
                }
                return nil
            },
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

private enum ContentViewPreviewDefaults {
    static var userDefaults: UserDefaults {
        UserDefaults(suiteName: "unit.preview.ContentView")!
    }
}

#Preview {
    ContentView(userDefaults: ContentViewPreviewDefaults.userDefaults)
        .modelContainer(PreviewSampleData.makePreviewContainer())
}
