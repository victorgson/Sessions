import Observation
import SwiftUI
import UIKit

struct AddObjectiveSheet: View {
    @Bindable private var viewModel: AddObjectiveSheetViewModel
    let onSave: (ObjectiveFormSubmission) -> Void
    let onCancel: () -> Void
    let onArchive: (() -> Void)?
    let onUnarchive: (() -> Void)?
    let onDelete: (() -> Void)?

    init(
        viewModel: AddObjectiveSheetViewModel = AddObjectiveSheetViewModel(),
        onSave: @escaping (ObjectiveFormSubmission) -> Void,
        onCancel: @escaping () -> Void,
        onArchive: (() -> Void)? = nil,
        onUnarchive: (() -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onSave = onSave
        self.onCancel = onCancel
        self.onArchive = onArchive
        self.onUnarchive = onUnarchive
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if viewModel.isEditing, viewModel.isCompleted || viewModel.isArchived {
                        SheetCardContainer {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(
                                        systemName: viewModel.isArchived ? "archivebox.fill" : "checkmark.circle.fill"
                                    )
                                        .font(.system(size: 28))
                                        .foregroundStyle(Color.accentColor)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(viewModel.isArchived ? "Objective Archived" : "Objective Completed")
                                            .font(.headline)
                                            .foregroundStyle(.primary)
                                        if viewModel.isArchived, let archivedText = viewModel.archivedDateText {
                                            Text("Archived on \(archivedText)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        } else if let completedText = viewModel.completedDateText {
                                            Text("Completed on \(completedText)")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }

                                if viewModel.canArchive {
                                    Button {
                                        onArchive?()
                                    } label: {
                                        Label("Move to Archive", systemImage: "archivebox.fill")
                                    }
                                    .timelineStyle(.secondary, size: .medium)
                                }

                                if viewModel.canRestore {
                                    Button {
                                        onUnarchive?()
                                    } label: {
                                        Label("Restore Objective", systemImage: "arrow.uturn.backward.circle.fill")
                                    }
                                    .timelineStyle(.secondary, size: .medium)
                                }
                            }
                        }
                    }

                    SheetCardContainer(title: "Objective") {
                        VStack(alignment: .leading, spacing: 20) {
                            SheetLabeledTextField(
                                title: "Title",
                                placeholder: "Ship the quarterly roadmap",
                                text: $viewModel.title,
                                axis: .vertical,
                                autocapitalization: .words
                            )

                            VStack(alignment: .leading, spacing: 16) {
                                Text("End Date")
                                    .sheetCardLabelStyle()

                                Picker("End Date", selection: $viewModel.endDatePreset) {
                                    ForEach(AddObjectiveSheetViewModel.EndDatePreset.allCases) { preset in
                                        Text(preset.displayName).tag(preset)
                                    }
                                }
                                .pickerStyle(.segmented)

                                Text("Pick a timeline preset and adjust the exact due date if needed.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if viewModel.endDatePreset != .none {
                                    DatePicker(
                                        "Objective End Date",
                                        selection: $viewModel.endDate,
                                        displayedComponents: [.date]
                                    )
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                }
                            }
                        }
                    }

                    SheetCardContainer(title: "Appearance") {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Color")
                                    .sheetCardLabelStyle()
                                Text("Choose a tint for this objective.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            ColorPicker("Objective Color", selection: $viewModel.color, supportsOpacity: false)
                                .labelsHidden()
                                .frame(width: 48, height: 48)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .stroke(Color(uiColor: .separator).opacity(0.4), lineWidth: 1)
                                )
                        }
                        .padding(.vertical, 4)
                    }

                    ForEach(viewModel.keyResults) { keyResult in
                        AddObjectiveSheet.KeyResultCard(
                            title: viewModel.sectionTitle(forKeyResult: keyResult.id),
                            keyResult: Binding(
                                get: {
                                    viewModel.keyResults.first(where: { $0.id == keyResult.id }) ?? keyResult
                                },
                                set: { newValue in
                                    viewModel.updateKeyResult(newValue)
                                }
                            ),
                            canRemove: viewModel.keyResults.count > 1,
                            onRemove: { viewModel.removeKeyResult(id: keyResult.id) }
                        )
                    }

                    Button {
                        viewModel.addKeyResult()
                    } label: {
                        Label("Add Key Result", systemImage: "plus.circle.fill")
                    }
                    .timelineStyle(.primary)
                    .padding(.top, 8)

                    if viewModel.isEditing, onDelete != nil {
                        Button(role: .destructive) {
                            onDelete?()
                        } label: {
                            Text("Delete Objective")
                        }
                        .timelineStyle(.destructive)
                        .padding(.top, 16)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .navigationTitle(viewModel.isEditing ? "Edit Objective" : "New Objective")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(viewModel.makeSubmission())
                    }
                    .disabled(viewModel.isSaveDisabled)
                }
            }
        }
    }
}
