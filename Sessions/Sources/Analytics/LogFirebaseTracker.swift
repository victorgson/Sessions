import Foundation
import Tracking
import TrackingFirebase

public final class LogFirebaseTracker: Tracker {
    public func track(event: TrackableEvent) {
        switch event {
        case let actionEvent as FirebaseTrackableActionEvent
            where !actionEvent.firebaseAdditionalParameters.isEmpty:
            let message = "Action: \(actionEvent.firebaseAction) with \(actionEvent.firebaseAdditionalParameters)"
            print("FirebaseAnalytics", message)
        case let actionEvent as FirebaseTrackableActionEvent:
            print("FirebaseAnalytics", "Action: \(actionEvent.firebaseAction)")
        case let pageEvent as FirebaseTrackablePageEvent
            where !pageEvent.firebaseAdditionalParameters.isEmpty:
            let message = "PageView: \(pageEvent.firebasePage) with \(pageEvent.firebaseAdditionalParameters)"
            print("FirebaseAnalytics", message)
        case let pageEvent as FirebaseTrackablePageEvent:
            print("FirebaseAnalytics", "PageView: \(pageEvent.firebasePage)")
        default:
            break
        }
    }
}
