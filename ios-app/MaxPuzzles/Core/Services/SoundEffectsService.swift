import AVFoundation
import SwiftUI

enum SoundEffect: String, CaseIterable {
    case buttonTap = "button_tap"
    case buttonPress = "button_press"
    case cardTap = "card_tap"
    case swipe = "swipe"
    case cellTap = "cell_tap"
    case correctMove = "correct_move"
    case wrongMove = "wrong_move"
    case levelComplete = "level_complete"
    case levelFail = "level_fail"
    case starReveal = "star_reveal"
    case coinCollect = "coin_collect"
    case coinBonus = "coin_bonus"
    case countdown = "countdown"
    case timerWarning = "timer_warning"
    case unlock = "unlock"
}

/// Small, locally-synthesised effects that respect the app's audio controls and the silent switch.
/// The audio engine is created only after the first enabled effect, avoiding launch-time work.
@MainActor
final class SoundEffectsService {
    static let shared = SoundEffectsService()

    private let storage = StorageService.shared
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var audioFormat: AVAudioFormat?
    private var audioBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    private var delayedTasks: [UUID: Task<Void, Never>] = [:]
    private var bufferWarmTask: Task<Void, Never>?
    private var requestedBufferTask: Task<Void, Never>?
    private var idleShutdownTask: Task<Void, Never>?
    private var activePlaybackID: UUID?
    private var latestImmediateRequestID: UUID?

    var isEnabled: Bool {
        get { storage.isSoundEnabled }
        set {
            storage.setSoundEnabled(newValue)
            if !newValue {
                suspend()
            }
        }
    }

    var volume: Float {
        get { storage.soundEffectsVolume }
        set {
            storage.setSoundEffectsVolume(newValue)
            audioEngine?.mainMixerNode.outputVolume = outputVolume
        }
    }

    private var outputVolume: Float {
        min(max(storage.soundEffectsVolume, 0), 1) * 0.42
    }

    private init() {}

    func play(_ effect: SoundEffect) {
        idleShutdownTask?.cancel()
        idleShutdownTask = nil
        guard isEnabled, ensureAudioEngine() else { return }

        activePlaybackID = nil
        playerNode?.stop()
        let requestID = UUID()
        latestImmediateRequestID = requestID
        if audioBuffers[effect] != nil {
            playPrepared(effect, requestID: requestID)
        } else {
            prepareRequestedBuffer(for: effect, requestID: requestID)
        }
    }

    /// Stops scheduled and active effects and releases the running render graph. The prepared
    /// buffers remain cached, so the next enabled effect can restart without regenerating audio.
    func suspend() {
        cancelScheduledEffects()
        bufferWarmTask?.cancel()
        bufferWarmTask = nil
        requestedBufferTask?.cancel()
        requestedBufferTask = nil
        idleShutdownTask?.cancel()
        idleShutdownTask = nil
        activePlaybackID = nil
        latestImmediateRequestID = nil
        playerNode?.stop()
        audioEngine?.stop()
    }

    func play(_ effect: SoundEffect, delay: TimeInterval) {
        guard isEnabled else { return }
        guard delay > 0 else {
            play(effect)
            return
        }
        let id = UUID()
        delayedTasks[id] = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            self?.play(effect)
            self?.delayedTasks[id] = nil
        }
    }

    func playStarSequence(count: Int, baseDelay: TimeInterval = 0.3) {
        guard isEnabled else { return }
        for index in 0..<min(count, 3) {
            play(.starReveal, delay: baseDelay + Double(index) * 0.25)
        }
    }

    private func ensureAudioEngine() -> Bool {
        guard AppAudioSessionCoordinator.shared.prepareForSoundEffects() else { return false }

        if audioEngine == nil {
            let engine = AVAudioEngine()
            let node = AVAudioPlayerNode()
            guard let format = AVAudioFormat(
                standardFormatWithSampleRate: 44_100,
                channels: 1
            ) else {
                return false
            }

            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            engine.mainMixerNode.outputVolume = outputVolume
            engine.prepare()
            audioEngine = engine
            playerNode = node
            audioFormat = format
        }

        if audioEngine?.isRunning == true {
            return true
        }

        do {
            try audioEngine?.start()
            return audioEngine?.isRunning == true
        } catch {
            return false
        }
    }

    private func cancelScheduledEffects() {
        for task in delayedTasks.values {
            task.cancel()
        }
        delayedTasks.removeAll()
    }

    private func finishPlayback(_ playbackID: UUID) {
        guard activePlaybackID == playbackID else { return }
        activePlaybackID = nil
        playerNode?.stop()
        scheduleIdleShutdown()
    }

    private func playPrepared(_ effect: SoundEffect, requestID: UUID) {
        guard latestImmediateRequestID == requestID,
              isEnabled,
              let node = playerNode,
              let buffer = audioBuffers[effect] else { return }

        let playbackID = UUID()
        activePlaybackID = playbackID
        node.scheduleBuffer(buffer, at: nil, options: .interrupts) { [weak self] in
            Task { @MainActor [weak self] in
                self?.finishPlayback(playbackID)
            }
        }
        node.play()
        warmRemainingBuffers()
    }

    private func prepareRequestedBuffer(for effect: SoundEffect, requestID: UUID) {
        requestedBufferTask?.cancel()
        guard let format = audioFormat else { return }
        let tone = Self.tone(for: effect)
        let sampleRate = format.sampleRate

        requestedBufferTask = Task { @MainActor [weak self] in
            let samples = await Task.detached(priority: .userInitiated) {
                Self.samples(for: tone, sampleRate: sampleRate)
            }.value
            guard let self,
                  !Task.isCancelled,
                  self.latestImmediateRequestID == requestID else { return }
            if self.audioBuffers[effect] == nil,
               let buffer = self.makeBuffer(samples: samples, format: format) {
                self.audioBuffers[effect] = buffer
            }
            self.requestedBufferTask = nil
            self.playPrepared(effect, requestID: requestID)
        }
    }

    /// Generate the remaining tiny PCM buffers one at a time across run-loop turns. The first
    /// tap pays only for the sound it requested, while later effects retain the exact samples
    /// and stay allocation-free.
    private func warmRemainingBuffers() {
        guard bufferWarmTask == nil, let format = audioFormat else { return }
        bufferWarmTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for effect in SoundEffect.allCases where self.audioBuffers[effect] == nil {
                guard !Task.isCancelled, self.isEnabled else { break }
                await Task.yield()
                guard !Task.isCancelled else { break }
                let tone = Self.tone(for: effect)
                let sampleRate = format.sampleRate
                let samples = await Task.detached(priority: .utility) {
                    Self.samples(for: tone, sampleRate: sampleRate)
                }.value
                guard !Task.isCancelled else { break }
                if let buffer = self.makeBuffer(samples: samples, format: format) {
                    self.audioBuffers[effect] = buffer
                }
            }
            self.bufferWarmTask = nil
        }
    }

    /// Keep the prepared render graph alive across bursts of taps, then release its audio thread
    /// once the interaction has genuinely gone idle.
    private func scheduleIdleShutdown() {
        idleShutdownTask?.cancel()
        idleShutdownTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(nanoseconds: 8_000_000_000)
            } catch {
                return
            }
            guard let self, self.activePlaybackID == nil else { return }
            self.audioEngine?.stop()
            self.idleShutdownTask = nil
        }
    }

    private struct Tone: Sendable {
        let duration: TimeInterval
        let startFrequency: Double
        let endFrequency: Double
        let amplitude: Double
    }

    private nonisolated static func tone(for effect: SoundEffect) -> Tone {
        switch effect {
        case .buttonTap: return Tone(duration: 0.045, startFrequency: 570, endFrequency: 520, amplitude: 0.12)
        case .buttonPress: return Tone(duration: 0.055, startFrequency: 520, endFrequency: 470, amplitude: 0.13)
        case .cardTap: return Tone(duration: 0.075, startFrequency: 480, endFrequency: 620, amplitude: 0.13)
        case .swipe: return Tone(duration: 0.09, startFrequency: 620, endFrequency: 430, amplitude: 0.10)
        case .cellTap: return Tone(duration: 0.055, startFrequency: 430, endFrequency: 470, amplitude: 0.12)
        case .correctMove: return Tone(duration: 0.13, startFrequency: 620, endFrequency: 880, amplitude: 0.16)
        case .wrongMove: return Tone(duration: 0.14, startFrequency: 330, endFrequency: 270, amplitude: 0.13)
        case .levelComplete: return Tone(duration: 0.32, startFrequency: 520, endFrequency: 1_040, amplitude: 0.18)
        case .levelFail: return Tone(duration: 0.22, startFrequency: 280, endFrequency: 220, amplitude: 0.13)
        case .starReveal: return Tone(duration: 0.14, startFrequency: 740, endFrequency: 1_100, amplitude: 0.16)
        case .coinCollect: return Tone(duration: 0.10, startFrequency: 900, endFrequency: 1_280, amplitude: 0.15)
        case .coinBonus: return Tone(duration: 0.20, startFrequency: 760, endFrequency: 1_360, amplitude: 0.17)
        case .countdown: return Tone(duration: 0.07, startFrequency: 460, endFrequency: 460, amplitude: 0.11)
        case .timerWarning: return Tone(duration: 0.11, startFrequency: 380, endFrequency: 320, amplitude: 0.12)
        case .unlock: return Tone(duration: 0.18, startFrequency: 640, endFrequency: 960, amplitude: 0.15)
        }
    }

    private nonisolated static func samples(
        for tone: Tone,
        sampleRate: Double
    ) -> [Float] {
        let frameCount = Int(AVAudioFrameCount(sampleRate * tone.duration))
        guard frameCount > 0 else { return [] }
        var samples = [Float](repeating: 0, count: frameCount)
        var phase = 0.0
        for frame in 0..<frameCount {
            let progress = Double(frame) / Double(max(frameCount - 1, 1))
            let frequency = tone.startFrequency
                + (tone.endFrequency - tone.startFrequency) * progress
            phase += 2 * Double.pi * frequency / sampleRate

            let attack = min(1, progress / 0.08)
            let release = pow(max(0, 1 - progress), 2.4)
            let envelope = attack * release
            let roundedTone = sin(phase) + 0.10 * sin(phase * 2)
            samples[frame] = Float(tone.amplitude * envelope * roundedTone)
        }
        return samples
    }

    private func makeBuffer(
        samples sourceSamples: [Float],
        format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sourceSamples.count)
        guard frameCount > 0,
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?[0] else {
            return nil
        }

        sourceSamples.withUnsafeBufferPointer { source in
            guard let baseAddress = source.baseAddress else { return }
            samples.update(from: baseAddress, count: sourceSamples.count)
        }

        buffer.frameLength = frameCount
        return buffer
    }
}

extension View {
    func soundOnTap(_ effect: SoundEffect) -> some View {
        simultaneousGesture(
            TapGesture().onEnded { _ in
                Task { @MainActor in
                    SoundEffectsService.shared.play(effect)
                }
            }
        )
    }
}
