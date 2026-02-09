# Xcode Project Setup Guide

## ✅ Step 1: Project Created

The Xcode project has been created at `WordJournal.xcodeproj`.

## ✅ Step 2: Add Files to Project

The project file has been generated, but you may need to verify all files are properly added. Here's how to check and add files if needed:

### Option A: Verify in Xcode (Recommended)

1. **Open the project**: Double-click `WordJournal.xcodeproj` or run:
   ```bash
   open WordJournal.xcodeproj
   ```

2. **Check file references**: In Xcode's Project Navigator (left sidebar), verify all these files appear:
   - `WordJournalApp.swift`
   - `Models/WordEntry.swift`
   - `Models/DictionaryResult.swift`
   - `Services/AccessibilityMonitor.swift`
   - `Services/DictionaryService.swift`
   - `Services/JournalStorage.swift`
   - `Views/DefinitionPopupView.swift`
   - `Views/JournalView.swift`
   - `Views/MenuBarView.swift`
   - `Views/PreferencesView.swift`
   - `Utilities/HotKeyManager.swift`
   - `Resources/Info.plist`
   - `Resources/dictionary.json`

3. **If files are missing**, add them:
   - Right-click on the appropriate folder (Models, Services, Views, etc.)
   - Select "Add Files to WordJournal..."
   - Navigate to the `WordJournal/` directory
   - Select the missing files
   - Make sure "Copy items if needed" is **unchecked** (files are already in place)
   - Make sure "Add to targets: WordJournal" is **checked**
   - Click "Add"

### Option B: Use Command Line Script

Run this script to verify and add files:

```bash
cd /Users/415350992/Downloads/vibe_coding/WordJournal
python3 verify_project.py
```

## ✅ Step 3: Ensure dictionary.json is in Bundle

1. In Xcode, select `dictionary.json` in the Project Navigator
2. In the File Inspector (right panel), check:
   - **Target Membership**: Make sure "WordJournal" is checked
   - **Location**: Should be "Relative to Group"
3. If it's not added to the target:
   - Select `dictionary.json`
   - In the right panel, under "Target Membership", check "WordJournal"

## Build Settings to Verify

1. Select the **WordJournal** project in the navigator
2. Select the **WordJournal** target
3. Go to **Build Settings** tab
4. Verify:
   - **Swift Language Version**: Swift 5
   - **macOS Deployment Target**: 13.0 or later
   - **Info.plist File**: `WordJournal/Info.plist`

## Build and Run

1. Select a scheme: **WordJournal > My Mac**
2. Press **Cmd+B** to build
3. Press **Cmd+R** to run

## Troubleshooting

### "No such module" errors
- Make sure all Swift files are added to the target
- Clean build folder: **Product > Clean Build Folder** (Shift+Cmd+K)

### "Info.plist not found"
- Verify Info.plist path in Build Settings
- Make sure Info.plist is in the Resources group

### "dictionary.json not found at runtime"
- Make sure dictionary.json is added to the target
- Check Target Membership in File Inspector

### Build errors
- Make sure all files are added to the "WordJournal" target
- Check that Swift version is 5.0 or later
- Verify macOS deployment target is 13.0+

## Quick Verification Checklist

- [ ] Project opens in Xcode without errors
- [ ] All 11 Swift files appear in Project Navigator
- [ ] Info.plist is in Resources group
- [ ] dictionary.json is in Resources group and has target membership
- [ ] Project builds without errors (Cmd+B)
- [ ] App runs and appears in menu bar (Cmd+R)

## Next Steps After Setup

1. Grant accessibility permissions when prompted
2. Test the hotkey (Cmd+Shift+D) with selected text
3. Verify dictionary lookups work
4. Test adding words to journal
5. Test journal editing and export
