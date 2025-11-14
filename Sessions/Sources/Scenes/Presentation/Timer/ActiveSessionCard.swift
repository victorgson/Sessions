import SwiftUI

struct ActiveSessionCard: View {
    let display: SessionTimerSnapshot
    let stopAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text(display.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.white.opacity(0.8))
                Text(display.valueText)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                if let detail = display.detailText {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(Color.white.opacity(0.75))
                }
            }

            Button("End Session", action: stopAction)
                .timelineStyle(.outline(.white), layout: .wrap)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(TimelinePalette.sessionGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 16, x: 0, y: 8)
    }
}
