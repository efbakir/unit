//
//  SettingsView.swift
//  Unit
//
//  Lightweight secondary preferences screen launched from Program.
//

import StoreKit
import SwiftUI
import UIKit

/// kg / lb segments shared by Settings and the onboarding review step.
enum WeightUnitOption: String, CaseIterable, Identifiable, Hashable {
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
    case restore = "Restore purchases"
    case manage = "Manage subscription"

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
enum SupportMailto {
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
    @Environment(\.openURL) private var openURL
    @Environment(StoreManager.self) private var store

    @State private var showingRestoreSuccess = false
    @State private var showingManageSubscriptions = false
    @State private var toastMessage: AppToastEvent?
    @State private var analyticsEnabled = UnitAnalytics.shared.isEnabled

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
                ToolbarItem(placement: .cancellationAction) {
                    Group {
                        Button { dismiss() } label: {
                            Label(AppCopy.Nav.close, systemImage: AppIcon.close.systemName)
                                .labelStyle(.iconOnly)
                        }
                        .accessibilityLabel(AppCopy.Nav.close)
                    }
                    .tint(AppColor.textPrimary)
                }
            }
        }
        .tint(AppColor.accent)
        .appToast(event: $toastMessage)
        .alert("Purchases restored", isPresented: $showingRestoreSuccess) {
            Button(AppCopy.Nav.ok, role: .cancel) { }
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .alert(
            "Restore",
            isPresented: infoAlertBinding,
            presenting: store.infoMessage
        ) { _ in
            Button(AppCopy.Nav.ok, role: .cancel) { store.infoMessage = nil }
        } message: { message in
            Text(message)
        }
        .alert(
            "Something went wrong",
            isPresented: errorAlertBinding,
            presenting: store.purchaseError
        ) { _ in
            Button(AppCopy.Nav.ok, role: .cancel) { store.purchaseError = nil }
        } message: { error in
            Text(error)
        }
    }

    @ViewBuilder
    private var settingsContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.lg) {
            preferencesSection
            dataSection
            subscriptionSection
            feedbackSection
            legalSection

            #if DEBUG
            SettingsSection(title: "Design system", contentInset: AppSpacing.sm) {
                NavigationLink {
                    AppComponentCatalog()
                } label: {
                    AppListRow(title: "Components", subtitle: "Shared controls and feedback", showsDisclosure: true)
                }
                .buttonStyle(ScaleButtonStyle())
            }
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
            AppDividedList(data: ["Weight unit", AppCopy.Preferences.anonymousAnalytics], id: \.self) { row in
                if row == "Weight unit" {
                    AppListRow(title: row) {
                        AppSegmentedControl(
                            selection: Binding(
                                get: { WeightUnitOption(rawValue: unitSystem) ?? .kg },
                                set: { unitSystem = $0.rawValue }
                            ),
                            items: WeightUnitOption.allCases,
                            label: "Weight unit",
                            title: { $0.rawValue }
                        )
                    }
                } else {
                    AppListRow(title: row) {
                        Toggle("", isOn: $analyticsEnabled)
                            .labelsHidden()
                            .tint(AppColor.accent)
                            .accessibilityLabel(AppCopy.Preferences.anonymousAnalytics)
                    }
                }
            }
        }
        .onChange(of: analyticsEnabled) { _, enabled in
            UnitAnalytics.shared.setEnabled(enabled)
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
                        AppListRow(title: row.rawValue, tone: .action) {
                            // Reserve the indicator's space so the row stays
                            // still when restoring begins or finishes.
                            ProgressView()
                                .opacity(store.isLoading ? 1 : 0)
                                .accessibilityHidden(!store.isLoading)
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
                        AppListRow(title: row.rawValue, showsDisclosure: true)
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

    private var feedbackSection: some View {
        SettingsSection(title: "Feedback", contentInset: AppSpacing.sm) {
            Button {
                openFeatureRequestPortal()
            } label: {
                AppListRow(title: AppCopy.FeatureRequest.actionTitle, showsDisclosure: true)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityLabel(AppCopy.FeatureRequest.actionTitle)
            .accessibilityHint(AppCopy.FeatureRequest.accessibilityHint)
        }
    }

    @ViewBuilder
    private var legalSection: some View {
        SettingsSection(title: "Legal", contentInset: AppSpacing.sm) {
            AppDividedList(LegalRow.allCases) { row in
                if let url = row.url {
                    Link(destination: url) {
                        AppListRow(title: row.title, showsDisclosure: true)
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
                Link(destination: mailURL) {
                    AppGhostButtonLabel(title: "support@unitlift.app", layout: .inline)
                }
                .buttonStyle(ScaleButtonStyle())
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, AppSpacing.lg)
    }

    private func openFeatureRequestPortal() {
        guard let url = AppCopy.FeatureRequest.portalURL else {
            toastMessage = .init(AppCopy.FeatureRequest.openError, kind: .error)
            return
        }

        UnitAnalytics.shared.track(.feedbackAction(action: .portal))
        openURL(url) { accepted in
            if !accepted {
                toastMessage = .init(AppCopy.FeatureRequest.openError, kind: .error)
            }
        }
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

/// One switch for the stored analytics setting, so setup and the paywall
/// can turn it off before purchase. Settings uses the same label and key.
struct AnonymousAnalyticsToggle: View {
    @State private var isEnabled = UnitAnalytics.shared.isEnabled

    var body: some View {
        Toggle(isOn: $isEnabled) {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(AppCopy.Preferences.anonymousAnalytics)
                    .font(AppFont.body.font)
                    .foregroundStyle(AppColor.textPrimary)
                Text(AppCopy.Preferences.anonymousAnalyticsCaption)
                    .font(AppFont.muted.font)
                    .foregroundStyle(AppColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(AppColor.accent)
        .frame(minHeight: 44)
        .accessibilityIdentifier("anonymous-analytics-toggle")
        .onAppear {
            isEnabled = UnitAnalytics.shared.isEnabled
        }
        .onChange(of: isEnabled) { _, enabled in
            UnitAnalytics.shared.setEnabled(enabled)
        }
    }
}

#Preview {
    SettingsView()
        .environment(StoreManager())
}
