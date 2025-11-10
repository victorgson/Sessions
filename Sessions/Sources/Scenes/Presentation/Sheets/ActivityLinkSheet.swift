import SwiftUI
import Observation

struct ActivityLinkSheet: View {
    let objectives: [Objective]
    let sessionDuration: TimeInterval
    @State private var viewModel: ActivityLinkSheetViewModel
    let onSelectObjective: (UUID?) -> [UUID: Double]
    let onSetQuantity: (UUID, Double) -> Void
    let onChangeNote: (String) -> Void
    let onChangeTags: (String) -> Void
    let onSave: () -> Void
    let onDiscard: () -> Void

    init(
        objectives: [Objective],
        draft: SessionTrackerViewModel.ActivityDraft,
        onSelectObjective: @escaping (UUID?) -> [UUID: Double],
        onSetQuantity: @escaping (UUID, Double) -> Void,
        onChangeNote: @escaping (String) -> Void,
        onChangeTags: @escaping (String) -> Void,
        onSave: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) {
        self.objectives = objectives
        self.sessionDuration = draft.duration
        _viewModel = State(initialValue: ActivityLinkSheetViewModel(draft: draft))
        self.onSelectObjective = onSelectObjective
        self.onSetQuantity = onSetQuantity
        self.onChangeNote = onChangeNote
        self.onChangeTags = onChangeTags
        self.onSave = onSave
        self.onDiscard = onDiscard
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        let selectedObjective = objective(for: bindableViewModel.selectedObjectiveID)

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
                                ForEach(objectives) { objective in
                                    Text(objective.title)
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

                    SheetCardContainer {
                        VStack(spacing: 12) {
                            Button {
                                onSave()
                            } label: {
                                Text("Save Session")
                            }
                            .timelineStyle(.primary)

                            Button(role: .destructive) {
                                onDiscard()
                            } label: {
                                Text("Discard")
                            }
                            .timelineStyle(.destructive)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .navigationTitle("Link Session")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: viewModel.selectedObjectiveID) { _, newValue in
            let quantityDefaults = onSelectObjective(newValue)
            viewModel.updateQuantityValues(quantityDefaults)
        }
        .onChange(of: viewModel.note) { _, newValue in
            onChangeNote(newValue)
        }
        .onChange(of: viewModel.tagsText) { _, newValue in
            onChangeTags(newValue)
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
                                onSetQuantity(keyResult.id, roundedValue)
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
            Text(objective?.title ?? "None")
                .foregroundStyle(.primary)
            Spacer()
            Image(systemName: "chevron.up.chevron.down")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .sheetInputFieldBackground()
    }

    private func objective(for id: UUID?) -> Objective? {
        guard let id else { return nil }
        return objectives.first(where: { $0.id == id })
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
