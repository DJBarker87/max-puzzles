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

    func testGeneratePuzzleLevel5() {
        let difficulty = DifficultyPresets.byLevel(5)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 4)
            XCTAssertEqual(puzzle.grid[0].count, 5)
            let validation = PuzzleValidator.validatePuzzle(puzzle)
            XCTAssertTrue(validation.valid, "Puzzle should be valid. Errors: \(validation.errors)")
        case .failure(let error):
            XCTFail("Generation failed: \(error)")
        }
    }

    func testGeneratePuzzleLevel10() {
        let difficulty = DifficultyPresets.byLevel(10)
        let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

        switch result {
        case .success(let puzzle):
            XCTAssertEqual(puzzle.grid.count, 6)
            XCTAssertEqual(puzzle.grid[0].count, 8)
            let validation = PuzzleValidator.validatePuzzle(puzzle)
            XCTAssertTrue(validation.valid, "Puzzle should be valid. Errors: \(validation.errors)")
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
        // Generate 50 puzzles at Level 5 and verify all are valid
        let difficulty = DifficultyPresets.byLevel(5)
        var failures = 0

        for i in 0..<50 {
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

        XCTAssertEqual(failures, 0, "\(failures) puzzles failed out of 50")
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

    func testPuzzleHasValidExpressions() {
        let difficulty = DifficultyPresets.byLevel(5)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        for row in puzzle.grid {
            for cell in row {
                if cell.isStart || cell.isFinish {
                    continue
                }

                let evaluated = ExpressionGenerator.evaluateExpression(cell.expression)
                XCTAssertNotNil(evaluated, "Expression '\(cell.expression)' should be evaluable")
                XCTAssertEqual(evaluated, cell.answer, "Expression '\(cell.expression)' should equal answer \(cell.answer ?? -1)")
            }
        }
    }

    func testPuzzleConnectorUniqueness() {
        let difficulty = DifficultyPresets.byLevel(5)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        // Check each cell has unique connector values
        for row in 0..<puzzle.rows {
            for col in 0..<puzzle.cols {
                let cellConnectors = puzzle.connectors(for: Coordinate(row: row, col: col))
                let values = cellConnectors.map { $0.value }
                XCTAssertEqual(values.count, Set(values).count, "Cell (\(row),\(col)) should have unique connector values")
            }
        }
    }

    func testStartCellHasExpression() {
        let difficulty = DifficultyPresets.byLevel(3)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        let startCell = puzzle.grid[0][0]
        XCTAssertTrue(startCell.isStart)
        // START cell should have an expression (it's on the solution path)
        XCTAssertFalse(startCell.expression.isEmpty || startCell.expression == "START", "START cell should have an arithmetic expression")
    }

    func testFinishCellHasNoExpression() {
        let difficulty = DifficultyPresets.byLevel(3)

        guard case .success(let puzzle) = PuzzleGenerator.generatePuzzle(difficulty: difficulty) else {
            XCTFail("Generation failed")
            return
        }

        let finishRow = puzzle.rows - 1
        let finishCol = puzzle.cols - 1
        let finishCell = puzzle.grid[finishRow][finishCol]
        XCTAssertTrue(finishCell.isFinish)
        XCTAssertTrue(finishCell.expression.isEmpty, "FINISH cell should have empty expression")
        XCTAssertNil(finishCell.answer, "FINISH cell should have nil answer")
    }
}
