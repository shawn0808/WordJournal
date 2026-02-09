//
//  WordEntry.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation

struct WordEntry: Identifiable, Codable {
    var id: UUID
    var word: String
    var definition: String
    var partOfSpeech: String
    var example: String
    var dateLookedUp: Date
    var notes: String
    
    init(id: UUID = UUID(), word: String, definition: String, partOfSpeech: String, example: String, dateLookedUp: Date = Date(), notes: String = "") {
        self.id = id
        self.word = word
        self.definition = definition
        self.partOfSpeech = partOfSpeech
        self.example = example
        self.dateLookedUp = dateLookedUp
        self.notes = notes
    }
}
