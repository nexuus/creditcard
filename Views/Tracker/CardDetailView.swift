import SwiftUI
import Foundation
import Combine

struct CardDetailView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // State for the card display and alerts
    let initialCard: CreditCard
    @State private var card: CreditCard
    @State private var isRotated = false
    @State private var showingInactivateAlert = false
    @State private var showingReactivateAlert = false
    
    // Date formatter
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    // Initialize with card and viewModel
    init(card: CreditCard, viewModel: CardViewModel) {
        self.viewModel = viewModel
        self.initialCard = card
        self._card = State(initialValue: card)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Status indicator for inactive cards
                if !card.isActive {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This card is inactive as of \(dateFormatter.string(from: card.dateInactivated ?? Date()))")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }
                
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
                            .opacity(card.isActive ? 1.0 : 0.7) // Dim inactive cards
                        
                        // Flip hint
                        Text("Tap card to flip")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                }
                .padding(.top, 16)
                
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
                // Modern toggle switch
                ZStack {
                    Capsule()
                        .fill(card.bonusAchieved ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 50, height: 30)
                    
                    Circle()
                        .fill(Color.white)
                        .shadow(radius: 1)
                        .frame(width: 26, height: 26)
                        .offset(x: card.bonusAchieved ? 10 : -10)
                }
                .animation(.spring(), value: card.bonusAchieved)
                .onTapGesture {
                    // Use the consistent toggle method instead of manual update
                    viewModel.toggleBonusAchieved(for: card.id) { success in
                        if success {
                            // Update local state only if the toggle was successful
                            var updatedCard = card
                            updatedCard.bonusAchieved.toggle()
                            self.card = updatedCard
                            
                            // Extra verification that changes are saved
                            print("✅ Card status toggle successful in CardDetailView")
                            // Force an extra save to be certain
                            _ = viewModel.enhancedSaveCards()
                        } else {
                            // Show error feedback if the toggle failed
                            print("❌ Card status toggle failed in CardDetailView")
                            let errorGenerator = UINotificationFeedbackGenerator()
                            errorGenerator.notificationOccurred(.error)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                .padding(.horizontal)
                
                // Active/Inactive Toggle Button
                Button(action: {
                    if card.isActive {
                        showingInactivateAlert = true
                    } else {
                        showingReactivateAlert = true
                    }
                }) {
                    HStack {
                        Image(systemName: card.isActive ? "xmark.circle" : "checkmark.circle")
                            .font(.headline)
                        
                        Text(card.isActive ? "Mark as Inactive" : "Reactivate Card")
                            .font(.headline)
                    }
                    .foregroundColor(card.isActive ? .red : .green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                }
                .padding(.horizontal)
                
                // Card details section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Card Details")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    ModernDetailRow(title: "Card Name", value: card.name)
                    ModernDetailRow(title: "Issuer", value: card.issuer)
                    ModernDetailRow(title: "Date Opened", value: dateFormatter.string(from: card.dateOpened))
                    
                    if !card.isActive, let inactiveDate = card.dateInactivated {
                        ModernDetailRow(title: "Date Inactivated", value: dateFormatter.string(from: inactiveDate))
                    }
                    
                    ModernDetailRow(title: "Annual Fee", value: "$\(String(format: "%.2f", card.annualFee))")
                    ModernDetailRow(title: "Signup Bonus", value: "\(formattedNumber(card.signupBonus)) points")
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                .padding(.horizontal)
                
                // Notes section
                if !card.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Notes")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(card.notes)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .navigationTitle(card.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .alert("Mark Card as Inactive", isPresented: $showingInactivateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Mark Inactive", role: .destructive) {
                markCardInactive()
            }
        } message: {
            Text("This will mark the card as inactive as of today. You can reactivate it later if needed.")
        }
        .alert("Reactivate Card", isPresented: $showingReactivateAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reactivate") {
                reactivateCard()
            }
        } message: {
            Text("This will mark the card as active again.")
        }
    }
    
    // Function to handle inactivating the card
    private func markCardInactive() {
        var updatedCard = card
        updatedCard.isActive = false
        updatedCard.dateInactivated = Date()
        
        // Update in the ViewModel
        viewModel.updateCard(updatedCard)
        
        // Update local state
        card = updatedCard
        
        // Show feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // Function to handle reactivating the card
    private func reactivateCard() {
        var updatedCard = card
        updatedCard.isActive = true
        updatedCard.dateInactivated = nil
        
        // Update in the ViewModel
        viewModel.updateCard(updatedCard)
        
        // Update local state
        card = updatedCard
        
        // Show feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
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

// Supporting Views
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
                            getCardColor(for: card.issuer).opacity(0.9),
                            getCardColor(for: card.issuer)
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
                .shadow(color: getCardColor(for: card.issuer).opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Card content
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
                    
                    // Issuer logo/text and inactive badge in a proper HStack
                    HStack(spacing: 6) {
                        Text(card.issuer.uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                        
                        // Inactive badge
                        if !card.isActive {
                            Text("INACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.white.opacity(0.3))
                                .foregroundColor(.white)
                                .cornerRadius(4)
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
                            getCardColor(for: card.issuer),
                            getCardColor(for: card.issuer).opacity(0.8)
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
                .shadow(color: getCardColor(for: card.issuer).opacity(0.5), radius: 10, x: 0, y: 5)
            
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
                    
                    // Show inactive status if applicable
                    if !card.isActive, let inactiveDate = card.dateInactivated {
                        HStack {
                            Text("INACTIVE SINCE:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                            
                            Text(formatDateShort(inactiveDate))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.top, 8)
                    }
                    
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
    
    // Format short date for inactive status
    func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Get color for the card based on issuer
    func getCardColor(for issuer: String) -> Color {
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

// Modern detail row
struct ModernDetailRow: View {
    var title: String
    var value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
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
                .foregroundColor(.secondary)
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
