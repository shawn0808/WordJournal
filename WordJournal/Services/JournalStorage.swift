//
//  JournalStorage.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation
import SQLite3

class JournalStorage: ObservableObject {
    static let shared = JournalStorage()
    
    @Published var entries: [WordEntry] = []
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let fileManager = FileManager.default
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolderURL = appSupportURL.appendingPathComponent("WordJournal", isDirectory: true)
        
        if !fileManager.fileExists(atPath: appFolderURL.path) {
            try? fileManager.createDirectory(at: appFolderURL, withIntermediateDirectories: true)
        }
        
        dbPath = appFolderURL.appendingPathComponent("journal.db").path
        initializeDatabase()
        loadEntries()
    }
    
    private func initializeDatabase() {
        guard sqlite3_open(dbPath, &db) == SQLITE_OK else {
            print("Error opening database: \(String(cString: sqlite3_errmsg(db)))")
            return
        }
        
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS word_entries (
                id TEXT PRIMARY KEY,
                word TEXT NOT NULL,
                definition TEXT NOT NULL,
                part_of_speech TEXT NOT NULL,
                example TEXT,
                date_looked_up REAL NOT NULL,
                notes TEXT
            );
        """
        
        var createTableStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, createTableSQL, -1, &createTableStatement, nil) == SQLITE_OK {
            if sqlite3_step(createTableStatement) == SQLITE_DONE {
                print("Table created successfully")
            } else {
                print("Table could not be created")
            }
        } else {
            print("CREATE TABLE statement could not be prepared: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(createTableStatement)
    }
    
    func addEntry(_ entry: WordEntry) {
        print("JournalStorage: addEntry() called for word: '\(entry.word)'")
        
        let insertSQL = """
            INSERT INTO word_entries (id, word, definition, part_of_speech, example, date_looked_up, notes)
            VALUES (?, ?, ?, ?, ?, ?, ?);
        """
        
        var insertStatement: OpaquePointer?
        let prepareResult = sqlite3_prepare_v2(db, insertSQL, -1, &insertStatement, nil)
        
        if prepareResult == SQLITE_OK {
            let idStr = (entry.id.uuidString as NSString).utf8String
            let wordStr = (entry.word as NSString).utf8String
            let defStr = (entry.definition as NSString).utf8String
            let posStr = (entry.partOfSpeech as NSString).utf8String
            let exStr = (entry.example as NSString).utf8String
            let notesStr = (entry.notes as NSString).utf8String
            
            sqlite3_bind_text(insertStatement, 1, idStr, -1, nil)
            sqlite3_bind_text(insertStatement, 2, wordStr, -1, nil)
            sqlite3_bind_text(insertStatement, 3, defStr, -1, nil)
            sqlite3_bind_text(insertStatement, 4, posStr, -1, nil)
            sqlite3_bind_text(insertStatement, 5, exStr, -1, nil)
            sqlite3_bind_double(insertStatement, 6, entry.dateLookedUp.timeIntervalSince1970)
            sqlite3_bind_text(insertStatement, 7, notesStr, -1, nil)
            
            let stepResult = sqlite3_step(insertStatement)
            if stepResult == SQLITE_DONE {
                print("JournalStorage: ✅ Entry saved to database: '\(entry.word)'")
                DispatchQueue.main.async {
                    self.entries.append(entry)
                    self.entries.sort { $0.dateLookedUp > $1.dateLookedUp }
                    print("JournalStorage: ✅ Entry added to list. Total entries: \(self.entries.count)")
                }
            } else {
                print("JournalStorage: ❌ Failed to insert. Step result: \(stepResult)")
                print("JournalStorage: Error: \(String(cString: sqlite3_errmsg(db)))")
            }
        } else {
            print("JournalStorage: ❌ Failed to prepare insert. Result: \(prepareResult)")
            print("JournalStorage: Error: \(String(cString: sqlite3_errmsg(db)))")
        }
        sqlite3_finalize(insertStatement)
    }
    
    func updateEntry(_ entry: WordEntry) {
        let updateSQL = """
            UPDATE word_entries
            SET word = ?, definition = ?, part_of_speech = ?, example = ?, notes = ?
            WHERE id = ?;
        """
        
        var updateStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, updateSQL, -1, &updateStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(updateStatement, 1, entry.word, -1, nil)
            sqlite3_bind_text(updateStatement, 2, entry.definition, -1, nil)
            sqlite3_bind_text(updateStatement, 3, entry.partOfSpeech, -1, nil)
            sqlite3_bind_text(updateStatement, 4, entry.example, -1, nil)
            sqlite3_bind_text(updateStatement, 5, entry.notes, -1, nil)
            sqlite3_bind_text(updateStatement, 6, entry.id.uuidString, -1, nil)
            
            if sqlite3_step(updateStatement) == SQLITE_DONE {
                DispatchQueue.main.async {
                    if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                        self.entries[index] = entry
                    }
                }
            }
        }
        sqlite3_finalize(updateStatement)
    }
    
    func deleteEntry(_ entry: WordEntry) {
        let deleteSQL = "DELETE FROM word_entries WHERE id = ?;"
        
        var deleteStatement: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &deleteStatement, nil) == SQLITE_OK {
            sqlite3_bind_text(deleteStatement, 1, entry.id.uuidString, -1, nil)
            
            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                DispatchQueue.main.async {
                    self.entries.removeAll { $0.id == entry.id }
                }
            }
        }
        sqlite3_finalize(deleteStatement)
    }
    
    private func loadEntries() {
        let querySQL = "SELECT id, word, definition, part_of_speech, example, date_looked_up, notes FROM word_entries ORDER BY date_looked_up DESC;"
        
        var queryStatement: OpaquePointer?
        var loadedEntries: [WordEntry] = []
        
        if sqlite3_prepare_v2(db, querySQL, -1, &queryStatement, nil) == SQLITE_OK {
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                guard let idString = sqlite3_column_text(queryStatement, 0),
                      let id = UUID(uuidString: String(cString: idString)),
                      let word = sqlite3_column_text(queryStatement, 1),
                      let definition = sqlite3_column_text(queryStatement, 2),
                      let partOfSpeech = sqlite3_column_text(queryStatement, 3) else {
                    continue
                }
                
                let example = sqlite3_column_text(queryStatement, 4).map { String(cString: $0) } ?? ""
                let dateLookedUp = Date(timeIntervalSince1970: sqlite3_column_double(queryStatement, 5))
                let notes = sqlite3_column_text(queryStatement, 6).map { String(cString: $0) } ?? ""
                
                let entry = WordEntry(
                    id: id,
                    word: String(cString: word),
                    definition: String(cString: definition),
                    partOfSpeech: String(cString: partOfSpeech),
                    example: example,
                    dateLookedUp: dateLookedUp,
                    notes: notes
                )
                
                loadedEntries.append(entry)
            }
        }
        sqlite3_finalize(queryStatement)
        
        DispatchQueue.main.async {
            self.entries = loadedEntries
        }
    }
    
    func exportToCSV() -> String {
        var csv = "Word,Definition,Part of Speech,Example,Date,Notes\n"
        
        for entry in entries {
            let word = escapeCSV(entry.word)
            let definition = escapeCSV(entry.definition)
            let partOfSpeech = escapeCSV(entry.partOfSpeech)
            let example = escapeCSV(entry.example)
            let date = DateFormatter().string(from: entry.dateLookedUp)
            let notes = escapeCSV(entry.notes)
            
            csv += "\(word),\(definition),\(partOfSpeech),\(example),\(date),\(notes)\n"
        }
        
        return csv
    }
    
    private func escapeCSV(_ string: String) -> String {
        if string.contains(",") || string.contains("\"") || string.contains("\n") {
            return "\"\(string.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return string
    }
    
    deinit {
        sqlite3_close(db)
    }
}
