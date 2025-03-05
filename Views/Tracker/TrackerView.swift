import SwiftUI
import Foundation
import Combine

struct TrackerView: View {
    @ObservedObject var viewModel: CardViewModel
    @State private var showingAddCard = false
    @State private var showInactiveCards = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background color
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                // Main content wrapped in ScrollView
                ScrollView {
                    VStack(spacing: 0) {
                        // Dashboard summary
                        DashboardView(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Active Cards Section
                        VStack(spacing: 8) {
                            // Section header for active cards
                            HStack {
                                Text("Active Cards")
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                // Count of active cards
                                Text("\(viewModel.getActiveCards().count) cards")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 4)
                            
                            // Active cards list
                            if viewModel.getActiveCards().isEmpty {
                                // Empty state for active cards
                                VStack(spacing: 20) {
                                    Text("No Active Cards")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                    
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
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 30)
                            } else {
                                // Active cards
                                LazyVStack(spacing: 12) {
                                    ForEach(viewModel.getActiveCards()) { card in
                                        NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                            CardRowView(card: card, viewModel: viewModel)
                                        }
                                        .buttonStyle(CardButtonStyle())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        // Add Card FAB (visible only when viewing active cards)
                        HStack {
                            Spacer()
                            
                            Button(action: {
                                showingAddCard = true
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(16)
                                    .background(Circle().fill(Color.blue))
                                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                            }
                            .padding(.trailing, 24)
                            .padding(.top, 8)
                        }
                        
                        // Inactive Cards Section
                        VStack(spacing: 8) {
                            // Section header with toggle button
                            Button(action: {
                                withAnimation {
                                    showInactiveCards.toggle()
                                }
                            }) {
                                HStack {
                                    Text("Inactive Cards")
                                        .font(.system(.title3, design: .rounded))
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    // Badge with inactive card count
                                    Text("\(viewModel.getInactiveCards().count) cards")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.orange)
                                        .cornerRadius(8)
                                    
                                    // Chevron that rotates
                                    Image(systemName: "chevron.right")
                                        .rotationEffect(.degrees(showInactiveCards ? 90 : 0))
                                        .animation(.spring(), value: showInactiveCards)
                                        .foregroundColor(.secondary)
                                        .padding(.leading, 8)
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.horizontal)
                            .padding(.top, 20)
                            .padding(.bottom, 4)
                            
                            // Inactive cards list (shown only when expanded)
                            if showInactiveCards {
                                if viewModel.getInactiveCards().isEmpty {
                                    // Empty state for inactive cards
                                    VStack(spacing: 20) {
                                        Text("No Inactive Cards")
                                            .font(.headline)
                                            .foregroundColor(.secondary)
                                            .padding(.vertical, 30)
                                    }
                                    .frame(maxWidth: .infinity)
                                } else {
                                    // Inactive cards
                                    LazyVStack(spacing: 12) {
                                        ForEach(viewModel.getInactiveCards()) { card in
                                            NavigationLink(destination: CardDetailView(card: card, viewModel: viewModel)) {
                                                CardRowView(card: card, viewModel: viewModel)
                                            }
                                            .buttonStyle(CardButtonStyle())
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 20)
                                }
                            }
                            
                            // Detailed Stats (only if we have cards)
                            if !viewModel.cards.isEmpty {
                                DetailedStatsView(viewModel: viewModel)
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    .padding(.bottom, 24)
                            }
                        }
                    }
                    .padding(.top) // Add some padding at the top of the entire content
                }
                // End of ScrollView
            }
            .navigationTitle("Card Tracker")
            .sheet(isPresented: $showingAddCard) {
                AddCardView(viewModel: viewModel)
            }
        }
    }
    
    // Helper functions
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Custom button style for card interactions
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// TrackerStatCard component for stats display
struct TrackerStatCard: View {
    var title: String
    var value: String
    var iconName: String
    var iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: iconName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Value with responsive text size
            Text(value)
                .font(.system(size: value.count > 6 ? 16 : 18, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .foregroundColor(.primary)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}
