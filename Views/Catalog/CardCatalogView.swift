import SwiftUI
import Foundation
import Combine

// MARK: - CardCatalogView
struct CardCatalogView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedBank: String? = nil
    @State private var expandedBanks: Set<String> = []
    @State private var isRefreshing = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search cards", text: $searchText)
                            .disableAutocorrection(true)
                        
                        if !searchText.isEmpty {
                            Button(action: {
                                searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding()
                    .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                    // Bank filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryButton(
                                title: "All Banks",
                                isSelected: selectedBank == nil,
                                action: { selectedBank = nil }
                            )
                            
                            ForEach(availableCategories, id: \.self) { bank in
                                CategoryButton(
                                    title: bank,
                                    isSelected: selectedBank == bank,
                                    action: { selectedBank = bank }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Status information
                    HStack {
                        if !searchText.isEmpty {
                            Text("Showing search results")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Showing top 10 most popular cards from each bank")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        // Refresh button
                        Button(action: {
                            refreshCardCatalog()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                                .opacity(isRefreshing ? 0.5 : 1.0)
                        }
                        .disabled(isRefreshing)
                        .padding(.trailing)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 4)
                    
                    // Cards display
                    if !searchText.isEmpty {
                        // Search results
                        SearchResultsView(viewModel: viewModel, searchText: searchText)
                    } else if viewModel.isLoadingCards {
                        // Loading view
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .padding()
                            
                            Text("Loading credit card catalog...")
                                .foregroundColor(.secondary)
                            
                            Text("This may take a moment")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        // Organized card catalog
                        OrganizedCatalogView(
                            viewModel: viewModel,
                            selectedBank: selectedBank,
                            expandedBanks: $expandedBanks
                        )
                    }
                }
            }
            .navigationTitle("Card Catalog")
        }
    }
    
    // Available banks for filtering
    private var availableCategories: [String] {
        return CardCategoryManager.shared.getAllCategories()
    }
    
    // Method to refresh the card catalog
    private func refreshCardCatalog() {
        isRefreshing = true
        
        Task {
            await viewModel.loadCreditCardsFromAPI()
            
            // Add a slight delay to make the refresh feel more substantial
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// MARK: - Search Results View
struct SearchResultsView: View {
    let viewModel: CardViewModel
    let searchText: String
    
    var body: some View {
        let filteredCards = viewModel.searchCreditCards(searchTerm: searchText)
        
        if filteredCards.isEmpty {
            VStack(spacing: 24) {
                Image(systemName: "creditcard")
                    .font(.system(size: 64))
                    .foregroundColor(.gray)
                    .padding(.top, 40)
                
                Text("No Cards Found")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Try a different search term")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Text("Found \(filteredCards.count) cards")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    ForEach(filteredCards) { card in
                        NavigationLink(destination: CardDetailCatalogView(card: card)) {
                            CatalogCardView(card: card)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - OrganizedCatalogView
struct OrganizedCatalogView: View {
    let viewModel: CardViewModel
    let selectedBank: String?
    @Binding var expandedBanks: Set<String>
    
    // List of popular banks to show
    private let popularBanks = ["Chase", "Wells Fargo", "Citi", "American Express", "Amex", "Capital One", "Barclays", "Barclays US", "Bank of America", "Discover"]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Using the new method to avoid ambiguity
                let topCardsByBank = viewModel.getCardsFromMajorIssuers(limit: 10)
                
                // Filter to only show popular banks
                let filteredBanks = topCardsByBank.keys.filter { bank in
                    return popularBanks.contains { popularBank in
                        bank.lowercased().contains(popularBank.lowercased())
                    }
                }
                
                let visibleBanks = selectedBank != nil ?
                    [selectedBank!] :
                    filteredBanks.sorted(by: { $0.lowercased() < $1.lowercased() })
                
                // If no specific bank is selected and we have cards, add a "Most Popular Cards" section
                if selectedBank == nil && !topCardsByBank.isEmpty {
                    PopularCardsSection(topCardsByBank: topCardsByBank)
                }
                
                // Then show all banks
                ForEach(visibleBanks, id: \.self) { bank in
                    if let bankCards = topCardsByBank[bank] {
                        SimpleBankSection(
                            bank: bank,
                            cards: bankCards,
                            isExpanded: expandedBanks.contains(bank) || selectedBank != nil,
                            toggleExpand: {
                                if expandedBanks.contains(bank) {
                                    expandedBanks.remove(bank)
                                } else {
                                    expandedBanks.insert(bank)
                                }
                            }
                        )
                    }
                }
            }
            .padding()
        }
    }
}

// MARK: - PopularCardsSection
struct PopularCardsSection: View {
    let topCardsByBank: [String: [CreditCardInfo]]
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Most Popular Cards")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Card count badge
                Text("\(popularCards.count) cards")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(8)
            }
            .padding()
            .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
            
            // Popular cards horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Add some spacing at the beginning
                    Spacer()
                        .frame(width: 8)
                    
                    ForEach(popularCards) { card in
                        NavigationLink(destination: CardDetailCatalogView(card: card)) {
                            CompactCardView(card: card)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    // Add some spacing at the end
                    Spacer()
                        .frame(width: 8)
                }
                .padding(.vertical, 12)
            }
        }
    }
    
    // Find the 10 most popular cards across all banks
    private var popularCards: [CreditCardInfo] {
        // Flatten all cards from all banks
        let allCards = topCardsByBank.values.flatMap { $0 }
        
        // Sort by signup bonus (as a proxy for popularity)
        let sortedCards = allCards.sorted { $0.signupBonus > $1.signupBonus }
        
        // Return top 10
        return Array(sortedCards.prefix(10))
    }
}

// MARK: - SimpleBankSection
struct SimpleBankSection: View {
    let bank: String
    let cards: [CreditCardInfo]
    let isExpanded: Bool
    let toggleExpand: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Bank header
            Button(action: toggleExpand) {
                HStack {
                    Text(bank)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Card count badge
                    Text("\(cards.count) cards")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                    
                    // Expand/collapse indicator
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                        .padding(.leading, 4)
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                // Display cards in a horizontal scroll
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        // Add some spacing at the beginning
                        Spacer()
                            .frame(width: 8)
                        
                        ForEach(cards) { card in
                            NavigationLink(destination: CardDetailCatalogView(card: card)) {
                                CompactCardView(card: card)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Add some spacing at the end
                        Spacer()
                            .frame(width: 8)
                    }
                    .padding(.vertical, 12)
                }
                
                // "View all" button for this bank
                Button(action: {
                    // This would navigate to a filtered view of all cards from this bank
                    // For now it's just visual
                }) {
                    HStack {
                        Text("View all \(bank) cards")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

// MARK: - CompactCardView
struct CompactCardView: View {
    let card: CreditCardInfo
    @State private var cardImage: UIImage? = nil
    @State private var isLoadingImage: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Card header with issuer color
            HStack {
                Text(card.issuer)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(card.category)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.3))
                    .cornerRadius(6)
                    .foregroundColor(.white)
            }
            .padding(12)
            .background(getCategoryColor(for: card.category))
            
            // Card image or placeholder
            ZStack {
                if isLoadingImage {
                    // Loading state
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(height: 80)
                } else if let image = cardImage {
                    // Image loaded
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 80)
                        .padding(.horizontal, 12)
                } else {
                    // Placeholder
                    Image(systemName: "creditcard.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 50)
                        .padding(.horizontal, 12)
                        .foregroundColor(getCategoryColor(for: card.category).opacity(0.3))
                }
            }
            .frame(height: 80)
            .padding(.vertical, 8)
            
            // Card details
            VStack(alignment: .leading, spacing: 8) {
                Text(card.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.primary)
                
                // Fee and bonus
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Annual Fee")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("$\(Int(card.annualFee))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Bonus")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text("\(formattedNumber(card.signupBonus))")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .frame(width: 180, height: 210)
        .background(colorScheme == .dark ? Color(.systemGray6) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            loadCardImage()
        }
    }
    
    // Load card image
    private func loadCardImage() {
        isLoadingImage = true
        
        Task {
            if let image = await CreditCardService.shared.fetchCardImageEnhanced(for: card.id, card: card) {
                await MainActor.run {
                    self.cardImage = image
                    self.isLoadingImage = false
                }
            } else {
                await MainActor.run {
                    self.isLoadingImage = false
                }
            }
        }
    }

    
    // Format large numbers with commas
    private func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    private func getCategoryColor(for category: String) -> Color {
        return CardCategoryManager.shared.colorForCategory(category)
    }
}

// MARK: - Extension for CardViewModel
extension CardViewModel {
    // Function to get top cards for each issuer - simple version without categories
    func getPopularCardsByIssuer(limit: Int = 10) -> [String: [CreditCardInfo]] {
        // Popular banks to filter
        let popularBanks = ["Chase", "Wells Fargo", "Citi", "American Express", "Amex", "Capital One", "Barclays", "Barclays US", "Bank of America", "Discover"]
        
        // Group all cards by issuer first
        let cardsByIssuer = Dictionary(grouping: availableCreditCards) { $0.issuer }
        
        var result: [String: [CreditCardInfo]] = [:]
        
        // Process each issuer
        for (issuer, cards) in cardsByIssuer {
            // Skip issuers that aren't in our popular banks list
            let isPopularBank = popularBanks.contains { popularBank in
                issuer.lowercased().contains(popularBank.lowercased())
            }
            
            if !isPopularBank {
                continue
            }
            
            // Sort all cards for this issuer by popularity (using signup bonus as a proxy)
            let sortedCards = cards.sorted { $0.signupBonus > $1.signupBonus }
            
            // Take only the top cards
            result[issuer] = Array(sortedCards.prefix(limit))
        }
        
        return result
    }
}
