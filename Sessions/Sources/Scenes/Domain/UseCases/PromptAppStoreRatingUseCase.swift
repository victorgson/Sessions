import Foundation

@MainActor
protocol PromptAppStoreRatingUseCase {
    func execute(
        totalSessionsCompleted: Int,
        didCloseLinkSheet: Bool,
        isEditingDraft: Bool
    )
}

@MainActor
struct DefaultPromptAppStoreRatingUseCase: PromptAppStoreRatingUseCase {
    private let repository: AppStoreRatingPromptRepository
    private let targetSessionCount: Int

    init(
        repository: AppStoreRatingPromptRepository,
        targetSessionCount: Int = 2
    ) {
        self.repository = repository
        self.targetSessionCount = targetSessionCount
    }

    func execute(
        totalSessionsCompleted: Int,
        didCloseLinkSheet: Bool,
        isEditingDraft: Bool
    ) {
        guard didCloseLinkSheet, !isEditingDraft else { return }
        guard totalSessionsCompleted == targetSessionCount else { return }
        repository.requestReviewPrompt()
    }
}
