import SwiftUI
import Combine

enum AppPage: Hashable {
    case insights
    case sessionDetail
}

@MainActor
final class AppCoordinator: ObservableObject {
    @Published var path: [AppPage] = []

    private let sessionTrackerCoordinator: SessionTrackerCoordinator

    init(sessionTrackerCoordinator: SessionTrackerCoordinator) {
        self.sessionTrackerCoordinator = sessionTrackerCoordinator
    }

    func push(_ route: AppPage) {
        switch route {
        case .insights:
            path.append(route)
        case .sessionDetail:
            guard path.last != .sessionDetail else { return }
            path.append(route)
        }
    }

    func pop(_ route: AppPage) {
        guard let index = path.lastIndex(of: route) else { return }
        path.remove(at: index)
    }
}

@MainActor
extension AppCoordinator {
    @ViewBuilder
    func build(page: AppPage) -> some View {
        switch page {
        case .insights:
            sessionTrackerCoordinator.insightsView()
        case .sessionDetail:
            sessionTrackerCoordinator.sessionDetailView { [weak self] in
                self?.pop(.sessionDetail)
            }
        }
    }
}
