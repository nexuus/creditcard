import SwiftUI
import Foundation
import Combine

struct DashboardView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @State private var isRecentActivityExpanded = false
    @Namespace private var animation
    
    var body: some View {
        VStack(spacing: 16) {
            // Header - more modern style with refresh button
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Rewards")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(getLastUpdatedText())
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh indicator with loading animation
                refreshButton(viewModel: viewModel)
            }
            .padding(.horizontal)
            
            // Summary cards in a 2x2 grid instead of horizontal scroll
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Total Cards
                StatCard(
                    title: "Total Cards",
                    value: "\(viewModel.getActiveCards().count)",
                    icon: "creditcard.fill",
                    iconColor: .blue
                )
                
                // Earned Points
                StatCard(
                    title: "Points Earned",
                    value: formattedNumber(viewModel.totalPointsEarned()),
                    icon: "star.fill",
                    iconColor: .green
                )
                
                // Pending Points
                StatCard(
                    title: "Points Pending",
                    value: formattedNumber(viewModel.pendingPoints()),
                    icon: "hourglass",
                    iconColor: .orange
                )
                
                // Annual Fees
                StatCard(
                    title: "Annual Fees",
                    value: "$\(Int(viewModel.totalAnnualFees()))",
                    icon: "dollarsign.circle.fill",
                    iconColor: .red
                )
            }
            .padding(.horizontal)
            
            // Recent activity section with modern design
            if viewModel.cards.count > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    // Header with toggle button
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isRecentActivityExpanded.toggle()
                        }
                    }) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.blue)
                                
                                Text("Recent Activity")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.primary)
                            }
                            
                            Spacer()
                            
                            // Animated chevron with rotation
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.secondary)
                                .rotationEffect(.degrees(isRecentActivityExpanded ? 90 : 0))
                                .padding(6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Activity content
                    if isRecentActivityExpanded {
                        VStack(spacing: 10) {
                            let activities = getRecentActivities()
                            
                            if activities.isEmpty {
                                HStack {
                                    Spacer()
                                    Text("No recent activity")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding()
                                    Spacer()
                                }
                            } else {
                                ForEach(activities.prefix(3)) { activity in
                                    ActivityRow(activity: activity)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
    }
    
    // Refresh button with loading state
    @ViewBuilder
    func refreshButton(viewModel: CardViewModel) -> some View {
        Button(action: {
            Task {
                // Trigger refresh of all data
                await viewModel.refreshAllData()
            }
        }) {
            Image(systemName: viewModel.isLoadingCards ? "arrow.triangle.2.circlepath.circle" : "arrow.triangle.2.circlepath")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(viewModel.isLoadingCards ? .gray : .secondary)
                .padding(8)
                .background(Color.secondary.opacity(0.1))
                .clipShape(Circle())
                .rotationEffect(Angle(degrees: viewModel.isLoadingCards ? 360 : 0))
                .animation(viewModel.isLoadingCards ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: viewModel.isLoadingCards)
        }
        .disabled(viewModel.isLoadingCards)
    }
    
    // Get last updated text
    private func getLastUpdatedText() -> String {
        let lastUpdated = UserDefaults.standard.object(forKey: "lastDataUpdate") as? Date ?? Date()
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return "Updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }
    
    // MARK: - Helper Methods
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Activity types
    enum ActivityType: Identifiable {
        case added(CreditCard)
        case earned(CreditCard)
        case inactivated(CreditCard)
        
        var id: UUID {
            switch self {
            case .added(let card), .earned(let card), .inactivated(let card):
                return card.id
            }
        }
    }
    
    // Activity model
    struct Activity: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let valueText: String
        let type: ActivityType
    }
    
    // Get recent activities from cards data
    func getRecentActivities() -> [Activity] {
        var activities = [Activity]()
        
        // Sort all cards by date opened (most recent first)
        let sortedCards = viewModel.cards.sorted { $0.dateOpened > $1.dateOpened }
        
        // Get recently added cards (last 30 days)
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recentlyAdded = sortedCards.filter { $0.dateOpened > thirtyDaysAgo }
        
        for card in recentlyAdded.prefix(2) {
            activities.append(
                Activity(
                    title: "Added New Card",
                    subtitle: "\(card.name) by \(card.issuer)",
                    valueText: formattedDate(card.dateOpened),
                    type: .added(card)
                )
            )
        }
        
        // Get recently achieved bonuses (cards with achieved bonus, sorted by most recent first)
        let achievedCards = sortedCards.filter { $0.bonusAchieved }
        
        for card in achievedCards.prefix(2) {
            activities.append(
                Activity(
                    title: "Earned Bonus",
                    subtitle: "\(card.name) by \(card.issuer)",
                    valueText: "+\(formattedNumber(card.signupBonus))",
                    type: .earned(card)
                )
            )
        }
        
        // Get recently inactivated cards
        let inactiveCards = viewModel.getInactiveCards()
            .filter { $0.dateInactivated != nil }
            .sorted { ($0.dateInactivated ?? Date()) > ($1.dateInactivated ?? Date()) }
        
        for card in inactiveCards.prefix(2) {
            activities.append(
                Activity(
                    title: "Card Inactivated",
                    subtitle: "\(card.name) by \(card.issuer)",
                    valueText: formattedDate(card.dateInactivated ?? Date()),
                    type: .inactivated(card)
                )
            )
        }
        
        // Sort by most recent first (approximating dates based on activity type)
        return activities.sorted { activity1, activity2 in
            let date1: Date
            let date2: Date
            
            switch activity1.type {
            case .added(let card):
                date1 = card.dateOpened
            case .earned(let card):
                date1 = card.dateOpened
            case .inactivated(let card):
                date1 = card.dateInactivated ?? Date.distantPast
            }
            
            switch activity2.type {
            case .added(let card):
                date2 = card.dateOpened
            case .earned(let card):
                date2 = card.dateOpened
            case .inactivated(let card):
                date2 = card.dateInactivated ?? Date.distantPast
            }
            
            return date1 > date2
        }
    }
    
    // Format relative date
    func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Stat card for the dashboard grid
struct StatCard: View {
    var title: String
    var value: String
    var icon: String
    var iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Icon in circle
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
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

// Activity row for recent activities
struct ActivityRow: View {
    var activity: DashboardView.Activity
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: iconName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(activity.subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Date or value
            Text(activity.valueText)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(iconColor.opacity(0.1))
                .foregroundColor(iconColor)
                .cornerRadius(8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    // Icon based on activity type
    private var iconName: String {
        switch activity.type {
        case .added:
            return "creditcard.fill"
        case .earned:
            return "star.fill"
        case .inactivated:
            return "xmark.circle.fill"
        }
    }
    
    // Color based on activity type
    private var iconColor: Color {
        switch activity.type {
        case .added:
            return .blue
        case .earned:
            return .green
        case .inactivated:
            return .orange
        }
    }
}
