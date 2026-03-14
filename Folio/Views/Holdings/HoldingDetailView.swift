import SwiftUI
import Charts

struct HoldingDetailView: View {
    let holding: Holding
    let currency: String
    let onSave: (Holding) -> Void
    let onDelete: (Holding) -> Void

    @State private var isEditing = false
    @State private var editViewModel = AddHoldingViewModel()
    @State private var showDeleteConfirmation = false
    @State private var isFavorite = false
    @State private var selectedTab: DetailTab = .general
    @State private var selectedTimePeriod: TimePeriod = .oneMonth
    @Environment(\.dismiss) private var dismiss

    enum DetailTab: String, CaseIterable {
        case general = "General"
        case transactions = "Transactions"
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsRow

                tabSelector

                if selectedTab == .general {
                    generalContent
                } else {
                    transactionsContent
                }
            }
            .padding()
        }
        .background(FolioTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    HStack(spacing: 6) {
                        detailAssetIcon
                        Text(holding.symbol)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                    }
                    Text(holding.name)
                        .font(.caption)
                        .foregroundStyle(FolioTheme.labelGray)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: 12) {
                    Button {
                        isFavorite.toggle()
                    } label: {
                        Image(systemName: isFavorite ? "star.fill" : "star")
                            .foregroundStyle(isFavorite ? .yellow : FolioTheme.labelGray)
                    }

                    Menu {
                        Button {
                            editViewModel.populateForEditing(holding)
                            isEditing = true
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(FolioTheme.labelGray)
                    }
                }
            }
        }
        .toolbarBackground(FolioTheme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isEditing) {
            NavigationStack {
                AddHoldingView(viewModel: editViewModel, isEditing: true) {
                    editViewModel.applyChanges(to: holding)
                    onSave(holding)
                    isEditing = false
                }
                .navigationTitle("Edit Holding")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") {
                            isEditing = false
                        }
                    }
                }
            }
        }
        .confirmationDialog("Delete Holding", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                onDelete(holding)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete \(holding.name)? This cannot be undone.")
        }
    }

    // MARK: - Header Asset Icon

    @ViewBuilder
    private var detailAssetIcon: some View {
        if holding.assetType == .crypto {
            AsyncImage(url: URL(string: "https://assets.coingecko.com/coins/images/1/thumb/\(holding.symbol.lowercased()).png")) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20).clipShape(Circle())
                case .failure, .empty:
                    Image(systemName: holding.assetType.sfSymbol)
                        .font(.caption)
                        .foregroundStyle(holding.assetType.color)
                @unknown default:
                    Image(systemName: holding.assetType.sfSymbol)
                        .font(.caption)
                        .foregroundStyle(holding.assetType.color)
                }
            }
        } else {
            Image(systemName: holding.assetType.sfSymbol)
                .font(.caption)
                .foregroundStyle(holding.assetType.color)
        }
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(title: "Holdings", value: CurrencyFormatter.formatQuantity(holding.quantity))
            Divider()
                .frame(height: 36)
                .background(FolioTheme.secondaryBackground)
            statItem(title: "Market Value", value: CurrencyFormatter.format(holding.totalValue, currency: currency))
            Divider()
                .frame(height: 36)
                .background(FolioTheme.secondaryBackground)
            statItem(
                title: "Total Profit",
                value: CurrencyFormatter.format(holding.profitLoss, currency: currency, showSign: true),
                valueColor: holding.profitLoss >= 0 ? FolioTheme.positive : FolioTheme.negative
            )
        }
        .padding(.vertical, 16)
        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statItem(title: String, value: String, valueColor: Color = .white) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(FolioTheme.labelGray)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(valueColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Tab Selector

    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(DetailTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        Text(tab.rawValue)
                            .font(.subheadline)
                            .fontWeight(selectedTab == tab ? .semibold : .regular)
                            .foregroundStyle(selectedTab == tab ? .white : FolioTheme.labelGray)

                        Rectangle()
                            .fill(selectedTab == tab ? FolioTheme.positive : Color.clear)
                            .frame(height: 2)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - General Tab

    private var generalContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current price
            VStack(alignment: .leading, spacing: 6) {
                Text(CurrencyFormatter.formatPrice(holding.currentPrice, currency: currency))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                HStack(spacing: 6) {
                    Text(CurrencyFormatter.format(holding.profitLoss, currency: currency, showSign: true))
                        .font(.subheadline)
                        .foregroundStyle(holding.profitLoss >= 0 ? FolioTheme.positive : FolioTheme.negative)

                    ValueChangeChip(percentage: holding.profitLossPercentage)
                }

                Text("Current price")
                    .font(.caption)
                    .foregroundStyle(FolioTheme.labelGray)
            }

            // Price chart
            priceChart

            // Position details
            detailsCard
        }
    }

    private var priceChart: some View {
        VStack(spacing: 12) {
            let priceData = generatePriceData()

            PortfolioChartView(
                dataPoints: priceData,
                selectedPeriod: $selectedTimePeriod
            )
        }
    }

    private func generatePriceData() -> [Double] {
        // Generate sparkline around the current price
        let currentPrice = holding.currentPrice
        let purchasePrice = holding.purchasePrice
        let steps = 24
        var points: [Double] = []
        for i in 0...steps {
            let progress = Double(i) / Double(steps)
            let noise = Double.random(in: -0.03...0.03) * currentPrice
            let interpolated = purchasePrice + ((currentPrice - purchasePrice) * progress) + noise
            points.append(max(0, interpolated))
        }
        points[points.count - 1] = currentPrice
        return points
    }

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow("Asset Type", value: holding.assetType.displayName)
            Divider().background(FolioTheme.secondaryBackground)
            detailRow("Purchase Price", value: CurrencyFormatter.formatPrice(holding.purchasePrice, currency: currency))
            Divider().background(FolioTheme.secondaryBackground)
            detailRow("Total Cost", value: CurrencyFormatter.format(holding.totalCost, currency: currency))
            if !holding.exchange.isEmpty {
                Divider().background(FolioTheme.secondaryBackground)
                detailRow("Exchange", value: holding.exchange)
            }
            if !holding.isin.isEmpty {
                Divider().background(FolioTheme.secondaryBackground)
                detailRow("ISIN", value: holding.isin)
            }
            Divider().background(FolioTheme.secondaryBackground)
            detailRow("Currency", value: holding.purchaseCurrency)
            Divider().background(FolioTheme.secondaryBackground)
            detailRow("Purchase Date", value: holding.purchaseDate.formatted(date: .abbreviated, time: .omitted))
        }
        .padding(.vertical, 4)
        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Transactions Tab

    private var transactionsContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Stats row
            HStack(spacing: 0) {
                statItem(
                    title: "Avg Buy Price",
                    value: CurrencyFormatter.formatPrice(holding.purchasePrice, currency: currency)
                )
                Divider().frame(height: 36).background(FolioTheme.secondaryBackground)
                statItem(title: "Avg Sell Price", value: "--")
                Divider().frame(height: 36).background(FolioTheme.secondaryBackground)
                statItem(title: "Transactions", value: "1")
            }
            .padding(.vertical, 16)
            .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))

            // New transaction button
            Button {
                editViewModel.populateForEditing(holding)
                isEditing = true
            } label: {
                HStack {
                    Image(systemName: "plus")
                    Text("New transaction")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(FolioTheme.positive)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(FolioTheme.positive.opacity(0.3), lineWidth: 1)
                )
            }

            // Transaction card (the original purchase)
            transactionCard
        }
    }

    private var transactionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Buy")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(FolioTheme.positive)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .overlay(
                        Capsule()
                            .stroke(FolioTheme.positive, lineWidth: 1)
                    )

                Spacer()

                Text(holding.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(FolioTheme.labelGray)
            }

            VStack(spacing: 0) {
                transactionDetailRow("Price", value: CurrencyFormatter.formatPrice(holding.purchasePrice, currency: currency))
                Divider().background(FolioTheme.secondaryBackground)
                transactionDetailRow("Quantity", value: CurrencyFormatter.formatQuantity(holding.quantity))
                Divider().background(FolioTheme.secondaryBackground)
                transactionDetailRow("Value", value: CurrencyFormatter.format(holding.totalCost, currency: currency))
                Divider().background(FolioTheme.secondaryBackground)
                HStack {
                    Text("Performance")
                        .font(.caption)
                        .foregroundStyle(FolioTheme.labelGray)
                    Spacer()
                    ValueChangeChip(percentage: holding.profitLossPercentage)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(FolioTheme.secondaryBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(16)
        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
    }

    private func transactionDetailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.caption)
                .foregroundStyle(FolioTheme.labelGray)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
}
