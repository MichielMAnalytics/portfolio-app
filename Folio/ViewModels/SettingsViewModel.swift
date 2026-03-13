import Foundation
import SwiftUI

@MainActor
@Observable
final class SettingsViewModel {
    var selectedProvider: LLMProvider = .claude
    var claudeAPIKey: String = ""
    var openAIAPIKey: String = ""
    var geminiAPIKey: String = ""
    var preferredCurrency: String = "USD"
    var isBiometricEnabled: Bool = false
    var biometricTypeDisplay: String = "Not Available"
    var biometricSymbol: String = "lock.slash"

    var showSaveConfirmation = false
    var errorMessage: String?

    static let supportedCurrencies = [
        "USD", "EUR", "GBP", "CHF", "JPY", "CAD", "AUD", "CNY", "KRW", "BRL", "INR"
    ]

    private let biometricEnabledKey = "biometric_enabled"
    private let currencyKey = "preferred_currency"

    func load() {
        if let providerRaw = KeychainHelper.retrieve(for: .selectedProvider),
           let provider = LLMProvider(rawValue: providerRaw) {
            selectedProvider = provider
        }

        claudeAPIKey = KeychainHelper.getAPIKey(for: .claude) ?? ""
        openAIAPIKey = KeychainHelper.getAPIKey(for: .openAI) ?? ""
        geminiAPIKey = KeychainHelper.getAPIKey(for: .gemini) ?? ""

        preferredCurrency = UserDefaults.standard.string(forKey: currencyKey) ?? "USD"
        isBiometricEnabled = UserDefaults.standard.bool(forKey: biometricEnabledKey)

        Task {
            await loadBiometricInfo()
        }
    }

    func loadBiometricInfo() async {
        let bioType = await BiometricService.shared.availableBiometricType()
        biometricTypeDisplay = bioType.displayName
        biometricSymbol = bioType.sfSymbol
    }

    func saveAPIKeys() {
        _ = KeychainHelper.save(selectedProvider.rawValue, for: .selectedProvider)

        if !claudeAPIKey.isEmpty {
            _ = KeychainHelper.saveAPIKey(claudeAPIKey, for: .claude)
        } else {
            _ = KeychainHelper.deleteAPIKey(for: .claude)
        }

        if !openAIAPIKey.isEmpty {
            _ = KeychainHelper.saveAPIKey(openAIAPIKey, for: .openAI)
        } else {
            _ = KeychainHelper.deleteAPIKey(for: .openAI)
        }

        if !geminiAPIKey.isEmpty {
            _ = KeychainHelper.saveAPIKey(geminiAPIKey, for: .gemini)
        } else {
            _ = KeychainHelper.deleteAPIKey(for: .gemini)
        }

        showSaveConfirmation = true
    }

    func saveCurrency() {
        UserDefaults.standard.set(preferredCurrency, forKey: currencyKey)
    }

    func toggleBiometric() async {
        if !isBiometricEnabled {
            let authenticated = await BiometricService.shared.authenticate(
                reason: "Enable biometric lock for Folio"
            )
            if authenticated {
                isBiometricEnabled = true
                UserDefaults.standard.set(true, forKey: biometricEnabledKey)
            }
        } else {
            isBiometricEnabled = false
            UserDefaults.standard.set(false, forKey: biometricEnabledKey)
        }
    }

    var hasValidAPIKey: Bool {
        switch selectedProvider {
        case .claude: return !claudeAPIKey.isEmpty
        case .openAI: return !openAIAPIKey.isEmpty
        case .gemini: return !geminiAPIKey.isEmpty
        }
    }

    var activeProviderKeyStatus: String {
        if hasValidAPIKey {
            return "Configured"
        }
        return "Not Set"
    }

    func maskedKey(_ key: String) -> String {
        guard key.count > 8 else { return key.isEmpty ? "" : "****" }
        let prefix = String(key.prefix(4))
        let suffix = String(key.suffix(4))
        return "\(prefix)...\(suffix)"
    }
}
