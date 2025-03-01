//
//  CreditCardTrackerApp.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/24/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

// Then your own types if needed (usually not necessary since they're in the same module)
// import MyCustomTypes

//
//  CreditCardTrackerApp.swift

@main
struct CreditCardTrackerApp: App {
    @StateObject private var viewModel = CardViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainAppView(viewModel: viewModel)
                .onAppear {
                    // Force initial load of API data
                    Task {
                        await viewModel.loadCreditCardsFromAPI()
                        
                        // Preload common card images for better UX
                        CreditCardService.shared.preloadCommonCardImages()
                    }
                }
        }
    }
}
