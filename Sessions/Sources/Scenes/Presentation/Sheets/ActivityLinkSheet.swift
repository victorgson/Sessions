import SwiftUI
import Observation

struct ActivityLinkSheet: View {
    @Bindable private var coordinator: ActivityLinkSheetCoordinator
    @State private var viewModel: ActivityLinkSheetViewModel
    private let sessionDuration: TimeInterval

    init(viewModel: ActivityLinkSheetCoordinator) {
        guard let draft = viewModel.draft else {
            preconditionFailure("ActivityLinkSheet requires an active draft")
        }
        self.coordinator = viewModel
        self.sessionDuration = draft.duration
        _viewModel = State(initialValue: ActivityLinkSheetViewModel(draft: draft))
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        let selectedObjective = coordinator.objective(withID: bindableViewModel.selectedObjectiveID)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    SheetCardContainer(title: "Linked Objective") {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Objective")
                                .sheetCardLabelStyle()
                            Picker(selection: $bindableViewModel.selectedObjectiveID) {
                                Text("None")
                                    .tag(UUID?.none)
                                ForEach(coordinator.objectives) { objective in
                                    Text(displayName(for: objective))
                                        .tag(UUID?.some(objective.id))
                                }
                            } label: {
                                objectivePickerLabel(for: selectedObjective)
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    if let selectedObjective {
                        keyResultsSection(for: selectedObjective)
                    }

                    SheetCardContainer(title: "Notes") {
                        TextField("Reflection", text: $bindableViewModel.note, axis: .vertical)
                            .textFieldStyle(.plain)
                            .sheetInputFieldBackground()
                            .lineLimit(3, reservesSpace: true)
                    }

                    SheetCardContainer(title: "Tags") {
                        TextField("Comma separated", text: $bindableViewModel.tagsText)
                            .textFieldStyle(.plain)
                            .textInputAutocapitalization(.never)
                            .sheetInputFieldBackground()
                    }

                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle("Link Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        coordinator.discardDraft()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        coordinator.saveDraft()
                    }
                }
            }
        }
        .onChange(of: viewModel.selectedObjectiveID) { _, newValue in
            let quantityDefaults = coordinator.selectObjective(newValue)
            viewModel.updateQuantityValues(quantityDefaults)
        }
        .onChange(of: viewModel.note) { _, newValue in
            coordinator.updateNote(newValue)
        }
        .onChange(of: viewModel.tagsText) { _, newValue in
            coordinator.updateTags(newValue)
        }
    }

    private func keyResultsSection(for objective: Objective) -> some View {
        SheetCardContainer(title: "Key Results") {
            if objective.keyResults.isEmpty {
                Text("No key results configured yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    ForEach(Array(objective.keyResults.enumerated()), id: \.element.id) { index, keyResult in
                        keyResultContent(for: keyResult)
                        if index < objective.keyResults.count - 1 {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    private func keyResultContent(for keyResult: KeyResult) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(keyResult.title)
                .font(.headline)
                .foregroundStyle(.primary)

            if let timeMetric = keyResult.timeMetric {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Time")
                        .sheetCardLabelStyle()
                    Text(timeDescription(for: timeMetric))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(sessionTimeDescription(for: timeMetric))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if let quantityMetric = keyResult.quantityMetric {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Quantity")
                            .sheetCardLabelStyle()
                        Spacer()
                        Text(quantityValueDescription(for: keyResult))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { viewModel.quantityValues[keyResult.id] ?? round(quantityMetric.current) },
                            set: { newValue in
                                let roundedValue = round(newValue)
                                viewModel.setQuantityValue(roundedValue, for: keyResult.id)
                                coordinator.setQuantity(roundedValue, for: keyResult.id)
                            }
                        ),
                        in: 0...sliderUpperBound(for: keyResult, metric: quantityMetric),
                        step: 1
                    )

                    Text(quantityUnitDescription(for: quantityMetric))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func objectivePickerLabel(for objective: Objective?) -> some View {
        HStack {
            Text(displayName(for: objective))
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .sheetInputFieldBackground()
    }

    private func displayName(for objective: Objective?) -> String {
        guard let objective else { return "None" }
        if objective.isArchived {
            return "\(objective.title) (Completed)"
        }
        return objective.title
    }

    private func timeDescription(for metric: KeyResult.TimeMetric) -> String {
        let logged = formatted(value: metric.logged)
        let target = formatted(value: metric.target)
        return "\(logged) / \(target) \(metric.unit.displayName.lowercased())"
    }

    private func sessionTimeDescription(for metric: KeyResult.TimeMetric) -> String {
        let sessionValue = metric.unit.value(from: sessionDuration)
        let formattedSession = formatted(value: sessionValue)
        return "This session: \(formattedSession) \(metric.unit.displayName.lowercased())"
    }

    private func quantityValueDescription(for keyResult: KeyResult) -> String {
        guard let quantity = keyResult.quantityMetric else { return "" }
        let value = viewModel.quantityValues[keyResult.id] ?? round(quantity.current)
        let formattedValue = formatted(value: value)
        let formattedTarget = formatted(value: quantity.target)
        return "\(formattedValue) / \(formattedTarget) \(quantity.unit)"
    }

    private func quantityUnitDescription(for metric: KeyResult.QuantityMetric) -> String {
        "Drag to update in \(metric.unit)"
    }

    private func sliderUpperBound(for keyResult: KeyResult, metric: KeyResult.QuantityMetric) -> Double {
        let currentValue = viewModel.quantityValues[keyResult.id] ?? round(metric.current)
        if metric.target <= 0 {
            return max(currentValue, 1)
        }
        return max(metric.target, currentValue)
    }

    private func formatted(value: Double) -> String {
        if value == floor(value) {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
