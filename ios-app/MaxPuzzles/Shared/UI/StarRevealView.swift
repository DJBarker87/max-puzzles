import SwiftUI

// MARK: - Star Reveal View

/// Animated star reveal after completing a level
/// Stars pop up and fly into their holders one by one
struct StarRevealView: View {
    let starsEarned: Int  // 1-3
    let onComplete: () -> Void

    @State private var revealedStars: Int = 0
    @State private var starScales: [CGFloat] = [0, 0, 0]
    @State private var starOpacities: [Double] = [0, 0, 0]
    @State private var starOffsets: [CGFloat] = [50, 50, 50]
    @State private var holderGlows: [Bool] = [false, false, false]

    private let starDelay: Double = 0.4  // Delay between each star

    var body: some View {
        VStack(spacing: 32) {
            // Star holders
            HStack(spacing: 24) {
                ForEach(0..<3) { index in
                    StarHolder(
                        isFilled: revealedStars > index,
                        isGlowing: holderGlows[index]
                    )
                }
            }

            // Flying stars (positioned absolutely)
            ZStack {
                ForEach(0..<3) { index in
                    if index < starsEarned {
                        FlyingStar(
                            scale: starScales[index],
                            opacity: starOpacities[index],
                            offset: starOffsets[index]
                        )
                    }
                }
            }
            .frame(height: 80)
        }
        .onAppear {
            animateStars()
        }
    }

    private func animateStars() {
        for i in 0..<starsEarned {
            let delay = Double(i) * starDelay

            // Pop up animation
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(delay)) {
                starScales[i] = 1.3
                starOpacities[i] = 1
                starOffsets[i] = 0
            }

            // Settle and fly to holder
            withAnimation(.easeInOut(duration: 0.3).delay(delay + 0.3)) {
                starScales[i] = 0.1
                starOffsets[i] = -100
                starOpacities[i] = 0
            }

            // Show in holder
            DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.5) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    revealedStars = i + 1
                    holderGlows[i] = true
                }

                // Remove glow after a moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        holderGlows[i] = false
                    }
                }
            }
        }

        // Call completion after all stars revealed
        let totalDuration = Double(starsEarned) * starDelay + 0.8
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            onComplete()
        }
    }
}

// MARK: - Star Holder

struct StarHolder: View {
    let isFilled: Bool
    let isGlowing: Bool

    var body: some View {
        ZStack {
            // Glow effect
            if isGlowing {
                Image(systemName: "star.fill")
                    .font(.system(size: 56))
                    .foregroundColor(AppTheme.accentTertiary)
                    .blur(radius: 15)
                    .opacity(0.8)
            }

            // Star shape
            Image(systemName: isFilled ? "star.fill" : "star")
                .font(.system(size: 48))
                .foregroundColor(isFilled ? AppTheme.accentTertiary : AppTheme.textSecondary.opacity(0.3))
                .scaleEffect(isFilled && isGlowing ? 1.2 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: isFilled)
        }
    }
}

// MARK: - Flying Star

struct FlyingStar: View {
    let scale: CGFloat
    let opacity: Double
    let offset: CGFloat

    var body: some View {
        Image(systemName: "star.fill")
            .font(.system(size: 64))
            .foregroundColor(AppTheme.accentTertiary)
            .scaleEffect(scale)
            .opacity(opacity)
            .offset(y: offset)
            .shadow(color: AppTheme.accentTertiary.opacity(0.6), radius: 10)
    }
}

// MARK: - Star Display (Static)

/// Static star display showing earned stars (for level select, etc.)
struct StarDisplay: View {
    let stars: Int  // 0-3
    let maxStars: Int
    let size: StarDisplaySize

    enum StarDisplaySize {
        case small, medium, large

        var fontSize: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 36
            }
        }

        var spacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 8
            }
        }
    }

    init(stars: Int, maxStars: Int = 3, size: StarDisplaySize = .medium) {
        self.stars = stars
        self.maxStars = maxStars
        self.size = size
    }

    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(0..<maxStars, id: \.self) { index in
                Image(systemName: index < stars ? "star.fill" : "star")
                    .font(.system(size: size.fontSize))
                    .foregroundColor(index < stars ? AppTheme.accentTertiary : AppTheme.textSecondary.opacity(0.3))
            }
        }
    }
}

// MARK: - Preview

#Preview("Star Reveal - 3 Stars") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        StarRevealView(starsEarned: 3, onComplete: {})
    }
}

#Preview("Star Reveal - 2 Stars") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        StarRevealView(starsEarned: 2, onComplete: {})
    }
}

#Preview("Star Reveal - 1 Star") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        StarRevealView(starsEarned: 1, onComplete: {})
    }
}

#Preview("Star Display") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 20) {
            StarDisplay(stars: 3, size: .large)
            StarDisplay(stars: 2, size: .medium)
            StarDisplay(stars: 1, size: .small)
            StarDisplay(stars: 0, size: .medium)
        }
    }
}
