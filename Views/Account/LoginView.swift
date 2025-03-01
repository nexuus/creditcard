//
//  LoginView.swift
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

struct LoginView: View {
    @Binding var isPresented: Bool
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
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
                        // Logo/header
                        VStack(spacing: 12) {
                            Image(systemName: "creditcard.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 70, height: 70)
                                .foregroundColor(.blue)
                                .padding(.top, 20)
                            
                            Text("Welcome Back")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Sign in to sync your cards across devices")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.bottom, 20)
                        
                        // Login form
                        VStack(spacing: 16) {
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
                                    
                                    SecureField("Your password", text: $password)
                                }
                                .padding()
                                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .cornerRadius(12)
                            }
                            
                            // Sign In button
                            Button(action: performLogin) {
                                Text("Sign In")
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
                        
                        // Sign up option
                        HStack {
                            Text("Don't have an account?")
                                .foregroundColor(.secondary)
                            
                            Button(action: {
                                showingSignUp = true
                            }) {
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Login Failed"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
            .sheet(isPresented: $showingSignUp) {
                SignUpView(isPresented: $isPresented)
            }
        }
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && email.contains("@") && !password.isEmpty
    }
    
    private func performLogin() {
        if UserService.shared.login(email: email, password: password) {
            isPresented = false
        } else {
            alertMessage = "Invalid email or password. Please try again."
            showingAlert = true
        }
    }
}
