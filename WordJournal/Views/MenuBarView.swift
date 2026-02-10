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
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 2) {
                Text("Word Journal")
                    .font(.headline)
                
                Text("\(journalStorage.entries.count) entries")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            Divider()
            
            // Menu items
            VStack(alignment: .leading, spacing: 2) {
                menuButton(title: "Open Journal", icon: "book.fill", shortcut: "⌘J") {
                    showJournal()
                }
                
                menuButton(title: "Preferences", icon: "gearshape", shortcut: "⌘,") {
                    showPreferences()
                }
            }
            .padding(.vertical, 4)
            
            Divider()
            
            // Quit
            menuButton(title: "Quit Word Journal", icon: "power", shortcut: "⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 220)
    }
    
    @ViewBuilder
    private func menuButton(title: String, icon: String, shortcut: String?, action: @escaping () -> Void) -> some View {
        HoverButton(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .frame(width: 16, alignment: .center)
                
                Text(title)
                
                Spacer()
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
        }
    }
}

// MARK: - Hover Button

struct HoverButton<Content: View>: View {
    let action: () -> Void
    let content: () -> Content
    
    @State private var isHovered = false
    
    init(action: @escaping () -> Void, @ViewBuilder content: @escaping () -> Content) {
        self.action = action
        self.content = content
    }
    
    var body: some View {
        Button(action: action) {
            content()
                .foregroundColor(isHovered ? .white : .primary)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isHovered ? Color.accentColor : Color.clear)
                        .padding(.horizontal, 4)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
