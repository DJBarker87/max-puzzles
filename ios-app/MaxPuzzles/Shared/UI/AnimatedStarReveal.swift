import SwiftUI
import UIKit

/// Animated star reveal that shows stars popping in one-by-one with bounce effect
struct AnimatedStarReveal: View {
    let starsEarned: Int
    let totalStars: Int
    let starSize: CGFloat
    let delay: Double

    @State private var revealedStars: [Bool] = []
    @State private var starScales: [CGFloat] = []
    @State private var sparkleOpacities: [Double] = []

    init(starsEarned: Int, totalStars: Int = 3, starSize: CGFloat = 36, delay: Double = 0.3) {
        self.starsEarned = starsEarned
        self.totalStars = totalStars
        self.starSize = starSize
        self.delay = delay
    }

    var body: some View {
        HStack(spacing: starSize * 0.25) {
            ForEach(0..<totalStars, id: \.self) { index in
                ZStack {
                    // Sparkle burst effect for earned stars
                    if index < starsEarned {
                        // Outer sparkle ring
                        ForEach(0..<8, id: \.self) { sparkleIndex in
                            Circle()
                                .fill(Color.yellow.opacity(0.8))
                                .frame(width: 4, height: 4)
                                .offset(
                                    x: cos(Double(sparkleIndex) * .pi / 4) * starSize * 0.6,
                                    y: sin(Double(sparkleIndex) * .pi / 4) * starSize * 0.6
                                )
                                .opacity(sparkleOpacity(for: index))
                                .scaleEffect(sparkleOpacity(for: index) > 0 ? 1.0 : 0.0)
                        }

                        // Glow behind star
                        Image(systemName: "star.fill")
                            .font(.system(size: starSize * 1.2))
                            .foregroundColor(AppTheme.accentTertiary.opacity(0.5))
                            .blur(radius: 8)
                            .opacity(isRevealed(index) ? 0.8 : 0)
                    }

                    // The star itself
                    Image(systemName: index < starsEarned ? "star.fill" : "star")
                        .font(.system(size: starSize, weight: .medium))
                        .foregroundColor(index < starsEarned ? AppTheme.accentTertiary : Color.gray.opacity(0.4))
                        .scaleEffect(starScale(for: index))
                        .opacity(isRevealed(index) ? 1.0 : (index < starsEarned ? 0.0 : 0.3))
                }
            }
        }
        .onAppear {
            setupInitialState()
            animateStars()
        }
    }

    // MARK: - State Helpers

    private func isRevealed(_ index: Int) -> Bool {
        guard index < revealedStars.count else { return false }
        return revealedStars[index]
    }

    private func starScale(for index: Int) -> CGFloat {
        guard index < starScales.count else { return index < starsEarned ? 0.0 : 1.0 }
        return starScales[index]
    }

    private func sparkleOpacity(for index: Int) -> Double {
        guard index < sparkleOpacities.count else { return 0 }
        return sparkleOpacities[index]
    }

    // MARK: - Animation

    private func setupInitialState() {
        revealedStars = Array(repeating: false, count: totalStars)
        starScales = (0..<totalStars).map { index in
            index < starsEarned ? 0.0 : 1.0
        }
        sparkleOpacities = Array(repeating: 0.0, count: totalStars)

        // Show empty stars immediately
        for i in starsEarned..<totalStars {
            revealedStars[i] = true
        }
    }

    private func animateStars() {
        // Animate each earned star with staggered delay
        for starIndex in 0..<starsEarned {
            let starDelay = delay + Double(starIndex) * 0.4

            // Pop in animation
            DispatchQueue.main.asyncAfter(deadline: .now() + starDelay) {
                // Show sparkle burst
                withAnimation(.easeOut(duration: 0.2)) {
                    sparkleOpacities[starIndex] = 1.0
                }

                // Pop in the star with overshoot
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0)) {
                    revealedStars[starIndex] = true
                    starScales[starIndex] = 1.3
                }

                // Settle to normal size
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        starScales[starIndex] = 1.0
                    }

                    // Fade sparkles
                    withAnimation(.easeOut(duration: 0.5)) {
                        sparkleOpacities[starIndex] = 0
                    }
                }

                // Trigger haptic
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            }
        }
    }
}

// MARK: - Convenience Extensions

extension AnimatedStarReveal {
    /// Standard size for summary screens
    static func summary(starsEarned: Int, delay: Double = 0.5, starSize: CGFloat = 36) -> AnimatedStarReveal {
        AnimatedStarReveal(starsEarned: starsEarned, starSize: starSize, delay: delay)
    }

    /// Large size for celebration screens
    static func celebration(starsEarned: Int, delay: Double = 0.3) -> AnimatedStarReveal {
        AnimatedStarReveal(starsEarned: starsEarned, starSize: 48, delay: delay)
    }

    /// Small size for inline displays
    static func inline(starsEarned: Int) -> AnimatedStarReveal {
        AnimatedStarReveal(starsEarned: starsEarned, starSize: 20, delay: 0)
    }
}

// MARK: - Preview

#Preview("3 Stars Earned") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedStarReveal.celebration(starsEarned: 3)
            AnimatedStarReveal.summary(starsEarned: 2)
            AnimatedStarReveal.inline(starsEarned: 1)
        }
    }
}

#Preview("0 Stars") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        AnimatedStarReveal.summary(starsEarned: 0)
    }
}
