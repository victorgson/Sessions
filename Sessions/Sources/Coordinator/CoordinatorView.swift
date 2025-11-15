import SwiftUI

struct CoordinatorView: View {
    @ObservedObject private var coordinator: AppCoordinator
    private let sessionTrackerViewModel: SessionTrackerViewModel

    init(
        coordinator: AppCoordinator,
        sessionTrackerViewModel: SessionTrackerViewModel
    ) {
        self.coordinator = coordinator
        self.sessionTrackerViewModel = sessionTrackerViewModel
    }

    var body: some View {
        NavigationStack(path: pathBinding) {
            SessionTrackerView(viewModel: sessionTrackerViewModel)
                .environmentObject(coordinator)
                .navigationDestination(for: AppRoute.self) { route in
                    coordinator.destination(for: route)
                }
        }
        .sheet(
            item: sheetBinding,
            onDismiss: {
                coordinator.handleSheetDismissed()
            },
            content: { sheet in
                coordinator.sheetView(for: sheet)
            }
        )
    }

    private var pathBinding: Binding<[AppRoute]> {
        Binding(
            get: { coordinator.path },
            set: { coordinator.path = $0 }
        )
    }

    private var sheetBinding: Binding<AppSheet?> {
        Binding(
            get: { coordinator.sheet },
            set: { coordinator.sheet = $0 }
        )
    }
}
