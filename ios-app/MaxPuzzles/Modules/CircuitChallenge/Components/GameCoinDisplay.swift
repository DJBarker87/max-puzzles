import SwiftUI

// MARK: - GameCoinDisplay

/// Coin display for in-game showing current puzzle earnings with floating animations
struct GameCoinDisplay: View {
    let amount: Int
    let showChange: CoinAnimation?
    var size: DisplaySize = .regular

    enum DisplaySize {
        case small, regular

        var fontSize: Font {
            switch self {
            case .small: return .system(size: 14, weight: .bold, design: .monospaced)
            case .regular: return .system(size: 18, weight: .bold, design: .monospaced)
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: return 16
            case .regular: return 22
            }
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Main display
            HStack(spacing: 6) {
                // Coin icon
                Circle()
                    .fill(AppTheme.accentTertiary)
                    .frame(width: size.iconSize, height: size.iconSize)
                    .overlay {
                        Text("$")
                            .font(.system(size: size.iconSize * 0.6, weight: .bold))
                            .foregroundColor(.black)
                    }

                Text("\(amount)")
                    .font(size.fontSize)
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(AppTheme.backgroundDark.opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )

            // Floating animation
            if let change = showChange {
                CoinChangeAnimation(change: change, size: size)
                    .offset(y: -30)
            }
        }
    }
}

// MARK: - CoinChangeAnimation

/// Floating animation for coin changes (+10 or -30)
struct CoinChangeAnimation: View {
    let change: CoinAnimation
    let size: GameCoinDisplay.DisplaySize

    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0

    private var isEarn: Bool {
        change.type == .earn
    }

    var body: some View {
        Text(isEarn ? "+\(change.value)" : "\(change.value)")
            .font(.system(size: size == .small ? 12 : 16, weight: .bold))
            .foregroundColor(isEarn ? AppTheme.accentPrimary : AppTheme.error)
            .opacity(opacity)
            .offset(y: offset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0
                    offset = isEarn ? -20 : 20
                }
            }
    }
}

// MARK: - Preview

#Preview("Game Coin Display") {
    VStack(spacing: 32) {
        VStack {
            Text("Regular - No Change")
                .foregroundColor(.white)
            GameCoinDisplay(amount: 50, showChange: nil)
        }

        VStack {
            Text("Regular - Earning")
                .foregroundColor(.white)
            GameCoinDisplay(
                amount: 60,
                showChange: CoinAnimation(value: 10, type: .earn, timestamp: Date())
            )
        }

        VStack {
            Text("Regular - Penalty")
                .foregroundColor(.white)
            GameCoinDisplay(
                amount: 20,
                showChange: CoinAnimation(value: -30, type: .penalty, timestamp: Date())
            )
        }

        VStack {
            Text("Small")
                .foregroundColor(.white)
            GameCoinDisplay(amount: 30, showChange: nil, size: .small)
        }

        VStack {
            Text("Zero")
                .foregroundColor(.white)
            GameCoinDisplay(amount: 0, showChange: nil)
        }
    }
    .padding()
    .background(AppTheme.backgroundDark)
}
