//
//  DefinitionPopupView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI
import AppKit

struct DefinitionPopupView: View {
    let word: String
    let result: DictionaryResult
    let onAddToJournal: () -> Void
    let onDismiss: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(word.capitalized)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let phonetic = result.phonetic ?? result.phonetics?.first?.text {
                    Text("[\(phonetic)]")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            // Meanings
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(Array(result.meanings.enumerated()), id: \.offset) { _, meaning in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(meaning.partOfSpeech.capitalized)
                                .font(.headline)
                                .foregroundColor(.blue)
                            
                            ForEach(Array(meaning.definitions.enumerated()), id: \.offset) { idx, definition in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(idx + 1). \(definition.definition)")
                                        .font(.body)
                                    
                                    if let example = definition.example {
                                        Text("\"\(example)\"")
                                            .font(.caption)
                                            .italic()
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 8)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // Actions
            HStack {
                Button("Add to Journal") {
                    onAddToJournal()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
        }
        .padding()
        .frame(width: 400)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(radius: 10)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

