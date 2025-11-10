import Foundation

@MainActor
protocol AppStoreRatingPromptRepository: AnyObject {
    func requestReviewPrompt()
}
