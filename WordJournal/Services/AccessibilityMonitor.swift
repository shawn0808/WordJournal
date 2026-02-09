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
        guard hasAccessibilityPermission,
              let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return ""
        }
        
        let appRef = AXUIElementCreateApplication(frontmostApp.processIdentifier)
        var selectedTextRef: CFTypeRef?
        
        let result = AXUIElementCopyAttributeValue(
            appRef,
            kAXSelectedTextAttribute as CFString,
            &selectedTextRef
        )
        
        if result == .success,
           let text = selectedTextRef as? String {
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return ""
    }
}
