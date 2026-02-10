//
//  AccessibilityMonitor.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import AppKit
import ApplicationServices

class AccessibilityMonitor: ObservableObject {
    static let shared = AccessibilityMonitor()
    
    @Published var selectedText: String = ""
    @Published var hasAccessibilityPermission: Bool = false
    
    private var timer: DispatchSourceTimer?
    private let pollingQueue = DispatchQueue(label: "com.wordjournal.polling", qos: .utility)
    
    // Cache with app tracking (Option 3)
    private let cacheLock = NSLock()
    private var cachedSelectedText: String = ""
    private var cachedFromAppPID: pid_t = 0
    private var nonAXApps: Set<pid_t> = []  // PIDs of apps where AX API failed (e.g., PDF viewers)
    
    private init() {
        checkAccessibilityPermission(showPrompt: false)
    }
    
    func checkAccessibilityPermission(showPrompt: Bool = false) {
        if showPrompt {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        } else {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
    
    func requestPermission() {
        checkAccessibilityPermission(showPrompt: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAccessibilityPermission(showPrompt: false)
            if self.hasAccessibilityPermission {
                self.startMonitoring()
            }
        }
    }
    
    func startMonitoring() {
        checkAccessibilityPermission(showPrompt: false)
        
        guard hasAccessibilityPermission else {
            print("AccessibilityMonitor: No permissions - monitoring disabled")
            return
        }
        
        stopMonitoring()
        
        let source = DispatchSource.makeTimerSource(queue: pollingQueue)
        source.schedule(deadline: .now(), repeating: 0.5)
        source.setEventHandler { [weak self] in
            self?.pollSelectedText()
        }
        source.resume()
        timer = source
        
        print("AccessibilityMonitor: ✅ Polling started on background thread")
    }
    
    func stopMonitoring() {
        timer?.cancel()
        timer = nil
    }
    
    // MARK: - Polling (background cache)
    
    private func pollSelectedText() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        let pid = frontmostApp.processIdentifier
        
        // Try Accessibility API to get selected text
        if let text = readSelectedTextViaAccessibility(pid: pid) {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            cacheLock.lock()
            let isDifferent = !trimmed.isEmpty && (trimmed != cachedSelectedText || pid != cachedFromAppPID)
            if isDifferent {
                cachedSelectedText = trimmed
                cachedFromAppPID = pid
            }
            cacheLock.unlock()
            
            if isDifferent {
                DispatchQueue.main.async { [weak self] in
                    self?.selectedText = trimmed
                }
                print("AccessibilityMonitor: 📝 Cached: '\(trimmed)' from \(frontmostApp.localizedName ?? "Unknown") (PID: \(pid))")
            }
        }
        // If Accessibility API fails, we don't update the cache.
        // The pasteboard fallback will handle it when the user triggers a lookup.
    }
    
    // MARK: - Get text when user triggers lookup
    
    func getCurrentSelectedText() -> String {
        checkAccessibilityPermission(showPrompt: false)
        
        guard hasAccessibilityPermission else {
            print("AccessibilityMonitor: No permissions")
            return ""
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("AccessibilityMonitor: No frontmost app")
            return ""
        }
        
        let currentPID = frontmostApp.processIdentifier
        let appName = frontmostApp.localizedName ?? "Unknown"
        
        cacheLock.lock()
        let currentCache = cachedSelectedText
        let currentCachePID = cachedFromAppPID
        let isNonAX = nonAXApps.contains(currentPID)
        cacheLock.unlock()
        
        print("AccessibilityMonitor: getCurrentSelectedText() - App: \(appName) (PID: \(currentPID))")
        print("AccessibilityMonitor: Cache: '\(currentCache)' from PID: \(currentCachePID)")
        
        // Option 3: Check if cached text is from the SAME app
        // BUT skip cache for apps where AX API doesn't work (e.g., PDF viewers)
        // because the polling can't update the cache for those apps
        if !currentCache.isEmpty && currentCachePID == currentPID && !isNonAX {
            print("AccessibilityMonitor: ✅ Using cached text (same app): '\(currentCache)'")
            return currentCache
        }
        
        // Cache is stale (different app) or empty.
        // Try live Accessibility API read first.
        if let liveText = readSelectedTextViaAccessibility(pid: currentPID) {
            let trimmed = liveText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty {
                print("AccessibilityMonitor: ✅ Got live text from Accessibility API: '\(trimmed)'")
                cacheLock.lock()
                cachedSelectedText = trimmed
                cachedFromAppPID = currentPID
                cacheLock.unlock()
                return trimmed
            }
        }
        
        // Mark this app as non-AX so we don't use stale cache for it next time
        cacheLock.lock()
        nonAXApps.insert(currentPID)
        cacheLock.unlock()
        
        // Option 2 fallback: Accessibility API failed (e.g., Preview, Chrome, etc.)
        // Use pasteboard method (simulate Cmd+C)
        print("AccessibilityMonitor: Accessibility API failed for \(appName), trying pasteboard method...")
        let pasteboardText = getTextFromPasteboard()
        if !pasteboardText.isEmpty {
            print("AccessibilityMonitor: ✅ Got text from pasteboard: '\(pasteboardText)'")
            cacheLock.lock()
            cachedSelectedText = pasteboardText
            cachedFromAppPID = currentPID
            cacheLock.unlock()
            return pasteboardText
        }
        
        print("AccessibilityMonitor: ❌ All methods failed for \(appName)")
        return ""
    }
    
    // MARK: - Accessibility API reader
    
    private func readSelectedTextViaAccessibility(pid: pid_t) -> String? {
        let appRef = AXUIElementCreateApplication(pid)
        
        // Try focused element first (more reliable)
        var focusedElementRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appRef,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )
        
        if focusResult == .success, let focusedElement = focusedElementRef {
            var selectedTextRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                focusedElement as! AXUIElement,
                kAXSelectedTextAttribute as CFString,
                &selectedTextRef
            )
            
            if result == .success, let text = selectedTextRef as? String, !text.isEmpty {
                return text
            }
        }
        
        // Try app-level
        var selectedTextRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )
        
        if result == .success, let text = selectedTextRef as? String, !text.isEmpty {
            return text
        }
        
        return nil
    }
    
    // MARK: - Pasteboard fallback (Cmd+C simulation)
    
    private func getTextFromPasteboard() -> String {
        print("AccessibilityMonitor: Simulating Cmd+C to copy selection...")
        
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        
        // Clear pasteboard to detect new content
        pasteboard.clearContents()
        
        // Simulate Cmd+C
        let source = CGEventSource(stateID: .hidSystemState)
        
        let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cmdCDown?.flags = .maskCommand
        let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cmdCUp?.flags = .maskCommand
        
        cmdCDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.03)
        cmdCUp?.post(tap: .cghidEventTap)
        
        // Wait for copy to complete
        Thread.sleep(forTimeInterval: 0.12)
        
        let newContents = pasteboard.string(forType: .string) ?? ""
        
        // Restore old pasteboard
        if let oldContents = oldContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pasteboard.clearContents()
                pasteboard.setString(oldContents, forType: .string)
            }
        }
        
        return newContents.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Cache management
    
    func clearCache() {
        cacheLock.lock()
        cachedSelectedText = ""
        cachedFromAppPID = 0
        cacheLock.unlock()
        selectedText = ""
    }
}
