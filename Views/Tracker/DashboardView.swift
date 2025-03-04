//
//  DashboardView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

// System frameworks first
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
        VStack(spacing: 20) {
            // Header - more modern style
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Rewards")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Updated today")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Refresh indicator
                Button(action: {}) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal)
            
            // Summary cards in a horizontal scroll - enhanced design
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    // Total Cards
                    ModernSummaryCard(
                        title: "Total Cards",
                        value: "\(viewModel.cards.count)",
                        icon: "creditcard.fill",
                        iconColor: Color.blue
                    )
                    
                    // Earned Points
                    ModernSummaryCard(
                        title: "Points Earned",
                        value: formattedNumber(viewModel.totalPointsEarned()),
                        icon: "star.fill",
                        iconColor: Color.green
                    )
                    
                    // Pending Points
                    ModernSummaryCard(
                        title: "Points Pending",
                        value: formattedNumber(viewModel.pendingPoints()),
                        icon: "hourglass",
                        iconColor: Color.orange
                    )
                    
                    // Annual Fees
                    ModernSummaryCard(
                        title: "Annual Fees",
                        value: "$\(Int(viewModel.totalAnnualFees()))",
                        icon: "dollarsign.circle.fill",
                        iconColor: Color.red
                    )
                }
                .padding(.horizontal)
            }
            
            // Recent activity section - completely redesigned for modern iOS look
            if viewModel.cards.count > 0 {
                VStack(alignment: .leading, spacing: 16) {
                    // Header with toggle button - more iOS 17 style
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isRecentActivityExpanded.toggle()
                        }
                    }) {
                        HStack {
                            HStack(spacing: 8) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.secondary)
                                
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
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isRecentActivityExpanded)
                                .padding(6)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // Content with animated expansion
                    if isRecentActivityExpanded {
                        VStack(spacing: 12) {
                            // Most recent card or latest bonus earned
                            ForEach(getRecentActivities().prefix(2)) { activity in
                                HStack(spacing: 16) {
                                    // Modern icon with SF Symbols
                                    ZStack {
                                        Circle()
                                            .fill(
                                                LinearGradient(
                                                    gradient: Gradient(colors: [
                                                        activity.type == .added ? Color.blue : Color.green,
                                                        activity.type == .added ? Color.blue.opacity(0.7) : Color.green.opacity(0.7)
                                                    ]),
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                            )
                                            .frame(width: 44, height: 44)
                                        
                                        Image(systemName: activity.type == .added ? "creditcard.fill" : "star.fill")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                    .shadow(color: (activity.type == .added ? Color.blue : Color.green).opacity(0.3), radius: 4, x: 0, y: 2)
                                    
                                    // Activity details with improved typography
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(activity.title)
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        
                                        Text(activity.subtitle)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    // Date or points with badge style
                                    Text(activity.valueText)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(activity.type == .added ? Color.blue : Color.green)
                                        )
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
                                )
                                .padding(.horizontal, 16)
                                .transition(.move(edge: .top).combined(with: .opacity))
                                .id("activity-\(activity.id)")
                            }
                        }
                        .padding(.bottom, 16)
                        .transition(.opacity)
                        .matchedGeometryEffect(id: "activities", in: animation)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Material.thin)
                )
            }
        }
        .padding(.vertical, 16)
    }
    
    // MARK: - Helper Methods
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Format date
    func formattedDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    // Activity types for the dashboard
    enum ActivityType {
        case added
        case earned
    }
    
    // Activity model for the dashboard
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
        
        // Sort cards by date opened (most recent first)
        let sortedCards = viewModel.cards.sorted { $0.dateOpened > $1.dateOpened }
        
        // Add most recently added card
        if let recentCard = sortedCards.first {
            activities.append(
                Activity(
                    title: "Added New Card",
                    subtitle: "\(recentCard.name) by \(recentCard.issuer)",
                    valueText: formattedDate(recentCard.dateOpened),
                    type: .added
                )
            )
        }
        
        // Add most recently achieved bonus
        let achievedCards = sortedCards.filter { $0.bonusAchieved }
        if let recentAchieved = achievedCards.first {
            activities.append(
                Activity(
                    title: "Earned Bonus",
                    subtitle: "\(recentAchieved.name) by \(recentAchieved.issuer)",
                    valueText: "+\(formattedNumber(recentAchieved.signupBonus))",
                    type: .earned
                )
            )
        }
        
        return activities
    }
}

// Modern iOS 17-style summary card component
struct ModernSummaryCard: View {
    var title: String
    var value: String
    var icon: String
    var iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    @State private var isPressed = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Top row with icon and value
            HStack(alignment: .center, spacing: 12) {
                // Beautiful SF Symbol with gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [iconColor, iconColor.opacity(0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                .shadow(color: iconColor.opacity(0.3), radius: 4, x: 0, y: 2)
                
                // Value with large text
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            
            // Title with better contrast
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.regular)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.secondary.opacity(0.1), lineWidth: 1)
        )
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        // Add haptic touch effect
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: 50, pressing: { pressing in
            isPressed = pressing
            if pressing {
                let impactGenerator = UIImpactFeedbackGenerator(style: .medium)
                impactGenerator.impactOccurred()
            }
        }, perform: {})
    }
}
