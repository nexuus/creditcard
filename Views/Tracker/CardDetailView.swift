//
//  CardDetailView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

//
//  CardDetailView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.

struct CardDetailView: View {
    var card: CreditCard
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var isRotated = false
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Layout.spacing) {
                // 3D credit card visualization
                ZStack {
                    // Card visualization
                    VStack {
                        CreditCardView(card: card, isBackVisible: isRotated)
                            .frame(height: 220)
                            .rotation3DEffect(
                                Angle(degrees: isRotated ? 180 : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                withAnimation(.spring()) {
                                    isRotated.toggle()
                                }
                            }
                        
                        // Flip hint
                        Text("Tap card to flip")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.tertiaryText)
                            .padding(.top, 8)
                    }
                }
                .padding(.vertical, 16)
                
                // Quick stats
                HStack(spacing: 20) {
                    QuickStatView(
                        title: "Bonus",
                        value: formattedNumber(card.signupBonus),
                        iconName: "star.fill",
                        iconColor: .yellow
                    )
                    
                    QuickStatView(
                        title: "Annual Fee",
                        value: "$\(Int(card.annualFee))",
                        iconName: "dollarsign.circle.fill",
                        iconColor: .red
                    )
                    
                    QuickStatView(
                        title: "Days Open",
                        value: "\(daysSinceOpened())",
                        iconName: "calendar",
                        iconColor: .blue
                    )
                }
                .padding(.horizontal)
                
                // Status section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bonus Status")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(card.bonusAchieved ? "Bonus Achieved" : "Bonus Pending")
                                .font(.headline)
                                .foregroundColor(card.bonusAchieved ? AppTheme.Colors.secondary : .orange)
                            
                            Text(card.bonusAchieved ? "You've earned these points!" : "Still working toward this bonus")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Modern toggle switch
                        ZStack {
                            Capsule()
                                .fill(card.bonusAchieved ? AppTheme.Colors.secondary : Color.gray.opacity(0.3))
                                .frame(width: 50, height: 30)
                            
                            Circle()
                                .fill(Color.white)
                                .shadow(radius: 1)
                                .frame(width: 26, height: 26)
                                .offset(x: card.bonusAchieved ? 10 : -10)
                        }
                        .animation(AppTheme.Animations.standard, value: card.bonusAchieved)
                        .onTapGesture {
                            viewModel.toggleBonusAchieved(for: card.id)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal)
                
                // Card details section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card Details")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    ModernDetailRow(title: "Card Name", value: card.name)
                    ModernDetailRow(title: "Issuer", value: card.issuer)
                    ModernDetailRow(title: "Date Opened", value: dateFormatter.string(from: card.dateOpened))
                    ModernDetailRow(title: "Annual Fee", value: "$\(String(format: "%.2f", card.annualFee))")
                    ModernDetailRow(title: "Signup Bonus", value: "\(formattedNumber(card.signupBonus)) points")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal)
                
                // Notes section
                if !card.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.text)
                        
                        Text(card.notes)
                            .font(.body)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                            )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                            .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                    )
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Calculate days since card was opened
    func daysSinceOpened() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: card.dateOpened, to: Date())
        return components.day ?? 0
    }
}

// 3D credit card visualization
struct CreditCardView: View {
    var card: CreditCard
    var isBackVisible: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // Back of the card
                cardBack
            } else {
                // Front of the card
                cardFront
            }
        }
    }
    
    // Front of the card
    var cardFront: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.Colors.issuerColor(for: card.issuer).opacity(0.9),
                            AppTheme.Colors.issuerColor(for: card.issuer)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Add subtle pattern overlay
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: AppTheme.Colors.issuerColor(for: card.issuer).opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Card content
            VStack(alignment: .leading) {
                // Top section with chip and issuer
                HStack {
                    // Chip
                    Rectangle()
                        .fill(Color.yellow.opacity(0.8))
                        .frame(width: 45, height: 35)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    // Issuer logo/text
                    Text(card.issuer.uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Card number placeholders
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { i in
                        Text(i == 3 ? "•••• 1234" : "••••")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Bottom row with name and expiry
                HStack {
                    // Cardholder name
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CARDHOLDER")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        Text("YOUR NAME")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Expiry date based on card open date
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("EXPIRES")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        let expiryDate = Calendar.current.date(byAdding: .year, value: 4, to: card.dateOpened) ?? Date()
                        Text("\(expiryMonth(from: expiryDate))/\(expiryYear(from: expiryDate))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
        }
    }
    
    // Back of the card
    var cardBack: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            AppTheme.Colors.issuerColor(for: card.issuer),
                            AppTheme.Colors.issuerColor(for: card.issuer).opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Add subtle pattern overlay
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: AppTheme.Colors.issuerColor(for: card.issuer).opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Card content
            VStack {
                // Magnetic stripe
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 50)
                    .padding(.top, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    // CVV section
                    HStack {
                        // White signature strip
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(height: 40)
                            .overlay(
                                Text("CVV: •••")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .padding(.trailing)
                                , alignment: .trailing
                            )
                    }
                    
                    // Points and program info
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REWARDS PROGRAM")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("Signup Bonus:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            Text(formattedNumber(card.signupBonus) + " Points")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Status indicator
                            Text(card.bonusAchieved ? "ACHIEVED" : "PENDING")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(card.bonusAchieved ? Color.green : Color.orange)
                                )
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)
                    
                    // Legal text
                    Text("This card is subject to the terms and conditions of your cardholder agreement.")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.top, 12)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        // Flip the back of the card
        .rotation3DEffect(
            Angle(degrees: 180),
            axis: (x: 0, y: 1, z: 0)
        )
    }
    
    // Helper to format month for expiry date
    func expiryMonth(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter.string(from: date)
    }
    
    // Helper to format year for expiry date
    func expiryYear(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yy"
        return formatter.string(from: date)
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Modern detail row
struct ModernDetailRow: View {
    var title: String
    var value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6).opacity(0.5))
        )
    }
}

// Quick stat view
struct QuickStatView: View {
    var title: String
    var value: String
    var iconName: String
    var iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: iconName)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )
            
            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.8)
                .lineLimit(1)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
}
