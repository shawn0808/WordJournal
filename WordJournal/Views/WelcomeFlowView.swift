//
//  WelcomeFlowView.swift
//  WordJournal
//
//  First-run welcome flow: intro, accessibility, shortcut, tip.
//

import SwiftUI
import AppKit

// MARK: - GIF Helpers
// Add welcome-step3.gif and welcome-step4.gif to the project (e.g. Resources folder)
// and include in the app target. If present, they'll show as live demos in steps 3 and 4.

private func gifExists(_ name: String) -> Bool {
    Bundle.main.url(forResource: name, withExtension: "gif") != nil
}

private let hasCompletedWelcomeKey = "hasCompletedWelcome"

// MARK: - UserDefaults Helper

enum WelcomeFlowStorage {
    static var hasCompletedWelcome: Bool {
        get { UserDefaults.standard.bool(forKey: hasCompletedWelcomeKey) }
        set { UserDefaults.standard.set(newValue, forKey: hasCompletedWelcomeKey) }
    }
    
    static func resetForTesting() {
        UserDefaults.standard.removeObject(forKey: hasCompletedWelcomeKey)
    }
}

// MARK: - Welcome Flow View

struct WelcomeFlowView: View {
    let onComplete: () -> Void
    let onOpenJournal: () -> Void
    
    @EnvironmentObject var triggerManager: TriggerManager
    @ObservedObject var accessibilityMonitor = AccessibilityMonitor.shared
    
    @State private var currentStep = 1
    private let totalSteps = 4
    
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var body: some View {
        VStack(spacing: 0) {
            // Step indicator
            stepIndicator
                .padding(.top, 24)
                .padding(.bottom, 20)
            
            // Content
            Group {
                switch currentStep {
                case 1: step1Welcome
                case 2: step2Accessibility
                case 3: step3Shortcut
                case 4: step4Tip
                default: step1Welcome
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, 32)
            
            // Bottom actions
            bottomActions
                .padding(.bottom, 28)
                .padding(.horizontal, 32)
        }
        .frame(width: 480, height: 600)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    // MARK: - Step Indicator
    
    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(1...totalSteps, id: \.self) { step in
                Circle()
                    .fill(step <= currentStep ? accentBlue : Color.secondary.opacity(0.25))
                    .frame(width: 6, height: 6)
            }
        }
    }
    
    // MARK: - Step 1: Welcome
    
    private var step1Welcome: some View {
        VStack(spacing: 32) {
            Image("MenuBarIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)
            
            Text("Word Journal")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            
            Text("Look up words instantly from anywhere — select text, trigger a lookup, and build your vocabulary.")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.top, 24)
    }
    
    // MARK: - Step 2: Accessibility
    
    private var step2Accessibility: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "hand.point.up.left.and.text")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(accentBlue)
            
            Text("Accessibility Permission")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            Text("Word Journal needs access to read selected text and listen for your shortcut in other apps.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if accessibilityMonitor.hasAccessibilityPermission {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Permission granted")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.green)
                }
                .padding(.top, 4)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Button(action: {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }) {
                        Label("Open System Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentBlue)
                    
                    Button(action: { AccessibilityMonitor.shared.requestPermission() }) {
                        Text("Request Permission")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.top, 4)
            }
            
            Spacer()
        }
        .padding(.top, 12)
    }
    
    // MARK: - Step 3: Shortcut
    
    private var step3Shortcut: some View {
        VStack(alignment: .leading, spacing: 20) {
            Image(systemName: "cursorarrow.click")
                .font(.system(size: 40, weight: .thin))
                .foregroundColor(accentBlue)
            
            Text("How do you want to trigger lookups?")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            
            VStack(spacing: 8) {
                ForEach(TriggerMethod.allCases, id: \.rawValue) { method in
                    let isSelected = triggerManager.triggerMethod == method
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(isSelected ? accentBlue : .secondary)
                            .font(.system(size: 16))
                            .padding(.top, 2)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(method.displayName)
                                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                            Text(method.description)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(isSelected ? accentBlue.opacity(0.08) : Color.clear)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? accentBlue.opacity(0.4) : Color.clear, lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            triggerManager.triggerMethod = method
                        }
                    }
                }
            }
            
            Spacer()
        }
        .padding(.top, 12)
    }
    
    // MARK: - Step 4: Tip
    
    private var step4Tip: some View {
        VStack(spacing: 24) {
            if gifExists("welcome-step4") {
                AnimatedGifView(name: "welcome-step4")
                    .frame(width: 416, height: 182)
                    .cornerRadius(8)
            } else {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 48, weight: .thin))
                    .foregroundColor(accentBlue)
            }
            
            Text("You're all set")
                .font(.system(size: 22, weight: .bold, design: .rounded))
            
            VStack(alignment: .leading, spacing: 12) {
                tipRow(icon: "menubar.rectangle", text: "Click the menu bar icon to search words directly")
                tipRow(icon: "hand.point.up.left", text: lookupTipText)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding(.top, 20)
    }
    
    /// Dynamic tip text based on user's selected trigger method
    private var lookupTipText: String {
        let method = triggerManager.triggerMethod
        switch method {
        case .shiftClick:
            return "Select a word as you read, and hold Shift and click to look it up conveniently"
        case .optionClick:
            return "Select a word as you read, and hold Option and click to look it up conveniently"
        case .doubleOption:
            return "Select a word as you read, and double-tap Option to look it up conveniently"
        }
    }
    
    private func tipRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(accentBlue)
                .frame(width: 24, alignment: .center)
            Text(text)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        HStack(spacing: 12) {
            if currentStep > 1 {
                Button("Back") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        currentStep -= 1
                    }
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if currentStep == 2 && !accessibilityMonitor.hasAccessibilityPermission {
                Button("Remind Me Later") {
                    advanceOrComplete()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }
            
            if currentStep < totalSteps {
                Button(currentStep == 1 ? "Get Started" : "Continue") {
                    advanceOrComplete()
                }
                .buttonStyle(.borderedProminent)
                .tint(accentBlue)
            } else {
                HStack(spacing: 10) {
                    Button("Open Word Journal") {
                        completeAndOpenJournal()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(accentBlue)
                    
                    Button("Done") {
                        complete()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .font(.system(size: 13, weight: .medium))
    }
    
    private func advanceOrComplete() {
        if currentStep == 2 && !accessibilityMonitor.hasAccessibilityPermission {
            // Re-check permission; user might have enabled it
            accessibilityMonitor.checkAccessibilityPermission(showPrompt: false)
        }
        
        if currentStep < totalSteps {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentStep += 1
            }
        }
    }
    
    private func complete() {
        WelcomeFlowStorage.hasCompletedWelcome = true
        AccessibilityMonitor.shared.startMonitoring()
        onComplete()
    }
    
    private func completeAndOpenJournal() {
        WelcomeFlowStorage.hasCompletedWelcome = true
        AccessibilityMonitor.shared.startMonitoring()
        onComplete()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            onOpenJournal()
        }
    }
}
