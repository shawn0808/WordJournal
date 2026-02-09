//
//  DictionaryService.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation

class DictionaryService: ObservableObject {
    static let shared = DictionaryService()
    
    private var localDictionary: [String: LocalDictionaryEntry] = [:]
    private var cache: [String: DictionaryResult] = [:]
    private let cacheQueue = DispatchQueue(label: "com.wordjournal.cache")
    
    private init() {
        loadLocalDictionary()
    }
    
    private func loadLocalDictionary() {
        guard let url = Bundle.main.url(forResource: "dictionary", withExtension: "json") else {
            // Dictionary file is optional - app will use API only
            print("Info: dictionary.json not found in bundle, using API only")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let entries = try JSONDecoder().decode([LocalDictionaryEntry].self, from: data)
            
            for entry in entries {
                localDictionary[entry.word.lowercased()] = entry
            }
            
            print("Loaded \(localDictionary.count) local dictionary entries")
        } catch {
            print("Error loading local dictionary: \(error). Will use API only.")
        }
    }
    
    func lookup(_ word: String, completion: @escaping (Result<DictionaryResult, Error>) -> Void) {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Check cache first
        cacheQueue.sync {
            if let cached = cache[normalizedWord] {
                DispatchQueue.main.async {
                    completion(.success(cached))
                }
                return
            }
        }
        
        // Check local dictionary
        if let localEntry = localDictionary[normalizedWord] {
            let result = DictionaryResult(
                word: localEntry.word,
                phonetic: localEntry.phonetic,
                phonetics: localEntry.phonetic.map { [Phonetic(text: $0, audio: nil)] },
                meanings: [
                    Meaning(
                        partOfSpeech: localEntry.partOfSpeech,
                        definitions: [
                            Definition(
                                definition: localEntry.definition,
                                example: localEntry.example,
                                synonyms: nil,
                                antonyms: nil
                            )
                        ],
                        synonyms: nil,
                        antonyms: nil
                    )
                ],
                sourceUrls: nil
            )
            
            cacheQueue.async { [weak self] in
                self?.cache[normalizedWord] = result
            }
            
            DispatchQueue.main.async {
                completion(.success(result))
            }
            return
        }
        
        // Fallback to API
        fetchFromAPI(word: normalizedWord) { [weak self] result in
            switch result {
            case .success(let apiResult):
                self?.cacheQueue.async {
                    self?.cache[normalizedWord] = apiResult
                }
                DispatchQueue.main.async {
                    completion(.success(apiResult))
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    private func fetchFromAPI(word: String, completion: @escaping (Result<DictionaryResult, Error>) -> Void) {
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)") else {
            completion(.failure(NSError(domain: "DictionaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid word or URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 10.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "DictionaryService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])))
                return
            }
            
            guard httpResponse.statusCode == 200 else {
                if httpResponse.statusCode == 404 {
                    completion(.failure(NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Word not found"])))
                } else {
                    completion(.failure(NSError(domain: "DictionaryService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(httpResponse.statusCode)"])))
                }
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "DictionaryService", code: -2, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                let results = try JSONDecoder().decode([DictionaryResult].self, from: data)
                if let firstResult = results.first {
                    completion(.success(firstResult))
                } else {
                    completion(.failure(NSError(domain: "DictionaryService", code: -3, userInfo: [NSLocalizedDescriptionKey: "No results found"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
