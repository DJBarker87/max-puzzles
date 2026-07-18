import AVFAudio
import Foundation

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
    private var requiredAudioToken: UUID?

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
            guard nextRecorder.record() else {
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

    @discardableResult
    func play(filename: String) -> Bool {
        if playingFilename == filename {
            stopPlayback()
            return false
        }
        _ = stopRecording(releaseAudioFocus: false)
        stopPlayback(releaseAudioFocus: false)
        acquireAudioFocus()

        let url = Self.recordingsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else {
            releaseAudioFocus()
            return false
        }
        do {
            guard AppAudioSessionCoordinator.shared.activate(.spokenPlayback) else {
                releaseAudioFocus()
                return false
            }
            let nextPlayer = try AVAudioPlayer(contentsOf: url)
            nextPlayer.delegate = self
            nextPlayer.volume = StorageService.shared.voiceVolume
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else {
                releaseAudioFocus()
                return false
            }
            player = nextPlayer
            playingFilename = filename
            return true
        } catch {
            stopPlayback()
            return false
        }
    }

    func stopPlayback() {
        stopPlayback(releaseAudioFocus: true)
    }

    private func stopPlayback(releaseAudioFocus shouldReleaseAudioFocus: Bool) {
        player?.stop()
        player = nil
        playingFilename = nil
        if shouldReleaseAudioFocus { releaseAudioFocus() }
    }

    func delete(filename: String) {
        if playingFilename == filename { stopPlayback() }
        try? FileManager.default.removeItem(
            at: Self.recordingsDirectory.appendingPathComponent(filename)
        )
    }

    func deleteAllRecordings() {
        _ = stopRecording(releaseAudioFocus: false)
        stopPlayback(releaseAudioFocus: false)
        releaseAudioFocus()
        try? FileManager.default.removeItem(at: Self.recordingsDirectory)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            guard self.player === player else { return }
            self.player = nil
            self.playingFilename = nil
            self.releaseAudioFocus()
        }
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
