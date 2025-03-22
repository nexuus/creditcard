//
//  CreditCardTrackerApp.swift
//  CreditCardTracker
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

@main
struct CreditCardTrackerApp: App {
    @StateObject private var viewModel = CardViewModel()
    
    var body: some Scene {
        WindowGroup {
            MainAppView(viewModel: viewModel)
                .onAppear {
                    // First load profile data
                    _ = ProfileService.shared
                    
                    // Then load card data with loading state
                    viewModel.initializeWithLoadingState()
                    
                    // Then load API data in the background
                    Task {
                        // A slight delay to ensure UI is responsive first
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        await viewModel.loadCreditCardsFromAPI()
                        
                        // Preload common card images for better UX
                        CreditCardService.shared.preloadCommonCardImages()
                    }
                }
        }
    }
}
