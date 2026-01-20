import Foundation

// MARK: - Print Converter

/// Converts generated puzzles to printable format
enum PrintConverter {

    /// Generates a batch of puzzles formatted for printing using preset difficulty
    static func generatePrintablePuzzles(config: PrintConfig) -> [PrintablePuzzle] {
        let difficulty = DifficultyPresets.byLevel(config.difficulty + 1)
        return generatePrintablePuzzles(config: config, difficulty: difficulty)
    }

    /// Generates a batch of puzzles formatted for printing using custom difficulty settings
    static func generatePrintablePuzzles(
        config: PrintConfig,
        difficulty: DifficultySettings
    ) -> [PrintablePuzzle] {
        var puzzles: [PrintablePuzzle] = []

        for i in 0..<config.puzzleCount {
            // Generate a puzzle using the existing engine
            let result = PuzzleGenerator.generatePuzzle(difficulty: difficulty)

            switch result {
            case .success(let puzzle):
                let printable = convertToPrintable(
                    puzzle: puzzle,
                    puzzleNumber: i + 1,
                    difficultySettings: difficulty
                )
                puzzles.append(printable)

            case .failure:
                // If generation fails, retry once more
                let retry = PuzzleGenerator.generatePuzzle(difficulty: difficulty)
                if case .success(let puzzle) = retry {
                    let printable = convertToPrintable(
                        puzzle: puzzle,
                        puzzleNumber: i + 1,
                        difficultySettings: difficulty
                    )
                    puzzles.append(printable)
                } else {
                    print("Failed to generate puzzle \(i + 1)")
                }
            }
        }

        return puzzles
    }

    /// Converts a generated puzzle to printable format
    static func convertToPrintable(
        puzzle: Puzzle,
        puzzleNumber: Int,
        difficultySettings: DifficultySettings
    ) -> PrintablePuzzle {
        let gridRows = puzzle.rows
        let gridCols = puzzle.cols

        // Create solution set for quick lookup (using coordinate key)
        let solutionCoords = Set(puzzle.solution.path.map { "\($0.row),\($0.col)" })

        // Create solution edges for connector highlighting
        var solutionEdges = Set<String>()
        for i in 0..<(puzzle.solution.path.count - 1) {
            let from = puzzle.solution.path[i]
            let to = puzzle.solution.path[i + 1]
            // Store both directions for easy lookup
            solutionEdges.insert("\(from.row),\(from.col)-\(to.row),\(to.col)")
            solutionEdges.insert("\(to.row),\(to.col)-\(from.row),\(from.col)")
        }

        // Convert cells
        var cells: [PrintableCell] = []
        var targetSum = 0

        for row in 0..<gridRows {
            for col in 0..<gridCols {
                let cell = puzzle.grid[row][col]
                let index = row * gridCols + col
                let coordKey = "\(row),\(col)"
                let inSolution = solutionCoords.contains(coordKey)

                // Calculate target sum from solution path cells
                if inSolution, let answer = cell.answer {
                    targetSum += answer
                }

                cells.append(PrintableCell(
                    index: index,
                    row: row,
                    col: col,
                    expression: cell.expression,
                    answer: cell.answer,
                    isStart: cell.isStart,
                    isEnd: cell.isFinish,
                    inSolution: inSolution
                ))
            }
        }

        // Convert connectors
        let printableConnectors: [PrintableConnector] = puzzle.connectors.map { conn in
            let edgeKey = "\(conn.cellA.row),\(conn.cellA.col)-\(conn.cellB.row),\(conn.cellB.col)"
            return PrintableConnector(
                fromRow: conn.cellA.row,
                fromCol: conn.cellA.col,
                toRow: conn.cellB.row,
                toCol: conn.cellB.col,
                value: conn.value,
                inSolution: solutionEdges.contains(edgeKey)
            )
        }

        // Convert solution path to indices
        let solutionIndices = puzzle.solution.path.map { coord in
            coord.row * gridCols + coord.col
        }

        return PrintablePuzzle(
            id: puzzle.id,
            puzzleNumber: puzzleNumber,
            difficulty: difficultySettings.levelNumber,
            difficultyName: difficultySettings.name,
            gridRows: gridRows,
            gridCols: gridCols,
            cells: cells,
            connectors: printableConnectors,
            targetSum: targetSum,
            solution: solutionIndices
        )
    }

    /// Validates print configuration
    static func validateConfig(_ config: PrintConfig) -> [String] {
        var errors: [String] = []

        if config.difficulty < 0 || config.difficulty > 9 {
            errors.append("Difficulty must be between 0 and 9")
        }

        if config.puzzleCount < 1 || config.puzzleCount > 100 {
            errors.append("Puzzle count must be between 1 and 100")
        }

        if config.cellSize < 8 || config.cellSize > 20 {
            errors.append("Cell size must be between 8mm and 20mm")
        }

        return errors
    }

    /// Generates a unique ID for a puzzle batch
    static func generateBatchId() -> String {
        let timestamp = Date().timeIntervalSince1970
        let random = Int.random(in: 0..<10000)
        return "batch-\(Int(timestamp))-\(random)"
    }
}
