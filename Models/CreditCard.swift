//
//  CreditCard.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

// Then your own types if needed (usually not necessary since they're in the same module)
// import MyCustomTypes

struct CreditCard: Identifiable, Codable {
    var id = UUID()
    var name: String
    var issuer: String
    var dateOpened: Date
    var signupBonus: Int
    var bonusAchieved: Bool
    var annualFee: Double
    var notes: String
    var cardColor: Color {
        switch issuer.lowercased() {
        case "chase": return Color.blue
        case "american express", "amex": return Color.green
        case "citi": return Color.red
        case "capital one": return Color.orange
        default: return Color.gray
        }
    }
}
