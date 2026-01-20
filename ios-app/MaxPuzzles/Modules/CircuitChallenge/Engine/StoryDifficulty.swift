import Foundation

// MARK: - Story Level Identifier

/// Identifies a specific level in story mode (e.g., "3-C" = Chapter 3, Level C)
struct StoryLevel: Hashable, Codable {
    let chapter: Int  // 1-10
    let level: Int    // 1-5 (A=1, B=2, C=3, D=4, E=5)

    /// Level letter (A-E)
    var levelLetter: String {
        ["A", "B", "C", "D", "E"][level - 1]
    }

    /// Display string (e.g., "3-C")
    var displayName: String {
        "\(chapter)-\(levelLetter)"
    }

    /// Create from chapter and letter
    static func from(chapter: Int, letter: String) -> StoryLevel? {
        guard let index = ["A", "B", "C", "D", "E"].firstIndex(of: letter.uppercased()) else {
            return nil
        }
        return StoryLevel(chapter: chapter, level: index + 1)
    }
}

// MARK: - Story Difficulty Generator

/// Generates DifficultySettings for story mode levels
enum StoryDifficulty {

    // MARK: - Chapter Configurations

    private struct ChapterConfig {
        let operations: Set<Operation>
        let addSubMax: Int
        let multDivMax: Int
        let startGrid: (rows: Int, cols: Int)
        let endGrid: (rows: Int, cols: Int)
        let allHidden: Bool

        enum Operation {
            case add, subtract, multiply, divide
        }
    }

    private static let chapters: [Int: ChapterConfig] = [
        1: ChapterConfig(
            operations: [.add],
            addSubMax: 10,
            multDivMax: 0,
            startGrid: (rows: 3, cols: 4),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        2: ChapterConfig(
            operations: [.add, .subtract],
            addSubMax: 15,
            multDivMax: 0,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        3: ChapterConfig(
            operations: [.add, .subtract],
            addSubMax: 20,
            multDivMax: 0,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        4: ChapterConfig(
            operations: [.add, .subtract],
            addSubMax: 35,
            multDivMax: 0,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        5: ChapterConfig(
            operations: [.add, .subtract, .multiply],
            addSubMax: 20,
            multDivMax: 20,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        6: ChapterConfig(
            operations: [.add, .subtract, .multiply],
            addSubMax: 30,
            multDivMax: 50,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        7: ChapterConfig(
            operations: [.add, .subtract, .multiply],
            addSubMax: 40,
            multDivMax: 100,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        8: ChapterConfig(
            operations: [.add, .subtract, .multiply, .divide],
            addSubMax: 50,
            multDivMax: 100,
            startGrid: (rows: 4, cols: 5),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        9: ChapterConfig(
            operations: [.add, .subtract, .multiply, .divide],
            addSubMax: 100,
            multDivMax: 144,
            startGrid: (rows: 6, cols: 7),
            endGrid: (rows: 6, cols: 7),
            allHidden: false
        ),
        10: ChapterConfig(
            operations: [.add, .subtract, .multiply, .divide],
            addSubMax: 100,
            multDivMax: 144,
            startGrid: (rows: 8, cols: 9),
            endGrid: (rows: 8, cols: 9),
            allHidden: true
        )
    ]

    // MARK: - Generate Settings

    /// Generate DifficultySettings for a specific story level
    static func settings(for storyLevel: StoryLevel) -> DifficultySettings {
        guard let config = chapters[storyLevel.chapter] else {
            // Fallback to chapter 1 if invalid
            return settings(for: StoryLevel(chapter: 1, level: 1))
        }

        // Calculate grid size based on level progression
        let grid = calculateGrid(
            level: storyLevel.level,
            start: config.startGrid,
            end: config.endGrid
        )

        // Determine if hidden mode
        let isHidden = config.allHidden || storyLevel.level == 5

        // Calculate operation weights
        let weights = calculateWeights(operations: config.operations)

        // Calculate connector range based on max values
        let connectorMax = max(config.addSubMax, config.multDivMax)

        // Calculate mult/div range (for operands, derive from max answer)
        // e.g., max answer 50 → operands up to ~7 (7×7=49)
        let multDivRange = config.multDivMax > 0 ? Int(sqrt(Double(config.multDivMax))) : 0

        var settings = DifficultySettings(
            name: "Story \(storyLevel.displayName)",
            additionEnabled: config.operations.contains(.add),
            subtractionEnabled: config.operations.contains(.subtract),
            multiplicationEnabled: config.operations.contains(.multiply),
            divisionEnabled: config.operations.contains(.divide),
            addSubRange: config.addSubMax,
            multDivRange: multDivRange,
            connectorMin: 5,
            connectorMax: connectorMax,
            gridRows: grid.rows,
            gridCols: grid.cols,
            minPathLength: 0,
            maxPathLength: 0,
            weights: weights,
            hiddenMode: isHidden,
            secondsPerStep: 5  // Used for 3-star calculation
        )

        // Calculate path lengths
        settings.minPathLength = DifficultyPresets.calculateMinPathLength(
            rows: grid.rows,
            cols: grid.cols
        )
        settings.maxPathLength = DifficultyPresets.calculateMaxPathLength(
            rows: grid.rows,
            cols: grid.cols
        )

        return settings
    }

    // MARK: - Grid Calculation

    private static func calculateGrid(
        level: Int,
        start: (rows: Int, cols: Int),
        end: (rows: Int, cols: Int)
    ) -> (rows: Int, cols: Int) {
        // Level 5 always gets end grid
        if level == 5 {
            return end
        }

        // If start == end (chapters 9, 10), return that size
        if start.rows == end.rows && start.cols == end.cols {
            return start
        }

        // Progressive growth for levels 1-4
        // Calculate total growth needed
        let rowGrowth = end.rows - start.rows
        let colGrowth = end.cols - start.cols
        let totalGrowth = rowGrowth + colGrowth

        // Distribute growth across levels 1-4
        let growthPerLevel = totalGrowth / 4
        let growthForThisLevel = (level - 1) * growthPerLevel

        // Alternate between adding rows and cols
        var rows = start.rows
        var cols = start.cols

        for i in 0..<growthForThisLevel {
            if i % 2 == 0 && rows < end.rows {
                rows += 1
            } else if cols < end.cols {
                cols += 1
            } else if rows < end.rows {
                rows += 1
            }
        }

        return (rows: rows, cols: cols)
    }

    // MARK: - Weight Calculation

    private static func calculateWeights(operations: Set<ChapterConfig.Operation>) -> OperationWeights {
        let count = operations.count
        guard count > 0 else {
            return OperationWeights(addition: 100, subtraction: 0, multiplication: 0, division: 0)
        }

        // Distribute weights based on enabled operations
        let baseWeight = 100 / count

        return OperationWeights(
            addition: operations.contains(.add) ? baseWeight : 0,
            subtraction: operations.contains(.subtract) ? baseWeight : 0,
            multiplication: operations.contains(.multiply) ? baseWeight : 0,
            division: operations.contains(.divide) ? baseWeight : 0
        )
    }

    // MARK: - Star Calculation

    /// Calculate stars earned for a completed level
    /// - Parameters:
    ///   - livesLost: Number of lives lost during the level
    ///   - timeSeconds: Total time to complete in seconds
    ///   - tileCount: Number of tiles in the puzzle
    /// - Returns: Stars earned (1-3)
    static func calculateStars(livesLost: Int, timeSeconds: Double, tileCount: Int) -> Int {
        // 1 star: Completed
        var stars = 1

        // 2 stars: No lives lost
        if livesLost == 0 {
            stars = 2

            // 3 stars: Under 5 seconds per tile
            let targetTime = Double(tileCount) * 5.0
            if timeSeconds < targetTime {
                stars = 3
            }
        }

        return stars
    }
}

// MARK: - Story Level Progress

/// Tracks progress for a single story level
struct StoryLevelProgress: Codable {
    let level: StoryLevel
    var completed: Bool = false
    var stars: Int = 0  // 0-3
    var bestTimeSeconds: Double?
    var attempts: Int = 0

    mutating func recordAttempt(won: Bool, livesLost: Int, timeSeconds: Double, tileCount: Int) {
        attempts += 1

        if won {
            completed = true

            // Calculate stars for this attempt
            let earnedStars = StoryDifficulty.calculateStars(
                livesLost: livesLost,
                timeSeconds: timeSeconds,
                tileCount: tileCount
            )

            // Keep best stars
            stars = max(stars, earnedStars)

            // Keep best time
            if let best = bestTimeSeconds {
                bestTimeSeconds = min(best, timeSeconds)
            } else {
                bestTimeSeconds = timeSeconds
            }
        }
    }
}
