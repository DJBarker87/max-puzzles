#!/usr/bin/env swift

// Simple generation stress test that can run standalone
// Run with: swift GenerationTest.swift

import Foundation

// Copy of key types needed for testing

enum DiagonalDirection: String, Codable {
    case DR  // Down-right: (r,c) -> (r+1,c+1)
    case DL  // Down-left: (r,c+1) -> (r+1,c)
}

struct Coordinate: Hashable, Codable {
    let row: Int
    let col: Int

    var key: String { "\(row),\(col)" }
}

struct OperationWeights: Codable {
    let addition: Int
    let subtraction: Int
    let multiplication: Int
    let division: Int
}

struct DifficultySettings: Codable {
    var name: String
    var additionEnabled: Bool
    var subtractionEnabled: Bool
    var multiplicationEnabled: Bool
    var divisionEnabled: Bool
    var addSubRange: Int
    var multDivRange: Int
    var connectorMin: Int
    var connectorMax: Int
    var gridRows: Int
    var gridCols: Int
    var minPathLength: Int
    var maxPathLength: Int
    var weights: OperationWeights
    var hiddenMode: Bool
    var secondsPerStep: Int
}

// Simplified PathFinder
enum PathFinder {
    static let directions: [(row: Int, col: Int)] = [
        (-1, 0), (1, 0), (0, -1), (0, 1),
        (-1, -1), (-1, 1), (1, -1), (1, 1)
    ]

    static func generatePath(rows: Int, cols: Int, minLength: Int, maxLength: Int) -> (success: Bool, path: [Coordinate], commitments: [String: DiagonalDirection]) {
        let start = Coordinate(row: 0, col: 0)
        let finish = Coordinate(row: rows - 1, col: cols - 1)
        let totalCells = rows * cols
        let isSmallGrid = totalCells <= 20

        for _ in 0..<200 {
            var path: [Coordinate] = [start]
            var visited = Set<String>([start.key])
            var commitments: [String: DiagonalDirection] = [:]

            var current = start

            while current != finish && path.count <= maxLength {
                let adjacent = getAdjacent(current, rows: rows, cols: cols)
                    .filter { !visited.contains($0.key) }
                    .filter { isDiagonalMoveValid(from: current, to: $0, commitments: commitments) }

                guard !adjacent.isEmpty else { break }

                let next: Coordinate
                let progressRatio = Double(path.count) / Double(maxLength)

                // For small grids, use mostly random moves
                // For large grids, use smarter scoring
                if isSmallGrid {
                    if progressRatio > 0.6 && Double.random(in: 0...1) < 0.4 {
                        next = adjacent.min(by: { manhattanDistance($0, finish) < manhattanDistance($1, finish) })!
                    } else {
                        next = adjacent.randomElement()!
                    }
                } else {
                    let scoredMoves = adjacent.map { move -> (Coordinate, Double) in
                        var score = 0.0
                        let distToFinish = manhattanDistance(move, finish)

                        if progressRatio > 0.7 {
                            score -= Double(distToFinish) * (progressRatio - 0.5) * 2
                        }

                        let futureOptions = getAdjacent(move, rows: rows, cols: cols)
                            .filter { !visited.contains($0.key) && $0 != current }
                            .count
                        score += Double(futureOptions) * 0.5
                        score += Double.random(in: 0...0.5)

                        return (move, score)
                    }
                    next = scoredMoves.max(by: { $0.1 < $1.1 })!.0
                }

                if isDiagonalMove(from: current, to: next) {
                    let key = getDiagonalKey(current, next)
                    commitments[key] = getDiagonalDirection(from: current, to: next)
                }

                path.append(next)
                visited.insert(next.key)
                current = next
            }

            if current == finish && path.count >= minLength && isInterestingPath(path) {
                return (true, path, commitments)
            }
        }
        return (false, [], [:])
    }

    static func getAdjacent(_ pos: Coordinate, rows: Int, cols: Int) -> [Coordinate] {
        directions.compactMap { dir in
            let newRow = pos.row + dir.row
            let newCol = pos.col + dir.col
            guard newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols else { return nil }
            return Coordinate(row: newRow, col: newCol)
        }
    }

    static func manhattanDistance(_ a: Coordinate, _ b: Coordinate) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }

    static func isDiagonalMove(from: Coordinate, to: Coordinate) -> Bool {
        from.row != to.row && from.col != to.col
    }

    static func getDiagonalKey(_ cellA: Coordinate, _ cellB: Coordinate) -> String {
        "\(min(cellA.row, cellB.row)),\(min(cellA.col, cellB.col))"
    }

    static func getDiagonalDirection(from: Coordinate, to: Coordinate) -> DiagonalDirection {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col
        return (rowDiff > 0 && colDiff > 0) || (rowDiff < 0 && colDiff < 0) ? .DR : .DL
    }

    static func isDiagonalMoveValid(from: Coordinate, to: Coordinate, commitments: [String: DiagonalDirection]) -> Bool {
        guard isDiagonalMove(from: from, to: to) else { return true }
        let key = getDiagonalKey(from, to)
        let direction = getDiagonalDirection(from: from, to: to)
        if let existing = commitments[key], existing != direction { return false }
        return true
    }

    static func isInterestingPath(_ path: [Coordinate]) -> Bool {
        guard path.count >= 3 else { return false }
        var changes = 0
        var prevDR = path[1].row - path[0].row
        var prevDC = path[1].col - path[0].col
        for i in 2..<path.count {
            let dr = path[i].row - path[i-1].row
            let dc = path[i].col - path[i-1].col
            if dr != prevDR || dc != prevDC { changes += 1 }
            prevDR = dr
            prevDC = dc
        }
        // More lenient requirements for shorter paths
        let minChanges: Int
        if path.count < 6 {
            minChanges = 1
        } else if path.count < 8 {
            minChanges = 2
        } else {
            minChanges = 3
        }
        return changes >= minChanges
    }
}

// Test connector assignment separately
func testConnectorAssignment(rows: Int, cols: Int, minValue: Int, maxValue: Int, path: [Coordinate], commitments: [String: DiagonalDirection]) -> Bool {
    // Build connector list
    var connectors: [(cellA: Coordinate, cellB: Coordinate)] = []

    // Horizontal
    for row in 0..<rows {
        for col in 0..<(cols-1) {
            connectors.append((Coordinate(row: row, col: col), Coordinate(row: row, col: col+1)))
        }
    }

    // Vertical
    for row in 0..<(rows-1) {
        for col in 0..<cols {
            connectors.append((Coordinate(row: row, col: col), Coordinate(row: row+1, col: col)))
        }
    }

    // Diagonal
    for row in 0..<(rows-1) {
        for col in 0..<(cols-1) {
            let key = "\(row),\(col)"
            let direction = commitments[key] ?? (Bool.random() ? DiagonalDirection.DR : .DL)
            if direction == .DR {
                connectors.append((Coordinate(row: row, col: col), Coordinate(row: row+1, col: col+1)))
            } else {
                connectors.append((Coordinate(row: row, col: col+1), Coordinate(row: row+1, col: col)))
            }
        }
    }

    // Build cell -> connector indices map
    var cellConnectorMap: [String: [Int]] = [:]
    for (i, c) in connectors.enumerated() {
        cellConnectorMap[c.cellA.key, default: []].append(i)
        cellConnectorMap[c.cellB.key, default: []].append(i)
    }

    // Assign values
    var values: [Int?] = Array(repeating: nil, count: connectors.count)
    let indices = (0..<connectors.count).shuffled()

    for idx in indices {
        let c = connectors[idx]
        var usedValues = Set<Int>()
        for i in cellConnectorMap[c.cellA.key] ?? [] {
            if let v = values[i] { usedValues.insert(v) }
        }
        for i in cellConnectorMap[c.cellB.key] ?? [] {
            if let v = values[i] { usedValues.insert(v) }
        }

        let available = (minValue...maxValue).filter { !usedValues.contains($0) }
        if available.isEmpty { return false }
        values[idx] = available.randomElement()
    }

    return true
}

// Chapter configs (matching StoryDifficulty)
struct ChapterConfig {
    let addSubMax: Int
    let multDivMax: Int
    let startGrid: (rows: Int, cols: Int)
    let endGrid: (rows: Int, cols: Int)
}

let chapters: [Int: ChapterConfig] = [
    1: ChapterConfig(addSubMax: 10, multDivMax: 0, startGrid: (3, 4), endGrid: (6, 7)),
    2: ChapterConfig(addSubMax: 15, multDivMax: 0, startGrid: (4, 5), endGrid: (6, 7)),
    3: ChapterConfig(addSubMax: 20, multDivMax: 0, startGrid: (4, 5), endGrid: (6, 7)),
    4: ChapterConfig(addSubMax: 35, multDivMax: 0, startGrid: (4, 5), endGrid: (6, 7)),
    5: ChapterConfig(addSubMax: 20, multDivMax: 20, startGrid: (4, 5), endGrid: (6, 7)),
    6: ChapterConfig(addSubMax: 30, multDivMax: 50, startGrid: (4, 5), endGrid: (6, 7)),
    7: ChapterConfig(addSubMax: 40, multDivMax: 100, startGrid: (4, 5), endGrid: (6, 7)),
    8: ChapterConfig(addSubMax: 50, multDivMax: 100, startGrid: (4, 5), endGrid: (6, 7)),
    9: ChapterConfig(addSubMax: 100, multDivMax: 144, startGrid: (6, 7), endGrid: (6, 7)),
    10: ChapterConfig(addSubMax: 100, multDivMax: 144, startGrid: (8, 9), endGrid: (8, 9)),
]

func calculateGrid(level: Int, start: (Int, Int), end: (Int, Int)) -> (rows: Int, cols: Int) {
    if level == 5 { return (end.0, end.1) }
    if start.0 == end.0 && start.1 == end.1 { return (start.0, start.1) }

    let rowGrowth = end.0 - start.0
    let colGrowth = end.1 - start.1
    let totalGrowth = rowGrowth + colGrowth
    let growthPerLevel = totalGrowth / 4
    let growthForThisLevel = (level - 1) * growthPerLevel

    var rows = start.0
    var cols = start.1
    for i in 0..<growthForThisLevel {
        if i % 2 == 0 && rows < end.0 { rows += 1 }
        else if cols < end.1 { cols += 1 }
        else if rows < end.0 { rows += 1 }
    }
    return (rows, cols)
}

func getSettings(chapter: Int, level: Int) -> (rows: Int, cols: Int, connectorMin: Int, connectorMax: Int, minPath: Int, maxPath: Int) {
    guard let config = chapters[chapter] else { fatalError() }
    let grid = calculateGrid(level: level, start: config.startGrid, end: config.endGrid)

    // NEW FIX: ensure at least 25 connector max
    let baseConnectorMax = max(config.addSubMax, config.multDivMax)
    let connectorMax = max(baseConnectorMax, 25)

    let totalCells = grid.rows * grid.cols
    // Graduated percentages based on grid complexity
    let percentage: Double
    if totalCells <= 16 {
        percentage = 0.50
    } else if totalCells <= 25 {
        percentage = 0.55
    } else if totalCells <= 42 {
        percentage = 0.50
    } else {
        percentage = 0.45  // Very large grids
    }
    let minPath = max(4, Int(floor(Double(totalCells) * percentage)))
    let maxPath = Int(floor(Double(totalCells) * 0.85))

    return (grid.rows, grid.cols, 5, connectorMax, minPath, maxPath)
}

// Run simulation
let iterations = 400
let letters = ["A", "B", "C", "D", "E"]

print("Generation Stress Test - \(iterations) iterations per level")
print("=".repeated(50))
print()

var totalSuccess = 0
var totalFail = 0
var failedLevels: [(String, Int, Int, Int)] = []  // (name, pathFail, connectorFail, total)

for chapter in 1...10 {
    for level in 1...5 {
        let levelName = "\(chapter)-\(letters[level-1])"
        let settings = getSettings(chapter: chapter, level: level)

        var pathFails = 0
        var connectorFails = 0
        var successes = 0

        for _ in 0..<iterations {
            let pathResult = PathFinder.generatePath(
                rows: settings.rows,
                cols: settings.cols,
                minLength: settings.minPath,
                maxLength: settings.maxPath
            )

            if !pathResult.success {
                pathFails += 1
                continue
            }

            let connectorSuccess = testConnectorAssignment(
                rows: settings.rows,
                cols: settings.cols,
                minValue: settings.connectorMin,
                maxValue: settings.connectorMax,
                path: pathResult.path,
                commitments: pathResult.commitments
            )

            if connectorSuccess {
                successes += 1
            } else {
                connectorFails += 1
            }
        }

        totalSuccess += successes
        let failures = pathFails + connectorFails
        totalFail += failures

        let rate = Double(successes) / Double(iterations) * 100
        if failures > 0 {
            failedLevels.append((levelName, pathFails, connectorFails, failures))
            print("\(levelName): \(successes)/\(iterations) (\(String(format: "%.1f", rate))%) - \(pathFails) path, \(connectorFails) connector")
        } else {
            print("\(levelName): ✓ 100%")
        }
    }
}

print()
print("=".repeated(50))
print("SUMMARY")
print("=".repeated(50))

let overallRate = Double(totalSuccess) / Double(totalSuccess + totalFail) * 100
print("Overall: \(totalSuccess)/\(totalSuccess + totalFail) (\(String(format: "%.1f", overallRate))% success)")

if failedLevels.isEmpty {
    print("\n✓ All levels achieved 100% generation success!")
} else {
    print("\nLevels with failures:")
    for f in failedLevels {
        print("  \(f.0): \(f.3) failures (path: \(f.1), connector: \(f.2))")
    }
}

// Helper
extension String {
    func repeated(_ n: Int) -> String {
        String(repeating: self, count: n)
    }
}
