import AVFoundation
import Foundation

// MARK: - MusicService

/// Service for managing background music playback
/// Uses AVAudioPlayer for looping background music
@MainActor
class MusicService: ObservableObject {
    // MARK: - Singleton

    static let shared = MusicService()

    // MARK: - Published Properties

    @Published private(set) var isPlaying = false
    @Published var volume: Float = 0.2 {
        didSet {
            player?.volume = volume
            storage.setMusicVolume(volume)
        }
    }

    // MARK: - Private Properties

    private var player: AVAudioPlayer?
    private let storage = StorageService.shared
    private var currentTrack: MusicTrack?

    // MARK: - Initialization

    private init() {
        // Load saved volume
        volume = storage.musicVolume

        // Configure audio session for background music
        configureAudioSession()
    }

    // MARK: - Audio Session

    private func configureAudioSession() {
        #if os(iOS)
        do {
            // Use ambient category so music mixes with other apps and respects silent switch
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
        #endif
    }

    // MARK: - Playback Control

    /// Plays background music from the specified file
    /// - Parameters:
    ///   - filename: The name of the audio file (without extension)
    ///   - fileExtension: The file extension (default: "m4a")
    ///   - loop: Whether to loop the music (default: true)
    func play(filename: String, fileExtension: String = "m4a", loop: Bool = true) {
        // Don't play if music is disabled
        guard storage.isMusicEnabled else { return }

        // Stop any current playback
        stop()

        guard let url = Bundle.main.url(forResource: filename, withExtension: fileExtension) else {
            print("Music file not found: \(filename).\(fileExtension)")
            return
        }

        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.volume = volume
            player?.numberOfLoops = loop ? -1 : 0 // -1 = infinite loop
            player?.prepareToPlay()
            player?.play()
            isPlaying = true
        } catch {
            print("Failed to play music: \(error)")
        }
    }

    /// Stops the currently playing music
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    /// Pauses the currently playing music
    func pause() {
        player?.pause()
        isPlaying = false
    }

    /// Resumes paused music
    /// If no player exists but we have a current track, starts playing it
    func resume() {
        guard storage.isMusicEnabled else { return }

        if let player = player {
            // Resume existing player
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

        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = volume / Float(fadeSteps)

        Task {
            for _ in 0..<fadeSteps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                let newVolume = max(0, player.volume - volumeStep)
                player.volume = newVolume
            }
            stop()
            // Restore volume for next play
            player.volume = volume
        }
    }

    /// Fades in the music over a duration
    /// - Parameters:
    ///   - filename: The name of the audio file
    ///   - duration: Fade duration in seconds
    func fadeIn(filename: String, fileExtension: String = "m4a", duration: TimeInterval = 1.0) {
        guard storage.isMusicEnabled else { return }

        let targetVolume = volume

        // Start at zero volume
        volume = 0
        play(filename: filename, fileExtension: fileExtension)

        let fadeSteps = 20
        let stepDuration = duration / Double(fadeSteps)
        let volumeStep = targetVolume / Float(fadeSteps)

        Task {
            for _ in 0..<fadeSteps {
                try? await Task.sleep(nanoseconds: UInt64(stepDuration * 1_000_000_000))
                let newVolume = min(targetVolume, (player?.volume ?? 0) + volumeStep)
                player?.volume = newVolume
            }
            volume = targetVolume
        }
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
        currentTrack = track
        play(filename: track.filename, fileExtension: track.fileExtension, loop: loop)
    }

    /// Fades in a predefined music track
    func fadeIn(track: MusicTrack, duration: TimeInterval = 1.0) {
        fadeIn(filename: track.filename, fileExtension: track.fileExtension, duration: duration)
    }
}
