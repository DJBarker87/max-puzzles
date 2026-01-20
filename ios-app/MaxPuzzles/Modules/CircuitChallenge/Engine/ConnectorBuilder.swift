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
