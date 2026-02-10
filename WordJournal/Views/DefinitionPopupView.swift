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
    let onAddToJournal: () -> Void
    let onDismiss: () -> Void
    
    @State private var isHovered = false
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
                Text(word.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let phonetic = result.phonetic ?? result.phonetics?.first?.text {
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
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(result.meanings.enumerated()), id: \.offset) { _, meaning in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meaning.partOfSpeech.capitalized)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { idx, definition in
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
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // Actions
            HStack {
                Button("Add to Journal") {
                    onAddToJournal()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
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
    
    /// Play pronunciation: try API audio URL first, fall back to Google TTS
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
            var played = false
            
            for url in urlsToTry {
                print("PronunciationPlayer: Trying audio from \(url.host ?? url.absoluteString)")
                
                if self?.downloadAndPlay(url: url) == true {
                    played = true
                    break
                }
            }
            
            if !played {
                print("PronunciationPlayer: ❌ All audio sources failed for '\(word)'")
            }
            
            DispatchQueue.main.async {
                self?.isPlaying = false
            }
        }
    }
    
    /// Download audio from URL and play with afplay. Returns true if successful.
    private func downloadAndPlay(url: URL) -> Bool {
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
        
        // Save to temp file and play with afplay
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("wordjournal_pronunciation.mp3")
        do {
            try data.write(to: tempURL)
            
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
            process.arguments = [tempURL.path]
            
            try process.run()
            process.waitUntilExit()
            
            let success = process.terminationStatus == 0
            if success {
                print("PronunciationPlayer: ✅ Played audio from \(url.host ?? "unknown")")
            } else {
                print("PronunciationPlayer: afplay exited with status \(process.terminationStatus)")
            }
            
            try? FileManager.default.removeItem(at: tempURL)
            return success
        } catch {
            print("PronunciationPlayer: afplay failed: \(error)")
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

