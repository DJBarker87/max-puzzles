import Foundation

// MARK: - PuzzleValidator

/// Validates generated puzzles
enum PuzzleValidator {

    // MARK: - Individual Validations

    /// Validate path is correctly formed
    static func validatePath(path: [Coordinate], rows: Int, cols: Int) -> ValidationResult {
        var errors: [String] = []

        // Path must have at least 2 elements
        guard path.count >= 2 else {
            return .failure(["Path must have at least 2 elements"])
        }

        // First element must be START (0, 0)
        if path[0] != Coordinate(row: 0, col: 0) {
            errors.append("Path must start at (0,0), but starts at \(path[0].key)")
        }

        // Last element must be FINISH
        let last = path[path.count - 1]
        if last != Coordinate(row: rows - 1, col: cols - 1) {
            errors.append("Path must end at (\(rows - 1),\(cols - 1)), but ends at \(last.key)")
        }

        // Check for valid adjacency and no duplicates
        var visited = Set<String>()

        for (i, coord) in path.enumerated() {
            // Check bounds
            if coord.row < 0 || coord.row >= rows || coord.col < 0 || coord.col >= cols {
                errors.append("Path coordinate \(coord.key) is out of bounds")
            }

            // Check for duplicates
            if visited.contains(coord.key) {
                errors.append("Duplicate coordinate in path: \(coord.key)")
            }
            visited.insert(coord.key)

            // Check adjacency with previous cell
            if i > 0 {
                let prev = path[i - 1]
                if !PathFinder.areAdjacent(prev, coord) {
                    errors.append("Non-adjacent cells in path: \(prev.key) to \(coord.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate connector values are unique per cell
    static func validateConnectorUniqueness(connectors: [Connector], rows: Int, cols: Int) -> ValidationResult {
        var errors: [String] = []

        for row in 0..<rows {
            for col in 0..<cols {
                let cell = Coordinate(row: row, col: col)
                let cellConnectors = ConnectorBuilder.getConnectors(for: cell, in: connectors)
                let values = cellConnectors.map { $0.value }

                if values.count != Set(values).count {
                    errors.append("Duplicate connector value at cell \(cell.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate cell answers match exactly one connector
    static func validateCellAnswers(cells: [[Cell]], connectors: [Connector]) -> ValidationResult {
        var errors: [String] = []

        for row in cells {
            for cell in row {
                if cell.isFinish {
                    if cell.answer != nil {
                        errors.append("FINISH cell should have nil answer")
                    }
                    continue
                }

                guard let answer = cell.answer else {
                    errors.append("Cell \(cell.coordinate.key) has nil answer but is not FINISH")
                    continue
                }

                let cellConnectors = ConnectorBuilder.getConnectors(for: cell.coordinate, in: connectors)
                let matchingCount = cellConnectors.filter { $0.value == answer }.count

                if matchingCount == 0 {
                    errors.append("Cell \(cell.coordinate.key) has answer \(answer) but no matching connector")
                } else if matchingCount > 1 {
                    errors.append("Cell \(cell.coordinate.key) has answer \(answer) matching \(matchingCount) connectors")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate solution path is arithmetically valid
    static func validateSolutionPath(path: [Coordinate], cells: [[Cell]], connectors: [Connector]) -> ValidationResult {
        var errors: [String] = []

        for i in 0..<(path.count - 1) {
            let current = path[i]
            let next = path[i + 1]
            let cell = cells[current.row][current.col]

            guard let connector = ConnectorBuilder.getConnector(between: current, and: next, in: connectors) else {
                errors.append("No connector between path cells \(current.key) and \(next.key)")
                continue
            }

            if cell.answer != connector.value {
                errors.append("Cell \(current.key) answer \(cell.answer ?? -1) doesn't match connector value \(connector.value)")
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    /// Validate all expressions evaluate correctly
    static func validateExpressions(cells: [[Cell]]) -> ValidationResult {
        var errors: [String] = []

        for row in cells {
            for cell in row {
                // Skip START and FINISH
                if cell.isStart || cell.isFinish {
                    continue
                }

                if cell.expression.isEmpty {
                    errors.append("Cell \(cell.coordinate.key) has empty expression")
                    continue
                }

                guard let result = ExpressionGenerator.evaluateExpression(cell.expression) else {
                    errors.append("Cannot evaluate expression '\(cell.expression)' at \(cell.coordinate.key)")
                    continue
                }

                if result != cell.answer {
                    errors.append("Expression '\(cell.expression)' = \(result), but cell answer is \(cell.answer ?? -1) at \(cell.coordinate.key)")
                }
            }
        }

        return errors.isEmpty ? .success() : .failure(errors)
    }

    // MARK: - Complete Validation

    /// Run all validations on a complete puzzle
    static func validatePuzzle(_ puzzle: Puzzle) -> ValidationResult {
        var allErrors: [String] = []
        var allWarnings: [String] = []

        // Validate path
        let pathResult = validatePath(path: puzzle.solution.path, rows: puzzle.rows, cols: puzzle.cols)
        allErrors.append(contentsOf: pathResult.errors)
        allWarnings.append(contentsOf: pathResult.warnings)

        // Validate connector uniqueness
        let connectorResult = validateConnectorUniqueness(connectors: puzzle.connectors, rows: puzzle.rows, cols: puzzle.cols)
        allErrors.append(contentsOf: connectorResult.errors)
        allWarnings.append(contentsOf: connectorResult.warnings)

        // Validate cell answers
        let cellResult = validateCellAnswers(cells: puzzle.grid, connectors: puzzle.connectors)
        allErrors.append(contentsOf: cellResult.errors)
        allWarnings.append(contentsOf: cellResult.warnings)

        // Validate solution path
        let solutionResult = validateSolutionPath(path: puzzle.solution.path, cells: puzzle.grid, connectors: puzzle.connectors)
        allErrors.append(contentsOf: solutionResult.errors)
        allWarnings.append(contentsOf: solutionResult.warnings)

        // Validate expressions
        let expressionResult = validateExpressions(cells: puzzle.grid)
        allErrors.append(contentsOf: expressionResult.errors)
        allWarnings.append(contentsOf: expressionResult.warnings)

        return ValidationResult(valid: allErrors.isEmpty, errors: allErrors, warnings: allWarnings)
    }
}
