import Foundation

@MainActor
extension SessionTrackerViewModel {
    func handleObjectiveSubmission(_ submission: ObjectiveFormSubmission) {
        Task { await handleObjectiveSubmissionAsync(submission) }
    }

    func deleteObjective(withID id: UUID) {
        guard let index = objectives.firstIndex(where: { $0.id == id }) else { return }
        objectives.remove(at: index)

        for activityIndex in activities.indices {
            guard activities[activityIndex].linkedObjectiveID == id else { continue }
            activities[activityIndex].linkedObjectiveID = nil
            activities[activityIndex].keyResultAllocations.removeAll()
        }

        if var draft = activityDraft, draft.selectedObjectiveID == id {
            draft.selectedObjectiveID = nil
            draft.selectedTimeAllocations = [:]
            draft.quantityValues = [:]
            activityDraft = draft
        }

        Task { await deleteObjectiveAsync(id: id) }
        hapticBox.triggerNotification(DefaultHapticBox.Notification.warning)
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
}

private extension SessionTrackerViewModel {
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
            activities = try await loadActivitiesUseCase.execute()
        } catch {
            assertionFailure("Failed to delete objective: \(error)")
        }
    }
}
