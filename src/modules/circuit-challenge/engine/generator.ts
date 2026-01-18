import { v4 as uuidv4 } from 'uuid'
import type { Puzzle } from '../types'
import type { DifficultySettings, GenerationResult } from './types'
import { generatePath } from './pathfinder'
import { buildDiagonalGrid, buildConnectorGraph } from './connectors'
import { assignConnectorValues } from './valueAssigner'
import { assignCellAnswers } from './cellAssigner'
import { applyExpressions } from './expressions'
import { validatePuzzle } from './validator'
import { calculateMinPathLength, calculateMaxPathLength } from './difficulty'

/**
 * Options for puzzle generation
 */
export interface GenerationOptions {
  /** Maximum attempts before giving up (default: 20) */
  maxAttempts?: number
  /** Whether to validate the result (default: true) */
  validateResult?: boolean
}

/**
 * Generate a unique puzzle ID
 */
function generatePuzzleId(): string {
  return uuidv4()
}

/**
 * Generate a complete puzzle for the given difficulty settings
 */
export function generatePuzzle(
  difficulty: DifficultySettings,
  options: GenerationOptions = {}
): GenerationResult {
  const maxAttempts = options.maxAttempts ?? 20
  const shouldValidate = options.validateResult ?? true

  const { gridRows, gridCols, connectorMin, connectorMax } = difficulty

  // Calculate path lengths if not set
  const minPath = difficulty.minPathLength || calculateMinPathLength(gridRows, gridCols)
  const maxPath = difficulty.maxPathLength || calculateMaxPathLength(gridRows, gridCols)

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      // Step 1: Generate solution path
      const pathResult = generatePath(gridRows, gridCols, minPath, maxPath)
      if (!pathResult.success) {
        continue
      }

      // Step 2: Build diagonal grid from path commitments
      const diagonalGrid = buildDiagonalGrid(gridRows, gridCols, pathResult.diagonalCommitments)

      // Step 3: Build connector graph
      const unvaluedConnectors = buildConnectorGraph(gridRows, gridCols, diagonalGrid)

      // Step 4: Assign connector values
      const valueResult = assignConnectorValues(unvaluedConnectors, connectorMin, connectorMax)
      if (!valueResult.success) {
        continue
      }

      // Step 5: Assign cell answers based on solution path
      const cellGrid = assignCellAnswers(gridRows, gridCols, pathResult.path, valueResult.connectors)

      // Step 6: Generate arithmetic expressions for each cell
      applyExpressions(cellGrid.cells, difficulty)

      // Step 7: Construct puzzle object
      const puzzle: Puzzle = {
        id: generatePuzzleId(),
        difficulty: getDifficultyLevel(difficulty),
        grid: cellGrid.cells,
        connectors: valueResult.connectors,
        solution: {
          path: pathResult.path,
          steps: pathResult.path.length - 1,
        },
      }

      // Step 8: Validate if requested
      if (shouldValidate) {
        const validation = validatePuzzle(puzzle)
        if (!validation.valid) {
          console.warn(`Attempt ${attempt} failed validation:`, validation.errors)
          continue
        }
      }

      // Success!
      return { success: true, puzzle }
    } catch (error) {
      console.warn(`Attempt ${attempt} threw error:`, error)
      continue
    }
  }

  // All attempts failed
  return {
    success: false,
    error: `Failed to generate puzzle after ${maxAttempts} attempts. Try adjusting difficulty settings.`,
  }
}

/**
 * Get numeric difficulty level from settings (1-10 or 0 for custom)
 */
function getDifficultyLevel(settings: DifficultySettings): number {
  // Map preset names to levels
  const nameToLevel: Record<string, number> = {
    'Tiny Tot': 1,
    'Beginner': 2,
    'Easy': 3,
    'Getting There': 4,
    'Times Tables': 5,
    'Confident': 6,
    'Adventurous': 7,
    'Division Intro': 8,
    'Challenge': 9,
    'Expert': 10,
  }
  return nameToLevel[settings.name] ?? 0
}
