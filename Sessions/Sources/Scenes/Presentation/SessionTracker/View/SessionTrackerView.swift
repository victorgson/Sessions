import SwiftUI
import Observation
import Tracking

struct SessionTrackerView: View {
    @State private var viewModel: SessionTrackerViewModel
    private let calendar = Calendar.current
    @State private var objectiveSheetViewModel: AddObjectiveSheetViewModel?
    @State private var isShowingArchivedObjectives = false
    @State private var showFullScreenTimer = false
    @State private var isShowingSettings = false
    init(viewModel: SessionTrackerViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel

        NavigationStack {
            List {

                Section {
                    objectivesSection(viewModel: bindableViewModel)
                        .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }
                .textCase(nil)
                .listSectionSeparator(.hidden)

                Section {
                SessionTimerView(viewModel: bindableViewModel) {
                    bindableViewModel.startSession()
                    showFullScreenTimer = true
                    bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showFullScreenTimer))
                }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if bindableViewModel.isTimerRunning {
                            showFullScreenTimer = true
                            bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showFullScreenTimer))
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20))
                    .listRowBackground(Color.clear)
                }
                .textCase(nil)
                .listSectionSeparator(.hidden)

                ActivityFeedView(
                    sections: activitySections(for: bindableViewModel),
                    emptyStateMessage: "No sessions logged yet.",
                    titleProvider: { activity in
                        bindableViewModel.label(for: activity, calendar: calendar)
                    },
                    durationFormatter: { duration in
                        bindableViewModel.formattedDuration(duration)
                    },
                    colorProvider: { activity in
                        guard let hex = bindableViewModel.colorHex(for: activity.linkedObjectiveID) else { return nil }
                        return Color(hex: hex)
                    },
                    onSelect: { activity in
                        bindableViewModel.editActivity(activity)
                    },
                    onDelete: { activity in
                        bindableViewModel.deleteActivity(activity)
                    }
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Sessions")
            .navigationDestination(isPresented: $showFullScreenTimer) {
                SessionDetailView(
                    viewModel: bindableViewModel,
                    onStop: {
                        showFullScreenTimer = false
                    }
                )
                .toolbarBackground(.hidden, for: .navigationBar)
                .statusBarHidden(true)
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    NavigationLink {
                        InsightsView(viewModel: bindableViewModel)
                    } label: {
                        Label("Insights", systemImage: "chart.bar.fill")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Insights")
                    .simultaneousGesture(TapGesture().onEnded {
                        bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .openInsights))
                    })

                    Button {
                        isShowingSettings = true
                        bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .openSettings))
                    } label: {
                        Label("Settings", systemImage: "gearshape")
                            .labelStyle(.iconOnly)
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .paywallIfNeeded()
        .onAppear {
            viewModel.trackPageView()
        }
        .sheet(isPresented: $isShowingSettings) {
            SettingsView()
        }
        .sheet(isPresented: Binding(
            get: { bindableViewModel.activityDraft != nil },
            set: { newValue in
                if !newValue {
                    bindableViewModel.saveDraft()
                }
            }
        )) {
            if let draft = bindableViewModel.activityDraft {
                ActivityLinkSheet(
                    objectives: bindableViewModel.activeObjectives,
                    draft: draft,
                    onSelectObjective: { objectiveID in
                        bindableViewModel.setDraftObjective(objectiveID)
                        return bindableViewModel.activityDraft?.quantityValues ?? [:]
                    },
                    onSetQuantity: { keyResultID, value in
                        bindableViewModel.setDraftQuantityValue(value, for: keyResultID)
                    },
                    onChangeNote: { bindableViewModel.setDraftNote($0) },
                    onChangeTags: { bindableViewModel.setDraftTags($0) },
                    onSave: { bindableViewModel.saveDraft() },
                    onDiscard: { bindableViewModel.discardDraft() }
                )
                .presentationDetents([.medium, .large])
            }
        }
        .sheet(item: $objectiveSheetViewModel) { sheetViewModel in
            AddObjectiveSheet(viewModel: sheetViewModel) { submission in
                bindableViewModel.handleObjectiveSubmission(submission)
                objectiveSheetViewModel = nil
            } onCancel: {
                objectiveSheetViewModel = nil
            } onArchive: {
                if let id = sheetViewModel.objectiveID {
                    bindableViewModel.archiveObjective(withID: id)
                }
                objectiveSheetViewModel = nil
            } onUnarchive: {
                if let id = sheetViewModel.objectiveID {
                    bindableViewModel.unarchiveObjective(withID: id)
                }
                objectiveSheetViewModel = nil
            } onDelete: {
                if let id = sheetViewModel.objectiveID {
                    bindableViewModel.deleteObjective(withID: id)
                }
                objectiveSheetViewModel = nil
            }
        }
        .sheet(isPresented: $isShowingArchivedObjectives) {
            ArchivedObjectivesView(
                objectives: bindableViewModel.archivedObjectives,
                onClose: {
                    isShowingArchivedObjectives = false
                },
                onSelect: { objective in
                    isShowingArchivedObjectives = false
                    bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .editObjective(id: objective.id)))
                    objectiveSheetViewModel = AddObjectiveSheetViewModel(
                        mode: .edit(objective),
                        defaultColor: ObjectiveColorProvider.color(for: objective)
                    )
                }
            )
        }
        .onChange(of: bindableViewModel.isTimerRunning) { _, running in
            if !running {
                showFullScreenTimer = false
            }
        }
    }

    private func objectivesSection(viewModel: SessionTrackerViewModel) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Objectives")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if viewModel.hasArchivedObjectives {
                    Button {
                        viewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showArchivedObjectives))
                        isShowingArchivedObjectives = true
                    } label: {
                        Label("Archived", systemImage: "archivebox")
                            .labelStyle(TrailingIconLabelStyle())
                    }
                    .timelineStyle(
                        .outline(.accentColor),
                        size: .medium,
                        layout: .wrap
                    )
                    .padding(.trailing, 4)
                }
            }
            .padding(.horizontal, 20)
            if viewModel.activeObjectives.isEmpty {
                AddObjectiveCircleButton {
                    viewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showAddObjective(.emptyState)))
                    objectiveSheetViewModel = AddObjectiveSheetViewModel()
                }
                .padding(.horizontal, 20)
            } else {
                ObjectiveCardView(
                    objectives: viewModel.activeObjectives,
                    onAddObjective: {
                        viewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showAddObjective(.activeObjectives)))
                        objectiveSheetViewModel = AddObjectiveSheetViewModel()
                    },
                    onSelectObjective: { objective in
                        viewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .editObjective(id: objective.id)))
                        objectiveSheetViewModel = AddObjectiveSheetViewModel(
                            mode: .edit(objective),
                            defaultColor: ObjectiveColorProvider.color(for: objective)
                        )
                    }
                )
            }
        }
    }

    private func activitySections(for viewModel: SessionTrackerViewModel) -> [ActivityFeedSection] {
        guard !viewModel.activities.isEmpty else { return [] }

        let grouped = Dictionary(grouping: viewModel.activities) { activity -> Date in
            calendar.startOfDay(for: activity.date)
        }

        let sortedDays = grouped.keys.sorted(by: >)
        return sortedDays.compactMap { day in
            guard let activities = grouped[day]?.sorted(by: { $0.date > $1.date }) else { return nil }
            let title = title(for: day)
            return ActivityFeedSection(id: day, title: title, activities: activities)
        }
    }

    private func title(for day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: day)
    }
}

private struct TrailingIconLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.title
            configuration.icon
        }
    }
}
