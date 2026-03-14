//
//  AIInsightCache.swift
//  WordJournal
//
//  Disk cache for AI-generated word insights.
//

import Foundation

enum AIInsightCache {
    private static let cacheSubdir = "AIInsights"
    
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
        return cacheDirectory.appendingPathComponent("\(safe).json")
    }
    
    static func load(for word: String) -> AIWordInsight? {
        let url = fileURL(for: word)
        guard FileManager.default.fileExists(atPath: url.path),
              let data = try? Data(contentsOf: url),
              let insight = try? JSONDecoder().decode(AIWordInsight.self, from: data) else {
            return nil
        }
        return insight
    }
    
    static func save(_ insight: AIWordInsight, for word: String) {
        let url = fileURL(for: word)
        guard let data = try? JSONEncoder().encode(insight) else { return }
        try? data.write(to: url)
    }
    
    static func hasCached(for word: String) -> Bool {
        FileManager.default.fileExists(atPath: fileURL(for: word).path)
    }
    
    static func clearAll() {
        let fm = FileManager.default
        let dir = cacheDirectory
        guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { return }
        for url in files {
            try? fm.removeItem(at: url)
        }
        NotificationCenter.default.post(name: .aiInsightCacheDidClear, object: nil)
    }
}

extension Notification.Name {
    static let aiInsightCacheDidClear = Notification.Name("AIInsightCacheDidClear")
}
