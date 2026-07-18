import Foundation

// MARK: - Story Progress Data

/// Persisted data structure for story progress
struct StoryProgressData: Codable {
    var levelProgress: [String: LevelProgressData]  // Key: "chapter-level" e.g., "3-2"

    init() {
        self.levelProgress = [:]
    }

    static func key(chapter: Int, level: Int) -> String {
        "\(chapter)-\(level)"
    }
}

/// Persisted data for a single level
struct LevelProgressData: Codable {
    var completed: Bool = false
    var stars: Int = 0  // 0-3
    var bestTimeSeconds: Double?
    var attempts: Int = 0
}

// MARK: - Story Progress Manager

/// Tracks story mode progress - chapters, levels, and stars
class StoryProgress: ObservableObject {

    private static let legacyStorageKey = "storyProgressV2"
    private static let legacyMigrationKey = "maxpuzzles.profiles.storyProgressLegacyMigrated"

    private let storageKey: String
    private let defaults: UserDefaults
    private var cloudObserver: NSObjectProtocol?

    @Published private(set) var data: StoryProgressData {
        didSet {
            save()
        }
    }

    init(profileID: UUID? = nil, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let profileID {
            storageKey = "maxpuzzles.profile.\(profileID.uuidString).storyProgressV2"
        } else {
            storageKey = Self.legacyStorageKey
        }

        if let stored = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(StoryProgressData.self, from: stored) {
            self.data = decoded
            if profileID != nil {
                defaults.set(true, forKey: Self.legacyMigrationKey)
            }
        } else if profileID != nil,
                  !defaults.bool(forKey: Self.legacyMigrationKey),
                  let legacyData = defaults.data(forKey: Self.legacyStorageKey),
                  let decoded = try? JSONDecoder().decode(
                    StoryProgressData.self,
                    from: legacyData
                  ) {
            self.data = decoded
            defaults.set(legacyData, forKey: storageKey)
            defaults.set(true, forKey: Self.legacyMigrationKey)
        } else {
            self.data = StoryProgressData()
            if profileID != nil {
                defaults.set(true, forKey: Self.legacyMigrationKey)
            }
        }

        cloudObserver = NotificationCenter.default.addObserver(
            forName: .maxPuzzlesCloudProgressDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.reloadAfterCloudSync()
        }
    }

    deinit {
        if let cloudObserver {
            NotificationCenter.default.removeObserver(cloudObserver)
        }
    }

    // MARK: - Chapter Progress

    /// Highest unlocked chapter (1 = only Bob, 10 = all unlocked)
    var highestUnlockedChapter: Int {
        // Find highest completed chapter
        var maxCompleted = 0
        for chapter in 1...10 {
            if isChapterCompleted(chapter) {
                maxCompleted = chapter
            }
        }
        return min(maxCompleted + 1, 10)
    }

    /// Check if a chapter is unlocked
    func isChapterUnlocked(_ chapter: Int) -> Bool {
        chapter <= highestUnlockedChapter
    }

    /// Check if all 7 levels of a chapter are completed
    func isChapterCompleted(_ chapter: Int) -> Bool {
        for level in 1...7 {
            if !isLevelCompleted(chapter: chapter, level: level) {
                return false
            }
        }
        return true
    }

    /// Total stars earned in a chapter (0-21)
    func starsInChapter(_ chapter: Int) -> Int {
        var total = 0
        for level in 1...7 {
            total += starsForLevel(chapter: chapter, level: level)
        }
        return total
    }

    /// Total stars earned overall (0-210)
    var totalStars: Int {
        var total = 0
        for chapter in 1...10 {
            total += starsInChapter(chapter)
        }
        return total
    }

    /// Count of completed chapters (0-10)
    var completedChaptersCount: Int {
        (1...10).filter { isChapterCompleted($0) }.count
    }

    // MARK: - Level Progress

    /// Check if a specific level is unlocked
    func isLevelUnlocked(chapter: Int, level: Int) -> Bool {
        // Chapter must be unlocked
        guard isChapterUnlocked(chapter) else { return false }

        guard (1...7).contains(level) else { return false }

        // Level 1 (A) is always unlocked if chapter is unlocked
        if level == 1 { return true }

        // Require the complete preceding sequence, not just the immediately
        // previous level. This prevents sparse legacy or merged iCloud progress
        // (for example, only level 6 being marked complete) from exposing the boss.
        // Stars remain a replay and mastery reward; completion alone unlocks progress.
        return (1..<level).allSatisfy {
            isLevelCompleted(chapter: chapter, level: $0)
        }
    }

    /// Check if a specific level is completed
    func isLevelCompleted(chapter: Int, level: Int) -> Bool {
        let key = StoryProgressData.key(chapter: chapter, level: level)
        return data.levelProgress[key]?.completed ?? false
    }

    /// Get stars for a specific level (0-3)
    func starsForLevel(chapter: Int, level: Int) -> Int {
        let key = StoryProgressData.key(chapter: chapter, level: level)
        return data.levelProgress[key]?.stars ?? 0
    }

    /// Get best time for a level (nil if never completed)
    func bestTimeForLevel(chapter: Int, level: Int) -> Double? {
        let key = StoryProgressData.key(chapter: chapter, level: level)
        return data.levelProgress[key]?.bestTimeSeconds
    }

    /// Get attempt count for a level
    func attemptsForLevel(chapter: Int, level: Int) -> Int {
        let key = StoryProgressData.key(chapter: chapter, level: level)
        return data.levelProgress[key]?.attempts ?? 0
    }

    // MARK: - Record Progress

    /// Record a level attempt
    func recordAttempt(
        chapter: Int,
        level: Int,
        won: Bool,
        livesLost: Int,
        timeSeconds: Double,
        tileCount: Int
    ) {
        let key = StoryProgressData.key(chapter: chapter, level: level)
        var levelData = data.levelProgress[key] ?? LevelProgressData()

        levelData.attempts += 1

        if won {
            levelData.completed = true

            // Calculate stars for this attempt
            let earnedStars = StoryDifficulty.calculateStars(livesLost: livesLost)

            // Keep best stars
            levelData.stars = max(levelData.stars, earnedStars)

            // Keep best time
            if let best = levelData.bestTimeSeconds {
                levelData.bestTimeSeconds = min(best, timeSeconds)
            } else {
                levelData.bestTimeSeconds = timeSeconds
            }
        }

        data.levelProgress[key] = levelData

        // Explicitly save - didSet doesn't trigger on nested property changes
        save()
    }

    // MARK: - Reset

    /// Reset all progress (for testing/debug)
    func resetProgress() {
        data = StoryProgressData()
    }

    /// Reset progress for a specific chapter
    func resetChapter(_ chapter: Int) {
        for level in 1...7 {
            let key = StoryProgressData.key(chapter: chapter, level: level)
            data.levelProgress.removeValue(forKey: key)
        }
        // Explicitly save - didSet doesn't trigger on nested property changes
        save()
    }

    // MARK: - Persistence

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data),
              defaults.data(forKey: storageKey) != encoded else { return }
        defaults.set(encoded, forKey: storageKey)
        NotificationCenter.default.post(name: .maxPuzzlesProgressDidChange, object: self)
    }

    private func reloadAfterCloudSync() {
        guard let stored = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode(StoryProgressData.self, from: stored) else {
            return
        }
        data = decoded
    }
}
