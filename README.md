# Word Journal

A native macOS menu bar application that detects word selections across all applications, displays definitions in a floating popup, and maintains an editable spreadsheet-like journal of lookup history.

## Features

- **System-wide text selection monitoring** using Accessibility API
- **Keyboard shortcut activation** (Cmd+Control+L by default)
- **Dictionary lookup** with local JSON dictionary and API fallback
- **Floating definition popup** that appears near your cursor
- **Editable journal** with spreadsheet-like interface
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

1. **Look up a word:**
   - Select any text in any application
   - Press `Cmd+Control+L` (or your custom shortcut)
   - A floating popup will appear with the definition

2. **Add to journal:**
   - Click "Add to Journal" in the definition popup
   - The word will be saved to your journal

3. **View journal:**
   - Click the menu bar icon
   - Select "Open Journal"
   - Edit entries by double-clicking cells
   - Export to CSV using the "Export CSV" button

4. **Preferences:**
   - Click the menu bar icon
   - Select "Preferences"
   - View accessibility permission status
   - Configure keyboard shortcut (coming soon)

## Project Structure

```
WordJournal/
├── WordJournal/
│   ├── WordJournalApp.swift          # Main app entry point
│   ├── Models/
│   │   ├── WordEntry.swift           # Journal entry model
│   │   └── DictionaryResult.swift    # Dictionary API response model
│   ├── Services/
│   │   ├── AccessibilityMonitor.swift    # Text selection monitoring
│   │   ├── DictionaryService.swift       # Dictionary lookup service
│   │   └── JournalStorage.swift          # SQLite storage service
│   ├── Views/
│   │   ├── DefinitionPopupView.swift     # Floating definition popup
│   │   ├── JournalView.swift             # Spreadsheet-like journal UI
│   │   ├── MenuBarView.swift             # Menu bar popover
│   │   └── PreferencesView.swift         # Preferences window
│   ├── Utilities/
│   │   └── HotKeyManager.swift           # Global keyboard shortcut handler
│   └── Resources/
│       └── dictionary.json              # Local dictionary data
└── README.md
```

## Technical Details

### Accessibility Permissions

The app requires accessibility permissions to read selected text from other applications. Users will be prompted to grant these permissions on first launch.

### Dictionary Service

- **Local dictionary**: JSON file with common words (expandable)
- **API fallback**: Free Dictionary API (https://api.dictionaryapi.dev)
- **Caching**: Recently looked-up words are cached in memory

### Storage

- Uses SQLite for persistent storage
- Database location: `~/Library/Application Support/WordJournal/journal.db`
- All entries are stored locally

### Hot Key Registration

Uses Carbon API for global hotkey registration. The default shortcut is Cmd+Shift+D.

## Troubleshooting

### Accessibility Permissions Not Working

1. Go to System Settings → Privacy & Security → Accessibility
2. Ensure "WordJournal" is checked
3. If not listed, add it manually by clicking the "+" button

### Hot Key Not Responding

1. Check if the shortcut conflicts with another app
2. Try restarting the app
3. Check Preferences to ensure hotkey is enabled

### Dictionary Lookup Failing

1. Check internet connection (for API fallback)
2. Verify `dictionary.json` is included in the app bundle
3. Check Console.app for error messages

## Future Enhancements

- Customizable keyboard shortcuts
- Expanded local dictionary
- Word frequency analysis
- Flashcard mode
- Cloud sync
- Multiple language support

## License

Copyright © 2026. All rights reserved.
