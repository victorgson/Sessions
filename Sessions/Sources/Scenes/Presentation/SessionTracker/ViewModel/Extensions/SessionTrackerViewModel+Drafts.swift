import Foundation
import Tracking

@MainActor
extension SessionTrackerViewModel {
    func saveDraft(now: Date = .now) {
        guard let draft = activityDraft else { return }
        trackAction(TrackingEvent.SessionTracker.Action(value: .saveActivityDraft(isEditing: draft.isEditing)))
        Task { await saveDraftAsync(draft: draft) }
    }

    func discardDraft() {
        guard let draft = activityDraft else { return }
        activityDraft = nil
        trackAction(TrackingEvent.SessionTracker.Action(value: .discardActivityDraft(isEditing: draft.isEditing)))
        hapticBox.triggerNotification(DefaultHapticBox.Notification.warning)
    }

    func setDraftObjective(_ objectiveID: UUID?) {
        guard var draft = activityDraft else { return }
        guard draft.selectedObjectiveID != objectiveID else { return }

        draft.selectedObjectiveID = objectiveID

        if let objectiveID, let objective = objectivesViewModel.objective(withID: objectiveID) {
            draft.selectedTimeAllocations = objectivesViewModel.defaultTimeAllocations(
                for: objective,
                duration: draft.duration
            )
            draft.quantityValues = objectivesViewModel.defaultQuantityValues(for: objective)
        } else {
            draft.selectedTimeAllocations = [:]
            draft.quantityValues = [:]
        }

        activityDraft = draft
    }

    func setDraftNote(_ note: String) {
        guard var draft = activityDraft else { return }
        draft.note = note
        activityDraft = draft
    }

    func setDraftTags(_ tags: String) {
        guard var draft = activityDraft else { return }
        draft.tagsText = tags
        activityDraft = draft
    }

    func setDraftQuantityValue(_ value: Double, for keyResultID: UUID) {
        guard var draft = activityDraft else { return }
        let clamped = max(0, value)
        let previous = draft.quantityValues[keyResultID]
        draft.quantityValues[keyResultID] = clamped
        activityDraft = draft

        if previous != clamped {
            hapticBox.triggerImpact(style: DefaultHapticBox.Impact.light)
        }
    }

    func quantityValue(for keyResultID: UUID) -> Double? {
        activityDraft?.quantityValues[keyResultID]
    }

    func isTimeKeyResultSelected(_ keyResultID: UUID) -> Bool {
        activityDraft?.selectedTimeAllocations[keyResultID] != nil
    }

    func editActivity(_ activity: Activity) {
        trackAction(
            TrackingEvent.SessionTracker.Action(value: .openActivityDraft(.edit))
        )
        var allocations: [UUID: TimeInterval] = [:]
        for allocation in activity.keyResultAllocations {
            allocations[allocation.keyResultID] = allocation.seconds
        }

        var quantityValues: [UUID: Double] = [:]
        if let objectiveID = activity.linkedObjectiveID,
           let objective = objectivesViewModel.objective(withID: objectiveID) {
            quantityValues = objectivesViewModel.defaultQuantityValues(for: objective)
        }

        activityDraft = ActivityDraft(
            originalActivity: activity,
            startedAt: activity.date,
            duration: activity.duration,
            selectedObjectiveID: activity.linkedObjectiveID,
            selectedTimeAllocations: allocations,
            quantityValues: quantityValues,
            note: activity.note ?? "",
            tagsText: activity.tags.joined(separator: ", ")
        )
    }

    func applyQuantityOverrides(_ overrides: [UUID: Double], to objectiveID: UUID) {
        objectivesViewModel.mutateObjective(withID: objectiveID) { objective in
            for (keyResultID, value) in overrides {
                guard let index = objective.keyResults.firstIndex(where: { $0.id == keyResultID }),
                      var quantity = objective.keyResults[index].quantityMetric else { continue }
                quantity.current = max(0, value)
                objective.keyResults[index].quantityMetric = quantity
            }
        }
    }

    func applyTimeAllocations(
        _ allocations: [KeyResultAllocation],
        to objectiveID: UUID,
        adding: Bool
    ) {
        guard !allocations.isEmpty else { return }
        objectivesViewModel.mutateObjective(withID: objectiveID) { objective in
            for allocation in allocations {
                guard let index = objective.keyResults.firstIndex(where: { $0.id == allocation.keyResultID }),
                      var timeMetric = objective.keyResults[index].timeMetric else { continue }

                let delta = timeMetric.unit.value(from: allocation.seconds)
                let adjusted = timeMetric.logged + (adding ? delta : -delta)
                timeMetric.logged = max(0, adjusted)
                objective.keyResults[index].timeMetric = timeMetric
            }
        }
    }
}

// MARK: - Draft Helpers

private extension SessionTrackerViewModel {
    func saveDraftAsync(draft: ActivityDraft) async {
        let tags = Self.tags(from: draft.tagsText)
        let note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        let allocations = draft.selectedTimeAllocations.map { key, seconds in
            KeyResultAllocation(keyResultID: key, seconds: seconds)
        }

        let activity = Activity(
            id: draft.originalActivity?.id ?? UUID(),
            date: draft.startedAt,
            duration: draft.duration,
            linkedObjectiveID: draft.selectedObjectiveID,
            note: note.isEmpty ? nil : note,
            tags: tags,
            keyResultAllocations: allocations
        )

        if let original = draft.originalActivity {
            await persistUpdatedActivity(activity, original: original, draft: draft)
        } else {
            await persistNewActivity(activity, draft: draft)
        }

        await recentSessionsViewModel.loadActivities()

        activityDraft = nil
        promptAppStoreRatingUseCase.execute(
            totalSessionsCompleted: activities.count,
            didCloseLinkSheet: true,
            isEditingDraft: draft.isEditing
        )
        hapticBox.triggerNotification(DefaultHapticBox.Notification.success)
    }

    static func tags(from text: String) -> [String] {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return trimmed
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    func persistUpdatedActivity(
        _ activity: Activity,
        original: Activity,
        draft: ActivityDraft
    ) async {
        do {
            try await updateActivityUseCase.execute(activity)
        } catch {
            assertionFailure("Failed to update activity: \(error)")
        }

        if let originalObjective = original.linkedObjectiveID {
            applyTimeAllocations(original.keyResultAllocations, to: originalObjective, adding: false)
        }

        if let newObjective = activity.linkedObjectiveID {
            applyTimeAllocations(activity.keyResultAllocations, to: newObjective, adding: true)
            applyQuantityOverrides(draft.quantityValues, to: newObjective)
        }
    }

    func persistNewActivity(_ activity: Activity, draft: ActivityDraft) async {
        do {
            try await recordActivityUseCase.execute(activity)
        } catch {
            assertionFailure("Failed to record activity: \(error)")
        }

        if let objectiveID = activity.linkedObjectiveID {
            applyTimeAllocations(activity.keyResultAllocations, to: objectiveID, adding: true)
            applyQuantityOverrides(draft.quantityValues, to: objectiveID)
        }
    }

}
