import SwiftUI
import UIKit

// MARK: - GameCoinDisplay

/// In-game puzzle-points display with floating feedback.
struct GameCoinDisplay: View {
    let amount: Int
    let showChange: CoinAnimation?
    var size: DisplaySize = .regular

    enum DisplaySize {
        case small, regular

        var fontSize: Font {
            switch self {
            case .small: return .system(.subheadline, design: .monospaced, weight: .bold)
            case .regular: return .system(.headline, design: .monospaced, weight: .bold)
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
                // Energy-point icon. Points are scoped to the current puzzle;
                // they do not imply a currency or an unfinished shop.
                Circle()
                    .fill(AppTheme.accentTertiary)
                    .frame(width: size.iconSize, height: size.iconSize)
                    .overlay {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: size.iconSize * 0.5, weight: .bold))
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
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Puzzle points: \(amount)")

            // Floating animation
            if let change = showChange {
                CoinChangeAnimation(change: change, size: size)
                    .offset(y: -30)
            }
        }
    }
}

// MARK: - CoinChangeAnimation

/// Floating animation for points earned by a correct move.
struct CoinChangeAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let change: CoinAnimation
    let size: GameCoinDisplay.DisplaySize

    @State private var opacity: Double = 1
    @State private var offset: CGFloat = 0

    var body: some View {
        Text("+\(change.value)")
            .font(.system(size: size == .small ? 12 : 16, weight: .bold))
            .foregroundColor(AppTheme.accentPrimary)
            .opacity(opacity)
            .offset(y: offset)
            .accessibilityHidden(true)
            .onAppear {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Earned \(change.value) puzzle points"
                )
                guard !reduceMotion else { return }
                withAnimation(.easeOut(duration: 0.8)) {
                    opacity = 0
                    offset = -20
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
