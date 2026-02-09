//
//  MenuBarView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI

struct MenuBarView: View {
    let showJournal: () -> Void
    let showPreferences: () -> Void
    @ObservedObject var journalStorage: JournalStorage
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Stats
            VStack(alignment: .leading, spacing: 4) {
                Text("Word Journal")
                    .font(.headline)
                
                Text("\(journalStorage.entries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            
            Divider()
            
            // Menu items
            Button(action: showJournal) {
                Label("Open Journal", systemImage: "book")
            }
            .buttonStyle(.plain)
            .keyboardShortcut("j", modifiers: .command)
            
            Button(action: showPreferences) {
                Label("Preferences", systemImage: "gear")
            }
            .buttonStyle(.plain)
            .keyboardShortcut(",", modifiers: .command)
            
            Divider()
            
            // Test button for debugging
            Button("Test Lookup") {
                print("MenuBarView: Test button clicked - triggering lookup manually")
                TriggerManager.shared.triggerManually()
            }
            .buttonStyle(.plain)
            
            Divider()
            
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.plain)
            .keyboardShortcut("q", modifiers: .command)
        }
        .frame(width: 200)
        .padding(.vertical, 8)
    }
}
