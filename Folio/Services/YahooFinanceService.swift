import Foundation

actor YahooFinanceService {
    static let shared = YahooFinanceService()

    private let baseURL = "https://query1.finance.yahoo.com"
    private let chartURL = "https://query1.finance.yahoo.com/v8/finance/chart"
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    private var quoteCache: [String: CachedData<[String: YahooQuote]>] = [:]
    private var searchCache: [String: CachedData<[YahooSearchResult]>] = [:]
    private var chartCache: [String: CachedData<[YahooChartPoint]>] = [:]

    private struct CachedData<T> {
        let data: T
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }

    private init() {}

    // MARK: - Quotes

    func fetchQuotes(symbols: [String]) async throws -> [String: YahooQuote] {
        guard !symbols.isEmpty else { return [:] }

        let symbolString = symbols.joined(separator: ",")
        let cacheKey = symbolString

        if let cached = quoteCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        var components = URLComponents(string: "\(baseURL)/v7/finance/quote")!
        components.queryItems = [
            URLQueryItem(name: "symbols", value: symbolString),
            URLQueryItem(name: "fields", value: "symbol,shortName,longName,regularMarketPrice,regularMarketChange,regularMarketChangePercent,regularMarketPreviousClose,regularMarketOpen,regularMarketDayHigh,regularMarketDayLow,regularMarketVolume,marketCap,fiftyTwoWeekHigh,fiftyTwoWeekLow,currency,exchangeTimezoneName,exchange,quoteType"),
        ]

        guard let url = components.url else {
            throw YahooFinanceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw YahooFinanceError.rateLimited
            }
            throw YahooFinanceError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let quoteResponse = try decoder.decode(YahooQuoteResponse.self, from: data)

        var result: [String: YahooQuote] = [:]
        for quote in quoteResponse.quoteResponse.result {
            result[quote.symbol.uppercased()] = quote
        }

        quoteCache[cacheKey] = CachedData(data: result, timestamp: Date())
        return result
    }

    func fetchQuote(symbol: String) async throws -> YahooQuote? {
        let quotes = try await fetchQuotes(symbols: [symbol])
        return quotes[symbol.uppercased()]
    }

    // MARK: - Search

    func search(query: String) async throws -> [YahooSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lowercased = query.lowercased()
        if let cached = searchCache[lowercased], !cached.isExpired {
            return cached.data
        }

        var components = URLComponents(string: "\(baseURL)/v1/finance/search")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "quotesCount", value: "15"),
            URLQueryItem(name: "newsCount", value: "0"),
            URLQueryItem(name: "listsCount", value: "0"),
            URLQueryItem(name: "enableFuzzyQuery", value: "false"),
            URLQueryItem(name: "quotesQueryId", value: "tss_match_phrase_query"),
        ]

        guard let url = components.url else {
            throw YahooFinanceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw YahooFinanceError.rateLimited
            }
            throw YahooFinanceError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(YahooSearchResponse.self, from: data)

        let results = searchResponse.quotes.filter { result in
            let type = result.quoteType?.uppercased() ?? ""
            return type == "EQUITY" || type == "ETF" || type == "MUTUALFUND" || type == "INDEX"
        }

        searchCache[lowercased] = CachedData(data: results, timestamp: Date())
        return results
    }

    // MARK: - Chart Data

    func fetchChart(symbol: String, range: String = "1mo", interval: String = "1d") async throws -> [YahooChartPoint] {
        let cacheKey = "\(symbol)_\(range)_\(interval)"

        if let cached = chartCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        var components = URLComponents(string: "\(chartURL)/\(symbol)")!
        components.queryItems = [
            URLQueryItem(name: "range", value: range),
            URLQueryItem(name: "interval", value: interval),
            URLQueryItem(name: "includeAdjustedClose", value: "true"),
        ]

        guard let url = components.url else {
            throw YahooFinanceError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw YahooFinanceError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw YahooFinanceError.rateLimited
            }
            throw YahooFinanceError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let chartResponse = try decoder.decode(YahooChartResponse.self, from: data)

        guard let result = chartResponse.chart.result?.first,
              let timestamps = result.timestamp,
              let closes = result.indicators.quote.first?.close else {
            return []
        }

        var points: [YahooChartPoint] = []
        for (i, timestamp) in timestamps.enumerated() {
            if i < closes.count, let close = closes[i] {
                points.append(YahooChartPoint(
                    date: Date(timeIntervalSince1970: TimeInterval(timestamp)),
                    close: close
                ))
            }
        }

        chartCache[cacheKey] = CachedData(data: points, timestamp: Date())
        return points
    }

    // MARK: - Symbol Resolution

    /// Resolves a ticker/name/ISIN to the best Yahoo Finance symbol.
    /// Tries multiple strategies: direct quote, search by symbol, search by ISIN, search by name.
    func resolveSymbol(symbol: String, name: String = "", isin: String = "", exchange: String = "") async -> String? {
        // Strategy 1: If symbol already has a suffix (e.g., VWCE.DE), try it directly
        if symbol.contains(".") {
            if let quote = try? await fetchQuote(symbol: symbol), quote.regularMarketPrice != nil {
                return symbol
            }
        }

        // Strategy 2: Try ISIN search first (most precise for European securities)
        if !isin.isEmpty {
            if let results = try? await search(query: isin), let first = results.first {
                return first.symbol
            }
        }

        // Strategy 3: Try symbol + common exchange suffixes based on exchange name
        let suffixes = guessSuffixes(exchange: exchange)
        for suffix in suffixes {
            let candidate = suffix.isEmpty ? symbol.uppercased() : "\(symbol.uppercased())\(suffix)"
            if let quote = try? await fetchQuote(symbol: candidate), quote.regularMarketPrice != nil {
                return candidate
            }
        }

        // Strategy 4: Search by symbol
        if let results = try? await search(query: symbol), let first = results.first {
            return first.symbol
        }

        // Strategy 5: Search by name
        if !name.isEmpty {
            if let results = try? await search(query: name), let first = results.first {
                return first.symbol
            }
        }

        return nil
    }

    /// Batch-resolve symbols for multiple holdings.
    func resolveSymbols(for holdings: [(symbol: String, name: String, isin: String, exchange: String)]) async -> [String: String] {
        var resolved: [String: String] = [:]

        for holding in holdings {
            if let yahooSymbol = await resolveSymbol(
                symbol: holding.symbol,
                name: holding.name,
                isin: holding.isin,
                exchange: holding.exchange
            ) {
                resolved[holding.symbol] = yahooSymbol
            }
            // Small delay to avoid rate limiting
            try? await Task.sleep(for: .milliseconds(200))
        }

        return resolved
    }

    private func guessSuffixes(exchange: String) -> [String] {
        let ex = exchange.lowercased()

        // Map common exchange names/codes to Yahoo Finance suffixes
        if ex.contains("xetra") || ex.contains("frankfurt") || ex.contains("fra") || ex.contains("ger") {
            return [".DE", ""]
        }
        if ex.contains("amsterdam") || ex.contains("euronext amsterdam") || ex.contains("ams") {
            return [".AS", ""]
        }
        if ex.contains("paris") || ex.contains("euronext paris") || ex.contains("epa") {
            return [".PA", ""]
        }
        if ex.contains("brussels") || ex.contains("euronext brussels") || ex.contains("ebr") {
            return [".BR", ""]
        }
        if ex.contains("lisbon") || ex.contains("euronext lisbon") {
            return [".LS", ""]
        }
        if ex.contains("london") || ex.contains("lse") || ex.contains("lon") {
            return [".L", ""]
        }
        if ex.contains("milan") || ex.contains("borsa italiana") || ex.contains("mil") || ex.contains("bit") {
            return [".MI", ""]
        }
        if ex.contains("madrid") || ex.contains("bme") || ex.contains("mcx") {
            return [".MC", ""]
        }
        if ex.contains("toronto") || ex.contains("tsx") {
            return [".TO", ""]
        }
        if ex.contains("hong kong") || ex.contains("hkex") {
            return [".HK", ""]
        }
        if ex.contains("tokyo") || ex.contains("tse") || ex.contains("jpx") {
            return [".T", ""]
        }
        if ex.contains("sydney") || ex.contains("asx") {
            return [".AX", ""]
        }
        if ex.contains("nyse") || ex.contains("nasdaq") || ex.contains("us") || ex.contains("new york") {
            return [""]
        }
        if ex.contains("euronext") {
            return [".AS", ".PA", ".BR", ".DE", ""]
        }

        // Default: try no suffix first, then common European ones
        return ["", ".DE", ".AS", ".PA", ".L"]
    }

    func clearCache() {
        quoteCache.removeAll()
        searchCache.removeAll()
        chartCache.removeAll()
    }
}

// MARK: - Models

struct YahooQuoteResponse: Codable {
    let quoteResponse: QuoteResponseBody

    struct QuoteResponseBody: Codable {
        let result: [YahooQuote]
    }
}

struct YahooQuote: Codable {
    let symbol: String
    let shortName: String?
    let longName: String?
    let regularMarketPrice: Double?
    let regularMarketChange: Double?
    let regularMarketChangePercent: Double?
    let regularMarketPreviousClose: Double?
    let regularMarketOpen: Double?
    let regularMarketDayHigh: Double?
    let regularMarketDayLow: Double?
    let regularMarketVolume: Int?
    let marketCap: Double?
    let fiftyTwoWeekHigh: Double?
    let fiftyTwoWeekLow: Double?
    let currency: String?
    let exchange: String?
    let quoteType: String?

    var displayName: String {
        longName ?? shortName ?? symbol
    }
}

struct YahooSearchResponse: Codable {
    let quotes: [YahooSearchResult]
}

struct YahooSearchResult: Codable, Identifiable {
    let symbol: String
    let shortname: String?
    let longname: String?
    let exchange: String?
    let quoteType: String?
    let exchDisp: String?
    let typeDisp: String?

    var id: String { symbol }

    var displayName: String {
        longname ?? shortname ?? symbol
    }

    var assetType: AssetType {
        switch quoteType?.uppercased() {
        case "ETF", "MUTUALFUND": return .etf
        case "INDEX": return .other
        default: return .stock
        }
    }
}

struct YahooChartResponse: Codable {
    let chart: ChartBody

    struct ChartBody: Codable {
        let result: [ChartResult]?
    }

    struct ChartResult: Codable {
        let timestamp: [Int]?
        let indicators: Indicators
    }

    struct Indicators: Codable {
        let quote: [QuoteIndicator]
    }

    struct QuoteIndicator: Codable {
        let close: [Double?]?
        let open: [Double?]?
        let high: [Double?]?
        let low: [Double?]?
        let volume: [Int?]?
    }
}

struct YahooChartPoint: Sendable {
    let date: Date
    let close: Double
}

// MARK: - Errors

enum YahooFinanceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case httpError(Int)
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from Yahoo Finance"
        case .rateLimited:
            return "Rate limited by Yahoo Finance. Please try again shortly."
        case .httpError(let code):
            return "Yahoo Finance HTTP error: \(code)"
        case .noData:
            return "No data available for this symbol"
        }
    }
}
