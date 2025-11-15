import SwiftUI
import FirebaseCore
import RevenueCat
import FactoryKit

@main
@MainActor
struct SessionsApp: App {
    @State private var sessionTrackerViewModel: SessionTrackerViewModel
    @StateObject private var coordinator: AppCoordinator

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
        _sessionTrackerViewModel = State(initialValue: trackerViewModel)
        _coordinator = StateObject(wrappedValue: AppCoordinator(sessionTrackerViewModel: trackerViewModel))
    }

    var body: some Scene {
        WindowGroup {
            CoordinatorView(
                coordinator: coordinator,
                sessionTrackerViewModel: sessionTrackerViewModel
            )
        }
    }
}
