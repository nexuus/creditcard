import SwiftUI
import Foundation
import Combine

struct TrackerView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var showingAddCard = false
    @State private var showInactiveCards = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content wrapped in ScrollView
                ScrollView {
                    VStack(spacing: 0) {
                        // Dashboard summary
                        DashboardView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Active Cards Section
                        VStack(spacing: 8) {
                            // Section header for active cards
                            HStack {
                                Text("Active Cards")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Count of active cards
                                Text("\(viewModel.getActiveCards().count) cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                            
                            // Active cards - HORIZONTAL SCROLLING LAYOUT
                            // Active cards section with horizontal scrolling
                            // Replace this section in your TrackerView.swift file:
                            
                            // Active cards section with horizontal scrolling
                            // Replace this section in your TrackerView.swift file:
                            
                            // Active cards section with horizontal scrolling
                            if viewModel.getActiveCards().isEmpty {
                                // Empty state for active cards
                                VStack(spacing: 20) {
                                    Text("No Active Cards")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
                                    Button(action: {
                                        showingAddCard = true
                                    }) {
                                        Text("Add Card")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.blue)
                                            .cornerRadius(10)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                // Improved scrolling cards layout using the CreditCardView style
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        // Extra spacing at start for visual balance
                                        Spacer()
                                            .frame(width: 8)
                                        
                                        ForEach(viewModel.getActiveCards()) { card in
                                            NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                                HorizontalCardView(card: card, viewModel: viewModel)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                        }
                                        
                                        // Extra spacing at end for visual balance
                                        Spacer()
                                            .frame(width: 8)
                                    }
                                    .padding(.vertical, 12)
                                }
                                .clipShape(Rectangle())
                                .padding(.vertical, 8)
                            }
                            
                            // Card Switcher (Pagination indicator)
                            if viewModel.getActiveCards().count > 1 {
                                HStack(spacing: 8) {
                                    ForEach(0..<min(viewModel.getActiveCards().count, 5), id: \.self) { index in
                                        Circle()
                                            .fill(Color.blue.opacity(0.3))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                                .padding(.bottom, 16)
                            }
                        }
                        
                        // Add Card Button
                        Button(action: {
                            showingAddCard = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                
                                Text("Add New Card")
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                        }
                        .padding(.vertical, 16)
                        
                        // Inactive Cards Section - Keep as list view
                        VStack(spacing: 8) {
                            // Section header with toggle button
                            Button(action: {
                                withAnimation {
                                    showInactiveCards.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Inactive Cards")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Badge with inactive card count
                                    Text("\(viewModel.getInactiveCards().count) cards")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                    
                                    // Chevron that rotates
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(showInactiveCards ? 90 : 0))
                                        .animation(.spring(), value: showInactiveCards)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 4)
                            
                            // Inactive cards list (shown only when expanded)
                            if showInactiveCards {
                                if viewModel.getInactiveCards().isEmpty {
                                    // Empty state for inactive cards
                                    VStack(spacing: 20) {
                                        Text("No Inactive Cards")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 30)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // Inactive cards as vertical list
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.getInactiveCards()) { card in
                                            NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                                CardRowView(card: card, viewModel: viewModel)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                                }
                            }
                            
                        }
                        if !viewModel.cards.isEmpty {
                                                   DetailedStatsView(viewModel: viewModel)
                                                       .padding(.horizontal)
                                                       .padding(.top, 8)
                                                       .padding(.bottom, 24)
                                               }
                        
                    }
                    .padding(.top) // Add some padding at the top of the entire content
                }
                // End of ScrollView
            }
            .navigationTitle("Card Tracker")
            .sheet(isPresented: $showingAddCard) {
                AddCardView(viewModel: viewModel)
            }
        }
    }
    
    // Helper functions
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Updated HorizontalCardView using the same style as CreditCardView
// Updated HorizontalCardView using the same style as CreditCardView
struct HorizontalCardView: View {
    var card: CreditCard
    var viewModel: CardViewModel
    @State private var isPressed = false
    
    var body: some View {
        // Use a modified version of CreditCardView but always show the front
        ZStack {
            // Extra spacer to ensure corners aren't clipped
            Color.clear
            
            // Card front - adapted from CreditCardView
            ZStack(alignment: .topLeading) {
                // Background with authentic credit card styling
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                getCardPrimaryColor(for: card.issuer).opacity(0.9),
                                getCardPrimaryColor(for: card.issuer)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        // Add subtle pattern overlay for authenticity
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(color: getCardPrimaryColor(for: card.issuer).opacity(0.5), radius: 10, x: 0, y: 5)
                
                // Card content with proper credit card layout
                VStack(alignment: .leading) {
                    // Top section with chip and issuer
                    HStack(alignment: .center, spacing: 8) {
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
                        
                        // Issuer logo/text and status badge in a vertical stack
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(card.issuer.uppercased())
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Bonus status badge
                            if !viewModel.isLoadingCardStatus {
                                Text(card.bonusAchieved ? "EARNED" : "PENDING")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(
                                        Capsule()
                                            .fill(card.bonusAchieved ? Color.green.opacity(0.3) : Color.yellow.opacity(0.3))
                                    )
                                    .foregroundColor(.white)
                            }
                        }
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
                    
                    // Bottom row with name and sign-up bonus
                    HStack {
                        // Card name
                        VStack(alignment: .leading, spacing: 2) {
                            Text("CARD NAME")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(card.name)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        // Sign-up bonus
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("BONUS")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text("\(formattedNumber(card.signupBonus))")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding()
            }
        }
        .frame(width: 340, height: 185)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        // Remove the direct tap gesture since we're using NavigationLink
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Get color based on issuer - keep this identical to CreditCardView
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
}
    
// Enhanced CardButtonStyle with better animation
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .brightness(configuration.isPressed ? -0.05 : 0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
