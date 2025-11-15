import Foundation

struct InsightsViewModel {
    let activities: [Activity]
    let objectives: [Objective]
    private let durationFormatter: (TimeInterval) -> String

    init(
        activities: [Activity],
        objectives: [Objective],
        durationFormatter: @escaping (TimeInterval) -> String
    ) {
        self.activities = activities
        self.objectives = objectives
        self.durationFormatter = durationFormatter
    }

    func formattedDuration(_ duration: TimeInterval) -> String {
        durationFormatter(duration)
    }
}

extension InsightsViewModel {
    // swiftlint:disable function_body_length
    func makeInsights(calendar: Calendar = .current, referenceDate: Date = Date()) -> SessionInsights {
        let totalSessions = activities.count
        let totalDuration = activities.reduce(0) { $0 + $1.duration }
        let averageDuration = totalSessions > 0 ? totalDuration / Double(totalSessions) : 0
        let activeObjectivesCount = objectives.filter { !$0.isArchived }.count

        let activitiesByDay = groupActivitiesByDay(calendar: calendar)
        let dayStarts = Set(activitiesByDay.keys)
        let trackedDaysCount = dayStarts.count
        let currentStreakCount = streakCount(from: dayStarts, calendar: calendar)

        let lastActivityDate = activities.max(by: { $0.date < $1.date })?.date

        let objectiveStats = makeObjectiveStats(totalTrackedDuration: totalDuration)
        let weeklyStats = makeWeeklyStats(
            activitiesByDay: activitiesByDay,
            calendar: calendar,
            referenceDate: referenceDate
        )
        let focusStats = makeFocusHourStats(calendar: calendar, totalSessions: totalSessions)

        return SessionInsights(
            totalDuration: totalDuration,
            totalSessions: totalSessions,
            averageDuration: averageDuration,
            activeObjectivesCount: activeObjectivesCount,
            trackedDaysCount: trackedDaysCount,
            currentStreakCount: currentStreakCount,
            focusObjective: objectiveStats.focusObjective,
            topObjectives: objectiveStats.topObjectives,
            unassignedSessions: objectiveStats.unassignedSessions,
            lastActivityDate: lastActivityDate,
            lastSevenDaysStats: weeklyStats.stats,
            lastSevenDaysTotalDuration: weeklyStats.totalDuration,
            lastSevenDaysSessionCount: weeklyStats.sessionCount,
            focusHourStats: focusStats.stats,
            consistentFocusHour: focusStats.consistent
        )
    }
    // swiftlint:enable function_body_length
}

private extension InsightsViewModel {
    func groupActivitiesByDay(calendar: Calendar) -> [Date: [Activity]] {
        Dictionary(grouping: activities) { calendar.startOfDay(for: $0.date) }
    }

    func streakCount(from dayStarts: Set<Date>, calendar: Calendar) -> Int {
        guard let mostRecentDay = dayStarts.sorted(by: >).first else {
            return 0
        }

        var streak = 1
        var cursor = mostRecentDay
        while let previous = calendar.date(byAdding: .day, value: -1, to: cursor),
              dayStarts.contains(previous) {
            streak += 1
            cursor = previous
        }
        return streak
    }

    func makeObjectiveStats(
        totalTrackedDuration: TimeInterval
    ) -> (
        focusObjective: SessionInsights.ObjectiveStat?,
        topObjectives: [SessionInsights.ObjectiveStat],
        unassignedSessions: SessionInsights.UnassignedStat?
    ) {
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

        let objectiveStats = aggregatedByObjective.compactMap { id, aggregation -> SessionInsights.ObjectiveStat? in
            guard let objective = objectivesByID[id] else { return nil }
            let percentage = totalTrackedDuration > 0 ? aggregation.duration / totalTrackedDuration : 0
            return SessionInsights.ObjectiveStat(
                objective: objective,
                totalDuration: aggregation.duration,
                sessionCount: aggregation.count,
                percentage: percentage
            )
        }
        .sorted { $0.totalDuration > $1.totalDuration }

        let unassignedSessions: SessionInsights.UnassignedStat?
        if unassignedAggregation.count > 0 {
            let percentage = totalTrackedDuration > 0 ? unassignedAggregation.duration / totalTrackedDuration : 0
            unassignedSessions = SessionInsights.UnassignedStat(
                totalDuration: unassignedAggregation.duration,
                sessionCount: unassignedAggregation.count,
                percentage: percentage
            )
        } else {
            unassignedSessions = nil
        }

        return (
            focusObjective: objectiveStats.first,
            topObjectives: Array(objectiveStats.prefix(3)),
            unassignedSessions: unassignedSessions
        )
    }

    func makeWeeklyStats(
        activitiesByDay: [Date: [Activity]],
        calendar: Calendar,
        referenceDate: Date
    ) -> (
        stats: [SessionInsights.WeekdayStat],
        totalDuration: TimeInterval,
        sessionCount: Int
    ) {
        let today = calendar.startOfDay(for: referenceDate)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("EEE")

        var sevenDayStats: [SessionInsights.WeekdayStat] = []
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
                SessionInsights.WeekdayStat(
                    date: dayStart,
                    label: formatter.string(from: dayStart),
                    totalDuration: duration,
                    sessionCount: count
                )
            )
        }

        return (
            stats: sevenDayStats,
            totalDuration: sevenDayDuration,
            sessionCount: sevenDaySessions
        )
    }

    func makeFocusHourStats(
        calendar: Calendar,
        totalSessions: Int
    ) -> (
        stats: [SessionInsights.FocusHourStat],
        consistent: SessionInsights.FocusHourStat?
    ) {
        let activitiesByHour = Dictionary(grouping: activities) {
            calendar.component(.hour, from: $0.date)
        }
        let totalSessionsDouble = Double(totalSessions)
        let focusStats = activitiesByHour.map { hour, groupedActivities -> SessionInsights.FocusHourStat in
            let duration = groupedActivities.reduce(0) { $0 + $1.duration }
            let count = groupedActivities.count
            let percentage = totalSessionsDouble > 0 ? Double(count) / totalSessionsDouble : 0
            return SessionInsights.FocusHourStat(
                hour: hour,
                totalDuration: duration,
                sessionCount: count,
                percentageOfSessions: percentage
            )
        }
        .sorted {
            if $0.totalDuration == $1.totalDuration {
                if $0.sessionCount == $1.sessionCount {
                    return $0.hour < $1.hour
                }
                return $0.sessionCount > $1.sessionCount
            }
            return $0.totalDuration > $1.totalDuration
        }

        let consistentFocusHour: SessionInsights.FocusHourStat?
        if let topHour = focusStats.first,
           topHour.sessionCount >= 3,
           topHour.percentageOfSessions >= 0.2 {
            consistentFocusHour = topHour
        } else {
            consistentFocusHour = nil
        }

        return (stats: focusStats, consistent: consistentFocusHour)
    }
}
