import { useReducer, useCallback, useEffect, useRef } from 'react'
import { gameReducer, createInitialGameState } from './gameReducer'
import { generatePuzzle } from '../engine'
import type { DifficultySettings } from '../engine/types'
import type { GameState } from '../types/gameState'
import type { Coordinate } from '../types'

/**
 * Return type for the useGame hook
 */
export interface UseGameReturn {
  // State
  state: GameState

  // Computed values
  canMove: boolean
  isGameOver: boolean
  timeThresholdMs: number | null

  // Actions
  setDifficulty: (difficulty: DifficultySettings) => void
  generateNewPuzzle: () => Promise<void>
  makeMove: (coord: Coordinate) => void
  resetPuzzle: () => void
  requestNewPuzzle: () => void
  showSolution: () => void
  hideSolution: () => void
  revealHiddenResults: () => void
}

/**
 * Main game hook for managing Circuit Challenge gameplay
 */
export function useGame(initialDifficulty?: DifficultySettings): UseGameReturn {
  const [state, dispatch] = useReducer(
    gameReducer,
    initialDifficulty,
    createInitialGameState
  )

  const timerRef = useRef<number | null>(null)
  const startTimeRef = useRef<number | null>(null)

  // Timer effect
  useEffect(() => {
    if (state.isTimerRunning && state.startTime) {
      startTimeRef.current = state.startTime

      const tick = () => {
        if (startTimeRef.current) {
          const elapsed = Date.now() - startTimeRef.current
          dispatch({ type: 'TICK_TIMER', payload: elapsed })
        }
        timerRef.current = requestAnimationFrame(tick)
      }

      timerRef.current = requestAnimationFrame(tick)

      return () => {
        if (timerRef.current) {
          cancelAnimationFrame(timerRef.current)
        }
      }
    }
  }, [state.isTimerRunning, state.startTime])

  // Stop timer when game ends
  useEffect(() => {
    if (
      state.status === 'won' ||
      state.status === 'lost' ||
      state.status === 'revealing'
    ) {
      if (timerRef.current) {
        cancelAnimationFrame(timerRef.current)
        timerRef.current = null
      }
    }
  }, [state.status])

  // Clear coin animations after delay
  useEffect(() => {
    state.coinAnimations.forEach((anim) => {
      const age = Date.now() - anim.timestamp
      if (age < 1000) {
        setTimeout(() => {
          dispatch({ type: 'CLEAR_COIN_ANIMATION', payload: anim.id })
        }, 1000 - age)
      }
    })
  }, [state.coinAnimations])

  // Actions
  const setDifficulty = useCallback((difficulty: DifficultySettings) => {
    dispatch({ type: 'SET_DIFFICULTY', payload: difficulty })
  }, [])

  const generateNewPuzzle = useCallback(async () => {
    dispatch({ type: 'GENERATE_PUZZLE' })

    // Run generation (could be async in web worker for large puzzles)
    const result = generatePuzzle(state.difficulty)

    if (result.success) {
      dispatch({ type: 'PUZZLE_GENERATED', payload: result.puzzle })
    } else {
      dispatch({
        type: 'PUZZLE_GENERATION_FAILED',
        payload: result.error || 'Unknown error',
      })
    }
  }, [state.difficulty])

  const makeMove = useCallback(
    (coord: Coordinate) => {
      // Start timer on first move if not already running
      if (state.status === 'ready') {
        dispatch({ type: 'START_TIMER' })
      }

      dispatch({ type: 'MAKE_MOVE', payload: coord })
    },
    [state.status]
  )

  const resetPuzzle = useCallback(() => {
    dispatch({ type: 'RESET_PUZZLE' })
  }, [])

  const requestNewPuzzle = useCallback(() => {
    dispatch({ type: 'NEW_PUZZLE' })
  }, [])

  const showSolution = useCallback(() => {
    dispatch({ type: 'SHOW_SOLUTION' })
  }, [])

  const hideSolution = useCallback(() => {
    dispatch({ type: 'HIDE_SOLUTION' })
  }, [])

  const revealHiddenResults = useCallback(() => {
    dispatch({ type: 'REVEAL_HIDDEN_RESULTS' })
  }, [])

  // Computed values
  const canMove = state.status === 'ready' || state.status === 'playing'
  const isGameOver = state.status === 'won' || state.status === 'lost'

  const timeThresholdMs = state.puzzle
    ? state.puzzle.solution.steps * state.difficulty.secondsPerStep * 1000
    : null

  return {
    state,
    canMove,
    isGameOver,
    timeThresholdMs,
    setDifficulty,
    generateNewPuzzle,
    makeMove,
    resetPuzzle,
    requestNewPuzzle,
    showSolution,
    hideSolution,
    revealHiddenResults,
  }
}
