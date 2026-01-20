import Foundation

// MARK: - Generation Options

/// Options for puzzle generation
struct GenerationOptions {
    var maxAttempts: Int = 30  // Increased from 20 for better success on complex grids
    var validateResult: Bool = true
}

// MARK: - PuzzleGenerator

/// Main puzzle generator - orchestrates all components
enum PuzzleGenerator {

    /// Generate a complete puzzle for the given difficulty settings
    static func generatePuzzle(
        difficulty: DifficultySettings,
        options: GenerationOptions = GenerationOptions()
    ) -> GenerationResult {

        // Calculate path lengths if not set
        var settings = difficulty
        if settings.minPathLength == 0 {
            settings.minPathLength = DifficultyPresets.calculateMinPathLength(rows: settings.gridRows, cols: settings.gridCols)
        }
        if settings.maxPathLength == 0 {
            settings.maxPathLength = DifficultyPresets.calculateMaxPathLength(rows: settings.gridRows, cols: settings.gridCols)
        }

        var pathFailures = 0
        var connectorFailures = 0
        var validationFailures = 0

        for attempt in 1...options.maxAttempts {
            // Step 1: Generate solution path
            let pathResult = PathFinder.generatePath(
                rows: settings.gridRows,
                cols: settings.gridCols,
                minLength: settings.minPathLength,
                maxLength: settings.maxPathLength
            )

            guard pathResult.success else {
                pathFailures += 1
                continue
            }

            // Step 2: Build diagonal grid from path commitments
            let diagonalGrid = ConnectorBuilder.buildDiagonalGrid(
                rows: settings.gridRows,
                cols: settings.gridCols,
                commitments: pathResult.diagonalCommitments
            )

            // Step 3: Build connector graph
            let unvaluedConnectors = ConnectorBuilder.buildConnectorGraph(
                rows: settings.gridRows,
                cols: settings.gridCols,
                diagonalGrid: diagonalGrid
            )

            // Step 4: Assign connector values
            let valueResult = ConnectorBuilder.assignConnectorValues(
                unvaluedConnectors: unvaluedConnectors,
                minValue: settings.connectorMin,
                maxValue: settings.connectorMax,
                divisionEnabled: settings.divisionEnabled,
                solutionPath: pathResult.path,
                multDivRange: settings.multDivRange
            )

            guard valueResult.success else {
                connectorFailures += 1
                continue
            }

            // Step 5: Assign cell answers based on solution path
            var cellGrid = CellAssigner.assignCellAnswers(
                rows: settings.gridRows,
                cols: settings.gridCols,
                solutionPath: pathResult.path,
                connectors: valueResult.connectors,
                divisionConnectorIndices: valueResult.divisionConnectorIndices
            )

            // Step 6: Generate arithmetic expressions for each cell
            ExpressionGenerator.applyExpressions(
                cells: &cellGrid.cells,
                difficulty: settings,
                divisionCells: cellGrid.divisionCells
            )

            // Step 7: Construct puzzle object
            let puzzle = Puzzle(
                id: UUID().uuidString,
                difficulty: settings.levelNumber,
                grid: cellGrid.cells,
                connectors: valueResult.connectors,
                solution: Solution(path: pathResult.path)
            )

            // Step 8: Validate if requested
            if options.validateResult {
                let validation = PuzzleValidator.validatePuzzle(puzzle)
                if !validation.valid {
                    print("Attempt \(attempt) failed validation: \(validation.errors)")
                    validationFailures += 1
                    continue
                }
            }

            // Success!
            return .success(puzzle)
        }

        // All attempts failed - log detailed breakdown
        print("Generation failed for \(settings.gridRows)×\(settings.gridCols) grid, connector range \(settings.connectorMin)-\(settings.connectorMax)")
        print("  Path failures: \(pathFailures), Connector failures: \(connectorFailures), Validation failures: \(validationFailures)")

        return .failure("Failed to generate puzzle after \(options.maxAttempts) attempts. Try adjusting difficulty settings.")
    }
}
