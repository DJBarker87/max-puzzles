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

    private static var recordingsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("CometWriterRecordings", isDirectory: true)
    }

    func startRecording(for word: CometCustomWord) async -> Bool {
        stopPlayback()
        if recordingWordID != nil { _ = stopRecording() }

        let allowed = await requestPermission()
        guard allowed else {
            permissionDenied = true
            return false
        }
        permissionDenied = false

        do {
            try FileManager.default.createDirectory(
                at: Self.recordingsDirectory,
                withIntermediateDirectories: true
            )
            let filename = "prompt-\(word.id.uuidString).m4a"
            let url = Self.recordingsDirectory.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: url)

            let session = AVAudioSession.sharedInstance()
            try session.setCategory(
                .playAndRecord,
                mode: .spokenAudio,
                options: [.defaultToSpeaker, .allowBluetoothHFP]
            )
            try session.setActive(true)

            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 22_050,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let nextRecorder = try AVAudioRecorder(url: url, settings: settings)
            nextRecorder.isMeteringEnabled = false
            nextRecorder.prepareToRecord()
            guard nextRecorder.record() else {
                restoreAmbientAudioSession()
                return false
            }
            recorder = nextRecorder
            recordingWordID = word.id
            return true
        } catch {
            recorder = nil
            recordingWordID = nil
            restoreAmbientAudioSession()
            return false
        }
    }

    /// Returns the completed local filename so the learning store can associate it with a word.
    func stopRecording() -> String? {
        guard let recorder else { return nil }
        recorder.stop()
        let filename = recorder.url.lastPathComponent
        self.recorder = nil
        recordingWordID = nil
        restoreAmbientAudioSession()

        guard FileManager.default.fileExists(atPath: recorder.url.path) else { return nil }
        return filename
    }

    func play(filename: String) {
        if playingFilename == filename {
            stopPlayback()
            return
        }
        _ = stopRecording()
        stopPlayback()

        let url = Self.recordingsDirectory.appendingPathComponent(filename)
        guard FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .spokenAudio, options: [.mixWithOthers])
            try session.setActive(true)
            let nextPlayer = try AVAudioPlayer(contentsOf: url)
            nextPlayer.delegate = self
            nextPlayer.volume = StorageService.shared.voiceVolume
            nextPlayer.prepareToPlay()
            guard nextPlayer.play() else { return }
            player = nextPlayer
            playingFilename = filename
        } catch {
            stopPlayback()
        }
    }

    func stopPlayback() {
        player?.stop()
        player = nil
        playingFilename = nil
    }

    func delete(filename: String) {
        if playingFilename == filename { stopPlayback() }
        try? FileManager.default.removeItem(
            at: Self.recordingsDirectory.appendingPathComponent(filename)
        )
    }

    func deleteAllRecordings() {
        _ = stopRecording()
        stopPlayback()
        try? FileManager.default.removeItem(at: Self.recordingsDirectory)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            self.playingFilename = nil
        }
    }

    private func requestPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }
    }

    private func restoreAmbientAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            // The next app audio action retries configuration; recording data is already safe.
        }
    }
}
