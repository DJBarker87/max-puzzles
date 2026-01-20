import SwiftUI

/// Animation style presets for alien characters
enum AlienAnimationStyle {
    case float      // Gentle floating up/down
    case bounce     // More energetic bouncing
    case breathe    // Subtle scale pulsing (breathing)
    case wiggle     // Side-to-side wiggle
}

/// View modifier that adds idle animation to alien character images
struct AlienIdleAnimationModifier: ViewModifier {
    let style: AlienAnimationStyle
    let intensity: CGFloat

    @State private var animationPhase: CGFloat = 0
    @State private var isAnimating = false

    init(style: AlienAnimationStyle = .float, intensity: CGFloat = 1.0) {
        self.style = style
        self.intensity = intensity
    }

    func body(content: Content) -> some View {
        content
            .offset(y: yOffset)
            .offset(x: xOffset)
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                startAnimation()
            }
    }

    // MARK: - Animation Values

    private var yOffset: CGFloat {
        switch style {
        case .float:
            return sin(animationPhase * .pi * 2) * 6 * intensity
        case .bounce:
            // Use absolute value for bouncing effect
            return -abs(sin(animationPhase * .pi * 2)) * 10 * intensity
        case .breathe, .wiggle:
            return 0
        }
    }

    private var xOffset: CGFloat {
        switch style {
        case .wiggle:
            return sin(animationPhase * .pi * 2) * 4 * intensity
        default:
            return 0
        }
    }

    private var scale: CGFloat {
        switch style {
        case .breathe:
            return 1.0 + sin(animationPhase * .pi * 2) * 0.03 * intensity
        case .bounce:
            // Slight squash/stretch during bounce
            let squash = sin(animationPhase * .pi * 2)
            return 1.0 + squash * 0.02 * intensity
        default:
            return 1.0
        }
    }

    private var rotation: Double {
        switch style {
        case .float:
            // Very subtle rotation while floating
            return sin(animationPhase * .pi * 2) * 2 * Double(intensity)
        case .wiggle:
            return sin(animationPhase * .pi * 4) * 3 * Double(intensity)
        default:
            return 0
        }
    }

    // MARK: - Animation Control

    private func startAnimation() {
        guard !isAnimating else { return }
        isAnimating = true

        let duration: Double
        switch style {
        case .float:
            duration = 3.0
        case .bounce:
            duration = 1.2
        case .breathe:
            duration = 4.0
        case .wiggle:
            duration = 2.0
        }

        withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
            animationPhase = 1.0
        }
    }
}

// MARK: - View Extension

extension View {
    /// Adds idle animation to the view (designed for alien character images)
    func alienIdleAnimation(style: AlienAnimationStyle = .float, intensity: CGFloat = 1.0) -> some View {
        modifier(AlienIdleAnimationModifier(style: style, intensity: intensity))
    }
}

// MARK: - Animated Alien Image View

/// Convenience view for displaying an alien image with idle animation
struct AnimatedAlienImage: View {
    let imageName: String
    let size: CGFloat
    let style: AlienAnimationStyle
    let intensity: CGFloat

    init(imageName: String, size: CGFloat = 100, style: AlienAnimationStyle = .float, intensity: CGFloat = 1.0) {
        self.imageName = imageName
        self.size = size
        self.style = style
        self.intensity = intensity
    }

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .alienIdleAnimation(style: style, intensity: intensity)
    }
}

// MARK: - ChapterAlien Extension

extension ChapterAlien {
    /// Returns an animated image view for this alien
    func animatedImage(size: CGFloat = 100, style: AlienAnimationStyle = .float, intensity: CGFloat = 1.0) -> AnimatedAlienImage {
        AnimatedAlienImage(imageName: imageName, size: size, style: style, intensity: intensity)
    }
}

// MARK: - Previews

#Preview("Float Animation") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedAlienImage(imageName: "alien_bob", size: 150, style: .float)
            Text("Float")
                .foregroundColor(.white)
        }
    }
}

#Preview("Bounce Animation") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedAlienImage(imageName: "alien_fuzz", size: 150, style: .bounce)
            Text("Bounce")
                .foregroundColor(.white)
        }
    }
}

#Preview("Breathe Animation") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedAlienImage(imageName: "alien_drift", size: 150, style: .breathe)
            Text("Breathe")
                .foregroundColor(.white)
        }
    }
}

#Preview("Wiggle Animation") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        VStack(spacing: 40) {
            AnimatedAlienImage(imageName: "alien_blink", size: 150, style: .wiggle)
            Text("Wiggle")
                .foregroundColor(.white)
        }
    }
}

#Preview("All Animations") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        HStack(spacing: 20) {
            VStack {
                AnimatedAlienImage(imageName: "alien_bob", size: 80, style: .float)
                Text("Float").font(.caption).foregroundColor(.white)
            }
            VStack {
                AnimatedAlienImage(imageName: "alien_fuzz", size: 80, style: .bounce)
                Text("Bounce").font(.caption).foregroundColor(.white)
            }
            VStack {
                AnimatedAlienImage(imageName: "alien_drift", size: 80, style: .breathe)
                Text("Breathe").font(.caption).foregroundColor(.white)
            }
            VStack {
                AnimatedAlienImage(imageName: "alien_blink", size: 80, style: .wiggle)
                Text("Wiggle").font(.caption).foregroundColor(.white)
            }
        }
    }
}
