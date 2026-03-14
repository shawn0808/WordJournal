//
//  MainWindowView.swift
//  WordJournal
//
//  Main app window with Lookup, Journal, and Preferences tabs.
//  Appears in dock; menu bar remains for quick access.
//

import SwiftUI

struct MainWindowView: View {
    @ObservedObject var mainWindowState: MainWindowState
    let onLookupWord: (String) -> Void
    @EnvironmentObject var journalStorage: JournalStorage
    @ObservedObject var dictionaryService = DictionaryService.shared

    @State private var lookupText = ""

    var body: some View {
        TabView(selection: Binding(
            get: { mainWindowState.selectedTab },
            set: { mainWindowState.selectedTab = $0 }
        )) {
            LookupTabView(
                lookupText: $lookupText,
                onLookupWord: { word in
                    lookupText = ""
                    onLookupWord(word)
                },
                journalStorage: journalStorage,
                dictionaryService: dictionaryService
            )
            .tabItem { Label("Lookup", systemImage: "magnifyingglass") }
            .tag(0)

            JournalView()
                .environmentObject(journalStorage)
                .tabItem { Label("Journal", systemImage: "book.fill") }
                .tag(1)

            PreferencesView()
                .environmentObject(TriggerManager.shared)
                .tabItem { Label("Preferences", systemImage: "gearshape") }
                .tag(2)
        }
        .frame(minWidth: 700, minHeight: 500)
        .onAppear { dictionaryService.refreshRecentLookups() }
    }
}

// MARK: - Word pool

private struct DailyWordEntry {
    let word: String
    let definition: String
    let searchTerms: [String]   // tried in order for Wikipedia pageimages
    let gradient: [Color]
    let icon: String
}

// 48-entry pool — 4 new words every day (rotates via day-of-year)
private let wordPool: [DailyWordEntry] = [
    DailyWordEntry(word: "Serendipity",    definition: "Finding something wonderful by chance",
              searchTerms: ["Serendipity", "Luck", "Fortune cookie"],
              gradient: [Color(red:0.85,green:0.55,blue:0.25), Color(red:0.60,green:0.35,blue:0.15)], icon: "sparkles"),
    DailyWordEntry(word: "Ephemeral",      definition: "Lasting for a very short time",
              searchTerms: ["Cherry blossom", "Mayfly", "Soap bubble"],
              gradient: [Color(red:0.60,green:0.45,blue:0.75), Color(red:0.40,green:0.25,blue:0.55)], icon: "leaf.fill"),
    DailyWordEntry(word: "Mellifluous",    definition: "Sweet and musical to hear",
              searchTerms: ["Violin", "Piano", "Orchestra concert"],
              gradient: [Color(red:0.30,green:0.35,blue:0.70), Color(red:0.20,green:0.15,blue:0.45)], icon: "music.note"),
    DailyWordEntry(word: "Luminescent",    definition: "Emitting light without heat",
              searchTerms: ["Bioluminescence", "Aurora borealis", "Firefly"],
              gradient: [Color(red:0.20,green:0.65,blue:0.80), Color(red:0.10,green:0.40,blue:0.60)], icon: "light.max"),
    DailyWordEntry(word: "Solitude",       definition: "The state of being alone peacefully",
              searchTerms: ["Solitude mountain", "Forest path", "Empty beach"],
              gradient: [Color(red:0.25,green:0.45,blue:0.35), Color(red:0.15,green:0.30,blue:0.25)], icon: "person"),
    DailyWordEntry(word: "Wanderlust",     definition: "Strong desire to travel and explore",
              searchTerms: ["Backpacking", "Adventure travel", "Mountain road"],
              gradient: [Color(red:0.75,green:0.45,blue:0.20), Color(red:0.50,green:0.30,blue:0.10)], icon: "map.fill"),
    DailyWordEntry(word: "Resilience",     definition: "The ability to bounce back from hardship",
              searchTerms: ["Oak tree", "Lighthouse storm", "Gymnast"],
              gradient: [Color(red:0.65,green:0.30,blue:0.30), Color(red:0.45,green:0.15,blue:0.15)], icon: "flame.fill"),
    DailyWordEntry(word: "Tranquil",       definition: "Free from disturbance; calm and peaceful",
              searchTerms: ["Zen garden", "Calm lake", "Misty morning"],
              gradient: [Color(red:0.30,green:0.55,blue:0.65), Color(red:0.20,green:0.35,blue:0.50)], icon: "wind"),
    DailyWordEntry(word: "Eloquent",       definition: "Fluent and persuasive in speaking",
              searchTerms: ["Public speaking", "Debate", "Rhetoric"],
              gradient: [Color(red:0.50,green:0.35,blue:0.65), Color(red:0.30,green:0.20,blue:0.45)], icon: "text.bubble"),
    DailyWordEntry(word: "Luminous",       definition: "Full of or shedding light; radiant",
              searchTerms: ["Golden hour photography", "Sunrise", "Sunbeam forest"],
              gradient: [Color(red:0.90,green:0.70,blue:0.20), Color(red:0.70,green:0.45,blue:0.10)], icon: "sun.max.fill"),
    DailyWordEntry(word: "Nostalgia",      definition: "Sentimental longing for the past",
              searchTerms: ["Vintage photograph", "Old town", "Retro"],
              gradient: [Color(red:0.70,green:0.55,blue:0.40), Color(red:0.50,green:0.35,blue:0.25)], icon: "clock"),
    DailyWordEntry(word: "Euphoria",       definition: "An intense feeling of happiness",
              searchTerms: ["Fireworks", "Carnival", "Celebration"],
              gradient: [Color(red:0.85,green:0.40,blue:0.55), Color(red:0.60,green:0.20,blue:0.35)], icon: "heart.fill"),
    DailyWordEntry(word: "Zenith",         definition: "The highest point; the peak",
              searchTerms: ["Mount Everest", "Mountain summit", "Alpine peak"],
              gradient: [Color(red:0.30,green:0.50,blue:0.70), Color(red:0.15,green:0.30,blue:0.50)], icon: "arrow.up"),
    DailyWordEntry(word: "Cascade",        definition: "A waterfall, or a succession of things",
              searchTerms: ["Waterfall", "Niagara Falls", "Mountain stream"],
              gradient: [Color(red:0.20,green:0.60,blue:0.70), Color(red:0.10,green:0.40,blue:0.55)], icon: "drop.fill"),
    DailyWordEntry(word: "Stoic",          definition: "Enduring pain without showing feelings",
              searchTerms: ["Marble sculpture", "Stoicism", "Ancient Rome"],
              gradient: [Color(red:0.50,green:0.50,blue:0.50), Color(red:0.30,green:0.30,blue:0.30)], icon: "shield.fill"),
    DailyWordEntry(word: "Vivid",          definition: "Producing powerful feelings; intensely bright",
              searchTerms: ["Rainbow", "Color photography", "Tropical bird"],
              gradient: [Color(red:0.80,green:0.30,blue:0.30), Color(red:0.50,green:0.10,blue:0.10)], icon: "paintbrush.fill"),
    DailyWordEntry(word: "Gossamer",       definition: "Light, delicate, or insubstantial",
              searchTerms: ["Spider web dew", "Silk fabric", "Morning dew"],
              gradient: [Color(red:0.70,green:0.75,blue:0.85), Color(red:0.50,green:0.55,blue:0.65)], icon: "cloud"),
    DailyWordEntry(word: "Labyrinth",      definition: "A complicated network of passages",
              searchTerms: ["Maze", "Labyrinth", "Knossos"],
              gradient: [Color(red:0.55,green:0.40,blue:0.30), Color(red:0.35,green:0.25,blue:0.20)], icon: "square.grid.3x3"),
    DailyWordEntry(word: "Momentum",       definition: "The force that keeps something moving forward",
              searchTerms: ["Bicycle racing", "Sprint athletics", "Skateboarding"],
              gradient: [Color(red:0.30,green:0.55,blue:0.35), Color(red:0.15,green:0.35,blue:0.20)], icon: "arrow.forward"),
    DailyWordEntry(word: "Reverie",        definition: "A state of pleasant daydreaming",
              searchTerms: ["Cloud landscape", "Meadow flowers", "Dreamy forest"],
              gradient: [Color(red:0.65,green:0.60,blue:0.80), Color(red:0.45,green:0.40,blue:0.60)], icon: "moon.stars"),
    DailyWordEntry(word: "Opulent",        definition: "Ostentatiously rich and luxurious",
              searchTerms: ["Palace of Versailles", "Luxury interior", "Gold architecture"],
              gradient: [Color(red:0.70,green:0.60,blue:0.20), Color(red:0.50,green:0.40,blue:0.10)], icon: "crown.fill"),
    DailyWordEntry(word: "Verdant",        definition: "Green with rich vegetation",
              searchTerms: ["Irish countryside", "Green meadow", "Rainforest"],
              gradient: [Color(red:0.25,green:0.60,blue:0.30), Color(red:0.15,green:0.40,blue:0.20)], icon: "leaf"),
    DailyWordEntry(word: "Enigma",         definition: "A mysterious and puzzling person or thing",
              searchTerms: ["Sphinx", "Enigma machine", "Mystery"],
              gradient: [Color(red:0.40,green:0.30,blue:0.50), Color(red:0.25,green:0.20,blue:0.35)], icon: "questionmark"),
    DailyWordEntry(word: "Kinetic",        definition: "Relating to motion; lively and active",
              searchTerms: ["Dance motion blur", "Athletics sprinting", "Skateboarding"],
              gradient: [Color(red:0.80,green:0.50,blue:0.20), Color(red:0.55,green:0.30,blue:0.10)], icon: "bolt.fill"),
    DailyWordEntry(word: "Serene",         definition: "Calm, peaceful, and untroubled",
              searchTerms: ["Reflection lake", "Calm water", "Morning mist lake"],
              gradient: [Color(red:0.35,green:0.60,blue:0.70), Color(red:0.20,green:0.40,blue:0.50)], icon: "water.waves"),
    DailyWordEntry(word: "Flourish",       definition: "To grow or develop in a healthy way",
              searchTerms: ["Flower garden", "Bloom", "Spring flowers"],
              gradient: [Color(red:0.60,green:0.75,blue:0.40), Color(red:0.40,green:0.55,blue:0.25)], icon: "leaf.fill"),
    DailyWordEntry(word: "Tenacious",      definition: "Holding firmly; not giving up easily",
              searchTerms: ["Rock climbing", "Mountain climbing", "Obstacle course"],
              gradient: [Color(red:0.65,green:0.35,blue:0.25), Color(red:0.45,green:0.20,blue:0.15)], icon: "hand.raised.fill"),
    DailyWordEntry(word: "Iridescent",     definition: "Showing rainbow-like colors that shift with angle",
              searchTerms: ["Peacock feather", "Soap bubble", "Hummingbird"],
              gradient: [Color(red:0.50,green:0.70,blue:0.90), Color(red:0.70,green:0.40,blue:0.80)], icon: "rainbow"),
    DailyWordEntry(word: "Jubilant",       definition: "Feeling or expressing great happiness",
              searchTerms: ["Carnival Brazil", "Festival", "Fireworks celebration"],
              gradient: [Color(red:0.90,green:0.60,blue:0.20), Color(red:0.70,green:0.40,blue:0.10)], icon: "star.fill"),
    DailyWordEntry(word: "Melancholy",     definition: "A feeling of pensive sadness",
              searchTerms: ["Autumn foggy", "Rain window", "Misty forest"],
              gradient: [Color(red:0.40,green:0.45,blue:0.55), Color(red:0.25,green:0.30,blue:0.40)], icon: "cloud.rain"),
    DailyWordEntry(word: "Ethereal",       definition: "Extremely delicate and light; heavenly",
              searchTerms: ["Aurora borealis", "Fog forest", "Angel Falls"],
              gradient: [Color(red:0.70,green:0.80,blue:0.90), Color(red:0.50,green:0.60,blue:0.75)], icon: "cloud"),
    DailyWordEntry(word: "Catharsis",      definition: "The release of emotions bringing relief",
              searchTerms: ["Ocean waves", "Thunderstorm", "Waterfall"],
              gradient: [Color(red:0.30,green:0.40,blue:0.60), Color(red:0.20,green:0.25,blue:0.45)], icon: "drop"),
    DailyWordEntry(word: "Sanguine",       definition: "Optimistic, especially in difficulty",
              searchTerms: ["Sunrise landscape", "Spring flowers", "Rainbow after rain"],
              gradient: [Color(red:0.85,green:0.45,blue:0.30), Color(red:0.65,green:0.25,blue:0.20)], icon: "sun.horizon"),
    DailyWordEntry(word: "Quixotic",       definition: "Unrealistically idealistic; romantically impractical",
              searchTerms: ["Don Quixote", "Windmill", "Knight armor"],
              gradient: [Color(red:0.55,green:0.45,blue:0.70), Color(red:0.35,green:0.25,blue:0.50)], icon: "shield"),
    DailyWordEntry(word: "Pensive",        definition: "Engaged in deep or serious thought",
              searchTerms: ["The Thinker", "Library reading", "Contemplation"],
              gradient: [Color(red:0.45,green:0.50,blue:0.55), Color(red:0.30,green:0.35,blue:0.40)], icon: "ellipsis.bubble"),
    DailyWordEntry(word: "Halcyon",        definition: "A period of happiness and prosperity",
              searchTerms: ["Summer blue sky", "Greek island", "Aegean sea"],
              gradient: [Color(red:0.40,green:0.70,blue:0.85), Color(red:0.25,green:0.50,blue:0.65)], icon: "sun.max"),
    DailyWordEntry(word: "Magnanimous",    definition: "Very generous or forgiving; noble-minded",
              searchTerms: ["Gift giving", "Eagle soaring", "Helping hand"],
              gradient: [Color(red:0.60,green:0.50,blue:0.30), Color(red:0.40,green:0.30,blue:0.15)], icon: "gift.fill"),
    DailyWordEntry(word: "Fortitude",      definition: "Courage in pain or adversity",
              searchTerms: ["Lighthouse storm", "Rocky coast waves", "Cliff"],
              gradient: [Color(red:0.50,green:0.45,blue:0.35), Color(red:0.35,green:0.30,blue:0.20)], icon: "flame"),
    DailyWordEntry(word: "Petrichor",      definition: "The pleasant smell of rain on dry earth",
              searchTerms: ["Rain puddle", "Raindrop leaf", "Wet cobblestones"],
              gradient: [Color(red:0.35,green:0.50,blue:0.40), Color(red:0.20,green:0.35,blue:0.30)], icon: "cloud.rain.fill"),
    DailyWordEntry(word: "Sonder",         definition: "Realizing strangers each have vivid inner lives",
              searchTerms: ["Crowd city", "Street photography", "Busy street"],
              gradient: [Color(red:0.40,green:0.40,blue:0.50), Color(red:0.25,green:0.25,blue:0.35)], icon: "person.3.fill"),
    DailyWordEntry(word: "Hiraeth",        definition: "Welsh longing for home or a lost past",
              searchTerms: ["Wales countryside", "Rolling hills", "Country road"],
              gradient: [Color(red:0.35,green:0.50,blue:0.45), Color(red:0.20,green:0.35,blue:0.30)], icon: "house.fill"),
    DailyWordEntry(word: "Limerence",      definition: "The state of involuntary romantic obsession",
              searchTerms: ["Red roses", "Heart flowers", "Romance"],
              gradient: [Color(red:0.80,green:0.30,blue:0.40), Color(red:0.60,green:0.15,blue:0.25)], icon: "heart"),
    DailyWordEntry(word: "Effulgent",      definition: "Radiant; shining brilliantly",
              searchTerms: ["Sunburst rays", "Cathedral light", "Golden light forest"],
              gradient: [Color(red:0.90,green:0.75,blue:0.30), Color(red:0.70,green:0.55,blue:0.15)], icon: "sun.max.fill"),
    DailyWordEntry(word: "Lissome",        definition: "Thin, supple, and graceful",
              searchTerms: ["Ballet dancer", "Gymnastics", "Contemporary dance"],
              gradient: [Color(red:0.70,green:0.60,blue:0.75), Color(red:0.50,green:0.40,blue:0.55)], icon: "figure.walk"),
    DailyWordEntry(word: "Mercurial",      definition: "Subject to sudden or unpredictable changes",
              searchTerms: ["Lightning storm", "Thunderstorm", "Weather"],
              gradient: [Color(red:0.50,green:0.60,blue:0.70), Color(red:0.30,green:0.40,blue:0.55)], icon: "bolt.fill"),
    DailyWordEntry(word: "Penumbra",       definition: "The partial shadow between full light and darkness",
              searchTerms: ["Solar eclipse", "Lunar eclipse", "Shadow"],
              gradient: [Color(red:0.25,green:0.20,blue:0.35), Color(red:0.15,green:0.10,blue:0.25)], icon: "circle.lefthalf.filled"),
    DailyWordEntry(word: "Susurrus",       definition: "A whispering or murmuring sound",
              searchTerms: ["Forest leaves wind", "Wheat field", "Grass breeze"],
              gradient: [Color(red:0.30,green:0.50,blue:0.40), Color(red:0.20,green:0.35,blue:0.25)], icon: "wind"),
    DailyWordEntry(word: "Verisimilitude", definition: "The appearance of being true or real",
              searchTerms: ["Theater stage", "Cinema film", "Illusion art"],
              gradient: [Color(red:0.45,green:0.35,blue:0.55), Color(red:0.30,green:0.20,blue:0.40)], icon: "theatermasks.fill"),
]

private func todaysWords() -> [DailyWordEntry] {
    let day = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
    let start = ((day - 1) * 4) % wordPool.count
    return (0..<4).map { wordPool[(start + $0) % wordPool.count] }
}

// MARK: - Lookup Tab

private struct LookupTabView: View {
    @Binding var lookupText: String
    let onLookupWord: (String) -> Void
    @ObservedObject var journalStorage: JournalStorage
    @ObservedObject var dictionaryService: DictionaryService

    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    private let entries = todaysWords()

    private let cardGap: CGFloat = 14

    private func performLookup(_ word: String) {
        let w = word.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !w.isEmpty else { return }
        lookupText = ""
        AppDelegate.shared?.lookupWord(w)
    }

    var body: some View {
        VStack(spacing: 0) {
            // ── Search bar at top ─────────────────────────────────
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                    TextField("Look up a word or phrase...", text: $lookupText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 15))
                        .onSubmit { performLookup(lookupText) }
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
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(NSColor.textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .frame(maxWidth: 400)

                Button("Look up") { performLookup(lookupText) }
                .buttonStyle(.borderedProminent)
                .tint(accentBlue)
                .disabled(lookupText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()

                HStack(spacing: 6) {
                    Text("\(journalStorage.entries.count)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(minWidth: 22, minHeight: 22)
                        .background(Circle().fill(accentBlue.opacity(0.85)))
                    Text("in journal")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // ── Recent lookups (compact) ──────────────────────────
            if !dictionaryService.recentLookups.isEmpty {
                HStack(spacing: 6) {
                    Text("Recent:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                    ForEach(dictionaryService.recentLookups, id: \.self) { word in
                        HStack(spacing: 4) {
                            Text(word)
                                .font(.system(size: 12))
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary.opacity(0.5))
                                .onTapGesture { dictionaryService.removeFromRecentLookups(word) }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(accentBlue.opacity(0.1)))
                        .contentShape(Rectangle())
                        .onTapGesture { performLookup(word) }
                        .pointingHandCursor()
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color(NSColor.windowBackgroundColor))
                Divider()
            }

            // ── Words of the Day: 4 cards fill remaining space ──────
            VStack(alignment: .leading, spacing: 12) {
                Text("Words of the Day")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)

            GeometryReader { geo in
                let pad: CGFloat = 20
                let w = geo.size.width - pad * 2 - cardGap
                let h = geo.size.height - pad * 2 - cardGap
                let cardW = max(120, w / 2)
                let cardH = max(80, h / 2)

                VStack(spacing: cardGap) {
                    HStack(spacing: cardGap) {
                        WordOfTheDayCard(entry: entries[0], width: cardW, height: cardH, onTap: { performLookup(entries[0].word) })
                        WordOfTheDayCard(entry: entries[1], width: cardW, height: cardH, onTap: { performLookup(entries[1].word) })
                    }
                    HStack(spacing: cardGap) {
                        WordOfTheDayCard(entry: entries[2], width: cardW, height: cardH, onTap: { performLookup(entries[2].word) })
                        WordOfTheDayCard(entry: entries[3], width: cardW, height: cardH, onTap: { performLookup(entries[3].word) })
                    }
                }
                .padding(20)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Word of the Day Card

private struct WordOfTheDayCard: View {
    let entry: DailyWordEntry
    let width: CGFloat
    let height: CGFloat
    let onTap: () -> Void

    @State private var loadedImage: NSImage?
    @State private var isLoading = false

    var body: some View {
        Button(action: onTap) {
            ZStack(alignment: .bottomLeading) {
                // ── Background ──────────────────────────────────
                if let img = loadedImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                } else {
                    LinearGradient(
                        colors: entry.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }

                // ── Dark scrim so text is always readable ────────
                LinearGradient(
                    colors: [.clear, .black.opacity(0.75)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // ── Faint decorative icon (top-right) ────────────
                Image(systemName: entry.icon)
                    .font(.system(size: min(100, width * 0.22), weight: .ultraLight))
                    .foregroundColor(.white.opacity(loadedImage != nil ? 0.07 : 0.14))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(18)

                // ── Loading spinner ──────────────────────────────
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }

                // ── Word + definition text at bottom ─────────────
                VStack(alignment: .leading, spacing: 5) {
                    Text(entry.word)
                        .font(.system(size: min(26, max(18, width * 0.065)), weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.6), radius: 3, x: 0, y: 1)
                        .lineLimit(1)
                    Text(entry.definition)
                        .font(.system(size: min(14, max(11, width * 0.038)), weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .shadow(color: .black.opacity(0.5), radius: 2, x: 0, y: 1)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 14)
            }
            .frame(width: width, height: height)
            .clipped()
        }
        .buttonStyle(.plain)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        .task(id: entry.word) { await loadImage() }
        .onReceive(NotificationCenter.default.publisher(for: .wordImageCacheDidClear)) { _ in
            loadedImage = nil
            Task { await loadImage() }
        }
    }

    private func loadImage() async {
        if let cached = WordImageCache.load(for: entry.word) {
            loadedImage = cached
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let data = try await UnsplashImageService.shared.fetchImage(for: entry.searchTerms)
            WordImageCache.save(data, for: entry.word)
            if let img = NSImage(data: data) {
                await MainActor.run { loadedImage = img }
            }
        } catch {
            print("WordJournal: image fetch failed for '\(entry.word)': \(error)")
        }
    }
}

// MARK: - Flow Layout for recent lookups

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (i, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[i].x,
                                     y: bounds.minY + result.positions[i].y),
                          proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += rowH + spacing; rowH = 0 }
            positions.append(CGPoint(x: x, y: y))
            rowH = max(rowH, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowH), positions)
    }
}
