//
//  SettingsView.swift
//  Unit
//
//  Lightweight secondary preferences screen launched from Program.
//

import StoreKit
import SwiftData
import SwiftUI
import UIKit

private enum SettingsWeightUnit: String, CaseIterable, Identifiable, Hashable {
    case kg
    case lb

    var id: String { rawValue }
}

private enum DataRow: String, CaseIterable, Identifiable {
    case storage = "Storage"
    case account = "Account"
    case export = "Export data"

    var id: String { rawValue }
}

private enum SubscriptionRow: String, CaseIterable, Identifiable {
    case status = "Unit Pro"
    case restore = "Restore Purchases"
    case manage = "Manage Subscription"

    var id: String { rawValue }
}

private enum LegalRow: String, CaseIterable, Identifiable {
    case privacy
    case terms
    case contact = "Contact me"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .privacy: AppCopy.Legal.privacyPolicy
        case .terms: AppCopy.Legal.termsOfService
        case .contact: rawValue
        }
    }

    var url: URL? {
        switch self {
        case .privacy: AppCopy.Legal.privacyPolicyURL
        case .terms: AppCopy.Legal.termsOfServiceURL
        case .contact: SupportMailto.composedURL()
        }
    }
}

/// Builds the support `mailto:` with a prefilled body (Unit version, build,
/// iOS version) so a "Contact support" reply lands with the diagnostic strip
/// already attached. Cuts the round-trip where support has to ask which build
/// the user is on. Pure dynamic — no hardcoded version strings.
private enum SupportMailto {
    static let recipient = "support@unitlift.app"

    static func composedURL() -> URL? {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let ios = UIDevice.current.systemVersion
        // Two leading newlines so the user types above the diagnostic strip
        // without having to delete anything. Plain dashes, no markdown — Mail
        // and Gmail both render the strip cleanly without a preview eyebrow.
        let body = """


        ---
        Unit \(version) (\(build)) · iOS \(ios)
        """
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = recipient
        components.queryItems = [
            URLQueryItem(name: "subject", value: "Unit support"),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url ?? URL(string: "mailto:\(recipient)")
    }
}

struct SettingsView: View {
    private let shouldShowCloseButton: Bool

    @AppStorage("unitSystem") private var unitSystem: String = "kg"
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store

    @State private var showingRestoreSuccess = false
    @State private var showingManageSubscriptions = false
    #if DEBUG
    @State private var debugSeedConfirmation: String?
    #endif

    init(showsCloseButton: Bool = true) {
        self.shouldShowCloseButton = showsCloseButton
    }

    var body: some View {
        AppScreen(showsNativeNavigationBar: true) {
            settingsContent
                .appScreenEnter()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if shouldShowCloseButton {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: {
                        Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName)
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel(AppCopy.Nav.close)
                }
            }
        }
        .tint(AppColor.accent)
        .alert("Purchases restored", isPresented: $showingRestoreSuccess) {
            Button("OK", role: .cancel) { }
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        #if DEBUG
        .alert(
            "Marketing data",
            isPresented: debugSeedAlertBinding,
            presenting: debugSeedConfirmation
        ) { _ in
            Button("OK", role: .cancel) { debugSeedConfirmation = nil }
        } message: { message in
            Text(message)
        }
        #endif
        .alert(
            "Restore",
            isPresented: infoAlertBinding,
            presenting: store.infoMessage
        ) { _ in
            Button("OK", role: .cancel) { store.infoMessage = nil }
        } message: { message in
            Text(message)
        }
        .alert(
            "Something went wrong",
            isPresented: errorAlertBinding,
            presenting: store.purchaseError
        ) { _ in
            Button("OK", role: .cancel) { store.purchaseError = nil }
        } message: { error in
            Text(error)
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            dataSection
            preferencesSection
            subscriptionSection
            legalSection

            #if DEBUG
            debugSection
            #endif

            settingsFooter
        }
    }

    @ViewBuilder
    private var dataSection: some View {
        SettingsSection(title: "Data", contentInset: AppSpacing.sm) {
            // `.export` is filtered out for v1.0.0 — same rationale as
            // `subscriptionSection` (Guideline 2.1(b) rejection 2026-06-03):
            // a PRO chip with no IAP behind it reads as undelivered paid
            // content to App Review. Re-include `.export` when Pro IAPs are
            // submitted in v1.1+. See docs/decision-log.md 2026-06-03.
            AppDividedList(DataRow.allCases.filter { $0 != .export }) { row in
                switch row {
                case .storage:
                    AppListRow(title: row.rawValue, value: "On this iPhone")
                case .account:
                    AppListRow(title: row.rawValue, value: "None")
                case .export:
                    // Unreachable in v1.0.0 (filtered above). Switch case
                    // retained so the v1.1+ Pro launch only needs to remove
                    // the filter, not re-add the rendering.
                    Button { } label: {
                        AppListRow(title: row.rawValue) {
                            AppTag(text: "PRO", style: .accent, layout: .compactCapsule)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences", contentInset: AppSpacing.sm) {
            AppListRow(title: "Weight unit") {
                AppSegmentedControl(
                    selection: Binding(
                        get: { SettingsWeightUnit(rawValue: unitSystem) ?? .kg },
                        set: { unitSystem = $0.rawValue }
                    ),
                    items: SettingsWeightUnit.allCases,
                    title: { $0.rawValue }
                )
            }
        }
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription", contentInset: AppSpacing.sm) {
            AppDividedList(subscriptionRows) { row in
                switch row {
                case .status:
                    AppListRow(title: row.rawValue, value: subscriptionStatusValue)
                case .restore:
                    Button {
                        Task { await runRestore() }
                    } label: {
                        AppListRow(title: row.rawValue) {
                            if store.isLoading {
                                ProgressView()
                            } else {
                                EmptyView()
                            }
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .disabled(store.isLoading)
                case .manage:
                    // Native iOS subscription management sheet (in-app, no
                    // Safari handoff). Settings is post-paywall in v2, so this
                    // is the right place for the required manage entry.
                    // Per CLAUDE.md §4: prefer iOS-native.
                    Button {
                        showingManageSubscriptions = true
                    } label: {
                        AppListRow(title: row.rawValue)
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
        }
    }

    private var subscriptionRows: [SubscriptionRow] {
        SubscriptionRow.allCases.filter { row in
            row != .manage || canShowManageSubscriptions
        }
    }

    private var canShowManageSubscriptions: Bool {
        guard store.isPurchased else { return false }
        guard let activeTier = store.activeTier else { return true }
        return activeTier.isSubscription
    }

    @ViewBuilder
    private var legalSection: some View {
        SettingsSection(title: "Legal", contentInset: AppSpacing.sm) {
            AppDividedList(LegalRow.allCases) { row in
                if let url = row.url {
                    Link(destination: url) {
                        AppListRow(title: row.title)
                    }
                }
            }
        }
    }

    private var settingsFooter: some View {
        VStack(spacing: AppSpacing.xxs) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.xxs) {
                Text("Made with")
                    .font(AppFont.caption.font)
                Text("❤️‍🔥")
                    .font(AppFont.emojiCaption.font)
                    .accessibilityLabel("love")
                Text("in my room")
                    .font(AppFont.caption.font)
            }
            .foregroundStyle(AppColor.textSecondary)
            if let mailURL = URL(string: "mailto:support@unitlift.app") {
                Link("support@unitlift.app", destination: mailURL)
                    .font(AppFont.caption.font)
                    .foregroundStyle(AppColor.textPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.lg)
    }

    private func runRestore() async {
        let wasPurchased = store.isPurchased
        await store.restore()
        if !wasPurchased && store.isPurchased {
            showingRestoreSuccess = true
        }
    }

    private var subscriptionStatusValue: String {
        guard let activeTier = store.activeTier else {
            return store.isPurchased ? "Active" : "Inactive"
        }

        switch activeTier {
        case .weekly: return "Weekly active"
        case .monthly: return "Monthly active"
        case .annual: return "Yearly active"
        case .lifetime: return "Lifetime active"
        }
    }

    #if DEBUG
    @ViewBuilder
    private var debugSection: some View {
        SettingsSection(title: "Debug", contentInset: AppSpacing.sm) {
            Button {
                runMarketingSeed()
            } label: {
                AppListRow(title: "Seed marketing data")
            }
            .buttonStyle(ScaleButtonStyle())
        }
    }

    private func runMarketingSeed() {
        let outcome = MarketingSeed.populateMonthOfHistory(in: modelContext)
        debugSeedConfirmation = outcome.message
    }

    private var debugSeedAlertBinding: Binding<Bool> {
        Binding(
            get: { debugSeedConfirmation != nil },
            set: { if !$0 { debugSeedConfirmation = nil } }
        )
    }
    #endif

    private var errorAlertBinding: Binding<Bool> {
        Binding(
            get: { store.purchaseError != nil },
            set: { if !$0 { store.purchaseError = nil } }
        )
    }

    private var infoAlertBinding: Binding<Bool> {
        Binding(
            get: { store.infoMessage != nil },
            set: { if !$0 { store.infoMessage = nil } }
        )
    }
}

#Preview {
    SettingsView()
        .environment(StoreManager())
}
