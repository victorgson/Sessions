import Foundation
import FactoryKit
import Tracking
import TrackingFirebase

extension Container {

    var subscriptionStatusProvider: Factory<SubscriptionStatusProviding> {
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

    var appStoreRatingPromptRepository: Factory<AppStoreRatingPromptRepository> {
        Factory(self) { @MainActor in StoreKitAppStoreRatingPromptRepository() }
            .singleton
    }

    var loadObjectivesUseCase: Factory<LoadObjectivesUseCase> {
        Factory(self) { @MainActor in DefaultLoadObjectivesUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var loadActivitiesUseCase: Factory<LoadActivitiesUseCase> {
        Factory(self) { @MainActor in DefaultLoadActivitiesUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var upsertObjectiveUseCase: Factory<UpsertObjectiveUseCase> {
        Factory(self) { @MainActor in DefaultUpsertObjectiveUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var createObjectiveUseCase: Factory<CreateObjectiveUseCase> {
        Factory(self) { @MainActor in DefaultCreateObjectiveUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var removeObjectiveUseCase: Factory<RemoveObjectiveUseCase> {
        Factory(self) { @MainActor in DefaultRemoveObjectiveUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var recordActivityUseCase: Factory<RecordActivityUseCase> {
        Factory(self) { @MainActor in DefaultRecordActivityUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var updateActivityUseCase: Factory<UpdateActivityUseCase> {
        Factory(self) { @MainActor in DefaultUpdateActivityUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var removeActivityUseCase: Factory<RemoveActivityUseCase> {
        Factory(self) { @MainActor in DefaultRemoveActivityUseCase(repository: self.sessionTrackerRepository()) }
            .singleton
    }

    var promptAppStoreRatingUseCase: Factory<PromptAppStoreRatingUseCase> {
        Factory(self) { @MainActor in
            DefaultPromptAppStoreRatingUseCase(repository: self.appStoreRatingPromptRepository())
        }
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

    var liveActivityController: Factory<SessionLiveActivityControlling> {
        Factory(self) { @MainActor in DefaultSessionLiveActivityController() }
            .singleton
    }

    var sessionTimerConfigurationStore: Factory<SessionTimerConfigurationStoring> {
        Factory(self) { @MainActor in DefaultsSessionTimerConfigurationStore() }
            .singleton
    }

    var sessionTrackerViewModel: Factory<SessionTrackerViewModel> {
        Factory(self) { @MainActor in
            return SessionTrackerViewModel(
                loadObjectivesUseCase: self.loadObjectivesUseCase(),
                loadActivitiesUseCase: self.loadActivitiesUseCase(),
                upsertObjectiveUseCase: self.upsertObjectiveUseCase(),
                createObjectiveUseCase: self.createObjectiveUseCase(),
                removeObjectiveUseCase: self.removeObjectiveUseCase(),
                recordActivityUseCase: self.recordActivityUseCase(),
                updateActivityUseCase: self.updateActivityUseCase(),
                removeActivityUseCase: self.removeActivityUseCase(),
                promptAppStoreRatingUseCase: self.promptAppStoreRatingUseCase(),
                trackerDispatcher: self.trackerDispatcher(),
                hapticBox: self.hapticBox(),
                liveActivityController: self.liveActivityController(),
                subscriptionStatusProvider: self.subscriptionStatusProvider(),
                timerConfigurationStore: self.sessionTimerConfigurationStore()
            )
        }
        .singleton
    }
}
