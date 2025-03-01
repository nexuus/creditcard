//
//  TrackerView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

//
//  TrackerView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.

struct TrackerView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var showingAddCard = false
    @Environment(\.colorScheme) var colorScheme
    
    // API testing state
    @State private var isTestingAPI = false
    @State private var apiTestResult = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content wrapped in ScrollView
                ScrollView {
                    VStack(spacing: 0) {
                       
                        // Debug section only appears in debug builds
                        
                            
                            // Add Card Search API test button
                        
                          
                        
                        
                        // Dashboard summary
                        DashboardView(viewModel: viewModel)
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 12)
                        
                        // Add Detailed Stats (only show if there are cards)
                        if !viewModel.cards.isEmpty {
                            DetailedStatsView(viewModel: viewModel)
                                .padding(.horizontal)
                                .padding(.bottom, 12)
                        }
                        
                        // Section header for cards
                        HStack {
                            Text("Your Cards")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        
                        // Cards content - either empty state or card list
                        if viewModel.cards.isEmpty {
                            // Empty state
                            VStack(spacing: 24) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                                
                                Text("No Cards Yet")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                Text("Add your first credit card to start tracking rewards")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                                
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
                                .padding(.top, 20)
                                .padding(.bottom, 40) // Add some padding at the bottom for empty state
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            // Card list
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.cards) { card in
                                    ZStack {
                                        CardRowView(card: card, viewModel: viewModel)
                                            .contentShape(Rectangle())
                                        
                                        NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                            EmptyView()
                                        }
                                        .opacity(0)
                                    }
                                }
                                .onDelete(perform: viewModel.deleteCard)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20) // Add padding at bottom to ensure last card isn't cut off
                        }
                    }
                    .padding(.top) // Add some padding at the top of the entire content
                }
                // End of ScrollView
            }
            .navigationTitle("Card Tracker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddCard = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .padding(8)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                }
            }
            .sheet(isPresented: $showingAddCard) {
                AddCardView(viewModel: viewModel)
            }
        }
    }
    
    // API testing function
    func testAPI() async {
        do {
            // Test the card detail endpoint
            let endpoint = "/creditcard-detail-bycard/amex-gold"
            print("Testing endpoint: \(endpoint)")
            
            // For debugging, first try to get the raw response without decoding
            let testURL = URL(string: APIClient.baseURL + endpoint)!
            var testRequest = URLRequest(url: testURL)
            testRequest.httpMethod = "GET"
            testRequest.addValue(APIClient.apiKey, forHTTPHeaderField: "x-rapidapi-key")
            testRequest.addValue(APIClient.apiHost, forHTTPHeaderField: "x-rapidapi-host")
            
            let (data, response) = try await URLSession.shared.data(for: testRequest)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run {
                    apiTestResult = "Error: Not an HTTP response"
                }
                return
            }
            
            print("HTTP Status: \(httpResponse.statusCode)")
            
            if (200...299).contains(httpResponse.statusCode) {
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString)")
                    await MainActor.run {
                        apiTestResult = "Success! Received \(data.count) bytes of data."
                    }
                    
                    // Try to test image API as well
                    await testImageAPI()
                }
            } else {
                await MainActor.run {
                    apiTestResult = "Error: HTTP \(httpResponse.statusCode)"
                }
            }
        } catch {
            print("API Test error: \(error)")
            await MainActor.run {
                apiTestResult = "Error: \(error.localizedDescription)"
            }
        }
    }
    
    // Helper to test image API
    func testImageAPI() async {
        do {
            let imageEndpoint = "/creditcard-card-image/amex-gold"
            let imageURL = URL(string: APIClient.baseURL + imageEndpoint)!
            var imageRequest = URLRequest(url: imageURL)
            imageRequest.httpMethod = "GET"
            imageRequest.addValue(APIClient.apiKey, forHTTPHeaderField: "x-rapidapi-key")
            imageRequest.addValue(APIClient.apiHost, forHTTPHeaderField: "x-rapidapi-host")
            
            let (imageData, imageResponse) = try await URLSession.shared.data(for: imageRequest)
            
            guard let httpImageResponse = imageResponse as? HTTPURLResponse else { return }
            
            print("Image API HTTP Status: \(httpImageResponse.statusCode)")
            
            if (200...299).contains(httpImageResponse.statusCode) {
                if let _ = UIImage(data: imageData) {
                    print("✅ Successfully received image data: \(imageData.count) bytes")
                    await MainActor.run {
                        apiTestResult += "\nImage API: Success! (\(imageData.count) bytes)"
                    }
                } else {
                    print("❌ Received data but couldn't create image")
                    await MainActor.run {
                        apiTestResult += "\nImage API: Data received but not a valid image"
                    }
                }
            } else {
                print("❌ Image API error: HTTP \(httpImageResponse.statusCode)")
                await MainActor.run {
                    apiTestResult += "\nImage API: HTTP \(httpImageResponse.statusCode)"
                }
            }
        } catch {
            print("Image API Test error: \(error)")
            await MainActor.run {
                apiTestResult += "\nImage API Error: \(error.localizedDescription)"
            }
        }
    }
}

// Preview provider for development
#Preview {
    TrackerView(viewModel: CardViewModel())
}
