import SwiftUI

struct ExtractedHoldingsReviewView: View {
    @Binding var holdings: [ExtractedHolding]
    let onConfirm: ([ExtractedHolding]) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Review the extracted holdings below. Tap to edit any field before importing.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Section("Extracted Holdings (\(holdings.count))") {
                    ForEach($holdings) { $holding in
                        extractedHoldingRow(holding: $holding)
                    }
                    .onDelete(perform: deleteHoldings)
                }

                if !holdings.isEmpty {
                    Section {
                        Button("Import \(holdings.count) Holdings") {
                            onConfirm(holdings)
                        }
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                    }
                }
            }
            .navigationTitle("Review Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
            }
        }
    }

    private func extractedHoldingRow(holding: Binding<ExtractedHolding>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    TextField("Name", text: Binding(
                        get: { holding.wrappedValue.name ?? "" },
                        set: { holding.wrappedValue.name = $0 }
                    ))
                    .font(.body)
                    .fontWeight(.medium)

                    TextField("Symbol", text: Binding(
                        get: { holding.wrappedValue.symbol ?? "" },
                        set: { holding.wrappedValue.symbol = $0 }
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textInputAutocapitalization(.characters)
                }

                Spacer()

                if let value = holding.wrappedValue.totalValue {
                    Text(CurrencyFormatter.format(value))
                        .font(.body)
                        .fontWeight(.semibold)
                }
            }

            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Text("Qty:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0", value: Binding(
                        get: { holding.wrappedValue.quantity ?? 0 },
                        set: { holding.wrappedValue.quantity = $0 }
                    ), format: .number)
                    .font(.caption)
                    .keyboardType(.decimalPad)
                    .frame(width: 60)
                }

                HStack(spacing: 4) {
                    Text("Price:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("0.00", value: Binding(
                        get: { holding.wrappedValue.currentPrice ?? 0 },
                        set: { holding.wrappedValue.currentPrice = $0 }
                    ), format: .number)
                    .font(.caption)
                    .keyboardType(.decimalPad)
                    .frame(width: 80)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func deleteHoldings(at offsets: IndexSet) {
        holdings.remove(atOffsets: offsets)
    }
}
