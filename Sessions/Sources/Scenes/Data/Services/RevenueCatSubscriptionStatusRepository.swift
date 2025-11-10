import Foundation
import Observation
import RevenueCat

@MainActor
@Observable
final class RevenueCatSubscriptionStatusRepository: NSObject, SubscriptionStatusProviding {
    @ObservationIgnored
    private let purchases: RevenueCatPurchasing
    private(set) var status: SubscriptionStatus

    var isSubscribed: Bool { status.isSubscribed }

    init(purchases: RevenueCatPurchasing = Purchases.shared) {
        self.purchases = purchases
        self.status = .unknown
        super.init()
        self.purchases.delegate = self
        Task { await refreshStatus() }
    }

    func refreshStatus() async {
        do {
            let info = try await purchases.customerInfo()
            status = SubscriptionStatus(customerInfo: info)
        } catch {
            status = .unknown
        }
    }
}

extension RevenueCatSubscriptionStatusRepository: PurchasesDelegate {
    nonisolated func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor [weak self] in
            self?.status = SubscriptionStatus(customerInfo: customerInfo)
        }
    }
}

private extension SubscriptionStatus {
    init(customerInfo: CustomerInfo) {
        let activeEntitlements = customerInfo.entitlements.active.values
        guard !activeEntitlements.isEmpty else {
            self = .inactive
            return
        }

        let expiration = activeEntitlements.compactMap(\.expirationDate).max()
        self = .active(expirationDate: expiration)
    }
}

protocol RevenueCatPurchasing: AnyObject {
    var delegate: PurchasesDelegate? { get set }
    func customerInfo() async throws -> CustomerInfo
}

extension Purchases: RevenueCatPurchasing {}
