import Observation
import Foundation

@MainActor
@Observable
final class ActivityLinkSheetCoordinator {
    private unowned let sessionTrackerViewModel: SessionTrackerViewModel

    init(sessionTrackerViewModel: SessionTrackerViewModel) {
        self.sessionTrackerViewModel = sessionTrackerViewModel
    }

    var draft: SessionTrackerViewModel.ActivityDraft? {
        sessionTrackerViewModel.activityDraft
    }

    var objectives: [Objective] {
        var objectives = sessionTrackerViewModel.objectivesViewModel.activeObjectives
        if let selectedID = draft?.selectedObjectiveID,
           let selectedObjective = sessionTrackerViewModel.objectivesViewModel.objective(withID: selectedID),
           !objectives.contains(where: { $0.id == selectedID }) {
            objectives.append(selectedObjective)
        }
        return objectives
    }

    func objective(withID id: UUID?) -> Objective? {
        guard let id else { return nil }
        return sessionTrackerViewModel.objectivesViewModel.objective(withID: id)
    }

    func selectObjective(_ objectiveID: UUID?) -> [UUID: Double] {
        sessionTrackerViewModel.setDraftObjective(objectiveID)
        return sessionTrackerViewModel.activityDraft?.quantityValues ?? [:]
    }

    func setQuantity(_ value: Double, for keyResultID: UUID) {
        sessionTrackerViewModel.setDraftQuantityValue(value, for: keyResultID)
    }

    func updateNote(_ note: String) {
        sessionTrackerViewModel.setDraftNote(note)
    }

    func updateTags(_ tags: String) {
        sessionTrackerViewModel.setDraftTags(tags)
    }

    func saveDraft() {
        sessionTrackerViewModel.saveDraft()
    }

    func discardDraft() {
        sessionTrackerViewModel.discardDraft()
    }
}
