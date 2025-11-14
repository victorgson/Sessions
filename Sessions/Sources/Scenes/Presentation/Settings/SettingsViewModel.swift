import Observation

@MainActor
@Observable
final class SettingsViewModel {
    let subscriptionStatusProvider: SubscriptionStatusProviding

    init(subscriptionStatusProvider: SubscriptionStatusProviding) {
        self.subscriptionStatusProvider = subscriptionStatusProvider
    }
}
