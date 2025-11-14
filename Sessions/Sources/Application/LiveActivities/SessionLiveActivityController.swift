import Foundation

protocol SessionLiveActivityControlling: AnyObject {
    func startLiveActivity(startDate: Date, state: SessionLiveActivityDisplayState) async
    func updateLiveActivity(with state: SessionLiveActivityDisplayState) async
    func endLiveActivity() async
}

import ActivityKit

@available(iOS 16.1, *)
final class DefaultSessionLiveActivityController: SessionLiveActivityControlling {
    private typealias SessionActivity = ActivityKit.Activity<SessionLiveActivityAttributes>

    private var currentActivity: SessionActivity?
    private var lastState: SessionLiveActivityDisplayState?

    init() {
        currentActivity = SessionActivity.activities.first
    }

    func startLiveActivity(startDate: Date, state: SessionLiveActivityDisplayState) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        await endLiveActivity()
        await endDanglingActivities()

        let attributes = SessionLiveActivityAttributes(startDate: startDate)
        lastState = state
        let content = ActivityContent(state: contentState(from: state), staleDate: nil)

        do {
            currentActivity = try SessionActivity.request(attributes: attributes, content: content)
        } catch {
            debugPrint("Failed to start session Live Activity: \(error)")
        }
    }

    func updateLiveActivity(with state: SessionLiveActivityDisplayState) async {
        guard let activity = currentActivity else { return }
        lastState = state
        let content = ActivityContent(state: contentState(from: state), staleDate: nil)
        await activity.update(content)
    }

    func endLiveActivity() async {
        guard let activity = currentActivity else { return }
        let timerRange = activity.attributes.startDate...Date()
        let finalState = SessionLiveActivityDisplayState(
            timerRange: timerRange,
            countsDown: false,
            title: lastState?.title ?? "Session",
            detail: lastState?.detail
        )
        let content = ActivityContent(state: contentState(from: finalState), staleDate: nil)
        await activity.end(content, dismissalPolicy: .immediate)
        currentActivity = nil
        lastState = nil
    }

    private func endDanglingActivities() async {
        let activeActivities = SessionActivity.activities
        for activity in activeActivities where activity.id != currentActivity?.id {
            let timerRange = activity.attributes.startDate...Date()
            let fallbackState = SessionLiveActivityDisplayState(
                timerRange: timerRange,
                countsDown: false,
                title: "Session",
                detail: nil
            )
            let content = ActivityContent(state: contentState(from: fallbackState), staleDate: nil)
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }

    private func contentState(
        from state: SessionLiveActivityDisplayState
    ) -> SessionLiveActivityAttributes.ContentState {
        SessionLiveActivityAttributes.ContentState(
            timerRange: state.timerRange,
            countsDown: state.countsDown,
            title: state.title,
            detail: state.detail
        )
    }
}
