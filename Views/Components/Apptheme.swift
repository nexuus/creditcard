//
//  Apptheme.swift
//  CreditCardTracker
//
//  Created by Hassan  on 2/26/25.
//

//
//  AppTheme.swift
//  CreditCardTracker
//
//  Created by Hassan on 2/26/25.
//

import SwiftUI

// A central place for app design elements
struct AppTheme {
    // MARK: - Colors
    struct Colors {
        // Main brand colors
        static let primary = Color(hex: "0A84FF")      // Blue
        static let secondary = Color(hex: "32D74B")    // Green
        static let accent = Color(hex: "FF453A")       // Red
        
        // Neutral colors
        static let background = Color(.systemBackground)
        static let secondaryBackground = Color(.secondarySystemBackground)
        static let groupedBackground = Color(.systemGroupedBackground)
        
        // Text colors
        static let text = Color(.label)
        static let secondaryText = Color(.secondaryLabel)
        static let tertiaryText = Color(.tertiaryLabel)
        
        // Card colors
        static let cardShadow = Color.black.opacity(0.1)
        
        // Card issuer colors for more vibrant, modern feel
        static func issuerColor(for issuer: String) -> Color {
            switch issuer.lowercased() {
            case "chase":
                return Color(hex: "0F4C81")  // Chase deep blue
            case "american express", "amex":
                return Color(hex: "006FCF")  // Amex blue
            case "citi":
                return Color(hex: "0E3388")  // Citi blue
            case "capital one":
                return Color(hex: "D03027")  // Capital One red
            case "discover":
                return Color(hex: "FF6000")  // Discover orange
            case "wells fargo":
                return Color(hex: "D71E2B")  // Wells Fargo red
            case "bank of america":
                return Color(hex: "012169")  // Bank of America blue
            case "us bank":
                return Color(hex: "003087")  // US Bank blue
            case "barclays":
                return Color(hex: "00AEEF")  // Barclays light blue
            default:
                return Color(hex: "6E6E73")  // Default dark gray
            }
        }
        
        // Category colors
        static func categoryColor(for category: String) -> Color {
            switch category.lowercased() {
            case "travel":
                return Color(hex: "007AFF")  // Blue
            case "cashback":
                return Color(hex: "34C759")  // Green
            case "business":
                return Color(hex: "5856D6")  // Purple
            case "hotel":
                return Color(hex: "FF9500")  // Orange
            case "airline":
                return Color(hex: "FF2D55")  // Red
            case "groceries":
                return Color(hex: "30B94D")  // Light Green
            case "dining":
                return Color(hex: "FF9F0A")  // Orange-Red
            case "gas":
                return Color(hex: "AF52DE")  // Light Purple
            default:
                return Color(hex: "8E8E93")  // Gray
            }
        }
    }
    
    // MARK: - Typography
    struct Typography {
        // Title styles
        static let largeTitle = Font.largeTitle.weight(.bold)
        static let title = Font.title.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        
        // Body text
        static let body = Font.body
        static let callout = Font.callout
        static let footnote = Font.footnote
        
        // Special text
        static let cardTitle = Font.system(size: 20, weight: .bold, design: .rounded)
        static let cardIssuer = Font.system(size: 14, weight: .medium, design: .rounded)
        static let cardPoints = Font.system(size: 18, weight: .bold, design: .rounded)
    }
    
    // MARK: - Layout
    struct Layout {
        // Standard spacing
        static let spacing: CGFloat = 16
        static let tightSpacing: CGFloat = 8
        static let looseSpacing: CGFloat = 24
        
        // Card dimensions
        static let cardCornerRadius: CGFloat = 16
        static let largeCardCornerRadius: CGFloat = 24
        
        // Shadow properties
        static let shadowRadius: CGFloat = 10
        static let shadowY: CGFloat = 4
        static let shadowOpacity: CGFloat = 0.1
    }
    
    // MARK: - Animations
    struct Animations {
        static let standard = Animation.spring(response: 0.3, dampingFraction: 0.7)
        static let quick = Animation.easeOut(duration: 0.2)
        static let hover = Animation.easeInOut(duration: 0.2)
    }
}

// MARK: - Extensions

// Extend Color to support hex values
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Style for modern buttons
struct ModernButtonStyle: ButtonStyle {
    var foregroundColor: Color = .white
    var backgroundColor: Color = AppTheme.Colors.primary
    var pressedOpacity: Double = 0.8
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(foregroundColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: backgroundColor.opacity(0.3),
                        radius: 5, x: 0, y: 2
                    )
            )
            .opacity(configuration.isPressed ? pressedOpacity : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(AppTheme.Animations.quick, value: configuration.isPressed)
    }
}

// Modern card style
struct ModernCardStyle: ViewModifier {
    var backgroundColor: Color = Color(.systemBackground)
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.Layout.cardCornerRadius)
                    .fill(backgroundColor)
                    .shadow(
                        color: AppTheme.Colors.cardShadow,
                        radius: AppTheme.Layout.shadowRadius,
                        x: 0, y: AppTheme.Layout.shadowY
                    )
            )
    }
}

// Extension to apply the modern card style
extension View {
    func modernCard(backgroundColor: Color = Color(.systemBackground)) -> some View {
        self.modifier(ModernCardStyle(backgroundColor: backgroundColor))
    }
}

// Modern text field style
struct ModernTextFieldStyle: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
            )
    }
}

// Extension to apply the modern text field style
extension View {
    func modernTextField() -> some View {
        self.modifier(ModernTextFieldStyle())
    }
}
