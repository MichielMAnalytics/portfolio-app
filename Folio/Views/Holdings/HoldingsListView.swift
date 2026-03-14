import SwiftUI

/// Embedded holdings list section used within DashboardView.
/// No longer a standalone tab -- kept as an extracted component for reuse.
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

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.holdings.isEmpty {
                    emptyState
                } else {
                    holdingsList
                }
            }
            .background(FolioTheme.background)
            .navigationTitle("Holdings")
            .searchable(text: $searchText, prompt: "Search holdings")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddHolding = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(FolioTheme.positive)
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
                            .foregroundStyle(FolioTheme.positive)
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
                .listRowBackground(FolioTheme.cardBackground)
            }
            .onDelete(perform: deleteHoldings)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(FolioTheme.background)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Holdings", systemImage: "tray")
                .foregroundStyle(FolioTheme.labelGray)
        } description: {
            Text("Add your first holding to start tracking your portfolio.")
                .foregroundStyle(FolioTheme.labelGray)
        } actions: {
            Button {
                showAddHolding = true
            } label: {
                Text("Add Holding")
            }
            .buttonStyle(.borderedProminent)
            .tint(FolioTheme.positive)
        }
    }

    private func deleteHoldings(at offsets: IndexSet) {
        for index in offsets {
            let holding = filteredHoldings[index]
            viewModel.deleteHolding(holding)
        }
    }
}
