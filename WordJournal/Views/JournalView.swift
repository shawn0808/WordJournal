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
            HStack {
                TextField("Search...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Spacer()
                
                Text("\(filteredEntries.count) entries")
                    .foregroundColor(.secondary)
                
                Button("Export CSV") {
                    exportToCSV()
                }
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Table
            Table(filteredEntries, selection: .constant(nil)) {
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
                
                TableColumn("Date") { entry in
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
