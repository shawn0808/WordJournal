# Creating a Signed & Notarized DMG for Word Journal v1.3

## Prerequisites

### 1. Developer ID Application Certificate
- Go to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list)
- Click **+** → **Developer ID Application** → Create
- Download and double-click to install in Keychain

### 2. create-dmg
```bash
brew install create-dmg
```

### 3. Notarization Credentials

**Create an app-specific password:**
1. [appleid.apple.com](https://appleid.apple.com) → Sign-In and Security → App-Specific Passwords
2. Generate a new password

**Store credentials for notarytool:**
```bash
xcrun notarytool store-credentials AC_PASSWORD \
  --apple-id "your-apple-id@email.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "xxxx-xxxx-xxxx-xxxx"
```

Find your Team ID at [developer.apple.com/account](https://developer.apple.com/account) (Membership details).

## Run the Script

```bash
./scripts/create_signed_notarized_dmg.sh
```

Output: `docs/WordJournal-1.3.dmg` (signed and notarized)

## Custom Signing Identity

If you have multiple Developer ID certs:
```bash
SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/create_signed_notarized_dmg.sh
```

## Notarization via Environment Variables

Instead of keychain profile:
```bash
NOTARY_APPLE_ID="your@email.com" \
NOTARY_TEAM_ID="YOUR_TEAM_ID" \
NOTARY_PASSWORD="xxxx-xxxx-xxxx-xxxx" \
./scripts/create_signed_notarized_dmg.sh
```
