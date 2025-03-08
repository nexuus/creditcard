import SwiftUI
import Foundation
import Combine

// Replace this with your current CreditCard model in Models/CreditCard.swift
struct CreditCard: Identifiable, Codable, Equatable {
    // IMPORTANT: Use CodingKeys to ensure consistent encoding/decoding
    enum CodingKeys: String, CodingKey {
        case id, name, issuer, dateOpened, signupBonus, bonusAchieved, annualFee, notes, isActive, dateInactivated
    }
    
    var id = UUID()
    var name: String
    var issuer: String
    var dateOpened: Date
    var signupBonus: Int
    var bonusAchieved: Bool
    var annualFee: Double
    var notes: String
    var isActive: Bool = true
    var dateInactivated: Date? = nil
    
    var cardColor: Color {
        switch issuer.lowercased() {
        case "chase": return Color.blue
        case "american express", "amex": return Color.green
        case "citi": return Color.red
        case "capital one": return Color.orange
        default: return Color.gray
        }
    }
    
    // Implement explicit Equatable to help with comparisons
    static func == (lhs: CreditCard, rhs: CreditCard) -> Bool {
        return lhs.id == rhs.id &&
               lhs.name == rhs.name &&
               lhs.issuer == rhs.issuer &&
               lhs.dateOpened == rhs.dateOpened &&
               lhs.signupBonus == rhs.signupBonus &&
               lhs.bonusAchieved == rhs.bonusAchieved &&
               lhs.annualFee == rhs.annualFee &&
               lhs.notes == rhs.notes &&
               lhs.isActive == rhs.isActive &&
               lhs.dateInactivated == rhs.dateInactivated
    }
}
