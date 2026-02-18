# Word Journal v2 — Detailed Plan

## Overview

This document expands the v2 feature plan with implementation details: APIs, data models, UI specs, error handling, and edge cases. No code changes until approved.

---

## 1. In-App Update Check

### 1.1 Data Flow

```
App Launch (or timer)
    |
    v
UpdateService.checkForUpdates()
    |
    +---> Fetch https://api.github.com/repos/shawn0808/WordJournal/releases/latest
    |     Headers: Accept: application/vnd.github.v3+json
    |     Response: { tag_name: "v1.1.0", html_url: "...", assets: [...] }
    |
    +---> Parse tag_name (strip "v" prefix) -> "1.1.0"
    |
    +---> Compare with Bundle.main.infoDictionary["CFBundleShortVersionString"] -> "1.0"
    |
    +---> If remote > local: set latestRelease (tag, url, releaseNotes, downloadURL)
    |
    v
UI: Menu bar shows "Update Available" or badge; Preferences shows "Check for Updates"
```

### 1.2 API Contract

**Request:** `GET https://api.github.com/repos/shawn0808/WordJournal/releases/latest`

**Response (relevant fields):**
```json
{
  "tag_name": "v1.1.0",
  "name": "Word Journal v1.1",
  "body": "Release notes...",
  "html_url": "https://github.com/shawn0808/WordJournal/releases/tag/v1.1.0",
  "assets": [
    { "name": "WordJournal.dmg", "browser_download_url": "https://github.com/.../WordJournal.dmg" }
  ]
}
```

**Version comparison:** Use `compare(_:options:)` with `.numeric` for `"1.0"` vs `"1.1.0"`.

### 1.3 UpdateService Spec

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `latestRelease` | `ReleaseInfo?` | Non-nil when update available |
| `lastCheckDate` | `Date?` | Stored in UserDefaults |
| `isChecking` | `Bool` | Loading state |
| `checkForUpdates(force: Bool)` | `void` | If `!force` and lastCheck < 24h, skip. Otherwise fetch. |
| `openDownloadPage()` | `void` | Open `latestRelease?.downloadURL` or `html_url` in browser |

**ReleaseInfo struct:**
- `tagName: String` (e.g. "v1.1.0")
- `version: String` (e.g. "1.1.0")
- `releaseNotes: String?`
- `downloadURL: URL?` — first `.dmg` or `.zip` asset, else `html_url`

### 1.4 UI Spec

**Menu bar:**
- Add "Check for Updates" below "Preferences", above divider
- When update available: show "Update Available (v1.1)" with download icon; tapping opens download URL
- Optional: small dot/badge on menu bar icon when update available

**Preferences (About tab):**
- Replace static "Version 1.0" with: "Version \(currentVersion)" + "Check for Updates" button
- When update available: "Version 1.0 — Update to 1.1 available" + "Download" button
- Show last check time: "Last checked: Never" or "Last checked: 2 hours ago"

### 1.5 Error Handling

| Scenario | Behavior |
|----------|----------|
| Network error | Silent fail; `isChecking = false`; no toast (user may be offline) |
| 404 / invalid JSON | Treat as no update |
| Rate limit (403) | Log; no user-facing error |
| No releases yet | `latestRelease = nil` |

### 1.6 Dependencies

- `Foundation` (URLSession, JSONDecoder)
- No new frameworks

---

## 2. Word Recommendations (Discover)

### 2.1 Data Flow

```
Menu bar opens OR user focuses Discover
    |
    v
RecommendationService.fetchRecommendations()
    |
    +---> Input: recentLookups (5) + journal words (last 10, unique)
    |     Filter to single words (no phrases for Datamuse rel_trg)
    |
    +---> For each seed word (up to 3), request:
    |     GET https://api.datamuse.com/words?rel_trg=<word>&md=d&max=10
    |     Response: [{ "word": "tinnitus", "score": 57312, "defs": [["n", "definition"]] }, ...]
    |
    +---> Merge results, filter out:
    |     - Words already in journal
    |     - Words in recentLookups
    |     - Duplicates
    |     - Empty or invalid strings
    |
    +---> Pick 3 (diversified: try not all from same seed)
    |
    v
Publish recommendations: [String]
```

### 2.2 Datamuse API

**Endpoint:** `https://api.datamuse.com/words?rel_trg=<word>&md=d&max=10`

- `rel_trg`: "triggers" — words strongly associated with the seed word
- `md=d`: include definitions (optional, for future "why" display)
- `max=10`: limit per request

**Response:**
```json
[
  { "word": "tinnitus", "score": 57312, "defs": [["n", "Ringing in the ears."]] },
  ...
]
```

**Rate limit:** 100,000 requests/day, no key. For 3 words × 3 seeds = 9 requests per Discover load — negligible.

### 2.3 RecommendationService Spec

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `recommendations` | `[String]` | Current 3 words |
| `isLoading` | `Bool` | Loading state |
| `fetchRecommendations()` | `async` or callback | Fetch and publish |
| `incrementUsage()` | `void` | Called when user taps a recommendation (PremiumService) |

**Seeds:** Prefer `recentLookups`; if < 3, pad with recent journal words. Skip phrases (Datamuse `rel_trg` works best with single words).

### 2.4 PremiumService (Shared)

| Key (UserDefaults) | Type | Description |
|--------------------|------|-------------|
| `recommendationsUsed` | Int | Count of recommendation taps. Trial = 5. |
| `flashCardSessionsUsed` | Int | Count of flash card sessions. Trial = 5. |
| `isPremium` | Bool | Future: true when license validated |

**Methods:**
- `canUseRecommendations: Bool` → `recommendationsUsed < 5 || isPremium`
- `canUseFlashCards: Bool` → `flashCardSessionsUsed < 5 || isPremium`
- `recordRecommendationUse()`, `recordFlashCardSession()`
- `getPremiumURL() -> URL?` — placeholder; returns nil or future purchase URL

### 2.5 UI Spec (Menu bar — Discover section)

**When `canUseRecommendations`:**
- Section "DISCOVER" below "RECENT"
- Up to 3 rows: word + sparkle icon; tap triggers `onLookupWord(word)` and `recordRecommendationUse()`
- Loading: show "Discovering..." or spinner
- Empty: "No suggestions right now" (e.g. no seeds, or all filtered out)

**When !`canUseRecommendations`:**
- Section "DISCOVER" with lock icon
- "Unlock with Premium — 5 free recommendations used"
- "Get Premium" button → `getPremiumURL()` or in-app paywall placeholder view

### 2.6 Edge Cases

| Case | Handling |
|------|----------|
| No seeds (empty journal + no recent) | Show "Add words to your journal to get recommendations" |
| All results filtered (all in journal) | Show "No new suggestions" |
| Network error | Show "Couldn't load suggestions" with retry |
| Offline | Don't fetch; show "Offline" or hide section |
| Datamuse returns < 3 | Show however many we got |

---

## 3. Flash Card Mode

### 3.1 Data Flow

```
User taps "Flash Cards" in menu bar
    |
    v
showFlashCards() — open FlashCardWindow
    |
    v
FlashCardView
    |
    +---> FlashCardService.buildDeck() from JournalStorage.entries
    |     Shuffle; optionally filter (e.g. last 50, or all)
    |
    +---> Display card: front = word (or definition, user preference)
    |     Tap / click to flip -> back = definition, example, POS
    |
    +---> "Next" -> next card
    |     "Know it" -> skip (optional: remove from session)
    |     "Review again" -> re-add to end of deck (optional)
    |
    +---> Session ends when deck empty or user closes
    |     recordFlashCardSession()
```

### 3.2 FlashCardService Spec

| Property / Method | Type | Description |
|-------------------|------|-------------|
| `deck` | `[WordEntry]` | Current deck (shuffled) |
| `currentIndex` | `Int` | 0-based |
| `buildDeck(from entries: [WordEntry])` | `void` | Shuffle, set deck |
| `currentCard` | `WordEntry?` | `deck[safe: currentIndex]` |
| `nextCard()` | `Bool` | Advance index; return true if more cards |
| `hasMoreCards` | `Bool` | `currentIndex < deck.count - 1` |
| `sessionCount` | `Int` | Incremented when session ends (>= 1 card shown) |

### 3.3 UI Spec (FlashCardView)

**Layout:**
- Window: ~500×400, similar to Preferences
- Card: Rounded rect, 400×250, centered
- Front: word (large, bold)
- Back: definition, part of speech, example (if any)
- Flip: 3D rotation or flip animation on click
- Buttons: "Flip" (or tap card), "Next", "Review again" (optional)
- Progress: "Card 3 of 12"
- Empty state: "No words in journal. Add some to start learning!"

**Paywall:**
- Before showing window: if !`canUseFlashCards`, show modal: "Flash Cards — 5 free sessions used. Get Premium to unlock."
- "Get Premium" / "Maybe Later"

### 3.4 Session Definition

**Trial:** 5 sessions. One session = opening Flash Cards and viewing at least 1 card (flipping counts). Closing after 0 cards does not increment.

### 3.5 Edge Cases

| Case | Handling |
|------|----------|
| Journal empty | Show "Add words to your journal first" |
| Single entry | Show single card; "Next" ends session |
| All definitions empty | Still show word on back; gracefully hide def |

---

## 4. Offline / Network Error Notification

### 4.1 Trigger Logic

**When to show banner:**
- NOT when `NetworkMonitor.isOffline` alone (user may not have tried any feature)
- WHEN a network-dependent operation fails with a network-related error:
  - `URLError.notConnectedToInternet`
  - `URLError.networkConnectionLost`
  - `URLError.timedOut` (could be network)
  - `URLError.dnsLookupFailed`

**Where to hook:**
1. **DictionaryService** `fetchFromAPI` / `fetchFromWiktionary`: in `completion(.failure(error))`, check `error as? URLError`; if network-related, post notification or call shared `OfflineBannerCoordinator.show()`.
2. **PronunciationPlayer** (DefinitionPopupView): on download/TTS failure with network error, same.
3. **RecommendationService**: on fetch failure, same.
4. **UpdateService**: optionally; low priority (user may not care).

### 4.2 OfflineBannerCoordinator

Centralized singleton to avoid duplicate banners:
- `show(message: String)`
- `dismiss()`
- Track `lastShownDate`; if shown in last 60 seconds, don't show again (debounce)
- Post `Notification` or use `@Published`; `AppDelegate` or root view observes and presents overlay

### 4.3 UI Spec

**Banner:**
- Position: Top of screen, below menu bar (or floating over content)
- Content: Icon (wifi.slash) + "No internet — some features may not work. Dictionary lookups use offline mode when possible."
- Style: Same as `OfflineBannerView` (rounded, shadow, dismiss button)
- Auto-dismiss: 4 seconds
- Manual dismiss: X button
- Non-modal: does not block interaction

**Presentation:** Overlay in `WordJournalApp` root view, or in each window. Simpler: single overlay in main menu bar popover host — but popover dismisses. Better: overlay in `JournalWindow` and `PreferencesWindow` and a global overlay for the definition popup (which is a panel). Complexity: use `NSWindow` overlay or SwiftUI `.overlay` on the key window. For simplicity: attach overlay to `journalWindow` and `preferencesWindow` and the panel's hosting view when it's the key window. Alternative: use a single `NSWindow` with `level = .floating` that appears above all app windows when banner is shown.

**Recommendation:** Use `NotificationCenter` to post `OfflineBannerShouldShow`. A single `OfflineBannerWindow` (borderless, small) that `AppDelegate` creates and shows/hides. When notification received, show window at top-center of main screen, auto-hide after 4s.

### 4.4 NetworkMonitor Spec (Implemented)

| Property | Type | Description |
|----------|------|-------------|
| `isPathSatisfied` | `Bool` | `path.status == .satisfied` |
| `isDictionaryReachable` | `Bool` | From probe to dictionary API |
| `isEffectivelyOffline` | `Bool` | `!isPathSatisfied \|\| !isDictionaryReachable` |

Uses `NWPathMonitor` for path status. **Probe:** `GET https://api.dictionaryapi.dev/api/v2/entries/en/test` directly tests dictionary API reachability (Option A). Probe runs on app launch (1s delay) and can be called on-demand.

---

## 5. Implementation Order & File Checklist

### Phase 1: NetworkMonitor + Offline Banner (DONE)
- [x] `Services/NetworkMonitor.swift` — uses NWPathMonitor + probe to `api.dictionaryapi.dev/api/v2/entries/en/test`
- [x] `Views/OfflineBannerView.swift` (reusable view)
- [x] `Services/OfflineBannerCoordinator.swift`
- [x] Hook `DictionaryService` failure handling (API + Wiktionary)
- [x] Hook `PronunciationPlayer` failure handling
- [x] Add `OfflineBannerWindow` (floating) to `WordJournalApp`

### Phase 2: UpdateService
- [ ] `Services/UpdateService.swift`
- [ ] `Models/ReleaseInfo.swift` (or inline)
- [ ] Menu bar: "Check for Updates", "Update Available"
- [ ] Preferences About tab: version + check button

### Phase 3: PremiumService (shared)
- [ ] `Services/PremiumService.swift`

### Phase 4: RecommendationService + Discover
- [ ] `Services/RecommendationService.swift`
- [ ] MenuBarView: Discover section, paywall UI
- [ ] Wire `PremiumService.canUseRecommendations`, `recordRecommendationUse`

### Phase 5: Flash Cards
- [ ] `Services/FlashCardService.swift`
- [ ] `Views/FlashCardView.swift`
- [ ] `WordJournalApp.showFlashCards()`
- [ ] Menu bar: "Flash Cards"
- [ ] Paywall before opening

### Phase 6: Polish
- [ ] Bump `CFBundleShortVersionString` to 1.1, `CFBundleVersion` to 2
- [ ] Add new files to Xcode project (`project.pbxproj`)

---

## 6. Open Questions

1. **Monetization:** Where should "Get Premium" link? (Placeholder URL, Gumroad, Stripe, license key entry?)
2. **Flash card direction:** Word→Definition only, or user choice (Definition→Word)?
3. **Offline banner placement:** Single floating window vs per-window overlay?
4. **Recommendation "why":** Show Datamuse definition on hover/long-press, or keep minimal (word only)?

---

## 7. Testing Scenarios

| Feature | Scenario | Expected |
|---------|----------|----------|
| Update | App 1.0, GitHub has v1.1 | "Update Available" shown |
| Update | App 1.1, GitHub has v1.1 | No update shown |
| Update | Offline during check | Silent fail, no crash |
| Recommendations | 3 seeds, Datamuse returns 5 | 3 shown, not in journal |
| Recommendations | After 5 taps | Paywall |
| Flash Cards | 0 journal entries | Empty state |
| Flash Cards | 5 sessions then open | Paywall |
| Offline | Lookup phrase, API fails (offline) | Banner shown |
| Offline | Lookup word, system dict hits | No banner |
