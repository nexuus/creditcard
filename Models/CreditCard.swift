import SwiftUI
import Foundation
import Combine

struct CreditCard: Identifiable, Codable {
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
}
