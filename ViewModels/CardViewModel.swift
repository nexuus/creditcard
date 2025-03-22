import SwiftUI
import Foundation
import Combine

// MARK: - CardViewModel
class CardViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var cards: [CreditCard] = []
    @Published var availableCreditCards: [CreditCardInfo] = []
    @Published var popularCreditCards: [CreditCardInfo] = []
    @Published var isLoadingCards: Bool = false
    @Published var isLoadingDetails: Bool = false
    @Published var apiLoadingError: String? = nil
    @Published var isLoadingCardStatus: Bool = true
    
    // MARK: - Private Properties
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
    
    // MARK: - Initialization
    init() {
        loadSampleData() // Keep for fallback
        
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
    
    // Initialize with loading state
    func initializeWithLoadingState() {
        // Set loading state to true
        isLoadingCardStatus = true
        
        // Perform loading on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            // Load cards
            let loadedCards = self.loadCardsWithPriority()
            
            // Update on main thread
            DispatchQueue.main.async {
                self.cards = loadedCards
                // Turn off loading state
                self.isLoadingCardStatus = false
                print("✅ Card loading complete with \(self.cards.count) cards")
            }
        }
    }
    
    // Optimized loading method that prioritizes card status
    private func loadCardsWithPriority() -> [CreditCard] {
        print("🔄 Loading cards with priority...")
        
        // First try to load from UserDefaults directly as it's fastest
        if let localCards = loadCardsDirectlyFromDefaults() {
            print("📦 Loaded \(localCards.count) cards directly from UserDefaults")
            return localCards
        }
        
        // Then try user account if logged in
        if let user = UserService.shared.currentUser {
            print("👤 Loaded \(user.cards.count) cards from user account")
            return user.cards
        }
        
        // Fall back to local storage (might be redundant but keeping for safety)
        if let localCards = loadCardsLocally() {
            print("💾 Loaded \(localCards.count) cards from local storage")
            return localCards
        }
        
        // Last resort: sample data
        print("⚠️ Using sample data")
        var sampleCards: [CreditCard] = []
        loadSampleData()
        sampleCards = self.cards
        return sampleCards
    }
    
    // Load sample data for fallback
    func loadSampleData() {
        cards = [
            CreditCard(name: "Sapphire Preferred", issuer: "Chase", dateOpened: Date().addingTimeInterval(-180*24*3600), signupBonus: 60000, bonusAchieved: true, annualFee: 95, notes: "Met spending requirement in month 2"),
            CreditCard(name: "Gold Card", issuer: "American Express", dateOpened: Date().addingTimeInterval(-90*24*3600), signupBonus: 75000, bonusAchieved: false, annualFee: 250, notes: "$2000 more spending needed by June 15"),
            CreditCard(name: "Venture X", issuer: "Capital One", dateOpened: Date().addingTimeInterval(-30*24*3600), signupBonus: 100000, bonusAchieved: false, annualFee: 395, notes: "Need to complete $10k spend")
        ]
    }
}

// MARK: - Card Data Management
extension CardViewModel {
    // Get active cards only
    func getActiveCards() -> [CreditCard] {
        return cards.filter { $0.isActive }
    }
    
    // Get inactive cards only
    func getInactiveCards() -> [CreditCard] {
        return cards.filter { !$0.isActive }
    }
    
    // Add a new card
    func addCard(_ card: CreditCard) {
        cards.append(card)
        saveCards()
    }
    
    // Delete card at specific index
    func deleteCard(at offsets: IndexSet) {
        cards.remove(atOffsets: offsets)
        saveCards()
    }
    
    // Load user cards
    func loadUserCards() {
        // Set loading state first
        isLoadingCardStatus = true
        
        // A brief artificial delay to ensure UI shows the loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let user = UserService.shared.currentUser {
                self.cards = user.cards
                print("📤 Loaded \(self.cards.count) cards from user account")
            } else {
                // Try to load from local storage if not logged in
                if let localCards = self.loadCardsLocally() {
                    self.cards = localCards
                    print("📤 Loaded \(self.cards.count) cards from local storage")
                } else {
                    self.loadSampleData()
                }
            }
            
            // Turn off loading state
            self.isLoadingCardStatus = false
        }
    }
    
    // Update an existing card with completion handler
    func updateCard(_ card: CreditCard, completion: ((Bool) -> Void)? = nil) {
        // Ensure we're on the main thread for UI operations
        DispatchQueue.main.async {
            if let index = self.cards.firstIndex(where: { $0.id == card.id }) {
                // Update card in the array
                self.cards[index] = card
                
                // Attempt to save changes
                let success = self.saveCards()
                
                // Force UI refresh
                self.objectWillChange.send()
                
                if success {
                    print("✅ Successfully updated card: \(card.name)")
                    completion?(true)
                } else {
                    print("❌ Error updating card: \(card.name)")
                    // Revert change if save failed
                    if let oldCards = UserService.shared.loadCardsDirectly() {
                        self.cards = oldCards
                    }
                    completion?(false)
                }
            } else {
                print("⚠️ Card not found in array: \(card.id)")
                completion?(false)
            }
        }
    }
    
    // Toggle bonus achieved status
    func toggleBonusAchieved(for cardID: UUID, completion: ((Bool) -> Void)? = nil) {
        // Ensure we're on the main thread
        DispatchQueue.main.async {
            if let index = self.cards.firstIndex(where: { $0.id == cardID }) {
                // Create a copy of the card
                var updatedCard = self.cards[index]
                
                // Toggle the status
                updatedCard.bonusAchieved.toggle()
                
                // Update the card in the array
                self.cards[index] = updatedCard
                
                // CRITICAL: Force save to UserDefaults immediately
                self.saveCards()
                
                // Force UserDefaults to synchronize
                UserDefaults.standard.synchronize()
                
                // Provide feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                
                // Log the change
                let status = updatedCard.bonusAchieved ? "earned" : "pending"
                print("💾 Card status changed: \(updatedCard.name) marked as \(status)")
                
                completion?(true)
            } else {
                print("⚠️ Card not found for toggle: \(cardID)")
                completion?(false)
            }
        }
    }
    
    // Save cards to storage
    func saveCards() -> Bool {
        do {
            if UserService.shared.isLoggedIn {
                UserService.shared.updateUserCards(cards: cards)
            } else {
                // Save locally if not logged in
                if !saveCardsLocally() {
                    return false
                }
            }
            
            // Set timestamp for last update
            UserDefaults.standard.set(Date(), forKey: "lastDataUpdate")
            return true
        } catch {
            print("❌ Error in saveCards: \(error)")
            return false
        }
    }
    
    // Save cards locally
    func saveCardsLocally() -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            UserDefaults.standard.set(data, forKey: "savedCards")
            
            print("💾 Cards saved locally: \(cards.count) cards")
            return true
        } catch {
            print("❌ Error saving cards locally: \(error)")
            return false
        }
    }
    
    // Load cards from local storage
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
    
    // Direct UserDefaults access for speed
    private func loadCardsDirectlyFromDefaults() -> [CreditCard]? {
        guard let data = UserDefaults.standard.data(forKey: "savedCards") else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let cards = try decoder.decode([CreditCard].self, from: data)
            return cards
        } catch {
            print("❌ Error in direct UserDefaults loading: \(error)")
            return nil
        }
    }
}

// MARK: - Statistics and Metrics
extension CardViewModel {
    // Calculate total historical points (all cards)
    func totalHistoricalPoints() -> Int {
        return cards.filter { $0.bonusAchieved }.reduce(0) { $0 + $1.signupBonus }
    }
    
    // Calculate total points earned (active cards)
    func totalPointsEarned() -> Int {
        return cards.filter { $0.bonusAchieved && $0.isActive }.reduce(0) { $0 + $1.signupBonus }
    }
    
    // Calculate pending points (active cards)
    func pendingPoints() -> Int {
        return cards.filter { !$0.bonusAchieved && $0.isActive }.reduce(0) { $0 + $1.signupBonus }
    }
    
    // Group points by year
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
    
    // Calculate lifetime points
    func lifetimePoints() -> Int {
        return totalPointsEarned()
    }
    
    // Calculate total annual fees (active cards)
    func totalAnnualFees() -> Double {
        return cards.filter { $0.isActive }.reduce(0) { $0 + $1.annualFee }
    }
    
    // Group cards opened by year
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
}

// MARK: - API Integration
extension CardViewModel {
    // Load credit cards from API with clear naming to avoid ambiguity
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
    
    // Force-refresh all data
    @MainActor
    func refreshAllData() async {
        // Show loading indicator
        isLoadingCards = true
        
        // Force refresh from API
        await loadCreditCardsFromAPI(forceRefresh: true)
        
        // Hide loading indicator
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
    
    // Fetch card details with caching
    @MainActor
    func getCardDetails(for cardId: String) async -> CreditCardInfo? {
        // Check if we already have a detailed card
        if let existingCard = availableCreditCards.first(where: { $0.id == cardId && $0.benefits != nil }) {
            return existingCard
        }
        
        // Otherwise fetch the details with caching
        return await CreditCardService.shared.fetchAndUpdateCardDetail(cardKey: cardId)
    }
    
    // Search credit cards by term
    func searchCreditCards(searchTerm: String) -> [CreditCardInfo] {
        if searchTerm.isEmpty {
            return popularCreditCards
        }
        
        return availableCreditCards.filter { card in
            card.name.localizedCaseInsensitiveContains(searchTerm) ||
            card.issuer.localizedCaseInsensitiveContains(searchTerm)
        }
    }
}

// MARK: - Card Recommendations and Organization
extension CardViewModel {
    // Get credit cards by category
    func getCreditCardsByCategory() -> [String: [CreditCardInfo]] {
        Dictionary(grouping: availableCreditCards) { $0.category }
    }
    
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
    
    // Function to get top cards by issuer - organized by category
    func getTopCardsByIssuerCategorized(limit: Int = 10) -> [String: [String: [CreditCardInfo]]] {
        // Group all cards by issuer first
        let cardsByIssuer = Dictionary(grouping: availableCreditCards) { $0.issuer }
        
        var result: [String: [String: [CreditCardInfo]]] = [:]
        
        // Process each issuer
        for (issuer, cards) in cardsByIssuer {
            // For each issuer, categorize cards
            var categorizedCards: [String: [CreditCardInfo]] = [
                "Travel": [],
                "Dining": [],
                "Business": [],
                "Misc": []
            ]
            
            // Categorize each card
            for card in cards {
                let category = getCategoryForFiltering(card)
                categorizedCards[category]?.append(card)
            }
            
            // Sort each category by signup bonus or other criteria and limit to top cards
            for (category, categoryCards) in categorizedCards {
                // Sort by signup bonus (higher is better)
                let sortedCards = categoryCards.sorted { $0.signupBonus > $1.signupBonus }
                categorizedCards[category] = Array(sortedCards.prefix(limit))
            }
            
            result[issuer] = categorizedCards
        }
        
        return result
    }
    
    // Get popular cards from major issuers
    func getCardsFromMajorIssuers(limit: Int = 10) -> [String: [CreditCardInfo]] {
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
    
    // Helper to determine the display category for a card
    private func getCategoryForFiltering(_ card: CreditCardInfo) -> String {
        let category = card.category.lowercased()
        
        if category.contains("travel") || category.contains("airline") || category.contains("hotel") {
            return "Travel"
        } else if category.contains("dining") || category.contains("restaurant") {
            return "Dining"
        } else if category.contains("business") {
            return "Business"
        } else {
            return "Misc"
        }
    }
}

// MARK: - Testing and Debug Methods
extension CardViewModel {
    // Test method to test search API
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
    func getSampleCreditCards() -> [CreditCardInfo] {
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
    
    // This function will print the current state of all cards
    func debugCardStatus() {
        print("\n===== DEBUG: CURRENT CARD STATUS =====")
        for (index, card) in cards.enumerated() {
            print("Card \(index+1): \(card.name) - Bonus Achieved: \(card.bonusAchieved)")
        }
        print("=====================================\n")
    }
    
    // Call this to check what's stored in UserDefaults
    func debugStoredCards() {
        print("\n===== DEBUG: STORED CARD STATUS =====")
        
        // Check cards stored directly
        if let storedCards = UserDefaults.standard.data(forKey: "savedCards") {
            do {
                let decoder = JSONDecoder()
                let decodedCards = try decoder.decode([CreditCard].self, from: storedCards)
                print("Found \(decodedCards.count) cards in UserDefaults 'savedCards'")
                for (index, card) in decodedCards.enumerated() {
                    print("Stored Card \(index+1): \(card.name) - Bonus Achieved: \(card.bonusAchieved)")
                }
            } catch {
                print("❌ Error decoding stored cards: \(error)")
            }
        } else {
            print("❌ No cards found in UserDefaults 'savedCards'")
        }
        
        // Check if the user is logged in
        if UserService.shared.isLoggedIn, let user = UserService.shared.currentUser {
            print("\nUser is logged in, found \(user.cards.count) cards in user account")
            for (index, card) in user.cards.enumerated() {
                print("User Card \(index+1): \(card.name) - Bonus Achieved: \(card.bonusAchieved)")
            }
        } else {
            print("\nUser is not logged in")
        }
        
        print("=====================================\n")
    }
    
    // Enhanced load user cards with more debug info
    func enhancedLoadUserCards() {
        print("\n===== DEBUG: LOADING USER CARDS =====")
        
        // First try loading from UserService (when logged in)
        if let user = UserService.shared.currentUser {
            self.cards = user.cards
            print("✅ Loaded \(cards.count) cards from user account")
            debugCardStatus()
        } else {
            // Try to load from local storage if not logged in
            print("Not logged in, trying local storage...")
            
            if let localCards = loadCardsLocally() {
                self.cards = localCards
                print("✅ Loaded \(cards.count) cards from local storage")
                debugCardStatus()
            } else {
                print("❌ No cards found in local storage, using sample data")
                loadSampleData()
                debugCardStatus()
            }
        }
        
        print("=====================================\n")
    }
    
    // Enhanced save method with more logging
    func enhancedSaveCards() -> Bool {
        print("\n===== DEBUG: SAVING CARDS =====")
        debugCardStatus()
        
        do {
            if UserService.shared.isLoggedIn {
                print("User logged in, saving to user account...")
                UserService.shared.updateUserCards(cards: cards)
            } else {
                // Save locally if not logged in
                print("User not logged in, saving locally...")
                if !enhancedSaveCardsLocally() {
                    print("❌ Failed to save cards locally")
                    return false
                }
            }
            
            // Set timestamp for last update
            UserDefaults.standard.set(Date(), forKey: "lastDataUpdate")
            print("✅ Cards saved successfully")
            
            // Force synchronize to ensure data is written immediately
            UserDefaults.standard.synchronize()
            
            // Verify what was actually saved
            debugStoredCards()
            
            return true
        } catch {
            print("❌ Error in saveCards: \(error)")
            return false
        }
    }
    
    // Enhanced local saving with more logging
    func enhancedSaveCardsLocally() -> Bool {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(cards)
            
            // Before saving, check if what we're about to save is different
            if let existingData = UserDefaults.standard.data(forKey: "savedCards") {
                do {
                    let existingCards = try JSONDecoder().decode([CreditCard].self, from: existingData)
                    print("Found \(existingCards.count) existing cards in UserDefaults")
                    
                    // Compare card status
                    for (newCard, oldCard) in zip(cards, existingCards) {
                        if newCard.id == oldCard.id && newCard.bonusAchieved != oldCard.bonusAchieved {
                            print("⚠️ Card status changing: \(newCard.name) from \(oldCard.bonusAchieved) to \(newCard.bonusAchieved)")
                        }
                    }
                } catch {
                    print("❌ Error comparing existing cards: \(error)")
                }
            }
            
            // Save the data
            UserDefaults.standard.set(data, forKey: "savedCards")
            
            // Force synchronize
            UserDefaults.standard.synchronize()
            
            print("💾 Cards saved locally: \(cards.count) cards")
            return true
        } catch {
            print("❌ Error saving cards locally: \(error)")
            return false
        }
    }
    

}

// MARK: - Profile Integration
extension CardViewModel {
    // Load cards for the active profile
    func loadCardsForActiveProfile() {
        if let profile = ProfileService.shared.activeProfile {
            // Load the cards associated with this profile
            cards = profile.cards
            print("📤 Loaded \(cards.count) cards from active profile")
        }
    }
    
    // Apply catalog preferences from the active profile
    func applyProfileCatalogPreferences() {
        // Here you would apply any catalog preferences from the active profile
        // For example, favorite cards, custom categories, etc.
        if let profile = ProfileService.shared.activeProfile {
            print("📤 Applied catalog preferences from profile: \(profile.name)")
            // Implementation details would depend on how your catalog preferences work
        }
    }
}
