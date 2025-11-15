import SwiftUI

struct CoordinatorView: View {
    @ObservedObject private var coordinator: AppCoordinator
    @ObservedObject private var sessionTrackerCoordinator: SessionTrackerCoordinator

    init(
        coordinator: AppCoordinator,
        sessionTrackerCoordinator: SessionTrackerCoordinator
    ) {
        self.coordinator = coordinator
        self.sessionTrackerCoordinator = sessionTrackerCoordinator
    }

    var body: some View {
        NavigationStack(path: pathBinding) {
            sessionTrackerCoordinator.buildMain(appCoordinator: coordinator)
            .sheet(
                item: sessionSheetBinding,
                onDismiss: {
                    sessionTrackerCoordinator.handleSheetDismissed()
                },
                content: { sheet in
                    sessionTrackerCoordinator.build(sheet: sheet)
                }
            )
                .navigationDestination(for: AppPage.self) { page in
                    coordinator.build(page: page)
                }
        }
    }

    private var pathBinding: Binding<[AppPage]> {
        Binding(
            get: { coordinator.path },
            set: { coordinator.path = $0 }
        )
    }

    private var sessionSheetBinding: Binding<SessionTrackerSheet?> {
        Binding(
            get: { sessionTrackerCoordinator.sheet },
            set: { sessionTrackerCoordinator.sheet = $0 }
        )
    }
}
