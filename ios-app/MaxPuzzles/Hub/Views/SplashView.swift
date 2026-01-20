import SwiftUI

/// Premium splash screen with particle assembly and energy effects
/// Features: Logo assembles from particles, energy trails, hyperspace stars
struct SplashView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var musicService: MusicService

    // Animation states
    @State private var phase: SplashPhase = .initial
    @State private var particleProgress: CGFloat = 0
    @State private var logoScale: CGFloat = 0.3
    @State private var logoOpacity: Double = 0
    @State private var boltScale: CGFloat = 0
    @State private var boltGlow: Double = 0.3
    @State private var ringScale: CGFloat = 0.5
    @State private var ringOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var energyRingRotation: Double = 0

    enum SplashPhase {
        case initial
        case assembling
        case revealing
        case complete
    }

    var body: some View {
        ZStack {
            // Background with shooting stars
            StarryBackground(useHubImage: true, enableShootingStars: true, enableParallax: true)

            // Energy ring expanding outward
            Circle()
                .stroke(AppTheme.connectorGlow.opacity(ringOpacity), lineWidth: 3)
                .frame(width: 200 * ringScale, height: 200 * ringScale)
                .blur(radius: 4)

            // Particle assembly effect
            if phase == .assembling || phase == .revealing {
                ParticleAssemblyView(progress: particleProgress)
            }

            // Main content
            VStack(spacing: AppSpacing.lg) {
                // Logo assembly
                ZStack {
                    // Outer glow ring
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    AppTheme.connectorGlow.opacity(boltGlow * 0.3),
                                    AppTheme.connectorGlow.opacity(0)
                                ],
                                center: .center,
                                startRadius: 40,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .rotationEffect(.degrees(energyRingRotation))

                    // Hexagon background
                    Image(systemName: "hexagon.fill")
                        .font(.system(size: 120))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    AppTheme.accentPrimary.opacity(0.5),
                                    AppTheme.accentPrimary.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: AppTheme.accentPrimary.opacity(0.5), radius: 20)

                    // Electric bolt with glow layers
                    ZStack {
                        // Outer glow
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 55))
                            .foregroundColor(AppTheme.connectorGlow)
                            .blur(radius: 15)
                            .opacity(boltGlow)

                        // Middle glow
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 52))
                            .foregroundColor(AppTheme.connectorGlow)
                            .blur(radius: 6)
                            .opacity(boltGlow * 0.8)

                        // Core
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                            .shadow(color: AppTheme.connectorGlow, radius: 8)
                    }
                    .scaleEffect(boltScale)
                }
                .scaleEffect(logoScale)
                .opacity(logoOpacity)

                // Title with premium typography
                Text("Max's Puzzles")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, .white.opacity(0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .shadow(color: AppTheme.connectorGlow.opacity(0.5), radius: 10)
                    .opacity(titleOpacity)

                // Subtitle
                Text("Fun maths puzzles for kids")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .opacity(subtitleOpacity)
            }
        }
        .onAppear {
            startPremiumAnimation()
            initializeApp()
        }
    }

    // MARK: - Premium Animation Sequence

    private func startPremiumAnimation() {
        // Phase 1: Particle assembly (0 - 0.5s)
        phase = .assembling

        withAnimation(.easeOut(duration: 0.5)) {
            particleProgress = 1
        }

        // Phase 2: Logo reveal (0.3s - 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .revealing

            // Logo scales up with spring
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            // Energy ring expands
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 3
                ringOpacity = 0.5
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                ringOpacity = 0
            }
        }

        // Phase 3: Bolt appears (0.5s - 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                boltScale = 1.0
            }

            // Haptic feedback
            FeedbackManager.shared.haptic(.medium)
            SoundEffectsService.shared.play(.unlock)
        }

        // Phase 4: Title and subtitle (0.7s - 1.2s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.4)) {
                titleOpacity = 1
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            withAnimation(.easeOut(duration: 0.3)) {
                subtitleOpacity = 1
            }
        }

        // Phase 5: Continuous glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                boltGlow = 1.0
            }

            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                energyRingRotation = 360
            }

            phase = .complete
        }
    }

    // MARK: - Initialization

    private func initializeApp() {
        // Ensure guest session exists
        let storage = StorageService.shared
        _ = storage.ensureGuestSession()

        // Start hub music
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            musicService.play(track: .hub)
        }

        // Transition to hub after splash
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeInOut(duration: 0.4)) {
                appState.completeLoading()
            }
        }
    }
}

// MARK: - Particle Assembly View

/// Particles that converge to form the logo
struct ParticleAssemblyView: View {
    let progress: CGFloat

    @State private var particles: [AssemblyParticle] = []

    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2 - 40)

            Canvas { context, size in
                for particle in particles {
                    let currentPos = particle.interpolatedPosition(progress: progress, target: center)
                    let opacity = min(1, progress * 2) * (1 - progress * 0.3)
                    let particleSize = particle.size * (1 - progress * 0.5)

                    // Draw particle with glow
                    let glowRect = CGRect(
                        x: currentPos.x - particleSize,
                        y: currentPos.y - particleSize,
                        width: particleSize * 2,
                        height: particleSize * 2
                    )

                    context.fill(
                        Path(ellipseIn: glowRect),
                        with: .color(particle.color.opacity(opacity * 0.5))
                    )

                    let coreRect = CGRect(
                        x: currentPos.x - particleSize * 0.5,
                        y: currentPos.y - particleSize * 0.5,
                        width: particleSize,
                        height: particleSize
                    )

                    context.fill(
                        Path(ellipseIn: coreRect),
                        with: .color(particle.color.opacity(opacity))
                    )
                }
            }
            .blur(radius: 2)
            .onAppear {
                createParticles(in: geometry.size)
            }
        }
        .allowsHitTesting(false)
    }

    private func createParticles(in size: CGSize) {
        particles = (0..<40).map { i in
            // Start from edges of screen
            let angle = Double(i) / 40 * 2 * .pi
            let distance = max(size.width, size.height) * 0.7
            let startX = size.width / 2 + cos(angle) * distance
            let startY = size.height / 2 + sin(angle) * distance

            return AssemblyParticle(
                startPosition: CGPoint(x: startX, y: startY),
                color: [AppTheme.connectorGlow, AppTheme.accentPrimary, .white].randomElement()!,
                size: CGFloat.random(in: 3...8),
                delay: Double(i) * 0.01
            )
        }
    }
}

// MARK: - Assembly Particle

struct AssemblyParticle: Identifiable {
    let id = UUID()
    let startPosition: CGPoint
    let color: Color
    let size: CGFloat
    let delay: Double

    func interpolatedPosition(progress: CGFloat, target: CGPoint) -> CGPoint {
        let adjustedProgress = max(0, min(1, (progress - delay) / (1 - delay)))
        let eased = easeOutQuart(adjustedProgress)

        return CGPoint(
            x: startPosition.x + (target.x - startPosition.x) * eased,
            y: startPosition.y + (target.y - startPosition.y) * eased
        )
    }

    private func easeOutQuart(_ t: CGFloat) -> CGFloat {
        1 - pow(1 - t, 4)
    }
}

#Preview {
    SplashView()
        .environmentObject(AppState())
        .environmentObject(MusicService.shared)
}
