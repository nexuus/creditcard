//
//  AppState.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/10/25.
//
// Add this as a new file: Services/AppState.swift

import Foundation
import Combine

/// AppState singleton to provide access to shared components across the app
class AppState {
    // Singleton instance
    static let shared = AppState()
    
    // Reference to the main CardViewModel
    weak var cardViewModel: CardViewModel?
    
    // Private initializer for singleton
    private init() {}
}
