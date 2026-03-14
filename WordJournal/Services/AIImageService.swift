//
//  AIImageService.swift
//  WordJournal
//
//  Generates AI background images for Word of the Day cards via OpenAI DALL-E.
//  Uses the same API key as AI insights (OpenAI provider only).
//

import Foundation
import AppKit

enum AIImageError: LocalizedError {
    case missingApiKey
    case openAIOnly
    case invalidResponse
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .missingApiKey: return "API key required"
        case .openAIOnly: return "Word of the Day images require OpenAI (ChatGPT)"
        case .invalidResponse: return "Invalid response from image API"
        case .apiError(let msg): return msg
        }
    }
}

actor AIImageService {
    static let shared = AIImageService()
    
    private let baseURL = "https://api.openai.com/v1/images/generations"
    private let model = "dall-e-2"
    private let size = "512x512"
    
    private init() {}
    
    /// Generates an image for the given word. Returns PNG data or nil on failure.
    func generateImage(for word: String, definition: String, apiKey: String) async throws -> Data {
        guard !apiKey.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw AIImageError.missingApiKey
        }
        
        let prompt = buildPrompt(word: word, definition: definition)
        
        guard let url = URL(string: baseURL) else {
            throw AIImageError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        let body: [String: Any] = [
            "model": model,
            "prompt": prompt,
            "n": 1,
            "size": size,
            "response_format": "b64_json" as String
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIImageError.invalidResponse
        }
        
        if httpResponse.statusCode != 200 {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw AIImageError.apiError(message)
            }
            throw AIImageError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        return try parseResponse(data: data)
    }
    
    private func buildPrompt(word: String, definition: String) -> String {
        """
        Anime or cartoon style illustration for the vocabulary word "\(word)" — \(definition). \
        Studio Ghibli aesthetic, soft colors, evocative and atmospheric. \
        No text, no people, no letters. \
        Suitable as background for a vocabulary card, warm and memorable.
        """
    }
    
    private func parseResponse(data: Data) throws -> Data {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let dataArray = json["data"] as? [[String: Any]],
              let first = dataArray.first,
              let b64 = first["b64_json"] as? String,
              let imageData = Data(base64Encoded: b64) else {
            throw AIImageError.invalidResponse
        }
        return imageData
    }
}
