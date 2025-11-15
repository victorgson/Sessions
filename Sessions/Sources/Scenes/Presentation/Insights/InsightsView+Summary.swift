import SwiftUI

// MARK: - Summary & Metrics
extension InsightsView {
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
