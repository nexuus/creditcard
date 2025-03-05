import SwiftUI
import Foundation
import Combine

struct CardRowView: View {
    var card: CreditCard
    var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 0) {
            // Top color bar representing the card issuer
            LinearGradient(
                gradient: Gradient(colors: [
                    getCardPrimaryColor(for: card.issuer),
                    getCardSecondaryColor(for: card.issuer)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(height: 10)
            .clipShape(
                RoundedShape(corners: [.topLeft, .topRight], radius: 16)
            )
            .opacity(card.isActive ? 1.0 : 0.5) // Dim for inactive cards
            
            // Main card content
            HStack(spacing: 16) {
                // Card logo circle
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
                        .opacity(card.isActive ? 1.0 : 0.5) // Dim for inactive cards
                    
                    Text(String(card.issuer.prefix(1)))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                // Card details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .center, spacing: 6) {
                        Text(card.name)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        // Inactive badge
                        if !card.isActive {
                            Text("Inactive")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                        }
                    }
                    
                    Text(card.issuer)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.secondary)
                    
                    // Card metrics in a horizontal stack with tighter spacing
                    HStack(spacing: 8) {
                        // Annual fee
                        Label(
                            title: { Text("$\(Int(card.annualFee))").font(.caption).bold() },
                            icon: { Image(systemName: "dollarsign.circle.fill").foregroundColor(.gray) }
                        )
                        .foregroundColor(.secondary)
                        
                        // Points - moved closer together
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            
                            Text("\(formattedNumber(card.signupBonus))")
                                .font(.caption)
                                .bold()
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 4)
                    
                    // Show date inactivated if applicable
                    if !card.isActive, let dateInactivated = card.dateInactivated {
                        Text("Since \(formattedDate(dateInactivated))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                // Right side elements
                VStack(alignment: .trailing, spacing: 6) {
                    // Points value with more appealing color
                    Text("\(formattedNumber(card.signupBonus))")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(getCardPrimaryColor(for: card.issuer))
                        .opacity(card.isActive ? 1.0 : 0.6) // Dim for inactive cards
                    
                    // Status button
                    if card.isActive {
                        Button(action: {
                            withAnimation(.spring()) {
                                var updatedCard = card
                                updatedCard.bonusAchieved.toggle()
                                viewModel.updateCard(updatedCard)
                                
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
                    } else {
                        // For inactive cards, show when it was inactivated
                        if let dateInactivated = card.dateInactivated {
                            Text(timeAgo(from: dateInactivated))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .opacity(card.isActive ? 1.0 : 0.8) // Slightly dim inactive cards
        }
        // Full card container with enhanced shadow and slight border
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorScheme == .dark ? Color.gray.opacity(0.2) : Color.gray.opacity(0.1), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(
            color: Color.black.opacity(card.isActive ? 0.08 : 0.04),
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
    
    // Format date
    func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Time ago string
    func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Get vibrant primary color based on issuer
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
