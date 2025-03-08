import SwiftUI
import Foundation
import Combine

struct DashboardView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 16) {
            // Header with refresh button
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
            
            // Simplified summary grid - only showing points earned and annual fees
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                // Earned Points
                StatCard(
                    title: "Points Earned",
                    value: formattedNumber(viewModel.totalPointsEarned()),
                    icon: "star.fill",
                    iconColor: .green
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
    
    // Format large numbers with commas
    func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// Stat card for the dashboard grid - Keep this as is
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
