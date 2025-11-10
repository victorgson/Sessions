import Foundation
import Observation
import Tracking

@MainActor
@Observable
final class SessionTrackerViewModel {
    let useCases: SessionTrackerUseCases
    let trackerDispatcher: TrackerDispatcher
    let hapticBox: HapticBox
    let liveActivityController: any SessionLiveActivityControlling
    let subscriptionStatusProvider: any SubscriptionStatusProviding

    var objectives: [Objective]
    var activities: [Activity]
    var activityDraft: ActivityDraft?
    var sessionStartDate: Date?
    var activeObjectives: [Objective] {
        objectives.filter { !$0.isArchived }
    }
    var archivedObjectives: [Objective] {
        objectives.filter { $0.isArchived }
    }
    var hasArchivedObjectives: Bool {
        !archivedObjectives.isEmpty
    }

    init(
        useCases: SessionTrackerUseCases,
        trackerDispatcher: TrackerDispatcher,
        hapticBox: HapticBox,
        liveActivityController: SessionLiveActivityControlling,
        subscriptionStatusProvider: any SubscriptionStatusProviding
    ) {
        self.useCases = useCases
        self.trackerDispatcher = trackerDispatcher
        self.hapticBox = hapticBox
        self.liveActivityController = liveActivityController
        self.subscriptionStatusProvider = subscriptionStatusProvider
        self.objectives = []
        self.activities = []

        Task {
            await loadInitialData()
        }
    }

    func updateCompletionStatus(for objective: inout Objective, now: @autoclosure () -> Date = .now) {
        let isComplete = objective.progress >= 1
        if isComplete {
            if objective.completedAt == nil {
                objective.completedAt = now()
            }
        } else {
            objective.completedAt = nil
        }
    }

    func archiveObjective(withID id: UUID, now: @autoclosure () -> Date = .now) {
        guard let index = objectives.firstIndex(where: { $0.id == id }) else { return }
        var objective = objectives[index]
        guard objective.progress >= 1, !objective.isArchived else { return }
        objective.archivedAt = now()
        updateCompletionStatus(for: &objective)
        objectives[index] = objective
        Task {
            do {
                try await useCases.upsertObjective.execute(objective)
            } catch {
                assertionFailure("Failed to archive objective: \(error)")
            }
        }
    }

    func unarchiveObjective(withID id: UUID) {
        guard let index = objectives.firstIndex(where: { $0.id == id }) else { return }
        var objective = objectives[index]
        guard objective.isArchived else { return }
        objective.archivedAt = nil
        updateCompletionStatus(for: &objective)
        objectives[index] = objective
        Task {
            do {
                try await useCases.upsertObjective.execute(objective)
            } catch {
                assertionFailure("Failed to unarchive objective: \(error)")
            }
        }
    }
}

extension SessionTrackerViewModel: ActionTracking, PageTracking {
    var pageViewEvent: TrackablePageEvent {
        TrackingEvent.SessionTracker.Page()
    }
}
