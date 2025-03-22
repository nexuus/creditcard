import SwiftUI
import Foundation
import Combine

struct AccountView: View {
    @Binding var showLoginSheet: Bool
    @ObservedObject var profileViewModel: ProfileViewModel
    @AppStorage("isDarkMode") private var isDarkMode = false
    @State private var showingLogoutAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    // Access UserService to check login state
    private var isLoggedIn: Bool {
        UserService.shared.isLoggedIn
    }
    
    private var user: User? {
        UserService.shared.currentUser
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoggedIn, let user = user {
                    // Logged in state - keep as is
                    // ...existing code...
                } else {
                    // Logged out state - modified to show profile info
                    VStack(spacing: 24) {
                        Spacer()
                        
                        // Profile avatar
                        if let profile = profileViewModel.activeProfile {
                            ZStack {
                                Circle()
                                    .fill(getAccentColor().opacity(0.2))
                                    .frame(width: 100, height: 100)
                                
                                Image(systemName: profile.avatar)
                                    .resizable()
                                    .scaledToFit()
                                    .padding(24)
                                    .foregroundColor(getAccentColor())
                                    .frame(width: 100, height: 100)
                            }
                            
                            VStack(spacing: 4) {
                                Text(profile.name)
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text(profile.email)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                            
                            Text("No Profile Selected")
                                .font(.title2)
                                .fontWeight(.bold)
                        }
                        
                        // Profile management buttons
                        VStack(spacing: 16) {
                            Button(action: {
                                profileViewModel.isProfileSwitcherVisible = true
                            }) {
                                HStack {
                                    Image(systemName: "person.2.fill")
                                    Text("Switch Profile")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 64)
                                .padding(.vertical, 16)
                                .background(getAccentColor())
                                .cornerRadius(12)
                            }
                            
                            Button(action: {
                                // Show create profile sheet
                                profileViewModel.newProfileName = ""
                                profileViewModel.newProfileEmail = ""
                                profileViewModel.newProfileAvatar = "person.circle.fill"
                                withAnimation {
                                    profileViewModel.isProfileSwitcherVisible = true
                                }
                            }) {
                                HStack {
                                    Image(systemName: "person.badge.plus")
                                    Text("Create New Profile")
                                }
                                .font(.headline)
                                .foregroundColor(getAccentColor())
                                .padding(.horizontal, 64)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(getAccentColor(), lineWidth: 2)
                                )
                            }
                        }
                        .padding(.top, 32)
                        
                        Spacer()
                        
                        // App Settings section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("App Settings")
                                .font(.headline)
                                .padding(.bottom, 8)
                            
                            // Dark Mode Toggle
                            Toggle(isOn: $isDarkMode) {
                                HStack {
                                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(isDarkMode ? .purple : .orange)
                                    
                                    Text("Dark Mode")
                                        .font(.body)
                                }
                            }
                            .onChange(of: isDarkMode) { newValue in
                                if var profile = profileViewModel.activeProfile {
                                    profile.themePreference.isDarkMode = newValue
                                    profileViewModel.updateProfile(profile)
                                }
                            }
                            
                            // Theme color picker
                            HStack {
                                Text("Theme Color")
                                
                                Spacer()
                                
                                HStack(spacing: 12) {
                                    ColorButton(color: .blue, isSelected: isSelectedColor("blue"), action: { selectColor("blue") })
                                    ColorButton(color: .green, isSelected: isSelectedColor("green"), action: { selectColor("green") })
                                    ColorButton(color: .purple, isSelected: isSelectedColor("purple"), action: { selectColor("purple") })
                                    ColorButton(color: .red, isSelected: isSelectedColor("red"), action: { selectColor("red") })
                                    ColorButton(color: .orange, isSelected: isSelectedColor("orange"), action: { selectColor("orange") })
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                        )
                        .padding()
                        
                        if isLoggedIn {
                            // Sign in button if not logged in
                            Button(action: {
                                showLoginSheet = true
                            }) {
                                Text("Sign In")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 64)
                                    .padding(.vertical, 16)
                                    .background(Color.blue)
                                    .cornerRadius(12)
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
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
    
    // Check if a color is selected
    private func isSelectedColor(_ colorName: String) -> Bool {
        return profileViewModel.activeProfile?.themePreference.accentColor == colorName
    }
    
    // Select a color
    private func selectColor(_ colorName: String) {
        if var profile = profileViewModel.activeProfile {
            profile.themePreference.accentColor = colorName
            profileViewModel.updateProfile(profile)
        }
    }
}

// Color picker button
struct ColorButton: View {
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(Color.white, lineWidth: isSelected ? 2 : 0)
                        .padding(2)
                )
                .overlay(
                    Circle()
                        .stroke(color, lineWidth: isSelected ? 1 : 0)
                        .padding(4)
                )
        }
    }
}
