//
//  DefinitionPopupView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

// MARK: - Pointing Hand Cursor Modifier

struct PointingHandCursor: ViewModifier {
    func body(content: Content) -> some View {
        content.onHover { hovering in
            if hovering {
                NSCursor.pointingHand.set()
            } else {
                NSCursor.arrow.set()
            }
        }
    }
}

extension View {
    func pointingHandCursor() -> some View {
        modifier(PointingHandCursor())
    }
}

struct DefinitionPopupView: View {
    let word: String
    let result: DictionaryResult?
    let isLoading: Bool
    let onAddToJournal: (String, String, String) -> Void  // (definition, partOfSpeech, example)
    let onDismiss: () -> Void
    
    @State private var isHovered = false
    @State private var addedDefinitions: Set<String> = []  // Track which definitions have been added
    @State private var hoveredButton: String? = nil  // Track hovered + button for animation
    @StateObject private var audioPlayer = PronunciationPlayer()
    
    // Accent color for consistent theming
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)  // #5B8FB9-ish
    
    /// Find the first available audio URL from phonetics
    private var audioURL: URL? {
        guard let phonetics = result?.phonetics else { return nil }
        for phonetic in phonetics {
            if let urlString = phonetic.audio, !urlString.isEmpty,
               let url = URL(string: urlString) {
                return url
            }
        }
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 8) {
                Text(word)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                if word.contains(" ") {
                    Text("phrase")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(accentBlue.opacity(0.8))
                        .cornerRadius(4)
                } else if let phonetic = result?.phonetic ?? result?.phonetics?.first?.text {
                    Text("[\(phonetic)]")
                        .font(.system(size: 14, weight: .light, design: .serif))
                        .foregroundColor(.secondary)
                }
                
                // Pronunciation button
                Button(action: {
                    audioPlayer.pronounce(word: word, audioURL: audioURL)
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "speaker.wave.3.fill" : "speaker.wave.2.fill")
                        .foregroundColor(accentBlue)
                        .font(.system(size: 14))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
                .help("Pronounce word")
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary.opacity(0.5))
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .pointingHandCursor()
            }
            
            // Thin accent divider
            Rectangle()
                .fill(accentBlue.opacity(0.3))
                .frame(height: 1)
            
            if isLoading {
                // Loading state
                VStack(spacing: 12) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Looking up definition...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else if let result = result {
                // Meanings
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(result.meanings.enumerated()), id: \.offset) { meaningIdx, meaning in
                            
                            // Visual separator between POS sections
                            if meaningIdx > 0 {
                                HStack(spacing: 8) {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(height: 1)
                                }
                                .padding(.vertical, 12)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                // Part of speech label
                                Text(meaning.partOfSpeech.capitalized)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(accentBlue)
                                    .textCase(.uppercase)
                                    .tracking(0.8)
                                
                                ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { idx, definition in
                                    let defKey = "\(meaning.partOfSpeech):\(idx)"
                                    let isAdded = addedDefinitions.contains(defKey)
                                    let isButtonHovered = hoveredButton == defKey
                                    
                                    HStack(alignment: .top, spacing: 10) {
                                        // Definition number
                                        Text("\(idx + 1)")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(accentBlue.opacity(0.6))
                                            .frame(width: 18, alignment: .trailing)
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(definition.definition)
                                                .font(.system(size: 13.5, weight: .regular))
                                                .lineSpacing(3)
                                                .fixedSize(horizontal: false, vertical: true)
                                            
                                            if let example = definition.example, !example.isEmpty {
                                                Text("\"\(example)\"")
                                                    .font(.system(size: 12, weight: .regular, design: .serif))
                                                    .italic()
                                                    .foregroundColor(.secondary.opacity(0.8))
                                                    .lineSpacing(2)
                                                    .padding(.leading, 4)
                                            }
                                        }
                                        
                                        Spacer(minLength: 4)
                                        
                                        // Add button with hover animation
                                        Button(action: {
                                            _ = withAnimation(.spring(response: 0.3)) {
                                                addedDefinitions.insert(defKey)
                                            }
                                            onAddToJournal(
                                                definition.definition,
                                                meaning.partOfSpeech,
                                                definition.example ?? ""
                                            )
                                        }) {
                                            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                                .foregroundColor(isAdded ? .green : accentBlue)
                                                .font(.system(size: 18))
                                                .scaleEffect(isButtonHovered && !isAdded ? 1.2 : 1.0)
                                                .animation(.spring(response: 0.2), value: isButtonHovered)
                                        }
                                        .buttonStyle(.plain)
                                        .pointingHandCursor()
                                        .onHover { hovered in
                                            hoveredButton = hovered ? defKey : nil
                                        }
                                        .help(isAdded ? "Added to Journal" : "Add this definition to Journal")
                                        .disabled(isAdded)
                                    }
                                    .padding(.vertical, 3)
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 300)
                
                // Source attribution
                if let source = result.sourceUrls?.first {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.1))
                        .frame(height: 1)
                    HStack(spacing: 5) {
                        Image(systemName: "book.closed.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary.opacity(0.45))
                        Text(dictionarySourceLabel(source))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary.opacity(0.45))
                        Spacer()
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.secondary.opacity(0.25), lineWidth: 1.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 28, x: 0, y: 10)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
        .padding(32)  // Outer transparent padding so corners + shadow aren't clipped
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func dictionarySourceLabel(_ source: String) -> String {
        if source == "macOS Dictionary" {
            return "New Oxford American Dictionary"
        } else if source.contains("wiktionary") {
            return "Wiktionary"
        } else if source.contains("dictionaryapi") {
            return "Free Dictionary API"
        } else if source.hasPrefix("http") {
            // Extract domain name
            return URL(string: source)?.host ?? source
        }
        return source
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

