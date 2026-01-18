import type { Cell, Coordinate, Connector } from '../types'
import { coordToKey } from './pathfinder'
import { getCellConnectors, getConnectorBetween } from './connectors'
import { randomChoice } from './valueAssigner'

/**
 * Grid of cells with dimensions
 */
export interface CellGrid {
  cells: Cell[][]
  rows: number
  cols: number
}

/**
 * Assign answers to all cells based on the solution path
 * - Path cells: answer = value of connector to next cell in path
 * - Other cells: answer = random connector value (creates wrong paths)
 * - FINISH cell: answer = null
 */
export function assignCellAnswers(
  rows: number,
  cols: number,
  solutionPath: Coordinate[],
  connectors: Connector[]
): CellGrid {
  // Initialize cells grid
  const cells: Cell[][] = []
  for (let row = 0; row < rows; row++) {
    const rowCells: Cell[] = []
    for (let col = 0; col < cols; col++) {
      rowCells.push({
        row,
        col,
        expression: '', // To be filled by expression generator
        answer: null,
        isStart: row === 0 && col === 0,
        isFinish: row === rows - 1 && col === cols - 1,
      })
    }
    cells.push(rowCells)
  }

  // Create set of solution path coordinates for quick lookup
  const pathSet = new Set(solutionPath.map(c => coordToKey(c)))

  // Assign answers for cells ON the solution path (except FINISH)
  for (let i = 0; i < solutionPath.length - 1; i++) {
    const current = solutionPath[i]
    const next = solutionPath[i + 1]

    // Find the connector between current and next
    const connector = getConnectorBetween(current, next, connectors)
    if (!connector) {
      throw new Error(`No connector found between (${current.row},${current.col}) and (${next.row},${next.col})`)
    }

    // Cell's answer is the connector's value
    cells[current.row][current.col].answer = connector.value
  }

  // Assign answers for cells NOT on the solution path (except FINISH)
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols; col++) {
      const cell = cells[row][col]

      // Skip FINISH cell
      if (cell.isFinish) {
        continue
      }

      // Skip cells already assigned (on solution path)
      const key = coordToKey({ row, col })
      if (pathSet.has(key)) {
        continue
      }

      // Get all connectors touching this cell
      const cellConnectors = getCellConnectors({ row, col }, connectors)

      if (cellConnectors.length === 0) {
        throw new Error(`No connectors found for cell (${row},${col})`)
      }

      // Pick a random connector's value as this cell's answer
      const randomConnector = randomChoice(cellConnectors)
      cell.answer = randomConnector.value
    }
  }

  return { cells, rows, cols }
}

/**
 * Find which cell a given cell leads to based on its answer
 * Returns null for FINISH or if no matching connector
 */
export function getExitCell(
  cell: Coordinate,
  answer: number,
  connectors: Connector[]
): Coordinate | null {
  const cellConnectors = getCellConnectors(cell, connectors)

  // Find connector with matching value
  const matchingConnector = cellConnectors.find(c => c.value === answer)
  if (!matchingConnector) {
    return null
  }

  // Return the other cell
  if (matchingConnector.cellA.row === cell.row && matchingConnector.cellA.col === cell.col) {
    return matchingConnector.cellB
  }
  return matchingConnector.cellA
}
