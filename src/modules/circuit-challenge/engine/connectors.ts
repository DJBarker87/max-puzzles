import type { Coordinate, DiagonalDirection, Connector } from '../types'
import type { DiagonalCommitments } from './pathfinder'

/**
 * Connector before value assignment
 */
export interface UnvaluedConnector {
  type: 'horizontal' | 'vertical' | 'diagonal'
  cellA: Coordinate
  cellB: Coordinate
  direction?: DiagonalDirection
}

/**
 * Grid of diagonal directions for each 2x2 block
 * [row][col] where row is 0 to rows-2, col is 0 to cols-2
 */
export type DiagonalGrid = DiagonalDirection[][]

/**
 * Build a grid of diagonal directions for each 2x2 block
 * Uses committed directions from path generation, fills rest randomly
 */
export function buildDiagonalGrid(
  rows: number,
  cols: number,
  commitments: DiagonalCommitments
): DiagonalGrid {
  const grid: DiagonalGrid = []

  for (let row = 0; row < rows - 1; row++) {
    const rowArray: DiagonalDirection[] = []
    for (let col = 0; col < cols - 1; col++) {
      const key = `${row},${col}`
      const committed = commitments.get(key)

      if (committed) {
        rowArray.push(committed)
      } else {
        // Randomly choose direction
        rowArray.push(Math.random() < 0.5 ? 'DR' : 'DL')
      }
    }
    grid.push(rowArray)
  }

  return grid
}

/**
 * Build the complete connector graph for a grid
 */
export function buildConnectorGraph(
  rows: number,
  cols: number,
  diagonalGrid: DiagonalGrid
): UnvaluedConnector[] {
  const connectors: UnvaluedConnector[] = []

  // Add horizontal connectors
  for (let row = 0; row < rows; row++) {
    for (let col = 0; col < cols - 1; col++) {
      connectors.push({
        type: 'horizontal',
        cellA: { row, col },
        cellB: { row, col: col + 1 },
      })
    }
  }

  // Add vertical connectors
  for (let row = 0; row < rows - 1; row++) {
    for (let col = 0; col < cols; col++) {
      connectors.push({
        type: 'vertical',
        cellA: { row, col },
        cellB: { row: row + 1, col },
      })
    }
  }

  // Add diagonal connectors based on grid directions
  for (let row = 0; row < rows - 1; row++) {
    for (let col = 0; col < cols - 1; col++) {
      const direction = diagonalGrid[row][col]

      if (direction === 'DR') {
        // Down-right diagonal: (row, col) to (row+1, col+1)
        connectors.push({
          type: 'diagonal',
          cellA: { row, col },
          cellB: { row: row + 1, col: col + 1 },
          direction: 'DR',
        })
      } else {
        // Down-left diagonal: (row, col+1) to (row+1, col)
        connectors.push({
          type: 'diagonal',
          cellA: { row, col: col + 1 },
          cellB: { row: row + 1, col },
          direction: 'DL',
        })
      }
    }
  }

  return connectors
}

/**
 * Get all connectors that touch a specific cell
 */
export function getCellConnectors<T extends UnvaluedConnector | Connector>(
  cell: Coordinate,
  connectors: T[]
): T[] {
  return connectors.filter(c =>
    (c.cellA.row === cell.row && c.cellA.col === cell.col) ||
    (c.cellB.row === cell.row && c.cellB.col === cell.col)
  )
}

/**
 * Find the connector between two specific cells
 */
export function getConnectorBetween(
  cellA: Coordinate,
  cellB: Coordinate,
  connectors: Connector[]
): Connector | undefined {
  return connectors.find(c =>
    (c.cellA.row === cellA.row && c.cellA.col === cellA.col &&
     c.cellB.row === cellB.row && c.cellB.col === cellB.col) ||
    (c.cellA.row === cellB.row && c.cellA.col === cellB.col &&
     c.cellB.row === cellA.row && c.cellB.col === cellA.col)
  )
}

/**
 * Check if two cells are adjacent (horizontally, vertically, or diagonally)
 */
export function areAdjacent(a: Coordinate, b: Coordinate): boolean {
  const rowDiff = Math.abs(a.row - b.row)
  const colDiff = Math.abs(a.col - b.col)
  return rowDiff <= 1 && colDiff <= 1 && (rowDiff + colDiff > 0)
}

/**
 * Get the other cell connected by a connector
 */
export function getOtherCell(connector: Connector, cell: Coordinate): Coordinate {
  if (connector.cellA.row === cell.row && connector.cellA.col === cell.col) {
    return connector.cellB
  }
  return connector.cellA
}
