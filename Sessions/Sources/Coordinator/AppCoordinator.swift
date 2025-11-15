import SwiftUI
import Tracking
import Combine

enum AppRoute: Hashable {
    case insights
    case sessionDetail
}

enum AppSheetKind: String {
    case settings
    case timerConfiguration
    case activityLink
    case addObjective
    case archivedObjectives
}

enum AppSheet: Identifiable {
    case settings(SettingsViewModel)
    case timerConfiguration(TimerConfigurationSheetViewModel)
    case activityLink(ActivityLinkSheetCoordinator)
    case addObjective(AddObjectiveSheetViewModel)
    case archivedObjectives(ArchivedObjectivesViewModel)

    var kind: AppSheetKind {
        switch self {
        case .settings:
            return .settings
        case .timerConfiguration:
            return .timerConfiguration
        case .activityLink:
            return .activityLink
        case .addObjective:
            return .addObjective
        case .archivedObjectives:
            return .archivedObjectives
        }
    }

    var id: String {
        switch self {
        case .settings:
            return AppSheetKind.settings.rawValue
        case .timerConfiguration:
            return AppSheetKind.timerConfiguration.rawValue
        case .activityLink:
            return AppSheetKind.activityLink.rawValue
        case .archivedObjectives:
            return AppSheetKind.archivedObjectives.rawValue
        case .addObjective(let viewModel):
            return "\(AppSheetKind.addObjective.rawValue)-\(viewModel.instanceID)"
        }
    }
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppRoute] = []
    @Published var sheet: AppSheet?

    private let sessionTrackerViewModel: SessionTrackerViewModel
    private var sheetDismissHandler: (() -> Void)?

    init(sessionTrackerViewModel: SessionTrackerViewModel) {
        self.sessionTrackerViewModel = sessionTrackerViewModel
    }

    func showInsights() {
        path.append(.insights)
    }

    func showSessionDetail() {
        guard path.last != .sessionDetail else { return }
        path.append(.sessionDetail)
    }

    func dismissSessionDetail() {
        guard let index = path.lastIndex(of: .sessionDetail) else { return }
        path.remove(at: index)
    }

    func presentSettings() {
        presentSheet(.settings(sessionTrackerViewModel.settingsViewModel))
    }

    func presentTimerConfiguration() {
        presentSheet(.timerConfiguration(sessionTrackerViewModel.timerConfigurationSheetViewModel))
    }

    func presentArchivedObjectives() {
        presentSheet(.archivedObjectives(sessionTrackerViewModel.archivedObjectivesViewModel))
    }

    func presentAddObjectiveSheet(viewModel: AddObjectiveSheetViewModel) {
        presentSheet(.addObjective(viewModel))
    }

    func presentActivityLinkSheetIfNeeded() {
        guard !isPresentingActivityLinkSheet,
              case let .activityLink(coordinator)? = sessionTrackerViewModel.sheet(for: .activityLink) else { return }
        presentSheet(
            .activityLink(coordinator),
            onDismiss: { [weak sessionTrackerViewModel] in
                sessionTrackerViewModel?.saveDraft()
            }
        )
    }

    func dismissActivityLinkSheetIfNeeded() {
        guard case .activityLink? = sheet else { return }
        dismissSheet()
    }

    var isPresentingActivityLinkSheet: Bool {
        if case .activityLink? = sheet {
            return true
        }
        return false
    }

    func dismissSheet(triggerDismissHandler: Bool = false) {
        if !triggerDismissHandler {
            sheetDismissHandler = nil
        }
        sheet = nil
    }

    func handleSheetDismissed() {
        sheetDismissHandler?()
        sheetDismissHandler = nil
    }
}

@MainActor
extension AppCoordinator {
    @ViewBuilder
    func destination(for route: AppRoute) -> some View {
        switch route {
        case .insights:
            InsightsView(viewModel: sessionTrackerViewModel.insightsViewModel)
        case .sessionDetail:
            SessionDetailView(timerViewModel: sessionTrackerViewModel.timerViewModel) { [weak self] in
                self?.dismissSessionDetail()
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .statusBarHidden(true)
        }
    }

    @ViewBuilder
    func sheetView(for sheet: AppSheet) -> some View {
        switch sheet {
        case .settings(let viewModel):
            SettingsView(viewModel: viewModel)
        case .timerConfiguration(let viewModel):
            TimerConfigurationSheet(viewModel: viewModel)
        case .activityLink(let coordinator):
            activityLinkSheet(coordinator)
        case .archivedObjectives(let viewModel):
            archivedObjectivesSheet(viewModel)
        case .addObjective(let viewModel):
            addObjectiveSheet(viewModel)
        }
    }

    private func presentSheet(_ sheet: AppSheet, onDismiss: (() -> Void)? = nil) {
        self.sheetDismissHandler = onDismiss
        self.sheet = sheet
    }

    @ViewBuilder
    private func activityLinkSheet(_ coordinator: ActivityLinkSheetCoordinator) -> some View {
        ActivityLinkSheet(viewModel: coordinator)
            .presentationDetents([.medium, .large])
    }

    @ViewBuilder
    private func archivedObjectivesSheet(_ viewModel: ArchivedObjectivesViewModel) -> some View {
        ArchivedObjectivesView(
            viewModel: viewModel,
            onClose: { [weak self] in
                self?.dismissSheet()
            },
            onSelect: { [weak self] objective in
                guard let self else { return }
                self.sessionTrackerViewModel.trackAction(
                    TrackingEvent.SessionTracker.Action(value: .editObjective(id: objective.id))
                )
                self.dismissSheet()
                let sheetViewModel = AddObjectiveSheetViewModel(
                    mode: .edit(objective),
                    defaultColor: ObjectiveColorProvider.color(for: objective)
                )
                self.presentAddObjectiveSheet(viewModel: sheetViewModel)
            }
        )
    }

    @ViewBuilder
    private func addObjectiveSheet(_ viewModel: AddObjectiveSheetViewModel) -> some View {
        AddObjectiveSheet(
            viewModel: viewModel,
            onSave: { [weak self] submission in
                guard let self else { return }
                self.sessionTrackerViewModel.objectivesViewModel.handleObjectiveSubmission(submission)
                self.dismissSheet()
            },
            onCancel: { [weak self] in
                self?.dismissSheet()
            },
            onArchive: { [weak self, weak viewModel] in
                guard let self, let id = viewModel?.objectiveID else { return }
                self.sessionTrackerViewModel.objectivesViewModel.archiveObjective(withID: id)
                self.dismissSheet()
            },
            onUnarchive: { [weak self, weak viewModel] in
                guard let self, let id = viewModel?.objectiveID else { return }
                self.sessionTrackerViewModel.objectivesViewModel.unarchiveObjective(withID: id)
                self.dismissSheet()
            },
            onDelete: { [weak self, weak viewModel] in
                guard let self, let id = viewModel?.objectiveID else { return }
                self.sessionTrackerViewModel.objectivesViewModel.deleteObjective(withID: id)
                self.dismissSheet()
            }
        )
    }
}
