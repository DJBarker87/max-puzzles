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
        speak(Self.lessonPrompt(for: glyph))
    }

    func speakLetterNamePrompt(for glyph: LetterGlyph) {
        speak(Self.letterNamePrompt(for: glyph))
    }

    func speakRecallPrompt(for glyph: LetterGlyph) {
        speak(Self.recallPrompt(for: glyph))
    }

    func speakPathPrompt(for glyph: LetterGlyph, animated: Bool) {
        speak(Self.pathPrompt(for: glyph, animated: animated))
    }

    func speakWordPrompt(
        for glyph: LetterGlyph,
        word: String,
        introduction: String,
        contextSentence: String?
    ) {
        speak(
            Self.wordPrompt(
                for: glyph,
                word: word,
                introduction: introduction,
                contextSentence: contextSentence
            )
        )
    }

    func speakSpellingPrompt(for word: String, contextSentence: String?) {
        speak(Self.spellingPrompt(for: word, contextSentence: contextSentence))
    }

    nonisolated static func lessonPrompt(for glyph: LetterGlyph) -> String {
        glyph.spokenPrompt
    }

    nonisolated static func letterNamePrompt(for glyph: LetterGlyph) -> String {
        if glyph.isNumber {
            return "Listen for the number name. Number \(glyph.character). Write \(glyph.character)."
        }
        return "Listen for the letter name. Letter \(glyph.character). Write \(glyph.character)."
    }

    nonisolated static func recallPrompt(for glyph: LetterGlyph) -> String {
        if glyph.isNumber {
            return "Write number \(glyph.character)."
        }
        return "Write the letter \(glyph.character). \(glyph.exampleWord) starts with the letter \(glyph.character)."
    }

    nonisolated static func pathPrompt(for glyph: LetterGlyph, animated: Bool) -> String {
        animated
            ? "Watch the comet write \(glyph.character), then have a go."
            : "The path for \(glyph.character) is shown. Start at the green star and follow the arrows."
    }

    nonisolated static func wordPrompt(
        for glyph: LetterGlyph,
        word: String,
        introduction: String,
        contextSentence: String?
    ) -> String {
        let context = contextSentence.map { " Example: \($0)" } ?? ""
        return "\(introduction) \(word).\(context) Write it on one line. Now write \(glyph.character)."
    }

    nonisolated static func spellingPrompt(
        for word: String,
        contextSentence: String?
    ) -> String {
        let context = contextSentence.map { " \($0)" } ?? ""
        return "Spell the word \(word).\(context)"
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
        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else { return }
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
