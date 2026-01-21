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
            SplashBackground(overlayOpacity: 0.3)

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
                Spacer()

                // Title with premium typography
                Text("Maxi's Mighty\nMindgames")
                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 0, y: 2)
                    .shadow(color: AppTheme.connectorGlow.opacity(0.6), radius: 12)
                    .opacity(titleOpacity)

                // Subtitle
                Text("Brain Training for Kids")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 0, y: 1)
                    .opacity(subtitleOpacity)

                Spacer()
                Spacer()
            }
            .padding(.top, 60)
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

        // Phase 2: Energy ring expands (0.3s - 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            phase = .revealing

            // Energy ring expands
            withAnimation(.easeOut(duration: 0.6)) {
                ringScale = 3
                ringOpacity = 0.5
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                ringOpacity = 0
            }
        }

        // Phase 3: Haptic feedback (0.5s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            FeedbackManager.shared.haptic(.medium)
            SoundEffectsService.shared.play(.unlock)
        }

        // Phase 4: Title appears (0.4s - 0.8s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) {
                titleOpacity = 1
            }
        }

        // Phase 5: Subtitle appears (0.7s - 1.0s)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.4)) {
                subtitleOpacity = 1
            }

            phase = .complete
        }
    }

    // MARK: - Initialization

    private func initializeApp() {
        // Ensure guest session exists (do this synchronously, it's fast)
        let storage = StorageService.shared
        _ = storage.ensureGuestSession()

        // Capture references for timer closures
        let music = musicService
        let state = appState

        // Use Timer for reliable execution (Task.sleep can be cancelled/interrupted)
        // Start hub music after 0.5s
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async {
                music.play(track: .hub)
            }
        }

        // Transition to hub after 2s total
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            DispatchQueue.main.async {
                state.completeLoading()
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
