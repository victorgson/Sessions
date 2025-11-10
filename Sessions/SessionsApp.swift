import SwiftUI
import FirebaseCore
import RevenueCat
import FactoryKit

@main
@MainActor
struct SessionsApp: App {
    @State private var sessionTrackerViewModel: SessionTrackerViewModel

    init() {
        FirebaseApp.configure()

        #if DEVELOPMENT
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_XuVymhSmFuWhMzaripgyhEZBhut")
        #else
        Purchases.configure(withAPIKey: "appl_sZlrdCheJelinBWvtihakkDDaiN")
        #endif

        let container = Container.shared
        _sessionTrackerViewModel = State(
            initialValue: container.sessionTrackerViewModel()
        )
    }

    var body: some Scene {
        WindowGroup {
            SessionTrackerView(viewModel: sessionTrackerViewModel)
        }
    }
}
