import SwiftUI

struct HoldingRowView: View {
    let holding: Holding
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            assetIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(holding.name)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(holding.symbol)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(CurrencyFormatter.formatQuantity(holding.quantity)) units")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.format(holding.totalValue, currency: currency))
                    .font(.body)
                    .fontWeight(.semibold)

                ValueChangeChip(percentage: holding.profitLossPercentage)
            }
        }
        .padding(.vertical, 4)
    }

    private var assetIcon: some View {
        Image(systemName: holding.assetType.sfSymbol)
            .font(.title3)
            .foregroundStyle(holding.assetType.color)
            .frame(width: 36, height: 36)
            .background(holding.assetType.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    List {
        HoldingRowView(
            holding: {
                let h = Holding(
                    name: "Apple Inc.",
                    symbol: "AAPL",
                    quantity: 50,
                    purchasePrice: 150,
                    currentPrice: 178.50,
                    assetType: .stock
                )
                return h
            }(),
            currency: "USD"
        )

        HoldingRowView(
            holding: {
                let h = Holding(
                    name: "Bitcoin",
                    symbol: "BTC",
                    quantity: 0.5,
                    purchasePrice: 30000,
                    currentPrice: 65000,
                    assetType: .crypto
                )
                return h
            }(),
            currency: "USD"
        )
    }
}
