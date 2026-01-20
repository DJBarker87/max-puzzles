import SwiftUI

/// A confetti celebration animation
struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var isAnimating = false

    let colors: [Color] = [
        Color(hex: "22c55e"),  // Green
        Color(hex: "fbbf24"),  // Gold
        Color(hex: "e94560"),  // Pink
        Color(hex: "3b82f6"),  // Blue
        Color(hex: "a855f7"),  // Purple
        Color(hex: "f97316"),  // Orange
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles) { particle in
                    ConfettiPiece(particle: particle)
                }
            }
            .onAppear {
                createParticles(in: geometry.size)
                startAnimation()
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<80).map { _ in
            ConfettiParticle(
                x: CGFloat.random(in: 0...size.width),
                y: -20,
                targetY: size.height + 50,
                color: colors.randomElement()!,
                size: CGFloat.random(in: 8...16),
                rotation: Double.random(in: 0...360),
                delay: Double.random(in: 0...0.5),
                duration: Double.random(in: 2.0...3.5),
                horizontalDrift: CGFloat.random(in: -100...100),
                shape: ConfettiShape.allCases.randomElement()!
            )
        }
    }

    private func startAnimation() {
        isAnimating = true
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
    let shape: ConfettiShape
}

enum ConfettiShape: CaseIterable {
    case rectangle
    case circle
    case triangle
}

// MARK: - Confetti Piece View

struct ConfettiPiece: View {
    let particle: ConfettiParticle

    @State private var currentY: CGFloat = -20
    @State private var currentX: CGFloat = 0
    @State private var currentRotation: Double = 0
    @State private var opacity: Double = 1

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
            }
        }
        .rotationEffect(.degrees(currentRotation))
        .rotation3DEffect(.degrees(currentRotation * 2), axis: (x: 1, y: 0, z: 0))
        .position(x: particle.x + currentX, y: currentY)
        .opacity(opacity)
        .onAppear {
            currentY = particle.y

            withAnimation(
                .easeIn(duration: particle.duration)
                .delay(particle.delay)
            ) {
                currentY = particle.targetY
                currentX = particle.horizontalDrift
            }

            withAnimation(
                .linear(duration: particle.duration)
                .delay(particle.delay)
                .repeatForever(autoreverses: false)
            ) {
                currentRotation = particle.rotation + 720
            }

            // Fade out near the end
            withAnimation(
                .easeIn(duration: 0.5)
                .delay(particle.delay + particle.duration - 0.5)
            ) {
                opacity = 0
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

// MARK: - Preview

#Preview {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        ConfettiView()
    }
}
