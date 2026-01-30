import SwiftUI

// MARK: - Enhanced Confetti View

/// Premium confetti celebration with burst effect, varied shapes, and gold sparkles
struct ConfettiView: View {
    var intensity: ConfettiIntensity = .normal
    var burstFromCenter: Bool = true

    @State private var particles: [ConfettiParticle] = []
    @State private var sparkles: [SparkleParticle] = []
    @State private var isAnimating = false

    enum ConfettiIntensity {
        case light, normal, intense

        var particleCount: Int {
            switch self {
            case .light: return 40
            case .normal: return 80
            case .intense: return 150
            }
        }

        var sparkleCount: Int {
            switch self {
            case .light: return 20
            case .normal: return 40
            case .intense: return 80
            }
        }
    }

    private let colors: [Color] = [
        Color(hex: "22c55e"),  // Green
        Color(hex: "fbbf24"),  // Gold
        Color(hex: "e94560"),  // Pink
        Color(hex: "3b82f6"),  // Blue
        Color(hex: "a855f7"),  // Purple
        Color(hex: "f97316"),  // Orange
        .white                 // White
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main confetti
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle, burstFromCenter: burstFromCenter)
                }

                // Gold sparkles
                ForEach(sparkles) { sparkle in
                    SparkleView(particle: sparkle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                createSparkles(in: geometry.size)
                isAnimating = true

                // Haptic only (sounds removed)
                FeedbackManager.shared.haptic(.levelComplete)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        let centerX = size.width / 2
        let centerY = size.height * 0.4  // Burst point

        particles = (0..<intensity.particleCount).map { i in
            let angle = burstFromCenter ? Double.random(in: 0...360) : 0
            let velocity = burstFromCenter ? CGFloat.random(in: 200...500) : 0
            let startX = burstFromCenter ? centerX : CGFloat.random(in: 0...size.width)
            let startY = burstFromCenter ? centerY : -20

            return ConfettiParticle(
                x: startX,
                y: startY,
                targetY: size.height + 50,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                delay: burstFromCenter ? 0 : Double.random(in: 0...0.5),
                duration: Double.random(in: 2.0...3.5),
                horizontalDrift: burstFromCenter
                    ? cos(angle * .pi / 180) * velocity
                    : CGFloat.random(in: -100...100),
                verticalVelocity: burstFromCenter
                    ? sin(angle * .pi / 180) * velocity * -0.5
                    : 0,
                shape: ConfettiShape.allCases.randomElement()!
            )
        }
    }

    private func createSparkles(in size: CGSize) {
        sparkles = (0..<intensity.sparkleCount).map { _ in
            SparkleParticle(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: 0...size.height),
                size: CGFloat.random(in: 4...12),
                delay: Double.random(in: 0...1.5),
                duration: Double.random(in: 0.3...0.8)
            )
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let color: Color
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let horizontalDrift: CGFloat
    let verticalVelocity: CGFloat
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
    case star
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: ConfettiParticle
    let burstFromCenter: Bool

    @State private var currentY: CGFloat = -20
    @State private var currentX: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0

    var body: some View {
        Group {
            switch particle.shape {
            case .rectangle:
                Rectangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size * 0.6)
            case .circle:
                Circle()
                    .fill(particle.color)
                    .frame(width: particle.size * 0.8, height: particle.size * 0.8)
            case .triangle:
                Triangle()
                    .fill(particle.color)
                    .frame(width: particle.size, height: particle.size)
            case .star:
                Image(systemName: "star.fill")
                    .font(.system(size: particle.size * 0.8))
                    .foregroundColor(particle.color)
            }
        }
        .rotationEffect(.degrees(currentRotation))
        .rotation3DEffect(.degrees(currentRotation * 2), axis: (x: 1, y: 0.5, z: 0))
        .position(x: particle.x + currentX, y: currentY)
        .opacity(opacity)
        .scaleEffect(scale)
        .onAppear {
            currentY = particle.y

            // Burst animation if from center
            if burstFromCenter {
                // Initial burst outward
                withAnimation(.easeOut(duration: 0.3).delay(particle.delay)) {
                    currentX = particle.horizontalDrift * 0.3
                    currentY = particle.y + particle.verticalVelocity
                    opacity = 1
                    scale = 1
                }

                // Then gravity takes over
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .delay(particle.delay + 0.3)
                ) {
                    currentY = particle.targetY
                    currentX = particle.horizontalDrift
                }
            } else {
                // Classic falling animation
                withAnimation(
                    .easeIn(duration: particle.duration)
                    .delay(particle.delay)
                ) {
                    currentY = particle.targetY
                    currentX = particle.horizontalDrift
                    opacity = 1
                    scale = 1
                }
            }

            // Rotation throughout
            withAnimation(
                .linear(duration: particle.duration)
                .delay(particle.delay)
                .repeatForever(autoreverses: false)
            ) {
                currentRotation = particle.rotation + 720
            }

            // Fade out at end
            withAnimation(
                .easeIn(duration: 0.5)
                .delay(particle.delay + particle.duration - 0.5)
            ) {
                opacity = 0
            }
        }
    }
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double
}

// MARK: - Sparkle View

struct SparkleView: View {
    let particle: SparkleParticle

    @State private var opacity: Double = 0
    @State private var scale: CGFloat = 0

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: particle.size))
            .foregroundColor(AppTheme.accentTertiary)
            .shadow(color: AppTheme.accentTertiary, radius: 4)
            .position(x: particle.x, y: particle.y)
            .opacity(opacity)
            .scaleEffect(scale)
            .onAppear {
                // Pop in
                withAnimation(.spring(response: 0.2, dampingFraction: 0.5).delay(particle.delay)) {
                    opacity = 1
                    scale = 1
                }

                // Pop out
                withAnimation(.easeOut(duration: particle.duration).delay(particle.delay + 0.2)) {
                    opacity = 0
                    scale = 1.5
                }
            }
    }
}

// MARK: - Triangle Shape

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Victory Flash Effect

/// Brief screen flash for victory moment
struct VictoryFlashView: View {
    @State private var opacity: Double = 0

    var body: some View {
        Color.white
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                // Quick flash
                withAnimation(.easeOut(duration: 0.1)) {
                    opacity = 0.6
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Star Pop Animation

/// Individual star with pop animation for star reveals
struct StarPopView: View {
    let filled: Bool
    let delay: TimeInterval
    let size: CGFloat

    @State private var scale: CGFloat = 0
    @State private var rotation: Double = -30
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            // Glow behind
            if filled {
                Image(systemName: "star.fill")
                    .font(.system(size: size * 1.5))
                    .foregroundColor(AppTheme.accentTertiary)
                    .blur(radius: 10)
                    .opacity(glowOpacity)
            }

            // Main star
            Image(systemName: filled ? "star.fill" : "star")
                .font(.system(size: size))
                .foregroundColor(filled ? AppTheme.accentTertiary : .gray.opacity(0.4))
                .shadow(color: filled ? AppTheme.accentTertiary.opacity(0.5) : .clear, radius: 4)
        }
        .scaleEffect(scale)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(
                .spring(response: 0.4, dampingFraction: 0.5)
                .delay(delay)
            ) {
                scale = 1
                rotation = 0
            }

            if filled {
                withAnimation(
                    .easeInOut(duration: 0.3)
                    .delay(delay + 0.2)
                ) {
                    glowOpacity = 0.6
                }

                // Haptic only (sounds removed)
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                    FeedbackManager.shared.haptic(.starReveal)
                }
            }
        }
    }
}

#Preview("Confetti Burst") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        ConfettiView(intensity: .intense, burstFromCenter: true)
    }
}

#Preview("Star Reveal") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedStarReveal.celebration(starsEarned: 3)
            AnimatedStarReveal.summary(starsEarned: 2)
            AnimatedStarReveal.inline(starsEarned: 1)
        }
    }
}

#Preview("Victory Flash") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VictoryFlashView()
    }
}
