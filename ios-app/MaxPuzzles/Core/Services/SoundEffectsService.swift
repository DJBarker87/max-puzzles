import SwiftUI
import AVFoundation
import AudioToolbox

// MARK: - Sound Effect Types

enum SoundEffect: String, CaseIterable {
    // UI Interactions
    case buttonTap = "button_tap"
    case buttonPress = "button_press"
    case cardTap = "card_tap"
    case swipe = "swipe"

    // Game Events
    case cellTap = "cell_tap"
    case correctMove = "correct_move"
    case wrongMove = "wrong_move"
    case levelComplete = "level_complete"
    case levelFail = "level_fail"

    // Rewards
    case starReveal = "star_reveal"
    case coinCollect = "coin_collect"
    case coinBonus = "coin_bonus"

    // Special
    case countdown = "countdown"
    case timerWarning = "timer_warning"
    case unlock = "unlock"
}

// MARK: - Sound Effects Service

/// Manages UI sound effects for premium feel
/// Uses system sounds and synthesized audio for responsive feedback
@MainActor
class SoundEffectsService: ObservableObject {

    // MARK: - Singleton

    static let shared = SoundEffectsService()

    // MARK: - Published State

    @Published var isEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: "soundEffectsEnabled")
        }
    }

    @Published var volume: Float = 0.7 {
        didSet {
            UserDefaults.standard.set(volume, forKey: "soundEffectsVolume")
        }
    }

    // MARK: - Private Properties

    private var audioEngine: AVAudioEngine?
    private var playerNodes: [SoundEffect: AVAudioPlayerNode] = [:]
    private var audioBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]

    // Pre-loaded audio players for custom sounds
    private var audioPlayers: [SoundEffect: AVAudioPlayer] = [:]

    // MARK: - Initialization

    private init() {
        isEnabled = UserDefaults.standard.object(forKey: "soundEffectsEnabled") as? Bool ?? true
        volume = UserDefaults.standard.object(forKey: "soundEffectsVolume") as? Float ?? 0.7

        setupAudioSession()
        generateSynthesizedSounds()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            // Use playback to ensure audio works, mix with others for flexibility
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
            print("🔊 SoundEffects audio session configured")
        } catch {
            print("❌ Failed to setup audio session: \(error)")
        }
    }

    // MARK: - Play Sound

    /// Play a sound effect
    func play(_ effect: SoundEffect) {
        guard isEnabled else { return }

        // Use system sounds for immediate feedback
        switch effect {
        case .buttonTap, .buttonPress:
            playSystemSound(.tap)
        case .cellTap:
            playSystemSound(.peek)
        case .correctMove:
            playSystemSound(.success)
        case .wrongMove:
            playSystemSound(.error)
        case .starReveal:
            playSystemSound(.pop)
        case .coinCollect:
            playSystemSound(.coin)
        case .levelComplete:
            playSystemSound(.fanfare)
        case .levelFail:
            playSystemSound(.fail)
        case .swipe:
            playSystemSound(.swipe)
        case .cardTap:
            playSystemSound(.tap)
        case .countdown:
            playSystemSound(.tick)
        case .timerWarning:
            playSystemSound(.warning)
        case .unlock:
            playSystemSound(.unlock)
        case .coinBonus:
            playSystemSound(.bonus)
        }
    }

    /// Play with delay (for sequential effects like star reveals)
    func play(_ effect: SoundEffect, delay: TimeInterval) {
        guard isEnabled else { return }

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.play(effect)
        }
    }

    /// Play star reveal sequence (3 stars with delays)
    func playStarSequence(count: Int, baseDelay: TimeInterval = 0.3) {
        guard isEnabled else { return }

        for i in 0..<min(count, 3) {
            play(.starReveal, delay: baseDelay + Double(i) * 0.25)
        }
    }

    // MARK: - System Sounds

    private enum SystemSound: UInt32 {
        case tap = 1104       // Light tap
        case peek = 1519      // Peek
        case pop = 1520       // Pop
        case success = 1057   // Mail sent (cheerful)
        case error = 1073     // Alert buzz
        case coin = 1054      // Payment success
        case fanfare = 1025   // SMS received (can use as fanfare)
        case fail = 1074      // Alert (different from error)
        case swipe = 1105     // Swipe
        case tick = 1103      // Tick
        case warning = 1071   // Warning
        case unlock = 1111    // Lock
        case bonus = 1117     // Begin recording (shimmer)
    }

    private func playSystemSound(_ sound: SystemSound) {
        AudioServicesPlaySystemSound(sound.rawValue)
    }

    // MARK: - Synthesized Sounds

    private func generateSynthesizedSounds() {
        // Future: Generate custom synthesized sounds using AVAudioEngine
        // For now, system sounds provide immediate feedback
    }
}

// MARK: - View Extension

extension View {
    /// Play sound on tap
    func soundOnTap(_ effect: SoundEffect) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in
                Task { @MainActor in
                    SoundEffectsService.shared.play(effect)
                }
            }
        )
    }
}
