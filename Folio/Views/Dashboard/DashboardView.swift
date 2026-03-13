import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: PortfolioViewModel
    let currency: String

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    PortfolioSummaryCard(
                        totalValue: viewModel.totalValue,
                        totalCost: viewModel.totalCost,
                        profitLoss: viewModel.totalProfitLoss,
                        profitLossPercentage: viewModel.totalProfitLossPercentage,
                        currency: currency,
                        holdingsCount: viewModel.holdings.count
                    )

                    AllocationChartView(allocations: viewModel.allocationData)

                    if !viewModel.topGainers.isEmpty {
                        topMoversSection(title: "Top Gainers", holdings: viewModel.topGainers, isGainer: true)
                    }

                    if !viewModel.topLosers.isEmpty {
                        topMoversSection(title: "Top Losers", holdings: viewModel.topLosers, isGainer: false)
                    }

                    if viewModel.holdings.isEmpty {
                        emptyStateView
                    }

                    if let lastRefresh = viewModel.lastRefreshDate {
                        Text("Last updated: \(lastRefresh.formatted(.relative(presentation: .named)))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding()
            }
            .navigationTitle("Dashboard")
            .refreshable {
                await viewModel.refreshPrices()
            }
            .overlay {
                if viewModel.isRefreshing {
                    ProgressView("Refreshing prices...")
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private func topMoversSection(title: String, holdings: [Holding], isGainer: Bool) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: isGainer ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .foregroundStyle(isGainer ? .green : .red)
                Text(title)
                    .font(.headline)
            }

            ForEach(holdings) { holding in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(holding.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text(holding.symbol)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(CurrencyFormatter.format(holding.totalValue, currency: currency))
                            .font(.subheadline)
                            .fontWeight(.medium)
                        ValueChangeChip(percentage: holding.profitLossPercentage)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No Holdings Yet")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Add your first holding or import from a screenshot or CSV to get started.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
