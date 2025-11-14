import Foundation

struct InsightsViewModel {
    let activities: [Activity]
    let objectives: [Objective]
    private let durationFormatter: (TimeInterval) -> String

    init(
        activities: [Activity],
        objectives: [Objective],
        durationFormatter: @escaping (TimeInterval) -> String
    ) {
        self.activities = activities
        self.objectives = objectives
        self.durationFormatter = durationFormatter
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        durationFormatter(duration)
    }
}
