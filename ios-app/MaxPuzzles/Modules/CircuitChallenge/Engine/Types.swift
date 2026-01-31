import Foundation
#if os(iOS)
import UIKit
#endif

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

// MARK: - Traversed Connector

/// Represents a connector that has been traversed during gameplay
struct TraversedConnector: Equatable {
    let cellA: Coordinate
    let cellB: Coordinate
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
struct OperationWeights: Codable, Hashable {
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
struct DifficultySettings: Codable, Hashable {
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

// MARK: - Device-Specific Grid Caps

extension DifficultySettings {
    /// Maximum grid dimensions for iPhone
    /// Quick Play: 5 rows x 6 cols
    /// Story Mode: 4 rows x 6 cols (ALL levels)
    static let iPhoneMaxRows = 5
    static let iPhoneMaxCols = 6

    /// Story mode: ALL levels capped at 4 rows on iPhone
    static let iPhoneStoryMaxRows = 4
    static let iPhoneStoryMaxCols = 6

    /// Returns settings with grid dimensions capped for the current device
    /// On iPhone: caps at 5×6 grid for Quick Play, 4×6 for ALL Story Mode levels
    /// On iPad: returns original dimensions
    /// - Parameter storyLevel: If in story mode, pass the level number. Pass nil for Quick Play.
    func cappedForDevice(storyLevel: Int? = nil) -> DifficultySettings {
        #if os(iOS)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        if isIPad {
            return self
        }

        // On iPhone, cap grid dimensions
        var capped = self

        // Story mode: ALL levels capped at 4 rows
        // Quick Play: 5 rows max
        let maxRows: Int
        let maxCols: Int
        if storyLevel != nil {
            // Story mode: 4 rows max for ALL levels
            maxRows = Self.iPhoneStoryMaxRows
            maxCols = Self.iPhoneStoryMaxCols
        } else {
            // Quick Play: 5 rows max
            maxRows = Self.iPhoneMaxRows
            maxCols = Self.iPhoneMaxCols
        }

        capped.gridRows = min(gridRows, maxRows)
        capped.gridCols = min(gridCols, maxCols)

        // Recalculate path lengths for new grid size
        capped.minPathLength = DifficultyPresets.calculateMinPathLength(rows: capped.gridRows, cols: capped.gridCols)
        capped.maxPathLength = DifficultyPresets.calculateMaxPathLength(rows: capped.gridRows, cols: capped.gridCols)

        return capped
        #else
        return self
        #endif
    }
}
