import AVFAudio
import Foundation
import UIKit

enum CustomPromptAudioPlaybackOutcome: Equatable, Sendable {
    case finished
    case failed

    init(didFinishSuccessfully: Bool) {
        self = didFinishSuccessfully ? .finished : .failed
    }
}

/// AVAudioPlayer is prepared completely on one worker and is not touched again until ownership
/// transfers to MainActor. This keeps file opening and codec priming out of the render loop.
private final class PreparedCustomPromptPlayer: @unchecked Sendable {
    let player: AVAudioPlayer

    init(url: URL) throws {
        player = try AVAudioPlayer(contentsOf: url)
        player.prepareToPlay()
    }
}

/// Records an adult's pronunciation for a custom word and keeps it entirely on-device.
/// Audio is opt-in, never starts without a tap, and is stored outside Documents so it is not
/// exposed through file sharing.
@MainActor
final class CustomPromptAudioService: NSObject, ObservableObject, AVAudioPlayerDelegate {
    static let shared = CustomPromptAudioService()

    @Published private(set) var recordingWordID: UUID?
    @Published private(set) var playingFilename: String?
    @Published private(set) var permissionDenied = false

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var cachedPlayer: AVAudioPlayer?
    private var cachedFilename: String?
    private var playbackCompletion: ((CustomPromptAudioPlaybackOutcome) -> Void)?
    private var requiredAudioToken: UUID?
    private var playbackGeneration: UInt64 = 0

    override init() {
        super.init()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(audioServicesWereReset(_:)),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(memoryWarningReceived(_:)),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private static var recordingsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("CometWriterRecordings", isDirectory: true)
    }

    func startRecording(for word: CometCustomWord) async -> Bool {
        stopPlayback(releaseAudioFocus: false)
        if recordingWordID != nil { _ = stopRecording(releaseAudioFocus: false) }

        let allowed = await requestPermission()
        guard !Task.isCancelled else {
            releaseAudioFocus()
            return false
        }
        guard allowed else {
            permissionDenied = true
            releaseAudioFocus()
            return false
        }
        permissionDenied = false
        acquireAudioFocus()

        do {
            try FileManager.default.createDirectory(
                at: Self.recordingsDirectory,
                withIntermediateDirectories: true
            )
            let filename = "prompt-\(word.id.uuidString).m4a"
            let url = Self.recordingsDirectory.appendingPathComponent(filename)
            if cachedFilename == filename {
                cachedPlayer = nil
                cachedFilename = nil
            }
            try? FileManager.default.removeItem(at: url)

            guard AppAudioSessionCoordinator.shared.activate(.promptRecording) else {
                releaseAudioFocus()
                return false
            }

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22_050,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let nextRecorder = try AVAudioRecorder(url: url, settings: settings)
            nextRecorder.isMeteringEnabled = false
            nextRecorder.prepareToRecord()
            guard !Task.isCancelled else {
                releaseAudioFocus()
                return false
            }
            // A custom prompt is a word or short sentence. Keep accidental unattended recording
            // bounded without changing its sample rate, codec, or audible quality.
            guard nextRecorder.record(forDuration: 120) else {
                releaseAudioFocus()
                return false
            }
            recorder = nextRecorder
            recordingWordID = word.id
            return true
        } catch {
            recorder = nil
            recordingWordID = nil
            releaseAudioFocus()
            return false
        }
    }

    /// Returns the completed local filename so the learning store can associate it with a word.
    func stopRecording() -> String? {
        stopRecording(releaseAudioFocus: true)
    }

    private func stopRecording(releaseAudioFocus shouldReleaseAudioFocus: Bool) -> String? {
        guard let recorder else {
            if shouldReleaseAudioFocus { releaseAudioFocus() }
            return nil
        }
        recorder.stop()
        let filename = recorder.url.lastPathComponent
        self.recorder = nil
        recordingWordID = nil
        if shouldReleaseAudioFocus { releaseAudioFocus() }

        guard FileManager.default.fileExists(atPath: recorder.url.path) else { return nil }
        return filename
    }

    /// Production playback path. Opening the file and preparing its decoder happen off-main;
    /// cached clips still begin immediately. If a cached player was invalidated by the system,
    /// recreate it from disk once before reporting failure.
    @discardableResult
    func playAsync(
        filename: String,
        onCompletion: ((CustomPromptAudioPlaybackOutcome) -> Void)? = nil
    ) async -> Bool {
        guard let request = beginPlaybackRequest(filename: filename) else { return false }

        if cachedFilename == filename, let cachedPlayer {
            self.cachedPlayer = nil
            cachedFilename = nil
            cachedPlayer.currentTime = 0
            if startPreparedPlayer(
                cachedPlayer,
                filename: filename,
                generation: request.generation,
                onCompletion: onCompletion
            ) {
                return true
            }
            guard playbackGeneration == request.generation else { return false }
        } else {
            cachedPlayer = nil
            cachedFilename = nil
        }

        let prepared = await Task.detached(priority: .userInitiated) {
            try? PreparedCustomPromptPlayer(url: request.url)
        }.value
        if Task.isCancelled {
            if playbackGeneration == request.generation { stopPlayback() }
            return false
        }
        guard playbackGeneration == request.generation else { return false }
        guard let prepared else {
            releaseAudioFocus()
            return false
        }
        return startPreparedPlayer(
            prepared.player,
            filename: filename,
            generation: request.generation,
            onCompletion: onCompletion
        )
    }

    func stopPlayback(preservingPreparedAudio: Bool = true) {
        stopPlayback(
            releaseAudioFocus: true,
            preservingPreparedAudio: preservingPreparedAudio
        )
    }

    private func stopPlayback(
        releaseAudioFocus shouldReleaseAudioFocus: Bool,
        preservingPreparedAudio: Bool = true
    ) {
        playbackGeneration &+= 1
        let previousPlayer = player
        let previousFilename = playingFilename
        player = nil
        playingFilename = nil
        playbackCompletion = nil
        previousPlayer?.delegate = nil
        previousPlayer?.stop()
        if preservingPreparedAudio, let previousPlayer, let previousFilename {
            previousPlayer.currentTime = 0
            cachedPlayer = previousPlayer
            cachedFilename = previousFilename
        } else if !preservingPreparedAudio {
            cachedPlayer = nil
            cachedFilename = nil
        }
        if shouldReleaseAudioFocus { releaseAudioFocus() }
    }

    private func beginPlaybackRequest(
        filename: String
    ) -> (url: URL, generation: UInt64)? {
        if playingFilename == filename {
            stopPlayback()
            return nil
        }
        _ = stopRecording(releaseAudioFocus: false)
        stopPlayback(releaseAudioFocus: false)

        let url = Self.recordingsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            releaseAudioFocus()
            return nil
        }
        return (url, playbackGeneration)
    }

    private func startPreparedPlayer(
        _ nextPlayer: AVAudioPlayer,
        filename: String,
        generation: UInt64,
        onCompletion: ((CustomPromptAudioPlaybackOutcome) -> Void)?
    ) -> Bool {
        guard playbackGeneration == generation else { return false }
        acquireAudioFocus()
        guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else {
            releaseAudioFocus()
            return false
        }

        nextPlayer.delegate = self
        nextPlayer.volume = StorageService.shared.voiceVolume
        player = nextPlayer
        playingFilename = filename
        playbackCompletion = onCompletion
        guard nextPlayer.play() else {
            nextPlayer.delegate = nil
            player = nil
            playingFilename = nil
            playbackCompletion = nil
            releaseAudioFocus()
            return false
        }
        return true
    }

    func delete(filename: String) {
        if playingFilename == filename { stopPlayback() }
        if cachedFilename == filename {
            cachedPlayer = nil
            cachedFilename = nil
        }
        try? FileManager.default.removeItem(
            at: Self.recordingsDirectory.appendingPathComponent(filename)
        )
    }

    func deleteAllRecordings() {
        _ = stopRecording(releaseAudioFocus: false)
        stopPlayback(releaseAudioFocus: false)
        cachedPlayer = nil
        cachedFilename = nil
        releaseAudioFocus()
        try? FileManager.default.removeItem(at: Self.recordingsDirectory)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.finishPlayback(
                player,
                outcome: CustomPromptAudioPlaybackOutcome(didFinishSuccessfully: flag)
            )
        }
    }

    @objc nonisolated private func audioServicesWereReset(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.stopPlayback(preservingPreparedAudio: false)
        }
    }

    @objc nonisolated private func memoryWarningReceived(_ notification: Notification) {
        Task { @MainActor [weak self] in
            self?.cachedPlayer = nil
            self?.cachedFilename = nil
        }
    }

    nonisolated func audioPlayerDecodeErrorDidOccur(
        _ player: AVAudioPlayer,
        error: Error?
    ) {
        Task { @MainActor in
            self.finishPlayback(player, outcome: .failed)
        }
    }

    private func finishPlayback(
        _ completedPlayer: AVAudioPlayer,
        outcome: CustomPromptAudioPlaybackOutcome
    ) {
        guard player === completedPlayer else { return }
        let completion = playbackCompletion
        let completedFilename = playingFilename
        player = nil
        playingFilename = nil
        playbackCompletion = nil
        completedPlayer.delegate = nil
        completedPlayer.stop()
        if outcome == .finished, let completedFilename {
            completedPlayer.currentTime = 0
            cachedPlayer = completedPlayer
            cachedFilename = completedFilename
        } else {
            cachedPlayer = nil
            cachedFilename = nil
        }
        releaseAudioFocus()
        completion?(outcome)
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func acquireAudioFocus() {
        guard requiredAudioToken == nil else { return }
        requiredAudioToken = MusicService.shared.beginRequiredAudioSession()
    }

    private func releaseAudioFocus() {
        guard let token = requiredAudioToken else { return }
        requiredAudioToken = nil
        MusicService.shared.endRequiredAudioSession(token)
    }
}
