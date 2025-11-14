#if canImport(ActivityKit)
import ActivityKit
import SwiftUI
import WidgetKit

struct SessionLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SessionLiveActivityAttributes.self) { context in
            SessionLiveActivityLockScreenView(state: context.state)
                .activityBackgroundTint(.clear)
                .activitySystemActionForegroundColor(.white)
//                .contentMarginsDisabled()
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) {
                    SessionLiveActivityExpandedView(state: context.state)
                }
            } compactLeading: {
                SessionLiveActivityElapsedLabel(state: context.state)
                    .font(.system(.title3, design: .rounded))
                    .fontWeight(.semibold)
            } compactTrailing: {
                Image(systemName: "timer")
                    .foregroundStyle(.white)
            } minimal: {
                SessionLiveActivityElapsedLabel(state: context.state)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
            }
        }
    }
}

private struct SessionLiveActivityLockScreenView: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        SessionLiveActivityCard(state: state)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

private struct SessionLiveActivityExpandedView: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        SessionLiveActivityCard(state: state)
            .padding(.horizontal)
            .padding(.vertical, 12)
    }
}

private struct SessionLiveActivityCard: View {
    let state: SessionLiveActivityAttributes.ContentState

    var body: some View {
        VStack(spacing: 20) {
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
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TimelinePalette.sessionGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.12), radius: 16, x: 0, y: 8)
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
#endif
