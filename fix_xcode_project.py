#!/usr/bin/env python3
"""
Script to create a properly formatted Xcode project file for WordJournal
"""

import uuid
from pathlib import Path

def generate_uuid():
    """Generate a 24-character hex string for Xcode UUIDs"""
    return uuid.uuid4().hex[:24].upper()

# Generate all UUIDs upfront
project_uuid = generate_uuid()
target_uuid = generate_uuid()
main_group_uuid = generate_uuid()
products_group_uuid = generate_uuid()
wordjournal_group_uuid = generate_uuid()
models_group_uuid = generate_uuid()
services_group_uuid = generate_uuid()
views_group_uuid = generate_uuid()
utilities_group_uuid = generate_uuid()
resources_group_uuid = generate_uuid()

# File reference UUIDs
app_product_uuid = generate_uuid()
wordjournal_app_ref = generate_uuid()
info_plist_file_ref = generate_uuid()
info_plist_build_ref = generate_uuid()

# Source file UUIDs (file references)
source_file_refs = {
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

# Build file UUIDs
source_build_refs = {
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

# Build phase UUIDs
sources_phase_uuid = generate_uuid()
frameworks_phase_uuid = generate_uuid()
resources_phase_uuid = generate_uuid()

# Configuration UUIDs
debug_config_uuid = generate_uuid()
release_config_uuid = generate_uuid()
project_debug_config_uuid = generate_uuid()
project_release_config_uuid = generate_uuid()
target_config_list_uuid = generate_uuid()
project_config_list_uuid = generate_uuid()

# Build the project.pbxproj content
pbxproj = f'''// !$*UTF8*$!
{{
	archiveVersion = 1;
	classes = {{
	}};
	objectVersion = 56;
	objects = {{

/* Begin PBXBuildFile section */
		{source_build_refs['WordJournalApp.swift']} /* WordJournalApp.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['WordJournalApp.swift']} /* WordJournalApp.swift */; }};
		{source_build_refs['WordEntry.swift']} /* WordEntry.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['WordEntry.swift']} /* WordEntry.swift */; }};
		{source_build_refs['DictionaryResult.swift']} /* DictionaryResult.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['DictionaryResult.swift']} /* DictionaryResult.swift */; }};
		{source_build_refs['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */; }};
		{source_build_refs['DictionaryService.swift']} /* DictionaryService.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['DictionaryService.swift']} /* DictionaryService.swift */; }};
		{source_build_refs['JournalStorage.swift']} /* JournalStorage.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['JournalStorage.swift']} /* JournalStorage.swift */; }};
		{source_build_refs['DefinitionPopupView.swift']} /* DefinitionPopupView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */; }};
		{source_build_refs['JournalView.swift']} /* JournalView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['JournalView.swift']} /* JournalView.swift */; }};
		{source_build_refs['MenuBarView.swift']} /* MenuBarView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['MenuBarView.swift']} /* MenuBarView.swift */; }};
		{source_build_refs['PreferencesView.swift']} /* PreferencesView.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['PreferencesView.swift']} /* PreferencesView.swift */; }};
		{source_build_refs['HotKeyManager.swift']} /* HotKeyManager.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['HotKeyManager.swift']} /* HotKeyManager.swift */; }};
		{info_plist_build_ref} /* Info.plist in Resources */ = {{isa = PBXBuildFile; fileRef = {info_plist_file_ref} /* Info.plist */; }};
		{source_build_refs['dictionary.json']} /* dictionary.json in Resources */ = {{isa = PBXBuildFile; fileRef = {source_file_refs['dictionary.json']} /* dictionary.json */; }};
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		{app_product_uuid} /* WordJournal.app */ = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = WordJournal.app; sourceTree = BUILT_PRODUCTS_DIR; }};
		{source_file_refs['WordJournalApp.swift']} /* WordJournalApp.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WordJournalApp.swift; sourceTree = "<group>"; }};
		{source_file_refs['WordEntry.swift']} /* WordEntry.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = WordEntry.swift; sourceTree = "<group>"; }};
		{source_file_refs['DictionaryResult.swift']} /* DictionaryResult.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DictionaryResult.swift; sourceTree = "<group>"; }};
		{source_file_refs['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = AccessibilityMonitor.swift; sourceTree = "<group>"; }};
		{source_file_refs['DictionaryService.swift']} /* DictionaryService.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DictionaryService.swift; sourceTree = "<group>"; }};
		{source_file_refs['JournalStorage.swift']} /* JournalStorage.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = JournalStorage.swift; sourceTree = "<group>"; }};
		{source_file_refs['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DefinitionPopupView.swift; sourceTree = "<group>"; }};
		{source_file_refs['JournalView.swift']} /* JournalView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = JournalView.swift; sourceTree = "<group>"; }};
		{source_file_refs['MenuBarView.swift']} /* MenuBarView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = MenuBarView.swift; sourceTree = "<group>"; }};
		{source_file_refs['PreferencesView.swift']} /* PreferencesView.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = PreferencesView.swift; sourceTree = "<group>"; }};
		{source_file_refs['HotKeyManager.swift']} /* HotKeyManager.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HotKeyManager.swift; sourceTree = "<group>"; }};
		{info_plist_file_ref} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; }};
		{source_file_refs['dictionary.json']} /* dictionary.json */ = {{isa = PBXFileReference; lastKnownFileType = text.json; path = dictionary.json; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
		{frameworks_phase_uuid} /* Frameworks */ = {{
			isa = PBXFrameworksBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
		{main_group_uuid} = {{
			isa = PBXGroup;
			children = (
				{wordjournal_group_uuid} /* WordJournal */,
				{products_group_uuid} /* Products */,
			);
			sourceTree = "<group>";
		}};
		{wordjournal_group_uuid} /* WordJournal */ = {{
			isa = PBXGroup;
			children = (
				{source_file_refs['WordJournalApp.swift']} /* WordJournalApp.swift */,
				{models_group_uuid} /* Models */,
				{services_group_uuid} /* Services */,
				{views_group_uuid} /* Views */,
				{utilities_group_uuid} /* Utilities */,
				{resources_group_uuid} /* Resources */,
			);
			path = WordJournal;
			sourceTree = "<group>";
		}};
		{models_group_uuid} /* Models */ = {{
			isa = PBXGroup;
			children = (
				{source_file_refs['WordEntry.swift']} /* WordEntry.swift */,
				{source_file_refs['DictionaryResult.swift']} /* DictionaryResult.swift */,
			);
			path = Models;
			sourceTree = "<group>";
		}};
		{services_group_uuid} /* Services */ = {{
			isa = PBXGroup;
			children = (
				{source_file_refs['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift */,
				{source_file_refs['DictionaryService.swift']} /* DictionaryService.swift */,
				{source_file_refs['JournalStorage.swift']} /* JournalStorage.swift */,
			);
			path = Services;
			sourceTree = "<group>";
		}};
		{views_group_uuid} /* Views */ = {{
			isa = PBXGroup;
			children = (
				{source_file_refs['DefinitionPopupView.swift']} /* DefinitionPopupView.swift */,
				{source_file_refs['JournalView.swift']} /* JournalView.swift */,
				{source_file_refs['MenuBarView.swift']} /* MenuBarView.swift */,
				{source_file_refs['PreferencesView.swift']} /* PreferencesView.swift */,
			);
			path = Views;
			sourceTree = "<group>";
		}};
		{utilities_group_uuid} /* Utilities */ = {{
			isa = PBXGroup;
			children = (
				{source_file_refs['HotKeyManager.swift']} /* HotKeyManager.swift */,
			);
			path = Utilities;
			sourceTree = "<group>";
		}};
		{resources_group_uuid} /* Resources */ = {{
			isa = PBXGroup;
			children = (
				{info_plist_file_ref} /* Info.plist */,
				{source_file_refs['dictionary.json']} /* dictionary.json */,
			);
			path = Resources;
			sourceTree = "<group>";
		}};
		{products_group_uuid} /* Products */ = {{
			isa = PBXGroup;
			children = (
				{app_product_uuid} /* WordJournal.app */,
			);
			name = Products;
			sourceTree = "<group>";
		}};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		{target_uuid} /* WordJournal */ = {{
			isa = PBXNativeTarget;
			buildConfigurationList = {target_config_list_uuid} /* Build configuration list for PBXNativeTarget "WordJournal" */;
			buildPhases = (
				{sources_phase_uuid} /* Sources */,
				{frameworks_phase_uuid} /* Frameworks */,
				{resources_phase_uuid} /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = WordJournal;
			productName = WordJournal;
			productReference = {app_product_uuid} /* WordJournal.app */;
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
			buildConfigurationList = {project_config_list_uuid} /* Build configuration list for PBXProject "WordJournal" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = en;
			hasScannedForEncodings = 0;
			knownRegions = (
				en,
				Base,
			);
			mainGroup = {main_group_uuid};
			productRefGroup = {products_group_uuid} /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				{target_uuid} /* WordJournal */,
			);
		}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		{resources_phase_uuid} /* Resources */ = {{
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{info_plist_build_ref} /* Info.plist in Resources */,
				{source_build_refs['dictionary.json']} /* dictionary.json in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		{sources_phase_uuid} /* Sources */ = {{
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				{source_build_refs['WordJournalApp.swift']} /* WordJournalApp.swift in Sources */,
				{source_build_refs['WordEntry.swift']} /* WordEntry.swift in Sources */,
				{source_build_refs['DictionaryResult.swift']} /* DictionaryResult.swift in Sources */,
				{source_build_refs['AccessibilityMonitor.swift']} /* AccessibilityMonitor.swift in Sources */,
				{source_build_refs['DictionaryService.swift']} /* DictionaryService.swift in Sources */,
				{source_build_refs['JournalStorage.swift']} /* JournalStorage.swift in Sources */,
				{source_build_refs['DefinitionPopupView.swift']} /* DefinitionPopupView.swift in Sources */,
				{source_build_refs['JournalView.swift']} /* JournalView.swift in Sources */,
				{source_build_refs['MenuBarView.swift']} /* MenuBarView.swift in Sources */,
				{source_build_refs['PreferencesView.swift']} /* PreferencesView.swift in Sources */,
				{source_build_refs['HotKeyManager.swift']} /* HotKeyManager.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{debug_config_uuid} /* Debug */ = {{
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
		{release_config_uuid} /* Release */ = {{
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
		{project_debug_config_uuid} /* Debug */ = {{
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
		{project_release_config_uuid} /* Release */ = {{
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
		{target_config_list_uuid} /* Build configuration list for PBXNativeTarget "WordJournal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{debug_config_uuid} /* Debug */,
				{release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
		{project_config_list_uuid} /* Build configuration list for PBXProject "WordJournal" */ = {{
			isa = XCConfigurationList;
			buildConfigurations = (
				{project_debug_config_uuid} /* Debug */,
				{project_release_config_uuid} /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		}};
/* End XCConfigurationList section */
	}};
	rootObject = {project_uuid} /* Project object */;
}}
'''

# Write the corrected project file
project_dir = Path('WordJournal.xcodeproj')
project_dir.mkdir(exist_ok=True)

pbxproj_path = project_dir / 'project.pbxproj'
with open(pbxproj_path, 'w') as f:
    f.write(pbxproj)

print("[OK] Fixed Xcode project file!")
print("[OK] All UUIDs are now consistent and properly referenced")
print("\nThe project should now open correctly in Xcode.")
