import SwiftUI

struct HoldingsListView: View {
    @Bindable var viewModel: PortfolioViewModel
    let currency: String

    @State private var searchText = ""
    @State private var selectedAssetType: AssetType?
    @State private var sortOrder: SortOrder = .value
    @State private var showAddHolding = false

    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case value = "Value"
        case change = "Change"
        case quantity = "Quantity"
    }

    private var filteredHoldings: [Holding] {
        var holdings = viewModel.holdings

        if let assetType = selectedAssetType {
            holdings = holdings.filter { $0.assetType == assetType }
        }

        if !searchText.isEmpty {
            holdings = holdings.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.symbol.localizedCaseInsensitiveContains(searchText)
            }
        }

        switch sortOrder {
        case .name:
            holdings.sort { $0.name < $1.name }
        case .value:
            holdings.sort { $0.totalValue > $1.totalValue }
        case .change:
            holdings.sort { $0.profitLossPercentage > $1.profitLossPercentage }
        case .quantity:
            holdings.sort { $0.quantity > $1.quantity }
        }

        return holdings
    }

    private var groupedHoldings: [(AssetType, [Holding])] {
        let grouped = Dictionary(grouping: filteredHoldings) { $0.assetType }
        return grouped
            .sorted { pair1, pair2 in
                let total1 = pair1.value.reduce(0) { $0 + $1.totalValue }
                let total2 = pair2.value.reduce(0) { $0 + $1.totalValue }
                return total1 > total2
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.holdings.isEmpty {
                    emptyState
                } else {
                    holdingsList
                }
            }
            .navigationTitle("Holdings")
            .searchable(text: $searchText, prompt: "Search holdings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Section("Sort By") {
                            ForEach(SortOrder.allCases, id: \.self) { order in
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
                        }

                        Section("Filter by Type") {
                            Button {
                                selectedAssetType = nil
                            } label: {
                                HStack {
                                    Text("All Types")
                                    if selectedAssetType == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }

                            ForEach(AssetType.allCases) { type in
                                Button {
                                    selectedAssetType = type
                                } label: {
                                    HStack {
                                        Image(systemName: type.sfSymbol)
                                        Text(type.displayName)
                                        if selectedAssetType == type {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .sheet(isPresented: $showAddHolding) {
                NavigationStack {
                    AddHoldingView(viewModel: AddHoldingViewModel()) {
                        // handled in AddHoldingView via the portfolio viewmodel
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

    private var holdingsList: some View {
        List {
            if selectedAssetType != nil {
                ForEach(filteredHoldings) { holding in
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
                }
                .onDelete(perform: deleteHoldings)
            } else {
                ForEach(groupedHoldings, id: \.0) { assetType, holdings in
                    Section {
                        ForEach(holdings) { holding in
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
                        }
                    } header: {
                        HStack {
                            Image(systemName: assetType.sfSymbol)
                                .foregroundStyle(assetType.color)
                            Text(assetType.displayName)
                            Spacer()
                            Text(CurrencyFormatter.format(
                                holdings.reduce(0) { $0 + $1.totalValue },
                                currency: currency
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Holdings", systemImage: "tray")
        } description: {
            Text("Add your first holding to start tracking your portfolio.")
        } actions: {
            Button {
                showAddHolding = true
            } label: {
                Text("Add Holding")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func deleteHoldings(at offsets: IndexSet) {
        for index in offsets {
            let holding = filteredHoldings[index]
            viewModel.deleteHolding(holding)
        }
    }
}
