//
//  CardSearchModel.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

//
//  CardSearchModel.swift
//  CreditCardTracker
//
//  Created by Hassan on 2/26/25.
//

import Foundation

// Simple model for card search results
struct CardSearchResult: Decodable, Identifiable {
    let cardKey: String
    let cardIssuer: String
    let cardName: String
    
    // Computed property to provide id for Identifiable conformance
    var id: String { cardKey }
    
    // Helper to convert to our main model
    func toCreditCardInfo() -> CreditCardInfo {
        // Create a basic CreditCardInfo with the limited data we have
        return CreditCardInfo(
            id: cardKey,
            name: cardName.replacingOccurrences(of: "®", with: "").replacingOccurrences(of: "℠", with: ""),
            issuer: cardIssuer,
            category: "Unknown", // Default category since we don't have this info
            description: "Details will be loaded when selected",
            annualFee: 0.0,
            signupBonus: 0,
            regularAPR: "See issuer website",
            imageName: "",
            applyURL: ""
        )
    }
}

// Type alias for the top-level response of search endpoint
typealias CardSearchAPIResponse = [CardSearchResult]
