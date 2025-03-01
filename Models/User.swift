//
//  User.swift
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

// User model for account functionality
struct User: Codable {
    var id: UUID
    var email: String
    var name: String
    var cards: [CreditCard]
    
    init(email: String, name: String) {
        self.id = UUID()
        self.email = email
        self.name = name
        self.cards = []
    }
}
