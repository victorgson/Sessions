import SwiftUI

struct SessionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Bindable var timerViewModel: SessionTimerViewModel
    let onStop: () -> Void

    init(timerViewModel: SessionTimerViewModel, onStop: @escaping () -> Void) {
        self.timerViewModel = timerViewModel
        self.onStop = onStop
    }

    var body: some View {
        ZStack {
            TimelinePalette.sessionGradient
                .ignoresSafeArea()

            VStack(spacing: 32) {
                TimelineView(.periodic(from: timerViewModel.activeSessionStartDate ?? .now, by: 1)) { timeline in
                    if let snapshot = timerViewModel.timerSnapshot(at: timeline.date) {
                        VStack(spacing: 12) {
                            Text(snapshot.title)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(Color.white.opacity(0.8))
                            Text(snapshot.valueText)
                                .font(.system(size: 64, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                            if let detail = snapshot.detailText {
                                Text(detail)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(Color.white.opacity(0.75))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    }
                }

                Button("End Session") {
                    let stopTime = Date()
                    onStop()
                    dismiss()
                    DispatchQueue.main.async {
                        timerViewModel.stopSession(now: stopTime)
                    }
                }
                .timelineStyle(.outline(.white))
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .ignoresSafeArea()
        .onDisappear {
            if timerViewModel.isTimerRunning {
                onStop()
            }
        }
    }

}
