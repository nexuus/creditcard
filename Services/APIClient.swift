//
//  APIClient.swift
//  CreditCardTracker
//

import Foundation

struct APIClient {
    // MARK: - API Configuration
    
    // Keep these for backward compatibility but they're no longer used
    static let apiKey = ""
    static let apiHost = ""
    static let baseURL = ""
    
    // GitHub credit card bonuses API configuration - updated URL
    static let bonusesBaseURL = "https://raw.githubusercontent.com/andenacitelli/credit-card-bonuses-api/main"
    static let bonusesDataURL = "\(bonusesBaseURL)/exports/data.json"
    
    // MARK: - Error Types
    
    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingFailed(Error)
        case rateLimitExceeded
        case emptyResponse
    }
    
    // MARK: - API Methods
    
    // Generic function to maintain backward compatibility
    // Modify the fetch<T> method to handle the new model structure
    // Modify the fetch<T> method to handle the new model structure
    static func fetch<T: Decodable>(endpoint: String, parameters: [String: String] = [:]) async throws -> T {
        print("⚠️ Legacy fetch method called - redirecting to GitHub API")
        
        // For compatibility, redirect to GitHub API instead
        if T.self == CreditCardAPIResponse.self {
            let bonuses = try await fetchCardBonuses()
            
            // Convert GitHub API response to match the expected type
            let convertedResponse = bonuses.map { bonus -> APICard in
                // Get the best offer for this card
                let bestOffer = bonus.offers.max(by: {
                    $0.amount.first?.amount ?? 0 < $1.amount.first?.amount ?? 0
                })
                
                let bonusAmount = bestOffer?.amount.first?.amount ?? 0
                let spendRequired = bestOffer?.spend ?? 0
                let timeframe = bestOffer?.days ?? 90
                
                // Format issuer name
                let issuerName = bonus.issuer
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
                
                // Determine bonus type
                var bonusType = "points"
                if bonus.universalCashbackPercent != nil && bonus.universalCashbackPercent ?? 0 > 0 {
                    bonusType = "cash back"
                } else if bonus.issuer == "AMERICAN_EXPRESS" {
                    bonusType = "Membership Rewards points"
                } else if bonus.issuer == "CHASE" {
                    bonusType = "Ultimate Rewards points"
                }
                
                return APICard(
                    cardKey: bonus.cardId,
                    cardName: bonus.name,
                    cardIssuer: issuerName,
                    spendType: bonusType,
                    earnMultiplier: Double(bonusAmount) / 1000.0,
                    earnMultiplierValue: Double(bonusAmount),
                    spendBonusDesc: "Earn \(bonusAmount) \(bonusType) after spending $\(spendRequired) in \(timeframe/30) months",
                    limitBeginDate: "",
                    limitEndDate: "",
                    isSpendLimit: 1,
                    spendLimit: Double(spendRequired),
                    spendLimitResetPeriod: "\(timeframe/30) months"
                )
            } as! T
            
            return convertedResponse
        }
        
        throw APIError.invalidResponse
    }
    
    // Fetch credit card bonuses from the GitHub API
    // Fetch credit card bonuses from the GitHub API
    static func fetchCardBonuses() async throws -> [CreditCardBonus] {
        print("🔄 Fetching credit card bonuses from GitHub API...")
        
        guard let url = URL(string: bonusesDataURL) else {
            print("❌ Invalid URL for GitHub bonuses API")
            throw APIError.invalidURL
        }
        
        // Create a URLSession configuration that doesn't store credentials
        let config = URLSessionConfiguration.ephemeral
        config.httpShouldSetCookies = false
        config.httpCookieAcceptPolicy = .never
        config.httpCookieStorage = nil
        config.urlCredentialStorage = nil
        
        let session = URLSession(configuration: config)
        
        do {
            let (data, response) = try await session.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response")
                throw APIError.invalidResponse
            }
            
            print("📥 GitHub API response status: \(httpResponse.statusCode)")
            
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("Error details: \(errorText)")
                }
                throw APIError.invalidResponse
            }
            
            // Log response preview for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                let previewLength = min(500, jsonString.count)
                let preview = jsonString.prefix(previewLength)
                print("✅ GitHub API response (\(data.count) bytes): \(preview)...")
            }
            
            do {
                let decoder = JSONDecoder()
                let bonuses = try decoder.decode([CreditCardBonus].self, from: data)
                print("✅ Successfully fetched \(bonuses.count) bonuses from GitHub API")
                return bonuses
            } catch {
                print("❌ Decoding error: \(error)")
                print("❌ Failed to decode GitHub API response: \(error)")
                throw APIError.decodingFailed(error)
            }
        } catch {
            print("❌ Network error: \(error)")
            if let apiError = error as? APIError {
                throw apiError
            }
            throw APIError.requestFailed(error)
        }
    }
    
    // Implement search functionality using GitHub API data
    static func fetchCardsBySearchTerm(_ term: String) async throws -> CardSearchAPIResponse {
        print("🔍 Searching cards with term: \(term) using GitHub API data")
        
        // First fetch all cards from GitHub
        let allBonuses = try await fetchCardBonuses()
        
        // Convert to the expected response type and filter by search term
        let searchResults = allBonuses
            .filter { bonus in
                // Case-insensitive search in card name and issuer
                bonus.name.lowercased().contains(term.lowercased()) ||
                bonus.issuer.lowercased().contains(term.lowercased())
            }
            .map { bonus -> CardSearchResult in
                // Convert to the expected CardSearchResult type
                return CardSearchResult(
                    cardKey: bonus.id,
                    cardIssuer: bonus.issuer,
                    cardName: bonus.name
                )
            }
        
        print("✅ Found \(searchResults.count) cards matching '\(term)'")
        return searchResults
    }
    
    // Stub methods for compatibility
    static func testCardDetailEndpoint(cardKey: String) async {
        print("⚠️ testCardDetailEndpoint called but using GitHub API instead")
    }
    
    static func testSearchAPI(term: String) async {
        print("⚠️ testSearchAPI called but using GitHub API instead")
        
        do {
            let results = try await fetchCardsBySearchTerm(term)
            print("✅ Found \(results.count) cards matching '\(term)'")
        } catch {
            print("❌ Error searching: \(error)")
        }
    }
}
