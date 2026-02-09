# WordJournal Testing Guide

## Prerequisites

1. **Build the app**:
   - Open `WordJournal.xcodeproj` in Xcode
   - Press **Cmd+B** to build
   - Fix any compilation errors if they appear

2. **Grant Accessibility Permissions**:
   - The app requires accessibility permissions for:
     - Text selection monitoring
     - Global hotkey detection
   - When you first run the app, macOS will prompt you
   - Go to **System Settings → Privacy & Security → Accessibility**
   - Make sure **WordJournal** is checked ✅

## Running the App

1. **Run the app**:
   - Press **Cmd+R** in Xcode, or
   - Click the **Run** button in Xcode toolbar
   - The app will appear in your **menu bar** (top right)

2. **Verify menu bar icon**:
   - Look for a **book icon** (📖) in your menu bar
   - Click it to see the menu

## Testing Features

### 1. Test Menu Bar Integration

**Steps**:
1. Click the menu bar icon
2. Verify you see:
   - "Word Journal" header
   - Entry count (should show "0 entries" initially)
   - "Open Journal" option
   - "Preferences" option
   - "Quit" option

**Expected Result**: Menu appears with all options

---

### 2. Test Dictionary Lookup (Hotkey)

**Steps**:
1. Open any application (Safari, TextEdit, Notes, etc.)
2. **Select a word** (e.g., "serendipity", "eloquent")
3. Press **Cmd+Shift+D** (default hotkey)
4. A floating popup should appear with the definition

**Expected Result**: 
- Popup appears near your cursor
- Shows word, pronunciation, definitions, examples
- "Add to Journal" button is visible

**Troubleshooting**:
- If popup doesn't appear:
  - Check accessibility permissions
  - Try selecting text again
  - Check Console.app for errors
  - Verify the word exists in dictionary (try "test" or "hello")

---

### 3. Test Adding Words to Journal

**Steps**:
1. Look up a word using Cmd+Shift+D
2. Click **"Add to Journal"** button in the popup
3. Click the menu bar icon
4. Click **"Open Journal"**

**Expected Result**:
- Journal window opens
- Shows the word you added
- Displays: Word, Definition, Part of Speech, Date, Notes columns

---

### 4. Test Journal Editing

**Steps**:
1. Open Journal (menu bar → Open Journal)
2. **Double-click** any cell (Word, Definition, Notes, etc.)
3. Edit the text
4. Press **Enter** or click outside to save

**Expected Result**:
- Cell becomes editable
- Changes are saved automatically
- Updated values persist after closing/reopening journal

---

### 5. Test Journal Search

**Steps**:
1. Add a few words to the journal
2. Open Journal window
3. Type in the **Search** field at the top
4. Try searching by:
   - Word name
   - Definition text
   - Notes

**Expected Result**:
- Table filters to show matching entries
- Entry count updates
- Search works in real-time

---

### 6. Test Journal Export

**Steps**:
1. Add at least one word to journal
2. Open Journal window
3. Click **"Export CSV"** button
4. Check your **Desktop** for the CSV file

**Expected Result**:
- CSV file appears on Desktop
- File name: `WordJournal_[timestamp].csv`
- File contains all journal entries
- Can be opened in Excel/Numbers

---

### 7. Test Preferences Window

**Steps**:
1. Click menu bar icon
2. Click **"Preferences"**
3. Verify:
   - Accessibility permission status
   - Hot key settings
   - About tab

**Expected Result**:
- Preferences window opens
- Shows current accessibility permission status
- Displays hotkey information

---

### 8. Test Hotkey with Different Apps

**Steps**:
1. Test in **Safari**:
   - Select text on a webpage
   - Press Cmd+Shift+D
   
2. Test in **TextEdit**:
   - Type some text
   - Select a word
   - Press Cmd+Shift+D
   
3. Test in **Notes**:
   - Select text in a note
   - Press Cmd+Shift+D

**Expected Result**: Hotkey works across all applications

---

### 9. Test Dictionary Service (Local + API)

**Test Local Dictionary**:
1. Try words from the sample dictionary:
   - "serendipity"
   - "eloquent"
   - "meticulous"
   - "resilient"

**Test API Fallback**:
1. Try a word NOT in local dictionary:
   - "supercalifragilisticexpialidocious"
   - "onomatopoeia"
   - Any uncommon word

**Expected Result**:
- Local words: Instant lookup (no network delay)
- API words: Slight delay, then definition appears
- Both show proper definitions

---

### 10. Test Popup Auto-Dismiss

**Steps**:
1. Look up a word (Cmd+Shift+D)
2. **Don't click anything**
3. Wait 10 seconds

**Expected Result**: Popup automatically closes after 10 seconds

---

### 11. Test Multiple Lookups

**Steps**:
1. Look up word #1 (Cmd+Shift+D)
2. Immediately look up word #2 (select different word, Cmd+Shift+D)

**Expected Result**:
- First popup closes
- New popup appears with new word
- No duplicate popups

---

### 12. Test Journal Persistence

**Steps**:
1. Add several words to journal
2. **Quit the app** (menu bar → Quit)
3. **Relaunch the app**
4. Open Journal

**Expected Result**:
- All previously added words are still there
- Data persists between app launches
- Database is stored in: `~/Library/Application Support/WordJournal/journal.db`

---

## Common Issues & Solutions

### Issue: Hotkey doesn't work
**Solutions**:
- Check accessibility permissions in System Settings
- Try restarting the app
- Verify no other app is using Cmd+Shift+D
- Check Console.app for errors

### Issue: Popup doesn't appear
**Solutions**:
- Ensure text is actually selected (highlighted)
- Check accessibility permissions
- Try a different word
- Verify internet connection (for API fallback)

### Issue: Dictionary lookup fails
**Solutions**:
- Check internet connection
- Verify `dictionary.json` is in app bundle
- Try common words first
- Check Console.app for API errors

### Issue: Journal doesn't save
**Solutions**:
- Check write permissions to Application Support folder
- Verify SQLite database file exists
- Check Console.app for database errors

### Issue: Menu bar icon doesn't appear
**Solutions**:
- Check if app is running (Activity Monitor)
- Verify `LSUIElement` is set to YES in Info.plist
- Try restarting the app

---

## Testing Checklist

- [ ] App builds without errors
- [ ] Menu bar icon appears
- [ ] Menu bar menu works
- [ ] Hotkey (Cmd+Shift+D) works
- [ ] Dictionary lookup shows popup
- [ ] Popup displays correct definition
- [ ] "Add to Journal" works
- [ ] Journal window opens
- [ ] Journal displays entries correctly
- [ ] Journal editing works (double-click)
- [ ] Journal search works
- [ ] Journal export creates CSV file
- [ ] Preferences window opens
- [ ] Accessibility permission status shows correctly
- [ ] Hotkey works in multiple apps
- [ ] Local dictionary works
- [ ] API fallback works
- [ ] Popup auto-dismisses after 10 seconds
- [ ] Multiple lookups work correctly
- [ ] Data persists after app restart

---

## Performance Testing

1. **Add 100+ words** to journal
2. **Test search performance** with large dataset
3. **Test scrolling** in journal table
4. **Monitor memory usage** (Activity Monitor)

---

## Edge Cases to Test

1. **Empty selection**: Press Cmd+Shift+D with no text selected
2. **Multiple words selected**: Select a phrase, press hotkey
3. **Special characters**: Try words with accents, hyphens
4. **Very long definitions**: Test with words that have long definitions
5. **Network offline**: Disconnect internet, test API fallback behavior
6. **Rapid hotkey presses**: Press Cmd+Shift+D multiple times quickly

---

## Console Logging

To see debug information:
1. Open **Console.app** (Applications → Utilities)
2. Filter by "WordJournal"
3. Look for:
   - Dictionary lookup messages
   - Error messages
   - Database operations

---

## Success Criteria

The app is working correctly if:
✅ All features work as described above
✅ No crashes or errors
✅ Data persists correctly
✅ Performance is acceptable
✅ UI is responsive

Happy testing! 🚀
