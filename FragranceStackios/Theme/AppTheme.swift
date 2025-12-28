//
//  AppTheme.swift
//  FragranceStackios
//
//  Created by Claude on 12/28/25.
//

import SwiftUI

// MARK: - Color Extensions

extension Color {
    // Primary color palette
    static let appNavy = Color(hex: "#1a1a2e")
    static let appGold = Color(hex: "#d4af37")
    static let appCream = Color(hex: "#faf8f5")

    // Semantic colors
    static let appBackground = appCream
    static let appPrimary = appNavy
    static let appAccent = appGold

    // Helper initializer for hex colors
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
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.appGold)
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.appNavy)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.appCream)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appGold, lineWidth: 2)
            )
            .cornerRadius(24)
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Styles

struct FragranceCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func fragranceCardStyle() -> some View {
        modifier(FragranceCardStyle())
    }
}

// MARK: - Badge Styles

struct BadgeStyle: ViewModifier {
    let color: Color

    func body(content: Content) -> some View {
        content
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color)
            .cornerRadius(8)
    }
}

extension View {
    func badgeStyle(color: Color = .appGold) -> some View {
        modifier(BadgeStyle(color: color))
    }
}

// MARK: - Typography Extensions

extension Font {
    static func appTitle() -> Font {
        .system(size: 28, weight: .bold, design: .default)
    }

    static func appHeadline() -> Font {
        .system(size: 20, weight: .semibold, design: .default)
    }

    static func appSubheadline() -> Font {
        .system(size: 16, weight: .medium, design: .default)
    }

    static func appBody() -> Font {
        .system(size: 16, weight: .regular, design: .default)
    }

    static func appCaption() -> Font {
        .system(size: 12, weight: .regular, design: .default)
    }

    static func appStat() -> Font {
        .system(size: 32, weight: .semibold, design: .rounded)
    }
}

// MARK: - Input Styles

struct AppTextFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(12)
            .background(Color.appCream)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

extension View {
    func appTextFieldStyle() -> some View {
        modifier(AppTextFieldStyle())
    }
}

// MARK: - Star Rating View

struct StarRatingView: View {
    let rating: Int // 1-5
    let maxRating: Int = 5
    let filledColor: Color = .appGold
    let emptyColor: Color = .gray.opacity(0.3)

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? filledColor : emptyColor)
                    .font(.system(size: 14))
            }
        }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading...")
                .font(.appSubheadline())
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.5))

            Text(title)
                .font(.appHeadline())
                .foregroundColor(.appNavy)

            Text(message)
                .font(.appBody())
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding(.vertical, 40)
    }
}
