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

    // swiftlint:disable function_body_length
    init(activities: [Activity], objectives: [Objective], calendar: Calendar = .current) {
        totalSessions = activities.count
        totalDuration = activities.reduce(0) { $0 + $1.duration }
        averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        activeObjectivesCount = objectives.filter { !$0.isArchived }.count

        let activitiesByDay = Dictionary(grouping: activities) { calendar.startOfDay(for: $0.date) }
        let dayStarts = Set(activitiesByDay.keys)
        trackedDaysCount = dayStarts.count

        if let mostRecentDay = dayStarts.sorted(by: >).first {
            var streak = 1
            var cursor = mostRecentDay
            while let previous = calendar.date(byAdding: .day, value: -1, to: cursor),
                  dayStarts.contains(previous) {
                streak += 1
                cursor = previous
            }
            currentStreakCount = streak
        } else {
            currentStreakCount = 0
        }

        lastActivityDate = activities.max(by: { $0.date < $1.date })?.date

        let objectivesByID = Dictionary(uniqueKeysWithValues: objectives.map { ($0.id, $0) })
        var aggregatedByObjective: [UUID: (duration: TimeInterval, count: Int)] = [:]
        var unassignedAggregation: (duration: TimeInterval, count: Int) = (0, 0)
        for activity in activities {
            guard let objectiveID = activity.linkedObjectiveID,
                  objectivesByID[objectiveID] != nil else {
                unassignedAggregation.duration += activity.duration
                unassignedAggregation.count += 1
                continue
            }
            var value = aggregatedByObjective[objectiveID] ?? (0, 0)
            value.duration += activity.duration
            value.count += 1
            aggregatedByObjective[objectiveID] = value
        }

        let totalTrackedDuration = totalDuration
        let objectiveStats = aggregatedByObjective.compactMap { id, aggregation -> ObjectiveStat? in
            guard let objective = objectivesByID[id] else { return nil }
            let percentage = totalTrackedDuration > 0 ? aggregation.duration / totalTrackedDuration : 0
            return ObjectiveStat(
                objective: objective,
                totalDuration: aggregation.duration,
                sessionCount: aggregation.count,
                percentage: percentage
            )
        }
        .sorted { $0.totalDuration > $1.totalDuration }

        focusObjective = objectiveStats.first
        topObjectives = Array(objectiveStats.prefix(3))
        if unassignedAggregation.count > 0 {
            let percentage = totalTrackedDuration > 0 ? unassignedAggregation.duration / totalTrackedDuration : 0
            unassignedSessions = UnassignedStat(
                totalDuration: unassignedAggregation.duration,
                sessionCount: unassignedAggregation.count,
                percentage: percentage
            )
        } else {
            unassignedSessions = nil
        }

        let today = calendar.startOfDay(for: Date())
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        var sevenDayStats: [WeekdayStat] = []
        var sevenDayDuration: TimeInterval = 0
        var sevenDaySessions = 0

        for offset in stride(from: -6, through: 0, by: 1) {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let dayActivities = activitiesByDay[dayStart] ?? []
            let duration = dayActivities.reduce(0) { $0 + $1.duration }
            let count = dayActivities.count
            sevenDayDuration += duration
            sevenDaySessions += count
            sevenDayStats.append(
                WeekdayStat(
                    date: dayStart,
                    label: formatter.string(from: dayStart),
                    totalDuration: duration,
                    sessionCount: count
                )
            )
        }

        lastSevenDaysStats = sevenDayStats
        lastSevenDaysTotalDuration = sevenDayDuration
        lastSevenDaysSessionCount = sevenDaySessions
    }
    // swiftlint:enable function_body_length
}
