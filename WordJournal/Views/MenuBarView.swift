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
    let onLookupWord: (String) -> Void
    @ObservedObject var journalStorage: JournalStorage
    @Environment(\.dismiss) private var dismiss
    @State private var lookupText = ""
    @FocusState private var isLookupFocused: Bool
    
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
            
            // Lookup field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                TextField("Look up a word...", text: $lookupText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .focused($isLookupFocused)
                    .onSubmit {
                        let word = lookupText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !word.isEmpty else { return }
                        lookupText = ""
                        dismiss()
                        onLookupWord(word)
                    }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            
            Divider()
            
            // Menu items
            VStack(alignment: .leading, spacing: 2) {
                menuButton(title: "Open Journal", icon: "book.fill", shortcut: "⌘J") {
                    dismiss()
                    showJournal()
                }
                
                menuButton(title: "Preferences", icon: "gearshape", shortcut: "⌘,") {
                    dismiss()
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
        .frame(width: 240)
        .background(KeyboardShortcutHandler(
            onCmdJ: {
                dismiss()
                showJournal()
            },
            onCmdComma: {
                dismiss()
                showPreferences()
            },
            onCmdQ: {
                NSApplication.shared.terminate(nil)
            }
        ))
        .onAppear {
            // Auto-focus the lookup field when the popover opens
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isLookupFocused = true
            }
        }
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

// MARK: - Keyboard Shortcut Handler

struct KeyboardShortcutHandler: NSViewRepresentable {
    let onCmdJ: () -> Void
    let onCmdComma: () -> Void
    let onCmdQ: () -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = KeyboardShortcutView()
        view.onCmdJ = onCmdJ
        view.onCmdComma = onCmdComma
        view.onCmdQ = onCmdQ
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let view = nsView as? KeyboardShortcutView {
            view.onCmdJ = onCmdJ
            view.onCmdComma = onCmdComma
            view.onCmdQ = onCmdQ
        }
    }
}

class KeyboardShortcutView: NSView {
    var onCmdJ: (() -> Void)?
    var onCmdComma: (() -> Void)?
    var onCmdQ: (() -> Void)?
    
    private var monitor: Any?
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        if window != nil && monitor == nil {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard event.modifierFlags.contains(.command) else { return event }
                
                switch event.charactersIgnoringModifiers?.lowercased() {
                case "j":
                    self?.onCmdJ?()
                    return nil
                case ",":
                    self?.onCmdComma?()
                    return nil
                case "q":
                    self?.onCmdQ?()
                    return nil
                default:
                    return event
                }
            }
        } else if window == nil, let monitor = monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
    }
    
    deinit {
        if let monitor = monitor {
            NSEvent.removeMonitor(monitor)
        }
    }
}
