//
//  AIWordInsight.swift
//  WordJournal
//
//  AI-generated word insights: plain explanation, synonyms, antonyms.
//

import Foundation

struct AIWordInsight: Equatable, Codable {
    /// Part of speech (e.g. noun, verb, adjective), like NOAD output.
    let partOfSpeech: String?
    let plainExplanation: String
    /// Example sentence showing the word in use (optional for backward compatibility with cache).
    let exampleSentence: String?
    let synonyms: [String]
    let antonyms: [String]

    init(partOfSpeech: String?, plainExplanation: String, exampleSentence: String? = nil, synonyms: [String], antonyms: [String]) {
        self.partOfSpeech = partOfSpeech
        self.plainExplanation = plainExplanation
        self.exampleSentence = exampleSentence
        self.synonyms = synonyms
        self.antonyms = antonyms
    }

    enum CodingKeys: String, CodingKey {
        case partOfSpeech, plainExplanation, exampleSentence, synonyms, antonyms
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        partOfSpeech = try c.decodeIfPresent(String.self, forKey: .partOfSpeech)
        plainExplanation = try c.decode(String.self, forKey: .plainExplanation)
        exampleSentence = try c.decodeIfPresent(String.self, forKey: .exampleSentence)
        synonyms = try c.decode([String].self, forKey: .synonyms)
        antonyms = try c.decode([String].self, forKey: .antonyms)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(partOfSpeech, forKey: .partOfSpeech)
        try c.encode(plainExplanation, forKey: .plainExplanation)
        try c.encodeIfPresent(exampleSentence, forKey: .exampleSentence)
        try c.encode(synonyms, forKey: .synonyms)
        try c.encode(antonyms, forKey: .antonyms)
    }
}
