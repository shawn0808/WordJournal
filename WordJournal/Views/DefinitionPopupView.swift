//
//  DefinitionPopupView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

struct DefinitionPopupView: View {
    let word: String
    let result: DictionaryResult
    let onAddToJournal: (String, String, String) -> Void  // (definition, partOfSpeech, example)
    let onDismiss: () -> Void
    
    @State private var isHovered = false
    @State private var addedDefinitions: Set<String> = []  // Track which definitions have been added
    @StateObject private var audioPlayer = PronunciationPlayer()
    
    /// Find the first available audio URL from phonetics
    private var audioURL: URL? {
        guard let phonetics = result.phonetics else { return nil }
        for phonetic in phonetics {
            if let urlString = phonetic.audio, !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(word.contains(" ") ? word : word.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if word.contains(" ") {
                    Text("phrase")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.7))
                        .cornerRadius(4)
                } else if let phonetic = result.phonetic ?? result.phonetics?.first?.text {
                    Text("[\(phonetic)]")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Pronunciation button
                Button(action: {
                    audioPlayer.pronounce(word: word, audioURL: audioURL)
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .foregroundColor(.blue)
                        .font(.body)
                }
                .buttonStyle(.plain)
                .help("Pronounce word")
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Meanings
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(result.meanings.enumerated()), id: \.offset) { _, meaning in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meaning.partOfSpeech.capitalized)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { idx, definition in
                                let defKey = "\(meaning.partOfSpeech):\(idx)"
                                let isAdded = addedDefinitions.contains(defKey)
                                
                                HStack(alignment: .top, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(idx + 1). \(definition.definition)")
                                            .font(.body)
                                        
                                        if let example = definition.example {
                                            Text("\"\(example)\"")
                                                .font(.caption)
                                                .italic()
                                                .foregroundColor(.secondary)
                                                .padding(.leading, 8)
                                        }
                                    }
                                    
                                    Spacer()
                                    
                                    // Add button for this specific definition
                                    Button(action: {
                                        addedDefinitions.insert(defKey)
                                        onAddToJournal(
                                            definition.definition,
                                            meaning.partOfSpeech,
                                            definition.example ?? ""
                                        )
                                    }) {
                                        Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                            .foregroundColor(isAdded ? .green : .blue)
                                            .font(.title3)
                                    }
                                    .buttonStyle(.plain)
                                    .help(isAdded ? "Added to Journal" : "Add this definition to Journal")
                                    .disabled(isAdded)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
        .padding()
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Pronunciation Player

class PronunciationPlayer: NSObject, ObservableObject {
    @Published var isPlaying = false
    
    private var downloadTask: URLSessionDataTask?
    
    // Audio cache directory
    private static let cacheDirectory: URL = {
        let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        let audioCache = caches.appendingPathComponent("WordJournal/audio", isDirectory: true)
        try? FileManager.default.createDirectory(at: audioCache, withIntermediateDirectories: true)
        return audioCache
    }()
    
    /// Get cached file URL for a word
    private func cacheURL(for word: String) -> URL {
        let sanitized = word.lowercased().replacingOccurrences(of: "[^a-z0-9]", with: "_", options: .regularExpression)
        return Self.cacheDirectory.appendingPathComponent("\(sanitized).mp3")
    }
    
    /// Play pronunciation: try cache first, then API audio URL, fall back to Google TTS
    func pronounce(word: String, audioURL: URL?) {
        guard !isPlaying else {
            print("PronunciationPlayer: Already playing, ignoring")
            return
        }
        
        isPlaying = true
        
        // Build list of audio URLs to try in order
        var urlsToTry: [URL] = []
        
        // 1. Dictionary API audio URL (if available)
        if let url = audioURL {
            urlsToTry.append(url)
        }
        
        // 2. Google Translate TTS fallback
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        if let googleURL = URL(string: "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=\(encoded)") {
            urlsToTry.append(googleURL)
        }
        
        // Try each URL on a background thread
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            var played = false
            
            // Check cache first
            let cached = self.cacheURL(for: word)
            if FileManager.default.fileExists(atPath: cached.path) {
                print("PronunciationPlayer: ✅ Playing from cache for '\(word)'")
                if self.playFile(at: cached) {
                    played = true
                }
            }
            
            if !played {
                for url in urlsToTry {
                    print("PronunciationPlayer: Trying audio from \(url.host ?? url.absoluteString)")
                    
                    if self.downloadAndPlay(url: url, cacheAs: word) {
                        played = true
                        break
                    }
                }
            }
            
            if !played {
                print("PronunciationPlayer: ❌ All audio sources failed for '\(word)'")
            }
            
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }
    
    /// Download audio from URL and play with afplay. Returns true if successful.
    /// Synchronous download and play — can be called from background thread
    func downloadAndPlaySync(url: URL) -> Bool {
        return downloadAndPlay(url: url, cacheAs: nil)
    }
    
    /// Play an audio file using afplay. Returns true if successful.
    private func playFile(at fileURL: URL) -> Bool {
        do {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
            process.arguments = [fileURL.path]
            
            try process.run()
            process.waitUntilExit()
            
            return process.terminationStatus == 0
        } catch {
            print("PronunciationPlayer: afplay failed: \(error)")
            return false
        }
    }
    
    private func downloadAndPlay(url: URL, cacheAs word: String?) -> Bool {
        let semaphore = DispatchSemaphore(value: 0)
        var audioData: Data?
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("PronunciationPlayer: Download error: \(error.localizedDescription)")
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("PronunciationPlayer: HTTP \(httpResponse.statusCode)")
            } else {
                audioData = data
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        
        guard let data = audioData, !data.isEmpty else {
            print("PronunciationPlayer: No audio data from \(url.host ?? "unknown")")
            return false
        }
        
        // Save to cache if word is provided
        if let word = word {
            let cached = cacheURL(for: word)
            try? data.write(to: cached)
            print("PronunciationPlayer: 💾 Cached audio for '\(word)'")
        }
        
        // Save to temp file and play with afplay
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("wordjournal_pronunciation.mp3")
        do {
            try data.write(to: tempURL)
            
            let success = playFile(at: tempURL)
            if success {
                print("PronunciationPlayer: ✅ Played audio from \(url.host ?? "unknown")")
            } else {
                print("PronunciationPlayer: afplay exited with non-zero status")
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            return success
        } catch {
            print("PronunciationPlayer: Failed to write temp file: \(error)")
            try? FileManager.default.removeItem(at: tempURL)
            return false
        }
    }
    
    /// Stop any current playback
    func stop() {
        downloadTask?.cancel()
        downloadTask = nil
        isPlaying = false
    }
}

