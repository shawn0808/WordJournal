//
//  DefinitionPopupView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

// MARK: - Content height preference (for NOAD section sizing)

private struct ContentHeightKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        value = max(value, next)
    }
}

// MARK: - Pointing Hand Cursor

extension View {
    func pointingHandCursor() -> some View {
        self.onContinuousHover { phase in
            switch phase {
            case .active:
                NSCursor.pointingHand.set()
            case .ended:
                NSCursor.arrow.set()
            }
        }
    }
}

struct DefinitionPopupView: View {
    let word: String
    let result: DictionaryResult?
    let isLoading: Bool
    let onAddToJournal: (String, String, String) -> Void  // (definition, partOfSpeech, example)
    var onAddAIInsightToJournal: ((String, String, String, String) -> Void)? = nil  // (definition, partOfSpeech, example, notes)
    let onDismiss: () -> Void
    var onAIInsightLoaded: (() -> Void)? = nil
    
    @State private var isHovered = false
    @State private var addedDefinitions: Set<String> = []  // Track which definitions have been added
    @State private var aiInsightAdded = false
    @State private var hoveredButton: String? = nil  // Track hovered + button for animation
    @StateObject private var audioPlayer = PronunciationPlayer()
    @ObservedObject private var aiConfig = AIConfigStore.shared
    
    @State private var aiInsight: AIWordInsight?
    @State private var aiLoading = false
    @State private var aiError: String?
    @State private var noadContentHeight: CGFloat = 280
    
    // Accent color for consistent theming
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)  // #5B8FB9-ish
    // Align NOAD and AI body text: number column + spacing
    private let bodyLeadingOffset: CGFloat = 18 + 10  // NOAD number width + HStack spacing
    private let bodyFontSize: CGFloat = 13.5
    private let bodyLineSpacing: CGFloat = 3
    private let exampleFontSize: CGFloat = 13
    
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
                VStack(alignment: .leading, spacing: 0) {
                    // ScrollView: NOAD + source only — AI insights stay visible below; height shrinks when content is short
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 0) {
                            // Meanings (NOAD) — fixedSize so we measure actual content height, not ScrollView's offered space
                            ForEach(Array(result.meanings.enumerated()), id: \.offset) { meaningIdx, meaning in
                                if meaningIdx > 0 {
                                    Rectangle()
                                        .fill(Color.secondary.opacity(0.15))
                                        .frame(height: 1)
                                        .padding(.vertical, 12)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
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
                                        Text("\(idx + 1)")
                                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                                            .foregroundColor(accentBlue.opacity(0.6))
                                            .frame(width: 18, alignment: .trailing)
                                        
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(definition.definition)
                                                .font(.system(size: bodyFontSize, weight: .regular))
                                                .lineSpacing(bodyLineSpacing)
                                                .fixedSize(horizontal: false, vertical: true)
                                                .textSelection(.enabled)
                                            
                                            if let example = definition.example, !example.isEmpty {
                                                Text("\"\(example)\"")
                                                    .font(.system(size: exampleFontSize, weight: .regular, design: .serif))
                                                    .italic()
                                                    .foregroundColor(.primary.opacity(0.85))
                                                    .lineSpacing(2)
                                                    .padding(.leading, 4)
                                                    .textSelection(.enabled)
                                            }
                                        }
                                        
                                        Spacer(minLength: 4)
                                        
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                _ = addedDefinitions.insert(defKey)
                                            }
                                            onAddToJournal(
                                                definition.definition,
                                                meaning.partOfSpeech,
                                                definition.example ?? ""
                                            )
                                        }) {
                                            Image(systemName: isAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                                                .foregroundColor(isAdded ? .green : (isButtonHovered ? accentBlue : accentBlue.opacity(0.6)))
                                                .font(.system(size: isButtonHovered && !isAdded ? 20 : 18))
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
                        
                        // Source attribution (NOAD / dictionary)
                        if let source = result.sourceUrls?.first {
                            Rectangle()
                                .fill(Color.secondary.opacity(0.1))
                                .frame(height: 1)
                                .padding(.top, 8)
                            HStack(spacing: 5) {
                                Image(systemName: "book.closed.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary.opacity(0.45))
                                Text(dictionarySourceLabel(source))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.secondary.opacity(0.45))
                                Spacer()
                            }
                            .padding(.top, 6)
                        }
                        }
                        .fixedSize(horizontal: false, vertical: true)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: ContentHeightKey.self, value: geo.size.height)
                            }
                        )
                    }
                    .onPreferenceChange(ContentHeightKey.self) { h in
                        if h > 0 { noadContentHeight = min(h, 280) }
                    }
                    .frame(height: min(noadContentHeight, 280))
                    .onChange(of: word, perform: { _ in noadContentHeight = 280 })
                    
                    // AI Insights — always visible below NOAD, no scrolling needed
                    if aiConfig.hasValidConfig {
                        aiInsightsSection(result: result)
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
        .task(id: "\(word)-\(result != nil)") {
            await fetchAIInsightIfNeeded()
        }
        .onChange(of: aiLoading) { isNowLoading in
            if !isNowLoading, aiInsight != nil {
                onAIInsightLoaded?()
            }
        }
    }
    
    @ViewBuilder
    private func aiInsightsSection(result: DictionaryResult) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Section label — "AI Insights" with same icon as Preferences
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14))
                    .foregroundColor(accentBlue)
                Text("AI Insights")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(accentBlue)
            }
            .padding(.top, 10)
            
            if aiLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Loading AI insights...")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            } else if let insight = aiInsight {
                aiInsightContent(insight: insight)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity
                    ))
            } else if let error = aiError {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                        .frame(width: 18, alignment: .trailing)
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .animation(.easeOut(duration: 0.35), value: aiInsight != nil)
    }
    
    @ViewBuilder
    private func aiInsightContent(insight: AIWordInsight) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Part of speech (like NOAD: full width)
            if let pos = insight.partOfSpeech, !pos.isEmpty {
                Text(pos.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(accentBlue)
                    .tracking(0.8)
                    .padding(.bottom, 6)
            }
            // Body content: same leading offset as NOAD definition text (number column + spacing)
            VStack(alignment: .leading, spacing: 0) {
            // Plain explanation — same font as NOAD
            HStack(alignment: .top, spacing: 10) {
                Text(insight.plainExplanation)
                    .font(.system(size: bodyFontSize, weight: .regular))
                    .lineSpacing(bodyLineSpacing)
                    .fixedSize(horizontal: false, vertical: true)
                    .textSelection(.enabled)
                Spacer(minLength: 4)
                if let addAI = onAddAIInsightToJournal {
                    Button(action: {
                        withAnimation(.spring(response: 0.3)) {
                            aiInsightAdded = true
                        }
                        let notes = buildAIInsightNotes(insight: insight)
                        addAI(insight.plainExplanation, insight.partOfSpeech ?? "", insight.exampleSentence ?? "", notes)
                    }) {
                        Image(systemName: aiInsightAdded ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundColor(aiInsightAdded ? .green : (hoveredButton == "aiInsight" ? accentBlue : accentBlue.opacity(0.6)))
                            .font(.system(size: hoveredButton == "aiInsight" && !aiInsightAdded ? 20 : 18))
                    }
                    .buttonStyle(.plain)
                    .pointingHandCursor()
                    .onHover { hovered in
                        hoveredButton = hovered ? "aiInsight" : nil
                    }
                    .help(aiInsightAdded ? "Added to Journal" : "Add AI insight to Journal")
                    .disabled(aiInsightAdded)
                }
            }
            .padding(.vertical, 3)
            
            if let example = insight.exampleSentence, !example.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Example")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(accentBlue)
                        Text(example)
                            .font(.system(size: exampleFontSize, weight: .regular, design: .serif))
                            .italic()
                            .foregroundColor(.primary.opacity(0.85))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 4)
                }
                .padding(.vertical, 3)
            }
            if !insight.synonyms.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Synonyms")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(accentBlue)
                        Text(insight.synonyms.joined(separator: ", "))
                            .font(.system(size: bodyFontSize, weight: .regular))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 4)
                }
                .padding(.vertical, 3)
            }
            if !insight.antonyms.isEmpty {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Antonyms")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(accentBlue)
                        Text(insight.antonyms.joined(separator: ", "))
                            .font(.system(size: bodyFontSize, weight: .regular))
                            .foregroundColor(.primary)
                            .textSelection(.enabled)
                    }
                    Spacer(minLength: 4)
                }
                .padding(.vertical, 3)
            }
            
            // Source attribution (same format as NOAD)
            Rectangle()
                .fill(Color.secondary.opacity(0.1))
                .frame(height: 1)
                .padding(.top, 8)
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.45))
                Text(aiConfig.provider.displayName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary.opacity(0.45))
                Spacer()
            }
            .padding(.top, 6)
            }
            .padding(.leading, bodyLeadingOffset)
        }
        .padding(.top, 8)
    }
    
    private func buildAIInsightNotes(insight: AIWordInsight) -> String {
        var parts: [String] = []
        if !insight.synonyms.isEmpty {
            parts.append("Synonyms: \(insight.synonyms.joined(separator: ", "))")
        }
        if !insight.antonyms.isEmpty {
            parts.append("Antonyms: \(insight.antonyms.joined(separator: ", "))")
        }
        return parts.joined(separator: ". ")
    }
    
    private func fetchAIInsightIfNeeded() async {
        guard let result = result,
              aiConfig.hasValidConfig else {
            await MainActor.run {
                aiInsight = nil
                aiLoading = false
                aiError = nil
            }
            return
        }
        
        // Check cache first — avoid re-fetching
        if let cached = AIInsightCache.load(for: word) {
            await MainActor.run {
                aiInsight = cached
                aiLoading = false
                aiError = nil
            }
            return
        }
        
        guard let apiKey = aiConfig.apiKey else {
            await MainActor.run {
                aiInsight = nil
                aiLoading = false
                aiError = nil
            }
            return
        }
        
        await MainActor.run {
            aiLoading = true
            aiInsight = nil
            aiError = nil
        }
        
        let definitions = result.meanings.flatMap { $0.definitions.map { $0.definition } }
        
        do {
            let insight = try await AIInsightService.shared.fetchInsight(
                word: word,
                existingDefinitions: definitions,
                provider: aiConfig.provider,
                apiKey: apiKey
            )
            AIInsightCache.save(insight, for: word)
            await MainActor.run {
                aiInsight = insight
                aiLoading = false
                aiError = nil
            }
        } catch {
            let message: String
            if let aiError = error as? AIInsightError {
                message = aiError.errorDescription ?? aiError.localizedDescription
            } else if (error as NSError).domain == NSURLErrorDomain {
                message = "Check your internet connection."
            } else {
                message = error.localizedDescription
            }
            await MainActor.run {
                aiInsight = nil
                aiLoading = false
                aiError = message
            }
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
                // Fallback: show banner if we're effectively offline (e.g. probe detected firewall)
                if NetworkMonitor.shared.isEffectivelyOffline {
                    DispatchQueue.main.async {
                        OfflineBannerCoordinator.shared.show(message: "No internet — pronunciation may not work.")
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
    }
    
    /// Play a word synchronously (for Play All). Tries cache first, then downloads.
    /// Returns true if audio was played successfully.
    func playWordSync(word: String, audioURL: URL?) -> Bool {
        // Try cache first
        let cached = cacheURL(for: word)
        if FileManager.default.fileExists(atPath: cached.path) {
            if playFile(at: cached) { return true }
        }
        // Try download — same URLs as pronounce()
        var urlsToTry: [URL] = []
        if let url = audioURL { urlsToTry.append(url) }
        let encoded = word.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? word
        if let googleURL = URL(string: "https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=en&q=\(encoded)") {
            urlsToTry.append(googleURL)
        }
        for url in urlsToTry {
            if downloadAndPlay(url: url, cacheAs: word) { return true }
        }
        if NetworkMonitor.shared.isEffectivelyOffline {
            DispatchQueue.main.async {
                OfflineBannerCoordinator.shared.show(message: "No internet — pronunciation may not work.")
            }
        }
        return false
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
        var shouldShowBanner = false
        
        var request = URLRequest(url: url)
        request.timeoutInterval = 2
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("PronunciationPlayer: Download error: \(error.localizedDescription)")
                if NetworkMonitor.isNetworkError(error) {
                    shouldShowBanner = true
                }
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("PronunciationPlayer: HTTP \(httpResponse.statusCode)")
                // 403/502/503 often indicate blocked or unavailable service
                if [403, 502, 503].contains(httpResponse.statusCode) {
                    shouldShowBanner = true
                }
            } else {
                audioData = data
            }
            if shouldShowBanner {
                DispatchQueue.main.async {
                    OfflineBannerCoordinator.shared.show(message: "No internet — pronunciation may not work.")
                }
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

