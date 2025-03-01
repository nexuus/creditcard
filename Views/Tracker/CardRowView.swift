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
    @State private var isPressed = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Top color bar representing the card issuer
            Rectangle()
                .fill(AppTheme.Colors.issuerColor(for: card.issuer))
                .frame(height: 8)
                .clipShape(
                    RoundedShape(corners: [.topLeft, .topRight], radius: AppTheme.Layout.cardCornerRadius)
                )
            
            // Main card content
            HStack(spacing: 16) {
                // Card logo circle
                ZStack {
                    Circle()
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
                        .frame(width: 50, height: 50)
                        .shadow(color: AppTheme.Colors.issuerColor(for: card.issuer).opacity(0.5),
                                radius: 4, x: 0, y: 2)
                    
                    Text(String(card.issuer.prefix(1)))
                        .font(.system(size: 22, weight: .bold))
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
                    // Points value
                    Text("\(formattedNumber(card.signupBonus))")
                        .font(AppTheme.Typography.cardPoints)
                        .foregroundColor(AppTheme.Colors.primary)
                    
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
                                      ? AppTheme.Colors.secondary.opacity(0.15)
                                      : AppTheme.Colors.accent.opacity(0.15))
                        )
                        .foregroundColor(card.bonusAchieved
                                         ? AppTheme.Colors.secondary
                                         : AppTheme.Colors.accent)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        }
        // Full card container with shadow
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius))
        .shadow(
            color: Color.black.opacity(0.07),
            radius: 8,
            x: 0,
            y: isPressed ? 2 : 4
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(AppTheme.Animations.quick, value: isPressed)
        .onTapGesture {
            withAnimation {
                isPressed = true
                
                // Reset after a short delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation {
                        isPressed = false
                    }
                }
            }
        }
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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

// Preview provider for development
struct CardRowView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = CardViewModel()
        let dummyCard = CreditCard(
            name: "Sapphire Preferred",
            issuer: "Chase",
            dateOpened: Date().addingTimeInterval(-180*24*3600),
            signupBonus: 60000,
            bonusAchieved: true,
            annualFee: 95,
            notes: "Met spending requirement in month 2"
        )
        
        CardRowView(card: dummyCard, viewModel: viewModel)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
