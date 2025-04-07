import Foundation
import SwiftUI

struct CreditCardBonus: Codable, Identifiable {
    var id: String { "\(issuer)-\(name.replacingOccurrences(of: " ", with: "-").lowercased())" }
    let name: String
    let issuer: String
    let annualFee: Int
    let bonusAmount: Int
    let bonusAmountExtra: Int?
    let bonusType: String
    let minSpend: Int
    let timeframe: Int
    let addedDate: String
    let notes: String?
    let url: String?
    
    // Convert to app's CreditCardInfo format
    func toCreditCardInfo() -> CreditCardInfo {
        let description = notes ?? "Earn \(bonusAmount) \(bonusType) after spending $\(minSpend) in \(timeframe) months"
        
        return CreditCardInfo(
            id: self.id,
            name: self.name,
            issuer: self.issuer,
            category: getCategoryFromBonus(),
            description: description,
            annualFee: Double(self.annualFee),
            signupBonus: self.bonusAmount,
            regularAPR: "See issuer website",
            imageName: "",
            applyURL: self.url ?? ""
        )
    }
    
    // Helper to determine category based on bonus type
    private func getCategoryFromBonus() -> String {
        if bonusType.lowercased().contains("miles") || 
           bonusType.lowercased().contains("airline") {
            return "Airline"
        } else if bonusType.lowercased().contains("hotel") {
            return "Hotel"
        } else if bonusType.lowercased().contains("cash") {
            return "Cashback"
        } else {
            return "Travel"
        }
    }
}

struct HistoricalBonus: Codable, Identifiable {
    var id: String { "\(issuer)-\(name)-\(date)" }
    let name: String
    let issuer: String
    let date: String
    let bonusAmount: Int
    let bonusType: String
}