//
//  TriggerManager.swift
//  WordJournal
//
//  Manages activation triggers for word lookups
//

import AppKit

enum TriggerMethod: String, CaseIterable {
    case shiftClick = "shiftClick"
    case optionClick = "optionClick"
    case doubleOption = "doubleOption"
    
    var displayName: String {
        switch self {
        case .shiftClick: return "Shift + Click"
        case .optionClick: return "Option + Click"
        case .doubleOption: return "Double-tap Option (⌥)"
        }
    }
    
    var description: String {
        switch self {
        case .shiftClick: return "Select text, then hold Shift and click to look it up"
        case .optionClick: return "Select text, then hold Option (⌥) and click to look it up"
        case .doubleOption: return "Select text, then quickly press Option (⌥) twice to look it up"
        }
    }
    
    var icon: String {
        switch self {
        case .shiftClick: return "cursorarrow.click"
        case .optionClick: return "cursorarrow.click"
        case .doubleOption: return "option"
        }
    }
}

class TriggerManager: ObservableObject {
    static let shared = TriggerManager()
    
    @Published var monitorActive: Bool = false
    @Published var triggerMethod: TriggerMethod {
        didSet {
            UserDefaults.standard.set(triggerMethod.rawValue, forKey: "triggerMethod")
            if activationHandler != nil {
                setupTriggers()
            }
        }
    }
    
    private var mouseMonitor: Any?
    private var keyMonitor: Any?
    private var activationHandler: (() -> Void)?
    
    /// The screen location where the last trigger was activated (e.g. Shift+Click position)
    var lastTriggerLocation: NSPoint?
    
    // Double-tap Option detection state
    private var lastOptionPressTime: TimeInterval = 0
    private let doubleTapThreshold: TimeInterval = 0.4  // 400ms window for double-tap
    private var optionWasPartOfCombo = false
    
    // Option+Click pre-trigger snapshot (captured on Option key down)
    private var optionPreTriggerText: String = ""
    private var optionPreTriggerPID: pid_t = 0
    
    private init() {
        let saved = UserDefaults.standard.string(forKey: "triggerMethod") ?? TriggerMethod.shiftClick.rawValue
        self.triggerMethod = TriggerMethod(rawValue: saved) ?? .shiftClick
        print("TriggerManager: Initialized with trigger method: \(triggerMethod.displayName)")
    }
    
    func consumeOptionPreTriggerTextForFrontmostApp() -> String {
        guard let frontmost = NSWorkspace.shared.frontmostApplication else { return "" }
        let pid = frontmost.processIdentifier
        guard optionPreTriggerPID == pid else { return "" }
        let text = optionPreTriggerText.trimmingCharacters(in: .whitespacesAndNewlines)
        optionPreTriggerText = ""
        optionPreTriggerPID = 0
        return text
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
        
        switch triggerMethod {
        case .shiftClick:
            setupShiftClick()
        case .optionClick:
            setupOptionClick()
        case .doubleOption:
            setupDoubleOption()
        }
    }
    
    // MARK: - Shift+Click
    
    private func setupShiftClick() {
        print("TriggerManager: Setting up Shift+Click detection")
        
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return }
            
            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])
            
            let hasShift = modifiers.contains(.shift)
            let hasCommand = modifiers.contains(.command)
            let hasOption = modifiers.contains(.option)
            let hasControl = modifiers.contains(.control)
            
            if hasShift && !hasCommand && !hasOption && !hasControl {
                print("TriggerManager: ✅✅✅ SHIFT+CLICK DETECTED!")
                // Capture the click location — this is exactly where the word is
                self.lastTriggerLocation = NSEvent.mouseLocation
                DispatchQueue.main.async {
                    self.activationHandler?()
                }
            }
        }
        
        if mouseMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ Failed to create Shift+Click monitor")
        } else {
            monitorActive = true
            print("TriggerManager: ✅ Shift+Click monitor active")
        }
    }

    // MARK: - Option+Click

    private func setupOptionClick() {
        print("TriggerManager: Setting up Option+Click detection")
        
        // Capture selection as soon as Option is pressed, before the click can alter selection.
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            guard let self = self else { return }
            let optionPressed = event.modifierFlags.contains(.option)
            let otherModifiers = event.modifierFlags.intersection([.command, .shift, .control])
            guard optionPressed && otherModifiers.isEmpty else { return }
            
            let snapshot = AccessibilityMonitor.shared.getCurrentSelectedText()
            self.optionPreTriggerText = snapshot
            self.optionPreTriggerPID = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
        }

        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
            guard let self = self else { return }

            let modifiers = event.modifierFlags.intersection([.command, .shift, .option, .control])

            let hasOption = modifiers.contains(.option)
            let hasCommand = modifiers.contains(.command)
            let hasShift = modifiers.contains(.shift)
            let hasControl = modifiers.contains(.control)
            if hasOption && !hasCommand && !hasShift && !hasControl {
                print("TriggerManager: ✅✅✅ OPTION+CLICK DETECTED!")
                self.lastTriggerLocation = NSEvent.mouseLocation
                DispatchQueue.main.async {
                    self.activationHandler?()
                }
            }
        }

        if mouseMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ Failed to create Option+Click monitor")
        } else {
            monitorActive = true
            print("TriggerManager: ✅ Option+Click monitor active")
        }
    }
    
    // MARK: - Double-tap Option
    
    private func setupDoubleOption() {
        print("TriggerManager: Setting up Double-tap Option detection")
        
        // Reset state
        lastOptionPressTime = 0
        optionWasPartOfCombo = false
        
        // Monitor flagsChanged to detect Option key presses/releases
        keyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged, .keyDown]) { [weak self] event in
            guard let self = self else { return }
            
            if event.type == .keyDown {
                // Any regular key pressed while Option is held = combo, not a standalone Option tap
                if event.modifierFlags.contains(.option) {
                    self.optionWasPartOfCombo = true
                }
                return
            }
            
            // flagsChanged event
            let optionPressed = event.modifierFlags.contains(.option)
            let otherModifiers = event.modifierFlags.intersection([.command, .shift, .control])
            
            // If other modifiers are involved, it's a combo
            if !otherModifiers.isEmpty {
                self.optionWasPartOfCombo = true
                return
            }
            
            if optionPressed {
                // Option key pressed down — record but don't act yet
                // Mark as not a combo (will be set to true if another key is pressed)
                self.optionWasPartOfCombo = false
            } else {
                // Option key released
                // Only count as a standalone Option tap if no other keys were pressed
                guard !self.optionWasPartOfCombo else {
                    self.optionWasPartOfCombo = false
                    return
                }
                
                let now = ProcessInfo.processInfo.systemUptime
                let elapsed = now - self.lastOptionPressTime
                
                if elapsed < self.doubleTapThreshold && self.lastOptionPressTime > 0 {
                    // Double-tap detected!
                    print("TriggerManager: ✅✅✅ DOUBLE-TAP OPTION DETECTED! (interval: \(String(format: "%.0f", elapsed * 1000))ms)")
                    self.lastOptionPressTime = 0  // Reset to prevent triple-tap
                    self.lastTriggerLocation = NSEvent.mouseLocation
                    DispatchQueue.main.async {
                        self.activationHandler?()
                    }
                } else {
                    // First tap — record time
                    self.lastOptionPressTime = now
                }
            }
        }
        
        if keyMonitor == nil {
            monitorActive = false
            print("TriggerManager: ❌ Failed to create Double-tap Option monitor")
        } else {
            monitorActive = true
            print("TriggerManager: ✅ Double-tap Option monitor active")
        }
    }
    
    func unregisterTriggers() {
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
            mouseMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
        monitorActive = false
    }
    
    deinit {
        unregisterTriggers()
    }
}
