//
//  WordJournalApp.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

// Subclass NSPanel to allow becoming key window when borderless
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    
    /// Fade out the panel then close it
    func fadeOutAndClose(duration: TimeInterval = 0.2) {
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = duration
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            self.animator().alphaValue = 0
        }, completionHandler: {
            self.close()
            self.alphaValue = 1  // Reset for reuse
        })
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    static var shared: AppDelegate?
    
    var journalWindow: NSWindow?
    var preferencesWindow: NSWindow?
    var popupWindow: NSWindow?
    var popupClickMonitor: Any?
    var lastAnchorRect: CGRect?  // Remembered position for popup updates
    
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
    
    func lookupWord(_ word: String) {
        let cleaned = word
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: .punctuationCharacters)
            .prefix(200)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !cleaned.isEmpty else { return }
        
        let isPhrase = cleaned.contains(" ")
        print("AppDelegate: Looking up \(isPhrase ? "phrase" : "word") from menu: '\(cleaned)'")
        
        // Show loading popup immediately
        self.showDefinitionPopup(word: String(cleaned), definition: nil, isLoading: true)
        
        DictionaryService.shared.lookup(String(cleaned)) { result in
            switch result {
            case .success(let definition):
                print("AppDelegate: Dictionary lookup successful")
                DispatchQueue.main.async {
                    // Update popup with the result (word may be lemmatized, e.g. "dogs" → "dog")
                    self.showDefinitionPopup(word: definition.word, definition: definition)
                }
            case .failure(let error):
                print("AppDelegate: Dictionary lookup failed: \(error)")
                DispatchQueue.main.async {
                    self.popupWindow?.close()
                    let alert = NSAlert()
                    alert.messageText = "Lookup Failed"
                    alert.informativeText = "Could not find definition for '\(cleaned)'. Error: \(error.localizedDescription)"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "OK")
                    alert.runModal()
                }
            }
        }
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
        
        // Capture the bounds of the selected text before lookup
        // Prefer AX bounds, but fall back to the trigger click location (right on the word)
        var selectionBounds = AccessibilityMonitor.shared.getSelectedTextBounds()
        if selectionBounds == nil, let triggerPt = TriggerManager.shared.lastTriggerLocation {
            // Create a small rect at the click point so the popup anchors right below the word
            selectionBounds = CGRect(x: triggerPt.x - 20, y: triggerPt.y - 10, width: 40, height: 20)
            print("AppDelegate: Using trigger click location as anchor: \(triggerPt)")
        }
        self.lastAnchorRect = selectionBounds
        print("AppDelegate: Selection bounds: \(String(describing: selectionBounds))")
        
        // Show loading popup immediately, anchored to the selected text
        self.showDefinitionPopup(word: String(word), definition: nil, isLoading: true, anchorRect: selectionBounds)
        
        DictionaryService.shared.lookup(String(word)) { result in
            switch result {
            case .success(let definition):
                print("AppDelegate: Dictionary lookup successful")
                DispatchQueue.main.async {
                    // Update popup with the result, keeping the same anchor position
                    self.showDefinitionPopup(word: definition.word, definition: definition, anchorRect: self.lastAnchorRect)
                }
            case .failure(let error):
                print("AppDelegate: Dictionary lookup failed: \(error)")
                DispatchQueue.main.async {
                    self.popupWindow?.close()
                    self.lastAnchorRect = nil
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
    
    func showDefinitionPopup(word: String, definition: DictionaryResult?, isLoading: Bool = false, anchorRect: CGRect? = nil) {
        print("AppDelegate: showDefinitionPopup() for '\(word)' (loading: \(isLoading))")
        
        // Close existing popup if any
        popupWindow?.close()
        
        let panel = KeyablePanel(
            contentRect: NSRect(x: 0, y: 0, width: 484, height: 464),
            styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
            backing: .buffered,
            defer: false
        )
        
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isFloatingPanel = true
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false  // SwiftUI handles the shadow now
        panel.isMovableByWindowBackground = false
        // Allow the panel to become key so buttons work
        panel.becomesKeyOnlyIfNeeded = true
        
        // Position so the click location is at one of the 4 corners of the popup card.
        // Pick the corner that keeps the most of the popup on screen.
        // The panel is 484x464 (card 420x~400 + 32pt transparent padding on each side).
        if let screen = NSScreen.main {
            let outerPadding: CGFloat = 32
            let cardWidth: CGFloat = 420
            let cardHeight: CGFloat = 400
            let panelWidth: CGFloat = cardWidth + outerPadding * 2   // 484
            let panelHeight: CGFloat = cardHeight + outerPadding * 2 // 464
            let visibleFrame = screen.visibleFrame
            let gap: CGFloat = 8  // Small gap between click point and card edge
            
            // Determine the reference point (anchor center or mouse cursor)
            let clickPt: NSPoint
            if let anchor = anchorRect, anchor.width > 0 {
                clickPt = NSPoint(x: anchor.midX, y: anchor.midY)
            } else {
                clickPt = NSEvent.mouseLocation
            }
            
            // Decide which corner to place relative to the click point:
            // Prefer popup below-right of click, but flip if not enough room
            let spaceRight = visibleFrame.maxX - clickPt.x
            let spaceLeft = clickPt.x - visibleFrame.minX
            let spaceBelow = clickPt.y - visibleFrame.minY
            let spaceAbove = visibleFrame.maxY - clickPt.y
            
            var x: CGFloat
            var y: CGFloat
            
            // Horizontal: prefer card to the right of click point
            if spaceRight >= cardWidth + gap {
                // Click at top-left corner of card
                x = clickPt.x + gap - outerPadding
            } else if spaceLeft >= cardWidth + gap {
                // Click at top-right corner of card
                x = clickPt.x - gap - cardWidth - outerPadding
            } else {
                // Center horizontally on click as fallback
                x = clickPt.x - panelWidth / 2
            }
            
            // Vertical: prefer card below click point (Cocoa coordinates: lower y = lower on screen)
            if spaceBelow >= cardHeight + gap {
                // Click at top edge of card
                y = clickPt.y - gap - cardHeight - outerPadding
            } else if spaceAbove >= cardHeight + gap {
                // Click at bottom edge of card
                y = clickPt.y + gap - outerPadding
            } else {
                // Center vertically as fallback
                y = clickPt.y - panelHeight / 2
            }
            
            // Final clamp to keep card within visible screen
            let cardRight = x + outerPadding + cardWidth
            let cardLeft = x + outerPadding
            let cardBottom = y + outerPadding
            let cardTop = y + outerPadding + cardHeight
            
            if cardRight > visibleFrame.maxX {
                x -= (cardRight - visibleFrame.maxX + 8)
            }
            if cardLeft < visibleFrame.minX {
                x += (visibleFrame.minX - cardLeft + 8)
            }
            if cardBottom < visibleFrame.minY {
                y += (visibleFrame.minY - cardBottom + 8)
            }
            if cardTop > visibleFrame.maxY {
                y -= (cardTop - visibleFrame.maxY + 8)
            }
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        let popupView = DefinitionPopupView(
            word: word,
            result: definition,
            isLoading: isLoading,
            onAddToJournal: { defText, posText, exText in
                print("AppDelegate: 'Add to Journal' clicked for definition: '\(defText.prefix(50))...'")
                self.addToJournal(word: word, definition: defText, partOfSpeech: posText, example: exText)
            },
            onDismiss: {
                panel.fadeOutAndClose()
            }
        )
        
        let hostingView = NSHostingView(rootView: popupView)
        hostingView.wantsLayer = true
        hostingView.layer?.backgroundColor = .clear
        panel.contentView = hostingView
        
        // Activate the app so the panel can receive clicks
        NSApp.activate(ignoringOtherApps: true)
        
        // Fade-in animation
        panel.alphaValue = 0
        panel.makeKeyAndOrderFront(nil)
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.18
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1
        }
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
            // Use the visible card area (inset by the transparent padding) for hit testing
            let cardFrame = panel.frame.insetBy(dx: 32, dy: 32)
            
            if !cardFrame.contains(screenLocation) {
                panel.fadeOutAndClose()
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
        MenuBarExtra("Word Journal", image: "MenuBarIcon") {
            MenuBarView(
                showJournal: { appDelegate.showJournal() },
                showPreferences: { appDelegate.showPreferences() },
                onLookupWord: { word in appDelegate.lookupWord(word) },
                journalStorage: journalStorage
            )
            
        }
        .menuBarExtraStyle(.window)
    }
}
