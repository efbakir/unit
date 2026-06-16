//
//  StoreManager.swift
//  Unit
//
//  Handles StoreKit 2 product loading, purchasing, and restore
//  for the three Unit subscription tiers: Weekly, Monthly, Annual.
//  Pricing authority: docs/pricing.md.
//

import StoreKit
import OSLog

@MainActor
@Observable
final class StoreManager {
    // MARK: - Product IDs

    enum Tier: String, CaseIterable, Identifiable {
        case weekly = "com.unit.weekly"
        case monthly = "com.unit.monthly"
        case annual = "com.unit.annual"

        var id: String { rawValue }
    }

    nonisolated static let weeklyProductID = Tier.weekly.rawValue
    nonisolated static let monthlyProductID = Tier.monthly.rawValue
    nonisolated static let annualProductID = Tier.annual.rawValue

    nonisolated private static let allProductIDs: [String] = [
        Tier.weekly.rawValue,
        Tier.monthly.rawValue,
        Tier.annual.rawValue
    ]

    // MARK: - State

    var products: [String: Product] = [:]
    var isLoading = false
    var isPurchased = false
    /// Flips true the first time `checkEntitlement()` completes (success or no
    /// entitlement). Read by `ContentView` to avoid flashing the hard paywall
    /// over `mainTabView` on cold launch before the StoreKit check returns.
    var hasCheckedEntitlement = false
    var purchaseError: String?
    /// Non-error notice shown via the same `.alert` channel — e.g.
    /// "No purchases to restore." after a benign restore call.
    var infoMessage: String?

    /// Currently selected tier in the paywall. Default = Annual (recommended).
    var selectedTier: Tier = .annual

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app.unitlift", category: "StoreManager")
    @ObservationIgnored nonisolated(unsafe) private var transactionListener: Task<Void, Never>?

    // MARK: - Init

    init() {
        guard !ProcessInfo.processInfo.isSwiftUIPreview else { return }
        transactionListener = listenForTransactions()
        Task { await checkEntitlement() }
    }

    /// Nonisolated for the same back-deploy-shim SIGABRT as
    /// `ActiveWorkoutViewModel.deinit` — see the comment there. Safe:
    /// `transactionListener` is `nonisolated(unsafe)` and `Task.cancel()`
    /// is thread-safe.
    nonisolated deinit {
        transactionListener?.cancel()
    }

    // MARK: - Accessors

    func product(for tier: Tier) -> Product? {
        products[tier.rawValue]
    }

    var selectedProduct: Product? { product(for: selectedTier) }

    // MARK: - Load Products

    @MainActor
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let loaded = try await Product.products(for: Self.allProductIDs)
            products = Dictionary(uniqueKeysWithValues: loaded.map { ($0.id, $0) })
        } catch {
            logger.error("Failed to load products: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    @MainActor
    func purchase() async {
        await purchase(tier: selectedTier)
    }

    @MainActor
    func purchase(tier: Tier) async {
        guard let product = product(for: tier) else { return }
        guard !isLoading else { return }
        purchaseError = nil
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                // Re-derive entitlement from `currentEntitlements` rather than
                // assuming success implies isPurchased = true. Keeps a single
                // source of truth and matches the transaction-listener path.
                await checkEntitlement()
            case .userCancelled:
                break
            case .pending:
                // Ask-to-buy / SCA / parental approval. The entitlement will
                // arrive via the transaction listener once the parent approves;
                // we don't need to surface anything here. Phase 2: revisit
                // with a "Pending approval" message if support requests it.
                break
            @unknown default:
                break
            }
        } catch {
            logger.error("Purchase failed: \(error.localizedDescription)")
            purchaseError = "Purchase failed. Try again in a moment."
        }
    }

    // MARK: - Restore

    @MainActor
    func restore() async {
        guard !isLoading else { return }
        purchaseError = nil
        infoMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await AppStore.sync()
            await checkEntitlement()
            if !isPurchased {
                infoMessage = "No purchases to restore."
            }
        } catch StoreKitError.userCancelled {
            // User dismissed the Apple ID sign-in prompt. Intentional back-out,
            // not an error — surfacing an alert here punishes the user for
            // declining to authenticate.
            return
        } catch StoreKitError.networkError(_) {
            logger.error("Restore failed: network error")
            purchaseError = "Couldn't reach the App Store. Check your connection and try again."
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            purchaseError = "Couldn't restore purchases. Try again in a moment."
        }
    }

    // MARK: - Entitlement Check

    @MainActor
    func checkEntitlement() async {
        var hasEntitlement = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               Self.allProductIDs.contains(transaction.productID) {
                hasEntitlement = true
                break
            }
        }
        isPurchased = hasEntitlement
        hasCheckedEntitlement = true
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                // Always finish verified transactions so they don't replay on
                // next launch. Then re-derive entitlement from
                // `currentEntitlements`, which excludes revoked / refunded /
                // expired transactions — never assume "verified update =
                // isPurchased true". A refund arrives here as a verified
                // transaction with a revocationDate; without re-checking, the
                // user would keep Pro until the next cold launch.
                if case .verified(let transaction) = result,
                   Self.allProductIDs.contains(transaction.productID) {
                    await transaction.finish()
                    await self?.checkEntitlement()
                }
            }
        }
    }

    // MARK: - Verification

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let value):
            return value
        }
    }
}

private extension ProcessInfo {
    var isSwiftUIPreview: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
}
