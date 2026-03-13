import Foundation

actor CoinGeckoService {
    static let shared = CoinGeckoService()

    private let baseURL = "https://api.coingecko.com/api/v3"
    private let cacheTTL: TimeInterval = 300 // 5 minutes

    private var marketDataCache: [String: CachedData<[CryptoMarketData]>] = [:]
    private var searchCache: [String: CachedData<CoinGeckoSearchResponse>] = [:]

    private struct CachedData<T> {
        let data: T
        let timestamp: Date

        var isExpired: Bool {
            Date().timeIntervalSince(timestamp) > 300
        }
    }

    private init() {}

    func fetchMarketData(
        vsCurrency: String = "usd",
        coinIds: [String]? = nil,
        perPage: Int = 100,
        page: Int = 1
    ) async throws -> [CryptoMarketData] {
        var components = URLComponents(string: "\(baseURL)/coins/markets")!

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "vs_currency", value: vsCurrency),
            URLQueryItem(name: "order", value: "market_cap_desc"),
            URLQueryItem(name: "per_page", value: String(perPage)),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "sparkline", value: "true"),
            URLQueryItem(name: "price_change_percentage", value: "24h,7d")
        ]

        if let coinIds, !coinIds.isEmpty {
            queryItems.append(URLQueryItem(name: "ids", value: coinIds.joined(separator: ",")))
        }

        components.queryItems = queryItems

        guard let url = components.url else {
            throw CoinGeckoError.invalidURL
        }

        let cacheKey = url.absoluteString
        if let cached = marketDataCache[cacheKey], !cached.isExpired {
            return cached.data
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinGeckoError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw CoinGeckoError.rateLimited
            }
            throw CoinGeckoError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let marketData = try decoder.decode([CryptoMarketData].self, from: data)

        marketDataCache[cacheKey] = CachedData(data: marketData, timestamp: Date())

        return marketData
    }

    func searchCoins(query: String) async throws -> [CoinSearchResult] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return []
        }

        let lowercased = query.lowercased()
        if let cached = searchCache[lowercased], !cached.isExpired {
            return cached.data.coins
        }

        var components = URLComponents(string: "\(baseURL)/search")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query)
        ]

        guard let url = components.url else {
            throw CoinGeckoError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw CoinGeckoError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 429 {
                throw CoinGeckoError.rateLimited
            }
            throw CoinGeckoError.httpError(httpResponse.statusCode)
        }

        let decoder = JSONDecoder()
        let searchResponse = try decoder.decode(CoinGeckoSearchResponse.self, from: data)

        searchCache[lowercased] = CachedData(data: searchResponse, timestamp: Date())

        return searchResponse.coins
    }

    func fetchPriceForCoin(id: String, vsCurrency: String = "usd") async throws -> Double? {
        let marketData = try await fetchMarketData(vsCurrency: vsCurrency, coinIds: [id], perPage: 1)
        return marketData.first?.currentPrice
    }

    func clearCache() {
        marketDataCache.removeAll()
        searchCache.removeAll()
    }
}

enum CoinGeckoError: LocalizedError {
    case invalidURL
    case invalidResponse
    case rateLimited
    case httpError(Int)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .rateLimited:
            return "Rate limited by CoinGecko. Please try again in a minute."
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}
