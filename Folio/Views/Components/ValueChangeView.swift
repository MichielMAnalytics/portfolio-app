import SwiftUI

struct ValueChangeView: View {
    let value: Double
    let percentage: Double
    let currency: String
    var showValue: Bool = true
    var showPercentage: Bool = true
    var font: Font = .subheadline

    private var changeColor: Color {
        if value > 0 { return FolioTheme.positive }
        if value < 0 { return FolioTheme.negative }
        return FolioTheme.labelGray
    }

    var body: some View {
        HStack(spacing: 6) {
            if showValue {
                Text(CurrencyFormatter.format(value, currency: currency, showSign: true))
                    .font(font)
                    .foregroundStyle(changeColor)
            }

            if showPercentage {
                ValueChangeChip(percentage: percentage)
            }
        }
    }
}

struct ValueChangeChip: View {
    let percentage: Double

    private var changeColor: Color {
        if percentage > 0 { return FolioTheme.positive }
        if percentage < 0 { return FolioTheme.negative }
        return FolioTheme.labelGray
    }

    private var backgroundColor: Color {
        if percentage > 0 { return FolioTheme.positiveBadgeBg }
        if percentage < 0 { return FolioTheme.negativeBadgeBg }
        return FolioTheme.chipBackground
    }

    var body: some View {
        Text(CurrencyFormatter.formatPercentage(percentage))
            .font(.caption)
            .fontWeight(.medium)
            .foregroundStyle(changeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor, in: Capsule())
    }
}

#Preview {
    VStack(spacing: 20) {
        ValueChangeView(value: 1234.56, percentage: 12.5, currency: "USD")
        ValueChangeView(value: -567.89, percentage: -5.2, currency: "USD")
        ValueChangeView(value: 0, percentage: 0, currency: "USD")

        HStack {
            ValueChangeChip(percentage: 8.5)
            ValueChangeChip(percentage: -3.2)
            ValueChangeChip(percentage: 0)
        }
    }
    .padding()
    .background(FolioTheme.background)
}
