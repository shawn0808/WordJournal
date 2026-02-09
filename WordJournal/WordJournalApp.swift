//
//  WordJournalApp.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    var journalWindow: NSWindow?
    var preferencesWindow: NSWindow?
    var popupWindow: NSWindow?
    
    override init() {
        super.init()
        AppDelegate.shared = self
        
        // Listen for test lookup notification
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTestLookup),
            name: NSNotification.Name("TestLookup"),
            object: nil
        )
    }
    
    @objc func handleTestLookup() {
        print("AppDelegate: Test lookup triggered from menu")
        handleLookup()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return false
    }
    
    func showJournal() {
        // Check if window exists and is still valid
        if let window = journalWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let contentView = JournalView()
            .environmentObject(JournalStorage.shared)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Word Journal"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        journalWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showPreferences() {
        // Check if window exists and is still valid
        if let window = preferencesWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        // Create new window
        let contentView = PreferencesView()
            .environmentObject(TriggerManager.shared)
        
        let hostingView = NSHostingView(rootView: contentView)
        hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.contentView = hostingView
        window.center()
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
        preferencesWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func handleLookup() {
        print("AppDelegate: handleLookup() called")
        
        // Check permissions first
        AccessibilityMonitor.shared.checkAccessibilityPermission(showPrompt: false)
        print("AppDelegate: Accessibility permission status: \(AccessibilityMonitor.shared.hasAccessibilityPermission)")
        
        let selectedText = AccessibilityMonitor.shared.getCurrentSelectedText()
        print("AppDelegate: Selected text: '\(selectedText)'")
        
        guard !selectedText.isEmpty else {
            print("AppDelegate: No text selected, showing alert")
            // Show a helpful message to the user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "No Text Selected"
                alert.informativeText = "Please select a word first, then Shift+Click to look it up"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }
        
        // Clean up the text - take first word if multiple words selected
        let words = selectedText.components(separatedBy: .whitespacesAndNewlines)
        let word = words.first?.trimmingCharacters(in: .punctuationCharacters) ?? selectedText
        
        guard !word.isEmpty else { 
            print("AppDelegate: Word is empty after cleanup")
            return 
        }
        
        print("AppDelegate: Looking up word: '\(word)'")
        
        DictionaryService.shared.lookup(word) { result in
            switch result {
            case .success(let definition):
                print("AppDelegate: Dictionary lookup successful")
                DispatchQueue.main.async {
                    self.showDefinitionPopup(word: word, definition: definition)
                }
            case .failure(let error):
                print("AppDelegate: Dictionary lookup failed: \(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Dictionary Lookup Failed"
                    alert.informativeText = "Could not find definition for '\(word)'. Error: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
    }
    
    func showDefinitionPopup(word: String, definition: DictionaryResult) {
        print("AppDelegate: showDefinitionPopup() for '\(word)'")
        
        // Close existing popup if any
        popupWindow?.close()
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.titled, .closable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.backgroundColor = NSColor.windowBackgroundColor
        panel.isOpaque = false
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        // Allow the panel to become key so buttons work
        panel.becomesKeyOnlyIfNeeded = true
        
        // Position near cursor
        if let screen = NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            let panelWidth: CGFloat = 400
            let panelHeight: CGFloat = 400
            
            // Position to the right and slightly below the cursor
            var x = mouseLocation.x + 10
            var y = mouseLocation.y - panelHeight - 10
            
            // Keep on screen
            if x + panelWidth > screen.visibleFrame.maxX {
                x = mouseLocation.x - panelWidth - 10
            }
            if y < screen.visibleFrame.minY {
                y = mouseLocation.y + 10
            }
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        let popupView = DefinitionPopupView(
            word: word,
            result: definition,
            onAddToJournal: {
                print("AppDelegate: 'Add to Journal' button clicked!")
                self.addToJournal(word: word, definition: definition)
                panel.close()
            },
            onDismiss: {
                panel.close()
            }
        )
        
        let hostingView = NSHostingView(rootView: popupView)
        panel.contentView = hostingView
        panel.contentView?.frame = NSRect(x: 0, y: 0, width: 400, height: 400)
        
        // Activate the app so the panel can receive clicks
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        popupWindow = panel
        
        // Auto-dismiss after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if panel.isVisible {
                panel.close()
            }
        }
    }
    
    private func addToJournal(word: String, definition: DictionaryResult) {
        print("AppDelegate: addToJournal() called for word: '\(word)'")
        
        let firstMeaning = definition.meanings.first
        let firstDefinition = firstMeaning?.definitions.first
        
        let defText = firstDefinition?.definition ?? "No definition available"
        let posText = firstMeaning?.partOfSpeech ?? "unknown"
        let exText = firstDefinition?.example ?? ""
        
        print("AppDelegate: Definition: '\(defText)'")
        print("AppDelegate: Part of speech: '\(posText)'")
        
        let entry = WordEntry(
            word: word,
            definition: defText,
            partOfSpeech: posText,
            example: exText,
            dateLookedUp: Date(),
            notes: ""
        )
        
        JournalStorage.shared.addEntry(entry)
        print("AppDelegate: ✅ addToJournal() complete")
    }
}

@main
struct WordJournalApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var journalStorage = JournalStorage.shared
    @StateObject private var accessibilityMonitor = AccessibilityMonitor.shared
    @StateObject private var hotKeyManager = HotKeyManager.shared
    @StateObject private var dictionaryService = DictionaryService.shared
    
    init() {
        print("WordJournalApp: App initializing...")
        // Initialization happens here, but setup will occur in onAppear
    }
    
    func setupServices() {
        print("WordJournalApp: setupServices() called")
        
        // Check accessibility permissions first
        AccessibilityMonitor.shared.checkAccessibilityPermission(showPrompt: false)
        
        if !AccessibilityMonitor.shared.hasAccessibilityPermission {
            print("⚠️ ⚠️ ⚠️ ACCESSIBILITY PERMISSIONS NOT GRANTED ⚠️ ⚠️ ⚠️")
            print("The app needs accessibility permissions to work!")
            print("Please go to: System Settings → Privacy & Security → Accessibility")
            print("Enable 'WordJournal' and restart the app")
            print("")
            print("Or click the menu bar icon → Preferences → Request Permission")
            
            // Show alert to user
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = """
                WordJournal needs accessibility permissions to:
                • Detect text selections
                • Listen for global keyboard shortcuts
                
                Please enable it in:
                System Settings → Privacy & Security → Accessibility
                
                Then restart the app.
                """
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Remind Me Later")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        } else {
            print("✅ Accessibility permissions granted")
        }
        
        // Set up trigger handler (keyboard or triple-click)
        let delegate = appDelegate
        print("WordJournalApp: Setting activation handler")
        TriggerManager.shared.setActivationHandler {
            print("WordJournalApp: Activation handler called!")
            delegate.handleLookup()
        }
        
        // Start monitoring accessibility
        print("WordJournalApp: Starting accessibility monitoring")
        AccessibilityMonitor.shared.startMonitoring()
        
        print("WordJournalApp: Setup complete")
    }
    
    var body: some Scene {
        MenuBarExtra("Word Journal", systemImage: "book.closed") {
            MenuBarView(
                showJournal: { appDelegate.showJournal() },
                showPreferences: { appDelegate.showPreferences() },
                journalStorage: journalStorage
            )
            .onAppear {
                print("WordJournalApp: MenuBarExtra appeared - calling setupServices()")
                setupServices()
            }
        }
        .menuBarExtraStyle(.window)
    }
}
