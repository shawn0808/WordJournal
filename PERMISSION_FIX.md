# Quick Fix: Accessibility Permissions Not Granted

## Problem
You're seeing this error in Console:
```
AccessibilityMonitor: No permissions - monitoring disabled
```

This means the app cannot:
- ❌ Detect text selections
- ❌ Listen for Cmd+Control+L hotkey
- ❌ Work at all

## Solution (2 minutes)

### Step 1: Grant Accessibility Permission

1. **Open System Settings**
   - Click the Apple menu () → System Settings
   - Or use Spotlight: Press Cmd+Space, type "System Settings"

2. **Navigate to Accessibility**
   - Click **"Privacy & Security"** in the sidebar
   - Click **"Accessibility"** in the main panel

3. **Enable WordJournal**
   - Look for **"WordJournal"** in the list
   - **Check the box** next to it ✅
   
   **If WordJournal is NOT in the list:**
   - Click the **"+"** button at the bottom
   - Navigate to your app (usually in Applications or wherever you built it)
   - Select WordJournal.app and click "Open"
   - Now check the box ✅

4. **Restart the App**
   - Go back to Xcode
   - Press **Cmd+.** (to stop the app)
   - Press **Cmd+R** (to run again)

### Step 2: Verify It Works

After restarting, check Console.app for:
```
✅ Accessibility permissions granted
HotKeyManager: ✅✅✅ Global event monitor created successfully!
HotKeyManager: ✅ Listening for Cmd+Control+L (KeyCode: 37)
```

**Or check Preferences:**
- Click menu bar icon → Preferences
- Should show: "Hotkey monitor active" (green ✓)

## Alternative Method (Using the App)

The app now shows an alert on startup if permissions are missing:

1. When you see the alert, click **"Open System Settings"**
2. Enable WordJournal in Accessibility
3. Restart the app

## Testing After Permissions are Granted

1. Open TextEdit
2. Type: `test`
3. Select the word (double-click)
4. Press **Cmd+Control+L**
5. Definition popup should appear!

## Still Not Working?

1. **Check Console logs** - Filter by "WordJournal"
2. **Check Preferences** - Is monitor active (green)?
3. **Restart Mac** (sometimes required for permissions to take effect)
4. **Try removing and re-adding** the app in Accessibility settings

## Quick Check Commands

```bash
# Check if app is running
ps aux | grep WordJournal | grep -v grep

# Watch live logs
log stream --predicate 'process == "WordJournal"' --level debug
```

---

**Summary**: Go to System Settings → Privacy & Security → Accessibility → Enable WordJournal → Restart app
