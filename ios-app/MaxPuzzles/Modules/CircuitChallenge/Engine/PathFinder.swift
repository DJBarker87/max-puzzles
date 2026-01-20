import Foundation

// MARK: - Path Result

/// Result of path generation attempt
struct PathResult {
    let success: Bool
    let path: [Coordinate]
    let diagonalCommitments: [String: DiagonalDirection]
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
    static func generatePath(
        rows: Int,
        cols: Int,
        minLength: Int,
        maxLength: Int,
        maxAttempts: Int = 200  // Increased from 100 for better success on larger grids
    ) -> PathResult {
        let start = Coordinate(row: 0, col: 0)
        let finish = Coordinate(row: rows - 1, col: cols - 1)

        for _ in 0..<maxAttempts {
            var path: [Coordinate] = [start]
            var visited = Set<String>([start.key])
            var diagonalCommitments: [String: DiagonalDirection] = [:]

            var current = start

            while current != finish {
                if path.count > maxLength {
                    break
                }

                let adjacent = getAdjacent(current, rows: rows, cols: cols)

                let validMoves = adjacent.filter { next in
                    guard !visited.contains(next.key) else { return false }
                    guard isDiagonalMoveValid(from: current, to: next, commitments: diagonalCommitments) else {
                        return false
                    }
                    return true
                }

                if validMoves.isEmpty {
                    break
                }

                let next: Coordinate
                let progressRatio = Double(path.count) / Double(maxLength)
                let totalCells = rows * cols
                let isSmallGrid = totalCells <= 20

                // For small grids, use mostly random moves with occasional bias toward finish
                // For large grids, use smarter scoring with dead-end avoidance
                if isSmallGrid {
                    // Small grid: mostly random with light progress bias
                    if progressRatio > 0.6 && Double.random(in: 0...1) < 0.4 {
                        next = validMoves.min(by: { a, b in
                            manhattanDistance(a, finish) < manhattanDistance(b, finish)
                        })!
                    } else {
                        next = validMoves.randomElement()!
                    }
                } else {
                    // Large grid: smart scoring with dead-end avoidance
                    let scoredMoves = validMoves.map { move -> (Coordinate, Double) in
                        var score = 0.0
                        let distToFinish = manhattanDistance(move, finish)

                        // Stronger finish bias as we approach max length
                        if progressRatio > 0.7 {
                            score -= Double(distToFinish) * (progressRatio - 0.5) * 2
                        }

                        // Dead-end avoidance
                        let futureOptions = getAdjacent(move, rows: rows, cols: cols)
                            .filter { !visited.contains($0.key) && $0 != current }
                            .count
                        score += Double(futureOptions) * 0.5

                        // Random factor for variety
                        score += Double.random(in: 0...0.5)

                        return (move, score)
                    }
                    next = scoredMoves.max(by: { $0.1 < $1.1 })!.0
                }

                if isDiagonalMove(from: current, to: next) {
                    let key = getDiagonalKey(current, next)
                    let direction = getDiagonalDirection(from: current, to: next)
                    diagonalCommitments[key] = direction
                }

                path.append(next)
                visited.insert(next.key)
                current = next
            }

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

    /// Get the key for the 2x2 block a diagonal belongs to
    static func getDiagonalKey(_ cellA: Coordinate, _ cellB: Coordinate) -> String {
        let minRow = min(cellA.row, cellB.row)
        let minCol = min(cellA.col, cellB.col)
        return "\(minRow),\(minCol)"
    }

    /// Determine diagonal direction for a move
    static func getDiagonalDirection(from: Coordinate, to: Coordinate) -> DiagonalDirection {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col

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
            return true
        }

        let key = getDiagonalKey(from, to)
        let direction = getDiagonalDirection(from: from, to: to)

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
    /// Shorter paths need fewer direction changes
    static func isInterestingPath(_ path: [Coordinate]) -> Bool {
        let minChanges: Int
        if path.count < 6 {
            minChanges = 1  // Very short paths just need 1 turn
        } else if path.count < 8 {
            minChanges = 2  // Short paths need 2 turns
        } else {
            minChanges = 3  // Normal paths need 3 turns
        }
        return countDirectionChanges(path) >= minChanges
    }

    /// Check if two cells are adjacent (including diagonally)
    static func areAdjacent(_ a: Coordinate, _ b: Coordinate) -> Bool {
        let rowDiff = abs(a.row - b.row)
        let colDiff = abs(a.col - b.col)
        return rowDiff <= 1 && colDiff <= 1 && (rowDiff + colDiff > 0)
    }
}
