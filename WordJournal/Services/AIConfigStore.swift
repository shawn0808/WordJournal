//
//  AIConfigStore.swift
//  WordJournal
//
//  User preferences for AI insights: enabled, provider, API key.
//

import Foundation
import Combine

class AIConfigStore: ObservableObject {
    static let shared = AIConfigStore()
    
    private let enabledKey = "aiInsightsEnabled"
    private let providerKey = "aiProvider"
    
    @Published var isEnabled: Bool {
        didSet { UserDefaults.standard.set(isEnabled, forKey: enabledKey) }
    }
    
    @Published var provider: AIProvider {
        didSet {
            UserDefaults.standard.set(provider.rawValue, forKey: providerKey)
        }
    }
    
    var apiKey: String? {
        KeychainStorage.getAIApiKey()
    }
    
    var hasValidConfig: Bool {
        isEnabled && !(apiKey ?? "").trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private init() {
        self.isEnabled = UserDefaults.standard.bool(forKey: enabledKey)
        let raw = UserDefaults.standard.string(forKey: providerKey) ?? AIProvider.gemini.rawValue
        self.provider = AIProvider(rawValue: raw) ?? .gemini
    }
    
    func setApiKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        let ok: Bool
        if trimmed.isEmpty {
            ok = KeychainStorage.deleteAIApiKey()
        } else {
            ok = KeychainStorage.saveAIApiKey(trimmed)
        }
        if ok { objectWillChange.send() }
        return ok
    }
    
    func clearApiKey() -> Bool {
        let ok = KeychainStorage.deleteAIApiKey()
        if ok { objectWillChange.send() }
        return ok
    }
}
