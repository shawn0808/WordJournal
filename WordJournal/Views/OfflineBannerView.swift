//
//  OfflineBannerView.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import SwiftUI

struct OfflineBannerView: View {
    let message: String
    let onDismiss: () -> Void
    
    private let accentBlue = Color(red: 0.35, green: 0.56, blue: 0.77)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Text(message)
                .font(.system(size: 13))
                .foregroundColor(Color(NSColor.labelColor))
                .lineLimit(2)
            
            Spacer(minLength: 8)
            
            Button(action: onDismiss) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
}
