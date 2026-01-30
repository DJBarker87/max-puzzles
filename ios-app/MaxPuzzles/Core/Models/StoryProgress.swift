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

    private let storageKey = "storyProgressV2"

    @Published private(set) var data: StoryProgressData {
        didSet {
            save()
        }
    }

    init() {
        // Load from UserDefaults
        if let stored = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode(StoryProgressData.self, from: stored) {
            self.data = decoded
        } else {
            self.data = StoryProgressData()
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

    /// Check if all 5 levels of a chapter are completed
    func isChapterCompleted(_ chapter: Int) -> Bool {
        for level in 1...5 {
            if !isLevelCompleted(chapter: chapter, level: level) {
                return false
            }
        }
        return true
    }

    /// Total stars earned in a chapter (0-15)
    func starsInChapter(_ chapter: Int) -> Int {
        var total = 0
        for level in 1...5 {
            total += starsForLevel(chapter: chapter, level: level)
        }
        return total
    }

    /// Total stars earned overall (0-150)
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

        // Level 1 (A) is always unlocked if chapter is unlocked
        if level == 1 { return true }

        // Require 2+ stars on previous level to unlock next
        return starsForLevel(chapter: chapter, level: level - 1) >= 2
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
            let earnedStars = StoryDifficulty.calculateStars(
                livesLost: livesLost,
                timeSeconds: timeSeconds,
                tileCount: tileCount
            )

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
        for level in 1...5 {
            let key = StoryProgressData.key(chapter: chapter, level: level)
            data.levelProgress.removeValue(forKey: key)
        }
        // Explicitly save - didSet doesn't trigger on nested property changes
        save()
    }

    // MARK: - Persistence

    private func save() {
        if let encoded = try? JSONEncoder().encode(data) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
}
