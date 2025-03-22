import Combine
import Foundation
import UIKit
import SwiftUI

class CreditCardService {
    static let shared = CreditCardService()
    
    // Cache keys
    private let basicCacheKey = "cachedBasicCards"
    private let detailCachePrefix = "cachedDetail_"
    private let cacheDurationInDays = 7 // Cache expires after 7 days
    
    // Thread-safe in-memory caches
    private var cachedCards: [CreditCardInfo]? = nil
    private var cachedCardDetails: [String: CreditCardInfo] = [:]
    private let imageCache = NSCache<NSString, UIImage>()
    
    // Serial queue for thread-safe operations
    private let cacheQueue = DispatchQueue(label: "com.creditcardtracker.cacheQueue")
    
    // Initialization
    private init() {
        // Configure image cache
        imageCache.name = "CreditCardImageCache"
        imageCache.countLimit = 100 // Limit to 100 images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // Limit to ~50MB
    }
    
    // MARK: - Cache Management
    func fetchComprehensiveCardCatalog() async throws -> [CreditCardInfo] {
        print("📊 Fetching comprehensive card catalog...")
        
        // First check in-memory cache
        var cachedResult: [CreditCardInfo]?
        cacheQueue.sync {
            cachedResult = self.cachedCards
        }
        
        if let cachedCards = cachedResult {
            print("📋 Using in-memory cached comprehensive catalog with \(cachedCards.count) cards")
            return cachedCards
        }
        
        // Then check device storage before trying API
        if let deviceCachedCards = loadCatalogCardsFromDevice() {
            print("📋 Using device-cached catalog cards")
            // Update in-memory cache
            cacheQueue.sync {
                self.cachedCards = deviceCachedCards
            }
            return deviceCachedCards
        }
        
        // If no cached data, try to fetch from API
        print("🌐 Fetching comprehensive catalog from API...")
        
        var allCards: [CreditCardInfo] = []
        
        // Common search terms to fetch popular cards
        let searchTerms = ["chase", "amex", "american express", "citi", "capital one",
                         "discover", "wells fargo", "bank of america", "barclays",
                         "us bank", "hsbc", "united", "delta", "southwest", "marriott",
                         "hilton", "ihg", "hyatt", "travel", "cash", "business"]
        
        // First get basic cards
        do {
            let basicCards = try await fetchCreditCards()
            allCards.append(contentsOf: basicCards)
            print("✅ Loaded \(basicCards.count) cards from basic endpoint")
        } catch {
            print("⚠️ Error fetching basic cards: \(error)")
            // Continue even if basic fetch fails
        }
        
        // Then get cards by search terms
        do {
            let searchCards = try await fetchCardsBySearch(searchTerms: searchTerms)
            
            // Merge with existing cards, avoiding duplicates
            var seenCardIds = Set(allCards.map { $0.id })
            
            for card in searchCards {
                if !seenCardIds.contains(card.id) {
                    allCards.append(card)
                    seenCardIds.insert(card.id)
                }
            }
            
            print("✅ Added \(searchCards.count) cards from search, \(allCards.count) total unique cards")
        } catch {
            print("⚠️ Error fetching search cards: \(error)")
        }
        
        // If we didn't get any cards from API, fall back to sample data
        if allCards.isEmpty {
            print("⚠️ No cards retrieved from API, using sample data")
            allCards = getSampleCreditCardData()
        }
        
        // Sort cards by issuer and name
        allCards.sort {
            if $0.issuer == $1.issuer {
                return $0.name < $1.name
            }
            return $0.issuer < $1.issuer
        }
        
        // Cache the results in a thread-safe way
        cacheQueue.sync {
            self.cachedCards = allCards
        }
        
        // Save to device cache
        saveCatalogCardsToDevice(allCards)
        
        print("✅ Complete catalog contains \(allCards.count) unique credit cards")
        return allCards
    }

    
    func saveCatalogCardsToDevice(_ cards: [CreditCardInfo]) {
        do {
            let data = try JSONEncoder().encode(cards)
            let cacheInfo = CacheInfo(timestamp: Date())
            let cacheInfoData = try JSONEncoder().encode(cacheInfo)
            
            UserDefaults.standard.set(data, forKey: "cachedCatalogCards")
            UserDefaults.standard.set(cacheInfoData, forKey: "cachedCatalogCards_info")
            print("💾 Saved \(cards.count) catalog cards to device cache")
            
            // Force synchronize to ensure data is written immediately
            UserDefaults.standard.synchronize()
        } catch {
            print("❌ Error saving catalog cards to device: \(error)")
        }
    }
    
    func loadCatalogCardsFromDevice() -> [CreditCardInfo]? {
        // Check if cache exists and is valid
        guard let cacheInfoData = UserDefaults.standard.data(forKey: "cachedCatalogCards_info"),
              let cacheInfo = try? JSONDecoder().decode(CacheInfo.self, from: cacheInfoData),
              isCacheValid(cacheInfo: cacheInfo) else {
            print("📋 No valid catalog card cache found")
            return nil
        }
        
        // Load cached data
        guard let cachedData = UserDefaults.standard.data(forKey: "cachedCatalogCards") else {
            return nil
        }
        
        do {
            let cards = try JSONDecoder().decode([CreditCardInfo].self, from: cachedData)
            print("📋 Loaded \(cards.count) catalog cards from device cache")
            return cards
        } catch {
            print("❌ Error decoding cached catalog cards: \(error)")
            return nil
        }
    }

    
    // Fetch cards using search terms
    func fetchCardsBySearch(searchTerms: [String]) async throws -> [CreditCardInfo] {
        print("🔍 Fetching credit cards using search terms: \(searchTerms)")
        var allCards: [CreditCardInfo] = []
        
        for term in searchTerms {
            do {
                // Make API request using the search endpoint
                let searchResults: CardSearchAPIResponse = try await APIClient.fetchCardsBySearchTerm(term)
                
                print("📦 Received \(searchResults.count) cards for search term '\(term)'")
                
                // Convert API response to our model and add to results
                let cards = searchResults.map { $0.toCreditCardInfo() }
                allCards.append(contentsOf: cards)
            } catch {
                print("⚠️ Error fetching cards for term '\(term)': \(error.localizedDescription)")
                // Continue with next search term even if one fails
                continue
            }
        }
        
        print("✅ Total cards fetched from search: \(allCards.count)")
        return allCards
    }
    
    func fetchCreditCards() async throws -> [CreditCardInfo] {
        // First check in-memory cache (thread-safe)
        var cachedResult: [CreditCardInfo]?
        cacheQueue.sync {
            cachedResult = self.cachedCards
        }
        
        if let cachedCards = cachedResult {
            print("📋 Using in-memory cached cards")
            return cachedCards
        }
        
        // Then check device storage
        if let cachedData = loadCardsFromDevice() {
            print("📋 Using device cached cards")
            cacheQueue.sync {
                self.cachedCards = cachedData
            }
            return cachedData
        }
        
        // If no cache, fetch from API
        print("🌐 Fetching cards from API")
        do {
            let cards = try await fetchCardsFromAPI()
            saveCardsToDevice(cards)
            return cards
        } catch {
            print("❌ API Error: \(error)")
            return getSampleCreditCardData() // Fallback to sample data
        }
    }
    
    // Add these two test methods to your CreditCardService class

    // Test method for card image loading
    func testCardImage(cardKey: String) {
        print("🧪 Testing card image loading for: \(cardKey)")
        
        Task {
            if let image = await fetchCardImage(for: cardKey) {
                print("✅ Successfully loaded image for \(cardKey) - Size: \(image.size.width) x \(image.size.height)")
            } else {
                print("❌ Failed to load image for card: \(cardKey)")
            }
        }
    }

    // Test method for the search API
    func testSearchAPI(term: String) async {
        print("🧪 Testing search API for term: \(term)")
        
        do {
            // Create the URL for testing
            let searchURL = URL(string: APIClient.baseURL + "/creditcard-detail-namesearch/\(term)")!
            var request = URLRequest(url: searchURL)
            request.httpMethod = "GET"
            request.addValue(APIClient.apiKey, forHTTPHeaderField: "x-rapidapi-key")
            request.addValue(APIClient.apiHost, forHTTPHeaderField: "x-rapidapi-host")
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response")
                return
            }
            
            print("📥 HTTP Status: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                print("✅ Successful response")
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    let preview = jsonString.prefix(500)
                    print("📄 Data preview: \(preview)...")
                }
                
                do {
                    let decoder = JSONDecoder()
                    let decoded = try decoder.decode(CardSearchAPIResponse.self, from: data)
                    print("✅ Successfully decoded \(decoded.count) cards for search term '\(term)'")
                } catch {
                    print("❌ Decoding error: \(error)")
                }
            } else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("Error details: \(errorText)")
                }
            }
        } catch {
            print("❌ Network error: \(error)")
        }
    }
    
    // Fetch a specific card's details, using cache when available
    func fetchCardDetail(cardKey: String) async throws -> CreditCardInfo {
        guard !cardKey.isEmpty else {
            throw NSError(domain: "CreditCardService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Empty card key provided"])
        }
        
        // Check in-memory cache first (thread-safe)
        var cachedResult: CreditCardInfo?
        cacheQueue.sync {
            cachedResult = self.cachedCardDetails[cardKey]
        }
        
        if let cachedDetail = cachedResult {
            print("📋 Using in-memory cached details for \(cardKey)")
            return cachedDetail
        }
        
        // Check device storage
        if let cachedDetail = loadCardDetailFromDevice(cardKey: cardKey) {
            print("📋 Using device cached details for \(cardKey)")
            cacheQueue.sync {
                self.cachedCardDetails[cardKey] = cachedDetail
            }
            return cachedDetail
        }
        
        // If no cache, fetch from API
        print("🌐 Fetching card details from API for \(cardKey)")
        do {
            let cardDetail = try await fetchCardDetailFromAPI(cardKey: cardKey)
            saveCardDetailToDevice(cardDetail, cardKey: cardKey)
            return cardDetail
        } catch {
            print("❌ API Error for card details: \(error)")
            
            // Try to return basic info if available
            var basicInfo: CreditCardInfo?
            cacheQueue.sync {
                if let cachedCards = self.cachedCards {
                    basicInfo = cachedCards.first(where: { $0.id == cardKey })
                }
            }
            
            if let info = basicInfo {
                return info
            }
            
            throw error
        }
    }
    
    // Fetch and update cached detail for a card
    func fetchAndUpdateCardDetail(cardKey: String) async -> CreditCardInfo? {
        guard !cardKey.isEmpty else {
            print("⚠️ Empty card key provided")
            return nil
        }
        
        do {
            let cardDetail = try await fetchCardDetail(cardKey: cardKey)
            
            // Update in the main cards array if it exists (thread-safe)
            cacheQueue.sync {
                if var cards = self.cachedCards, let index = cards.firstIndex(where: { $0.id == cardKey }) {
                    cards[index] = cardDetail
                    self.cachedCards = cards
                    saveCardsToDevice(cards)
                }
            }
            
            return cardDetail
        } catch {
            print("❌ Error fetching card details: \(error)")
            return nil
        }
    }
    
    // MARK: - Device Storage Methods
    
    // Save cards to device storage
    private func saveCardsToDevice(_ cards: [CreditCardInfo]) {
        do {
            let data = try JSONEncoder().encode(cards)
            let cacheInfo = CacheInfo(timestamp: Date())
            let cacheInfoData = try JSONEncoder().encode(cacheInfo)
            
            UserDefaults.standard.set(data, forKey: basicCacheKey)
            UserDefaults.standard.set(cacheInfoData, forKey: "\(basicCacheKey)_info")
            print("💾 Saved \(cards.count) cards to device cache")
        } catch {
            print("❌ Error saving cards to device: \(error)")
        }
    }
    
    // Load cards from device storage
    private func loadCardsFromDevice() -> [CreditCardInfo]? {
        // Check if cache exists and is valid
        guard let cacheInfoData = UserDefaults.standard.data(forKey: "\(basicCacheKey)_info"),
              let cacheInfo = try? JSONDecoder().decode(CacheInfo.self, from: cacheInfoData),
              isCacheValid(cacheInfo: cacheInfo) else {
            print("📋 No valid card cache found")
            return nil
        }
        
        // Load cached data
        guard let cachedData = UserDefaults.standard.data(forKey: basicCacheKey) else {
            return nil
        }
        
        do {
            let cards = try JSONDecoder().decode([CreditCardInfo].self, from: cachedData)
            print("📋 Loaded \(cards.count) cards from device cache")
            return cards
        } catch {
            print("❌ Error decoding cached cards: \(error)")
            return nil
        }
    }
    
    // Save card detail to device storage
    private func saveCardDetailToDevice(_ card: CreditCardInfo, cardKey: String) {
        guard !cardKey.isEmpty else {
            print("⚠️ Cannot save card detail with empty key")
            return
        }
        
        do {
            let data = try JSONEncoder().encode(card)
            let cacheInfo = CacheInfo(timestamp: Date())
            let cacheInfoData = try JSONEncoder().encode(cacheInfo)
            
            UserDefaults.standard.set(data, forKey: "\(detailCachePrefix)\(cardKey)")
            UserDefaults.standard.set(cacheInfoData, forKey: "\(detailCachePrefix)\(cardKey)_info")
            print("💾 Saved details for \(cardKey) to device cache")
        } catch {
            print("❌ Error saving card details to device: \(error)")
        }
    }
    
    // Load card detail from device storage
    private func loadCardDetailFromDevice(cardKey: String) -> CreditCardInfo? {
        guard !cardKey.isEmpty else {
            print("⚠️ Cannot load card detail with empty key")
            return nil
        }
        
        // Check if cache exists and is valid
        guard let cacheInfoData = UserDefaults.standard.data(forKey: "\(detailCachePrefix)\(cardKey)_info"),
              let cacheInfo = try? JSONDecoder().decode(CacheInfo.self, from: cacheInfoData),
              isCacheValid(cacheInfo: cacheInfo) else {
            return nil
        }
        
        // Load cached data
        guard let cachedData = UserDefaults.standard.data(forKey: "\(detailCachePrefix)\(cardKey)") else {
            return nil
        }
        
        do {
            let card = try JSONDecoder().decode(CreditCardInfo.self, from: cachedData)
            print("📋 Loaded details for \(cardKey) from device cache")
            return card
        } catch {
            print("❌ Error decoding cached card details: \(error)")
            return nil
        }
    }
    
    // Check if cache is still valid
    private func isCacheValid(cacheInfo: CacheInfo) -> Bool {
        let calendar = Calendar.current
        let expirationDate = calendar.date(byAdding: .day, value: cacheDurationInDays, to: cacheInfo.timestamp) ?? Date()
        return Date() < expirationDate
    }
    
    // Clear all caches (for debugging or forced refresh)
    func clearAllCaches() {
        // Clear in-memory caches (thread-safe)
        cacheQueue.sync {
            self.cachedCards = nil
            self.cachedCardDetails.removeAll()
        }
        
        // Clear image cache
        imageCache.removeAllObjects()
        
        // Clear device storage caches
        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: basicCacheKey)
        userDefaults.removeObject(forKey: "\(basicCacheKey)_info")
        
        // Find and remove all detail caches
        let allKeys = userDefaults.dictionaryRepresentation().keys
        for key in allKeys {
            if key.hasPrefix(detailCachePrefix) {
                userDefaults.removeObject(forKey: key)
            }
        }
        
        // Clear disk image cache
        clearImageCache()
        
        print("🧹 All caches cleared")
    }
    
    // MARK: - API Methods
    
    // Fetch basic card list from API
    private func fetchCardsFromAPI() async throws -> [CreditCardInfo] {
        print("🔍 Fetching credit cards from API...")
        
        // Make API request
        let response: CreditCardAPIResponse = try await APIClient.fetch(endpoint: "/cards")
        print("📦 Received \(response.count) cards from basic API")
        
        // Process cards to remove duplicates
        var uniqueCards: [String: APICard] = [:]
        
        // Group cards by cardKey, keeping one with highest multiplier
        for card in response {
            if let existingCard = uniqueCards[card.cardKey],
               existingCard.earnMultiplier < card.earnMultiplier {
                uniqueCards[card.cardKey] = card
            } else if uniqueCards[card.cardKey] == nil {
                uniqueCards[card.cardKey] = card
            }
        }
        
        print("🔄 Processed down to \(uniqueCards.count) unique cards")
        
        // Create simplified card info
        let simplifiedCardInfos = uniqueCards.values.map { basicCard -> CreditCardInfo in
            // Create a simplified CreditCardInfo
            return CreditCardInfo(
                id: basicCard.cardKey,
                name: basicCard.cardName.replacingOccurrences(of: "®", with: "").replacingOccurrences(of: "℠", with: ""),
                issuer: basicCard.cardIssuer,
                category: getCategoryFromDescription(basicCard.spendBonusDesc),
                description: basicCard.spendBonusDesc,
                annualFee: 0.0, // Will be updated with details if needed
                signupBonus: Int(basicCard.earnMultiplier * 10000), // Placeholder until we get real data
                regularAPR: "Variable", // Will be updated with details if needed
                imageName: "", // Will be updated with details if needed
                applyURL: "" // Will be updated with details if needed
            )
        }
        
        print("✅ Created \(simplifiedCardInfos.count) card info objects")
        
        // Update in-memory cache (thread-safe)
        cacheQueue.sync {
            self.cachedCards = simplifiedCardInfos
        }
        
        return simplifiedCardInfos
    }
    
    // Fetch detail for a specific card from API
    private func fetchCardDetailFromAPI(cardKey: String) async throws -> CreditCardInfo {
        guard !cardKey.isEmpty else {
            throw NSError(domain: "CreditCardService", code: 400, userInfo: [NSLocalizedDescriptionKey: "Empty card key provided"])
        }
        
        // Make API request
        let endpoint = "/creditcard-detail-bycard/\(cardKey)"
        let response: CardDetailAPIResponse = try await APIClient.fetch(endpoint: endpoint)
        
        // The endpoint returns an array, but we expect only one card
        guard let cardDetail = response.first else {
            throw NSError(domain: "CreditCardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card details not found"])
        }
        
        // Convert to our model
        let detailedCard = cardDetail.toCreditCardInfo()
        
        // Update caches (thread-safe)
        cacheQueue.sync {
            self.cachedCardDetails[cardKey] = detailedCard
        }
        
        return detailedCard
    }
    
    private func getCategoryFromDescription(_ description: String) -> String {
        // Use the centralized category manager
        return CardCategoryManager.shared.categorizeFromString(description)
    }

    
    func getCategoryFromDetail(_ cardDetail: CardDetail) -> String {
        // Extract relevant information for categorization
        var categoryText = cardDetail.cardName + " " + cardDetail.signupBonusDesc
        
        // Add bonus category information
        for category in cardDetail.spendBonusCategory {
            categoryText += " " + category.spendBonusCategoryGroup + " " + category.spendBonusDesc
        }
        
        // Add benefit information
        for benefit in cardDetail.benefit {
            categoryText += " " + benefit.benefitTitle + " " + benefit.benefitDesc
        }
        
        // Use the centralized manager for consistent categorization
        return CardCategoryManager.shared.categorizeFromString(categoryText)
    }

    // Replace the existing standardizeCardCategory method with this:
    func standardizeCardCategory(_ category: String) -> String {
        return CardCategoryManager.shared.standardizeCategory(category)
    }
    
    // Add this method to your CreditCardService class to recategorize existing cards
    func recategorizeAllCards() {
        // Log what we're doing
        print("🔄 Recategorizing all cards for consistency...")
        
        // Process popularCreditCards
        if let viewModel = AppState.shared.cardViewModel {
            var updatedCount = 0
            
            // Update available cards
            for index in 0..<viewModel.availableCreditCards.count {
                let card = viewModel.availableCreditCards[index]
                let newCategory = CardCategoryManager.shared.categorizeCard(card)
                
                if card.category != newCategory {
                    updatedCount += 1
                    viewModel.availableCreditCards[index].category = newCategory
                }
            }
            
            // Update popular cards
            for index in 0..<viewModel.popularCreditCards.count {
                let card = viewModel.popularCreditCards[index]
                let newCategory = CardCategoryManager.shared.categorizeCard(card)
                
                if card.category != newCategory {
                    viewModel.popularCreditCards[index].category = newCategory
                }
            }
            
            print("✅ Recategorized \(updatedCount) cards for consistency")
        }
    }

    
    // Sample data for fallback
    func getSampleCreditCardData() -> [CreditCardInfo] {
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
            )
        ]
    }
    
    // MARK: - Card Image Caching
    
    // Image cache directory
    private var imageCacheDirectory: URL? {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appendingPathComponent("card_images")
    }
    
    // Response model for card image API
    struct CardImageResponse: Codable {
        let cardKey: String
        let cardName: String
        let cardImageUrl: String
    }
    
    
    
    
    // Method for fetching card images with caching
    func fetchCardImage(for cardKey: String) async -> UIImage? {
        guard !cardKey.isEmpty else {
            print("⚠️ Empty card key provided")
            return createGenericCardImage(id: "unknown")
        }
        
        // First check in-memory cache
        if let cachedImage = imageCache.object(forKey: cardKey as NSString) {
            print("🖼️ Using in-memory cached image for \(cardKey)")
            return cachedImage
        }
        
        // Then check disk cache
        if let diskCachedImage = loadImageFromDisk(for: cardKey) {
            print("🖼️ Using disk cached image for \(cardKey)")
            
            // Store in memory cache (thread-safe)
            DispatchQueue.main.async {
                self.imageCache.setObject(diskCachedImage, forKey: cardKey as NSString)
            }
            return diskCachedImage
        }
        
        print("🌐 Fetching image for card: \(cardKey)")
        
        // If no cache, try to get image from API
        do {
            // First, we need to get the URL to the actual image
            let imageInfoUrl = URL(string: "https://rewards-credit-card-api.p.rapidapi.com/creditcard-card-image/\(cardKey)")!
            
            let headers = [
                "x-rapidapi-key": APIClient.apiKey,
                "x-rapidapi-host": APIClient.apiHost
            ]
            
            var request = URLRequest(url: imageInfoUrl)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response for image info")
                let placeholderImage = await generatePlaceholderImage(for: cardKey)
                saveToDiskCache(image: placeholderImage, for: cardKey)
                return placeholderImage
            }
            
            print("📥 Image info response status: \(httpResponse.statusCode)")
            
            // If we got valid JSON data, try to parse it
            if let jsonString = String(data: data, encoding: .utf8) {
                // Check if it's an empty array or other invalid response
                if jsonString == "[]" || jsonString == "{}" {
                    print("⚠️ Empty response from API")
                    let placeholderImage = await generatePlaceholderImage(for: cardKey)
                    saveToDiskCache(image: placeholderImage, for: cardKey)
                    return placeholderImage
                }
                
                // Try to decode the response
                let decoder = JSONDecoder()
                var imageUrl: URL? = nil
                
                // Try to decode as array first (which seems to be the format)
                do {
                    if let imageResponses = try? decoder.decode([CardImageResponse].self, from: data),
                       !imageResponses.isEmpty,
                       let firstResponse = imageResponses.first,
                       !firstResponse.cardImageUrl.isEmpty {
                        imageUrl = URL(string: firstResponse.cardImageUrl)
                        print("✅ Found image URL from array response: \(firstResponse.cardImageUrl)")
                    }
                    // Fallback: try to decode as a single object
                    else if let imageResponse = try? decoder.decode(CardImageResponse.self, from: data),
                            !imageResponse.cardImageUrl.isEmpty {
                        imageUrl = URL(string: imageResponse.cardImageUrl)
                        print("✅ Found image URL from single response: \(imageResponse.cardImageUrl)")
                    }
                } catch {
                    print("❌ Error decoding image response: \(error)")
                }
                
                // If we have a valid URL, download the actual image
                if let imageUrl = imageUrl {
                    do {
                        print("📥 Downloading image from URL: \(imageUrl)")
                        let (imageData, imageResponse) = try await URLSession.shared.data(from: imageUrl)
                        
                        guard let httpImageResponse = imageResponse as? HTTPURLResponse,
                              (200...299).contains(httpImageResponse.statusCode) else {
                            print("❌ Failed to download image from URL")
                            let placeholderImage = await generatePlaceholderImage(for: cardKey)
                            saveToDiskCache(image: placeholderImage, for: cardKey)
                            return placeholderImage
                        }
                        
                        if let image = UIImage(data: imageData) {
                            print("🎉 Successfully downloaded image from URL!")
                            
                            // Cache the image (thread-safe)
                            DispatchQueue.main.async {
                                self.imageCache.setObject(image, forKey: cardKey as NSString)
                            }
                            saveToDiskCache(image: image, for: cardKey)
                            return image
                        } else {
                            print("❌ Invalid image data from URL")
                        }
                    } catch {
                        print("❌ Error downloading image from URL: \(error)")
                    }
                } else {
                    print("❌ No valid image URL found in response")
                }
            } else {
                print("❌ Failed to convert response to string")
            }
            
            // If we couldn't get a valid image, generate a placeholder
            let placeholderImage = await generatePlaceholderImage(for: cardKey)
            saveToDiskCache(image: placeholderImage, for: cardKey)
            return placeholderImage
        } catch {
            print("❌ Error fetching image info: \(error)")
            let placeholderImage = await generatePlaceholderImage(for: cardKey)
            saveToDiskCache(image: placeholderImage, for: cardKey)
            return placeholderImage
        }
    }
    
    // Corrected method for fetching card images with database integration
    func fetchCardImageEnhanced(for cardKey: String, card: CreditCardInfo? = nil) async -> UIImage? {
        guard !cardKey.isEmpty else {
            print("⚠️ Empty card key provided")
            return createGenericCardImage(id: "unknown")
        }
        
        // First check in-memory cache
        if let cachedImage = imageCache.object(forKey: cardKey as NSString) {
            print("🖼️ Using in-memory cached image for \(cardKey)")
            return cachedImage
        }
        
        // Then check disk cache
        if let diskCachedImage = loadImageFromDisk(for: cardKey) {
            print("🖼️ Using disk cached image for \(cardKey)")
            
            // Store in memory cache (thread-safe)
            DispatchQueue.main.async {
                self.imageCache.setObject(diskCachedImage, forKey: cardKey as NSString)
            }
            return diskCachedImage
        }
        
        print("🌐 Fetching enhanced image for card: \(cardKey)")
        
        // Try to get image from the database if we have the card info
        // Fixed: Don't use await with nil-coalescing operator
        var cardInfo = card
        if cardInfo == nil {
            cardInfo = await getCardInfoForKey(cardKey)
        }
        
        if let cardInfo = cardInfo {
            if let databaseImage = await CardImageDatabase.shared.getImageForCard(cardId: cardKey, card: cardInfo) {
                print("📚 Using image from database for \(cardKey)")
                
                // Cache the image (thread-safe)
                DispatchQueue.main.async {
                    self.imageCache.setObject(databaseImage, forKey: cardKey as NSString)
                }
                saveToDiskCache(image: databaseImage, for: cardKey)
                return databaseImage
            }
        }
        
        // If no database match, try the API
        do {
            // First, we need to get the URL to the actual image
            let imageInfoUrl = URL(string: "https://rewards-credit-card-api.p.rapidapi.com/creditcard-card-image/\(cardKey)")!
            
            let headers = [
                "x-rapidapi-key": APIClient.apiKey,
                "x-rapidapi-host": APIClient.apiHost
            ]
            
            var request = URLRequest(url: imageInfoUrl)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response for image info")
                let placeholderImage = await generatePlaceholderImage(for: cardKey)
                saveToDiskCache(image: placeholderImage, for: cardKey)
                return placeholderImage
            }
            
            print("📥 Image info response status: \(httpResponse.statusCode)")
            
            // If we got valid JSON data, try to parse it
            if let jsonString = String(data: data, encoding: .utf8) {
                // Check if it's an empty array or other invalid response
                if jsonString == "[]" || jsonString == "{}" {
                    print("⚠️ Empty response from API")
                    let placeholderImage = await generatePlaceholderImage(for: cardKey)
                    saveToDiskCache(image: placeholderImage, for: cardKey)
                    return placeholderImage
                }
                
                // Try to decode the response
                let decoder = JSONDecoder()
                var imageUrl: URL? = nil
                
                // Try to decode as array first (which seems to be the format)
                do {
                    if let imageResponses = try? decoder.decode([CardImageResponse].self, from: data),
                       !imageResponses.isEmpty,
                       let firstResponse = imageResponses.first,
                       !firstResponse.cardImageUrl.isEmpty {
                        imageUrl = URL(string: firstResponse.cardImageUrl)
                        print("✅ Found image URL from array response: \(firstResponse.cardImageUrl)")
                        
                        // Save to database if we have card info
                        if let cardInfoForDb = cardInfo {
                            await MainActor.run {
                                CardImageDatabase.shared.addImageFromAPI(
                                    cardId: cardKey,
                                    issuer: cardInfoForDb.issuer,
                                    cardName: cardInfoForDb.name,
                                    imageURL: firstResponse.cardImageUrl
                                )
                            }
                        }
                    }
                    // Fallback: try to decode as a single object
                    else if let imageResponse = try? decoder.decode(CardImageResponse.self, from: data),
                            !imageResponse.cardImageUrl.isEmpty {
                        imageUrl = URL(string: imageResponse.cardImageUrl)
                        print("✅ Found image URL from single response: \(imageResponse.cardImageUrl)")
                        
                        // Save to database if we have card info
                        if let cardInfoForDb = cardInfo {
                            await MainActor.run {
                                CardImageDatabase.shared.addImageFromAPI(
                                    cardId: cardKey,
                                    issuer: cardInfoForDb.issuer,
                                    cardName: cardInfoForDb.name,
                                    imageURL: imageResponse.cardImageUrl
                                )
                            }
                        }
                    }
                } catch {
                    print("❌ Error decoding image response: \(error)")
                }
                
                // If we have a valid URL, download the actual image
                if let imageUrl = imageUrl {
                    do {
                        print("📥 Downloading image from URL: \(imageUrl)")
                        let (imageData, imageResponse) = try await URLSession.shared.data(from: imageUrl)
                        
                        guard let httpImageResponse = imageResponse as? HTTPURLResponse,
                              (200...299).contains(httpImageResponse.statusCode) else {
                            print("❌ Failed to download image from URL")
                            let placeholderImage = await generatePlaceholderImage(for: cardKey)
                            saveToDiskCache(image: placeholderImage, for: cardKey)
                            return placeholderImage
                        }
                        
                        if let image = UIImage(data: imageData) {
                            print("🎉 Successfully downloaded image from URL!")
                            
                            // Cache the image (thread-safe)
                            DispatchQueue.main.async {
                                self.imageCache.setObject(image, forKey: cardKey as NSString)
                            }
                            saveToDiskCache(image: image, for: cardKey)
                            return image
                        } else {
                            print("❌ Invalid image data from URL")
                        }
                    } catch {
                        print("❌ Error downloading image from URL: \(error)")
                    }
                } else {
                    print("❌ No valid image URL found in response")
                }
            } else {
                print("❌ Failed to convert response to string")
            }
            
            // If we couldn't get a valid image, generate a placeholder
            let placeholderImage = await generatePlaceholderImage(for: cardKey)
            saveToDiskCache(image: placeholderImage, for: cardKey)
            return placeholderImage
        } catch {
            print("❌ Error fetching image info: \(error)")
            let placeholderImage = await generatePlaceholderImage(for: cardKey)
            saveToDiskCache(image: placeholderImage, for: cardKey)
            return placeholderImage
        }
    }

    
    private func getCardInfoForKey(_ cardKey: String) async -> CreditCardInfo? {
        // First check in cached cards
        if let viewModel = AppState.shared.cardViewModel {
            if let card = viewModel.availableCreditCards.first(where: { $0.id == cardKey }) {
                return card
            }
        }
        
        // If not found, try to fetch it from the API
        do {
            return try await fetchCardDetail(cardKey: cardKey)
        } catch {
            print("❌ Error fetching card details for image lookup: \(error)")
            return nil
        }
    }

    
    
    // Fallback method for fetching images from URL
    func fetchCardImageFromURL(for url: String) async -> UIImage? {
        guard !url.isEmpty else {
            print("⚠️ Empty URL provided")
            return nil
        }
        
        // Check cache first (thread-safe)
        let cacheKey = url as NSString
        if let cachedImage = imageCache.object(forKey: cacheKey) {
            print("🖼️ Using cached image for URL: \(url)")
            return cachedImage
        }
        
        // Check disk cache
        if let diskCachedImage = loadImageFromDisk(for: url) {
            print("🖼️ Using disk cached image for URL: \(url)")
            // Store in memory cache (thread-safe)
            DispatchQueue.main.async {
                self.imageCache.setObject(diskCachedImage, forKey: cacheKey)
            }
            return diskCachedImage
        }
        
        // Skip if URL is empty or invalid
        guard let imageURL = URL(string: url) else {
            print("❌ Invalid image URL: \(url)")
            return nil
        }
        
        print("🌐 Fetching image from URL: \(url)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: imageURL)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                print("❌ Invalid response fetching image from URL")
                return nil
            }
            
            if let image = UIImage(data: data) {
                print("✅ Successfully loaded image from URL")
                // Cache the image (thread-safe)
                DispatchQueue.main.async {
                    self.imageCache.setObject(image, forKey: cacheKey)
                }
                saveToDiskCache(image: image, for: url)
                return image
            } else {
                print("❌ Invalid image data from URL")
            }
        } catch {
            print("❌ Error fetching image from URL: \(error)")
        }
        
        return nil
    }
    
    // Helper method to generate a placeholder image
    private func generatePlaceholderImage(for cardKey: String) async -> UIImage {
        // Validate the key
        guard !cardKey.isEmpty else {
            return createGenericCardImage(id: "unknown")
        }
        
        // Check if image is already in cache (thread-safe)
        if let cachedImage = imageCache.object(forKey: cardKey as NSString) {
            print("🖼️ Using cached placeholder image for: \(cardKey)")
            return cachedImage
        }
        
        // Find the card info if available
        var cardInfo: CreditCardInfo?
        
        // Check in-memory caches (thread-safe)
        cacheQueue.sync {
            if let existingCard = self.cachedCards?.first(where: { $0.id == cardKey }) {
                cardInfo = existingCard
            } else if let detailedCard = self.cachedCardDetails[cardKey] {
                cardInfo = detailedCard
            }
        }
        
        // If not in memory, try to get card details
        if cardInfo == nil {
            do {
                cardInfo = try await fetchCardDetail(cardKey: cardKey)
            } catch {
                // Generate a generic card with just the ID
                let genericCard = CreditCardInfo(
                    id: cardKey,
                    name: cardKey.replacingOccurrences(of: "-", with: " ").capitalized,
                    issuer: String(cardKey.split(separator: "-").first ?? "").capitalized,
                    category: "Unknown",
                    description: "",
                    annualFee: 0.0,
                    signupBonus: 0,
                    regularAPR: "",
                    imageName: "",
                    applyURL: ""
                )
                cardInfo = genericCard
            }
        }
        
        guard let card = cardInfo else {
            // If all else fails, create a completely generic card
            return createGenericCardImage(id: cardKey)
        }
            
        // Generate the image on a background thread to avoid UI blocking
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                // Canvas size - credit card aspect ratio
                let size = CGSize(width: 600, height: 380)
                
                // Get background color based on card category or issuer
                let backgroundColor = self.getColorForCard(card)
                
                // Start drawing
                UIGraphicsBeginImageContextWithOptions(size, false, 0)
                defer { UIGraphicsEndImageContext() }
                
                // Draw card background with rounded corners
                guard let context = UIGraphicsGetCurrentContext() else {
                    continuation.resume(returning: self.createGenericCardImage(id: cardKey))
                    return
                }
                
                let rect = CGRect(origin: .zero, size: size)
                let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 20)
                
                // Create a gradient background
                let colors = self.createGradientColors(for: backgroundColor)
                
                guard let gradient = CGGradient(
                    colorsSpace: CGColorSpaceCreateDeviceRGB(),
                    colors: colors as CFArray,
                    locations: [0.0, 1.0]
                ) else {
                    continuation.resume(returning: self.createGenericCardImage(id: cardKey))
                    return
                }
                
                context.saveGState()
                roundedRect.addClip()
                context.drawLinearGradient(
                    gradient,
                    start: CGPoint(x: 0, y: 0),
                    end: CGPoint(x: size.width, y: size.height),
                    options: []
                )
                context.restoreGState()
                
                // Draw the card issuer logo or initial
                self.drawIssuerLogo(for: card, in: context, size: size)
                
                // Draw card name
                self.drawCardName(card.name, in: context, size: size)
                
                // Get the final image
                guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
                    continuation.resume(returning: self.createGenericCardImage(id: cardKey))
                    return
                }
                
                // Cache the generated image (thread-safe)
                DispatchQueue.main.async {
                    self.imageCache.setObject(image, forKey: cardKey as NSString)
                    print("🎨 Generated placeholder image for: \(cardKey)")
                }
                
                continuation.resume(returning: image)
            }
        }
    }

    // Fallback method for completely unknown cards
    private func createGenericCardImage(id: String) -> UIImage {
        let size = CGSize(width: 600, height: 380)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else {
            // If we can't create an image context, return a 1x1 pixel image
            return UIImage(systemName: "creditcard.fill") ?? UIImage()
        }
        
        let rect = CGRect(origin: .zero, size: size)
        let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 20)
        
        // Generic blue gradient
        let blueColor = UIColor(red: 0.1, green: 0.4, blue: 0.8, alpha: 1.0)
        let colors = [
            blueColor.cgColor,
            blueColor.withAlphaComponent(0.8).cgColor
        ]
        
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 1.0]
        ) else {
            return UIImage(systemName: "creditcard.fill") ?? UIImage()
        }
        
        context.saveGState()
        roundedRect.addClip()
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: size.width, y: size.height),
            options: []
        )
        context.restoreGState()
        
        // Draw a simple logo
        let circlePath = UIBezierPath(ovalIn: CGRect(x: 40, y: 40, width: 80, height: 80))
        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        context.addPath(circlePath.cgPath)
        context.fillPath()
        
        // Draw card ID as text
        let idText = id.replacingOccurrences(of: "-", with: " ").capitalized
        let idAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        idText.draw(
            at: CGPoint(x: 40, y: size.height - 80),
            withAttributes: idAttributes
        )
        
        guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
            return UIImage(systemName: "creditcard.fill") ?? UIImage()
        }
        
        return image
    }

    // Get a consistent color for a card based on its category or issuer
    private func getColorForCard(_ card: CreditCardInfo) -> UIColor {
        // Define colors by category
        switch card.category.lowercased() {
        case "travel":
            return UIColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0) // Blue
        case "cashback":
            return UIColor(red: 0.2, green: 0.6, blue: 0.3, alpha: 1.0) // Green
        case "business":
            return UIColor(red: 0.5, green: 0.3, blue: 0.7, alpha: 1.0) // Purple
        case "hotel":
            return UIColor(red: 0.9, green: 0.5, blue: 0.2, alpha: 1.0) // Orange
        case "airline":
            return UIColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0) // Red
        case "groceries":
            return UIColor(red: 0.4, green: 0.7, blue: 0.3, alpha: 1.0) // Light Green
        case "dining":
            return UIColor(red: 0.8, green: 0.4, blue: 0.2, alpha: 1.0) // Orange-Red
        case "gas":
            return UIColor(red: 0.6, green: 0.4, blue: 0.7, alpha: 1.0) // Light Purple
        default:
            // Fallback to issuer-based colors
            switch card.issuer.lowercased() {
            case "chase":
                return UIColor(red: 0.0, green: 0.4, blue: 0.8, alpha: 1.0) // Chase Blue
            case "american express", "amex":
                return UIColor(red: 0.0, green: 0.6, blue: 0.5, alpha: 1.0) // Amex Green/Teal
            case "citi":
                return UIColor(red: 0.0, green: 0.35, blue: 0.6, alpha: 1.0) // Citi Blue
            case "capital one":
                return UIColor(red: 0.7, green: 0.0, blue: 0.0, alpha: 1.0) // Capital One Red
            case "discover":
                return UIColor(red: 0.95, green: 0.4, blue: 0.0, alpha: 1.0) // Discover Orange
            case "wells fargo":
                return UIColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0) // Wells Fargo Red
            default:
                // Generate a color based on the card name (for consistency)
                let nameHash = card.name.hash
                let hue = CGFloat(abs(nameHash) % 1000) / 1000.0
                return UIColor(hue: hue, saturation: 0.6, brightness: 0.8, alpha: 1.0)
            }
        }
    }

    // Create gradient colors based on the background color
    private func createGradientColors(for color: UIColor) -> [CGColor] {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        
        // Create a darker version for the gradient
        let lighterColor = UIColor(hue: h, saturation: max(0, s - 0.1), brightness: min(1, b + 0.15), alpha: a)
        let darkerColor = UIColor(hue: h, saturation: min(1, s + 0.1), brightness: max(0, b - 0.15), alpha: a)
        
        return [lighterColor.cgColor, darkerColor.cgColor]
    }

    // Draw the issuer logo or initial
    private func drawIssuerLogo(for card: CreditCardInfo, in context: CGContext, size: CGSize) {
        // Draw a circle with the first letter of the issuer
        let circleSize: CGFloat = 80
        let circleRect = CGRect(x: 40, y: 40, width: circleSize, height: circleSize)
        
        // Draw white circle with opacity
        context.setFillColor(UIColor.white.withAlphaComponent(0.2).cgColor)
        context.fillEllipse(in: circleRect)
        
        // Get the first letter of the issuer
        let issuerInitial = String(card.issuer.prefix(1).uppercased())
        
        // Draw the issuer initial
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 50, weight: .bold),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = issuerInitial.size(withAttributes: attributes)
        let textPoint = CGPoint(
            x: circleRect.midX - textSize.width / 2,
            y: circleRect.midY - textSize.height / 2
        )
        
        issuerInitial.draw(at: textPoint, withAttributes: attributes)
        
        // Draw little chip icon
        let chipRect = CGRect(x: size.width - 120, y: 40, width: 50, height: 40)
        context.setFillColor(UIColor(red: 0.85, green: 0.7, blue: 0.3, alpha: 1.0).cgColor) // Gold color
        let chipPath = UIBezierPath(roundedRect: chipRect, cornerRadius: 5)
        context.addPath(chipPath.cgPath)
        context.fillPath()
        
        // Add chip lines
        context.setStrokeColor(UIColor(white: 0.3, alpha: 1.0).cgColor) // Dark gray
        context.setLineWidth(2)
        let chipLineY = chipRect.minY + chipRect.height / 2
        let chipLine = UIBezierPath()
        chipLine.move(to: CGPoint(x: chipRect.minX + 5, y: chipLineY))
        chipLine.addLine(to: CGPoint(x: chipRect.maxX - 5, y: chipLineY))
        context.addPath(chipLine.cgPath)
        context.strokePath()
    }

    // Draw the card name
    private func drawCardName(_ name: String, in context: CGContext, size: CGSize) {
        // Draw card name at the bottom
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
            .foregroundColor: UIColor.white
        ]
        
        let bottomY = size.height - 80
        let namePoint = CGPoint(x: 40, y: bottomY)
        
        name.draw(at: namePoint, withAttributes: attributes)
        
        // Draw "Credit Card" text below the name
        let subAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 18, weight: .regular),
            .foregroundColor: UIColor.white.withAlphaComponent(0.7)
        ]
        
        let subText = "Credit Card"
        let subPoint = CGPoint(x: 40, y: bottomY + 36)
        
        subText.draw(at: subPoint, withAttributes: subAttributes)
    }
    
    // Save image to disk cache
    private func saveToDiskCache(image: UIImage, for key: String) {
        guard !key.isEmpty, let directory = imageCacheDirectory else {
            print("⚠️ Cannot save image with empty key or invalid directory")
            return
        }
        
        // Create a safe filename from the key (works for both card keys and URLs)
        let safeFilename = createSafeFilename(from: key)
        
        do {
            // Create directory if it doesn't exist
            if !FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }
            
            let fileURL = directory.appendingPathComponent("\(safeFilename).png")
            
            // Convert image to PNG data and write to file
            if let data = image.pngData() {
                try data.write(to: fileURL)
                print("💾 Saved image for \(key) to disk cache")
            }
        } catch {
            print("❌ Error saving image to disk: \(error)")
        }
    }
    
    private func loadImageFromDisk(for key: String) -> UIImage? {
        guard !key.isEmpty, let directory = imageCacheDirectory else {
            return nil
        }
        
        // Create a safe filename from the key (works for both card keys and URLs)
        let safeFilename = createSafeFilename(from: key)
        
        let fileURL = directory.appendingPathComponent("\(safeFilename).png")
        
        // Check if file exists
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                let data = try Data(contentsOf: fileURL)
                if let image = UIImage(data: data) {
                    return image
                }
            } catch {
                print("❌ Error loading image from disk: \(error)")
            }
        }
        
        return nil
    }
    
    private func createSafeFilename(from key: String) -> String {
        // If the key contains URL characters, it's likely a URL
        if key.contains("://") || key.contains("/") {
            // Sanitize URL to create a valid filename
            let sanitized = key
                .replacingOccurrences(of: "/", with: "_")
                .replacingOccurrences(of: ":", with: "_")
                .replacingOccurrences(of: "?", with: "_")
                .replacingOccurrences(of: "&", with: "_")
                .replacingOccurrences(of: "=", with: "_")
                .replacingOccurrences(of: ".", with: "_")
            
            // Limit length to avoid issues with very long URLs
            // Use hash for uniqueness when truncating
            let hash = abs(key.hashValue).description
            if sanitized.count > 100 {
                return String(sanitized.prefix(80)) + "_" + hash
            }
            return sanitized
        } else {
            // For card keys, just use the key directly (they're already filename safe)
            return key
        }
    }
    
    // Clear image cache (both memory and disk)
    func clearImageCache() {
        // Clear memory cache (thread-safe)
        imageCache.removeAllObjects()
        
        // Clear disk cache
        guard let directory = imageCacheDirectory else { return }
        
        do {
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
            print("🧹 Image cache cleared")
        } catch {
            print("❌ Error clearing image cache: \(error)")
        }
    }
    
    func preloadCommonCardImages() {
        Task {
            let commonCards = ["chase-sapphire-preferred", "chase-sapphire-reserve", "amex-gold", "amex-platinum", "chase-hyatt", "capital-one-venture", "discover-it", "citi-double-cash"]
            
            for cardKey in commonCards {
                // Check if image is already in cache (thread-safe)
                if imageCache.object(forKey: cardKey as NSString) == nil && loadImageFromDisk(for: cardKey) == nil {
                    print("🔄 Preloading image for: \(cardKey)")
                    
                    // Get the card info if possible
                    var cardInfo: CreditCardInfo? = nil
                    if let viewModel = AppState.shared.cardViewModel {
                        cardInfo = viewModel.availableCreditCards.first(where: { $0.id == cardKey })
                    }
                    
                    // Use enhanced image fetching
                    _ = await fetchCardImageEnhanced(for: cardKey, card: cardInfo)
                }
            }
        }
    }
    // Initialize the image database
    func initializeImageDatabase() {
        Task {
            await CardImageDatabase.shared.initialize()
        }
    }
    
    
}

// Helper struct to track cache age
private struct CacheInfo: Codable {
    let timestamp: Date
}
