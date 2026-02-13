//
//  DictionaryService.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation
import CoreServices
import NaturalLanguage

// Private Dictionary Services API declarations
@_silgen_name("DCSGetActiveDictionaries")
func DCSGetActiveDictionaries() -> CFArray?

@_silgen_name("DCSDictionaryGetName")
func DCSDictionaryGetName(_ dictionary: DCSDictionary) -> CFString

class DictionaryService: ObservableObject {
    static let shared = DictionaryService()
    
    private var localDictionary: [String: LocalDictionaryEntry] = [:]
    private var cache: [String: DictionaryResult] = [:]
    private let cacheQueue = DispatchQueue(label: "com.wordjournal.cache")
    
    /// Recently looked up words (most recent first, max 5)
    @Published var recentLookups: [String] = []
    private let maxRecentLookups = 5
    
    private func addToRecentLookups(_ word: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            // Remove if already in list, then prepend
            self.recentLookups.removeAll { $0.lowercased() == word.lowercased() }
            self.recentLookups.insert(word, at: 0)
            if self.recentLookups.count > self.maxRecentLookups {
                self.recentLookups = Array(self.recentLookups.prefix(self.maxRecentLookups))
            }
        }
    }
    
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
                // Skip cached macOS Dictionary results — they're instant to re-fetch
                // and we want them re-parsed with the latest parser logic
                if result.sourceUrls?.contains("macOS Dictionary") == true {
                    try? fm.removeItem(at: file)
                    continue
                }
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
    
    // MARK: - macOS Built-in Dictionary (DCSCopyTextDefinition)
    
    // Private Dictionary Services API to access specific dictionaries (e.g., NOAD vs Thesaurus)
    private lazy var definitionDictionary: DCSDictionary? = {
        return findDefinitionDictionary()
    }()
    
    private func findDefinitionDictionary() -> DCSDictionary? {
        // Get all active dictionaries using private API
        guard let cfArray = DCSGetActiveDictionaries() else {
            print("DictionaryService: Could not get active dictionaries")
            return nil
        }
        
        let count = CFArrayGetCount(cfArray)
        guard count > 0 else { return nil }
        
        // Preferred dictionary names — definition dictionaries, NOT thesaurus
        let preferredNames = ["new oxford american", "oxford dictionary of english", "oxford american"]
        let excludeNames = ["thesaurus", "writer"]
        
        var allDicts: [(DCSDictionary, String)] = []
        
        for i in 0..<count {
            guard let ptr = CFArrayGetValueAtIndex(cfArray, i) else { continue }
            let dict = unsafeBitCast(ptr, to: DCSDictionary.self)
            let name = (DCSDictionaryGetName(dict) as String)
            allDicts.append((dict, name))
        }
        
        // Find preferred definition dictionary
        for (dict, name) in allDicts {
            let nameLower = name.lowercased()
            
            // Skip thesaurus dictionaries
            if excludeNames.contains(where: { nameLower.contains($0) }) { continue }
            
            // Prefer Oxford definition dictionaries
            if preferredNames.contains(where: { nameLower.contains($0) }) {
                print("DictionaryService: Using dictionary: '\(name)'")
                return dict
            }
        }
        
        // Log available dictionaries for debugging
        for (_, name) in allDicts {
            print("DictionaryService: Available dictionary: '\(name)'")
        }
        
        return nil
    }
    
    private func fetchFromSystemDictionary(word: String) -> DictionaryResult? {
        // Guard against empty or excessively long words that can crash CoreServices
        let trimmed = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed.count <= 200 else { return nil }
        
        // We MUST have a specific dictionary reference — passing nil to DCS APIs
        // can cause EXC_BAD_ACCESS on some macOS versions
        guard let dictRef = definitionDictionary else {
            print("DictionaryService: No system dictionary available, skipping")
            return nil
        }
        
        let cfWord = trimmed as CFString
        let range = DCSGetTermRangeInString(dictRef, cfWord, 0)
        
        guard range.location != kCFNotFound else {
            print("DictionaryService: System dictionary — no term found for '\(trimmed)'")
            return nil
        }
        
        guard let cfDefinition = DCSCopyTextDefinition(dictRef, cfWord, range) else {
            print("DictionaryService: System dictionary — no definition for '\(trimmed)'")
            return nil
        }
        
        let fullText = cfDefinition.takeRetainedValue() as String
        return parseSystemDictionaryText(word: trimmed, text: fullText)
    }
    
    private func parseSystemDictionaryText(word: String, text: String) -> DictionaryResult? {
        // macOS dictionary can return text in two formats:
        //   1. Single line: "word | phonetic | noun definition text. ORIGIN ..."
        //   2. Multi-line: lines separated by \n with POS headers, numbered defs, etc.
        
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        var phonetic: String? = nil
        var bodyText = text
        var headword: String? = nil  // The actual dictionary headword (base form)
        
        // Extract phonetic and body from pipe-separated header
        // Format: "word | phonetic | rest..."  or "word | phonetic |\nrest..."
        if text.contains("|") {
            let parts = text.components(separatedBy: "|")
            if parts.count >= 3 {
                // First part is the dictionary headword (e.g. "mammologist" even if we looked up "mammologists")
                let headwordPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if !headwordPart.isEmpty {
                    headword = headwordPart
                }
                let phoneticPart = parts[1].trimmingCharacters(in: .whitespaces)
                if !phoneticPart.isEmpty {
                    phonetic = "/\(phoneticPart)/"
                }
                // Everything after the second | is the body
                bodyText = parts.dropFirst(2).joined(separator: "|").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if parts.count == 2 {
                // "word | rest..."
                let headwordPart = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                if !headwordPart.isEmpty {
                    headword = headwordPart
                }
                bodyText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Known part-of-speech labels
        let posLabels = ["noun", "verb", "adjective", "adverb", "pronoun", "preposition",
            "conjunction", "interjection", "exclamation", "determiner", "article",
            "abbreviation", "prefix", "suffix", "combining form", "modal verb",
            "auxiliary verb", "linking verb", "phrasal verb"]
        
        // Stop words — truncate body at these section headers
        let stopPatterns = ["PHRASES", "PHRASAL VERBS", "DERIVATIVES", "ORIGIN", "USAGE", "NOTE"]
        for stop in stopPatterns {
            if let range = bodyText.range(of: stop) {
                bodyText = String(bodyText[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Strip bracketed grammar annotations (e.g. [mass noun], [with object]) early
        // so they don't interfere with POS detection or definition text
        bodyText = stripBracketedAnnotations(bodyText)
        
        guard !bodyText.isEmpty else { return nil }
        
        // Split body into segments by POS labels
        // The POS label may appear inline: "noun a slowly moving mass..." or on its own line
        var meanings: [Meaning] = []
        
        // Build a regex that finds POS labels at word boundaries
        let posPattern = "\\b(" + posLabels.joined(separator: "|") + ")\\b"
        
        // Find all POS positions in the body
        struct POSMatch {
            let pos: String
            let contentStart: String.Index
        }
        
        var posMatches: [POSMatch] = []
        if let regex = try? NSRegularExpression(pattern: posPattern, options: [.caseInsensitive]) {
            let nsBody = bodyText as NSString
            let results = regex.matches(in: bodyText, range: NSRange(location: 0, length: nsBody.length))
            for match in results {
                guard let swiftRange = Range(match.range, in: bodyText) else { continue }
                let posStr = String(bodyText[swiftRange]).lowercased()
                posMatches.append(POSMatch(pos: posStr, contentStart: swiftRange.upperBound))
            }
        }
        
        if posMatches.isEmpty {
            // No POS found — treat the whole body as a single definition
            let defs = splitDefinitions(bodyText)
            if !defs.isEmpty {
                meanings.append(Meaning(
                    partOfSpeech: "unknown",
                    definitions: defs,
                    synonyms: nil,
                    antonyms: nil
                ))
            }
        } else {
            // Extract content between consecutive POS labels
            for (i, posMatch) in posMatches.enumerated() {
                let contentEnd: String.Index
                if i + 1 < posMatches.count {
                    // Content runs until the next POS label starts
                    // Find the start of the next POS keyword by going back from its contentStart
                    let nextPOS = posMatches[i + 1]
                    let nextPOSLen = nextPOS.pos.count
                    contentEnd = bodyText.index(nextPOS.contentStart, offsetBy: -nextPOSLen, limitedBy: bodyText.startIndex) ?? nextPOS.contentStart
                } else {
                    contentEnd = bodyText.endIndex
                }
                
                let content = String(bodyText[posMatch.contentStart..<contentEnd]).trimmingCharacters(in: .whitespacesAndNewlines)
                
                guard !content.isEmpty else { continue }
                
                let defs = splitDefinitions(content)
                if !defs.isEmpty {
                    meanings.append(Meaning(
                        partOfSpeech: posMatch.pos,
                        definitions: defs,
                        synonyms: nil,
                        antonyms: nil
                    ))
                }
            }
        }
        
        guard !meanings.isEmpty else { return nil }
        
        // Use the dictionary's headword (base form) if available, otherwise the input word
        let displayWord = headword ?? word
        print("DictionaryService: ✅ System dictionary returned \(meanings.count) meaning(s) for '\(displayWord)' (looked up '\(word)')")
        
        return DictionaryResult(
            word: displayWord,
            phonetic: phonetic,
            phonetics: phonetic.map { [Phonetic(text: $0, audio: nil)] },
            meanings: meanings,
            sourceUrls: ["macOS Dictionary"]
        )
    }
    
    /// Strip bracketed grammar annotations like [mass noun], [with object], [no object], [count noun], etc.
    private func stripBracketedAnnotations(_ text: String) -> String {
        return text
            .replacingOccurrences(of: "\\[.*?\\]\\s*", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Split a definition content string into individual Definition objects.
    /// Handles numbered definitions ("1 ...", "2 ...") and sentence-based splitting.
    private func splitDefinitions(_ text: String) -> [Definition] {
        var definitions: [Definition] = []
        
        // Strip bracketed grammar annotations (e.g. [mass noun], [with object]) before parsing
        let cleanedText = stripBracketedAnnotations(text)
        
        guard !cleanedText.isEmpty else { return [] }
        
        // Try splitting by numbered definitions (1 ..., 2 ...)
        let numberedPattern = "(?:^|\\s)\\d+\\s+"
        if let regex = try? NSRegularExpression(pattern: numberedPattern),
           regex.numberOfMatches(in: cleanedText, range: NSRange(location: 0, length: (cleanedText as NSString).length)) >= 2 {
            // Has numbered defs — split using regex matches as delimiters
            let nsText = cleanedText as NSString
            let matches = regex.matches(in: cleanedText, range: NSRange(location: 0, length: nsText.length))
            for (i, match) in matches.enumerated() {
                let contentStart = match.range.location + match.range.length
                let contentEnd = (i + 1 < matches.count) ? matches[i + 1].range.location : nsText.length
                let part = nsText.substring(with: NSRange(location: contentStart, length: contentEnd - contentStart))
                let cleaned = part.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleaned.count >= 3 {
                    let (def, example) = extractExample(from: cleaned)
                    definitions.append(Definition(definition: def, example: example, synonyms: nil, antonyms: nil))
                }
            }
        }
        
        // If no numbered defs found, try splitting by bullet points or treat as a single definition
        if definitions.isEmpty {
            // Split by bullet characters
            let bulletParts = cleanedText.components(separatedBy: "•").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { $0.count >= 3 }
            if bulletParts.count > 1 {
                for part in bulletParts {
                    let (def, example) = extractExample(from: part)
                    definitions.append(Definition(definition: def, example: example, synonyms: nil, antonyms: nil))
                }
            } else {
                // Single definition — use the whole text
                if cleanedText.count >= 3 {
                    let (def, example) = extractExample(from: cleanedText)
                    definitions.append(Definition(definition: def, example: example, synonyms: nil, antonyms: nil))
                }
            }
        }
        
        return definitions
    }
    
    /// Try to split "definition text: example sentence" into (definition, example).
    /// NOAD uses ": " followed by an example sentence — sometimes quoted, sometimes unquoted.
    private func extractExample(from text: String) -> (String, String?) {
        let quoteChars = CharacterSet(charactersIn: "\"'\u{201C}\u{201D}\u{2018}\u{2019}")
        
        // Find the last ": " that looks like a definition–example separator.
        // NOAD format: "definition text: example sentence."
        // We search for ": " where the part before it looks like a definition
        // (ends with a word char, not a URL scheme like "http:").
        if let colonRange = text.range(of: ": ") {
            let beforeColon = String(text[..<colonRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            let afterColon = String(text[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
            
            // Skip if it looks like a URL (e.g. "http: //") or too short
            guard beforeColon.count >= 3, !afterColon.isEmpty else {
                return (text, nil)
            }
            
            // If quoted, strip quotes
            if afterColon.hasPrefix("\"") || afterColon.hasPrefix("'") || afterColon.hasPrefix("\u{201C}") {
                let example = afterColon.trimmingCharacters(in: quoteChars)
                return (beforeColon, example)
            }
            
            // Unquoted example: the text after ": " starts with a lowercase letter
            // (definitions/labels typically start uppercase, examples start lowercase)
            if let firstChar = afterColon.first, firstChar.isLowercase {
                // Clean up trailing period or sub-definitions marked with •
                var example = afterColon
                // If there's a bullet point (•), only take the first example
                if let bulletRange = example.range(of: " •") {
                    example = String(example[..<bulletRange.lowerBound])
                }
                // Trim trailing period
                example = example.trimmingCharacters(in: .whitespaces)
                if example.hasSuffix(".") {
                    example = String(example.dropLast()).trimmingCharacters(in: .whitespaces)
                }
                return (beforeColon, example)
            }
        }
        return (text, nil)
    }
    
    // MARK: - Lemmatization (NLTagger)
    
    private func lemmatize(_ word: String) -> String {
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = word
        
        let range = word.startIndex..<word.endIndex
        var lemma = word
        
        tagger.enumerateTags(in: range, unit: .word, scheme: .lemma) { tag, _ in
            if let tag = tag {
                lemma = tag.rawValue
            }
            return false // stop after first word
        }
        
        return lemma.lowercased()
    }
    
    /// Generate suffix-stripped candidates for words NLTagger doesn't recognize.
    /// Returns candidates in priority order (most specific suffix first).
    private func suffixStrippedCandidates(_ word: String) -> [String] {
        let lower = word.lowercased()
        
        // Don't strip words that end in common non-plural "s" suffixes
        let noStripSuffixes = [
            "ous", "ious", "eous",          // adventurous, curious, gorgeous
            "us",                            // genus, campus, status
            "ss",                            // class, grass, boss
            "is",                            // basis, crisis, analysis
            "ness",                          // kindness, darkness
            "less",                          // careless, homeless
            "wards",                         // towards, afterwards
            "ics",                           // physics, mathematics
            "itis",                          // arthritis, bronchitis
        ]
        
        for suffix in noStripSuffixes {
            if lower.hasSuffix(suffix) {
                return []  // Not a plural — don't strip
            }
        }
        
        // Order matters: check longer/more specific suffixes first
        let suffixRules: [(suffix: String, replacement: String, minStemLength: Int)] = [
            ("ologies", "ology", 3),
            ("nesses", "ness", 3),
            ("ments", "ment", 3),
            ("ists", "ist", 3),         // e.g. mammologists → mammologist
            ("isms", "ism", 3),
            ("ings", "ing", 3),
            ("ies", "y", 3),            // e.g. berries → berry
            ("ses", "se", 3),           // e.g. responses → response
            ("ers", "er", 3),
            ("ors", "or", 3),
            ("es", "e", 3),             // e.g. plates → plate
            ("es", "", 3),              // e.g. dishes → dish (if dropping "e" form fails)
            ("s", "", 3),               // e.g. cats → cat (generic plural)
        ]
        
        var candidates: [String] = []
        
        for rule in suffixRules {
            if lower.hasSuffix(rule.suffix) {
                let stem = String(lower.dropLast(rule.suffix.count))
                if stem.count >= rule.minStemLength {
                    let candidate = stem + rule.replacement
                    if candidate != lower && !candidates.contains(candidate) {
                        candidates.append(candidate)
                    }
                }
            }
        }
        
        return candidates
    }
    
    func lookup(_ word: String, completion: @escaping (Result<DictionaryResult, Error>) -> Void) {
        let normalizedWord = word.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        // Wrap completion to track recent lookups on success
        let trackedCompletion: (Result<DictionaryResult, Error>) -> Void = { [weak self] result in
            if case .success(let dictResult) = result {
                self?.addToRecentLookups(dictResult.word)
            }
            completion(result)
        }
        
        // Only lemmatize single words — phrases (e.g. "break a leg") must be looked up as-is
        let isPhrase = normalizedWord.contains(" ")
        let baseForm = isPhrase ? normalizedWord : lemmatize(normalizedWord)
        var wasLemmatized = !isPhrase && baseForm != normalizedWord && !baseForm.isEmpty
        var lookupWord = wasLemmatized ? baseForm : normalizedWord
        
        if wasLemmatized {
            print("DictionaryService: Lemmatized '\(normalizedWord)' → '\(lookupWord)'")
        }
        
        // Check cache first (try both original and lemmatized forms)
        var cachedResult: DictionaryResult?
        cacheQueue.sync {
            cachedResult = cache[lookupWord] ?? cache[normalizedWord]
        }
        
        if let cached = cachedResult {
            DispatchQueue.main.async {
                trackedCompletion(.success(cached))
            }
            return
        }
        
        // Check macOS built-in dictionary with the current word first
        if let systemResult = fetchFromSystemDictionary(word: lookupWord) {
            cacheQueue.async { [weak self] in
                self?.cache[lookupWord] = systemResult
            }
            DispatchQueue.main.async {
                trackedCompletion(.success(systemResult))
            }
            return
        }
        
        // If NLTagger didn't lemmatize and the system dictionary didn't find the word,
        // try suffix-stripped candidates (e.g. "mammologists" → "mammologist")
        if !wasLemmatized && !isPhrase {
            let candidates = suffixStrippedCandidates(normalizedWord)
            if !candidates.isEmpty {
                // Try each candidate against the system dictionary
                for candidate in candidates {
                    if let systemResult = fetchFromSystemDictionary(word: candidate) {
                        print("DictionaryService: Suffix-stripped '\(normalizedWord)' → '\(candidate)' (found in system dictionary)")
                        cacheQueue.async { [weak self] in
                            self?.cache[candidate] = systemResult
                            self?.cache[normalizedWord] = systemResult
                        }
                        DispatchQueue.main.async {
                            trackedCompletion(.success(systemResult))
                        }
                        return
                    }
                }
                // No candidate found in system dictionary — use the best candidate
                // for subsequent API/Wiktionary lookups
                lookupWord = candidates.first!
                wasLemmatized = true
                print("DictionaryService: Suffix-stripped '\(normalizedWord)' → '\(lookupWord)' (for API lookup)")
            }
        }
        
        // Check local JSON dictionary (legacy fallback)
        if let localEntry = localDictionary[lookupWord] {
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
                self?.cache[lookupWord] = result
            }
            
            DispatchQueue.main.async {
                trackedCompletion(.success(result))
            }
            return
        }
        
        // Fallback to APIs
        fetchFromAPI(word: lookupWord) { [weak self] result in
            switch result {
            case .success(let apiResult):
                self?.cacheQueue.async {
                    self?.cache[lookupWord] = apiResult
                    self?.saveToPersistentCache(word: lookupWord, result: apiResult)
                }
                DispatchQueue.main.async {
                    trackedCompletion(.success(apiResult))
                }
            case .failure(_):
                // Dictionary API failed — try Wiktionary as fallback
                print("DictionaryService: Primary API failed for '\(lookupWord)', trying Wiktionary...")
                self?.fetchFromWiktionary(word: lookupWord) { wiktResult in
                    switch wiktResult {
                    case .success(let wiktApiResult):
                        self?.cacheQueue.async {
                            self?.cache[lookupWord] = wiktApiResult
                            self?.saveToPersistentCache(word: lookupWord, result: wiktApiResult)
                        }
                        DispatchQueue.main.async {
                            trackedCompletion(.success(wiktApiResult))
                        }
                    case .failure(let wiktError):
                        print("DictionaryService: Wiktionary also failed for '\(lookupWord)'")
                        DispatchQueue.main.async {
                            trackedCompletion(.failure(wiktError))
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
