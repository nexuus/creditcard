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
    private var _bonusCategories: [SpendBonusCategory]?
    
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
    
    // Add this initializer to your CreditCardInfo.swift file:

    init(id: String, name: String, issuer: String, category: String, description: String,
         annualFee: Double, signupBonus: Int, regularAPR: String, imageName: String, applyURL: String) {
        self.id = id
        self.name = name
        self.issuer = issuer
        self.category = category
        self.description = description
        self.annualFee = annualFee
        self.signupBonus = signupBonus
        self.regularAPR = regularAPR
        self.imageName = imageName
        self.applyURL = applyURL
    }
    
    
    // Custom initializer for Decodable conformance
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Decode regular properties
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        issuer = try container.decode(String.self, forKey: .issuer)
        category = try container.decode(String.self, forKey: .category)
        description = try container.decode(String.self, forKey: .description)
        annualFee = try container.decode(Double.self, forKey: .annualFee)
        signupBonus = try container.decode(Int.self, forKey: .signupBonus)
        regularAPR = try container.decode(String.self, forKey: .regularAPR)
        imageName = try container.decode(String.self, forKey: .imageName)
        applyURL = try container.decode(String.self, forKey: .applyURL)
        
        // Decode optional properties
        cardNetwork = try container.decodeIfPresent(String.self, forKey: .cardNetwork)
        cardType = try container.decodeIfPresent(String.self, forKey: .cardType)
        fxFee = try container.decodeIfPresent(Double.self, forKey: .fxFee)
        creditRange = try container.decodeIfPresent(String.self, forKey: .creditRange)
        
        signupBonusType = try container.decodeIfPresent(String.self, forKey: .signupBonusType)
        signupBonusCategory = try container.decodeIfPresent(String.self, forKey: .signupBonusCategory)
        signupBonusSpend = try container.decodeIfPresent(Int.self, forKey: .signupBonusSpend)
        signupBonusLength = try container.decodeIfPresent(Int.self, forKey: .signupBonusLength)
        signupBonusLengthPeriod = try container.decodeIfPresent(String.self, forKey: .signupBonusLengthPeriod)
        
        // Decode the properties with private backing storage - FIXED
        _benefits = try container.decodeIfPresent([CardBenefit].self, forKey: CodingKeys._benefits)
        _bonusCategories = try container.decodeIfPresent([SpendBonusCategory].self, forKey: CodingKeys._bonusCategories)
        
        annualSpendBonuses = try container.decodeIfPresent([String].self, forKey: .annualSpendBonuses)
        hasLoungeAccess = try container.decodeIfPresent(Bool.self, forKey: .hasLoungeAccess)
        hasFreeHotelNight = try container.decodeIfPresent(Bool.self, forKey: .hasFreeHotelNight)
        hasFreeCheckedBag = try container.decodeIfPresent(Bool.self, forKey: .hasFreeCheckedBag)
        hasTrustedTraveler = try container.decodeIfPresent(Bool.self, forKey: .hasTrustedTraveler)
    }
    
    // Custom encoder for Encodable conformance
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        // Encode regular properties
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(issuer, forKey: .issuer)
        try container.encode(category, forKey: .category)
        try container.encode(description, forKey: .description)
        try container.encode(annualFee, forKey: .annualFee)
        try container.encode(signupBonus, forKey: .signupBonus)
        try container.encode(regularAPR, forKey: .regularAPR)
        try container.encode(imageName, forKey: .imageName)
        try container.encode(applyURL, forKey: .applyURL)
        
        // Encode optional properties
        try container.encodeIfPresent(cardNetwork, forKey: .cardNetwork)
        try container.encodeIfPresent(cardType, forKey: .cardType)
        try container.encodeIfPresent(fxFee, forKey: .fxFee)
        try container.encodeIfPresent(creditRange, forKey: .creditRange)
        
        try container.encodeIfPresent(signupBonusType, forKey: .signupBonusType)
        try container.encodeIfPresent(signupBonusCategory, forKey: .signupBonusCategory)
        try container.encodeIfPresent(signupBonusSpend, forKey: .signupBonusSpend)
        try container.encodeIfPresent(signupBonusLength, forKey: .signupBonusLength)
        try container.encodeIfPresent(signupBonusLengthPeriod, forKey: .signupBonusLengthPeriod)
        
        // Encode the properties with private backing storage - FIXED
        try container.encodeIfPresent(_benefits, forKey: CodingKeys._benefits)
        try container.encodeIfPresent(_bonusCategories, forKey: CodingKeys._bonusCategories)
        
        try container.encodeIfPresent(annualSpendBonuses, forKey: .annualSpendBonuses)
        try container.encodeIfPresent(hasLoungeAccess, forKey: .hasLoungeAccess)
        try container.encodeIfPresent(hasFreeHotelNight, forKey: .hasFreeHotelNight)
        try container.encodeIfPresent(hasFreeCheckedBag, forKey: .hasFreeCheckedBag)
        try container.encodeIfPresent(hasTrustedTraveler, forKey: .hasTrustedTraveler)
    }
    
    // Public accessors for private properties
    var benefits: [CardBenefit]? {
        get { return _benefits }
        set { _benefits = newValue }
    }
    
    var bonusCategories: [SpendBonusCategory]? {
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
        category = CreditCardService.shared.getCategoryFromDetail(cardDetail)
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

// Extend the CardBenefit from APIModels to add Identifiable and Hashable
extension CardBenefit: Identifiable, Hashable {
    // Computed property for id since it's not in the JSON
    var id: String { benefitTitle }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(benefitTitle)
    }
    
    public static func == (lhs: CardBenefit, rhs: CardBenefit) -> Bool {
        return lhs.benefitTitle == rhs.benefitTitle
    }
}

// Extend SpendBonusCategory from APIModels to add Identifiable and Hashable
extension SpendBonusCategory: Identifiable, Hashable {
    // Computed property for id
    var id: Int { spendBonusCategoryId }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(spendBonusCategoryId)
    }
    
    public static func == (lhs: SpendBonusCategory, rhs: SpendBonusCategory) -> Bool {
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

// Use AnyCodable extension from APIModels.swift for annual spend bonuses
extension AnyCodable {
    var annualSpendDesc: String {
        if let str = self.value as? String {
            return str
        }
        return String(describing: self.value)
    }
}
