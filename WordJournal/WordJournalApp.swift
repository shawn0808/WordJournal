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
        if journalWindow == nil || !journalWindow!.isVisible {
            let contentView = JournalView()
                .environmentObject(JournalStorage.shared)
            
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 800, height: 600)
            
            journalWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .miniaturizable, .resizable],
                backing: .buffered,
                defer: false
            )
            journalWindow?.title = "Word Journal"
            journalWindow?.contentView = hostingView
            journalWindow?.center()
        }
        journalWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func showPreferences() {
        if preferencesWindow == nil || !preferencesWindow!.isVisible {
            let contentView = PreferencesView()
                .environmentObject(TriggerManager.shared)
            
            let hostingView = NSHostingView(rootView: contentView)
            hostingView.frame = NSRect(x: 0, y: 0, width: 500, height: 400)
            
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            preferencesWindow?.title = "Preferences"
            preferencesWindow?.contentView = hostingView
            preferencesWindow?.center()
        }
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func handleLookup() {
        print("AppDelegate: handleLookup() called")
        let selectedText = AccessibilityMonitor.shared.getCurrentSelectedText()
        print("AppDelegate: Selected text: '\(selectedText)'")
        
        guard !selectedText.isEmpty else {
            print("AppDelegate: No text selected, showing alert")
            // Show a helpful message to the user
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "No Text Selected"
                alert.informativeText = "Please select a word first, then press Cmd+Shift+Option+D"
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
        // Close existing popup if any
        popupWindow?.close()
        
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 400),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = true
        
        // Position near cursor
        if let screen = NSScreen.main {
            let mouseLocation = NSEvent.mouseLocation
            let screenHeight = screen.frame.height
            let y = screenHeight - mouseLocation.y - 200
            panel.setFrameOrigin(NSPoint(x: mouseLocation.x, y: y))
        }
        
        let popupView = DefinitionPopupView(
            word: word,
            result: definition,
            onAddToJournal: {
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
        let firstMeaning = definition.meanings.first
        let firstDefinition = firstMeaning?.definitions.first
        
        let entry = WordEntry(
            word: word,
            definition: firstDefinition?.definition ?? definition.meanings.first?.definitions.first?.definition ?? "No definition available",
            partOfSpeech: firstMeaning?.partOfSpeech ?? "unknown",
            example: firstDefinition?.example ?? "",
            dateLookedUp: Date(),
            notes: ""
        )
        
        JournalStorage.shared.addEntry(entry)
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
