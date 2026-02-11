# Word Journal

A native macOS menu bar application that detects word and phrase selections across all applications, displays definitions in a floating popup, and maintains an editable journal of lookup history with pronunciation support.

## Features

- **System-wide text selection monitoring** using Accessibility API with pasteboard fallback (works in PDF viewers and other apps where AX fails)
- **Two activation methods** (switchable in Preferences):
  - **Shift+Click** — Select text, hold Shift, and click
  - **Double-tap Option (⌥)** — Select text, then quickly press Option twice
- **Dictionary lookup** for words and phrases:
  - Local JSON dictionary (optional)
  - Free Dictionary API (https://api.dictionaryapi.dev)
  - Wiktionary API fallback for phrases and idioms
  - Persistent file-based cache
- **Floating definition popup** that appears near your cursor
- **Pronunciation** — Click the speaker icon for audio (Dictionary API + Google TTS fallback, cached locally)
- **Per-definition add** — Each meaning has its own + button; add only the definitions you want
- **Editable journal** with search, pronunciation buttons, and "Play All"
- **Export to CSV** functionality

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later
- Swift 5.7 or later

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose "macOS" → "App"
   - Product Name: `WordJournal`
   - Interface: SwiftUI
   - Language: Swift
   - Uncheck "Use Core Data" (we're using SQLite directly)

### 2. Add Files to Project

Add all files from the `WordJournal/` directory to your Xcode project, maintaining the folder structure:
- Models/
- Services/
- Views/
- Utilities/
- Resources/

### 3. Configure Info.plist

The `Info.plist` file is already configured with:
- `LSUIElement` set to `YES` (hides app from dock)
- `NSAccessibilityUsageDescription` for accessibility permissions

### 4. Add Dictionary Resource

Ensure `dictionary.json` is added to the app bundle:
1. Select `dictionary.json` in Xcode
2. In the File Inspector, check "WordJournal" under "Target Membership"

### 5. Build and Run

1. Build the project (Cmd+B)
2. Run the app (Cmd+R)
3. Grant accessibility permissions when prompted
4. The app will appear in your menu bar

## Usage

1. **Look up a word or phrase:**
   - Select any text in any application (double-click a word, or drag to select a phrase)
   - **Shift+Click:** Hold Shift and click anywhere
   - **Double-tap Option:** Quickly press Option (⌥) twice
   - A floating popup will appear with the definition(s)

2. **Add to journal:**
   - Click the **+** button next to the definition you want to save
   - You can add multiple meanings of the same word

3. **View journal:**
   - Click the menu bar icon
   - Select "Open Journal"
   - Use the search bar to filter entries
   - Click the speaker icon on any row to hear pronunciation
   - Use "Play All" to pronounce all filtered words in sequence
   - Export to CSV using the "Export to CSV" button

4. **Preferences:**
   - Click the menu bar icon
   - Select "Preferences"
   - Switch between **Shift+Click** and **Double-tap Option** activation
   - View accessibility permission status

## Project Structure

```
WordJournal/
├── WordJournal/
│   ├── WordJournalApp.swift          # Main app entry point, window management
│   ├── Models/
│   │   ├── WordEntry.swift           # Journal entry model
│   │   └── DictionaryResult.swift    # Dictionary & Wiktionary API models
│   ├── Services/
│   │   ├── AccessibilityMonitor.swift    # Text selection (AX + pasteboard)
│   │   ├── DictionaryService.swift       # Lookup (API + Wiktionary + cache)
│   │   └── JournalStorage.swift          # SQLite storage
│   ├── Views/
│   │   ├── DefinitionPopupView.swift     # Definition popup + pronunciation
│   │   ├── JournalView.swift             # Journal table with search, Play All
│   │   ├── MenuBarView.swift             # Menu bar popover
│   │   └── PreferencesView.swift        # Preferences (trigger method, permissions)
│   ├── Utilities/
│   │   ├── TriggerManager.swift          # Shift+Click & Double-tap Option
│   │   └── HotKeyManager.swift           # Optional hotkey support
│   └── Resources/
│       └── dictionary.json              # Local dictionary (optional)
└── README.md
```

## Technical Details

### Accessibility Permissions

The app requires accessibility permissions to read selected text from other applications. Users will be prompted to grant these permissions on first launch.

### Text Selection

- **Accessibility API** — Primary method for reading selected text
- **Pasteboard fallback** — Used when AX fails (e.g., PDF viewers); simulates Cmd+C to copy selection
- **Cached selection** — Background polling updates a cache for faster lookups in AX-supported apps

### Dictionary Service

- **Local dictionary**: Optional JSON file with common words
- **Primary API**: Free Dictionary API (https://api.dictionaryapi.dev)
- **Fallback**: Wiktionary API for phrases and idioms
- **Caching**: In-memory + persistent file cache (`~/Library/Caches/WordJournal/dictionary/`)

### Storage

- Uses SQLite for persistent storage
- Database location: `~/Library/Application Support/WordJournal/journal.db`
- All entries are stored locally

### Activation Triggers

- **Shift+Click**: Global mouse monitor detects left-click with Shift held
- **Double-tap Option**: Global key monitor detects two Option key releases within ~400ms (ignores Option when used as modifier in shortcuts)

## Troubleshooting

### Accessibility Permissions Not Working

1. Go to System Settings → Privacy & Security → Accessibility
2. Ensure "WordJournal" is checked
3. If not listed, add it manually by clicking the "+" button
4. Restart the app after granting permission

### Trigger Not Responding

**Shift+Click:**
- Ensure only Shift is held (no Cmd, Option, or Control)
- Try selecting text first, then Shift+Click

**Double-tap Option:**
- Press Option twice quickly (within ~400ms)
- Do not press other keys between the two Option taps
- Check Preferences to confirm "Double-tap Option" is selected

### No Text Selected in PDF

The app uses a pasteboard fallback for PDF viewers. If lookup shows no text:
- Ensure the word/phrase is actually selected (highlighted)
- Wait a moment after selecting before triggering (the fallback needs time to copy)

### Dictionary Lookup Failing

1. Check internet connection (for API fallback)
2. Verify `dictionary.json` is included in the app bundle (optional)
3. Check Console.app for error messages

## Future Enhancements

- Chinese translation for words and phrases
- Expanded local dictionary
- Word frequency analysis
- Flashcard mode
- Cloud sync
- Multiple language support

## License

Copyright © 2026. All rights reserved.
