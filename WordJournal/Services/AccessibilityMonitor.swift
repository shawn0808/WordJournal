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
    private var lastSelectedText: String = ""
    
    private init() {
        // Silent check on init - don't prompt
        checkAccessibilityPermission(showPrompt: false)
    }
    
    func checkAccessibilityPermission(showPrompt: Bool = false) {
        if showPrompt {
            // Only show prompt when explicitly requested (e.g., from Preferences button)
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
            hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        } else {
            // Silent check - don't prompt, just check status
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false]
            hasAccessibilityPermission = AXIsProcessTrustedWithOptions(options as CFDictionary)
        }
    }
    
    func requestPermission() {
        // Explicitly request permission (will show prompt)
        checkAccessibilityPermission(showPrompt: true)
        // Re-check after potential permission grant
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.checkAccessibilityPermission(showPrompt: false)
            if self.hasAccessibilityPermission {
                self.startMonitoring()
            }
        }
    }
    
    func startMonitoring() {
        // Check permissions silently first
        checkAccessibilityPermission(showPrompt: false)
        
        guard hasAccessibilityPermission else {
            // Don't prompt here - user can grant via System Settings or Preferences button
            print("AccessibilityMonitor: No permissions - monitoring disabled")
            return
        }
        
        stopMonitoring()
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.pollSelectedText()
        }
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
        var selectedTextRef: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )
        
        if result == .success,
           let text = selectedTextRef as? String,
           !text.isEmpty,
           text != lastSelectedText {
            DispatchQueue.main.async { [weak self] in
                self?.selectedText = text
                self?.lastSelectedText = text
            }
        }
    }
    
    func getCurrentSelectedText() -> String {
        guard hasAccessibilityPermission else {
            print("AccessibilityMonitor: No permissions for getCurrentSelectedText")
            return ""
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("AccessibilityMonitor: No frontmost application")
            return ""
        }
        
        print("AccessibilityMonitor: Frontmost app: \(frontmostApp.localizedName ?? "Unknown") (PID: \(frontmostApp.processIdentifier))")
        
        // Try multiple methods to get selected text
        
        // Method 1: Try to get focused element first, then get selected text from it
        let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        
        // First, try to get the focused UI element
        var focusedElementRef: CFTypeRef?
        let focusResult = AXUIElementCopyAttributeValue(
            appRef,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElementRef
        )
        
        if focusResult == .success, let focusedElement = focusedElementRef {
            print("AccessibilityMonitor: Got focused element")
            
            // Try to get selected text from focused element
            var selectedTextRef: CFTypeRef?
            let result = AXUIElementCopyAttributeValue(
                focusedElement as! AXUIElement,
                kAXSelectedTextAttribute as CFString,
                &selectedTextRef
            )
            
            if result == .success, let text = selectedTextRef as? String, !text.isEmpty {
                print("AccessibilityMonitor: ✅ Got selected text from focused element: '\(text)'")
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                print("AccessibilityMonitor: Failed to get selected text from focused element. Result: \(result.rawValue)")
            }
        } else {
            print("AccessibilityMonitor: Failed to get focused element. Result: \(focusResult.rawValue)")
        }
        
        // Method 2: Try to get selected text directly from application
        var selectedTextRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )
        
        if result == .success, let text = selectedTextRef as? String, !text.isEmpty {
            print("AccessibilityMonitor: ✅ Got selected text from app: '\(text)'")
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            print("AccessibilityMonitor: Failed to get selected text from app. Result: \(result.rawValue)")
        }
        
        // Method 3: Try using pasteboard (copy selection)
        print("AccessibilityMonitor: Trying pasteboard method...")
        let text = getTextFromPasteboard()
        if !text.isEmpty {
            print("AccessibilityMonitor: ✅ Got text from pasteboard: '\(text)'")
            return text
        }
        
        print("AccessibilityMonitor: ❌ All methods failed to get selected text")
        return ""
    }
    
    private func getTextFromPasteboard() -> String {
        print("AccessibilityMonitor: Starting pasteboard method (Cmd+C simulation)")
        
        // Save current pasteboard contents
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        print("AccessibilityMonitor: Old pasteboard contents: '\(oldContents ?? "nil")'")
        
        // Clear pasteboard first to ensure we get fresh content
        pasteboard.clearContents()
        
        // Simulate Cmd+C to copy selection
        let source = CGEventSource(stateID: .hidSystemState)
        
        // Press Cmd+C (C key = 0x08)
        let cmdCDown = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: true)
        cmdCDown?.flags = .maskCommand
        let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 0x08, keyDown: false)
        cmdCUp?.flags = .maskCommand
        
        print("AccessibilityMonitor: Posting Cmd+C events...")
        cmdCDown?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.02) // Small delay between down and up
        cmdCUp?.post(tap: .cghidEventTap)
        
        // Wait for copy to complete
        Thread.sleep(forTimeInterval: 0.1)
        
        // Get the new pasteboard contents
        let newContents = pasteboard.string(forType: .string) ?? ""
        print("AccessibilityMonitor: New pasteboard contents: '\(newContents)'")
        
        // Restore old pasteboard contents
        if let oldContents = oldContents {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                pasteboard.clearContents()
                pasteboard.setString(oldContents, forType: .string)
                print("AccessibilityMonitor: Restored old pasteboard contents")
            }
        }
        
        let result = newContents.trimmingCharacters(in: .whitespacesAndNewlines)
        print("AccessibilityMonitor: Pasteboard method result: '\(result)'")
        return result
    }
}
