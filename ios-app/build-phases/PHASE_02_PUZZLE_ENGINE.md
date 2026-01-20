# Phase 2: Puzzle Engine

**Goal:** Port the complete puzzle generation algorithm from TypeScript to Swift with full test coverage.

**Prerequisites:** Phase 1 complete (project structure, theme system)

**Estimated Subphases:** 6

**Reference Web Files:**
- `src/modules/circuit-challenge/engine/generator.ts`
- `src/modules/circuit-challenge/engine/pathfinder.ts`
- `src/modules/circuit-challenge/engine/connectors.ts`
- `src/modules/circuit-challenge/engine/valueAssigner.ts`
- `src/modules/circuit-challenge/engine/cellAssigner.ts`
- `src/modules/circuit-challenge/engine/expressions.ts`
- `src/modules/circuit-challenge/engine/validator.ts`
- `src/modules/circuit-challenge/engine/difficulty.ts`
- `src/modules/circuit-challenge/engine/types.ts`
- `src/modules/circuit-challenge/types.ts`

---

## Subphase 2.1: Core Types & Models

### Objective
Define all the data types needed for the puzzle engine in Swift.

### Technical Prompt for Claude Code

```
Create the core types for the Circuit Challenge puzzle engine in Swift.

FILE: Modules/CircuitChallenge/Engine/Types.swift

```swift
import Foundation

// MARK: - Coordinate

/// Grid coordinate (row, col)
struct Coordinate: Hashable, Codable, Equatable {
    let row: Int
    let col: Int

    /// String key for use in Sets/Dictionaries: "row,col"
    var key: String {
        "\(row),\(col)"
    }

    /// Create from string key "row,col"
    init?(fromKey key: String) {
        let parts = key.split(separator: ",")
        guard parts.count == 2,
              let row = Int(parts[0]),
              let col = Int(parts[1]) else {
            return nil
        }
        self.row = row
        self.col = col
    }

    init(row: Int, col: Int) {
        self.row = row
        self.col = col
    }
}

// MARK: - Diagonal Direction

/// Diagonal direction for connector placement in 2x2 blocks
/// - DR: Down-Right diagonal (top-left to bottom-right)
/// - DL: Down-Left diagonal (top-right to bottom-left)
enum DiagonalDirection: String, Codable {
    case DR // Down-right: (row,col) to (row+1,col+1)
    case DL // Down-left: (row,col+1) to (row+1,col)
}

// MARK: - Connector Type

/// Types of connectors between cells
enum ConnectorType: String, Codable {
    case horizontal
    case vertical
    case diagonal
}

// MARK: - Connector

/// Connector between two adjacent cells
struct Connector: Codable, Identifiable {
    let id: UUID
    let type: ConnectorType
    let cellA: Coordinate
    let cellB: Coordinate
    var value: Int
    var direction: DiagonalDirection?

    init(type: ConnectorType, cellA: Coordinate, cellB: Coordinate, value: Int = 0, direction: DiagonalDirection? = nil) {
        self.id = UUID()
        self.type = type
        self.cellA = cellA
        self.cellB = cellB
        self.value = value
        self.direction = direction
    }

    /// Check if this connector touches a given cell
    func touches(_ cell: Coordinate) -> Bool {
        cellA == cell || cellB == cell
    }

    /// Get the other cell connected by this connector
    func otherCell(from cell: Coordinate) -> Coordinate {
        cell == cellA ? cellB : cellA
    }

    /// Check if this connector connects two specific cells (order doesn't matter)
    func connects(_ a: Coordinate, _ b: Coordinate) -> Bool {
        (cellA == a && cellB == b) || (cellA == b && cellB == a)
    }
}

// MARK: - Cell State

/// Visual states for cells during gameplay
enum CellState: String, Codable {
    case normal
    case start
    case finish
    case current
    case visited
    case wrong
}

// MARK: - Game Mode

/// Game mode variants
enum GameMode: String, Codable {
    case standard  // 5 lives, feedback after each move
    case hidden    // No lives, all revealed at end
}

// MARK: - Cell

/// A cell in the puzzle grid
struct Cell: Codable, Identifiable {
    let id: UUID
    let row: Int
    let col: Int
    var expression: String
    var answer: Int?
    let isStart: Bool
    let isFinish: Bool

    init(row: Int, col: Int, expression: String = "", answer: Int? = nil, isStart: Bool = false, isFinish: Bool = false) {
        self.id = UUID()
        self.row = row
        self.col = col
        self.expression = expression
        self.answer = answer
        self.isStart = isStart
        self.isFinish = isFinish
    }

    var coordinate: Coordinate {
        Coordinate(row: row, col: col)
    }
}

// MARK: - Solution

/// Solution information for a puzzle
struct Solution: Codable {
    let path: [Coordinate]
    var steps: Int { path.count - 1 }
}

// MARK: - Puzzle

/// Complete puzzle definition
struct Puzzle: Codable, Identifiable {
    let id: String
    let difficulty: Int
    var grid: [[Cell]]
    var connectors: [Connector]
    let solution: Solution

    /// Grid dimensions
    var rows: Int { grid.count }
    var cols: Int { grid.first?.count ?? 0 }

    /// Get cell at coordinate
    func cell(at coord: Coordinate) -> Cell? {
        guard coord.row >= 0, coord.row < rows,
              coord.col >= 0, coord.col < cols else {
            return nil
        }
        return grid[coord.row][coord.col]
    }

    /// Get all connectors touching a cell
    func connectors(for cell: Coordinate) -> [Connector] {
        connectors.filter { $0.touches(cell) }
    }

    /// Find connector between two cells
    func connector(between a: Coordinate, and b: Coordinate) -> Connector? {
        connectors.first { $0.connects(a, b) }
    }
}

// MARK: - Operation

/// Arithmetic operations used in expressions
enum Operation: String, Codable, CaseIterable {
    case addition = "+"
    case subtraction = "−"  // Unicode minus
    case multiplication = "×"
    case division = "÷"

    var symbol: String { rawValue }
}

// MARK: - Operation Weights

/// Weights for operation selection during expression generation
struct OperationWeights: Codable {
    var addition: Int
    var subtraction: Int
    var multiplication: Int
    var division: Int

    init(addition: Int = 0, subtraction: Int = 0, multiplication: Int = 0, division: Int = 0) {
        self.addition = addition
        self.subtraction = subtraction
        self.multiplication = multiplication
        self.division = division
    }

    /// Total weight of all enabled operations
    var total: Int {
        addition + subtraction + multiplication + division
    }
}

// MARK: - Difficulty Settings

/// Configuration for puzzle generation
struct DifficultySettings: Codable {
    var name: String

    // Operations enabled
    var additionEnabled: Bool
    var subtractionEnabled: Bool
    var multiplicationEnabled: Bool
    var divisionEnabled: Bool

    // Ranges
    var addSubRange: Int      // Max operand for +/-
    var multDivRange: Int     // Max operand for ×/÷

    // Connector values
    var connectorMin: Int
    var connectorMax: Int

    // Grid size
    var gridRows: Int
    var gridCols: Int

    // Path constraints
    var minPathLength: Int
    var maxPathLength: Int

    // Operation weights
    var weights: OperationWeights

    // Game mode
    var hiddenMode: Bool

    // Timer
    var secondsPerStep: Int
}

// MARK: - Generation Result

/// Result of puzzle generation attempt
enum GenerationResult {
    case success(Puzzle)
    case failure(String)
}

// MARK: - Validation Result

/// Result of puzzle validation
struct ValidationResult {
    let valid: Bool
    let errors: [String]
    let warnings: [String]

    static func success() -> ValidationResult {
        ValidationResult(valid: true, errors: [], warnings: [])
    }

    static func failure(_ errors: [String], warnings: [String] = []) -> ValidationResult {
        ValidationResult(valid: false, errors: errors, warnings: warnings)
    }
}
```

Ensure:
1. All types are Codable for persistence
2. Coordinate has proper Hashable conformance
3. Types match web app exactly for cross-platform compatibility
```

### Acceptance Criteria
- [ ] All types compile without errors
- [ ] Coordinate properly hashable
- [ ] Types can be encoded/decoded to JSON
- [ ] Matches web TypeScript types

---

## Subphase 2.2: Difficulty Presets

### Objective
Create the 10 preset difficulty levels matching the web app exactly.

### Technical Prompt for Claude Code

```
Create the difficulty presets for Circuit Challenge. All values must match the web app exactly.

FILE: Modules/CircuitChallenge/Engine/DifficultyPresets.swift

```swift
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
        minPathLength: 0,  // Will be calculated
        maxPathLength: 0,  // Will be calculated
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

    /// Calculate minimum path length (~60% of cells)
    static func calculateMinPathLength(rows: Int, cols: Int) -> Int {
        let totalCells = rows * cols
        return max(4, Int(floor(Double(totalCells) * 0.6)))
    }

    /// Calculate maximum path length (~85% of cells)
    static func calculateMaxPathLength(rows: Int, cols: Int) -> Int {
        let totalCells = rows * cols
        return Int(floor(Double(totalCells) * 0.85))
    }

    /// Create custom difficulty with Level 5 as base
    static func createCustom(overrides: DifficultySettings) -> DifficultySettings {
        var settings = overrides

        // Calculate path lengths if grid size was specified
        settings.minPathLength = calculateMinPathLength(rows: settings.gridRows, cols: settings.gridCols)
        settings.maxPathLength = calculateMaxPathLength(rows: settings.gridRows, cols: settings.gridCols)

        // Auto-calculate weights if not explicitly set
        if settings.weights.total == 0 {
            var enabledCount = 0
            if settings.additionEnabled { enabledCount += 1 }
            if settings.subtractionEnabled { enabledCount += 1 }
            if settings.multiplicationEnabled { enabledCount += 1 }
            if settings.divisionEnabled { enabledCount += 1 }

            let weightPerOp = enabledCount > 0 ? 100 / enabledCount : 0

            settings.weights = OperationWeights(
                addition: settings.additionEnabled ? weightPerOp : 0,
                subtraction: settings.subtractionEnabled ? weightPerOp : 0,
                multiplication: settings.multiplicationEnabled ? weightPerOp : 0,
                division: settings.divisionEnabled ? weightPerOp : 0
            )
        }

        return settings
    }

    /// Validate difficulty settings
    static func validate(_ settings: DifficultySettings) -> ValidationResult {
        var errors: [String] = []

        // At least one operation must be enabled
        if !settings.additionEnabled && !settings.subtractionEnabled &&
           !settings.multiplicationEnabled && !settings.divisionEnabled {
            errors.append("At least one operation must be enabled")
        }

        // Ranges must be positive
        if settings.addSubRange < 1 {
            errors.append("Addition/subtraction range must be at least 1")
        }

        if (settings.multiplicationEnabled || settings.divisionEnabled) && settings.multDivRange < 2 {
            errors.append("Multiplication/division range must be at least 2")
        }

        // Connector range validation
        if settings.connectorMin < 1 {
            errors.append("Minimum connector value must be at least 1")
        }

        if settings.connectorMax <= settings.connectorMin {
            errors.append("Maximum connector value must be greater than minimum")
        }

        // Grid size validation
        if settings.gridRows < 3 {
            errors.append("Grid must have at least 3 rows")
        }

        if settings.gridCols < 4 {
            errors.append("Grid must have at least 4 columns")
        }

        // Path length validation
        if settings.minPathLength < 4 {
            errors.append("Minimum path length must be at least 4")
        }

        if settings.maxPathLength < settings.minPathLength {
            errors.append("Maximum path length must be at least equal to minimum")
        }

        // Weights validation
        if settings.additionEnabled && settings.weights.addition <= 0 {
            errors.append("Addition weight must be positive when enabled")
        }
        if settings.subtractionEnabled && settings.weights.subtraction <= 0 {
            errors.append("Subtraction weight must be positive when enabled")
        }
        if settings.multiplicationEnabled && settings.weights.multiplication <= 0 {
            errors.append("Multiplication weight must be positive when enabled")
        }
        if settings.divisionEnabled && settings.weights.division <= 0 {
            errors.append("Division weight must be positive when enabled")
        }

        // Timer validation
        if settings.secondsPerStep < 1 {
            errors.append("Seconds per step must be at least 1")
        }

        return errors.isEmpty ? .success() : .failure(errors)
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
```

Verify:
1. All 10 levels match web app values exactly
2. Path length calculations match
3. Custom difficulty creation works
4. Validation catches all edge cases
```

### Acceptance Criteria
- [ ] All 10 preset levels match web app exactly
- [ ] Path length calculations correct
- [ ] Validation catches invalid settings
- [ ] byLevel and byName functions work correctly

---

## Subphase 2.3: Path Generation

### Objective
Port the path generation algorithm that creates solution paths from START to FINISH.

### Technical Prompt for Claude Code

```
Port the path generation algorithm from TypeScript to Swift. This generates solution paths from START (0,0) to FINISH (rows-1, cols-1).

FILE: Modules/CircuitChallenge/Engine/PathFinder.swift

```swift
import Foundation

// MARK: - Path Result

/// Result of path generation attempt
struct PathResult {
    let success: Bool
    let path: [Coordinate]
    let diagonalCommitments: [String: DiagonalDirection]  // Key: "row,col" of 2x2 block top-left
    let error: String?

    static func failure(_ error: String) -> PathResult {
        PathResult(success: false, path: [], diagonalCommitments: [:], error: error)
    }

    static func success(path: [Coordinate], commitments: [String: DiagonalDirection]) -> PathResult {
        PathResult(success: true, path: path, diagonalCommitments: commitments, error: nil)
    }
}

// MARK: - PathFinder

/// Generates solution paths for Circuit Challenge puzzles
enum PathFinder {

    // MARK: - Direction Constants

    /// All 8 possible movement directions
    private static let directions: [(row: Int, col: Int)] = [
        (-1, 0),   // up
        (1, 0),    // down
        (0, -1),   // left
        (0, 1),    // right
        (-1, -1),  // up-left
        (-1, 1),   // up-right
        (1, -1),   // down-left
        (1, 1)     // down-right
    ]

    // MARK: - Public API

    /// Generate a solution path from START to FINISH
    /// - Parameters:
    ///   - rows: Number of rows in grid
    ///   - cols: Number of columns in grid
    ///   - minLength: Minimum path length required
    ///   - maxLength: Maximum path length allowed
    ///   - maxAttempts: Maximum attempts before giving up (default 100)
    /// - Returns: PathResult with path and diagonal commitments
    static func generatePath(
        rows: Int,
        cols: Int,
        minLength: Int,
        maxLength: Int,
        maxAttempts: Int = 100
    ) -> PathResult {
        let start = Coordinate(row: 0, col: 0)
        let finish = Coordinate(row: rows - 1, col: cols - 1)

        for _ in 0..<maxAttempts {
            var path: [Coordinate] = [start]
            var visited = Set<String>([start.key])
            var diagonalCommitments: [String: DiagonalDirection] = [:]

            var current = start

            while current != finish {
                // Check if path is too long
                if path.count > maxLength {
                    break
                }

                // Get all adjacent cells
                let adjacent = getAdjacent(current, rows: rows, cols: cols)

                // Filter to valid moves
                let validMoves = adjacent.filter { next in
                    // Must not be visited
                    guard !visited.contains(next.key) else { return false }

                    // Diagonal moves must not conflict with commitments
                    guard isDiagonalMoveValid(from: current, to: next, commitments: diagonalCommitments) else {
                        return false
                    }

                    return true
                }

                // No valid moves - stuck
                if validMoves.isEmpty {
                    break
                }

                // Select next cell
                let next: Coordinate

                // Bias towards finish as path gets longer
                let progressRatio = Double(path.count) / Double(maxLength)
                if Double.random(in: 0...1) < progressRatio * 0.7 {
                    // Pick closest to finish (by Manhattan distance)
                    next = validMoves.min(by: { a, b in
                        manhattanDistance(a, finish) < manhattanDistance(b, finish)
                    })!
                } else {
                    // Pick random
                    next = validMoves.randomElement()!
                }

                // Record diagonal commitment if applicable
                if isDiagonalMove(from: current, to: next) {
                    let key = getDiagonalKey(current, next)
                    let direction = getDiagonalDirection(from: current, to: next)
                    diagonalCommitments[key] = direction
                }

                // Add to path
                path.append(next)
                visited.insert(next.key)
                current = next
            }

            // Check if we reached finish with valid length and interesting path
            if current == finish && path.count >= minLength && isInterestingPath(path) {
                return .success(path: path, commitments: diagonalCommitments)
            }
        }

        return .failure("Failed to generate valid path after \(maxAttempts) attempts")
    }

    // MARK: - Helper Functions

    /// Get all adjacent cells within grid bounds
    static func getAdjacent(_ pos: Coordinate, rows: Int, cols: Int) -> [Coordinate] {
        var adjacent: [Coordinate] = []

        for dir in directions {
            let newRow = pos.row + dir.row
            let newCol = pos.col + dir.col

            if newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols {
                adjacent.append(Coordinate(row: newRow, col: newCol))
            }
        }

        return adjacent
    }

    /// Calculate Manhattan distance between two cells
    static func manhattanDistance(_ a: Coordinate, _ b: Coordinate) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }

    /// Check if a move is diagonal
    static func isDiagonalMove(from: Coordinate, to: Coordinate) -> Bool {
        from.row != to.row && from.col != to.col
    }

    /// Get the key for the 2x2 block a diagonal belongs to (top-left corner)
    static func getDiagonalKey(_ cellA: Coordinate, _ cellB: Coordinate) -> String {
        let minRow = min(cellA.row, cellB.row)
        let minCol = min(cellA.col, cellB.col)
        return "\(minRow),\(minCol)"
    }

    /// Determine diagonal direction for a move
    /// DR = down-right or up-left (same diagonal line)
    /// DL = down-left or up-right (anti-diagonal)
    static func getDiagonalDirection(from: Coordinate, to: Coordinate) -> DiagonalDirection {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col

        // DR: both increase or both decrease
        // DL: one increases while other decreases
        if (rowDiff > 0 && colDiff > 0) || (rowDiff < 0 && colDiff < 0) {
            return .DR
        }
        return .DL
    }

    /// Check if a diagonal move conflicts with existing commitment
    private static func isDiagonalMoveValid(
        from: Coordinate,
        to: Coordinate,
        commitments: [String: DiagonalDirection]
    ) -> Bool {
        guard isDiagonalMove(from: from, to: to) else {
            return true // Not a diagonal move, always valid
        }

        let key = getDiagonalKey(from, to)
        let direction = getDiagonalDirection(from: from, to: to)

        // If there's an existing commitment, it must match
        if let existing = commitments[key], existing != direction {
            return false
        }

        return true
    }

    /// Count direction changes in a path
    private static func countDirectionChanges(_ path: [Coordinate]) -> Int {
        guard path.count >= 3 else { return 0 }

        var changes = 0
        var prevDeltaRow = path[1].row - path[0].row
        var prevDeltaCol = path[1].col - path[0].col

        for i in 2..<path.count {
            let deltaRow = path[i].row - path[i - 1].row
            let deltaCol = path[i].col - path[i - 1].col

            if deltaRow != prevDeltaRow || deltaCol != prevDeltaCol {
                changes += 1
            }

            prevDeltaRow = deltaRow
            prevDeltaCol = deltaCol
        }

        return changes
    }

    /// Check if path is "interesting" (has enough direction changes)
    static func isInterestingPath(_ path: [Coordinate]) -> Bool {
        countDirectionChanges(path) >= 3
    }

    /// Check if two cells are adjacent (including diagonally)
    static func areAdjacent(_ a: Coordinate, _ b: Coordinate) -> Bool {
        let rowDiff = abs(a.row - b.row)
        let colDiff = abs(a.col - b.col)
        return rowDiff <= 1 && colDiff <= 1 && (rowDiff + colDiff > 0)
    }
}
```

Unit tests to add:

FILE: Tests/EngineTests/PathFinderTests.swift

```swift
import XCTest
@testable import MaxPuzzles

final class PathFinderTests: XCTestCase {

    func testPathStartsAtOrigin() {
        let result = PathFinder.generatePath(rows: 4, cols: 5, minLength: 6, maxLength: 15)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.path.first, Coordinate(row: 0, col: 0))
    }

    func testPathEndsAtFinish() {
        let result = PathFinder.generatePath(rows: 4, cols: 5, minLength: 6, maxLength: 15)

        XCTAssertTrue(result.success)
        XCTAssertEqual(result.path.last, Coordinate(row: 3, col: 4))
    }

    func testPathWithinLengthBounds() {
        let minLength = 8
        let maxLength = 15

        for _ in 0..<20 {
            let result = PathFinder.generatePath(rows: 4, cols: 5, minLength: minLength, maxLength: maxLength)

            XCTAssertTrue(result.success)
            XCTAssertGreaterThanOrEqual(result.path.count, minLength)
            XCTAssertLessThanOrEqual(result.path.count, maxLength)
        }
    }

    func testPathHasNoDuplicates() {
        let result = PathFinder.generatePath(rows: 5, cols: 5, minLength: 10, maxLength: 20)

        XCTAssertTrue(result.success)
        let keys = result.path.map { $0.key }
        XCTAssertEqual(keys.count, Set(keys).count, "Path should have no duplicate cells")
    }

    func testAllMovesAreAdjacent() {
        let result = PathFinder.generatePath(rows: 5, cols: 6, minLength: 10, maxLength: 25)

        XCTAssertTrue(result.success)

        for i in 0..<(result.path.count - 1) {
            XCTAssertTrue(
                PathFinder.areAdjacent(result.path[i], result.path[i + 1]),
                "Cells at index \(i) and \(i + 1) should be adjacent"
            )
        }
    }

    func testManhattanDistance() {
        let a = Coordinate(row: 0, col: 0)
        let b = Coordinate(row: 3, col: 4)

        XCTAssertEqual(PathFinder.manhattanDistance(a, b), 7)
    }

    func testDiagonalDirection() {
        // Down-right
        XCTAssertEqual(
            PathFinder.getDiagonalDirection(from: Coordinate(row: 0, col: 0), to: Coordinate(row: 1, col: 1)),
            .DR
        )
        // Up-left (same as DR)
        XCTAssertEqual(
            PathFinder.getDiagonalDirection(from: Coordinate(row: 1, col: 1), to: Coordinate(row: 0, col: 0)),
            .DR
        )
        // Down-left
        XCTAssertEqual(
            PathFinder.getDiagonalDirection(from: Coordinate(row: 0, col: 1), to: Coordinate(row: 1, col: 0)),
            .DL
        )
        // Up-right (same as DL)
        XCTAssertEqual(
            PathFinder.getDiagonalDirection(from: Coordinate(row: 1, col: 0), to: Coordinate(row: 0, col: 1)),
            .DL
        )
    }
}
```
```

### Acceptance Criteria
- [ ] Path generation produces valid paths
- [ ] Paths start at (0,0) and end at (rows-1, cols-1)
- [ ] Diagonal commitments tracked correctly
- [ ] All unit tests pass

---

## Subphase 2.4: Connector & Value Assignment

### Objective
Port the connector graph building and value assignment algorithms.

### Technical Prompt for Claude Code

```
Port the connector graph building and value assignment algorithms from TypeScript to Swift.

FILE: Modules/CircuitChallenge/Engine/ConnectorBuilder.swift

```swift
import Foundation

// MARK: - Unvalued Connector

/// Connector before value assignment
struct UnvaluedConnector {
    let type: ConnectorType
    let cellA: Coordinate
    let cellB: Coordinate
    let direction: DiagonalDirection?

    /// Check if this connector touches a given cell
    func touches(_ cell: Coordinate) -> Bool {
        cellA == cell || cellB == cell
    }
}

// MARK: - Diagonal Grid

/// Grid of diagonal directions for each 2x2 block
/// Index [row][col] where row is 0 to rows-2, col is 0 to cols-2
typealias DiagonalGrid = [[DiagonalDirection]]

// MARK: - Value Assignment Result

/// Result of connector value assignment
struct ValueAssignmentResult {
    let success: Bool
    let connectors: [Connector]
    let divisionConnectorIndices: [Int]  // Indices of connectors reserved for division
    let error: String?

    static func failure(_ error: String) -> ValueAssignmentResult {
        ValueAssignmentResult(success: false, connectors: [], divisionConnectorIndices: [], error: error)
    }

    static func success(connectors: [Connector], divisionIndices: [Int]) -> ValueAssignmentResult {
        ValueAssignmentResult(success: true, connectors: connectors, divisionConnectorIndices: divisionIndices, error: nil)
    }
}

// MARK: - ConnectorBuilder

/// Builds connector graphs and assigns values
enum ConnectorBuilder {

    /// Proportion of path connectors reserved for division when enabled
    private static let divisionConnectorRatio = 0.25

    // MARK: - Build Diagonal Grid

    /// Build a grid of diagonal directions for each 2x2 block
    /// Uses committed directions from path generation, fills rest randomly
    static func buildDiagonalGrid(
        rows: Int,
        cols: Int,
        commitments: [String: DiagonalDirection]
    ) -> DiagonalGrid {
        var grid: DiagonalGrid = []

        for row in 0..<(rows - 1) {
            var rowArray: [DiagonalDirection] = []
            for col in 0..<(cols - 1) {
                let key = "\(row),\(col)"

                if let committed = commitments[key] {
                    rowArray.append(committed)
                } else {
                    // Randomly choose direction
                    rowArray.append(Bool.random() ? .DR : .DL)
                }
            }
            grid.append(rowArray)
        }

        return grid
    }

    // MARK: - Build Connector Graph

    /// Build the complete connector graph for a grid
    static func buildConnectorGraph(
        rows: Int,
        cols: Int,
        diagonalGrid: DiagonalGrid
    ) -> [UnvaluedConnector] {
        var connectors: [UnvaluedConnector] = []

        // Add horizontal connectors
        for row in 0..<rows {
            for col in 0..<(cols - 1) {
                connectors.append(UnvaluedConnector(
                    type: .horizontal,
                    cellA: Coordinate(row: row, col: col),
                    cellB: Coordinate(row: row, col: col + 1),
                    direction: nil
                ))
            }
        }

        // Add vertical connectors
        for row in 0..<(rows - 1) {
            for col in 0..<cols {
                connectors.append(UnvaluedConnector(
                    type: .vertical,
                    cellA: Coordinate(row: row, col: col),
                    cellB: Coordinate(row: row + 1, col: col),
                    direction: nil
                ))
            }
        }

        // Add diagonal connectors based on grid directions
        for row in 0..<(rows - 1) {
            for col in 0..<(cols - 1) {
                let direction = diagonalGrid[row][col]

                if direction == .DR {
                    // Down-right: (row, col) to (row+1, col+1)
                    connectors.append(UnvaluedConnector(
                        type: .diagonal,
                        cellA: Coordinate(row: row, col: col),
                        cellB: Coordinate(row: row + 1, col: col + 1),
                        direction: .DR
                    ))
                } else {
                    // Down-left: (row, col+1) to (row+1, col)
                    connectors.append(UnvaluedConnector(
                        type: .diagonal,
                        cellA: Coordinate(row: row, col: col + 1),
                        cellB: Coordinate(row: row + 1, col: col),
                        direction: .DL
                    ))
                }
            }
        }

        return connectors
    }

    // MARK: - Assign Connector Values

    /// Assign unique values to all connectors
    /// Ensures no cell has duplicate connector values
    static func assignConnectorValues(
        unvaluedConnectors: [UnvaluedConnector],
        minValue: Int,
        maxValue: Int,
        divisionEnabled: Bool = false,
        solutionPath: [Coordinate] = [],
        multDivRange: Int = 12
    ) -> ValueAssignmentResult {

        // Build map: cellKey -> list of connector indices touching that cell
        var cellConnectorMap: [String: [Int]] = [:]

        for (index, connector) in unvaluedConnectors.enumerated() {
            let keyA = connector.cellA.key
            let keyB = connector.cellB.key

            cellConnectorMap[keyA, default: []].append(index)
            cellConnectorMap[keyB, default: []].append(index)
        }

        // Create array with nil values initially
        var connectorValues: [Int?] = Array(repeating: nil, count: unvaluedConnectors.count)

        // When division is enabled, identify path connectors and reserve some for division
        var divisionConnectorIndices: [Int] = []

        if divisionEnabled && solutionPath.count > 1 {
            // Find all connectors on the solution path
            var pathConnectorIndices: [Int] = []
            for (index, connector) in unvaluedConnectors.enumerated() {
                if isConnectorOnPath(connector, path: solutionPath) {
                    pathConnectorIndices.append(index)
                }
            }

            // Reserve ~25% for division
            let numDivisionConnectors = max(1, Int(floor(Double(pathConnectorIndices.count) * divisionConnectorRatio)))
            let shuffledPathIndices = pathConnectorIndices.shuffled()
            divisionConnectorIndices = Array(shuffledPathIndices.prefix(numDivisionConnectors))

            // Assign division connectors FIRST with small values (1 to multDivRange)
            for index in divisionConnectorIndices {
                if let value = assignValueToConnector(
                    index: index,
                    unvaluedConnectors: unvaluedConnectors,
                    connectorValues: &connectorValues,
                    cellConnectorMap: cellConnectorMap,
                    minValue: max(1, minValue),
                    maxValue: min(multDivRange, maxValue),
                    preferSmall: true,
                    maxSmallValue: multDivRange
                ) {
                    connectorValues[index] = value
                } else {
                    // Fallback to full range
                    if let fallbackValue = assignValueToConnector(
                        index: index,
                        unvaluedConnectors: unvaluedConnectors,
                        connectorValues: &connectorValues,
                        cellConnectorMap: cellConnectorMap,
                        minValue: minValue,
                        maxValue: maxValue,
                        preferSmall: false
                    ) {
                        connectorValues[index] = fallbackValue
                    } else {
                        let connector = unvaluedConnectors[index]
                        return .failure("No available values for division connector between \(connector.cellA.key) and \(connector.cellB.key)")
                    }
                }
            }
        }

        // Assign remaining connectors in shuffled order
        let assignedIndices = Set(divisionConnectorIndices)
        let remainingIndices = (0..<unvaluedConnectors.count)
            .filter { !assignedIndices.contains($0) }
            .shuffled()

        for index in remainingIndices {
            if let value = assignValueToConnector(
                index: index,
                unvaluedConnectors: unvaluedConnectors,
                connectorValues: &connectorValues,
                cellConnectorMap: cellConnectorMap,
                minValue: minValue,
                maxValue: maxValue,
                preferSmall: false
            ) {
                connectorValues[index] = value
            } else {
                let connector = unvaluedConnectors[index]
                return .failure("No available values for connector between \(connector.cellA.key) and \(connector.cellB.key)")
            }
        }

        // Convert to Connector type
        let connectors: [Connector] = unvaluedConnectors.enumerated().map { index, uv in
            Connector(
                type: uv.type,
                cellA: uv.cellA,
                cellB: uv.cellB,
                value: connectorValues[index]!,
                direction: uv.direction
            )
        }

        return .success(connectors: connectors, divisionIndices: divisionConnectorIndices)
    }

    // MARK: - Private Helpers

    /// Check if a connector is on the solution path
    private static func isConnectorOnPath(_ connector: UnvaluedConnector, path: [Coordinate]) -> Bool {
        for i in 0..<(path.count - 1) {
            let current = path[i]
            let next = path[i + 1]

            let matchesForward = connector.cellA == current && connector.cellB == next
            let matchesBackward = connector.cellA == next && connector.cellB == current

            if matchesForward || matchesBackward {
                return true
            }
        }
        return false
    }

    /// Assign a value to a single connector
    private static func assignValueToConnector(
        index: Int,
        unvaluedConnectors: [UnvaluedConnector],
        connectorValues: inout [Int?],
        cellConnectorMap: [String: [Int]],
        minValue: Int,
        maxValue: Int,
        preferSmall: Bool,
        maxSmallValue: Int = 12
    ) -> Int? {
        let connector = unvaluedConnectors[index]

        // Collect all values already used by connectors touching cellA or cellB
        var usedValues = Set<Int>()

        let touchingA = cellConnectorMap[connector.cellA.key] ?? []
        let touchingB = cellConnectorMap[connector.cellB.key] ?? []

        for i in touchingA {
            if let value = connectorValues[i] {
                usedValues.insert(value)
            }
        }
        for i in touchingB {
            if let value = connectorValues[i] {
                usedValues.insert(value)
            }
        }

        // Find available values
        var available = (minValue...maxValue).filter { !usedValues.contains($0) }

        if available.isEmpty {
            return nil
        }

        // If preferring small values, filter to small values if possible
        if preferSmall {
            let smallValues = available.filter { $0 <= maxSmallValue }
            if !smallValues.isEmpty {
                return smallValues.randomElement()
            }
        }

        return available.randomElement()
    }

    // MARK: - Helper Functions for External Use

    /// Get all connectors touching a specific cell
    static func getConnectors(for cell: Coordinate, in connectors: [Connector]) -> [Connector] {
        connectors.filter { $0.touches(cell) }
    }

    /// Find connector between two specific cells
    static func getConnector(between a: Coordinate, and b: Coordinate, in connectors: [Connector]) -> Connector? {
        connectors.first { $0.connects(a, b) }
    }
}
```

Add tests:

FILE: Tests/EngineTests/ConnectorBuilderTests.swift

```swift
import XCTest
@testable import MaxPuzzles

final class ConnectorBuilderTests: XCTestCase {

    func testDiagonalGridSize() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: [:])

        XCTAssertEqual(grid.count, 3)  // rows - 1
        XCTAssertEqual(grid[0].count, 4)  // cols - 1
    }

    func testDiagonalGridRespectsCommitments() {
        let commitments: [String: DiagonalDirection] = [
            "0,0": .DR,
            "1,2": .DL
        ]

        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: commitments)

        XCTAssertEqual(grid[0][0], .DR)
        XCTAssertEqual(grid[1][2], .DL)
    }

    func testConnectorGraphCount() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 3, cols: 4, commitments: [:])
        let connectors = ConnectorBuilder.buildConnectorGraph(rows: 3, cols: 4, diagonalGrid: grid)

        // Horizontal: 3 rows × 3 connectors = 9
        // Vertical: 2 rows × 4 connectors = 8
        // Diagonal: 2 rows × 3 connectors = 6
        // Total: 23
        XCTAssertEqual(connectors.count, 23)
    }

    func testConnectorValuesAreUnique() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: [:])
        let unvalued = ConnectorBuilder.buildConnectorGraph(rows: 4, cols: 5, diagonalGrid: grid)
        let result = ConnectorBuilder.assignConnectorValues(
            unvaluedConnectors: unvalued,
            minValue: 5,
            maxValue: 50
        )

        XCTAssertTrue(result.success)

        // Check uniqueness per cell
        for row in 0..<4 {
            for col in 0..<5 {
                let cell = Coordinate(row: row, col: col)
                let cellConnectors = ConnectorBuilder.getConnectors(for: cell, in: result.connectors)
                let values = cellConnectors.map { $0.value }

                XCTAssertEqual(values.count, Set(values).count, "Cell (\(row),\(col)) has duplicate connector values")
            }
        }
    }
}
```
```

### Acceptance Criteria
- [ ] Diagonal grid built correctly
- [ ] All connector types created (horizontal, vertical, diagonal)
- [ ] Connector values are unique per cell
- [ ] Division connector reservation works
- [ ] All tests pass

---

## Subphase 2.5: Expression Generation

### Objective
Port the arithmetic expression generation algorithm.

### Technical Prompt for Claude Code

```
Port the expression generation algorithm from TypeScript to Swift.

FILE: Modules/CircuitChallenge/Engine/ExpressionGenerator.swift

```swift
import Foundation

// MARK: - Expression

/// A generated arithmetic expression
struct Expression {
    let text: String
    let operation: Operation
    let operandA: Int
    let operandB: Int
    let result: Int
}

// MARK: - ExpressionGenerator

/// Generates arithmetic expressions for puzzle cells
enum ExpressionGenerator {

    // MARK: - Operation Selection

    /// Select a random operation based on weights
    static func selectOperation(weights: OperationWeights, settings: DifficultySettings) -> Operation {
        var enabledWeights: [(op: Operation, weight: Int)] = []

        if settings.additionEnabled && weights.addition > 0 {
            enabledWeights.append((.addition, weights.addition))
        }
        if settings.subtractionEnabled && weights.subtraction > 0 {
            enabledWeights.append((.subtraction, weights.subtraction))
        }
        if settings.multiplicationEnabled && weights.multiplication > 0 {
            enabledWeights.append((.multiplication, weights.multiplication))
        }
        if settings.divisionEnabled && weights.division > 0 {
            enabledWeights.append((.division, weights.division))
        }

        guard !enabledWeights.isEmpty else {
            return .addition // Fallback
        }

        let total = enabledWeights.reduce(0) { $0 + $1.weight }
        var random = Int.random(in: 0..<total)

        for (op, weight) in enabledWeights {
            random -= weight
            if random < 0 {
                return op
            }
        }

        return enabledWeights[0].op
    }

    // MARK: - Individual Operation Generators

    /// Generate addition: a + b = target
    static func generateAddition(target: Int, maxOperand: Int) -> Expression? {
        guard target >= 2 else { return nil }

        // For a + b = target where both a, b in [1, maxOperand]:
        // a must satisfy: max(1, target - maxOperand) <= a <= min(maxOperand, target - 1)
        let minA = max(1, target - maxOperand)
        let maxA = min(maxOperand, target - 1)

        guard minA <= maxA else { return nil }

        let a = Int.random(in: minA...maxA)
        let b = target - a

        return Expression(
            text: "\(a) + \(b)",
            operation: .addition,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    /// Generate subtraction: a - b = target (where a > b, no negatives)
    static func generateSubtraction(target: Int, maxOperand: Int) -> Expression? {
        guard target >= 1 else { return nil }

        // a - b = target, so a = target + b
        // b can be 1 to (maxOperand - target)
        let maxB = maxOperand - target
        guard maxB >= 1 else { return nil }

        let b = Int.random(in: 1...maxB)
        let a = target + b

        // Ensure a is within reasonable range
        guard a <= maxOperand * 2 else { return nil }

        return Expression(
            text: "\(a) − \(b)",  // Unicode minus
            operation: .subtraction,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    /// Generate multiplication: a × b = target
    static func generateMultiplication(target: Int, maxFactor: Int) -> Expression? {
        guard target >= 4 else { return nil } // Need at least 2 × 2

        // Find all valid factor pairs
        var pairs: [(Int, Int)] = []
        let sqrtTarget = Int(sqrt(Double(target)))

        for a in 2...min(maxFactor, sqrtTarget) {
            if target % a == 0 {
                let b = target / a
                if b >= 2 && b <= maxFactor {
                    pairs.append((a, b))
                }
            }
        }

        guard let (a, b) = pairs.randomElement() else { return nil }

        // Randomly swap order
        if Bool.random() {
            return Expression(
                text: "\(a) × \(b)",
                operation: .multiplication,
                operandA: a,
                operandB: b,
                result: target
            )
        } else {
            return Expression(
                text: "\(b) × \(a)",
                operation: .multiplication,
                operandA: b,
                operandB: a,
                result: target
            )
        }
    }

    /// Generate division: a ÷ b = target (where a = target × b)
    static func generateDivision(target: Int, maxDivisor: Int, maxDividend: Int = 1000) -> Expression? {
        guard target >= 1 else { return nil }

        // a ÷ b = target, so a = target × b
        let maxB = min(maxDivisor, 12)
        var validDivisors: [Int] = []

        for b in 2...maxB {
            let a = target * b
            if a <= maxDividend {
                validDivisors.append(b)
            }
        }

        guard let b = validDivisors.randomElement() else { return nil }
        let a = target * b

        return Expression(
            text: "\(a) ÷ \(b)",
            operation: .division,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    // MARK: - Multiplication Boost

    /// Check if a number is a good multiplication candidate
    /// Returns likelihood boost (0 to 1)
    private static func getMultiplicationBoost(target: Int, maxFactor: Int) -> Double {
        // Check if this number has valid factor pairs (factors >= 2)
        var hasValidFactors = false
        let sqrtTarget = Int(sqrt(Double(target)))

        for a in 2...min(maxFactor, sqrtTarget) {
            if target % a == 0 {
                let b = target / a
                if b >= 2 && b <= maxFactor {
                    hasValidFactors = true
                    break
                }
            }
        }

        guard hasValidFactors else { return 0 }

        // Scale likelihood based on value
        if target <= 25 {
            return 0.40
        } else if target >= 50 {
            return 0.60
        } else {
            // Linear interpolation
            return 0.40 + Double(target - 25) * 0.008
        }
    }

    // MARK: - Main Expression Generator

    /// Generate an arithmetic expression that evaluates to the target value
    static func generateExpression(
        target: Int,
        difficulty: DifficultySettings,
        prioritizeDivision: Bool = false
    ) -> Expression {
        let maxDivisionAnswer = difficulty.multDivRange

        // Try up to 10 times
        for _ in 0..<10 {
            var operation: Operation

            // Division priority for marked cells
            if prioritizeDivision && difficulty.divisionEnabled && target <= maxDivisionAnswer {
                if Double.random(in: 0...1) < 0.8 {
                    operation = .division
                } else {
                    operation = selectOperation(weights: difficulty.weights, settings: difficulty)
                }
            } else if difficulty.multiplicationEnabled && !prioritizeDivision {
                // Check for multiplication boost
                let multBoost = getMultiplicationBoost(target: target, maxFactor: difficulty.multDivRange)
                if multBoost > 0 && Double.random(in: 0...1) < multBoost {
                    operation = .multiplication
                } else {
                    operation = selectOperation(weights: difficulty.weights, settings: difficulty)
                }
            } else {
                operation = selectOperation(weights: difficulty.weights, settings: difficulty)
            }

            var expression: Expression?

            switch operation {
            case .addition:
                expression = generateAddition(target: target, maxOperand: difficulty.addSubRange)
            case .subtraction:
                expression = generateSubtraction(target: target, maxOperand: difficulty.addSubRange)
            case .multiplication:
                expression = generateMultiplication(target: target, maxFactor: difficulty.multDivRange)
            case .division:
                if target <= maxDivisionAnswer {
                    expression = generateDivision(target: target, maxDivisor: difficulty.multDivRange)
                }
            }

            if let expr = expression {
                return expr
            }
        }

        // Fallback: handle edge cases
        if target == 1 {
            return Expression(
                text: "2 − 1",
                operation: .subtraction,
                operandA: 2,
                operandB: 1,
                result: 1
            )
        }

        // Force addition with relaxed constraints
        let a = target / 2
        let b = target - a
        return Expression(
            text: "\(a) + \(b)",
            operation: .addition,
            operandA: a,
            operandB: b,
            result: target
        )
    }

    // MARK: - Apply Expressions to Cells

    /// Apply expressions to all cells in the grid (mutates cells)
    static func applyExpressions(
        cells: inout [[Cell]],
        difficulty: DifficultySettings,
        divisionCells: Set<String> = []
    ) {
        for row in 0..<cells.count {
            for col in 0..<cells[row].count {
                var cell = cells[row][col]

                if cell.isFinish {
                    // FINISH cell doesn't need an expression
                    cell.expression = ""
                } else if let answer = cell.answer {
                    // Generate math expression
                    let prioritizeDivision = divisionCells.contains(cell.coordinate.key)
                    let expression = generateExpression(target: answer, difficulty: difficulty, prioritizeDivision: prioritizeDivision)
                    cell.expression = expression.text
                } else {
                    cell.expression = ""
                }

                cells[row][col] = cell
            }
        }
    }

    // MARK: - Expression Evaluation

    /// Evaluate a simple arithmetic expression
    /// Returns nil for invalid expressions
    static func evaluateExpression(_ expression: String) -> Int? {
        // Handle special cases
        if expression == "START" || expression == "FINISH" || expression.isEmpty {
            return nil
        }

        // Replace unicode operators
        let normalized = expression
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .trimmingCharacters(in: .whitespaces)

        // Parse: "number operator number"
        let pattern = #"^(\d+)\s*([+\-*/])\s*(\d+)$"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: normalized, range: NSRange(normalized.startIndex..., in: normalized)),
              match.numberOfRanges == 4 else {
            return nil
        }

        guard let aRange = Range(match.range(at: 1), in: normalized),
              let opRange = Range(match.range(at: 2), in: normalized),
              let bRange = Range(match.range(at: 3), in: normalized),
              let a = Int(normalized[aRange]),
              let b = Int(normalized[bRange]) else {
            return nil
        }

        let op = String(normalized[opRange])

        switch op {
        case "+": return a + b
        case "-": return a - b
        case "*": return a * b
        case "/": return b != 0 ? a / b : nil
        default: return nil
        }
    }
}
```

Add tests:

FILE: Tests/EngineTests/ExpressionGeneratorTests.swift

```swift
import XCTest
@testable import MaxPuzzles

final class ExpressionGeneratorTests: XCTestCase {

    func testAdditionExpressionEvaluatesCorrectly() {
        for target in [5, 10, 15, 20, 25] {
            if let expr = ExpressionGenerator.generateAddition(target: target, maxOperand: 30) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testSubtractionExpressionEvaluatesCorrectly() {
        for target in [5, 10, 15, 20] {
            if let expr = ExpressionGenerator.generateSubtraction(target: target, maxOperand: 30) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testMultiplicationExpressionEvaluatesCorrectly() {
        for target in [6, 12, 24, 36, 48] {
            if let expr = ExpressionGenerator.generateMultiplication(target: target, maxFactor: 12) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testDivisionExpressionEvaluatesCorrectly() {
        for target in [2, 3, 4, 5, 6] {
            if let expr = ExpressionGenerator.generateDivision(target: target, maxDivisor: 12) {
                XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target)
            }
        }
    }

    func testEvaluateExpressionHandlesUnicode() {
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("10 − 3"), 7)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("4 × 5"), 20)
        XCTAssertEqual(ExpressionGenerator.evaluateExpression("20 ÷ 4"), 5)
    }

    func testExpressionGeneratorAlwaysReturnsValidExpression() {
        let difficulty = DifficultyPresets.byLevel(5)

        for target in 1...50 {
            let expr = ExpressionGenerator.generateExpression(target: target, difficulty: difficulty)
            XCTAssertEqual(ExpressionGenerator.evaluateExpression(expr.text), target, "Expression for target \(target) should evaluate correctly")
        }
    }
}
```
```

### Acceptance Criteria
- [ ] All operation generators produce valid expressions
- [ ] Expression evaluation handles all operators
- [ ] Unicode operators (−, ×, ÷) work correctly
- [ ] Division prioritization works for marked cells
- [ ] All tests pass

---

## Subphase 2.6: Complete Generator & Validator

### Objective
Create the main puzzle generator that orchestrates all components, plus comprehensive validation.

### Technical Prompt for Claude Code

```
Create the main puzzle generator and validator that ties all components together.

FILE: Modules/CircuitChallenge/Engine/CellAssigner.swift

```swift
import Foundation

// MARK: - Cell Grid

/// Grid of cells with division cell tracking
struct CellGrid {
    var cells: [[Cell]]
    let rows: Int
    let cols: Int
    let divisionCells: Set<String>  // Cell keys that should prioritize division
}

// MARK: - CellAssigner

/// Assigns answers to cells based on solution path and connectors
enum CellAssigner {

    /// Assign answers to all cells
    static func assignCellAnswers(
        rows: Int,
        cols: Int,
        solutionPath: [Coordinate],
        connectors: [Connector],
        divisionConnectorIndices: [Int] = []
    ) -> CellGrid {
        let divisionConnectorSet = Set(divisionConnectorIndices)
        var divisionCells = Set<String>()

        // Initialize cells grid
        var cells: [[Cell]] = []
        for row in 0..<rows {
            var rowCells: [Cell] = []
            for col in 0..<cols {
                rowCells.append(Cell(
                    row: row,
                    col: col,
                    isStart: row == 0 && col == 0,
                    isFinish: row == rows - 1 && col == cols - 1
                ))
            }
            cells.append(rowCells)
        }

        // Create set of solution path coordinates
        let pathSet = Set(solutionPath.map { $0.key })

        // Assign answers for cells ON the solution path (except FINISH)
        for i in 0..<(solutionPath.count - 1) {
            let current = solutionPath[i]
            let next = solutionPath[i + 1]

            // Find connector (and its index)
            var connectorIndex = -1
            guard let connector = connectors.enumerated().first(where: { index, c in
                let matches = c.connects(current, next)
                if matches { connectorIndex = index }
                return matches
            })?.element else {
                fatalError("No connector found between \(current.key) and \(next.key)")
            }

            // Cell's answer is the connector's value
            cells[current.row][current.col].answer = connector.value

            // If connector is reserved for division, mark the cell
            if divisionConnectorSet.contains(connectorIndex) {
                divisionCells.insert(current.key)
            }
        }

        // Assign answers for cells NOT on the solution path
        for row in 0..<rows {
            for col in 0..<cols {
                let cell = cells[row][col]

                // Skip FINISH and already-assigned cells
                if cell.isFinish || pathSet.contains(cell.coordinate.key) {
                    continue
                }

                // Get all connectors touching this cell
                let cellConnectors = ConnectorBuilder.getConnectors(for: Coordinate(row: row, col: col), in: connectors)

                guard !cellConnectors.isEmpty else {
                    fatalError("No connectors found for cell (\(row),\(col))")
                }

                // Pick random connector's value as answer
                cells[row][col].answer = cellConnectors.randomElement()!.value
            }
        }

        return CellGrid(cells: cells, rows: rows, cols: cols, divisionCells: divisionCells)
    }
}
```

FILE: Modules/CircuitChallenge/Engine/PuzzleValidator.swift

```swift
import Foundation

// MARK: - PuzzleValidator

/// Validates generated puzzles
enum PuzzleValidator {

    // MARK: - Individual Validations

    /// Validate path is correctly formed
    static func validatePath(path: [Coordinate], rows: Int, cols: Int) -> ValidationResult {
        var errors: [String] = []

        // Path must have at least 2 elements
        guard path.count >= 2 else {
            return .failure(["Path must have at least 2 elements"])
        }

        // First element must be START (0, 0)
        if path[0] != Coordinate(row: 0, col: 0) {
            errors.append("Path must start at (0,0), but starts at \(path[0].key)")
        }

        // Last element must be FINISH
        let last = path[path.count - 1]
        if last != Coordinate(row: rows - 1, col: cols - 1) {
            errors.append("Path must end at (\(rows - 1),\(cols - 1)), but ends at \(last.key)")
        }

        // Check for valid adjacency and no duplicates
        var visited = Set<String>()

        for (i, coord) in path.enumerated() {
            // Check bounds
            if coord.row < 0 || coord.row >= rows || coord.col < 0 || coord.col >= cols {
                errors.append("Path coordinate \(coord.key) is out of bounds")
            }

            // Check for duplicates
            if visited.contains(coord.key) {
                errors.append("Duplicate coordinate in path: \(coord.key)")
            }
            visited.insert(coord.key)

            // Check adjacency with previous cell
            if i > 0 {
                let prev = path[i - 1]
                if !PathFinder.areAdjacent(prev, coord) {
                    errors.append("Non-adjacent cells in path: \(prev.key) to \(coord.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate connector values are unique per cell
    static func validateConnectorUniqueness(connectors: [Connector], rows: Int, cols: Int) -> ValidationResult {
        var errors: [String] = []

        for row in 0..<rows {
            for col in 0..<cols {
                let cell = Coordinate(row: row, col: col)
                let cellConnectors = ConnectorBuilder.getConnectors(for: cell, in: connectors)
                let values = cellConnectors.map { $0.value }

                if values.count != Set(values).count {
                    errors.append("Duplicate connector value at cell \(cell.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate cell answers match exactly one connector
    static func validateCellAnswers(cells: [[Cell]], connectors: [Connector]) -> ValidationResult {
        var errors: [String] = []

        for row in cells {
            for cell in row {
                if cell.isFinish {
                    if cell.answer != nil {
                        errors.append("FINISH cell should have nil answer")
                    }
                    continue
                }

                guard let answer = cell.answer else {
                    errors.append("Cell \(cell.coordinate.key) has nil answer but is not FINISH")
                    continue
                }

                let cellConnectors = ConnectorBuilder.getConnectors(for: cell.coordinate, in: connectors)
                let matchingCount = cellConnectors.filter { $0.value == answer }.count

                if matchingCount == 0 {
                    errors.append("Cell \(cell.coordinate.key) has answer \(answer) but no matching connector")
                } else if matchingCount > 1 {
                    errors.append("Cell \(cell.coordinate.key) has answer \(answer) matching \(matchingCount) connectors")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate solution path is arithmetically valid
    static func validateSolutionPath(path: [Coordinate], cells: [[Cell]], connectors: [Connector]) -> ValidationResult {
        var errors: [String] = []

        for i in 0..<(path.count - 1) {
            let current = path[i]
            let next = path[i + 1]
            let cell = cells[current.row][current.col]

            guard let connector = ConnectorBuilder.getConnector(between: current, and: next, in: connectors) else {
                errors.append("No connector between path cells \(current.key) and \(next.key)")
                continue
            }

            if cell.answer != connector.value {
                errors.append("Cell \(current.key) answer \(cell.answer ?? -1) doesn't match connector value \(connector.value)")
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate all expressions evaluate correctly
    static func validateExpressions(cells: [[Cell]]) -> ValidationResult {
        var errors: [String] = []

        for row in cells {
            for cell in row {
                // Skip START and FINISH
                if cell.isStart || cell.isFinish {
                    continue
                }

                if cell.expression.isEmpty {
                    errors.append("Cell \(cell.coordinate.key) has empty expression")
                    continue
                }

                guard let result = ExpressionGenerator.evaluateExpression(cell.expression) else {
                    errors.append("Cannot evaluate expression '\(cell.expression)' at \(cell.coordinate.key)")
                    continue
                }

                if result != cell.answer {
                    errors.append("Expression '\(cell.expression)' = \(result), but cell answer is \(cell.answer ?? -1) at \(cell.coordinate.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    // MARK: - Complete Validation

    /// Run all validations on a complete puzzle
    static func validatePuzzle(_ puzzle: Puzzle) -> ValidationResult {
        var allErrors: [String] = []
        var allWarnings: [String] = []

        // Validate path
        let pathResult = validatePath(path: puzzle.solution.path, rows: puzzle.rows, cols: puzzle.cols)
        allErrors.append(contentsOf: pathResult.errors)
        allWarnings.append(contentsOf: pathResult.warnings)

        // Validate connector uniqueness
        let connectorResult = validateConnectorUniqueness(connectors: puzzle.connectors, rows: puzzle.rows, cols: puzzle.cols)
        allErrors.append(contentsOf: connectorResult.errors)
        allWarnings.append(contentsOf: connectorResult.warnings)

        // Validate cell answers
        let cellResult = validateCellAnswers(cells: puzzle.grid, connectors: puzzle.connectors)
        allErrors.append(contentsOf: cellResult.errors)
        allWarnings.append(contentsOf: cellResult.warnings)

        // Validate solution path
        let solutionResult = validateSolutionPath(path: puzzle.solution.path, cells: puzzle.grid, connectors: puzzle.connectors)
        allErrors.append(contentsOf: solutionResult.errors)
        allWarnings.append(contentsOf: solutionResult.warnings)

        // Validate expressions
        let expressionResult = validateExpressions(cells: puzzle.grid)
        allErrors.append(contentsOf: expressionResult.errors)
        allWarnings.append(contentsOf: expressionResult.warnings)

        return ValidationResult(valid: allErrors.isEmpty, errors: allErrors, warnings: allWarnings)
    }
}
```

FILE: Modules/CircuitChallenge/Engine/PuzzleGenerator.swift

```swift
import Foundation

// MARK: - Generation Options

/// Options for puzzle generation
struct GenerationOptions {
    var maxAttempts: Int = 20
    var validateResult: Bool = true
}

// MARK: - PuzzleGenerator

/// Main puzzle generator - orchestrates all components
enum PuzzleGenerator {

    /// Generate a complete puzzle for the given difficulty settings
    static func generatePuzzle(
        difficulty: DifficultySettings,
        options: GenerationOptions = GenerationOptions()
    ) -> GenerationResult {

        // Calculate path lengths if not set
        var settings = difficulty
        if settings.minPathLength == 0 {
            settings.minPathLength = DifficultyPresets.calculateMinPathLength(rows: settings.gridRows, cols: settings.gridCols)
        }
        if settings.maxPathLength == 0 {
            settings.maxPathLength = DifficultyPresets.calculateMaxPathLength(rows: settings.gridRows, cols: settings.gridCols)
        }

        for attempt in 1...options.maxAttempts {
            do {
                // Step 1: Generate solution path
                let pathResult = PathFinder.generatePath(
                    rows: settings.gridRows,
                    cols: settings.gridCols,
                    minLength: settings.minPathLength,
                    maxLength: settings.maxPathLength
                )

                guard pathResult.success else {
                    continue
                }

                // Step 2: Build diagonal grid from path commitments
                let diagonalGrid = ConnectorBuilder.buildDiagonalGrid(
                    rows: settings.gridRows,
                    cols: settings.gridCols,
                    commitments: pathResult.diagonalCommitments
                )

                // Step 3: Build connector graph
                let unvaluedConnectors = ConnectorBuilder.buildConnectorGraph(
                    rows: settings.gridRows,
                    cols: settings.gridCols,
                    diagonalGrid: diagonalGrid
                )

                // Step 4: Assign connector values
                let valueResult = ConnectorBuilder.assignConnectorValues(
                    unvaluedConnectors: unvaluedConnectors,
                    minValue: settings.connectorMin,
                    maxValue: settings.connectorMax,
                    divisionEnabled: settings.divisionEnabled,
                    solutionPath: pathResult.path,
                    multDivRange: settings.multDivRange
                )

                guard valueResult.success else {
                    continue
                }

                // Step 5: Assign cell answers based on solution path
                var cellGrid = CellAssigner.assignCellAnswers(
                    rows: settings.gridRows,
                    cols: settings.gridCols,
                    solutionPath: pathResult.path,
                    connectors: valueResult.connectors,
                    divisionConnectorIndices: valueResult.divisionConnectorIndices
                )

                // Step 6: Generate arithmetic expressions for each cell
                ExpressionGenerator.applyExpressions(
                    cells: &cellGrid.cells,
                    difficulty: settings,
                    divisionCells: cellGrid.divisionCells
                )

                // Step 7: Construct puzzle object
                let puzzle = Puzzle(
                    id: UUID().uuidString,
                    difficulty: settings.levelNumber,
                    grid: cellGrid.cells,
                    connectors: valueResult.connectors,
                    solution: Solution(path: pathResult.path)
                )

                // Step 8: Validate if requested
                if options.validateResult {
                    let validation = PuzzleValidator.validatePuzzle(puzzle)
                    if !validation.valid {
                        print("Attempt \(attempt) failed validation: \(validation.errors)")
                        continue
                    }
                }

                // Success!
                return .success(puzzle)

            } catch {
                print("Attempt \(attempt) threw error: \(error)")
                continue
            }
        }

        // All attempts failed
        return .failure("Failed to generate puzzle after \(options.maxAttempts) attempts. Try adjusting difficulty settings.")
    }
}
```

Add comprehensive tests:

FILE: Tests/EngineTests/PuzzleGeneratorTests.swift

```swift
import XCTest
@testable import MaxPuzzles

final class PuzzleGeneratorTests: XCTestCase {

    func testGeneratePuzzleLevel1() {
        let difficulty = DifficultyPresets.byLevel(1)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 3)
            XCTAssertEqual(puzzle.grid[0].count, 4)
            XCTAssertTrue(puzzle.grid[0][0].isStart)
            XCTAssertTrue(puzzle.grid[2][3].isFinish)
        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testGeneratePuzzleAllLevels() {
        for level in 1...10 {
            let difficulty = DifficultyPresets.byLevel(level)
            let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

            switch result {
            case .success(let puzzle):
                let validation = PuzzleValidator.validatePuzzle(puzzle)
                XCTAssertTrue(validation.valid, "Level \(level) puzzle should be valid. Errors: \(validation.errors)")
            case .failure(let error):
                XCTFail("Level \(level) generation failed: \(error)")
            }
        }
    }

    func testGeneratePuzzlePerformance() {
        let difficulty = DifficultyPresets.byLevel(5)

        measure {
            _ = PuzzleGenerator.generatePuzzle(difficulty: difficulty)
        }
    }

    func testMassGeneration() {
        // Generate 100 puzzles at Level 5 and verify all are valid
        let difficulty = DifficultyPresets.byLevel(5)
        var failures = 0

        for i in 0..<100 {
            let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

            switch result {
            case .success(let puzzle):
                let validation = PuzzleValidator.validatePuzzle(puzzle)
                if !validation.valid {
                    print("Puzzle \(i) failed validation: \(validation.errors)")
                    failures += 1
                }
            case .failure(let error):
                print("Puzzle \(i) generation failed: \(error)")
                failures += 1
            }
        }

        XCTAssertEqual(failures, 0, "\(failures) puzzles failed out of 100")
    }

    func testPuzzleSolutionPathIsValid() {
        let difficulty = DifficultyPresets.byLevel(5)

        for _ in 0..<10 {
            guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
                XCTFail("Generation failed")
                continue
            }

            // Walk the solution path and verify each step
            for i in 0..<(puzzle.solution.path.count - 1) {
                let current = puzzle.solution.path[i]
                let next = puzzle.solution.path[i + 1]
                let cell = puzzle.cell(at: current)!

                // Cell answer should lead to next cell
                guard let connector = puzzle.connector(between: current, and: next) else {
                    XCTFail("No connector between \(current.key) and \(next.key)")
                    continue
                }

                XCTAssertEqual(cell.answer, connector.value, "Cell \(current.key) answer should match connector to \(next.key)")
            }
        }
    }
}
```
```

### Acceptance Criteria
- [ ] Complete puzzle generator works
- [ ] All validation checks implemented
- [ ] Puzzles pass validation for all 10 levels
- [ ] Mass generation (100+ puzzles) has 0 failures
- [ ] Generation time < 200ms per puzzle
- [ ] All unit tests pass

---

## Phase 2 Completion Checklist

- [ ] All types compile and match web app
- [ ] All 10 difficulty presets match web exactly
- [ ] Path generation produces valid paths
- [ ] Connector building creates correct graph
- [ ] Value assignment ensures uniqueness per cell
- [ ] Expression generation produces valid math
- [ ] Complete generator orchestrates all steps
- [ ] Validator catches all error types
- [ ] All unit tests pass
- [ ] Performance is acceptable (< 200ms)

---

## Files Created in Phase 2

```
Modules/CircuitChallenge/
└── Engine/
    ├── Types.swift
    ├── DifficultyPresets.swift
    ├── PathFinder.swift
    ├── ConnectorBuilder.swift
    ├── ExpressionGenerator.swift
    ├── CellAssigner.swift
    ├── PuzzleValidator.swift
    └── PuzzleGenerator.swift

Tests/EngineTests/
├── PathFinderTests.swift
├── ConnectorBuilderTests.swift
├── ExpressionGeneratorTests.swift
└── PuzzleGeneratorTests.swift
```

---

*End of Phase 2*
