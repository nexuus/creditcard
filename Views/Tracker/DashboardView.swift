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

//
//  DashboardView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.


struct DashboardView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            // Header
            HStack {
                Text("Your Rewards")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                
                Spacer()
                
                Text("Updated today")
                    .font(AppTheme.Typography.footnote)
                    .foregroundColor(AppTheme.Colors.tertiaryText)
            }
            
            // Summary cards in a horizontal scroll
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Total Cards
                    SummaryCardView(
                        title: "Total Cards",
                        value: "\(viewModel.cards.count)",
                        icon: "creditcard.fill",
                        iconColor: AppTheme.Colors.primary
                    )
                    
                    // Earned Points
                    SummaryCardView(
                        title: "Points Earned",
                        value: formattedNumber(viewModel.totalPointsEarned()),
                        icon: "star.fill",
                        iconColor: AppTheme.Colors.secondary
                    )
                    
                    // Pending Points
                    SummaryCardView(
                        title: "Points Pending",
                        value: formattedNumber(viewModel.pendingPoints()),
                        icon: "hourglass",
                        iconColor: AppTheme.Colors.accent
                    )
                    
                    // Annual Fees
                    SummaryCardView(
                        title: "Annual Fees",
                        value: "$\(Int(viewModel.totalAnnualFees()))",
                        icon: "dollarsign.circle.fill",
                        iconColor: Color(.systemOrange)
                    )
                }
                .padding(.horizontal, 2)
                .padding(.bottom, 4)
            }
            
            // Recent activity (for a more complete dashboard)
            if viewModel.cards.count > 0 {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    // Most recent card or latest bonus earned
                    ForEach(getRecentActivities().prefix(2)) { activity in
                        HStack(spacing: 14) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(activity.type == .added
                                          ? AppTheme.Colors.primary.opacity(0.15)
                                          : AppTheme.Colors.secondary.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: activity.type == .added ? "plus.circle.fill" : "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(activity.type == .added
                                                     ? AppTheme.Colors.primary
                                                     : AppTheme.Colors.secondary)
                            }
                            
                            // Activity details
                            VStack(alignment: .leading, spacing: 3) {
                                Text(activity.title)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(activity.subtitle)
                                    .font(.caption)
                                    .foregroundColor(AppTheme.Colors.secondaryText)
                            }
                            
                            Spacer()
                            
                            // Date or points
                            Text(activity.valueText)
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(activity.type == .added
                                               ? AppTheme.Colors.primary
                                               : AppTheme.Colors.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
                        )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color.white)
                .shadow(
                    color: AppTheme.Colors.cardShadow,
                    radius: AppTheme.Layout.shadowRadius,
                    x: 0, y: AppTheme.Layout.shadowY
                )
        )
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

// Modern summary card component
struct SummaryCardView: View {
    var title: String
    var value: String
    var icon: String
    var iconColor: Color
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Icon with gradient background
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Value in large text
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)
                
                // Title in smaller text
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(AppTheme.Colors.secondaryText)
            }
        }
        .frame(width: 140)
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }
}
