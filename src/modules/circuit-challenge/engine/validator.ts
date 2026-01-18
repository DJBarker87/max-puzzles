import type { Coordinate, Cell, Connector, Puzzle } from '../types'
import { coordToKey } from './pathfinder'
import { getCellConnectors, getConnectorBetween, areAdjacent } from './connectors'
import { evaluateExpression } from './expressions'

/**
 * Result of validation
 */
export interface ValidationResult {
  valid: boolean
  errors: string[]
  warnings: string[]
}

/**
 * Validate that a path is correctly formed
 */
export function validatePath(
  path: Coordinate[],
  rows: number,
  cols: number
): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  // Path must have at least 2 elements
  if (path.length < 2) {
    errors.push('Path must have at least 2 elements')
    return { valid: false, errors, warnings }
  }

  // First element must be START (0, 0)
  if (path[0].row !== 0 || path[0].col !== 0) {
    errors.push(`Path must start at (0,0), but starts at (${path[0].row},${path[0].col})`)
  }

  // Last element must be FINISH (rows-1, cols-1)
  const last = path[path.length - 1]
  if (last.row !== rows - 1 || last.col !== cols - 1) {
    errors.push(`Path must end at (${rows - 1},${cols - 1}), but ends at (${last.row},${last.col})`)
  }

  // Check for valid adjacency and no duplicates
  const visited = new Set<string>()

  for (let i = 0; i < path.length; i++) {
    const coord = path[i]
    const key = coordToKey(coord)

    // Check bounds
    if (coord.row < 0 || coord.row >= rows || coord.col < 0 || coord.col >= cols) {
      errors.push(`Path coordinate (${coord.row},${coord.col}) is out of bounds`)
    }

    // Check for duplicates
    if (visited.has(key)) {
      errors.push(`Duplicate coordinate in path: (${coord.row},${coord.col})`)
    }
    visited.add(key)

    // Check adjacency with previous cell
    if (i > 0) {
      const prev = path[i - 1]
      if (!areAdjacent(prev, coord)) {
        errors.push(`Non-adjacent cells in path: (${prev.row},${prev.col}) to (${coord.row},${coord.col})`)
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Validate that all connector values are unique per cell
 */
export function validateConnectorUniqueness(
  connectors: Connector[],
  rows: number,
  cols: number
): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const cell = { row, col }
      const cellConnectors = getCellConnectors(cell, connectors)
      const values = cellConnectors.map(c => c.value)

      // Check for duplicates
      const seen = new Set<number>()
      for (const value of values) {
        if (seen.has(value)) {
          errors.push(`Duplicate connector value ${value} at cell (${row},${col})`)
        }
        seen.add(value)
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Validate that cell answers match exactly one connector
 */
export function validateCellAnswers(
  cells: Cell[][],
  connectors: Connector[]
): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  for (const row of cells) {
    for (const cell of row) {
      // FINISH cell should have null answer
      if (cell.isFinish) {
        if (cell.answer !== null) {
          errors.push(`FINISH cell should have null answer, but has ${cell.answer}`)
        }
        continue
      }

      // Other cells must have a non-null answer
      if (cell.answer === null) {
        errors.push(`Cell (${cell.row},${cell.col}) has null answer but is not FINISH`)
        continue
      }

      // Check that exactly one connector has this value
      const cellConnectors = getCellConnectors({ row: cell.row, col: cell.col }, connectors)
      const matchingConnectors = cellConnectors.filter(c => c.value === cell.answer)

      if (matchingConnectors.length === 0) {
        errors.push(`Cell (${cell.row},${cell.col}) has answer ${cell.answer} but no matching connector`)
      } else if (matchingConnectors.length > 1) {
        errors.push(`Cell (${cell.row},${cell.col}) has answer ${cell.answer} matching ${matchingConnectors.length} connectors`)
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Validate that the solution path is arithmetically valid
 */
export function validateSolutionPath(
  path: Coordinate[],
  cells: Cell[][],
  connectors: Connector[]
): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  for (let i = 0; i < path.length - 1; i++) {
    const current = path[i]
    const next = path[i + 1]
    const cell = cells[current.row][current.col]

    // Find connector between current and next
    const connector = getConnectorBetween(current, next, connectors)
    if (!connector) {
      errors.push(`No connector between path cells (${current.row},${current.col}) and (${next.row},${next.col})`)
      continue
    }

    // Cell's answer should match connector value
    if (cell.answer !== connector.value) {
      errors.push(
        `Cell (${current.row},${current.col}) answer ${cell.answer} doesn't match connector value ${connector.value}`
      )
    }
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Validate that all expressions evaluate correctly
 */
export function validateExpressions(cells: Cell[][]): ValidationResult {
  const errors: string[] = []
  const warnings: string[] = []

  for (const row of cells) {
    for (const cell of row) {
      // Skip START and FINISH
      if (cell.isStart || cell.isFinish) {
        continue
      }

      if (!cell.expression) {
        errors.push(`Cell (${cell.row},${cell.col}) has empty expression`)
        continue
      }

      const result = evaluateExpression(cell.expression)
      if (result === null) {
        errors.push(`Cannot evaluate expression "${cell.expression}" at (${cell.row},${cell.col})`)
        continue
      }

      if (result !== cell.answer) {
        errors.push(
          `Expression "${cell.expression}" = ${result}, but cell answer is ${cell.answer} at (${cell.row},${cell.col})`
        )
      }
    }
  }

  return { valid: errors.length === 0, errors, warnings }
}

/**
 * Run all validations on a complete puzzle
 */
export function validatePuzzle(puzzle: Puzzle): ValidationResult {
  const allErrors: string[] = []
  const allWarnings: string[] = []

  const rows = puzzle.grid.length
  const cols = puzzle.grid[0]?.length ?? 0

  // Validate path
  const pathResult = validatePath(puzzle.solution.path, rows, cols)
  allErrors.push(...pathResult.errors)
  allWarnings.push(...pathResult.warnings)

  // Validate connector uniqueness
  const connectorResult = validateConnectorUniqueness(puzzle.connectors, rows, cols)
  allErrors.push(...connectorResult.errors)
  allWarnings.push(...connectorResult.warnings)

  // Validate cell answers
  const cellResult = validateCellAnswers(puzzle.grid, puzzle.connectors)
  allErrors.push(...cellResult.errors)
  allWarnings.push(...cellResult.warnings)

  // Validate solution path
  const solutionResult = validateSolutionPath(puzzle.solution.path, puzzle.grid, puzzle.connectors)
  allErrors.push(...solutionResult.errors)
  allWarnings.push(...solutionResult.warnings)

  // Validate expressions
  const expressionResult = validateExpressions(puzzle.grid)
  allErrors.push(...expressionResult.errors)
  allWarnings.push(...expressionResult.warnings)

  return {
    valid: allErrors.length === 0,
    errors: allErrors,
    warnings: allWarnings,
  }
}
