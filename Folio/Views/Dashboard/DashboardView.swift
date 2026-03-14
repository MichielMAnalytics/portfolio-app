import SwiftUI

struct DashboardView: View {
    @Bindable var viewModel: PortfolioViewModel
    let currency: String

    @State private var selectedAssetFilter: AssetFilterChip = .all
    @State private var selectedTimePeriod: TimePeriod = .oneMonth
    @State private var sortOrder: HoldingSortOrder = .value
    @State private var showAddHolding = false

    enum AssetFilterChip: String, CaseIterable {
        case all = "All"
        case crypto = "Crypto"
        case stocks = "Stocks"
        case etfs = "ETFs"
        case bonds = "Bonds"

        var assetType: AssetType? {
            switch self {
            case .all: return nil
            case .crypto: return .crypto
            case .stocks: return .stock
            case .etfs: return .etf
            case .bonds: return .bond
            }
        }
    }

    enum HoldingSortOrder: String, CaseIterable {
        case value = "Largest position"
        case name = "Name"
        case change = "Best performance"
    }

    private var filteredHoldings: [Holding] {
        var holdings = viewModel.holdings

        if let assetType = selectedAssetFilter.assetType {
            holdings = holdings.filter { $0.assetType == assetType }
        }

        switch sortOrder {
        case .value:
            holdings.sort { $0.totalValue > $1.totalValue }
        case .name:
            holdings.sort { $0.name < $1.name }
        case .change:
            holdings.sort { $0.profitLossPercentage > $1.profitLossPercentage }
        }

        return holdings
    }

    private var chartData: [Double] {
        // Generate sparkline data from holdings values or use placeholder
        let baseValue = viewModel.totalValue
        guard baseValue > 0 else {
            return [0, 0, 0, 0, 0]
        }
        // Create a simulated sparkline using the overall profit/loss trajectory
        let change = viewModel.totalProfitLoss
        let startValue = baseValue - change
        let steps = 24
        var points: [Double] = []
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let noise = Double.random(in: -0.02...0.02) * baseValue
            let interpolated = startValue + (change * progress) + noise
            points.append(max(0, interpolated))
        }
        // Ensure the last point is the current value
        points[points.count - 1] = baseValue
        return points
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(spacing: 20) {
                        filterChips

                        PortfolioSummaryCard(
                            totalValue: viewModel.totalValue,
                            totalCost: viewModel.totalCost,
                            profitLoss: viewModel.totalProfitLoss,
                            profitLossPercentage: viewModel.totalProfitLossPercentage,
                            currency: currency,
                            holdingsCount: viewModel.holdings.count
                        )

                        if !viewModel.holdings.isEmpty {
                            PortfolioChartView(
                                dataPoints: chartData,
                                selectedPeriod: $selectedTimePeriod
                            )
                        }

                        if viewModel.holdings.isEmpty {
                            emptyStateView
                        } else {
                            holdingsSection
                        }

                        if let lastRefresh = viewModel.lastRefreshDate {
                            Text("Last updated: \(lastRefresh.formatted(.relative(presentation: .named)))")
                                .font(.caption2)
                                .foregroundStyle(FolioTheme.labelGray)
                        }

                        // Bottom spacer for FAB clearance
                        Spacer().frame(height: 60)
                    }
                    .padding()
                }
                .background(FolioTheme.background)

                // Floating action button
                Button {
                    showAddHolding = true
                } label: {
                    Image(systemName: "plus")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .frame(width: 56, height: 56)
                        .background(.white, in: Circle())
                        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Portfolio")
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .toolbarBackground(FolioTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .refreshable {
                await viewModel.refreshPrices()
            }
            .overlay {
                if viewModel.isRefreshing {
                    ProgressView("Refreshing prices...")
                        .padding()
                        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
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
            .sheet(isPresented: $showAddHolding) {
                NavigationStack {
                    AddHoldingView(viewModel: AddHoldingViewModel()) {
                        // handled in AddHoldingView
                    }
                    .navigationTitle("Add Holding")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .topBarLeading) {
                            Button("Cancel") {
                                showAddHolding = false
                            }
                        }
                    }
                }
                .interactiveDismissDisabled()
            }
        }
    }

    // MARK: - Filter Chips

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AssetFilterChip.allCases, id: \.self) { chip in
                    Button {
                        selectedAssetFilter = chip
                    } label: {
                        Text(chip.rawValue)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(selectedAssetFilter == chip ? .white : FolioTheme.labelGray)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                selectedAssetFilter == chip ? FolioTheme.chipBackground : Color.clear,
                                in: Capsule()
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        selectedAssetFilter == chip ? Color.clear : FolioTheme.chipBackground,
                                        lineWidth: 1
                                    )
                            )
                    }
                }
            }
        }
    }

    // MARK: - Holdings Section

    private var holdingsSection: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "line.3.horizontal.decrease")
                    .foregroundStyle(FolioTheme.labelGray)

                Spacer()

                Menu {
                    ForEach(HoldingSortOrder.allCases, id: \.self) { order in
                        Button {
                            sortOrder = order
                        } label: {
                            HStack {
                                Text(order.rawValue)
                                if sortOrder == order {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortOrder.rawValue)
                            .font(.subheadline)
                            .foregroundStyle(FolioTheme.labelGray)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                            .foregroundStyle(FolioTheme.labelGray)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(FolioTheme.chipBackground, in: Capsule())
                }
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 12)

            // Holdings list
            VStack(spacing: 0) {
                ForEach(Array(filteredHoldings.enumerated()), id: \.element.id) { index, holding in
                    NavigationLink {
                        HoldingDetailView(
                            holding: holding,
                            currency: currency,
                            onSave: { viewModel.updateHolding($0) },
                            onDelete: { viewModel.deleteHolding($0) }
                        )
                    } label: {
                        HoldingRowView(holding: holding, currency: currency)
                    }
                    .buttonStyle(.plain)

                    if index < filteredHoldings.count - 1 {
                        Divider()
                            .background(FolioTheme.secondaryBackground)
                            .padding(.leading, 56)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 48))
                .foregroundStyle(FolioTheme.labelGray)

            Text("No Holdings Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.white)

            Text("Add your first holding or import from a screenshot or CSV to get started.")
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 16))
    }
}
