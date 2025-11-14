import SwiftUI

struct ArchivedObjectivesView: View {
    @Bindable private var viewModel: ArchivedObjectivesViewModel
    let onClose: () -> Void
    let onSelect: (Objective) -> Void

    init(viewModel: ArchivedObjectivesViewModel, onClose: @escaping () -> Void, onSelect: @escaping (Objective) -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.onSelect = onSelect
    }

    var body: some View {
        NavigationStack {
            List {
                if viewModel.objectives.isEmpty {
                    Text("No archived objectives yet.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 32)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.objectives) { objective in
                        Button {
                            onSelect(objective)
                        } label: {
                            archivedObjectiveRow(for: objective)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Archived Objectives")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close", action: onClose)
                }
            }
        }
    }

    private func archivedObjectiveRow(for objective: Objective) -> some View {
        HStack(spacing: 16) {
            Circle()
                .fill(ObjectiveColorProvider.color(for: objective))
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "archivebox.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text(objective.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                if let archivedAt = objective.archivedAt {
                    Text("Archived on \(Self.dateFormatter.string(from: archivedAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else if let completedAt = objective.completedAt {
                    Text("Completed on \(Self.dateFormatter.string(from: completedAt))")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(uiColor: .separator).opacity(0.2), lineWidth: 1)
        )
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
