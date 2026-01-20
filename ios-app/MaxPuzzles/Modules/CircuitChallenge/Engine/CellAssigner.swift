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
