# Troubleshooting: Hotkey Not Working

## Quick Diagnosis Steps

### 1. Check Console Logs

Open **Console.app** (Applications → Utilities → Console) and filter by "WordJournal" or "HotKeyManager". Look for:

- ✅ `"HotKeyManager: Global event monitor created successfully"` - Good!
- ❌ `"HotKeyManager: WARNING - Failed to create global event monitor"` - **Problem: No accessibility permissions**

### 2. Check Accessibility Permissions

**Critical**: `NSEvent.addGlobalMonitorForEvents` requires accessibility permissions!

1. Go to **System Settings → Privacy & Security → Accessibility**
2. Make sure **WordJournal** is checked ✅
3. If it's not listed, click the **+** button and add it
4. **Restart the app** after granting permissions

### 3. Test if Handler is Being Called

When you press Cmd+Shift+D, check Console.app for:
- `"HotKeyManager: Hotkey triggered!"` - Handler is being called
- `"AppDelegate: handleLookup() called"` - Lookup function is running

### 4. Test Text Selection

1. Open any app (TextEdit, Safari, Notes)
2. **Type or paste**: "test"
3. **Select the word** (double-click or drag)
4. Make sure it's **highlighted/selected**
5. Press Cmd+Shift+D

### 5. Manual Test

Try this in Terminal to test if the app is receiving events:

```bash
# Check if app is running
ps aux | grep WordJournal

# Check Console logs
log stream --predicate 'process == "WordJournal"' --level debug
```

## Common Issues

### Issue: "Failed to create global event monitor"

**Cause**: No accessibility permissions

**Fix**:
1. Grant accessibility permissions (see step 2 above)
2. Restart the app
3. Check Console for success message

### Issue: Handler called but no popup

**Possible causes**:
1. No text selected - Check Console for "No text selected" message
2. Dictionary lookup failed - Check Console for error messages
3. Popup window creation failed - Check Console for errors

### Issue: Nothing happens at all

**Check**:
1. Is the app running? (Check menu bar for icon)
2. Are permissions granted?
3. Check Console.app for any error messages
4. Try restarting the app

## Debug Mode

The app now includes debug logging. To see what's happening:

1. Open **Console.app**
2. Filter by "WordJournal"
3. Press Cmd+Shift+D
4. Look for log messages showing:
   - Hotkey detection
   - Text selection
   - Dictionary lookup
   - Popup creation

## Alternative: Test Hotkey Detection

Add this temporary test to verify hotkey is working:

1. Open the app
2. Check Console.app
3. Press Cmd+Shift+D
4. You should see: `"HotKeyManager: Hotkey triggered!"`

If you see this but no popup, the issue is with text selection or dictionary lookup, not the hotkey itself.

## Still Not Working?

1. **Rebuild the app**: Clean build folder (Shift+Cmd+K), then build (Cmd+B)
2. **Restart the app**: Quit completely and relaunch
3. **Check System Logs**: Console.app → System Reports → Look for errors
4. **Verify Permissions**: System Settings → Privacy & Security → Accessibility
