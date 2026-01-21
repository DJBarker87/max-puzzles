import type { Coordinate, DiagonalDirection } from '../types'

/**
 * Key format for 2x2 block diagonal tracking: "row,col" of top-left corner
 */
export type DiagonalKey = string

/**
 * Map of diagonal commitments for each 2x2 block
 */
export type DiagonalCommitments = Map<DiagonalKey, DiagonalDirection>

/**
 * Result of path generation attempt
 */
export interface PathResult {
  success: boolean
  path: Coordinate[]
  diagonalCommitments: DiagonalCommitments
  error?: string
}

/**
 * Convert coordinate to string key for use in Sets/Maps
 */
export function coordToKey(c: Coordinate): string {
  return `${c.row},${c.col}`
}

/**
 * Get the key for the 2x2 block a diagonal belongs to
 * The key is the top-left corner of that block
 */
export function getDiagonalKey(cellA: Coordinate, cellB: Coordinate): DiagonalKey {
  const minRow = Math.min(cellA.row, cellB.row)
  const minCol = Math.min(cellA.col, cellB.col)
  return `${minRow},${minCol}`
}

/**
 * Determine the diagonal direction for a move
 * DR = down-right or up-left (same diagonal line)
 * DL = down-left or up-right (anti-diagonal)
 */
export function getDiagonalDirection(from: Coordinate, to: Coordinate): DiagonalDirection {
  const rowDiff = to.row - from.row
  const colDiff = to.col - from.col

  // DR: (row increases AND col increases) OR (row decreases AND col decreases)
  // DL: (row increases AND col decreases) OR (row decreases AND col increases)
  if ((rowDiff > 0 && colDiff > 0) || (rowDiff < 0 && colDiff < 0)) {
    return 'DR'
  }
  return 'DL'
}

/**
 * Check if a move between two cells is diagonal
 */
export function isDiagonalMove(from: Coordinate, to: Coordinate): boolean {
  return from.row !== to.row && from.col !== to.col
}

/**
 * Get all adjacent cells (8 directions) that are within grid bounds
 */
export function getAdjacent(pos: Coordinate, rows: number, cols: number): Coordinate[] {
  const directions = [
    { row: -1, col: 0 },  // up
    { row: 1, col: 0 },   // down
    { row: 0, col: -1 },  // left
    { row: 0, col: 1 },   // right
    { row: -1, col: -1 }, // up-left
    { row: -1, col: 1 },  // up-right
    { row: 1, col: -1 },  // down-left
    { row: 1, col: 1 },   // down-right
  ]

  const adjacent: Coordinate[] = []
  for (const dir of directions) {
    const newRow = pos.row + dir.row
    const newCol = pos.col + dir.col
    if (newRow >= 0 && newRow < rows && newCol >= 0 && newCol < cols) {
      adjacent.push({ row: newRow, col: newCol })
    }
  }

  return adjacent
}

/**
 * Calculate Manhattan distance between two cells
 */
export function manhattanDistance(a: Coordinate, b: Coordinate): number {
  return Math.abs(a.row - b.row) + Math.abs(a.col - b.col)
}

/**
 * Check if a diagonal move conflicts with existing commitment
 */
function isDiagonalMoveValid(
  from: Coordinate,
  to: Coordinate,
  commitments: DiagonalCommitments
): boolean {
  if (!isDiagonalMove(from, to)) {
    return true // Not a diagonal move, always valid
  }

  const key = getDiagonalKey(from, to)
  const direction = getDiagonalDirection(from, to)
  const existing = commitments.get(key)

  // If there's an existing commitment, it must match
  if (existing && existing !== direction) {
    return false
  }

  return true
}

/**
 * Count the number of direction changes in a path
 */
function countDirectionChanges(path: Coordinate[]): number {
  if (path.length < 3) return 0

  let changes = 0
  let prevDeltaRow = path[1].row - path[0].row
  let prevDeltaCol = path[1].col - path[0].col

  for (let i = 2; i < path.length; i++) {
    const deltaRow = path[i].row - path[i - 1].row
    const deltaCol = path[i].col - path[i - 1].col

    if (deltaRow !== prevDeltaRow || deltaCol !== prevDeltaCol) {
      changes++
    }

    prevDeltaRow = deltaRow
    prevDeltaCol = deltaCol
  }

  return changes
}

/**
 * Check if a path is "interesting" (has enough direction changes)
 * Shorter paths need fewer direction changes
 */
export function isInterestingPath(path: Coordinate[]): boolean {
  let minChanges: number
  if (path.length < 6) {
    minChanges = 1 // Very short paths just need 1 turn
  } else if (path.length < 8) {
    minChanges = 2 // Short paths need 2 turns
  } else {
    minChanges = 3 // Normal paths need 3 turns
  }
  return countDirectionChanges(path) >= minChanges
}

/**
 * Generate a solution path from START (0,0) to FINISH (rows-1, cols-1)
 */
export function generatePath(
  rows: number,
  cols: number,
  minLength: number,
  maxLength: number,
  maxAttempts: number = 200 // Increased from 100 for better success on larger grids
): PathResult {
  const start: Coordinate = { row: 0, col: 0 }
  const finish: Coordinate = { row: rows - 1, col: cols - 1 }

  for (let attempt = 0; attempt < maxAttempts; attempt++) {
    const path: Coordinate[] = [start]
    const visited = new Set<string>([coordToKey(start)])
    const diagonalCommitments: DiagonalCommitments = new Map()

    let current = start

    while (!(current.row === finish.row && current.col === finish.col)) {
      // Check if path is too long
      if (path.length > maxLength) {
        break
      }

      // Get all adjacent cells
      const adjacent = getAdjacent(current, rows, cols)

      // Filter to valid moves
      const validMoves = adjacent.filter(next => {
        // Must not be visited
        if (visited.has(coordToKey(next))) {
          return false
        }
        // Diagonal moves must not conflict with commitments
        if (!isDiagonalMoveValid(current, next, diagonalCommitments)) {
          return false
        }
        return true
      })

      // No valid moves - stuck
      if (validMoves.length === 0) {
        break
      }

      // Select next cell
      let next: Coordinate
      const progressRatio = path.length / maxLength
      const totalCells = rows * cols
      const isSmallGrid = totalCells <= 20

      // For small grids, use mostly random moves with occasional bias toward finish
      // For large grids, use smarter scoring with dead-end avoidance
      if (isSmallGrid) {
        // Small grid: mostly random with light progress bias
        if (progressRatio > 0.6 && Math.random() < 0.4) {
          // Pick closest to finish
          validMoves.sort((a, b) =>
            manhattanDistance(a, finish) - manhattanDistance(b, finish)
          )
          next = validMoves[0]
        } else {
          next = validMoves[Math.floor(Math.random() * validMoves.length)]
        }
      } else {
        // Large grid: smart scoring with dead-end avoidance
        const scoredMoves = validMoves.map(move => {
          let score = 0
          const distToFinish = manhattanDistance(move, finish)

          // Stronger finish bias as we approach max length
          if (progressRatio > 0.7) {
            score -= distToFinish * (progressRatio - 0.5) * 2
          }

          // Dead-end avoidance: prefer moves with more future options
          const futureOptions = getAdjacent(move, rows, cols)
            .filter(opt => !visited.has(coordToKey(opt)) && !(opt.row === current.row && opt.col === current.col))
            .length
          score += futureOptions * 0.5

          // Random factor for variety
          score += Math.random() * 0.5

          return { move, score }
        })

        // Pick move with highest score
        scoredMoves.sort((a, b) => b.score - a.score)
        next = scoredMoves[0].move
      }

      // Record diagonal commitment if applicable
      if (isDiagonalMove(current, next)) {
        const key = getDiagonalKey(current, next)
        const direction = getDiagonalDirection(current, next)
        diagonalCommitments.set(key, direction)
      }

      // Add to path
      path.push(next)
      visited.add(coordToKey(next))
      current = next
    }

    // Check if we reached finish with valid length
    if (
      current.row === finish.row &&
      current.col === finish.col &&
      path.length >= minLength &&
      isInterestingPath(path)
    ) {
      return {
        success: true,
        path,
        diagonalCommitments,
      }
    }
  }

  return {
    success: false,
    path: [],
    diagonalCommitments: new Map(),
    error: `Failed to generate valid path after ${maxAttempts} attempts`,
  }
}
