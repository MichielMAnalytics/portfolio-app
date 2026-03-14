import SwiftUI

struct PortfolioSummaryCard: View {
    let totalValue: Double
    let totalCost: Double
    let profitLoss: Double
    let profitLossPercentage: Double
    let currency: String
    let holdingsCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total value")
                .font(.subheadline)
                .foregroundStyle(FolioTheme.labelGray)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(formattedValue)
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(currency)
                        .font(.subheadline)
                        .foregroundStyle(FolioTheme.labelGray)

                    Image(systemName: "arrow.left.arrow.right")
                        .font(.caption2)
                        .foregroundStyle(FolioTheme.labelGray)
                }
            }

            if totalCost > 0 {
                ValueChangeView(
                    value: profitLoss,
                    percentage: profitLossPercentage,
                    currency: currency,
                    font: .subheadline
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 4)
    }

    private var formattedValue: String {
        CurrencyFormatter.formatBareNumber(totalValue)
    }
}

#Preview {
    PortfolioSummaryCard(
        totalValue: 87947.40,
        totalCost: 82615.30,
        profitLoss: 5332.10,
        profitLossPercentage: 6.45,
        currency: "EUR",
        holdingsCount: 12
    )
    .padding()
    .background(FolioTheme.background)
}
