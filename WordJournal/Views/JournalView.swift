//
//  JournalView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI

struct JournalView: View {
    @EnvironmentObject var journalStorage: JournalStorage
    @State private var searchText = ""
    @State private var editingEntry: WordEntry?
    @State private var showExportAlert = false
    @StateObject private var audioPlayer = PronunciationPlayer()
    @State private var isPlayingAll = false
    @State private var currentPlayIndex = 0
    
    var filteredEntries: [WordEntry] {
        if searchText.isEmpty {
            return journalStorage.entries
        }
        
        return journalStorage.entries.filter { entry in
            entry.word.localizedCaseInsensitiveContains(searchText) ||
            entry.definition.localizedCaseInsensitiveContains(searchText) ||
            entry.notes.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    TextField("Search...", text: $searchText)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 85)
                    
                    Text("\(filteredEntries.count) entries")
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                
                HStack(spacing: 8) {
                    Button(action: {
                        if isPlayingAll {
                            stopPlayAll()
                        } else {
                            playAllWords()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isPlayingAll ? "stop.fill" : "play.fill")
                            Text(isPlayingAll ? "Stop (\(currentPlayIndex + 1)/\(filteredEntries.count))" : "Play All")
                        }
                    }
                    .disabled(filteredEntries.isEmpty)
                    
                    Button("Export CSV") {
                        exportToCSV()
                    }
                    
                    Spacer()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            // Table
            Table(filteredEntries, selection: .constant(nil)) {
                TableColumn("") { entry in
                    Button(action: {
                        audioPlayer.pronounce(word: entry.word, audioURL: nil)
                    }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .foregroundColor(.blue)
                            .font(.caption)
                    }
                    .buttonStyle(.plain)
                    .help("Pronounce \(entry.word)")
                }
                .width(30)
                
                TableColumn("Word") { entry in
                    EditableText(text: Binding(
                        get: { entry.word },
                        set: { newValue in
                            var updated = entry
                            updated.word = newValue
                            journalStorage.updateEntry(updated)
                        }
                    ))
                }
                .width(min: 100, ideal: 150)
                
                TableColumn("Definition") { entry in
                    EditableText(text: Binding(
                        get: { entry.definition },
                        set: { newValue in
                            var updated = entry
                            updated.definition = newValue
                            journalStorage.updateEntry(updated)
                        }
                    ))
                }
                .width(min: 200, ideal: 300)
                
                TableColumn("Example") { entry in
                    EditableText(text: Binding(
                        get: { entry.example },
                        set: { newValue in
                            var updated = entry
                            updated.example = newValue
                            journalStorage.updateEntry(updated)
                        }
                    ))
                }
                .width(min: 150, ideal: 250)
                
                TableColumn("Part of Speech") { entry in
                    EditableText(text: Binding(
                        get: { entry.partOfSpeech },
                        set: { newValue in
                            var updated = entry
                            updated.partOfSpeech = newValue
                            journalStorage.updateEntry(updated)
                        }
                    ))
                }
                .width(min: 100, ideal: 120)
                
                TableColumn("Date Added") { entry in
                    Text(entry.dateLookedUp, style: .date)
                        .foregroundColor(.secondary)
                }
                .width(min: 100, ideal: 120)
                
                TableColumn("Notes") { entry in
                    EditableText(text: Binding(
                        get: { entry.notes },
                        set: { newValue in
                            var updated = entry
                            updated.notes = newValue
                            journalStorage.updateEntry(updated)
                        }
                    ))
                }
                .width(min: 150, ideal: 200)
                
                TableColumn("") { entry in
                    Button(action: {
                        journalStorage.deleteEntry(entry)
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                    .buttonStyle(.plain)
                }
                .width(50)
            }
        }
        .alert("Export Complete", isPresented: $showExportAlert) {
            Button("OK") { }
        } message: {
            Text("CSV file has been saved to your Desktop.")
        }
    }
    
    private func playAllWords() {
        let words = filteredEntries.map { $0.word }
        guard !words.isEmpty else { return }
        
        isPlayingAll = true
        currentPlayIndex = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            for (index, word) in words.enumerated() {
                // Check if stopped
                if !isPlayingAll { break }
                
                DispatchQueue.main.async {
                    currentPlayIndex = index
                }
                
                print("PronunciationPlayer: Playing all - [\(index + 1)/\(words.count)] '\(word)'")
                
                // Use synchronous download and play
                let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
                if let url = URL(string: "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=\(encoded)") {
                    _ = audioPlayer.downloadAndPlaySync(url: url)
                }
                
                // Small pause between words
                if isPlayingAll && index < words.count - 1 {
                    Thread.sleep(forTimeInterval: 0.5)
                }
            }
            
            DispatchQueue.main.async {
                isPlayingAll = false
            }
        }
    }
    
    private func stopPlayAll() {
        isPlayingAll = false
        audioPlayer.stop()
    }
    
    private func exportToCSV() {
        let csv = journalStorage.exportToCSV()
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileURL = desktopURL.appendingPathComponent("WordJournal_\(Date().timeIntervalSince1970).csv")
        
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            showExportAlert = true
        } catch {
            print("Error exporting CSV: \(error)")
        }
    }
}

struct EditableText: View {
    @Binding var text: String
    @State private var isEditing = false
    @FocusState private var isFocused: Bool
    
    var body: some View {
        if isEditing {
            TextField("", text: $text)
                .textFieldStyle(.plain)
                .focused($isFocused)
                .onSubmit {
                    isEditing = false
                }
                .onChange(of: isFocused) { focused in
                    if !focused {
                        isEditing = false
                    }
                }
        } else {
            Text(text.isEmpty ? "—" : text)
                .onTapGesture(count: 2) {
                    isEditing = true
                    isFocused = true
                }
        }
    }
}
