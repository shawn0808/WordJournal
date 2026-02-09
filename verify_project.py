#!/usr/bin/env python3
"""
Script to verify Xcode project has all required files
"""

import os
from pathlib import Path

required_files = {
    'WordJournalApp.swift': 'WordJournal/',
    'WordEntry.swift': 'WordJournal/Models/',
    'DictionaryResult.swift': 'WordJournal/Models/',
    'AccessibilityMonitor.swift': 'WordJournal/Services/',
    'DictionaryService.swift': 'WordJournal/Services/',
    'JournalStorage.swift': 'WordJournal/Services/',
    'DefinitionPopupView.swift': 'WordJournal/Views/',
    'JournalView.swift': 'WordJournal/Views/',
    'MenuBarView.swift': 'WordJournal/Views/',
    'PreferencesView.swift': 'WordJournal/Views/',
    'HotKeyManager.swift': 'WordJournal/Utilities/',
    'Info.plist': 'WordJournal/',
    'dictionary.json': 'WordJournal/Resources/',
}

base_dir = Path(__file__).parent

print("Verifying project files...")
print("=" * 50)

all_present = True
for filename, expected_path in required_files.items():
    filepath = base_dir / expected_path / filename
    if filepath.exists():
        print(f"[OK] {filename}")
    else:
        print(f"[MISSING] {filename} at {filepath}")
        all_present = False

print("=" * 50)

if all_present:
    print("\n[SUCCESS] All required files are present!")
    print("\nNext steps:")
    print("1. Open WordJournal.xcodeproj in Xcode")
    print("2. Verify all files appear in Project Navigator")
    print("3. Ensure dictionary.json has Target Membership checked")
    print("4. Build and run (Cmd+R)")
else:
    print("\n[ERROR] Some files are missing!")
    print("Please check the file paths above.")

# Check if project file exists
project_file = base_dir / 'WordJournal.xcodeproj' / 'project.pbxproj'
if project_file.exists():
    print(f"\n[OK] Xcode project file exists: {project_file}")
else:
    print(f"\n[ERROR] Xcode project file not found: {project_file}")
