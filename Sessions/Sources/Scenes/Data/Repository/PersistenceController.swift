import Foundation
import CoreData
import CloudKit

final class PersistenceController {
    let mode: PersistenceMode
    let container: NSPersistentContainer

    init(
        subscriptionStatusProvider: any SubscriptionStatusProviding,
        useInMemoryStore: Bool = false
    ) {
        let isPremiumEnabled = subscriptionStatusProvider.isSubscribed
        let model = Self.makeModel()
        mode = isPremiumEnabled ? .cloud : .local
        container = Self.makeContainer(
            mode: mode,
            model: model,
            useInMemoryStore: useInMemoryStore
        )

        configureViewContext()
        loadPersistentStores()
    }

    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}

private extension PersistenceController {
    func configureViewContext() {
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.undoManager = nil
    }

    func loadPersistentStores() {
        let semaphore = DispatchSemaphore(value: 0)
        container.loadPersistentStores { _, error in
            if let error {
                assertionFailure("Failed to load persistent store: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
    }

    static func makeContainer(
        mode: PersistenceMode,
        model: NSManagedObjectModel,
        useInMemoryStore: Bool
    ) -> NSPersistentContainer {
        switch mode {
        case .cloud:
            return makeCloudContainer(model: model, useInMemoryStore: useInMemoryStore)
        case .local:
            return makeLocalContainer(model: model, useInMemoryStore: useInMemoryStore)
        }
    }

    static func makeCloudContainer(
        model: NSManagedObjectModel,
        useInMemoryStore: Bool
    ) -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(
            name: "SessionTracker",
            managedObjectModel: model
        )
        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        configureCloudDescription(description, useInMemoryStore: useInMemoryStore)
        container.persistentStoreDescriptions = [description]
        return container
    }

    static func makeLocalContainer(
        model: NSManagedObjectModel,
        useInMemoryStore: Bool
    ) -> NSPersistentContainer {
        let container = NSPersistentContainer(
            name: "SessionTracker",
            managedObjectModel: model
        )
        let description = container.persistentStoreDescriptions.first ?? NSPersistentStoreDescription()
        configureLocalDescription(description, useInMemoryStore: useInMemoryStore)
        container.persistentStoreDescriptions = [description]
        return container
    }

    static func configureCloudDescription(
        _ description: NSPersistentStoreDescription,
        useInMemoryStore: Bool
    ) {
        if useInMemoryStore {
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
            description.cloudKitContainerOptions = nil
        } else {
            description.type = NSSQLiteStoreType
            description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.com.placeholder.sessiontracker"
            )
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
    }

    static func configureLocalDescription(
        _ description: NSPersistentStoreDescription,
        useInMemoryStore: Bool
    ) {
        if useInMemoryStore {
            description.type = NSInMemoryStoreType
            description.url = URL(fileURLWithPath: "/dev/null")
        } else {
            description.type = NSSQLiteStoreType
        }
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true
    }

    static func makeModel() -> NSManagedObjectModel {
        SessionTrackerManagedObjectModelFactory.make()
    }
}
