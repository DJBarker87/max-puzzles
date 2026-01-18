import type { Coordinate, Puzzle } from '../types'
import type { DifficultySettings } from '../engine/types'

/**
 * Game status representing the current state of gameplay
 */
export type GameStatus =
  | 'setup'      // Choosing difficulty
  | 'ready'      // Puzzle generated, waiting for first move
  | 'playing'    // Timer running, game in progress
  | 'won'        // Reached FINISH
  | 'lost'       // Out of lives (standard mode only)
  | 'revealing'  // Hidden mode: showing results

/**
 * Result of a single move during gameplay
 */
export interface GameMoveResult {
  /** Whether the move followed the solution path */
  correct: boolean
  /** Starting cell */
  fromCell: Coordinate
  /** Target cell */
  toCell: Coordinate
  /** Value on the connector taken */
  connectorValue: number
  /** The answer value of the cell we moved from */
  cellAnswer: number
}

/**
 * Coin animation for visual feedback
 */
export interface CoinAnimation {
  /** Unique ID for this animation */
  id: string
  /** Amount of coins (+10 or -30) */
  value: number
  /** Type of change */
  type: 'earn' | 'penalty'
  /** Timestamp when animation started */
  timestamp: number
}

/**
 * Hidden mode results tracking
 */
export interface HiddenModeResults {
  /** All moves made */
  moves: GameMoveResult[]
  /** Number of correct moves */
  correctCount: number
  /** Number of incorrect moves */
  mistakeCount: number
}

/**
 * Complete game state interface
 */
export interface GameState {
  // Core state
  /** Current game status */
  status: GameStatus
  /** The puzzle being played */
  puzzle: Puzzle | null
  /** Difficulty settings */
  difficulty: DifficultySettings

  // Position tracking
  /** Current player position */
  currentPosition: Coordinate
  /** Cells that have been visited */
  visitedCells: Coordinate[]
  /** Connectors that have been traversed */
  traversedConnectors: Array<{ cellA: Coordinate; cellB: Coordinate }>
  /** History of all moves made */
  moveHistory: GameMoveResult[]

  // Lives (standard mode)
  /** Remaining lives */
  lives: number
  /** Maximum lives */
  maxLives: number

  // Timer
  /** Timestamp when timer started */
  startTime: number | null
  /** Current elapsed time in milliseconds */
  elapsedMs: number
  /** Whether the timer is currently running */
  isTimerRunning: boolean

  // Coins (for this puzzle)
  /** Running total for current puzzle (clamped to min 0) */
  puzzleCoins: number
  /** Active coin animations */
  coinAnimations: CoinAnimation[]

  // Mode flags
  /** Whether playing in hidden mode */
  isHiddenMode: boolean

  // Hidden mode tracking
  /** Results tracked during hidden mode */
  hiddenModeResults: HiddenModeResults | null

  // For solution reveal
  /** Whether the solution is being shown */
  showingSolution: boolean

  // Error state
  /** Error message if puzzle generation failed */
  error: string | null
}

/**
 * Game actions for the reducer
 */
export type GameAction =
  | { type: 'SET_DIFFICULTY'; payload: DifficultySettings }
  | { type: 'GENERATE_PUZZLE' }
  | { type: 'PUZZLE_GENERATED'; payload: Puzzle }
  | { type: 'PUZZLE_GENERATION_FAILED'; payload: string }
  | { type: 'MAKE_MOVE'; payload: Coordinate }
  | { type: 'START_TIMER' }
  | { type: 'TICK_TIMER'; payload: number }
  | { type: 'RESET_PUZZLE' }
  | { type: 'NEW_PUZZLE' }
  | { type: 'SHOW_SOLUTION' }
  | { type: 'HIDE_SOLUTION' }
  | { type: 'REVEAL_HIDDEN_RESULTS' }
  | { type: 'CLEAR_COIN_ANIMATION'; payload: string }
