//
//  ProfileViewModel.swift
//  CreditCardTracker
//
//  Created by Hassan  on 3/22/25.
//


import Foundation
import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profiles: [UserProfile] = []
    @Published var activeProfile: UserProfile?
    @Published var isProfileSwitcherVisible = false
    
    // Form fields for creating new profile
    @Published var newProfileName = ""
    @Published var newProfileEmail = ""
    @Published var newProfileAvatar = "person.circle.fill"
    
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to profile service changes
        ProfileService.shared.$profiles
            .sink { [weak self] profiles in
                self?.profiles = profiles
            }
            .store(in: &cancellables)
        
        ProfileService.shared.$activeProfile
            .sink { [weak self] profile in
                self?.activeProfile = profile
            }
            .store(in: &cancellables)
        
        // Load profiles from service
        loadProfiles()
    }
    
    func loadProfiles() {
        isLoading = true
        
        // Load profiles from the service
        profiles = ProfileService.shared.profiles
        activeProfile = ProfileService.shared.activeProfile
        
        isLoading = false
    }
    
    func createProfile() {
        guard !newProfileName.isEmpty, !newProfileEmail.isEmpty else {
            errorMessage = "Name and email are required"
            return
        }
        
        isLoading = true
        
        let newProfile = ProfileService.shared.createProfile(
            name: newProfileName,
            email: newProfileEmail,
            avatar: newProfileAvatar
        )
        
        // Reset form fields
        newProfileName = ""
        newProfileEmail = ""
        newProfileAvatar = "person.circle.fill"
        
        isLoading = false
        
        // Switch to the new profile
        switchProfile(newProfile.id)
    }
    
    func updateProfile(_ profile: UserProfile) {
        ProfileService.shared.updateProfile(profile)
    }
    
    func deleteProfile(_ profileId: UUID) {
        // Don't allow deleting the last profile
        guard profiles.count > 1 else {
            errorMessage = "Cannot delete the only profile"
            return
        }
        
        ProfileService.shared.deleteProfile(profileId)
    }
    
    func switchProfile(_ profileId: UUID) {
        // First, sync current cards to the current active profile
        if let cardViewModel = AppState.shared.cardViewModel {
            cardViewModel.syncCardsToActiveProfile()
        }
        
        // Then set the new active profile
        ProfileService.shared.setActiveProfile(profileId)
        
        // Hide the profile switcher
        isProfileSwitcherVisible = false
    }
    
    // Catalog preferences methods
    
    func toggleFavoriteCard(_ cardId: String) {
        guard let profile = activeProfile else { return }
        
        if profile.catalogPreferences.favoriteCards.contains(cardId) {
            ProfileService.shared.removeFavoriteCard(cardId)
        } else {
            ProfileService.shared.addFavoriteCard(cardId)
        }
    }
    
    func isFavoriteCard(_ cardId: String) -> Bool {
        return activeProfile?.catalogPreferences.favoriteCards.contains(cardId) ?? false
    }
    
    func hasCustomCards() -> Bool {
        return activeProfile?.catalogPreferences.customCatalogCards?.isEmpty == false
    }
    
    func getCustomCards() -> [CreditCardInfo] {
        return activeProfile?.catalogPreferences.customCatalogCards ?? []
    }
    
    // Theme preference methods
    
    func toggleDarkMode() {
        guard var profile = activeProfile else { return }
        profile.themePreference.isDarkMode.toggle()
        ProfileService.shared.updateProfile(profile)
    }
    
    func setAccentColor(_ color: String) {
        guard var profile = activeProfile else { return }
        profile.themePreference.accentColor = color
        ProfileService.shared.updateProfile(profile)
    }
}
