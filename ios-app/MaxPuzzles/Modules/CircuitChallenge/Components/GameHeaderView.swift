import SwiftUI

// MARK: - GameHeaderView

/// Header for the game screen showing back button, title, and status displays
struct GameHeaderView: View {
    let title: String
    let lives: Int
    let maxLives: Int
    let elapsedMs: Int
    let isTimerRunning: Bool
    let coins: Int
    let coinChange: CoinAnimation?
    let isHiddenMode: Bool
    let onBackClick: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Back button
            Button(action: onBackClick) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(AppTheme.backgroundDark.opacity(0.8))
                    .cornerRadius(10)
            }

            // Music toggle
            MusicToggleButton(size: .small)

            // Title
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            // Status displays
            HStack(spacing: 10) {
                // Lives (hidden in hidden mode)
                if !isHiddenMode {
                    LivesDisplay(lives: lives, maxLives: maxLives)
                }

                // Timer
                TimerDisplayCompact(elapsedMs: elapsedMs)

                // Coins (hidden in hidden mode during play)
                if !isHiddenMode {
                    GameCoinDisplay(
                        amount: coins,
                        showChange: coinChange,
                        size: .small
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            AppTheme.backgroundDark.opacity(0.95)
                .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        )
    }
}

// MARK: - TimerDisplayCompact

/// Compact timer display for header (horizontal layout)
struct TimerDisplayCompact: View {
    let elapsedMs: Int
    var vertical: Bool = false

    private var formattedTime: String {
        let totalSeconds = elapsedMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    var body: some View {
        Group {
            if vertical {
                VStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.accentPrimary)

                    Text(formattedTime)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.accentPrimary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.backgroundMid.opacity(0.8))
                )
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "stopwatch.fill")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)

                    Text(formattedTime)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.backgroundMid.opacity(0.8))
                )
            }
        }
    }
}

// MARK: - Preview

#Preview("Game Header") {
    VStack(spacing: 20) {
        GameHeaderView(
            title: "Quick Play",
            lives: 5,
            maxLives: 5,
            elapsedMs: 0,
            isTimerRunning: false,
            coins: 0,
            coinChange: nil,
            isHiddenMode: false,
            onBackClick: {}
        )

        GameHeaderView(
            title: "Quick Play",
            lives: 3,
            maxLives: 5,
            elapsedMs: 45000,
            isTimerRunning: true,
            coins: 50,
            coinChange: nil,
            isHiddenMode: false,
            onBackClick: {}
        )

        GameHeaderView(
            title: "Quick Play",
            lives: 2,
            maxLives: 5,
            elapsedMs: 125000,
            isTimerRunning: true,
            coins: 30,
            coinChange: CoinAnimation(value: -30, type: .penalty, timestamp: Date()),
            isHiddenMode: false,
            onBackClick: {}
        )

        GameHeaderView(
            title: "Hidden Mode",
            lives: 5,
            maxLives: 5,
            elapsedMs: 30000,
            isTimerRunning: true,
            coins: 0,
            coinChange: nil,
            isHiddenMode: true,
            onBackClick: {}
        )
    }
    .background(AppTheme.gridBackgroundTop)
}
