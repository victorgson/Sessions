import Foundation

struct SessionInsights {
    struct ObjectiveStat: Identifiable {
        let objective: Objective
        let totalDuration: TimeInterval
        let sessionCount: Int
        let percentage: Double

        var id: UUID { objective.id }
        var colorHex: String? { objective.colorHex }
        var title: String { objective.title }
    }

    struct UnassignedStat {
        let totalDuration: TimeInterval
        let sessionCount: Int
        let percentage: Double
    }

    struct WeekdayStat: Identifiable {
        let date: Date
        let label: String
        let totalDuration: TimeInterval
        let sessionCount: Int

        var id: Date { date }
    }

    struct FocusHourStat: Identifiable {
        let hour: Int
        let totalDuration: TimeInterval
        let sessionCount: Int
        let percentageOfSessions: Double

        var id: Int { hour }
    }

    let totalDuration: TimeInterval
    let totalSessions: Int
    let averageDuration: TimeInterval
    let activeObjectivesCount: Int
    let trackedDaysCount: Int
    let currentStreakCount: Int
    let focusObjective: ObjectiveStat?
    let topObjectives: [ObjectiveStat]
    let unassignedSessions: UnassignedStat?
    let lastActivityDate: Date?
    let lastSevenDaysStats: [WeekdayStat]
    let lastSevenDaysTotalDuration: TimeInterval
    let lastSevenDaysSessionCount: Int
    let focusHourStats: [FocusHourStat]
    let consistentFocusHour: FocusHourStat?
}
