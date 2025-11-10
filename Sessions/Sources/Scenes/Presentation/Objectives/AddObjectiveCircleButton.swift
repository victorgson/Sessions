import SwiftUI

struct AddObjectiveCircleButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.05))
                    Circle()
                        .stroke(
                            style: StrokeStyle(lineWidth: 2, dash: [6, 6])
                        )
                        .foregroundStyle(Color.primary.opacity(0.3))
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                .frame(width: 88, height: 88)

                Text("New Objective")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
            }
            .frame(width: 96)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Create Objective")
    }
}
