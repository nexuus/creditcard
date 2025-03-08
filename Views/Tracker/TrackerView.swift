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
                                // Horizontal scrolling cards
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(viewModel.getActiveCards()) { card in
                                            NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                                HorizontalCardView(card: card, viewModel: viewModel)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 12)
                                }
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

// New Horizontal Card View for active cards
struct HorizontalCardView: View {
    var card: CreditCard
    var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        // Card container
        ZStack {
            // Card background with gradient based on issuer
            RoundedRectangle(cornerRadius: 20)
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
                .shadow(color: getCardPrimaryColor(for: card.issuer).opacity(0.4),
                        radius: 10, x: 0, y: 5)
            
            // Card content with proper alignment
            VStack(alignment: .center, spacing: 12) {
                // Top row with issuer logo and card type
                HStack(alignment: .center) {
                    // Issuer circle - with proper centering
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: 40, height: 40)
                        
                        Text(String(card.issuer.prefix(1)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .multilineTextAlignment(.center)
                    }
                    
                    Spacer()
                    
                    // Card type chip - with better padding and alignment
                    Text(card.issuer)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(12)
                        .multilineTextAlignment(.center)
                }
                
                // Center spacer to push content apart
                Spacer()
                
                // Centered card name
                Text(card.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
                
                // Card details - evenly spaced with better alignment
                HStack(alignment: .center) {
                    // Annual fee section - aligned center
                    VStack(alignment: .center, spacing: 4) {
                        Text("ANNUAL FEE")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("$\(Int(card.annualFee))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Bonus section - aligned center
                    VStack(alignment: .center, spacing: 4) {
                        Text("BONUS")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        
                        Text("\(formattedNumber(card.signupBonus))")
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                // Status indicator - properly centered
                if !viewModel.isLoadingCardStatus {
                    Button(action: {
                        withAnimation(.spring()) {
                            viewModel.toggleBonusAchieved(for: card.id) { success in
                                if !success {
                                    let errorGenerator = UINotificationFeedbackGenerator()
                                    errorGenerator.notificationOccurred(.error)
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(card.bonusAchieved ? "EARNED" : "PENDING")
                                .font(.system(size: 12, weight: .bold))
                                .multilineTextAlignment(.center)
                            
                            Image(systemName: card.bonusAchieved ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 12))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(card.bonusAchieved
                                      ? Color.green.opacity(0.3)
                                      : Color.yellow.opacity(0.3))
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .padding()
        }
        .frame(width: 300, height: 190)
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
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

// Custom button style for card interactions
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
