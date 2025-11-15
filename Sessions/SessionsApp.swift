import SwiftUI
import FirebaseCore
import RevenueCat
import FactoryKit

@main
@MainActor
struct SessionsApp: App {
    @State private var sessionTrackerViewModel: SessionTrackerViewModel
    @StateObject private var coordinator: AppCoordinator
    @StateObject private var sessionTrackerCoordinator: SessionTrackerCoordinator

    init() {
        FirebaseApp.configure()

        #if DEVELOPMENT
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_XuVymhSmFuWhMzaripgyhEZBhut")
        #else
        Purchases.configure(withAPIKey: "appl_sZlrdCheJelinBWvtihakkDDaiN")
        #endif

        let container = Container.shared
        let trackerViewModel = container.sessionTrackerViewModel()
        let trackerCoordinator = container.sessionTrackerCoordinator()
        _sessionTrackerViewModel = State(initialValue: trackerViewModel)
        _sessionTrackerCoordinator = StateObject(wrappedValue: trackerCoordinator)
        _coordinator = StateObject(wrappedValue: container.appCoordinator())
    }

    var body: some Scene {
        WindowGroup {
            CoordinatorView(
                coordinator: coordinator,
                sessionTrackerCoordinator: sessionTrackerCoordinator
            )
        }
    }
}
