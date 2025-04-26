// File: CreditCardTracker/Views/Tracker/InactiveCardsListView.swift
import SwiftUI

struct InactiveCardsListView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        let inactiveCards = viewModel.getInactiveCards()

        List {
            if inactiveCards.isEmpty {
                // Empty State
                Text("No Inactive Cards")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 50)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowSeparator(.hidden) // Hide separator for empty state
            } else {
                // List of inactive cards
                ForEach(inactiveCards) { card in
                    NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                        // Use the existing CardRowView
                        CardRowView(card: card, viewModel: viewModel)
                            // Add some padding if needed, List might handle it
                            // .padding(.vertical, 4)
                    }
                }
            }
        }
        .listStyle(.insetGrouped) // Or .plain if preferred
        .navigationTitle("Inactive Cards")
        .navigationBarTitleDisplayMode(.inline) // Keep title small
        .background(Color(.systemGroupedBackground).ignoresSafeArea()) // Match background
    }
}

// Optional: Preview Provider
struct InactiveCardsListView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample view model for previewing
        let previewViewModel = CardViewModel()
        // Add some sample inactive cards to the preview model if needed
        // previewViewModel.cards.append(CreditCard(..., isActive: false))

        NavigationView { // Wrap in NavigationView for preview title
            InactiveCardsListView(viewModel: previewViewModel)
        }
    }
}