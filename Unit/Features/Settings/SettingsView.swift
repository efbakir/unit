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
import UniformTypeIdentifiers

/// kg / lb segments shared by Settings and the onboarding review step.
enum WeightUnitOption: String, CaseIterable, Identifiable, Hashable {
    case kg
    case lb

    var id: String { rawValue }
}

private enum DataRow: String, CaseIterable, Identifiable {
    case storage = "Storage"
    case account = "Account"
    case export = "Export workouts"
    case importHistory = "Import from Strong or Hevy"
    case undoImport = "Undo last import"

    var id: String { rawValue }
}

private enum SubscriptionRow: String, CaseIterable, Identifiable {
    case status = "Unit Pro"
    case renewal = "Renewal"
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
    @Environment(\.modelContext) private var modelContext
    @Environment(StoreManager.self) private var store
    @Query(.anyLoggedSet) private var anyLoggedSet: [SetEntry]

    @State private var showingRestoreSuccess = false
    @State private var showingManageSubscriptions = false
    @State private var toastMessage: AppToastEvent?
    @State private var showsHistoryImporter = false
    @State private var importPlan: ImportPlanItem?
    @State private var importError: String?
    @State private var lastImport = WorkoutHistoryImporter.lastBatch()
    @State private var showsUndoImportConfirmation = false
    @AppStorage(HealthWorkoutPolicy.enabledKey) private var savesToAppleHealth = false

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
        .fileImporter(
            isPresented: $showsHistoryImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text]
        ) { result in
            readHistoryFile(result)
        }
        .sheet(item: $importPlan) { item in
            ImportHistorySheet(
                plan: item.plan,
                defaultUnit: unitSystem == "lb" ? .lb : .kg
            ) { unit in
                importHistory(item.plan, weightUnit: unit)
            }
        }
        .alert(
            AppCopy.DataTransfer.importFailedTitle,
            isPresented: importErrorBinding,
            presenting: importError
        ) { _ in
            Button(AppCopy.Nav.close, role: .cancel) { importError = nil }
        } message: { message in
            Text(message)
        }
        .alert("Purchases restored", isPresented: $showingRestoreSuccess) {
            Button(AppCopy.Nav.ok, role: .cancel) { }
        }
        .manageSubscriptionsSheet(isPresented: $showingManageSubscriptions)
        .task { await store.refreshRenewalSummary() }
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
            AppDividedList(DataRow.allCases.filter { $0 != .undoImport || lastImport != nil }) { row in
                switch row {
                case .storage:
                    AppListRow(
                        title: row.rawValue,
                        value: "On this iPhone",
                        subtitle: AppCopy.DataTransfer.storageBackup
                    )
                case .account:
                    AppListRow(title: row.rawValue, value: "None")
                case .export:
                    exportRow(title: row.rawValue)
                case .importHistory:
                    Button {
                        showsHistoryImporter = true
                    } label: {
                        AppListRow(title: row.rawValue, subtitle: AppCopy.DataTransfer.csvFile)
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityIdentifier("settings-import-history")
                case .undoImport:
                    Button {
                        showsUndoImportConfirmation = true
                    } label: {
                        AppListRow(
                            title: row.rawValue,
                            value: AppCopy.DataTransfer.workoutCount(lastImport?.workoutCount ?? 0)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .accessibilityIdentifier("settings-undo-import")
                    .confirmationDialog(
                        AppCopy.DataTransfer.undoImportConfirmTitle,
                        isPresented: $showsUndoImportConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button(AppCopy.DataTransfer.undoImportAction, role: .destructive, action: undoLastImport)
                    } message: {
                        Text(AppCopy.DataTransfer.undoImportMessage(lastImport?.workoutCount ?? 0))
                    }
                }
            }
        }
    }

    /// Reads the picked file and parses it off the main actor; the preview
    /// sheet opens with what would be imported. Nothing is saved yet.
    private func readHistoryFile(_ result: Result<URL, any Error>) {
        guard case .success(let url) = result else { return }
        let isScoped = url.startAccessingSecurityScopedResource()
        defer { if isScoped { url.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: url),
              let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
            importError = AppCopy.DataTransfer.readFailed
            return
        }
        Task {
            let parsed = await Task.detached(priority: .userInitiated) {
                Result { try WorkoutHistoryParser.parse(text) }
            }.value
            switch parsed {
            case .success(let file):
                let sessions = (try? modelContext.fetch(FetchDescriptor<WorkoutSession>())) ?? []
                let exercises = (try? modelContext.fetch(FetchDescriptor<Exercise>())) ?? []
                importPlan = ImportPlanItem(plan: WorkoutHistoryImporter.plan(
                    for: file,
                    existingSessions: sessions,
                    exercises: exercises
                ))
            case .failure(let error):
                importError = (error as? WorkoutHistoryImportError) == .noWorkouts
                    ? AppCopy.DataTransfer.noWorkouts
                    : AppCopy.DataTransfer.unknownFormat
            }
        }
    }

    private func importHistory(_ plan: WorkoutHistoryImportPlan, weightUnit: ImportWeightUnit) -> Bool {
        do {
            let batch = try WorkoutHistoryImporter.importHistory(plan, weightUnit: weightUnit, into: modelContext)
            lastImport = batch
            UnitAnalytics.shared.track(.historyImported(
                source: plan.source,
                size: AnalyticsImportSizeBucket(workoutCount: batch.workoutCount)
            ))
            toastMessage = .init(AppCopy.DataTransfer.imported(batch.workoutCount), kind: .success)
            AppHaptic.success.fire()
            return true
        } catch {
            AppHaptic.error.fire()
            return false
        }
    }

    private func undoLastImport() {
        guard let batch = lastImport else { return }
        do {
            try WorkoutHistoryImporter.undo(batch, in: modelContext)
            lastImport = nil
            toastMessage = .init(AppCopy.DataTransfer.importUndone, kind: .success)
            AppHaptic.warning.fire()
        } catch {
            toastMessage = .init(AppCopy.DataTransfer.undoFailed, kind: .error)
            AppHaptic.error.fire()
        }
    }

    /// The native share sheet with every logged set as a CSV file. A plain
    /// value row while there is nothing to export, so the row never looks
    /// tappable without doing anything.
    @ViewBuilder
    private func exportRow(title: String) -> some View {
        if anyLoggedSet.isEmpty {
            AppListRow(title: title, value: AppCopy.DataTransfer.noWorkoutsYet)
        } else {
            ShareLink(
                item: WorkoutCSVFile(container: modelContext.container, unitSystem: unitSystem),
                preview: SharePreview(AppCopy.DataTransfer.exportPreviewTitle)
            ) {
                AppListRow(title: title, subtitle: AppCopy.DataTransfer.csvFile)
            }
            .buttonStyle(ScaleButtonStyle())
            .accessibilityIdentifier("settings-export-workouts")
        }
    }

    @ViewBuilder
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences", contentInset: AppSpacing.sm) {
            AppDividedList(data: preferenceRows, id: \.self) { row in
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
                } else if row == AppCopy.Preferences.saveToAppleHealth {
                    AppListRow(title: row) {
                        Toggle("", isOn: $savesToAppleHealth)
                            .labelsHidden()
                            .tint(AppColor.accent)
                            .accessibilityLabel(AppCopy.Preferences.saveToAppleHealth)
                            .accessibilityIdentifier("settings-apple-health")
                    }
                } else {
                    AnonymousAnalyticsToggle(style: .tappable)
                }
            }
        }
        .onChange(of: savesToAppleHealth) { _, enabled in
            guard enabled else { return }
            Task { await confirmAppleHealthAccess() }
        }
        .task {
            // Access can be removed in the Apple Health app at any time.
            if savesToAppleHealth && !HealthWorkoutSync.canSave { savesToAppleHealth = false }
        }
    }

    private var preferenceRows: [String] {
        ["Weight unit", AppCopy.Preferences.anonymousAnalytics]
            + (HealthWorkoutSync.isAvailable ? [AppCopy.Preferences.saveToAppleHealth] : [])
    }

    /// iOS asks only now, when the lifter turns the switch on.
    private func confirmAppleHealthAccess() async {
        guard !(await HealthWorkoutSync.requestAccess()) else { return }
        savesToAppleHealth = false
        // Stays until dismissed: it tells the lifter what to change in another app.
        toastMessage = AppToastEvent(AppCopy.Preferences.appleHealthDenied, kind: .error)
    }

    @ViewBuilder
    private var subscriptionSection: some View {
        SettingsSection(title: "Subscription", contentInset: AppSpacing.sm) {
            AppDividedList(subscriptionRows) { row in
                switch row {
                case .status:
                    AppListRow(title: row.rawValue, value: subscriptionStatusValue)
                case .renewal:
                    // Trial end or next charge (benchmark 2026-10-24).
                    if let summary = store.renewalSummary {
                        AppListRow(
                            title: renewalTitle(summary.kind),
                            value: AppCopy.Paywall.timelineDate(summary.date)
                        )
                    }
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
            switch row {
            case .manage: canShowManageSubscriptions
            case .renewal: store.renewalSummary != nil
            case .status, .restore: true
            }
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

    private func renewalTitle(_ kind: SubscriptionRenewalSummary.Kind) -> String {
        switch kind {
        case .trialEnds: "Trial ends"
        case .renews: "Renews"
        case .ends: "Ends"
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

    private var importErrorBinding: Binding<Bool> {
        Binding(
            get: { importError != nil },
            set: { if !$0 { importError = nil } }
        )
    }

    private var infoAlertBinding: Binding<Bool> {
        Binding(
            get: { store.infoMessage != nil },
            set: { if !$0 { store.infoMessage = nil } }
        )
    }
}

/// One opt-in switch for the stored analytics setting, shared by setup step 1,
/// the paywall and Settings so the three places cannot drift. The wrapper
/// exists only for that shared binding; the row is the canonical `AppListRow`.
struct AnonymousAnalyticsToggle: View {
    /// `.cardListContent` on the page (setup, paywall); `.tappable` inside
    /// Settings' list, where rows own their inset. Same row everywhere.
    var style: AppListRowStyle = .cardListContent
    @State private var isEnabled = UnitAnalytics.shared.isEnabled

    var body: some View {
        AppListRow(
            title: AppCopy.Preferences.anonymousAnalytics,
            subtitle: AppCopy.Preferences.anonymousAnalyticsCaption,
            style: style
        ) {
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .tint(AppColor.accent)
                .accessibilityLabel(AppCopy.Preferences.anonymousAnalytics)
                .accessibilityHint(AppCopy.Preferences.anonymousAnalyticsCaption)
                .accessibilityIdentifier("anonymous-analytics-toggle")
        }
        .frame(minHeight: 44)
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
