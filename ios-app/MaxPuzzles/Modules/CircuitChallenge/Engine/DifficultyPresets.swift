import Foundation

// MARK: - Difficulty Presets

/// All 10 preset difficulty levels
enum DifficultyPresets {

    // MARK: Level 1: Tiny Tot
    static let level1TinyTot = DifficultySettings(
        name: "Tiny Tot",
        additionEnabled: true,
        subtractionEnabled: false,
        multiplicationEnabled: false,
        divisionEnabled: false,
        addSubRange: 10,
        multDivRange: 0,
        connectorMin: 5,
        connectorMax: 10,
        gridRows: 3,
        gridCols: 4,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 100, subtraction: 0, multiplication: 0, division: 0),
        hiddenMode: false,
        secondsPerStep: 10
    )

    // MARK: Level 2: Beginner
    static let level2Beginner = DifficultySettings(
        name: "Beginner",
        additionEnabled: true,
        subtractionEnabled: false,
        multiplicationEnabled: false,
        divisionEnabled: false,
        addSubRange: 15,
        multDivRange: 0,
        connectorMin: 5,
        connectorMax: 15,
        gridRows: 4,
        gridCols: 4,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 100, subtraction: 0, multiplication: 0, division: 0),
        hiddenMode: false,
        secondsPerStep: 9
    )

    // MARK: Level 3: Easy
    static let level3Easy = DifficultySettings(
        name: "Easy",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: false,
        divisionEnabled: false,
        addSubRange: 15,
        multDivRange: 0,
        connectorMin: 5,
        connectorMax: 15,
        gridRows: 4,
        gridCols: 5,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 60, subtraction: 40, multiplication: 0, division: 0),
        hiddenMode: false,
        secondsPerStep: 8
    )

    // MARK: Level 4: Getting There
    static let level4GettingThere = DifficultySettings(
        name: "Getting There",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: false,
        divisionEnabled: false,
        addSubRange: 20,
        multDivRange: 0,
        connectorMin: 5,
        connectorMax: 20,
        gridRows: 4,
        gridCols: 5,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 55, subtraction: 45, multiplication: 0, division: 0),
        hiddenMode: false,
        secondsPerStep: 7
    )

    // MARK: Level 5: Times Tables
    static let level5TimesTables = DifficultySettings(
        name: "Times Tables",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: false,
        addSubRange: 20,
        multDivRange: 5,
        connectorMin: 5,
        connectorMax: 25,
        gridRows: 4,
        gridCols: 5,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 40, subtraction: 35, multiplication: 25, division: 0),
        hiddenMode: false,
        secondsPerStep: 7
    )

    // MARK: Level 6: Confident
    static let level6Confident = DifficultySettings(
        name: "Confident",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: false,
        addSubRange: 25,
        multDivRange: 6,
        connectorMin: 5,
        connectorMax: 36,
        gridRows: 5,
        gridCols: 5,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 35, subtraction: 30, multiplication: 35, division: 0),
        hiddenMode: false,
        secondsPerStep: 6
    )

    // MARK: Level 7: Adventurous
    static let level7Adventurous = DifficultySettings(
        name: "Adventurous",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: false,
        addSubRange: 30,
        multDivRange: 8,
        connectorMin: 5,
        connectorMax: 64,
        gridRows: 5,
        gridCols: 6,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 30, subtraction: 30, multiplication: 40, division: 0),
        hiddenMode: false,
        secondsPerStep: 6
    )

    // MARK: Level 8: Division Intro
    static let level8DivisionIntro = DifficultySettings(
        name: "Division Intro",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: true,
        addSubRange: 30,
        multDivRange: 6,
        connectorMin: 5,
        connectorMax: 36,
        gridRows: 5,
        gridCols: 6,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 30, subtraction: 25, multiplication: 30, division: 15),
        hiddenMode: false,
        secondsPerStep: 6
    )

    // MARK: Level 9: Challenge
    static let level9Challenge = DifficultySettings(
        name: "Challenge",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: true,
        addSubRange: 50,
        multDivRange: 10,
        connectorMin: 5,
        connectorMax: 100,
        gridRows: 6,
        gridCols: 7,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 25, subtraction: 25, multiplication: 30, division: 20),
        hiddenMode: false,
        secondsPerStep: 5
    )

    // MARK: Level 10: Expert
    static let level10Expert = DifficultySettings(
        name: "Expert",
        additionEnabled: true,
        subtractionEnabled: true,
        multiplicationEnabled: true,
        divisionEnabled: true,
        addSubRange: 100,
        multDivRange: 12,
        connectorMin: 5,
        connectorMax: 144,
        gridRows: 6,
        gridCols: 8,
        minPathLength: 0,
        maxPathLength: 0,
        weights: OperationWeights(addition: 25, subtraction: 25, multiplication: 30, division: 20),
        hiddenMode: false,
        secondsPerStep: 5
    )

    // MARK: All Presets Array

    /// All difficulty presets in order (1-10)
    static let all: [DifficultySettings] = [
        level1TinyTot,
        level2Beginner,
        level3Easy,
        level4GettingThere,
        level5TimesTables,
        level6Confident,
        level7Adventurous,
        level8DivisionIntro,
        level9Challenge,
        level10Expert
    ]

    // MARK: Helper Functions

    /// Get difficulty by level number (1-10)
    static func byLevel(_ level: Int) -> DifficultySettings {
        let index = max(0, min(9, level - 1))
        var settings = all[index]

        // Calculate path lengths based on grid size
        settings.minPathLength = calculateMinPathLength(rows: settings.gridRows, cols: settings.gridCols)
        settings.maxPathLength = calculateMaxPathLength(rows: settings.gridRows, cols: settings.gridCols)

        return settings
    }

    /// Get difficulty by name
    static func byName(_ name: String) -> DifficultySettings? {
        guard var settings = all.first(where: { $0.name == name }) else {
            return nil
        }

        settings.minPathLength = calculateMinPathLength(rows: settings.gridRows, cols: settings.gridCols)
        settings.maxPathLength = calculateMaxPathLength(rows: settings.gridRows, cols: settings.gridCols)

        return settings
    }

    /// Calculate minimum path length based on grid size
    /// Larger grids need lower percentages for reliable generation
    static func calculateMinPathLength(rows: Int, cols: Int) -> Int {
        let totalCells = rows * cols
        // Graduated percentages based on grid complexity
        let percentage: Double
        if totalCells <= 16 {
            percentage = 0.50  // Small grids: 50%
        } else if totalCells <= 25 {
            percentage = 0.55  // Medium grids: 55%
        } else if totalCells <= 42 {
            percentage = 0.50  // Large grids: 50%
        } else {
            percentage = 0.45  // Very large grids (8×9=72): 45%
        }
        return max(4, Int(floor(Double(totalCells) * percentage)))
    }

    /// Calculate maximum path length (~85% of cells)
    static func calculateMaxPathLength(rows: Int, cols: Int) -> Int {
        let totalCells = rows * cols
        return Int(floor(Double(totalCells) * 0.85))
    }
}

// MARK: - Difficulty Level Number

extension DifficultySettings {
    /// Get the level number (1-10) or 0 for custom
    var levelNumber: Int {
        let nameToLevel: [String: Int] = [
            "Tiny Tot": 1,
            "Beginner": 2,
            "Easy": 3,
            "Getting There": 4,
            "Times Tables": 5,
            "Confident": 6,
            "Adventurous": 7,
            "Division Intro": 8,
            "Challenge": 9,
            "Expert": 10
        ]
        return nameToLevel[name] ?? 0
    }
}
