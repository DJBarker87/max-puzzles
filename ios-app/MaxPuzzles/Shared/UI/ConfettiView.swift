import QuartzCore
import SwiftUI

// MARK: - Enhanced Confetti View

/// Premium confetti celebration with burst effect, varied shapes, and gold sparkles
struct ConfettiView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var intensity: ConfettiIntensity = .normal
    var burstFromCenter: Bool = true

    @State private var particles: [ConfettiParticle] = []
    @State private var sparkles: [SparkleParticle] = []
    @State private var startedAt: Date?
    @State private var isAnimating = false
    @State private var stopTask: Task<Void, Never>?

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
            TimelineView(
                .animation(
                    minimumInterval: 1.0 / 60.0,
                    paused: !isAnimating || reduceMotion
                )
            ) { timeline in
                Canvas(rendersAsynchronously: true) { context, _ in
                    guard let startedAt else { return }
                    ConfettiRenderer.draw(
                        particles: particles,
                        sparkles: sparkles,
                        elapsed: max(0, timeline.date.timeIntervalSince(startedAt)),
                        burstFromCenter: burstFromCenter,
                        colors: colors,
                        context: &context
                    )
                }
            }
            .onAppear {
                if !reduceMotion {
                    startAnimation(in: geometry.size)
                }

                // Haptic only (sounds removed)
                FeedbackManager.shared.haptic(.levelComplete)
            }
            .onChange(of: reduceMotion) { shouldReduceMotion in
                if shouldReduceMotion {
                    stopAnimation(clearParticles: true)
                } else {
                    startAnimation(in: geometry.size)
                }
            }
            .onDisappear {
                stopAnimation(clearParticles: false)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func startAnimation(in size: CGSize) {
        guard size.width > 0, size.height > 0 else { return }

        var generator = SystemRandomNumberGenerator()
        let nextParticles = ConfettiParticleFactory.makeParticles(
            count: intensity.particleCount,
            in: size,
            burstFromCenter: burstFromCenter,
            colorCount: colors.count,
            using: &generator
        )
        let nextSparkles = ConfettiParticleFactory.makeSparkles(
            count: intensity.sparkleCount,
            in: size,
            using: &generator
        )
        let startDate = Date()

        stopTask?.cancel()
        particles = nextParticles
        sparkles = nextSparkles
        startedAt = startDate
        isAnimating = true

        let visibleDuration = max(
            nextParticles.map(\.visibleDuration).max() ?? 0,
            nextSparkles.map(\.visibleDuration).max() ?? 0
        )
        stopTask = Task { @MainActor in
            if visibleDuration > 0 {
                try? await Task.sleep(
                    nanoseconds: UInt64(visibleDuration * 1_000_000_000)
                )
            }
            guard !Task.isCancelled, startedAt == startDate else { return }
            isAnimating = false
            stopTask = nil
        }
    }

    private func stopAnimation(clearParticles: Bool) {
        stopTask?.cancel()
        stopTask = nil
        isAnimating = false
        startedAt = nil
        if clearParticles {
            particles = []
            sparkles = []
        }
    }
}

// MARK: - Confetti Particle

struct ConfettiParticle: Identifiable, Equatable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let targetY: CGFloat
    let colorIndex: Int
    let size: CGFloat
    let rotation: Double
    let delay: Double
    let duration: Double
    let horizontalDrift: CGFloat
    let verticalVelocity: CGFloat
    let shape: ConfettiShape

    var visibleDuration: TimeInterval { delay + duration }
}

enum ConfettiShape: Int, CaseIterable {
    case rectangle
    case circle
    case triangle
    case star
}

// MARK: - Sparkle Particle

struct SparkleParticle: Identifiable, Equatable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let delay: Double
    let duration: Double

    var visibleDuration: TimeInterval { delay + 0.2 + duration }
}

// MARK: - Particle generation and simulation

enum ConfettiParticleFactory {
    static func makeParticles<R: RandomNumberGenerator>(
        count: Int,
        in size: CGSize,
        burstFromCenter: Bool,
        colorCount: Int,
        using generator: inout R
    ) -> [ConfettiParticle] {
        precondition(colorCount > 0)
        let centerX = size.width / 2
        let centerY = size.height * 0.4

        return (0..<count).map { id in
            let angle = burstFromCenter
                ? Double.random(in: 0...360, using: &generator)
                : 0
            let velocity = burstFromCenter
                ? CGFloat.random(in: 200...500, using: &generator)
                : 0
            let startX = burstFromCenter
                ? centerX
                : CGFloat.random(in: 0...size.width, using: &generator)
            let startY = burstFromCenter ? centerY : -20
            let horizontalDrift: CGFloat = burstFromCenter
                ? CGFloat(cos(angle * .pi / 180)) * velocity
                : CGFloat.random(in: -100...100, using: &generator)

            return ConfettiParticle(
                id: id,
                x: startX,
                y: startY,
                targetY: size.height + 50,
                colorIndex: Int.random(in: 0..<colorCount, using: &generator),
                size: CGFloat.random(in: 8...16, using: &generator),
                rotation: Double.random(in: 0...360, using: &generator),
                delay: burstFromCenter
                    ? 0
                    : Double.random(in: 0...0.5, using: &generator),
                duration: Double.random(in: 2...3.5, using: &generator),
                horizontalDrift: horizontalDrift,
                verticalVelocity: burstFromCenter
                    ? CGFloat(sin(angle * .pi / 180)) * velocity * -0.5
                    : 0,
                shape: ConfettiShape.allCases[
                    Int.random(in: 0..<ConfettiShape.allCases.count, using: &generator)
                ]
            )
        }
    }

    static func makeSparkles<R: RandomNumberGenerator>(
        count: Int,
        in size: CGSize,
        using generator: inout R
    ) -> [SparkleParticle] {
        (0..<count).map { id in
            SparkleParticle(
                id: id,
                x: CGFloat.random(in: 0...size.width, using: &generator),
                y: CGFloat.random(in: 0...size.height, using: &generator),
                size: CGFloat.random(in: 4...12, using: &generator),
                delay: Double.random(in: 0...1.5, using: &generator),
                duration: Double.random(in: 0.3...0.8, using: &generator)
            )
        }
    }
}

struct ConfettiParticleFrame: Equatable {
    let position: CGPoint
    let rotation: Double
    let opacity: Double
    let scale: CGFloat
}

struct ConfettiSparkleFrame: Equatable {
    let opacity: Double
    let scale: CGFloat
}

enum ConfettiSymbolGeometry {
    static let starSystemName = "star.fill"
    static let sparkleSystemName = "sparkle"
    static let sourcePointSize: CGFloat = 100

    static func layoutSize(
        for particle: ConfettiParticle,
        starSourceSize: CGSize
    ) -> CGSize {
        switch particle.shape {
        case .rectangle:
            return CGSize(width: particle.size, height: particle.size * 0.6)
        case .circle:
            return CGSize(width: particle.size * 0.8, height: particle.size * 0.8)
        case .triangle:
            return CGSize(width: particle.size, height: particle.size)
        case .star:
            return typographicLayoutSize(
                sourceSize: starSourceSize,
                targetPointSize: particle.size * 0.8
            )
        }
    }

    static func typographicLayoutSize(
        sourceSize: CGSize,
        targetPointSize: CGFloat
    ) -> CGSize {
        let scale = targetPointSize / sourcePointSize
        return CGSize(
            width: sourceSize.width * scale,
            height: sourceSize.height * scale
        )
    }
}

/// Recreates the transform stack from the former particle view:
/// `rotationEffect`, then `rotation3DEffect` around (1, 0.5, 0), then `scaleEffect`.
/// SwiftUI normalises 3D perspective by the view's longest edge; the same projection is applied
/// here around the particle's final Canvas position.
enum ConfettiParticleProjection {
    static func transform(
        rotationDegrees: Double,
        scale: CGFloat,
        layoutSize: CGSize,
        anchor: CGPoint,
        contentScale: CGFloat = 1
    ) -> ProjectionTransform {
        let zRotation = ConfettiHomography.rotation(
            radians: CGFloat(rotationDegrees * .pi / 180)
        )
        let threeDRotation = ConfettiHomography(
            projectionTransform: centeredThreeDRotation(
                rotationDegrees: rotationDegrees * 2,
                layoutSize: layoutSize
            )
        )
        let scaledProjection = ConfettiHomography.scale(scale)
            * threeDRotation
            * zRotation
            * ConfettiHomography.scale(contentScale)
        let anchoredProjection = ConfettiHomography.translation(x: anchor.x, y: anchor.y)
            * scaledProjection
            * ConfettiHomography.translation(x: -anchor.x, y: -anchor.y)
        return anchoredProjection.projectionTransform
    }

    /// Exposed for equivalence tests against SwiftUI's former `rotation3DEffect` matrix.
    static func threeDRotation(
        rotationDegrees: Double,
        layoutSize: CGSize,
        anchor: CGPoint
    ) -> ProjectionTransform {
        let centered = ConfettiHomography(
            projectionTransform: centeredThreeDRotation(
                rotationDegrees: rotationDegrees,
                layoutSize: layoutSize
            )
        )
        return (
            ConfettiHomography.translation(x: anchor.x, y: anchor.y)
                * centered
                * ConfettiHomography.translation(x: -anchor.x, y: -anchor.y)
        ).projectionTransform
    }

    static func scale(_ amount: CGFloat, anchor: CGPoint) -> ProjectionTransform {
        (
            ConfettiHomography.translation(x: anchor.x, y: anchor.y)
                * ConfettiHomography.scale(amount)
                * ConfettiHomography.translation(x: -anchor.x, y: -anchor.y)
        ).projectionTransform
    }

    private static func centeredThreeDRotation(
        rotationDegrees: Double,
        layoutSize: CGSize
    ) -> ProjectionTransform {
        let longestEdge = max(layoutSize.width, layoutSize.height)
        guard longestEdge > 0 else { return ProjectionTransform() }

        var transform = CATransform3DIdentity
        transform.m34 = -1 / longestEdge
        transform = CATransform3DRotate(
            transform,
            CGFloat(rotationDegrees * .pi / 180),
            1,
            0.5,
            0
        )
        return ProjectionTransform(transform)
    }
}

private struct ConfettiHomography {
    let a: CGFloat
    let b: CGFloat
    let c: CGFloat
    let d: CGFloat
    let e: CGFloat
    let f: CGFloat
    let g: CGFloat
    let h: CGFloat
    let i: CGFloat

    init(
        a: CGFloat,
        b: CGFloat,
        c: CGFloat,
        d: CGFloat,
        e: CGFloat,
        f: CGFloat,
        g: CGFloat,
        h: CGFloat,
        i: CGFloat
    ) {
        self.a = a
        self.b = b
        self.c = c
        self.d = d
        self.e = e
        self.f = f
        self.g = g
        self.h = h
        self.i = i
    }

    init(projectionTransform: ProjectionTransform) {
        a = projectionTransform.m11
        b = projectionTransform.m21
        c = projectionTransform.m31
        d = projectionTransform.m12
        e = projectionTransform.m22
        f = projectionTransform.m32
        g = projectionTransform.m13
        h = projectionTransform.m23
        i = projectionTransform.m33
    }

    var projectionTransform: ProjectionTransform {
        var result = ProjectionTransform()
        result.m11 = a
        result.m21 = b
        result.m31 = c
        result.m12 = d
        result.m22 = e
        result.m32 = f
        result.m13 = g
        result.m23 = h
        result.m33 = i
        return result
    }

    static func translation(x: CGFloat, y: CGFloat) -> ConfettiHomography {
        ConfettiHomography(
            a: 1, b: 0, c: x,
            d: 0, e: 1, f: y,
            g: 0, h: 0, i: 1
        )
    }

    static func rotation(radians: CGFloat) -> ConfettiHomography {
        let cosine = cos(radians)
        let sine = sin(radians)
        return ConfettiHomography(
            a: cosine, b: -sine, c: 0,
            d: sine, e: cosine, f: 0,
            g: 0, h: 0, i: 1
        )
    }

    static func scale(_ amount: CGFloat) -> ConfettiHomography {
        ConfettiHomography(
            a: amount, b: 0, c: 0,
            d: 0, e: amount, f: 0,
            g: 0, h: 0, i: 1
        )
    }

    static func * (
        lhs: ConfettiHomography,
        rhs: ConfettiHomography
    ) -> ConfettiHomography {
        ConfettiHomography(
            a: lhs.a * rhs.a + lhs.b * rhs.d + lhs.c * rhs.g,
            b: lhs.a * rhs.b + lhs.b * rhs.e + lhs.c * rhs.h,
            c: lhs.a * rhs.c + lhs.b * rhs.f + lhs.c * rhs.i,
            d: lhs.d * rhs.a + lhs.e * rhs.d + lhs.f * rhs.g,
            e: lhs.d * rhs.b + lhs.e * rhs.e + lhs.f * rhs.h,
            f: lhs.d * rhs.c + lhs.e * rhs.f + lhs.f * rhs.i,
            g: lhs.g * rhs.a + lhs.h * rhs.d + lhs.i * rhs.g,
            h: lhs.g * rhs.b + lhs.h * rhs.e + lhs.i * rhs.h,
            i: lhs.g * rhs.c + lhs.h * rhs.f + lhs.i * rhs.i
        )
    }
}

enum ConfettiSimulation {
    private static let burstDuration: TimeInterval = 0.3
    private static let fadeDuration: TimeInterval = 0.5

    static func frame(
        for particle: ConfettiParticle,
        elapsed: TimeInterval,
        burstFromCenter: Bool
    ) -> ConfettiParticleFrame {
        let localTime = elapsed - particle.delay
        guard localTime >= 0 else {
            return ConfettiParticleFrame(
                position: CGPoint(x: particle.x, y: particle.y),
                rotation: 0,
                opacity: 0,
                scale: 0
            )
        }

        let rotationProgress = clamp(localTime / particle.duration)
        let rotation = (particle.rotation + 720) * rotationProgress
        let fadeStart = max(0, particle.duration - fadeDuration)
        let fadeProgress = easeIn(
            clamp((localTime - fadeStart) / fadeDuration)
        )

        if burstFromCenter {
            let burstProgress = easeOut(clamp(localTime / burstDuration))
            let gravityProgress = easeIn(
                clamp((localTime - burstDuration) / particle.duration)
            )
            let burstX = particle.horizontalDrift * 0.3
            let burstY = particle.y + particle.verticalVelocity
            let currentX = interpolate(
                from: burstX,
                to: particle.horizontalDrift,
                progress: gravityProgress
            )
            let currentY = interpolate(
                from: burstY,
                to: particle.targetY,
                progress: gravityProgress
            )

            return ConfettiParticleFrame(
                position: CGPoint(
                    x: particle.x + interpolate(from: 0, to: currentX, progress: burstProgress),
                    y: interpolate(from: particle.y, to: currentY, progress: burstProgress)
                ),
                rotation: rotation,
                opacity: min(burstProgress, 1 - fadeProgress),
                scale: CGFloat(burstProgress)
            )
        }

        let fallProgress = easeIn(clamp(localTime / particle.duration))
        return ConfettiParticleFrame(
            position: CGPoint(
                x: particle.x + particle.horizontalDrift * CGFloat(fallProgress),
                y: interpolate(
                    from: particle.y,
                    to: particle.targetY,
                    progress: fallProgress
                )
            ),
            rotation: rotation,
            opacity: min(fallProgress, 1 - fadeProgress),
            scale: CGFloat(fallProgress)
        )
    }

    static func frame(
        for sparkle: SparkleParticle,
        elapsed: TimeInterval
    ) -> ConfettiSparkleFrame {
        let localTime = elapsed - sparkle.delay
        guard localTime >= 0 else {
            return ConfettiSparkleFrame(opacity: 0, scale: 0)
        }

        if localTime < 0.2 {
            let spring = springProgress(elapsed: localTime, response: 0.2, dampingFraction: 0.5)
            return ConfettiSparkleFrame(
                opacity: clamp(spring),
                scale: CGFloat(max(0, spring))
            )
        }

        let popProgress = easeOut(clamp((localTime - 0.2) / sparkle.duration))
        return ConfettiSparkleFrame(
            opacity: 1 - popProgress,
            scale: CGFloat(interpolate(from: 1, to: 1.5, progress: popProgress))
        )
    }

    private static func springProgress(
        elapsed: TimeInterval,
        response: TimeInterval,
        dampingFraction: Double
    ) -> Double {
        let angularFrequency = 2 * Double.pi / response
        let dampedFrequency = angularFrequency * sqrt(1 - dampingFraction * dampingFraction)
        let decay = exp(-dampingFraction * angularFrequency * elapsed)
        let correction = dampingFraction / sqrt(1 - dampingFraction * dampingFraction)
        return 1 - decay * (
            cos(dampedFrequency * elapsed) + correction * sin(dampedFrequency * elapsed)
        )
    }

    private static func easeIn(_ progress: Double) -> Double {
        cubicBezier(progress, control1: CGPoint(x: 0.42, y: 0), control2: CGPoint(x: 1, y: 1))
    }

    private static func easeOut(_ progress: Double) -> Double {
        cubicBezier(progress, control1: CGPoint(x: 0, y: 0), control2: CGPoint(x: 0.58, y: 1))
    }

    /// Solves the timing curve's x component before evaluating y, matching SwiftUI's ease curves.
    private static func cubicBezier(
        _ progress: Double,
        control1: CGPoint,
        control2: CGPoint
    ) -> Double {
        let progress = clamp(progress)
        if progress == 0 || progress == 1 {
            return progress
        }
        var lower = 0.0
        var upper = 1.0
        var parameter = progress
        for _ in 0..<12 {
            parameter = (lower + upper) / 2
            let x = cubicCoordinate(
                parameter,
                firstControl: control1.x,
                secondControl: control2.x
            )
            if x < progress {
                lower = parameter
            } else {
                upper = parameter
            }
        }
        return cubicCoordinate(
            parameter,
            firstControl: control1.y,
            secondControl: control2.y
        )
    }

    private static func cubicCoordinate(
        _ parameter: Double,
        firstControl: CGFloat,
        secondControl: CGFloat
    ) -> Double {
        let inverse = 1 - parameter
        return 3 * inverse * inverse * parameter * Double(firstControl)
            + 3 * inverse * parameter * parameter * Double(secondControl)
            + parameter * parameter * parameter
    }

    private static func clamp(_ value: Double) -> Double {
        min(max(value, 0), 1)
    }

    private static func interpolate(
        from start: CGFloat,
        to end: CGFloat,
        progress: Double
    ) -> CGFloat {
        start + (end - start) * CGFloat(progress)
    }

    private static func interpolate(
        from start: Double,
        to end: Double,
        progress: Double
    ) -> Double {
        start + (end - start) * progress
    }
}

private enum ConfettiRenderer {
    static func draw(
        particles: [ConfettiParticle],
        sparkles: [SparkleParticle],
        elapsed: TimeInterval,
        burstFromCenter: Bool,
        colors: [Color],
        context: inout GraphicsContext
    ) {
        let sourcePointSize = ConfettiSymbolGeometry.sourcePointSize
        let measurementBounds = CGSize(
            width: sourcePointSize * 2,
            height: sourcePointSize * 2
        )
        let resolvedStar = context.resolve(
            Text(Image(systemName: ConfettiSymbolGeometry.starSystemName))
                .font(.system(size: sourcePointSize))
        )
        let starSourceSize = resolvedStar.measure(in: measurementBounds)
        var resolvedSparkle = context.resolve(
            Text(Image(systemName: ConfettiSymbolGeometry.sparkleSystemName))
                .font(.system(size: sourcePointSize))
        )
        resolvedSparkle.shading = .color(AppTheme.accentTertiary)

        for particle in particles {
            let frame = ConfettiSimulation.frame(
                for: particle,
                elapsed: elapsed,
                burstFromCenter: burstFromCenter
            )
            guard frame.opacity > 0.001 else { continue }

            var particleContext = context
            particleContext.opacity = frame.opacity
            let layoutSize = ConfettiSymbolGeometry.layoutSize(
                for: particle,
                starSourceSize: starSourceSize
            )
            let contentScale = particle.shape == .star
                ? particle.size * 0.8 / sourcePointSize
                : 1
            particleContext.addFilter(
                .projectionTransform(
                    ConfettiParticleProjection.transform(
                        rotationDegrees: frame.rotation,
                        scale: frame.scale,
                        layoutSize: layoutSize,
                        anchor: frame.position,
                        contentScale: contentScale
                    )
                )
            )

            if particle.shape == .star {
                var star = resolvedStar
                star.shading = .color(colors[particle.colorIndex])
                particleContext.draw(
                    star,
                    at: frame.position,
                    anchor: .center
                )
            } else {
                particleContext.fill(
                    path(for: particle, centeredAt: frame.position),
                    with: .color(colors[particle.colorIndex])
                )
            }
        }

        for sparkle in sparkles {
            let frame = ConfettiSimulation.frame(for: sparkle, elapsed: elapsed)
            guard frame.opacity > 0.001 else { continue }

            var sparkleContext = context
            sparkleContext.opacity = frame.opacity
            let typographyScale = sparkle.size / sourcePointSize
            sparkleContext.addFilter(
                .projectionTransform(
                    ConfettiParticleProjection.scale(
                        typographyScale,
                        anchor: CGPoint(x: sparkle.x, y: sparkle.y)
                    )
                )
            )
            sparkleContext.addFilter(
                .shadow(color: AppTheme.accentTertiary, radius: 4)
            )
            sparkleContext.addFilter(
                .projectionTransform(
                    ConfettiParticleProjection.scale(
                        frame.scale,
                        anchor: CGPoint(x: sparkle.x, y: sparkle.y)
                    )
                )
            )
            sparkleContext.draw(
                resolvedSparkle,
                at: CGPoint(x: sparkle.x, y: sparkle.y),
                anchor: .center
            )
        }
    }

    private static func path(
        for particle: ConfettiParticle,
        centeredAt center: CGPoint
    ) -> Path {
        switch particle.shape {
        case .rectangle:
            return Path(CGRect(
                x: center.x - particle.size / 2,
                y: center.y - particle.size * 0.3,
                width: particle.size,
                height: particle.size * 0.6
            ))
        case .circle:
            let diameter = particle.size * 0.8
            return Path(ellipseIn: CGRect(
                x: center.x - diameter / 2,
                y: center.y - diameter / 2,
                width: diameter,
                height: diameter
            ))
        case .triangle:
            var path = Path()
            path.move(to: CGPoint(x: center.x, y: center.y - particle.size / 2))
            path.addLine(to: CGPoint(
                x: center.x + particle.size / 2,
                y: center.y + particle.size / 2
            ))
            path.addLine(to: CGPoint(
                x: center.x - particle.size / 2,
                y: center.y + particle.size / 2
            ))
            path.closeSubpath()
            return path
        case .star:
            return Path()
        }
    }
}

// MARK: - Victory Flash Effect

/// Brief screen flash for victory moment
struct VictoryFlashView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var opacity: Double = 0

    var body: some View {
        Color.white
            .opacity(opacity)
            .ignoresSafeArea()
            .allowsHitTesting(false)
            .onAppear {
                guard !reduceMotion else { return }
                // Quick flash
                withAnimation(.easeOut(duration: 0.1)) {
                    opacity = 0.6
                }
                withAnimation(.easeIn(duration: 0.3).delay(0.1)) {
                    opacity = 0
                }
            }
            .onDisappear { opacity = 0 }
    }
}

// MARK: - Star Pop Animation

/// Individual star with pop animation for star reveals
struct StarPopView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let filled: Bool
    let delay: TimeInterval
    let size: CGFloat

    @State private var scale: CGFloat = 0
    @State private var rotation: Double = -30
    @State private var glowOpacity: Double = 0
    @State private var hapticTask: Task<Void, Never>?

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
            if reduceMotion {
                scale = 1
                rotation = 0
                glowOpacity = filled ? 0.4 : 0
                if filled { FeedbackManager.shared.haptic(.starReveal) }
                return
            }
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
                hapticTask = Task { @MainActor in
                    if delay > 0 {
                        try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                    guard !Task.isCancelled else { return }
                    FeedbackManager.shared.haptic(.starReveal)
                    hapticTask = nil
                }
            }
        }
        .onDisappear {
            hapticTask?.cancel()
            hapticTask = nil
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
