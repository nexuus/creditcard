//
//  CardViewModel.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

class CardViewModel: ObservableObject {
    @Published var cards: [CreditCard] = []
    @Published var availableCreditCards: [CreditCardInfo] = []
    @Published var popularCreditCards: [CreditCardInfo] = []
    @Published var isLoadingCards: Bool = false
    @Published var isLoadingDetails: Bool = false
    @Published var apiLoadingError: String? = nil
    private var cancellables = Set<AnyCancellable>()
    
    // List of major banks to show by default
    private let majorBanks = [
        "Chase",
        "Citi",
        "American Express",
        "Amex", // Some cards list it as "Amex" instead of "American Express"
        "Wells Fargo",
        "Capital One"
    ]

    // Popular card types to prioritize
    private let popularCardTypes = [
        "sapphire", "gold", "platinum", "venture", "freedom", "cash", "premier",
        "reserve", "preferred", "double", "blue", "propel"
    ]
    
    // Popular card categories
    private let popularCategories = [
        "Travel", "Cashback", "Hotel", "Airline", "Groceries", "Dining", "Gas"
    ]
    
    init() {
        loadSampleData() // Keep for fallback
        
        // Load card catalog from API on startup
        Task {
            await loadCreditCardsFromAPI()
        }
        
        // Subscribe to user login changes
        UserService.shared.$isLoggedIn
            .sink { [weak self] isLoggedIn in
                if isLoggedIn {
                    self?.loadUserCards()
                }
            }
            .store(in: &cancellables)
        
        // Initial load of user cards if logged in
        if UserService.shared.isLoggedIn {
            loadUserCards()
        }
    }
    
    // MARK: - User Card Management
    
    
    func updateCard(_ card: CreditCard) {
            if let index = cards.firstIndex(where: { $0.id == card.id }) {
                cards[index] = card
                saveCards()
                // Force UI refresh
                objectWillChange.send()
            }
        }
        
        // Get active cards only
        func getActiveCards() -> [CreditCard] {
            return cards.filter { $0.isActive }
        }
        
        // Get inactive cards only
        func getInactiveCards() -> [CreditCard] {
            return cards.filter { !$0.isActive }
        }
    
    
    func loadSampleData() {
        cards = [
            CreditCard(name: "Sapphire Preferred", issuer: "Chase", dateOpened: Date().addingTimeInterval(-180*24*3600), signupBonus: 60000, bonusAchieved: true, annualFee: 95, notes: "Met spending requirement in month 2"),
            CreditCard(name: "Gold Card", issuer: "American Express", dateOpened: Date().addingTimeInterval(-90*24*3600), signupBonus: 75000, bonusAchieved: false, annualFee: 250, notes: "$2000 more spending needed by June 15"),
            CreditCard(name: "Venture X", issuer: "Capital One", dateOpened: Date().addingTimeInterval(-30*24*3600), signupBonus: 100000, bonusAchieved: false, annualFee: 395, notes: "Need to complete $10k spend")
        ]
    }
    
    func addCard(_ card: CreditCard) {
        cards.append(card)
        saveCards()
    }
    
    func deleteCard(at offsets: IndexSet) {
        cards.remove(atOffsets: offsets)
        saveCards()
    }
    
    func toggleBonusAchieved(for cardID: UUID) {
        if let index = cards.firstIndex(where: { $0.id == cardID }) {
            // Toggle the status
            cards[index].bonusAchieved.toggle()
            
            // Save changes immediately
            saveCards()
            
            // Optional: Add haptic feedback for better user experience
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            
            // Log the change for debugging
            let status = cards[index].bonusAchieved ? "earned" : "pending"
            let points = cards[index].signupBonus
            print("💾 Card status changed: \(cards[index].name) marked as \(status) (\(points) points)")
        }
    }

    func saveCardsLocally() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            UserDefaults.standard.set(data, forKey: "savedCards")
            
            print("💾 Cards saved locally: \(cards.count) cards")
        } catch {
            print("❌ Error saving cards locally: \(error)")
        }
    }
    
    func saveCards() {
        if UserService.shared.isLoggedIn {
            UserService.shared.updateUserCards(cards: cards)
        }
    }
    
    
    func totalHistoricalPoints() -> Int {
            return cards.filter { $0.bonusAchieved }.reduce(0) { $0 + $1.signupBonus }
        }
    // MARK: - Points and Statistics
    
    func totalPointsEarned() -> Int {
            return cards.filter { $0.bonusAchieved && $0.isActive }.reduce(0) { $0 + $1.signupBonus }
        }
    
    func pendingPoints() -> Int {
            return cards.filter { !$0.bonusAchieved && $0.isActive }.reduce(0) { $0 + $1.signupBonus }
        }
    
    func pointsByYear() -> [String: Int] {
            let calendar = Calendar.current
            var yearlyPoints: [String: Int] = [:]
            
            for card in cards where card.bonusAchieved {
                let year = calendar.component(.year, from: card.dateOpened)
                let yearString = String(year)
                yearlyPoints[yearString, default: 0] += card.signupBonus
            }
            
            return yearlyPoints
        }
        

    func lifetimePoints() -> Int {
        return totalPointsEarned()
    }

    func totalAnnualFees() -> Double {
           return cards.filter { $0.isActive }.reduce(0) { $0 + $1.annualFee }
       }

    func cardsOpenedByYear() -> [String: Int] {
           let calendar = Calendar.current
           var yearlyCards: [String: Int] = [:]
           
           for card in cards {
               let year = calendar.component(.year, from: card.dateOpened)
               let yearString = String(year)
               yearlyCards[yearString, default: 0] += 1
           }
           
           return yearlyCards
       }
    
    // MARK: - API Integration
    
    @MainActor
    func loadCreditCardsFromAPI() async {
        isLoadingCards = true
        apiLoadingError = nil
        
        do {
            print("📊 Fetching comprehensive credit card catalog...")
            // Using the comprehensive method to fetch all cards
            availableCreditCards = try await CreditCardService.shared.fetchComprehensiveCardCatalog()
            print("✅ Successfully loaded \(availableCreditCards.count) cards from API")
            
            // Filter out the popular cards
            filterPopularCards()
            
            // Prefetch details for popular cards
            await prefetchPopularCardDetails()
        } catch {
            print("❌ API Error: \(error)")
            apiLoadingError = "Failed to load credit cards: \(error.localizedDescription)"
            
            // If we fail to load cards, check if we have any cached
            if availableCreditCards.isEmpty {
                // Fall back to sample data if no cards are available
                availableCreditCards = getSampleCreditCards()
                popularCreditCards = availableCreditCards // For sample data, use all cards
                print("⚠️ Using \(availableCreditCards.count) sample cards as fallback")
            }
        }
        
        isLoadingCards = false
    }
    
    // Method to filter out popular cards
    private func filterPopularCards() {
        // Start with an empty array
        var popular: [CreditCardInfo] = []
        
        // First, include cards from major banks
        let majorBankCards = availableCreditCards.filter { card in
            majorBanks.contains { bank in
                card.issuer.lowercased().contains(bank.lowercased())
            }
        }
        
        // Extract the popular cards from major banks
        let popularFromMajor = majorBankCards.filter { card in
            popularCardTypes.contains { cardType in
                card.name.lowercased().contains(cardType.lowercased()) ||
                card.id.lowercased().contains(cardType.lowercased())
            }
        }
        
        // Add the popular cards first
        popular.append(contentsOf: popularFromMajor)
        
        // Then add other cards from major banks, but limit to a reasonable number
        let otherMajorBankCards = majorBankCards.filter { card in
            !popularFromMajor.contains { popular in
                popular.id == card.id
            }
        }
        
        // Also prioritize cards with popular categories
        let categoryCards = otherMajorBankCards.filter { card in
            popularCategories.contains { category in
                card.category.lowercased() == category.lowercased()
            }
        }
        
        // Add category cards first (if not already added)
        let remainingCategoryCards = categoryCards.filter { card in
            !popular.contains { popularCard in
                popularCard.id == card.id
            }
        }
        
        // Add remaining category cards (up to 20)
        popular.append(contentsOf: remainingCategoryCards.prefix(20))
        
        // Limit to top 30 other major bank cards
        let remainingMajorBankCards = otherMajorBankCards.filter { card in
            !popular.contains { popularCard in
                popularCard.id == card.id
            }
        }
        
        popular.append(contentsOf: remainingMajorBankCards.prefix(30))
        
        // Sort the final list by issuer and then name
        popular.sort {
            if $0.issuer == $1.issuer {
                return $0.name < $1.name
            }
            return $0.issuer < $1.issuer
        }
        
        // Update the published property
        popularCreditCards = popular
        
        print("📊 Filtered to \(popularCreditCards.count) popular cards from major banks")
    }
    
    // Method to prefetch details for popular cards
    @MainActor
    func prefetchPopularCardDetails() async {
        isLoadingDetails = true
        print("🔍 Prefetching details for popular cards...")
        
        // Get the top 10 popular cards to prefetch
        let topPopularCards = popularCreditCards.prefix(10)
        
        // Create a task group to fetch details in parallel
        await withTaskGroup(of: Void.self) { group in
            for card in topPopularCards {
                group.addTask {
                    if let detailedCard = await CreditCardService.shared.fetchAndUpdateCardDetail(cardKey: card.id) {
                        // Update in our card list
                        await MainActor.run {
                            if let index = self.popularCreditCards.firstIndex(where: { $0.id == card.id }) {
                                self.popularCreditCards[index] = detailedCard
                            }
                            
                            if let index = self.availableCreditCards.firstIndex(where: { $0.id == card.id }) {
                                self.availableCreditCards[index] = detailedCard
                            }
                        }
                    }
                }
            }
        }
        
        isLoadingDetails = false
        print("✅ Prefetched details for top popular cards")
    }
    
    func searchCreditCards(searchTerm: String) -> [CreditCardInfo] {
        if searchTerm.isEmpty {
            return popularCreditCards
        }
        
        return availableCreditCards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchTerm) ||
            card.issuer.localizedCaseInsensitiveContains(searchTerm)
        }
    }
    
    func getCreditCardsByCategory() -> [String: [CreditCardInfo]] {
        Dictionary(grouping: availableCreditCards) { $0.category }
    }
    
    // MARK: - Card Recommendations
    
    // Get recommended cards based on a category
    func getRecommendedCards(for category: String, limit: Int = 5) -> [CreditCardInfo] {
        // Filter cards by category
        let categoryCards = availableCreditCards.filter {
            $0.category.lowercased() == category.lowercased()
        }
        
        // Sort by signup bonus (assuming higher bonus = better card)
        let sortedCards = categoryCards.sorted { $0.signupBonus > $1.signupBonus }
        
        // Take the top cards up to the limit
        return Array(sortedCards.prefix(limit))
    }
    
    // Get cards by issuer
    func getCardsByIssuer(_ issuer: String, limit: Int = 10) -> [CreditCardInfo] {
        // Filter by issuer
        let issuerCards = availableCreditCards.filter {
            $0.issuer.lowercased().contains(issuer.lowercased())
        }
        
        // Sort by popularity
        let sortedCards = issuerCards.sorted { $0.signupBonus > $1.signupBonus }
        
        // Take the top cards up to the limit
        return Array(sortedCards.prefix(limit))
    }
    
    // MARK: - Testing Methods
    
    func testSearchAPI() async {
        print("🧪 TESTING CARD SEARCH API")
        isLoadingCards = true
        apiLoadingError = nil
        
        // Test common search terms
        let testTerms = ["chase", "amex", "citi", "discover", "ihg", "marriott", "hilton"]
        
        var allCards: [CreditCardInfo] = []
        for term in testTerms {
            do {
                // Be more explicit to avoid ambiguity
                await CreditCardService.shared.testSearchAPI(term: term)
                
                // Try to fetch cards with this term - using the new CardSearchAPIResponse
                let results: CardSearchAPIResponse = try await APIClient.fetchCardsBySearchTerm(term)
                print("✅ Found \(results.count) cards for '\(term)'")
                
                // Convert to our model
                let cards = results.map { $0.toCreditCardInfo() }
                
                // Add only unique cards
                let existingIDs = Set(allCards.map { $0.id })
                for card in cards {
                    if !existingIDs.contains(card.id) {
                        allCards.append(card)
                    }
                }
            } catch {
                print("❌ Error testing term '\(term)': \(error.localizedDescription)")
            }
        }
        
        await MainActor.run {
            print("📊 TEST COMPLETE - Found \(allCards.count) unique cards")
            isLoadingCards = false
            
            // Print a summary of what we found
            let issuers = Set(allCards.map { $0.issuer })
            print("Issuers found: \(issuers.sorted().joined(separator: ", "))")
            
            let categories = Set(allCards.map { $0.category })
            print("Categories found: \(categories.sorted().joined(separator: ", "))")
        }
    }
    
    // Test method to get card details for a specific card
    func testCardDetail(for cardId: String) async {
        print("🧪 TESTING CARD DETAIL API FOR: \(cardId)")
        
        if let detailedCard = await CreditCardService.shared.fetchAndUpdateCardDetail(cardKey: cardId) {
            print("✅ Successfully fetched card details:")
            print("Name: \(detailedCard.name)")
            print("Issuer: \(detailedCard.issuer)")
            print("Annual Fee: $\(detailedCard.annualFee)")
            print("Signup Bonus: \(detailedCard.signupBonus)")
            
            if let benefits = detailedCard.benefits {
                print("Benefits: \(benefits.count)")
                for benefit in benefits.prefix(3) {
                    print("- \(benefit.benefitTitle)")
                }
            }
            
            if let categories = detailedCard.bonusCategories {
                print("Bonus Categories: \(categories.count)")
                for category in categories.prefix(3) {
                    print("- \(category.spendBonusCategoryName): \(category.earnMultiplier)x")
                }
            }
        } else {
            print("❌ Failed to fetch card details for: \(cardId)")
        }
    }
    
    // Method to test card image loading
    func testCardImageAPI(cardKey: String) {
        CreditCardService.shared.testCardImage(cardKey: cardKey)
    }
    
    // Provide some sample cards in case API fails
    private func getSampleCreditCards() -> [CreditCardInfo] {
        return [
            CreditCardInfo(
                id: "chase-sapphire-reserve",
                name: "Sapphire Reserve",
                issuer: "Chase",
                category: "Travel",
                description: "Premium travel rewards card with 3x points on travel and dining, $300 annual travel credit.",
                annualFee: 550.00,
                signupBonus: 60000,
                regularAPR: "21.24% - 28.24% Variable",
                imageName: "",
                applyURL: "https://creditcards.chase.com/rewards-credit-cards/sapphire/reserve"
            ),
            CreditCardInfo(
                id: "amex-gold",
                name: "American Express Gold",
                issuer: "American Express",
                category: "Groceries",
                description: "4x on groceries at U.S. supermarkets on up to $25,000 in purchases per year",
                annualFee: 250.00,
                signupBonus: 60000,
                regularAPR: "See Terms",
                imageName: "",
                applyURL: "https://www.americanexpress.com/us/credit-cards/card/gold-card/"
            ),
            CreditCardInfo(
                id: "capital-one-venture",
                name: "Venture Rewards",
                issuer: "Capital One",
                category: "Travel",
                description: "Earn unlimited 2x miles on every purchase, everywhere",
                annualFee: 95.00,
                signupBonus: 75000,
                regularAPR: "19.99% - 27.99% Variable",
                imageName: "",
                applyURL: ""
            ),
            CreditCardInfo(
                id: "citi-double-cash",
                name: "Double Cash",
                issuer: "Citi",
                category: "Cashback",
                description: "Earn 2% cash back on all purchases - 1% when you buy and 1% when you pay",
                annualFee: 0.00,
                signupBonus: 0,
                regularAPR: "18.24% - 28.24% Variable",
                imageName: "",
                applyURL: ""
            ),
            CreditCardInfo(
                id: "discover-it",
                name: "Discover it Cash Back",
                issuer: "Discover",
                category: "Cashback",
                description: "5% cash back in rotating quarterly categories up to quarterly maximum",
                annualFee: 0.00,
                signupBonus: 0,
                regularAPR: "16.24% - 27.24% Variable",
                imageName: "",
                applyURL: ""
            )
        ]
    }
}

extension CardViewModel {
    // Do NOT redeclare toggleBonusAchieved - instead add these supporting methods
    
    // Load cards locally from UserDefaults
    private func loadCardsLocally() -> [CreditCard]? {
        guard let data = UserDefaults.standard.data(forKey: "savedCards") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let loadedCards = try decoder.decode([CreditCard].self, from: data)
            
            print("📤 Loaded \(loadedCards.count) cards from local storage")
            return loadedCards
        } catch {
            print("❌ Error loading cards locally: \(error)")
            return nil
        }
    }
    
    // Enhanced load user cards method with fallback to local storage
    func loadUserCards() {
        if let user = UserService.shared.currentUser {
            self.cards = user.cards
            print("📤 Loaded \(cards.count) cards from user account")
        } else {
            // Try to load from local storage if not logged in
            if let localCards = loadCardsLocally() {
                self.cards = localCards
            } else {
                loadSampleData()
            }
        }
    }
        // Add a method to force-refresh all data
        @MainActor
        func refreshAllData() async {
            // Show loading indicator
            isLoadingCards = true
            
            // Force refresh from API
            await loadCreditCardsFromAPI(forceRefresh: true)
            
            // Hide loading indicator
            isLoadingCards = false
        }
        
        // Method to fetch card details with caching
        @MainActor
        func getCardDetails(for cardId: String) async -> CreditCardInfo? {
            // Check if we already have a detailed card
            if let existingCard = availableCreditCards.first(where: { $0.id == cardId && $0.benefits != nil }) {
                return existingCard
            }
            
            // Otherwise fetch the details with caching
            return await CreditCardService.shared.fetchAndUpdateCardDetail(cardKey: cardId)
        }
    }
    

extension CardViewModel {
    // Load cards from API with improved caching
    @MainActor
    func loadCreditCardsFromAPI(forceRefresh: Bool = false) async {
        isLoadingCards = true
        apiLoadingError = nil
        
        do {
            if forceRefresh {
                // Clear caches if force refresh is requested
                print("🔄 Force refreshing card data...")
                CreditCardService.shared.clearAllCaches()
            }
            
            print("📊 Fetching credit card catalog...")
            // Use enhanced fetching method with caching
            availableCreditCards = try await CreditCardService.shared.fetchCreditCards()
            print("✅ Successfully loaded \(availableCreditCards.count) cards")
            
            // Filter out the popular cards
            filterPopularCards()
            
            // Prefetch details for popular cards
            await prefetchPopularCardDetails()
        } catch {
            print("❌ API Error: \(error)")
            apiLoadingError = "Failed to load credit cards: \(error.localizedDescription)"
            
            // If we fail to load cards, check if we have any cached
            if availableCreditCards.isEmpty {
                // Fall back to sample data if no cards are available
                availableCreditCards = CreditCardService.shared.getSampleCreditCardData()
                popularCreditCards = availableCreditCards // For sample data, use all cards
                print("⚠️ Using \(availableCreditCards.count) sample cards as fallback")
            }
        }
        
        isLoadingCards = false
    }
}
