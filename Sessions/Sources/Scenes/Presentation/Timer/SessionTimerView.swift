import SwiftUI
import Observation

struct SessionTimerView: View {
    @Bindable var viewModel: SessionTimerViewModel
    let onStartSession: () -> Void
    let onConfigure: () -> Void

    init(
        viewModel: SessionTimerViewModel,
        onStartSession: @escaping () -> Void,
        onConfigure: @escaping () -> Void
    ) {
        self.viewModel = viewModel
        self.onStartSession = onStartSession
        self.onConfigure = onConfigure
    }

    var body: some View {
        if viewModel.isTimerRunning, let start = viewModel.activeSessionStartDate {
            TimelineView(.periodic(from: start, by: 1)) { timeline in
                if let snapshot = viewModel.timerSnapshot(at: timeline.date) {
                    ActiveSessionCard(
                        display: snapshot,
                        stopAction: { viewModel.stopSession(now: timeline.date) }
                    )
                }
            }
            .frame(maxWidth: .infinity)
        } else {
            InactiveSessionCard(
                action: onStartSession,
                configureAction: onConfigure,
                subtitle: viewModel.timerConfiguration.summaryText
            )
                .frame(maxWidth: .infinity)
        }
    }
}
