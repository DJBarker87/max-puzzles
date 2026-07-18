import AVFoundation
import Combine
import Foundation

/// Parent-authored context is optional enrichment, never a reason to send a bare grapheme to a
/// speech engine. A and I remain valid one-letter words; every other standalone English letter is
/// rejected with the whole context so callers cannot accidentally turn it into a letter name.
enum SpokenPromptContextSanitizer {
    nonisolated static func sanitized(_ context: String?) -> String? {
        guard let context else { return nil }
        let cleaned = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }

        let characters = Array(cleaned)
        for index in characters.indices where isUnsafeEnglishLetter(characters[index]) {
            guard !isAttachedToWord(at: index, in: characters) else { continue }
            return nil
        }
        return cleaned
    }

    private nonisolated static func isUnsafeEnglishLetter(_ character: Character) -> Bool {
        let lowercased = String(character).lowercased()
        guard lowercased != "i",
              lowercased.unicodeScalars.count == 1,
              let value = lowercased.unicodeScalars.first?.value else { return false }
        return value >= 98 && value <= 122
    }

    private nonisolated static func isAttachedToWord(
        at index: Int,
        in characters: [Character]
    ) -> Bool {
        isWordConnection(from: index, offset: -1, in: characters)
            || isWordConnection(from: index, offset: 1, in: characters)
    }

    private nonisolated static func isWordConnection(
        from index: Int,
        offset: Int,
        in characters: [Character]
    ) -> Bool {
        let adjacentIndex = index + offset
        guard characters.indices.contains(adjacentIndex) else { return false }
        let adjacent = characters[adjacentIndex]
        if adjacent.isLetter { return true }
        guard adjacent == "'" || adjacent == "’" else { return false }

        let beyondApostropheIndex = adjacentIndex + offset
        return characters.indices.contains(beyondApostropheIndex)
            && characters[beyondApostropheIndex].isLetter
    }
}

/// A child-facing prompt is assembled from speech, reviewed recordings and real timed pauses.
/// Letter characters never appear in `.spoken` steps: passing `c` to speech synthesis would ask
/// the system voice to say the letter name ("see") instead of the taught sound (/k/).
enum LetterSpeechStep: Equatable, Sendable {
    case spoken(String)
    case phoneme(BritishEnglishPhoneme.ID)
    case pause(TimeInterval)
}

enum LetterSpeechPlaybackState: Equatable, Sendable {
    case idle
    case playing
    case failed
}

@MainActor
final class LetterSpeechService: NSObject {
    static let shared = LetterSpeechService()

    @Published private(set) var playbackState: LetterSpeechPlaybackState = .idle

    nonisolated static let lessonLeadInPause: TimeInterval = 0.12
    /// A full second is intentionally conspicuous to a young listener; shorter gaps were heard
    /// as a doubled sound (for example /k//k/) during play-testing.
    nonisolated static let lessonRepetitionPause: TimeInterval = 1.0
    nonisolated static let lessonExamplePause: TimeInterval = 0.10

    // Both engines stay lazy so entering a writing screen never pays their startup cost until the
    // child asks to hear something. The outer required-audio token prevents music from resuming
    // between the synthesised words and the two reviewed phoneme recordings.
    private var synthesizer: AVSpeechSynthesizer?
    // Keep queued lessons on their own player. The standalone Debug lab and any future direct
    // catalogue audition must not be able to replace a child's in-flight lesson recording.
    private let phonemeAudio: PhonemeAudioService
    private var phonemeStateCancellable: AnyCancellable?
    private var phonemeCompletionCancellable: AnyCancellable?
    private var pendingSteps: [LetterSpeechStep] = []
    private var activeUtterance: AVSpeechUtterance?
    private var activePhonemeID: BritishEnglishPhoneme.ID?
    private var activePhonemeRequestID: UInt64?
    private var phonemeStartTask: Task<Void, Never>?
    private var pauseTask: Task<Void, Never>?
    private var requiredAudioToken: UUID?
    private var generation: UInt64 = 0
    private var isStartingPhoneme = false

    private override init() {
        phonemeAudio = PhonemeAudioService(bundle: .main, storage: .shared)
        super.init()
        phonemeStateCancellable = phonemeAudio.$state.sink { [weak self] state in
            self?.phonemeStateDidChange(state)
        }
        phonemeCompletionCancellable = phonemeAudio.approvedPlaybackDidFinish.sink {
            [weak self] completion in
            self?.phonemePlaybackDidFinish(completion)
        }
    }

    @discardableResult
    func speak(_ glyph: LetterGlyph) -> Bool {
        speak(Self.lessonPlan(for: glyph))
    }

    @discardableResult
    func speakLetterSoundPrompt(for glyph: LetterGlyph) -> Bool {
        speak(Self.letterSoundPlan(for: glyph))
    }

    @discardableResult
    func speakRecallPrompt(for glyph: LetterGlyph) -> Bool {
        speak(Self.recallPlan(for: glyph))
    }

    @discardableResult
    func speakPathPrompt(for glyph: LetterGlyph, animated: Bool) -> Bool {
        speak(Self.pathPlan(for: glyph, animated: animated))
    }

    @discardableResult
    func speakWordPrompt(
        for glyph: LetterGlyph,
        word: String,
        introduction: String,
        contextSentence: String?
    ) -> Bool {
        speak(
            Self.wordPlan(
                for: glyph,
                word: word,
                introduction: introduction,
                contextSentence: contextSentence
            )
        )
    }

    @discardableResult
    func speakSpellingPrompt(for word: String, contextSentence: String?) -> Bool {
        speak(Self.spellingPlan(for: word, contextSentence: contextSentence))
    }

    /// The Reception/Year 1 correspondence used by Comet Writer. Ambiguous letters intentionally
    /// use the example word in LetterLibrary: hard c as in cat, hard g as in goat and short vowels.
    /// Q and X are sequences of real recordings rather than invented extra phonemes.
    nonisolated static func phonemeIDs(
        forLetter character: String
    ) -> [BritishEnglishPhoneme.ID]? {
        switch character.lowercased() {
        case "a": return [.vowelTrap]
        case "b": return [.consonantB]
        case "c": return [.consonantK]
        case "d": return [.consonantD]
        case "e": return [.vowelDress]
        case "f": return [.consonantF]
        case "g": return [.consonantG]
        case "h": return [.consonantH]
        case "i": return [.vowelKit]
        case "j": return [.consonantJ]
        case "k": return [.consonantK]
        case "l": return [.consonantL]
        case "m": return [.consonantM]
        case "n": return [.consonantN]
        case "o": return [.vowelLot]
        case "p": return [.consonantP]
        case "q": return [.consonantK, .consonantW]
        case "r": return [.consonantR]
        case "s": return [.consonantS]
        case "t": return [.consonantT]
        case "u": return [.vowelStrut]
        case "v": return [.consonantV]
        case "w": return [.consonantW]
        case "x": return [.consonantK, .consonantS]
        case "y": return [.consonantY]
        case "z": return [.consonantZ]
        default: return nil
        }
    }

    nonisolated static func lessonPlan(for glyph: LetterGlyph) -> [LetterSpeechStep] {
        if glyph.isNumber {
            return [
                .spoken("Number \(glyph.character)."),
                .pause(lessonRepetitionPause),
                .spoken("\(glyph.character) is \(glyph.exampleWord).")
            ]
        }

        guard let phonemeIDs = phonemeIDs(forLetter: glyph.character) else { return [] }
        return [
            .spoken("Letter."),
            .pause(lessonLeadInPause)
        ]
            + phonemeIDs.map(LetterSpeechStep.phoneme)
            + [.pause(lessonRepetitionPause)]
            + phonemeIDs.map(LetterSpeechStep.phoneme)
            + [
                .pause(lessonExamplePause),
                .spoken(lessonExamplePhrase(for: glyph))
            ]
    }

    nonisolated static func letterSoundPlan(for glyph: LetterGlyph) -> [LetterSpeechStep] {
        guard !glyph.isNumber else {
            return [
                .spoken("Listen for the number name."),
                .pause(lessonLeadInPause),
                .spoken("Number \(glyph.character)."),
                .pause(lessonRepetitionPause),
                .spoken("Now write that number.")
            ]
        }
        return lessonPlan(for: glyph) + [
            .pause(lessonLeadInPause),
            .spoken("Now write that letter.")
        ]
    }

    nonisolated static func recallPlan(for glyph: LetterGlyph) -> [LetterSpeechStep] {
        if glyph.isNumber {
            return [.spoken("Write the number shown.")]
        }
        return letterSoundPlan(for: glyph)
    }

    nonisolated static func pathPlan(
        for glyph: LetterGlyph,
        animated: Bool
    ) -> [LetterSpeechStep] {
        let symbol = glyph.isNumber ? "number" : "letter"
        return [
            .spoken(
                animated
                    ? "Watch the comet write this \(symbol), then have a go."
                    : "The path is shown. Start at the green star and follow the arrows."
            )
        ]
    }

    nonisolated static func wordPlan(
        for glyph: LetterGlyph,
        word: String,
        introduction: String,
        contextSentence: String?
    ) -> [LetterSpeechStep] {
        let cleanedWord = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedWord = cleanedWord.lowercased()
        if cleanedWord.count == 1,
           lowercasedWord != "a",
           lowercasedWord != "i",
           let phonemeIDs = phonemeIDs(forLetter: cleanedWord) {
            return [
                .spoken("Write this one-letter sound."),
                .pause(lessonLeadInPause)
            ]
                + phonemeIDs.map(LetterSpeechStep.phoneme)
                + [
                    .pause(lessonExamplePause),
                    .spoken("Now write the highlighted letter.")
                ]
        }

        let context = SpokenPromptContextSanitizer.sanitized(contextSentence)
            .map { " Example: \($0)" } ?? ""
        let symbol = glyph.isNumber ? "number" : "letter"
        return [
            .spoken(
                "\(introduction) \(cleanedWord).\(context) Write it on one line. "
                    + "Now write the highlighted \(symbol)."
            )
        ]
    }

    nonisolated static func spellingPlan(
        for word: String,
        contextSentence: String?
    ) -> [LetterSpeechStep] {
        let cleaned = word.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = cleaned.lowercased()

        // "a" and "I" are genuine one-letter words and must keep their word pronunciations.
        // Any other single-letter custom entry is treated as a sound so it cannot become "see",
        // "gee", and so on through plain-text speech synthesis.
        if cleaned.count == 1,
           lowercased != "a",
           lowercased != "i",
           let phonemeIDs = phonemeIDs(forLetter: cleaned) {
            // Parent-authored context can itself be a bare grapheme (for example "c") and would
            // reintroduce the forbidden letter-name TTS. The reviewed clip is the whole prompt.
            return [
                .spoken("Spell the one-letter sound."),
                .pause(lessonLeadInPause)
            ]
                + phonemeIDs.map(LetterSpeechStep.phoneme)
        }

        let context = SpokenPromptContextSanitizer.sanitized(contextSentence)
            .map { " \($0)" } ?? ""
        return [.spoken("Spell the word \(cleaned).\(context)")]
    }

    nonisolated static func spokenText(in plan: [LetterSpeechStep]) -> [String] {
        plan.compactMap { step in
            guard case let .spoken(text) = step else { return nil }
            return text
        }
    }

    func stop(preservingPreparedAudio: Bool = true) {
        terminateSequence(
            finalState: .idle,
            preservingPreparedAudio: preservingPreparedAudio
        )
    }

    @discardableResult
    private func speak(_ steps: [LetterSpeechStep]) -> Bool {
        let storage = StorageService.shared
        guard storage.isVoiceEnabled, !steps.isEmpty else { return false }

        cancelSequence()
        requiredAudioToken = MusicService.shared.beginRequiredAudioSession()
        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else {
            releaseRequiredAudioFocus()
            playbackState = .failed
            return false
        }

        pendingSteps = steps
        playbackState = .playing
        advanceSequence()
        return !pendingSteps.isEmpty
            || activeUtterance != nil
            || activePhonemeID != nil
            || pauseTask != nil
    }

    private func advanceSequence() {
        guard activeUtterance == nil,
              activePhonemeID == nil,
              pauseTask == nil else { return }
        guard StorageService.shared.isVoiceEnabled else {
            cancelSequence()
            return
        }
        guard !pendingSteps.isEmpty else {
            finishSequence()
            return
        }

        let next = pendingSteps.removeFirst()
        switch next {
        case let .spoken(text):
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                advanceSequence()
                return
            }
            let utterance = AVSpeechUtterance(string: text)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
            utterance.rate = 0.43
            utterance.pitchMultiplier = 1.05
            utterance.volume = StorageService.shared.voiceVolume
            activeUtterance = utterance
            speechEngine().speak(utterance)

        case let .phoneme(id):
            let requestGeneration = generation
            activePhonemeID = id
            isStartingPhoneme = true
            phonemeStartTask?.cancel()
            phonemeStartTask = Task { @MainActor [weak self] in
                guard let self else { return }
                let result = await self.phonemeAudio.playAsync(id)
                guard !Task.isCancelled,
                      self.generation == requestGeneration,
                      self.activePhonemeID == id else { return }
                self.phonemeStartTask = nil
                self.isStartingPhoneme = false
                guard case let .started(_, _, requestID) = result else {
                    // The audio service has already published and released its own failed request.
                    self.failSequence(stoppingPhonemeAudio: false)
                    return
                }
                self.activePhonemeRequestID = requestID
            }

        case let .pause(duration):
            guard duration > 0 else {
                advanceSequence()
                return
            }
            let requestGeneration = generation
            pauseTask = Task { @MainActor [weak self] in
                do {
                    try await Task.sleep(
                        nanoseconds: UInt64(duration * 1_000_000_000)
                    )
                } catch {
                    return
                }
                guard let self,
                      self.generation == requestGeneration else { return }
                self.pauseTask = nil
                self.advanceSequence()
            }
        }
    }

    private func phonemeStateDidChange(_ state: PhonemeAudioPlaybackState) {
        guard !isStartingPhoneme, let activePhonemeID else { return }

        switch state {
        case .idle:
            // Stop, replacement and successful completion all become idle. Only the matching
            // completion event below is allowed to advance a queued lesson.
            break

        case let .playing(stableID, _, requestID):
            guard stableID == activePhonemeID.rawValue,
                  requestID == activePhonemeRequestID else {
                // Never stop a replacement player from inside its synchronous state delivery.
                // This queue owns a private player, so a mismatch is an invariant failure only.
                failSequence(stoppingPhonemeAudio: false)
                return
            }

        case .missingApprovedRecording, .failed:
            // These states are terminal and the audio service has already stopped/released its
            // player. Avoid a nested state mutation while @Published is notifying subscribers.
            failSequence(stoppingPhonemeAudio: false)
        }
    }

    private func phonemePlaybackDidFinish(_ completion: PhonemeAudioPlaybackCompletion) {
        guard let activePhonemeID,
              completion.stableID == activePhonemeID.rawValue,
              completion.requestID == activePhonemeRequestID else { return }
        self.activePhonemeID = nil
        activePhonemeRequestID = nil
        advanceSequence()
    }

    private func finishSpokenUtterance(
        synthesizer: AVSpeechSynthesizer,
        utterance: AVSpeechUtterance,
        wasCancelled: Bool
    ) {
        guard self.synthesizer === synthesizer,
              activeUtterance === utterance else { return }
        activeUtterance = nil
        if wasCancelled {
            failSequence()
        } else {
            advanceSequence()
        }
    }

    private func finishSequence() {
        pendingSteps = []
        activeUtterance = nil
        activePhonemeID = nil
        activePhonemeRequestID = nil
        phonemeStartTask?.cancel()
        phonemeStartTask = nil
        isStartingPhoneme = false
        pauseTask = nil
        releaseRequiredAudioFocus()
        playbackState = .idle
    }

    private func cancelSequence() {
        terminateSequence(finalState: .idle)
    }

    private func failSequence(stoppingPhonemeAudio: Bool = true) {
        terminateSequence(
            finalState: .failed,
            stoppingPhonemeAudio: stoppingPhonemeAudio
        )
    }

    private func terminateSequence(
        finalState: LetterSpeechPlaybackState,
        stoppingPhonemeAudio: Bool = true,
        preservingPreparedAudio: Bool = true
    ) {
        generation &+= 1
        pendingSteps = []
        phonemeStartTask?.cancel()
        phonemeStartTask = nil
        pauseTask?.cancel()
        pauseTask = nil
        activeUtterance = nil
        activePhonemeID = nil
        activePhonemeRequestID = nil
        isStartingPhoneme = false
        synthesizer?.stopSpeaking(at: .immediate)
        if stoppingPhonemeAudio {
            phonemeAudio.stop(preservingPreparedAudio: preservingPreparedAudio)
        }
        releaseRequiredAudioFocus()
        playbackState = finalState
    }

    private func releaseRequiredAudioFocus() {
        guard let requiredAudioToken else { return }
        self.requiredAudioToken = nil
        MusicService.shared.endRequiredAudioSession(requiredAudioToken, resume: nil)
    }

    private func speechEngine() -> AVSpeechSynthesizer {
        if let synthesizer { return synthesizer }
        let engine = AVSpeechSynthesizer()
        #if os(iOS)
        engine.usesApplicationAudioSession = true
        #endif
        engine.delegate = self
        synthesizer = engine
        return engine
    }

    nonisolated private static func lessonExamplePhrase(for glyph: LetterGlyph) -> String {
        if glyph.character.lowercased() == "x" {
            return "as in \(glyph.exampleWord)."
        }
        return "is for \(glyph.exampleWord)."
    }
}

extension LetterSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishSpokenUtterance(
                synthesizer: synthesizer,
                utterance: utterance,
                wasCancelled: false
            )
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishSpokenUtterance(
                synthesizer: synthesizer,
                utterance: utterance,
                wasCancelled: true
            )
        }
    }
}
