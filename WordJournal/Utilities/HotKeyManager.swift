//
//  HotKeyManager.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import AppKit

class HotKeyManager: ObservableObject {
    static let shared = HotKeyManager()
    
    @Published var hotKeyEnabled: Bool = true
    @Published var modifierFlags: NSEvent.ModifierFlags = [.command, .control]
    @Published var keyCode: UInt16 = 37 // 'L' key
    @Published var monitorActive: Bool = false // Track if event monitor is active
    
    private var eventMonitor: Any?
    private var activationHandler: (() -> Void)?
    
    private init() {
        print("HotKeyManager: Initialized")
        // Don't setup hotkey in init - wait for handler to be set
    }
    
    func setActivationHandler(_ handler: @escaping () -> Void) {
        print("HotKeyManager: setActivationHandler() called")
        activationHandler = handler
        // Setup hotkey after handler is set
        setupHotKey()
    }
    
    func triggerManually() {
        print("HotKeyManager: Manually triggered")
        activationHandler?()
    }
    
    func setupHotKey() {
        unregisterHotKey()
        
        guard hotKeyEnabled else { 
            print("HotKeyManager: Hotkey disabled")
            return 
        }
        
        guard activationHandler != nil else {
            print("HotKeyManager: WARNING - No activation handler set!")
            return
        }
        
        print("HotKeyManager: Setting up hotkey - KeyCode: \(keyCode), Expected Modifiers: Command+Control")
        
        // Use NSEvent global monitor for modern hotkey detection
        // Note: This requires accessibility permissions
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            // Get the modifier flags (only the ones we care about)
            let eventModifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            
            // Debug: log all Cmd+Control combinations
            if eventModifiers.contains(.command) && eventModifiers.contains(.control) {
                print("HotKeyManager: 🔍 Cmd+Control detected - KeyCode: \(event.keyCode), All Modifiers: \(event.modifierFlags.rawValue)")
            }
            
            // Check if we have exactly Command + Control (no other modifiers)
            let hasCommand = eventModifiers.contains(.command)
            let hasShift = eventModifiers.contains(.shift)
            let hasOption = eventModifiers.contains(.option)
            let hasControl = eventModifiers.contains(.control)
            
            // We want Command + Control, but NOT Shift or Option
            guard hasCommand && hasControl && !hasShift && !hasOption else {
                return
            }
            
            // Check if key code matches (L = 37)
            guard event.keyCode == self.keyCode else {
                if hasCommand && hasControl {
                    print("HotKeyManager: ⚠️ Wrong key - Expected: \(self.keyCode) (L), Got: \(event.keyCode)")
                }
                return
            }
            
            print("HotKeyManager: ✅✅✅ HOTKEY MATCHED! KeyCode: \(event.keyCode) (L), Modifiers: Cmd+Control")
            print("HotKeyManager: Calling activation handler...")
            
            // Call the activation handler
            DispatchQueue.main.async {
                print("HotKeyManager: Executing handler on main queue")
                self.activationHandler?()
            }
        }
        
        if eventMonitor == nil {
            monitorActive = false
            print("HotKeyManager: ❌❌❌ CRITICAL ERROR - Failed to create global event monitor!")
            print("HotKeyManager: This means accessibility permissions are NOT granted.")
            print("HotKeyManager: SOLUTION:")
            print("HotKeyManager: 1. Go to System Settings → Privacy & Security → Accessibility")
            print("HotKeyManager: 2. Find 'WordJournal' in the list and enable it ✅")
            print("HotKeyManager: 3. If WordJournal is not in the list, click '+' and add it")
            print("HotKeyManager: 4. RESTART the app after granting permissions")
        } else {
            monitorActive = true
            print("HotKeyManager: ✅✅✅ Global event monitor created successfully!")
            print("HotKeyManager: ✅ Listening for Cmd+Control+L (KeyCode: \(keyCode))")
            print("HotKeyManager: ✅ Monitor object: \(String(describing: eventMonitor))")
            print("HotKeyManager: ✅ Ready to detect hotkey!")
        }
    }
    
    func unregisterHotKey() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
            monitorActive = false
        }
    }
    
    deinit {
        unregisterHotKey()
    }
}
