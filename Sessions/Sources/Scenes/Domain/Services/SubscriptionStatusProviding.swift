import Foundation
import Observation

enum SubscriptionStatus: Equatable {
    case unknown
    case inactive
    case active(expirationDate: Date?)

    var isSubscribed: Bool {
        if case .active = self {
            return true
        }
        return false
    }
}

@MainActor
protocol SubscriptionStatusProviding: Observable, AnyObject {
    var status: SubscriptionStatus { get }
    var isSubscribed: Bool { get }
    func refreshStatus() async
}
