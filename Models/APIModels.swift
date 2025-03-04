import Foundation

// Model matching the exact API response structure
import Foundation
import SwiftUI

// MARK: - Basic Card Model (from first endpoint)

struct APICard: Decodable, Identifiable {
    let cardKey: String
    let cardName: String
    let cardIssuer: String
    let spendType: String
    let earnMultiplier: Double
    let earnMultiplierValue: Double
    let spendBonusDesc: String
    let limitBeginDate: String
    let limitEndDate: String
    let isSpendLimit: Int
    let spendLimit: Double
    let spendLimitResetPeriod: String
    
    // Computed property to provide id for Identifiable conformance
    var id: String { cardKey }
}

// Type alias for the top-level response of basic cards endpoint
typealias CreditCardAPIResponse = [APICard]

// MARK: - Detailed Card Models (from /creditcard-detail-bycard/{cardKey})

// Top level response is an array containing a single card detail
typealias CardDetailAPIResponse = [CardDetail]

// Main card detail structure
struct CardDetail: Decodable {
    let cardKey: String
    let cardIssuer: String
    let cardName: String
    let cardNetwork: String
    let cardType: String
    let cardUrl: String
    let annualFee: Int
    let fxFee: Double
    let isFxFee: Int
    let creditRange: String
    
    // Base earn information
    let baseSpendAmount: Double
    let baseSpendEarnType: String
    let baseSpendEarnCategory: String
    let baseSpendEarnCurrency: String
    let baseSpendEarnValuation: Double
    let baseSpendEarnIsCash: Int
    let baseSpendEarnCashValue: Double
    
    // Signup bonus information
    let isSignupBonus: Int
    let signupBonusAmount: String
    let signupBonusType: String
    let signupBonusCategory: String
    let signUpBonusItem: String
    let signupBonusSpend: Int
    let signupBonusLength: Int
    let signupBonusLengthPeriod: String
    let signupAnnualFee: Int
    let isSignupAnnualFeeWaived: Int
    let signupStatementCredit: Int
    let signupBonusDesc: String
    
    // Travel benefits
    let trustedTraveler: String
    let isTrustedTraveler: Int
    let loungeAccess: String
    let isLoungeAccess: Int
    let freeHotelNight: String
    let isFreeHotelNight: Int
    let freeCheckedBag: String
    let isFreeCheckedBag: Int
    
    let isActive: Int
    
    // Card benefits and bonus categories
    let benefit: [CardBenefit]
    let spendBonusCategory: [SpendBonusCategory]
    let annualSpend: [AnyCodable] // Using AnyCodable for flexibility since array is empty in sample
    
    // Convert to our app's model
    func toCreditCardInfo() -> CreditCardInfo {
        let primaryCategory = CreditCardService.shared.getCategoryFromDetail(self)
            
            // Format description combining signup bonus and primary earn category
            let description = formatDescription()
            
            // Parse signup bonus amount
            let bonusAmount = Int(signupBonusAmount) ?? 0
            
            // Format APR (not provided in this API, we'll use a placeholder)
            let aprText = "See issuer website for details"
            
            return CreditCardInfo(
                id: cardKey,
                name: cardName.replacingOccurrences(of: "®", with: "").replacingOccurrences(of: "℠", with: ""),
                issuer: cardIssuer,
                category: primaryCategory,
                description: description,
                annualFee: Double(annualFee),
                signupBonus: bonusAmount,
                regularAPR: aprText,
                imageName: "", // No image URL in response, would need a mapping
                applyURL: cardUrl
            )
        }
    
    // Helper to determine primary category
    private func getPrimaryCategory() -> String {
        if spendBonusCategory.isEmpty {
            return baseSpendEarnCategory
        }
        
        // Find category with highest multiplier
        if let highest = spendBonusCategory.max(by: { $0.earnMultiplier < $1.earnMultiplier }) {
            return highest.spendBonusCategoryGroup
        }
        
        return baseSpendEarnCategory
    }
    
    // Format a comprehensive description
    private func formatDescription() -> String {
        var desc = ""
        
        // Add signup bonus if available
        if isSignupBonus == 1 && !signupBonusDesc.isEmpty {
            desc += signupBonusDesc
        }
        
        // Add key benefits summary (up to 2)
        if !benefit.isEmpty {
            desc += "\n\nKey Benefits:"
            for i in 0..<min(2, benefit.count) {
                desc += "\n• \(benefit[i].benefitTitle): \(benefit[i].benefitDesc.prefix(100))..."
            }
        }
        
        // Add earning rates
        if !spendBonusCategory.isEmpty {
            desc += "\n\nEarn:"
            for category in spendBonusCategory.prefix(3) {
                desc += "\n• \(category.spendBonusDesc)"
            }
        }
        
        return desc
    }
}

// Card benefit model
struct CardBenefit: Codable {
    let benefitTitle: String
    let benefitDesc: String
}

// Spend bonus category model
struct SpendBonusCategory: Codable {
    let spendBonusCategoryType: String
    let spendBonusCategoryName: String
    let spendBonusCategoryId: Int
    let spendBonusCategoryGroup: String
    let spendBonusSubcategoryGroup: String
    let spendBonusDesc: String
    let earnMultiplier: Double
    let isDateLimit: Int
    let limitBeginDate: String
    let limitEndDate: String
    let isSpendLimit: Int
    let spendLimit: Int
    let spendLimitResetPeriod: String
}

// Utility struct for handling empty arrays or unknown types
struct AnyCodable: Decodable {
    var value: Any
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            self.value = NSNull()
        }
    }
}
