import { generatePuzzle } from '../engine/generator'
import { DIFFICULTY_PRESETS } from '../engine/difficulty'
import type { DifficultySettings } from '../engine/types'
import type { Puzzle, Coordinate, Connector } from '../types'
import type {
  PrintConfig,
  PrintablePuzzle,
  PrintableCell,
  PrintableConnector,
} from '../types/print'

/**
 * Generates a batch of puzzles formatted for printing.
 */
export function generatePrintablePuzzles(config: PrintConfig): PrintablePuzzle[] {
  const puzzles: PrintablePuzzle[] = []
  const difficultyIndex = Math.max(0, Math.min(9, config.difficulty))
  const diffSettings = DIFFICULTY_PRESETS[difficultyIndex]

  for (let i = 0; i < config.puzzleCount; i++) {
    // Generate a puzzle using the existing engine
    const result = generatePuzzle(diffSettings)

    if (result.success) {
      // Convert to printable format
      const printable = convertToPrintable(result.puzzle, i + 1, difficultyIndex)
      puzzles.push(printable)
    } else {
      // If generation fails, retry once more
      const retry = generatePuzzle(diffSettings)
      if (retry.success) {
        const printable = convertToPrintable(retry.puzzle, i + 1, difficultyIndex)
        puzzles.push(printable)
      } else {
        console.warn(`Failed to generate puzzle ${i + 1}:`, retry.error)
      }
    }
  }

  return puzzles
}

/**
 * Generates a batch of puzzles formatted for printing using custom difficulty settings.
 */
export function generatePrintablePuzzlesWithSettings(
  config: PrintConfig,
  diffSettings: DifficultySettings
): PrintablePuzzle[] {
  const puzzles: PrintablePuzzle[] = []

  for (let i = 0; i < config.puzzleCount; i++) {
    // Generate a puzzle using the existing engine with custom settings
    const result = generatePuzzle(diffSettings)

    if (result.success) {
      // Convert to printable format
      const printable = convertToPrintableWithSettings(result.puzzle, i + 1, diffSettings)
      puzzles.push(printable)
    } else {
      // If generation fails, retry once more
      const retry = generatePuzzle(diffSettings)
      if (retry.success) {
        const printable = convertToPrintableWithSettings(retry.puzzle, i + 1, diffSettings)
        puzzles.push(printable)
      } else {
        console.warn(`Failed to generate puzzle ${i + 1}:`, retry.error)
      }
    }
  }

  return puzzles
}

/**
 * Difficulty names for display.
 */
const DIFF_NAMES: Record<number, string> = {
  0: 'Tiny Tot',
  1: 'Beginner',
  2: 'Easy',
  3: 'Getting There',
  4: 'Times Tables',
  5: 'Confident',
  6: 'Adventurous',
  7: 'Division Intro',
  8: 'Challenge',
  9: 'Expert',
}

/**
 * Converts a generated puzzle to printable format.
 */
function convertToPrintable(
  puzzle: Puzzle,
  puzzleNumber: number,
  difficultyIndex: number
): PrintablePuzzle {
  const { grid, connectors, solution } = puzzle
  const gridRows = grid.length
  const gridCols = grid[0]?.length || 0

  // Create solution set for quick lookup (using coordinate key)
  const solutionCoords = solution.path.map(
    (c: Coordinate) => `${c.row},${c.col}`
  )
  const solutionSet = new Set(solutionCoords)

  // Create solution edges for connector highlighting
  const solutionEdges = new Set<string>()
  for (let i = 0; i < solution.path.length - 1; i++) {
    const from = solution.path[i]
    const to = solution.path[i + 1]
    // Store both directions for easy lookup
    solutionEdges.add(`${from.row},${from.col}-${to.row},${to.col}`)
    solutionEdges.add(`${to.row},${to.col}-${from.row},${from.col}`)
  }

  // Convert cells
  const cells: PrintableCell[] = []
  let targetSum = 0

  for (let row = 0; row < gridRows; row++) {
    for (let col = 0; col < gridCols; col++) {
      const cell = grid[row][col]
      const index = row * gridCols + col
      const coordKey = `${row},${col}`
      const inSolution = solutionSet.has(coordKey)

      // Calculate target sum from solution path cells
      if (inSolution && cell.answer !== null) {
        targetSum += cell.answer
      }

      cells.push({
        index,
        row,
        col,
        expression: cell.expression,
        answer: cell.answer,
        isStart: cell.isStart,
        isEnd: cell.isFinish,
        inSolution,
      })
    }
  }

  // Convert connectors
  const printableConnectors: PrintableConnector[] = connectors.map(
    (conn: Connector) => {
      const edgeKey = `${conn.cellA.row},${conn.cellA.col}-${conn.cellB.row},${conn.cellB.col}`
      return {
        fromRow: conn.cellA.row,
        fromCol: conn.cellA.col,
        toRow: conn.cellB.row,
        toCol: conn.cellB.col,
        value: conn.value,
        inSolution: solutionEdges.has(edgeKey),
      }
    }
  )

  // Convert solution path to indices
  const solutionIndices = solution.path.map(
    (c: Coordinate) => c.row * gridCols + c.col
  )

  return {
    id: puzzle.id,
    puzzleNumber,
    difficulty: difficultyIndex,
    difficultyName: DIFF_NAMES[difficultyIndex] || `Level ${difficultyIndex + 1}`,
    gridRows,
    gridCols,
    cells,
    connectors: printableConnectors,
    targetSum,
    solution: solutionIndices,
  }
}

/**
 * Converts a generated puzzle to printable format using custom difficulty settings.
 */
function convertToPrintableWithSettings(
  puzzle: Puzzle,
  puzzleNumber: number,
  diffSettings: DifficultySettings
): PrintablePuzzle {
  const { grid, connectors, solution } = puzzle
  const gridRows = grid.length
  const gridCols = grid[0]?.length || 0

  // Create solution set for quick lookup (using coordinate key)
  const solutionCoords = solution.path.map(
    (c: Coordinate) => `${c.row},${c.col}`
  )
  const solutionSet = new Set(solutionCoords)

  // Create solution edges for connector highlighting
  const solutionEdges = new Set<string>()
  for (let i = 0; i < solution.path.length - 1; i++) {
    const from = solution.path[i]
    const to = solution.path[i + 1]
    solutionEdges.add(`${from.row},${from.col}-${to.row},${to.col}`)
    solutionEdges.add(`${to.row},${to.col}-${from.row},${from.col}`)
  }

  // Convert cells
  const cells: PrintableCell[] = []
  let targetSum = 0

  for (let row = 0; row < gridRows; row++) {
    for (let col = 0; col < gridCols; col++) {
      const cell = grid[row][col]
      const index = row * gridCols + col
      const coordKey = `${row},${col}`
      const inSolution = solutionSet.has(coordKey)

      if (inSolution && cell.answer !== null) {
        targetSum += cell.answer
      }

      cells.push({
        index,
        row,
        col,
        expression: cell.expression,
        answer: cell.answer,
        isStart: cell.isStart,
        isEnd: cell.isFinish,
        inSolution,
      })
    }
  }

  // Convert connectors
  const printableConnectors: PrintableConnector[] = connectors.map(
    (conn: Connector) => {
      const edgeKey = `${conn.cellA.row},${conn.cellA.col}-${conn.cellB.row},${conn.cellB.col}`
      return {
        fromRow: conn.cellA.row,
        fromCol: conn.cellA.col,
        toRow: conn.cellB.row,
        toCol: conn.cellB.col,
        value: conn.value,
        inSolution: solutionEdges.has(edgeKey),
      }
    }
  )

  // Convert solution path to indices
  const solutionIndices = solution.path.map(
    (c: Coordinate) => c.row * gridCols + c.col
  )

  // Build difficulty name from settings
  const difficultyName = diffSettings.name || 'Custom'

  return {
    id: puzzle.id,
    puzzleNumber,
    difficulty: 0, // Custom difficulty doesn't have a preset index
    difficultyName,
    gridRows,
    gridCols,
    cells,
    connectors: printableConnectors,
    targetSum,
    solution: solutionIndices,
  }
}

/**
 * Generates a unique ID for a puzzle batch.
 */
export function generateBatchId(): string {
  const timestamp = Date.now().toString(36)
  const random = Math.random().toString(36).substring(2, 6)
  return `batch-${timestamp}-${random}`
}

/**
 * Validates print configuration.
 */
export function validatePrintConfig(config: Partial<PrintConfig>): string[] {
  const errors: string[] = []

  if (config.difficulty !== undefined) {
    if (config.difficulty < 0 || config.difficulty > 9) {
      errors.push('Difficulty must be between 0 and 9')
    }
  }

  if (config.puzzleCount !== undefined) {
    if (config.puzzleCount < 1 || config.puzzleCount > 100) {
      errors.push('Puzzle count must be between 1 and 100')
    }
  }

  if (config.cellSize !== undefined) {
    if (config.cellSize < 8 || config.cellSize > 20) {
      errors.push('Cell size must be between 8mm and 20mm')
    }
  }

  return errors
}
