import Foundation
import FactoryKit
import Tracking
import TrackingFirebase


extension Container {

    var subscriptionStatusProvider: Factory<any SubscriptionStatusProviding> {
        Factory(self) { @MainActor in RevenueCatSubscriptionStatusRepository() }
            .singleton
    }

    var persistenceController: Factory<PersistenceController> {
        Factory(self) { @MainActor in
            PersistenceController(subscriptionStatusProvider: self.subscriptionStatusProvider())
        }
        .singleton
    }

    var sessionTrackerRepository: Factory<SessionTrackerRepository> {
        Factory(self) { @MainActor in
            CoreDataSessionTrackerRepository(persistenceController: self.persistenceController())
        }
        .singleton
    }

    var sessionTrackerUseCases: Factory<SessionTrackerUseCases> {
        Factory(self) { @MainActor in
            SessionTrackerUseCases.make(repository: self.sessionTrackerRepository())
        }
        .singleton
    }

    var trackerDispatcher: Factory<TrackerDispatcher> {
        Factory(self) { @MainActor in
            DefaultTrackerDispatcher(
                trackers: [FirebaseTracker(), LogFirebaseTracker()]
            )
        }
        .singleton
    }

    var hapticBox: Factory<HapticBox> {
        Factory(self) { @MainActor in DefaultHapticBox() }
            .singleton
    }

    var liveActivityController: Factory<any SessionLiveActivityControlling> {
        Factory(self) { @MainActor in DefaultSessionLiveActivityController() }
            .singleton
    }

    var sessionTrackerViewModel: Factory<SessionTrackerViewModel> {
        Factory(self) { @MainActor in
            SessionTrackerViewModel(
                useCases: self.sessionTrackerUseCases(),
                trackerDispatcher: self.trackerDispatcher(),
                hapticBox: self.hapticBox(),
                liveActivityController: self.liveActivityController(),
                subscriptionStatusProvider: self.subscriptionStatusProvider()
            )
        }
        .singleton
    }
}
