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
    var popupClickMonitor: Any?
    
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
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("AppDelegate: applicationDidFinishLaunching - setting up services")
        
        // Check accessibility permissions
        if !AccessibilityMonitor.shared.hasAccessibilityPermission {
            print("⚠️ Accessibility permissions not granted")
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
        
        // Set up trigger handler
        TriggerManager.shared.setActivationHandler { [weak self] in
            print("WordJournalApp: Activation handler called!")
            self?.handleLookup()
        }
        
        // Start monitoring accessibility
        AccessibilityMonitor.shared.startMonitoring()
        
        print("AppDelegate: Setup complete")
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
                alert.informativeText = "Please select a word or phrase first, then Shift+Click to look it up"
                alert.alertStyle = .informational
                alert.addButton(withTitle: "OK")
                alert.runModal()
            }
            return
        }
        
        // Clean up the text - trim whitespace and limit length
        // Support both single words and phrases
        let word = selectedText
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
            .prefix(200)  // Reasonable limit for phrases
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !word.isEmpty else { 
            print("AppDelegate: Word is empty after cleanup")
            return 
        }
        
        let isPhrase = word.contains(" ")
        print("AppDelegate: Looking up \(isPhrase ? "phrase" : "word"): '\(word)'")
        
        DictionaryService.shared.lookup(String(word)) { result in
            switch result {
            case .success(let definition):
                print("AppDelegate: Dictionary lookup successful")
                DispatchQueue.main.async {
                    self.showDefinitionPopup(word: String(word), definition: definition)
                }
            case .failure(let error):
                print("AppDelegate: Dictionary lookup failed: \(error)")
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Lookup Failed"
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
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
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
            onAddToJournal: { defText, posText, exText in
                print("AppDelegate: 'Add to Journal' clicked for definition: '\(defText.prefix(50))...'")
                self.addToJournal(word: word, definition: defText, partOfSpeech: posText, example: exText)
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
        
        // Remove any previous click-outside monitor
        if let oldMonitor = popupClickMonitor {
            NSEvent.removeMonitor(oldMonitor)
            popupClickMonitor = nil
        }
        
        // Dismiss when user clicks outside the popup
        popupClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self, weak panel] event in
            guard let panel = panel, panel.isVisible else {
                // Panel is gone, clean up monitor
                if let monitor = self?.popupClickMonitor {
                    NSEvent.removeMonitor(monitor)
                    self?.popupClickMonitor = nil
                }
                return
            }
            
            let screenLocation = NSEvent.mouseLocation
            let panelFrame = panel.frame
            
            if !panelFrame.contains(screenLocation) {
                panel.close()
                if let monitor = self?.popupClickMonitor {
                    NSEvent.removeMonitor(monitor)
                    self?.popupClickMonitor = nil
                }
            }
        }
    }
    
    private func addToJournal(word: String, definition: String, partOfSpeech: String, example: String) {
        print("AppDelegate: addToJournal() called for word: '\(word)'")
        print("AppDelegate: Definition: '\(definition)'")
        print("AppDelegate: Part of speech: '\(partOfSpeech)'")
        
        let entry = WordEntry(
            word: word,
            definition: definition,
            partOfSpeech: partOfSpeech,
            example: example,
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
    }
    
    var body: some Scene {
        MenuBarExtra("Word Journal", systemImage: "character.book.closed.fill") {
            MenuBarView(
                showJournal: { appDelegate.showJournal() },
                showPreferences: { appDelegate.showPreferences() },
                journalStorage: journalStorage
            )
            
        }
        .menuBarExtraStyle(.window)
    }
}
