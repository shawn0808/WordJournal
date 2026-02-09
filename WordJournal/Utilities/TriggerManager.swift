//
//  TriggerManager.swift
//  WordJournal
//
//  Manages both keyboard shortcuts and mouse gestures (triple-click)
//

import AppKit

enum TriggerMode: String, CaseIterable {
    case keyboard = "Keyboard Shortcut"
    case threeFingerTap = "3-Finger Tap"
    case controlClick = "Control+Click"
    case both = "Both"
}

class TriggerManager: ObservableObject {
    static let shared = TriggerManager()
    
    @Published var triggerMode: TriggerMode = .controlClick
    @Published var hotKeyEnabled: Bool = true
    @Published var modifierFlags: NSEvent.ModifierFlags = [.command, .shift, .option]
    @Published var keyCode: UInt16 = 2 // 'D' key
    @Published var monitorActive: Bool = false
    
    private var keyboardMonitor: Any?
    private var mouseMonitor: Any?
    private var activationHandler: (() -> Void)?
    
    private init() {
        print("TriggerManager: Initialized")
    }
    
    func setActivationHandler(_ handler: @escaping () -> Void) {
        print("TriggerManager: setActivationHandler() called")
        activationHandler = handler
        setupTriggers()
    }
    
    func triggerManually() {
        print("TriggerManager: Manually triggered")
        activationHandler?()
    }
    
    func setupTriggers() {
        unregisterTriggers()
        
        guard activationHandler != nil else {
            print("TriggerManager: WARNING - No activation handler set!")
            return
        }
        
        switch triggerMode {
        case .keyboard:
            setupKeyboardShortcut()
        case .threeFingerTap:
            setupThreeFingerTap()
        case .controlClick:
            setupControlClick()
        case .both:
            setupKeyboardShortcut()
            setupThreeFingerTap()
        }
    }
    
    private func setupKeyboardShortcut() {
        guard hotKeyEnabled else {
            print("TriggerManager: Keyboard shortcut disabled")
            return
        }
        
        print("TriggerManager: Setting up keyboard shortcut - KeyCode: \(keyCode), Modifiers: Cmd+Shift+Option")
        
        keyboardMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            let eventModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            
            if eventModifiers.contains(.command) && eventModifiers.contains(.shift) && eventModifiers.contains(.option) {
                print("TriggerManager: 🔍 Cmd+Shift+Option detected - KeyCode: \(event.keyCode)")
            }
            
            let hasCommand = eventModifiers.contains(.command)
            let hasShift = eventModifiers.contains(.shift)
            let hasOption = eventModifiers.contains(.option)
            let hasControl = eventModifiers.contains(.control)
            
            guard hasCommand && hasShift && hasOption && !hasControl else {
                return
            }
            
            guard event.keyCode == self.keyCode else {
                return
            }
            
            print("TriggerManager: ✅ KEYBOARD SHORTCUT MATCHED!")
            DispatchQueue.main.async {
                self.activationHandler?()
            }
        }
        
        if keyboardMonitor != nil {
            print("TriggerManager: ✅ Keyboard shortcut monitor active")
        }
    }
    
    private func setupThreeFingerTap() {
        print("TriggerManager: Setting up 3-finger tap detection")
        print("TriggerManager: Note - macOS 3-finger tap triggers Force Touch/Look Up by default")
        print("TriggerManager: Recommend using Control+Click mode instead for reliability")
        
        // Monitor for gesture events
        // Note: 3-finger tap is hard to detect reliably because macOS uses it for "Look Up & Data Detectors"
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.gesture, .smartMagnify, .pressure]) { [weak self] event in
            guard let self = self else { return }
            
            print("TriggerManager: Gesture event detected - type: \(event.type.rawValue)")
            print("TriggerManager: ✅ 3-finger tap detected!")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.activationHandler?()
            }
        }
        
        if mouseMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ Failed to create gesture monitor")
        } else {
            monitorActive = true
            print("TriggerManager: ✅ 3-finger tap monitor active (experimental)")
        }
    }
    
    private func setupControlClick() {
        print("TriggerManager: Setting up Control+Click detection")
        
        // Monitor for Control+Click (right-click equivalent)
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            let modifiers = event.modifierFlags
            
            // Check for Control key held during click
            if modifiers.contains(.control) && event.type == .leftMouseDown {
                print("TriggerManager: ✅✅✅ CONTROL+CLICK DETECTED!")
                
                // Small delay to ensure text selection is complete
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.activationHandler?()
                }
            }
            
            // Also detect right-click (which is often Control+Click on trackpad)
            if event.type == .rightMouseDown {
                print("TriggerManager: ✅✅✅ RIGHT-CLICK DETECTED!")
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    self.activationHandler?()
                }
            }
        }
        
        if mouseMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ CRITICAL ERROR - Failed to create click monitor!")
        } else {
            monitorActive = true
            print("TriggerManager: ✅✅✅ Control+Click monitor active!")
            print("TriggerManager: ✅ Control+Click or Right-Click on selected text to trigger")
        }
    }
    
    func unregisterTriggers() {
        if let monitor = keyboardMonitor {
            NSEvent.removeMonitor(monitor)
            keyboardMonitor = nil
        }
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        monitorActive = false
    }
    
    deinit {
        unregisterTriggers()
    }
}
