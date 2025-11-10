import SwiftUI

struct ObjectiveRingView: View {
    let objective: Objective
    let onTap: (() -> Void)?
    private let ringLineWidth: Double = 11

    init(objective: Objective, onTap: (() -> Void)? = nil) {
        self.objective = objective
        self.onTap = onTap
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                    .foregroundStyle(Color.primary.opacity(0.12))
                Circle()
                    .trim(from: 0, to: CGFloat(progress))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color.opacity(0.85), color]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)

                VStack(spacing: 2) {
                    Text(percentageText)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.primary)
                    Text("Complete")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 88, height: 88)

            Text(objective.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 96)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap?()
        }
    }

    private var progress: Double {
        min(max(objective.progress, 0), 1)
    }

    private var percentageText: String {
        "\(Int(progress * 100))%"
    }

    private var color: Color {
        ObjectiveColorProvider.color(for: objective)
    }

}
