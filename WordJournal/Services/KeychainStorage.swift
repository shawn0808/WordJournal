//
//  KeychainStorage.swift
//  WordJournal
//
//  Secure storage for AI API keys.
//

import Foundation
import Security

enum KeychainStorage {
    private static let serviceName = "com.wordjournal"
    private static let aiApiKeyAccount = "ai_api_key"
    
    static func saveAIApiKey(_ key: String) -> Bool {
        guard let data = key.data(using: .utf8) else { return false }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: aiApiKeyAccount
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        var addQuery = query
        addQuery[kSecValueData as String] = data
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    static func getAIApiKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: aiApiKeyAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        return key
    }
    
    static func deleteAIApiKey() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: aiApiKeyAccount
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
