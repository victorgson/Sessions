import Foundation
import Tracking

extension TrackingEvent.SessionTracker.Page: FirebaseTrackablePageEvent {
    public var firebasePage: String {
        switch value {
        case .overview:
            return "session_tracker"
        }
    }

    public var firebaseAdditionalParameters: [String: TrackableValue] {
        [:]
    }
}

extension TrackingEvent.SessionTracker.Action: FirebaseTrackableActionEvent {
    public var firebaseAction: String {
        switch value {
        case .startSession:
            return "session_start"
        case .stopSession:
            return "session_stop"
        case .showFullScreenTimer:
            return "session_fullscreen_timer_open"
        case .openInsights:
            return "session_insights_open"
        case .openSettings:
            return "session_settings_open"
        case .showArchivedObjectives:
            return "session_archived_objectives_open"
        case .showAddObjective(let source):
            switch source {
            case .emptyState:
                return "session_add_objective_empty_state"
            case .activeObjectives:
                return "session_add_objective_active"
            }
        case .editObjective:
            return "session_edit_objective"
        case .openActivityDraft(let source):
            switch source {
            case .new:
                return "session_activity_draft_new"
            case .edit:
                return "session_activity_draft_edit"
            }
        case .deleteActivity:
            return "session_activity_delete"
        case .saveActivityDraft:
            return "session_activity_save"
        case .discardActivityDraft:
            return "session_activity_discard"
        }
    }

    public var firebaseAdditionalParameters: [String: TrackableValue] {
        additionalParameters
    }
}
