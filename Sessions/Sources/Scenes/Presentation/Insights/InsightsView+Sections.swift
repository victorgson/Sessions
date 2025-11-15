import SwiftUI

// MARK: - Focus Hours
extension InsightsView {
    @ViewBuilder
    func focusHoursCard(for insights: SessionInsights) -> some View {
        card {
            VStack(alignment: .leading, spacing: 16) {
                Text("Focus Hours")
                    .font(.headline)
                    .foregroundStyle(.primary)

                if insights.focusHourStats.isEmpty {
                    Text("Log sessions to reveal when you tend to get the most focus.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                } else {
                    if let consistentHour = insights.consistentFocusHour {
                        Text("You're most consistent around \(hourWindowDescription(for: consistentHour.hour)).")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        let shareText = consistentHour.percentageOfSessions.formatted(
                            .percent.precision(.fractionLength(0))
                        )
                        Text("\(shareText) of sessions happen during this hour.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Keep tracking to uncover a consistent focus window.")
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }

                    let maxDuration = insights.focusHourStats.map(\.totalDuration).max() ?? 0
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(Array(insights.focusHourStats.prefix(3))) { stat in
                            focusHourRow(for: stat, maxDuration: maxDuration)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func focusHourRow(for stat: SessionInsights.FocusHourStat, maxDuration: TimeInterval) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(hourWindowDescription(for: stat.hour))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 12)
                let durationText = viewModel.formattedDuration(stat.totalDuration)
                let sessionText = stat.sessionCount == 1 ? "session" : "sessions"
                Text("\(durationText) • \(stat.sessionCount) \(sessionText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            let ratio = maxDuration > 0 ? stat.totalDuration / maxDuration : 0
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color(.systemFill))
                    Capsule(style: .continuous)
                        .fill(Color.accentColor.opacity(0.85))
                        .frame(width: max(12, geometry.size.width * ratio))
                }
            }
            .frame(height: 8)
            .animation(.easeOut(duration: 0.3), value: ratio)
        }
    }
}

// MARK: - Focus Objective
extension InsightsView {
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
                        let durationText = viewModel.formattedDuration(stat.totalDuration)
                        let sessionText = stat.sessionCount == 1 ? "session" : "sessions"
                        Text("\(durationText) across \(stat.sessionCount) \(sessionText)")
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
extension InsightsView {
    @ViewBuilder
    // swiftlint:disable:next function_body_length
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

                        let percentageText = stat.percentage.formatted(
                            .percent.precision(.fractionLength(0))
                        )
                        Text("\(percentageText) of tracked time")
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

                        let unassignedText = unassigned.percentage.formatted(
                            .percent.precision(.fractionLength(0))
                        )
                        Text("\(unassignedText) of tracked time")
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
extension InsightsView {
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
extension InsightsView {
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

    func hourWindowDescription(for hour: Int) -> String {
        let startOfToday = calendar.startOfDay(for: Date())
        guard let start = calendar.date(
            bySettingHour: hour,
            minute: 0,
            second: 0,
            of: startOfToday
        ),
        let end = calendar.date(byAdding: .hour, value: 1, to: start) else {
            let endHour = (hour + 1) % 24
            return String(format: "%02d:00 – %02d:00", hour, endHour)
        }

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .autoupdatingCurrent
        formatter.dateFormat = "h a"
        return "\(formatter.string(from: start)) – \(formatter.string(from: end))"
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
