import AVFoundation
import Combine
import Foundation
import UIKit

enum PhonemeAudioPlaybackPolicy: Equatable, Sendable {
    /// Production playback must use a reviewed recording shipped in the application bundle.
    case approvedRecordingOnly

    #if DEBUG
    /// Development/lab tooling may preview the catalogue's authored IPA through Apple's voice.
    /// This policy is intentionally unavailable through the ordinary `play` API.
    case allowIPAPreview
    #endif
}

struct PhonemeAudioAssetReference: Equatable, Hashable, Sendable {
    let stableID: String
    let resourceName: String
    let fileExtension: String
    let subdirectory: String

    var relativePath: String {
        "\(subdirectory)/\(resourceName).\(fileExtension)"
    }
}

enum PhonemeAudioSource: Equatable, Sendable {
    case approvedRecording(PhonemeAudioAssetReference)
    #if DEBUG
    case ipaLabPreview(synthesisIPA: String)
    #endif
}

enum PhonemeAudioFailure: Error, Equatable, Sendable {
    case voiceDisabled
    case catalogueEntryMissing(stableID: String)
    case invalidStableID(stableID: String)
    case approvedRecordingCouldNotLoad(PhonemeAudioAssetReference)
    case approvedRecordingCouldNotStart(PhonemeAudioAssetReference)
    case approvedRecordingDecodeFailed(PhonemeAudioAssetReference)
    case audioSessionActivationFailed
    case audioSessionInterrupted
    case audioOutputRouteLost
    case audioServicesWereReset
    #if DEBUG
    case invalidSynthesisIPA(stableID: String)
    case britishEnglishVoiceUnavailable
    case ipaPreviewCancelled(stableID: String)
    #endif
}

enum PhonemeAudioPlaybackResult: Equatable, Sendable {
    case started(stableID: String, source: PhonemeAudioSource, requestID: UInt64)
    case missingApprovedRecording(PhonemeAudioAssetReference)
    case failed(stableID: String, reason: PhonemeAudioFailure)
}

enum PhonemeAudioPlaybackState: Equatable, Sendable {
    case idle
    case playing(stableID: String, source: PhonemeAudioSource, requestID: UInt64)
    case missingApprovedRecording(PhonemeAudioAssetReference)
    case failed(stableID: String, reason: PhonemeAudioFailure)
}

struct PhonemeAudioPlaybackCompletion: Equatable, Sendable {
    let stableID: String
    let requestID: UInt64
}

private final class PreparedPhonemeAudioPlayer: @unchecked Sendable {
    let player: AVAudioPlayer

    init(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
    }
}

enum PhonemeAudioAssetIssue: Equatable, Sendable {
    case duplicateStableID(String)
    case invalidStableID(String)
    case missing(PhonemeAudioAssetReference)
    case emptyOrUnreadable(PhonemeAudioAssetReference)
    case unexpectedM4A(resourceName: String)
}

struct PhonemeAudioAssetAudit: Equatable, Sendable {
    let expected: [PhonemeAudioAssetReference]
    let available: [PhonemeAudioAssetReference]
    let issues: [PhonemeAudioAssetIssue]

    var isComplete: Bool {
        issues.isEmpty && expected.count == available.count
    }
}

/// Plays the app's reviewed British-English phoneme recordings.
///
/// Ordinary app code can only call `play`, which never asks speech synthesis to pronounce a
/// grapheme. IPA synthesis is isolated behind the explicitly named lab-preview API and always
/// uses `AVSpeechSynthesisIPANotationAttribute`; the stable ID or displayed letter is never sent
/// to the synthesizer as plain text.
@MainActor
final class PhonemeAudioService: NSObject, ObservableObject {
    static let shared = PhonemeAudioService()

    nonisolated static let approvedRecordingSubdirectory = "PhonemeAudio/en-GB/v1"
    nonisolated static let approvedRecordingFileExtension = "m4a"

    @Published private(set) var state: PhonemeAudioPlaybackState = .idle

    /// Successful endings are separate from `.idle`: an explicit stop or replacement request is
    /// idle too, but must never be mistaken for the end of a phoneme in a queued lesson.
    let approvedPlaybackDidFinish = PassthroughSubject<PhonemeAudioPlaybackCompletion, Never>()

    private let bundle: Bundle
    private let storage: StorageService

    // Both engines are deliberately lazy. In particular, no AVAudioPlayer is created while the
    // app is launching; a reviewed clip is opened only after an explicit playback request.
    private var approvedPlayer: AVAudioPlayer?
    private var cachedApprovedPlayer: AVAudioPlayer?
    private var cachedApprovedReference: PhonemeAudioAssetReference?
    #if DEBUG
    private var ipaSynthesizer: AVSpeechSynthesizer?
    private var activeUtterance: AVSpeechUtterance?
    #endif
    private var activePlayerContext: ActivePlaybackContext?
    #if DEBUG
    private var activeSpeechContext: ActivePlaybackContext?
    #endif
    private var requiredAudioToken: UUID?
    private var generation: UInt64 = 0

    override init() {
        self.bundle = .main
        self.storage = .shared
        super.init()
        installAudioSessionObservers()
    }

    init(
        bundle: Bundle,
        storage: StorageService
    ) {
        self.bundle = bundle
        self.storage = storage
        super.init()
        installAudioSessionObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    /// Production-safe playback. There is intentionally no policy argument here: a missing or
    /// broken approved recording is reported as such and never falls back to letter-name TTS.
    @discardableResult
    func play(_ phoneme: BritishEnglishPhoneme) -> PhonemeAudioPlaybackResult {
        startApprovedRecording(phoneme, policy: .approvedRecordingOnly)
    }

    /// Looks up a catalogue entry and performs production-safe approved-recording playback.
    @discardableResult
    func play(_ id: BritishEnglishPhoneme.ID) -> PhonemeAudioPlaybackResult {
        guard let phoneme = BritishEnglishPhonemeCatalogue.phoneme(for: id) else {
            let stableID = id.rawValue
            beginLatestRequest()
            return recordFailure(
                stableID: stableID,
                reason: .catalogueEntryMissing(stableID: stableID)
            )
        }
        return play(phoneme)
    }

    /// Production lesson path. File opening and preparation happen on a dedicated worker; only
    /// audio-session ownership, delegates and playback state return to MainActor.
    @discardableResult
    func playAsync(_ id: BritishEnglishPhoneme.ID) async -> PhonemeAudioPlaybackResult {
        guard let phoneme = BritishEnglishPhonemeCatalogue.phoneme(for: id) else {
            let stableID = id.rawValue
            beginLatestRequest()
            return recordFailure(
                stableID: stableID,
                reason: .catalogueEntryMissing(stableID: stableID)
            )
        }
        return await startApprovedRecordingAsync(phoneme)
    }

    #if DEBUG
    /// Development/lab-only pronunciation preview. Unlike `play`, this deliberately exercises
    /// Apple's IPA attribute and never reads the phoneme's stable ID as speech text.
    @discardableResult
    func previewIPAInLab(
        _ phoneme: BritishEnglishPhoneme
    ) -> PhonemeAudioPlaybackResult {
        startIPAPreview(phoneme, policy: .allowIPAPreview)
    }

    /// Catalogue-ID convenience for explicit development/lab preview tooling.
    @discardableResult
    func previewIPAInLab(
        _ id: BritishEnglishPhoneme.ID
    ) -> PhonemeAudioPlaybackResult {
        guard let phoneme = BritishEnglishPhonemeCatalogue.phoneme(for: id) else {
            let stableID = id.rawValue
            beginLatestRequest()
            return recordFailure(
                stableID: stableID,
                reason: .catalogueEntryMissing(stableID: stableID)
            )
        }
        return previewIPAInLab(phoneme)
    }
    #endif

    /// Cancels approved and preview playback, releases this service's audio-focus token exactly
    /// once, and leaves a stable idle state. Repeated calls are safe.
    func stop(preservingPreparedAudio: Bool = true) {
        generation &+= 1
        cancelEngines(preserveApprovedPlayerCache: preservingPreparedAudio)
        if !preservingPreparedAudio {
            cachedApprovedPlayer = nil
            cachedApprovedReference = nil
        }
        releaseRequiredAudioFocus()
        state = .idle
    }

    /// Audits target membership and naming without decoding every clip or creating a player.
    /// This is suitable for release checks and hosted tests after Copy Bundle Resources runs.
    func auditApprovedRecordingAssets() -> PhonemeAudioAssetAudit {
        var expected: [PhonemeAudioAssetReference] = []
        var available: [PhonemeAudioAssetReference] = []
        var issues: [PhonemeAudioAssetIssue] = []
        var seenStableIDs = Set<String>()

        for phoneme in BritishEnglishPhonemeCatalogue.all {
            let stableID = phoneme.id.rawValue
            if !seenStableIDs.insert(stableID).inserted {
                issues.append(.duplicateStableID(stableID))
                continue
            }
            guard Self.isResourceSafeStableID(stableID) else {
                issues.append(.invalidStableID(stableID))
                continue
            }

            let reference = Self.approvedRecordingReference(for: phoneme.id)
            expected.append(reference)
            guard let url = approvedRecordingURL(for: reference) else {
                issues.append(.missing(reference))
                continue
            }

            let values = try? url.resourceValues(
                forKeys: [.isRegularFileKey, .fileSizeKey]
            )
            guard values?.isRegularFile == true, (values?.fileSize ?? 0) > 0 else {
                issues.append(.emptyOrUnreadable(reference))
                continue
            }
            available.append(reference)
        }

        let expectedNames = Set(expected.map(\.resourceName))
        let bundledNames = Set(
            (bundle.urls(
                forResourcesWithExtension: Self.approvedRecordingFileExtension,
                subdirectory: Self.approvedRecordingSubdirectory
            ) ?? []).map { $0.deletingPathExtension().lastPathComponent }
        )
        for resourceName in bundledNames.subtracting(expectedNames).sorted() {
            issues.append(.unexpectedM4A(resourceName: resourceName))
        }

        return PhonemeAudioAssetAudit(
            expected: expected,
            available: available,
            issues: issues
        )
    }

    nonisolated static func approvedRecordingResourceName(
        for id: BritishEnglishPhoneme.ID
    ) -> String {
        "phoneme_\(id.rawValue)"
    }

    nonisolated static func approvedRecordingReference(
        for id: BritishEnglishPhoneme.ID
    ) -> PhonemeAudioAssetReference {
        PhonemeAudioAssetReference(
            stableID: id.rawValue,
            resourceName: approvedRecordingResourceName(for: id),
            fileExtension: approvedRecordingFileExtension,
            subdirectory: approvedRecordingSubdirectory
        )
    }

    #if DEBUG
    /// Builds the exact attributed carrier used by the Debug lab. Keeping this pure makes it
    /// possible to prove that every preview is driven by IPA rather than a displayed grapheme.
    nonisolated static func ipaPreviewAttributedText(
        for phoneme: BritishEnglishPhoneme
    ) -> NSAttributedString? {
        let ipa = phoneme.synthesisIPA.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !ipa.isEmpty else { return nil }

        let attributedText = NSMutableAttributedString(string: "sound")
        attributedText.addAttribute(
            NSAttributedString.Key(rawValue: AVSpeechSynthesisIPANotationAttribute),
            value: ipa,
            range: NSRange(location: 0, length: attributedText.length)
        )
        return attributedText
    }
    #endif

    private func startApprovedRecording(
        _ phoneme: BritishEnglishPhoneme,
        policy: PhonemeAudioPlaybackPolicy
    ) -> PhonemeAudioPlaybackResult {
        precondition(policy == .approvedRecordingOnly)
        let requestGeneration = beginLatestRequest()
        let stableID = phoneme.id.rawValue

        guard storage.isVoiceEnabled else {
            return recordFailure(stableID: stableID, reason: .voiceDisabled)
        }
        guard Self.isResourceSafeStableID(stableID) else {
            return recordFailure(
                stableID: stableID,
                reason: .invalidStableID(stableID: stableID)
            )
        }

        let reference = Self.approvedRecordingReference(for: phoneme.id)
        guard let url = approvedRecordingURL(for: reference) else {
            releaseRequiredAudioFocus()
            state = .missingApprovedRecording(reference)
            return .missingApprovedRecording(reference)
        }

        let nextPlayer: AVAudioPlayer
        if cachedApprovedReference == reference, let cachedApprovedPlayer {
            nextPlayer = cachedApprovedPlayer
            nextPlayer.currentTime = 0
            self.cachedApprovedPlayer = nil
            cachedApprovedReference = nil
        } else {
            cachedApprovedPlayer = nil
            cachedApprovedReference = nil
            do {
                nextPlayer = try AVAudioPlayer(contentsOf: url)
            } catch {
                return recordFailure(
                    stableID: stableID,
                    reason: .approvedRecordingCouldNotLoad(reference)
                )
            }
        }

        return startPreparedApprovedPlayer(
            nextPlayer,
            reference: reference,
            stableID: stableID,
            requestGeneration: requestGeneration
        )
    }

    private func startApprovedRecordingAsync(
        _ phoneme: BritishEnglishPhoneme
    ) async -> PhonemeAudioPlaybackResult {
        let requestGeneration = beginLatestRequest()
        let stableID = phoneme.id.rawValue

        guard storage.isVoiceEnabled else {
            return recordFailure(stableID: stableID, reason: .voiceDisabled)
        }
        guard Self.isResourceSafeStableID(stableID) else {
            return recordFailure(
                stableID: stableID,
                reason: .invalidStableID(stableID: stableID)
            )
        }

        let reference = Self.approvedRecordingReference(for: phoneme.id)
        guard let url = approvedRecordingURL(for: reference) else {
            releaseRequiredAudioFocus()
            state = .missingApprovedRecording(reference)
            return .missingApprovedRecording(reference)
        }

        let nextPlayer: AVAudioPlayer
        let reusedCachedPlayer: Bool
        if cachedApprovedReference == reference, let cachedApprovedPlayer {
            reusedCachedPlayer = true
            nextPlayer = cachedApprovedPlayer
            nextPlayer.currentTime = 0
            self.cachedApprovedPlayer = nil
            cachedApprovedReference = nil
        } else {
            reusedCachedPlayer = false
            cachedApprovedPlayer = nil
            cachedApprovedReference = nil
            let prepared = await Task.detached(priority: .userInitiated) {
                try? PreparedPhonemeAudioPlayer(url: url)
            }.value
            guard !Task.isCancelled, generation == requestGeneration else {
                return .failed(stableID: stableID, reason: .audioSessionInterrupted)
            }
            guard let prepared else {
                return recordFailure(
                    stableID: stableID,
                    reason: .approvedRecordingCouldNotLoad(reference)
                )
            }
            nextPlayer = prepared.player
        }

        let firstResult = startPreparedApprovedPlayer(
            nextPlayer,
            reference: reference,
            stableID: stableID,
            requestGeneration: requestGeneration
        )
        guard reusedCachedPlayer,
              case .failed(_, .approvedRecordingCouldNotStart) = firstResult,
              generation == requestGeneration else {
            return firstResult
        }

        // A prepared player can be invalidated by an audio-service transition between lifecycle
        // notifications. Reopen the exact same reviewed file once before surfacing a failure.
        let replacement = await Task.detached(priority: .userInitiated) {
            try? PreparedPhonemeAudioPlayer(url: url)
        }.value
        guard !Task.isCancelled, generation == requestGeneration else {
            return .failed(stableID: stableID, reason: .audioSessionInterrupted)
        }
        guard let replacement else { return firstResult }
        return startPreparedApprovedPlayer(
            replacement.player,
            reference: reference,
            stableID: stableID,
            requestGeneration: requestGeneration
        )
    }

    private func startPreparedApprovedPlayer(
        _ nextPlayer: AVAudioPlayer,
        reference: PhonemeAudioAssetReference,
        stableID: String,
        requestGeneration: UInt64
    ) -> PhonemeAudioPlaybackResult {
        guard generation == requestGeneration else {
            return .failed(stableID: stableID, reason: .audioSessionInterrupted)
        }
        guard acquireRequiredAudioFocusAndActivateSession() else {
            return recordFailure(
                stableID: stableID,
                reason: .audioSessionActivationFailed
            )
        }

        let source = PhonemeAudioSource.approvedRecording(reference)
        let context = ActivePlaybackContext(
            generation: requestGeneration,
            stableID: stableID,
            source: source
        )
        nextPlayer.delegate = self
        nextPlayer.volume = clampedVoiceVolume
        approvedPlayer = nextPlayer
        activePlayerContext = context

        guard nextPlayer.play() else {
            nextPlayer.delegate = nil
            approvedPlayer = nil
            activePlayerContext = nil
            releaseRequiredAudioFocus()
            return recordFailure(
                stableID: stableID,
                reason: .approvedRecordingCouldNotStart(reference)
            )
        }

        state = .playing(
            stableID: stableID,
            source: source,
            requestID: requestGeneration
        )
        return .started(
            stableID: stableID,
            source: source,
            requestID: requestGeneration
        )
    }

    #if DEBUG
    private func startIPAPreview(
        _ phoneme: BritishEnglishPhoneme,
        policy: PhonemeAudioPlaybackPolicy
    ) -> PhonemeAudioPlaybackResult {
        precondition(policy == .allowIPAPreview)
        let requestGeneration = beginLatestRequest()
        let stableID = phoneme.id.rawValue

        guard storage.isVoiceEnabled else {
            return recordFailure(stableID: stableID, reason: .voiceDisabled)
        }
        guard Self.isResourceSafeStableID(stableID) else {
            return recordFailure(
                stableID: stableID,
                reason: .invalidStableID(stableID: stableID)
            )
        }

        guard let attributedText = Self.ipaPreviewAttributedText(for: phoneme) else {
            return recordFailure(
                stableID: stableID,
                reason: .invalidSynthesisIPA(stableID: stableID)
            )
        }
        let ipa = phoneme.synthesisIPA.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let voice = AVSpeechSynthesisVoice(language: "en-GB") else {
            return recordFailure(
                stableID: stableID,
                reason: .britishEnglishVoiceUnavailable
            )
        }
        guard acquireRequiredAudioFocusAndActivateSession() else {
            return recordFailure(
                stableID: stableID,
                reason: .audioSessionActivationFailed
            )
        }

        // `sound` is only a carrier for the IPA attribute. The stable ID/displayed grapheme is
        // never used as the utterance string, so this path cannot degrade into plain-letter TTS.
        let utterance = AVSpeechUtterance(attributedString: attributedText)
        utterance.voice = voice
        utterance.rate = 0.43
        utterance.pitchMultiplier = 1.0
        utterance.volume = clampedVoiceVolume

        let source = PhonemeAudioSource.ipaLabPreview(synthesisIPA: ipa)
        let context = ActivePlaybackContext(
            generation: requestGeneration,
            stableID: stableID,
            source: source
        )
        let synthesizer = speechEngine()
        activeUtterance = utterance
        activeSpeechContext = context
        state = .playing(
            stableID: stableID,
            source: source,
            requestID: requestGeneration
        )
        synthesizer.speak(utterance)
        return .started(
            stableID: stableID,
            source: source,
            requestID: requestGeneration
        )
    }
    #endif

    /// Invalidates old callbacks before stopping their objects. Delegate callbacks dispatched by
    /// a just-cancelled request therefore cannot complete or fail the replacement request.
    @discardableResult
    private func beginLatestRequest() -> UInt64 {
        generation &+= 1
        cancelEngines()
        state = .idle
        return generation
    }

    private func cancelEngines(preserveApprovedPlayerCache: Bool = true) {
        let oldPlayer = approvedPlayer
        let oldContext = activePlayerContext
        approvedPlayer = nil
        activePlayerContext = nil
        oldPlayer?.delegate = nil
        oldPlayer?.stop()
        if preserveApprovedPlayerCache,
           let oldPlayer,
           let oldContext,
           case let .approvedRecording(reference) = oldContext.source {
            oldPlayer.currentTime = 0
            cachedApprovedPlayer = oldPlayer
            cachedApprovedReference = reference
        }

        #if DEBUG
        activeUtterance = nil
        activeSpeechContext = nil
        ipaSynthesizer?.stopSpeaking(at: .immediate)
        #endif
    }

    private func approvedRecordingURL(
        for reference: PhonemeAudioAssetReference
    ) -> URL? {
        bundle.url(
            forResource: reference.resourceName,
            withExtension: reference.fileExtension,
            subdirectory: reference.subdirectory
        )
    }

    #if DEBUG
    private func speechEngine() -> AVSpeechSynthesizer {
        if let ipaSynthesizer { return ipaSynthesizer }
        let synthesizer = AVSpeechSynthesizer()
        #if os(iOS)
        synthesizer.usesApplicationAudioSession = true
        #endif
        synthesizer.delegate = self
        ipaSynthesizer = synthesizer
        return synthesizer
    }
    #endif

    private var clampedVoiceVolume: Float {
        min(max(storage.voiceVolume, 0), 1)
    }

    private func acquireRequiredAudioFocusAndActivateSession() -> Bool {
        if requiredAudioToken == nil {
            requiredAudioToken = MusicService.shared.beginRequiredAudioSession()
        }
        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else {
            releaseRequiredAudioFocus()
            return false
        }
        return true
    }

    private func releaseRequiredAudioFocus() {
        guard let token = requiredAudioToken else { return }
        requiredAudioToken = nil
        MusicService.shared.endRequiredAudioSession(token, resume: nil)
    }

    private func installAudioSessionObservers() {
        let center = NotificationCenter.default
        center.addObserver(
            self,
            selector: #selector(audioSessionWasInterrupted(_:)),
            name: AVAudioSession.interruptionNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(audioOutputRouteChanged(_:)),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(audioServicesWereReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(memoryWarningReceived(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    @objc nonisolated private func audioSessionWasInterrupted(_ notification: Notification) {
        guard let rawValue = (
            notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? NSNumber
        )?.uintValue,
        AVAudioSession.InterruptionType(rawValue: rawValue) == .began else {
            return
        }

        Task { @MainActor [weak self] in
            self?.handleSystemAudioLoss(.audioSessionInterrupted)
        }
    }

    @objc nonisolated private func audioOutputRouteChanged(_ notification: Notification) {
        guard let rawValue = (
            notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? NSNumber
        )?.uintValue,
        let reason = AVAudioSession.RouteChangeReason(rawValue: rawValue),
        reason == .oldDeviceUnavailable || reason == .noSuitableRouteForCategory else {
            return
        }

        Task { @MainActor [weak self] in
            self?.handleSystemAudioLoss(.audioOutputRouteLost)
        }
    }

    @objc nonisolated private func audioServicesWereReset(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.handleSystemAudioLoss(.audioServicesWereReset)
        }
    }

    @objc nonisolated private func memoryWarningReceived(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.cachedApprovedPlayer = nil
            self?.cachedApprovedReference = nil
        }
    }

    private func handleSystemAudioLoss(_ reason: PhonemeAudioFailure) {
        let interruptedStableID: String?
        if case let .playing(stableID, _, _) = state {
            interruptedStableID = stableID
        } else {
            interruptedStableID = nil
        }

        generation &+= 1
        cancelEngines(preserveApprovedPlayerCache: false)
        cachedApprovedPlayer = nil
        cachedApprovedReference = nil
        releaseRequiredAudioFocus()

        if let interruptedStableID {
            state = .failed(stableID: interruptedStableID, reason: reason)
        } else {
            state = .idle
        }
    }

    private func recordFailure(
        stableID: String,
        reason: PhonemeAudioFailure
    ) -> PhonemeAudioPlaybackResult {
        releaseRequiredAudioFocus()
        state = .failed(stableID: stableID, reason: reason)
        return .failed(stableID: stableID, reason: reason)
    }

    nonisolated private static func isResourceSafeStableID(_ stableID: String) -> Bool {
        guard !stableID.isEmpty else { return false }
        return stableID.unicodeScalars.allSatisfy { scalar in
            switch scalar.value {
            case 45, 46, 48...57, 65...90, 95, 97...122:
                return true
            default:
                return false
            }
        }
    }

    private struct ActivePlaybackContext {
        let generation: UInt64
        let stableID: String
        let source: PhonemeAudioSource
    }

    private func finishApprovedPlayback(
        player: AVAudioPlayer,
        successfully: Bool
    ) {
        guard approvedPlayer === player,
              let context = activePlayerContext,
              context.generation == generation else {
            return
        }

        player.delegate = nil
        approvedPlayer = nil
        activePlayerContext = nil
        releaseRequiredAudioFocus()

        if successfully {
            player.currentTime = 0
            cachedApprovedPlayer = player
            if case let .approvedRecording(reference) = context.source {
                cachedApprovedReference = reference
            }
            state = .idle
            approvedPlaybackDidFinish.send(
                PhonemeAudioPlaybackCompletion(
                    stableID: context.stableID,
                    requestID: context.generation
                )
            )
        } else if case let .approvedRecording(reference) = context.source {
            cachedApprovedPlayer = nil
            cachedApprovedReference = nil
            state = .failed(
                stableID: context.stableID,
                reason: .approvedRecordingDecodeFailed(reference)
            )
        }
    }

    private func failApprovedPlayback(
        player: AVAudioPlayer
    ) {
        finishApprovedPlayback(player: player, successfully: false)
    }

    #if DEBUG
    private func finishIPAPreview(
        synthesizer: AVSpeechSynthesizer,
        utterance: AVSpeechUtterance,
        cancelled: Bool
    ) {
        guard ipaSynthesizer === synthesizer,
              activeUtterance === utterance,
              let context = activeSpeechContext,
              context.generation == generation else {
            return
        }

        activeUtterance = nil
        activeSpeechContext = nil
        releaseRequiredAudioFocus()
        state = cancelled
            ? .failed(
                stableID: context.stableID,
                reason: .ipaPreviewCancelled(stableID: context.stableID)
            )
            : .idle
    }
    #endif
}

extension PhonemeAudioService: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(
        _ player: AVAudioPlayer,
        successfully flag: Bool
    ) {
        Task { @MainActor [weak self] in
            self?.finishApprovedPlayback(player: player, successfully: flag)
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        Task { @MainActor [weak self] in
            self?.failApprovedPlayback(player: player)
        }
    }
}

#if DEBUG
extension PhonemeAudioService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didFinish utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishIPAPreview(
                synthesizer: synthesizer,
                utterance: utterance,
                cancelled: false
            )
        }
    }

    nonisolated func speechSynthesizer(
        _ synthesizer: AVSpeechSynthesizer,
        didCancel utterance: AVSpeechUtterance
    ) {
        Task { @MainActor [weak self] in
            self?.finishIPAPreview(
                synthesizer: synthesizer,
                utterance: utterance,
                cancelled: true
            )
        }
    }
}
#endif
