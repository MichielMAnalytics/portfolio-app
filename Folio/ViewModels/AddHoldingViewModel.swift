import Foundation
import SwiftUI

@MainActor
@Observable
final class AddHoldingViewModel {
    var name: String = ""
    var symbol: String = ""
    var quantity: String = ""
    var purchasePrice: String = ""
    var currentPrice: String = ""
    var purchaseCurrency: String = "USD"
    var assetType: AssetType = .stock
    var purchaseDate: Date = Date()
    var notes: String = ""
    var exchange: String = ""
    var isin: String = ""

    var cryptoSearchQuery: String = ""
    var cryptoSearchResults: [CoinSearchResult] = []
    var selectedCoin: CoinSearchResult?

    var stockSearchQuery: String = ""
    var stockSearchResults: [YahooSearchResult] = []
    var selectedStock: YahooSearchResult?

    var isSearching = false
    var isLoadingPrice = false
    var errorMessage: String?

    private var searchTask: Task<Void, Never>?

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !symbol.trimmingCharacters(in: .whitespaces).isEmpty &&
        (Double(quantity) ?? 0) > 0 &&
        (Double(purchasePrice) ?? 0) >= 0
    }

    var quantityValue: Double {
        Double(quantity) ?? 0
    }

    var purchasePriceValue: Double {
        Double(purchasePrice) ?? 0
    }

    var currentPriceValue: Double {
        Double(currentPrice) ?? 0
    }

    var totalCost: Double {
        quantityValue * purchasePriceValue
    }

    var totalValue: Double {
        quantityValue * currentPriceValue
    }

    func searchCrypto() {
        searchTask?.cancel()

        let query = cryptoSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            cryptoSearchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            defer { isSearching = false }

            do {
                let results = try await CoinGeckoService.shared.searchCoins(query: query)
                if !Task.isCancelled {
                    cryptoSearchResults = Array(results.prefix(20))
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectCoin(_ coin: CoinSearchResult) {
        selectedCoin = coin
        name = coin.name
        symbol = coin.symbol.uppercased()
        cryptoSearchQuery = coin.name
        cryptoSearchResults = []

        Task {
            await fetchCoinPrice(coinId: coin.id)
        }
    }

    func fetchCoinPrice(coinId: String) async {
        isLoadingPrice = true
        defer { isLoadingPrice = false }

        do {
            if let price = try await CoinGeckoService.shared.fetchPriceForCoin(id: coinId) {
                currentPrice = String(format: "%.2f", price)
                    if purchasePrice.isEmpty {
                        purchasePrice = currentPrice
                    }
            }
        } catch {
            errorMessage = "Failed to fetch price: \(error.localizedDescription)"
        }
    }

    func createHolding() -> Holding {
        Holding(
            name: name.trimmingCharacters(in: .whitespaces),
            symbol: symbol.trimmingCharacters(in: .whitespaces).uppercased(),
            quantity: quantityValue,
            purchasePrice: purchasePriceValue,
            purchaseCurrency: purchaseCurrency,
            currentPrice: currentPriceValue > 0 ? currentPriceValue : purchasePriceValue,
            assetType: assetType,
            purchaseDate: purchaseDate,
            notes: notes.trimmingCharacters(in: .whitespaces),
            exchange: exchange.trimmingCharacters(in: .whitespaces),
            isin: isin.trimmingCharacters(in: .whitespaces)
        )
    }

    // MARK: - Stock/ETF Search (Yahoo Finance)

    func searchStocks() {
        searchTask?.cancel()

        let query = stockSearchQuery.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            stockSearchResults = []
            return
        }

        searchTask = Task {
            isSearching = true
            defer { isSearching = false }

            do {
                let results = try await YahooFinanceService.shared.search(query: query)
                if !Task.isCancelled {
                    stockSearchResults = Array(results.prefix(15))
                }
            } catch {
                if !Task.isCancelled {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    func selectStock(_ stock: YahooSearchResult) {
        selectedStock = stock
        name = stock.displayName
        symbol = stock.symbol
        exchange = stock.exchDisp ?? stock.exchange ?? ""
        assetType = stock.assetType
        stockSearchQuery = stock.displayName
        stockSearchResults = []

        Task {
            await fetchStockPrice(symbol: stock.symbol)
        }
    }

    func fetchStockPrice(symbol: String) async {
        isLoadingPrice = true
        defer { isLoadingPrice = false }

        do {
            if let quote = try await YahooFinanceService.shared.fetchQuote(symbol: symbol),
               let price = quote.regularMarketPrice {
                currentPrice = String(format: "%.2f", price)
                if purchasePrice.isEmpty {
                    purchasePrice = currentPrice
                }
                if let cur = quote.currency {
                    purchaseCurrency = cur
                }
            }
        } catch {
            errorMessage = "Failed to fetch price: \(error.localizedDescription)"
        }
    }

    func reset() {
        name = ""
        symbol = ""
        quantity = ""
        purchasePrice = ""
        currentPrice = ""
        purchaseCurrency = "USD"
        assetType = .stock
        purchaseDate = Date()
        notes = ""
        exchange = ""
        isin = ""
        cryptoSearchQuery = ""
        cryptoSearchResults = []
        selectedCoin = nil
        stockSearchQuery = ""
        stockSearchResults = []
        selectedStock = nil
        errorMessage = nil
    }

    func populateForEditing(_ holding: Holding) {
        name = holding.name
        symbol = holding.symbol
        quantity = String(holding.quantity)
        purchasePrice = String(holding.purchasePrice)
        currentPrice = String(holding.currentPrice)
        purchaseCurrency = holding.purchaseCurrency
        assetType = holding.assetType
        purchaseDate = holding.purchaseDate
        notes = holding.notes
        exchange = holding.exchange
        isin = holding.isin
    }

    func applyChanges(to holding: Holding) {
        holding.name = name.trimmingCharacters(in: .whitespaces)
        holding.symbol = symbol.trimmingCharacters(in: .whitespaces).uppercased()
        holding.quantity = quantityValue
        holding.purchasePrice = purchasePriceValue
        holding.currentPrice = currentPriceValue > 0 ? currentPriceValue : purchasePriceValue
        holding.purchaseCurrency = purchaseCurrency
        holding.assetType = assetType
        holding.purchaseDate = purchaseDate
        holding.notes = notes.trimmingCharacters(in: .whitespaces)
        holding.exchange = exchange.trimmingCharacters(in: .whitespaces)
        holding.isin = isin.trimmingCharacters(in: .whitespaces)
    }
}
