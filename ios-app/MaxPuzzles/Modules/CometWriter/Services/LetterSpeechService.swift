import AVFoundation
import Foundation

struct LetterSpeechSegment: Equatable, Sendable {
    let text: String
    let postUtteranceDelay: TimeInterval

    init(_ text: String, postUtteranceDelay: TimeInterval = 0) {
        self.text = text
        self.postUtteranceDelay = postUtteranceDelay
    }
}

@MainActor
final class LetterSpeechService {
    static let shared = LetterSpeechService()

    // Creating the speech engine can be expensive on a cold simulator/device. Keep the visual
    // writing flow instant and pay that cost only when the child actually asks to hear a prompt.
    private var synthesizer: AVSpeechSynthesizer?

    private init() {}

    @discardableResult
    func speak(_ glyph: LetterGlyph) -> Bool {
        speak(Self.lessonSequence(for: glyph))
    }

    @discardableResult
    func speakLetterNamePrompt(for glyph: LetterGlyph) -> Bool {
        speak(Self.letterNamePrompt(for: glyph))
    }

    @discardableResult
    func speakRecallPrompt(for glyph: LetterGlyph) -> Bool {
        speak(Self.recallPrompt(for: glyph))
    }

    @discardableResult
    func speakPathPrompt(for glyph: LetterGlyph, animated: Bool) -> Bool {
        speak(Self.pathPrompt(for: glyph, animated: animated))
    }

    @discardableResult
    func speakWordPrompt(
        for glyph: LetterGlyph,
        word: String,
        introduction: String,
        contextSentence: String?
    ) -> Bool {
        return speak(
            Self.wordPrompt(
                for: glyph,
                word: word,
                introduction: introduction,
                contextSentence: contextSentence
            )
        )
    }

    @discardableResult
    func speakSpellingPrompt(for word: String, contextSentence: String?) -> Bool {
        speak(Self.spellingPrompt(for: word, contextSentence: contextSentence))
    }

    nonisolated static func lessonPrompt(for glyph: LetterGlyph) -> String {
        lessonSequence(for: glyph).map(\.text).joined(separator: " ")
    }

    /// Separate queued utterances keep the repeated letter names intelligible to young children.
    /// Punctuation alone is voice-dependent and can collapse "Letter C. C is for cat" into a
    /// single run of sound, so the introduction owns an explicit post-utterance pause. Keep the
    /// example as its own exact phrase; formation guidance is presented separately in the UI.
    nonisolated static func lessonSequence(for glyph: LetterGlyph) -> [LetterSpeechSegment] {
        let introduction = glyph.isNumber
            ? "Number \(glyph.character)."
            : "Letter \(glyph.character)."
        return [
            LetterSpeechSegment(
                introduction,
                postUtteranceDelay: lessonIntroductionPause
            ),
            LetterSpeechSegment("\(glyph.promptTitle).")
        ]
    }

    nonisolated static var lessonIntroductionPause: TimeInterval {
        0.45
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

    @discardableResult
    func speak(_ words: String) -> Bool {
        speak([LetterSpeechSegment(words)])
    }

    @discardableResult
    private func speak(_ segments: [LetterSpeechSegment]) -> Bool {
        let storage = StorageService.shared
        guard storage.isVoiceEnabled, !segments.isEmpty else { return false }

        let synthesizer = speechEngine()
        synthesizer.stopSpeaking(at: .immediate)

        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else { return false }
        for segment in segments {
            let utterance = AVSpeechUtterance(string: segment.text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.43
            utterance.pitchMultiplier = 1.05
            utterance.volume = storage.voiceVolume
            utterance.postUtteranceDelay = segment.postUtteranceDelay
            synthesizer.speak(utterance)
        }
        return true
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
