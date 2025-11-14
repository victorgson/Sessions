import Foundation

struct SessionLiveActivityDisplayState {
    let timerRange: ClosedRange<Date>
    let countsDown: Bool
    let title: String
    let detail: String?
}
