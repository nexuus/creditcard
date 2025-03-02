//
//  CardDetailCatalogView.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

import SwiftUI
import Foundation
import Combine

struct CardDetailCatalogView: View {
    let card: CreditCardInfo
    @State private var detailedCard: CreditCardInfo?
    @State private var isLoadingDetails = false
    @State private var cardImage: UIImage? = nil
    @State private var isLoadingImage = true
    @State private var selectedTab = 0
    @State private var isRotated = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ScrollView {
            VStack(spacing: AppTheme.Layout.spacing) {
                // Card visualization section
                VStack(spacing: 8) {
                    // 3D credit card visualization
                    ZStack {
                        if isLoadingImage || cardImage == nil {
                            // 3D credit card visualization
                            CatalogCreditCardView(
                                card: displayCard,
                                isBackVisible: isRotated
                            )
                            .frame(height: 220)
                            .rotation3DEffect(
                                Angle(degrees: isRotated ? 180 : 0),
                                axis: (x: 0, y: 1, z: 0)
                            )
                        } else {
                            // Real card image if available
                            Image(uiImage: cardImage!)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 220)
                                .cornerRadius(16)
                                .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
                        }
                    }
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isRotated.toggle()
                        }
                    }
                    
                    // Issuer and card name
                    VStack(spacing: 4) {
                        Text(displayCard.name)
                            .font(AppTheme.Typography.title)
                            .foregroundColor(AppTheme.Colors.text)
                            .multilineTextAlignment(.center)
                        
                        Text(displayCard.issuer)
                            .font(AppTheme.Typography.headline)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                        
                        // Category badge
                        Text(displayCard.category)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(AppTheme.Colors.categoryColor(for: displayCard.category).opacity(0.15))
                            .foregroundColor(AppTheme.Colors.categoryColor(for: displayCard.category))
                            .cornerRadius(20)
                            .padding(.top, 8)
                    }
                    .padding(.top, 16)
                }
                .padding(.bottom, 8)
                
                // Loading indicator for details
                if isLoadingDetails {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading card details...")
                            .font(.caption)
                            .foregroundColor(AppTheme.Colors.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    // Tab picker for different sections
                    TabPickerView(selection: $selectedTab, tabs: ["Overview", "Benefits", "Categories"])
                        .padding(.horizontal)
                    
                    // Content based on selected tab
                    switch selectedTab {
                    case 0:
                        // Overview tab
                        overviewSection
                    case 1:
                        // Benefits tab
                        benefitsSection
                    case 2:
                        // Categories tab
                        categoriesSection
                    default:
                        EmptyView()
                    }
                }
                
                // Apply button
                if let url = URL(string: displayCard.applyURL), !displayCard.applyURL.isEmpty {
                    Link(destination: url) {
                        Text("Apply Now")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.Colors.primary)
                            .cornerRadius(AppTheme.Layout.cardCornerRadius)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCardDetails()
            loadCardImage()
        }
    }
    
    // Use detailed card if available, otherwise use the basic card
    private var displayCard: CreditCardInfo {
        detailedCard ?? card
    }
    
    // MARK: - Content Sections
    
    // Overview section
    private var overviewSection: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            // Key stats in a grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCardView(
                    title: "Annual Fee",
                    value: "$\(Int(displayCard.annualFee))",
                    icon: "dollarsign.circle.fill",
                    iconColor: .red
                )
                
                StatCardView(
                    title: "Signup Bonus",
                    value: formattedNumber(displayCard.signupBonus),
                    icon: "star.fill",
                    iconColor: .yellow
                )
                
                if let spendReq = displayCard.signupBonusSpend {
                    StatCardView(
                        title: "Min. Spend",
                        value: "$\(formattedNumber(spendReq))",
                        icon: "creditcard.fill",
                        iconColor: .blue
                    )
                }
                
                if let months = displayCard.signupBonusLength {
                    StatCardView(
                        title: "Time Frame",
                        value: "\(months) months",
                        icon: "calendar",
                        iconColor: .purple
                    )
                }
            }
            .padding(.horizontal)
            
            // Signup bonus description
            if !displayCard.description.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Signup Bonus")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    Text(displayCard.description)
                        .font(.body)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal)
            }
            
            // Annual spend opportunities
            if let annualSpendBonuses = displayCard.annualSpendBonuses, !annualSpendBonuses.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Annual Spending Bonuses")
                        .font(AppTheme.Typography.headline)
                        .foregroundColor(AppTheme.Colors.text)
                    
                    ForEach(annualSpendBonuses, id: \.self) { bonusDesc in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(AppTheme.Colors.secondary)
                                .font(.system(size: 18))
                                .frame(width: 24, height: 24)
                            
                            Text(bonusDesc)
                                .font(.subheadline)
                                .foregroundColor(AppTheme.Colors.secondaryText)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                        .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                        .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                )
                .padding(.horizontal)
            }
            
            // Card details like APR, credit score, etc.
            VStack(alignment: .leading, spacing: 12) {
                Text("Card Details")
                    .font(AppTheme.Typography.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                CatalogDetailRow(title: "Card Network", value: displayCard.cardNetwork ?? "Unknown")
                CatalogDetailRow(title: "Card Type", value: displayCard.cardType ?? "Unknown")
                CatalogDetailRow(title: "Credit Range", value: displayCard.creditRange ?? "Unknown")
                CatalogDetailRow(title: "Regular APR", value: displayCard.regularAPR)
                
                if let fxFee = displayCard.fxFee, fxFee > 0 {
                    CatalogDetailRow(title: "Foreign Transaction Fee", value: "\(Int(fxFee * 100))%")
                } else {
                    CatalogDetailRow(title: "Foreign Transaction Fee", value: "None")
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
            )
            .padding(.horizontal)
        }
    }
    
    // Benefits section
    private var benefitsSection: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            if let benefits = displayCard.benefits, !benefits.isEmpty {
                LazyVStack(spacing: 16) {
                    ForEach(benefits) { benefit in
                        BenefitCardView(benefit: benefit)
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    
                    Text("No detailed benefits information available")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Text("Check the issuer's website for more details")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // Categories section
    private var categoriesSection: some View {
        VStack(spacing: AppTheme.Layout.spacing) {
            if let bonusCategories = displayCard.bonusCategories, !bonusCategories.isEmpty {
                // Group categories by group
                let groupedCategories = Dictionary(grouping: bonusCategories) { $0.spendBonusCategoryGroup }
                
                LazyVStack(spacing: 20) {
                    ForEach(groupedCategories.keys.sorted(), id: \.self) { group in
                        if let categories = groupedCategories[group] {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(group)
                                    .font(AppTheme.Typography.headline)
                                    .foregroundColor(AppTheme.Colors.categoryColor(for: group))
                                
                                ForEach(Array(categories.sorted(by: { $0.earnMultiplier > $1.earnMultiplier })), id: \.id) { category in
                                    BonusCategoryRow(category: category)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
                            )
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                    
                    Text("No bonus categories information available")
                        .font(.headline)
                        .foregroundColor(AppTheme.Colors.secondaryText)
                    
                    Text("Check the issuer's website for more details")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.Colors.tertiaryText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCardDetails() {
        // Only load if we don't already have detailed info
        if detailedCard == nil && !isLoadingDetails {
            isLoadingDetails = true
            
            Task {
                if let details = await CreditCardService.shared.fetchAndUpdateCardDetail(cardKey: card.id) {
                    await MainActor.run {
                        detailedCard = details
                        isLoadingDetails = false
                    }
                } else {
                    await MainActor.run {
                        isLoadingDetails = false
                    }
                }
            }
        }
    }
    
    private func loadCardImage() {
        isLoadingImage = true
        
        Task {
            if let image = await CreditCardService.shared.fetchCardImage(for: card.id) {
                await MainActor.run {
                    withAnimation {
                        self.cardImage = image
                        self.isLoadingImage = false
                    }
                }
            } else {
                await MainActor.run {
                    isLoadingImage = false
                }
            }
        }
    }
    
    // Format points with comma separators
    private func formattedNumber(_ number: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: number)) ?? "\(number)"
    }
}

// MARK: - Helper Views

// Tab picker view for switching between sections
struct TabPickerView: View {
    @Binding var selection: Int
    let tabs: [String]
    
    var body: some View {
        VStack(spacing: 0) {
            // Tab buttons
            HStack(spacing: 0) {
                ForEach(0..<tabs.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.spring()) {
                            selection = index
                        }
                    }) {
                        Text(tabs[index])
                            .font(.system(size: 16, weight: selection == index ? .semibold : .regular))
                            .foregroundColor(selection == index ? AppTheme.Colors.primary : AppTheme.Colors.secondaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                }
            }
            
            // Selection indicator
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 3)
                
                Rectangle()
                    .fill(AppTheme.Colors.primary)
                    .frame(width: UIScreen.main.bounds.width / CGFloat(tabs.count), height: 3)
                    .offset(x: CGFloat(selection) * UIScreen.main.bounds.width / CGFloat(tabs.count))
            }
        }
        .background(Color(.systemBackground))
    }
}

// Card stats view
struct StatCardView: View {
    let title: String
    let value: String
    let icon: String
    let iconColor: Color
    
    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(iconColor.opacity(0.15))
                )
            
            // Value
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            // Title
            Text(title)
                .font(.caption)
                .foregroundColor(AppTheme.Colors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 3)
        )
    }
}

// Benefit card view
struct BenefitCardView: View {
    let benefit: CardBenefit
    @State private var isExpanded = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Benefit title and toggle button
            HStack {
                Text(benefit.benefitTitle)
                    .font(.headline)
                    .foregroundColor(AppTheme.Colors.text)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring()) {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.Colors.primary)
                }
            }
            
            // Benefit description (expanded)
            if isExpanded {
                Text(benefit.benefitDesc)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 3)
        )
    }
}

// Bonus category row
struct BonusCategoryRow: View {
    let category: SpendBonusCategory
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            // Multiplier badge
            Text(category.multiplierDisplay)
                .font(.system(size: 14, weight: .bold))
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(category.categoryColor.opacity(0.15))
                )
                .foregroundColor(category.categoryColor)
            
            // Category name and description
            VStack(alignment: .leading, spacing: 4) {
                Text(category.spendBonusCategoryName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.Colors.text)
                
                Text(category.spendBonusDesc)
                    .font(.caption)
                    .foregroundColor(AppTheme.Colors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6).opacity(0.5))
        )
    }
}

// Card visualization for catalog
struct CatalogCreditCardView: View {
    var card: CreditCardInfo
    var isBackVisible: Bool
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            if isBackVisible {
                // Back of the card
                cardBack
            } else {
                // Front of the card
                cardFront
            }
        }
    }
    
    // Front of the card
    var cardFront: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            card.primaryColor.opacity(0.9),
                            card.primaryColor
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Add subtle pattern overlay
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: card.primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Card content
            VStack(alignment: .leading) {
                // Top section with chip and issuer
                HStack {
                    // Chip
                    Rectangle()
                        .fill(Color.yellow.opacity(0.8))
                        .frame(width: 45, height: 35)
                        .clipShape(RoundedRectangle(cornerRadius: 5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    // Issuer logo/text
                    Text(card.issuer.uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Card number placeholders
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { i in
                        Text(i == 3 ? "•••• 1234" : "••••")
                            .font(.system(size: 16, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                Spacer()
                
                // Bottom row with name
                VStack(alignment: .leading, spacing: 2) {
                    Text(card.name)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .padding()
        }
    }
    
    // Back of the card
    var cardBack: some View {
        ZStack(alignment: .leading) {
            // Background
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            card.primaryColor,
                            card.primaryColor.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    // Add subtle pattern overlay
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .shadow(color: card.primaryColor.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Card content
            VStack {
                // Magnetic stripe
                Rectangle()
                    .fill(Color.black)
                    .frame(height: 50)
                    .padding(.top, 20)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    // CVV section
                    HStack {
                        // White signature strip
                        Rectangle()
                            .fill(Color.white.opacity(0.9))
                            .frame(height: 40)
                            .overlay(
                                Text("CVV: •••")
                                    .font(.system(size: 14))
                                    .foregroundColor(.black)
                                    .padding(.trailing)
                                , alignment: .trailing
                            )
                    }
                    
                    // Points information
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(card.category.uppercased()) CARD")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        
                        HStack {
                            Text("Signup Bonus:")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                            
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .decimal
                            let bonusText = formatter.string(from: NSNumber(value: card.signupBonus)) ?? "\(card.signupBonus)"
                            
                            Text(bonusText + " Points")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        // Flip the back of the card
        .rotation3DEffect(
            Angle(degrees: 180),
            axis: (x: 0, y: 1, z: 0)
        )
    }
}

// Catalog detail row - renamed to avoid conflict with ModernDetailRow in CardDetailView
struct CatalogDetailRow: View {
    var title: String
    var value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.Colors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.Colors.text)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ? Color(.systemGray5).opacity(0.5) : Color(.systemGray6).opacity(0.5))
        )
    }
}

// Preview provider for development
struct CardDetailCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleCard = CreditCardInfo(
            id: "amex-hiltonsurpass",
            name: "Hilton Honors Surpass",
            issuer: "American Express",
            category: "Hotel",
            description: "Earn 130,000 Hilton Honors Bonus Points after you spend $3,000 in purchases on the Card within your first 6 months of Card Membership.",
            annualFee: 150.00,
            signupBonus: 130000,
            regularAPR: "Variable",
            imageName: "",
            applyURL: "https://www.americanexpress.com/us/credit-cards/card/hilton-honors-surpass"
        )
        
        NavigationView {
            CardDetailCatalogView(card: sampleCard)
        }
    }
}
