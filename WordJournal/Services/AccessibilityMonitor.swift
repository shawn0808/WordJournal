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
    
    private var timer: Timer?
    private var cachedSelectedText: String = ""
    
    private init() {
        // Silent check on init - don't prompt
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
        
        // Poll every 0.3 seconds for selected text
        timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.pollSelectedText()
        }
        
        print("AccessibilityMonitor: ✅ Polling started - monitoring text selection")
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func pollSelectedText() {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return
        }
        
        let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        
        // Try focused element first
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
            
            if result == .success,
               let text = selectedTextRef as? String,
               !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed != cachedSelectedText {
                    cachedSelectedText = trimmed
                    DispatchQueue.main.async { [weak self] in
                        self?.selectedText = trimmed
                    }
                    print("AccessibilityMonitor: 📝 Cached selected text: '\(trimmed)'")
                }
                return
            }
        }
        
        // Try app-level as fallback
        var selectedTextRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )
        
        if result == .success,
           let text = selectedTextRef as? String,
           !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed != cachedSelectedText {
                cachedSelectedText = trimmed
                DispatchQueue.main.async { [weak self] in
                    self?.selectedText = trimmed
                }
                print("AccessibilityMonitor: 📝 Cached selected text: '\(trimmed)'")
            }
        }
    }
    
    /// Returns the most recently selected text (cached by the polling timer).
    /// This is reliable because it captures the text BEFORE any click deselects it.
    func getCurrentSelectedText() -> String {
        checkAccessibilityPermission(showPrompt: false)
        
        guard hasAccessibilityPermission else {
            print("AccessibilityMonitor: No permissions for getCurrentSelectedText")
            return ""
        }
        
        // Return the cached selected text from the polling timer.
        // This is the key fix: we return what was selected BEFORE the click,
        // not what's selected now (which may be nothing after a click).
        let text = cachedSelectedText
        print("AccessibilityMonitor: Returning cached text: '\(text)'")
        
        if !text.isEmpty {
            return text
        }
        
        // If cache is empty, try reading live as a last resort
        print("AccessibilityMonitor: Cache empty, trying live read...")
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return ""
        }
        
        let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        
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
            
            if result == .success, let liveText = selectedTextRef as? String, !liveText.isEmpty {
                print("AccessibilityMonitor: ✅ Got live text: '\(liveText)'")
                return liveText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        print("AccessibilityMonitor: ❌ No text available")
        return ""
    }
    
    /// Clear the cached text after a successful lookup
    func clearCache() {
        cachedSelectedText = ""
        selectedText = ""
    }
}
