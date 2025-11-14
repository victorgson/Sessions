import Foundation
import Observation

@MainActor
@Observable
final class ObjectivesOverviewViewModel {
    typealias ObjectiveCleanupHandler = (UUID) -> Void
    typealias ActivitiesReloadHandler = () async -> Void

    private let loadObjectivesUseCase: any LoadObjectivesUseCase
    private let upsertObjectiveUseCase: any UpsertObjectiveUseCase
    private let createObjectiveUseCase: any CreateObjectiveUseCase
    private let removeObjectiveUseCase: any RemoveObjectiveUseCase
    private let hapticBox: HapticBox
    private let cleanupHandler: ObjectiveCleanupHandler
    private let reloadActivitiesHandler: ActivitiesReloadHandler

    var objectives: [Objective]

    init(
        loadObjectivesUseCase: any LoadObjectivesUseCase,
        upsertObjectiveUseCase: any UpsertObjectiveUseCase,
        createObjectiveUseCase: any CreateObjectiveUseCase,
        removeObjectiveUseCase: any RemoveObjectiveUseCase,
        hapticBox: HapticBox,
        cleanupHandler: @escaping ObjectiveCleanupHandler,
        reloadActivitiesHandler: @escaping ActivitiesReloadHandler
    ) {
        self.loadObjectivesUseCase = loadObjectivesUseCase
        self.upsertObjectiveUseCase = upsertObjectiveUseCase
        self.createObjectiveUseCase = createObjectiveUseCase
        self.removeObjectiveUseCase = removeObjectiveUseCase
        self.hapticBox = hapticBox
        self.cleanupHandler = cleanupHandler
        self.reloadActivitiesHandler = reloadActivitiesHandler
        self.objectives = []
    }

    var activeObjectives: [Objective] {
        objectives.filter { !$0.isArchived }
    }

    var archivedObjectives: [Objective] {
        objectives.filter { $0.isArchived }
    }

    var hasArchivedObjectives: Bool {
        !archivedObjectives.isEmpty
    }

    func loadObjectives() async {
        do {
            objectives = try await loadObjectivesUseCase.execute()
        } catch {
            assertionFailure("Failed to load objectives: \(error)")
            objectives = []
        }
    }

    func handleObjectiveSubmission(_ submission: ObjectiveFormSubmission) {
        Task { await handleObjectiveSubmissionAsync(submission) }
    }

    func deleteObjective(withID id: UUID) {
        guard let index = objectives.firstIndex(where: { $0.id == id }) else { return }
        objectives.remove(at: index)
        cleanupHandler(id)

        Task { await deleteObjectiveAsync(id: id) }
        hapticBox.triggerNotification(DefaultHapticBox.Notification.warning)
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
                try await upsertObjectiveUseCase.execute(objective)
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
                try await upsertObjectiveUseCase.execute(objective)
            } catch {
                assertionFailure("Failed to unarchive objective: \(error)")
            }
        }
    }

    func label(for activity: Activity, calendar: Calendar = .current) -> String {
        guard let objectiveID = activity.linkedObjectiveID,
              let objective = objectives.first(where: { $0.id == objectiveID }) else {
            return "Session"
        }
        return objective.title
    }

    func objective(withID id: UUID) -> Objective? {
        objectives.first(where: { $0.id == id })
    }

    func colorHex(for objectiveID: UUID?) -> String? {
        guard let id = objectiveID, let objective = objective(withID: id) else { return nil }
        return objective.colorHex
    }

    func defaultTimeAllocations(
        for objective: Objective,
        duration: TimeInterval
    ) -> [UUID: TimeInterval] {
        objective.keyResults.reduce(into: [UUID: TimeInterval]()) { partialResult, keyResult in
            guard keyResult.timeMetric != nil else { return }
            partialResult[keyResult.id] = duration
        }
    }

    func defaultQuantityValues(for objective: Objective) -> [UUID: Double] {
        objective.keyResults.reduce(into: [UUID: Double]()) { partialResult, keyResult in
            if let quantity = keyResult.quantityMetric {
                partialResult[keyResult.id] = quantity.current
            }
        }
    }

    func mutateObjective(withID id: UUID, mutation: (inout Objective) -> Void) {
        guard let index = objectives.firstIndex(where: { $0.id == id }) else { return }
        var objective = objectives[index]
        mutation(&objective)
        updateCompletionStatus(for: &objective)
        objectives[index] = objective
        Task {
            do {
                try await upsertObjectiveUseCase.execute(objective)
            } catch {
                assertionFailure("Failed to persist objective mutation: \(error)")
            }
        }
    }
}

// MARK: - Private helpers

@MainActor
private extension ObjectivesOverviewViewModel {
    func handleObjectiveSubmissionAsync(_ submission: ObjectiveFormSubmission) async {
        if let id = submission.id, let index = objectives.firstIndex(where: { $0.id == id }) {
            await updateObjective(at: index, with: submission)
        } else {
            await createObjective(from: submission)
        }
    }

    func updateObjective(at index: Int, with submission: ObjectiveFormSubmission) async {
        var updated = objectives[index]
        updated.title = submission.title
        updated.colorHex = submission.colorHex
        updated.endDate = submission.endDate
        updated.keyResults = submission.keyResults
        updateCompletionStatus(for: &updated)
        objectives[index] = updated

        do {
            try await upsertObjectiveUseCase.execute(updated)
        } catch {
            assertionFailure("Failed to update objective: \(error)")
        }
    }

    func createObjective(from submission: ObjectiveFormSubmission) async {
        do {
            _ = try await createObjectiveUseCase.execute(
                title: submission.title,
                colorHex: submission.colorHex,
                endDate: submission.endDate,
                keyResults: submission.keyResults
            )
            objectives = try await loadObjectivesUseCase.execute()
        } catch {
            assertionFailure("Failed to create objective: \(error)")
        }
    }

    func deleteObjectiveAsync(id: UUID) async {
        do {
            try await removeObjectiveUseCase.execute(id)
            objectives = try await loadObjectivesUseCase.execute()
            await reloadActivitiesHandler()
        } catch {
            assertionFailure("Failed to delete objective: \(error)")
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
}
