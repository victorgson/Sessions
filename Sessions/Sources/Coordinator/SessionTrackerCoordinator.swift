import SwiftUI
import Combine
import Tracking

enum SessionTrackerSheetKind: String {
    case settings
    case timerConfiguration
    case activityLink
    case addObjective
    case archivedObjectives
}

enum SessionTrackerSheet: Identifiable {
    case settings(SettingsViewModel)
    case timerConfiguration(TimerConfigurationSheetViewModel)
    case activityLink(ActivityLinkSheetCoordinator)
    case addObjective(AddObjectiveSheetViewModel)
    case archivedObjectives(ArchivedObjectivesViewModel)

    var kind: SessionTrackerSheetKind {
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
            return SessionTrackerSheetKind.settings.rawValue
        case .timerConfiguration:
            return SessionTrackerSheetKind.timerConfiguration.rawValue
        case .activityLink:
            return SessionTrackerSheetKind.activityLink.rawValue
        case .archivedObjectives:
            return SessionTrackerSheetKind.archivedObjectives.rawValue
        case .addObjective(let viewModel):
            return "\(SessionTrackerSheetKind.addObjective.rawValue)-\(viewModel.instanceID)"
        }
    }
}

enum SessionTrackerDestination {
    case settings
    case timerConfiguration
    case archivedObjectives
    case addObjective(AddObjectiveSheetViewModel)
    case activityLinkDraft
}

@MainActor
final class SessionTrackerCoordinator: ObservableObject {
    @Published var sheet: SessionTrackerSheet?

    private let sessionTrackerViewModel: SessionTrackerViewModel
    private var sheetDismissHandler: (() -> Void)?

    init(sessionTrackerViewModel: SessionTrackerViewModel) {
        self.sessionTrackerViewModel = sessionTrackerViewModel
    }

    func present(_ destination: SessionTrackerDestination) {
        switch destination {
        case .settings:
            presentSheet(.settings(sessionTrackerViewModel.settingsViewModel))
        case .timerConfiguration:
            presentSheet(.timerConfiguration(sessionTrackerViewModel.timerConfigurationSheetViewModel))
        case .archivedObjectives:
            presentSheet(.archivedObjectives(sessionTrackerViewModel.archivedObjectivesViewModel))
        case .addObjective(let viewModel):
            presentSheet(.addObjective(viewModel))
        case .activityLinkDraft:
            presentActivityLinkSheetIfNeeded()
        }
    }

    func dismiss(_ kind: SessionTrackerSheetKind) {
        guard sheet?.kind == kind else { return }
        dismissSheet()
    }

    private var isPresentingActivityLinkSheet: Bool {
        if case .activityLink? = sheet {
            return true
        }
        return false
    }

    private func presentActivityLinkSheetIfNeeded() {
        guard !isPresentingActivityLinkSheet,
              case let .activityLink(coordinator)? = sessionTrackerViewModel.sheet(for: .activityLink) else { return }
        presentSheet(
            .activityLink(coordinator),
            onDismiss: { [weak sessionTrackerViewModel] in
                sessionTrackerViewModel?.saveDraft()
            }
        )
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
extension SessionTrackerCoordinator {
    @ViewBuilder
    func buildMain(appCoordinator: AppCoordinator) -> some View {
        SessionTrackerView(
            viewModel: sessionTrackerViewModel,
            coordinator: appCoordinator,
            sessionCoordinator: self
        )
    }

    @ViewBuilder
    func build(sheet: SessionTrackerSheet) -> some View {
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

    @ViewBuilder
    func insightsView() -> some View {
        InsightsView(viewModel: sessionTrackerViewModel.insightsViewModel)
    }

    @ViewBuilder
    func sessionDetailView(onDismiss: @escaping () -> Void) -> some View {
        SessionDetailView(timerViewModel: sessionTrackerViewModel.timerViewModel, onStop: onDismiss)
            .toolbarBackground(.hidden, for: .navigationBar)
            .statusBarHidden(true)
    }

    private func presentSheet(_ sheet: SessionTrackerSheet, onDismiss: (() -> Void)? = nil) {
        self.sheetDismissHandler = onDismiss
        self.sheet = sheet
    }

    @ViewBuilder
    private func activityLinkSheet(_ coordinator: ActivityLinkSheetCoordinator) -> some View {
        if coordinator.draft != nil {
            ActivityLinkSheet(viewModel: coordinator)
                .presentationDetents([.medium, .large])
        } else {
            EmptyView()
                .task { [weak self] in
                    self?.dismiss(.activityLink)
                }
        }
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
                self.present(.addObjective(sheetViewModel))
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
