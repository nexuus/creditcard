//
//  AddCardView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
import SwiftUI
import Foundation
import Combine


struct AddCardView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    // Form fields
    @State private var name = ""
    @State private var issuer = ""
    @State private var signupBonus = ""
    @State private var annualFee = ""
    @State private var notes = ""
    @State private var bonusAchieved = false
    @State private var dateOpened = Date()
    
    // Search and selection
    @State private var searchQuery = ""
    @State private var selectedCard: CreditCardInfo? = nil
    @State private var showingCardPicker = false
    @State private var selectedCategory: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Card Selection Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Card Selection")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            if viewModel.isLoadingCards {
                                HStack {
                                    Text("Loading available cards...")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    ProgressView()
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                )
                            } else if let error = viewModel.apiLoadingError {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Error loading cards")
                                        .font(.headline)
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                    Button("Try Again") {
                                        Task {
                                            await viewModel.loadCreditCardsFromAPI()
                                        }
                                    }
                                    .padding(.top, 4)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                )
                            } else {
                                // Card selection button
                                Button(action: {
                                    showingCardPicker = true
                                }) {
                                    HStack {
                                        if selectedCard == nil {
                                            Image(systemName: "creditcard")
                                                .foregroundColor(.accentColor)
                                                .font(.headline)
                                                .padding(.trailing, 4)
                                            
                                            Text("Select a Credit Card")
                                                .foregroundColor(.accentColor)
                                        } else {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(selectedCard!.name)")
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text("\(selectedCard!.issuer) • \(selectedCard!.category)")
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                            }
                                            
                                            Spacer()
                                            
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                                            .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
                                    )
                                }
                            }
                        }
                        
                        // Card Details Section
                        cardDetailsSection
                        
                        // Bonus Details Section
                        bonusDetailsSection
                        
                        // Notes Section
                        notesSection
                        
                        // Save Button
                        Button(action: {
                            saveCard()
                        }) {
                            Text("Save Card")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isFormValid ? Color.accentColor : Color.gray)
                                )
                        }
                        .disabled(!isFormValid)
                        .padding(.vertical, 10)
                    }
                    .padding()
                }
            }
            .navigationTitle("Add New Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCardPicker) {
                CardPickerView(
                    selectedCard: $selectedCard,
                    searchQuery: $searchQuery,
                    selectedCategory: $selectedCategory,
                    categories: categories,
                    filteredCards: filteredCards,
                    onDismiss: {
                        // Your existing onDismiss code
                    },
                    viewModel: viewModel // Pass the viewModel instance here
                )
            }
            
            .onChange(of: selectedCard) { newSelectedCard in
                if let card = newSelectedCard {
                    // Auto-fill form fields with selected card data
                    name = card.name
                    issuer = card.issuer
                    signupBonus = String(card.signupBonus)
                    annualFee = String(format: "%.0f", card.annualFee)
                    
                    // Prepare detailed description for notes
                    var detailedNotes = "Card details:\n"
                    detailedNotes += "• Category: \(card.category)\n"
                    detailedNotes += "• Annual Fee: $\(card.annualFee)\n"
                    detailedNotes += "• Signup Bonus: \(card.signupBonus) points\n"
                    if !card.description.isEmpty {
                        detailedNotes += "\nDescription:\n\(card.description)"
                    }
                    notes = detailedNotes
                }
            }
            
        }
    }
    
    // MARK: - Computed Properties
    
    // Computed properties for filtering
    private var filteredCards: [CreditCardInfo] {
        let results = viewModel.searchCreditCards(searchTerm: searchQuery)
        if let category = selectedCategory {
            return results.filter { $0.category == category }
        }
        return results
    }
    
    private var categories: [String] {
        Array(Set(viewModel.availableCreditCards.map { $0.category })).sorted()
    }
    
    private var isFormValid: Bool {
        return !name.isEmpty && !issuer.isEmpty
    }
    
    // MARK: - View Components
    
    private var cardDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Card Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if selectedCard != nil {
                    Spacer()
                    Text("Auto-filled")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            FormField(
                icon: "creditcard",
                title: "Card Name",
                placeholder: "e.g. Sapphire Preferred",
                text: $name,
                isAutofilled: selectedCard != nil
            )
            
            FormField(
                icon: "building.columns",
                title: "Card Issuer",
                placeholder: "e.g. Chase",
                text: $issuer,
                isAutofilled: selectedCard != nil
            )
            
            // Date picker with custom style
            VStack(alignment: .leading, spacing: 6) {
                Text("Date Opened")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                DatePicker(
                    "",
                    selection: $dateOpened,
                    displayedComponents: .date
                )
                .labelsHidden()
                .padding(.horizontal, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            )
            
            FormField(
                icon: "dollarsign.circle",
                title: "Annual Fee",
                placeholder: "e.g. 95",
                text: $annualFee,
                keyboardType: .decimalPad,
                prefix: "$",
                isAutofilled: selectedCard != nil
            )
        }
    }
    
    private var bonusDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Bonus Details")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if selectedCard != nil {
                    Spacer()
                    Text("Auto-filled")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            FormField(
                icon: "star",
                title: "Signup Bonus Points",
                placeholder: "e.g. 60000",
                text: $signupBonus,
                keyboardType: .numberPad,
                isAutofilled: selectedCard != nil
            )
            
            // Toggle with custom style
            VStack(alignment: .leading, spacing: 6) {
                Text("Bonus Achieved")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Bonus Achieved", isOn: $bonusAchieved)
                    .labelsHidden()
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                    .padding(.horizontal, 4)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            )
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Notes")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if selectedCard != nil && !notes.isEmpty {
                    Spacer()
                    Text("Auto-filled")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Additional Details")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if selectedCard != nil {
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $notes)
                            .frame(minHeight: 120)
                            .padding(4)
                            .foregroundColor(.blue)
                        
                        if notes.isEmpty {
                            Text("Card details and description will appear here...")
                                .foregroundColor(Color(.placeholderText))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
                } else {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                        .padding(4)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                    .shadow(color: Color.black.opacity(0.03), radius: 5, x: 0, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedCard != nil && !notes.isEmpty ? Color.blue.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
    }
    
    
    
    // MARK: - Methods
    
    private func saveCard() {
        let newCard = CreditCard(
            name: name,
            issuer: issuer,
            dateOpened: dateOpened,
            signupBonus: Int(signupBonus) ?? 0,
            bonusAchieved: bonusAchieved,
            annualFee: Double(annualFee) ?? 0.0,
            notes: notes
        )
        
        viewModel.addCard(newCard)
        presentationMode.wrappedValue.dismiss()
    }
}
