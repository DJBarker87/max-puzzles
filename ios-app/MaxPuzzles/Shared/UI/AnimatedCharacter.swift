import SwiftUI

/// Animation style for character images
enum CharacterAnimation {
    case boxer      // Celebration: bounce in + punch motion + bob
    case octopus    // Floating: drift in + gentle bob + slow rotation
}

/// Animated character image for win/lose screens
struct AnimatedCharacter: View {
    let imageName: String
    let animation: CharacterAnimation
    let size: CGFloat

    @State private var appeared = false
    @State private var floatOffset: CGFloat = 0
    @State private var rotation: Double = 0
    @State private var punchOffset: CGFloat = 0
    @State private var bounceScale: CGFloat = 0.3

    var body: some View {
        Image(imageName)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(animation == .boxer ? bounceScale : (appeared ? 1.0 : 0.5))
            .offset(x: animation == .boxer ? punchOffset : 0)
            .offset(y: animation == .octopus ? floatOffset : 0)
            .rotationEffect(animation == .octopus ? .degrees(rotation) : .zero)
            .opacity(animation == .octopus ? (appeared ? 1.0 : 0.0) : 1.0)
            .onAppear {
                startAnimations()
            }
    }

    // MARK: - Animations

    private func startAnimations() {
        switch animation {
        case .boxer:
            startBoxerAnimation()
        case .octopus:
            startOctopusAnimation()
        }
    }

    private func startBoxerAnimation() {
        // Initial bounce in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
            bounceScale = 1.0
        }

        // Victory punch motion (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 0.15)) {
                punchOffset = 15
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    punchOffset = 0
                }
            }
        }

        // Continuous subtle bob
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                bounceScale = 1.05
            }
        }
    }

    private func startOctopusAnimation() {
        // Float in from above
        floatOffset = -30

        withAnimation(.spring(response: 0.8, dampingFraction: 0.7)) {
            appeared = true
            floatOffset = 0
        }

        // Continuous floating bob
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                floatOffset = 12
            }
        }

        // Gentle rotation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                rotation = 8
            }
        }
    }
}

// MARK: - Convenience Initializers

extension AnimatedCharacter {
    /// Boxer character for win screens
    static func boxer(size: CGFloat = 140) -> AnimatedCharacter {
        AnimatedCharacter(imageName: "boxer", animation: .boxer, size: size)
    }

    /// Space octopus character for lose screens
    static func spaceOctopus(size: CGFloat = 140) -> AnimatedCharacter {
        AnimatedCharacter(imageName: "space-octopus", animation: .octopus, size: size)
    }
}

// MARK: - Preview

#Preview("Boxer (Win)") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        AnimatedCharacter.boxer(size: 300)
    }
}

#Preview("Space Octopus (Lose)") {
    ZStack {
        Color(hex: "0f0f23").ignoresSafeArea()
        AnimatedCharacter.spaceOctopus(size: 300)
    }
}
