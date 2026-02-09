# Hotkey Conflict Fix

## Problem Identified

The console logs show that **Siri is intercepting Cmd+Shift+D** before it reaches WordJournal. This is a known macOS behavior where system shortcuts take priority.

## Solution

I've changed the default hotkey from **Cmd+Shift+D** to **Cmd+Shift+B** to avoid the Siri conflict.

## What Changed

- Default hotkey: `Cmd+Shift+D` → `Cmd+Shift+B`
- Key code: `2` (D) → `11` (B)

## Testing the New Hotkey

1. **Rebuild the app** (Cmd+B)
2. **Run the app** (Cmd+R)
3. **Check Console** for:
   ```
   HotKeyManager: ✅ Global event monitor created successfully
   HotKeyManager: Listening for Cmd+Shift+B (KeyCode: 11)
   ```

4. **Test the hotkey**:
   - Open TextEdit or Notes
   - Type "test" and **select it**
   - Press **Cmd+Shift+B** (not D!)
   - Should see popup with definition

## If Cmd+Shift+B Still Doesn't Work

### Check Console Logs

Look for WordJournal logs (not Siri logs):

1. Open **Console.app**
2. Filter by **"WordJournal"** or **"HotKeyManager"**
3. When you press Cmd+Shift+B, you should see:
   ```
   HotKeyManager: Detected Cmd+Shift+Key - KeyCode: 11, Modifiers: [.command, .shift]
   HotKeyManager: ✅ Hotkey MATCHED! KeyCode: 11
   ```

### If No WordJournal Logs Appear

**Problem**: Event monitor not created (no accessibility permissions)

**Fix**:
1. System Settings → Privacy & Security → Accessibility
2. Enable WordJournal ✅
3. Restart the app

### Alternative Hotkeys to Try

If Cmd+Shift+B conflicts with something else, you can change it in code:

- `Cmd+Shift+W` (keyCode: 13)
- `Cmd+Shift+E` (keyCode: 14)
- `Cmd+Shift+R` (keyCode: 15)
- `Cmd+Shift+T` (keyCode: 17)

Edit `HotKeyManager.swift` line 15:
```swift
@Published var keyCode: UInt16 = 11 // Change this number
```

## Key Code Reference

- A = 0
- S = 1
- D = 2 (conflicts with Siri)
- F = 3
- H = 4
- G = 5
- Z = 6
- X = 7
- C = 8
- V = 9
- B = 11 ✅ (new default)
- Q = 12
- W = 13
- E = 14
- R = 15
- Y = 16
- T = 17

## Summary

**Old hotkey**: Cmd+Shift+D (conflicted with Siri)  
**New hotkey**: Cmd+Shift+B (should work!)

Try it now: Select text → Press **Cmd+Shift+B** → Should see definition popup!
