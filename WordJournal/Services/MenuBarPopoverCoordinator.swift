//
//  MenuBarPopoverCoordinator.swift
//  WordJournal
//
//  Coordinates programmatic opening of the MenuBarExtra popover.
//

import Foundation
import Combine

/// Shared coordinator to request opening the menu bar popover from outside SwiftUI (e.g. AppDelegate).
class MenuBarPopoverCoordinator: ObservableObject {
    static let shared = MenuBarPopoverCoordinator()
    
    @Published var isMenuBarPresented: Bool = false
    
    private init() {}
    
    /// Call to programmatically open the menu bar popover (same as clicking the status item).
    func open() {
        DispatchQueue.main.async {
            self.isMenuBarPresented = true
        }
    }
}
