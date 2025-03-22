import Foundation
import SwiftUI
import Combine

// Enhanced User model to support profiles and catalogs
struct UserProfile: Codable, Identifiable, Equatable {
    var id: UUID
    var name: String
    var avatar: String // Icon name or color reference for the avatar
    var email: String
    var isActive: Bool // Flag to identify the currently active profile
    var cards: [CreditCard] // User's owned cards
    var catalogPreferences: CatalogPreferences // User-specific catalog settings
    
    // User-specific theme preferences
    var themePreference: ThemePreference
    
    init(name: String, email: String, avatar: String = "person.circle.fill") {
        self.id = UUID()
        self.name = name
        self.email = email
        self.avatar = avatar
        self.isActive = false
        self.cards = []
        self.catalogPreferences = CatalogPreferences()
        self.themePreference = ThemePreference()
    }
    
    // Static equality for Equatable conformance
    static func == (lhs: UserProfile, rhs: UserProfile) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.email == rhs.email &&
               lhs.avatar == rhs.avatar &&
               lhs.isActive == rhs.isActive
    }
}

// User-specific catalog preferences
struct CatalogPreferences: Codable, Equatable {
    var favoriteCards: [String] // IDs of favorite cards
    var hiddenCards: [String] // IDs of cards to hide from catalog
    var preferredCategories: [String] // User's preferred categories
    var preferredIssuers: [String] // User's preferred issuers
    var customCatalogCards: [CreditCardInfo]? // User's custom added cards
    
    init() {
        self.favoriteCards = []
        self.hiddenCards = []
        self.preferredCategories = []
        self.preferredIssuers = []
        self.customCatalogCards = []
    }
}

// Theme preferences for personalization
struct ThemePreference: Codable, Equatable {
    var isDarkMode: Bool
    var accentColor: String // "blue", "green", etc. to be converted to Color
    
    init(isDarkMode: Bool = false, accentColor: String = "blue") {
        self.isDarkMode = isDarkMode
        self.accentColor = accentColor
    }
}
