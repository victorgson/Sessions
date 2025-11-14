import Foundation
import Observation
import Tracking

@MainActor
@Observable
final class RecentSessionsViewModel: ActionTracking {
    typealias ObjectiveAdjustmentHandler = (
        _ objectiveID: UUID,
        _ allocations: [KeyResultAllocation],
        _ adding: Bool
    ) -> Void

    let loadActivitiesUseCase: any LoadActivitiesUseCase
    let removeActivityUseCase: any RemoveActivityUseCase
    let trackerDispatcher: TrackerDispatcher
    let hapticBox: HapticBox
    private let objectiveAdjustmentHandler: ObjectiveAdjustmentHandler

    var activities: [Activity]

    init(
        loadActivitiesUseCase: any LoadActivitiesUseCase,
        removeActivityUseCase: any RemoveActivityUseCase,
        trackerDispatcher: TrackerDispatcher,
        hapticBox: HapticBox,
        objectiveAdjustmentHandler: @escaping ObjectiveAdjustmentHandler
    ) {
        self.loadActivitiesUseCase = loadActivitiesUseCase
        self.removeActivityUseCase = removeActivityUseCase
        self.trackerDispatcher = trackerDispatcher
        self.hapticBox = hapticBox
        self.objectiveAdjustmentHandler = objectiveAdjustmentHandler
        self.activities = []
    }

    func loadActivities() async {
        do {
            activities = try await loadActivitiesUseCase.execute()
        } catch {
            assertionFailure("Failed to load activities: \(error)")
            activities = []
        }
    }

    func reloadActivities() async {
        await loadActivities()
    }

    func deleteActivity(_ activity: Activity) {
        trackAction(TrackingEvent.SessionTracker.Action(value: .deleteActivity(id: activity.id)))
        Task { await deleteActivityAsync(activity) }
    }
}

private extension RecentSessionsViewModel {
    func deleteActivityAsync(_ activity: Activity) async {
        do {
            try await removeActivityUseCase.execute(activity.id)
            activities = try await loadActivitiesUseCase.execute()
        } catch {
            assertionFailure("Failed to delete activity: \(error)")
        }

        if let objectiveID = activity.linkedObjectiveID {
            objectiveAdjustmentHandler(objectiveID, activity.keyResultAllocations, false)
        }

        hapticBox.triggerNotification(DefaultHapticBox.Notification.warning)
    }
}
