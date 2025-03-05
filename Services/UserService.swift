import SwiftUI
import Foundation
import Combine

class UserService: ObservableObject {
    static let shared = UserService()
    private let userDefaultsKey = "savedUser"
    private let isLoggedInKey = "isLoggedIn"
    private let cardsDefaultsKey = "savedCards" // Added key for direct card storage
    
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
        // Before logging out, make sure any unsaved data is preserved
        if let user = currentUser {
            // Save cards directly to ensure they're preserved
            saveCardsDirectly(user.cards)
        }
        
        self.isLoggedIn = false
        UserDefaults.standard.set(false, forKey: isLoggedInKey)
    }
    
    func saveUser() {
        guard let user = currentUser else { return }
        
        do {
            let encoded = try JSONEncoder().encode(user)
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
            UserDefaults.standard.set(true, forKey: isLoggedInKey)
            
            // Also save cards directly for redundancy
            saveCardsDirectly(user.cards)
            
            print("💾 User saved successfully with \(user.cards.count) cards")
        } catch {
            print("❌ Error saving user: \(error)")
        }
    }
    
    func updateUserCards(cards: [CreditCard]) {
        guard var user = currentUser else {
            // If not logged in, still save cards directly
            saveCardsDirectly(cards)
            return
        }
        
        user.cards = cards
        currentUser = user
        saveUser()
        
        // Save timestamp of last update
        UserDefaults.standard.set(Date(), forKey: "lastCardUpdate")
    }
    
    // New method to directly save cards for redundancy
    private func saveCardsDirectly(_ cards: [CreditCard]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            UserDefaults.standard.set(data, forKey: cardsDefaultsKey)
            
            // Save timestamp
            UserDefaults.standard.set(Date(), forKey: "lastCardUpdate")
            
            print("💾 Saved \(cards.count) cards directly")
        } catch {
            print("❌ Error saving cards directly: \(error)")
        }
    }
    
    private func loadUser() {
        self.isLoggedIn = UserDefaults.standard.bool(forKey: isLoggedInKey)
        
        if isLoggedIn {
            currentUser = loadSavedUser()
            
            // Verify user has the latest cards
            if var user = currentUser, let cards = loadCardsDirectly() {
                // Only update if direct cards are newer (have more or different cards)
                if cards.count > user.cards.count || cardsAreDifferent(cards, user.cards) {
                    print("⚠️ Found newer card data, updating user")
                    user.cards = cards
                    currentUser = user
                    saveUser()
                }
            }
        }
    }
    
    private func loadSavedUser() -> User? {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey) {
            do {
                let savedUser = try JSONDecoder().decode(User.self, from: savedData)
                return savedUser
            } catch {
                print("❌ Error decoding user: \(error)")
            }
        }
        return nil
    }
    
    // Load cards directly from UserDefaults
    func loadCardsDirectly() -> [CreditCard]? {
        guard let data = UserDefaults.standard.data(forKey: cardsDefaultsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cards = try decoder.decode([CreditCard].self, from: data)
            print("📤 Loaded \(cards.count) cards directly")
            return cards
        } catch {
            print("❌ Error loading cards directly: \(error)")
            return nil
        }
    }
    
    // Check if card collections are different
    private func cardsAreDifferent(_ cards1: [CreditCard], _ cards2: [CreditCard]) -> Bool {
        // Quick check: different count means different collections
        if cards1.count != cards2.count {
            return true
        }
        
        // Create a dictionary of card IDs to bonusAchieved status for the first collection
        let statusMap1 = Dictionary(uniqueKeysWithValues: cards1.map { ($0.id.uuidString, $0.bonusAchieved) })
        
        // Check if any card in the second collection has a different status
        for card in cards2 {
            if let status = statusMap1[card.id.uuidString], status != card.bonusAchieved {
                return true
            }
        }
        
        return false
    }
}
