//
//  CatalogCardView.swift
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

struct CatalogCardView: View {
    let card: CreditCardInfo
    @State private var cardImage: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    @State private var imageLoadError: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header with issuer color
            HStack {
                Text(card.issuer)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(card.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(8)
                    .foregroundColor(.white)
            }
            .padding()
            .background(getCategoryColor(for: card.category))
            
            // Card content
            VStack(alignment: .leading, spacing: 12) {
                Text(card.name)
                    .font(.title3)
                    .fontWeight(.bold)
                
                // Card image section - using cardKey for image fetching
                cardImageView
                
                // Card highlights
                VStack(spacing: 8) {
                    KeyValueRow(key: "Annual Fee", value: "$\(String(format: "%.2f", card.annualFee))")
                    
                    KeyValueRow(key: "Signup Bonus", value: "\(formatPoints(card.signupBonus)) points")
                    
                    KeyValueRow(key: "Regular APR", value: card.regularAPR)
                }
                .padding(.top, 8)
                
                // Description snippet
                Text(card.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .padding(.top, 8)
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .onAppear {
            loadCardImage()
        }
    }
    
    // Card image view with loading states
    private var cardImageView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                .frame(height: 160)
            
            if isLoadingImage {
                // Loading state
                ProgressView()
                    .scaleEffect(1.2)
            } else if let image = cardImage {
                // Image loaded successfully
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 160)
                    .cornerRadius(8)
                    .transition(.opacity)
            } else if imageLoadError {
                // Error loading image
                VStack(spacing: 8) {
                    Image(systemName: "creditcard.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 60)
                        .foregroundColor(getCategoryColor(for: card.category).opacity(0.5))
                    
                    Text(card.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                // Fallback image when no URL available
                Image(systemName: "creditcard.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(getCategoryColor(for: card.category).opacity(0.5))
            }
        }
    }
    
    // Load image using cardKey
    private func loadCardImage() {
        isLoadingImage = true
        imageLoadError = false
        
        Task {
            do {
                // First try to load from the dedicated card image endpoint
                if let image = await CreditCardService.shared.fetchCardImage(for: card.id) {
                    await MainActor.run {
                        withAnimation {
                            self.cardImage = image
                            self.isLoadingImage = false
                        }
                    }
                    return
                }
                
                // Fallback to using imageName if it's a URL
                if !card.imageName.isEmpty {
                    if let image = await CreditCardService.shared.fetchCardImageFromURL(for: card.imageName) {
                        await MainActor.run {
                            withAnimation {
                                self.cardImage = image
                                self.isLoadingImage = false
                            }
                        }
                        return
                    }
                }
                
                // If both methods fail, show error state
                throw URLError(.cannotDecodeRawData)
            } catch {
                await MainActor.run {
                    withAnimation {
                        self.imageLoadError = true
                        self.isLoadingImage = false
                    }
                }
            }
        }
    }
    
    // Format points with comma separators
    private func formatPoints(_ points: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: points)) ?? "\(points)"
    }
    
    // Get color based on card category
    func getCategoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "travel":
            return .blue
        case "cashback":
            return .green
        case "business":
            return .purple
        case "hotel":
            return .orange
        case "airline":
            return .red
        case "groceries":
            return .green
        case "dining":
            return .orange
        case "gas":
            return .purple
        default:
            return .gray
        }
    }
}

// Helper view for displaying key-value pairs
struct KeyValueRow: View {
    let key: String
    let value: String
    
    var body: some View {
        HStack {
            Text(key)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// Preview provider for development
#Preview {
    let sampleCard = CreditCardInfo(
        id: "chase-sapphire-preferred",
        name: "Sapphire Preferred",
        issuer: "Chase",
        category: "Travel",
        description: "Earn 60,000 bonus points after you spend $4,000 on purchases in the first 3 months from account opening.",
        annualFee: 95.00,
        signupBonus: 60000,
        regularAPR: "18.24% - 25.24% Variable",
        imageName: "https://example.com/card-image.png",
        applyURL: "https://creditcards.chase.com/rewards-credit-cards/sapphire/preferred"
    )
    
    return CatalogCardView(card: sampleCard)
        .padding()
        .previewLayout(.sizeThatFits)
}
