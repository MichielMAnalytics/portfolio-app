import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let totalCost: Double
    let profitLoss: Double
    let profitLossPercentage: Double
    let currency: String
    let holdingsCount: Int

    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text("Portfolio Value")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(CurrencyFormatter.format(totalValue, currency: currency))
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }

            if totalCost > 0 {
                ValueChangeView(
                    value: profitLoss,
                    percentage: profitLossPercentage,
                    currency: currency,
                    font: .body
                )
            }

            Divider()

            HStack(spacing: 0) {
                summaryItem(title: "Invested", value: CurrencyFormatter.format(totalCost, currency: currency))
                Divider()
                    .frame(height: 30)
                summaryItem(title: "Returns", value: CurrencyFormatter.format(profitLoss, currency: currency, showSign: true))
                Divider()
                    .frame(height: 30)
                summaryItem(title: "Holdings", value: "\(holdingsCount)")
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PortfolioSummaryCard(
        totalValue: 125678.90,
        totalCost: 100000,
        profitLoss: 25678.90,
        profitLossPercentage: 25.68,
        currency: "USD",
        holdingsCount: 12
    )
    .padding()
}
