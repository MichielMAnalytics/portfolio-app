import Foundation
import UIKit

enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case claude
    case openAI
    case gemini

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .claude: return "Claude (Anthropic)"
        case .openAI: return "OpenAI"
        case .gemini: return "Gemini (Google)"
        }
    }

    var keyPlaceholder: String {
        switch self {
        case .claude: return "sk-ant-..."
        case .openAI: return "sk-..."
        case .gemini: return "AIza..."
        }
    }
}

struct ExtractedHolding: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String?
    var symbol: String?
    var quantity: Double?
    var currentPrice: Double?
    var totalValue: Double?

    enum CodingKeys: String, CodingKey {
        case name, symbol, quantity, currentPrice, totalValue
    }
}

actor LLMService {
    static let shared = LLMService()

    private let extractionPrompt = """
    Analyze this screenshot of a financial portfolio/brokerage account. Extract all visible holdings/positions. \
    For each holding, extract: name (full asset name), symbol (ticker/symbol), quantity (number of units held), \
    currentPrice (current price per unit), totalValue (total position value). Return ONLY a JSON array of objects \
    with these fields. If a field is not visible, use null. Example: \
    [{"name": "Apple Inc.", "symbol": "AAPL", "quantity": 10, "currentPrice": 178.50, "totalValue": 1785.00}]
    """

    private init() {}

    func extractHoldings(from image: UIImage, provider: LLMProvider, apiKey: String) async throws -> [ExtractedHolding] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw LLMError.imageConversionFailed
        }

        let base64Image = imageData.base64EncodedString()

        switch provider {
        case .claude:
            return try await callClaude(base64Image: base64Image, apiKey: apiKey)
        case .openAI:
            return try await callOpenAI(base64Image: base64Image, apiKey: apiKey)
        case .gemini:
            return try await callGemini(base64Image: base64Image, apiKey: apiKey)
        }
    }

    private func callClaude(base64Image: String, apiKey: String) async throws -> [ExtractedHolding] {
        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "type": "text",
                            "text": extractionPrompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(provider: "Claude", statusCode: statusCode, message: responseBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let content = json?["content"] as? [[String: Any]],
              let textBlock = content.first(where: { $0["type"] as? String == "text" }),
              let text = textBlock["text"] as? String else {
            throw LLMError.unexpectedResponse
        }

        return try parseExtractedHoldings(from: text)
    }

    private func callOpenAI(base64Image: String, apiKey: String) async throws -> [ExtractedHolding] {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let body: [String: Any] = [
            "model": "gpt-5.4",
            "max_tokens": 4096,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ],
                        [
                            "type": "text",
                            "text": extractionPrompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(provider: "OpenAI", statusCode: statusCode, message: responseBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let choices = json?["choices"] as? [[String: Any]],
              let message = choices.first?["message"] as? [String: Any],
              let text = message["content"] as? String else {
            throw LLMError.unexpectedResponse
        }

        return try parseExtractedHoldings(from: text)
    }

    private func callGemini(base64Image: String, apiKey: String) async throws -> [ExtractedHolding] {
        let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "inlineData": [
                                "mimeType": "image/jpeg",
                                "data": base64Image
                            ]
                        ],
                        [
                            "text": extractionPrompt
                        ]
                    ]
                ]
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            let responseBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw LLMError.apiError(provider: "Gemini", statusCode: statusCode, message: responseBody)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let candidates = json?["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw LLMError.unexpectedResponse
        }

        return try parseExtractedHoldings(from: text)
    }

    private func parseExtractedHoldings(from text: String) throws -> [ExtractedHolding] {
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if let jsonStart = jsonString.firstIndex(of: "["),
           let jsonEnd = jsonString.lastIndex(of: "]") {
            jsonString = String(jsonString[jsonStart...jsonEnd])
        }

        jsonString = jsonString
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw LLMError.parsingFailed
        }

        let decoder = JSONDecoder()
        do {
            let holdings = try decoder.decode([ExtractedHolding].self, from: data)
            return holdings
        } catch {
            throw LLMError.parsingFailed
        }
    }
}

enum LLMError: LocalizedError {
    case imageConversionFailed
    case apiError(provider: String, statusCode: Int, message: String)
    case unexpectedResponse
    case parsingFailed
    case noAPIKey

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed:
            return "Failed to convert image for upload"
        case .apiError(let provider, let statusCode, let message):
            return "\(provider) API error (\(statusCode)): \(message)"
        case .unexpectedResponse:
            return "Received unexpected response from the API"
        case .parsingFailed:
            return "Failed to parse holdings from LLM response"
        case .noAPIKey:
            return "No API key configured. Please add one in Settings."
        }
    }
}
