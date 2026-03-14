import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class PortfolioViewModel {
    var portfolio: Portfolio?
    var isRefreshing = false
    var errorMessage: String?
    var lastRefreshDate: Date?
    var cryptoPrices: [String: CryptoMarketData] = [:]

    private var modelContext: ModelContext?

    var totalValue: Double {
        portfolio?.totalValue ?? 0
    }

    var totalCost: Double {
        portfolio?.totalCost ?? 0
    }

    var totalProfitLoss: Double {
        portfolio?.totalProfitLoss ?? 0
    }

    var totalProfitLossPercentage: Double {
        portfolio?.totalProfitLossPercentage ?? 0
    }

    var holdings: [Holding] {
        portfolio?.holdings ?? []
    }

    var holdingsByAssetType: [AssetType: [Holding]] {
        Dictionary(grouping: holdings) { $0.assetType }
    }

    var allocationData: [(assetType: AssetType, value: Double, percentage: Double)] {
        portfolio?.allocationByAssetType ?? []
    }

    var topGainers: [Holding] {
        holdings
            .filter { $0.profitLossPercentage > 0 }
            .sorted { $0.profitLossPercentage > $1.profitLossPercentage }
            .prefix(5)
            .map { $0 }
    }

    var topLosers: [Holding] {
        holdings
            .filter { $0.profitLossPercentage < 0 }
            .sorted { $0.profitLossPercentage < $1.profitLossPercentage }
            .prefix(5)
            .map { $0 }
    }

    func setup(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadOrCreatePortfolio()
    }

    private func loadOrCreatePortfolio() {
        guard let modelContext else { return }

        let descriptor = FetchDescriptor<Portfolio>()
        do {
            let portfolios = try modelContext.fetch(descriptor)
            if let existing = portfolios.first {
                portfolio = existing
            } else {
                let newPortfolio = Portfolio()
                modelContext.insert(newPortfolio)
                try modelContext.save()
                portfolio = newPortfolio
            }
        } catch {
            errorMessage = "Failed to load portfolio: \(error.localizedDescription)"
        }
    }

    func addHolding(_ holding: Holding) {
        guard let portfolio, let modelContext else { return }

        portfolio.holdings.append(holding)
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save holding: \(error.localizedDescription)"
        }
    }

    func addHoldings(_ newHoldings: [Holding]) {
        guard let portfolio, let modelContext else { return }

        for holding in newHoldings {
            portfolio.holdings.append(holding)
        }
        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to save holdings: \(error.localizedDescription)"
        }
    }

    func deleteHolding(_ holding: Holding) {
        guard let portfolio, let modelContext else { return }

        if let index = portfolio.holdings.firstIndex(where: { $0.id == holding.id }) {
            portfolio.holdings.remove(at: index)
            modelContext.delete(holding)
            do {
                try modelContext.save()
            } catch {
                errorMessage = "Failed to delete holding: \(error.localizedDescription)"
            }
        }
    }

    func updateHolding(_ holding: Holding) {
        guard let modelContext else { return }

        do {
            try modelContext.save()
        } catch {
            errorMessage = "Failed to update holding: \(error.localizedDescription)"
        }
    }

    func refreshPrices() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        errorMessage = nil

        defer {
            isRefreshing = false
            lastRefreshDate = Date()
        }

        // Refresh crypto prices via CoinGecko
        await refreshCryptoPrices()

        // Refresh stock/ETF/other prices via Yahoo Finance
        await refreshStockPrices()

        if let modelContext {
            try? modelContext.save()
        }
    }

    private func refreshCryptoPrices() async {
        let cryptoHoldings = holdings.filter { $0.assetType == .crypto }
        guard !cryptoHoldings.isEmpty else { return }

        let coinIds = cryptoHoldings.compactMap { $0.symbol.lowercased() }

        do {
            let marketData = try await CoinGeckoService.shared.fetchMarketData(coinIds: coinIds)

            for data in marketData {
                cryptoPrices[data.id] = data

                for holding in cryptoHoldings {
                    if holding.symbol.lowercased() == data.symbol.lowercased() ||
                       holding.symbol.lowercased() == data.id.lowercased() {
                        if let price = data.currentPrice {
                            holding.currentPrice = price
                        }
                    }
                }
            }
        } catch {
            errorMessage = "Failed to refresh crypto prices: \(error.localizedDescription)"
        }
    }

    private func refreshStockPrices() async {
        let stockHoldings = holdings.filter { $0.assetType != .crypto && $0.assetType != .cash }
        guard !stockHoldings.isEmpty else { return }

        let symbols = Array(Set(stockHoldings.map { $0.symbol.uppercased() }))

        do {
            let quotes = try await YahooFinanceService.shared.fetchQuotes(symbols: symbols)

            for holding in stockHoldings {
                if let quote = quotes[holding.symbol.uppercased()],
                   let price = quote.regularMarketPrice {
                    holding.currentPrice = price
                }
            }
        } catch {
            let existing = errorMessage ?? ""
            let stockError = "Failed to refresh stock prices: \(error.localizedDescription)"
            errorMessage = existing.isEmpty ? stockError : "\(existing)\n\(stockError)"
        }
    }
}
