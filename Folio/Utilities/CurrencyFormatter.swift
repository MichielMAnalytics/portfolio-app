import Foundation

struct CurrencyFormatter {
    static func format(_ value: Double, currency: String = "USD", showSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        if showSign && value > 0 {
            formatter.positivePrefix = "+\(formatter.positivePrefix ?? "")"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    /// Formats just the numeric portion without currency symbol, using locale grouping.
    static func formatBareNumber(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "0.00"
    }

    static func formatLarge(_ value: Double, currency: String = "USD") -> String {
        if abs(value) >= 1_000_000_000 {
            return formatCompact(value / 1_000_000_000, suffix: "B", currency: currency)
        } else if abs(value) >= 1_000_000 {
            return formatCompact(value / 1_000_000, suffix: "M", currency: currency)
        } else if abs(value) >= 1_000 {
            return formatCompact(value / 1_000, suffix: "K", currency: currency)
        }
        return format(value, currency: currency)
    }

    private static func formatCompact(_ value: Double, suffix: String, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1

        let formatted = formatter.string(from: NSNumber(value: value)) ?? "$0.0"
        return "\(formatted)\(suffix)"
    }

    static func formatPercentage(_ value: Double, showSign: Bool = true) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.multiplier = 1

        if showSign && value > 0 {
            formatter.positivePrefix = "+"
        }

        return formatter.string(from: NSNumber(value: value)) ?? "0.00%"
    }

    static func formatQuantity(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal

        if value == value.rounded() && value < 1_000_000 {
            formatter.minimumFractionDigits = 0
            formatter.maximumFractionDigits = 0
        } else if value < 1 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 4
        }

        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }

    static func formatPrice(_ value: Double, currency: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency

        if value < 0.01 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 8
        } else if value < 1 {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 4
        } else {
            formatter.minimumFractionDigits = 2
            formatter.maximumFractionDigits = 2
        }

        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}
