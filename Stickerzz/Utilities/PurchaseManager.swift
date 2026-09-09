import StoreKit
import Observation

@Observable
final class PurchaseManager {
    static let shared = PurchaseManager()

    // Free tier limits
    static let routineLimit = 1
    static let habitsPerRoutineLimit = 3
    static let standaloneLimit = 5

    private(set) var isPro: Bool = false

    #if DEBUG
    func debugTogglePro() { isPro.toggle() }
    #endif
    private(set) var product: Product? = nil
    private(set) var isLoading: Bool = false

    private let productID = "com.stickerzz.pro"

    private init() {
        Task.detached(priority: .background) { await self.loadAndVerify() }
    }

    private func loadAndVerify() async {
        if let products = try? await Product.products(for: [productID]) {
            product = products.first
        }
        await refreshEntitlement()
    }

    func refreshEntitlement() async {
        var found = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result, tx.productID == productID {
                found = true
                break
            }
        }
        isPro = found
    }

    @MainActor
    func purchase() async throws {
        guard let product else { return }
        isLoading = true
        defer { isLoading = false }
        let result = try await product.purchase()
        if case .success(let verification) = result,
           case .verified(let tx) = verification {
            isPro = true
            await tx.finish()
        }
    }

    @MainActor
    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }
        try? await AppStore.sync()
        await refreshEntitlement()
    }

    // MARK: - Limit helpers

    func canAddRoutine(currentCount: Int) -> Bool {
        isPro || currentCount < Self.routineLimit
    }

    func canAddHabitToRoutine(currentCount: Int) -> Bool {
        isPro || currentCount < Self.habitsPerRoutineLimit
    }

    func canAddStandalone(currentCount: Int) -> Bool {
        isPro || currentCount < Self.standaloneLimit
    }
}
