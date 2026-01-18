import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useGame } from '../hooks/useGame'
import { useFeedback } from '../hooks/useFeedback'
import {
  PuzzleGrid,
  GameHeader,
  ActionButtons,
  StarryBackground,
} from '../components'
import { Button, Modal } from '@/ui'
import type { DifficultySettings } from '../engine/types'

interface LocationState {
  difficulty?: DifficultySettings
  showSolution?: boolean
}

/**
 * Main game screen for playing Circuit Challenge
 */
export default function GameScreen() {
  const location = useLocation()
  const navigate = useNavigate()
  const locationState = location.state as LocationState | null

  const difficulty = locationState?.difficulty

  const [showExitConfirm, setShowExitConfirm] = useState(false)

  const { triggerShake, shakeClassName } = useFeedback()

  // Redirect to setup if no difficulty
  useEffect(() => {
    if (!difficulty) {
      navigate('/play/circuit-challenge/quick')
    }
  }, [difficulty, navigate])

  // Initialize game hook
  const {
    state,
    canMove,
    isGameOver,
    timeThresholdMs,
    generateNewPuzzle,
    makeMove,
    resetPuzzle,
    requestNewPuzzle,
    showSolution,
  } = useGame(difficulty)

  // Generate puzzle on mount
  useEffect(() => {
    if (difficulty && !state.puzzle && state.status === 'setup') {
      generateNewPuzzle()
    }
  }, [difficulty, state.puzzle, state.status, generateNewPuzzle])

  // Watch for wrong moves and trigger shake
  useEffect(() => {
    const lastMove = state.moveHistory[state.moveHistory.length - 1]
    if (lastMove && !lastMove.correct && !state.isHiddenMode) {
      triggerShake()
    }
  }, [state.moveHistory, state.isHiddenMode, triggerShake])

  // Navigate to summary when game ends
  useEffect(() => {
    if (state.status === 'won' || state.status === 'lost') {
      // Small delay to show final state
      const timer = setTimeout(() => {
        navigate('/play/circuit-challenge/summary', {
          state: {
            won: state.status === 'won',
            isHiddenMode: state.isHiddenMode,
            elapsedMs: state.elapsedMs,
            puzzleCoins: state.puzzleCoins,
            moveHistory: state.moveHistory,
            hiddenModeResults: state.hiddenModeResults,
            difficulty: state.difficulty,
            puzzle: state.puzzle,
          },
        })
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [state.status, navigate, state])

  // Handle revealing hidden mode results
  useEffect(() => {
    if (state.status === 'revealing' && state.isHiddenMode) {
      // Navigate to summary for hidden mode reveal
      navigate('/play/circuit-challenge/summary', {
        state: {
          won: true, // Hidden mode always "wins"
          isHiddenMode: true,
          elapsedMs: state.elapsedMs,
          puzzleCoins: state.puzzleCoins,
          moveHistory: state.moveHistory,
          hiddenModeResults: state.hiddenModeResults,
          difficulty: state.difficulty,
          puzzle: state.puzzle,
        },
      })
    }
  }, [state.status, state.isHiddenMode, navigate, state])

  const handleNewPuzzle = async () => {
    requestNewPuzzle()
    await generateNewPuzzle()
  }

  const handlePrint = () => {
    window.print()
  }

  // Get the most recent coin animation
  const coinChange = state.coinAnimations[0]
    ? {
        value: state.coinAnimations[0].value,
        type: state.coinAnimations[0].type,
      }
    : undefined

  // Don't render if no difficulty
  if (!difficulty) {
    return null
  }

  return (
    <div className={`min-h-screen flex flex-col relative ${shakeClassName}`}>
      <StarryBackground />

      {/* Game Header */}
      <GameHeader
        title={state.isHiddenMode ? 'Hidden Mode' : 'Quick Play'}
        lives={state.lives}
        maxLives={state.maxLives}
        elapsedMs={state.elapsedMs}
        isTimerRunning={state.isTimerRunning}
        timeThresholdMs={timeThresholdMs ?? undefined}
        coins={state.puzzleCoins}
        coinChange={coinChange}
        isHiddenMode={state.isHiddenMode}
        onBackClick={() => setShowExitConfirm(true)}
      />

      {/* Puzzle Grid */}
      <div className="flex-1 flex items-center justify-center p-2 relative z-10 overflow-hidden">
        {state.puzzle ? (
          <div className="w-full h-full max-w-[90vw] max-h-[calc(100vh-180px)] flex items-center justify-center">
            <PuzzleGrid
              puzzle={state.puzzle}
              currentPosition={state.currentPosition}
              visitedCells={state.visitedCells}
              traversedConnectors={state.traversedConnectors}
              onCellClick={canMove ? makeMove : undefined}
              disabled={!canMove}
              showSolution={state.showingSolution}
              className="max-w-full max-h-full"
            />
          </div>
        ) : state.error ? (
          <div className="text-center">
            <div className="text-4xl mb-4">⚠️</div>
            <p className="text-error mb-4">{state.error}</p>
            <Button variant="primary" onClick={handleNewPuzzle}>
              Try Again
            </Button>
          </div>
        ) : (
          <div className="text-center">
            <div className="animate-spin text-4xl mb-4">⚡</div>
            <p className="text-text-secondary">Generating puzzle...</p>
          </div>
        )}
      </div>

      {/* Action Buttons */}
      <ActionButtons
        onReset={resetPuzzle}
        onNewPuzzle={handleNewPuzzle}
        onChangeDifficulty={() => navigate('/play/circuit-challenge/quick')}
        onPrint={handlePrint}
        onViewSolution={state.status === 'lost' ? showSolution : undefined}
        showViewSolution={state.status === 'lost' && !state.showingSolution}
        disabled={!state.puzzle}
      />

      {/* Exit Confirmation Modal */}
      <Modal
        isOpen={showExitConfirm}
        onClose={() => setShowExitConfirm(false)}
        title="Exit Puzzle?"
      >
        <p className="mb-6 text-text-secondary">
          Your progress on this puzzle will be lost.
        </p>
        <div className="flex gap-3">
          <Button
            variant="ghost"
            onClick={() => setShowExitConfirm(false)}
            className="flex-1"
          >
            Continue Playing
          </Button>
          <Button
            variant="secondary"
            onClick={() => navigate('/play/circuit-challenge')}
            className="flex-1"
          >
            Exit
          </Button>
        </div>
      </Modal>

      {/* Game Over Overlay */}
      {isGameOver && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <div className="text-center animate-pulse">
            <div className="text-6xl mb-4">
              {state.status === 'won' ? '🎉' : '💔'}
            </div>
            <p className="text-2xl font-display font-bold">
              {state.status === 'won' ? 'Puzzle Complete!' : 'Out of Lives'}
            </p>
          </div>
        </div>
      )}
    </div>
  )
}
