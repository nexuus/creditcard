//
//  CreditCardInfo.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

import SwiftUI
import Foundation
import Combine

// Enhanced credit card info for the catalog
struct CreditCardInfo: Codable, Identifiable, Hashable {
    // Basic identification
    var id: String
    var name: String
    var issuer: String
    var category: String
    var description: String
    
    // Basic financials
    var annualFee: Double
    var signupBonus: Int
    var regularAPR: String
    var imageName: String
    var applyURL: String
    
    // Advanced details (optional, filled in when detailed info is fetched)
    var cardNetwork: String?
    var cardType: String?
    var fxFee: Double?
    var creditRange: String?
    
    // Signup bonus details
    var signupBonusType: String?
    var signupBonusCategory: String?
    var signupBonusSpend: Int?
    var signupBonusLength: Int?
    var signupBonusLengthPeriod: String?
    
    // Card benefits - need special handling for Codable
    private var _benefits: [CardBenefit]?
    
    // Bonus categories - need special handling for Codable
    private var _bonusCategories: [CardBonusCategory]?
    
    // Annual spending bonuses
    var annualSpendBonuses: [String]?
    
    // Feature flags
    var hasLoungeAccess: Bool?
    var hasFreeHotelNight: Bool?
    var hasFreeCheckedBag: Bool?
    var hasTrustedTraveler: Bool?
    
    // Computed properties don't affect Codable
    var primaryColor: Color {
        return AppTheme.Colors.issuerColor(for: issuer)
    }
    
    // Properties with custom coding keys
    enum CodingKeys: String, CodingKey {
        case id, name, issuer, category, description
        case annualFee, signupBonus, regularAPR, imageName, applyURL
        case cardNetwork, cardType, fxFee, creditRange
        case signupBonusType, signupBonusCategory, signupBonusSpend, signupBonusLength, signupBonusLengthPeriod
        case _benefits = "benefits"
        case _bonusCategories = "bonusCategories"
        case annualSpendBonuses
        case hasLoungeAccess, hasFreeHotelNight, hasFreeCheckedBag, hasTrustedTraveler
    }
    
    // Public accessors for private properties
    var benefits: [CardBenefit]? {
        get { return _benefits }
        set { _benefits = newValue }
    }
    
    var bonusCategories: [CardBonusCategory]? {
        get { return _bonusCategories }
        set { _bonusCategories = newValue }
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: CreditCardInfo, rhs: CreditCardInfo) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Helper method to update with detailed information
    mutating func updateWithDetails(from cardDetail: CardDetail) {
        // Update basic fields if they were placeholders
        name = cardDetail.cardName.replacingOccurrences(of: "®", with: "").replacingOccurrences(of: "℠", with: "")
        issuer = cardDetail.cardIssuer
        description = cardDetail.signupBonusDesc
        annualFee = Double(cardDetail.annualFee)
        
        // Try to parse the signup bonus amount
        if let bonusAmount = Int(cardDetail.signupBonusAmount) {
            signupBonus = bonusAmount
        }
        
        // Apply URL
        applyURL = cardDetail.cardUrl
        
        // Advanced details
        cardNetwork = cardDetail.cardNetwork
        cardType = cardDetail.cardType
        fxFee = cardDetail.fxFee
        creditRange = cardDetail.creditRange
        
        // Signup bonus details
        signupBonusType = cardDetail.signupBonusType
        signupBonusCategory = cardDetail.signupBonusCategory
        signupBonusSpend = cardDetail.signupBonusSpend
        signupBonusLength = cardDetail.signupBonusLength
        signupBonusLengthPeriod = cardDetail.signupBonusLengthPeriod
        
        // Benefits
        benefits = cardDetail.benefit
        
        // Bonus categories
        bonusCategories = cardDetail.spendBonusCategory
        
        // Annual spend bonuses
        annualSpendBonuses = cardDetail.annualSpend.map { $0.annualSpendDesc }
        
        // Feature flags
        hasLoungeAccess = cardDetail.isLoungeAccess == 1
        hasFreeHotelNight = cardDetail.isFreeHotelNight == 1
        hasFreeCheckedBag = cardDetail.isFreeCheckedBag == 1
        hasTrustedTraveler = cardDetail.isTrustedTraveler == 1
        
        // Set category based on bonus categories if available
        if let topCategory = cardDetail.spendBonusCategory.max(by: { $0.earnMultiplier < $1.earnMultiplier }) {
            category = topCategory.spendBonusCategoryGroup
        } else if !cardDetail.signupBonusCategory.isEmpty {
            category = cardDetail.signupBonusCategory
        }
    }
}

// Card benefit model
struct CardBenefit: Codable, Identifiable, Hashable {
    var benefitTitle: String
    var benefitDesc: String
    
    // Computed property for id since it's not in the JSON
    var id: String { benefitTitle }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(benefitTitle)
    }
    
    static func == (lhs: CardBenefit, rhs: CardBenefit) -> Bool {
        return lhs.benefitTitle == rhs.benefitTitle
    }
}

// Spend bonus category model
struct CardBonusCategory: Codable, Identifiable, Hashable {
    var spendBonusCategoryType: String
    var spendBonusCategoryName: String
    var spendBonusCategoryId: Int
    var spendBonusCategoryGroup: String
    var spendBonusSubcategoryGroup: String
    var spendBonusDesc: String
    var earnMultiplier: Double
    
    // Computed property for id
    var id: Int { spendBonusCategoryId }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(spendBonusCategoryId)
    }
    
    static func == (lhs: CardBonusCategory, rhs: CardBonusCategory) -> Bool {
        return lhs.spendBonusCategoryId == rhs.spendBonusCategoryId
    }
    
    // Computed properties that don't affect Codable
    var multiplierDisplay: String {
        return "\(Int(earnMultiplier))x"
    }
    
    var categoryColor: Color {
        return AppTheme.Colors.categoryColor(for: spendBonusCategoryGroup)
    }
}

// Annual spend bonus model
struct AnnualSpendBonus: Codable {
    var annualSpendDesc: String
}
