//
//  SignUpView.swift
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

struct SignUpView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 12) {
                            Image(systemName: "person.badge.plus")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                            
                            Text("Create Account")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Sign up to track your credit card rewards")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                        
                        // Sign up form
                        VStack(spacing: 16) {
                            // Name
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Name")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                    
                                    TextField("Your name", text: $name)
                                        .disableAutocorrection(true)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Email
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundColor(.gray)
                                    
                                    TextField("your@email.com", text: $email)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundColor(.gray)
                                    
                                    SecureField("Create password", text: $password)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Confirm Password
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "lock.shield")
                                        .foregroundColor(.gray)
                                    
                                    SecureField("Confirm password", text: $confirmPassword)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Sign Up button
                            Button(action: performSignUp) {
                                Text("Create Account")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(isFormValid ? Color.blue : Color.gray)
                                    .cornerRadius(12)
                            }
                            .disabled(!isFormValid)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Sign Up Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty &&
               !email.isEmpty &&
               email.contains("@") &&
               !password.isEmpty &&
               password == confirmPassword
    }
    
    private func performSignUp() {
        if password != confirmPassword {
            alertMessage = "Passwords don't match."
            showingAlert = true
            return
        }
        
        if UserService.shared.signUp(email: email, name: name, password: password) {
            isPresented = false
        } else {
            alertMessage = "Failed to create account. Please try again."
            showingAlert = true
        }
    }
}
