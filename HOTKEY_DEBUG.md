# Hotkey Debugging Guide

## Quick Check Steps

### 1. Check if Monitor is Active

1. **Open Preferences**: Click the menu bar icon → Preferences
2. **Look at "Keyboard Shortcut" section**:
   - ✅ **Green "Hotkey monitor active"** = Monitor is working
   - ❌ **Red "Hotkey monitor inactive"** = **Problem: No accessibility permissions**

### 2. Check Console Logs

Open **Console.app** (Applications → Utilities → Console) and filter by **"WordJournal"** or **"HotKeyManager"**.

**Look for these messages:**

#### ✅ Success Messages:
```
HotKeyManager: ✅✅✅ Global event monitor created successfully!
HotKeyManager: ✅ Listening for Cmd+Shift+B (KeyCode: 11)
HotKeyManager: ✅ Ready to detect hotkey!
```

#### ❌ Error Messages:
```
HotKeyManager: ❌❌❌ CRITICAL ERROR - Failed to create global event monitor!
```

**If you see the error**, accessibility permissions are NOT granted.

### 3. Grant Accessibility Permissions

1. Go to **System Settings** → **Privacy & Security** → **Accessibility**
2. Look for **"WordJournal"** in the list
3. If it's there but unchecked → **Enable it** ✅
4. If it's NOT in the list → Click **"+"** button → Navigate to your app → Add it
5. **RESTART the app** after granting permissions

### 4. Test the Hotkey

1. Open **TextEdit** or **Notes**
2. Type: `test`
3. **Select the word** (double-click or drag to highlight)
4. Press **Cmd+Shift+B**
5. Check Console for:
   ```
   HotKeyManager: 🔍 Cmd+Shift detected - KeyCode: 11, All Modifiers: ...
   HotKeyManager: ✅✅✅ HOTKEY MATCHED! KeyCode: 11 (B), Modifiers: Cmd+Shift
   ```

### 5. If Still Not Working

#### Check if ANY Cmd+Shift events are detected:

When you press Cmd+Shift+B, you should see in Console:
```
HotKeyManager: 🔍 Cmd+Shift detected - KeyCode: 11, All Modifiers: ...
```

**If you DON'T see this message:**
- Monitor is not active (check step 1)
- Permissions not granted (check step 3)

**If you DO see this but NOT the "MATCHED" message:**
- Check the KeyCode in the log - is it 11?
- Check if other modifiers (Option/Control) are being pressed accidentally

#### Try Manual Test

1. Click menu bar icon
2. Click **"Test Lookup"** button
3. This bypasses the hotkey and directly calls the lookup function
4. If this works but hotkey doesn't → Hotkey detection issue
5. If this doesn't work → Text selection or dictionary lookup issue

## Common Issues

### Issue: "Failed to create global event monitor"

**Cause**: No accessibility permissions

**Fix**: 
1. Grant permissions (see step 3)
2. **Restart the app** (quit completely and relaunch)
3. Check Preferences to confirm monitor is active

### Issue: Monitor active but hotkey doesn't work

**Check**:
1. Are you pressing **Cmd+Shift+B** (not D)?
2. Are you in an app where text can be selected?
3. Is text actually selected (highlighted)?
4. Check Console for "Cmd+Shift detected" messages

### Issue: Hotkey works but no popup appears

**Check**:
1. Is text selected? (You'll see an alert if not)
2. Check Console for dictionary lookup errors
3. Try "Test Lookup" button to isolate the issue

## Still Not Working?

1. **Check Console logs** - Look for any error messages
2. **Check Preferences** - Is monitor active?
3. **Try different hotkey** - Edit `HotKeyManager.swift` line 15 to change keyCode:
   - `Cmd+Shift+W` = keyCode: 13
   - `Cmd+Shift+E` = keyCode: 14
   - `Cmd+Shift+R` = keyCode: 15
4. **Restart the app** after any changes
