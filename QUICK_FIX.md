# Quick Fix: Hotkey Not Working

## Step-by-Step Diagnosis

### 1. Check Console Logs (MOST IMPORTANT)

1. **Open Console.app**:
   - Press Cmd+Space
   - Type "Console"
   - Open Console.app

2. **Filter logs**:
   - In the search box, type: `WordJournal` or `HotKeyManager`
   - Or filter by process: Select your Mac name → Look for "WordJournal"

3. **Rebuild and run the app**:
   - In Xcode: Cmd+B (build), then Cmd+R (run)

4. **Look for these messages**:

   ✅ **SUCCESS**: 
   ```
   HotKeyManager: ✅ Global event monitor created successfully
   HotKeyManager: Listening for Cmd+Shift+D (KeyCode: 2)
   ```

   ❌ **PROBLEM**: 
   ```
   HotKeyManager: ❌ ERROR - Failed to create global event monitor!
   ```
   **This means: NO ACCESSIBILITY PERMISSIONS**

### 2. Grant Accessibility Permissions

**This is REQUIRED for the hotkey to work!**

1. Go to **System Settings** (Apple menu → System Settings)
2. Click **Privacy & Security** (left sidebar)
3. Click **Accessibility** (right side)
4. Look for **WordJournal** in the list
5. **Toggle it ON** ✅
6. If WordJournal is NOT in the list:
   - Click the **+** button (or lock icon if locked)
   - Navigate to: `/Users/415350992/Library/Developer/Xcode/DerivedData/WordJournal-*/Build/Products/Debug/WordJournal.app`
   - Or drag the app from Finder
   - Make sure it's checked ✅

7. **RESTART THE APP** (Quit and relaunch)

### 3. Test with "Test Lookup" Button

1. Click the menu bar icon
2. Click **"Test Lookup"** button
3. This should trigger the lookup manually
4. Check Console for: `"AppDelegate: handleLookup() called"`

**If this works but hotkey doesn't**: The handler works, but event monitoring is broken (permissions issue)

**If this doesn't work**: There's a different problem (text selection, dictionary lookup, etc.)

### 4. Test Hotkey Detection

1. After granting permissions and restarting
2. Press **Cmd+Shift+D** (anywhere)
3. Check Console for:
   - `"HotKeyManager: Detected Cmd+Shift+Key"` - Event monitor is working!
   - `"HotKeyManager: ✅ Hotkey MATCHED!"` - Hotkey detected correctly!

### 5. Verify Text Selection

The hotkey works, but you need **selected text**:

1. Open **TextEdit** or **Notes**
2. Type: `test`
3. **Select the word** (double-click or drag to highlight)
4. Make sure it's **highlighted/selected**
5. Press **Cmd+Shift+D**

### 6. Check What Console Shows

When you press Cmd+Shift+D, you should see:

```
HotKeyManager: Detected Cmd+Shift+Key - KeyCode: 2, Modifiers: [.command, .shift]
HotKeyManager: ✅ Hotkey MATCHED! KeyCode: 2, Modifiers: [.command, .shift]
AppDelegate: handleLookup() called
AppDelegate: Selected text: 'test'
AppDelegate: Looking up word: 'test'
```

## Common Scenarios

### Scenario A: No Console Messages at All
- **Problem**: App might not be running
- **Fix**: Check menu bar for icon, restart app

### Scenario B: "Failed to create global event monitor"
- **Problem**: No accessibility permissions
- **Fix**: Grant permissions (Step 2), restart app

### Scenario C: "Hotkey MATCHED" but no popup
- **Problem**: No text selected OR dictionary lookup failed
- **Fix**: Select text first, check Console for errors

### Scenario D: "Test Lookup" works but hotkey doesn't
- **Problem**: Event monitor not working (permissions)
- **Fix**: Grant accessibility permissions, restart

## Still Not Working?

1. **Check if app is running**:
   ```bash
   ps aux | grep WordJournal
   ```

2. **Check system logs**:
   - Console.app → System Reports
   - Look for errors related to WordJournal

3. **Try a different hotkey**:
   - The key code 2 is 'D'
   - Try changing to a different key temporarily

4. **Verify permissions are actually granted**:
   - System Settings → Privacy & Security → Accessibility
   - WordJournal should be checked ✅
   - If unchecked, check it and restart app

## Quick Test Checklist

- [ ] App is running (menu bar icon visible)
- [ ] Console shows "Global event monitor created successfully"
- [ ] Accessibility permissions granted
- [ ] App restarted after granting permissions
- [ ] Text is selected before pressing hotkey
- [ ] Console shows "Hotkey MATCHED" when pressing Cmd+Shift+D
- [ ] "Test Lookup" button works

If all checked but still not working, check Console for specific error messages!
