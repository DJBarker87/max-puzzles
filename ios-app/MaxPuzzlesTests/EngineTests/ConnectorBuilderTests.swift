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

    func testConnectorGraphCountLargerGrid() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: [:])
        let connectors = ConnectorBuilder.buildConnectorGraph(rows: 4, cols: 5, diagonalGrid: grid)

        // Horizontal: 4 rows × 4 connectors = 16
        // Vertical: 3 rows × 5 connectors = 15
        // Diagonal: 3 rows × 4 connectors = 12
        // Total: 43
        XCTAssertEqual(connectors.count, 43)
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

    func testConnectorValuesWithinRange() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: [:])
        let unvalued = ConnectorBuilder.buildConnectorGraph(rows: 4, cols: 5, diagonalGrid: grid)
        let result = ConnectorBuilder.assignConnectorValues(
            unvaluedConnectors: unvalued,
            minValue: 10,
            maxValue: 40
        )

        XCTAssertTrue(result.success)

        for connector in result.connectors {
            XCTAssertGreaterThanOrEqual(connector.value, 10)
            XCTAssertLessThanOrEqual(connector.value, 40)
        }
    }

    func testDivisionConnectorsReserved() {
        // Generate a path first
        let pathResult = PathFinder.generatePath(rows: 4, cols: 5, minLength: 8, maxLength: 15)
        XCTAssertTrue(pathResult.success)

        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 4, cols: 5, commitments: pathResult.diagonalCommitments)
        let unvalued = ConnectorBuilder.buildConnectorGraph(rows: 4, cols: 5, diagonalGrid: grid)
        let result = ConnectorBuilder.assignConnectorValues(
            unvaluedConnectors: unvalued,
            minValue: 5,
            maxValue: 50,
            divisionEnabled: true,
            solutionPath: pathResult.path,
            multDivRange: 12
        )

        XCTAssertTrue(result.success)
        XCTAssertGreaterThan(result.divisionConnectorIndices.count, 0, "Should have at least one division connector")
    }

    func testGetConnectorBetweenCells() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 3, cols: 3, commitments: [:])
        let unvalued = ConnectorBuilder.buildConnectorGraph(rows: 3, cols: 3, diagonalGrid: grid)
        let result = ConnectorBuilder.assignConnectorValues(
            unvaluedConnectors: unvalued,
            minValue: 1,
            maxValue: 20
        )

        XCTAssertTrue(result.success)

        // Should find horizontal connector between (0,0) and (0,1)
        let connector = ConnectorBuilder.getConnector(
            between: Coordinate(row: 0, col: 0),
            and: Coordinate(row: 0, col: 1),
            in: result.connectors
        )
        XCTAssertNotNil(connector)
        XCTAssertEqual(connector?.type, .horizontal)
    }

    func testGetConnectorsForCell() {
        let grid = ConnectorBuilder.buildDiagonalGrid(rows: 3, cols: 3, commitments: [:])
        let unvalued = ConnectorBuilder.buildConnectorGraph(rows: 3, cols: 3, diagonalGrid: grid)
        let result = ConnectorBuilder.assignConnectorValues(
            unvaluedConnectors: unvalued,
            minValue: 1,
            maxValue: 20
        )

        XCTAssertTrue(result.success)

        // Middle cell should have 8 connectors (or close to it depending on diagonals)
        let middleConnectors = ConnectorBuilder.getConnectors(
            for: Coordinate(row: 1, col: 1),
            in: result.connectors
        )
        XCTAssertGreaterThanOrEqual(middleConnectors.count, 6)
    }
}
