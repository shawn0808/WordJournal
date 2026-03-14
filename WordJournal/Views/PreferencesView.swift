//
//  PreferencesView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject var triggerManager: TriggerManager
    @ObservedObject var accessibilityMonitor = AccessibilityMonitor.shared
    @ObservedObject var aiConfig = AIConfigStore.shared
    
    @State private var apiKeyInput: String = ""
    @State private var hasApiKey = false
    
    // Consistent accent color
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var body: some View {
        TabView {
            // General Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("General Settings")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                // Accessibility Permission
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accessibility Permission")
                        .font(.system(size: 14, weight: .semibold))
                    
                    if accessibilityMonitor.hasAccessibilityPermission {
                        Label("Permission granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 13))
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Permission required", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 13))
                            
                            Text("Word Journal needs accessibility permissions to detect text selections and gestures.")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                Button("Request Permission") {
                                    AccessibilityMonitor.shared.requestPermission()
                                }
                                .buttonStyle(.bordered)
                                .tint(accentBlue)
                                
                                Button("Open System Settings") {
                                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                        NSWorkspace.shared.open(url)
                                    }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Activation Method
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activation Method")
                        .font(.system(size: 14, weight: .semibold))
                    
                    // Trigger method picker
                    ForEach(TriggerMethod.allCases, id: \.rawValue) { method in
                        let isSelected = triggerManager.triggerMethod == method
                        
                        HStack(spacing: 10) {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? accentBlue : .secondary)
                                .font(.title3)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(method.displayName)
                                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                                Text(method.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(isSelected ? accentBlue.opacity(0.08) : Color.clear)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                triggerManager.triggerMethod = method
                            }
                        }
                    }
                    
                    // Show monitor status
                    if triggerManager.monitorActive {
                        Label("Trigger monitor active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 11))
                            .padding(.top, 4)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Trigger monitor inactive", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.system(size: 11))
                            
                            Text("Accessibility permissions required.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // AI Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Insights")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                
                // Billing notice
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(accentBlue)
                    Text("Most providers require a credit card or account top-up before use, even for \"free\" tiers. Check each provider's current terms.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
                
                Toggle(isOn: $aiConfig.isEnabled) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable AI insights in definition popup")
                            .font(.system(size: 14, weight: .medium))
                        Text("Show synonyms, antonyms, and plain-language explanation")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .tint(accentBlue)
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Provider")
                        .font(.system(size: 14, weight: .semibold))
                    
                    Picker("", selection: $aiConfig.provider) {
                        ForEach(AIProvider.allCases) { provider in
                            Text(provider.displayName).tag(provider)
                        }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("API Key")
                        .font(.system(size: 14, weight: .semibold))
                    
                    if hasApiKey {
                        HStack(spacing: 8) {
                            Text("••••••••••••")
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(.secondary)
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.secondary.opacity(0.1))
                                .cornerRadius(6)
                            Button("Clear") {
                                _ = aiConfig.clearApiKey()
                                hasApiKey = false
                                apiKeyInput = ""
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        SecureField("Paste your API key", text: $apiKeyInput)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                if !apiKeyInput.isEmpty {
                                    _ = aiConfig.setApiKey(apiKeyInput)
                                    hasApiKey = true
                                }
                            }
                        Button("Save") {
                            if !apiKeyInput.isEmpty {
                                _ = aiConfig.setApiKey(apiKeyInput)
                                hasApiKey = true
                            }
                        }
                        .buttonStyle(.bordered)
                        .tint(accentBlue)
                    }
                    
                    Text("Your key is stored locally and never sent except to your chosen AI provider. Each provider needs its own key—clear and re-enter when switching.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    
                    if aiConfig.provider == .openAI {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("With OpenAI, Word of the Day cards can show AI-generated background images.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                            Button("Clear Word of the Day image cache") {
                                WordImageCache.clearAll()
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Group {
                        switch aiConfig.provider {
                        case .openAI:
                            Link("Get API key: platform.openai.com", destination: URL(string: "https://platform.openai.com/api-keys")!)
                        case .gemini:
                            Link("Get API key: aistudio.google.com (free tier)", destination: URL(string: "https://aistudio.google.com/apikey")!)
                        case .deepSeek:
                            Link("Get API key: platform.deepseek.com (free tier)", destination: URL(string: "https://platform.deepseek.com")!)
                        }
                    }
                    .font(.system(size: 10))
                }
                
                Spacer()
            }
            .padding(20)
            .tabItem {
                Label("AI", systemImage: "sparkles")
            }
            .onAppear {
                hasApiKey = aiConfig.apiKey != nil
            }
            
            // About Tab
            VStack(spacing: 20) {
                Image(systemName: "book.closed")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(accentBlue)
                
                Text("Word Journal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("A macOS menu bar app for\ndictionary lookups and word journaling.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
                
                Button("Show Welcome Again") {
                    WelcomeFlowStorage.hasCompletedWelcome = false
                    guard let appDelegate = AppDelegate.shared else { return }
                    appDelegate.preferencesWindow?.close()
                    appDelegate.preferencesWindow = nil
                    // Defer so the preferences window closes before showing welcome
                    DispatchQueue.main.async {
                        appDelegate.showWelcomeFlow()
                    }
                }
                .buttonStyle(.bordered)
                .tint(accentBlue)
                .padding(.top, 8)
            }
            .padding(20)
            .tabItem {
                Label("About", systemImage: "info.circle")
            }
        }
        .frame(width: 500, height: 400)
    }
    
    private func formatModifiers(_ modifiers: NSEvent.ModifierFlags) -> String {
        var parts: [String] = []
        if modifiers.contains(.command) { parts.append("⌘") }
        if modifiers.contains(.shift) { parts.append("⇧") }
        if modifiers.contains(.option) { parts.append("⌥") }
        if modifiers.contains(.control) { parts.append("⌃") }
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt16) -> String {
        // Simple mapping for common keys
        let mapping: [UInt16: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G",
            6: "Z", 7: "X", 8: "C", 9: "V", 11: "B", 12: "Q",
            13: "W", 14: "E", 15: "R", 16: "Y", 17: "T", 37: "L"
        ]
        return mapping[keyCode] ?? "Key"
    }
}
