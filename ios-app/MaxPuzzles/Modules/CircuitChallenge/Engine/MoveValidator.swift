import Foundation

// MARK: - MoveValidator

/// Utility functions for validating game moves

// MARK: - Adjacency Check

/// Check if two cells are adjacent (including diagonals)
/// Adjacent means at most 1 step in each direction, but not same cell
func isAdjacent(from: Coordinate, to: Coordinate) -> Bool {
    let rowDiff = abs(from.row - to.row)
    let colDiff = abs(from.col - to.col)
    return rowDiff <= 1 && colDiff <= 1 && (rowDiff > 0 || colDiff > 0)
}

// MARK: - Connector Finding

/// Find the connector between two cells
func getConnectorBetweenCells(
    from: Coordinate,
    to: Coordinate,
    connectors: [Connector]
) -> Connector? {
    return connectors.first { c in
        (c.cellA == from && c.cellB == to) ||
        (c.cellB == from && c.cellA == to)
    }
}

// MARK: - Move Check Result

/// Result of checking a move
struct MoveCheckResult {
    let correct: Bool
    let connector: Connector?
}

// MARK: - Move Correctness Check

/// Check if a move is correct (follows the solution path)
/// A move is correct if the connector's value equals the fromCell's answer
func checkMoveCorrectness(
    fromCell: Cell,
    toCell: Coordinate,
    connectors: [Connector]
) -> MoveCheckResult {
    guard let connector = getConnectorBetweenCells(
        from: Coordinate(row: fromCell.row, col: fromCell.col),
        to: toCell,
        connectors: connectors
    ) else {
        return MoveCheckResult(correct: false, connector: nil)
    }

    // A move is correct if the connector's value equals the fromCell's answer
    // The fromCell's answer tells us which connector to take
    guard let answer = fromCell.answer else {
        return MoveCheckResult(correct: false, connector: connector)
    }

    let correct = answer == connector.value

    return MoveCheckResult(correct: correct, connector: connector)
}

// MARK: - Visited Check

/// Check if a coordinate is in the visited cells list
func isAlreadyVisited(_ coord: Coordinate, in visitedCells: [Coordinate]) -> Bool {
    return visitedCells.contains { $0.row == coord.row && $0.col == coord.col }
}

// MARK: - Finish Check

/// Check if a coordinate is the FINISH cell
func isFinishCell(_ coord: Coordinate, in puzzle: Puzzle) -> Bool {
    return coord.row == puzzle.grid.count - 1 &&
           coord.col == puzzle.grid[0].count - 1
}

// MARK: - Get Adjacent Cells

/// Get all adjacent cell coordinates for a given position
func getAdjacentCells(from position: Coordinate, rows: Int, cols: Int) -> [Coordinate] {
    var adjacent: [Coordinate] = []

    for rowOffset in -1...1 {
        for colOffset in -1...1 {
            // Skip self
            if rowOffset == 0 && colOffset == 0 { continue }

            let newRow = position.row + rowOffset
            let newCol = position.col + colOffset

            // Check bounds
            if newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols {
                adjacent.append(Coordinate(row: newRow, col: newCol))
            }
        }
    }

    return adjacent
}
