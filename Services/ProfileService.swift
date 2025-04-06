//
//  ProfileService.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/22/25.
//


import Foundation
import SwiftUI
import Combine

class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let profilesDefaultsKey = "userProfiles"
    private let activeProfileKey = "activeProfileId"
    
    @Published var profiles: [UserProfile] = []
    @Published var activeProfile: UserProfile?
    
    init() {
        loadProfiles()
    }
    
    // MARK: - Profile Management
    
    func loadProfiles() {
        if let savedData = UserDefaults.standard.data(forKey: profilesDefaultsKey) {
            do {
                let decoder = JSONDecoder()
                let savedProfiles = try decoder.decode([UserProfile].self, from: savedData)
                
                self.profiles = savedProfiles
                print("📤 Loaded \(savedProfiles.count) profiles from local storage")
                
                // Set active profile based on the stored ID
                if let activeProfileId = UserDefaults.standard.string(forKey: activeProfileKey),
                   let uuid = UUID(uuidString: activeProfileId),
                   let active = savedProfiles.first(where: { $0.id == uuid }) {
                    // This will use the setter method and trigger the UI update
                    self.activeProfile = active
                    print("👤 Loaded active profile: \(active.name)")
                } else if !savedProfiles.isEmpty {
                    // If no active profile is set but we have profiles, use the first one
                    self.activeProfile = savedProfiles.first
                    print("👤 No active profile set, using first profile: \(savedProfiles.first?.name ?? "Unknown")")
                }
            } catch {
                print("❌ Error loading profiles: \(error)")
                // Create a default profile if loading failed
                createDefaultProfile()
            }
        } else {
            // No profiles exist, create a default one
            createDefaultProfile()
        }
    }
    
    func debugProfileCards(profileName: String) {
        print("\n===== DEBUG: PROFILE CARDS FOR '\(profileName)' =====")
        if let profile = profiles.first(where: { $0.name == profileName }) {
            for (index, card) in profile.cards.enumerated() {
                print("  Card \(index+1): \(card.name) (ID: \(card.id))")
            }
        } else {
            print("  Profile not found")
        }
        print("=====================================\n")
    }
    
    func createDefaultProfile() {
        let defaultProfile = UserProfile(name: "Default Profile", email: "user@example.com")
        self.profiles = [defaultProfile]
        self.activeProfile = defaultProfile
        self.activeProfile?.isActive = true
        saveProfiles()
    }
    
    func createProfile(name: String, email: String, avatar: String) -> UserProfile {
        let newProfile = UserProfile(name: name, email: email, avatar: avatar)
        profiles.append(newProfile)
        saveProfiles()
        return newProfile
    }
    
    func updateProfile(_ profile: UserProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
            
            // If this is the active profile, update that reference too
            if activeProfile?.id == profile.id {
                activeProfile = profile
            }
            
            saveProfiles()
        }
    }
    
    func updateActiveProfileCards(_ cards: [CreditCard]) {
        guard let activeProfile = activeProfile,
              let index = profiles.firstIndex(where: { $0.id == activeProfile.id }) else {
            print("❌ No active profile found to update cards")
            return
        }
        
        // Create copies of the cards to ensure independence between profiles
        let cardsCopy = cards.map { $0 }
        
        // Update only in the profiles array (not directly to activeProfile)
        profiles[index].cards = cardsCopy
        
        // Save the changes
        saveProfiles()
        
        print("💾 Updated profile '\(profiles[index].name)' with \(cardsCopy.count) cards")
    }
    
    func deleteProfile(_ profileId: UUID) {
        profiles.removeAll { $0.id == profileId }
        
        // If we deleted the active profile, select another one
        if activeProfile?.id == profileId {
            activeProfile = profiles.first
            if let newActive = activeProfile {
                setActiveProfile(newActive.id)
            }
        }
        
        saveProfiles()
    }
    
    
    
    func setActiveProfile(_ profileId: UUID) {
        // First save current cards if there's an active profile
        if let cardViewModel = AppState.shared.cardViewModel,
           activeProfile != nil {
            cardViewModel.syncCardsToActiveProfile()
        }
        
        // Mark all profiles as inactive
        for i in 0..<profiles.count {
            profiles[i].isActive = (profiles[i].id == profileId)
        }
        
        // Instead of directly modifying activeProfile, we reload it from the profiles array
        // The @Published property will still trigger the UI update
        if let newActiveProfile = profiles.first(where: { $0.id == profileId }) {
            // We need to reload the profile reference since we can't modify it directly
            UserDefaults.standard.set(profileId.uuidString, forKey: activeProfileKey)
            
            // Force the change to be reflected by loading profiles
            loadProfiles()
            
            print("👤 Switched to profile: \(newActiveProfile.name)")
        }
        
        saveProfiles()
    }
    
    // MARK: - Card Management for Profiles
    
    func addCardToProfile(_ card: CreditCard, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let index = profiles.firstIndex(where: { $0.id == id }) else {
            print("❌ No valid profile found to add card")
            return
        }
        
        // Add the card to the profile's cards
        profiles[index].cards.append(card)
        
        // If this is the active profile, update that reference too
        if activeProfile?.id == id {
            activeProfile?.cards.append(card)
        }
        
        saveProfiles()
    }
    
    func updateCardInProfile(_ card: CreditCard, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let profileIndex = profiles.firstIndex(where: { $0.id == id }) else {
            print("❌ No valid profile found to update card")
            return
        }
        
        // Find and update the card in the profile's cards
        if let cardIndex = profiles[profileIndex].cards.firstIndex(where: { $0.id == card.id }) {
            profiles[profileIndex].cards[cardIndex] = card
            
            // If this is the active profile, update that reference too
            if activeProfile?.id == id {
                if let activeCardIndex = activeProfile?.cards.firstIndex(where: { $0.id == card.id }) {
                    activeProfile?.cards[activeCardIndex] = card
                }
            }
            
            saveProfiles()
        }
    }
    
    func removeCardFromProfile(_ cardId: UUID, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let profileIndex = profiles.firstIndex(where: { $0.id == id }) else {
            print("❌ No valid profile found to remove card")
            return
        }
        
        // Remove the card from the profile's cards
        profiles[profileIndex].cards.removeAll { $0.id == cardId }
        
        // If this is the active profile, update that reference too
        if activeProfile?.id == id {
            activeProfile?.cards.removeAll { $0.id == cardId }
        }
        
        saveProfiles()
    }
    
    // MARK: - Catalog Preferences
    
    func addFavoriteCard(_ cardId: String, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let profileIndex = profiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Add to favorites if not already there
        if !profiles[profileIndex].catalogPreferences.favoriteCards.contains(cardId) {
            profiles[profileIndex].catalogPreferences.favoriteCards.append(cardId)
            
            // Update active profile reference if needed
            if activeProfile?.id == id {
                activeProfile?.catalogPreferences.favoriteCards.append(cardId)
            }
            
            saveProfiles()
        }
    }
    
    func removeFavoriteCard(_ cardId: String, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let profileIndex = profiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Remove from favorites
        profiles[profileIndex].catalogPreferences.favoriteCards.removeAll { $0 == cardId }
        
        // Update active profile reference if needed
        if activeProfile?.id == id {
            activeProfile?.catalogPreferences.favoriteCards.removeAll { $0 == cardId }
        }
        
        saveProfiles()
    }
    
    func addCustomCatalogCard(_ card: CreditCardInfo, profileId: UUID? = nil) {
        let targetProfileId = profileId ?? activeProfile?.id
        
        guard let id = targetProfileId,
              let profileIndex = profiles.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        // Initialize customCatalogCards if nil
        if profiles[profileIndex].catalogPreferences.customCatalogCards == nil {
            profiles[profileIndex].catalogPreferences.customCatalogCards = []
        }
        
        // Add to custom catalog
        profiles[profileIndex].catalogPreferences.customCatalogCards?.append(card)
        
        // Update active profile reference if needed
        if activeProfile?.id == id {
            if activeProfile?.catalogPreferences.customCatalogCards == nil {
                activeProfile?.catalogPreferences.customCatalogCards = []
            }
            activeProfile?.catalogPreferences.customCatalogCards?.append(card)
        }
        
        saveProfiles()
    }
    
    // MARK: - Data Persistence
    
    private func saveProfiles() {
        do {
            let encoder = JSONEncoder()
            let encoded = try encoder.encode(profiles)
            UserDefaults.standard.set(encoded, forKey: profilesDefaultsKey)
            UserDefaults.standard.synchronize()
            print("💾 Saved \(profiles.count) profiles to device storage")
        } catch {
            print("❌ Error saving profiles: \(error)")
        }
    }
}
