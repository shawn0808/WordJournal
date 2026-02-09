# How to Find WordJournal Logs in Console

## Good News! ✅

The app **IS running** - I can see it in the logs:
```
BackgroundState = 3;
BundleID = "com.wordjournal.app";
```

## Finding Our Print Statements

The logs you're seeing are **system-level** logs. Our `print()` statements might be in a different stream. Here's how to find them:

### Method 1: Filter by Process

1. **Open Console.app**
2. **In the left sidebar**, click your **Mac name**
3. **In the search box**, type: `process == "WordJournal"`
4. **Look for** our print statements like:
   - `WordJournalApp: App initializing...`
   - `HotKeyManager: ✅ Global event monitor created successfully`

### Method 2: Filter by Text

1. **In Console search box**, type: `HotKeyManager` or `WordJournalApp`
2. **Make sure** "Any" is selected (not "Info" or "Error")
3. **Scroll through** the results

### Method 3: Check Xcode Console

1. **In Xcode**, look at the **bottom panel**
2. **Click the "All Output"** tab (or "Debug" tab)
3. **Run the app** (Cmd+R)
4. **Look for** our print statements there

### Method 4: Use Terminal

```bash
# Stream WordJournal logs in real-time
log stream --predicate 'process == "WordJournal"' --level debug

# Then press Cmd+Shift+B and watch for logs
```

## What to Look For

When you **rebuild and run**, you should see:

```
WordJournalApp: App initializing...
HotKeyManager: Initialized
WordJournalApp: MenuBarExtra appeared - calling setupServices()
WordJournalApp: setupServices() called
HotKeyManager: setActivationHandler() called
HotKeyManager: Setting up hotkey - KeyCode: 11, Modifiers: [.command, .shift]
```

Then ONE of these:

✅ **SUCCESS**:
```
HotKeyManager: ✅ Global event monitor created successfully
HotKeyManager: Listening for Cmd+Shift+B (KeyCode: 11)
```

❌ **FAILURE**:
```
HotKeyManager: ❌ ERROR - Failed to create global event monitor!
```

## Quick Test

1. **Click menu bar icon** → **"Test Lookup"**
2. **Check Console** → Should see:
   ```
   MenuBarView: Test button clicked
   HotKeyManager: Manually triggered
   AppDelegate: handleLookup() called
   ```

If you see these logs, the app is working but event monitor might not be created.

## If Still No Logs

Try rebuilding:
1. **Clean** (Shift+Cmd+K)
2. **Build** (Cmd+B)  
3. **Run** (Cmd+R)
4. **Check Xcode console** (bottom panel) instead of Console.app
