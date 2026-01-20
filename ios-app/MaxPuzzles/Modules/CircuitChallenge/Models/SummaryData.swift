import Foundation

// MARK: - SummaryData

/// Data passed to the summary screen after game completion
struct SummaryData {
    /// Whether the player won (reached FINISH)
    let won: Bool

    /// Whether the game was in hidden mode
    let isHiddenMode: Bool

    /// Total time elapsed in milliseconds
    let elapsedMs: Int

    /// Coins earned (or remaining after penalties) for this puzzle
    let puzzleCoins: Int

    /// Complete move history
    let moveHistory: [GameMoveResult]

    /// Hidden mode results (only for hidden mode)
    let hiddenModeResults: HiddenModeResults?

    /// The puzzle that was played
    let puzzle: Puzzle?

    /// Difficulty level played
    let difficulty: DifficultySettings

    // MARK: - Story Mode

    /// The alien for story mode (nil for quick play)
    let storyAlien: ChapterAlien?

    /// The chapter number for story mode
    let storyChapter: Int?

    /// The level number for story mode (1-5)
    let storyLevel: Int?

    /// Whether this is a story mode game
    var isStoryMode: Bool {
        storyAlien != nil
    }

    // Default initializer for non-story mode
    init(
        won: Bool,
        isHiddenMode: Bool,
        elapsedMs: Int,
        puzzleCoins: Int,
        moveHistory: [GameMoveResult],
        hiddenModeResults: HiddenModeResults?,
        puzzle: Puzzle?,
        difficulty: DifficultySettings,
        storyAlien: ChapterAlien? = nil,
        storyChapter: Int? = nil,
        storyLevel: Int? = nil
    ) {
        self.won = won
        self.isHiddenMode = isHiddenMode
        self.elapsedMs = elapsedMs
        self.puzzleCoins = puzzleCoins
        self.moveHistory = moveHistory
        self.hiddenModeResults = hiddenModeResults
        self.puzzle = puzzle
        self.difficulty = difficulty
        self.storyAlien = storyAlien
        self.storyChapter = storyChapter
        self.storyLevel = storyLevel
    }

    // MARK: - Computed Properties

    /// Total number of moves made
    var totalMoves: Int {
        moveHistory.count
    }

    /// Number of correct moves
    var correctMoves: Int {
        if let results = hiddenModeResults {
            return results.correctCount
        }
        return moveHistory.filter { $0.correct }.count
    }

    /// Number of mistakes made
    var mistakes: Int {
        if let results = hiddenModeResults {
            return results.mistakeCount
        }
        return totalMoves - correctMoves
    }

    /// Accuracy percentage (0-100)
    var accuracy: Int {
        guard totalMoves > 0 else { return 0 }
        return Int(round(Double(correctMoves) / Double(totalMoves) * 100))
    }

    /// Formatted time string (M:SS)
    var formattedTime: String {
        let totalSeconds = elapsedMs / 1000
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Average time per tile in milliseconds
    /// Calculated as total time / number of correct moves (tiles traversed)
    var averageTileTimeMs: Double {
        guard correctMoves > 0 else { return 0 }
        return Double(elapsedMs) / Double(correctMoves)
    }

    /// Stars earned for this puzzle (1-3)
    /// - 1 star: Completed the puzzle
    /// - 2 stars: Completed with no lives lost (no mistakes)
    /// - 3 stars: Completed with no lives lost AND average tile time < 5 seconds
    var starsEarned: Int {
        guard won else { return 0 }

        // 1 star for completing
        var stars = 1

        // 2 stars for no mistakes (no lives lost)
        if mistakes == 0 {
            stars = 2

            // 3 stars for no mistakes AND average tile time < 5 seconds (5000ms)
            if averageTileTimeMs < 5000 {
                stars = 3
            }
        }

        return stars
    }
}
