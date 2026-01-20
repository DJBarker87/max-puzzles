import { useEffect, useState } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import { useGame } from '../hooks/useGame'
import { useFeedback } from '../hooks/useFeedback'
import { useOrientation } from '@/shared/hooks'
import {
  PuzzleGrid,
  GameHeader,
  ActionButtons,
  StarryBackground,
  LivesDisplay,
  TimerDisplay,
  GameCoinDisplay,
  MusicToggleButton,
} from '../components'
import { Button, Modal } from '@/ui'
import { printCurrentPuzzle } from '../services/pdfGenerator'
import type { DifficultySettings } from '../engine/types'
import type { ChapterAlien } from '@/shared/types/chapterAlien'

interface LocationState {
  difficulty?: DifficultySettings
  showSolution?: boolean
}

interface GameScreenProps {
  // Story mode optional props
  storyAlien?: ChapterAlien
  storyChapter?: number
  storyLevel?: number
}

/**
 * Main game screen for playing Circuit Challenge
 */
export default function GameScreen({
  storyAlien,
  storyChapter,
  storyLevel,
}: GameScreenProps = {}) {
  const location = useLocation()
  const navigate = useNavigate()
  const locationState = location.state as LocationState | null

  const difficulty = locationState?.difficulty

  const [showExitConfirm, setShowExitConfirm] = useState(false)

  const { triggerShake, shakeClassName } = useFeedback()
  const { isMobileLandscape } = useOrientation()

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

  // Navigate to summary when game ends (but not if viewing solution)
  useEffect(() => {
    if ((state.status === 'won' || state.status === 'lost') && !state.showingSolution) {
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
            // Story mode data
            storyAlien,
            storyChapter,
            storyLevel,
          },
        })
      }, 1000)
      return () => clearTimeout(timer)
    }
  }, [state.status, state.showingSolution, navigate, state, storyAlien, storyChapter, storyLevel])

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
          // Story mode data
          storyAlien,
          storyChapter,
          storyLevel,
        },
      })
    }
  }, [state.status, state.isHiddenMode, navigate, state, storyAlien, storyChapter, storyLevel])

  const handleNewPuzzle = async () => {
    requestNewPuzzle()
    await generateNewPuzzle()
  }

  const handlePrint = () => {
    if (state.puzzle) {
      printCurrentPuzzle(state.puzzle, state.showingSolution)
    }
  }

  const handleContinueToSummary = () => {
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
        // Story mode data
        storyAlien,
        storyChapter,
        storyLevel,
      },
    })
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

  // Render landscape mobile layout
  if (isMobileLandscape) {
    return (
      <div className={`h-screen flex relative overflow-hidden ${shakeClassName}`}>
        <StarryBackground />

        {/* Left Panel: Back button + Action buttons (vertical, centered) */}
        <div className="shrink-0 flex flex-col items-center justify-center gap-3 py-2 px-1 bg-background-dark/80 backdrop-blur-sm border-r border-white/10 z-20">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => setShowExitConfirm(true)}
            className="w-10 h-10 rounded-xl !p-0 flex items-center justify-center"
            aria-label="Go back"
          >
            <span className="text-lg">←</span>
          </Button>

          <MusicToggleButton size="sm" />

          <ActionButtons
            onReset={resetPuzzle}
            onNewPuzzle={handleNewPuzzle}
            onChangeDifficulty={() => navigate('/play/circuit-challenge/quick')}
            onPrint={handlePrint}
            onViewSolution={state.status === 'lost' ? showSolution : undefined}
            showViewSolution={state.status === 'lost' && !state.showingSolution}
            onContinue={handleContinueToSummary}
            showContinue={state.showingSolution}
            disabled={!state.puzzle}
            vertical
          />
        </div>

        {/* Center: Puzzle Grid */}
        <div className="flex-1 min-w-0 flex items-center justify-center p-1 relative z-10">
          {state.puzzle ? (
            <div className="w-full h-full flex items-center justify-center">
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

        {/* Right Panel: Status displays (vertical) */}
        <div className="shrink-0 flex flex-col items-center justify-center gap-3 py-2 px-2 bg-background-dark/80 backdrop-blur-sm border-l border-white/10 z-20">
          {!state.isHiddenMode && (
            <LivesDisplay
              lives={state.lives}
              maxLives={state.maxLives}
              size="sm"
              vertical
            />
          )}

          <TimerDisplay
            elapsedMs={state.elapsedMs}
            thresholdMs={state.isHiddenMode ? undefined : timeThresholdMs ?? undefined}
            isRunning={state.isTimerRunning}
            size="sm"
          />

          <GameCoinDisplay
            amount={state.puzzleCoins}
            showChange={state.isHiddenMode ? undefined : coinChange}
            size="sm"
          />
        </div>

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

  // Portrait / Desktop layout
  return (
    <div className={`h-screen flex flex-col relative overflow-hidden ${shakeClassName}`}>
      <StarryBackground />

      {/* Game Header - shrink-0 to prevent compression */}
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
        className="shrink-0"
      />

      {/* Puzzle Grid - flex-1 min-h-0 allows proper shrinking within flexbox */}
      <div className="flex-1 min-h-0 flex items-center justify-center p-2 relative z-10">
        {state.puzzle ? (
          <div className="w-full h-full flex items-center justify-center">
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

      {/* Action Buttons - shrink-0 to prevent compression */}
      <ActionButtons
        onReset={resetPuzzle}
        onNewPuzzle={handleNewPuzzle}
        onChangeDifficulty={() => navigate('/play/circuit-challenge/quick')}
        onPrint={handlePrint}
        onViewSolution={state.status === 'lost' ? showSolution : undefined}
        showViewSolution={state.status === 'lost' && !state.showingSolution}
        onContinue={handleContinueToSummary}
        showContinue={state.showingSolution}
        disabled={!state.puzzle}
        className="shrink-0"
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
