import ActivityKit
import SwiftUI
import WidgetKit

struct SessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionLiveActivityAttributes.self) { context in
            SessionLiveActivityLockScreenView(state: context.state)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    SessionLiveActivityExpandedView(state: context.state)
                }
            } compactLeading: {
                SessionLiveActivityElapsedLabel(state: context.state)
            } compactTrailing: {
                Image(systemName: "timer")
                    .foregroundStyle(.white)
            } minimal: {
                SessionLiveActivityElapsedLabel(state: context.state)
            }
            .keylineTint(.white)
        }

    }
}

private struct SessionLiveActivityLockScreenView: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        SessionLiveActivityCard(state: state)
    }
}

private struct SessionLiveActivityExpandedView: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        SessionLiveActivityCard(state: state)
    }
}

private struct SessionLiveActivityCard: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(state.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                LiveActivityTimerLabel(timerRange: state.timerRange, countsDown: state.countsDown)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                if let detail = state.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }
            .multilineTextAlignment(.center)
        }
        .padding(.vertical, 16)
    }
}

private struct SessionLiveActivityElapsedLabel: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        LiveActivityTimerLabel(timerRange: state.timerRange, countsDown: state.countsDown)
            .foregroundStyle(.white)
    }
}

private struct LiveActivityTimerLabel: View {
    let timerRange: ClosedRange<Date>
    let countsDown: Bool

    var body: some View {
        Text(timerInterval: timerRange, countsDown: countsDown)
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

#Preview("Live Activity", as: .content, using: SessionLiveActivityAttributes(startDate: .now)) {
    SessionLiveActivityWidget()
} contentStates: {
    SessionLiveActivityAttributes.ContentState(
        timerRange: Date.now.addingTimeInterval(-90)...Date.now.addingTimeInterval(60),
        countsDown: true,
        title: "Focus",
        detail: "Pomodoro • 25m focus, 5m break"
    )
}
