# Debug Steps: No WordJournal Logs in Console

## Problem
You're seeing Siri logs but **NO WordJournal logs** in Console. This means either:
1. The app isn't running
2. The app isn't logging
3. Console is filtering incorrectly

## Step 1: Verify App is Running

1. **Check menu bar**: Look for the book icon 📖
2. **If no icon**: App isn't running - launch it from Xcode (Cmd+R)
3. **If icon exists**: Click it to verify it's WordJournal

## Step 2: Check Console Filtering

The logs you showed are from **Siri**, not WordJournal. You need to filter correctly:

1. **Open Console.app**
2. **In the search box**, type: `WordJournal` or `HotKeyManager`
3. **OR** click your Mac name in left sidebar → Look for process "WordJournal"
4. **OR** use this filter: `process == "WordJournal"`

## Step 3: Rebuild and Check Startup Logs

1. **In Xcode**: Clean build folder (Shift+Cmd+K)
2. **Build** (Cmd+B)
3. **Run** (Cmd+R)
4. **Immediately check Console** - you should see:
   ```
   WordJournalApp: App initializing...
   HotKeyManager: Initialized
   WordJournalApp: MenuBarExtra appeared - calling setupServices()
   WordJournalApp: setupServices() called
   HotKeyManager: setActivationHandler() called
   HotKeyManager: Setting up hotkey - KeyCode: 11, Modifiers: [.command, .shift]
   ```

## Step 4: Check Event Monitor Creation

After running, look for ONE of these:

✅ **SUCCESS**:
```
HotKeyManager: ✅ Global event monitor created successfully
HotKeyManager: Listening for Cmd+Shift+B (KeyCode: 11)
```

❌ **FAILURE**:
```
HotKeyManager: ❌ ERROR - Failed to create global event monitor!
```

## Step 5: Test Hotkey Detection

1. **Press Cmd+Shift+B** (anywhere)
2. **Check Console** - you should see:
   ```
   HotKeyManager: Detected Cmd+Shift+Key - KeyCode: 11, Modifiers: [.command, .shift]
   HotKeyManager: ✅ Hotkey MATCHED! KeyCode: 11
   ```

**If you see Siri logs but NO WordJournal logs**: The event monitor wasn't created (no permissions)

## Step 6: Grant Accessibility Permissions

**CRITICAL**: `NSEvent.addGlobalMonitorForEvents` REQUIRES accessibility permissions!

1. **System Settings** → **Privacy & Security** → **Accessibility**
2. **Find WordJournal** in the list
3. **Toggle it ON** ✅
4. **If not listed**:
   - Click **+** button
   - Navigate to: `/Users/415350992/Library/Developer/Xcode/DerivedData/WordJournal-*/Build/Products/Debug/WordJournal.app`
   - Or drag the app from Finder
5. **RESTART THE APP** (Quit completely, then relaunch)

## Step 7: Use "Test Lookup" Button

1. **Click menu bar icon**
2. **Click "Test Lookup"** button
3. **Check Console** - should see:
   ```
   MenuBarView: Test button clicked - triggering lookup manually
   HotKeyManager: Manually triggered
   AppDelegate: handleLookup() called
   ```

**If this works**: Handler is fine, but event monitor isn't working (permissions issue)

**If this doesn't work**: Different problem (text selection, dictionary, etc.)

## Step 8: Alternative - Check if App is Actually Running

In Terminal:
```bash
ps aux | grep -i wordjournal
```

Should show the WordJournal process running.

## What to Look For

### ✅ Good Signs:
- Console shows "WordJournalApp: App initializing..."
- Console shows "Global event monitor created successfully"
- "Test Lookup" button works
- Menu bar icon appears

### ❌ Bad Signs:
- No WordJournal logs at all
- "Failed to create global event monitor"
- App doesn't appear in menu bar
- "Test Lookup" doesn't work

## Next Steps Based on What You Find

**If no logs at all**:
- App isn't running → Launch from Xcode
- Console filter wrong → Filter by "WordJournal"

**If "Failed to create global event monitor"**:
- No permissions → Grant accessibility permissions
- Restart app after granting

**If logs show but hotkey doesn't work**:
- Check if you're pressing Cmd+Shift+B (not D)
- Verify text is selected
- Check for other conflicts
