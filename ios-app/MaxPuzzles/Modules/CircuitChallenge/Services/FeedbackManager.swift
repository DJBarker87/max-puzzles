import SwiftUI
import Combine
import CoreHaptics
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Haptic Type

enum HapticType {
    case light
    case medium
    case heavy
    case soft
    case rigid
    case selection
    case success
    case warning
    case error

    // Custom patterns
    case buttonPress
    case buttonRelease
    case cellTap
    case correctMove
    case wrongMove
    case starReveal
    case coinCollect
    case levelComplete
    case levelFail
    case carouselTick
}

// MARK: - FeedbackManager

/// Manages visual and haptic feedback for game events
@MainActor
class FeedbackManager: ObservableObject {

    // MARK: - Singleton

    static let shared = FeedbackManager()

    // MARK: - Published State

    @Published private(set) var isShaking: Bool = false
    @Published private(set) var shakeAmount: CGFloat = 0
    @Published var hapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled")
        }
    }

    // MARK: - Private

    private var shakeTimer: AnyCancellable?
    private var hapticEngine: CHHapticEngine?
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactMedium = UIImpactFeedbackGenerator(style: .medium)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)
    private let impactSoft = UIImpactFeedbackGenerator(style: .soft)
    private let impactRigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionFeedback = UISelectionFeedbackGenerator()
    private let notificationFeedback = UINotificationFeedbackGenerator()

    // MARK: - Initialization

    private init() {
        self.hapticsEnabled = UserDefaults.standard.object(forKey: "hapticsEnabled") as? Bool ?? true
        prepareHaptics()
        setupHapticEngine()
    }

    // MARK: - Haptic Engine Setup

    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()

            // Restart engine if it stops
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason)")
                Task { @MainActor in
                    self?.restartHapticEngine()
                }
            }

            hapticEngine?.resetHandler = { [weak self] in
                Task { @MainActor in
                    self?.restartHapticEngine()
                }
            }
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }

    private func restartHapticEngine() {
        do {
            try hapticEngine?.start()
        } catch {
            print("Failed to restart haptic engine: \(error)")
        }
    }

    private func prepareHaptics() {
        impactLight.prepare()
        impactMedium.prepare()
        impactHeavy.prepare()
        impactSoft.prepare()
        impactRigid.prepare()
        selectionFeedback.prepare()
        notificationFeedback.prepare()
    }

    // MARK: - Play Haptic

    /// Play a haptic feedback
    func haptic(_ type: HapticType) {
        guard hapticsEnabled else { return }

        switch type {
        case .light:
            impactLight.impactOccurred()
        case .medium:
            impactMedium.impactOccurred()
        case .heavy:
            impactHeavy.impactOccurred()
        case .soft:
            impactSoft.impactOccurred()
        case .rigid:
            impactRigid.impactOccurred()
        case .selection:
            selectionFeedback.selectionChanged()
        case .success:
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            notificationFeedback.notificationOccurred(.error)

        // Custom patterns
        case .buttonPress:
            impactLight.impactOccurred(intensity: 0.6)
        case .buttonRelease:
            impactSoft.impactOccurred(intensity: 0.4)
        case .cellTap:
            impactLight.impactOccurred(intensity: 0.5)
        case .correctMove:
            playCustomPattern(.correctMove)
        case .wrongMove:
            playCustomPattern(.wrongMove)
        case .starReveal:
            playCustomPattern(.starReveal)
        case .coinCollect:
            impactMedium.impactOccurred(intensity: 0.7)
        case .levelComplete:
            playCustomPattern(.levelComplete)
        case .levelFail:
            playCustomPattern(.levelFail)
        case .carouselTick:
            selectionFeedback.selectionChanged()
        }
    }

    /// Play haptic with delay
    func haptic(_ type: HapticType, delay: TimeInterval) {
        guard hapticsEnabled else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.haptic(type)
        }
    }

    // MARK: - Custom Haptic Patterns

    private func playCustomPattern(_ type: HapticType) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let engine = hapticEngine else {
            // Fallback to simple haptics
            fallbackHaptic(for: type)
            return
        }

        do {
            let pattern = try createPattern(for: type)
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            fallbackHaptic(for: type)
        }
    }

    private func createPattern(for type: HapticType) throws -> CHHapticPattern {
        var events: [CHHapticEvent] = []

        switch type {
        case .correctMove:
            // Quick double tap - success feel
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ))
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
                ],
                relativeTime: 0.08
            ))

        case .wrongMove:
            // Buzz pattern - error feel
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                ],
                relativeTime: 0,
                duration: 0.15
            ))

        case .starReveal:
            // Pop with sparkle
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.6)
                ],
                relativeTime: 0
            ))

        case .levelComplete:
            // Celebration pattern - triple pulse
            for i in 0..<3 {
                let intensity = Float(0.9 - Double(i) * 0.15)
                events.append(CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.4)
                    ],
                    relativeTime: Double(i) * 0.12
                ))
            }

        case .levelFail:
            // Heavy thud
            events.append(CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
                ],
                relativeTime: 0,
                duration: 0.2
            ))

        default:
            // Default single tap
            events.append(CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [
                    CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                    CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
                ],
                relativeTime: 0
            ))
        }

        return try CHHapticPattern(events: events, parameters: [])
    }

    private func fallbackHaptic(for type: HapticType) {
        switch type {
        case .correctMove, .starReveal:
            notificationFeedback.notificationOccurred(.success)
        case .wrongMove, .levelFail:
            notificationFeedback.notificationOccurred(.error)
        case .levelComplete:
            // Triple success
            notificationFeedback.notificationOccurred(.success)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
                self?.notificationFeedback.notificationOccurred(.success)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.24) { [weak self] in
                self?.notificationFeedback.notificationOccurred(.success)
            }
        default:
            impactMedium.impactOccurred()
        }
    }

    // MARK: - Screen Shake

    /// Trigger screen shake animation for wrong moves
    func triggerShake() {
        isShaking = true
        shakeAmount = 1

        // Also trigger haptic
        haptic(.wrongMove)

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
