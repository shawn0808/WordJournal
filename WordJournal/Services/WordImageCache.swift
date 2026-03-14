//
//  WordImageCache.swift
//  WordJournal
//
//  Disk cache for AI-generated Word of the Day images.
//

import Foundation
import AppKit

enum WordImageCache {
    private static let cacheSubdir = "WordOfTheDayImages"
    
    static var cacheDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let bundleId = Bundle.main.bundleIdentifier ?? "WordJournal"
        let dir = appSupport.appendingPathComponent(bundleId, isDirectory: true)
            .appendingPathComponent(cacheSubdir, isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    
    static func fileURL(for word: String) -> URL {
        let safe = word.lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        return cacheDirectory.appendingPathComponent("\(safe).png")
    }
    
    static func load(for word: String) -> NSImage? {
        let url = fileURL(for: word)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return NSImage(contentsOf: url)
    }
    
    static func save(_ data: Data, for word: String) {
        let url = fileURL(for: word)
        try? data.write(to: url)
    }
    
    static func hasCached(for word: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: word).path)
    }
    
    /// Removes all cached images. Call when you want to force regeneration (e.g. after prompt changes).
    static func clearAll() {
        let fm = FileManager.default
        let dir = cacheDirectory
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for url in files {
            try? fm.removeItem(at: url)
        }
        NotificationCenter.default.post(name: .wordImageCacheDidClear, object: nil)
    }
}

extension Notification.Name {
    static let wordImageCacheDidClear = Notification.Name("WordImageCacheDidClear")
}
