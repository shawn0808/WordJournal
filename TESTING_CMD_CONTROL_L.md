# WordJournal Testing Checklist - Cmd+Control+L

## Pre-Test Setup

### 1. Build and Run
- [ ] Open Xcode (should open automatically)
- [ ] Press **Cmd+B** to build
- [ ] Press **Cmd+R** to run
- [ ] Verify app icon appears in menu bar

### 2. Grant Permissions
- [ ] Open **Preferences** (click menu bar icon → Preferences)
- [ ] Check if "Hotkey monitor active" shows (green ✓) or (red ✗)
- [ ] If red, click **"Request Permission"** or **"Open System Settings"**
- [ ] In System Settings → Privacy & Security → Accessibility:
  - [ ] Find "WordJournal" and enable it ✅
  - [ ] If not listed, click "+" and add the app
- [ ] **Restart the app** after granting permissions
- [ ] Verify Preferences now shows "Hotkey monitor active" (green)

## Testing the New Hotkey (Cmd+Control+L)

### Test 1: Basic Lookup
1. [ ] Open **TextEdit** or **Notes**
2. [ ] Type: `beautiful`
3. [ ] **Select the word** (double-click or drag)
4. [ ] Press **Cmd+Control+L** (Command + Control + L)
5. [ ] **Expected**: Popup appears with definition

### Test 2: Console Logs (Debugging)
1. [ ] Open **Console.app** (Applications → Utilities → Console)
2. [ ] In the search bar, type: `WordJournal`
3. [ ] Or filter by: `HotKeyManager`
4. [ ] Clear the console
5. [ ] Press **Cmd+Control+L** in any app
6. [ ] **Expected logs**:
   ```
   HotKeyManager: 🔍 Cmd+Control detected - KeyCode: 37, All Modifiers: ...
   HotKeyManager: ✅✅✅ HOTKEY MATCHED! KeyCode: 37 (L), Modifiers: Cmd+Control
   AppDelegate: handleLookup() called
   ```

### Test 3: Manual Test (Bypass Hotkey)
1. [ ] Click menu bar icon
2. [ ] Select some text in any app first
3. [ ] Click **"Test Lookup"** button
4. [ ] **Expected**: Popup appears (proves lookup logic works)

### Test 4: Journal
1. [ ] Click menu bar icon → **"Open Journal"**
2. [ ] Verify journal window opens
3. [ ] Look up a word and click **"Add to Journal"** in popup
4. [ ] Verify word appears in journal

### Test 5: Different Apps
Test the hotkey in various applications:
- [ ] Safari (select text on webpage)
- [ ] TextEdit
- [ ] Notes
- [ ] Mail
- [ ] Any other app

## Troubleshooting

### If Hotkey Doesn't Work:

1. **Check Monitor Status**:
   - Preferences → Is "Hotkey monitor active" green?
   - If no → Permissions issue (see Pre-Test Setup #2)

2. **Check Console Logs**:
   - Do you see "Cmd+Control detected" when pressing the keys?
   - If no → Monitor not working (check permissions)
   - If yes but no "MATCHED" → Wrong key code or modifier issue

3. **Check Accessibility Permissions**:
   - System Settings → Privacy & Security → Accessibility
   - WordJournal must be checked ✅
   - Restart app after enabling

4. **Try Manual Test**:
   - If "Test Lookup" button works but hotkey doesn't:
     → Hotkey detection issue (check Console logs)
   - If "Test Lookup" doesn't work either:
     → Text selection or dictionary lookup issue

## Expected Results

✅ **Success Indicators**:
- Menu bar icon appears
- Preferences shows "Hotkey monitor active" (green)
- Console shows detection logs when pressing Cmd+Control+L
- Popup appears with word definition
- Word can be added to journal

❌ **Failure Indicators**:
- "Hotkey monitor inactive" (red) in Preferences
- No console logs when pressing hotkey
- No popup appears
- Alert says "No Text Selected" (but text IS selected)

## Console Log Reference

**Good logs (working)**:
```
HotKeyManager: ✅✅✅ Global event monitor created successfully!
HotKeyManager: ✅ Listening for Cmd+Control+L (KeyCode: 37)
HotKeyManager: 🔍 Cmd+Control detected - KeyCode: 37
HotKeyManager: ✅✅✅ HOTKEY MATCHED! KeyCode: 37 (L)
AppDelegate: handleLookup() called
```

**Bad logs (not working)**:
```
HotKeyManager: ❌❌❌ CRITICAL ERROR - Failed to create global event monitor!
```

---

## Quick Commands

**Open Console logs**:
```bash
# Real-time log streaming
log stream --predicate 'process == "WordJournal"' --level debug

# Or just open Console.app and filter by "WordJournal"
```

**Check if app is running**:
```bash
ps aux | grep WordJournal | grep -v grep
```
