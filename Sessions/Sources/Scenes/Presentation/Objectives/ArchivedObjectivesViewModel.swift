import Observation

@MainActor
@Observable
final class ArchivedObjectivesViewModel {
    private let objectivesViewModel: ObjectivesOverviewViewModel

    init(objectivesViewModel: ObjectivesOverviewViewModel) {
        self.objectivesViewModel = objectivesViewModel
    }

    var objectives: [Objective] {
        objectivesViewModel.archivedObjectives
    }
}
