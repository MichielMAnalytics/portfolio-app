import SwiftUI
import Charts

struct AllocationChartView: View {
    let allocations: [(assetType: AssetType, value: Double, percentage: Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Asset Allocation")
                .font(.headline)

            if allocations.isEmpty {
                ContentUnavailableView(
                    "No Holdings",
                    systemImage: "chart.pie",
                    description: Text("Add holdings to see your allocation")
                )
                .frame(height: 200)
            } else {
                HStack(spacing: 20) {
                    donutChart
                        .frame(width: 160, height: 160)

                    legendView
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var donutChart: some View {
        Chart(allocations, id: \.assetType) { allocation in
            SectorMark(
                angle: .value("Value", allocation.value),
                innerRadius: .ratio(0.6),
                angularInset: 1.5
            )
            .foregroundStyle(allocation.assetType.color)
            .cornerRadius(4)
        }
        .chartBackground { chartProxy in
            GeometryReader { geometry in
                let frame = geometry[chartProxy.plotFrame!]
                VStack(spacing: 2) {
                    Text("Total")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(CurrencyFormatter.formatLarge(
                        allocations.reduce(0) { $0 + $1.value }
                    ))
                    .font(.caption)
                    .fontWeight(.semibold)
                }
                .position(x: frame.midX, y: frame.midY)
            }
        }
    }

    private var legendView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(allocations.prefix(6), id: \.assetType) { allocation in
                HStack(spacing: 8) {
                    Circle()
                        .fill(allocation.assetType.color)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(allocation.assetType.displayName)
                            .font(.caption)
                            .fontWeight(.medium)
                        Text(CurrencyFormatter.formatPercentage(allocation.percentage, showSign: false))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if allocations.count > 6 {
                Text("+\(allocations.count - 6) more")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    AllocationChartView(allocations: [
        (assetType: .stock, value: 50000, percentage: 50),
        (assetType: .crypto, value: 20000, percentage: 20),
        (assetType: .etf, value: 15000, percentage: 15),
        (assetType: .bond, value: 10000, percentage: 10),
        (assetType: .cash, value: 5000, percentage: 5)
    ])
    .padding()
}
