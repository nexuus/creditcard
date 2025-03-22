//
//  CreateProfileView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/22/25.
//


import SwiftUI

struct CreateProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Available avatars
    let avatarOptions = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "person.fill",
        "person.text.rectangle.fill",
        "face.smiling.fill",
        "star.circle.fill",
        "heart.circle.fill",
        "creditcard.circle.fill"
    ]
    
    // Available theme colors
    let colorOptions = [
        "blue",
        "green",
        "purple",
        "red",
        "orange",
        "pink"
    ]
    
    @State private var selectedColor = "blue"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Avatar selection
                        VStack(spacing: 12) {
                            Text("Choose an Avatar")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Avatar grid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                ForEach(avatarOptions, id: \.self) { avatar in
                                    Button(action: {
                                        viewModel.newProfileAvatar = avatar
                                    }) {
                                        ZStack {
                                            Circle()
                                                .fill(colorFromString(selectedColor).opacity(0.2))
                                                .frame(width: 60, height: 60)
                                            
                                            Image(systemName: avatar)
                                                .font(.system(size: 30))
                                                .foregroundColor(colorFromString(selectedColor))
                                        }
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(viewModel.newProfileAvatar == avatar ? Color.blue : Color.clear, lineWidth: 3)
                                            .frame(width: 66, height: 66)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Color theme selection
                        VStack(spacing: 12) {
                            Text("Choose a Theme Color")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Color grid
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 70))], spacing: 16) {
                                ForEach(colorOptions, id: \.self) { color in
                                    Button(action: {
                                        selectedColor = color
                                    }) {
                                        Circle()
                                            .fill(colorFromString(color))
                                            .frame(width: 40, height: 40)
                                    }
                                    .overlay(
                                        Circle()
                                            .stroke(selectedColor == color ? Color.white : Color.clear, lineWidth: 3)
                                            .frame(width: 46, height: 46)
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Profile details form
                        VStack(spacing: 16) {
                            // Name field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Profile Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                    
                                    TextField("John Doe", text: $viewModel.newProfileName)
                                        .autocapitalization(.words)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                            }
                            
                            // Email field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email Address")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                    
                                    TextField("john@example.com", text: $viewModel.newProfileEmail)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        )
                        .padding(.horizontal)
                        
                        // Create button
                        Button(action: {
                            // Create new profile with selected theme color
                            viewModel.createProfile()
                            
                            // Update the theme color for the new profile
                            if let newProfile = viewModel.profiles.last {
                                var updatedProfile = newProfile
                                updatedProfile.themePreference.accentColor = selectedColor
                                viewModel.updateProfile(updatedProfile)
                            }
                            
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Create Profile")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isFormValid ?
                                    colorFromString(selectedColor) :
                                    Color.gray
                                )
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                        .disabled(!isFormValid)
                        
                        // Error message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Create New Profile")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    private var isFormValid: Bool {
        return !viewModel.newProfileName.isEmpty && !viewModel.newProfileEmail.isEmpty
    }
    
    // Helper to convert color string to Color
    func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "red": return .red
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        default: return .blue
        }
    }
}