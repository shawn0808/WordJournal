# Text Selection Debugging Guide

## Problem: "No text selected" even when text IS selected

This happens when the Accessibility API can't read the selected text from the application.

## Debugging Steps

### 1. Check Console Logs

When you Control+Click, check Console.app for these messages:

```
AccessibilityMonitor: Frontmost app: TextEdit (PID: ...)
AccessibilityMonitor: Got focused element
AccessibilityMonitor: Failed to get selected text from focused element. Result: -25205
AccessibilityMonitor: Failed to get selected text from app. Result: -25205
AccessibilityMonitor: Trying pasteboard method...
AccessibilityMonitor: Starting pasteboard method (Cmd+C simulation)
AccessibilityMonitor: Old pasteboard contents: '...'
AccessibilityMonitor: Posting Cmd+C events...
AccessibilityMonitor: New pasteboard contents: 'beautiful'
AccessibilityMonitor: ✅ Got text from pasteboard: 'beautiful'
```

### 2. What the Error Codes Mean

- **Result: -25205** = `kAXErrorAttributeUnsupported` - The app doesn't support the selected text attribute
- **Result: -25204** = `kAXErrorNoValue` - No text is selected
- **Result: 0** = Success

### 3. Test in Different Apps

Some apps work better with the Accessibility API than others:

**Usually Works:**
- ✅ TextEdit
- ✅ Notes
- ✅ Pages
- ✅ Safari (sometimes)
- ✅ Mail

**May Not Work:**
- ❌ Some web apps in browsers
- ❌ Electron apps
- ❌ Some third-party text editors

### 4. Verify Text is Actually Selected

1. Select text in TextEdit
2. The text should be **highlighted** (blue background)
3. Try copying it manually (Cmd+C) to verify it's selectable
4. Then try Control+Click

### 5. Check Pasteboard Method

The pasteboard method (Cmd+C simulation) should work in most cases:

1. Select text
2. Control+Click
3. Check Console for "Pasteboard method result"
4. If it shows the text, but popup doesn't appear, there's a different issue

### 6. Test Sequence

Try this exact sequence:

1. **Open TextEdit**
2. **Type**: `beautiful`
3. **Double-click** the word to select it (should be highlighted)
4. **Wait 1 second** (ensure selection is complete)
5. **Control+Click** on the selected word
6. **Check Console** for the logs above

### 7. Common Issues

#### Issue: Pasteboard method returns empty string

**Possible causes:**
- Text wasn't actually selected
- Cmd+C didn't work in that app
- Timing issue (try increasing sleep time)

**Fix:**
```swift
// In AccessibilityMonitor.swift, increase sleep time:
Thread.sleep(forTimeInterval: 0.2) // Was 0.1
```

#### Issue: "Got text from pasteboard" but popup doesn't show

**Cause:** The text is being retrieved, but something else is failing

**Check:**
1. Dictionary lookup working? (Check DictionaryService logs)
2. Popup window creation working? (Check AppDelegate logs)

#### Issue: Works in TextEdit but not Safari

**Cause:** Different apps implement accessibility differently

**Solution:** The pasteboard method should work as a fallback

### 8. Manual Test

Try the "Test Lookup" button:

1. Select text in any app
2. Click menu bar icon → **"Test Lookup"**
3. This bypasses the Control+Click detection
4. If this works, the issue is with click detection, not text selection

### 9. Enable More Debugging

The code already has extensive logging. Check Console.app and filter by:
- `AccessibilityMonitor`
- `AppDelegate`
- `TriggerManager`

### 10. Last Resort: Force Pasteboard Method

If the Accessibility API never works, modify `getCurrentSelectedText()` to skip methods 1 and 2:

```swift
func getCurrentSelectedText() -> String {
    guard hasAccessibilityPermission else {
        print("AccessibilityMonitor: No permissions")
        return ""
    }
    
    // Skip Accessibility API, go straight to pasteboard
    print("AccessibilityMonitor: Using pasteboard method only")
    return getTextFromPasteboard()
}
```

## Expected Console Output (Success)

```
TriggerManager: ✅✅✅ CONTROL+CLICK DETECTED!
AppDelegate: handleLookup() called
AccessibilityMonitor: Frontmost app: TextEdit (PID: 12345)
AccessibilityMonitor: Got focused element
AccessibilityMonitor: ✅ Got selected text from focused element: 'beautiful'
AppDelegate: Selected text: 'beautiful'
DictionaryService: Looking up word: beautiful
DictionaryService: ✅ Found definition in local dictionary
AppDelegate: showDefinitionPopup() called
```

## Quick Fix

If nothing works, rebuild with more aggressive pasteboard method:

1. Open `AccessibilityMonitor.swift`
2. Find `getCurrentSelectedText()`
3. Comment out methods 1 and 2
4. Only use method 3 (pasteboard)
5. Rebuild and test

This should work in 99% of apps!
