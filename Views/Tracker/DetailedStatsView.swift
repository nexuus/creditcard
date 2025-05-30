import SwiftUI

struct DetailedStatsView: View {
    @ObservedObject var viewModel: CardViewModel
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedSection: String? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("Detailed Statistics")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(viewModel.cards.count) cards")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Lifetime points - always includes ALL cards (active and inactive)
            statRow(
                title: "Lifetime Points",
                value: formattedNumber(viewModel.totalHistoricalPoints()),
                icon: "star.circle.fill",
                color: .purple,
                section: "lifetime"
            )
            
            // Annual fees - only active cards
            statRow(
                title: "Active Annual Fees",
                value: "$\(String(format: "%.2f", viewModel.totalAnnualFees()))",
                icon: "dollarsign.circle.fill",
                color: .red,
                section: "fees"
            )
            
            // Points by year - use historical points to include all cards
            statRow(
                title: "Points by Year",
                value: "\(viewModel.pointsByYear().count) years",
                icon: "calendar",
                color: .blue,
                section: "points"
            )
            
            if expandedSection == "points" {
                pointsByYearDetail
            }
            
            // Cards by year - show all cards
            statRow(
                title: "Cards Opened by Year",
                value: "\(viewModel.cardsOpenedByYear().count) years",
                icon: "creditcard.fill",
                color: .green,
                section: "cards"
            )
            
            if expandedSection == "cards" {
                cardsByYearDetail
            }
            
            // 5/24 Status Row
            statRow(
                title: "Chase 5/24 Status",
                value: "\(viewModel.calculate524Status().count)/5",
                icon: "creditcard.and.arrow.up",
                color: viewModel.isUnder524Rule() ? .green : .red,
                section: "524rule"
            )
            
            if expandedSection == "524rule" {
                chase524Detail
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
    }
    
    private var pointsByYearDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            let yearlyPoints = viewModel.pointsByYear().sorted { $0.key > $1.key }
            
            ForEach(yearlyPoints, id: \.key) { year, points in
                HStack {
                    Text(year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        let maxPoints = yearlyPoints.map { $0.value }.max() ?? 1
                        let width = CGFloat(points) / CGFloat(maxPoints) * geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: geometry.size.width)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.blue)
                                .frame(width: width)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 12)
                    
                    Text(formattedNumber(points))
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var cardsByYearDetail: some View {
        VStack(alignment: .leading, spacing: 10) {
            let yearlyCards = viewModel.cardsOpenedByYear().sorted { $0.key > $1.key }
            
            ForEach(yearlyCards, id: \.key) { year, count in
                HStack {
                    Text(year)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                    
                    // Progress bar
                    GeometryReader { geometry in
                        let maxCards = yearlyCards.map { $0.value }.max() ?? 1
                        let width = CGFloat(count) / CGFloat(maxCards) * geometry.size.width
                        
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: geometry.size.width)
                                .cornerRadius(4)
                            
                            Rectangle()
                                .fill(Color.green)
                                .frame(width: width)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 12)
                    
                    Text("\(count) cards")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .frame(width: 80, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    private var chase524Detail: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status message with color
            HStack {
                Image(systemName: viewModel.isUnder524Rule() ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                    .foregroundColor(viewModel.isUnder524Rule() ? .green : .red)
                
                Text(viewModel.isUnder524Rule()
                    ? "You're under the Chase 5/24 rule and eligible for new Chase cards."
                    : "You're at or over the Chase 5/24 limit.")
                    .font(.subheadline)
                    .foregroundColor(viewModel.isUnder524Rule() ? .green : .red)
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            // Next eligible date if over limit
            if !viewModel.isUnder524Rule(), let nextDate = viewModel.nextEligibleDate() {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundColor(.orange)
                    
                    Text("Next eligible: \(formatDate(nextDate))")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
                .padding(.horizontal)
            }
            
            // Cards in the last 24 months
            VStack(alignment: .leading, spacing: 4) {
                Text("Cards opened in the last 24 months:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                ForEach(viewModel.calculate524Status().cards) { card in
                    HStack {
                        Text(card.name)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Text(formatDate(card.dateOpened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
                    )
                    .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private func statRow(title: String, value: String, icon: String, color: Color, section: String) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                expandedSection = expandedSection == section ? nil : section
            }
        }) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.secondary)
                
                if viewModel.pointsByYear().count > 0 && (section == "points" || section == "cards") || section == "524rule" {
                    Image(systemName: expandedSection == section ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // Format large numbers with commas
    private func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
    
    // Helper for formatting dates consistently
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
