//
//  APIClient.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

import Foundation

// Make sure your APIClient struct has the correct API credentials:

//
//  APIClient.swift

struct APIClient {
    // Use your actual RapidAPI credentials
    static let apiKey = "7afdf81bdfmshec1b3d513d53327p1aa78bjsncf0b3e26c2a5"
    static let apiHost = "rewards-credit-card-api.p.rapidapi.com"
    static let baseURL = "https://rewards-credit-card-api.p.rapidapi.com"
    
    enum APIError: Error {
        case invalidURL
        case requestFailed(Error)
        case invalidResponse
        case decodingFailed(Error)
    }
    
    // Generic function to fetch data from any endpoint
    static func fetch<T: Decodable>(endpoint: String, parameters: [String: String] = [:]) async throws -> T {
        print("🌐 API REQUEST: \(baseURL + endpoint)")
        
        // Construct URL with parameters
        var components = URLComponents(string: baseURL + endpoint)
        
        if !parameters.isEmpty {
            components?.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
            print("📝 Parameters: \(parameters)")
        }
        
        guard let url = components?.url else {
            print("❌ Invalid URL: \(baseURL + endpoint)")
            throw APIError.invalidURL
        }
        
        // Create request with headers
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
        request.addValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
        
        print("📤 Sending request to: \(url.absoluteString)")
        
        // Make request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Not an HTTP response")
                throw APIError.invalidResponse
            }
            
            print("📥 Response status: \(httpResponse.statusCode)")
            
            // Check response status
            guard (200...299).contains(httpResponse.statusCode) else {
                print("❌ HTTP Error: \(httpResponse.statusCode)")
                if let errorText = String(data: data, encoding: .utf8) {
                    print("Error details: \(errorText)")
                }
                throw APIError.invalidResponse
            }
            
            // Log response for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                let previewLength = min(500, jsonString.count)
                let preview = jsonString.prefix(previewLength)
                print("✅ API response (\(data.count) bytes): \(preview)...")
            }
            
            do {
                let decoder = JSONDecoder()
                let decoded = try decoder.decode(T.self, from: data)
                print("✅ Successfully decoded response to \(T.self)")
                return decoded
            } catch {
                print("❌ Decoding error: \(error)")
                print("❌ Failed to decode to \(T.self)")
                
                // Print the raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Raw JSON: \(jsonString)")
                }
                
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
}

extension APIClient {
    // Specific method for the card search endpoint to ensure proper handling
    // Update this method in APIClient.swift:

    // Specific method for the card search endpoint to ensure proper handling
    static func fetchCardsBySearchTerm(_ term: String) async throws -> CardSearchAPIResponse {
        // URL encode the search term
        guard let encodedTerm = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            throw APIError.invalidURL
        }
        
        let endpoint = "/creditcard-detail-namesearch/\(encodedTerm)"
        print("🔍 Searching cards with term: \(term)")
        
        return try await fetch(endpoint: endpoint)
    }
    // Test a specific card detail endpoint
    static func testCardDetailEndpoint(cardKey: String) async {
        print("🧪 Testing card detail endpoint for: \(cardKey)")
        
        do {
            // Create the URL for testing
            let testURL = URL(string: baseURL + "/creditcard-detail-bycard/\(cardKey)")!
            var request = URLRequest(url: testURL)
            request.httpMethod = "GET"
            request.addValue(apiKey, forHTTPHeaderField: "x-rapidapi-key")
            request.addValue(apiHost, forHTTPHeaderField: "x-rapidapi-host")
            
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
                    let decoded = try decoder.decode(CardDetailAPIResponse.self, from: data)
                    print("✅ Successfully decoded \(decoded.count) cards")
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
}
