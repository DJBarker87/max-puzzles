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
        let minLength = 6
        let maxLength = 15

        var successCount = 0
        for _ in 0..<20 {
            let result = PathFinder.generatePath(rows: 4, cols: 5, minLength: minLength, maxLength: maxLength)

            if result.success {
                successCount += 1
                XCTAssertGreaterThanOrEqual(result.path.count, minLength)
                XCTAssertLessThanOrEqual(result.path.count, maxLength)
            }
        }

        // Most attempts should succeed
        XCTAssertGreaterThanOrEqual(successCount, 15, "At least 15/20 paths should generate successfully")
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

    func testAreAdjacentHorizontal() {
        let a = Coordinate(row: 2, col: 3)
        let b = Coordinate(row: 2, col: 4)
        XCTAssertTrue(PathFinder.areAdjacent(a, b))
    }

    func testAreAdjacentVertical() {
        let a = Coordinate(row: 2, col: 3)
        let b = Coordinate(row: 3, col: 3)
        XCTAssertTrue(PathFinder.areAdjacent(a, b))
    }

    func testAreAdjacentDiagonal() {
        let a = Coordinate(row: 2, col: 3)
        let b = Coordinate(row: 3, col: 4)
        XCTAssertTrue(PathFinder.areAdjacent(a, b))
    }

    func testAreNotAdjacentFarApart() {
        let a = Coordinate(row: 0, col: 0)
        let b = Coordinate(row: 2, col: 2)
        XCTAssertFalse(PathFinder.areAdjacent(a, b))
    }

    func testAreNotAdjacentSameCell() {
        let a = Coordinate(row: 2, col: 3)
        XCTAssertFalse(PathFinder.areAdjacent(a, a))
    }

    func testGetAdjacentReturnsValidCells() {
        let pos = Coordinate(row: 1, col: 1)
        let adjacent = PathFinder.getAdjacent(pos, rows: 4, cols: 4)

        // Should have 8 neighbors in the middle
        XCTAssertEqual(adjacent.count, 8)
    }

    func testGetAdjacentCornerHasFewerNeighbors() {
        let pos = Coordinate(row: 0, col: 0)
        let adjacent = PathFinder.getAdjacent(pos, rows: 4, cols: 4)

        // Corner should have 3 neighbors
        XCTAssertEqual(adjacent.count, 3)
    }

    func testGetAdjacentEdgeHasFewerNeighbors() {
        let pos = Coordinate(row: 0, col: 1)
        let adjacent = PathFinder.getAdjacent(pos, rows: 4, cols: 4)

        // Edge (not corner) should have 5 neighbors
        XCTAssertEqual(adjacent.count, 5)
    }
}
