/**
 * Grid coordinate
 */
export interface Coordinate {
  /** Row index (0-based) */
  row: number
  /** Column index (0-based) */
  col: number
}

/**
 * Diagonal direction for connector placement
 */
export type DiagonalDirection = 'DR' | 'DL'

/**
 * Diagonal connector information
 */
export interface Diagonal {
  /** Direction of the diagonal */
  direction: DiagonalDirection
  /** Value on the diagonal connector */
  value: number
}

/**
 * Types of connectors between cells
 */
export type ConnectorType = 'horizontal' | 'vertical' | 'diagonal'

/**
 * Connector between two adjacent cells
 */
export interface Connector {
  /** Type of connector */
  type: ConnectorType
  /** First cell coordinate */
  cellA: Coordinate
  /** Second cell coordinate */
  cellB: Coordinate
  /** Numeric value on the connector */
  value: number
  /** Direction for diagonal connectors */
  direction?: DiagonalDirection
}

/**
 * Cell visual states
 */
export type CellState = 'normal' | 'start' | 'finish' | 'current' | 'visited' | 'wrong'

/**
 * Game mode (standard with lives or hidden for challenge)
 */
export type GameMode = 'standard' | 'hidden'

/**
 * A cell in the puzzle grid
 */
export interface Cell {
  /** Row position */
  row: number
  /** Column position */
  col: number
  /** Arithmetic expression displayed in the cell */
  expression: string
  /** Evaluated answer (null for START cell) */
  answer: number | null
  /** Whether this is the start cell */
  isStart: boolean
  /** Whether this is the finish cell */
  isFinish: boolean
}

/**
 * Complete puzzle definition
 */
export interface Puzzle {
  /** Unique puzzle identifier */
  id: string
  /** Difficulty level (1-10) */
  difficulty: number
  /** Grid of cells */
  grid: Cell[][]
  /** All connectors in the puzzle */
  connectors: Connector[]
  /** Solution information */
  solution: {
    /** Ordered path from start to finish */
    path: Coordinate[]
    /** Number of steps (path length - 1) */
    steps: number
  }
}

/**
 * Result of attempting to move to a cell
 */
export interface MoveResult {
  /** Whether the move was valid */
  valid: boolean
  /** Whether the game is complete */
  complete: boolean
  /** Whether this was a wrong move */
  wrong: boolean
  /** Remaining lives (standard mode only) */
  livesRemaining?: number
}

/**
 * Game state during play
 */
export interface GameState {
  /** Current puzzle */
  puzzle: Puzzle
  /** Current cell position */
  currentPosition: Coordinate
  /** Cells visited so far */
  visitedCells: Coordinate[]
  /** Connectors that have been traversed */
  traversedConnectors: Connector[]
  /** Game mode */
  mode: GameMode
  /** Lives remaining (standard mode) */
  lives: number
  /** Time elapsed in milliseconds */
  timeElapsed: number
  /** Whether timer has started */
  timerStarted: boolean
  /** Whether game is complete */
  isComplete: boolean
  /** Whether game is won */
  isWon: boolean
  /** Coins earned this game */
  coinsEarned: number
}
