import Foundation

@MainActor
extension SessionTrackerViewModel {
    func loadInitialData() async {
        await objectivesViewModel.loadObjectives()

        await recentSessionsViewModel.loadActivities()
    }

    func deleteActivity(_ activity: Activity) {
        recentSessionsViewModel.deleteActivity(activity)
    }
}
