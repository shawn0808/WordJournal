//
//  MainWindowView.swift
//  WordJournal
//
//  Main app window with Lookup, Journal, and Settings tabs.
//  Appears in dock; menu bar remains for quick access.
//

import SwiftUI

struct MainWindowView: View {
    let onLookupWord: (String) -> Void
    @EnvironmentObject var journalStorage: JournalStorage
    @ObservedObject var dictionaryService = DictionaryService.shared
    
    @State private var lookupText = ""
    @State private var selectedTab = 0
    
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Lookup tab
            LookupTabView(
                lookupText: $lookupText,
                onLookupWord: { word in
                    lookupText = ""
                    onLookupWord(word)
                },
                journalStorage: journalStorage,
                dictionaryService: dictionaryService
            )
            .tabItem {
                Label("Lookup", systemImage: "magnifyingglass")
            }
            .tag(0)
            
            // Journal tab
            JournalView()
                .environmentObject(journalStorage)
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
                }
                .tag(1)
            
            // Settings tab
            PreferencesView()
                .environmentObject(TriggerManager.shared)
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(2)
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear {
            dictionaryService.refreshRecentLookups()
        }
    }
}

// MARK: - Lookup Tab

private struct LookupTabView: View {
    @Binding var lookupText: String
    let onLookupWord: (String) -> Void
    @ObservedObject var journalStorage: JournalStorage
    @ObservedObject var dictionaryService: DictionaryService
    @ObservedObject var aiConfig = AIConfigStore.shared
    
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    private static let wordsOfTheDay: [(word: String, definition: String, gradient: [Color], icon: String)] = [
        ("Serendipity", "Finding something wonderful by chance", [Color(red: 0.85, green: 0.55, blue: 0.25), Color(red: 0.6, green: 0.35, blue: 0.15)], "sparkles"),
        ("Ephemeral", "Lasting for a very short time", [Color(red: 0.6, green: 0.45, blue: 0.75), Color(red: 0.4, green: 0.25, blue: 0.55)], "leaf.fill"),
        ("Mellifluous", "Sweet and musical to hear", [Color(red: 0.3, green: 0.35, blue: 0.7), Color(red: 0.2, green: 0.15, blue: 0.45)], "music.note"),
        ("Luminescent", "Emitting light without heat", [Color(red: 0.2, green: 0.65, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.6)], "light.max")
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Look up a word")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    HStack(spacing: 6) {
                        Text("\(journalStorage.entries.count)")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 24, minHeight: 24)
                            .background(Circle().fill(accentBlue.opacity(0.8)))
                        Text("words in your journal")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                
                // Word of the Day
                VStack(alignment: .leading, spacing: 12) {
                    Text("Word of the Day")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 24)
                    
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                        ForEach(Self.wordsOfTheDay, id: \.word) { item in
                            WordOfTheDayCard(
                                word: item.word,
                                definition: item.definition,
                                gradient: item.gradient,
                                icon: item.icon,
                                canUseAI: aiConfig.isEnabled && aiConfig.provider == .openAI && (aiConfig.apiKey ?? "").isEmpty == false,
                                apiKey: aiConfig.apiKey,
                                onTap: { onLookupWord(item.word) }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                // Search field
                HStack(spacing: 12) {
                    HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    TextField("Type a word or phrase...", text: $lookupText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 16))
                        .onSubmit {
                            let word = lookupText.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !word.isEmpty else { return }
                            onLookupWord(word)
                        }
                    if !lookupText.isEmpty {
                        Button(action: { lookupText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary.opacity(0.5))
                                .font(.system(size: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .frame(maxWidth: 400)
                
                Button("Look up") {
                    let word = lookupText.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !word.isEmpty else { return }
                    onLookupWord(word)
                }
                .buttonStyle(.borderedProminent)
                .tint(accentBlue)
                .disabled(lookupText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 24)
                
                // Recent lookups
                if !dictionaryService.recentLookups.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent lookups")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 24)
                        
                        FlowLayout(spacing: 8) {
                            ForEach(dictionaryService.recentLookups, id: \.self) { word in
                                Button(action: { onLookupWord(word) }) {
                                    HStack(spacing: 6) {
                                        Text(word)
                                            .font(.system(size: 13))
                                        Button(action: {
                                            dictionaryService.removeFromRecentLookups(word)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary.opacity(0.6))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                                            .fill(accentBlue.opacity(0.12))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                
                Spacer(minLength: 24)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Word of the Day Card (Netflix-style)

private struct WordOfTheDayCard: View {
    let word: String
    let definition: String
    let gradient: [Color]
    let icon: String
    let canUseAI: Bool
    let apiKey: String?
    let onTap: () -> Void
    
    @State private var loadedImage: NSImage?
    @State private var isLoading = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // Background: AI image or gradient fallback
                Group {
                    if let img = loadedImage {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        LinearGradient(
                            colors: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
                .overlay(
                    LinearGradient(
                        colors: [.clear, .black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                // Loading indicator
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tint(.white)
                }
                
                // Decorative icon (Netflix-style hero element)
                if !isLoading {
                    Image(systemName: icon)
                        .font(.system(size: 100, weight: .light))
                        .foregroundColor(.white.opacity(loadedImage != nil ? 0.08 : 0.15))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(24)
                }
                
                // Content overlay
                VStack(alignment: .leading, spacing: 8) {
                    Text(word)
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.4), radius: 2, x: 0, y: 1)
                    Text(definition)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                }
                .padding(24)
            }
            .frame(maxWidth: .infinity, minHeight: 200)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .task(id: "\(word)-\(canUseAI)") {
            await loadImageIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: .wordImageCacheDidClear)) { _ in
            loadedImage = nil
            Task { await loadImageIfNeeded() }
        }
    }
    
    private func loadImageIfNeeded() async {
        // 1. Check cache first
        if let cached = WordImageCache.load(for: word) {
            loadedImage = cached
            return
        }
        
        // 2. Generate via AI if enabled
        guard canUseAI, let key = apiKey, !key.isEmpty else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let data = try await AIImageService.shared.generateImage(for: word, definition: definition, apiKey: key)
            WordImageCache.save(data, for: word)
            if let img = NSImage(data: data) {
                await MainActor.run { loadedImage = img }
            }
        } catch {
            print("WordJournal: AI image generation failed for '\(word)': \(error)")
        }
    }
}

// MARK: - Flow Layout for recent lookups

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        
        let totalHeight = y + rowHeight
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}
