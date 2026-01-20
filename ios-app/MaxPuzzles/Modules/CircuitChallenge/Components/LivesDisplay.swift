import SwiftUI

// MARK: - LivesDisplay

/// Display of remaining lives as hearts with pulse animation
/// Matches web app exactly: active hearts pulse, inactive are dimmed
struct LivesDisplay: View {
    let lives: Int
    let maxLives: Int
    let vertical: Bool

    init(
        lives: Int,
        maxLives: Int = 5,
        vertical: Bool = false
    ) {
        self.lives = lives
        self.maxLives = maxLives
        self.vertical = vertical
    }

    var body: some View {
        Group {
            if vertical {
                VStack(spacing: 8) {
                    heartStack
                }
            } else {
                HStack(spacing: 8) {
                    heartStack
                }
            }
        }
    }

    private var heartStack: some View {
        ForEach(0..<maxLives, id: \.self) { index in
            HeartView(
                isActive: index < lives,
                isBreaking: false
            )
        }
    }
}

// MARK: - HeartView

/// Single heart with pulse animation for active state
/// Matches web: #ff3366 active, #2a2a3a inactive
struct HeartView: View {
    let isActive: Bool
    let isBreaking: Bool

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    private let activeColor = Color(hex: "ff3366")
    private let inactiveColor = Color(hex: "2a2a3a")

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 20))
            .foregroundColor(isActive ? activeColor : inactiveColor)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                if isActive && !isBreaking {
                    startPulseAnimation()
                }
            }
            .onChange(of: isBreaking) { breaking in
                if breaking {
                    playBreakAnimation()
                }
            }
            .onChange(of: isActive) { active in
                if active && !isBreaking {
                    startPulseAnimation()
                } else if !active {
                    scale = 1.0
                }
            }
    }

    private func startPulseAnimation() {
        // Matching web: heartPulse 1.2s ease-in-out infinite
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            scale = 1.15
        }
    }

    private func playBreakAnimation() {
        // Matching web: heartBreak 0.5s ease-out
        // Scale up quickly
        withAnimation(.easeOut(duration: 0.1)) {
            scale = 1.3
        }

        // Then shrink and rotate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.15)) {
                scale = 0.8
                rotation = 10
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.easeOut(duration: 0.15)) {
                scale = 0.5
                rotation = -10
            }
        }

        // Return to normal
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.1)) {
                scale = 1.0
                rotation = 0
            }
        }
    }
}

// MARK: - Preview

#Preview("Lives Display") {
    VStack(spacing: 40) {
        VStack {
            Text("5 Lives").foregroundColor(.white)
            LivesDisplay(lives: 5)
        }

        VStack {
            Text("3 Lives").foregroundColor(.white)
            LivesDisplay(lives: 3)
        }

        VStack {
            Text("1 Life").foregroundColor(.white)
            LivesDisplay(lives: 1)
        }

        VStack {
            Text("0 Lives").foregroundColor(.white)
            LivesDisplay(lives: 0)
        }

        VStack {
            Text("Vertical").foregroundColor(.white)
            LivesDisplay(lives: 4, vertical: true)
        }
    }
    .padding()
    .background(Color(hex: "0f0f23"))
}
