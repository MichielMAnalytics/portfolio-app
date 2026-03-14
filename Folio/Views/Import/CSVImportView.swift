import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Bindable var importViewModel: ImportViewModel
    @Bindable var portfolioViewModel: PortfolioViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showFilePicker = false
    @State private var showColumnMapping = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if importViewModel.csvHeaders.isEmpty {
                    filePickerPrompt
                } else if !importViewModel.parsedCSVHoldings.isEmpty {
                    csvPreview
                } else {
                    noDataView
                }

                Spacer()
            }
            .padding()
            .background(FolioTheme.background)
            .navigationTitle("CSV Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FolioTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        importViewModel.resetCSVImport()
                        dismiss()
                    }
                }
            }
            .fileImporter(
                isPresented: $showFilePicker,
                allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importViewModel.processCSV(url: url)
                    }
                case .failure(let error):
                    importViewModel.errorMessage = error.localizedDescription
                    importViewModel.showError = true
                }
            }
            .sheet(isPresented: $showColumnMapping) {
                columnMappingSheet
            }
            .sheet(isPresented: $importViewModel.showCSVReview) {
                csvReviewSheet
            }
            .alert("Error", isPresented: $importViewModel.showError) {
                Button("OK") { importViewModel.showError = false }
            } message: {
                Text(importViewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }

    private var filePickerPrompt: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(FolioTheme.labelGray)

            Text("Import from CSV")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Select a CSV file exported from your broker. Supports Trade Republic exports and generic CSV formats.")
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)
                .multilineTextAlignment(.center)

            Button {
                showFilePicker = true
            } label: {
                Label("Choose CSV File", systemImage: "doc.badge.plus")
                    .font(.body)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(FolioTheme.positive, in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.black)
            }
            .padding(.top, 8)

            VStack(alignment: .leading, spacing: 8) {
                Text("Supported formats:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)

                ForEach(["Trade Republic CSV export", "Generic CSV with headers", "Semicolon or comma separated"], id: \.self) { format in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(FolioTheme.positive)
                        Text(format)
                            .font(.caption)
                            .foregroundStyle(FolioTheme.labelGray)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
        }
        .padding(.top, 40)
    }

    private var csvPreview: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("\(importViewModel.parsedCSVHoldings.count) holdings found")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(importViewModel.csvRows.count) rows parsed")
                        .font(.caption)
                        .foregroundStyle(FolioTheme.labelGray)
                }
                Spacer()

                Button("Remap Columns") {
                    showColumnMapping = true
                }
                .font(.caption)
                .foregroundStyle(FolioTheme.positive)
            }

            List {
                ForEach(importViewModel.parsedCSVHoldings) { holding in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(holding.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.white)
                            Spacer()
                            Text(CurrencyFormatter.formatQuantity(holding.quantity))
                                .font(.caption)
                                .foregroundStyle(FolioTheme.labelGray)
                        }
                        HStack {
                            if !holding.isin.isEmpty {
                                Text(holding.isin)
                                    .font(.caption)
                                    .foregroundStyle(FolioTheme.labelGray)
                            }
                            Spacer()
                            Text(CurrencyFormatter.formatPrice(holding.price, currency: holding.currency))
                                .font(.caption)
                                .foregroundStyle(FolioTheme.labelGray)
                        }
                    }
                    .padding(.vertical, 2)
                    .listRowBackground(FolioTheme.cardBackground)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .frame(maxHeight: 400)

            HStack(spacing: 12) {
                Button {
                    importViewModel.resetCSVImport()
                } label: {
                    Text("Reset")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FolioTheme.cardBackground, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }

                Button {
                    let holdings = importViewModel.createHoldingsFromCSV()
                    portfolioViewModel.addHoldings(holdings)
                    importViewModel.importSuccessCount = holdings.count
                    importViewModel.showImportSuccess = true
                    importViewModel.resetCSVImport()
                    dismiss()
                } label: {
                    Text("Import \(importViewModel.parsedCSVHoldings.count) Holdings")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(FolioTheme.positive, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.black)
                }
            }
        }
    }

    private var noDataView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(.orange)

            Text("No holdings could be extracted")
                .font(.headline)
                .foregroundStyle(.white)

            Text("Try adjusting the column mapping or use a different CSV file.")
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Choose Another File") {
                    importViewModel.resetCSVImport()
                    showFilePicker = true
                }
                .buttonStyle(.bordered)
                .tint(FolioTheme.positive)

                Button("Adjust Mapping") {
                    showColumnMapping = true
                }
                .buttonStyle(.borderedProminent)
                .tint(FolioTheme.positive)
            }
        }
        .padding(.top, 40)
    }

    private var columnMappingSheet: some View {
        NavigationStack {
            Form {
                Section("Column Mapping") {
                    Text("Assign CSV columns to the correct fields")
                        .font(.caption)
                        .foregroundStyle(FolioTheme.labelGray)

                    columnPicker("Name / Asset", selection: $importViewModel.columnMapping.nameColumn)
                    columnPicker("Symbol", selection: $importViewModel.columnMapping.symbolColumn)
                    columnPicker("ISIN", selection: $importViewModel.columnMapping.isinColumn)
                    columnPicker("Quantity", selection: $importViewModel.columnMapping.quantityColumn)
                    columnPicker("Price", selection: $importViewModel.columnMapping.priceColumn)
                    columnPicker("Amount / Total", selection: $importViewModel.columnMapping.amountColumn)
                    columnPicker("Date", selection: $importViewModel.columnMapping.dateColumn)
                    columnPicker("Type (Buy/Sell)", selection: $importViewModel.columnMapping.typeColumn)
                    columnPicker("Currency", selection: $importViewModel.columnMapping.currencyColumn)
                }
                .listRowBackground(FolioTheme.cardBackground)
            }
            .scrollContentBackground(.hidden)
            .background(FolioTheme.background)
            .navigationTitle("Column Mapping")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Apply") {
                        importViewModel.remapCSV()
                        showColumnMapping = false
                    }
                    .foregroundStyle(FolioTheme.positive)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        showColumnMapping = false
                    }
                }
            }
        }
    }

    private func columnPicker(_ title: String, selection: Binding<Int?>) -> some View {
        Picker(title, selection: selection) {
            Text("Not Mapped").tag(nil as Int?)
            ForEach(Array(importViewModel.csvHeaders.enumerated()), id: \.offset) { index, header in
                Text(header).tag(index as Int?)
            }
        }
        .tint(FolioTheme.positive)
    }

    private var csvReviewSheet: some View {
        NavigationStack {
            List {
                ForEach(importViewModel.parsedCSVHoldings) { holding in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(holding.name)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                        HStack {
                            Text("Qty: \(CurrencyFormatter.formatQuantity(holding.quantity))")
                            Spacer()
                            Text(CurrencyFormatter.formatPrice(holding.price, currency: holding.currency))
                        }
                        .font(.caption)
                        .foregroundStyle(FolioTheme.labelGray)
                    }
                    .listRowBackground(FolioTheme.cardBackground)
                }
            }
            .scrollContentBackground(.hidden)
            .background(FolioTheme.background)
            .navigationTitle("Review")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import") {
                        let holdings = importViewModel.createHoldingsFromCSV()
                        portfolioViewModel.addHoldings(holdings)
                        importViewModel.showCSVReview = false
                        dismiss()
                    }
                    .foregroundStyle(FolioTheme.positive)
                }
            }
        }
    }
}
