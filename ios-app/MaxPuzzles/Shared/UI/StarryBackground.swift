import SwiftUI
import CoreMotion

/// Animated starry background with shooting stars and parallax
struct StarryBackground: View {
    let starCount: Int
    let useHubImage: Bool
    let enableShootingStars: Bool
    let enableParallax: Bool

    init(
        starCount: Int = 80,
        useHubImage: Bool = false,
        enableShootingStars: Bool = true,
        enableParallax: Bool = true
    ) {
        self.starCount = starCount
        self.useHubImage = useHubImage
        self.enableShootingStars = enableShootingStars
        self.enableParallax = enableParallax
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if useHubImage {
                    // Hub/Splash background with parallax
                    ParallaxBackground(
                        imageName: "HubBackground",
                        size: geometry.size,
                        enableParallax: enableParallax
                    )

                    // Shooting stars overlay
                    if enableShootingStars {
                        ShootingStarsLayer(bounds: geometry.size)
                    }
                } else {
                    // Base gradient
                    AppTheme.gridBackground

                    // Stars
                    ForEach(0..<starCount, id: \.self) { index in
                        StarView(
                            seed: index,
                            bounds: geometry.size
                        )
                    }

                    // Shooting stars
                    if enableShootingStars {
                        ShootingStarsLayer(bounds: geometry.size)
                    }

                    // Ambient green glow
                    AppTheme.connectorGlow.opacity(0.03)
                }
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Parallax Background

/// Background image with subtle parallax effect based on device motion
struct ParallaxBackground: View {
    let imageName: String
    let size: CGSize
    let enableParallax: Bool

    @StateObject private var motionManager = MotionManager()

    // Parallax intensity (how much the image moves)
    private let parallaxIntensity: CGFloat = 20

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(
                width: size.width + parallaxIntensity * 2,
                height: size.height + parallaxIntensity * 2
            )
            .offset(
                x: enableParallax ? motionManager.roll * parallaxIntensity : 0,
                y: enableParallax ? motionManager.pitch * parallaxIntensity : 0
            )
            .clipped()
            .overlay(Color.black.opacity(0.3)) // Slight darkening for text readability
            .animation(.easeOut(duration: 0.1), value: motionManager.roll)
            .animation(.easeOut(duration: 0.1), value: motionManager.pitch)
    }
}

// MARK: - Motion Manager

/// Manages device motion for parallax effect
class MotionManager: ObservableObject {
    private var motionManager: CMMotionManager?

    @Published var pitch: CGFloat = 0  // Forward/backward tilt
    @Published var roll: CGFloat = 0   // Left/right tilt

    init() {
        #if os(iOS)
        setupMotionManager()
        #endif
    }

    private func setupMotionManager() {
        #if os(iOS)
        motionManager = CMMotionManager()
        motionManager?.deviceMotionUpdateInterval = 1.0 / 60.0

        guard let manager = motionManager, manager.isDeviceMotionAvailable else { return }

        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let motion = motion, error == nil else { return }

            // Normalize and clamp values (-1 to 1)
            let newPitch = max(-1, min(1, motion.attitude.pitch))
            let newRoll = max(-1, min(1, motion.attitude.roll))

            DispatchQueue.main.async {
                self?.pitch = newPitch
                self?.roll = newRoll
            }
        }
        #endif
    }

    deinit {
        #if os(iOS)
        motionManager?.stopDeviceMotionUpdates()
        #endif
    }
}

// MARK: - Shooting Stars Layer

/// Occasional shooting star animations
struct ShootingStarsLayer: View {
    let bounds: CGSize

    @State private var stars: [ShootingStar] = []
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            ForEach(stars) { star in
                ShootingStarView(star: star)
            }
        }
        .onAppear {
            startSpawning()
        }
        .onDisappear {
            timer?.invalidate()
        }
    }

    private func startSpawning() {
        // Spawn a shooting star every 3-8 seconds
        spawnStar()

        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { _ in
            spawnStar()
            // Randomize next interval
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: true) { _ in
                spawnStar()
            }
        }
    }

    private func spawnStar() {
        let star = ShootingStar(
            id: UUID(),
            startX: CGFloat.random(in: 0...bounds.width),
            startY: CGFloat.random(in: -50...bounds.height * 0.3),
            angle: CGFloat.random(in: 25...65),  // Degrees from horizontal
            length: CGFloat.random(in: 80...150),
            duration: Double.random(in: 0.8...1.5),
            delay: 0
        )

        withAnimation {
            stars.append(star)
        }

        // Remove after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + star.duration + 0.5) {
            stars.removeAll { $0.id == star.id }
        }
    }
}

// MARK: - Shooting Star Model

struct ShootingStar: Identifiable {
    let id: UUID
    let startX: CGFloat
    let startY: CGFloat
    let angle: CGFloat
    let length: CGFloat
    let duration: Double
    let delay: Double
}

// MARK: - Shooting Star View

struct ShootingStarView: View {
    let star: ShootingStar

    @State private var progress: CGFloat = 0
    @State private var opacity: CGFloat = 0

    private var endX: CGFloat {
        star.startX + cos(star.angle * .pi / 180) * star.length * 3
    }

    private var endY: CGFloat {
        star.startY + sin(star.angle * .pi / 180) * star.length * 3
    }

    var body: some View {
        Canvas { context, size in
            let currentX = star.startX + (endX - star.startX) * progress
            let currentY = star.startY + (endY - star.startY) * progress

            // Trail
            let trailLength = star.length * (1 - progress * 0.5)
            let trailStartX = currentX - cos(star.angle * .pi / 180) * trailLength
            let trailStartY = currentY - sin(star.angle * .pi / 180) * trailLength

            var path = Path()
            path.move(to: CGPoint(x: trailStartX, y: trailStartY))
            path.addLine(to: CGPoint(x: currentX, y: currentY))

            // Gradient from transparent to bright white
            let gradient = Gradient(colors: [
                Color.white.opacity(0),
                Color.white.opacity(opacity * 0.3),
                Color.white.opacity(opacity * 0.8),
                Color.white.opacity(opacity)
            ])

            context.stroke(
                path,
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: trailStartX, y: trailStartY),
                    endPoint: CGPoint(x: currentX, y: currentY)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )

            // Bright head
            let headPath = Path(ellipseIn: CGRect(
                x: currentX - 2,
                y: currentY - 2,
                width: 4,
                height: 4
            ))
            context.fill(headPath, with: .color(.white.opacity(opacity)))

            // Glow
            context.addFilter(.blur(radius: 3))
            context.stroke(
                path,
                with: .color(.white.opacity(opacity * 0.5)),
                style: StrokeStyle(lineWidth: 4, lineCap: .round)
            )
        }
        .allowsHitTesting(false)
        .onAppear {
            // Fade in
            withAnimation(.easeIn(duration: 0.1).delay(star.delay)) {
                opacity = 1
            }

            // Move across screen
            withAnimation(.easeIn(duration: star.duration).delay(star.delay)) {
                progress = 1
            }

            // Fade out near end
            withAnimation(.easeOut(duration: 0.3).delay(star.delay + star.duration * 0.7)) {
                opacity = 0
            }
        }
    }
}

// MARK: - Individual Star View

/// Individual twinkling star
struct StarView: View {
    let seed: Int
    let bounds: CGSize

    @State private var opacity: Double = 0.3

    private var position: CGPoint {
        // Use seed for deterministic random position
        let x = CGFloat((seed * 7919) % 1000) / 1000.0 * bounds.width
        let y = CGFloat((seed * 6271) % 1000) / 1000.0 * bounds.height
        return CGPoint(x: x, y: y)
    }

    private var size: CGFloat {
        CGFloat((seed * 3571) % 3 + 1)
    }

    private var animationDuration: Double {
        Double((seed * 2311) % 20 + 30) / 10.0  // 3-5 seconds
    }

    var body: some View {
        Circle()
            .fill(Color.white)
            .frame(width: size, height: size)
            .position(position)
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: animationDuration)
                    .repeatForever(autoreverses: true)
                    .delay(Double(seed % 50) * 0.1)
                ) {
                    opacity = 0.8
                }
            }
    }
}

// MARK: - Splash Background

/// Reusable splash background with dark overlay
/// Offsets the image on portrait mobile to hide the bear character
struct SplashBackground: View {
    var overlayOpacity: Double = 0.6

    // Calculate offset once based on screen bounds (stable, no animation)
    private var backgroundOffset: CGFloat {
        let screen = UIScreen.main.bounds
        let isPortrait = screen.height > screen.width
        let isPhone = UIDevice.current.userInterfaceIdiom == .phone
        return (isPortrait && isPhone) ? -80 : 0
    }

    var body: some View {
        ZStack {
            // Fallback solid color (always visible immediately)
            AppTheme.backgroundDark

            // Fallback gradient
            AppTheme.gridBackground

            // Background image
            Image("splash_background")
                .resizable()
                .scaledToFill()
                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                .offset(x: backgroundOffset)
                .clipped()

            Color.black.opacity(overlayOpacity)
        }
        .ignoresSafeArea()
    }
}

#Preview("Splash Background") {
    SplashBackground()
}

#Preview {
    StarryBackground(useHubImage: true)
}
