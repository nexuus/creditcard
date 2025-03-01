//
//  UserService.swift
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

// User Authentication Service
class UserService: ObservableObject {
    static let shared = UserService()
    private let userDefaultsKey = "savedUser"
    private let isLoggedInKey = "isLoggedIn"
    
    @Published var currentUser: User?
    @Published var isLoggedIn: Bool = false
    
    init() {
        loadUser()
    }
    
    func signUp(email: String, name: String, password: String) -> Bool {
        // In a real app, you would validate and store the password securely
        let newUser = User(email: email, name: name)
        self.currentUser = newUser
        self.isLoggedIn = true
        saveUser()
        return true
    }
    
    func login(email: String, password: String) -> Bool {
        // In a real app, this would validate against stored credentials
        guard let savedUser = loadSavedUser() else {
            return false
        }
        
        if savedUser.email.lowercased() == email.lowercased() {
            self.currentUser = savedUser
            self.isLoggedIn = true
            UserDefaults.standard.set(true, forKey: isLoggedInKey)
            return true
        }
        
        return false
    }
    
    func logout() {
        self.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
    }
    
    func saveUser() {
        guard let user = currentUser else { return }
        
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.set(true, forKey: isLoggedInKey)
        }
    }
    
    func updateUserCards(cards: [CreditCard]) {
        guard var user = currentUser else { return }
        user.cards = cards
        currentUser = user
        saveUser()
    }
    
    private func loadUser() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        
        if isLoggedIn {
            currentUser = loadSavedUser()
        }
    }
    
    private func loadSavedUser() -> User? {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let savedUser = try? JSONDecoder().decode(User.self, from: savedData) {
                return savedUser
            }
        }
        return nil
    }
}
