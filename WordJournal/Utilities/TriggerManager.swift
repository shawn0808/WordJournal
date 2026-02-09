//
//  TriggerManager.swift
//  WordJournal
//
//  Manages Shift+Click activation for word lookups
//

import AppKit

class TriggerManager: ObservableObject {
    static let shared = TriggerManager()
    
    @Published var monitorActive: Bool = false
    
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
        
        setupShiftClick()
    }
    
    private func setupShiftClick() {
        print("TriggerManager: Setting up Shift+Click detection")
        
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            
            // Check for Shift key held during click (only Shift, not other modifiers)
            let hasShift = modifiers.contains(.shift)
            let hasCommand = modifiers.contains(.command)
            let hasOption = modifiers.contains(.option)
            let hasControl = modifiers.contains(.control)
            
            if hasShift && !hasCommand && !hasOption && !hasControl {
                print("TriggerManager: ✅✅✅ SHIFT+CLICK DETECTED!")
                
                // Small delay to let things settle
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.activationHandler?()
                }
            }
        }
        
        if mouseMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ CRITICAL ERROR - Failed to create click monitor!")
            print("TriggerManager: Accessibility permissions may not be granted.")
        } else {
            monitorActive = true
            print("TriggerManager: ✅✅✅ Shift+Click monitor active!")
            print("TriggerManager: ✅ Select text, then Shift+Click to trigger lookup")
        }
    }
    
    func unregisterTriggers() {
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
