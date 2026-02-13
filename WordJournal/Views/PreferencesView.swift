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
            
            // About Tab
            VStack(spacing: 16) {
                Image(systemName: "book.closed")
                    .font(.system(size: 56, weight: .thin))
                    .foregroundColor(accentBlue)
                
                Text("Word Journal")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                
                Text("Version 1.0")
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                Text("A macOS menu bar app for\ndictionary lookups and word journaling.")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .lineSpacing(3)
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
