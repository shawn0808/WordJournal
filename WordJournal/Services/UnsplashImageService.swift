//
//  WordImageService.swift (née UnsplashImageService)
//  WordJournal
//
//  Fetches a representative photo for a vocabulary word using Wikipedia's
//  free pageimages API — no API key required.
//  TODO: Switch to Unsplash search API once key is approved.
//

import Foundation

enum UnsplashError: LocalizedError {
    case noResults
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noResults: return "No photo found for this word"
        case .invalidResponse: return "Invalid response"
        }
    }
}

actor UnsplashImageService {
    static let shared = UnsplashImageService()
    private init() {}

    /// Tries each term in `searchTerms` in order, returning the first image found.
    func fetchImage(for searchTerms: [String]) async throws -> Data {
        for term in searchTerms {
            if let data = try? await fetchWikipediaImage(for: term) {
                return data
            }
        }
        throw UnsplashError.noResults
    }

    private func fetchWikipediaImage(for term: String) async throws -> Data {
        var components = URLComponents(string: "https://en.wikipedia.org/w/api.php")!
        components.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "titles", value: term),
            URLQueryItem(name: "prop", value: "pageimages"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "pithumbsize", value: "1000"),
            URLQueryItem(name: "redirects", value: "1")
        ]

        var request = URLRequest(url: components.url!)
        request.addValue("WordJournal/1.0 (mac app)", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        let (metaData, _) = try await URLSession.shared.data(for: request)

        guard
            let json = try? JSONSerialization.jsonObject(with: metaData) as? [String: Any],
            let query = json["query"] as? [String: Any],
            let pages = query["pages"] as? [String: Any],
            let page = pages.values.first as? [String: Any],
            let thumbnail = page["thumbnail"] as? [String: Any],
            let sourceStr = thumbnail["source"] as? String,
            let imageURL = URL(string: sourceStr)
        else {
            throw UnsplashError.noResults
        }

        let (imageData, _) = try await URLSession.shared.data(from: imageURL)
        guard !imageData.isEmpty else { throw UnsplashError.noResults }
        return imageData
    }
}
