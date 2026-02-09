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
