//
//  OfflineBannerCoordinator.swift
//  WordJournal
//
//  Created on 2026-02-05.
//

import Foundation
import Combine

/// Coordinates showing the offline banner. Debounces to avoid duplicate banners.
class OfflineBannerCoordinator: ObservableObject {
    static let shared = OfflineBannerCoordinator()
    
    @Published private(set) var isShowing: Bool = false
    @Published var message: String = "No internet — dictionary lookups may not work."
    
    private var lastShownDate: Date?
    private let debounceInterval: TimeInterval = 60
    private var autoDismissWorkItem: DispatchWorkItem?
    
    private init() {}
    
    func show(message: String? = nil) {
        if let m = message { self.message = m }
        
        let now = Date()
        if let last = lastShownDate, now.timeIntervalSince(last) < debounceInterval {
            return // Skip, already shown recently
        }
        
        lastShownDate = now
        isShowing = true
        
        // Cancel any pending auto-dismiss
        autoDismissWorkItem?.cancel()
        
        let work = DispatchWorkItem { [weak self] in
            self?.dismiss()
        }
        autoDismissWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 4, execute: work)
    }
    
    func dismiss() {
        autoDismissWorkItem?.cancel()
        autoDismissWorkItem = nil
        isShowing = false
    }
}
