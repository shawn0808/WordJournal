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
    
    var body: some View {
        TabView {
            // General Tab
            VStack(alignment: .leading, spacing: 20) {
                Text("General Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Accessibility Permission
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accessibility Permission")
                        .font(.headline)
                    
                    if accessibilityMonitor.hasAccessibilityPermission {
                        Label("Permission granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Permission required", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            
                            Text("Word Journal needs accessibility permissions to detect text selections and gestures.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack {
                                Button("Request Permission") {
                                    AccessibilityMonitor.shared.requestPermission()
                                }
                                .buttonStyle(.bordered)
                                
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
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Shift+Click to lookup", systemImage: "cursorarrow.click")
                            .foregroundColor(.blue)
                        Text("Select text, then Shift+Click to see the definition")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Simple: select a word, hold Shift, click!")
                            .font(.caption2)
                            .foregroundColor(.green)
                    }
                    
                    // Show monitor status
                    if triggerManager.monitorActive {
                        Label("Trigger monitor active", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Trigger monitor inactive", systemImage: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Text("Accessibility permissions required.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .tabItem {
                Label("General", systemImage: "gear")
            }
            
            // About Tab
            VStack(spacing: 20) {
                Image(systemName: "book.closed")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)
                
                Text("Word Journal")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Version 1.0")
                    .foregroundColor(.secondary)
                
                Text("A macOS menu bar app for dictionary lookups and word journaling.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .padding()
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
