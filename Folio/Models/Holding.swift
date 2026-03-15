import Foundation
import SwiftData

@Model
final class Holding {
    var id: UUID
    var name: String
    var symbol: String
    var quantity: Double
    var purchasePrice: Double
    var purchaseCurrency: String
    var currentPrice: Double
    var assetTypeRaw: String
    var purchaseDate: Date
    var notes: String
    var exchange: String
    var isin: String
    var yahooSymbol: String

    @Relationship(inverse: \Portfolio.holdings)
    var portfolio: Portfolio?

    /// The ticker to use for Yahoo Finance price lookups.
    /// Falls back to symbol if yahooSymbol is empty.
    var priceSymbol: String {
        yahooSymbol.isEmpty ? symbol : yahooSymbol
    }

    var assetType: AssetType {
        get { AssetType(rawValue: assetTypeRaw) ?? .other }
        set { assetTypeRaw = newValue.rawValue }
    }

    var totalValue: Double {
        quantity * currentPrice
    }

    var totalCost: Double {
        quantity * purchasePrice
    }

    var profitLoss: Double {
        totalValue - totalCost
    }

    var profitLossPercentage: Double {
        guard totalCost > 0 else { return 0 }
        return (profitLoss / totalCost) * 100
    }

    init(
        id: UUID = UUID(),
        name: String = "",
        symbol: String = "",
        quantity: Double = 0,
        purchasePrice: Double = 0,
        purchaseCurrency: String = "USD",
        currentPrice: Double = 0,
        assetType: AssetType = .other,
        purchaseDate: Date = Date(),
        notes: String = "",
        exchange: String = "",
        isin: String = "",
        yahooSymbol: String = ""
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.quantity = quantity
        self.purchasePrice = purchasePrice
        self.purchaseCurrency = purchaseCurrency
        self.currentPrice = currentPrice
        self.assetTypeRaw = assetType.rawValue
        self.purchaseDate = purchaseDate
        self.notes = notes
        self.exchange = exchange
        self.isin = isin
        self.yahooSymbol = yahooSymbol
    }
}
