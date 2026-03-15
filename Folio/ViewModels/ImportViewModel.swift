import Foundation
import SwiftUI
import PhotosUI

@MainActor
@Observable
final class ImportViewModel {
    // Screenshot Import
    var selectedPhotoItem: PhotosPickerItem?
    var selectedImage: UIImage?
    var isProcessingScreenshot = false
    var extractedHoldings: [ExtractedHolding] = []
    var showExtractedReview = false

    // CSV Import
    var csvHeaders: [String] = []
    var csvRows: [CSVRow] = []
    var columnMapping = CSVColumnMapping()
    var parsedCSVHoldings: [ParsedCSVHolding] = []
    var showCSVReview = false
    var isProcessingCSV = false

    // Common
    var errorMessage: String?
    var showError = false
    var importSuccessCount = 0
    var showImportSuccess = false

    func loadImage() async {
        guard let item = selectedPhotoItem else { return }

        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                selectedImage = image
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
            showError = true
        }
    }

    func extractFromScreenshot() async {
        guard let image = selectedImage else {
            errorMessage = "No image selected"
            showError = true
            return
        }

        let providerRaw = KeychainHelper.retrieve(for: .selectedProvider) ?? LLMProvider.claude.rawValue
        guard let provider = LLMProvider(rawValue: providerRaw) else {
            errorMessage = "Invalid LLM provider"
            showError = true
            return
        }

        guard let apiKey = KeychainHelper.getAPIKey(for: provider), !apiKey.isEmpty else {
            errorMessage = "No API key configured for \(provider.displayName). Please add one in Settings."
            showError = true
            return
        }

        isProcessingScreenshot = true
        errorMessage = nil

        do {
            let holdings = try await LLMService.shared.extractHoldings(
                from: image,
                provider: provider,
                apiKey: apiKey
            )

            extractedHoldings = holdings
            showExtractedReview = true
            isProcessingScreenshot = false
        } catch {
            errorMessage = error.localizedDescription
            showError = true
            isProcessingScreenshot = false
        }
    }

    func processCSV(url: URL) {
        isProcessingCSV = true
        errorMessage = nil

        do {
            let (headers, rows) = try CSVImportService.parseCSV(from: url)
            csvHeaders = headers
            csvRows = rows
            columnMapping = CSVImportService.autoDetectMapping(headers: headers)

            let parsed = CSVImportService.applyMapping(rows: rows, mapping: columnMapping)
            parsedCSVHoldings = CSVImportService.aggregateHoldings(parsed)
            showCSVReview = true
        } catch {
            errorMessage = "Failed to parse CSV: \(error.localizedDescription)"
            showError = true
        }

        isProcessingCSV = false
    }

    func remapCSV() {
        let parsed = CSVImportService.applyMapping(rows: csvRows, mapping: columnMapping)
        parsedCSVHoldings = CSVImportService.aggregateHoldings(parsed)
    }

    func createHoldingsFromExtracted() -> [Holding] {
        extractedHoldings.compactMap { extracted in
            guard let name = extracted.name, !name.isEmpty else { return nil }

            return Holding(
                name: name,
                symbol: extracted.symbol ?? "",
                quantity: extracted.quantity ?? 0,
                purchasePrice: extracted.currentPrice ?? 0,
                purchaseCurrency: extracted.currency ?? "USD",
                currentPrice: extracted.currentPrice ?? 0,
                assetType: guessAssetTypeFromExtracted(extracted),
                purchaseDate: Date(),
                notes: "Imported from screenshot",
                exchange: extracted.exchange ?? "",
                isin: extracted.isin ?? ""
            )
        }
    }

    private func guessAssetTypeFromExtracted(_ extracted: ExtractedHolding) -> AssetType {
        let name = (extracted.name ?? "").lowercased()
        if name.contains("etf") || name.contains("ucits") || name.contains("tracker") || name.contains("ishares") || name.contains("vanguard") {
            return .etf
        }
        if name.contains("etc") || name.contains("nickel") || name.contains("gold") || name.contains("silver") {
            return .commodity
        }
        if name.contains("bond") || name.contains("anleihe") {
            return .bond
        }
        return .stock
    }

    func createHoldingsFromCSV() -> [Holding] {
        parsedCSVHoldings.map { parsed in
            Holding(
                name: parsed.name,
                symbol: parsed.symbol,
                quantity: parsed.quantity,
                purchasePrice: parsed.price,
                purchaseCurrency: parsed.currency,
                currentPrice: parsed.price,
                assetType: guessAssetType(from: parsed),
                purchaseDate: parsed.date ?? Date(),
                notes: "Imported from CSV",
                isin: parsed.isin
            )
        }
    }

    private func guessAssetType(from parsed: ParsedCSVHolding) -> AssetType {
        let nameLower = parsed.name.lowercased()
        let typeLower = parsed.type.lowercased()

        if nameLower.contains("bitcoin") || nameLower.contains("ethereum") ||
           nameLower.contains("crypto") || typeLower.contains("crypto") {
            return .crypto
        }
        if nameLower.contains("etf") || typeLower.contains("etf") {
            return .etf
        }
        if nameLower.contains("bond") || typeLower.contains("bond") ||
           nameLower.contains("anleihe") {
            return .bond
        }
        if nameLower.contains("gold") || nameLower.contains("silver") ||
           nameLower.contains("commodity") {
            return .commodity
        }
        return .stock
    }

    func resetScreenshotImport() {
        selectedPhotoItem = nil
        selectedImage = nil
        extractedHoldings = []
        showExtractedReview = false
        isProcessingScreenshot = false
    }

    func resetCSVImport() {
        csvHeaders = []
        csvRows = []
        columnMapping = CSVColumnMapping()
        parsedCSVHoldings = []
        showCSVReview = false
        isProcessingCSV = false
    }

    func resetAll() {
        resetScreenshotImport()
        resetCSVImport()
        errorMessage = nil
        showError = false
        importSuccessCount = 0
        showImportSuccess = false
    }
}
