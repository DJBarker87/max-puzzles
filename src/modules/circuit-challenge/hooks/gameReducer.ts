import type { Coordinate, Connector, Cell } from '../types'
import type { DifficultySettings } from '../engine/types'
import type { GameState, GameAction, GameMoveResult } from '../types/gameState'
import { DIFFICULTY_PRESETS } from '../engine/difficulty'

/**
 * Check if two cells are adjacent (including diagonals)
 */
export function isAdjacent(from: Coordinate, to: Coordinate): boolean {
  const rowDiff = Math.abs(from.row - to.row)
  const colDiff = Math.abs(from.col - to.col)

  // Adjacent means at most 1 step in each direction, but not same cell
  return rowDiff <= 1 && colDiff <= 1 && (rowDiff > 0 || colDiff > 0)
}

/**
 * Find the connector between two cells
 */
export function getConnectorBetweenCells(
  from: Coordinate,
  to: Coordinate,
  connectors: Connector[]
): Connector | undefined {
  return connectors.find(
    (c) =>
      (c.cellA.row === from.row &&
        c.cellA.col === from.col &&
        c.cellB.row === to.row &&
        c.cellB.col === to.col) ||
      (c.cellB.row === from.row &&
        c.cellB.col === from.col &&
        c.cellA.row === to.row &&
        c.cellA.col === to.col)
  )
}

/**
 * Check if a move is correct (follows the solution path)
 */
export function checkMoveCorrectness(
  fromCell: Cell,
  toCell: Coordinate,
  connectors: Connector[]
): { correct: boolean; connector: Connector | undefined } {
  const connector = getConnectorBetweenCells(
    { row: fromCell.row, col: fromCell.col },
    toCell,
    connectors
  )

  if (!connector) {
    return { correct: false, connector: undefined }
  }

  // A move is correct if the connector's value equals the fromCell's answer
  // The fromCell's answer tells us which connector to take
  const correct = fromCell.answer === connector.value

  return { correct, connector }
}

/**
 * Create initial game state
 */
export function createInitialGameState(
  difficulty?: DifficultySettings
): GameState {
  const difficultySettings = difficulty || DIFFICULTY_PRESETS[4] // Default to Level 5

  return {
    status: 'setup',
    puzzle: null,
    difficulty: difficultySettings,
    currentPosition: { row: 0, col: 0 },
    visitedCells: [],
    traversedConnectors: [],
    moveHistory: [],
    lives: 5,
    maxLives: 5,
    startTime: null,
    elapsedMs: 0,
    isTimerRunning: false,
    puzzleCoins: 0,
    coinAnimations: [],
    isHiddenMode: difficultySettings.hiddenMode,
    hiddenModeResults: null,
    showingSolution: false,
    error: null,
  }
}

/**
 * Game reducer for state management
 */
export function gameReducer(state: GameState, action: GameAction): GameState {
  switch (action.type) {
    case 'SET_DIFFICULTY':
      return {
        ...state,
        difficulty: action.payload,
        isHiddenMode: action.payload.hiddenMode,
      }

    case 'GENERATE_PUZZLE':
      return {
        ...state,
        status: 'setup',
        error: null,
      }

    case 'PUZZLE_GENERATED':
      return {
        ...state,
        status: 'ready',
        puzzle: action.payload,
        currentPosition: { row: 0, col: 0 },
        visitedCells: [{ row: 0, col: 0 }], // START is initially visited
        traversedConnectors: [],
        moveHistory: [],
        lives: state.maxLives,
        startTime: null,
        elapsedMs: 0,
        isTimerRunning: false,
        puzzleCoins: 0,
        coinAnimations: [],
        hiddenModeResults: state.isHiddenMode
          ? { moves: [], correctCount: 0, mistakeCount: 0 }
          : null,
        showingSolution: false,
        error: null,
      }

    case 'PUZZLE_GENERATION_FAILED':
      return {
        ...state,
        status: 'setup',
        error: action.payload,
      }

    case 'START_TIMER':
      if (state.isTimerRunning) return state
      return {
        ...state,
        status: 'playing',
        startTime: Date.now(),
        isTimerRunning: true,
      }

    case 'TICK_TIMER':
      if (!state.isTimerRunning) return state
      return {
        ...state,
        elapsedMs: action.payload,
      }

    case 'MAKE_MOVE': {
      if (
        !state.puzzle ||
        state.status === 'won' ||
        state.status === 'lost'
      ) {
        return state
      }

      const targetCoord = action.payload
      const fromCell =
        state.puzzle.grid[state.currentPosition.row][state.currentPosition.col]

      // Check if target is adjacent
      if (!isAdjacent(state.currentPosition, targetCoord)) {
        return state // Invalid move, ignore
      }

      // Check if already visited
      if (
        state.visitedCells.some(
          (c) => c.row === targetCoord.row && c.col === targetCoord.col
        )
      ) {
        return state // Can't revisit
      }

      // Check move correctness
      const { correct, connector } = checkMoveCorrectness(
        fromCell,
        targetCoord,
        state.puzzle.connectors
      )

      if (!connector) return state // No connector exists

      const moveResult: GameMoveResult = {
        correct,
        fromCell: state.currentPosition,
        toCell: targetCoord,
        connectorValue: connector.value,
        cellAnswer: fromCell.answer!,
      }

      // Check if reached FINISH
      const isFinish =
        targetCoord.row === state.puzzle.grid.length - 1 &&
        targetCoord.col === state.puzzle.grid[0].length - 1

      // Handle based on mode
      if (state.isHiddenMode) {
        // Hidden mode: always accept move, track results
        const newHiddenResults = {
          moves: [...state.hiddenModeResults!.moves, moveResult],
          correctCount:
            state.hiddenModeResults!.correctCount + (correct ? 1 : 0),
          mistakeCount:
            state.hiddenModeResults!.mistakeCount + (correct ? 0 : 1),
        }

        return {
          ...state,
          currentPosition: targetCoord,
          visitedCells: [...state.visitedCells, targetCoord],
          traversedConnectors: [
            ...state.traversedConnectors,
            { cellA: state.currentPosition, cellB: targetCoord },
          ],
          moveHistory: [...state.moveHistory, moveResult],
          hiddenModeResults: newHiddenResults,
          status: isFinish ? 'revealing' : state.status,
        }
      } else {
        // Standard mode
        if (correct) {
          // Correct move
          const coinId = `coin-${Date.now()}`
          const newPuzzleCoins = state.puzzleCoins + 10

          return {
            ...state,
            currentPosition: targetCoord,
            visitedCells: [...state.visitedCells, targetCoord],
            traversedConnectors: [
              ...state.traversedConnectors,
              { cellA: state.currentPosition, cellB: targetCoord },
            ],
            moveHistory: [...state.moveHistory, moveResult],
            puzzleCoins: newPuzzleCoins,
            coinAnimations: [
              ...state.coinAnimations,
              { id: coinId, value: 10, type: 'earn', timestamp: Date.now() },
            ],
            status: isFinish ? 'won' : state.status,
          }
        } else {
          // Wrong move
          const newLives = state.lives - 1
          const coinId = `coin-${Date.now()}`
          const newPuzzleCoins = Math.max(0, state.puzzleCoins - 30) // Clamp to 0

          return {
            ...state,
            lives: newLives,
            moveHistory: [...state.moveHistory, moveResult],
            puzzleCoins: newPuzzleCoins,
            coinAnimations: [
              ...state.coinAnimations,
              {
                id: coinId,
                value: -30,
                type: 'penalty',
                timestamp: Date.now(),
              },
            ],
            status: newLives <= 0 ? 'lost' : state.status,
          }
        }
      }
    }

    case 'RESET_PUZZLE':
      // Reset to start of same puzzle
      if (!state.puzzle) return state
      return {
        ...state,
        status: 'ready',
        currentPosition: { row: 0, col: 0 },
        visitedCells: [{ row: 0, col: 0 }],
        traversedConnectors: [],
        moveHistory: [],
        lives: state.maxLives,
        startTime: null,
        elapsedMs: 0,
        isTimerRunning: false,
        puzzleCoins: 0,
        coinAnimations: [],
        hiddenModeResults: state.isHiddenMode
          ? { moves: [], correctCount: 0, mistakeCount: 0 }
          : null,
        showingSolution: false,
      }

    case 'NEW_PUZZLE':
      return {
        ...state,
        status: 'setup',
        puzzle: null,
        error: null,
      }

    case 'SHOW_SOLUTION':
      return {
        ...state,
        showingSolution: true,
      }

    case 'HIDE_SOLUTION':
      return {
        ...state,
        showingSolution: false,
      }

    case 'REVEAL_HIDDEN_RESULTS':
      // Calculate final coins for hidden mode
      if (!state.hiddenModeResults) return state
      const { correctCount, mistakeCount } = state.hiddenModeResults
      const earnedCoins = correctCount * 10
      const penaltyCoins = mistakeCount * 30
      const finalCoins = Math.max(0, earnedCoins - penaltyCoins)

      return {
        ...state,
        status: 'won',
        puzzleCoins: finalCoins,
      }

    case 'CLEAR_COIN_ANIMATION':
      return {
        ...state,
        coinAnimations: state.coinAnimations.filter(
          (a) => a.id !== action.payload
        ),
      }

    default:
      return state
  }
}
