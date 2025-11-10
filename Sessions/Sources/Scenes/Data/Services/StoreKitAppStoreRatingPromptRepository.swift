import StoreKit
import UIKit

@MainActor
final class StoreKitAppStoreRatingPromptRepository: AppStoreRatingPromptRepository {
    func requestReviewPrompt() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return
        }

        AppStore.requestReview(in: scene)
    }
}
