import SwiftUI
import Combine

// MARK: - FeedbackManager

/// Manages visual feedback for game events (screen shake)
@MainActor
class FeedbackManager: ObservableObject {
    // MARK: - Published State

    @Published private(set) var isShaking: Bool = false
    @Published private(set) var shakeAmount: CGFloat = 0

    // MARK: - Private

    private var shakeTimer: AnyCancellable?

    // MARK: - Screen Shake

    /// Trigger screen shake animation for wrong moves
    func triggerShake() {
        isShaking = true
        shakeAmount = 1

        // Auto-reset after 300ms (matches web app)
        shakeTimer?.cancel()
        shakeTimer = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.isShaking = false
                self?.shakeAmount = 0
            }
    }

    /// View modifier offset for shake animation
    var shakeOffset: CGFloat {
        isShaking ? 8 : 0
    }
}

// MARK: - Shake Effect Modifier

/// View modifier that applies shake effect
struct ShakeEffect: GeometryEffect {
    var amount: CGFloat = 8
    var shakesPerUnit: CGFloat = 3
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        let translation = amount * sin(animatableData * .pi * shakesPerUnit)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}

extension View {
    /// Apply shake animation when isShaking is true
    func shake(isShaking: Bool) -> some View {
        self.modifier(ShakeEffect(animatableData: isShaking ? 1 : 0))
            .animation(.linear(duration: 0.3), value: isShaking)
    }

    /// Apply shake with custom amount
    func shake(amount: CGFloat) -> some View {
        self.modifier(ShakeEffect(animatableData: amount))
            .animation(.linear(duration: 0.3), value: amount)
    }
}

// MARK: - Preview

#Preview("Shake Effect") {
    struct ShakeDemo: View {
        @State private var isShaking = false

        var body: some View {
            VStack(spacing: 40) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue)
                    .frame(width: 200, height: 100)
                    .shake(isShaking: isShaking)

                Button("Trigger Shake") {
                    isShaking = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isShaking = false
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    return ShakeDemo()
}
