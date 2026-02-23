//
//  AnimatedGifView.swift
//  WordJournal
//
//  Displays an animated GIF from the app bundle using WKWebView.
//

import SwiftUI
import WebKit

/// Displays an animated GIF from the app bundle. Add .gif files to Resources and reference by name (without extension).
struct AnimatedGifView: NSViewRepresentable {
    let name: String
    
    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        
        if let url = Bundle.main.url(forResource: name, withExtension: "gif"),
           let data = try? Data(contentsOf: url) {
            webView.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        } else if let url = Bundle.main.url(forResource: name, withExtension: nil) {
            let data = (try? Data(contentsOf: url)) ?? Data()
            webView.load(data, mimeType: "image/gif", characterEncodingName: "UTF-8", baseURL: url.deletingLastPathComponent())
        }
        return webView
    }
    
    func updateNSView(_ nsView: WKWebView, context: Context) {}
}
