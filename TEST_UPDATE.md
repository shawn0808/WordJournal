# Testing Sparkle Updates (Option A)

The project is now at **v1.2 (build 3)** — includes the update-check fix (uses `isPathSatisfied` instead of dictionary probe).

## Step 1: Build and export the update (v1.2)

1. In Xcode: **Product → Archive**
2. In the Organizer: **Distribute App** → **Copy App**
3. Save the exported `WordJournal.app` somewhere (e.g. `~/Desktop/WordJournal_v1.2/`)
4. Create a DMG:
   ```bash
   hdiutil create -volname "Word Journal" -srcfolder /path/to/WordJournal.app -ov -format UDZO WordJournal-1.2.dmg
   ```

## Step 2: Generate the appcast

1. Put the DMG in the updates folder:
   ```bash
   mv ~/Desktop/WordJournal-1.2.dmg /Users/415350992/Downloads/WordJournalUpdates/
   ```

2. Run `generate_appcast`:
   ```bash
   /Users/415350992/Library/Developer/Xcode/DerivedData/WordJournal-gekptpqlwqugvtareqvqdcgryjbh/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_appcast /Users/415350992/Downloads/WordJournalUpdates
   ```

3. This creates/updates `appcast.xml` in the updates folder

## Step 3: Push to GitHub (docs/ folder)

Copy the new appcast and DMG to docs/, then push:

```bash
cd /Users/415350992/Downloads/vibe_coding/WordJournal
cp /Users/415350992/Downloads/WordJournalUpdates/appcast.xml docs/
cp /Users/415350992/Downloads/WordJournalUpdates/WordJournal-1.2.dmg docs/
git add docs/
git commit -m "Add v1.2 to appcast"
git push origin main
```

## Step 4: Test the update flow

You have **v1.1** installed. Test update to v1.2:

1. **Clear Sparkle's last check:**
   ```bash
   defaults delete com.wordjournal.app SULastCheckTime
   ```

2. **Launch WordJournal** (v1.1)

3. **Wait ~5–10 seconds** — Sparkle checks in the background on launch

4. **Quit the app** — The update installs when the app quits (with `SUAutomaticallyUpdate`)

5. **Launch again** — You should now be running v1.2

## Verify the appcast

```bash
curl https://shawn0808.github.io/WordJournal/appcast.xml
```

You should see XML with an `<item>` for version 1.1.

## Debugging

- **Console.app** — Filter by "Sparkle" or "WordJournal" for update logs
- **No update found?** — Check `SUFeedURL` in Info.plist matches where you hosted the appcast
- **"An error occurred"** — Appcast URL may be unreachable or the appcast format may be invalid
