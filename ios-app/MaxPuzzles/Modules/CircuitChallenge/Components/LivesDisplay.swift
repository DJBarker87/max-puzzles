import SwiftUI

// MARK: - LivesDisplay

/// Premium display of remaining lives as hearts with pulse and crack animations
struct LivesDisplay: View {
    let lives: Int
    let maxLives: Int
    let vertical: Bool
    let compact: Bool

    @State private var previousLives: Int?

    init(
        lives: Int,
        maxLives: Int = 5,
        vertical: Bool = false,
        compact: Bool = false
    ) {
        self.lives = lives
        self.maxLives = maxLives
        self.vertical = vertical
        self.compact = compact
    }

    private var spacing: CGFloat { compact ? 4 : 8 }

    var body: some View {
        Group {
            if vertical {
                VStack(spacing: spacing) {
                    heartStack
                }
            } else {
                HStack(spacing: spacing) {
                    heartStack
                }
            }
        }
        .onChange(of: lives) { newValue in
            if let prev = previousLives, newValue < prev {
                // Life lost - play sound and haptic
                SoundEffectsService.shared.play(.wrongMove)
                FeedbackManager.shared.haptic(.wrongMove)
            }
            previousLives = newValue
        }
        .onAppear {
            previousLives = lives
        }
    }

    private var heartStack: some View {
        ForEach(0..<maxLives, id: \.self) { index in
            HeartView(
                isActive: index < lives,
                isBreaking: previousLives != nil && index == lives && index < (previousLives ?? 0),
                compact: compact
            )
        }
    }
}

// MARK: - HeartView

/// Single heart with premium pulse, glow, and crack animations
struct HeartView: View {
    let isActive: Bool
    let isBreaking: Bool
    let compact: Bool

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var glowOpacity: Double = 0.3
    @State private var crackOffset: CGFloat = 0
    @State private var showCrack: Bool = false

    private let activeColor = Color(hex: "ff3366")
    private let inactiveColor = Color(hex: "2a2a3a")

    private var heartSize: CGFloat { compact ? 14 : 20 }

    init(isActive: Bool, isBreaking: Bool, compact: Bool = false) {
        self.isActive = isActive
        self.isBreaking = isBreaking
        self.compact = compact
    }

    var body: some View {
        ZStack {
            // Glow behind active heart
            if isActive && !isBreaking {
                Image(systemName: "heart.fill")
                    .font(.system(size: heartSize * 1.3))
                    .foregroundColor(activeColor)
                    .blur(radius: 6)
                    .opacity(glowOpacity)
            }

            // Main heart
            Image(systemName: "heart.fill")
                .font(.system(size: heartSize))
                .foregroundColor(isActive ? activeColor : inactiveColor)
                .shadow(
                    color: isActive ? activeColor.opacity(0.5) : .clear,
                    radius: 4
                )

            // Crack effect when breaking
            if showCrack {
                Image(systemName: "bolt.fill")
                    .font(.system(size: heartSize * 0.6))
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(15))
                    .offset(y: crackOffset)
                    .opacity(1 - Double(crackOffset / 10))
            }
        }
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
                withAnimation {
                    scale = 1.0
                    glowOpacity = 0
                }
            }
        }
    }

    private func startPulseAnimation() {
        // Heart pulse with glow
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            scale = 1.15
            glowOpacity = 0.6
        }
    }

    private func playBreakAnimation() {
        // Show crack
        showCrack = true
        crackOffset = 0

        // Initial pop
        withAnimation(.easeOut(duration: 0.08)) {
            scale = 1.4
        }

        // Crack travels down
        withAnimation(.easeOut(duration: 0.15).delay(0.08)) {
            crackOffset = 10
        }

        // Shake
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.1)) {
                scale = 1.1
                rotation = 12
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.1)) {
                scale = 0.9
                rotation = -12
            }
        }

        // Settle and fade
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.easeOut(duration: 0.15)) {
                scale = 1.0
                rotation = 0
                showCrack = false
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

        VStack {
            Text("Compact Vertical").foregroundColor(.white)
            LivesDisplay(lives: 4, vertical: true, compact: true)
        }
    }
    .padding()
    .background(Color(hex: "0f0f23"))
}
