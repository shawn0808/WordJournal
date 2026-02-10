//
//  DictionaryResult.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation

struct DictionaryResult: Codable {
    let word: String
    let phonetic: String?
    let phonetics: [Phonetic]?
    let meanings: [Meaning]
    let sourceUrls: [String]?
    
    enum CodingKeys: String, CodingKey {
        case word, phonetic, phonetics, meanings
        case sourceUrls = "sourceUrls"
    }
}

struct Phonetic: Codable {
    let text: String?
    let audio: String?
}

struct Meaning: Codable {
    let partOfSpeech: String
    let definitions: [Definition]
    let synonyms: [String]?
    let antonyms: [String]?
}

struct Definition: Codable {
    let definition: String
    let example: String?
    let synonyms: [String]?
    let antonyms: [String]?
}

// Local dictionary entry format
struct LocalDictionaryEntry: Codable {
    let word: String
    let phonetic: String?
    let partOfSpeech: String
    let definition: String
    let example: String?
}

// MARK: - Wiktionary API response models

struct WiktionaryResponse: Codable {
    let en: [WiktionaryEntry]?
    
    // Wiktionary returns a dictionary keyed by language code.
    // We use custom decoding to extract the "en" key dynamically.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)
        en = try container.decodeIfPresent([WiktionaryEntry].self, forKey: DynamicCodingKeys(stringValue: "en")!)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        try container.encodeIfPresent(en, forKey: DynamicCodingKeys(stringValue: "en")!)
    }
    
    private struct DynamicCodingKeys: CodingKey {
        var stringValue: String
        var intValue: Int?
        
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { self.intValue = intValue; self.stringValue = String(intValue) }
    }
}

struct WiktionaryEntry: Codable {
    let partOfSpeech: String
    let language: String?
    let definitions: [WiktionaryDefinition]
}

struct WiktionaryDefinition: Codable {
    let definition: String
    let examples: [String]?
}
