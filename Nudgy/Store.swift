import Foundation
import StoreKit

/// The one-time unlock, sold on the iPhone only. The Watch is told the result by sync.
@MainActor
final class Store: ObservableObject {
    /// Must match the product created in App Store Connect (type: non-consumable).
    static let productID = "com.georgfasching.nudgy.unlock"

    @Published private(set) var unlocked: Bool
    /// Nil until the App Store has returned the product (or if it does not exist yet).
    @Published private(set) var product: Product?
    @Published private(set) var busy = false
    @Published var message: String?

    var onUnlockedChange: ((Bool) -> Void)?

    private static let cacheKey = "nudgy.unlocked.v1"
    private static let debugKey = "nudgy.debugMode.v1"
    private var updates: Task<Void, Never>?

    init() {
        // Start from the last known state so the app works offline; then verify.
        unlocked = UserDefaults.standard.bool(forKey: Self.cacheKey)
        updates = Task { [weak self] in
            for await _ in Transaction.updates {
                await self?.refresh()
            }
        }
        Task { [weak self] in
            await self?.refresh()
            await self?.loadProduct()
        }
    }

    func loadProduct() async {
        product = try? await Product.products(for: [Self.productID]).first
    }

    func purchase() async {
        guard let product else {
            message = "The purchase isn't available yet."
            return
        }
        busy = true
        defer { busy = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refresh()
                } else {
                    message = "The purchase could not be verified."
                }
            case .pending:
                message = "The purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            message = "The purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        busy = true
        defer { busy = false }
        do {
            try await AppStore.sync()
            await refresh()
            if !unlocked { message = "No earlier purchase was found for this Apple ID." }
        } catch {
            message = "Restore failed: \(error.localizedDescription)"
        }
    }

    /// Re-reads what the user owns from the App Store.
    func refresh() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                owned = true
            }
        }
        #if DEBUG
        switch debugMode {
        case .real: break
        case .free: owned = false
        case .paid: owned = true
        }
        #endif
        if owned != unlocked {
            unlocked = owned
            onUnlockedChange?(owned)
        }
        UserDefaults.standard.set(owned, forKey: Self.cacheKey)
    }

    #if DEBUG
    /// Test switch, compiled into debug builds only (runs from Xcode), never into App Store builds.
    enum DebugMode: String, CaseIterable, Identifiable {
        /// What the App Store says this Apple ID owns.
        case real
        /// Paid features removed, even if a test purchase was made.
        case free
        /// Paid features on, without a purchase.
        case paid
        var id: String { rawValue }
        var title: String {
            switch self {
            case .real: return "Real purchase"
            case .free: return "Free"
            case .paid: return "Paid"
            }
        }
    }

    var debugMode: DebugMode {
        get { DebugMode(rawValue: UserDefaults.standard.string(forKey: Self.debugKey) ?? "") ?? .real }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: Self.debugKey)
            objectWillChange.send()
            Task { await refresh() }
        }
    }
    #endif
}
