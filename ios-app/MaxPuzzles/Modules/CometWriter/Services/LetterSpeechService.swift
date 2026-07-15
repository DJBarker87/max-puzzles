import AVFoundation
import Foundation

@MainActor
final class LetterSpeechService {
    static let shared = LetterSpeechService()

    // Creating the speech engine can be expensive on a cold simulator/device. Keep the visual
    // writing flow instant and pay that cost only when the child actually asks to hear a prompt.
    private var synthesizer: AVSpeechSynthesizer?

    private init() {}

    func speak(_ glyph: LetterGlyph) {
        speak(glyph.spokenPrompt)
    }

    func speak(_ words: String) {
        let storage = StorageService.shared
        guard storage.isVoiceEnabled else { return }

        let synthesizer = speechEngine()
        synthesizer.stopSpeaking(at: .immediate)

        let utterance = AVSpeechUtterance(string: words)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.05
        utterance.volume = storage.voiceVolume
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer?.stopSpeaking(at: .immediate)
    }

    private func speechEngine() -> AVSpeechSynthesizer {
        if let synthesizer { return synthesizer }
        let engine = AVSpeechSynthesizer()
        synthesizer = engine
        return engine
    }
}
