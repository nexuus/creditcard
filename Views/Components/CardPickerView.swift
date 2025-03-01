//
//  CardPickerView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

import SwiftUI

// In AddCardView.swift, ensure the CardPickerView is showing the API data


struct CardPickerView: View {
    @Binding var selectedCard: CreditCardInfo?
    @Binding var searchQuery: String
    @Binding var selectedCategory: String?
    let categories: [String]
    let filteredCards: [CreditCardInfo]
    let onDismiss: () -> Void
    @ObservedObject var viewModel: CardViewModel // Add this property
    
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @State private var showingAllCards = false // Add this state
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search cards", text: $searchQuery)
                        .disableAutocorrection(true)
                    
                    if !searchQuery.isEmpty {
                        Button(action: {
                            searchQuery = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                
                // "Show all cards" toggle
                Toggle("Show all \(viewModel.availableCreditCards.count) cards", isOn: $showingAllCards)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .onChange(of: showingAllCards) { _ in
                        // Clear search when toggling to ensure correct filtering
                        if !showingAllCards && !searchQuery.isEmpty {
                            searchQuery = ""
                        }
                    }
                
                // Category filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryButton(
                            title: "All",
                            isSelected: selectedCategory == nil,
                            action: { selectedCategory = nil }
                        )
                        
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
                .padding(.vertical, 8)
                .background(colorScheme == .dark ? Color(.systemGray6) : Color(.systemGray6))
                
                // Results list
                if cardsToShow.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "creditcard")
                            .font(.system(size: 48))
                            .foregroundColor(.gray)
                        
                        Text("No cards found")
                            .font(.headline)
                        
                        Text("Try a different search term or category")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    List {
                        Text("Found \(cardsToShow.count) cards")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                        
                        ForEach(cardsToShow) { card in
                            CardInfoRow(card: card, isSelected: selectedCard?.id == card.id)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedCard = card
                                    presentationMode.wrappedValue.dismiss()
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Select Credit Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        onDismiss()
                    }
                }
            }
        }
    }
    
    // Compute which cards to show based on search, filters, and toggle state
    private var cardsToShow: [CreditCardInfo] {
        // Base collection - use all cards or popular cards based on toggle
        let baseCards = showingAllCards || !searchQuery.isEmpty
            ? viewModel.availableCreditCards
            : viewModel.popularCreditCards
        
        // Apply category filter if selected
        let categoryFiltered = selectedCategory == nil
            ? baseCards
            : baseCards.filter { $0.category == selectedCategory }
        
        // Apply search filter if text entered
        if searchQuery.isEmpty {
            return categoryFiltered
        } else {
            return categoryFiltered.filter { card in
                card.name.localizedCaseInsensitiveContains(searchQuery) ||
                card.issuer.localizedCaseInsensitiveContains(searchQuery)
            }
        }
    }
}


// This is needed by CardPickerView
struct CardInfoRow: View {
    let card: CreditCardInfo
    let isSelected: Bool
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(card.name)
                    .font(.headline)
                
                Text(card.issuer)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                
                Text(card.category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(
                        categoryColor(for: card.category)
                            .opacity(0.2)
                    )
                    .foregroundColor(categoryColor(for: card.category))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark")
                    .foregroundColor(.accentColor)
            }
        }
        .contentShape(Rectangle())
        .padding(.vertical, 6)
    }
    
    func categoryColor(for category: String) -> Color {
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
        default:
            return .gray
        }
    }
}
