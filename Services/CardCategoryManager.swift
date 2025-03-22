// Modified CardCategoryManager.swift without the duplicate Color extension

import SwiftUI
import Foundation

/// A centralized manager for handling card categorization throughout the app
class CardCategoryManager {
    // Singleton instance
    static let shared = CardCategoryManager()
    
    // Primary card categories (in order of precedence)
    enum CardCategory: String, CaseIterable {
        case travel = "Travel"
        case airline = "Airline"
        case hotel = "Hotel"
        case cashback = "Cashback"
        case dining = "Dining"
        case groceries = "Groceries"
        case gas = "Gas"
        case business = "Business"
        case student = "Student"
        case luxury = "Luxury"
        case general = "General"
        
        // Helper to get all categories as strings
        static var allCategories: [String] {
            Self.allCases.map { $0.rawValue }
        }
    }
    
    // Category keyword mappings for better recognition
    private let categoryKeywords: [CardCategory: [String]] = [
        .travel: ["travel", "point", "mile", "adventure", "journey", "trip", "vacation", "rewards"],
        .airline: ["airline", "flight", "aviation", "aircraft", "airplane", "airport", "delta", "united", "southwest", "american airlines", "jetblue", "alaska air"],
        .hotel: ["hotel", "lodging", "accommodation", "hospitality", "marriott", "hilton", "hyatt", "ihg", "wyndham", "radisson", "stay"],
        .cashback: ["cash", "back", "rebate", "refund", "return", "money", "dollar", "percent", "unlimited", "freedom"],
        .dining: ["dining", "restaurant", "food", "eat", "cafe", "cuisine", "meal", "culinary"],
        .groceries: ["grocery", "groceries", "supermarket", "store", "shopping", "market"],
        .gas: ["gas", "fuel", "petrol", "station", "pump", "drive", "road"],
        .business: ["business", "corporate", "company", "enterprise", "commercial", "professional", "ink", "spark"],
        .student: ["student", "college", "university", "campus", "education", "school", "academic", "journey", "young"],
        .luxury: ["platinum", "reserve", "prestige", "elite", "premium", "luxury", "priority", "exclusive", "privilege", "black card"]
    ]
    
    // Private initializer for singleton
    private init() {}
    
    /// Categorizes a card based on its properties with improved consistency
    func categorizeCard(_ card: CreditCardInfo) -> String {
        // If card already has a valid category in our system, use it
        if isValidCategory(card.category) {
            return standardizeCategory(card.category)
        }
        
        // Extract from bonus categories if available
        if let bonusCategories = card.bonusCategories, !bonusCategories.isEmpty {
            // First try to find the category with highest multiplier
            if let highest = bonusCategories.max(by: { $0.earnMultiplier < $1.earnMultiplier }) {
                let categorized = categorizeFromString(highest.spendBonusCategoryGroup)
                if categorized != CardCategory.general.rawValue {
                    return categorized
                }
            }
            
            // If that didn't work, check all category descriptions
            for category in bonusCategories {
                let combinedText = category.spendBonusDesc + " " + category.spendBonusCategoryGroup
                let categorized = categorizeFromString(combinedText)
                if categorized != CardCategory.general.rawValue {
                    return categorized
                }
            }
        }
        
        // Check the card name and description
        let nameAndDesc = card.name + " " + card.description
        let fromDesc = categorizeFromString(nameAndDesc)
        if fromDesc != CardCategory.general.rawValue {
            return fromDesc
        }
        
        // Check issuer to categorize business or student cards
        let issuerLower = card.issuer.lowercased()
        if issuerLower.contains("business") || issuerLower.contains("ink") {
            return CardCategory.business.rawValue
        }
        if issuerLower.contains("student") || issuerLower.contains("college") {
            return CardCategory.student.rawValue
        }
        
        // Default to general
        return CardCategory.general.rawValue
    }
    
    /// Categorizes text content based on keyword matching
    func categorizeFromString(_ text: String) -> String {
        let lowercasedText = text.lowercased()
        
        // Check each category's keywords
        for (category, keywords) in categoryKeywords {
            for keyword in keywords {
                if lowercasedText.contains(keyword) {
                    return category.rawValue
                }
            }
        }
        
        // Handle special cases for travel cards by looking for points/miles terminology
        if lowercasedText.contains("point") || lowercasedText.contains("mile") {
            if !(lowercasedText.contains("cash") && lowercasedText.contains("back")) {
                return CardCategory.travel.rawValue
            }
        }
        
        return CardCategory.general.rawValue
    }
    
    /// Standardizes a category string to match our system
    func standardizeCategory(_ category: String) -> String {
        let standardized = category.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = standardized.lowercased()
        
        // Direct match with our enum
        for cardCategory in CardCategory.allCases {
            if lowercased == cardCategory.rawValue.lowercased() {
                return cardCategory.rawValue
            }
        }
        
        // Check for aliases and similar terms
        if lowercased.contains("cash") && (lowercased.contains("back") || lowercased.contains("reward")) {
            return CardCategory.cashback.rawValue
        }
        
        if lowercased.contains("travel") || lowercased.contains("point") || lowercased.contains("mile") {
            return CardCategory.travel.rawValue
        }
        
        if lowercased.contains("air") || lowercased.contains("flight") || lowercased.contains("airline") {
            return CardCategory.airline.rawValue
        }
        
        if lowercased.contains("hotel") || lowercased.contains("lodging") || lowercased.contains("stay") {
            return CardCategory.hotel.rawValue
        }
        
        if lowercased.contains("dining") || lowercased.contains("restaurant") || lowercased.contains("food") {
            return CardCategory.dining.rawValue
        }
        
        if lowercased.contains("grocer") || lowercased.contains("supermarket") {
            return CardCategory.groceries.rawValue
        }
        
        if lowercased.contains("gas") || lowercased.contains("fuel") {
            return CardCategory.gas.rawValue
        }
        
        if lowercased.contains("business") || lowercased.contains("corporate") {
            return CardCategory.business.rawValue
        }
        
        // Return the original category if we couldn't match it
        return category
    }
    
    /// Checks if a category is in our standardized list
    func isValidCategory(_ category: String) -> Bool {
        return CardCategory.allCases.map { $0.rawValue.lowercased() }
            .contains(category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    /// Returns appropriate color for a category
    func colorForCategory(_ category: String) -> Color {
        let standardized = standardizeCategory(category)
        
        switch standardized.lowercased() {
        case CardCategory.travel.rawValue.lowercased():
            return Color(hex: "007AFF")  // Blue
        case CardCategory.cashback.rawValue.lowercased():
            return Color(hex: "34C759")  // Green
        case CardCategory.business.rawValue.lowercased():
            return Color(hex: "5856D6")  // Purple
        case CardCategory.hotel.rawValue.lowercased():
            return Color(hex: "FF9500")  // Orange
        case CardCategory.airline.rawValue.lowercased():
            return Color(hex: "FF2D55")  // Red
        case CardCategory.groceries.rawValue.lowercased():
            return Color(hex: "30B94D")  // Light Green
        case CardCategory.dining.rawValue.lowercased():
            return Color(hex: "FF9F0A")  // Orange-Red
        case CardCategory.gas.rawValue.lowercased():
            return Color(hex: "AF52DE")  // Light Purple
        case CardCategory.student.rawValue.lowercased():
            return Color(hex: "32ADE6")  // Teal Blue
        case CardCategory.luxury.rawValue.lowercased():
            return Color(hex: "8E8E93")  // Dark Gray
        default:
            return Color(hex: "8E8E93")  // Gray for general or unknown
        }
    }
    
    /// Helper method to get all standardized categories
    func getAllCategories() -> [String] {
        return CardCategory.allCategories
    }
}

// NOTE: The Color extension with init(hex:) has been removed to avoid duplication
// The existing Color.init(hex:) method from AppTheme.swift will be used instead
