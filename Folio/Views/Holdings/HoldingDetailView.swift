import SwiftUI

struct HoldingDetailView: View {
    let holding: Holding
    let currency: String
    let onSave: (Holding) -> Void
    let onDelete: (Holding) -> Void

    @State private var isEditing = false
    @State private var editViewModel = AddHoldingViewModel()
    @State private var showDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                overviewHeader
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            Section("Position Details") {
                detailRow("Quantity", value: CurrencyFormatter.formatQuantity(holding.quantity))
                detailRow("Current Price", value: CurrencyFormatter.formatPrice(holding.currentPrice, currency: currency))
                detailRow("Total Value", value: CurrencyFormatter.format(holding.totalValue, currency: currency))
                detailRow("Purchase Price", value: CurrencyFormatter.formatPrice(holding.purchasePrice, currency: currency))
                detailRow("Total Cost", value: CurrencyFormatter.format(holding.totalCost, currency: currency))
            }

            Section("Performance") {
                HStack {
                    Text("Profit / Loss")
                    Spacer()
                    ValueChangeView(
                        value: holding.profitLoss,
                        percentage: holding.profitLossPercentage,
                        currency: currency
                    )
                }
            }

            Section("Information") {
                detailRow("Asset Type", value: holding.assetType.displayName)
                detailRow("Symbol", value: holding.symbol)
                if !holding.exchange.isEmpty {
                    detailRow("Exchange", value: holding.exchange)
                }
                if !holding.isin.isEmpty {
                    detailRow("ISIN", value: holding.isin)
                }
                detailRow("Currency", value: holding.purchaseCurrency)
                detailRow("Purchase Date", value: holding.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            }

            if !holding.notes.isEmpty {
                Section("Notes") {
                    Text(holding.notes)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Delete Holding", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle(holding.symbol)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") {
                    editViewModel.populateForEditing(holding)
                    isEditing = true
                }
            }
        }
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

    private var overviewHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: holding.assetType.sfSymbol)
                .font(.largeTitle)
                .foregroundStyle(holding.assetType.color)
                .frame(width: 60, height: 60)
                .background(holding.assetType.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))

            Text(holding.name)
                .font(.title2)
                .fontWeight(.bold)

            Text(CurrencyFormatter.format(holding.totalValue, currency: currency))
                .font(.title)
                .fontWeight(.bold)

            ValueChangeView(
                value: holding.profitLoss,
                percentage: holding.profitLossPercentage,
                currency: currency,
                font: .body
            )
        }
        .frame(maxWidth: .infinity)
        .padding()
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
        }
    }
}
