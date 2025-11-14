import ActivityKit
import Foundation

@available(iOS 16.1, *)
struct SessionLiveActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var timerRange: ClosedRange<Date>
        var countsDown: Bool
        var title: String
        var detail: String?

        init(timerRange: ClosedRange<Date>, countsDown: Bool, title: String, detail: String? = nil) {
            self.timerRange = timerRange
            self.countsDown = countsDown
            self.title = title
            self.detail = detail
        }
    }

    let id: UUID
    let startDate: Date

    init(id: UUID = UUID(), startDate: Date) {
        self.id = id
        self.startDate = startDate
    }
}
