import Foundation

public extension TrackingEvent {
    enum SessionTracker {
        public struct Page: TrackablePageEvent, Equatable {
            public enum Value: String {
                case overview
            }

            public let value: Value

            public init(value: Value = .overview) {
                self.value = value
            }
        }

        public struct Action: TrackableActionEvent, Equatable {
            public enum ObjectiveSource: String {
                case emptyState
                case activeObjectives
            }

            public enum ActivityDraftSource: String {
                case new
                case edit
            }

            public enum Value: Equatable {
                case startSession
                case stopSession
                case showFullScreenTimer
                case openInsights
                case openSettings
                case showArchivedObjectives
                case showAddObjective(ObjectiveSource)
                case editObjective(id: UUID)
                case openActivityDraft(ActivityDraftSource)
                case deleteActivity(id: UUID)
                case saveActivityDraft(isEditing: Bool)
                case discardActivityDraft(isEditing: Bool)
            }

            public let value: Value

            public init(value: Value) {
                self.value = value
            }

            public var additionalParameters: [String: TrackableValue] {
                switch value {
                case .showAddObjective(let source):
                    return ["source": source.rawValue]
                case .editObjective(let id),
                     .deleteActivity(let id):
                    return ["id": id.uuidString]
                case .openActivityDraft(let source):
                    return ["source": source.rawValue]
                case .saveActivityDraft(let isEditing),
                     .discardActivityDraft(let isEditing):
                    return ["is_editing": isEditing]
                default:
                    return [:]
                }
            }
        }
    }
}
