import SwiftUI

struct ValueChangeView: View {
    let value: Double
    let percentage: Double
    let currency: String
    var showValue: Bool = true
    var showPercentage: Bool = true
    var font: Font = .subheadline

    private var changeColor: Color {
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .secondary
    }

    private var arrowSymbol: String {
        if value > 0 { return "arrow.up.right" }
        if value < 0 { return "arrow.down.right" }
        return "arrow.right"
    }

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: arrowSymbol)
                .font(.caption)
                .foregroundStyle(changeColor)

            if showValue {
                Text(CurrencyFormatter.format(abs(value), currency: currency, showSign: false))
                    .font(font)
                    .foregroundStyle(changeColor)
            }

            if showPercentage {
                Text("(\(CurrencyFormatter.formatPercentage(percentage)))")
                    .font(font)
                    .foregroundStyle(changeColor)
            }
        }
    }
}

struct ValueChangeChip: View {
    let percentage: Double

    private var changeColor: Color {
        if percentage > 0 { return .green }
        if percentage < 0 { return .red }
        return .secondary
    }

    private var backgroundColor: Color {
        if percentage > 0 { return .green.opacity(0.15) }
        if percentage < 0 { return .red.opacity(0.15) }
        return .secondary.opacity(0.15)
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
}
