import Foundation
import Security

struct KeychainHelper {
    private static let serviceName = "com.michielvoortman.folio"
    private static let udPrefix = "folio_secure_"

    enum KeychainKey: String {
        case claudeAPIKey = "claude_api_key"
        case openAIAPIKey = "openai_api_key"
        case geminiAPIKey = "gemini_api_key"
        case selectedProvider = "selected_provider"
    }

    // MARK: - Save (Keychain + UserDefaults backup)

    static func save(_ value: String, for key: KeychainKey) -> Bool {
        // Always save to UserDefaults as backup (survives reinstalls)
        UserDefaults.standard.set(value, forKey: udPrefix + key.rawValue)

        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        SecItemDelete(query as CFDictionary)

        let attributes: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        let status = SecItemAdd(attributes as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve (Keychain first, UserDefaults fallback)

    static func retrieve(for key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status == errSecSuccess,
           let data = result as? Data,
           let value = String(data: data, encoding: .utf8),
           !value.isEmpty {
            return value
        }

        // Fallback: check UserDefaults backup
        if let backup = UserDefaults.standard.string(forKey: udPrefix + key.rawValue),
           !backup.isEmpty {
            // Restore to Keychain
            _ = save(backup, for: key)
            return backup
        }

        return nil
    }

    static func delete(for key: KeychainKey) -> Bool {
        UserDefaults.standard.removeObject(forKey: udPrefix + key.rawValue)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    static func exists(for key: KeychainKey) -> Bool {
        retrieve(for: key) != nil
    }

    // MARK: - LLM Provider Helpers

    static func saveAPIKey(_ key: String, for provider: LLMProvider) -> Bool {
        let keychainKey: KeychainKey
        switch provider {
        case .claude: keychainKey = .claudeAPIKey
        case .openAI: keychainKey = .openAIAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        }
        return save(key, for: keychainKey)
    }

    static func getAPIKey(for provider: LLMProvider) -> String? {
        let keychainKey: KeychainKey
        switch provider {
        case .claude: keychainKey = .claudeAPIKey
        case .openAI: keychainKey = .openAIAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        }
        return retrieve(for: keychainKey)
    }

    static func deleteAPIKey(for provider: LLMProvider) -> Bool {
        let keychainKey: KeychainKey
        switch provider {
        case .claude: keychainKey = .claudeAPIKey
        case .openAI: keychainKey = .openAIAPIKey
        case .gemini: keychainKey = .geminiAPIKey
        }
        return delete(for: keychainKey)
    }
}
