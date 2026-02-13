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
    @State private var sortOrder = [KeyPathComparator(\WordEntry.dateLookedUp, order: .reverse)]
    @State private var lookingUpEntryID: UUID? = nil
    @State private var entryToDelete: WordEntry? = nil
    @State private var showDeleteConfirmation = false
    @State private var hoveredToolbarButton: String? = nil
    
    // Accent color matching the popup
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var filteredEntries: [WordEntry] {
        let base: [WordEntry]
        if searchText.isEmpty {
            base = journalStorage.entries
        } else {
            base = journalStorage.entries.filter { entry in
                entry.word.localizedCaseInsensitiveContains(searchText) ||
                entry.definition.localizedCaseInsensitiveContains(searchText) ||
                entry.notes.localizedCaseInsensitiveContains(searchText)
            }
        }
        return base.sorted(using: sortOrder)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Toolbar
            HStack(spacing: 12) {
                // Search field with icon
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                    TextField("Search words...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .frame(width: 220)
                
                // Entry count badge
                HStack(spacing: 5) {
                    Text("\(filteredEntries.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 24, minHeight: 24)
                        .background(Circle().fill(accentBlue.opacity(0.8)))
                    Text("entries")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Toolbar buttons
                toolbarButton(
                    id: "playAll",
                    icon: isPlayingAll ? "stop.fill" : "play.fill",
                    label: isPlayingAll ? "Stop (\(currentPlayIndex + 1)/\(filteredEntries.count))" : "Play All",
                    color: isPlayingAll ? .orange : accentBlue
                ) {
                    if isPlayingAll { stopPlayAll() } else { playAllWords() }
                }
                .disabled(filteredEntries.isEmpty)
                
                toolbarButton(
                    id: "export",
                    icon: "square.and.arrow.up",
                    label: "Export CSV",
                    color: accentBlue
                ) {
                    exportToCSV()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // MARK: - Content
            if filteredEntries.isEmpty && searchText.isEmpty {
                // Empty state
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No words yet")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.secondary)
                    Text("Look up a word to get started, or click\nthe + button below to add one manually.")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(3)
                }
                Spacer()
            } else if filteredEntries.isEmpty && !searchText.isEmpty {
                // No search results
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 36, weight: .thin))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No results for \"\(searchText)\"")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                // Table with alternating row colors
                Table(filteredEntries, sortOrder: $sortOrder) {
                    TableColumn("") { entry in
                        Button(action: {
                            audioPlayer.pronounce(word: entry.word, audioURL: nil)
                        }) {
                            Image(systemName: "speaker.wave.2.fill")
                                .foregroundColor(accentBlue)
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help("Pronounce \(entry.word)")
                    }
                    .width(30)
                    
                    TableColumn("Word", value: \.word) { entry in
                        EditableText(text: Binding(
                            get: { entry.word },
                            set: { newValue in
                                var updated = entry
                                updated.word = newValue
                                journalStorage.updateEntry(updated)
                                
                                // Auto-populate if this is a blank row and user just entered a word
                                if entry.definition.isEmpty && !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    autoLookup(word: newValue.trimmingCharacters(in: .whitespacesAndNewlines), entryID: entry.id)
                                }
                            }
                        ), fontWeight: .semibold)
                        .overlay(alignment: .trailing) {
                            if lookingUpEntryID == entry.id {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .padding(.trailing, 4)
                            }
                        }
                    }
                    .width(min: 100, ideal: 150)
                    
                    TableColumn("Definition", value: \.definition) { entry in
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
                    
                    TableColumn("Example", value: \.example) { entry in
                        EditableText(text: Binding(
                            get: { entry.example },
                            set: { newValue in
                                var updated = entry
                                updated.example = newValue
                                journalStorage.updateEntry(updated)
                            }
                        ), isItalic: true)
                    }
                    .width(min: 150, ideal: 250)
                    
                    TableColumn("POS", value: \.partOfSpeech) { entry in
                        if !entry.partOfSpeech.isEmpty {
                            Text(entry.partOfSpeech)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(accentBlue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule().fill(accentBlue.opacity(0.1))
                                )
                        } else {
                            EditableText(text: Binding(
                                get: { entry.partOfSpeech },
                                set: { newValue in
                                    var updated = entry
                                    updated.partOfSpeech = newValue
                                    journalStorage.updateEntry(updated)
                                }
                            ))
                        }
                    }
                    .width(min: 80, ideal: 100)
                    
                    TableColumn("Date", value: \.dateLookedUp) { entry in
                        Text(entry.dateLookedUp, style: .date)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .width(min: 90, ideal: 110)
                    
                    TableColumn("Notes", value: \.notes) { entry in
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
                            entryToDelete = entry
                            showDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red.opacity(0.6))
                                .font(.system(size: 12))
                        }
                        .buttonStyle(.plain)
                        .pointingHandCursor()
                        .help("Delete \(entry.word)")
                    }
                    .width(40)
                }
                .alternatingRowBackgroundsIfAvailable()
            }
            
            Divider()
            
            // MARK: - Bottom Bar
            HStack(spacing: 12) {
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        _ = journalStorage.addBlankEntry()
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 14))
                        Text("Add Word")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(accentBlue)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accentBlue.opacity(0.08))
                    )
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                
                Spacer()
                
                if !filteredEntries.isEmpty {
                    Text("\(journalStorage.entries.count) total words in journal")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .alert("Export Complete", isPresented: $showExportAlert) {
            Button("OK") { }
        } message: {
            Text("CSV file has been saved to your Desktop.")
        }
        .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    withAnimation {
                        journalStorage.deleteEntry(entry)
                    }
                    entryToDelete = nil
                }
            }
        } message: {
            if let entry = entryToDelete {
                Text("Are you sure you want to delete \"\(entry.word)\" from your journal? This cannot be undone.")
            }
        }
    }
    
    // MARK: - Toolbar Button Helper
    
    @ViewBuilder
    private func toolbarButton(id: String, icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(hoveredToolbarButton == id ? .white : color)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(hoveredToolbarButton == id ? color : color.opacity(0.1))
            )
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredToolbarButton = hovering ? id : nil
            }
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
    
    private func autoLookup(word: String, entryID: UUID) {
        lookingUpEntryID = entryID
        
        DictionaryService.shared.lookup(word) { result in
            DispatchQueue.main.async {
                lookingUpEntryID = nil
                
                switch result {
                case .success(let dictResult):
                    guard let entry = journalStorage.entries.first(where: { $0.id == entryID }) else { return }
                    
                    // Only auto-fill if the definition is still empty (user hasn't manually typed one)
                    guard entry.definition.isEmpty else { return }
                    
                    var updated = entry
                    if let firstMeaning = dictResult.meanings.first,
                       let firstDef = firstMeaning.definitions.first {
                        updated.definition = firstDef.definition
                        updated.partOfSpeech = firstMeaning.partOfSpeech
                        updated.example = firstDef.example ?? ""
                    }
                    journalStorage.updateEntry(updated)
                    print("JournalStorage: ✅ Auto-populated entry for '\(word)'")
                    
                case .failure(let error):
                    print("JournalStorage: Auto-lookup failed for '\(word)': \(error.localizedDescription)")
                }
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
    var fontWeight: Font.Weight = .regular
    var isItalic: Bool = false
    
    @State private var localText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("—", text: $localText)
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: fontWeight))
            .italic(isItalic && !localText.isEmpty)
            .focused($isFocused)
            .onAppear { localText = text }
            .onChange(of: text) { newValue in localText = newValue }
            .onSubmit { text = localText }
            .onChange(of: isFocused) { focused in
                if !focused { text = localText }
            }
    }
}

// MARK: - Availability Helper

extension View {
    @ViewBuilder
    func alternatingRowBackgroundsIfAvailable() -> some View {
        if #available(macOS 14.0, *) {
            self.alternatingRowBackgrounds(.enabled)
        } else {
            self
        }
    }
}
