//
//  CardCatalogView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine

struct CardCatalogView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    @State private var isLoadingImages = false
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
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryButton(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            // Only show categories that actually have cards
                            let cardsToFilter = searchText.isEmpty ? viewModel.popularCreditCards : viewModel.availableCreditCards
                            let categories = Array(Set(cardsToFilter.map { $0.category })).sorted()
                            
                            ForEach(categories, id: \.self) { category in
                                CategoryButton(
                                    title: category,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Status information
                    // Show card count
                    HStack {
                        if searchText.isEmpty {
                            Text("\(viewModel.popularCreditCards.count) popular cards")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Showing results from \(viewModel.availableCreditCards.count) cards")
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
                    
                    // Cards list
                    if viewModel.isLoadingCards {
                        // Full loading view
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
                        // For empty search or category filter, use popularCreditCards
                        // For non-empty search, search through ALL available cards
                        let cardsToDisplay = searchText.isEmpty ? viewModel.popularCreditCards : viewModel.availableCreditCards
                        
                        let filteredCards = cardsToDisplay.filter {
                            (selectedCategory == nil || $0.category == selectedCategory) &&
                            (searchText.isEmpty ||
                             $0.name.lowercased().contains(searchText.lowercased()) ||
                             $0.issuer.lowercased().contains(searchText.lowercased()))
                        }
                        
                        if filteredCards.isEmpty {
                            VStack(spacing: 24) {
                                Image(systemName: "creditcard")
                                    .font(.system(size: 64))
                                    .foregroundColor(.gray)
                                    .padding(.top, 40)
                                
                                Text("No Cards Found")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                if searchText.isEmpty && selectedCategory != nil {
                                    Text("No cards found in the '\(selectedCategory!)' category")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                } else if !searchText.isEmpty {
                                    Text("Try a different search term")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    // Show info that we're searching all cards
                                    Text("Searching across all \(viewModel.availableCreditCards.count) cards")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 8)
                                } else {
                                    Text("Try a different category or search")
                                        .font(.body)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView {
                                // Show search info if user is searching
                                if !searchText.isEmpty {
                                    HStack {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.blue)
                                        
                                        Text("Searching all \(viewModel.availableCreditCards.count) cards")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                                
                                LazyVStack(spacing: 16) {
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
            }
            .navigationTitle("Card Catalog")
            .onAppear {
                // Load cards if we don't have any yet
                if viewModel.availableCreditCards.isEmpty {
                    Task {
                        await viewModel.loadCreditCardsFromAPI()
                    }
                }
            }
        }
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

// Preview provider for development
#Preview {
    CardCatalogView(viewModel: CardViewModel())
}
