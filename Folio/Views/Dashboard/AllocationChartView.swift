import SwiftUI
import Charts

enum TimePeriod: String, CaseIterable {
    case oneHour = "1H"
    case oneDay = "1D"
    case oneWeek = "1W"
    case oneMonth = "1M"
    case ytd = "YTD"
    case oneYear = "1Y"
    case all = "ALL"
}

struct PortfolioChartView: View {
    let dataPoints: [Double]
    @Binding var selectedPeriod: TimePeriod

    private var isPositive: Bool {
        guard let first = dataPoints.first, let last = dataPoints.last else { return true }
        return last >= first
    }

    private var lineColor: Color {
        isPositive ? FolioTheme.positive : FolioTheme.negative
    }

    private var maxValue: Double {
        dataPoints.max() ?? 0
    }

    private var minValue: Double {
        dataPoints.min() ?? 0
    }

    var body: some View {
        VStack(spacing: 16) {
            chartView
                .frame(height: 200)

            timePeriodSelector
        }
    }

    private var chartView: some View {
        Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { index, value in
                LineMark(
                    x: .value("Time", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(lineColor)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Time", index),
                    y: .value("Value", value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [lineColor.opacity(0.3), lineColor.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            if !dataPoints.isEmpty {
                RuleMark(y: .value("High", maxValue))
                    .foregroundStyle(FolioTheme.labelGray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .top, alignment: .trailing) {
                        Text(CurrencyFormatter.formatBareNumber(maxValue))
                            .font(.system(size: 9))
                            .foregroundStyle(FolioTheme.labelGray)
                    }

                RuleMark(y: .value("Low", minValue))
                    .foregroundStyle(FolioTheme.labelGray.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .annotation(position: .bottom, alignment: .trailing) {
                        Text(CurrencyFormatter.formatBareNumber(minValue))
                            .font(.system(size: 9))
                            .foregroundStyle(FolioTheme.labelGray)
                    }
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartYScale(domain: (minValue * 0.98)...(maxValue * 1.02))
    }

    private var timePeriodSelector: some View {
        HStack(spacing: 0) {
            ForEach(TimePeriod.allCases, id: \.self) { period in
                Button {
                    selectedPeriod = period
                } label: {
                    Text(period.rawValue)
                        .font(.caption)
                        .fontWeight(selectedPeriod == period ? .semibold : .regular)
                        .foregroundStyle(selectedPeriod == period ? .white : FolioTheme.labelGray)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedPeriod == period ? FolioTheme.chipBackground : Color.clear,
                            in: Capsule()
                        )
                }
            }
        }
    }
}

#Preview {
    PortfolioChartView(
        dataPoints: [100, 105, 102, 110, 108, 115, 120, 118, 125, 130, 128, 135],
        selectedPeriod: .constant(.oneMonth)
    )
    .padding()
    .background(FolioTheme.background)
}
