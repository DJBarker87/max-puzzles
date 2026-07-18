import SwiftUI

/// Animated starry background with optional shooting stars.
struct StarryBackground: View {
    let starCount: Int
    let enableShootingStars: Bool
    let animateStars: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        starCount: Int = 40,
        enableShootingStars: Bool = false,
        animateStars: Bool = true
    ) {
        self.starCount = starCount
        self.enableShootingStars = enableShootingStars
        self.animateStars = animateStars
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.gridBackground

                // A single canvas drives the whole star field, avoiding one perpetual
                // animation transaction per star.
                StarFieldView(
                    starCount: starCount,
                    bounds: geometry.size,
                    animate: animateStars && !reduceMotion
                )

                if enableShootingStars && !reduceMotion {
                    ShootingStarsLayer(bounds: geometry.size)
                }

                AppTheme.connectorGlow.opacity(0.03)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Shooting Stars Layer

/// Occasional shooting star animations
struct ShootingStarsLayer: View {
    let bounds: CGSize

    @State private var stars: [ShootingStar] = []
    @State private var timer: Timer?
    @State private var removalTasks: [UUID: Task<Void, Never>] = [:]

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
            timer = nil
            for task in removalTasks.values { task.cancel() }
            removalTasks.removeAll()
            stars.removeAll()
        }
    }

    private func startSpawning() {
        // Spawn a shooting star every 3-8 seconds
        spawnStar()

        scheduleNextSpawn()
    }

    private func scheduleNextSpawn() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 3...8), repeats: false) { _ in
            spawnStar()
            scheduleNextSpawn()
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
        removalTasks[star.id] = Task { @MainActor in
            do {
                try await Task.sleep(
                    nanoseconds: UInt64((star.duration + 0.5) * 1_000_000_000)
                )
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            stars.removeAll { $0.id == star.id }
            removalTasks[star.id] = nil
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

// MARK: - Star Field

/// All ambient stars share one low-frequency timeline and one canvas redraw.
private struct StarFieldView: View {
    let starCount: Int
    let bounds: CGSize
    let animate: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 12.0, paused: !animate)) { timeline in
            Canvas { context, _ in
                let time = timeline.date.timeIntervalSinceReferenceDate
                for seed in 0..<starCount {
                    let x = CGFloat((seed * 7_919) % 1_000) / 1_000 * bounds.width
                    let y = CGFloat((seed * 6_271) % 1_000) / 1_000 * bounds.height
                    let diameter = CGFloat((seed * 3_571) % 3 + 1)
                    let duration = Double((seed * 2_311) % 20 + 30) / 10
                    let phase = Double(seed % 50) * 0.1
                    let pulse = (sin((time + phase) * 2 * .pi / duration) + 1) / 2
                    let opacity = animate ? 0.3 + pulse * 0.5 : 0.55
                    let rect = CGRect(
                        x: x - diameter / 2,
                        y: y - diameter / 2,
                        width: diameter,
                        height: diameter
                    )
                    context.fill(Path(ellipseIn: rect), with: .color(.white.opacity(opacity)))
                }
            }
        }
    }
}

// MARK: - Splash Background

/// Reusable splash background with dark overlay
/// Offsets the image on portrait mobile to hide the bear character
struct SplashBackground: View {
    var overlayOpacity: Double = 0.6

    var body: some View {
        GeometryReader { geometry in
            let isPortraitPhone = geometry.size.height > geometry.size.width
                && UIDevice.current.userInterfaceIdiom == .phone

            ZStack {
                // Fallback solid color (always visible immediately)
                AppTheme.backgroundDark

                // Fallback gradient
                AppTheme.gridBackground

                // Give the artwork a fixed viewport. Card micro-animations elsewhere in the
                // hierarchy must never be able to renegotiate the background image's size.
                Image("splash_background")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .offset(x: isPortraitPhone ? -80 : 0)

                Color.black.opacity(overlayOpacity)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
            .transaction { transaction in
                // Splash artwork is a stable scene, even when a descendant starts a repeating
                // glow or hover animation.
                transaction.animation = nil
            }
        }
        .ignoresSafeArea()
    }
}

#Preview("Splash Background") {
    SplashBackground()
}
