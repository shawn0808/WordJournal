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
    @ObservedObject var dictionaryService = DictionaryService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var lookupText = ""
    @FocusState private var isLookupFocused: Bool
    
    // Accent color consistent with the rest of the app
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // MARK: - Header
            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Word Journal")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                    
                    HStack(spacing: 4) {
                        Text("\(journalStorage.entries.count)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .frame(minWidth: 22, minHeight: 22)
                            .background(Circle().fill(accentBlue.opacity(0.8)))
                        Text("words saved")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            
            // MARK: - Lookup field
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 12))
                
                TextField("Look up a word...", text: $lookupText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .focused($isLookupFocused)
                    .onSubmit {
                        let word = lookupText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !word.isEmpty else { return }
                        lookupText = ""
                        dismiss()
                        onLookupWord(word)
                    }
                
                if !lookupText.isEmpty {
                    Button(action: { lookupText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary.opacity(0.5))
                            .font(.system(size: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(NSColor.textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
            
            // MARK: - Recent Lookups
            if !dictionaryService.recentLookups.isEmpty {
                Divider()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("RECENT")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary.opacity(0.6))
                        .tracking(0.8)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    ForEach(dictionaryService.recentLookups, id: \.self) { word in
                        HStack(spacing: 4) {
                            HoverButton(action: {
                                dismiss()
                                onLookupWord(word)
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary.opacity(0.5))
                                        .frame(width: 16, alignment: .center)
                                    
                                    Text(word)
                                        .font(.system(size: 13))
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 5)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Button(action: {
                                dictionaryService.removeFromRecentLookups(word)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary.opacity(0.5))
                                    .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .pointingHandCursor()
                            .help("Remove from recent")
                            .padding(.trailing, 10)
                        }
                    }
                }
                .padding(.bottom, 4)
            }
            
            Divider()
            
            // MARK: - Menu items
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
            
            // MARK: - Quit
            menuButton(title: "Quit Word Journal", icon: "power", shortcut: "⌘Q") {
                NSApplication.shared.terminate(nil)
            }
            .padding(.vertical, 4)
        }
        .frame(width: 260)
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
            dictionaryService.refreshRecentLookups()
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
                    .font(.system(size: 12))
                    .frame(width: 16, alignment: .center)
                
                Text(title)
                    .font(.system(size: 13))
                
                Spacer()
                
                if let shortcut = shortcut {
                    Text(shortcut)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.5))
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
    
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
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
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isHovered ? accentBlue : Color.clear)
                        .padding(.horizontal, 4)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .pointingHandCursor()
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
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
