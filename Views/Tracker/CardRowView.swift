//
//  CardRowView.swift
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

//
//  CardRowView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//


struct CardRowView: View {
    var card: CreditCard
    var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Top color bar representing the card issuer - more vibrant gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    getCardPrimaryColor(for: card.issuer),
                    getCardSecondaryColor(for: card.issuer)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 10) // Slightly taller for better visual impact
            .clipShape(
                RoundedShape(corners: [.topLeft, .topRight], radius: AppTheme.Layout.cardCornerRadius)
            )
            
            // Main card content
            HStack(spacing: 16) {
                // Card logo circle with modern gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    getCardPrimaryColor(for: card.issuer),
                                    getCardSecondaryColor(for: card.issuer)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                        .shadow(color: getCardPrimaryColor(for: card.issuer).opacity(0.4),
                                radius: 5, x: 0, y: 3)
                    
                    Text(String(card.issuer.prefix(1)))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Card details
                VStack(alignment: .leading, spacing: 4) {
                    Text(card.name)
                        .font(AppTheme.Typography.cardTitle)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(card.issuer)
                        .font(AppTheme.Typography.cardIssuer)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    // Card metrics in a horizontal stack
                    HStack(spacing: 12) {
                        // Annual fee
                        Label(
                            title: { Text("$\(Int(card.annualFee))").font(.caption).bold() },
                            icon: { Image(systemName: "dollarsign.circle.fill").foregroundColor(.gray) }
                        )
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                        
                        // Points
                        Label(
                            title: { Text("\(formattedNumber(card.signupBonus))").font(.caption).bold() },
                            icon: { Image(systemName: "star.fill").foregroundColor(.yellow) }
                        )
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    }
                    .padding(.top, 4)
                }
                
                Spacer()
                
                // Points and status on the right
                VStack(alignment: .trailing, spacing: 6) {
                    // Points value with more appealing color
                    Text("\(formattedNumber(card.signupBonus))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(getCardPrimaryColor(for: card.issuer))
                    
                    // Status button
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.toggleBonusAchieved(for: card.id)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Text(card.bonusAchieved ? "Earned" : "Pending")
                                .font(.system(size: 12, weight: .semibold))
                            
                            Image(systemName: card.bonusAchieved ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(card.bonusAchieved
                                      ? Color.green.opacity(0.15)
                                      : Color.orange.opacity(0.15))
                        )
                        .foregroundColor(card.bonusAchieved
                                         ? Color.green
                                         : Color.orange)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        }
        // Full card container with enhanced shadow and slight border
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                .stroke(Color.gray.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius))
        .shadow(
            color: Color.black.opacity(0.08),
            radius: 10,
            x: 0,
            y: 5
        )
        .contentShape(Rectangle()) // Makes the entire card tappable
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // MARK: - Helper Methods for Card Colors
    
    // Get a vibrant primary color based on issuer
    func getCardPrimaryColor(for issuer: String) -> Color {
        switch issuer.lowercased() {
        case "chase":
            return Color(red: 0.0, green: 0.45, blue: 0.94) // Vibrant blue
        case "american express", "amex":
            return Color(red: 0.13, green: 0.59, blue: 0.95) // Bright blue
        case "citi":
            return Color(red: 0.85, green: 0.23, blue: 0.23) // Vibrant red
        case "capital one":
            return Color(red: 0.98, green: 0.36, blue: 0.0) // Vibrant orange
        case "discover":
            return Color(red: 0.96, green: 0.65, blue: 0.14) // Bright yellow-orange
        case "wells fargo":
            return Color(red: 0.76, green: 0.06, blue: 0.15) // Deep red
        case "bank of america":
            return Color(red: 0.76, green: 0.15, blue: 0.26) // Wine red
        case "barclays":
            return Color(red: 0.15, green: 0.67, blue: 0.88) // Sky blue
        default:
            // Generate a nice color based on the issuer name
            let hash = issuer.hash
            let hue = Double(abs(hash) % 256) / 256.0
            return Color(hue: hue, saturation: 0.7, brightness: 0.9)
        }
    }
    
    // Get a complementary secondary color
    func getCardSecondaryColor(for issuer: String) -> Color {
        let primary = getCardPrimaryColor(for: issuer)
        
        // Extract the primary color components and create a complementary gradient color
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        UIColor(primary).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        
        // Adjust hue slightly for a nice gradient (not too contrasting)
        let newHue = fmod(hue + 0.05, 1.0)
        
        return Color(hue: Double(newHue), saturation: Double(saturation * 0.9), brightness: Double(brightness * 0.85))
    }
}

// Helper shape for rounded corners
struct RoundedShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
