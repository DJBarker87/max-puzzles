import AVFoundation
import Foundation

// MARK: - App Audio Session Coordinator

/// The single place where app-owned audio changes AVAudioSession configuration.
/// Keeping category changes here prevents music, spoken prompts and recording from racing.
@MainActor
final class AppAudioSessionCoordinator {
    enum Purpose: Equatable {
        case music
        case spokenPlayback
        case promptRecording
    }

    static let shared = AppAudioSessionCoordinator()

    private var activePurpose: Purpose?

    private init() {}

    @discardableResult
    func activate(_ purpose: Purpose) -> Bool {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        do {
            switch purpose {
            case .music:
                try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            case .spokenPlayback:
                try session.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            case .promptRecording:
                try session.setCategory(
                    .playAndRecord,
                    mode: .default,
                    options: [.defaultToSpeaker, .allowBluetoothHFP]
                )
            }
            try session.setActive(true)
            activePurpose = purpose
            return true
        } catch {
            activePurpose = nil
            return false
        }
        #else
        activePurpose = purpose
        return true
        #endif
    }

    /// Effects can share music and spoken-playback sessions, but are blocked while the microphone
    /// is recording. Crucially, checking this never downgrades an active spoken/recording session.
    func prepareForSoundEffects() -> Bool {
        switch activePurpose {
        case .promptRecording:
            return false
        case .music, .spokenPlayback:
            return true
        case nil:
            return activate(.music)
        }
    }
}

// MARK: - MusicService

/// Service for managing background music playback
/// Uses AVAudioPlayer for looping background music
@MainActor
class MusicService: ObservableObject {
    // MARK: - Singleton

    static let shared = MusicService()

    // MARK: - Published Properties

    @Published private(set) var isPlaying = false
    @Published var volume: Float = 0.5 {
        didSet {
            fadeTask?.cancel()
            fadeTask = nil
            player?.volume = volume
            storage.setMusicVolume(volume)
        }
    }

    // MARK: - Private Properties

    private var player: AVAudioPlayer?
    private let storage = StorageService.shared
    private var currentTrack: MusicTrack?
    private var requiredAudioSessions: Set<UUID> = []
    private var fadeTask: Task<Void, Never>?
    private var playbackGeneration = 0
    private var isSceneActive = true

    private var isSuppressedForRequiredAudio: Bool {
        !requiredAudioSessions.isEmpty
    }

    // MARK: - Initialization

    private init() {
        // Load saved volume
        volume = storage.musicVolume
        // Audio setup is deliberately deferred until playback is requested.
    }

    // MARK: - Audio Session

    @discardableResult
    private func configureAudioSession() -> Bool {
        AppAudioSessionCoordinator.shared.activate(.music)
    }

    // MARK: - Playback Control

    /// Plays background music from the specified file
    /// - Parameters:
    ///   - filename: The name of the audio file (without extension)
    ///   - fileExtension: The file extension (default: "m4a")
    ///   - loop: Whether to loop the music (default: true)
    func play(filename: String, fileExtension: String = "m4a", loop: Bool = true) {
        // Don't play if music is disabled
        guard isSceneActive, storage.isMusicEnabled, !isSuppressedForRequiredAudio else {
            return
        }

        guard configureAudioSession() else { return }

        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Music file not found: \(filename).\(fileExtension)")
            return
        }

        startPlayback(url: url, loop: loop, initialVolume: volume)
    }

    /// Stops the currently playing music
    func stop() {
        stopPlayback(cancelFade: true)
    }

    /// Pauses the currently playing music
    func pause() {
        cancelFade()
        player?.pause()
        player?.volume = volume
        isPlaying = false
    }

    /// Resumes paused music
    /// If no player exists but we have a current track, starts playing it
    func resume() {
        guard isSceneActive, storage.isMusicEnabled, !isSuppressedForRequiredAudio else { return }
        cancelFade()
        guard configureAudioSession() else { return }

        if let player = player {
            // Resume existing player
            player.volume = volume
            player.play()
            isPlaying = player.isPlaying
        } else if let track = currentTrack {
            // No player but we have a track - restart it
            play(track: track)
        }
        // If no player and no track, do nothing - music will start when views appear
    }

    /// Toggles music playback
    func toggle() {
        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    /// Scene lifecycle is authoritative for whether app-owned music may start. Audio callbacks
    /// can arrive after backgrounding, so every playback entry point also checks this flag.
    func setSceneActive(_ active: Bool) {
        isSceneActive = active
        if !active { pause() }
    }

    // MARK: - Music State

    /// Called when music setting is toggled in settings
    func onMusicSettingChanged(enabled: Bool) {
        if enabled {
            // If we have a paused player, resume it
            if player != nil {
                resume()
            } else if let track = currentTrack {
                // No player exists - start playing the current track
                play(track: track)
            } else {
                // No track set - default to hub music
                play(track: .hub)
            }
        } else {
            pause()
        }
    }

    /// Fades out the music over a duration
    /// - Parameter duration: Fade duration in seconds
    func fadeOut(duration: TimeInterval = 1.0) {
        guard let player = player, isPlaying else { return }
        cancelFade()

        guard duration > 0 else {
            stop()
            return
        }

        let generation = playbackGeneration
        let startVolume = player.volume
        let fadeSteps = 20
        let stepNanoseconds = UInt64((duration / Double(fadeSteps)) * 1_000_000_000)

        fadeTask = Task { @MainActor [weak self, weak player] in
            guard let self, let player else { return }
            for step in 1...fadeSteps {
                do {
                    try await Task.sleep(nanoseconds: stepNanoseconds)
                } catch {
                    return
                }
                guard !Task.isCancelled,
                      self.playbackGeneration == generation,
                      self.player === player else { return }
                let progress = Float(step) / Float(fadeSteps)
                player.volume = startVolume * (1 - progress)
            }
            guard self.playbackGeneration == generation, self.player === player else { return }
            self.stopPlayback(cancelFade: false)
            self.fadeTask = nil
        }
    }

    /// Fades in the music over a duration
    /// - Parameters:
    ///   - filename: The name of the audio file
    ///   - duration: Fade duration in seconds
    func fadeIn(filename: String, fileExtension: String = "m4a", duration: TimeInterval = 1.0) {
        guard isSceneActive, storage.isMusicEnabled, !isSuppressedForRequiredAudio else { return }
        guard configureAudioSession() else { return }

        let targetVolume = volume
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Music file not found: \(filename).\(fileExtension)")
            return
        }

        startPlayback(url: url, loop: true, initialVolume: duration > 0 ? 0 : targetVolume)
        guard duration > 0, let player, isPlaying else { return }

        let generation = playbackGeneration
        let fadeSteps = 20
        let stepNanoseconds = UInt64((duration / Double(fadeSteps)) * 1_000_000_000)

        fadeTask = Task { @MainActor [weak self, weak player] in
            guard let self, let player else { return }
            for step in 1...fadeSteps {
                do {
                    try await Task.sleep(nanoseconds: stepNanoseconds)
                } catch {
                    return
                }
                guard !Task.isCancelled,
                      self.playbackGeneration == generation,
                      self.player === player else { return }
                player.volume = targetVolume * Float(step) / Float(fadeSteps)
            }
            guard self.playbackGeneration == generation, self.player === player else { return }
            player.volume = targetVolume
            self.fadeTask = nil
        }
    }

    // MARK: - Required Audio Focus

    /// Prevents background music from playing while a game depends on speech or recorded prompts.
    /// Tokens make nested flows (for example spelling followed by handwriting) safe to overlap.
    @discardableResult
    func beginRequiredAudioSession() -> UUID {
        let token = UUID()
        requiredAudioSessions.insert(token)
        stop()
        return token
    }

    /// Releases required-audio focus and restores menu music only after the final nested session.
    func endRequiredAudioSession(
        _ token: UUID,
        resume track: MusicTrack? = .hub
    ) {
        guard requiredAudioSessions.remove(token) != nil else { return }
        guard requiredAudioSessions.isEmpty else { return }
        guard isSceneActive else { return }

        // Only the final focus owner restores the ordinary app session. This keeps a nested
        // recorded prompt from downgrading the session while its enclosing speech game is active.
        _ = AppAudioSessionCoordinator.shared.activate(.music)
        guard let track else { return }
        play(track: track)
    }

    // MARK: - Player Lifecycle

    private func startPlayback(url: URL, loop: Bool, initialVolume: Float) {
        stopPlayback(cancelFade: true)
        do {
            let nextPlayer = try AVAudioPlayer(contentsOf: url)
            nextPlayer.volume = initialVolume
            nextPlayer.numberOfLoops = loop ? -1 : 0
            nextPlayer.prepareToPlay()
            player = nextPlayer
            playbackGeneration &+= 1
            isPlaying = nextPlayer.play()
            if !isPlaying {
                player = nil
            }
        } catch {
            player = nil
            isPlaying = false
        }
    }

    private func stopPlayback(cancelFade shouldCancelFade: Bool) {
        if shouldCancelFade { cancelFade() }
        playbackGeneration &+= 1
        player?.stop()
        player = nil
        isPlaying = false
    }

    private func cancelFade() {
        fadeTask?.cancel()
        fadeTask = nil
    }
}

// MARK: - Music Tracks

/// Available music tracks in the app
enum MusicTrack: String {
    case hub = "hub_music"
    case game = "game_music"
    case victory = "victory_music"
    case lose = "lose_music"

    var filename: String { rawValue }

    var fileExtension: String {
        switch self {
        case .lose:
            return "wav"
        default:
            return "m4a"
        }
    }
}

// MARK: - MusicService Extension for Tracks

extension MusicService {
    /// Plays a predefined music track
    func play(track: MusicTrack, loop: Bool = true) {
        guard !isSuppressedForRequiredAudio else { return }
        currentTrack = track
        play(filename: track.filename, fileExtension: track.fileExtension, loop: loop)
    }

    /// Fades in a predefined music track
    func fadeIn(track: MusicTrack, duration: TimeInterval = 1.0) {
        guard !isSuppressedForRequiredAudio else { return }
        currentTrack = track
        fadeIn(filename: track.filename, fileExtension: track.fileExtension, duration: duration)
    }
}
