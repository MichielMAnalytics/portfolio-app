import SwiftUI

struct HoldingRowView: View {
    let holding: Holding
    let currency: String

    var body: some View {
        HStack(spacing: 12) {
            assetIcon

            VStack(alignment: .leading, spacing: 3) {
                Text(holding.symbol)
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                Text("\(CurrencyFormatter.formatQuantity(holding.quantity)) | \(CurrencyFormatter.formatPrice(holding.purchasePrice, currency: currency))")
                    .font(.caption)
                    .foregroundStyle(FolioTheme.labelGray)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(CurrencyFormatter.format(holding.totalValue, currency: currency))
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Text(CurrencyFormatter.format(holding.profitLoss, currency: currency, showSign: true))
                        .font(.caption)
                        .foregroundStyle(holding.profitLoss >= 0 ? FolioTheme.positive : FolioTheme.negative)

                    ValueChangeChip(percentage: holding.profitLossPercentage)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    @ViewBuilder
    private var assetIcon: some View {
        if holding.assetType == .crypto {
            // For crypto, try to use CoinGecko thumb image
            AsyncImage(url: cryptoIconURL) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(Circle())
                case .failure, .empty:
                    fallbackIcon
                @unknown default:
                    fallbackIcon
                }
            }
        } else {
            fallbackIcon
        }
    }

    private var fallbackIcon: some View {
        Image(systemName: holding.assetType.sfSymbol)
            .font(.body)
            .foregroundStyle(holding.assetType.color)
            .frame(width: 40, height: 40)
            .background(holding.assetType.color.opacity(0.15), in: Circle())
    }

    private var cryptoIconURL: URL? {
        // Build a CoinGecko thumb URL from symbol
        let symbol = holding.symbol.lowercased()
        return URL(string: "https://assets.coingecko.com/coins/images/1/thumb/\(symbol).png")
    }
}

#Preview {
    VStack(spacing: 0) {
        HoldingRowView(
            holding: {
                let h = Holding(
                    name: "Bitcoin",
                    symbol: "BTC",
                    quantity: 0.6128,
                    purchasePrice: 70550.02,
                    currentPrice: 97842.50,
                    assetType: .crypto
                )
                return h
            }(),
            currency: "EUR"
        )

        Divider().background(FolioTheme.secondaryBackground).padding(.leading, 56)

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
    }
    .background(FolioTheme.cardBackground)
    .padding()
    .background(FolioTheme.background)
}
