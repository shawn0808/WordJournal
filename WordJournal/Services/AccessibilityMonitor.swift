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
    
    /// Returns the latest cached selected text for the current frontmost app, if available.
    /// Useful for click-based triggers (e.g. Option+Click) where the click may clear selection.
    func getCachedSelectedTextForFrontmostApp() -> String {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return "" }
        let currentPID = frontmostApp.processIdentifier
        
        cacheLock.lock()
        let cached = cachedSelectedText
        let cachedPID = cachedFromAppPID
        cacheLock.unlock()
        guard cachedPID == currentPID else { return "" }
        return cached.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
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
        
        // Always try fresh read first so we don't return stale cache (e.g. "youtube.com"
        // when user just selected a different word in Chrome). Use cache only as fallback.
        
        // 1. Try live Accessibility API read first.
        let liveAXResult = readSelectedTextViaAccessibility(pid: currentPID)
        if let liveText = liveAXResult {
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
        
        // 2. Try pasteboard (simulate Cmd+C) — works in Chrome, PDF viewers, etc.
        print("AccessibilityMonitor: Live AX empty/failed for \(appName), trying pasteboard...")
        let pasteboardText = getTextFromPasteboard()
        if !pasteboardText.isEmpty {
            print("AccessibilityMonitor: ✅ Got text from pasteboard: '\(pasteboardText)'")
            cacheLock.lock()
            cachedSelectedText = pasteboardText
            cachedFromAppPID = currentPID
            cacheLock.unlock()
            return pasteboardText
        }
        
        // 3. Fallback: use cache if same app (e.g. AX and pasteboard both failed this time)
        if !currentCache.isEmpty && currentCachePID == currentPID && !isNonAX {
            print("AccessibilityMonitor: Using cached text (fallback): '\(currentCache)'")
            return currentCache
        }
        
        // Mark this app as non-AX only when we have no cache for it
        if currentCachePID != currentPID || currentCache.isEmpty {
            cacheLock.lock()
            nonAXApps.insert(currentPID)
            cacheLock.unlock()
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
        
        // Retry with increasing delays — fast for normal apps, reliable for PDFs
        let retryDelays: [TimeInterval] = [0.05, 0.05, 0.1, 0.15]  // total max ~350ms
        var newContents = ""
        
        for (i, delay) in retryDelays.enumerated() {
            Thread.sleep(forTimeInterval: delay)
            newContents = pasteboard.string(forType: .string) ?? ""
            if !newContents.isEmpty {
                print("AccessibilityMonitor: Pasteboard got text on attempt \(i + 1)")
                break
            }
        }
        
        // Restore old pasteboard
        if let oldContents = oldContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pasteboard.clearContents()
                pasteboard.setString(oldContents, forType: .string)
            }
        }
        
        return newContents.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Selected text bounds
    
    /// Returns the screen-space bounding rect of the currently selected text, or nil if unavailable.
    func getSelectedTextBounds() -> CGRect? {
        guard hasAccessibilityPermission else { return nil }
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else { return nil }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        // Get focused element
        var focusedElementRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appRef,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )
        
        guard focusResult == .success, let focusedElement = focusedElementRef else {
            print("AccessibilityMonitor: Could not get focused element for bounds")
            return nil
        }
        
        let element = focusedElement as! AXUIElement
        
        // Get selected text range
        var selectedRangeRef: CFTypeRef?
        let rangeResult = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &selectedRangeRef
        )
        
        guard rangeResult == .success, let rangeValue = selectedRangeRef else {
            print("AccessibilityMonitor: Could not get selected text range")
            return nil
        }
        
        // Get bounds for the selected range
        var boundsRef: CFTypeRef?
        let boundsResult = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &boundsRef
        )
        
        guard boundsResult == .success, let boundsValue = boundsRef else {
            print("AccessibilityMonitor: Could not get bounds for selected text range")
            return nil
        }
        
        // Extract CGRect from AXValue
        var bounds = CGRect.zero
        if AXValueGetValue(boundsValue as! AXValue, .cgRect, &bounds) {
            // AX bounds use top-left origin; convert to bottom-left (Cocoa) coordinates
            if let screen = NSScreen.main {
                let screenHeight = screen.frame.height
                let cocoaY = screenHeight - bounds.origin.y - bounds.size.height
                let cocoaRect = CGRect(x: bounds.origin.x, y: cocoaY, width: bounds.size.width, height: bounds.size.height)
                print("AccessibilityMonitor: Selected text bounds (Cocoa): \(cocoaRect)")
                return cocoaRect
            }
            return bounds
        }
        
        return nil
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
