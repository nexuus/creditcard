//
//  CreditCardService.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first

import Combine
import Foundation
import UIKit
import SwiftUI

//
//  CreditCardService.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.

class CreditCardService {
    static let shared = CreditCardService()
    private var cachedCards: [CreditCardInfo]? = nil
    private var cachedCardDetails: [String: CreditCardInfo] = [:]
    private var imageCache: [String: UIImage] = [:]
    
    // MARK: - Basic Card List
    
    // Fetch basic card list
    func fetchCreditCards() async throws -> [CreditCardInfo] {
        // Return cached data if available
        if let cachedCards = cachedCards {
            return cachedCards
        }
        
        do {
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
            
            // Cache the results
            self.cachedCards = simplifiedCardInfos
            return simplifiedCardInfos
        } catch {
            print("❌ API Error: \(error)")
            
            // If the API fails, fall back to sample data
            let sampleData = getSampleCreditCardData()
            self.cachedCards = sampleData
            return sampleData
        }
    }
    
    func fetchAndUpdateCardDetail(cardKey: String) async -> CreditCardInfo? {
        print("🔍 Fetching detailed info for card: \(cardKey)")
        
        // Check if we already have cached details
        if let cachedDetail = cachedCardDetails[cardKey] {
            print("✅ Using cached detailed info for: \(cardKey)")
            return cachedDetail
        }
        
        do {
            // Make API request to get detailed info
            let endpoint = "/creditcard-detail-bycard/\(cardKey)"
            let response: CardDetailAPIResponse = try await APIClient.fetch(endpoint: endpoint)
            
            // The endpoint returns an array, but we expect only one card
            guard let cardDetail = response.first else {
                print("❌ No card details found for: \(cardKey)")
                throw NSError(domain: "CreditCardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card details not found"])
            }
            
            // Find the basic card info if available
            var updatedCardInfo: CreditCardInfo
            
            if let existingCardInfo = cachedCards?.first(where: { $0.id == cardKey }) {
                // Update existing card with detailed info
                updatedCardInfo = existingCardInfo
                updatedCardInfo.updateWithDetails(from: cardDetail)
                print("✅ Updated existing card with detailed info: \(cardKey)")
            } else {
                // Create new card info from detail
                updatedCardInfo = cardDetail.toCreditCardInfo()
                print("✅ Created new card info from details: \(cardKey)")
            }
            
            // Cache the detailed card info
            cachedCardDetails[cardKey] = updatedCardInfo
            
            // Also update in the main cards array if it exists
            if var cards = cachedCards, let index = cards.firstIndex(where: { $0.id == cardKey }) {
                cards[index] = updatedCardInfo
                cachedCards = cards
            }
            
            return updatedCardInfo
        } catch {
            print("❌ Error fetching card details: \(error)")
            
            // Try to return basic info if it exists
            if let basicInfo = cachedCards?.first(where: { $0.id == cardKey }) {
                return basicInfo
            }
            
            return nil
        }
    }

    
    func prefetchCardDetails(for cardKeys: [String]) async {
        print("🔄 Prefetching details for \(cardKeys.count) cards")
        
        let priorityCards = cardKeys.prefix(5) // Limit to avoid too many API calls at once
        
        // Create a task group to fetch details in parallel
        await withTaskGroup(of: Void.self) { group in
            for cardKey in priorityCards {
                group.addTask {
                    _ = await self.fetchAndUpdateCardDetail(cardKey: cardKey)
                }
            }
        }
        
        print("✅ Prefetched details for priority cards")
    }
    
    
    
    
    
    
    
    // MARK: - Card Details
    
    // Fetch detail for a specific card
    func fetchCardDetail(cardKey: String) async throws -> CreditCardInfo {
        // Check if we already have details cached
        if let cachedDetail = cachedCardDetails[cardKey] {
            return cachedDetail
        }
        
        do {
            // Make API request
            let endpoint = "/creditcard-detail-bycard/\(cardKey)"
            let response: CardDetailAPIResponse = try await APIClient.fetch(endpoint: endpoint)
            
            // The endpoint returns an array, but we expect only one card
            guard let cardDetail = response.first else {
                throw NSError(domain: "CreditCardService", code: 404, userInfo: [NSLocalizedDescriptionKey: "Card details not found"])
            }
            
            // Convert to our model
            let detailedCard = cardDetail.toCreditCardInfo()
            
            // Cache the result
            cachedCardDetails[cardKey] = detailedCard
            
            // Update our cached cards list if it exists
            if let index = cachedCards?.firstIndex(where: { $0.id == cardKey }) {
                cachedCards?[index] = detailedCard
            }
            
            return detailedCard
        } catch {
            print("Error fetching card detail: \(error)")
            
            // If we fail to get details, return basic info if available
            if let basicCards = cachedCards,
               let basicInfo = basicCards.first(where: { $0.id == cardKey }) {
                return basicInfo
            }
            
            // If all else fails, throw the error
            throw error
        }
    }
    
    // MARK: - Card Images
    
    // Method for fetching card images from dedicated endpoint
    struct CardImageResponse: Codable {
        let cardKey: String
        let cardName: String
        let cardImageUrl: String
    }

    // Now, replace the fetchCardImage method with this updated version:

    // Method for fetching card images from dedicated endpoint
    func fetchCardImage(for cardKey: String) async -> UIImage? {
        // Check cache first to avoid redundant network calls
        if let cachedImage = imageCache[cardKey] {
            print("✅ Using cached image for: \(cardKey)")
            return cachedImage
        }
        
        print("📤 Fetching image for card: \(cardKey)")
        
        // Step 1: Get the image URL from the API
        do {
            // First, we need to get the URL to the actual image
            let imageInfoUrl = URL(string: "https://rewards-credit-card-api.p.rapidapi.com/creditcard-card-image/\(cardKey)")!
            
            let headers = [
                "x-rapidapi-key": "a65d839d26msh7165854114aafbbp1c3b60jsnc2e5f215b4c9",
                "x-rapidapi-host": "rewards-credit-card-api.p.rapidapi.com"
            ]
            
            var request = URLRequest(url: imageInfoUrl)
            request.httpMethod = "GET"
            request.allHTTPHeaderFields = headers
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response for image info")
                return await generatePlaceholderImage(for: cardKey)
            }
            
            print("📥 Image info response status: \(httpResponse.statusCode)")
            
            // If we got valid JSON data, try to parse it
            if let jsonString = String(data: data, encoding: .utf8) {
                print("🔍 Received JSON: \(jsonString)")
                
                // Check if it's an empty array or other invalid response
                if jsonString == "[]" || jsonString == "{}" {
                    print("⚠️ Empty response from API")
                    return await generatePlaceholderImage(for: cardKey)
                }
                
                // Try to decode the response
                let decoder = JSONDecoder()
                var imageUrl: URL? = nil
                
                // Try to decode as array first (which seems to be the format)
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
                
                // Step 2: If we have a valid URL, download the actual image
                if let imageUrl = imageUrl {
                    do {
                        print("📥 Downloading image from URL: \(imageUrl)")
                        let (imageData, imageResponse) = try await URLSession.shared.data(from: imageUrl)
                        
                        guard let httpImageResponse = imageResponse as? HTTPURLResponse,
                              (200...299).contains(httpImageResponse.statusCode) else {
                            print("❌ Failed to download image from URL")
                            return await generatePlaceholderImage(for: cardKey)
                        }
                        
                        if let image = UIImage(data: imageData) {
                            print("🎉 Successfully downloaded image from URL!")
                            imageCache[cardKey] = image
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
            return await generatePlaceholderImage(for: cardKey)
        } catch {
            print("❌ Error fetching image info: \(error)")
            return await generatePlaceholderImage(for: cardKey)
        }
    }
    
    
    
    
    
    
    // Helper method to generate a placeholder image
    private func generatePlaceholderImage(for cardKey: String) async -> UIImage {
        // Find the card info if available
        let cardInfo: CreditCardInfo?
        
        if let existingCard = cachedCards?.first(where: { $0.id == cardKey }) {
            cardInfo = existingCard
        } else if let detailedCard = cachedCardDetails[cardKey] {
            cardInfo = detailedCard
        } else {
            // Try to get card details if we don't have them
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
        
        let card = cardInfo!
            
            // Canvas size - credit card aspect ratio
            let size = CGSize(width: 600, height: 380)
            
            // Get background color based on card category or issuer
            let backgroundColor = getColorForCard(card)
            
            // Start drawing
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            defer { UIGraphicsEndImageContext() }
            
            // Draw card background with rounded corners
            let context = UIGraphicsGetCurrentContext()!
            let rect = CGRect(origin: .zero, size: size)
            let roundedRect = UIBezierPath(roundedRect: rect, cornerRadius: 20)
            
            // Create a gradient background
            let colors = createGradientColors(for: backgroundColor)
            let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: colors as CFArray,
                locations: [0.0, 1.0]
            )!
            
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
            drawIssuerLogo(for: card, in: context, size: size)
            
            // Draw card name
            drawCardName(card.name, in: context, size: size)
            
            // Get the final image
            let image = UIGraphicsGetImageFromCurrentImageContext()!
            
            // Cache the generated image
            imageCache[cardKey] = image
            print("🎨 Generated placeholder image for: \(cardKey)")
            
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
    
    
    
    
    
    // Test method for card images
    func testCardImage(cardKey: String) {
        print("🧪 TESTING CARD IMAGE API FOR: \(cardKey)")
        
        let imageUrl = URL(string: "https://rewards-credit-card-api.p.rapidapi.com/creditcard-card-image/\(cardKey)")!
        
        let headers = [
            "x-rapidapi-key": "a65d839d26msh7165854114aafbbp1c3b60jsnc2e5f215b4c9",
            "x-rapidapi-host": "rewards-credit-card-api.p.rapidapi.com"
        ]
        
        let request = NSMutableURLRequest(
            url: imageUrl,
            cachePolicy: .useProtocolCachePolicy,
            timeoutInterval: 10.0
        )
        
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                print("❌ Error: \(error)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response")
                return
            }
            
            print("📥 HTTP Status: \(httpResponse.statusCode)")
            
            if let data = data {
                print("📊 Received data size: \(data.count) bytes")
                
                // Try to interpret as a string
                if let textContent = String(data: data, encoding: .utf8) {
                    print("📝 Text content (if applicable): \(textContent)")
                }
                
                // Try to create an image
                if let image = UIImage(data: data) {
                    print("✅ Successfully created image with size: \(image.size.width) x \(image.size.height)")
                } else {
                    print("❌ Failed to create image from data")
                }
            } else {
                print("❌ No data received")
            }
        }
        
        dataTask.resume()
        print("🔄 Test initiated - check console for results")
    }
    
    func fetchCardsByFilter(category: String? = nil, issuer: String? = nil, limit: Int = 10) async -> [CreditCardInfo] {
        print("🔍 Fetching cards with filter - Category: \(category ?? "Any"), Issuer: \(issuer ?? "Any")")
        
        // First, make sure we have basic cards loaded
        if cachedCards == nil || cachedCards?.isEmpty == true {
            do {
                _ = try await fetchComprehensiveCardCatalog()
            } catch {
                print("❌ Failed to load basic card catalog: \(error)")
                return []
            }
        }
        
        guard let cards = cachedCards else { return [] }
        
        // Filter the cards based on criteria
        let filteredCards = cards.filter { card in
            let categoryMatch = category == nil || card.category.lowercased() == category?.lowercased()
            let issuerMatch = issuer == nil || card.issuer.lowercased().contains(issuer?.lowercased() ?? "")
            return categoryMatch && issuerMatch
        }
        
        // Sort by popularity (assuming higher signup bonus means more popular)
        let sortedCards = filteredCards.sorted { $0.signupBonus > $1.signupBonus }
        
        // Limit the number of cards to return
        let limitedCards = sortedCards.prefix(limit)
        
        // Now prefetch details for these cards in background
        Task {
            await prefetchCardDetails(for: limitedCards.map { $0.id })
        }
        
        return Array(limitedCards)
    }
    
    
    
    
    // Fallback method for fetching images from URL
    func fetchCardImageFromURL(for url: String) async -> UIImage? {
        // Check cache first
        if let cachedImage = imageCache[url] {
            return cachedImage
        }
        
        // Skip if URL is empty
        guard !url.isEmpty, let imageURL = URL(string: url) else {
            return nil
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            if let image = UIImage(data: data) {
                // Cache the image
                imageCache[url] = image
                return image
            }
        } catch {
            print("Error fetching image from URL: \(error)")
        }
        
        return nil
    }
    
    // For manually clearing the image cache (useful for debugging)
    func clearImageCache() {
        imageCache.removeAll()
        print("🧹 Image cache cleared")
    }
    
    // Utility method to preload common card images
    func preloadCommonCardImages() {
        Task {
            let commonCards = ["chase-sapphire-preferred", "chase-sapphire-reserve", "amex-gold", "amex-platinum", "chase-hyatt"]
            
            for cardKey in commonCards {
                if imageCache[cardKey] == nil {
                    print("🔄 Preloading image for: \(cardKey)")
                    _ = await fetchCardImage(for: cardKey)
                }
            }
        }
    }
    
    // MARK: - Search Methods
    
    // Fetch cards using search terms
    func fetchCardsBySearch(searchTerms: [String]) async throws -> [CreditCardInfo] {
        print("🔍 Fetching credit cards using search terms: \(searchTerms)")
        var allCards: [CreditCardInfo] = []
        
        for term in searchTerms {
            do {
                // Make API request using the search endpoint - now using CardSearchAPIResponse
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
    
    // Test searching for specific cards
    func testSearchAPI(term: String) async {
        print("🧪 TESTING SEARCH API WITH TERM: \(term)")
        
        do {
            let searchResults: CardSearchAPIResponse = try await APIClient.fetchCardsBySearchTerm(term)
            print("✅ Found \(searchResults.count) cards for search term '\(term)'")
            
            // Print details about each card
            for (index, card) in searchResults.enumerated() {
                print("  Card \(index + 1): \(card.cardName) by \(card.cardIssuer) (ID: \(card.cardKey))")
            }
            
            // Try to fetch an image for the first card if available
            if let firstCard = searchResults.first {
                print("🖼️ Testing image fetch for: \(firstCard.cardKey)")
                if let _ = await fetchCardImage(for: firstCard.cardKey) {
                    print("✅ Successfully fetched image for \(firstCard.cardKey)")
                } else {
                    print("❌ Failed to fetch image for \(firstCard.cardKey)")
                }
            }
        } catch {
            print("❌ Error testing search API: \(error)")
        }
    }
    
    // Fetch comprehensive card catalog by combining basic and search endpoints
    func fetchComprehensiveCardCatalog() async throws -> [CreditCardInfo] {
        print("📊 Fetching comprehensive card catalog...")
        
        // Common search terms to fetch popular cards
        let searchTerms = ["chase", "amex", "american express", "citi", "capital one",
                         "discover", "wells fargo", "bank of america", "barclays",
                         "us bank", "hsbc", "united", "delta", "southwest", "marriott",
                         "hilton", "ihg", "hyatt", "travel", "cash", "business"]
        
        var allCards: [CreditCardInfo] = []
        
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
            
            print("✅ Added \(allCards.count - seenCardIds.count) unique cards from search")
        } catch {
            print("⚠️ Error fetching search cards: \(error)")
        }
        
        // Sort cards by issuer and name
        allCards.sort {
            if $0.issuer == $1.issuer {
                return $0.name < $1.name
            }
            return $0.issuer < $1.issuer
        }
        
        // Cache the results
        self.cachedCards = allCards
        
        print("✅ Complete catalog contains \(allCards.count) unique credit cards")
        return allCards
    }
    
    // MARK: - Helper Methods
    
    // Helper function to categorize based on description
    // Replace the existing getCategoryFromDescription method
    private func getCategoryFromDescription(_ description: String) -> String {
        let lowercased = description.lowercased()
        
        // Try to infer category from description
        if lowercased.contains("groceries") || lowercased.contains("supermarket") {
            return "Groceries"
        } else if lowercased.contains("dining") || lowercased.contains("restaurant") {
            return "Dining"
        } else if lowercased.contains("travel") || lowercased.contains("flight") || lowercased.contains("hotel") {
            return "Travel"
        } else if lowercased.contains("airline") || lowercased.contains("flight") {
            return "Airline"
        } else if lowercased.contains("hotel") || lowercased.contains("resort") {
            return "Hotel"
        } else if lowercased.contains("gas") || lowercased.contains("fuel") {
            return "Gas"
        } else if lowercased.contains("cash") || lowercased.contains("back") {
            return "Cashback"
        } else if lowercased.contains("business") {
            return "Business"
        } else {
            return "General"
        }
    }
    
    // Diagnostic method to dump all loaded cards to the console
    func dumpAllCards() {
        guard let cards = cachedCards else {
            print("❌ No cached cards available")
            return
        }
        
        print("📋 CARD CATALOG SUMMARY:")
        print("Total cards: \(cards.count)")
        
        // Count by issuer
        let issuerCounts = Dictionary(grouping: cards, by: { $0.issuer })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        print("\nCards by Issuer:")
        for (issuer, count) in issuerCounts {
            print("  \(issuer): \(count) cards")
        }
        
        // Count by category
        let categoryCounts = Dictionary(grouping: cards, by: { $0.category })
            .mapValues { $0.count }
            .sorted { $0.value > $1.value }
        
        print("\nCards by Category:")
        for (category, count) in categoryCounts {
            print("  \(category): \(count) cards")
        }
        
        // Show some sample cards
        print("\nSample Cards:")
        for (index, card) in cards.prefix(10).enumerated() {
            print("  \(index + 1). \(card.name) (\(card.issuer)) - \(card.category) - $\(card.annualFee) Annual Fee")
        }
    }
    
    
    
    
    // Sample data for fallback
    private func getSampleCreditCardData() -> [CreditCardInfo] {
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
}

// Extension for improved categorization
extension CreditCardService {
    // Standardize categories to a common set
    func standardizeCardCategory(_ category: String) -> String {
        let lowerCategory = category.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Map to standard categories
        if lowerCategory.contains("travel") || lowerCategory.contains("point") {
            return "Travel"
        } else if lowerCategory.contains("cash") || lowerCategory.contains("back") {
            return "Cashback"
        } else if lowerCategory.contains("hotel") || lowerCategory.contains("lodging") {
            return "Hotel"
        } else if lowerCategory.contains("airline") || lowerCategory.contains("flight") {
            return "Airline"
        } else if lowerCategory.contains("dining") || lowerCategory.contains("restaurant") {
            return "Dining"
        } else if lowerCategory.contains("grocer") || lowerCategory.contains("supermarket") {
            return "Groceries"
        } else if lowerCategory.contains("gas") || lowerCategory.contains("fuel") {
            return "Gas"
        } else if lowerCategory.contains("business") {
            return "Business"
        } else if lowerCategory.contains("student") || lowerCategory.contains("college") {
            return "Student"
        } else {
            return "General"
        }
    }
    
    // Enhanced category detection from card details
    func getCategoryFromDetail(_ cardDetail: CardDetail) -> String {
        // Start with a default category
        var category = "General"
        
        // Check if we have bonus categories
        if !cardDetail.spendBonusCategory.isEmpty {
            // Get the category with the highest multiplier
            if let highest = cardDetail.spendBonusCategory.max(by: { $0.earnMultiplier < $1.earnMultiplier }) {
                let bonusCategory = highest.spendBonusCategoryGroup
                
                // If the highest bonus category is significant, use it
                if highest.earnMultiplier >= 3.0 {
                    return standardizeCardCategory(bonusCategory)
                }
                
                // Otherwise, consider it but keep checking
                category = standardizeCardCategory(bonusCategory)
            }
        }
        
        // Check the sign-up bonus category
        if !cardDetail.signupBonusCategory.isEmpty {
            let signupCategory = cardDetail.signupBonusCategory
            
            // If it's a travel-related signup bonus, prioritize that
            if signupCategory.lowercased().contains("travel") ||
               signupCategory.lowercased().contains("hotel") ||
               signupCategory.lowercased().contains("airline") {
                return standardizeCardCategory(signupCategory)
            }
        }
        
        // Look for key features in the benefits
        for benefit in cardDetail.benefit {
            let benefitDesc = benefit.benefitDesc.lowercased()
            
            if benefitDesc.contains("travel credit") ||
               benefitDesc.contains("hotel credit") ||
               benefitDesc.contains("lounge access") {
                return "Travel"
            }
            
            if benefitDesc.contains("free night") || benefitDesc.contains("hotel status") {
                return "Hotel"
            }
            
            if benefitDesc.contains("companion pass") || benefitDesc.contains("free checked bag") {
                return "Airline"
            }
        }
        
        // Return the best category we've found
        return category
    }
}
