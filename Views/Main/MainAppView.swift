import SwiftUI
import Foundation
import Combine

struct MainAppView: View {
    @ObservedObject var viewModel: CardViewModel
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var selectedTab = 0
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showLoginSheet = false  // Make sure the name exactly matches
    
    var body: some View {
        ZStack {
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
                AccountView(showLoginSheet: $showLoginSheet, profileViewModel: profileViewModel)
                    .tabItem {
                        Label("Account", systemImage: "person.fill")
                    }
                    .tag(2)
            }
            .accentColor(getAccentColor())
            .preferredColorScheme(getColorScheme())
            
            // Profile switcher overlay
            if profileViewModel.isProfileSwitcherVisible {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        profileViewModel.isProfileSwitcherVisible = false
                    }
                
                ProfileSwitcherView(viewModel: profileViewModel)
                    .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.7)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                    .transition(.opacity)
                    .animation(.spring(), value: profileViewModel.isProfileSwitcherVisible)
            }
        }
        .overlay(
            // Profile indicator at top right
            Button(action: {
                profileViewModel.isProfileSwitcherVisible = true
            }) {
                HStack(spacing: 8) {
                    if let profile = profileViewModel.activeProfile {
                        Image(systemName: profile.avatar)
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(getAccentColor())
                            )
                        
                        Text(profile.name)
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                    
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color(.systemBackground))
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .padding(.top, 55)
            .padding(.trailing, 16)
            , alignment: .topTrailing
        )
        // Update this in MainAppView.swift's onChange handler
        .onChange(of: profileViewModel.activeProfile?.id) { newProfileId in
            if newProfileId != nil {
                // Save current cards to previous profile before switching
                viewModel.syncCardsToActiveProfile()
                
                // When profile changes, reload cards for that profile
                viewModel.loadCardsForActiveProfile()
                
                // Also apply the profile's catalog preferences
                viewModel.applyProfileCatalogPreferences()
                
                // Apply theme preferences
                if let profile = profileViewModel.activeProfile {
                    isDarkMode = profile.themePreference.isDarkMode
                }
                
            }
        }
    }
    
    // Helper to get accent color from active profile
    private func getAccentColor() -> Color {
        if let profile = profileViewModel.activeProfile {
            switch profile.themePreference.accentColor.lowercased() {
            case "blue": return .blue
            case "green": return .green
            case "red": return .red
            case "orange": return .orange
            case "purple": return .purple
            case "pink": return .pink
            default: return .blue
            }
        }
        return .blue
    }
    
    // Helper to get color scheme from active profile
    private func getColorScheme() -> ColorScheme? {
        if let profile = profileViewModel.activeProfile {
            return profile.themePreference.isDarkMode ? .dark : .light
        }
        return isDarkMode ? .dark : .light
    }
}
