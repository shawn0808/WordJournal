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
    
    // Persistent file-based cache directory
    private static let persistentCacheDir: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let dir = caches.appendingPathComponent("WordJournal/dictionary", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()
    
    private init() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.loadPersistentCache()
            self?.loadLocalDictionary()
        }
    }
    
    // MARK: - Persistent cache
    
    private func persistentCacheURL(for word: String) -> URL {
        let sanitized = word.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "_", options: .regularExpression)
        return Self.persistentCacheDir.appendingPathComponent("\(sanitized).json")
    }
    
    private func loadPersistentCache() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: Self.persistentCacheDir, includingPropertiesForKeys: nil) else { return }
        
        var loaded = 0
        for file in files where file.pathExtension == "json" {
            if let data = try? Data(contentsOf: file),
               let result = try? JSONDecoder().decode(DictionaryResult.self, from: data) {
                let word = result.word.lowercased()
                cache[word] = result
                loaded += 1
            }
        }
        print("DictionaryService: Loaded \(loaded) entries from persistent cache")
    }
    
    private func saveToPersistentCache(word: String, result: DictionaryResult) {
        let url = persistentCacheURL(for: word)
        if let data = try? JSONEncoder().encode(result) {
            try? data.write(to: url)
        }
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
        var cachedResult: DictionaryResult?
        cacheQueue.sync {
            cachedResult = cache[normalizedWord]
        }
        
        if let cached = cachedResult {
            DispatchQueue.main.async {
                completion(.success(cached))
            }
            return
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
        
        // Fallback to APIs
        fetchFromAPI(word: normalizedWord) { [weak self] result in
            switch result {
            case .success(let apiResult):
                self?.cacheQueue.async {
                    self?.cache[normalizedWord] = apiResult
                    self?.saveToPersistentCache(word: normalizedWord, result: apiResult)
                }
                DispatchQueue.main.async {
                    completion(.success(apiResult))
                }
            case .failure(_):
                // Dictionary API failed — try Wiktionary as fallback
                print("DictionaryService: Primary API failed for '\(normalizedWord)', trying Wiktionary...")
                self?.fetchFromWiktionary(word: normalizedWord) { wiktResult in
                    switch wiktResult {
                    case .success(let wiktApiResult):
                        self?.cacheQueue.async {
                            self?.cache[normalizedWord] = wiktApiResult
                            self?.saveToPersistentCache(word: normalizedWord, result: wiktApiResult)
                        }
                        DispatchQueue.main.async {
                            completion(.success(wiktApiResult))
                        }
                    case .failure(let wiktError):
                        print("DictionaryService: Wiktionary also failed for '\(normalizedWord)'")
                        DispatchQueue.main.async {
                            completion(.failure(wiktError))
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Wiktionary API (fallback for phrases and uncommon words)
    
    private func fetchFromWiktionary(word: String, completion: @escaping (Result<DictionaryResult, Error>) -> Void) {
        // Wiktionary uses underscores for spaces in URLs
        let wiktWord = word.replacingOccurrences(of: " ", with: "_")
        guard let encodedWord = wiktWord.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://en.wiktionary.org/api/rest_v1/page/definition/\(encodedWord)") else {
            completion(.failure(NSError(domain: "DictionaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid word or URL for Wiktionary"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                let code = (response as? HTTPURLResponse)?.statusCode ?? -1
                completion(.failure(NSError(domain: "DictionaryService", code: code, userInfo: [NSLocalizedDescriptionKey: "Wiktionary: word/phrase not found"])))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "DictionaryService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Wiktionary: no data"])))
                return
            }
            
            do {
                let wiktResponse = try JSONDecoder().decode(WiktionaryResponse.self, from: data)
                
                // Convert Wiktionary format → our DictionaryResult format
                // Wiktionary response is keyed by language code, e.g. "en"
                guard let englishEntries = wiktResponse.en, !englishEntries.isEmpty else {
                    completion(.failure(NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "No English definition found on Wiktionary"])))
                    return
                }
                
                var meanings: [Meaning] = []
                for entry in englishEntries {
                    let defs = entry.definitions.map { wiktDef -> Definition in
                        // Wiktionary definitions may contain HTML tags — strip them
                        let cleanDef = wiktDef.definition.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        let example = wiktDef.examples?.first.map { ex in
                            ex.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
                        }
                        return Definition(
                            definition: cleanDef,
                            example: example,
                            synonyms: nil,
                            antonyms: nil
                        )
                    }
                    
                    if !defs.isEmpty {
                        meanings.append(Meaning(
                            partOfSpeech: entry.partOfSpeech,
                            definitions: defs,
                            synonyms: nil,
                            antonyms: nil
                        ))
                    }
                }
                
                guard !meanings.isEmpty else {
                    completion(.failure(NSError(domain: "DictionaryService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Wiktionary returned no usable definitions"])))
                    return
                }
                
                let result = DictionaryResult(
                    word: word,
                    phonetic: nil,
                    phonetics: nil,
                    meanings: meanings,
                    sourceUrls: ["https://en.wiktionary.org/wiki/\(wiktWord)"]
                )
                
                print("DictionaryService: ✅ Wiktionary returned \(meanings.count) meanings for '\(word)'")
                completion(.success(result))
                
            } catch {
                print("DictionaryService: Wiktionary parse error: \(error)")
                completion(.failure(error))
            }
        }.resume()
    }
    
    // MARK: - Primary Dictionary API
    
    private func fetchFromAPI(word: String, completion: @escaping (Result<DictionaryResult, Error>) -> Void) {
        guard let encodedWord = word.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let url = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/\(encodedWord)") else {
            completion(.failure(NSError(domain: "DictionaryService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid word or URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 5.0
        
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
