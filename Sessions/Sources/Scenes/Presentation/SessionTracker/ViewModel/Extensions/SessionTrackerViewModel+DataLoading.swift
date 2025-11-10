import Foundation
import Tracking

@MainActor
extension SessionTrackerViewModel {
    func loadInitialData() async {
        do {
            objectives = try await loadObjectivesUseCase.execute()
        } catch {
            assertionFailure("Failed to load objectives: \(error)")
            objectives = []
        }

        do {
            activities = try await loadActivitiesUseCase.execute()
        } catch {
            assertionFailure("Failed to load activities: \(error)")
            activities = []
        }
    }

    func deleteActivity(_ activity: Activity) {
        trackAction(TrackingEvent.SessionTracker.Action(value: .deleteActivity(id: activity.id)))
        Task { await deleteActivityAsync(activity) }
    }

    private func deleteActivityAsync(_ activity: Activity) async {
        do {
            try await removeActivityUseCase.execute(activity.id)
            activities = try await loadActivitiesUseCase.execute()
        } catch {
            assertionFailure("Failed to delete activity: \(error)")
        }

        if let objectiveID = activity.linkedObjectiveID {
            applyTimeAllocations(activity.keyResultAllocations, to: objectiveID, adding: false)
        }

        hapticBox.triggerNotification(DefaultHapticBox.Notification.warning)
    }
}
