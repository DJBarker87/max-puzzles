import SwiftUI

// MARK: - Color Extension

extension Color {
    /// Initialize a Color from a hex string (supports RGB, ARGB formats)
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
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Theme

/// Central theme configuration matching the web app exactly
struct AppTheme {
    // MARK: Hub Colors
    static let backgroundDark = Color(hex: "0f0f23")
    static let backgroundMid = Color(hex: "1a1a3e")
    static let accentPrimary = Color(hex: "22c55e")      // Success green
    static let accentSecondary = Color(hex: "e94560")    // Accent pink/red
    static let accentTertiary = Color(hex: "fbbf24")     // Coins gold
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "a1a1aa")
    static let error = Color(hex: "ef4444")

    // MARK: Circuit Challenge Grid
    static let gridBackgroundTop = Color(hex: "0a0a12")
    static let gridBackgroundBottom = Color(hex: "0d0d18")
    static let connectorDefault = Color(hex: "3d3428")
    static let connectorActive = Color(hex: "00dd77")
    static let connectorGlow = Color(hex: "00ff88")
    static let heartsActive = Color(hex: "ff3366")
    static let heartsInactive = Color(hex: "2a2a3a")

    // MARK: Cell States - Normal
    static let cellNormalTop1 = Color(hex: "3a3a4a")
    static let cellNormalTop2 = Color(hex: "252530")
    static let cellNormalEdge1 = Color(hex: "1a1a25")
    static let cellNormalEdge2 = Color(hex: "0f0f15")
    static let cellNormalBorder = Color(hex: "4a4a5a")

    // MARK: Cell States - Start
    static let cellStartTop1 = Color(hex: "15803d")
    static let cellStartTop2 = Color(hex: "0d5025")
    static let cellStartBorder = Color(hex: "00ff88")

    // MARK: Cell States - Finish
    static let cellFinishTop1 = Color(hex: "ca8a04")
    static let cellFinishTop2 = Color(hex: "854d0e")
    static let cellFinishBorder = Color(hex: "ffcc00")
    static let cellFinishText = Color(hex: "ffdd44")

    // MARK: Cell States - Current
    static let cellCurrentTop1 = Color(hex: "0d9488")
    static let cellCurrentTop2 = Color(hex: "086560")
    static let cellCurrentBorder = Color(hex: "00ffcc")

    // MARK: Cell States - Visited
    static let cellVisitedTop1 = Color(hex: "1a5c38")
    static let cellVisitedTop2 = Color(hex: "103822")
    static let cellVisitedBorder = Color(hex: "00ff88")

    // MARK: Cell States - Wrong
    static let cellWrongTop = Color(hex: "ef4444")
    static let cellWrongBorder = Color(hex: "dc2626")

    // MARK: Connector Badge
    static let connectorBadgeBackground = Color(hex: "15151f")
    static let connectorBadgeText = Color(hex: "ff9f43")

    // MARK: Gradients

    static var gridBackground: LinearGradient {
        LinearGradient(
            colors: [gridBackgroundTop, Color(hex: "12121f"), gridBackgroundBottom],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var splashBackground: LinearGradient {
        LinearGradient(
            colors: [backgroundDark, backgroundMid],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: Cell Gradients

    static func cellTopGradient(for state: CellState) -> LinearGradient {
        switch state {
        case .normal:
            return LinearGradient(
                colors: [cellNormalTop1, cellNormalTop2],
                startPoint: .top,
                endPoint: .bottom
            )
        case .start:
            return LinearGradient(
                colors: [cellStartTop1, cellStartTop2],
                startPoint: .top,
                endPoint: .bottom
            )
        case .finish:
            return LinearGradient(
                colors: [cellFinishTop1, cellFinishTop2],
                startPoint: .top,
                endPoint: .bottom
            )
        case .current:
            return LinearGradient(
                colors: [cellCurrentTop1, cellCurrentTop2],
                startPoint: .top,
                endPoint: .bottom
            )
        case .visited:
            return LinearGradient(
                colors: [cellVisitedTop1, cellVisitedTop2],
                startPoint: .top,
                endPoint: .bottom
            )
        case .wrong:
            return LinearGradient(
                colors: [cellWrongTop, cellWrongTop.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    static func cellBorderColor(for state: CellState) -> Color {
        switch state {
        case .normal: return cellNormalBorder
        case .start: return cellStartBorder
        case .finish: return cellFinishBorder
        case .current: return cellCurrentBorder
        case .visited: return cellVisitedBorder
        case .wrong: return cellWrongBorder
        }
    }
}

// MARK: - Cell State Enum

enum CellState {
    case normal
    case start
    case finish
    case current
    case visited
    case wrong
}

// MARK: - Typography

struct AppTypography {
    // Premium rounded titles for playful kid-friendly feel
    static let titleLarge = Font.system(size: 32, weight: .bold, design: .rounded)
    static let titleMedium = Font.system(size: 24, weight: .bold, design: .rounded)
    static let titleSmall = Font.system(size: 20, weight: .semibold, design: .rounded)

    // Heavy display font for big impact text
    static let displayLarge = Font.system(size: 48, weight: .heavy, design: .rounded)
    static let displayMedium = Font.system(size: 36, weight: .heavy, design: .rounded)

    // Body text with rounded design for consistency
    static let bodyLarge = Font.system(size: 18, weight: .regular, design: .rounded)
    static let bodyMedium = Font.system(size: 16, weight: .regular, design: .rounded)
    static let bodySmall = Font.system(size: 14, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 12, weight: .regular, design: .rounded)

    // Game-specific fonts
    static let cellExpression = Font.system(size: 14, weight: .bold, design: .rounded)
    static let connectorBadge = Font.system(size: 14, weight: .bold, design: .monospaced)

    // Button text
    static let buttonLarge = Font.system(size: 18, weight: .semibold, design: .rounded)
    static let buttonMedium = Font.system(size: 16, weight: .semibold, design: .rounded)
    static let buttonSmall = Font.system(size: 14, weight: .semibold, design: .rounded)
}

// MARK: - Spacing

struct AppSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}

// MARK: - Animation Durations

struct AppAnimation {
    // Basic durations
    static let fast: Double = 0.15
    static let normal: Double = 0.3
    static let slow: Double = 0.5

    // Game animations
    static let energyFlowFast: Double = 0.8
    static let energyFlowSlow: Double = 1.2
    static let cellPulse: Double = 1.5
    static let visitedPulse: Double = 2.0
    static let heartPulse: Double = 1.2

    // Premium micro-interactions
    static let buttonPress: Double = 0.08
    static let buttonRelease: Double = 0.25
    static let cardLift: Double = 0.2
    static let starPop: Double = 0.3
    static let coinBounce: Double = 0.4
    static let confettiBurst: Double = 0.6
    static let characterReveal: Double = 0.6
    static let screenTransition: Double = 0.35
    static let shootingStar: Double = 1.2

    // Spring configurations
    static let buttonSpring = Animation.spring(response: 0.3, dampingFraction: 0.6)
    static let cardSpring = Animation.spring(response: 0.4, dampingFraction: 0.7)
    static let bounceSpring = Animation.spring(response: 0.5, dampingFraction: 0.5)
    static let gentleSpring = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - Glass Effect

struct GlassEffect: ViewModifier {
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.7

    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial.opacity(opacity))
            .background(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func glassEffect(cornerRadius: CGFloat = 20, opacity: Double = 0.7) -> some View {
        modifier(GlassEffect(cornerRadius: cornerRadius, opacity: opacity))
    }
}
