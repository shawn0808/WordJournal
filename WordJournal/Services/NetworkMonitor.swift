//
//  NetworkMonitor.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation
import Network

/// Monitors network connectivity. Uses NWPathMonitor for local path status
/// and probes the dictionary API directly to detect firewall/blocked scenarios
/// (e.g. user in China with internet but Western services blocked).
class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    /// Path status from NWPathMonitor (has Wi-Fi, has IP, etc.)
    @Published private(set) var isPathSatisfied: Bool = true
    
    /// Probe result: can we reach the dictionary API? Updated by checkDictionaryReachability().
    @Published private(set) var isDictionaryReachable: Bool = true
    
    /// Combined: treat as "effectively offline" if path unsatisfied OR probe failed.
    var isEffectivelyOffline: Bool {
        !isPathSatisfied || !isDictionaryReachable
    }
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.wordjournal.networkmonitor")
    
    /// URL used for reachability probe — directly tests dictionary API
    private static let probeURL = URL(string: "https://api.dictionaryapi.dev/api/v2/entries/en/test")!
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isPathSatisfied = (path.status == .satisfied)
            }
        }
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
    
    /// Probes the dictionary API. Call on app launch (delayed) and optionally after path becomes satisfied.
    func checkDictionaryReachability(completion: ((Bool) -> Void)? = nil) {
        var request = URLRequest(url: Self.probeURL)
        request.httpMethod = "GET"
        request.timeoutInterval = 2
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        
        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            let reachable: Bool
            if let err = error as? URLError {
                reachable = false
                print("NetworkMonitor: Dictionary API probe failed - \(err.localizedDescription)")
            } else if let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) {
                reachable = true
            } else {
                reachable = false
                print("NetworkMonitor: Dictionary API probe returned non-OK status")
            }
            
            DispatchQueue.main.async {
                self?.isDictionaryReachable = reachable
                completion?(reachable)
            }
        }.resume()
    }
    
    /// Returns true if the error is network-related (no connection, timeout, DNS, etc.)
    static func isNetworkError(_ error: Error) -> Bool {
        guard let urlError = error as? URLError else { return false }
        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .timedOut, .dnsLookupFailed,
             .cannotConnectToHost, .cannotFindHost, .internationalRoamingOff,
             .secureConnectionFailed, .resourceUnavailable, .dataNotAllowed:
            return true
        default:
            return false
        }
    }
}
