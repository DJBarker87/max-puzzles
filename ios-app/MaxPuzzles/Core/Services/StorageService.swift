import Foundation

// MARK: - StorageService

/// Service for managing local storage using UserDefaults
/// Handles guest sessions, preferences, and local progress
@MainActor
class StorageService: ObservableObject {
    // MARK: - Singleton

    static let shared = StorageService()

    // MARK: - Published Properties

    @Published private(set) var guestSessionId: UUID?
    @Published private(set) var guestDisplayName: String
    @Published private(set) var playerName: String
    @Published private(set) var hasCompletedFirstRun: Bool
    @Published private(set) var totalCoinsEarned: Int
    @Published private(set) var isSoundEnabled: Bool
    @Published private(set) var soundEffectsVolume: Float
    @Published private(set) var isVoiceEnabled: Bool
    @Published private(set) var voiceVolume: Float
    @Published private(set) var isMusicEnabled: Bool
    @Published private(set) var musicVolume: Float
    @Published private(set) var lastPlayedDifficulty: Int
    @Published private(set) var puzzlesCompletedCount: Int
    @Published private(set) var hasSeenAccountPrompt: Bool
    @Published private(set) var cometWriterCompletedLetters: Set<String>
    @Published private(set) var cometWriterBestScores: [String: Int]
    @Published private(set) var lastCometWriterLetter: String?

    // MARK: - Keys

    private enum Keys {
        static let guestSessionId = "maxpuzzles.guest.sessionId"
        static let guestDisplayName = "maxpuzzles.guest.displayName"
        static let playerName = "maxpuzzles.player.name"
        static let hasCompletedFirstRun = "maxpuzzles.firstRun.completed"
        static let soundEnabled = "maxpuzzles.settings.soundEnabled"
        static let soundEffectsVolume = "maxpuzzles.settings.soundEffectsVolume"
        static let voiceEnabled = "maxpuzzles.settings.voiceEnabled"
        static let voiceVolume = "maxpuzzles.settings.voiceVolume"
        static let musicEnabled = "maxpuzzles.settings.musicEnabled"
        static let musicVolume = "maxpuzzles.settings.musicVolume"
        static let lastDifficulty = "maxpuzzles.settings.lastDifficulty"
        static let puzzlesCompleted = "maxpuzzles.stats.puzzlesCompleted"
        static let hasSeenAccountPrompt = "maxpuzzles.prompts.accountPromptShown"
        static let totalCoinsEarned = "maxpuzzles.stats.totalCoinsEarned"
        static let totalGamesPlayed = "maxpuzzles.stats.totalGamesPlayed"
        static let bestTimeByLevel = "maxpuzzles.stats.bestTimeByLevel"
        static let circuitChallengeTutorialCompleted = "maxpuzzles.tutorial.circuitChallenge.completed"
        static let cometWriterCompletedLetters = "maxpuzzles.cometWriter.completedLetters"
        static let cometWriterBestScores = "maxpuzzles.cometWriter.bestScores"
        static let lastCometWriterLetter = "maxpuzzles.cometWriter.lastLetter"
    }

    // MARK: - UserDefaults

    private let defaults: UserDefaults

    // MARK: - Initialization

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // Load initial values
        let legacyGuestName = defaults.string(forKey: Keys.guestDisplayName)
        let savedPlayerName = defaults.string(forKey: Keys.playerName)
        let resolvedName = [savedPlayerName, legacyGuestName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty && $0 != "Guest" }
            ?? ""
        self.guestDisplayName = resolvedName.isEmpty ? "Guest" : resolvedName
        self.playerName = resolvedName
        self.hasCompletedFirstRun = defaults.bool(forKey: Keys.hasCompletedFirstRun)
        self.totalCoinsEarned = defaults.integer(forKey: Keys.totalCoinsEarned)
        self.isSoundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool
            ?? defaults.object(forKey: "soundEffectsEnabled") as? Bool
            ?? true
        self.soundEffectsVolume = defaults.object(forKey: Keys.soundEffectsVolume) as? Float
            ?? defaults.object(forKey: "soundEffectsVolume") as? Float
            ?? 0.55
        self.isVoiceEnabled = defaults.object(forKey: Keys.voiceEnabled) as? Bool ?? true
        self.voiceVolume = defaults.object(forKey: Keys.voiceVolume) as? Float ?? 0.9
        self.isMusicEnabled = defaults.object(forKey: Keys.musicEnabled) as? Bool ?? true // Music on by default
        self.musicVolume = defaults.object(forKey: Keys.musicVolume) as? Float ?? 0.2 // 20% volume default
        self.lastPlayedDifficulty = defaults.object(forKey: Keys.lastDifficulty) as? Int ?? 1 // Start new players gently
        self.puzzlesCompletedCount = defaults.integer(forKey: Keys.puzzlesCompleted)
        self.hasSeenAccountPrompt = defaults.bool(forKey: Keys.hasSeenAccountPrompt)
        self.cometWriterCompletedLetters = Set(defaults.stringArray(forKey: Keys.cometWriterCompletedLetters) ?? [])
        self.cometWriterBestScores = (defaults.dictionary(forKey: Keys.cometWriterBestScores) ?? [:])
            .reduce(into: [:]) { scores, entry in
                if let value = entry.value as? NSNumber {
                    scores[entry.key] = min(max(value.intValue, 0), 100)
                }
            }
        self.lastCometWriterLetter = defaults.string(forKey: Keys.lastCometWriterLetter)

        // Load or create guest session
        if let sessionIdString = defaults.string(forKey: Keys.guestSessionId),
           let sessionId = UUID(uuidString: sessionIdString) {
            self.guestSessionId = sessionId
        } else {
            self.guestSessionId = nil
        }
    }

    // MARK: - Guest Session Management

    /// Creates a new guest session if none exists
    /// Called on first app launch
    func ensureGuestSession() -> UUID {
        if let existingSession = guestSessionId {
            return existingSession
        }

        let newSessionId = UUID()
        defaults.set(newSessionId.uuidString, forKey: Keys.guestSessionId)
        guestSessionId = newSessionId
        return newSessionId
    }

    /// Clears the guest session (when logging in with an account)
    func clearGuestSession() {
        defaults.removeObject(forKey: Keys.guestSessionId)
        guestSessionId = nil
    }

    /// Checks if a guest session exists
    var hasGuestSession: Bool {
        guestSessionId != nil
    }

    // MARK: - Guest Name

    /// Sets the guest display name
    func setGuestDisplayName(_ name: String) {
        setPlayerName(name)
    }

    // MARK: - Player Name

    /// Sets the player's name (from first run setup)
    func setPlayerName(_ name: String) {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        defaults.set(trimmedName, forKey: Keys.playerName)
        defaults.set(trimmedName.isEmpty ? "Guest" : trimmedName, forKey: Keys.guestDisplayName)
        playerName = trimmedName
        guestDisplayName = trimmedName.isEmpty ? "Guest" : trimmedName
    }

    /// Marks first run as completed
    func completeFirstRun() {
        defaults.set(true, forKey: Keys.hasCompletedFirstRun)
        hasCompletedFirstRun = true
    }

    /// Check if first run needs to be shown
    var needsFirstRunSetup: Bool {
        !hasCompletedFirstRun
    }

    // MARK: - Sound Settings

    /// Enables or disables sound effects
    func setSoundEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.soundEnabled)
        isSoundEnabled = enabled
    }

    func setSoundEffectsVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        defaults.set(clampedVolume, forKey: Keys.soundEffectsVolume)
        soundEffectsVolume = clampedVolume
    }

    func setVoiceEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.voiceEnabled)
        isVoiceEnabled = enabled
    }

    func setVoiceVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        defaults.set(clampedVolume, forKey: Keys.voiceVolume)
        voiceVolume = clampedVolume
    }

    // MARK: - Music Settings

    /// Enables or disables background music
    func setMusicEnabled(_ enabled: Bool) {
        defaults.set(enabled, forKey: Keys.musicEnabled)
        isMusicEnabled = enabled
    }

    /// Sets the music volume (0.0 to 1.0)
    func setMusicVolume(_ volume: Float) {
        let clampedVolume = max(0, min(1, volume))
        defaults.set(clampedVolume, forKey: Keys.musicVolume)
        musicVolume = clampedVolume
    }

    // MARK: - Difficulty Settings

    /// Saves the last played difficulty level (1-10 or custom)
    func setLastPlayedDifficulty(_ level: Int) {
        defaults.set(level, forKey: Keys.lastDifficulty)
        lastPlayedDifficulty = level
    }

    // MARK: - Progress Tracking

    /// Increments the completed puzzles count
    func incrementPuzzlesCompleted() {
        puzzlesCompletedCount += 1
        defaults.set(puzzlesCompletedCount, forKey: Keys.puzzlesCompleted)
    }

    /// Gets the total number of games played
    var totalGamesPlayed: Int {
        get { defaults.integer(forKey: Keys.totalGamesPlayed) }
    }

    /// Increments total games played
    func incrementGamesPlayed() {
        let current = totalGamesPlayed
        defaults.set(current + 1, forKey: Keys.totalGamesPlayed)
    }

    /// Adds coins to the total (guest mode only)
    func addCoins(_ amount: Int) {
        let newTotal = totalCoinsEarned + amount
        defaults.set(newTotal, forKey: Keys.totalCoinsEarned)
        totalCoinsEarned = newTotal
    }

    // MARK: - Best Times

    /// Gets the best time for a specific level (in milliseconds)
    func getBestTime(forLevel level: Int) -> Int? {
        guard let dict = defaults.dictionary(forKey: Keys.bestTimeByLevel) as? [String: Int] else {
            return nil
        }
        return dict["\(level)"]
    }

    /// Updates the best time for a level if the new time is better
    func updateBestTime(forLevel level: Int, timeMs: Int) {
        var dict = (defaults.dictionary(forKey: Keys.bestTimeByLevel) as? [String: Int]) ?? [:]
        let key = "\(level)"

        if let existing = dict[key] {
            if timeMs < existing {
                dict[key] = timeMs
                defaults.set(dict, forKey: Keys.bestTimeByLevel)
            }
        } else {
            dict[key] = timeMs
            defaults.set(dict, forKey: Keys.bestTimeByLevel)
        }
    }

    // MARK: - Account Prompt

    /// Marks that the account creation prompt has been shown
    func markAccountPromptShown() {
        defaults.set(true, forKey: Keys.hasSeenAccountPrompt)
        hasSeenAccountPrompt = true
    }

    /// Check if we should show the account prompt (after 5 puzzles, not shown before)
    var shouldShowAccountPrompt: Bool {
        !hasSeenAccountPrompt && puzzlesCompletedCount >= 5
    }

    // MARK: - Comet Writer Progress

    /// Marks a lowercase letter, capital letter, or number as mastered.
    /// Replaying a symbol never inflates progress and case is deliberately preserved.
    func markCometWriterLetterCompleted(_ letter: String) {
        guard let normalized = normalizedWritingSymbol(letter) else { return }

        cometWriterCompletedLetters.insert(normalized)
        defaults.set(cometWriterCompletedLetters.sorted(), forKey: Keys.cometWriterCompletedLetters)
    }

    func setLastCometWriterLetter(_ letter: String) {
        guard let normalized = normalizedWritingSymbol(letter) else { return }
        lastCometWriterLetter = normalized
        defaults.set(normalized, forKey: Keys.lastCometWriterLetter)
    }

    /// Keeps the strongest formation score for each letter or number across all writing modes.
    /// Replaying a character can improve its score, but can never lower an earlier result.
    func recordCometWriterScore(_ score: Int, for character: String) {
        guard let normalized = normalizedWritingSymbol(character) else { return }

        let clampedScore = min(max(score, 0), 100)
        guard clampedScore > (cometWriterBestScores[normalized] ?? -1) else { return }
        cometWriterBestScores[normalized] = clampedScore
        defaults.set(cometWriterBestScores, forKey: Keys.cometWriterBestScores)
    }

    func bestCometWriterScore(for character: String) -> Int? {
        guard let normalized = normalizedWritingSymbol(character) else { return nil }
        return cometWriterBestScores[normalized]
    }

    private func normalizedWritingSymbol(_ value: String) -> String? {
        guard value.count == 1, let scalar = value.unicodeScalars.first else { return nil }
        let codePoint = Int(scalar.value)
        guard (48...57).contains(codePoint)
                || (65...90).contains(codePoint)
                || (97...122).contains(codePoint) else {
            return nil
        }
        return value
    }

    // MARK: - Reset

    /// Clears all stored data (for testing or logout)
    func clearAllData() {
        // All first-party keys share this namespace. Clearing by namespace means newly-added
        // Comet Writer preferences and progress cannot silently survive a destructive reset.
        let keysToRemove = defaults.dictionaryRepresentation().keys.filter {
            $0.hasPrefix("maxpuzzles.") || $0 == "soundEffectsEnabled" || $0 == "soundEffectsVolume"
        }
        for key in keysToRemove {
            defaults.removeObject(forKey: key)
        }

        // Reset published properties
        guestSessionId = nil
        guestDisplayName = "Guest"
        playerName = ""
        hasCompletedFirstRun = false
        totalCoinsEarned = 0
        isSoundEnabled = true
        soundEffectsVolume = 0.55
        isVoiceEnabled = true
        voiceVolume = 0.9
        isMusicEnabled = true
        musicVolume = 0.2
        lastPlayedDifficulty = 1
        puzzlesCompletedCount = 0
        hasSeenAccountPrompt = false
        cometWriterCompletedLetters = []
        cometWriterBestScores = [:]
        lastCometWriterLetter = nil
    }
}

// MARK: - QuickPlayStats

/// Statistics for Quick Play mode
struct QuickPlayStats: Codable {
    var gamesPlayed: Int = 0
    var gamesWon: Int = 0
    var totalCoins: Int = 0
    var bestTimeMs: Int? = nil
    var averageTimeMs: Int? = nil
    var winStreak: Int = 0
    var bestWinStreak: Int = 0

    var winRate: Double {
        guard gamesPlayed > 0 else { return 0 }
        return Double(gamesWon) / Double(gamesPlayed)
    }
}
