#!/usr/bin/env python3
"""
Script to create Xcode project structure for WordJournal
"""

import os
import uuid
import plistlib
from pathlib import Path

def generate_uuid():
    """Generate a 24-character hex string for Xcode UUIDs"""
    return uuid.uuid4().hex[:24].upper()

# Generate UUIDs for all objects
project_uuid = generate_uuid()
target_uuid = generate_uuid()
group_uuid = generate_uuid()
app_file_ref = generate_uuid()
info_plist_ref = generate_uuid()

# Source file UUIDs
source_files = {
    'WordJournalApp.swift': generate_uuid(),
    'WordEntry.swift': generate_uuid(),
    'DictionaryResult.swift': generate_uuid(),
    'AccessibilityMonitor.swift': generate_uuid(),
    'DictionaryService.swift': generate_uuid(),
    'JournalStorage.swift': generate_uuid(),
    'DefinitionPopupView.swift': generate_uuid(),
    'JournalView.swift': generate_uuid(),
    'MenuBarView.swift': generate_uuid(),
    'PreferencesView.swift': generate_uuid(),
    'HotKeyManager.swift': generate_uuid(),
    'dictionary.json': generate_uuid(),
}

# Build configuration UUIDs
debug_config = generate_uuid()
release_config = generate_uuid()
project_debug_config = generate_uuid()
project_release_config = generate_uuid()

# Create project directory
project_dir = Path('WordJournal.xcodeproj')
project_dir.mkdir(exist_ok=True)

# Create project.pbxproj content
pbxproj_content = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
		{app_file_ref} /* WordJournalApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['WordJournalApp.swift']} /* WordJournalApp.swift */; }};
		{info_plist_ref} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {generate_uuid()} /* Info.plist */; }};
		{source_files['WordEntry.swift']} /* WordEntry.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['WordEntry.swift']} /* WordEntry.swift */; }};
		{source_files['DictionaryResult.swift']} /* DictionaryResult.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['DictionaryResult.swift']} /* DictionaryResult.swift */; }};
		{source_files['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */; }};
		{source_files['DictionaryService.swift']} /* DictionaryService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['DictionaryService.swift']} /* DictionaryService.swift */; }};
		{source_files['JournalStorage.swift']} /* JournalStorage.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['JournalStorage.swift']} /* JournalStorage.swift */; }};
		{source_files['DefinitionPopupView.swift']} /* DefinitionPopupView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */; }};
		{source_files['JournalView.swift']} /* JournalView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['JournalView.swift']} /* JournalView.swift */; }};
		{source_files['MenuBarView.swift']} /* MenuBarView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['MenuBarView.swift']} /* MenuBarView.swift */; }};
		{source_files['PreferencesView.swift']} /* PreferencesView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['PreferencesView.swift']} /* PreferencesView.swift */; }};
		{source_files['HotKeyManager.swift']} /* HotKeyManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_files['HotKeyManager.swift']} /* HotKeyManager.swift */; }};
		{source_files['dictionary.json']} /* dictionary.json in Resources */ = {{isa = PBXBuildFile; fileRef = {source_files['dictionary.json']} /* dictionary.json */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{generate_uuid()} /* WordJournal.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WordJournal.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{source_files['WordJournalApp.swift']} /* WordJournalApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WordJournalApp.swift; sourceTree = "<group>"; }};
		{generate_uuid()} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
		{source_files['WordEntry.swift']} /* WordEntry.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WordEntry.swift; sourceTree = "<group>"; }};
		{source_files['DictionaryResult.swift']} /* DictionaryResult.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DictionaryResult.swift; sourceTree = "<group>"; }};
		{source_files['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AccessibilityMonitor.swift; sourceTree = "<group>"; }};
		{source_files['DictionaryService.swift']} /* DictionaryService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DictionaryService.swift; sourceTree = "<group>"; }};
		{source_files['JournalStorage.swift']} /* JournalStorage.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = JournalStorage.swift; sourceTree = "<group>"; }};
		{source_files['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DefinitionPopupView.swift; sourceTree = "<group>"; }};
		{source_files['JournalView.swift']} /* JournalView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = JournalView.swift; sourceTree = "<group>"; }};
		{source_files['MenuBarView.swift']} /* MenuBarView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MenuBarView.swift; sourceTree = "<group>"; }};
		{source_files['PreferencesView.swift']} /* PreferencesView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PreferencesView.swift; sourceTree = "<group>"; }};
		{source_files['HotKeyManager.swift']} /* HotKeyManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HotKeyManager.swift; sourceTree = "<group>"; }};
		{source_files['dictionary.json']} /* dictionary.json */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = dictionary.json; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{generate_uuid()} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{group_uuid} = {{
			isa = PBXGroup;
			children = (
				{generate_uuid()} /* WordJournal */,
				{generate_uuid()} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* WordJournal */ = {{
			isa = PBXGroup;
			children = (
				{source_files['WordJournalApp.swift']} /* WordJournalApp.swift */,
				{generate_uuid()} /* Models */,
				{generate_uuid()} /* Services */,
				{generate_uuid()} /* Views */,
				{generate_uuid()} /* Utilities */,
				{generate_uuid()} /* Resources */,
			);
			path = WordJournal;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{source_files['WordEntry.swift']} /* WordEntry.swift */,
				{source_files['DictionaryResult.swift']} /* DictionaryResult.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{source_files['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */,
				{source_files['DictionaryService.swift']} /* DictionaryService.swift */,
				{source_files['JournalStorage.swift']} /* JournalStorage.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{source_files['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */,
				{source_files['JournalView.swift']} /* JournalView.swift */,
				{source_files['MenuBarView.swift']} /* MenuBarView.swift */,
				{source_files['PreferencesView.swift']} /* PreferencesView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Utilities */ = {{
			isa = PBXGroup;
			children = (
				{source_files['HotKeyManager.swift']} /* HotKeyManager.swift */,
			);
			path = Utilities;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{generate_uuid()} /* Info.plist */,
				{source_files['dictionary.json']} /* dictionary.json */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{generate_uuid()} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{generate_uuid()} /* WordJournal.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_uuid} /* WordJournal */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {generate_uuid()} /* Build configuration list for PBXNativeTarget "WordJournal" */;
			buildPhases = (
				{generate_uuid()} /* Sources */,
				{generate_uuid()} /* Frameworks */,
				{generate_uuid()} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WordJournal;
			productName = WordJournal;
			productReference = {generate_uuid()} /* WordJournal.app */;
			productType = "com.apple.product-type.application";
		}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		{project_uuid} /* Project object */ = {{
			isa = PBXProject;
			attributes = {{
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1500;
				LastUpgradeCheck = 1500;
				TargetAttributes = {{
					{target_uuid} = {{
						CreatedOnToolsVersion = 15.0;
					}};
				}};
			}};
			buildConfigurationList = {generate_uuid()} /* Build configuration list for PBXProject "WordJournal" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {group_uuid};
			productRefGroup = {generate_uuid()} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_uuid} /* WordJournal */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{generate_uuid()} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{info_plist_ref} /* Info.plist in Resources */,
				{source_files['dictionary.json']} /* dictionary.json in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{generate_uuid()} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{app_file_ref} /* WordJournalApp.swift in Sources */,
				{source_files['WordEntry.swift']} /* WordEntry.swift in Sources */,
				{source_files['DictionaryResult.swift']} /* DictionaryResult.swift in Sources */,
				{source_files['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift in Sources */,
				{source_files['DictionaryService.swift']} /* DictionaryService.swift in Sources */,
				{source_files['JournalStorage.swift']} /* JournalStorage.swift in Sources */,
				{source_files['DefinitionPopupView.swift']} /* DefinitionPopupView.swift in Sources */,
				{source_files['JournalView.swift']} /* JournalView.swift in Sources */,
				{source_files['MenuBarView.swift']} /* MenuBarView.swift in Sources */,
				{source_files['PreferencesView.swift']} /* PreferencesView.swift in Sources */,
				{source_files['HotKeyManager.swift']} /* HotKeyManager.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_config} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				MTL_FAST_MATH = YES;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = "DEBUG $(inherited)";
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			}};
			name = Debug;
		}};
		{release_config} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_ANALYZER_NUMBER_OBJECT_CONVERSION = YES_AGGRESSIVE;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				CLANG_ENABLE_OBJC_WEAK = YES;
				CLANG_WARN_BLOCK_CAPTURE_AUTORELEASING = YES;
				CLANG_WARN_BOOL_CONVERSION = YES;
				CLANG_WARN_COMMA = YES;
				CLANG_WARN_CONSTANT_CONVERSION = YES;
				CLANG_WARN_DEPRECATED_OBJC_IMPLEMENTATIONS = YES;
				CLANG_WARN_DIRECT_OBJC_ISA_USAGE = YES_ERROR;
				CLANG_WARN_DOCUMENTATION_COMMENTS = YES;
				CLANG_WARN_EMPTY_BODY = YES;
				CLANG_WARN_ENUM_CONVERSION = YES;
				CLANG_WARN_INFINITE_RECURSION = YES;
				CLANG_WARN_INT_CONVERSION = YES;
				CLANG_WARN_NON_LITERAL_NULL_CONVERSION = YES;
				CLANG_WARN_OBJC_IMPLICIT_RETAIN_SELF = YES;
				CLANG_WARN_OBJC_LITERAL_CONVERSION = YES;
				CLANG_WARN_OBJC_ROOT_CLASS = YES_ERROR;
				CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER = YES;
				CLANG_WARN_RANGE_LOOP_ANALYSIS = YES;
				CLANG_WARN_STRICT_PROTOTYPES = YES;
				CLANG_WARN_SUSPICIOUS_MOVE = YES;
				CLANG_WARN_UNGUARDED_AVAILABILITY = YES_AGGRESSIVE;
				CLANG_WARN_UNREACHABLE_CODE = YES;
				CLANG_WARN__DUPLICATE_METHOD_MATCH = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_USER_SCRIPT_SANDBOXING = YES;
				GCC_C_LANGUAGE_STANDARD = gnu17;
				GCC_NO_COMMON_BLOCKS = YES;
				GCC_WARN_64_TO_32_BIT_CONVERSION = YES;
				GCC_WARN_ABOUT_RETURN_TYPE = YES_ERROR;
				GCC_WARN_UNDECLARED_SELECTOR = YES;
				GCC_WARN_UNINITIALIZED_AUTOS = YES_AGGRESSIVE;
				GCC_WARN_UNUSED_FUNCTION = YES;
				GCC_WARN_UNUSED_VARIABLE = YES;
				LOCALIZATION_PREFERS_STRING_CATALOGS = YES;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				MTL_FAST_MATH = YES;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			}};
			name = Release;
		}};
		{project_debug_config} /* Debug */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = "";
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = "";
				CODE_SIGN_ENTITLEMENTS = "";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = WordJournal/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wordjournal.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Debug;
		}};
		{project_release_config} /* Release */ = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ASSETCATALOG_COMPILER_APPICON_NAME = "";
				ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME = "";
				CODE_SIGN_ENTITLEMENTS = "";
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				DEVELOPMENT_ASSET_PATHS = "";
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = WordJournal/Info.plist;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MARKETING_VERSION = 1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.wordjournal.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			}};
			name = Release;
		}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		{generate_uuid()} /* Build configuration list for PBXNativeTarget "WordJournal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_config} /* Debug */,
				{release_config} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{generate_uuid()} /* Build configuration list for PBXProject "WordJournal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{project_debug_config} /* Debug */,
				{project_release_config} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
'''

# Write project.pbxproj file
pbxproj_path = project_dir / 'project.pbxproj'
with open(pbxproj_path, 'w') as f:
    f.write(pbxproj_content)

print(f"[OK] Created Xcode project at {project_dir}")
print("[OK] Project structure created successfully!")
print("\nNext steps:")
print("1. Open WordJournal.xcodeproj in Xcode")
print("2. Verify all files are added to the target")
print("3. Build and run!")
