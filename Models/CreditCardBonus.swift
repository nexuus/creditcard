import Foundation
import SwiftUI

// Amount structure represents a reward amount
struct Amount: Codable {
    let amount: Int
}

// Credit structure for any statement credits
struct Credit: Codable {
    let amount: Int
    let description: String?
    let excluded: Bool?
    
    // Add CodingKeys as the API might have optional fields
    enum CodingKeys: String, CodingKey {
        case amount
        case description
        case excluded
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        amount = try container.decode(Int.self, forKey: .amount)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        excluded = try container.decodeIfPresent(Bool.self, forKey: .excluded)
    }
}

// Offer structure representing a card's signup bonus offer
struct Offer: Codable {
    let spend: Int
    let amount: [Amount]
    let days: Int
    let credits: [Credit]
    let details: String?
    let expiration: String?
    
    // Add CodingKeys as some fields are optional
    enum CodingKeys: String, CodingKey {
        case spend
        case amount
        case days
        case credits
        case details
        case expiration
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        spend = try container.decode(Int.self, forKey: .spend)
        amount = try container.decode([Amount].self, forKey: .amount)
        days = try container.decode(Int.self, forKey: .days)
        credits = try container.decode([Credit].self, forKey: .credits)
        details = try container.decodeIfPresent(String.self, forKey: .details)
        expiration = try container.decodeIfPresent(String.self, forKey: .expiration)
    }
}

// Main card model matching the JSON structure
struct CreditCardBonus: Codable, Identifiable {
    let cardId: String
    let name: String
    let issuer: String
    let network: String
    let currency: String
    let isBusiness: Bool
    let annualFee: Int
    let isAnnualFeeWaived: Bool
    let universalCashbackPercent: Double?
    let url: String
    let imageUrl: String
    let credits: [Credit]
    let offers: [Offer]
    let historicalOffers: [Offer]
    let discontinued: Bool
    
    // Use cardId as id for Identifiable protocol
    var id: String { return cardId }
    
    // Add CodingKeys as the API might have optional fields
    enum CodingKeys: String, CodingKey {
        case cardId
        case name
        case issuer
        case network
        case currency
        case isBusiness
        case annualFee
        case isAnnualFeeWaived
        case universalCashbackPercent
        case url
        case imageUrl
        case credits
        case offers
        case historicalOffers
        case discontinued
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        cardId = try container.decode(String.self, forKey: .cardId)
        name = try container.decode(String.self, forKey: .name)
        issuer = try container.decode(String.self, forKey: .issuer)
        network = try container.decode(String.self, forKey: .network)
        currency = try container.decode(String.self, forKey: .currency)
        isBusiness = try container.decode(Bool.self, forKey: .isBusiness)
        annualFee = try container.decode(Int.self, forKey: .annualFee)
        isAnnualFeeWaived = try container.decode(Bool.self, forKey: .isAnnualFeeWaived)
        universalCashbackPercent = try container.decodeIfPresent(Double.self, forKey: .universalCashbackPercent)
        url = try container.decode(String.self, forKey: .url)
        imageUrl = try container.decode(String.self, forKey: .imageUrl)
        credits = try container.decode([Credit].self, forKey: .credits)
        offers = try container.decode([Offer].self, forKey: .offers)
        historicalOffers = try container.decode([Offer].self, forKey: .historicalOffers)
        discontinued = try container.decode(Bool.self, forKey: .discontinued)
    }
    
    // Convert to app's CreditCardInfo format
    func toCreditCardInfo() -> CreditCardInfo {
        // Get the best offer (highest bonus amount)
        let bestOffer = offers.max(by: {
            $0.amount.first?.amount ?? 0 < $1.amount.first?.amount ?? 0
        })
        
        let bonusAmount = bestOffer?.amount.first?.amount ?? 0
        let minSpend = bestOffer?.spend ?? 0
        let timeframe = bestOffer?.days ?? 90
        let details = bestOffer?.details
        
        // Format a description
        var description = "Earn \(bonusAmount) "
        
        // Determine the bonus type based on available information
        let bonusType = determineBonusType()
        description += "\(bonusType) after spending $\(minSpend) in \(timeframe/30) months"
        
        if let offerDetails = details, !offerDetails.isEmpty {
            description += ". Note: \(offerDetails)"
        }
        
        // Format display name
        let displayName = formatDisplayName()
        
        // Determine category
        let category = determineCategory()
        
        return CreditCardInfo(
            id: self.cardId,
            name: displayName,
            issuer: formatIssuerName(),
            category: category,
            description: description,
            annualFee: Double(self.annualFee),
            signupBonus: bonusAmount,
            regularAPR: "See issuer website",
            imageName: self.imageUrl,
            applyURL: self.url
        )
    }
    
    // Format the issuer name to be more readable
    private func formatIssuerName() -> String {
        return issuer
            .replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    // Format the card name for display
    private func formatDisplayName() -> String {
        // If issuer is part of the name, don't duplicate it
        if name.lowercased().contains(issuer.lowercased().replacingOccurrences(of: "_", with: " ")) {
            return name
        } else {
            return name
        }
    }
    
    // Determine the bonus type based on the card details
    private func determineBonusType() -> String {
        if universalCashbackPercent != nil && universalCashbackPercent ?? 0 > 0 {
            return "cash back"
        } else if issuer == "AMERICAN_EXPRESS" {
            return "Membership Rewards points"
        } else if issuer == "CHASE" {
            return "Ultimate Rewards points"
        } else if issuer == "CAPITAL_ONE" {
            return "Venture miles"
        } else if name.lowercased().contains("marriott") {
            return "Marriott Bonvoy points"
        } else if name.lowercased().contains("hilton") {
            return "Hilton Honors points"
        } else if name.lowercased().contains("delta") {
            return "Delta SkyMiles"
        } else if name.lowercased().contains("united") {
            return "United miles"
        } else {
            return "points"
        }
    }
    
    // Determine the card category
    private func determineCategory() -> String {
        // Check card name first for specific patterns
        let lowercaseName = name.lowercased()
        
        if isBusiness {
            return "Business"
        } else if universalCashbackPercent != nil && universalCashbackPercent ?? 0 > 0 {
            return "Cashback"
        } else if lowercaseName.contains("sapphire") {
            return "Travel"
        } else if lowercaseName.contains("freedom") || lowercaseName.contains("cash") {
            return "Cashback"
        } else if lowercaseName.contains("gold") || lowercaseName.contains("platinum") {
            return "Travel"
        } else if lowercaseName.contains("marriott") || lowercaseName.contains("hilton") ||
                  lowercaseName.contains("hyatt") || lowercaseName.contains("ihg") {
            return "Hotel"
        } else if lowercaseName.contains("delta") || lowercaseName.contains("united") ||
                  lowercaseName.contains("southwest") || lowercaseName.contains("aadvantage") {
            return "Airline"
        } else if lowercaseName.contains("business") || lowercaseName.contains("ink") {
            return "Business"
        }
        
        // Default category
        return "Travel"
    }
}
