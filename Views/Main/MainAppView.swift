//
//  MainAppView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

// Then your own types if needed (usually not necessary since they're in the same module)
// import MyCustomTypes

//
//  MainAppView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

struct MainAppView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var selectedTab = 0
    @State private var showingLoginSheet = false
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // First Tab: Cards Dashboard
            TrackerView(viewModel: viewModel)
                .tabItem {
                    Label("My Cards", systemImage: "creditcard.fill")
                }
                .tag(0)
            
            // Second Tab: Card Catalog
            CardCatalogView(viewModel: viewModel)
                .tabItem {
                    Label("Catalog", systemImage: "list.bullet.rectangle.fill")
                }
                .tag(1)
            
            // Third Tab: Account
            AccountView(showLoginSheet: $showingLoginSheet)
                .tabItem {
                    Label("Account", systemImage: "person.fill")
                }
                .tag(2)
        }
        .accentColor(.blue)
        .sheet(isPresented: $showingLoginSheet) {
            if !UserService.shared.isLoggedIn {
                LoginView(isPresented: $showingLoginSheet)
            }
        }
    }
}

#Preview {
    MainAppView(viewModel: CardViewModel())
}
