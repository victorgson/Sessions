import SwiftUI
import Observation
import Tracking

struct SessionTrackerView: View {
    @State private var viewModel: SessionTrackerViewModel
    private let coordinator: AppCoordinator
    private let sessionCoordinator: SessionTrackerCoordinator
    private let calendar = Calendar.current
    init(
        viewModel: SessionTrackerViewModel,
        coordinator: AppCoordinator,
        sessionCoordinator: SessionTrackerCoordinator
    ) {
        _viewModel = State(initialValue: viewModel)
        self.coordinator = coordinator
        self.sessionCoordinator = sessionCoordinator
    }

    var body: some View {
        @Bindable var bindableViewModel = viewModel
        @Bindable var objectivesViewModel = bindableViewModel.objectivesViewModel
        @Bindable var timerViewModel = bindableViewModel.timerViewModel
        @Bindable var recentSessionsViewModel = bindableViewModel.recentSessionsViewModel

        List {
            ForEach(bindableViewModel.homeSections) { section in
                sectionView(
                    section: section,
                    baseViewModel: bindableViewModel
                )
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sessions")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    coordinator.push(.insights)
                    bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .openInsights))
                } label: {
                    Label("Insights", systemImage: "chart.bar.fill")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Insights")

                Button {
                    sessionCoordinator.present(.settings)
                    bindableViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .openSettings))
                } label: {
                    Label("Settings", systemImage: "gearshape")
                        .labelStyle(.iconOnly)
                }
                .accessibilityLabel("Settings")
            }
        }
        .paywallIfNeeded(
            shouldPresent: bindableViewModel.shouldPresentInitialPaywall,
            onPurchaseCompleted: { _ in refreshSubscriptionStatus() },
            onRestoreCompleted: { _ in refreshSubscriptionStatus() }
        )
        .onAppear {
            bindableViewModel.markInitialPaywallPresentedIfNeeded()
            bindableViewModel.trackPageView()
            if bindableViewModel.activityDraft != nil {
                sessionCoordinator.present(.activityLinkDraft)
            }
        }
        .onChange(of: timerViewModel.isTimerRunning) { _, running in
            if !running {
                coordinator.pop(.sessionDetail)
            }
        }
        .onChange(of: bindableViewModel.activityDraft != nil) { _, hasDraft in
            if hasDraft {
                sessionCoordinator.present(.activityLinkDraft)
            } else {
                sessionCoordinator.dismiss(.activityLink)
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func objectivesSection(
        viewModel: SessionTrackerViewModel,
        objectivesViewModel: ObjectivesOverviewViewModel
    ) -> some View {
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Objectives")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
                if objectivesViewModel.hasArchivedObjectives {
                    Button {
                        viewModel.trackAction(
                            TrackingEvent.SessionTracker.Action(value: .showArchivedObjectives)
                        )
                        sessionCoordinator.present(.archivedObjectives)
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
            if objectivesViewModel.activeObjectives.isEmpty {
                AddObjectiveCircleButton {
                    viewModel.trackAction(
                        TrackingEvent.SessionTracker.Action(value: .showAddObjective(.emptyState))
                    )
                    sessionCoordinator.present(.addObjective(AddObjectiveSheetViewModel()))
                }
                .padding(.horizontal, 20)
            } else {
                ObjectiveCardView(
                    objectives: objectivesViewModel.activeObjectives,
                    onAddObjective: {
                        viewModel.trackAction(
                            TrackingEvent.SessionTracker.Action(value: .showAddObjective(.activeObjectives))
                        )
                        sessionCoordinator.present(.addObjective(AddObjectiveSheetViewModel()))
                    },
                    onSelectObjective: { objective in
                        viewModel.trackAction(
                            TrackingEvent.SessionTracker.Action(value: .editObjective(id: objective.id))
                        )
                        sessionCoordinator.present(.addObjective(AddObjectiveSheetViewModel(
                            mode: .edit(objective),
                            defaultColor: ObjectiveColorProvider.color(for: objective)
                        )))
                    }
                )
            }
        }
    }

    private func activitySections(for viewModel: RecentSessionsViewModel) -> [ActivityFeedSection] {
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

    private func refreshSubscriptionStatus() {
        Task {
            await viewModel.subscriptionStatusProvider.refreshStatus()
        }
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

@MainActor
private extension SessionTrackerView {
    @ViewBuilder
    func sectionView(
        section: SessionTrackerViewModel.HomeSection,
        baseViewModel: SessionTrackerViewModel
    ) -> some View {
        switch section {
        case .objectives(let viewModel):
            objectivesSectionView(
                viewModel: baseViewModel,
                objectivesViewModel: viewModel
            )

        case .timer(let viewModel):
            timerSectionView(
                baseViewModel: baseViewModel,
                timerViewModel: viewModel
            )

        case .activityFeed(let viewModel):
            activityFeedSectionView(
                baseViewModel: baseViewModel,
                objectivesViewModel: baseViewModel.objectivesViewModel,
                recentSessionsViewModel: viewModel
            )
        }
    }

    @ViewBuilder
    func objectivesSectionView(
        viewModel: SessionTrackerViewModel,
        objectivesViewModel: ObjectivesOverviewViewModel
    ) -> some View {
        Section {
            objectivesSection(viewModel: viewModel, objectivesViewModel: objectivesViewModel)
                .listRowInsets(EdgeInsets(top: 24, leading: 0, bottom: 8, trailing: 0))
                .listRowBackground(Color.clear)
        }
        .textCase(nil)
        .listSectionSeparator(.hidden)
    }

    @ViewBuilder
    func timerSectionView(
        baseViewModel: SessionTrackerViewModel,
        timerViewModel: SessionTimerViewModel
    ) -> some View {
        Section {
            SessionTimerView(viewModel: timerViewModel) {
                timerViewModel.startSession()
                coordinator.push(.sessionDetail)
                baseViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showFullScreenTimer))
            } onConfigure: {
                sessionCoordinator.present(.timerConfiguration)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if timerViewModel.isTimerRunning {
                    coordinator.push(.sessionDetail)
                    baseViewModel.trackAction(TrackingEvent.SessionTracker.Action(value: .showFullScreenTimer))
                }
            }
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 24, trailing: 20))
            .listRowBackground(Color.clear)
        }
        .textCase(nil)
        .listSectionSeparator(.hidden)
    }

    @ViewBuilder
    func activityFeedSectionView(
        baseViewModel: SessionTrackerViewModel,
        objectivesViewModel: ObjectivesOverviewViewModel,
        recentSessionsViewModel: RecentSessionsViewModel
    ) -> some View {
        ActivityFeedView(
            sections: activitySections(for: recentSessionsViewModel),
            emptyStateMessage: "No sessions logged yet.",
            titleProvider: { activity in
                objectivesViewModel.label(for: activity, calendar: calendar)
            },
            durationFormatter: { duration in
                baseViewModel.formattedDuration(duration)
            },
            colorProvider: { activity in
                guard let hex = objectivesViewModel.colorHex(for: activity.linkedObjectiveID) else { return nil }
                return Color(hex: hex)
            },
            onSelect: { activity in
                baseViewModel.editActivity(activity)
            },
            onDelete: { activity in
                recentSessionsViewModel.deleteActivity(activity)
            }
        )
    }
}
