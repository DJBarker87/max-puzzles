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
        multDivRange: Int = 12,
        allowedValues: [Int]? = nil
    ) -> ValueAssignmentResult {

        guard minValue <= maxValue else {
            return .failure("Connector range is empty")
        }

        // Build map: cellKey -> list of connector indices touching that cell
        var cellConnectorMap: [String: [Int]] = [:]

        for (index, connector) in unvaluedConnectors.enumerated() {
            let keyA = connector.cellA.key
            let keyB = connector.cellB.key

            cellConnectorMap[keyA, default: []].append(index)
            cellConnectorMap[keyB, default: []].append(index)
        }

        let palette = allowedValues.map { values in
            Array(Set(values.filter { (minValue...maxValue).contains($0) })).sorted()
        } ?? Array(minValue...maxValue)
        guard !palette.isEmpty else {
            return .failure("The selected times tables do not provide any connector values")
        }
        if let impossibleCell = cellConnectorMap.first(where: { $0.value.count > palette.count }) {
            return .failure(
                "Cell \(impossibleCell.key) needs \(impossibleCell.value.count) unique values, but the range only has \(palette.count)"
            )
        }

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

        }

        guard let connectorValues = solveConnectorValues(
            unvaluedConnectors: unvaluedConnectors,
            cellConnectorMap: cellConnectorMap,
            palette: palette,
            divisionConnectorIndices: Set(divisionConnectorIndices),
            multDivRange: multDivRange
        ) else {
            return .failure("No unique connector-value assignment exists for this graph and range")
        }

        // Convert to Connector type
        let connectors: [Connector] = unvaluedConnectors.enumerated().map { index, uv in
            Connector(
                type: uv.type,
                cellA: uv.cellA,
                cellB: uv.cellB,
                value: connectorValues[index],
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

    /// Edge-colour the connector graph. A one-pass random greedy assignment can paint itself into
    /// a corner even when a valid assignment exists, especially in Level 1's six-value palette.
    /// Most-constrained-first backtracking makes those launches reliable while staying tiny for
    /// the small grids used by the game.
    private static func solveConnectorValues(
        unvaluedConnectors: [UnvaluedConnector],
        cellConnectorMap: [String: [Int]],
        palette: [Int],
        divisionConnectorIndices: Set<Int>,
        multDivRange: Int
    ) -> [Int]? {
        guard !unvaluedConnectors.isEmpty else { return [] }

        var values = Array<Int?>(repeating: nil, count: unvaluedConnectors.count)
        var usedByCell: [String: Set<Int>] = [:]
        for key in cellConnectorMap.keys {
            usedByCell[key] = []
        }

        var unassigned = Set(unvaluedConnectors.indices)
        var exploredNodes = 0
        let nodeBudget = max(250_000, unvaluedConnectors.count * 5_000)

        func availableValues(for index: Int) -> [Int] {
            let connector = unvaluedConnectors[index]
            let usedA = usedByCell[connector.cellA.key] ?? []
            let usedB = usedByCell[connector.cellB.key] ?? []
            return palette.filter { !usedA.contains($0) && !usedB.contains($0) }
        }

        func orderedValues(_ available: [Int], for index: Int) -> [Int] {
            guard divisionConnectorIndices.contains(index) else {
                return available.shuffled()
            }

            let small = available.filter { $0 <= multDivRange }.shuffled()
            let remaining = available.filter { $0 > multDivRange }.shuffled()
            return small + remaining
        }

        func solve() -> Bool {
            guard !unassigned.isEmpty else { return true }
            exploredNodes += 1
            guard exploredNodes <= nodeBudget else { return false }

            var selectedIndex: Int?
            var selectedAvailable: [Int] = []
            var selectedDegree = -1

            for index in unassigned {
                let available = availableValues(for: index)
                if available.isEmpty { return false }

                let connector = unvaluedConnectors[index]
                let degree = (cellConnectorMap[connector.cellA.key]?.count ?? 0)
                    + (cellConnectorMap[connector.cellB.key]?.count ?? 0)

                if selectedIndex == nil
                    || available.count < selectedAvailable.count
                    || (available.count == selectedAvailable.count && degree > selectedDegree) {
                    selectedIndex = index
                    selectedAvailable = available
                    selectedDegree = degree
                }
            }

            guard let index = selectedIndex else { return true }
            let connector = unvaluedConnectors[index]
            unassigned.remove(index)

            for value in orderedValues(selectedAvailable, for: index) {
                values[index] = value
                usedByCell[connector.cellA.key, default: []].insert(value)
                usedByCell[connector.cellB.key, default: []].insert(value)

                if solve() { return true }

                usedByCell[connector.cellA.key]?.remove(value)
                usedByCell[connector.cellB.key]?.remove(value)
                values[index] = nil
            }

            unassigned.insert(index)
            return false
        }

        guard solve() else { return nil }
        return values.compactMap { $0 }
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
