import SwiftUI

struct InsightsView: View {
    let viewModel: InsightsViewModel
    let calendar: Calendar
    let relativeFormatter: RelativeDateTimeFormatter
    enum Layout {
        static let metricCardHeight: CGFloat = 150
        static let metricCardSubtitleLineLimit = 1
        static let metricCardSubtitleMinScale: CGFloat = 0.75
    }
    let metricsColumns: [GridItem] = Array(
        repeating: GridItem(.flexible(), spacing: 16, alignment: .leading),
        count: 2
    )

    init(viewModel: InsightsViewModel, calendar: Calendar = .current) {
        self.viewModel = viewModel
        self.calendar = calendar

        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.dateTimeStyle = .named
        self.relativeFormatter = formatter
    }

    private var insights: SessionInsights {
        viewModel.makeInsights(calendar: calendar)
    }

    var body: some View {
        let insights = insights
        return ScrollView {
            VStack(spacing: 24) {
                summaryCard(for: insights)
                metricsGrid(for: insights)
                focusHoursCard(for: insights)
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
