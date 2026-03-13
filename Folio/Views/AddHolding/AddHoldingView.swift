import SwiftUI

struct AddHoldingView: View {
    @Bindable var viewModel: AddHoldingViewModel
    var isEditing: Bool = false
    var onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        Form {
            Section("Asset Type") {
                Picker("Type", selection: $viewModel.assetType) {
                    ForEach(AssetType.allCases) { type in
                        Label(type.displayName, systemImage: type.sfSymbol)
                            .tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            if viewModel.assetType == .crypto {
                cryptoSearchSection
            }

            Section("Basic Information") {
                TextField("Asset Name", text: $viewModel.name)
                    .textContentType(.name)

                TextField("Symbol / Ticker", text: $viewModel.symbol)
                    .textInputAutocapitalization(.characters)

                if viewModel.assetType != .crypto {
                    TextField("ISIN", text: $viewModel.isin)
                        .textInputAutocapitalization(.characters)

                    TextField("Exchange", text: $viewModel.exchange)
                }
            }

            Section("Position") {
                HStack {
                    Text("Quantity")
                    Spacer()
                    TextField("0", text: $viewModel.quantity)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Purchase Price")
                    Spacer()
                    TextField("0.00", text: $viewModel.purchasePrice)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Current Price")
                    Spacer()
                    if viewModel.isLoadingPrice {
                        ProgressView()
                    } else {
                        TextField("0.00", text: $viewModel.currentPrice)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Picker("Currency", selection: $viewModel.purchaseCurrency) {
                    ForEach(SettingsViewModel.supportedCurrencies, id: \.self) { currency in
                        Text(currency).tag(currency)
                    }
                }
            }

            Section("Date & Notes") {
                DatePicker("Purchase Date", selection: $viewModel.purchaseDate, displayedComponents: .date)

                TextField("Notes (optional)", text: $viewModel.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            if viewModel.isValid {
                Section("Summary") {
                    HStack {
                        Text("Total Cost")
                        Spacer()
                        Text(CurrencyFormatter.format(viewModel.totalCost, currency: viewModel.purchaseCurrency))
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("Current Value")
                        Spacer()
                        Text(CurrencyFormatter.format(viewModel.totalValue, currency: viewModel.purchaseCurrency))
                            .fontWeight(.medium)
                    }
                }
            }

            Section {
                Button(isEditing ? "Save Changes" : "Add Holding") {
                    onSave()
                    if !isEditing {
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .fontWeight(.semibold)
                .disabled(!viewModel.isValid)
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

    private var cryptoSearchSection: some View {
        Section("Search Cryptocurrency") {
            TextField("Search coins...", text: $viewModel.cryptoSearchQuery)
                .textInputAutocapitalization(.never)
                .onChange(of: viewModel.cryptoSearchQuery) { _, _ in
                    viewModel.searchCrypto()
                }

            if viewModel.isSearching {
                HStack {
                    ProgressView()
                    Text("Searching...")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !viewModel.cryptoSearchResults.isEmpty {
                ForEach(viewModel.cryptoSearchResults) { coin in
                    Button {
                        viewModel.selectCoin(coin)
                    } label: {
                        HStack {
                            AsyncImage(url: URL(string: coin.thumb ?? "")) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } placeholder: {
                                Image(systemName: "bitcoinsign.circle")
                                    .foregroundStyle(.orange)
                            }
                            .frame(width: 24, height: 24)

                            VStack(alignment: .leading) {
                                Text(coin.name)
                                    .font(.body)
                                    .foregroundStyle(.primary)
                                Text(coin.symbol.uppercased())
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            if let rank = coin.marketCapRank {
                                Text("#\(rank)")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }

                            if viewModel.selectedCoin?.id == coin.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                }
            }
        }
    }
}
