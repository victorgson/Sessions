import SwiftUI

struct InsightsView: View {
    @Bindable var viewModel: SessionTrackerViewModel
    private let calendar: Calendar
    private let relativeFormatter: RelativeDateTimeFormatter
    private enum Layout {
        static let metricCardHeight: CGFloat = 150
        static let metricCardSubtitleLineLimit = 1
        static let metricCardSubtitleMinScale: CGFloat = 0.75
    }
    private let metricsColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 16, alignment: .leading),
        count: 2
    )

    init(viewModel: SessionTrackerViewModel, calendar: Calendar = .current) {
        self.viewModel = viewModel
        self.calendar = calendar

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        self.relativeFormatter = formatter
    }

    private var insights: SessionInsights {
        SessionInsights(
            activities: viewModel.activities,
            objectives: viewModel.objectives,
            calendar: calendar
        )
    }

    var body: some View {
        let insights = insights
        return ScrollView {
            VStack(spacing: 24) {
                summaryCard(for: insights)
                metricsGrid(for: insights)
                if let focus = insights.focusObjective {
                    focusObjectiveCard(for: focus)
                }
                if !insights.topObjectives.isEmpty || insights.unassignedSessions != nil {
                    objectiveBreakdownCard(for: insights)
                } else {
                    objectiveEmptyStateCard()
                }
                weeklyTrendCard(for: insights)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 24)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("Insights")
        .toolbarTitleDisplayMode(.inline)
    }
}

// MARK: - Summary
private extension InsightsView {
    @ViewBuilder
    func summaryCard(for insights: SessionInsights) -> some View {
        let totalHours = formatHours(insights.totalDuration)
        let sessionsText = "\(insights.totalSessions) \(insights.totalSessions == 1 ? "session" : "sessions")"
        let averageText = insights.totalSessions > 0
            ? viewModel.formattedDuration(insights.averageDuration)
            : "–"
        let lastSession = lastSessionDescription(for: insights.lastActivityDate)

        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(TimelinePalette.sessionGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tracked Hours")
                        .font(.caption.weight(.semibold))
                        .textCase(.uppercase)
                        .foregroundStyle(Color.white.opacity(0.7))
                    Text("\(totalHours) h")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.8)
                }

                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    Label(sessionsText, systemImage: "clock.arrow.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                    Label("Avg \(averageText)", systemImage: "timelapse")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.white.opacity(0.85))
                }

                Text(lastSession)
                    .font(.footnote)
                    .foregroundStyle(Color.white.opacity(0.7))
            }
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Metrics
private extension InsightsView {
    @ViewBuilder
    func metricsGrid(for insights: SessionInsights) -> some View {
        LazyVGrid(columns: metricsColumns, alignment: .leading, spacing: 16) {
            metricCard(
                title: "Active Objectives",
                value: "\(insights.activeObjectivesCount)",
                subtitle: "Tracking goals in progress"
            )

            metricCard(
                title: "Tracked Days",
                value: "\(insights.trackedDaysCount)",
                subtitle: "Unique days with a session"
            )

            metricCard(
                title: "Current Streak",
                value: "\(insights.currentStreakCount) \(insights.currentStreakCount == 1 ? "day" : "days")",
                subtitle: insights.currentStreakCount > 0 ? "Consecutive days logged" : "Start a new streak"
            )

            let sevenDayValue = insights.lastSevenDaysSessionCount
            metricCard(
                title: "Last 7 Days",
                value: "\(sevenDayValue) \(sevenDayValue == 1 ? "session" : "sessions")",
                subtitle: shortWeekRangeDescription()
            )
        }
    }

    @ViewBuilder
    func metricCard(title: String, value: String, subtitle: String) -> some View {
        card(padding: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 0)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: Layout.metricCardHeight, alignment: .topLeading)
    }
}

// MARK: - Focus Objective
private extension InsightsView {
    @ViewBuilder
    func focusObjectiveCard(for stat: SessionInsights.ObjectiveStat) -> some View {
        let objectiveColor = Color(hex: stat.colorHex ?? "") ?? Color.accentColor

        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Most Worked Objective")
                    .font(.headline)
                    .foregroundStyle(.primary)

                HStack(alignment: .center, spacing: 16) {
                    Circle()
                        .fill(objectiveColor)
                        .frame(width: 44, height: 44)
                        .overlay(
                            Circle()
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        Text(stat.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text("\(viewModel.formattedDuration(stat.totalDuration)) across \(stat.sessionCount) \(stat.sessionCount == 1 ? "session" : "sessions")")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Time Allocation")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ObjectiveProgressBar(progress: stat.percentage, color: objectiveColor)
                        .animation(.easeOut(duration: 0.3), value: stat.percentage)
                }

                Text(stat.percentage.formatted(.percent.precision(.fractionLength(0))) + " of tracked time")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Objective Breakdown
private extension InsightsView {
    @ViewBuilder
    func objectiveBreakdownCard(for insights: SessionInsights) -> some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Objective Breakdown")
                    .font(.headline)
                    .foregroundStyle(.primary)

                ForEach(insights.topObjectives) { stat in
                    let objectiveColor = Color(hex: stat.colorHex ?? "") ?? .accentColor
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(stat.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 12)
                            Text(viewModel.formattedDuration(stat.totalDuration))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        ObjectiveProgressBar(progress: stat.percentage, color: objectiveColor)
                            .animation(.easeOut(duration: 0.3), value: stat.percentage)

                        Text(stat.percentage.formatted(.percent.precision(.fractionLength(0))) + " of tracked time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if let unassigned = insights.unassignedSessions {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Unassigned Sessions")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer(minLength: 12)
                            Text(viewModel.formattedDuration(unassigned.totalDuration))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }

                        let unassignedColor = Color(.systemGray4)
                        ObjectiveProgressBar(progress: unassigned.percentage, color: unassignedColor)
                            .animation(.easeOut(duration: 0.3), value: unassigned.percentage)

                        Text(unassigned.percentage.formatted(.percent.precision(.fractionLength(0))) + " of tracked time")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    func objectiveEmptyStateCard() -> some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("Objective Breakdown")
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text("Assign sessions to objectives to uncover how your effort is distributed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Weekly Trend
private extension InsightsView {
    @ViewBuilder
    func weeklyTrendCard(for insights: SessionInsights) -> some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Weekly Activity")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if insights.lastSevenDaysSessionCount == 0 {
                    Text("Log sessions to see your weekly momentum.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    let maxDuration = insights.lastSevenDaysStats.map(\.totalDuration).max() ?? 0
                    HStack(alignment: .bottom, spacing: 12) {
                        ForEach(insights.lastSevenDaysStats) { stat in
                            let ratio = maxDuration > 0 ? stat.totalDuration / maxDuration : 0
                            let barHeight = max(8, 120 * ratio)

                            VStack(spacing: 6) {
                                Text(shortDuration(stat.totalDuration))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Capsule(style: .continuous)
                                    .fill(TimelinePalette.sessionGradientVertical)
                                    .frame(width: 16, height: barHeight)
                                Text(stat.label.uppercased())
                                    .font(.caption2.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }

                let sevenDayDurationText = viewModel.formattedDuration(insights.lastSevenDaysTotalDuration)
                Text("\(sevenDayDurationText) tracked in the last 7 days")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Helpers
private extension InsightsView {
    func lastSessionDescription(for date: Date?) -> String {
        guard let date else { return "Log your first session to unlock insights." }
        return "Last session " + relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    func formatHours(_ duration: TimeInterval) -> String {
        let hours = duration / 3600
        return hours.formatted(
            .number.precision(
                hours >= 10 ? .fractionLength(0) : .fractionLength(1)
            )
        )
    }

    func shortDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes >= 60 {
            return "\(minutes / 60)h"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "0"
        }
    }

    func shortWeekRangeDescription() -> String {
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: startOfToday) else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return "\(formatter.string(from: startDate)) – \(formatter.string(from: startOfToday))"
    }

    @ViewBuilder
    func card<Content: View>(padding: CGFloat = 20, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
            )
    }
}
