import SwiftUI
import Foundation
import Combine

struct AccountView: View {
    @Binding var showLoginSheet: Bool
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
                    // Logged in state
                    VStack {
                        // Profile header
                        VStack(spacing: 20) {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 80, height: 80)
                                .overlay(
                                    Text(String(user.name.prefix(1)))
                                        .font(.system(size: 32, weight: .bold))
                                        .foregroundColor(.white)
                                )
                                .padding(.bottom, 8)
                            
                            Text(user.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 30)
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .cornerRadius(16)
                        .padding()
                        
                        // Account options
                        VStack(spacing: 0) {
                            // Dark Mode Toggle
                            Toggle(isOn: $isDarkMode) {
                                HStack {
                                    Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                        .foregroundColor(isDarkMode ? .purple : .orange)
                                        .frame(width: 24)
                                    
                                    Text("Dark Mode")
                                        .font(.body)
                                }
                            }
                            .padding()
                            .background(Color.clear)
                            .contentShape(Rectangle())
                            
                            Divider()
                            
                            NavigationLink(destination: Text("Profile Settings")) {
                                SettingsRow(icon: "person.fill", title: "Profile Settings")
                            }
                            
                            NavigationLink(destination: Text("Notification Preferences")) {
                                SettingsRow(icon: "bell.fill", title: "Notifications")
                            }
                            
                            NavigationLink(destination: Text("App Settings")) {
                                SettingsRow(icon: "gear", title: "Settings")
                            }
                        }
                        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Logout button
                        Button(action: {
                            showingLogoutAlert = true
                        }) {
                            HStack {
                                Image(systemName: "arrow.right.square")
                                    .font(.system(size: 16))
                                
                                Text("Log Out")
                                    .font(.headline)
                            }
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            .padding(.top, 16)
                        }
                        
                        Spacer()
                    }
                    .alert(isPresented: $showingLogoutAlert) {
                        Alert(
                            title: Text("Log Out"),
                            message: Text("Are you sure you want to log out?"),
                            primaryButton: .destructive(Text("Log Out")) {
                                UserService.shared.logout()
                            },
                            secondaryButton: .cancel()
                        )
                    }
                } else {
                    // Logged out state
                    VStack(spacing: 24) {
                        Spacer()
                        
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .foregroundColor(.gray)
                        
                        Text("Not Logged In")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Sign in to sync your cards across devices")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
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
                        
                        // Dark Mode Toggle for non-logged in users too
                        Toggle(isOn: $isDarkMode) {
                            HStack {
                                Image(systemName: isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundColor(isDarkMode ? .purple : .orange)
                                
                                Text("Dark Mode")
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 32)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Account")
        }
    }
}

struct SettingsRow: View {
    var icon: String
    var title: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.clear)
        .contentShape(Rectangle())
    }
}
