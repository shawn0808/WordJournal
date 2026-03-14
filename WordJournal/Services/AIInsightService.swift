//
//  AIInsightService.swift
//  WordJournal
//
//  Fetches AI-generated word insights (plain explanation, synonyms, antonyms).
//  Supports OpenAI (ChatGPT) with "bring your own API key."
//

import Foundation

enum AIProvider: String, CaseIterable, Identifiable {
    case openAI = "openai"
    case gemini = "gemini"
    case deepSeek = "deepseek"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .openAI: return "OpenAI (ChatGPT)"
        case .gemini: return "Google Gemini"
        case .deepSeek: return "DeepSeek"
        }
    }
    
    var baseURL: String {
        switch self {
        case .openAI: return "https://api.openai.com/v1/chat/completions"
        case .gemini: return "https://generativelanguage.googleapis.com/v1beta/models"
        case .deepSeek: return "https://api.deepseek.com/v1/chat/completions"
        }
    }
    
    var geminiModel: String { "gemini-2.0-flash" }
    
    var openAICompatibleModel: String? {
        switch self {
        case .openAI: return "gpt-4o-mini"
        case .deepSeek: return "deepseek-chat"
        case .gemini: return nil
        }
    }
}

actor AIInsightService {
    static let shared = AIInsightService()
    
    private init() {}
    
    func fetchInsight(
        word: String,
        existingDefinitions: [String],
        provider: AIProvider,
        apiKey: String
    ) async throws -> AIWordInsight {
        guard !apiKey.isEmpty else {
            throw AIInsightError.missingApiKey
        }
        
        let context = existingDefinitions.prefix(2).joined(separator: " ")
        let prompt = buildPrompt(word: word, context: context)
        
        switch provider {
        case .openAI:
            return try await fetchFromOpenAI(prompt: prompt, apiKey: apiKey, word: word)
        case .gemini:
            return try await fetchFromGemini(prompt: prompt, apiKey: apiKey, word: word)
        case .deepSeek:
            return try await fetchFromOpenAICompatible(prompt: prompt, apiKey: apiKey, word: word, provider: provider)
        }
    }
    
    private func buildPrompt(word: String, context: String) -> String {
        """
        You are a vocabulary assistant. For the word "\(word)", provide:
        
        1. PART OF SPEECH: One word — noun, verb, adjective, adverb, preposition, conjunction, interjection, or pronoun. Use lowercase.
        2. EXPLANATION: One easy-to-understand sentence that defines the word. Write it as a direct definition (e.g. "To find out what is wrong..." or "A brief moment...")—do NOT start with "[word] means" or "To [word] means".
        3. EXAMPLE SENTENCE: One short example sentence that uses the word naturally in context, so the user can see how it is used.
        4. SYNONYMS: A comma-separated list of 3-5 common synonyms.
        5. ANTONYMS: A comma-separated list of 2-4 common antonyms.
        
        Format your response exactly like this:
        Part of speech: [noun/verb/adjective/etc]
        Explanation: [your one-sentence explanation]
        Example sentence: [one sentence using the word in context]
        Synonyms: [word1, word2, word3]
        Antonyms: [word1, word2]
        
        \(context.isEmpty ? "" : "Dictionary definition for context: \(context)")
        """
    }
    
    private func fetchFromOpenAI(prompt: String, apiKey: String, word: String) async throws -> AIWordInsight {
        return try await fetchFromOpenAICompatible(prompt: prompt, apiKey: apiKey, word: word, provider: .openAI)
    }
    
    private func fetchFromOpenAICompatible(prompt: String, apiKey: String, word: String, provider: AIProvider) async throws -> AIWordInsight {
        guard let model = provider.openAICompatibleModel else {
            throw AIInsightError.invalidResponse
        }
        let url = URL(string: provider.baseURL)!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30
        
        let body: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": "You are a concise vocabulary assistant. Reply only with the requested format, no preamble."],
                ["role": "user", "content": prompt]
            ],
            "max_tokens": 200,
            "temperature": 0.3
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIInsightError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIInsightError.apiError(message)
            }
            throw AIInsightError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        return try parseOpenAIResponse(data: data, word: word)
    }
    
    private func fetchFromGemini(prompt: String, apiKey: String, word: String) async throws -> AIWordInsight {
        let model = AIProvider.gemini.geminiModel
        guard let url = URL(string: "\(AIProvider.gemini.baseURL)/\(model):generateContent") else {
            throw AIInsightError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.timeoutInterval = 30
        
        let fullPrompt = "You are a concise vocabulary assistant. Reply only with the requested format, no preamble.\n\n\(prompt)"
        
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": fullPrompt]
                    ]
                ]
            ],
            "generationConfig": [
                "maxOutputTokens": 200,
                "temperature": 0.3
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIInsightError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIInsightError.apiError(message)
            }
            throw AIInsightError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        return try parseGeminiResponse(data: data, word: word)
    }
    
    private func parseGeminiResponse(data: Data, word: String) throws -> AIWordInsight {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let first = candidates.first,
              let content = first["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIInsightError.parseError
        }
        return parseFormattedResponse(text, word: word)
    }
    
    private func parseOpenAIResponse(data: Data, word: String) throws -> AIWordInsight {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIInsightError.parseError
        }
        
        return parseFormattedResponse(content, word: word)
    }
    
    private func parseFormattedResponse(_ text: String, word: String) -> AIWordInsight {
        var partOfSpeech: String? = nil
        var plainExplanation = "\(word) means something that lasts for a very short time."
        var exampleSentence: String? = nil
        var synonyms: [String] = []
        var antonyms: [String] = []
        var firstLineAsFallback: String?
        
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            if trimmed.lowercased().hasPrefix("part of speech:") {
                partOfSpeech = String(trimmed.dropFirst("part of speech:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("explanation:") {
                plainExplanation = String(trimmed.dropFirst("explanation:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("in plain terms:") {
                plainExplanation = String(trimmed.dropFirst("in plain terms:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("example sentence:") {
                exampleSentence = String(trimmed.dropFirst("example sentence:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("example:") {
                exampleSentence = String(trimmed.dropFirst("example:".count)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.lowercased().hasPrefix("synonyms:") {
                let rest = String(trimmed.dropFirst("synonyms:".count)).trimmingCharacters(in: .whitespaces)
                synonyms = rest.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if trimmed.lowercased().hasPrefix("antonyms:") {
                let rest = String(trimmed.dropFirst("antonyms:".count)).trimmingCharacters(in: .whitespaces)
                antonyms = rest.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            } else if firstLineAsFallback == nil,
                      !trimmed.lowercased().hasPrefix("part of speech:"),
                      !trimmed.lowercased().hasPrefix("explanation:"),
                      !trimmed.lowercased().hasPrefix("in plain terms:"),
                      !trimmed.lowercased().hasPrefix("example sentence:"),
                      !trimmed.lowercased().hasPrefix("example:"),
                      !trimmed.lowercased().hasPrefix("synonyms:"),
                      !trimmed.lowercased().hasPrefix("antonyms:") {
                firstLineAsFallback = trimmed
            }
        }
        
        if plainExplanation == "\(word) means something that lasts for a very short time." && firstLineAsFallback != nil {
            plainExplanation = firstLineAsFallback!
        }
        
        // Strip redundant "[word] means " or "To [word] means " prefix if AI still includes it
        let lower = plainExplanation.lowercased()
        let wordLower = word.lowercased()
        for prefix in ["to \(wordLower) means ", "\(wordLower) means ", "to \(wordLower) is ", "\(wordLower) is "] {
            if lower.hasPrefix(prefix) {
                var rest = String(plainExplanation.dropFirst(prefix.count))
                if let first = rest.first, first.isLowercase {
                    rest = first.uppercased() + rest.dropFirst()
                }
                plainExplanation = rest
                break
            }
        }
        
        return AIWordInsight(
            partOfSpeech: partOfSpeech,
            plainExplanation: plainExplanation,
            exampleSentence: exampleSentence,
            synonyms: synonyms.isEmpty ? ["fleeting", "brief", "momentary"] : synonyms,
            antonyms: antonyms.isEmpty ? ["permanent", "lasting"] : antonyms
        )
    }
}

enum AIInsightError: LocalizedError {
    case missingApiKey
    case invalidResponse
    case apiError(String)
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey: return "API key not configured"
        case .invalidResponse: return "Invalid response from AI"
        case .apiError(let msg): return msg
        case .parseError: return "Could not parse AI response"
        }
    }
}
